class_name PanicHUD
extends CanvasLayer

var mundo: PanicWorld
var painel_objetivo: PanelContainer
var label_regiao: Label
var label_objetivo: Label
var label_status: Label
var label_msg: Label
var label_interacao: Label
var label_fps: Label
var label_mapa_overlay: Label
var label_dialogo: Label
var label_falante: Label
var barra_vida: ProgressBar
var barra_sanidade: ProgressBar
var barra_stamina: ProgressBar
var barra_bateria: ProgressBar
var barra_chefe: ProgressBar
var label_chefe: Label
var painel_dialogo: PanelContainer
var painel_diario: PanelContainer
var painel_mapa: PanelContainer
var painel_pausa: PanelContainer
var painel_final: PanelContainer
var label_diario: Label
var label_mapa: Label
var label_pausa: Label
var label_final: Label
var dialogo_ativo: bool = false
var diario_ativo: bool = false
var mapa_ativo: bool = false
var pausa_ativa: bool = false
var _linhas_dialogo: Array = []
var _indice_dialogo: int = 0
var _mensagem_tempo: float = 0.0
var _indice_nota: int = 0
var _tremor: ColorRect
var _tempo_ui: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mundo = get_parent() as PanicWorld
	_criar_interface()
	EventBus.notas_alteradas.connect(_atualizar_diario)
	EventBus.susto.connect(_ao_susto)
	atualizar()


func _process(delta: float) -> void:
	_tempo_ui += delta
	if _mensagem_tempo > 0.0:
		_mensagem_tempo -= delta
		if _mensagem_tempo <= 0.0:
			label_msg.visible = false
	var jogador: PlayerController = mundo._jogador_local() if mundo != null else null
	if jogador != null:
		barra_vida.value = jogador.vida
		barra_sanidade.value = jogador.sanidade
		barra_stamina.value = jogador.stamina
		barra_bateria.value = jogador.bateria
		label_status.text = (
			"MUNIÇÃO %d   •   KITS %d   •   CALMANTES %d   •   BATERIAS %d"
			% [
				jogador.municao,
				int(GameState.inventario.get("kits", 0)),
				int(GameState.inventario.get("calmantes", 0)),
				int(GameState.inventario.get("baterias", 0))
			]
		)
		var perto: Interactable = mundo.interacao_proxima(jogador)
		if perto != null and not diario_ativo and not pausa_ativa and not dialogo_ativo:
			label_interacao.text = "[ E ]  " + perto.nome_exibido
			label_interacao.visible = true
		else:
			label_interacao.visible = false
		var zona: String = "FLORESTA DE PINHEIROS"
		if jogador.global_position.x > 145.0:
			zona = "CIDADE DE VALE SOMBRIO"
		if jogador.global_position.x > 420.0:
			zona = "COMPLEXO PANIC INC."
		if jogador.global_position.y < -10.0:
			zona = "SUBSOLO — NÍVEL -3"
		label_regiao.text = zona
	var chefe: PanicMonster = mundo._chefe if mundo != null else null
	barra_chefe.visible = chefe != null and is_instance_valid(chefe)
	label_chefe.visible = barra_chefe.visible
	if barra_chefe.visible:
		barra_chefe.value = 100.0 * chefe.vida / 280.0
		label_chefe.text = "O DIRETOR   •   FASE %d" % chefe.fase
	var intensidade: float = 0.0
	if jogador != null:
		intensidade = 1.0 - clampf(jogador.sanidade / 100.0, 0.0, 1.0)
	_tremor.color = Color(0.16, 0.012, 0.025, intensidade * 0.16)
	_tremor.visible = jogador != null and intensidade > 0.03
	if Settings.mostrar_fps:
		label_fps.text = "FPS %d" % Engine.get_frames_per_second()
	if diario_ativo and Input.is_action_just_pressed("mover_frente"):
		_indice_nota = maxi(0, _indice_nota - 1)
		_atualizar_diario()
	if diario_ativo and Input.is_action_just_pressed("mover_tras"):
		_indice_nota = mini(GameState.notas.size() - 1, _indice_nota + 1)
		_atualizar_diario()


func atualizar() -> void:
	if label_objetivo != null:
		label_objetivo.text = GameState.objetivo_atual()
		_atualizar_diario()


