# ADAPT! — World Foundation

O mundo está criado em `build/ADAPT-WorldFoundation.rbxl`. `build/ADAPT.rbxl` e `build/ADAPT.rbxlx` também contêm a versão atual. Abra o arquivo no Studio e use **Play/F5**. Não é necessário executar um gerador manualmente nem instalar plugin para ver o mundo.

## Composição entregue

Área oceânica de **3.840 × 3.840 studs**, com sete ilhas terrestres principais, o bioma aéreo, 24 ilhotas adicionais, oito ilhas flutuantes, oito travessias entre regiões e 42 POIs nomeados. O núcleo do MVP foi preservado dentro de Verdant.

| Região | Identidade e explorações |
| --- | --- |
| Verdant Island | Costa recortada, colinas, rio, queda d'água, arco costeiro, ruínas e grutas. Contém spawn, Guardian, caverna e rotas iniciais das adaptações. |
| Ember Atoll | Vulcão dominante, caldeira com lava, basalto, fumarolas, cavernas internas e praia escura. Espaço geográfico reservado para resistência ao calor. |
| Rift Crown | Picos, fendas, cânion, plataformas, cachoeira, escarpa marcada e trilha em espiral ao cume. Serve como lançamento para a cadeia aérea descendente. |
| Sky Reach | Oito ilhas em alturas distintas, cristais, vegetação clara e quedas d'água suspensas. A cadeia baixa usa o Glide atual; os extremos superiores ficam para voo futuro. |
| Oldgrowth Sanctuary | Floresta mais densa, lago, raízes, caverna e Árvore das Eras, com apoios de escalada e plataformas para descanso. |
| Sunscar Expanse | Mesas de arenito, ravina, arcos, bacia de sal, fendas e ruínas enterradas. Silhueta diferente das ilhas verdes. |
| Tideglass Reefs | Lagoa aberta, canais, praias pequenas, coral estilizado, estruturas submersas e túnel aquático. Nado padrão do Humanoid; nenhuma adaptação aquática nova. |
| Vesper Hollow | Cristais, monólitos suspensos, costa violeta, passagens profundas e objetos revelados por visão noturna. |

A geografia vai do fundo oceânico em torno de −150 studs até Terrain aéreo em +685; o cristal mais alto chega perto de +715. Vegetação: 260 árvores posicionadas com seed **817204**, além de vegetação aérea e cristais. O atlas em `build/WORLD_ATLAS.png` é uma vista técnica da geografia, não uma captura do Studio.

## Rotas e acesso

As sete ilhas terrestres formam uma rede conectada de baixios, ilhotas e pontes naturais. Não é necessário implementar barco, voo ou uma adaptação nova para visitar as regiões principais. Há 24 ilhotas fora das travessias para exploração pela água ou futuras rotas aéreas.

Os pontos extremamente altos, recortes verticais e alguns recessos foram deixados como destinos de retorno. A existência dessas áreas não significa que voo completo, resistência ao calor ou fisiologia aquática já tenham sido implementados. A lava atual é ambiental: não foi acrescentado um sistema de dano térmico nesta etapa.

As paredes marcadas usam as garras existentes, em trechos de até 52 studs com plataformas de descanso. A partir do cume de Rift Crown, Cloud Gate → Rain Garden → Azure Step → Sky Heart é uma sequência descendente cuja distância/queda cabe nos limites atuais do Glide. A ilha inicial permanece acessível pela rampa original.

As cavernas novas são vazios reais em Terrain. Cinco receberam aproximações escavadas e rampas de pedra; a sexta tem entrada submersa. Existem verificações geométricas para teto, interior aberto, inclinação de saída e espaço de passagem. Esses testes não substituem percorrer cada entrada no motor.

## Estrutura

```text
Workspace
├── Terrain                     Água, ilhas, montanhas, fundo e cavernas
└── ADAPTWorld
    ├── Core                    Núcleo inicial e rotas originais
    ├── Islands                 Regiões, ilhotas e decoração de costa
    ├── Vegetation              Árvores por bioma
    ├── Landmarks               Caldeira e silhuetas de orientação
    ├── POIs                    42 pontos e entradas de caverna
    ├── SeaPaths                Oito travessias e pontes
    ├── Environment             Reserva para elementos ambientais
    ├── FutureRoutes            Metadados de futuras adaptações
    ├── Essence                 Recursos criados pelo serviço existente
    └── Guardian                Combate existente
```

## Fonte e reprodução

