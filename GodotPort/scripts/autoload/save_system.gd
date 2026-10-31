extends Node

const CAMINHO_SAVE: String = "user://panicinc_save.json"


func salvar() -> bool:
	var arquivo: FileAccess = FileAccess.open(CAMINHO_SAVE, FileAccess.WRITE)
	if arquivo == null:
		return false
	arquivo.store_string(JSON.stringify(GameState.snapshot(), "\t"))
	return true


func carregar() -> bool:
	if not FileAccess.file_exists(CAMINHO_SAVE):
		return false
	var arquivo: FileAccess = FileAccess.open(CAMINHO_SAVE, FileAccess.READ)
	if arquivo == null:
		return false
	var dados: Variant = JSON.parse_string(arquivo.get_as_text())
	if not dados is Dictionary:
		return false
	GameState.restaurar_snapshot(dados)
	return true
