extends Node3D
## Cada região vive em uma cena própria para reduzir conflitos no trabalho em equipe.

const CENA_ARVORE: Array[String] = [
	"res://assets/kenney_survival/tree.glb",
	"res://assets/kenney_survival/tree-tall.glb",
	"res://assets/kenney_survival/tree-autumn.glb"
]
const CENA_ROCHA: Array[String] = [
	"res://assets/kenney_survival/rock-a.glb",
	"res://assets/kenney_survival/rock-b.glb",
	"res://assets/kenney_survival/rock-c.glb"
]
const CENA_TENDA: PackedScene = preload("res://assets/kenney_survival/tent.glb")
const TEXTURA_CONCRETO: Texture2D = preload("res://assets/polyhaven/concrete_floor_diff_1k.jpg")
const TEXTURA_PINHO: Texture2D = preload("res://assets/polyhaven/pine_bark_diff_1k.jpg")

@export_enum("forest", "city", "complex", "subsoil") var region_id: String = "forest"
@export var centro: Vector3 = Vector3.ZERO
@export var tamanho: Vector2 = Vector2(230.0, 190.0)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash(region_id) + 91273
	_montar_chao()
	_montar_cenario()
	_montar_pontos_de_interesse()


func _montar_chao() -> void:
	var plano: PlaneMesh = PlaneMesh.new()
	plano.size = tamanho
	plano.subdivide_width = 48
	plano.subdivide_depth = 40
	var solo: MeshInstance3D = MeshInstance3D.new()
	solo.name = "TerrenoPBR"
	solo.mesh = plano
	solo.position = Vector3(centro.x, centro.y - 0.12, centro.z)
	solo.material_override = _material_solo()
	add_child(solo)
	var corpo: StaticBody3D = StaticBody3D.new()
	corpo.name = "ColisaoDoTerreno"
	var forma: CollisionShape3D = CollisionShape3D.new()
	var plano_colisao: BoxShape3D = BoxShape3D.new()
	plano_colisao.size = Vector3(tamanho.x, 1.0, tamanho.y)
	forma.shape = plano_colisao
	corpo.position = Vector3(centro.x, centro.y, centro.z)
	forma.position.y = -0.62
	corpo.add_child(forma)
	add_child(corpo)
	# Plataforma de segurança dedicada no Nível -3: evita fendas entre colisores
	# e mantém um piso navegável mesmo se a geometria decorativa falhar.
	if region_id == "subsolo":
		var piso_seguro: StaticBody3D = StaticBody3D.new()
		piso_seguro.name = "PisoSeguroSubsolo"
		piso_seguro.position = centro
		var piso_forma: CollisionShape3D = CollisionShape3D.new()
		var caixa: BoxShape3D = BoxShape3D.new()
		caixa.size = Vector3(tamanho.x, 2.0, tamanho.y)
		piso_forma.shape = caixa
		piso_forma.position.y = -1.0
		piso_seguro.add_child(piso_forma)
		add_child(piso_seguro)


func _material_solo() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.roughness = 0.94
	material.metallic = 0.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.uv1_scale = Vector3(16.0, 16.0, 1.0)
	var caminho: String = "res://assets/polyhaven/forrest_ground_03_diff_1k.jpg"
	if region_id == "city":
		caminho = "res://assets/polyhaven/concrete_floor_diff_1k.jpg"
	elif region_id in ["complex", "subsoil"]:
		caminho = "res://assets/polyhaven/concrete_floor_diff_1k.jpg"
	if region_id != "forest":
		material.albedo_texture = TEXTURA_CONCRETO
	elif ResourceLoader.exists(caminho):
		material.albedo_texture = load(caminho) as Texture2D
	match region_id:
		"forest":
			material.albedo_color = Color(0.30, 0.36, 0.27)
		"city":
			material.albedo_color = Color(0.43, 0.40, 0.34)
		"complex":
			material.albedo_color = Color(0.40, 0.44, 0.46)
		_:
			material.albedo_color = Color(0.48, 0.30, 0.27)
	return material


