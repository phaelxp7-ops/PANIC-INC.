class_name PlayerController
extends CharacterBody3D
## O servidor simula o movimento recebido como intenção e valida combate/interações.

const CENA_HUMANO: String = "res://assets/kenney_characters/characterMedium.fbx"
const TEXTURA_ANA: String = "res://assets/kenney_characters/survivorFemaleA.png"
const ALTURA: float = 1.74

@export var vida: float = 100.0
@export var sanidade: float = 100.0
@export var bateria: float = 100.0
@export var stamina: float = 100.0
@export var municao: int = 6
@export var tem_revolver: bool = false
@export var caido: bool = false
var peer_id: int = 1
var world: PanicWorld
var camera: Camera3D
var pivot_camera: Node3D
var lanterna: SpotLight3D
var nome_jogador: String = "Ana"
var lanternada: bool = true
var _visual: Node3D
var _intencao: Vector2 = Vector2.ZERO
var _yaw: float = 0.0
var _pitch: float = -0.16
var _correndo: bool = false
var _agachado: bool = false
var _usar_lanterna: bool = true
var _temporizador_sync: float = 0.0
var _temporizador_bateria: float = 0.0
var _temporizador_passos: float = 0.0
var _temporizador_intencao: float = 0.0
var _tempo_animacao: float = 0.0
var _sistema_audio: AudioStreamPlayer3D


func _ready() -> void:
	if peer_id == 1:
		# Começa olhando para a cabana de Marta, no leste da floresta.
		_yaw = -PI * 0.5
		rotation.y = _yaw
	add_to_group("players")
	_montar_colisao()
	_montar_personagem()
	_montar_camera_e_lanterna()
	_montar_audio()
	_montar_sincronizacao()
	if peer_id == multiplayer.get_unique_id():
		camera.current = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false

	if multiplayer.is_server() and peer_id == 1:
		municao = 6


