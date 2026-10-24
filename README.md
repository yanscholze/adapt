# ADAPT! — 1.0 / O Arquipélago Desperto

Explore como um **Blank**, colete Essence, escolha uma adaptação e abra novas rotas com seu novo corpo. Projeto original em Luau, sem assets pagos, dependências de runtime externas ou credenciais.

**Entrada mais rápida:** abra `build/ADAPT-1.0.rbxl` (ou `build/ADAPT.rbxl` / `build/ADAPT.rbxlx`) no Roblox Studio e pressione **Play (F5)**. O mapa já aparece no editor. Use **Play**, pois **Run/F8** não cria jogador nem interface.

**Revisão de controles e câmera (23/10):** carregamento padrão do personagem, câmera próxima no início/renascimento e liberação do foco ao fechar o diário. Reabra o arquivo atualizado antes de F5. 80 verificações offline aprovadas; confirmação do movimento no motor ainda pendente. [Registro de validação](docs/VALIDATION.md).

**Novo personagem 3D (23/10):** corpo e olhos refeitos, asas/garras facetadas, cauda articulada e animações de movimento. [Detalhes e limites](docs/CHARACTER_ART.md) · [Prévia da geometria real](build/ADAPT-character-preview.png). 87 testes offline aprovados; revisão visual e física em Play pendente.

## Campanha e lançamento 1.0

A jornada agora tem começo e fim: tutorial, guardião inicial, oito santuários, 24 memórias, novas adaptações para os seis slots, refúgios com cura/retorno/viagem, Guardião do Zênite, epílogo e coroa. Abra **Diário [C]** para objetivos, mapa e troca de corpo. **M** abre o mapa e **R** interage; no toque, use os botões e prompts.

- [Conteúdo, regras e operação da versão](docs/RELEASE_1_0.md)
- [Preparação e instruções para publicar](docs/PUBLISHING.md)
- [Auditoria das lacunas e decisão de escopo](docs/RELEASE_AUDIT.md)
- [Validação e limites do que foi testado](docs/VALIDATION.md)
- [Artes de divulgação e créditos](assets/branding/CREDITS.md)

O arquivo contém a implementação da campanha. Um erro na gravação das coordenadas do Terrain que congelava o carregamento foi corrigido em 23/10/2026; a abertura do mapa completo foi conferida pelos registros do Studio no Vinegar. Veja [o diagnóstico e a correção](docs/TERRAIN_LOAD_FIX.md). **O playtest da campanha, aparelhos e DataStore real permanecem pendentes.** Não houve publicação. A elegibilidade pública depende da conta do criador.

## Mundo expandido

A etapa **World Foundation** acrescenta oito biomas em 3.840 × 3.840 studs, 24 ilhotas, oito ilhas flutuantes e 42 POIs, com Terrain real já gravado no arquivo. O núcleo inicial permanece; a campanha integra os novos destinos, e uma ligação no vale de Rift Crown foi corrigida. Veja [o relatório do mundo](docs/WORLD_FOUNDATION.md) e [o atlas](build/WORLD_ATLAS.png).

## O que está implementado

| Sistema | Comportamento |
| --- | --- |
| Blank | Criatura própria com corpo arredondado, olhos, patas, rig R6 e movimento procedural local |
| Essence | 131 pontos pelo mundo, incluindo os 18 comuns e 3 raros originais; coleta por proximidade no servidor e respawn compartilhado |
| Evolução | Energia, thresholds, três cards, validação com token de escolha, energia excedente preservada |
| Anatomia | Head / Body / Arms / Legs / Back / Tail; substituir uma adaptação mantém os outros slots |
| Adaptações | Dez definições: as seis iniciais, Patas de Salto, Cauda das Marés, Carapaça de Brasa e Asas do Zênite |
| Habilidades | Planeio, escalada, visão noturna, salto, natação/respiração, proteção térmica e ascensão finita |
| Mundo | Oito biomas, 24 ilhotas, oito ilhas flutuantes, cavernas e oceano; rotas originais preservadas dentro de Verdant |
| Guardian | HP, aviso de ataque em área, dano, ataque do jogador, recompensa por contribuição e respawn |
| Codex | Adaptações, áreas e synergy secreta; desconhecidos aparecem como ??? |
| Persistência | UpdateAsync, lease por sessão, autosave, saída, shutdown, schema e modo seguro após falha de leitura |
| Interface | HUD, diário, mapa, direção/distância, memórias pessoais, prévia do corpo em 3D, inventário, Codex e opções |
| Plataforma | Teclado, botões de toque e atalhos básicos de controle; testes em aparelhos ainda pendentes |
| Extras | Leaderstats Evolution, analytics desacoplado e desligado, feedback, ferramentas DEV protegidas |

