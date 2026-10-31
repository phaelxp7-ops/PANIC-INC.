# PANIC INC. — protótipo GameMaker

Esta pasta contém os quatro eventos de `obj_panic` da versão v4: `Create_0.gml`, `Step_0.gml`, `Draw_0.gml` e `Draw_64.gml` (Draw GUI). O projeto original `.yyp` e os recursos do GameMaker ainda não estão neste repositório; portanto os arquivos são fontes para colar nos eventos correspondentes, não um projeto pronto para abrir.

## O que entrou nesta versão

- Campanha contínua por quatro regiões: floresta, Vale Sombrio, complexo PANIC INC. e subsolo.
- História de Ana procurando o irmão Lucas, contada por cenas, diálogos e documentos que podem ser relidos no diário.
- Progressão com chave, cartão de acesso e fusíveis para abrir áreas; há suprimentos, checkpoints e ameaças que mudam conforme a região.
- Encontros com quatro tipos de inimigo, sustos e alucinações ligados à sanidade, apagões e armadilhas. Sobreviventes opcionais aparecem em lugares sorteados: podem dar suprimentos ou atrair uma emboscada. A campanha culmina numa luta em três fases contra o Diretor.
- Dois finais com escolha do jogador.
- Câmera 3D com mouse na horizontal e vertical, modo 2D e interface com objetivo, inventário, sanidade e mapa explorado.
- Malhas low-poly e detalhes procedurais para as criaturas. A arte é geométrica, não há modelos ou texturas realistas importados.

## Eventos e controles

Copie cada arquivo para o evento com o mesmo nome no objeto `obj_panic`:

| Arquivo | Evento do GameMaker |
| --- | --- |
| `Create_0.gml` | Create |
| `Step_0.gml` | Step |
| `Draw_0.gml` | Draw |
| `Draw_64.gml` | Draw GUI |

Controles principais: `WASD` move; `Shift` corre; mouse move a câmera no modo 3D; `Tab` alterna 2D/3D; `E` interage; `F` alterna lanterna; clique esquerdo ou espaço dispara; `H` usa cura; `Q` usa calmante; `R` usa bateria; `J` abre o diário; `M` abre o mapa; `N` alterna o som; `Esc` pausa.

## Limites de integração

- O modo multiplayer não foi implementado nesta versão. A estrutura de `player` mantém campos para sincronização futura, mas não há lobby, servidor, replicação nem conexão de rede.
- O mapa é gerado e desenhado por código. É uma base jogável de exploração, não um mundo aberto com arte final, navegação por quests ou saves de campanha completos.
- O repositório ainda não tem `.yyp`, sprites, fontes importadas nem projeto para compilar. A integração e compilação precisam acontecer no projeto real do GameMaker.