func _unhandled_input(evento: InputEvent) -> void:
	if peer_id != multiplayer.get_unique_id():
		return
	if evento is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse: InputEventMouseMotion = evento as InputEventMouseMotion
		_yaw -= mouse.relative.x * Settings.sensibilidade_mouse
		_pitch = clampf(_pitch + mouse.relative.y * Settings.sensibilidade_mouse, -0.88, 0.72)
		rotation.y = _yaw
		pivot_camera.rotation.x = _pitch
	if evento.is_action_pressed("pausar"):
		if world.hud != null:
			world.hud.alternar_pausa()
	if evento.is_action_pressed("diario") and world.hud != null:
		world.hud.alternar_diario()
	if evento.is_action_pressed("mapa") and world.hud != null:
		world.hud.alternar_mapa()
	if evento.is_action_pressed("alternar_camera"):
		_alternar_perspectiva()
	if evento.is_action_pressed("lanterna"):
		_alternar_lanterna()
	if evento.is_action_pressed("interagir") and world.hud != null and not world.hud.dialogo_ativo:
		world.solicitar_interacao(self)
	if evento.is_action_pressed("atirar"):
		_solicitar_tiro()
	if evento.is_action_pressed("recarregar"):
		_recarregar()
	if evento.is_action_pressed("ping"):
		world.solicitar_ping(self)
	if evento.is_action_pressed("curar"):
		_usar_cura()
	if evento.is_action_pressed("calmante"):
		_usar_calmante()
	if (
		evento is InputEventKey
		and (evento as InputEventKey).keycode == KEY_ENTER
		and world.hud != null
		and world.hud.dialogo_ativo
	):
		world.hud.avancar_dialogo()
	if (
		evento is InputEventMouseButton
		and (evento as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
		and world.hud != null
		and world.hud.dialogo_ativo
	):
		world.hud.avancar_dialogo()


func _physics_process(delta: float) -> void:
	if peer_id == multiplayer.get_unique_id():
		_ler_intencao()
		if not multiplayer.is_server():
			_temporizador_intencao += delta
			if _temporizador_intencao >= 0.06:
				_temporizador_intencao = 0.0
				_enviar_intencao()
	if multiplayer.is_server() or peer_id == multiplayer.get_unique_id():
		_simular_movimento(delta)
	if multiplayer.is_server():
		_temporizadores_servidor(delta)
		_temporizador_sync += delta
		if _temporizador_sync >= 0.08:
			_temporizador_sync = 0.0
			_sincronizar_estado.rpc(
				global_position,
				_yaw,
				_pitch,
				vida,
				sanidade,
				bateria,
				stamina,
				_usar_lanterna,
				caido
			)
	if peer_id == multiplayer.get_unique_id():
		_atualizar_necessidades(delta)
		if peer_id == 1:
			GameState.vida = vida
			GameState.sanidade = sanidade
			GameState.bateria = bateria
			GameState.stamina = stamina


func _ler_intencao() -> void:
	if (
		world.hud != null
		and (
			world.hud.dialogo_ativo
			or world.hud.pausa_ativa
			or world.hud.diario_ativo
			or world.hud.mapa_ativo
		)
	):
		_intencao = Vector2.ZERO
		_correndo = false
		_agachado = false
		return
	_intencao = Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
	_correndo = Input.is_action_pressed("correr") and stamina > 1.0 and _intencao.length() > 0.2
	_agachado = Input.is_action_pressed("agachar")


func _enviar_intencao() -> void:
	_enviar_intencao_remota.rpc_id(
		1, peer_id, _intencao, _yaw, _pitch, _correndo, _agachado, _usar_lanterna
	)


@rpc("any_peer", "unreliable_ordered")
func _enviar_intencao_remota(
	id: int,
	movimento: Vector2,
	yaw: float,
	pitch: float,
	correr: bool,
	agachar: bool,
	lanterna_ativa: bool
) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != id or id != peer_id:
		return
	_intencao = movimento.limit_length(1.0)
	_yaw = yaw
	_pitch = clampf(pitch, -0.88, 0.72)
	_correndo = correr
	_agachado = agachar
	_usar_lanterna = lanterna_ativa
	rotation.y = _yaw
	if lanterna != null:
		lanterna.visible = _usar_lanterna and bateria > 0.0


@rpc("authority", "call_remote", "unreliable_ordered")
func _sincronizar_estado(
	pos: Vector3,
	yaw: float,
	pitch: float,
	hp: float,
	mente: float,
	carga: float,
	folego: float,
	lanterna_ativa: bool,
	derrubado: bool
) -> void:
	if peer_id == multiplayer.get_unique_id():
		global_position = global_position.lerp(pos, 0.45)
	else:
		global_position = pos
	_yaw = yaw
	rotation.y = yaw
	_pitch = pitch
	pivot_camera.rotation.x = pitch
	vida = hp
	sanidade = mente
	bateria = carga
	stamina = folego
	caido = derrubado
	_usar_lanterna = lanterna_ativa
	lanterna.visible = lanterna_ativa and carga > 0.0


func _simular_movimento(delta: float) -> void:
	if caido:
		velocity = Vector3.ZERO
		return
	var frente: Vector3 = Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var direita: Vector3 = Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var direcao: Vector3 = (direita * _intencao.x + frente * -_intencao.y).normalized()
	var velocidade_base: float = 2.15 if _agachado else (5.15 if _correndo else 3.25)
	var destino: Vector3 = direcao * velocidade_base
	velocity.x = move_toward(velocity.x, destino.x, 18.0 * delta)
	velocity.z = move_toward(velocity.z, destino.z, 18.0 * delta)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.05
	move_and_slide()
	if _visual != null:
		_tempo_animacao += delta * (10.0 if _correndo else 6.0)
		var velocidade_horizontal: float = Vector2(velocity.x, velocity.z).length()
		_visual.position.y = sin(_tempo_animacao) * 0.035 * minf(velocidade_horizontal, 4.0)
		_visual.rotation.z = lerpf(_visual.rotation.z, -_intencao.x * 0.05, 0.12)
	if direcao.length() > 0.1:
		_temporizador_passos += delta
		var intervalo: float = 0.31 if _correndo else 0.52
		if _temporizador_passos >= intervalo:
			_temporizador_passos = 0.0
			_tocar_passo()
	else:
		_temporizador_passos = 0.0


func _temporizadores_servidor(delta: float) -> void:
	if _usar_lanterna and bateria > 0.0:
		_temporizador_bateria += delta
		if _temporizador_bateria >= 1.0:
			_temporizador_bateria = 0.0
			bateria = maxf(0.0, bateria - 1.0)
			if bateria <= 0.0:
				_usar_lanterna = false
				lanterna.visible = false
				if peer_id == multiplayer.get_unique_id():
					EventBus.mensagem.emit("A bateria da lanterna acabou.", 3.0)
	if _correndo and _intencao.length() > 0.1:
		stamina = maxf(0.0, stamina - 23.0 * delta)
	else:
		stamina = minf(100.0, stamina + 15.0 * delta)
	if multiplayer.is_server():
		var perto_de_inimigo: bool = false
		for no: Node in get_tree().get_nodes_in_group("monstros"):
			if no is PanicMonster and global_position.distance_to(no.global_position) < 16.0:
				perto_de_inimigo = true
				break
		var aliado_perto: bool = false
		for no: Node in get_tree().get_nodes_in_group("players"):
			if (
				no is PlayerController
				and no != self
				and global_position.distance_to(no.global_position) < 8.0
			):
				aliado_perto = true
				break
		if perto_de_inimigo:
			sanidade = maxf(0.0, sanidade - (0.42 if aliado_perto else 0.72) * delta)
		elif not _usar_lanterna:
			sanidade = maxf(0.0, sanidade - 0.12 * delta)
		else:
			sanidade = minf(100.0, sanidade + 0.06 * delta)
	if sanidade <= 0.0:
		if randf() < delta * 0.6:
			EventBus.susto.emit(0.48)
			EventBus.mensagem.emit("Você ouviu Lucas chamar seu nome. Ele não está aqui.", 3.2)


func _atualizar_necessidades(delta: float) -> void:
	if multiplayer.is_server() and peer_id == 1:
		GameState.tempo_jogo += delta


func _montar_colisao() -> void:
	var forma: CollisionShape3D = CollisionShape3D.new()
	var capsula: CapsuleShape3D = CapsuleShape3D.new()
	capsula.height = ALTURA
	capsula.radius = 0.34
	forma.shape = capsula
	forma.position.y = ALTURA * 0.5
	add_child(forma)


func _montar_personagem() -> void:
	_visual = Node3D.new()
	_visual.name = "ModeloHumano"
	_visual.position.y = 0.0
	add_child(_visual)
	var cena: PackedScene = load(CENA_HUMANO) as PackedScene
	if cena != null:
		var modelo: Node3D = cena.instantiate() as Node3D
		if modelo != null:
			modelo.position.y = -0.02
			modelo.scale = Vector3.ONE
			_visual.add_child(modelo)
			_aplicar_textura(modelo, TEXTURA_ANA)
			return
	push_warning(
		"Modelo Kenney não importado; usando silhueta temporária. Verifique assets/kenney_characters."
	)
	var fallback: MeshInstance3D = MeshInstance3D.new()
	var malha: CapsuleMesh = CapsuleMesh.new()
	malha.radius = 0.31
	malha.height = 1.55
	fallback.mesh = malha
	fallback.position.y = 0.83
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.27, 0.29)
	fallback.material_override = material
	_visual.add_child(fallback)


