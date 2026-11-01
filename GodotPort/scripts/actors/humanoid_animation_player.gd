class_name HumanoidAnimationPlayer
extends AnimationPlayer
## State machine leve, dirigida pelo movimento, para rigs Kenney com ossos idênticos.

const CENA_IDLE: String = "res://assets/kenney_characters/idle.fbx"
const CENA_CORRER: String = "res://assets/kenney_characters/run.fbx"
const TRANSICAO: float = 0.18

var _esqueleto: Skeleton3D
var _clips: Dictionary = {}
var _estado: StringName = &""
var _locomocao: StringName = &"idle"


func configurar(rig_root: Node3D) -> bool:
	_esqueleto = rig_root.find_child("Skeleton3D", true, false) as Skeleton3D
	if _esqueleto == null:
		push_warning("HumanoidAnimationPlayer: o modelo não possui Skeleton3D.")
		return false
	# O AnimationPlayer fica ao lado de Root. Os FBX Kenney usam caminhos
	# Root/Skeleton3D:Bone e compartilham os mesmos 57 ossos.
	root_node = NodePath("..")
	var idle: Animation = _obter_clipe(CENA_IDLE, "idle")
	var corrida: Animation = _obter_clipe(CENA_CORRER, "run")
	if idle == null or corrida == null:
		push_warning("HumanoidAnimationPlayer: clipes Idle/Run não carregaram no rig.")
		return false
	if not _caminhos_compativeis(idle) or not _caminhos_compativeis(corrida):
		push_warning("HumanoidAnimationPlayer: animação não é compatível com o Skeleton3D.")
		return false
	idle = _relaxar_pose_idle(idle)
	idle.loop_mode = Animation.LOOP_LINEAR
	corrida.loop_mode = Animation.LOOP_LINEAR
	animation_finished.connect(_ao_terminar_clipe)
	_adicionar_clipe(&"idle", idle)
	_adicionar_clipe(&"run", corrida)
	_adicionar_clipe(&"walk", _retimar(corrida, 1.48))
	_adicionar_clipe(&"crouch", _ajustar_agachado(idle))
	_adicionar_clipe(&"crouch_walk", _ajustar_agachado(_retimar(corrida, 1.75)))
	_adicionar_clipe(&"turn", _clipe_de_acao(idle, "turn"))
	_adicionar_clipe(&"interact", _clipe_de_acao(idle, "interact"))
	_adicionar_clipe(&"combat", _clipe_de_acao(idle, "combat"))
	play_state(&"idle", true)
	return true


func atualizar_locomocao(andando: bool, correndo: bool, agachado: bool) -> void:
	if agachado:
		_locomocao = &"crouch_walk" if andando else &"crouch"
	elif andando:
		_locomocao = &"run" if correndo else &"walk"
	else:
		_locomocao = &"idle"
	if not _estado in [&"interact", &"combat"]:
		play_state(_locomocao)


func play_state(nome: StringName, imediato: bool = false) -> void:
	var clipe: StringName = nome
	if not _clips.has(clipe):
		clipe = &"idle"
	if _estado == clipe and is_playing():
		return
	_estado = clipe
	speed_scale = 0.72 if clipe in [&"walk", &"crouch_walk"] else 1.0
	play(clipe, 0.0 if imediato else TRANSICAO)


func acionar(nome: StringName) -> void:
	if nome not in [&"turn", &"interact", &"combat"] or not _clips.has(nome):
		return
	_estado = nome
	speed_scale = 1.0
	play(nome, TRANSICAO)


func _obter_clipe(caminho: String, esperado: String) -> Animation:
	var packed: PackedScene = load(caminho) as PackedScene
	if packed == null:
		return null
	var origem_root: Node = packed.instantiate()
	var origem: AnimationPlayer = (
		origem_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	)
	if origem == null:
		origem_root.free()
		return null
	var selecionado: Animation
	for nome: StringName in origem.get_animation_list():
		# Os FBX importam primeiro um clipe de um frame chamado "0_Targeting Pose";
		# ele é literalmente uma pose de rig e era escolhido pelo código antigo.
		if String(nome).to_lower().ends_with(esperado):
			selecionado = _copiar_clipe(origem.get_animation(nome))
			break
	origem_root.free()
	return selecionado


func _caminhos_compativeis(animacao: Animation) -> bool:
	var trilhas_osso: int = 0
	for indice: int in range(animacao.get_track_count()):
		var caminho: NodePath = animacao.track_get_path(indice)
		if caminho.get_subname_count() == 0:
			continue
		var osso: StringName = caminho.get_subname(caminho.get_subname_count() - 1)
		if _esqueleto.find_bone(osso) < 0:
			return false
		trilhas_osso += 1
	return trilhas_osso >= 30


func _adicionar_clipe(nome: StringName, animacao: Animation) -> void:
	if not has_animation_library(&""):
		add_animation_library(&"", AnimationLibrary.new())
	var biblioteca: AnimationLibrary = get_animation_library(&"")
	if biblioteca.has_animation(nome):
		biblioteca.remove_animation(nome)
	biblioteca.add_animation(nome, animacao)
	_clips[nome] = nome


func _retimar(origem: Animation, fator: float) -> Animation:
	var animacao: Animation = _copiar_clipe(origem, fator)
	animacao.loop_mode = Animation.LOOP_LINEAR
	return animacao


