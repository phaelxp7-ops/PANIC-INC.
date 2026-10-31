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