func _aplicar_textura(modelo: Node, caminho: String) -> void:
	var textura: Texture2D = load(caminho) as Texture2D
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = textura
	material.roughness = 0.82
	material.metallic = 0.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_aplicar_material_recursivo(modelo, material)


func _aplicar_material_recursivo(no: Node, material: StandardMaterial3D) -> void:
	if no is MeshInstance3D:
		var malha: MeshInstance3D = no as MeshInstance3D
		for superficie: int in range(malha.mesh.get_surface_count() if malha.mesh != null else 0):
			malha.set_surface_override_material(superficie, material)
	for filho: Node in no.get_children():
		_aplicar_material_recursivo(filho, material)


func _montar_camera_e_lanterna() -> void:
	pivot_camera = Node3D.new()
	pivot_camera.name = "CameraPivot"
	pivot_camera.position.y = 1.56
	pivot_camera.rotation.x = _pitch
	add_child(pivot_camera)
	camera = Camera3D.new()
	camera.name = "CameraPrimeiraPessoa"
	camera.position = Vector3(0.0, 0.0, 0.04)
	camera.fov = 72.0
	camera.near = 0.08
	camera.far = 180.0
	if world != null and world._ambiente != null:
		camera.environment = world._ambiente.environment
	pivot_camera.add_child(camera)
	_visual.visible = false
	var ponto: Node3D = Node3D.new()
	ponto.position = Vector3(0.23, -0.12, -0.12)
	pivot_camera.add_child(ponto)
	lanterna = SpotLight3D.new()
	lanterna.name = "FeixeDaLanterna"
	lanterna.position = Vector3(0, 0, -0.24)
	lanterna.rotation_degrees = Vector3(-4, 0, 0)
	lanterna.light_color = Color(0.80, 0.89, 1.0)
	lanterna.light_energy = 5.2
	lanterna.spot_range = 25.0
	lanterna.spot_angle = 28.0
	lanterna.spot_angle_attenuation = 1.1
	lanterna.shadow_enabled = true
	lanterna.visible = true
	ponto.add_child(lanterna)
	var arma: MeshInstance3D = MeshInstance3D.new()
	var cano: CylinderMesh = CylinderMesh.new()
	cano.top_radius = 0.035
	cano.bottom_radius = 0.055
	cano.height = 0.36
	arma.mesh = cano
	arma.rotation.x = PI / 2.0
	arma.position = Vector3(0.30, -0.24, -0.4)
	var metal: StandardMaterial3D = StandardMaterial3D.new()
	metal.albedo_color = Color(0.12, 0.15, 0.17)
	metal.metallic = 0.72
	metal.roughness = 0.29
	arma.material_override = metal
	pivot_camera.add_child(arma)


