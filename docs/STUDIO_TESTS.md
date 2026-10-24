# Roteiro de validação no Roblox Studio

Todos os itens abaixo permanecem **pendentes de execução no motor**. Os testes offline aprovados não marcam estes itens como concluídos.

## Revisão visual do personagem — 23/10/2026

- [ ] Comparar corpo inicial e conjunto evoluído com a capa: proporções, olhos, patas, faces dos cristais e cauda vistos de frente e de costas.
- [ ] Repouso e piscar sem olhos/reflexos separados; caminhar e saltar sem braços rígidos; queda e pouso com transição.
- [ ] Planar abre as asas; escalar alterna braços; nadar movimenta cauda e membros; atacar anima o braço.
- [ ] Trocar asas/cauda e renascer: articulações visuais voltam a funcionar e nenhum detalhe antigo fica solto no mapa.
- [ ] Movimento reduzido diminui a oscilação; câmera e WASD continuam funcionando.
- [ ] Dois clientes veem movimento/ataque um do outro; medir desempenho com conjuntos completos em celular.

## Regressão de controles e câmera — revisão de 23/10/2026

Reabra o arquivo atualizado antes de iniciar F5; uma aba antiga não recarrega as alterações do disco.

- [ ] Fechar a introdução e andar com WASD, saltar com Espaço; câmera começa próxima e acompanha o personagem.
- [ ] Girar e ajustar zoom; abrir/fechar Diário por botão e C; confirmar que o movimento volta e que a câmera não reinicia durante o giro normal.
- [ ] Morrer e renascer: corpo/adaptações preservados, caminhada e câmera continuam funcionando, inclusive após mudar o refúgio de retorno.
- [ ] Dois clientes e rede lenta: inicialização sem personagem ausente, travamento por streaming ou correções indevidas de posição.
- [ ] Celular e controle: direcional, pulo, giro da câmera e retorno do menu.
- [ ] Conferir `[ADAPT CLIENT]` no Output: PlayerModule presente, câmera Custom, follows character true, walk speed 20 (ou bônus da adaptação), streaming paused false após carregar.

## Versão 1.0 — roteiro de liberação

Use `build/ADAPT-1.0.rbxl`. Os roteiros históricos abaixo continuam úteis para as mecânicas básicas; o topo aéreo agora é alcançável com as Asas do Zênite.

- [ ] F5: criatura aparece, diário abre, Começar fecha a introdução e a câmera acompanha; Output sem erros.
- [ ] Sem DEV: cinco cristais → escolha → guardião → três adaptações disponíveis → três memórias iniciais → primeiro santuário.
- [ ] Trocar corpo no refúgio; ver prévia 3D; tentar trocar longe e confirmar recusa com instrução.
- [ ] Morrer e voltar ao último refúgio; resgate mantém descobertas; cura e recuperação fora de combate funcionam.
- [ ] Seguir o diário por Oldgrowth, Tideglass, Sunscar, Ember, Hollow e Rift; cada capítulo exige três memórias. Confirmar chão e passagem em cada destino.
- [ ] Mergulhar com e sem cauda; conferir ar e dano. Visitar caldeira com e sem carapaça. Confirmar que as memórias de biomas exigem a adaptação correta.
- [ ] Sair do vale de Rift pela ligação nova e alcançar o cume pela trilha.
- [ ] Sete sementes → equipar Asas do Zênite → saltar/G → High Orchard → Zênite → Star Needle. G cancela; pousar recarrega; reativar no ar não recarrega.
- [ ] Oitava semente → despertar chefe. Testar área central, anel e ecos, com e sem carapaça. Confirmar áreas seguras e avisos visíveis.
- [ ] Vencer: epílogo, coroa e recompensa única. Reconectar e confirmar que conclusão/coroa persistem no teste de nuvem.
- [ ] Dois clientes: memórias independentes, Essence compartilhada, contribuições do chefe, morte de um participante e abandono da arena.
- [ ] Viagem entre refúgios com rede lenta: esperar streaming, confirmar que não cai pelo chão. Testar retorno e respawn em cada ilha.
- [ ] Telefone real em retrato e paisagem: diário, escolha, corpo, mapa, rolagem, câmera, prompts, pulo e três botões de ação sem sobreposição. Testar textos longos.
- [ ] Controle: selecionar cards, abrir/fechar diário, rolar listas e ativar prompts. Publicar em console somente após validar.
- [ ] Som desligado silencia feedback; movimento reduzido evita pulsos e animações decorativas; UI mantém informações sem depender da cor.
- [ ] Perfil antigo v1 em DataStore de teste: migrar, salvar, reconectar; verificar campos antigos e campanha nova, sem usar dados de produção.
- [ ] Medir FPS/memória/rede no dispositivo com o limite planejado de jogadores; registrar o resultado real.

