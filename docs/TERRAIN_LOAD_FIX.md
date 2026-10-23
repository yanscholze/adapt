# Correção do congelamento ao abrir — 23/10/2026

O pacote inicial tinha um erro na gravação das coordenadas do Terrain. O Studio ficava parado entre `OpenPlaceCreateDataModel` e o carregamento do documento; após cerca de 30 segundos, registrava um hang em `sabuiltin_StartPage...Shimmer`. Esse componente era o local do aviso, não a causa identificada.

## Causa e mudança

O SmoothGrid armazena os deltas de coordenadas de chunks em três inteiros **big-endian**, com bytes intercalados. O gerador usava little-endian. Um deslocamento de um chunk era lido como 16.777.216 chunks, fora da região válida. O decoder dos testes usava a mesma suposição; por isso o teste offline passava sem provar compatibilidade com o motor.

Foram corrigidos `scripts/build_terrain.py` e `tests/test_terrain.py`. O novo cenário usa offsets de bytes conhecidos de um arquivo salvo pelo Studio, verifica suas coordenadas esperadas e os limites do mapa entregue. Geografia, materiais, ocupações dos voxels e conteúdo da campanha permanecem os mesmos; muda a gravação correta das posições.

## Evidência no ambiente real

Mesmo Vinegar 1.9.4, Studio 0.744.0.7441077, DXVK 2.7.1 e Intel Iris Xe; configurações do Vinegar preservadas.

- Arquivo completo anterior: abertura presa antes de `OpenPlaceLoadDataModel`.
- Cópia temporária sem Terrain: `OpenPlaceSuccess` em aproximadamente 11 segundos.
- Uma região isolada: abertura concluída, permitindo reduzir o problema aos dados de posição.
- Cópia do mapa inteiro com somente a ordem dos bytes das coordenadas corrigida: texturas de Terrain carregadas e `OpenPlaceSuccess` em aproximadamente 12 segundos.
- Binário reconstruído, em uma cópia byte a byte idêntica a `build/ADAPT-1.0.rbxl`: `OpenPlaceSuccess` em aproximadamente 10 segundos. A cópia é usada apenas para evitar interferência de bloqueios antigos do nome do arquivo.
- Arquivo definitivo `build/ADAPT-1.0.rbxl`, depois de preservar os locks obsoletos: `OpenPlaceSuccess` em aproximadamente 13 segundos; deixado aberto para o usuário iniciar Play.

Depois das tentativas interrompidas, os arquivos de lock obsoletos dos lugares atuais foram preservados fora de `build/`, após verificar a ausência de um editor Studio ativo. Instalação, login e configurações gráficas não foram reinicializados.

As cópias de diagnóstico não são entregáveis de jogo. Abra `build/ADAPT-1.0.rbxl` ou `build/ADAPT.rbxlx` reconstruídos. O pacote anterior foi preservado em `backups/ADAPT-before-terrain-fix-20261023.zip`; contém o erro e serve apenas como histórico.

Esta validação confirma o carregamento no editor. Física, percurso completo da campanha, UI durante Play, aparelhos, multiplayer e DataStore real continuam no roteiro `STUDIO_TESTS.md`.
