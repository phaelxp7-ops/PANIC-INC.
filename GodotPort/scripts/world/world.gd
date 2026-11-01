class_name PanicWorld
extends Node3D

const CENAS_REGIOES: Array[String] = [
	"res://scenes/regions/forest.tscn",
	"res://scenes/regions/city.tscn",
	"res://scenes/regions/complex.tscn",
	"res://scenes/regions/subsoil.tscn"
]
const INICIO_FLORESTA: Vector3 = Vector3(-83.0, 0.3, 4.0)

var hud: PanicHUD
var _ambiente: WorldEnvironment
var _luz_direcional: DirectionalLight3D
var _segundos: float = 0.0
var _timer_spawn: float = 24.0
var _indice_dialogo_marta: int = 0
var _chefe: PanicMonster
var _quedas_recuperadas: Dictionary = {}
@onready var _jogadores: Node3D = $Jogadores
@onready var _spawner: MultiplayerSpawner = $MultiplayerSpawner


func _ready() -> void:
	add_to_group("mundo_principal")
	montar_ambiente()
	montar_regioes()
	hud = PanicHUD.new()
	add_child(hud)
	_spawner.spawn_function = Callable(self, "_criar_jogador_rede")
	EventBus.mensagem.connect(hud.mostrar_mensagem)
	EventBus.estado_alterado.connect(hud.atualizar)
	if multiplayer.is_server():
		_spawn_jogador(1)
		multiplayer.peer_connected.connect(_ao_conectar)
		multiplayer.peer_disconnected.connect(_ao_desconectar)
	else:
		call_deferred("_enviar_pronto")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.mensagem.emit("A floresta está quieta demais. Siga a luz da cabana.", 4.5)


func _process(delta: float) -> void:
	_segundos += delta
	if multiplayer.is_server():
		_timer_spawn -= delta
		if _timer_spawn <= 0.0:
			_tentar_surgimento()
			_timer_spawn = maxf(19.0, 37.0 - float(GameState.dificuldade) * 2.0)
		if int(_segundos) % 40 == 0 and int(_segundos - delta) % 40 != 0:
			GameState.dificuldade = mini(GameState.dificuldade + 1, 5)
			EventBus.mensagem.emit("Algo respondeu ao som dos seus passos.", 3.0)
			EventBus.susto.emit(0.35)
	if hud != null:
		hud.atualizar()
	var jogador_local: PlayerController = _jogador_local()
	if jogador_local != null:
		_verificar_queda(jogador_local)
		_atualizar_regiao(jogador_local.global_position)
	if multiplayer.is_server():
		for jogador: Node in _jogadores.get_children():
			if jogador is PlayerController and jogador != jogador_local:
				_verificar_queda(jogador as PlayerController)


func _verificar_queda(jogador: PlayerController) -> void:
	if jogador.global_position.y > -50.0:
		return
	jogador.global_position = _posicao_segura(jogador.global_position.x)
	jogador.velocity = Vector3.ZERO
	EventBus.mensagem.emit("Queda detectada. Você foi levado ao último setor seguro.", 3.0)


func _posicao_segura(pos_x: float) -> Vector3:
	if pos_x > 760.0:
		return Vector3(840.0, -15.0, 14.0)
	if pos_x > 420.0:
		return Vector3(560.0, 1.0, 3.0)
	if pos_x > 145.0:
		return Vector3(280.0, 1.0, 3.0)
	return INICIO_FLORESTA