func _criar_interface() -> void:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_tremor = ColorRect.new()
	_tremor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tremor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tremor.visible = false
	root.add_child(_tremor)
	var topo_esquerda: PanelContainer = _painel(
		root, Vector2(20, 18), Vector2(300, 154), Vector2(0, 0)
	)
	var coluna: VBoxContainer = VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 3)
	topo_esquerda.add_child(coluna)
	_colocar_barra(coluna, "VIDA", 100, Color(0.67, 0.14, 0.17), "Vida")
	_colocar_barra(coluna, "SANIDADE", 100, Color(0.20, 0.66, 0.70), "Sanidade")
	_colocar_barra(coluna, "FOLEGO", 100, Color(0.30, 0.67, 0.42), "Stamina")
	_colocar_barra(coluna, "LANTERNA", 100, Color(0.92, 0.77, 0.40), "Bateria")
	label_status = _label(
		"MUNIÇÃO 6   •   KITS 0   •   CALMANTES 0   •   BATERIAS 1", 12, Color(0.76, 0.78, 0.78)
	)
	coluna.add_child(label_status)
	var topo_direita: PanelContainer = _painel(
		root, Vector2(-390, 18), Vector2(370, 116), Vector2(1, 0)
	)
	var coluna_info: VBoxContainer = VBoxContainer.new()
	coluna_info.alignment = BoxContainer.ALIGNMENT_END
	topo_direita.add_child(coluna_info)
	label_regiao = _label("FLORESTA DE PINHEIROS", 16, Color(0.31, 0.84, 0.84))
	label_regiao.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coluna_info.add_child(label_regiao)
	label_objetivo = _label(GameState.objetivo_atual(), 14, Color(0.91, 0.9, 0.85))
	label_objetivo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_objetivo.custom_minimum_size.x = 330
	coluna_info.add_child(label_objetivo)
	var label_notas: Label = _label(
		"DIÁRIO %d/15   •   DIFICULDADE %d/5" % [GameState.notas.size(), GameState.dificuldade],
		12,
		Color(0.7, 0.72, 0.73)
	)
	label_notas.name = "ResumoNotas"
	label_notas.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coluna_info.add_child(label_notas)
	label_chefe = _label("O DIRETOR", 17, Color(1.0, 0.24, 0.20))
	label_chefe.name = "NomeChefe"
	label_chefe.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_chefe.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	label_chefe.position = Vector2(-200, 83)
	label_chefe.size = Vector2(400, 26)
	label_chefe.visible = false
	root.add_child(label_chefe)
	barra_chefe = ProgressBar.new()
	barra_chefe.max_value = 100.0
	barra_chefe.set_anchors_preset(Control.PRESET_CENTER_TOP)
	barra_chefe.position = Vector2(-225, 111)
	barra_chefe.size = Vector2(450, 18)
	barra_chefe.visible = false
	root.add_child(barra_chefe)

	var mira: Label = _label("+", 24, Color(0.92, 0.95, 0.92, 0.8))
	mira.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mira.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mira.set_anchors_preset(Control.PRESET_CENTER)
	mira.position = Vector2(-14, -16)
	mira.size = Vector2(28, 32)
	root.add_child(mira)
	label_interacao = _label("[ E ] Interagir", 19, Color(0.98, 0.83, 0.24))
	label_interacao.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_interacao.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label_interacao.position = Vector2(-250, -92)
	label_interacao.size = Vector2(500, 44)
	label_interacao.visible = false
	root.add_child(label_interacao)
	label_msg = _label("", 17, Color(0.9, 0.92, 0.88))
	label_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_msg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_msg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	label_msg.position = Vector2(-450, 148)
	label_msg.size = Vector2(900, 50)
	label_msg.visible = false
	root.add_child(label_msg)
	var rodape: Label = _label(
		(
			"WASD mover • SHIFT correr • CTRL agachar • E interagir • V câmera • F lanterna • "
			+ "M mapa • J diário • Mouse atacar • R recarregar • H curar • Q calmante • G ping • ESC pausa"
		),
		12,
		Color(0.72, 0.75, 0.76)
	)
	rodape.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rodape.offset_left = 20
	rodape.offset_right = -20
	rodape.offset_top = -48
	rodape.offset_bottom = -10
	root.add_child(rodape)
	label_fps = _label("", 11, Color(0.54, 0.62, 0.68))
	label_fps.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	label_fps.position = Vector2(-78, -28)
	label_fps.size = Vector2(70, 18)
	root.add_child(label_fps)

	painel_dialogo = _painel(root, Vector2(-480, -145), Vector2(960, 118), Vector2(0.5, 1.0))
	var caixa_dialogo: VBoxContainer = VBoxContainer.new()
	caixa_dialogo.add_theme_constant_override("separation", 8)
	painel_dialogo.add_child(caixa_dialogo)
	label_falante = _label("", 14, Color(0.40, 0.85, 0.85))
	caixa_dialogo.add_child(label_falante)
	label_dialogo = _label("", 17, Color(0.95, 0.93, 0.88))
	label_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caixa_dialogo.add_child(label_dialogo)
	var ajuda: Label = _label("E ou clique para continuar", 11, Color(0.56, 0.60, 0.62))
	ajuda.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	caixa_dialogo.add_child(ajuda)
	painel_dialogo.visible = false
	dialogo_ativo = false

	painel_diario = _painel(root, Vector2(-480, -300), Vector2(960, 600), Vector2(0.5, 0.5))
	var c_diario: VBoxContainer = VBoxContainer.new()
	c_diario.add_theme_constant_override("separation", 14)
	painel_diario.add_child(c_diario)
	var t_diario: Label = _label("DIÁRIO DE ANA", 30, Color(0.81, 0.72, 0.39))
	t_diario.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_diario.add_child(t_diario)
	label_diario = _label("", 18, Color(0.83, 0.83, 0.79))
	label_diario.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_diario.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c_diario.add_child(label_diario)
	var ajuda_diario: Label = _label(
		"↑/↓ selecionar   •   ESC ou J voltar", 13, Color(0.61, 0.64, 0.64)
	)
	ajuda_diario.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_diario.add_child(ajuda_diario)
	painel_diario.visible = false

	painel_mapa = _painel(root, Vector2(-330, -250), Vector2(660, 500), Vector2(0.5, 0.5))
	label_mapa_overlay = _label("MAPA DE VALE SOMBRIO", 22, Color(0.72, 0.83, 0.82))
	label_mapa_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_mapa_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_mapa_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	painel_mapa.add_child(label_mapa_overlay)
	painel_mapa.visible = false

	painel_pausa = _painel(root, Vector2(-210, -225), Vector2(420, 450), Vector2(0.5, 0.5))
	var c_pausa: VBoxContainer = VBoxContainer.new()
	c_pausa.add_theme_constant_override("separation", 12)
	painel_pausa.add_child(c_pausa)
	label_pausa = _label("PAUSADO", 30, Color(0.72, 0.83, 0.82))
	label_pausa.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_pausa.add_child(label_pausa)
	_botao(c_pausa, "Continuar", alternar_pausa)
	_botao(c_pausa, "Salvar", _salvar)
	_botao(c_pausa, "Voltar ao menu", _voltar_menu)
	painel_pausa.visible = false

	painel_final = _painel(root, Vector2(-300, -180), Vector2(600, 360), Vector2(0.5, 0.5))
	var c_final: VBoxContainer = VBoxContainer.new()
	c_final.add_theme_constant_override("separation", 14)
	painel_final.add_child(c_final)
	label_final = _label("ESCOLHA O DESTINO DO CORAÇÃO", 23, Color(0.82, 0.71, 0.4))
	label_final.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_final.add_child(label_final)
	_botao(
		c_final, "O Descanso — desligar o reator", func() -> void: mundo.escolher_final("descanso")
	)
	_botao(c_final, "O Eco do Medo — levar Lucas", func() -> void: mundo.escolher_final("eco"))
	_botao(c_final, "Voltar", _fechar_final)
	painel_final.visible = false


