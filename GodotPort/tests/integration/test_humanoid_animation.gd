extends GutTest


func test_kenney_idle_and_run_are_bound_to_live_skeleton() -> void:
	var cena: PackedScene = load("res://assets/kenney_characters/characterMedium.fbx") as PackedScene
	var modelo: Node3D = cena.instantiate() as Node3D
	add_child(modelo)
	var rig: Skeleton3D = modelo.find_child("Skeleton3D", true, false) as Skeleton3D
	var animador: HumanoidAnimationPlayer = HumanoidAnimationPlayer.new()
	animador.name = "AnimationPlayer"
	modelo.add_child(animador)
	assert_true(animador.configurar(modelo), "Os clipes precisam retargetar no rig Kenney")
	assert_true(animador.is_playing(), "O idle precisa estar tocando ao instanciar o personagem")
	assert_eq(animador.current_animation, &"idle")
	var caminho_rig: NodePath = animador.get_animation(&"idle").track_get_path(0)
	var alvo_trilha: NodePath = NodePath(
		String(animador.root_node) + "/" + String(caminho_rig.get_concatenated_names())
	)
	assert_not_null(
		animador.get_node_or_null(alvo_trilha), "As trilhas precisam apontar para o rig ativo"
	)
	var estados: Array[StringName] = [
		&"walk", &"run", &"crouch", &"crouch_walk", &"turn", &"interact", &"combat"
	]
	for nome: StringName in estados:
		assert_true(animador.has_animation(nome), "Estado ausente: " + String(nome))
	animador.atualizar_locomocao(true, false, false)
	assert_eq(animador.current_animation, &"walk")
	animador.atualizar_locomocao(true, true, false)
	assert_eq(animador.current_animation, &"run")
	animador.atualizar_locomocao(false, false, true)
	assert_eq(animador.current_animation, &"crouch")
	animador.atualizar_locomocao(true, false, true)
	assert_eq(animador.current_animation, &"crouch_walk")
	animador.atualizar_locomocao(false, false, false)
	assert_eq(animador.current_animation, &"idle")
	await get_tree().process_frame
	animador.advance(0.45)
	rig.force_update_all_bone_transforms()
	var braco: int = rig.find_bone("LeftArm")
	var antebraco: int = rig.find_bone("LeftForeArm")
	var diferenca_esquerda: Vector3 = (
		rig.get_bone_global_pose(antebraco).origin - rig.get_bone_global_pose(braco).origin
	)
	var braco_direito: int = rig.find_bone("RightArm")
	var antebraco_direito: int = rig.find_bone("RightForeArm")
	var diferenca_direita: Vector3 = (
		rig.get_bone_global_pose(antebraco_direito).origin
		- rig.get_bone_global_pose(braco_direito).origin
	)
	var inclinacao_esquerda: float = (
		absf(diferenca_esquerda.y) / maxf(diferenca_esquerda.length(), 0.0001)
	)
	var inclinacao_direita: float = (
		absf(diferenca_direita.y) / maxf(diferenca_direita.length(), 0.0001)
	)
	assert_gt(inclinacao_esquerda, 0.45, "O cotovelo esquerdo não pode ficar em T-pose")
	assert_gt(inclinacao_direita, 0.45, "O cotovelo direito não pode ficar em T-pose")
	rig.force_update_all_bone_transforms()
	assert_ne(
		rig.get_bone_pose_rotation(braco),
		rig.get_bone_rest(braco).basis.get_rotation_quaternion(),
		"O idle precisa animar os braços do rig"
	)
	modelo.queue_free()
	await get_tree().process_frame


func test_npc_and_monster_install_the_same_rigged_animation_player() -> void:
	var marta: PanicNPC = PanicNPC.new()
	marta.nome = "Marta"
	marta.visual_id = "marta"
	add_child(marta)
	await get_tree().process_frame
	var idle_marta: HumanoidAnimationPlayer = (
		marta.find_child("AnimationPlayer", true, false) as HumanoidAnimationPlayer
	)
	assert_not_null(idle_marta, "Marta precisa de controlador no esqueleto real")
	if idle_marta != null:
		assert_true(idle_marta.is_playing(), "Marta precisa iniciar animando Idle")
		assert_eq(idle_marta.current_animation, &"idle")
	marta.queue_free()
	await get_tree().process_frame
	var monstro: PanicMonster = PanicMonster.new()
	add_child(monstro)
	await get_tree().process_frame
	var idle_monstro: HumanoidAnimationPlayer = (
		monstro.find_child("AnimationPlayer", true, false) as HumanoidAnimationPlayer
	)
	assert_not_null(idle_monstro, "Inimigo precisa de controlador no esqueleto real")
	if idle_monstro != null:
		assert_true(idle_monstro.is_playing(), "Inimigo precisa iniciar animando Idle")
		assert_eq(idle_monstro.current_animation, &"idle")
	monstro.queue_free()
	await get_tree().process_frame