func _montar_cenario() -> void:
	if region_id == "forest":
		_plantar_pinheiros()
		_espalhar_multimesh(CENA_ROCHA, Settings.densidade_vegetacao(30), 50.0, 0.7, 2.3)
		_montar_cabana(centro + Vector3(-55, 0, 8), "Cabana de Marta", Color(0.24, 0.15, 0.10))
		_montar_cabana(centro + Vector3(55, 0, -40), "Estação Florestal", Color(0.27, 0.20, 0.14))
		_montar_tenda_acampamento(centro + Vector3(20, 0, 57))
		_montar_luz(centro + Vector3(-55, 3.2, 8), Color(1.0, 0.56, 0.26), 10.0)
	elif region_id == "city":
		_montar_rua()
		for i: int in range(5):
			var x: float = centro.x + float(i - 2) * 34.0
			_montar_predio(
				Vector3(x, centro.y, -48.0), "Casa %02d" % i, Color(0.28 + 0.02 * i, 0.31, 0.35)
			)
			_montar_predio(
				Vector3(x, centro.y, 48.0), "Loja %02d" % i, Color(0.32, 0.26 + 0.02 * i, 0.22)
			)
		_montar_predio(centro + Vector3(-50, 0, 0), "Delegacia", Color(0.24, 0.29, 0.33))
		_montar_predio(centro + Vector3(50, 0, -2), "Farmácia", Color(0.28, 0.34, 0.29))
		_espalhar_multimesh(CENA_ROCHA, 12, 65.0, 0.3, 0.7)
	elif region_id == "complex":
		_montar_predio(
			centro + Vector3(0, 0, 0),
			"Complexo PANIC INC.",
			Color(0.16, 0.23, 0.26),
			Vector3(52, 19, 44)
		)
		_montar_predio(
			centro + Vector3(-62, 0, 28),
			"Anexo de Pesquisa",
			Color(0.22, 0.27, 0.29),
			Vector3(24, 11, 20)
		)
		_montar_predio(
			centro + Vector3(61, 0, -28), "Geradores", Color(0.26, 0.22, 0.17), Vector3(22, 9, 18)
		)
		_montar_luz(centro + Vector3(0, 7, 0), Color(0.16, 0.52, 0.70), 28.0)
	else:
		_montar_predio(
			centro + Vector3(0, 0, 0),
			"Câmara do Coração",
			Color(0.18, 0.10, 0.13),
			Vector3(58, 15, 56)
		)
		_montar_luz(centro + Vector3(0, 6, 0), Color(0.83, 0.08, 0.09), 32.0)
		_montar_luz(centro + Vector3(-35, 3, -28), Color(0.78, 0.10, 0.07), 13.0)
		_montar_luz(centro + Vector3(35, 3, 28), Color(0.78, 0.10, 0.07), 13.0)


