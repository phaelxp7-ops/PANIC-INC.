class_name PanicMonster
extends CharacterBody3D
## Perseguição server-side, silhueta humana texturizada e telegraph antes do ataque.

const MODELO: String = "res://assets/kenney_characters/characterMedium.fbx"
const MAPA_ZUMBI: String = "res://assets/kenney_characters/zombieA.png"
const ANIMACAO_IDLE: String = "res://assets/kenney_characters/idle.fbx"
const ANIMACAO_CORRER: String = "res://assets/kenney_characters/run.fbx"
const RAIO_PERCEPCAO: float = 28.0
const VELOCIDADE_TIPO: Dictionary = {
	"esvaziado": 1.85, "rastejante": 3.65, "estatua": 2.9, "sombra": 2.55
}

@export var tipo: StringName = &"esvaziado"
@export var is_boss: bool = false
var world: PanicWorld
var vida: float = 112.0
var fase: int = 1
var estado_ia: StringName = &"vagando"
var _alvo: PlayerController
var _tempo: float = 0.0
var _ataque: float = 1.2
var _dano_lanterna: float = 0.0
var _recuo: float = 0.0
var _modelo: Node3D
var _luz_olhos: OmniLight3D
var _pulso: float = 0.0
var _tempo_rede: float = 0.0
var _morto: bool = false
var _animacao: AnimationPlayer
var _animacao_idle: StringName = &""
var _animacao_corrida: StringName = &""


func _ready() -> void:
	add_to_group("monstros")
	if is_boss:
		vida = 280.0
		name = "O_Diretor"
	var colisao: CollisionShape3D = CollisionShape3D.new()
	var capsula: CapsuleShape3D = CapsuleShape3D.new()
	capsula.height = 2.0 if is_boss else 1.74
	capsula.radius = 0.4 if is_boss else 0.32
	colisao.shape = capsula
	colisao.position.y = capsula.height * 0.5
	add_child(colisao)
	_montar_visual()
	if is_boss:
		EventBus.mensagem.emit("A figura do Diretor atravessa a luz sem fazer sombra.", 3.2)


func _physics_process(delta: float) -> void:
	_tempo += delta
	_ataque -= delta
	if _modelo != null:
		_pulso += delta * (3.8 if is_boss else 2.4)
		_modelo.scale.y = (1.04 if is_boss else 1.0) + 0.012 * sin(_pulso)
		_modelo.rotation.z = lerpf(_modelo.rotation.z, 0.018 * sin(_pulso * 0.5), 0.04)
		_atualizar_animacao()
	if not multiplayer.is_server():
		return
	_tempo_rede += delta
	if _tempo_rede >= 0.08:
		_tempo_rede = 0.0
		_replicar_estado.rpc(global_position, rotation.y, vida, fase)
	_alvo = _achar_alvo()
	if _alvo == null:
		estado_ia = &"vagando"
		return
	var distancia: float = global_position.distance_to(_alvo.global_position)
	if distancia <= RAIO_PERCEPCAO:
		estado_ia = &"perseguindo"
		if tipo == &"estatua" and _alvo_esta_olhando():
			estado_ia = &"parado_sob_observacao"
			velocity = Vector3.ZERO
			return
		_perseguir(delta, distancia)
	else:
		estado_ia = &"vagando"
		velocity = Vector3.ZERO
	if distancia < (2.3 if is_boss else 1.55) and _ataque <= 0.0 and not _alvo.caido:
		_alvo.receber_dano(20.0 if is_boss else 12.0)
		_ataque = 1.25 if is_boss else 1.65
		_recuo = 0.34
	if _recuo > 0.0:
		_recuo -= delta
		velocity.x *= 0.4
		velocity.z *= 0.4
	if vida <= 0.0:
		_morrer()


func _achar_alvo() -> PlayerController:
	var alvo: PlayerController
	var menor: float = RAIO_PERCEPCAO
	for no: Node in get_tree().get_nodes_in_group("players"):
		if not no is PlayerController or (no as PlayerController).caido:
			continue
		var jogador: PlayerController = no as PlayerController
		var distancia: float = global_position.distance_to(jogador.global_position)
		if distancia < menor:
			menor = distancia
			alvo = jogador
	return alvo


