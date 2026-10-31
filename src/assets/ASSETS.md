# Materiais e referências visuais

As pequenas texturas usadas no modelo procedural de Marta são incorporadas em
`obj_panic/Create_0.gml` como imagens base64 e viram sprites dinâmicos com
`sprite_add`. Assim o jogo não depende de caminhos externos nem precisa de
importação manual de recursos no IDE.

## Texturas incorporadas ao jogo

- `materials/world_surface_atlas.jpg`: 64 variações compactas para quatro biomas. A floresta usa folhas e agulhas secas; a cidade usa asfalto; o complexo e o subsolo usam concreto com tratamento de cor diferente.
- `materials/pine_bark_atlas.jpg`: variantes de casca usadas nos troncos dos pinheiros.
- `materials/monster_skin_atlas.jpg`: quatro paletas de pele para Esvaziado, Rastejante, Estátua e Sombra, derivadas do material orgânico descrito abaixo.
- `marta_materials/`: camiseta xadrez, jeans, pele e os mapas de Marta. O GML embute os JPGs como data URLs para que o protótipo não dependa de caminhos locais.
- `materials/build_materials.py` reconstrói os mapas finais; `marta_materials/embed_materials.py` atualiza os data URLs em `obj_panic/Create_0.gml`.

Para regenerar as imagens, instale Pillow (`python -m pip install Pillow`) e execute, na raiz do repositório:

```powershell
python src/assets/materials/build_materials.py
python src/assets/marta_materials/embed_materials.py
```

O atlas de piso tem 16 recortes por bioma; a seleção muda por tile e a geometria 3D recebe UVs individuais. No modo 2D os mesmos recortes aparecem em escala reduzida. O projeto atual não tem `.yyp`, então os mapas são carregados pelo GML e não por recursos do navegador de assets.

## Fontes

- `third_party/stef_npc/`: personagem humana texturizada “npc girl Stef”, por
  supersteve, CC0. A camiseta e a pele foram recortadas dos mapas de textura do
  pacote para vestir as malhas do jogo. Página/licença:
  https://opengameart.org/content/npc-girl-stef
- `third_party/polyhaven/denim_fabric_diff_1k.jpg`: textura difusa Denim Fabric,
  por Rob Tuytel, CC0. A versão 256×256 é incorporada ao GML. Fonte:
  https://polyhaven.com/a/denim_fabric
- Texturas CC0 da Poly Haven: [Forest Ground 03](https://polyhaven.com/a/forrest_ground_03), [Asphalt 01](https://polyhaven.com/a/asphalt_01), [Concrete Floor](https://polyhaven.com/a/concrete_floor), [Fabric Pattern 05](https://polyhaven.com/a/fabric_pattern_05) e [Pine Bark](https://polyhaven.com/a/pine_bark). Apenas mapas diffuse reduzidos/recortados entram no jogo.
- Material `Organic_Matter_002_COLOR.jpg` do pacote CC0 [Nightmare Monsters](https://opengameart.org/content/nightmare-monsters), por Teh_Bucket; os créditos do pacote citam Joao Paulo/3dtextures.me como autor das texturas. Foi usado como base de cor para o atlas de pele das criaturas. Créditos e licença original estão em `third_party/opengameart/`.

Os recursos da Poly Haven são CC0; a licença está em https://polyhaven.com/license. A página de Nightmare Monsters marca o pacote como CC0; os modelos FBX não são carregados pelo protótipo atual.

As licenças CC0 permitem uso sem atribuição; as fontes ficam registradas aqui
para rastreabilidade do projeto.
