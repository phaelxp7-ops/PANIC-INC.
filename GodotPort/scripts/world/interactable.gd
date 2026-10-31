class_name Interactable
extends Node3D

var nome_exibido: String = "Interagir"
var acao: String = ""
var cor: Color = Color(0.4, 0.7, 0.8)
var show_marker: bool = true


func _ready() -> void:
	add_to_group("interactables")
	if show_marker:
		_montar_visual()


func _montar_visual() -> void:
	var orb: MeshInstance3D = MeshInstance3D.new()
	var malha: SphereMesh = SphereMesh.new()
	malha.radius = 0.2 if acao.begins_with("nota_") else 0.3
	malha.height = malha.radius * 2.0
	orb.mesh = malha
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = cor
	material.metallic = 0.22
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = cor
	material.emission_energy_multiplier = 1.1
	orb.material_override = material
	orb.position.y = 1.05
	add_child(orb)
	var aro: MeshInstance3D = MeshInstance3D.new()
	var toro: TorusMesh = TorusMesh.new()
	toro.inner_radius = 0.38
	toro.outer_radius = 0.42
	aro.mesh = toro
	aro.rotation.x = PI / 2.0
	aro.position.y = 0.12
	var aro_mat: StandardMaterial3D = StandardMaterial3D.new()
	aro_mat.albedo_color = cor.darkened(0.2)
	aro_mat.emission_enabled = true
	aro_mat.emission = cor
	aro_mat.emission_energy_multiplier = 0.35
	aro.material_override = aro_mat
	add_child(aro)
