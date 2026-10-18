# Validação atual — World Foundation — 17/10/2026

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