func montar_ambiente() -> void:
	_ambiente = WorldEnvironment.new()
	var ambiente: Environment = Environment.new()
	# Um céu explícito evita o fundo branco que algumas combinações AMD/Vulkan
	# mostram quando o viewport troca de câmera durante o carregamento da cena.
	var ceu: Sky = Sky.new()
	var material_ceu: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	material_ceu.sky_top_color = Color(0.018, 0.028, 0.052)
	material_ceu.sky_horizon_color = Color(0.13, 0.16, 0.17)
	material_ceu.ground_bottom_color = Color(0.012, 0.018, 0.020)
	material_ceu.ground_horizon_color = Color(0.060, 0.078, 0.075)
	material_ceu.sun_angle_max = 0.0
	material_ceu.use_debanding = true
	ceu.sky_material = material_ceu
	ambiente.background_mode = Environment.BG_SKY
	ambiente.sky = ceu
	ambiente.background_energy_multiplier = 0.82
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	ambiente.ambient_light_color = Color(0.39, 0.45, 0.49)
	ambiente.ambient_light_energy = 0.82
	ambiente.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.tonemap_exposure = 0.82
	ambiente.tonemap_white = 1.6
	# Neblina de profundidade simples: legível e compatível com GPU integrada.
	ambiente.fog_enabled = true
	ambiente.fog_light_color = Color(0.055, 0.073, 0.078)
	ambiente.fog_density = 0.006
	ambiente.fog_sun_scatter = 0.0
	ambiente.fog_aerial_perspective = 0.0
	ambiente.fog_depth_begin = 24.0
	ambiente.fog_depth_end = 145.0
	ambiente.glow_enabled = false
	ambiente.ssao_enabled = false # indisponível no renderer Mobile
	ambiente.ssil_enabled = false
	ambiente.sdfgi_enabled = false
	_ambiente.environment = ambiente
	_ambiente.add_to_group("ambiente_global")
	add_child(_ambiente)
	_luz_direcional = DirectionalLight3D.new()
	_luz_direcional.rotation_degrees = Vector3(-52, -30, 0)
	_luz_direcional.light_color = Color(0.48, 0.57, 0.64)
	_luz_direcional.light_energy = 0.82
	_luz_direcional.shadow_enabled = true
	_luz_direcional.directional_shadow_max_distance = 95.0
	_luz_direcional.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(_luz_direcional)
	Settings.aplicar_qualidade()


func montar_regioes() -> void:
	for caminho: String in CENAS_REGIOES:
		var cena: PackedScene = load(caminho) as PackedScene
		if cena != null:
			$Regioes.add_child(cena.instantiate())


func _criar_jogador_rede(dados: Variant) -> Node:
	var informacao: Dictionary = dados as Dictionary
	var jogador: PlayerController = PlayerController.new()
	jogador.name = "Ana_%d" % int(informacao.get("id", 1))
	jogador.peer_id = int(informacao.get("id", 1))
	jogador.world = self
	var posicao: Variant = informacao.get("posicao", INICIO_FLORESTA)
	if posicao is Vector3:
		jogador.position = posicao
	jogador.set_multiplayer_authority(1)
	return jogador


func _spawn_jogador(id: int, posicao: Vector3 = INICIO_FLORESTA) -> void:
	for filho: Node in _jogadores.get_children():
		if filho is PlayerController and (filho as PlayerController).peer_id == id:
			return
	_spawner.spawn({"id": id, "posicao": posicao})


func _ao_conectar(id: int) -> void:
	EventBus.mensagem.emit("Jogador %d entrou na trilha." % id, 3.0)


func _ao_desconectar(id: int) -> void:
	var jogador: Node = _jogadores.get_node_or_null("Ana_%d" % id)
	if jogador != null:
		jogador.queue_free()
	EventBus.mensagem.emit("Jogador %d perdeu a conexão." % id, 3.0)


func _rng_lado(id: int) -> float:
	return float((id % 3) * 1.7)


@rpc("any_peer", "reliable")
func _avisar_servidor_pronto() -> void:
	if multiplayer.is_server():
		var id: int = multiplayer.get_remote_sender_id()
		if id > 1:
			_spawn_jogador(id, INICIO_FLORESTA + Vector3(float(id % 3) * 2.0, 0, 3.0))
			GameState.receber_snapshot.rpc_id(id, GameState.snapshot())


func _enviar_pronto() -> void:
	if not multiplayer.is_server():
		_avisar_servidor_pronto.rpc_id(1)


func _jogador_local() -> PlayerController:
	var id_local: int = multiplayer.get_unique_id()
	for filho: Node in _jogadores.get_children():
		if filho is PlayerController and (filho as PlayerController).peer_id == id_local:
			return filho as PlayerController
	return null


func interacao_proxima(jogador: PlayerController) -> Interactable:
	var melhor: Interactable
	var distancia: float = 3.2
	var frente: Vector3 = -jogador.camera.global_basis.z
	for no: Node in get_tree().get_nodes_in_group("interactables"):
		if not no is Interactable or not is_instance_valid(no):
			continue
		var alvo: Interactable = no as Interactable
		var deslocamento: Vector3 = alvo.global_position - jogador.global_position
		var d: float = deslocamento.length()
		if d > distancia or d < 0.001:
			continue
		if frente.dot(deslocamento.normalized()) < 0.18:
			continue
		melhor = alvo
		distancia = d
	return melhor


func solicitar_interacao(jogador: PlayerController) -> void:
	if not multiplayer.is_server():
		jogador.solicitar_interacao_remota.rpc_id(1)
		return
	_executar_interacao(jogador)


