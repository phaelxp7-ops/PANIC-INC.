# PANIC INC. — O Coração do Medo (Godot)

Port paralelo do protótipo GameMaker. `src/` continua intacto. Godot 4.7.2 padrão (GDScript) instalada em `E:\GameDev\Godot\4.7.2`; os atalhos também aceitam `GODOT_EXE` ou `tools\godot\Godot_v4.7.2-stable_win64.exe` em outra máquina.

## Abrir e jogar

1. Execute `Setup.bat` uma vez para preparar Git LFS e verificar ferramentas.
2. Use `Run_Editor.bat` para abrir `project.godot` ou `Run_Game.bat` para jogar.
3. Escolha **Começar história**. O preset inicial é Baixo para funcionar melhor em GPU integrada.
4. Controles: `WASD` mover, mouse olhar, `Shift` correr, `Ctrl` agachar, `E` interagir, `F` lanterna, botão esquerdo atirar, `R` recarregar, `H` kit, `Q` calmante, `G` ping, `V` alternar primeira/terceira pessoa, `M` mapa, `J` diário, `Esc` pausa.

## Cooperativo

- Anfitrião: **Criar partida** no menu. Porta UDP padrão `27840`; conexões externas dependem do firewall/roteador.
- Cliente: informe o IP do anfitrião e escolha **Entrar na partida**.
- `Run_Server.bat` inicia um host headless; `Run_2Clients.bat` abre host e duas janelas de cliente para teste local.
- O servidor é autoridade para monstros, dano, interações e progressão. Matchmaking/Steam e validação completa entre máquinas ainda não estão prontos.

## Estrutura e equipe

- `scenes/regions/`: quatro regiões separadas; `scripts/autoload/`: estado, eventos, settings, saves e ENet.
- `scripts/actors/`: jogador, NPCs e monstros. `scripts/world/`: construção e interações.
- `resources/story/`: as 15 notas recuperadas do GameMaker e diálogos. `docs/CONVENCOES.md`: divisão de trabalho e PR.
- Assets opcionais e formatos: `ASSETS_MANUAIS.md`; licenças: `CREDITOS.md`.

## Validar, testar e exportar

- `Test.bat`: importa, executa GUT e verifica estilo com `gdtoolkit` se instalado.
- `godot --headless --path . --script tools/build_world.gd`: valida chunks e gera `docs/world_manifest.json`.
- `Export.bat`: exporta Windows para `build/PanicInc.exe` (requer templates da versão 4.7.2).
- GitHub Actions executa importação headless, lint e GUT.

## Limites desta base

É um port jogável da história, não tem fidelidade de GTA V/Red Dead. Cenários/personagens usam modelos CC0 low-poly, geometria modular e diffuse 1K. Faltam heightmap com NavMesh baked, conjuntos completos de mapas PBR, captura facial, retarget final, ragdoll e validação do coop pela Internet. Forward+ está configurado; presets altos podem ficar lentos na Radeon integrada.
