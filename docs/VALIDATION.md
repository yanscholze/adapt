# Validação atual — campanha 1.0 — 23/10/2026

Comando executado: `python3 scripts/check.py`. Resultado final: **PASS ALL OFFLINE CHECKS**.

- **72 cenários aprovados:** 10 de regras puras, 19 de integração, oito de cliente, seis de mundo, 17 da campanha e 12 de Terrain.
- 49 arquivos Luau compilados, incluindo 40 fontes do jogo. Análise Luau aprovada; a limitação dos tipos do motor no analisador standalone permanece.
- Os 40 fontes incorporados ao lugar correspondem aos arquivos atuais; 91 requires resolvidos, grafo sem ciclos e remotes declarados.
- Campanha simulada do tutorial à vitória final: desbloqueios, 24 memórias, oito sementes, troca de corpo, refúgios, viagem, resgate, checkpoint, morte, recompensas únicas, três padrões de combate e epílogo.
- Servidor rejeita pedidos distantes, itens não descobertos, pré-requisitos ausentes, repetição de recompensas e ataques inválidos. Finalização só recompensa contribuidores elegíveis próximos.
- Migração do perfil anterior, sanitização e roundtrip de progresso verificados com armazenamento simulado. Falhas de leitura, lease concorrente e save continuam cobertos pela suíte anterior; nenhum DataStore da nuvem foi acessado.
- Efeitos de salto, natação, oxigênio, calor, carapaça e ascensão conferidos por estado/velocidade nos serviços. Não são testes de movimento físico no Roblox.
- Diário e suas três abas construídos em 360×640, 667×375 e 1440×900. As verificações anteriores de HUD, cards e Codex em outros tamanhos continuam aprovadas. Prévia 3D e elementos de interface são instanciados, mas não foram renderizados pelo motor nesta sessão.
- Terrain real entregue: 2.192 chunks, 57.396.975 células ocupadas e 2.086.288 bytes de payload. Decoder independente e testes geométricos executados nos voxels do arquivo gravado.
- Os 15 destinos terrestres novos têm aproximações amostradas a cada seis studs, com inclinação limitada a 1,1, a partir do respectivo refúgio. Os destinos iniciais, submersos e aéreos têm verificações separadas. A conexão de Rift Crown foi corrigida após falhar nesse teste.
- 1.785 Parts no cenário gravado, 131 pontos de Essence, oito biomas, oito refúgios, oito santuários e 24 memórias. A campanha acrescenta modelos locais atômicos; as configurações de streaming anteriores permanecem.
- Gerados `build/ADAPT-1.0.rbxl`, sua cópia `build/ADAPT.rbxl`, o XML `build/ADAPT.rbxlx`, atlas e âncoras de campanha exportadas dos módulos incorporados.
- Capa e ícone originais incluídos em `assets/branding/`, com créditos e prompts. São ilustrações de divulgação, não capturas do jogo.
- Snapshot antes das alterações em `backups/ADAPT-before-campaign-20261023.zip`; documentos dos marcos anteriores preservados abaixo. Não houve login, publicação, push ou uso de credenciais.

**Pendência de liberação:** executar `STUDIO_TESTS.md` no Roblox Studio, com campanha completa, multiplayer, mobile, streaming, física, renderização e persistência real. Nesta sessão, o StudioMCP respondeu à inicialização, mas a conexão com o host Studio foi recusada e o proxy falhou no Wine. Não foi possível executar Play pelo agente. O jogo pode ser aberto pelo usuário sem MCP.

Os testes da campanha reposicionam personagens para exercitar os serviços; não demonstram que um jogador percorreu fisicamente todo o mundo. Os trajetos de Terrain são amostragens e não cobrem cada detalhe de colisão. Não há medição de FPS, memória ou latência em aparelho real. O arquivo implementado e a suíte verde não substituem essa etapa de homologação.

---

# Marco anterior: World Foundation — 17/10/2026

Comando executado: `python3 scripts/check.py`. Resultado final: aprovado.

