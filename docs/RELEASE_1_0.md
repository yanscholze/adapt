# ADAPT! 1.0 — campanha implementada

## Abrir

Abra **`build/ADAPT-1.0.rbxl`** no Roblox Studio e use **Play / F5**. O cenário já está no arquivo; não é necessário instalar plugins, publicar ou habilitar APIs para jogar localmente. `build/ADAPT.rbxl` é uma cópia idêntica. Não use o arquivo antigo World Foundation para testar a campanha nova.

## Jornada completa

1. Comece pelo diário, colete cinco cristais e escolha o primeiro corpo.
2. Derrote o guardião em Verdant. As três adaptações básicas ficam disponíveis, eliminando bloqueios por sorte nas escolhas.
3. Recupere as memórias do penhasco, da caverna e da ilha inicial; restaure a primeira semente.
4. Explore os demais biomas. Cada um tem três memórias e um santuário. O diário acompanha o próximo objetivo; o mapa permite marcar um destino diferente.
5. Ao restaurar sete sementes, receba as Asas do Zênite. Equipe-as em um refúgio, salte e use G / Subir para alcançar as ilhas superiores. G novamente cancela a ascensão; o chão recarrega sua duração.
6. Restaure a oitava semente e desperte o Guardião do Zênite. Observe os avisos de pulso central, anel externo e ecos direcionados.
7. A vitória de um contribuidor elegível libera epílogo, coroa visível, recompensa única e exploração livre. O chefe reaparece para permitir ajudar outros jogadores.

## Conteúdo entregue

- Oito biomas, 24 ilhotas, oito ilhas flutuantes e 42 pontos de interesse no arquipélago existente.
- Oito refúgios, oito santuários, 24 memórias pessoais e dois encontros de guardião.
- Dez definições de adaptação, distribuídas pelos seis slots anatômicos. As variantes iniciais continuam disponíveis.
- Patas de Salto: salto 60 e caminhada 24; Cauda das Marés: respiração submersa e natação 28; Carapaça de Brasa: resistência ao calor e redução de 25% no dano de guardiões; Asas do Zênite: ascensão por 35 s, além de bônus de synergy quando aplicável.
- Calor na caldeira, reserva de ar de 20 s sem cauda, recuperação gradual fora de combate, cura em refúgios, retorno após morte e resgate contra aprisionamento.
- Diário, mapa esquemático interativo, direção e distância, revisão do corpo em 3D, troca de adaptações descobertas em refúgios, Codex e opções.
- Memórias e santuários mostram conclusão local por jogador; o progresso de outro jogador não consome suas memórias. Essence e encontros continuam compartilhados.
- Interface e instruções em português, teclado, toque e atalhos de controle. Navegação por controle usa seleção inicial dos painéis; confirmação em aparelho continua pendente.

## Operação e compatibilidade

O DataStore continua `ADAPT_Profile_v1`, agora com envelope e perfil de schema 2. Não renomeie esse armazenamento para publicar uma atualização do mesmo jogo: isso separaria os saves anteriores. Campos existentes são preservados; a campanha é adicionada com defaults. A campanha nova começa no início em saves antigos, sem apagar nível, adaptações ou Codex.

`StudioPersistence=false` permanece como padrão: progresso local temporário, claramente indicado na interface. Produção usa DataStore com lease, tentativas de salvamento, autosave e liberação na saída. Falha de leitura continua em modo sem escrita, protegendo o registro original. Não habilite APIs de Studio sobre dados de produção para validar saves.

Servidor valida distância, vida, desbloqueios, inventário, pré-requisitos e recompensas únicas. Remotes são limitados por jogador. Escolhas de evolução não permitem atacar ou coletar Essence; o dano de combate e ambiente fica suspenso enquanto há uma escolha pendente no servidor.

O mapa mantém streaming, modelos pequenos e landmarks limitados. Refúgios e chefe final são modelos atômicos locais. A conexão entre o vale de Rift Crown e sua trilha foi escavada; dois refúgios foram retirados das bocas de cavernas. Vegetação que colidia com os refúgios foi removida apenas nesses pontos.

## Visual e assets

O visual do jogo é construído com Terrain, Parts, materiais e interface nativa. Não depende do upload das artes de divulgação. Capa e ícone são ilustrações promocionais originais produzidas com a ferramenta integrada de geração de imagens; **não são screenshots do jogo**. Arquivos em `assets/branding/`, com prompts e créditos preservados. Não há músicas ou imagens externas necessárias para iniciar.

## Limite da validação

A campanha foi executada do começo ao fim pelos serviços reais com adapters offline. Isso demonstra as transições e a autoridade do servidor, mas não demonstra física, câmera, rede Roblox, renderização, mobile ou DataStore real. Os testes de terreno verificam os voxels entregues e trajetos amostrados; não substituem o motor.

Nesta sessão, o StudioMCP 1.0 respondeu à inicialização, mas recusou a conexão com o host Studio e encerrou com falha no Wine. Nenhum Play real, medição de FPS, login, upload, publicação ou acesso a credenciais foi executado. A liberação pública depende da validação de `STUDIO_TESTS.md` e das configurações da conta, descritas em `PUBLISHING.md`.

Após a entrega inicial, foi corrigido o byte order das coordenadas do Terrain que congelava a abertura. O mapa completo passou a carregar no mesmo Studio/Vinegar, confirmado pelo evento `OpenPlaceSuccess`; consulte `TERRAIN_LOAD_FIX.md`. Esta confirmação de abertura não equivale ao playtest acima.

## Reconstruir

`python3 scripts/check.py` reconstrói o Terrain e o lugar, compila e analisa Luau, valida as referências, executa as suítes e gera atlas/âncoras. `python3 scripts/package.py` cria o pacote da versão atual com manifesto e validação de ZIP. As ferramentas ficam em `.tools/`; o arquivo pronto do Studio é independente delas.

Snapshot pré-campanha: `backups/ADAPT-before-campaign-20261023.zip`. Snapshot pré-World Foundation e seu arquivo `.rbxl` histórico continuam preservados.
