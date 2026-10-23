# Publicar ADAPT! 1.0

Preparação conferida em 23/10/2026. Arquivo de lançamento: `build/ADAPT-1.0.rbxl`. A sessão não realizou publicação; a conta do criador e os testes no motor não foram validados.

## Sequência

1. Abra o arquivo no Studio e execute o roteiro de teste em `STUDIO_TESTS.md`, incluindo a campanha até o final, dois clientes e um celular. Resolva erros de Output antes de abrir ao público.
2. Use **File → Publish** para criar uma experiência privada. Confira o proprietário e o lugar de destino. Se estiver atualizando um jogo existente, escolha conscientemente o mesmo lugar, preservando seu DataStore.
3. Para este primeiro lançamento, selecione computador e telefone/tablet. Controle tem implementação básica; habilite consoles somente depois do respectivo playtest. Comece com limite de oito jogadores por servidor e ajuste após medir desempenho.
4. Preencha nome, gênero e descrição. Use os arquivos da pasta `assets/branding` como ícone e capa ilustrados, conferindo o enquadramento na prévia. Acrescente screenshots reais de Play quando disponíveis.
5. Valide saves em uma experiência privada separada, com outro nome de DataStore. Reentre para conferir nível, corpo, memórias, refúgios e conclusão. Mantenha `StudioPersistence=false` no arquivo de produção; servidores publicados usam salvamento automaticamente.
6. No Creator Dashboard, confira elegibilidade, alcance de audiência, classificação de conteúdo e acesso público. As exigências dependem da conta e da audiência. Responda aos formulários com o conteúdo real, sem presumir aprovação. Só então altere o acesso para público.

O fluxo de publicação, audiência e permissões é descrito na [documentação oficial de publicação](https://create.roblox.com/docs/production/publishing/publish-games-and-places). Os requisitos por audiência estão em [Roblox Kids e Select](https://create.roblox.com/docs/production/publishing/kids-and-select). Estas configurações pertencem à conta, não ao arquivo `.rbxl`.

## Texto para a página

**Nome:** ADAPT!

**Gênero sugerido:** Aventura / Exploração (selecione o equivalente disponível no formulário).

**Descrição:**

Comece como uma pequena criatura e transforme seu corpo para explorar um arquipélago adormecido.

Colete essência, abra asas, escale penhascos, enxergue segredos e mergulhe entre ruínas. Recupere 24 memórias, restaure oito sementes e enfrente o Guardião do Zênite. Sua jornada desbloqueia novas adaptações, refúgios e uma coroa especial.

Explore sozinho ou colabore com outros jogadores. Sem PvP e sem compras dentro do jogo.

Computador: WASD para mover, Espaço para saltar, G para asas, E para escalar, F para atacar, R para interagir, C para o diário e M para o mapa. No celular, use os botões na tela.

## Mídia e conteúdo

- Ícone: `assets/branding/ADAPT-icon.png`, quadrado, pelo menos 512 px. [Guia oficial de ícones](https://create.roblox.com/docs/production/publishing/experience-icons).
- Capa: `assets/branding/ADAPT-cover.png`, ilustração horizontal próxima de 16:9; confira o corte da prévia. A plataforma recomenda 1920×1080. [Guia oficial de thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails).
- Conteúdo a declarar conforme o formulário: combate fantasioso contra criaturas, dano e reaparecimento, sem sangue. Não há apostas, troca de itens, conteúdo pago, texto livre criado pelo usuário ou monetização implementada. O chat padrão é administrado pela plataforma, conforme as permissões e configurações da conta.
- Não há IDs fictícios de badges, passes, produtos ou áudio para preencher. A coroa é uma recompensa dentro do jogo, salva no perfil; não é um badge da plataforma.

## Atualizações futuras

Guarde o ZIP de cada versão antes de substituir o lugar. Acompanhe erros e falhas de salvamento no ambiente privado. O schema 2 preserva os campos antigos, mas um servidor antigo de schema 1 recusa o novo envelope; use reinício controlado dos servidores ao atualizar uma experiência já em produção. Não publique o snapshot antigo sobre saves migrados.