func _montar_pontos_de_interesse() -> void:
	if region_id == "forest":
		_adicionar_interacao(
			"Marta", "npc_marta", centro + Vector3(-54, 0, 5), Color(0.72, 0.48, 0.39)
		)
		_adicionar_interacao(
			"Bilhete de Lucas", "nota_0", centro + Vector3(-48, 0, 10), Color(0.82, 0.75, 0.56)
		)
		_adicionar_interacao(
			"Aviso da Guarda Florestal",
			"nota_1",
			centro + Vector3(45, 0, -32),
			Color(0.72, 0.62, 0.40)
		)
		_adicionar_interacao(
			"Chave da estação",
			"chave_floresta",
			centro + Vector3(61, 0, -39),
			Color(0.83, 0.63, 0.22)
		)
		_adicionar_interacao(
			"Portão de Vale Sombrio",
			"portao_cidade",
			centro + Vector3(102, 0, 0),
			Color(0.25, 0.39, 0.42)
		)
		_adicionar_interacao(
			"Acampamento abandonado", "nota_2", centro + Vector3(20, 0, 53.5), Color(0.67, 0.51, 0.32)
		)
		_adicionar_interacao(
			"Lápide sem nome", "nota_3", centro + Vector3(-8, 0, -62), Color(0.52, 0.55, 0.56)
		)
		_adicionar_interacao(
			"Kit médico da cabana",
			"kit_forest",
			centro + Vector3(-47, 0, 16),
			Color(0.67, 0.83, 0.70)
		)
		_adicionar_interacao(
			"Bateria reserva",
			"bateria_forest",
			centro + Vector3(-64, 0, 16),
			Color(0.86, 0.76, 0.30)
		)
	elif region_id == "city":
		_adicionar_interacao(
			"Tomás", "npc_tomas", centro + Vector3(34, 0, 3), Color(0.44, 0.57, 0.61)
		)
		_adicionar_interacao(
			"Cartão da delegacia",
			"cartao_acesso",
			centro + Vector3(-50, 0, 5),
			Color(0.29, 0.68, 0.72)
		)
		_adicionar_interacao(
			"Relatório da Delegacia",
			"nota_5",
			centro + Vector3(-44, 0, -4),
			Color(0.72, 0.62, 0.40)
		)
		_adicionar_interacao(
			"Boletim da Rádio Vale", "nota_4", centro + Vector3(17, 0, 38), Color(0.72, 0.62, 0.40)
		)
		_adicionar_interacao(
			"Entrada do complexo",
			"porta_complexo",
			centro + Vector3(101, 0, 0),
			Color(0.29, 0.41, 0.48)
		)
		_adicionar_interacao(
			"Receita da farmácia", "nota_6", centro + Vector3(50, 0, 6), Color(0.72, 0.62, 0.40)
		)
		_adicionar_interacao(
			"Carta na igreja", "nota_7", centro + Vector3(-4, 0, -76), Color(0.72, 0.62, 0.40)
		)
		_adicionar_interacao(
			"Munição da loja de armas",
			"municao_cidade",
			centro + Vector3(12, 0, -18),
			Color(0.83, 0.55, 0.27)
		)
		_adicionar_interacao(
			"Kit médico", "kit_cidade", centro + Vector3(49, 0, 11), Color(0.67, 0.83, 0.70)
		)
	elif region_id == "complex":
		_adicionar_interacao(
			"Memorando do Projeto Coração",
			"nota_8",
			centro + Vector3(-22, 0, 11),
			Color(0.69, 0.72, 0.77)
		)
		_adicionar_interacao(
			"Memorando da Âncora", "nota_9", centro + Vector3(-43, 0, 12), Color(0.69, 0.72, 0.77)
		)
		_adicionar_interacao(
			"Diário de Lucas", "nota_10", centro + Vector3(17, 0, 12), Color(0.72, 0.62, 0.40)
		)
		_adicionar_interacao(
			"Gravação de Voss", "nota_11", centro + Vector3(37, 0, 12), Color(0.69, 0.72, 0.77)
		)
		_adicionar_interacao(
			"Laudo de autópsia", "nota_12", centro + Vector3(-24, 0, -12), Color(0.69, 0.72, 0.77)
		)
		_adicionar_interacao(
			"Terminal do elevador", "nota_13", centro + Vector3(0, 0, 20), Color(0.69, 0.72, 0.77)
		)
		_adicionar_interacao(
			"Fusível — sala de manutenção",
			"fusivel_1",
			centro + Vector3(-42, 0, -15),
			Color(0.87, 0.58, 0.18)
		)
		_adicionar_interacao(
			"Fusível — arquivo técnico",
			"fusivel_2",
			centro + Vector3(31, 0, -24),
			Color(0.87, 0.58, 0.18)
		)
		_adicionar_interacao(
			"Fusível — geradores",
			"fusivel_3",
			centro + Vector3(64, 0, -24),
			Color(0.87, 0.58, 0.18)
		)
		_adicionar_interacao(
			"Munição do depósito",
			"municao_complexo",
			centro + Vector3(47, 0, 8),
			Color(0.83, 0.55, 0.27)
		)
		_adicionar_interacao(
			"Bateria do gerador",
			"bateria_complexo",
			centro + Vector3(64, 0, -12),
			Color(0.86, 0.76, 0.30)
		)
		_adicionar_interacao(
			"Console do elevador", "elevador", centro + Vector3(0, 0, 17), Color(0.17, 0.68, 0.83)
		)
		_adicionar_interacao(
			"Elevador para o Nível -3",
			"elevador_subsolo",
			centro + Vector3(0, 0, 21),
			Color(0.31, 0.55, 0.68)
		)
	else:
		_adicionar_interacao(
			"Terminal de segurança",
			"nota_14",
			centro + Vector3(-33, 0, 30),
			Color(0.70, 0.71, 0.74)
		)
		_adicionar_interacao(
			"O Diretor", "chefe", centro + Vector3(0, 0, -13), Color(0.46, 0.14, 0.18)
		)
		_adicionar_interacao("Lucas", "lucas", centro + Vector3(0, 0, 18), Color(0.38, 0.55, 0.61))


