extends GutTest


func test_player_camera_flashlight_movement_items_and_revive() -> void:
	var jogador: PlayerController = PlayerController.new()
	add_child(jogador)
	await get_tree().process_frame
	assert_true(jogador.camera.current, "A câmera local precisa ser ativada")
	assert_false(jogador._visual.visible, "O modelo fica oculto na primeira pessoa")
	var alternar_camera: InputEventAction = InputEventAction.new()
	alternar_camera.action = &"alternar_camera"
	alternar_camera.pressed = true
	jogador._unhandled_input(alternar_camera)
	assert_gt(jogador.camera.position.z, 1.0, "V precisa habilitar a terceira pessoa")
	assert_true(jogador._visual.visible, "O modelo precisa aparecer na terceira pessoa")
	var alternar_lanterna: InputEventAction = InputEventAction.new()
	alternar_lanterna.action = &"lanterna"
	alternar_lanterna.pressed = true
	jogador._unhandled_input(alternar_lanterna)
	assert_false(jogador.lanterna.visible, "F precisa alternar a lanterna")
	jogador._unhandled_input(alternar_lanterna)
	assert_true(jogador.lanterna.visible, "F precisa reativar a lanterna")
	jogador._intencao = Vector2.RIGHT
	jogador._correndo = false
	jogador._agachado = false
	jogador._simular_movimento(0.5)
	var velocidade_caminhada: float = jogador.velocity.x
	assert_gt(velocidade_caminhada, 0.0, "D precisa mover a personagem para a direita")
	jogador.velocity = Vector3.ZERO
	jogador._correndo = true
	jogador._simular_movimento(0.5)
	var velocidade_corrida: float = jogador.velocity.x
	assert_gt(velocidade_corrida, velocidade_caminhada, "SHIFT precisa acelerar a corrida")
	jogador.velocity = Vector3.ZERO
	jogador._correndo = false
	jogador._agachado = true
	jogador._simular_movimento(0.5)
	assert_lt(jogador.velocity.x, velocidade_caminhada, "CTRL precisa reduzir a velocidade")
	GameState.inventario["kits"] = 1
	jogador.vida = 40.0
	jogador._usar_item_servidor("kits")
	assert_eq(jogador.vida, 85.0, "H precisa consumir kit e recuperar vida")
	assert_eq(GameState.inventario["kits"], 0)
	GameState.inventario["calmantes"] = 1
	jogador.sanidade = 50.0
	jogador._usar_item_servidor("calmantes")
	assert_eq(jogador.sanidade, 88.0, "Q precisa consumir calmante e recuperar sanidade")
	jogador.receber_dano(200.0)
	assert_true(jogador.caido, "Dano fatal precisa derrubar a personagem")
	jogador.reviver()
	assert_false(jogador.caido, "E deve permitir levantar um aliado derrubado")
	assert_eq(jogador.vida, 42.0)
	jogador.receber_dano(100.0)
	jogador._temporizadores_servidor(PlayerController.PRAZO_REANIMACAO_SOLO + 0.1)
	assert_false(jogador.caido, "O modo solo não pode ficar travado aguardando um aliado")
	assert_eq(jogador.vida, 42.0, "A reanimação solo precisa devolver a personagem ao jogo")
	jogador.queue_free()
	await get_tree().process_frame