Registro: data, versão do arquivo, dispositivo, número de jogadores, itens aprovados, erros de Output e medições. Não marcar itens por inferência dos testes offline.

## Preparação sem publicar

1. Abra `build/ADAPT.rbxl` no Roblox Studio. O `.rbxlx` contém o mesmo projeto em XML.
2. Abra **View → Output** para acompanhar erros. Use **Play/F5**, não Run.
3. Deve aparecer `[ADAPT] Server ready` no Output e a criatura na área inicial.
4. No Command Bar, durante Play, selecione o contexto **Server** e execute:

```lua
require(game.ServerScriptService.Server.StudioSmoke).run()
```

Esse teste apenas inspeciona mundo, tags, remotes, personagens, leaderstats e perfis. Não concede energia e não prova física ou aparência. Deve imprimir `[ADAPT SMOKE] Initial server invariants passed`.

## Primeiro minuto

- [ ] Sem DEV, localizar o waypoint de cristal em até 10 s.
- [ ] Coletar cinco cristais, receber 30 de energia e abrir três cards.
- [ ] Escolher uma adaptação e observar imediatamente a mudança de corpo.
- [ ] Confirmar que a energia é descontada uma única vez e a build aparece no Codex.
- [ ] Usar a adaptação dentro do primeiro minuto, ajustando o mapa se o trajeto for lento.

## Asas e ilha

- [ ] DEV → Wings ou seleção normal; caminhar até a rampa oeste e subir sem garras.
- [ ] Saltar do deck, ativar G/Planar, direcionar WASD/direcional até a ilha.
- [ ] Confirmar queda lenta contínua, direção controlável e pouso estável.
- [ ] G novamente cancela; abrir Codex/escolha interrompe a habilidade.
- [ ] Permanecer no ar por mais que o orçamento deve encerrar o planeio; reativar no ar não restaura o orçamento.
- [ ] Pousar restaura a habilidade. Confirmar que ela não deixa o Humanoid travado.
- [ ] Testar a variante Dawn Sails e a synergy Moondrift.

## Garras e penhasco

- [ ] Equipar Grip Claws; aproximar-se da parede dourada e ativar E/Escalar olhando para ela.
- [ ] Subir continuamente por todas as marcas e terminar sobre a borda, sem atravessar a parede.
- [ ] Tentar em uma parede lateral sem tag: não escalar.
- [ ] Afastar-se da parede, cancelar com E e verificar retorno ao movimento normal.
- [ ] Testar esgotamento sem tocar o chão e repetição com Stone Hooks.

## Olhos e caverna

- [ ] Sem olhos especiais, ver apenas os indícios externos; não receber Lumen ao tocar sua posição.
- [ ] Com Night Eyes, ver as cinco marcas e os três cristais raros, apenas nesse cliente.
- [ ] Coletar Lumen: +18 de energia, cristal oculto durante 24 s, novo aparecimento depois.
- [ ] Substituir Night Eyes por Echo Eyes e verificar olhos e revelação.
- [ ] Remover o slot com DEV → reset: ocultos voltam a ficar invisíveis e indisponíveis para coleta.

## Guardian, vida e respawn

- [ ] Ataque F/toque só causa dano perto da arena e com linha de visão.
- [ ] Segurar/spammar ataque não ignora cooldown.
- [ ] Círculo vermelho antecede o dano; sair a tempo evita o impacto.
- [ ] Guardian morre após dano suficiente, concede recompensa uma vez e reaparece em 35 s.
- [ ] Jogador morre e reaparece após 3 s com build, energia e descobertas anteriores.
- [ ] Reset Character do menu Roblox deve resultar em respawn correto.
- [ ] Confirmar que nenhuma habilidade ou câmera permanece presa ao corpo anterior.

## Dois clientes no mesmo servidor

Use as opções de teste **Server & Clients**, com dois jogadores.