func _espalhar_multimesh(
	caminhos: Array[String], quantidade: int, raio: float, escala_min: float, escala_max: float
) -> void:
	if caminhos.is_empty():
		return
	var por_tipo: int = maxi(1, ceili(float(quantidade) / float(caminhos.size())))
	for tipo: int in range(caminhos.size()):
		var cena: PackedScene = load(caminhos[tipo]) as PackedScene
		if cena == null:
			continue
		var instancia: Node = cena.instantiate()
		var malha: MeshInstance3D = _procurar_malha(instancia)
		if malha == null or malha.mesh == null:
			instancia.free()
			continue
		var multi: MultiMesh = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = malha.mesh.duplicate() as Mesh
		# Cenas GLB podem guardar o material como override no MeshInstance;
		# copiar só o Mesh deixa a vegetação branca ou invisível no MultiMesh.
		for superficie: int in range(malha.mesh.get_surface_count()):
			var material_superficie: Material = malha.get_active_material(superficie)
			if material_superficie != null:
				multi.mesh.surface_set_material(superficie, material_superficie)
		var total: int = mini(por_tipo, quantidade - tipo * por_tipo)
		multi.instance_count = maxi(total, 0)
		for i: int in range(multi.instance_count):
			var a: float = _rng.randf_range(0.0, TAU)
			var r: float = sqrt(_rng.randf()) * raio
			var altura: float = _rng.randf_range(escala_min, escala_max)
			var p: Vector3 = Vector3(centro.x + cos(a) * r, centro.y, centro.z + sin(a) * r)
			var basis: Basis = Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(
				Vector3.ONE * altura
			)
			multi.set_instance_transform(i, Transform3D(basis, p))
		var repetidor: MultiMeshInstance3D = MultiMeshInstance3D.new()
		repetidor.multimesh = multi
		repetidor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(repetidor)
		instancia.free()


func _plantar_pinheiros() -> void:
	# Folhagem explícita em tons de pinheiro; os GLBs de referência apareciam
	# brancos no driver integrado, por isso a floresta usa meshes leves próprios.
	var posicoes: Array[Vector3] = []
	var escalas: Array[float] = []
	var quantidade: int = Settings.densidade_vegetacao(100)
	for i: int in range(quantidade):
		var x: float = _rng.randf_range(-106.0, 106.0)
		var z: float = _rng.randf_range(-83.0, 83.0)
		# Deixa livre o caminho entre o ponto inicial e a cabana de Marta.
		if Vector2(x, z).distance_to(Vector2(-67.0, 5.0)) < 15.0:
			continue
		posicoes.append(centro + Vector3(x, 0.0, z))
		escalas.append(_rng.randf_range(0.78, 1.42))
	for i: int in range(14):
		var x_trilha: float = -79.0 + float(i) * 10.5
		var lado: float = -1.0 if i % 2 == 0 else 1.0
		posicoes.append(centro + Vector3(x_trilha, 0.0, 5.0 + lado * _rng.randf_range(17.0, 23.0)))
		escalas.append(_rng.randf_range(0.85, 1.25))

	var tronco: CylinderMesh = CylinderMesh.new()
	tronco.top_radius = 0.17
	tronco.bottom_radius = 0.27
	tronco.height = 3.0
	tronco.radial_segments = 7
	_adicionar_camada_pinheiros(tronco, _mat(Color(0.20, 0.105, 0.062)), posicoes, escalas, 1.5)
	var cores: Array[Color] = [
		Color(0.035, 0.115, 0.067), Color(0.045, 0.155, 0.082), Color(0.065, 0.19, 0.10)
	]
	var alturas: Array[float] = [2.5, 3.55, 4.45]
	var raios: Array[float] = [1.65, 1.25, 0.87]
	for camada: int in range(3):
		var copa: CylinderMesh = CylinderMesh.new()
		copa.top_radius = 0.0
		copa.bottom_radius = raios[camada]
		copa.height = 3.0 - float(camada) * 0.28
		copa.radial_segments = 7
		_adicionar_camada_pinheiros(
			copa, _mat(cores[camada]), posicoes, escalas, alturas[camada]
		)


