# PANIC INC. — código do protótipo

Estes arquivos vieram dos eventos enviados: `Create_0.gml`, `Step_0.gml`, `Draw_0.gml` e `Draw_64.gml` para `obj_panic`. Eles são fonte de referência/importação; o repositório ainda não contém um `.yyp` nem metadados de recursos para abrir como projeto GameMaker completo.

## Evolução para exploração RPG

- Cada contrato gera uma área ampla e contínua, com salas conectadas, estruturas sorteadas (arquivo, enfermaria, subestação e abrigo) e saída opcional depois de completar o objetivo.
- A dificuldade de cada estrutura varia conforme a distância e o sorteio da geração: áreas de risco maior podem gerar perseguidores mais fortes e causar mais dano.
- O jogador recebe XP ao recuperar documentos. Ao subir de nível de campo, aumenta vida e vigor e recupera parte dos recursos.
- No modo 3D, o mouse controla a visão horizontal e vertical; o minimapa acompanha os mapas maiores.
- Pisos e paredes usam paletas procedurais por estrutura, além de grades, faixas e marcas geométricas. São detalhes em cores de vértice; o projeto ainda não tem texturas bitmap/modelos 3D próprios.

Para importar a versão atual, substitua os eventos correspondentes de `obj_panic` pelos quatro arquivos `.gml` desta pasta e salve no GameMaker. O repositório ainda não contém o `.yyp` real, portanto esses arquivos não são um projeto instalável por si só.

## Multiplayer online — próximo passo implementado como preparação

A lógica atual usa um único `player` global e simula todos os inimigos localmente. Para multiplayer online confiável, a sessão precisa de servidor autoritativo: o servidor valida movimento, coleta, dano, alarmes, inimigos e fim de fase; clientes enviam comandos e recebem snapshots. A conexão TCP do GameMaker sozinha não fornece matchmaking nem atravessa NAT. É necessário definir servidor público/relay e protocolo de lobby antes de habilitar “Criar/Entrar”.

Ordem de integração:

1. Abrir o `.yyp` real em `src/` e converter `player` em lista de jogadores identificados.
2. Separar input local de simulação e replicação de estado.
3. Implementar eventos assíncronos de rede e reconexão, com mensagens versionadas e validação no host.
4. Adicionar lobby/invite, teste com duas instâncias e tratar desconexão/retorno.

Não há serviço público de servidor configurado, então o modo online ainda não pode ser anunciado como jogável.

