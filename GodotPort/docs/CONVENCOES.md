# Convenções para três desenvolvedores

## Donos de área

- **Dev 1 — sistemas:** `scripts/autoload/`, `scripts/actors/`, inventário, combate, IA, rede e salvamento.
- **Dev 2 — mundo:** `scenes/regions/`, `scripts/world/`, terreno, pontos de interesse e navegação.
- **Dev 3 — conteúdo:** `scripts/ui/`, `resources/story/`, `resources/items/`, áudio, apresentação e testes de conteúdo.
- Os diretórios são sugestões de propriedade: mudanças compartilhadas devem ser combinadas antes do PR.

## Regras de merge

1. Uma branch curta por tarefa: `feat/`, `fix/` ou `content/` + descrição.
2. Uma cena por região ou sistema. Evite editar a mesma `.tscn` simultaneamente; prefira componentes e recursos `.tres` pequenos.
3. Não comite `.godot/`, exportações, saves nem dados de usuário.
4. `*.gd`, `*.tscn`, `*.tres` e JSON ficam como texto. Modelos, imagens, áudio e vídeo usam Git LFS.
5. Antes do PR: importar, rodar `Test.bat`, formatar com `gdformat` e conferir `git diff --check`.
6. PR descreve objetivo, cenas/recursos alterados, teste executado e captura visual se mexeu no mundo ou HUD.

## GDScript

- Use `snake_case`, nomes em português para gameplay e tipos explícitos em variáveis, parâmetros e retornos.
- Prefira `Resource` para definições de itens/inimigos; evite arrays escondidos em cena monolítica.
- Sinais globais passam por `EventBus`; estado persistente fica em `GameState`/`SaveSystem`.
- Formate com `gdformat GodotPort/scripts GodotPort/tests` e verifique com `gdlint`.
