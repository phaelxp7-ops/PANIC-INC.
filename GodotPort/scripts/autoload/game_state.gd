extends Node
## Estado pequeno e serializável. No coop, o servidor é a fonte da verdade.

const CAMINHO_HISTORIA: String = "res://resources/story/historia.json"

var historia: Dictionary = {}
var flags: Dictionary = {}
var inventario: Dictionary = {"municao": 0, "kits": 0, "calmantes": 0, "baterias": 1, "fusives": 0}
var notas: Array[int] = []
var vida: float = 100.0
var sanidade: float = 100.0
var bateria: float = 100.0
var stamina: float = 100.0
var tempo_jogo: float = 0.0
var dificuldade: int = 1
var final_escolhido: String = ""


func _ready() -> void:
	var arquivo: FileAccess = FileAccess.open(CAMINHO_HISTORIA, FileAccess.READ)
	if arquivo != null:
		var dados: Variant = JSON.parse_string(arquivo.get_as_text())
		if dados is Dictionary:
			historia = dados
	_resetar_flags()


func iniciar_novo_jogo() -> void:
	_resetar_flags()
	inventario = {"municao": 0, "kits": 0, "calmantes": 0, "baterias": 1, "fusives": 0}
	notas.clear()
	vida = 100.0
	sanidade = 100.0
	bateria = 100.0
	stamina = 100.0
	tempo_jogo = 0.0
	dificuldade = 1
	final_escolhido = ""
	_emitir_estado()


func _resetar_flags() -> void:
	flags = {
		"falou_marta": false,
		"chave_floresta": false,
		"portao_cidade": false,
		"falou_tomas": false,
		"cartao_acesso": false,
		"porta_complexo": false,
		"elevador_ativo": false,
		"diretor_derrotado": false,
		"lucas_encontrado": false,
		"final": ""
	}


func tem_flag(nome: String) -> bool:
	return bool(flags.get(nome, false))


func definir_flag(nome: String, valor: Variant = true) -> void:
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		rpc_id(1, "solicitar_flag", nome, valor)
		return
	flags[nome] = valor
	if nome == "fusivel_coletado":
		inventario["fusives"] = int(inventario.get("fusives", 0)) + 1
	if nome == "sanidade_bonus":
		dificuldade = maxi(1, dificuldade)
	_emitir_estado()


func adicionar_nota(id_nota: int) -> void:
	if id_nota < 0 or id_nota >= 15 or notas.has(id_nota):
		return
	notas.append(id_nota)
	notas.sort()
	EventBus.notas_alteradas.emit()
	EventBus.mensagem.emit("Nota adicionada ao diário.", 2.4)
	_emitir_estado()


func adicionar_item(nome: String, quantidade: int = 1) -> void:
	inventario[nome] = int(inventario.get(nome, 0)) + quantidade
	_emitir_estado()


func gastar_item(nome: String, quantidade: int = 1) -> bool:
	var atual: int = int(inventario.get(nome, 0))
	if atual < quantidade:
		return false
	inventario[nome] = atual - quantidade
	_emitir_estado()
	return true


func objetivo_atual() -> String:
	if not tem_flag("falou_marta"):
		return "Encontre Marta na cabana iluminada."
	if not tem_flag("chave_floresta"):
		return "Procure a chave do portão na Estação Florestal, ao norte."
	if not tem_flag("portao_cidade"):
		return "Use a chave para atravessar o portão de Vale Sombrio."
	if not tem_flag("falou_tomas"):
		return "Encontre Tomás junto ao rádio da cidade."
	if not tem_flag("cartao_acesso"):
		return "Recupere o cartão-mestre na sala de evidências da delegacia."
	if not tem_flag("porta_complexo"):
		return "Abra a entrada do Complexo PANIC INC."
	if int(inventario.get("fusives", 0)) < 3:
		return "Encontre os 3 fusíveis espalhados pelo complexo."
	if not tem_flag("elevador_ativo"):
		return "Ative o elevador de serviço no setor sul."
	if not tem_flag("diretor_derrotado"):
		return "Desça ao Nível -3 e enfrente O Diretor."
	if not tem_flag("lucas_encontrado"):
		return "Encontre Lucas perto do Coração."
	if final_escolhido.is_empty():
		return "Decida o destino do Coração."
	return "Fim: " + ("O Descanso" if final_escolhido == "descanso" else "O Eco do Medo")


func snapshot() -> Dictionary:
	return {
		"flags": flags.duplicate(true),
		"inventario": inventario.duplicate(true),
		"notas": notas.duplicate(),
		"vida": vida,
		"sanidade": sanidade,
		"bateria": bateria,
		"stamina": stamina,
		"tempo_jogo": tempo_jogo,
		"dificuldade": dificuldade,
		"final_escolhido": final_escolhido
	}


func restaurar_snapshot(dados: Dictionary) -> void:
	var notas_anteriores: Array[int] = notas.duplicate()
	flags = dados.get("flags", flags).duplicate(true)
	inventario = dados.get("inventario", inventario).duplicate(true)
	notas.clear()
	var lista_notas: Variant = dados.get("notas", [])
	if lista_notas is Array:
		for item: Variant in lista_notas:
			var id_nota: int = int(item)
			if id_nota >= 0 and id_nota < 15 and not notas.has(id_nota):
				notas.append(id_nota)
	notas.sort()
	vida = float(dados.get("vida", 100.0))
	sanidade = float(dados.get("sanidade", 100.0))
	bateria = float(dados.get("bateria", 100.0))
	stamina = float(dados.get("stamina", 100.0))
	tempo_jogo = float(dados.get("tempo_jogo", 0.0))
	dificuldade = int(dados.get("dificuldade", 1))
	final_escolhido = str(dados.get("final_escolhido", ""))
	if notas != notas_anteriores:
		EventBus.notas_alteradas.emit()
	_emitir_estado()


func _emitir_estado() -> void:
	EventBus.estado_alterado.emit()
	EventBus.objetivo_alterado.emit(objetivo_atual())
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		rpc("receber_snapshot", snapshot())


@rpc("any_peer", "reliable")
func solicitar_flag(nome: String, valor: Variant) -> void:
	if not multiplayer.is_server():
		return
	var remetente: int = multiplayer.get_remote_sender_id()
	if (
		remetente <= 0
		or (
			nome
			not in [
				"falou_marta",
				"chave_floresta",
				"portao_cidade",
				"falou_tomas",
				"cartao_acesso",
				"porta_complexo",
				"elevador_ativo",
				"diretor_derrotado",
				"lucas_encontrado",
				"final"
			]
		)
	):
		return
	flags[nome] = valor
	_emitir_estado()


@rpc("authority", "reliable")
func receber_snapshot(dados: Dictionary) -> void:
	restaurar_snapshot(dados)