- `src/shared/WorldDefinition.luau`: composição autoral, ilhas, picos, rotas, cavernas, ilhotas e POIs.
- `scripts/terrain_geometry.py`: avaliação de relevo, cavernas, canais, água e ilhas suspensas.
- `scripts/build_terrain.py`: gera voxels, escreve `world/Terrain.rbxmx` e produz `src/shared/WorldSamples.luau` com posições amostradas. WorldSamples é gerado; não editar manualmente.
- `world/Terrain.rbxmx`: Terrain real gravado, incluído pela árvore Rojo. Não contém apenas instruções de geração.
- `src/server/World/Archipelago.luau`: constrói vegetação, landmarks, caminhos e detalhes sobre o Terrain.
- `WorldService`: mantém sua interface anterior, acrescenta metadados e reutiliza o modelo gravado quando sua versão corresponde ao layout.
- `EnvironmentController`: cor local sutil por bioma e ativação de partículas próximas, respeitando movimento reduzido.
- `scripts/bake.luau`: incorpora a decoração, recursos e Guardian, e grava o arquivo completo para o editor.

Para reconstruir: `make build`. Para construir e verificar: `python3 scripts/check.py`.

A etapa de Terrain precisa de NumPy e Pillow. O localizador usa Python com essas bibliotecas ou o runtime fornecido pelo Codex neste ambiente. Em outra máquina, instale `requirements-world.txt` em uma venv e aponte `ADAPT_WORLD_PYTHON` para seu Python. O jogo pronto não depende de Python, dessas bibliotecas ou de Rojo.

O projeto usa uma implementação própria do formato público SmoothGrid. Referências: [especificação de Terrain no rbx-dom](https://github.com/rojo-rbx/rbx-dom/blob/45cc9de5053bc8fcfaf6d9a5731eeb77dc872fd3/docs/smooth-grid.md), [explicação de armazenamento pelo autor do sistema](https://zeux.io/2017/03/27/voxel-terrain-storage/). O decoder independente também foi conferido contra um fixture público do Rojo. Nenhum terreno de terceiros foi incorporado ao mundo do jogo.

## Streaming e orçamento

StreamingEnabled está gravado como true, com raio mínimo de 128 e alvo de 512 studs. ModelStreamingBehavior usa Improved, StreamOutBehavior usa Opportunistic e StreamingIntegrityMode usa PauseOutsideLoadedArea. Essas são configurações do lugar, não atribuições ilegais em runtime.

Árvores usam modelos atômicos pequenos. O núcleo inicial também é atômico. O arquipélago inteiro não é atômico nem persistente. Só 79 Parts de landmarks são persistentes para ajudar a orientar pelo horizonte; o restante é elegível para streaming. Partículas ambientais distantes são desligadas localmente, e não há scripts por árvore ou por pedra.

A orientação segue a [documentação de streaming da Roblox](https://create.roblox.com/docs/workspace/streaming). Os valores escolhidos são um ponto inicial para playtest, não uma medição de desempenho mobile. Não houve declaração de FPS ou memória em aparelho real.

## Integrações preservadas

Os primeiros 21 recursos conservam IDs, ordem e posições; agora há 131 pontos no mundo inteiro, administrados pelo mesmo EssenceService. Os IDs Wilds, Cliff, Cave e SkyIsland continuam válidos para saves anteriores. Novas regiões entram no Codex pelo registro Areas, sem novo schema ou DataStore.

Spawn, Guardian, configurações das habilidades, autoridade do servidor e regras de evolução não foram substituídos. O painel DEV já existente ganhou os destinos das novas regiões. Reabrir Play não apaga Terrain nem recria a decoração: só renova instâncias dinâmicas de Essence e Guardian, sem duplicação.

## Validação e limites

Passaram 52 cenários offline: 37 anteriores, seis de mundo e nove de Terrain. Também passaram compilação/análise Luau, conferência dos fontes incorporados, requires e grafo sem ciclos. Os testes incluem presença de água, ilhas separadas, cavidades cobertas, voxel sólido em ilhas flutuantes, conservação do spawn, rede de travessias, inclinação das aproximações e alcance da sequência de Glide.

Ainda é necessário testar **Play**, colisões efetivas, câmera, streaming sob latência, multiplayer e aparelhos reais. O ambiente desta conversa não ofereceu controle interativo do Studio; o atlas não foi usado como evidência de renderização no motor. A serialização bem formada e os testes de geometria não garantem ausência de todos os pontos de aprisionamento ou problemas de FPS.

Próxima etapa: percorrer as oito regiões no motor, validar cada entrada/ponte/apoio, testar telefone e dois clientes, ajustar visibilidade/streaming e só então detalhar novas mecânicas de travessia. Não publicar antes desse playtest.