**Estado da validação:** build real gerado; análise/compilação Luau e verificações offline documentadas em `docs/VALIDATION.md`. Testes usam os módulos reais, instâncias offline e serviços simulados. **Física, renderização, rede multiplayer e DataStore real ainda não foram validados no Studio.** Não foi feito login, publicação ou push.

## Como jogar e testar as adaptações

Ande com WASD ou o direcional de toque; salte com Espaço ou o botão padrão do Roblox. Toque os cristais verdes. Cinco cristais comuns dão os 30 pontos da primeira evolução. Escolha um card por clique/toque ou pelas teclas **1, 2, 3**.

| Adaptação | Teste prático |
| --- | --- |
| Wings / Dawn Sails | Vá à rampa oeste, em `(-63, 1, -65)`, e suba ao deck em `(31, 63, -65)`. Salte na direção da ilha a leste e ative **G / Planar**. O voo desce continuamente, tem orçamento de tempo e termina ao pousar. G novamente cancela. Dawn Sails troca duração por velocidade. |
| Grip Claws / Stone Hooks | Vá à face dourada em `(70, 22, 9.7)`, olhe para a parede e use **E / Escalar**. Direcione-se contra a superfície. No topo, a habilidade termina e coloca o corpo sobre a borda. Paredes sem a tag não permitem escalar. Stone Hooks troca velocidade por duração. |
| Night Eyes / Echo Eyes | Entre na caverna a sudoeste, em `(-64, 5, 43)`. As marcas e os três cristais raros aparecem só para você. Sem a adaptação, o servidor também impede receber a recompensa. Echo Eyes muda a assinatura visual. |
| Synergy secreta | Equipe uma adaptação de asas e uma de visão noturna. Descubra **Moondrift**, registrada no Codex: aura e mais 2 segundos de planeio. |

**F / Atacar** causa dano ao Guardian na arena em `(20, 4.5, 70)`. Afaste-se do círculo vermelho antes do impacto. Quem contribuiu e permanece próximo recebe 45 de energia, uma vez por vida do Guardian. O Guardian reaparece em 35 segundos.

**C / Diário** abre jornada, mapa e corpo. O botão **Codex** abre descobertas e opções. No toque, use os botões **Planar**, **Escalar**, **Atacar** e **Codex**. As habilidades aparecem conforme os slots são desbloqueados. Suporte básico de controle: X planeia, Y escala, R2 ataca, Select abre Diário; navegação por controle requer playtest no dispositivo.

## DEV — teste rápido sem grind

Em Studio aparece **DEV**, no canto superior direito. Em produção só aparece para IDs explicitamente cadastrados em `src/shared/Config.luau → AdminUserIds`. A autorização é conferida novamente no servidor.

| Comando interno | Botão / efeito |
| --- | --- |
| `energy`, número | +60 pelo botão; limite de 500 por chamada |
| `grant`, ID | Equipar Wings, GripClaws ou NightEyes; respeita o slot |
| `reset` | Limpar build, energia e escolha pendente; **preserva nível e descobertas** |
| `teleport`, área | Wilds / Cliff / Cave / SkyIsland |
| `state` | Imprimir o perfil no Output do servidor |

Os comandos são chamadas do painel ao serviço, não comandos públicos do chat. IDs de variantes também são aceitos pelo serviço. Nunca coloque a checagem administrativa apenas no cliente.

## Estrutura e arquitetura

```text
default.project.json       Árvore Rojo
src/shared/                Config, registros, regras puras, schema e rate limiter
src/server/init.server     Bootstrap e validação dos remotes
src/server/Services/       Mundo, personagens, jogadores, habilidades, Essence,
                           Guardian, persistência, analytics e debug
src/client/init.client     Bootstrap, câmera e sincronização
src/client/Controllers/    HUD, cards, Codex, controles, visão, feedback e animação
tests/                     Regras puras, integração de serviços e cliente offline
scripts/                   Instalação, validação, adapter offline e bake do mapa
build/ADAPT.rbxl(x)         Arquivos completos para abrir no Studio
docs/                      Arquitetura, auditoria e roteiro de validação real
```

O servidor emite snapshots para o cliente. O cliente pede ações; não concede energia, adaptações ou recompensas. A coleta não possui remote: o servidor verifica proximidade, vida, disponibilidade e requisitos. Habilidades usam LinearVelocity no servidor, com ownership do servidor durante seu uso. O movimento normal continua com o controle padrão do Roblox.