func _adicionar_camada_pinheiros(
	malha: Mesh, material: Material, posicoes: Array[Vector3], escalas: Array[float], altura: float
) -> void:
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = malha
	multimesh.instance_count = posicoes.size()
	for i: int in range(posicoes.size()):
		var escala: float = escalas[i]
		var base: Vector3 = posicoes[i] + Vector3.UP * altura * escala
		var transformacao: Transform3D = Transform3D(
			Basis(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(Vector3.ONE * escala), base
		)
		multimesh.set_instance_transform(i, transformacao)
	var instancia: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instancia.multimesh = multimesh
	instancia.material_override = material
	instancia.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instancia)


func _procurar_malha(no: Node) -> MeshInstance3D:
	if no is MeshInstance3D and no.mesh != null:
		return no as MeshInstance3D
	for filho: Node in no.get_children():
		var encontrada: MeshInstance3D = _procurar_malha(filho)
		if encontrada != null:
			return encontrada
	return null


func _montar_cabana(pos: Vector3, nome: String, cor: Color) -> void:
	var raiz: Node3D = Node3D.new()
	raiz.name = nome.replace(" ", "")
	raiz.position = pos
	add_child(raiz)
	var madeira: StandardMaterial3D = StandardMaterial3D.new()
	madeira.albedo_texture = TEXTURA_PINHO
	madeira.albedo_color = cor
	madeira.roughness = 0.9
	# Paredes físicas. A fachada oeste deixa um vão de 3,8 m para a porta.
	_adicionar_cubo(raiz, "ParedeNorte", Vector3(0, 2.0, -4), Vector3(10, 4, 0.5), madeira, true)
	_adicionar_cubo(raiz, "ParedeSul", Vector3(0, 2.0, 4), Vector3(10, 4, 0.5), madeira, true)
	_adicionar_cubo(raiz, "ParedeLeste", Vector3(5, 2.0, 0), Vector3(0.5, 4, 8), madeira, true)
	_adicionar_cubo(raiz, "ParedeOesteA", Vector3(-5, 2.0, -3.0), Vector3(0.5, 4, 2.0), madeira, true)
	_adicionar_cubo(raiz, "ParedeOesteB", Vector3(-5, 2.0, 3.0), Vector3(0.5, 4, 2.0), madeira, true)
	_adicionar_cubo(raiz, "VergaDaPorta", Vector3(-5, 3.72, 0), Vector3(0.5, 0.56, 4.0), madeira, true)
	_montar_porta_cabana(
		raiz, madeira, "porta_marta" if nome == "Cabana de Marta" else "porta_estacao"
	)
	var telhado_mat: StandardMaterial3D = madeira.duplicate() as StandardMaterial3D
	telhado_mat.albedo_color = cor.darkened(0.32)
	var telhado: PrismMesh = PrismMesh.new()
	telhado.size = Vector3(12, 2, 10)
	var telha: MeshInstance3D = MeshInstance3D.new()
	telha.mesh = telhado
	telha.position = Vector3(0, 5, 0)
	telha.material_override = telhado_mat
	raiz.add_child(telha)
	for x: int in range(4):
		var toras: MeshInstance3D = MeshInstance3D.new()
		var cil: CylinderMesh = CylinderMesh.new()
		cil.top_radius = 0.17
		cil.bottom_radius = 0.19
		cil.height = 10.2
		toras.mesh = cil
		toras.rotation.z = PI / 2.0
		toras.position = Vector3(0, 0.35 + float(x) * 0.2, -4.28)
		toras.material_override = madeira
		raiz.add_child(toras)
	var janela: MeshInstance3D = MeshInstance3D.new()
	var vidro: BoxMesh = BoxMesh.new()
	vidro.size = Vector3(0.12, 1.0, 1.1)
	janela.mesh = vidro
	janela.position = Vector3(5.28, 2.2, 0.2)
	var vidro_mat: StandardMaterial3D = StandardMaterial3D.new()
	vidro_mat.albedo_color = Color(0.20, 0.42, 0.48)
	vidro_mat.emission_enabled = true
	vidro_mat.emission = Color(0.98, 0.42, 0.19)
	vidro_mat.emission_energy_multiplier = 1.8
	janela.material_override = vidro_mat
	raiz.add_child(janela)
	# Moldura simples para dar leitura de janela sem aumentar custo de renderização.
	var moldura_mat: StandardMaterial3D = madeira.duplicate() as StandardMaterial3D
	for lado: float in [-1.0, 1.0]:
		_adicionar_cubo(
			raiz, "MolduraJanela_%s" % str(lado), Vector3(5.36, 2.2, 0.2 + lado * 0.68),
			Vector3(0.18, 1.22, 0.12), moldura_mat
		)
	_adicionar_cubo(
		raiz, "PeitorilJanela", Vector3(5.38, 1.58, 0.2), Vector3(0.24, 0.12, 1.5), moldura_mat
	)


