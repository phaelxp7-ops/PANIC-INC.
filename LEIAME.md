# PANIC INC. — execução e estado técnico

## Abrir e controles

1. Abra `PANIC INC..yyp` no GameMaker Studio 2026.
2. Execute com F5.
3. `TAB` alterna câmera 2D/3D; `F10` alterna qualidade baixa, média e alta.
   Os outros controles aparecem no HUD.

O pós-processamento tem fallback: se um shader ou a surface de brilho não estiver
disponível, o evento desenha a application surface sem o efeito.

## Alterações desta revisão

- Integradas duas passagens de pós-processamento: extração do brilho e composição
  com tonemap ACES, gradação por região, vinheta, grão, aberração cromática e
  distorção regulada por sanidade, pânico e dano.
- F10 alterna a qualidade e afeta o número de amostras do bloom e o alcance da
  neblina 3D. Baixa desliga o brilho; alta usa suavização adicional.
- Adicionado eco curto e limitado para sons de horror em complexo/subsolo.
- Texturas, terreno, pinheiros e efeitos existentes foram preservados.
- Compilação F5 no GameMaker 2026 concluída; o jogo abriu, exibiu título e
  introdução e chegou à floresta em 2D.

## Limites e decisões

- A etapa 3 do roteiro foi pulada conforme o pré-requisito: `src/assets/models/`
  não contém modelos e `blender --background` não está disponível. Há FBX em
  third-party, mas eles não estão organizados em `modelos/` nem foram
  convertidos/renderizados; não foram substituídos por desenhos geométricos.
- Não encontrei a pasta `pacote_grafico/` com os rascunhos citados; foram criados
  shaders novos compatíveis com o formato de recurso do projeto.
- O pós-processamento executa em duas passagens. Iluminação 3D por pixel,
  sombras 2D por raycast e chuva/faíscas/vapor dedicados ainda não foram
  integrados. A neblina nativa do GameMaker continua ativa para profundidade.
- Personagens continuam sendo malhas procedurais sem animação esquelética. Bloom
  e surfaces extras têm custo variável; use F10 para reduzir efeitos.
- Não fiz a checagem interativa de F10, 3D, combate, chefe, finais, morte e
  respawn. A tentativa de alternar para 3D foi interrompida por nova entrada do
  usuário na janela. Esses fluxos continuam precisando de validação manual.
- O custo de GPU/FPS das três qualidades não foi medido; F10 apenas alterna as
  amostras de bloom e o alcance da neblina. Faça a medição em cada alvo antes de
  fixar a qualidade padrão para distribuição.

## Reconstruir texturas

Com Python e Pillow instalados, execute:

```powershell
python src/assets/materials/build_materials.py
python src/assets/marta_materials/embed_materials.py
```

Consulte `CREDITOS.md` para fontes e licenças dos materiais externos.