func _painel(pai: Control, pos: Vector2, tamanho: Vector2, ancora: Vector2) -> PanelContainer:
	var painel: PanelContainer = PanelContainer.new()
	painel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	if ancora.x == 0.5:
		painel.set_anchors_preset(Control.PRESET_CENTER)
	elif ancora.x == 1.0:
		painel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	painel.position = pos
	painel.size = tamanho
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = Color(0.008, 0.014, 0.018, 0.82)
	estilo.border_color = Color(0.25, 0.34, 0.36, 0.58)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(7)
	estilo.content_margin_left = 14
	estilo.content_margin_top = 11
	estilo.content_margin_right = 14
	estilo.content_margin_bottom = 11
	painel.add_theme_stylebox_override("panel", estilo)
	pai.add_child(painel)
	return painel


func _label(texto: String, tamanho: int, cor: Color) -> Label:
	var label: Label = Label.new()
	label.text = texto
	label.add_theme_font_size_override("font_size", tamanho)
	label.add_theme_color_override("font_color", cor)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _colocar_barra(
	pai: VBoxContainer, nome: String, maximo: float, cor: Color, id: String
) -> void:
	var label: Label = _label(nome, 11, Color(0.82, 0.84, 0.81))
	pai.add_child(label)
	var barra: ProgressBar = ProgressBar.new()
	barra.max_value = maximo
	barra.value = maximo
	barra.custom_minimum_size.y = 12
	barra.show_percentage = false
	barra.add_theme_stylebox_override("fill", _barra_estilo(cor))
	barra.add_theme_stylebox_override("background", _barra_estilo(Color(0.12, 0.15, 0.15)))
	pai.add_child(barra)
	match id:
		"Vida":
			barra_vida = barra
		"Sanidade":
			barra_sanidade = barra
		"Stamina":
			barra_stamina = barra
		"Bateria":
			barra_bateria = barra


