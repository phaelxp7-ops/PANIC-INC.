class_name PanicNPC
extends CharacterBody3D

const MODELO: String = "res://assets/kenney_characters/characterMedium.fbx"
const PELE_MARTA: String = "res://assets/kenney_characters/survivorFemaleA.png"
const PELE_TOMAS: String = "res://assets/kenney_characters/survivorMaleB.png"
const ANIMACAO_IDLE: String = "res://assets/kenney_characters/idle.fbx"

@export var nome: String = "Sobrevivente"
@export var visual_id: String = "marta"
var _tempo: float = 0.0
var _corpo_visual: Node3D
var _animacao: AnimationPlayer


func _ready() -> void:
	add_to_group("npcs")
	var colisao: CollisionShape3D = CollisionShape3D.new()
	var capsula: CapsuleShape3D = CapsuleShape3D.new()
	capsula.height = 1.72
	capsula.radius = 0.33
	colisao.shape = capsula
	colisao.position.y = 0.86
	add_child(colisao)
	_corpo_visual = Node3D.new()
	add_child(_corpo_visual)
	var cena: PackedScene = load(MODELO) as PackedScene
	if cena != null:
		var modelo: Node3D = cena.instantiate() as Node3D
		if modelo != null:
			_corpo_visual.add_child(modelo)
			var pele: String = PELE_MARTA if visual_id == "marta" else PELE_TOMAS
			var textura: Texture2D = load(pele) as Texture2D
			_aplicar_mapa(modelo, textura)
			_configurar_idle(modelo)
	else:
		push_warning(
			"Sem modelo de NPC: usar placeholder até colocar um modelo rigado em assets/characters."
		)


func _process(delta: float) -> void:
	_tempo += delta
	if _corpo_visual != null:
		_corpo_visual.position.y = 0.006 * sin(_tempo * 1.4)
		_corpo_visual.rotation.y = sin(_tempo * 0.22) * 0.025


func _configurar_idle(modelo: Node3D) -> void:
	_animacao = modelo.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var packed: PackedScene = load(ANIMACAO_IDLE) as PackedScene
	if _animacao == null or packed == null:
		return
	var origem_root: Node = packed.instantiate()
	var origem: AnimationPlayer = (
		origem_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	)
	if origem == null:
		origem_root.free()
		return
	var origem_biblioteca: AnimationLibrary = origem.get_animation_library("")
	var destino_biblioteca: AnimationLibrary = _animacao.get_animation_library("")
	for nome: StringName in origem.get_animation_list():
		if origem_biblioteca == null or destino_biblioteca == null:
			break
		var clip: Animation = origem_biblioteca.get_animation(nome).duplicate() as Animation
		# Mantém caminhos relativos ao root importado; o modelo usa o mesmo rig Kenney.
		var nome_destino: StringName = StringName("npc_idle_" + String(nome))
		if destino_biblioteca.has_animation(nome_destino):
			destino_biblioteca.remove_animation(nome_destino)
		destino_biblioteca.add_animation(nome_destino, clip)
		_animacao.play(nome_destino)
		break
	origem_root.free()


func _aplicar_mapa(no: Node, textura: Texture2D) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = textura
	material.roughness = 0.82
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if no is MeshInstance3D:
		var mesh_instance: MeshInstance3D = no as MeshInstance3D
		if mesh_instance.mesh != null:
			for superficie: int in range(mesh_instance.mesh.get_surface_count()):
				mesh_instance.set_surface_override_material(superficie, material)
	for filho: Node in no.get_children():
		_aplicar_mapa(filho, textura)