func _ajustar_agachado(origem: Animation) -> Animation:
	var animacao: Animation = _copiar_clipe(origem)
	# Ajusta pelvis, quadris e joelhos como um clipe esquelético completo; os braços
	# continuam vindo do Idle/Run real, sem set_bone_pose manual por frame.
	_deslocar_trilha_de_posicao(animacao, &"HipsCtrl", Vector3(0.0, -0.20, 0.0))
	_girar_trilha(animacao, &"LeftUpLeg", Vector3.RIGHT, -0.32)
	_girar_trilha(animacao, &"RightUpLeg", Vector3.RIGHT, -0.32)
	_girar_trilha(animacao, &"LeftLeg", Vector3.RIGHT, 0.72)
	_girar_trilha(animacao, &"RightLeg", Vector3.RIGHT, 0.72)
	_girar_trilha(animacao, &"Spine", Vector3.RIGHT, 0.10)
	animacao.loop_mode = Animation.LOOP_LINEAR
	return animacao


func _relaxar_pose_idle(origem: Animation) -> Animation:
	# O Idle distribuído com o rig preserva os braços quase na horizontal. Corrige
	# os canais do próprio Skeleton3D (ombro, braço, antebraço e mão) e mantém a
	# animação corporal original ativa em loop; walk/run continuam usando o clipe FBX.
	var animacao: Animation = _copiar_clipe(origem)
	_girar_trilha(animacao, &"LeftShoulder", Vector3.RIGHT, -0.08)
	_girar_trilha(animacao, &"RightShoulder", Vector3.FORWARD, -0.08)
	_girar_trilha(animacao, &"LeftArm", Vector3.RIGHT, -0.95)
	_girar_trilha(animacao, &"RightArm", Vector3.FORWARD, -1.25)
	_girar_trilha(animacao, &"LeftForeArm", Vector3.RIGHT, -0.28)
	_girar_trilha(animacao, &"RightForeArm", Vector3.FORWARD, -0.25)
	_girar_trilha(animacao, &"LeftHand", Vector3.RIGHT, -0.06)
	_girar_trilha(animacao, &"RightHand", Vector3.FORWARD, -0.05)
	_girar_trilha(animacao, &"Neck", Vector3.RIGHT, 0.025)
	return animacao


func _clipe_de_acao(origem: Animation, acao: String) -> Animation:
	var animacao: Animation = _copiar_clipe(origem)
	animacao.loop_mode = Animation.LOOP_NONE
	match acao:
		"turn":
			_girar_trilha(animacao, &"Neck", Vector3.UP, 0.24)
			_girar_trilha(animacao, &"UpperChest", Vector3.UP, 0.10)
		"interact":
			_girar_trilha(animacao, &"RightArm", Vector3.RIGHT, -0.48)
			_girar_trilha(animacao, &"RightForeArm", Vector3.RIGHT, -0.72)
		"combat":
			_girar_trilha(animacao, &"RightArm", Vector3.RIGHT, -0.24)
			_girar_trilha(animacao, &"RightForeArm", Vector3.RIGHT, -0.42)
	return animacao


func _deslocar_trilha_de_posicao(animacao: Animation, osso: StringName, delta: Vector3) -> void:
	var indice: int = _indice_trilha(animacao, osso, Animation.TYPE_POSITION_3D)
	if indice < 0:
		return
	for chave: int in range(animacao.track_get_key_count(indice)):
		var valor: Vector3 = animacao.track_get_key_value(indice, chave)
		animacao.track_set_key_value(indice, chave, valor + delta)


func _girar_trilha(
	animacao: Animation, osso: StringName, eixo: Vector3, angulo: float
) -> void:
	var indice: int = _indice_trilha(animacao, osso, Animation.TYPE_ROTATION_3D)
	if indice < 0:
		return
	var ajuste: Quaternion = Quaternion(eixo.normalized(), angulo)
	for chave: int in range(animacao.track_get_key_count(indice)):
		var valor: Quaternion = animacao.track_get_key_value(indice, chave)
		animacao.track_set_key_value(indice, chave, (valor * ajuste).normalized())


func _indice_trilha(animacao: Animation, osso: StringName, tipo: Animation.TrackType) -> int:
	for indice: int in range(animacao.get_track_count()):
		var caminho: NodePath = animacao.track_get_path(indice)
		if (
			caminho.get_subname_count() > 0
			and caminho.get_subname(caminho.get_subname_count() - 1) == osso
			and animacao.track_get_type(indice) == tipo
		):
			return indice
	return -1


func _ao_terminar_clipe(nome: StringName) -> void:
	if nome in [&"turn", &"interact", &"combat"]:
		_estado = &""
		play_state(_locomocao)


func _copiar_clipe(origem: Animation, escala_tempo: float = 1.0) -> Animation:
	# FBX imports may store optimized typed key arrays. Rebuilding tracks avoids
	# mutating those shared compressed arrays when deriving Walk/Crouch/action clips.
	var copia: Animation = Animation.new()
	copia.length = origem.length * escala_tempo
	copia.loop_mode = origem.loop_mode
	for trilha: int in range(origem.get_track_count()):
		var destino: int = copia.add_track(origem.track_get_type(trilha))
		copia.track_set_path(destino, origem.track_get_path(trilha))
		copia.track_set_interpolation_type(destino, origem.track_get_interpolation_type(trilha))
		copia.track_set_interpolation_loop_wrap(
			destino, origem.track_get_interpolation_loop_wrap(trilha)
		)
		copia.track_set_enabled(destino, origem.track_is_enabled(trilha))
		for chave: int in range(origem.track_get_key_count(trilha)):
			copia.track_insert_key(
				destino,
				origem.track_get_key_time(trilha, chave) * escala_tempo,
				origem.track_get_key_value(trilha, chave)
			)
	return copia
