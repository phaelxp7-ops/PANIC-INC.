extends GutTest


func test_all_four_region_scenes_load() -> void:
	var paths: Array[String] = [
		"res://scenes/regions/forest.tscn",
		"res://scenes/regions/city.tscn",
		"res://scenes/regions/complex.tscn",
		"res://scenes/regions/subsoil.tscn"
	]
	for path: String in paths:
		assert_not_null(load(path), "Falha ao carregar " + path)


func test_kenney_models_and_textures_are_available() -> void:
	assert_true(ResourceLoader.exists("res://assets/kenney_characters/characterMedium.fbx"))
	assert_true(ResourceLoader.exists("res://assets/kenney_characters/survivorFemaleA.png"))
	assert_true(ResourceLoader.exists("res://assets/kenney_characters/survivorMaleB.png"))
	assert_true(ResourceLoader.exists("res://assets/kenney_characters/zombieA.png"))
	assert_true(ResourceLoader.exists("res://assets/kenney_survival/tent.glb"))


func test_world_builds_all_regions_and_host_player() -> void:
	NetworkManager.iniciar_solo()
	GameState.iniciar_novo_jogo()
	var mundo: PanicWorld = (
		(load("res://scenes/world.tscn") as PackedScene).instantiate() as PanicWorld
	)
	get_tree().root.add_child(mundo)
	await get_tree().process_frame
	assert_eq(mundo.get_node("Regioes").get_child_count(), 4)
	assert_not_null(mundo._jogador_local())
	assert_true(mundo._jogador_local().camera.current, "A câmera do host precisa estar ativa")
	var lucas: PanicNPC
	for no: Node in get_tree().get_nodes_in_group("npcs"):
		if no is PanicNPC and (no as PanicNPC).nome == "Lucas":
			lucas = no as PanicNPC
			break
	assert_not_null(lucas, "Lucas precisa aparecer como personagem no Subsolo")
	if lucas != null:
		var idle_lucas: HumanoidAnimationPlayer = (
			lucas.find_child("AnimationPlayer", true, false) as HumanoidAnimationPlayer
		)
		assert_not_null(idle_lucas, "Lucas precisa usar o controlador de animação humano")
		if idle_lucas != null:
			assert_eq(idle_lucas.current_animation, &"idle")
	var jogador: PlayerController = mundo._jogador_local()
	var ponto_marta: Interactable
	for no: Node in get_tree().get_nodes_in_group("interactables"):
		if no is Interactable and (no as Interactable).acao == "npc_marta":
			ponto_marta = no as Interactable
			break
	assert_not_null(ponto_marta, "Marta precisa poder ser encontrada pelo sistema de interação")
	if ponto_marta != null:
		jogador.global_position = ponto_marta.global_position + Vector3(-3.0, 0.0, 0.0)
		jogador.rotation.y = -PI * 0.5
		var interagir: InputEventAction = InputEventAction.new()
		interagir.action = &"interagir"
		interagir.pressed = true
		jogador._unhandled_input(interagir)
		assert_true(GameState.tem_flag("falou_marta"), "E precisa iniciar o diálogo de Marta")
		assert_true(jogador.tem_revolver, "Marta precisa entregar a arma ao conversar")
		assert_true(mundo.hud.dialogo_ativo, "O diálogo precisa abrir no HUD")
		while mundo.hud.dialogo_ativo:
			mundo.hud.avancar_dialogo()
	assert_eq(
		mundo._jogador_local().camera.environment.background_color,
		mundo._ambiente.environment.background_color,
		"A câmera precisa usar o ambiente noturno do mundo"
	)
	var cabana: Node3D = mundo.get_node("Regioes/FlorestaPinheiros/CabanadeMarta")
	var porta: CabinDoor = cabana.get_node("PortaInterativa") as CabinDoor
	assert_not_null(porta, "A cabana precisa ter uma porta interativa")
	assert_not_null(porta.get_node_or_null("ColisaoDaPorta"), "A porta precisa bloquear passagem")
	assert_not_null(
		cabana.get_node_or_null("Colisao_ParedeOesteA"), "As paredes da cabana precisam de colisão"
	)
	assert_not_null(
		porta.get_node_or_null("PontoDeInteracao") as Interactable,
		"A porta precisa expor a ação de interação"
	)
	var ponto_porta: Interactable = porta.get_node("PontoDeInteracao") as Interactable
	jogador.global_position = ponto_porta.global_position + Vector3(0.0, 0.0, 3.0)
	jogador.rotation.y = 0.0
	await get_tree().process_frame
	var abrir_porta: InputEventAction = InputEventAction.new()
	abrir_porta.action = &"interagir"
	abrir_porta.pressed = true
	jogador._unhandled_input(abrir_porta)
	await get_tree().create_timer(CabinDoor.DURACAO + 0.12).timeout
	assert_almost_eq(
		porta.rotation.y, deg_to_rad(96.0), 0.02, "A porta deve abrir pela dobradiça"
	)
	jogador.global_position = ponto_porta.global_position + Vector3(0.0, 0.0, 3.0)
	var direcao_porta: Vector3 = (ponto_porta.global_position - jogador.global_position).normalized()
	jogador.rotation.y = atan2(-direcao_porta.x, -direcao_porta.z)
	await get_tree().process_frame
	jogador._unhandled_input(abrir_porta)
	await get_tree().create_timer(CabinDoor.DURACAO + 0.12).timeout
	assert_almost_eq(porta.rotation.y, 0.0, 0.02, "E deve fechar a porta novamente")
	var tenda: Node3D = mundo.get_node("Regioes/FlorestaPinheiros/TendaDoAcampamento")
	assert_not_null(
		tenda.get_node_or_null("ModeloKenney"), "O acampamento precisa usar a tenda do asset pack"
	)
	var aba: CabinDoor = tenda.get_node("PortaInterativa") as CabinDoor
	assert_not_null(aba.get_node_or_null("ColisaoDaPorta"), "A aba da tenda precisa ter colisão")
	mundo.queue_free()
	await get_tree().process_frame
	NetworkManager.encerrar()