func solicitar_ping(jogador: PlayerController) -> void:
	if multiplayer.is_server():
		_criar_ping_rede.rpc(jogador.global_position, jogador.nome_jogador)
	else:
		_solicitar_ping_remoto.rpc_id(1, jogador.peer_id)


@rpc("any_peer", "reliable")
func _solicitar_ping_remoto(id: int) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != id:
		return
	var jogador: Node = _jogadores.get_node_or_null("Ana_%d" % id)
	if jogador is PlayerController:
		_criar_ping_rede.rpc(
			(jogador as PlayerController).global_position,
			(jogador as PlayerController).nome_jogador
		)


@rpc("authority", "call_local", "reliable")
func _criar_ping_rede(posicao: Vector3, remetente: String) -> void:
	var indicador: Label3D = Label3D.new()
	indicador.text = "PING  •  " + remetente
	indicador.font_size = 56
	indicador.pixel_size = 0.006
	indicador.modulate = Color(0.32, 0.92, 0.9)
	indicador.outline_size = 10
	indicador.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	indicador.position = posicao + Vector3.UP * 2.2
	add_child(indicador)
	var timer: SceneTreeTimer = get_tree().create_timer(4.0)
	timer.timeout.connect(indicador.queue_free)


@rpc("any_peer", "reliable")
func solicitar_interacao_remota() -> void:
	if not multiplayer.is_server():
		return
	var id: int = multiplayer.get_remote_sender_id()
	var jogador: Node = _jogadores.get_node_or_null("Ana_%d" % id)
	if jogador is PlayerController:
		_executar_interacao(jogador as PlayerController)


