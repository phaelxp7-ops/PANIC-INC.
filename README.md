# PANIC-INC.

## Visão geral

RPG de terror e sobrevivência no qual Ana atravessa a floresta, Vale Sombrio e as instalações da PANIC INC. para encontrar o irmão Lucas. O protótipo inclui exploração em áreas conectadas, combate e furtividade, documentos de história, personagens, gestão de sanidade e recursos, e um confronto final com dois desfechos. Multiplayer permanece como objetivo futuro, ainda sem rede implementada.

## Abrir no GameMaker

Abra [`PANIC INC..yyp`](PANIC%20INC..yyp) na raiz do repositório e execute com F5.
Os quatro eventos do objeto principal ficam em `objects/obj_panic/`. Os shaders
de pós-processamento estão em `shaders/` e são registrados no projeto.

`src/` mantém os fontes GML e scripts/ferramentas de materiais usados para
regenerar texturas. `docs/` reúne documentação; `assets_raw/` guarda arquivos
brutos de arte e áudio ainda não importados.

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

- [x] Compilar e abrir a introdução até a floresta 2D no GameMaker.
- [ ] Implementar iluminação por pixel com máscaras de luz e sombras suaves.
- [ ] Testar a progressão da floresta até o chefe e equilibrar recursos/dificuldade.
- [ ] Definir a arquitetura de servidor, lobby e sincronização antes de iniciar o multiplayer.

### Dev 2 — Level design, arte, sprites, rooms e áudio

- [ ] Instalar Blender e organizar modelos CC0 em `src/assets/models/` antes de renderizar folhas de sprites.
- [ ] Criar texturas e elementos de cenário para diferenciar as quatro regiões.
- [ ] Preparar efeitos de áudio originais para exploração, sustos, inimigos e chefe.
- [ ] Validar F10, HUD e leitura visual nos modos 2D e 3D.

## Protótipo atual

O jogo combina exploração top-down e primeira pessoa, áreas geradas, notas,
NPCs, monstros, sanidade, lanterna e chefe. O pós-processamento oferece gradação
por região, ACES, extração/composição de brilho e efeitos de terror. F10 alterna
entre qualidade baixa, média e alta. Leia [`LEIAME.md`](LEIAME.md) para limites
conhecidos e [`CREDITOS.md`](CREDITOS.md) para as fontes dos materiais.

