# Pipeline 3D — PANIC INC.

## Meta
Substituir gradualmente a geometria feita de esferas/caixas por personagens e ambientes autorais ou CC0, mantendo versões fonte e versões otimizadas separadas. O GameMaker atual recebe apenas GML e imagens embutidas; este checkout não contém um arquivo `.yyp`, então a importação final dos modelos precisa acontecer no projeto aberto do GameMaker.

## Pastas
- `models/source/`: arquivos editáveis do Blender (`.blend`) e downloads originais, sem alterações.
- `models/game_ready/`: modelos exportados, com escala aplicada, pivô no chão e nomes estáveis.
- `textures/source/`: texturas originais e mapas PBR completos.
- `textures/game_ready/`: texturas reduzidas para o jogo (`albedo`, `normal`, `roughness`, `metallic`, `emission`).
- `materials/shaders/`: shaders e notas de configuração do material no GameMaker.

## Exportação de personagem no Blender
1. Trabalhar em metros; aplicar rotação/escala e colocar origem dos personagens no centro dos pés.
2. Separar malha, esqueleto e materiais com nomes estáveis (`Marta_Body`, `Marta_Rig`, `Marta_Cloth`).
3. Fazer UV unwrap sem sobreposição em partes que precisam de textura distinta. Usar albedo sem iluminação pintada; guardar normal/roughness como mapas separados.
4. Reduzir malhas distantes e remover faces internas. Alvo inicial: NPC 8–20 mil triângulos; criatura comum 5–15 mil; chefe 25–45 mil. Criar LOD distante quando necessário.
5. Exportar uma cópia de teste em formato interoperável aceito pelo runtime alvo do projeto e validar escala, orientação, UV e animações antes de trocar o desenho procedural. Nunca substituir o arquivo fonte `.blend`.

## Materiais e cena
- Floresta: solo orgânico, casca de pinheiro, folhagem e variação por decalques; evitar ladrilhos grandes e repetidos.
- Subsolo: concreto, manchas, bordas gastas, tubos/cabos e luzes práticas. Não reutilizar material de concreto na floresta.
- Personagens: albedo + normal + roughness; variação sutil de tons, sujeira e resposta diferente entre pele, roupa e partes molhadas.
- Usar poucas luzes dinâmicas próximas do jogador, sombras com distância limitada, neblina por bioma e iluminação ambiente suave. Evitar superfícies emissivas estouradas.
- Medir FPS e draw calls antes/depois. Preferir atlas por bioma e instancing/geometry batches onde o runtime permitir.

## Ordem de integração
1. Marta: modelo rigado e animações idle/walk/talk; comparar em 2D e 3D.
2. Uma criatura comum: estados idle/chase/attack/death; validar silhueta à distância e resposta à lanterna.
3. Chefe: modelo separado e animações por fase.
4. Trocar uma área de floresta e uma sala de concreto por assets modulares; conferir colisão e navegação.
5. Integrar no `.yyp` ativo, compilar, comparar capturas na mesma resolução e só então remover o placeholder GML.

## Limite atual
O renderizador 3D deste protótipo é desenhado manualmente em GML e o repositório não inclui `.yyp` nem modelos rigados. Texturas melhores ajudam, mas não convertem esferas em personagens AAA. O salto real depende de importar malhas, rig e animações no projeto GameMaker e adaptar o renderer para elas. Este pipeline prepara as pastas e o processo sem fingir que a importação já ocorreu.

## Execução local

Na raiz do checkout, rode python src/assets/materials/build_materials.py e depois python src/assets/marta_materials/embed_materials.py. Isso regenera os atlases e os incorpora ao evento Create do protótipo. O chão de biomas auxiliares agora usa o material de floresta; o interior da cabana tem um atlas próprio de tábuas para não herdar o solo da mata. Para qualquer nova textura, valide primeiro a repetição na escala de 32 unidades por tile e confira a região interna e externa da mesma estrutura.
