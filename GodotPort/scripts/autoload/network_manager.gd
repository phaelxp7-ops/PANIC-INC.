extends Node
## Host listen ENet (1 servidor + até 3 clientes). A camada está pronta para Steam depois.

const PORTA: int = 27840
const MAX_CLIENTES: int = 3
var ultimo_erro: String = ""


func iniciar_solo() -> Error:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	ultimo_erro = ""
	return OK


func criar_partida() -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var erro: Error = peer.create_server(PORTA, MAX_CLIENTES)
	if erro == OK:
		multiplayer.multiplayer_peer = peer
		ultimo_erro = ""
		EventBus.conexao_alterada.emit("Servidor aberto na porta %d" % PORTA, 3.0)
	else:
		ultimo_erro = "Não foi possível abrir a porta %d (erro %d)." % [PORTA, erro]
	return erro


func entrar_partida(ip: String) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var erro: Error = peer.create_client(ip.strip_edges(), PORTA)
	if erro == OK:
		multiplayer.multiplayer_peer = peer
		ultimo_erro = ""
	else:
		ultimo_erro = "Não foi possível conectar a %s (erro %d)." % [ip, erro]
	return erro


func encerrar() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