func _montar_audio() -> void:
	_sistema_audio = AudioStreamPlayer3D.new()
	_sistema_audio.max_distance = 36.0
	_sistema_audio.unit_size = 6.0
	_sistema_audio.bus = "SFX"
	add_child(_sistema_audio)


func _montar_sincronizacao() -> void:
	var replicador: MultiplayerSynchronizer = MultiplayerSynchronizer.new()
	replicador.name = "Sincronizador"
	var configuracao: SceneReplicationConfig = SceneReplicationConfig.new()
	configuracao.add_property(NodePath(".:vida"))
	configuracao.add_property(NodePath(".:sanidade"))
	configuracao.add_property(NodePath(".:bateria"))
	configuracao.add_property(NodePath(".:stamina"))
	configuracao.add_property(NodePath(".:caido"))
	configuracao.add_property(NodePath(".:municao"))
	configuracao.add_property(NodePath(".:tem_revolver"))
	replicador.replication_config = configuracao
	add_child(replicador)


func _tocar_passo() -> void:
	if _sistema_audio == null:
		return
	if ResourceLoader.exists("res://assets/audio/passo.wav"):
		_sistema_audio.stream = load("res://assets/audio/passo.wav") as AudioStream
		_sistema_audio.pitch_scale = randf_range(0.9, 1.08) * (1.1 if _correndo else 0.94)
		_sistema_audio.play()


func _alternar_perspectiva() -> void:
	var primeira_pessoa: bool = camera.position.z > 1.0
	camera.position = (Vector3(0, 0.0, 0.04) if primeira_pessoa else Vector3(0.9, 0.45, 5.8))
	if _visual != null:
		_visual.visible = not primeira_pessoa


func _alternar_lanterna() -> void:
	if bateria <= 0.0:
		EventBus.mensagem.emit("Sem bateria. Procure uma reposição.", 2.0)
		return
	_usar_lanterna = not _usar_lanterna
	lanterna.visible = _usar_lanterna