- [ ] Dois jogadores tocam o mesmo cristal: apenas um recebe energia; ambos veem o despawn e respawn.
- [ ] Equipar olhos só no cliente A; B não deve ver as marcas/Lumen nem receber energia rara.
- [ ] Wings, garras e olhos de A são visíveis no corpo dele para B.
- [ ] Cada jogador mantém escolha, energia e Codex independentes.
- [ ] Ambos danificam Guardian: os dois contribuidores próximos recebem recompensa. Observador não recebe.
- [ ] Um jogador sai durante escolha ou habilidade sem deixar efeitos/erros no outro.
- [ ] Testar com latência simulada e verificar controle de planeio/escalada, recompensa e recuperação.

## Mobile e acessibilidade

- [ ] Device Emulator: 360×640, 375×667, 667×375 e tablet.
- [ ] Confirmar barras de sistema, safe areas e botão padrão de salto.
- [ ] Testar escolher três cards rolando no retrato; texto e botões não podem ficar cortados.
- [ ] Combinar joystick, câmera, salto e Planar/Escalar/Atacar sem sobreposição.
- [ ] Codex rola e fecha; sons desligam; movimento reduzido elimina pulsos e balanço das patas.
- [ ] Repetir pelo menos em um telefone real, com qualidade gráfica baixa e alta.
- [ ] Testar controle físico se essa plataforma for alvo de lançamento.

## Persistência real — somente em experiência privada de teste

1. Salve/publique manualmente uma experiência privada de teste.
2. Use outro `DataStoreName`, por exemplo `ADAPT_Test_Profile_v1`.
3. Habilite acesso a API no Studio e `StudioPersistence = true`. Reconstrua se estiver editando os fontes externos.
4. Confirme estado `Cloud` inspecionando o perfil/session ou a State no cliente. `StudioMemory` é temporário.

- [ ] Evoluir, equipar, descobrir synergy/área, alterar opções, aguardar autosave e reconectar.
- [ ] Sair antes do autosave e confirmar tentativa de save na saída.
- [ ] Fechar servidor de teste e validar BindToClose.
- [ ] Sessão ativa concorrente deve ser recusada sem sobrescrever progresso.
- [ ] Indisponibilidade de leitura deve mostrar aviso de sessão não salva e não gravar defaults.
- [ ] Indisponibilidade de escrita deve preservar o último save e tentar novamente no autosave seguinte.
- [ ] Nunca usar o DataStore de produção para testes destrutivos.

## O que foi executado offline

`python3 scripts/check.py`: sintaxe de todos os fontes/testes/adapters, análise Luau, build Rojo, resolução de require paths, grafo sem ciclos, nomes de remotes, 10 cenários de regras puras, 19 de integração e 8 de cliente. A integração inclui duas instâncias de jogador, concorrência de coleta sequencial no mesmo tick, replay de escolha, respawn, orçamento de habilidades, Guardian, autorização e cenários de falha de um store simulado.

Esses adapters **não implementam simulação física**, concorrência distribuída, serviços reais nem renderização. O teste de tamanhos de UI confirma construção e limites de painéis; não comprova leitura de texto ou interação no aparelho. Avisos de falhas de DataStore durante os testes são intencionais, produzidos por cenários de indisponibilidade/schema novo/tomada de lease.


## World Foundation — percurso adicional

- [ ] Abrir `ADAPT-WorldFoundation.rbxl` e conferir Terrain, oceano, vegetação e landmarks antes de Play.
- [ ] Nascer e executar o teste StudioSmoke no servidor; conferir que existem recursos e Guardian únicos.
- [ ] Percorrer as oito travessias, incluindo as pontes sobre canais, sem adaptação nova.
- [ ] Usar DEV para visitar os novos destinos; confirmar que os spawns estão acima do chão.
- [ ] Entrar e sair das cinco cavernas de aproximação escavada, e nadar pelo túnel de Tideglass.
- [ ] Percorrer as plataformas de escalada da Árvore das Eras e de Rift Crown, descansando entre trechos.
- [ ] Testar Cloud Gate → Rain Garden → Azure Step → Sky Heart com Wings.
- [ ] Na versão 1.0, confirmar que as Asas do Zênite alcançam o topo aéreo e seus objetivos.
- [ ] Testar streaming ao caminhar, planar, teleportar via DEV e retornar ao spawn com dois clientes.
- [ ] Medir FPS/memória no aparelho e ajustar raio, sombras e partículas com dados reais.

Esses itens continuam pendentes no motor. Os testes de mundo/Terrain offline não os marcam como realizados.