func _montar_tenda_acampamento(pos: Vector3) -> void:
	var abrigo: Node3D = Node3D.new()
	abrigo.name = "TendaDoAcampamento"
	abrigo.position = pos
	add_child(abrigo)
	var visual: Node3D = CENA_TENDA.instantiate() as Node3D
	visual.name = "ModeloKenney"
	visual.scale = Vector3.ONE * 8.0
	abrigo.add_child(visual)
	var porta: CabinDoor = CabinDoor.new()
	porta.name = "PortaInterativa"
	porta.position = Vector3(-0.72, 0.0, -2.14)
	abrigo.add_child(porta)
	var aba: MeshInstance3D = MeshInstance3D.new()
	aba.name = "AbaDaTenda"
	var malha: BoxMesh = BoxMesh.new()
	malha.size = Vector3(1.45, 2.82, 0.10)
	aba.mesh = malha
	aba.position = Vector3(0.73, 1.41, 0.0)
	var lona: StandardMaterial3D = StandardMaterial3D.new()
	lona.albedo_color = Color(0.16, 0.22, 0.17)
	lona.roughness = 0.98
	aba.material_override = lona
	porta.add_child(aba)
	var colisao: CollisionShape3D = CollisionShape3D.new()
	colisao.name = "ColisaoDaPorta"
	var caixa: BoxShape3D = BoxShape3D.new()
	caixa.size = malha.size
	colisao.shape = caixa
	colisao.position = aba.position
	porta.add_child(colisao)
	var ponto: Interactable = Interactable.new()
	ponto.name = "PontoDeInteracao"
	ponto.nome_exibido = "Abrir a lona"
	ponto.acao = "porta_tenda"
	ponto.position = Vector3(0.73, 0.0, 0.2)
	ponto.cor = Color(0.65, 0.72, 0.48)
	ponto.show_marker = false
	porta.add_child(ponto)


