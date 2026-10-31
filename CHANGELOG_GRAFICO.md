# Changelog gráfico — PANIC INC.

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

Estas alterações usam geometria e cores geradas em GML. Não são materiais PBR nem substituem modelos, mapas de textura, animações ou iluminação avançada. O repositório não inclui o projeto `.yyp` nem assets externos. Para personagens com aparência realista, será necessário criar/importar modelos e texturas no projeto GameMaker.
# Atualização: correções visuais da captura 2026-10-31

- Corrigido o vetor lateral do WASD no modo 3D (D/Right aponta para o lado da câmera).
- NPC Marta: removido olho amarelo fora do rosto; cabeça/cabelo agora usam cores humanas, olhos só aparecem de frente sob a lanterna, corpo menor.
- Piso do mundo: substituído o padrão de tiles grandes por variação tonal discreta em subtiles.
- Mantidos pinheiros e céu aberto no bioma de floresta.

Limite: a geometria ainda é procedural low-poly. Texturas PBR externas exigem importar sprites/recursos no projeto GameMaker; não há `.yyp` ou pasta de assets no repositório para registrar/importar recursos automaticamente.