func _perseguir(delta: float, _distancia: float) -> void:
	var vetor: Vector3 = _alvo.global_position - global_position
	vetor.y = 0.0
	if vetor.length_squared() < 0.001:
		return
	var direcao: Vector3 = vetor.normalized()
	var velocidade: float = float(VELOCIDADE_TIPO.get(String(tipo), 1.85))
	if is_boss:
		velocidade = 2.55
	if is_boss and fase == 3:
		velocidade = 4.8
	var zigue: float = sin(_tempo * 3.2) * 0.36 if tipo == &"rastejante" else 0.0
	var alvo_movimento: Vector3 = direcao + Vector3(direcao.z, 0, -direcao.x) * zigue
	velocity.x = move_toward(velocity.x, alvo_movimento.normalized().x * velocidade, 10.0 * delta)
	velocity.z = move_toward(velocity.z, alvo_movimento.normalized().z * velocidade, 10.0 * delta)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = -0.04
	look_at(
		Vector3(_alvo.global_position.x, global_position.y, _alvo.global_position.z), Vector3.UP
	)
	move_and_slide()
	if is_boss:
		var proxima_fase: int = 1 if vida > 196.0 else (2 if vida > 98.0 else 3)
		if proxima_fase != fase:
			fase = proxima_fase
			_transicao_fase()
	elif _alvo._usar_lanterna and _alvo.bateria > 0 and _dentro_do_feixe(_alvo):
		vida -= 1.5 * delta
		if tipo == &"sombra":
			vida -= 7.0 * delta


func _dentro_do_feixe(jogador: PlayerController) -> bool:
	var para_monstro: Vector3 = global_position + Vector3.UP - jogador.camera.global_position
	if para_monstro.length() > 22.0:
		return false
	var frente: Vector3 = -jogador.camera.global_basis.z
	if frente.dot(para_monstro.normalized()) < 0.90:
		return false
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		jogador.camera.global_position, global_position + Vector3.UP
	)
	query.exclude = [jogador.get_rid()]
	var resultado: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return resultado.is_empty() or resultado.get("collider") == self


func _alvo_esta_olhando() -> bool:
	if _alvo == null or _alvo.camera == null:
		return false
	var para_monstro: Vector3 = global_position + Vector3.UP - _alvo.camera.global_position
	if para_monstro.length() > 24.0:
		return false
	return (-_alvo.camera.global_basis.z).dot(para_monstro.normalized()) > 0.84


func receber_tiro(dano: float, feixe_lanterna: bool) -> void:
	if is_boss and not feixe_lanterna:
		EventBus.mensagem.emit("A bala atravessa a distorção. Revele-o com a lanterna.", 2.5)
		return
	vida -= dano
	_recuo = 0.38
	if is_boss:
		EventBus.mensagem.emit("O Diretor recua, mas o Coração o recompõe.", 1.4)


func _transicao_fase() -> void:
	EventBus.susto.emit(0.65)
	var chamadas: Array[String] = [
		"O Diretor abre os braços. A luz da arena morre.",
		"Ele surge atrás de você. Continue iluminando o rosto.",
		"O chão vibra: o Coração está chamando outros Esvaziados."
	]
	EventBus.mensagem.emit(chamadas[mini(fase - 1, chamadas.size() - 1)], 3.3)
	if fase == 2:
		global_position += Vector3(randf_range(-8, 8), 0, randf_range(-7, 7))
	if fase == 3 and world != null:
		world._criar_monstro_rede.rpc(randi(), global_position + Vector3(8, 0, 5), "rastejante")


func _montar_visual() -> void:
	_modelo = Node3D.new()
	_modelo.name = "SilhuetaTexturizada"
	_modelo.position.y = 0.0
	add_child(_modelo)
	var cena: PackedScene = load(MODELO) as PackedScene
	if cena != null:
		var corpo: Node3D = cena.instantiate() as Node3D
		if corpo != null:
			corpo.scale = Vector3(1.06, 1.11, 1.06) if is_boss else Vector3(1.0, 0.98, 1.0)
			_modelo.add_child(corpo)
			_aplicar_textura(corpo)
			_configurar_animacoes(corpo)
			# Silhueta curvada e braços baixos; evita a pose T enquanto a animação carrega.
			for no: Node in corpo.find_children("*", "Skeleton3D", true, false):
				var esqueleto: Skeleton3D = no as Skeleton3D
				for osso: int in range(esqueleto.get_bone_count()):
					var nome_osso: String = esqueleto.get_bone_name(osso).to_lower()
					# Não escreva rotações diretamente no Skeleton: isso sobrescrevia
					# a pose importada e deixava o rig em T-pose/torções incorretas.
					if "arm" in nome_osso or "shoulder" in nome_osso:
						esqueleto.set_bone_pose_rotation(osso, Quaternion.IDENTITY)
	var mat_olho: StandardMaterial3D = StandardMaterial3D.new()
	mat_olho.albedo_color = Color(0.95, 0.04, 0.015)
	mat_olho.emission_enabled = true
	mat_olho.emission = Color(1.0, 0.025, 0.005)
	mat_olho.emission_energy_multiplier = 2.8
	for lado: float in [-0.11, 0.11]:
		var olho: MeshInstance3D = MeshInstance3D.new()
		var esfera: SphereMesh = SphereMesh.new()
		esfera.radius = 0.042 if not is_boss else 0.065
		esfera.height = esfera.radius * 2.0
		olho.mesh = esfera
		olho.position = Vector3(lado, 1.55 if not is_boss else 1.79, -0.28)
		olho.material_override = mat_olho
		_modelo.add_child(olho)
	_luz_olhos = OmniLight3D.new()
	_luz_olhos.light_color = Color(0.76, 0.015, 0.008)
	_luz_olhos.light_energy = 0.32
	_luz_olhos.omni_range = 1.8 if is_boss else 0.9
	_luz_olhos.position = Vector3(0, 1.55, -0.4)
	_modelo.add_child(_luz_olhos)
	if tipo == &"sombra":
		var nevoa: MeshInstance3D = MeshInstance3D.new()
		var aura: SphereMesh = SphereMesh.new()
		aura.radius = 0.72
		aura.height = 2.0
		nevoa.mesh = aura
		var sombra: StandardMaterial3D = StandardMaterial3D.new()
		sombra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sombra.albedo_color = Color(0.025, 0.018, 0.04, 0.23)
		sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		nevoa.material_override = sombra
		nevoa.position.y = 0.92
		_modelo.add_child(nevoa)


