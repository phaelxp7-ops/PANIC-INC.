extends SceneTree
## Valida os chunks e gera um manifesto de conteúdo reproduzível.

const REGIOES: Array[String] = [
	"res://scenes/regions/forest.tscn",
	"res://scenes/regions/city.tscn",
	"res://scenes/regions/complex.tscn",
	"res://scenes/regions/subsoil.tscn"
]

func _initialize() -> void:
	var registro: Array[Dictionary] = []
	for caminho: String in REGIOES:
		var cena: PackedScene = load(caminho) as PackedScene
		if cena == null:
			push_error("Chunk ausente ou inválido: " + caminho)
			quit(1)
			return
		var instancia: Node = cena.instantiate()
		var script: Script = instancia.get_script() as Script
		registro.append({"cena": caminho, "raiz": instancia.name, "gerador": script.resource_path if script != null else ""})
		instancia.free()
	var arquivo: FileAccess = FileAccess.open("res://docs/world_manifest.json", FileAccess.WRITE)
	if arquivo == null:
		push_error("Não foi possível gravar docs/world_manifest.json")
		quit(1)
		return
	arquivo.store_string(JSON.stringify({"gerado_por": "tools/build_world.gd", "regioes": registro}, "\t"))
	print("Manifesto atualizado: ", registro.size(), " regiões validadas.")
	quit(0)