func _barra_estilo(cor: Color) -> StyleBoxFlat:
	var estilo: StyleBoxFlat = StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(3)
	return estilo


func _botao(pai: VBoxContainer, texto: String, acao: Callable) -> void:
	var botao: Button = Button.new()
	botao.text = texto
	botao.custom_minimum_size.y = 42
	botao.pressed.connect(acao)
	pai.add_child(botao)


func mostrar_mensagem(texto: String, duracao: float = 3.0) -> void:
	label_msg.text = texto
	label_msg.visible = true
	_mensagem_tempo = duracao


func mostrar_dialogo(linhas: Array) -> void:
	if linhas.is_empty():
		return
	_linhas_dialogo = linhas.duplicate(true)
	_indice_dialogo = 0
	dialogo_ativo = true
	painel_dialogo.visible = true
	_atualizar_linha_dialogo()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func avancar_dialogo() -> void:
	if not dialogo_ativo:
		return
	_indice_dialogo += 1
	if _indice_dialogo >= _linhas_dialogo.size():
		dialogo_ativo = false
		painel_dialogo.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	_atualizar_linha_dialogo()


func _atualizar_linha_dialogo() -> void:
	var linha: Array = _linhas_dialogo[_indice_dialogo]
	label_falante.text = str(linha[0])
	label_dialogo.text = str(linha[1])


func alternar_diario() -> void:
	diario_ativo = not diario_ativo
	painel_diario.visible = diario_ativo
	if diario_ativo:
		mapa_ativo = false
		painel_mapa.visible = false
		_atualizar_diario()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if diario_ativo else Input.MOUSE_MODE_CAPTURED


func _atualizar_diario() -> void:
	if label_diario == null:
		return
	var notas: Array = GameState.historia.get("notas", [])
	var lidos: Array[int] = GameState.notas
	if lidos.is_empty():
		label_diario.text = "Nenhuma nota encontrada.\n\nA floresta guarda os últimos rastros de Lucas."
		return
	_indice_nota = clampi(_indice_nota, 0, lidos.size() - 1)
	var indice_historia: int = lidos[_indice_nota]
	var dado: Dictionary = notas[indice_historia]
	var lista: String = ""
	for i: int in range(lidos.size()):
		var n: Dictionary = notas[lidos[i]]
		lista += ("> " if i == _indice_nota else "  ") + str(n.get("titulo", "Nota")) + "\n"
	label_diario.text = lista + "\n" + "—".repeat(40) + "\n\n" + str(dado.get("texto", ""))
	var resumo: Label = (
		get_node_or_null("Control/PanelContainer/VBoxContainer/ResumoNotas") as Label
	)
	if resumo != null:
		resumo.text = "DIÁRIO %d/15   •   DIFICULDADE %d/5" % [lidos.size(), GameState.dificuldade]


func alternar_mapa() -> void:
	mapa_ativo = not mapa_ativo
	painel_mapa.visible = mapa_ativo
	if mapa_ativo:
		diario_ativo = false
		painel_diario.visible = false
	label_mapa_overlay.text = (
		"VALE SOMBRIO\n\nFloresta de Pinheiros\n   Marta — Estação — Portão\n\n"
		+ "Cidade de Vale Sombrio\n   Rádio — Delegacia — Farmácia\n\n"
		+ "Complexo PANIC INC.\n   3 fusíveis — Elevador\n\n"
		+ "Subsolo — Nível -3\n   O Diretor — Lucas\n\nObjetivo: "
		+ GameState.objetivo_atual()
	)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if mapa_ativo else Input.MOUSE_MODE_CAPTURED


func alternar_pausa() -> void:
	pausa_ativa = not pausa_ativa
	painel_pausa.visible = pausa_ativa
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pausa_ativa else Input.MOUSE_MODE_CAPTURED
	get_tree().paused = pausa_ativa


func mostrar_escolha_final() -> void:
	painel_final.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func finalizar_partida(texto: String) -> void:
	label_final.text = "FIM DA HISTÓRIA\n\n" + texto
	painel_final.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _fechar_final() -> void:
	painel_final.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _salvar() -> void:
	SaveSystem.salvar()
	mostrar_mensagem("Progresso salvo neste computador.", 2.5)


func _voltar_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	NetworkManager.encerrar()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _ao_susto(intensidade: float) -> void:
	var tween: Tween = create_tween()
	_tremor.color = Color(0.3, 0.015, 0.025, clampf(intensidade, 0.0, 1.0) * 0.72)
	_tremor.visible = true
	tween.tween_property(_tremor, "color:a", 0.0, 0.65)
	tween.tween_callback(func() -> void: _tremor.visible = false)