func _configurar_animacoes(corpo: Node3D) -> void:
	_animacao = corpo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animacao == null:
		return
	var cena_idle: PackedScene = load(ANIMACAO_IDLE) as PackedScene
	var cena_run: PackedScene = load(ANIMACAO_CORRER) as PackedScene
	var idle_root: Node = cena_idle.instantiate() if cena_idle != null else null
	var run_root: Node = cena_run.instantiate() if cena_run != null else null
	var idle_player: AnimationPlayer = (
		idle_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if idle_root != null else null
	)
	var run_player: AnimationPlayer = (
		run_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if run_root != null else null
	)
	if idle_player != null:
		_animacao_idle = _copiar_animacao(idle_player, "idle")
	if run_player != null:
		_animacao_corrida = _copiar_animacao(run_player, "run")
	if idle_root != null:
		idle_root.free()
	if run_root != null:
		run_root.free()
	if not _animacao_idle.is_empty():
		_animacao.play(_animacao_idle)


func _copiar_animacao(origem: AnimationPlayer, prefixo: String) -> StringName:
	for nome: StringName in origem.get_animation_list():
		var biblioteca: AnimationLibrary = origem.get_animation_library("")
		var copia: Animation = biblioteca.get_animation(nome).duplicate() as Animation
		var destino: StringName = StringName(prefixo + "_" + String(nome))
		var biblioteca_destino: AnimationLibrary = _animacao.get_animation_library("")
		if biblioteca_destino == null:
			biblioteca_destino = AnimationLibrary.new()
			_animacao.add_animation_library("", biblioteca_destino)
		if biblioteca_destino.has_animation(destino):
			biblioteca_destino.remove_animation(destino)
		biblioteca_destino.add_animation(destino, copia)
		return destino
	return &""


func _atualizar_animacao() -> void:
	if _animacao == null:
		return
	var andando: bool = Vector2(velocity.x, velocity.z).length() > 0.35
	var desejada: StringName = _animacao_corrida if andando else _animacao_idle
	if not desejada.is_empty() and _animacao.current_animation != desejada:
		_animacao.play(desejada, 0.18)


func _aplicar_textura(no: Node) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = load(MAPA_ZUMBI) as Texture2D
	material.roughness = 0.9
	material.metallic = 0.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if no is MeshInstance3D:
		var mesh_instance: MeshInstance3D = no as MeshInstance3D
		if mesh_instance.mesh != null:
			for superficie: int in range(mesh_instance.mesh.get_surface_count()):
				mesh_instance.set_surface_override_material(superficie, material)
	for filho: Node in no.get_children():
		_aplicar_textura(filho)


func _morrer() -> void:
	if _morto:
		return
	_morto = true
	if is_boss:
		if world != null:
			world.ao_derrotar_chefe(self)
	else:
		if randf() < 0.28:
			GameState.adicionar_item("municao", 3)
	_remover_rede.rpc()


@rpc("authority", "call_remote", "unreliable_ordered")
func _replicar_estado(posicao: Vector3, yaw: float, vida_atual: float, fase_atual: int) -> void:
	global_position = posicao
	rotation.y = yaw
	vida = vida_atual
	fase = fase_atual


@rpc("authority", "call_local", "reliable")
func _remover_rede() -> void:
	queue_free()