Detalhes de extensão e dados salvos em [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Roteiro de teste real em [docs/STUDIO_TESTS.md](docs/STUDIO_TESTS.md). Auditoria inicial em [docs/AUDIT.md](docs/AUDIT.md).

## Desenvolver e reconstruir

Para **abrir e jogar o arquivo pronto**, não é necessário Rojo nem plugin. Para editar o código externo e reconstruir em Linux x86_64:

```sh
python3 scripts/setup_tools.py
python3 scripts/check.py
```

Para reconstruir o Terrain, também é necessário Python com NumPy e Pillow (`requirements-world.txt`). Veja a configuração de `ADAPT_WORLD_PYTHON` no relatório do mundo.

O instalador baixa apenas releases públicos oficiais, com versões e hashes em `tools.lock.json`, para `.tools/`. Não altera o sistema. Ferramentas usadas: Rojo 7.7.1, Luau 0.743, Lune 0.11.0. Python 3 é a única dependência do instalador.

`make build` reconstrói os dois formatos com o mapa visível no editor. `make check` faz a verificação completa. `make serve` inicia Rojo; instalar e conectar o plugin Rojo no Studio é opcional. Não use o Studio e o editor externo como duas fontes simultâneas do mesmo código.

**Mapa gerado:** `ADAPTWorld` é recriado por WorldService quando não existe um mundo gravado compatível ou durante o bake. Em Play, o cenário gravado é reutilizado. Faça mudanças permanentes na definição e no construtor, ou extraia sua nova área para uma fonte própria antes de editar o mapa gerado manualmente. O restante do lugar não é apagado.

## Persistência e ações manuais

O schema atual é 2, no mesmo armazenamento `ADAPT_Profile_v1`, preservando os campos anteriores e acrescentando a campanha. Por padrão, **Studio usa memória temporária**, permitindo jogar sem publicar ou habilitar APIs. Fechar o teste descarta o progresso desse modo. O HUD e o estado distinguem `StudioMemory`, `Cloud` e `ReadOnly`.

Para testar DataStore real, o responsável deve, manualmente, salvar/publicar uma **experiência privada de teste**, habilitar **Game Settings → Security → Enable Studio Access to API Services**, usar um nome de DataStore separado e definir `StudioPersistence = true`. Isso não foi executado nesta sessão. A documentação oficial explica o [acesso a DataStore em Studio](https://create.roblox.com/docs/cloud-services/data-stores).

Em servidores publicados, o serviço tenta salvar automaticamente. Uma falha no load entra em `ReadOnly`: permite experimentar com defaults, avisa que a sessão não será salva e **não sobrescreve dados reais**. Uma sessão concorrente ativa é recusada. Falhas de save mantêm o último registro na nuvem e geram aviso; não há garantia de salvar alterações feitas durante uma indisponibilidade prolongada.

## Limitações e bugs conhecidos

- Não há resultado de playtest real nesta entrega. A abertura do arquivo corrigido foi confirmada pelo Studio no Vinegar; isso não valida física, câmera, renderização da interface durante Play, replicação ou APIs Roblox.
- Não há bug reproduzível conhecido nos testes executados. Aterrissagem, saída da borda de escalada, estabilidade do rig e latência precisam de confirmação no motor.
- UI foi construída e seus limites foram conferidos em 360×640, 375×667, 667×375, 768×1024 e 1440×900; não são capturas nem testes em aparelhos reais. Legibilidade, safe areas, gamepad e colisões com a UI padrão continuam no roteiro manual.
- Guardian é uma sentinela estacionária, com ataque radial anunciado. Não persegue nem navega o mapa.
- Modelos e animação usam geometria e movimento procedurais próprios. A troca de adaptações descobertas acontece pelo Diário, perto de refúgios. Não há editor livre de anatomia.
- Há dez definições de adaptação; os novos comportamentos são ligados à campanha. As variantes iniciais mantêm escolhas disponíveis depois das primeiras descobertas.
- A proteção de movimento é uma barreira simples contra teleporte, não um anticheat completo. A validação de ações continua no servidor.
- Analytics registra milestones locais no perfil. Envio externo está desligado e não tem fornecedor configurado.
- Colaboração é livre: Essence é compartilhada e pode haver competição; Guardian recompensa contribuidores próximos. Sem trading, PvP, matchmaking ou monetização.
- O mundo atual usa Terrain e menos de 2 mil Parts no arquivo, com streaming. Efeitos e criaturas acrescentam Parts durante o jogo. Não houve medição de FPS ou memória em dispositivo.

## Liberação pública

O conteúdo da versão está implementado. Antes de liberar ao público, execute `docs/STUDIO_TESTS.md`: primeiro minuto, campanha, multiplayer, mobile, streaming e persistência real em uma experiência privada separada. Confira o enquadramento de capa/ícone e as permissões no Creator Dashboard. O passo a passo e o texto da página estão em `docs/PUBLISHING.md`.

A auditoria inicial e os relatórios anteriores permanecem em `docs/`. Os marcos anteriores de validação são históricos e não substituem os resultados da versão atual.

## Git e entrega

A pasta original não era repositório Git. `Prompt.txt` foi preservado byte a byte. Não foi criado commit, realizado push ou feita publicação. Portanto não há `git diff`/`git status` aplicáveis; a entrega consiste nos arquivos adicionados e listados no manifesto do pacote.
