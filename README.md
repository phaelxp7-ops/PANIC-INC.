# PANIC-INC.

## Visão geral

RPG de terror e sobrevivência no qual Ana atravessa a floresta, Vale Sombrio e as instalações da PANIC INC. para encontrar o irmão Lucas. O protótipo inclui exploração em áreas conectadas, combate e furtividade, documentos de história, personagens, gestão de sanidade e recursos, e um confronto final com dois desfechos. Multiplayer permanece como objetivo futuro, ainda sem rede implementada.

## Organização do projeto

- `src/`: projeto do GameMaker Studio (`.yyp`) e seus recursos.
- `docs/`: documentação de game design, mecânicas, ideias e decisões do projeto.
- `assets_raw/`: arquivos-fonte de arte e áudio antes da importação no GameMaker, como `.psd`, `.wav` e `.aseprite`.

## Divisão de tarefas

| Pessoa | Responsabilidades |
| --- | --- |
| **Dev 1** | Sistemas, lógica de jogo, arquitetura e rede/multiplayer. |
| **Dev 2** | Level design, arte, sprites, rooms e áudio. |

As responsabilidades podem ser combinadas em conjunto quando uma tarefa atravessar essas áreas. Registrem decisões importantes em `docs/`.

## Workflow com Git

1. Atualize sua branch base antes de começar: `git switch main` e `git pull`.
2. Crie uma branch individual por tarefa, por exemplo: `git switch -c feat/movimento-jogador` ou `git switch -c art/primeira-room`.
3. Faça commits pequenos e com mensagens claras. Envie a branch e abra um Pull Request para revisão antes de integrar à `main`.
4. No GameMaker, evitem editar a mesma **Room** ao mesmo tempo. O arquivo da Room pode concentrar mudanças de posicionamento e instâncias difíceis de mesclar. Combinem quem ficará responsável por cada Room.
5. Dividam o trabalho por recursos e arquivos sempre que possível. Antes de sincronizar, salvem o projeto no GameMaker, revisem `git status` e façam pull da branch base.
6. Não incluam builds, exports, logs ou arquivos pessoais do editor. O `.gitignore` da raiz já cobre esses itens.

## Próximas tarefas

### Dev 1 — Sistemas, lógica e rede/multiplayer

- [ ] Adicionar o projeto `.yyp` real e vincular os quatro eventos de `obj_panic`.
- [ ] Compilar no GameMaker e corrigir erros de runtime com o log do IDE.
- [ ] Testar a progressão da floresta até o chefe e equilibrar recursos/dificuldade.
- [ ] Definir a arquitetura de servidor, lobby e sincronização antes de iniciar o multiplayer.

### Dev 2 — Level design, arte, sprites, rooms e áudio

- [ ] Criar sprites/modelos próprios para Ana, NPCs, monstros e Diretor; substituir os desenhos procedurais.
- [ ] Criar texturas e elementos de cenário para diferenciar as quatro regiões.
- [ ] Preparar efeitos de áudio originais para exploração, sustos, inimigos e chefe.
- [ ] Validar visibilidade, animações e leitura da HUD nos modos 2D e 3D.

## Protótipo atual

Os quatro eventos-fonte de `obj_panic` ficam em [`src/obj_panic/`](src/obj_panic/). Consulte [`src/README.md`](src/README.md) para os controles, conteúdo e passos de integração. O `.yyp` e os recursos do GameMaker ainda precisam ser adicionados para abrir e compilar o jogo diretamente pelo IDE.

