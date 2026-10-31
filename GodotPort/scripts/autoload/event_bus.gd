extends Node
## Sinais compartilhados entre sistemas; evite dependências diretas entre cenas.

signal mensagem(texto: String, duracao: float)
signal estado_alterado
signal notas_alteradas
signal objetivo_alterado(texto: String)
signal conexao_alterada(texto: String)
signal susto(intensidade: float)
signal jogador_derrotado(peer_id: int)
signal ping_recebido(posicao: Vector3, remetente: String)
