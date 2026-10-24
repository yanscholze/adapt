# Personagem 3D — revisão visual de 23/10/2026

A referência é `assets/branding/ADAPT-cover.png`, junto do ícone original. A capa continua sendo uma ilustração promocional, não uma captura do jogo. Esta revisão aproxima a geometria jogável das suas proporções e cores; a iluminação e o acabamento do render promocional não são reproduzidos integralmente.

## Modelo implementado

- Cabeça arredondada maior que o tronco, corpo marfim, barriga de tom quente, braços/coxas volumosos e patas turquesa com dedos.
- Olhos ovais escuros com íris e dois reflexos por olho. Rosto preso à cabeça do esqueleto; o piscar comprime também a posição dos reflexos.
- Seis lâminas de cristal nas asas, construídas com faces triangulares reais; três garras facetadas em cada mão.
- Cauda com duas articulações e duas nadadeiras facetadas; carapaça com placas de brasa, patas de salto e coroa do epílogo.
- Cores próprias das variantes e olhos especiais mantidos. Os desbloqueios, slots e regras de progressão não mudaram.

`src/shared/CreatureAppearance.luau` é a fonte da geometria em runtime. Não há IDs de meshes/texturas ou animações que precisem ser enviados para uma conta. A decoração não colide, não participa de consultas/toques, não fica ancorada e é massless. O esqueleto R6, câmera e fluxo `LoadCharacterAsync` da correção anterior permanecem.

Orçamento medido: 25 peças visíveis no Blank, 253 no explorador com asas/garras/cauda e 386 visíveis no conjunto completo; com os quatro pivôs invisíveis, o máximo é 390 peças decorativas. Isso é uma contagem, não uma medição de FPS. Validar especialmente celulares e multiplayer antes de publicar.

## Animação

`src/shared/CreatureMotion.luau` calcula poses de repouso/respiração, caminhada, salto, queda, pouso, planar, escalar, nadar, ataque e movimentos secundários das asas e da cauda. O cliente interpola as poses, pisca e refaz as referências quando troca o corpo. Usa `PreSimulation`, após a avaliação do Animator, e mantém a interpolação em estado próprio para que uma escrita do Animator não reinicie a pose todo frame.

Ataques locais têm resposta visual imediata; ataques aceitos pelos guardiões incrementam uma sequência no servidor para os demais clientes. Essa sequência não concede dano ou recompensa. Movimento reduzido diminui os movimentos secundários. O cliente reaproveita referências de articulações e deixa de atualizar rigs além de 180 studs.

Referências: [Motor6D.Transform](https://create.roblox.com/docs/reference/engine/classes/Motor6D/Transform), [ordem das atualizações do motor](https://create.roblox.com/docs/performance-optimization/microprofiler/task-scheduler), [SpecialMesh](https://create.roblox.com/docs/reference/engine/classes/SpecialMesh).

## Inspeção e reprodução

- `build/ADAPT-1.0.rbxl`: jogo atualizado; abrir novamente para carregar as fontes novas e usar F5.
- `build/ADAPT-character-preview.png`: prévia técnica renderizada da geometria e das poses exportadas; iluminação aproximada, não screenshot do Studio.
- `assets/models/ADAPT-CharacterGallery.rbxmx`: galeria estática editável com quatro variantes. As peças são ancoradas somente nessa galeria de inspeção, não no personagem jogável.
- `scripts/export_character.luau` executa o mesmo construtor e amostrador de poses do jogo e exporta `build/character-preview.json`; `scripts/render_character.py` renderiza esse resultado.
- `python3 scripts/check.py` inclui os testes, exportação da galeria e renderização da prévia.

Revisão manual necessária: caminhar, pular e girar a câmera; comparar frente/costas; piscar sem reflexos flutuantes; planar, escalar, nadar, atacar, trocar adaptações e renascer; confirmar ausência de conflito com animação padrão, estabilidade da câmera e custo em múltiplos clientes. A suíte offline não executa a física nem renderiza materiais no Roblox.

Backup anterior: `backups/ADAPT-before-character-art-20261023.zip`.
