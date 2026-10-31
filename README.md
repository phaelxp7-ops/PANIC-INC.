# PANIC-INC.

## Visão geral

Jogo multiplayer cooperativo de caos e sobrevivência. De 2 a 4 trabalhadores falidos são contratados por uma corporação suspeita para cumprir missões bizarras em locais mal-assombrados ou em ruínas. Entre os objetivos estão desarmar bombas, resgatar artefatos e reparar geradores enquanto fogem de monstros bizarros.

## Organização do projeto

- `src/`: projeto do GameMaker Studio (`.yyp`) e seus recursos.
- `docs/`: documentação de game design, mecânicas, ideias e decisões do projeto.
- `assets_raw/`: arquivos-fonte de arte e áudio antes da importação no GameMaker, como `.psd`, `.wav` e `.aseprite`.

## Divisão de tarefas

| Pessoa | Responsabilidades |
| --- | --- |
| **Dev 1** | Sistemas, lógica de jogo, arquitetura e rede/multiplayer. |
| **Dev 2** | Level design, arte, sprites, rooms e áudio. |

Registrem decisões importantes em `docs/`.

## Workflow com Git

1. Atualizem a branch base: `git switch main` e `git pull`.
2. Criem uma branch individual por tarefa, por exemplo `feat/movimento-jogador` ou `art/primeira-room`.
3. Façam commits pequenos e claros; enviem a branch e abram um Pull Request para revisão.
4. Evitem editar a mesma **Room** ao mesmo tempo. Combinem quem será responsável por cada Room, pois posicionamentos e instâncias podem gerar conflitos difíceis de mesclar.
5. Dividam o trabalho por recursos e arquivos sempre que possível. Salvem no GameMaker e revisem `git status` antes de sincronizar.
6. Não incluam builds, exports, logs ou arquivos pessoais do editor.

## Primeiras tarefas

### Dev 1 — Sistemas, lógica e rede/multiplayer

- [ ] Criar e configurar o projeto `.yyp` dentro de `src/`.
- [ ] Definir o loop principal e documentar as regras iniciais em `docs/`.
- [ ] Criar um protótipo de movimento e interação do jogador.
- [ ] Propor a arquitetura de sessões multiplayer e sincronização.

### Dev 2 — Level design, arte, sprites, rooms e áudio

- [ ] Organizar referências e fontes em `assets_raw/`.
- [ ] Definir a direção visual e um guia de sprites em `docs/`.
- [ ] Criar uma Room de protótipo com layout simples.
- [ ] Levantar referências de áudio para ambiente, ações e ameaças.