func _montar_porta_cabana(raiz: Node3D, madeira: StandardMaterial3D, acao: String) -> void:
	var porta: CabinDoor = CabinDoor.new()
	porta.name = "PortaInterativa"
	porta.position = Vector3(-4.72, 0.0, -1.82)
	raiz.add_child(porta)
	var folha: MeshInstance3D = MeshInstance3D.new()
	folha.name = "Folha"
	var malha: BoxMesh = BoxMesh.new()
	malha.size = Vector3(0.18, 3.55, 3.55)
	folha.mesh = malha
	folha.position = Vector3(0.0, 1.78, 1.82)
	var madeira_porta: StandardMaterial3D = StandardMaterial3D.new()
	madeira_porta.albedo_texture = TEXTURA_PINHO
	madeira_porta.albedo_color = Color(0.25, 0.14, 0.085)
	madeira_porta.roughness = 0.92
	folha.material_override = madeira_porta
	porta.add_child(folha)
	var macaneta: MeshInstance3D = MeshInstance3D.new()
	macaneta.name = "Macaneta"
	var esfera: SphereMesh = SphereMesh.new()
	esfera.radius = 0.085
	esfera.height = 0.17
	macaneta.mesh = esfera
	macaneta.position = Vector3(-0.14, 1.76, 3.34)
	var metal: StandardMaterial3D = StandardMaterial3D.new()
	metal.albedo_color = Color(0.48, 0.31, 0.12)
	metal.metallic = 0.68
	metal.roughness = 0.34
	macaneta.material_override = metal
	porta.add_child(macaneta)
	var colisao: CollisionShape3D = CollisionShape3D.new()
	colisao.name = "ColisaoDaPorta"
	var caixa: BoxShape3D = BoxShape3D.new()
	caixa.size = malha.size
	colisao.shape = caixa
	colisao.position = folha.position
	porta.add_child(colisao)
	var marco: StandardMaterial3D = madeira.duplicate() as StandardMaterial3D
	for lado: float in [-1.0, 1.0]:
		_adicionar_cubo(
			raiz, "Batente_%s" % str(lado), Vector3(-4.70, 1.78, lado * 1.92),
			Vector3(0.28, 3.6, 0.22), marco
		)
	var ponto: Interactable = Interactable.new()
	ponto.name = "PontoDeInteracao"
	ponto.nome_exibido = "Abrir a porta" if acao == "porta_marta" else "Abrir a estação"
	ponto.acao = acao
	ponto.position = Vector3(0.0, 0.0, 1.82)
	ponto.cor = Color(0.78, 0.57, 0.30)
	ponto.show_marker = false
	porta.add_child(ponto)


func _montar_predio(
	pos: Vector3, nome: String, cor: Color, dimensoes: Vector3 = Vector3(18, 12, 16)
) -> void:
	var raiz: Node3D = Node3D.new()
	raiz.name = nome.replace(" ", "")
	raiz.position = pos
	add_child(raiz)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = TEXTURA_CONCRETO
	material.albedo_color = cor
	material.roughness = 0.84
	material.uv1_scale = Vector3(2.0, 2.0, 1.0)
	var espessura: float = 1.0
	var altura_parede: float = dimensoes.y
	var largura_porta: float = minf(7.0, dimensoes.x * 0.28)
	var largura_frente: float = (dimensoes.x - largura_porta) * 0.5
	_adicionar_cubo(
		raiz,
		"ParedeFundo",
		Vector3(0, altura_parede * 0.5, -dimensoes.z * 0.5),
		Vector3(dimensoes.x, altura_parede, espessura),
		material,
		true
	)
	_adicionar_cubo(
		raiz,
		"ParedeEsquerda",
		Vector3(-dimensoes.x * 0.5, altura_parede * 0.5, 0),
		Vector3(espessura, altura_parede, dimensoes.z),
		material,
		true
	)
	_adicionar_cubo(
		raiz,
		"ParedeDireita",
		Vector3(dimensoes.x * 0.5, altura_parede * 0.5, 0),
		Vector3(espessura, altura_parede, dimensoes.z),
		material,
		true
	)
	_adicionar_cubo(
		raiz,
		"FachadaEsquerda",
		Vector3(-(largura_porta + largura_frente) * 0.5, altura_parede * 0.5, dimensoes.z * 0.5),
		Vector3(largura_frente, altura_parede, espessura),
		material,
		true
	)
	_adicionar_cubo(
		raiz,
		"FachadaDireita",
		Vector3((largura_porta + largura_frente) * 0.5, altura_parede * 0.5, dimensoes.z * 0.5),
		Vector3(largura_frente, altura_parede, espessura),
		material,
		true
	)
	var metal: StandardMaterial3D = StandardMaterial3D.new()
	metal.albedo_color = cor.darkened(0.38)
	metal.metallic = 0.48
	metal.roughness = 0.46
	var beiral: BoxMesh = BoxMesh.new()
	beiral.size = Vector3(dimensoes.x + 0.7, 0.35, dimensoes.z + 0.7)
	var telhado: MeshInstance3D = MeshInstance3D.new()
	telhado.mesh = beiral
	telhado.position.y = dimensoes.y + 0.16
	telhado.material_override = metal
	raiz.add_child(telhado)
	var janela_mat: StandardMaterial3D = StandardMaterial3D.new()
	janela_mat.albedo_color = Color(0.13, 0.23, 0.28)
	janela_mat.emission_enabled = true
	janela_mat.emission = Color(0.26, 0.38, 0.42)
	janela_mat.emission_energy_multiplier = 0.55
	for lado: int in [-1, 1]:
		var painel: BoxMesh = BoxMesh.new()
		painel.size = Vector3(2.4, 1.4, 0.12)
		var vidro: MeshInstance3D = MeshInstance3D.new()
		vidro.mesh = painel
		vidro.material_override = janela_mat
		vidro.position = Vector3(
			float(lado) * minf(dimensoes.x * 0.32, largura_porta * 0.5 + 2.5),
			dimensoes.y * 0.57,
			dimensoes.z * 0.5 + 0.08
		)
		raiz.add_child(vidro)