- 52 cenários: 10 de regras puras, 19 de integração, oito de cliente, seis de mundo e nove de Terrain.
- As 37 verificações do MVP foram preservadas; referências ao cenário foram atualizadas para o agrupamento Core.
- 39 arquivos Luau compilados, incluindo 32 fontes do jogo. Análise Luau aprovada com as mesmas limitações de tipos de motor descritas abaixo.
- 32 fontes incorporados conferidos contra os arquivos atuais; 65 requires resolvidos; grafo sem ciclos; remotes consistentes.
- Terrain real incorporado: 2.192 chunks de 32³ voxels, resolução de 4 studs, água, relevo e cavidades. O decoder independente percorreu todos os chunks e verificou seus limites.
- Oito biomas, 24 ilhotas, oito ilhas flutuantes, 42 POIs e oito travessias. As ligações formam uma rede conectada das sete ilhas terrestres; os canais têm pontes reais.
- Cinco aproximações de cavernas tiveram inclinação e espaço de saída conferidos; a sexta é submersa. Centros de cavidades e teto sólido foram inspecionados nos voxels entregues.
- 1.669 Parts no arquivo gravado, incluindo recursos e Guardian; somente 79 Parts de landmarks persistentes. 131 pontos de Essence. Terrain compõe as grandes massas geográficas.
- StreamingEnabled true; Improved; Opportunistic; PauseOutsideLoadedArea; raios 128/512. Conferidos no artefato.
- 260 árvores amostradas em terra, mais vegetação aérea. Seed 817204.
- Um fixture público de Terrain do Rojo foi decodificado separadamente: 16 chunks, 524.288 células. Ele não está incorporado ao jogo nem ao pacote.
- Nove arquivos centrais foram comparados byte a byte ao backup: persistência, perfil/autoridade, habilidades, personagem, Config, registros de adaptações, schema, progressão e Prompt.txt intactos.
- Pacote com fontes, Terrain, arquivos para Studio, atlas e documentação; sem publicação, push ou credenciais.

**Não comprovado nesta sessão:** renderização e física no Studio, colisão de todos os detalhes, multiplayer no motor, comportamento do streaming sob rede real, câmera, mobile e DataStore da nuvem. Os testes geométricos e adapters offline não são uma simulação do motor. O atlas é uma vista técnica, não screenshot de Play.

A ausência de falhas na suíte não garante ausência de pontos de aprisionamento fora dos trajetos amostrados. O roteiro manual está em `STUDIO_TESTS.md`, e o relatório de escopo em `WORLD_FOUNDATION.md`.

---

# Marco anterior: MVP — 17/10/2026

Comando executado: `python3 scripts/check.py`. Resultado: aprovado.

- 33 arquivos Luau compilados: 28 fontes de jogo, 3 suítes e 2 scripts de suporte.
- Análise Luau dos fontes aprovada. Shared usa strict; módulos do motor usam nonstrict com globals declarados. Não há definição completa de tipos da API Roblox nesse analisador standalone. O lint UnknownType é desativado porque typeof reconhece tipos do motor que não existem no runtime standalone.
- 28 fontes incorporados ao lugar conferidos byte a byte contra os fontes atuais.
- 58 requires resolvidos; grafo de dependências sem ciclos; nomes de remotes consistentes.
- 10 cenários de regras puras, incluindo 500 escolhas consecutivas simuladas.
- 19 cenários de integração executando os módulos reais contra instâncias offline e serviços simulados.
- 8 cenários de cliente: construção de UI, dimensões de painéis, seleção, Codex, revelação local, entrada e cleanup.
- 75 Parts estáticas, 21 pontos de Essence, 4 áreas e Guardian gerados pelos próprios módulos de mundo.
- Arquivos binário `.rbxl` e XML `.rbxlx` produzidos com fontes e cenário incorporados.
- Releases públicos das ferramentas fixados em lockfile, com SHA256 de arquivos e binários.
- Prompt.txt original preservado; diretório sem Git; nenhuma credencial, publicação ou push.

Os avisos de DataStore na suíte são falhas intencionalmente simuladas. Não houve acesso ao DataStore real.

**Ainda não comprovado:** funcionamento físico e visual no Studio, renderização da UI, estabilidade sob rede real, multiplayer em sessões do motor, dispositivo mobile e persistência na nuvem. A presença de arquivos compiláveis ou de testes verdes não marca essas etapas como concluídas. Execute `docs/STUDIO_TESTS.md` para essa validação.