func _executar_interacao(jogador: PlayerController) -> void:
	for no: Node in _jogadores.get_children():
		if (
			no is PlayerController
			and no != jogador
			and (no as PlayerController).caido
			and jogador.global_position.distance_to(no.global_position) < 2.4
		):
			(no as PlayerController).reviver()
			return
	var alvo: Interactable = interacao_proxima(jogador)
	if alvo == null:
		return
	var acao: String = alvo.acao
	match acao:
		"porta_marta", "porta_estacao", "porta_tenda":
			var porta: Node = alvo.get_parent()
			if porta is CabinDoor:
				(porta as CabinDoor).alternar()
				EventBus.mensagem.emit(
					"A madeira range alto demais para uma floresta tão quieta.", 2.5
				)
		"npc_marta":
			var dialogo_marta: Array = GameState.historia.get("dialogos", {}).get("marta", [])
			if not GameState.tem_flag("falou_marta"):
				_falar(dialogo_marta)
				GameState.definir_flag("falou_marta")
				for no: Node in _jogadores.get_children():
					if no is PlayerController:
						(no as PlayerController).tem_revolver = true
						(no as PlayerController).municao = maxi(6, (no as PlayerController).municao)
				GameState._emitir_estado()
			else:
				_falar(
					[
						["Marta", "A cabana ainda está segura. Não deixe a lanterna apagar."],
						["Marta", GameState.objetivo_atual()]
					]
				)
		"npc_tomas":
			if not GameState.tem_flag("falou_tomas"):
				_falar(GameState.historia.get("dialogos", {}).get("tomas", []))
				GameState.definir_flag("falou_tomas")
				GameState.adicionar_item("calmantes", 2)
			else:
				_falar(
					[
						["Tomás", "Fique na luz, Ana. Sempre na luz."],
						["Tomás", GameState.objetivo_atual()]
					]
				)
		"chave_floresta":
			if not GameState.tem_flag("falou_marta"):
				EventBus.mensagem.emit("A porta da estação está trancada. Marta pode ajudar.", 3.0)
				return
			GameState.definir_flag("chave_floresta")
			_remover_acao(acao)
			EventBus.mensagem.emit(
				"Chave do portão encontrada. A estrada para a cidade está aberta.", 3.5
			)
		"portao_cidade":
			if not GameState.tem_flag("chave_floresta"):
				EventBus.mensagem.emit(
					"O cadeado está enferrujado, mas ainda firme. Falta a chave da estação.", 3.0
				)
				return
			GameState.definir_flag("portao_cidade")
			_teletransportar_jogador(jogador, Vector3(180, 0.3, 3))
			EventBus.mensagem.emit(
				"O portão cede com um gemido de metal. Vale Sombrio está à frente.", 4.0
			)
		"cartao_acesso":
			if not GameState.tem_flag("falou_tomas"):
				EventBus.mensagem.emit(
					"A evidência está lacrada. Procure o sobrevivente do rádio.", 3.0
				)
				return
			GameState.definir_flag("cartao_acesso")
			_remover_acao(acao)
			EventBus.mensagem.emit("Cartão-mestre recuperado na sala de evidências.", 3.0)
		"porta_complexo":
			if not GameState.tem_flag("cartao_acesso"):
				EventBus.mensagem.emit(
					"Leitor biométrico: acesso negado. O cartão está na delegacia.", 3.2
				)
				return
			GameState.definir_flag("porta_complexo")
			_teletransportar_jogador(jogador, Vector3(455, 0.3, 3))
			EventBus.mensagem.emit(
				"O portão do complexo abre. Uma voz chama seu nome nos alto-falantes.", 4.0
			)
		"fusivel_1", "fusivel_2", "fusivel_3":
			if not GameState.tem_flag("porta_complexo"):
				return
			GameState.adicionar_item("fusives", 1)
			_remover_acao(acao)
			EventBus.mensagem.emit(
				"Fusível recuperado: %d/3." % int(GameState.inventario.get("fusives", 0)), 2.8
			)
		"elevador":
			if int(GameState.inventario.get("fusives", 0)) < 3:
				EventBus.mensagem.emit(
					"O painel está sem energia. O elevador precisa de 3 fusíveis.", 3.0
				)
				return
			GameState.definir_flag("elevador_ativo")
			EventBus.mensagem.emit(
				"Os três fusíveis encaixam. O elevador começa a descer sozinho.", 3.8
			)
		"elevador_subsolo":
			if not GameState.tem_flag("elevador_ativo"):
				EventBus.mensagem.emit(
					"O elevador está sem energia. Ative o console primeiro.", 3.0
				)
				return
			_teletransportar_jogador(jogador, Vector3(840, -15.4, 14))
			EventBus.mensagem.emit("NÍVEL -3. A porta fecha atrás de você.", 4.0)
			if not GameState.tem_flag("diretor_derrotado"):
				_iniciar_chefe()
		"chefe":
			if not GameState.tem_flag("elevador_ativo"):
				EventBus.mensagem.emit(
					"O núcleo está protegido. Restaure a energia do elevador.", 3.0
				)
			elif _chefe == null and not GameState.tem_flag("diretor_derrotado"):
				_iniciar_chefe()
				_falar(GameState.historia.get("dialogos", {}).get("voss", []))
		"lucas":
			if not GameState.tem_flag("diretor_derrotado"):
				EventBus.mensagem.emit(
					"Lucas está preso ao Coração. Primeiro, derrote O Diretor.", 3.0
				)
				return
			GameState.definir_flag("lucas_encontrado")
			_falar(GameState.historia.get("dialogos", {}).get("lucas", []))
			if hud != null:
				hud.mostrar_escolha_final()
		"kit_forest", "kit_cidade":
			GameState.adicionar_item("kits", 1)
			_remover_acao(acao)
			EventBus.mensagem.emit("Kit médico adicionado ao inventário.", 2.4)
		"municao_cidade", "municao_complexo":
			GameState.adicionar_item("municao", 14)
			_remover_acao(acao)
			EventBus.mensagem.emit("Munição recuperada. Não desperdice os tiros.", 2.5)
		"bateria_forest", "bateria_complexo":
			GameState.adicionar_item("baterias", 1)
			jogador.bateria = minf(100.0, jogador.bateria + 55.0)
			_remover_acao(acao)
			EventBus.mensagem.emit("Bateria substituída. A lanterna voltou a carregar.", 2.8)
		_:
			if acao.begins_with("nota_"):
				var id_nota: int = int(acao.trim_prefix("nota_"))
				GameState.adicionar_nota(id_nota)
				_remover_acao(acao)
			else:
				EventBus.mensagem.emit(alvo.nome_exibido, 2.0)


func _falar(linhas: Array) -> void:
	if multiplayer.is_server():
		mostrar_dialogo_rede.rpc(linhas)
	else:
		mostrar_dialogo_rede(linhas)


@rpc("authority", "call_local", "reliable")
func mostrar_dialogo_rede(linhas: Array) -> void:
	if hud != null:
		hud.mostrar_dialogo(linhas)


func _remover_acao(acao: String) -> void:
	for peer: int in multiplayer.get_peers():
		rpc_id(peer, "remover_acao_remota", acao)
	remover_acao_remota(acao)


@rpc("authority", "call_remote", "reliable")
func remover_acao_remota(acao: String) -> void:
	for no: Node in get_tree().get_nodes_in_group("interactables"):
		if no is Interactable and (no as Interactable).acao == acao:
			no.queue_free()