func _solicitar_tiro() -> void:
	if (
		peer_id != multiplayer.get_unique_id()
		or world.hud.dialogo_ativo
		or world.hud.pausa_ativa
		or world.hud.diario_ativo
	):
		return
	if multiplayer.is_server():
		_executar_tiro()
	else:
		_solicitar_tiro_remoto.rpc_id(1, peer_id, _yaw, _pitch, _usar_lanterna)


@rpc("any_peer", "reliable")
func _solicitar_tiro_remoto(id: int, yaw: float, pitch: float, lanterna_ativa: bool) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != id or id != peer_id:
		return
	_yaw = yaw
	_pitch = pitch
	_usar_lanterna = lanterna_ativa
	_executar_tiro()


func _executar_tiro() -> void:
	if caido:
		return
	if not tem_revolver:
		EventBus.mensagem.emit("Marta ainda não entregou o revólver.", 2.0)
		return
	if municao <= 0:
		if peer_id == multiplayer.get_unique_id():
			EventBus.mensagem.emit("Revólver vazio. R para recarregar.", 2.0)
		return
	municao -= 1
	var origem: Vector3 = camera.global_position
	var fim: Vector3 = origem - camera.global_basis.z * 60.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origem, fim)
	query.exclude = [get_rid()]
	query.collision_mask = 7
	var resultado: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if resultado.has("collider") and resultado["collider"] is PanicMonster:
		(resultado["collider"] as PanicMonster).receber_tiro(42.0, _usar_lanterna)
	if peer_id == multiplayer.get_unique_id():
		EventBus.susto.emit(0.05)


func _recarregar() -> void:
	if not multiplayer.is_server():
		_solicitar_item_remoto.rpc_id(1, "recarregar")
		return
	_recarregar_servidor()


func _recarregar_servidor() -> void:
	var reserva: int = int(GameState.inventario.get("municao", 0))
	if reserva < 1:
		EventBus.mensagem.emit("Você não tem munição no inventário.", 2.2)
		return
	var quantidade: int = mini(6 - municao, reserva)
	if quantidade <= 0:
		EventBus.mensagem.emit("O tambor já está cheio.", 1.8)
		return
	municao += quantidade
	GameState.inventario["municao"] = reserva - quantidade
	GameState._emitir_estado()
	EventBus.mensagem.emit("Revólver recarregado: %d balas." % municao, 1.8)


func _usar_cura() -> void:
	if not multiplayer.is_server():
		_solicitar_item_remoto.rpc_id(1, "kits")
		return
	_usar_item_servidor("kits")


func _usar_calmante() -> void:
	if not multiplayer.is_server():
		_solicitar_item_remoto.rpc_id(1, "calmantes")
		return
	_usar_item_servidor("calmantes")


@rpc("any_peer", "reliable")
func _solicitar_item_remoto(item: String) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != peer_id:
		return
	if item == "recarregar":
		_recarregar_servidor()
	elif item in ["kits", "calmantes"]:
		_usar_item_servidor(item)


func _usar_item_servidor(item: String) -> void:
	if not GameState.gastar_item(item, 1):
		if peer_id == multiplayer.get_unique_id():
			EventBus.mensagem.emit("Você não tem " + item + " no inventário.", 2.0)
		return
	if item == "kits":
		vida = minf(100.0, vida + 45.0)
		EventBus.mensagem.emit("Kit aplicado. A respiração ainda está irregular.", 2.0)
	else:
		sanidade = minf(100.0, sanidade + 38.0)
		EventBus.mensagem.emit("As mãos param de tremer por alguns segundos.", 2.0)


func receber_dano(valor: float) -> void:
	if caido:
		return
	vida = maxf(0.0, vida - valor)
	if vida <= 0.0:
		caido = true
		EventBus.jogador_derrotado.emit(peer_id)
		if peer_id == multiplayer.get_unique_id():
			EventBus.mensagem.emit("Você caiu. Um aliado pode reviver você com E.", 5.0)


func reviver() -> void:
	caido = false
	vida = 42.0
	global_position.y += 0.2
	EventBus.mensagem.emit("Você voltou. Permaneçam juntos.", 2.8)
