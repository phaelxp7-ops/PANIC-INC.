extends Control

const CENA_MUNDO: String = "res://scenes/world.tscn"
var campo_ip: LineEdit
var status: Label


func _ready() -> void:
	_criar_interface()
	var argumentos: PackedStringArray = OS.get_cmdline_user_args()
	if "--panic-start" in argumentos:
		call_deferred("_jogar_solo")
		return
	if "--panic-server" in argumentos:
		NetworkManager.criar_partida()
		GameState.iniciar_novo_jogo()
		get_tree().call_deferred("change_scene_to_file", CENA_MUNDO)
	for argumento: String in argumentos:
		if argumento.begins_with("--panic-join="):
			campo_ip.text = argumento.trim_prefix("--panic-join=")
			call_deferred("_entrar_partida")
			return


func _criar_interface() -> void:
	var fundo: ColorRect = ColorRect.new()
	fundo.color = Color(0.012, 0.018, 0.025, 1.0)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_CENTER)
	coluna.position = Vector2(-260, -250)
	coluna.size = Vector2(520, 500)
	coluna.add_theme_constant_override("separation", 14)
	add_child(coluna)
	var titulo: Label = Label.new()
	titulo.text = "PANIC INC."
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 54)
	titulo.add_theme_color_override("font_color", Color(0.62, 0.84, 0.86))
	coluna.add_child(titulo)
	var subtitulo: Label = Label.new()
	subtitulo.text = "O CORAÇÃO DO MEDO"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 22)
	subtitulo.add_theme_color_override("font_color", Color(0.87, 0.73, 0.58))
	coluna.add_child(subtitulo)
	var sinopse: Label = Label.new()
	sinopse.text = "Ana procura Lucas em Vale Sombrio.\nA luz revela o que a escuridão esconde."
	sinopse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sinopse.add_theme_color_override("font_color", Color(0.75, 0.77, 0.78))
	sinopse.add_theme_font_size_override("font_size", 16)
	coluna.add_child(sinopse)
	_adicionar_botao(coluna, "Começar história", _jogar_solo)
	_adicionar_botao(coluna, "Continuar (se houver salvamento)", _continuar_historia)
	_adicionar_botao(coluna, "Criar partida cooperativa (porta 27840)", _criar_partida)
	campo_ip = LineEdit.new()
	campo_ip.placeholder_text = "IP do anfitrião (ex.: 192.168.0.10)"
	campo_ip.text = "127.0.0.1"
	campo_ip.custom_minimum_size.y = 42
	coluna.add_child(campo_ip)
	_adicionar_botao(coluna, "Entrar na partida", _entrar_partida)
	_adicionar_botao(
		coluna, "Qualidade: " + Settings.qualidade + " (clique para alternar)", _alternar_qualidade
	)
	status = Label.new()
	status.text = "WASD mover  •  Mouse olhar  •  E interagir  •  F lanterna  •  J diário"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_color_override("font_color", Color(0.55, 0.62, 0.64))
	coluna.add_child(status)


func _adicionar_botao(pai: VBoxContainer, texto: String, acao: Callable) -> void:
	var botao: Button = Button.new()
	botao.text = texto
	botao.custom_minimum_size.y = 44
	botao.add_theme_font_size_override("font_size", 17)
	botao.pressed.connect(acao)
	pai.add_child(botao)


func _jogar_solo() -> void:
	NetworkManager.iniciar_solo()
	GameState.iniciar_novo_jogo()
	get_tree().change_scene_to_file(CENA_MUNDO)


func _criar_partida() -> void:
	var erro: Error = NetworkManager.criar_partida()
	if erro != OK:
		status.text = NetworkManager.ultimo_erro
		return
	GameState.iniciar_novo_jogo()
	get_tree().change_scene_to_file(CENA_MUNDO)


func _continuar_historia() -> void:
	NetworkManager.iniciar_solo()
	if not SaveSystem.carregar():
		status.text = "Nenhum salvamento encontrado. Comece uma história nova."
		return
	get_tree().change_scene_to_file(CENA_MUNDO)


func _entrar_partida() -> void:
	if not multiplayer.connected_to_server.is_connected(_ao_conectar_partida):
		multiplayer.connected_to_server.connect(_ao_conectar_partida, CONNECT_ONE_SHOT)
	if not multiplayer.connection_failed.is_connected(_ao_falhar_conexao):
		multiplayer.connection_failed.connect(_ao_falhar_conexao, CONNECT_ONE_SHOT)
	status.text = "Conectando ao anfitrião..."
	var erro: Error = NetworkManager.entrar_partida(campo_ip.text)
	if erro != OK:
		multiplayer.connected_to_server.disconnect(_ao_conectar_partida)
		multiplayer.connection_failed.disconnect(_ao_falhar_conexao)
		status.text = NetworkManager.ultimo_erro
		return


func _ao_conectar_partida() -> void:
	get_tree().change_scene_to_file(CENA_MUNDO)


func _ao_falhar_conexao() -> void:
	NetworkManager.encerrar()
	status.text = "Conexão falhou. Confira o IP e a porta UDP 27840."


func _alternar_qualidade() -> void:
	var niveis: Array[String] = ["Baixo", "Médio", "Alto", "Épico"]
	var indice: int = niveis.find(Settings.qualidade)
	Settings.qualidade = niveis[(indice + 1) % niveis.size()]
	Settings.aplicar_qualidade()
	Settings.salvar()
	for filho: Node in get_children():
		if filho is VBoxContainer:
			for controle: Node in filho.get_children():
				if controle is Button and str(controle.text).begins_with("Qualidade:"):
					controle.text = "Qualidade: " + Settings.qualidade + " (clique para alternar)"
