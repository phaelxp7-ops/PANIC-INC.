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
	assert_eq(
		mundo._jogador_local().camera.environment.background_color,
		mundo._ambiente.environment.background_color,
		"A câmera precisa usar o ambiente noturno do mundo"
	)
	mundo.queue_free()
	await get_tree().process_frame
	NetworkManager.encerrar()
