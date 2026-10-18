# Auditoria para World Foundation — 17/10/2026

Antes da expansão, os 49 arquivos do manifesto anterior foram conferidos e estavam sem alterações. Foram lidos os registros compartilhados, bootstrap, serviços, controllers, scripts de build e testes. Não havia Git, AGENTS.md adicional, editor de ilhas ou gerador de Terrain prévio. O backup completo anterior está em `backups/ADAPT-before-world-foundation.zip`.

## Caminhos reais encontrados

- WorldService criava um mapa de 75 Parts com coordenadas fixas e apagava ADAPTWorld em cada inicialização. O bake chamava esse mesmo módulo e incorporava cenário e fontes ao lugar.
- CharacterService depende do spawn original em `(0,5,20)`. O Guardian fica em `(20,4.5,70)`. As rotas das três adaptações e os primeiros 21 recursos também usam posições conhecidas.
- AbilityService valida parede com tag `Climbable`, chão, loadout e tempo. Seu teste de topo pressupõe parede vertical alinhada ao eixo Y; por isso os novos apoios de escalada respeitam esse formato e cabem no orçamento existente.
- EssenceService mantém autoridade no servidor. NightVisionController acompanha tags entrando/saindo; isso já permite tratar recursos ocultos sujeitos a streaming.
- O schema aceita áreas pelo registro Areas. Foi possível acrescentar regiões e preservar IDs anteriores sem trocar DataStore ou schema.
- HUD/Codex já comportavam rolagem e descobertas. A única integração de UI necessária foi acrescentar destinos ao painel DEV existente.
- Streaming estava desabilitado. A configuração deve ficar gravada no lugar, pois StreamingEnabled não pode ser ativado em runtime.

## Decisões executadas

Preservar o núcleo inicial em um Model atômico, manter sistemas de progresso e habilidades, produzir Terrain real durante o build e acrescentar decoração modular. O mapa gravado é reutilizado em Play; somente Essence e Guardian renovam suas instâncias dinâmicas. Nenhuma região precisa de um sistema novo de combate, quests ou economia para existir.

A implantação inclui costa, fundo oceânico, ocupação de água, cavernas e plataformas flutuantes em voxels de 4 studs. Landmarks e pequenos detalhes usam Parts. A composição das ilhas é intencional; seed fixa varia apenas a decoração.

## Preservação verificada

CharacterService, AbilityService, PlayerService, PersistenceService, Config, Adaptations, ProfileSchema, Progression e Prompt.txt foram comparados byte a byte ao backup e permaneceram iguais. Guardian e Essence receberam apenas a remoção de instâncias antigas durante inicialização a partir de um lugar já gravado, evitando duplicatas. Os testes anteriores continuam presentes.