func _teletransportar_jogador(jogador: PlayerController, destino: Vector3) -> void:
	jogador.global_position = destino
	jogador.velocity = Vector3.ZERO


func _iniciar_chefe() -> void:
	if _chefe != null or GameState.tem_flag("diretor_derrotado"):
		return
	_criar_chefe_rede.rpc()
	EventBus.mensagem.emit("DIRETOR VOSS: 'Mostre-me o seu medo.'", 4.0)
	EventBus.susto.emit(1.0)


@rpc("authority", "call_local", "reliable")
func _criar_chefe_rede() -> void:
	if _chefe != null:
		return
	_chefe = PanicMonster.new()
	_chefe.name = "O_Diretor"
	_chefe.is_boss = true
	_chefe.world = self
	_chefe.position = Vector3(840, -15.6, -14)
	add_child(_chefe)


func ao_derrotar_chefe(chefe: PanicMonster) -> void:
	if chefe != _chefe:
		return
	GameState.definir_flag("diretor_derrotado")
	EventBus.mensagem.emit("O Diretor cai. O reator perde o ritmo. Lucas está perto.", 5.0)
	EventBus.susto.emit(0.7)


func _tentar_surgimento() -> void:
	if not multiplayer.is_server() or _chefe != null:
		return
	var vivos: int = 0
	for filho: Node in get_children():
		if filho is PanicMonster and not (filho as PanicMonster).is_boss:
			vivos += 1
	if vivos >= mini(2 + GameState.dificuldade, 6):
		return
	var jogadores: Array[Node] = _jogadores.get_children()
	if jogadores.is_empty():
		return
	var jogador: PlayerController = jogadores.pick_random() as PlayerController
	if jogador == null:
		return
	var nova_posicao: Vector3 = (
		jogador.position + Vector3(randf_range(-24, 24), 0, randf_range(-24, 24))
	)
	var novo_tipo: String = ["esvaziado", "rastejante", "sombra"][randi_range(0, 2)]
	_criar_monstro_rede.rpc(randi(), nova_posicao, novo_tipo)
	if jogador.peer_id == multiplayer.get_unique_id():
		EventBus.mensagem.emit("Um galho estalou atrás de você.", 2.0)
		EventBus.susto.emit(0.25)


@rpc("authority", "call_local", "reliable")
func _criar_monstro_rede(id_monstro: int, posicao: Vector3, tipo_monstro: String) -> void:
	var monstro: PanicMonster = PanicMonster.new()
	monstro.name = "Esvaziado_%d" % id_monstro
	monstro.world = self
	monstro.tipo = StringName(tipo_monstro)
	monstro.position = posicao
	monstro.set_multiplayer_authority(1)
	add_child(monstro)


func aplicar_dano_jogador(id: int, dano: float) -> void:
	var jogador: Node = _jogadores.get_node_or_null("Ana_%d" % id)
	if jogador is PlayerController:
		(jogador as PlayerController).receber_dano(dano)


func _atualizar_regiao(pos: Vector3) -> void:
	if _ambiente == null or _ambiente.environment == null:
		return
	var destino: Color = Color(0.31, 0.38, 0.38)
	if pos.x > 150.0:
		destino = Color(0.36, 0.31, 0.25)
	if pos.x > 420.0:
		destino = Color(0.22, 0.34, 0.39)
	if pos.y < -10.0:
		destino = Color(0.43, 0.11, 0.13)
	_ambiente.environment.volumetric_fog_albedo = _ambiente.environment.volumetric_fog_albedo.lerp(
		destino, 0.025
	)
	if pos.x > 760.0:
		_luz_direcional.light_energy = 0.07
	else:
		_luz_direcional.light_energy = 0.28


func escolher_final(final: String) -> void:
	if final not in ["descanso", "eco"]:
		return
	if not multiplayer.is_server():
		_escolher_final_remoto.rpc_id(1, final)
		return
	_aplicar_final(final)


@rpc("any_peer", "reliable")
func _escolher_final_remoto(final: String) -> void:
	if (
		not multiplayer.is_server()
		or final not in ["descanso", "eco"]
		or not GameState.tem_flag("lucas_encontrado")
	):
		return
	_aplicar_final(final)


func _aplicar_final(final: String) -> void:
	GameState.final_escolhido = final
	GameState.definir_flag("final", final)
	var texto: String = str(GameState.historia.get("finais", {}).get(final, ""))
	mostrar_dialogo_rede.rpc([["ANA", texto]])
	SaveSystem.salvar()
	if hud != null:
		hud.finalizar_partida(texto)