func _montar_rua() -> void:
	var via: MeshInstance3D = MeshInstance3D.new()
	var malha: PlaneMesh = PlaneMesh.new()
	malha.size = Vector2(200, 17)
	malha.subdivide_width = 32
	via.mesh = malha
	via.position = Vector3(centro.x, centro.y + 0.01, centro.z)
	var asfalto: StandardMaterial3D = StandardMaterial3D.new()
	asfalto.albedo_texture = TEXTURA_CONCRETO
	asfalto.albedo_color = Color(0.25, 0.27, 0.27)
	asfalto.roughness = 0.97
	asfalto.uv1_scale = Vector3(30, 3, 1)
	via.material_override = asfalto
	add_child(via)
	for faixa: int in range(28):
		_adicionar_cubo(
			self,
			"FaixaViaria_%02d" % faixa,
			Vector3(centro.x - 97.0 + faixa * 7.2, centro.y + 0.035, centro.z),
			Vector3(3.2, 0.03, 0.12),
			_mat(Color(0.75, 0.66, 0.43))
		)


func _adicionar_cubo(
	pai: Node3D,
	nome: String,
	pos: Vector3,
	escala: Vector3,
	material: Material,
	colisao: bool = false
) -> MeshInstance3D:
	var malha: BoxMesh = BoxMesh.new()
	malha.size = escala
	var instancia: MeshInstance3D = MeshInstance3D.new()
	instancia.name = nome
	instancia.mesh = malha
	instancia.position = pos
	instancia.material_override = material
	pai.add_child(instancia)
	if colisao:
		var corpo: StaticBody3D = StaticBody3D.new()
		corpo.name = "Colisao_" + nome
		corpo.position = pos
		var forma: CollisionShape3D = CollisionShape3D.new()
		var caixa: BoxShape3D = BoxShape3D.new()
		caixa.size = escala
		forma.shape = caixa
		corpo.add_child(forma)
		pai.add_child(corpo)
	return instancia


func _adicionar_interacao(rotulo: String, acao: String, pos: Vector3, cor: Color) -> void:
	if acao.begins_with("npc_") or acao == "lucas":
		var personagem: PanicNPC = PanicNPC.new()
		personagem.nome = (
			"Marta" if acao == "npc_marta" else ("Lucas" if acao == "lucas" else "Tomás")
		)
		personagem.visual_id = "marta" if acao == "npc_marta" else "tomas"
		personagem.position = pos
		add_child(personagem)
		var ponto_pessoa: Interactable = Interactable.new()
		ponto_pessoa.nome_exibido = rotulo
		ponto_pessoa.acao = acao
		ponto_pessoa.cor = cor
		ponto_pessoa.show_marker = false
		personagem.add_child(ponto_pessoa)
		return
	var ponto: Interactable = Interactable.new()
	ponto.nome_exibido = rotulo
	ponto.acao = acao
	ponto.position = pos
	ponto.cor = cor
	add_child(ponto)


func _montar_luz(pos: Vector3, cor: Color, alcance: float) -> void:
	var luz: OmniLight3D = OmniLight3D.new()
	luz.position = pos
	luz.light_color = cor
	luz.light_energy = 1.6
	luz.omni_range = alcance
	luz.shadow_enabled = true
	add_child(luz)


func _mat(cor: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = cor
	material.roughness = 0.94
	return material
