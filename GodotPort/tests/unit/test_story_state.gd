extends GutTest


func before_each() -> void:
	GameState.iniciar_novo_jogo()


func test_story_contains_fifteen_notes() -> void:
	assert_eq(GameState.historia.get("notas", []).size(), 15)


func test_objective_starts_at_marta() -> void:
	assert_eq(GameState.objetivo_atual(), "Encontre Marta na cabana iluminada.")


func test_progression_does_not_skip_required_key() -> void:
	GameState.definir_flag("falou_marta")
	assert_false(GameState.tem_flag("chave_floresta"))
	assert_eq(
		GameState.objetivo_atual(), "Procure a chave do portão na Estação Florestal, ao norte."
	)


func test_duplicate_note_is_not_added_twice() -> void:
	GameState.adicionar_nota(0)
	GameState.adicionar_nota(0)
	assert_eq(GameState.notas.size(), 1)


func test_unknown_note_id_is_ignored() -> void:
	GameState.adicionar_nota(99)
	assert_true(GameState.notas.is_empty())
