# Changelog gráfico — PANIC INC.

## Pipeline cinematográfico e controles — 2026-10-31

- Adicionados `sh_bloom_extract` e `sh_cinematic`, com extração e composição de
  brilho, tonemap ACES, gradação por bioma, vinheta, grão, aberração cromática e
  distorção dependente de sanidade, pânico e dano.
- O pós-processamento trata perda/redimensionamento da surface e mantém desenho
  direto da application surface como fallback.
- F10 alterna qualidade baixa/média/alta; a qualidade altera as amostras do
  bloom e o alcance da neblina para equilibrar custo e leitura.
- Sons longos de horror recebem eco discreto e limitado em áreas internas.
- O projeto `.yyp` completo foi incluído na raiz para abrir diretamente no IDE.
- Compilação F5 no GameMaker 2026 concluída e jogo aberto até a floresta 2D;
  a alternância para 3D e os demais fluxos não foram validados.

Etapa 3 (sprites renderizados via Blender) foi pulada conforme os
pré-requisitos: `src/assets/models/` está vazia e Blender não está
instalado/disponível. Os FBX third-party não foram usados como substituto.
Ver `LEIAME.md` para efeitos ainda pendentes e `CREDITOS.md` para fontes/licenças.

## Materiais de monstros e biomas — 2026-10-31

- Substituído o piso quadriculado por atlas de terreno com 64 recortes de folhas, agulhas de pinheiro, asfalto e concreto; cada tile escolhe um recorte estável, evitando o padrão repetitivo.
- Troncos de pinheiro agora usam casca texturizada e suas copas foram redesenhadas em camadas; o bioma florestal mantém céu aberto e não gera paredes de sala.
- Criado atlas orgânico em quatro paletas para monstros. Corpos e membros usam malhas com UVs e textura em vez de esferas de cor sólida; silhuetas específicas acrescentam mandíbula, costelas, garras, espinhos e movimento de ataque.
- Marta usa tecido xadrez escuro, jeans e pele em mapas próprios; o código carrega as imagens em sprites dinâmicos por data URL e não depende de caminhos locais.
- No modo 2D, os recortes de chão também aparecem no mapa, com cores diferentes por bioma.
- Fontes, créditos, licenças CC0 e scripts para refazer os atlases estão em `src/assets/ASSETS.md` e `src/assets/`.

Validação anterior: algumas revisões distribuíam apenas eventos e materiais, sem
o `.yyp`. Nesta revisão o projeto e seus recursos foram incluídos para abrir no IDE.

## Problemas observados nas capturas

- A floresta era renderizada como blocos de concreto porque obstáculos do bioma 0 passavam pelo mesmo gerador de paredes dos interiores.
- O céu da floresta era coberto por planos de teto no topo de cada tile, criando um horizonte artificial.
- O piso tinha alternância regular de brilho que parecia um tabuleiro quadriculado.
- A tela de escolha de melhorias posicionava a descrição à esquerda dos cartões, causando sobreposição.
- Os NPCs apareciam como volumes grandes e rosa, sem proporção humana clara.

## Correções aplicadas

- Obstáculos do bioma da floresta agora são desenhados como pinheiros de tronco e copas em camadas; paredes permanecem em áreas urbanas e internas.
- Removido o teto do bioma externo para abrir o céu.
- Removido o padrão xadrez do piso; a variação de cor agora é discreta e determinística.
- Descrições das melhorias centralizadas nos cartões.
- NPCs receberam cores mais naturais e proporções menores, com cabeça, tronco, braços e pernas separados.
- Neblina 3D usa tons diferentes por região e maior alcance quando a lanterna está ligada.
- Malhas de criaturas ganharam variação de cor orgânica; a introdução recebeu pistas narrativas mais inquietantes e mensagens raras de rádio para sanidade baixa.

## Limitações

O renderizador atual usa malhas geradas em GML; não oferece animação esquelética,
sombras ou materiais PBR comparáveis a GTA V/Red Dead Redemption 2. O projeto
GameMaker `.yyp` agora está incluído na raiz do repositório.
# Atualização: correções visuais da captura 2026-10-31

- Corrigido o vetor lateral do WASD no modo 3D (D/Right aponta para o lado da câmera).
- NPC Marta: removido olho amarelo fora do rosto; cabeça/cabelo agora usam cores humanas, olhos só aparecem de frente sob a lanterna, corpo menor.
- Piso do mundo: substituído o padrão de tiles grandes por variação tonal discreta em subtiles.
- Mantidos pinheiros e céu aberto no bioma de floresta.

## Atualização: personagem Marta e materiais CC0

- Substituída a silhueta larga por um corpo humanoide com pernas separadas, tronco estreito, mangas, mãos, botas, pescoço e cabelo preso.
- Marta vira o rosto para o jogador a curta distância; olhos, sobrancelhas, nariz e boca ficam alinhados na frente da cabeça.
- Camiseta, pele e jeans recebem UVs e texturas de diffuse. Os mapas são incorporados no `Create_0.gml` como data URLs e carregados por `sprite_add`, sem caminhos absolutos ou passos de importação no IDE.
- Fontes CC0 e scripts para reconstruir as texturas estão em `src/assets/ASSETS.md` e `src/assets/marta_materials/`.

Limite: Marta continua sendo uma malha procedural low-poly, sem rig esquelético ou normal maps; a melhoria foca em silhueta, textura e legibilidade dentro do renderer atual. Não alcança o nível de GTA V/Red Dead, que depende de outro pipeline 3D, modelos detalhados, rigging, shaders e iluminação mais avançados.
