extends Node
## Preferências locais persistentes; preset padrão é Baixo para a GPU integrada.

const CAMINHO: String = "user://preferencias.cfg"
var qualidade: String = "Baixo"
var sensibilidade_mouse: float = 0.0024
var volume_mestre: float = 0.8
var modo_tela: String = "janela"
var mostrar_fps: bool = true


func _ready() -> void:
	_carregar()
	_criar_controles()


func _carregar() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CAMINHO) == OK:
		qualidade = str(config.get_value("video", "qualidade", qualidade))
		sensibilidade_mouse = float(
			config.get_value("controles", "sensibilidade", sensibilidade_mouse)
		)
		volume_mestre = float(config.get_value("audio", "volume", volume_mestre))
		mostrar_fps = bool(config.get_value("video", "fps", mostrar_fps))
	aplicar_qualidade()
	AudioServer.set_bus_volume_db(0, linear_to_db(clampf(volume_mestre, 0.0, 1.0)))


func salvar() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("video", "qualidade", qualidade)
	config.set_value("video", "fps", mostrar_fps)
	config.set_value("controles", "sensibilidade", sensibilidade_mouse)
	config.set_value("audio", "volume", volume_mestre)
	config.save(CAMINHO)


func aplicar_qualidade() -> void:
	# Mantém a cena 3D na resolução nativa: FSR em algumas GPUs integradas AMD
	# estava produzindo viewport branco/artefatos em vez de reduzir resolução.
	get_viewport().scaling_3d_scale = 1.0
	get_viewport().msaa_3d = (
		Viewport.MSAA_2X if qualidade in ["Alto", "Épico"] else Viewport.MSAA_DISABLED
	)
	get_viewport().screen_space_aa = (
		Viewport.SCREEN_SPACE_AA_FXAA if qualidade != "Baixo" else Viewport.SCREEN_SPACE_AA_DISABLED
	)
	get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	var ambiente: WorldEnvironment = (
		get_tree().get_first_node_in_group("ambiente_global") as WorldEnvironment
	)
	if ambiente == null or ambiente.environment == null:
		return
	var env: Environment = ambiente.environment
	# Evita pós-processamento caro e instável no driver integrado; atmosfera
	# fica a cargo da neblina de profundidade simples do WorldEnvironment.
	env.volumetric_fog_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.sdfgi_enabled = false
	env.glow_enabled = false
	var mundo: Node3D = get_tree().get_first_node_in_group("mundo_principal") as Node3D
	if mundo != null:
		for luz: Node in mundo.find_children("*", "DirectionalLight3D", true, false):
			(luz as DirectionalLight3D).shadow_enabled = qualidade != "Baixo"
			(luz as DirectionalLight3D).directional_shadow_max_distance = (
				48.0 if qualidade == "Baixo" else 95.0
			)


func densidade_vegetacao(base: int) -> int:
	var fator: float = (
		0.52
		if qualidade == "Baixo"
		else (0.76 if qualidade == "Médio" else (1.0 if qualidade == "Alto" else 1.15))
	)
	return maxi(1, roundi(float(base) * fator))


func _criar_controles() -> void:
	_registrar_tecla("mover_frente", KEY_W)
	_registrar_tecla("mover_tras", KEY_S)
	_registrar_tecla("mover_esquerda", KEY_A)
	_registrar_tecla("mover_direita", KEY_D)
	_registrar_tecla("correr", KEY_SHIFT)
	_registrar_tecla("agachar", KEY_CTRL)
	_registrar_tecla("interagir", KEY_E)
	_registrar_tecla("lanterna", KEY_F)
	_registrar_tecla("diario", KEY_J)
	_registrar_tecla("mapa", KEY_M)
	_registrar_tecla("alternar_camera", KEY_V)
	_registrar_tecla("curar", KEY_H)
	_registrar_tecla("calmante", KEY_Q)
	_registrar_tecla("recarregar", KEY_R)
	_registrar_tecla("ping", KEY_G)
	_registrar_tecla("pausar", KEY_ESCAPE)
	_registrar_mouse("atirar", MOUSE_BUTTON_LEFT)


func _registrar_tecla(acao: String, tecla: Key) -> void:
	if not InputMap.has_action(acao):
		InputMap.add_action(acao)
	var evento: InputEventKey = InputEventKey.new()
	evento.physical_keycode = tecla
	InputMap.action_add_event(acao, evento)


func _registrar_mouse(acao: String, botao: MouseButton) -> void:
	if not InputMap.has_action(acao):
		InputMap.add_action(acao)
	var evento: InputEventMouseButton = InputEventMouseButton.new()
	evento.button_index = botao
	InputMap.action_add_event(acao, evento)
