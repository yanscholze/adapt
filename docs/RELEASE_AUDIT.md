# Auditoria para ADAPT! 1.0 — 23/10/2026

Antes das alterações: 70 arquivos do manifesto conferidos sem diferenças; suíte anterior com 52 cenários aprovada. Snapshot integral em `backups/ADAPT-before-campaign-20261023.zip`. Fontes originais, mundo e históricos preservados.

## Lacunas reais

- O mundo expandido não tem campanha, objetivos persistentes, encerramento nem conteúdo nos destinos finais.
- Três slots anatômicos não têm adaptações; áreas de voo, calor e mergulho permanecem reservas.
- Morte sempre retorna ao início; não há acampamento, recuperação de vida, viagem entre locais descobertos nem resgate contra aprisionamento.
- As descobertas não podem ser reequipadas. Escolhas aleatórias podem atrasar a travessia necessária.
- HUD não acompanha o arquipélago; faltam mapa, diário, introdução, final e estado de salvamento visível.
- O guardião único é introdutório. Falta um desafio final com progressão, comunicação e recompensa própria.
- Pacote não contém identidade de lançamento, descrição da loja nem roteiro de publicação atualizado.
- A suíte offline não executa física/renderização de Roblox. Studio está instalado via Vinegar; existe StudioMCP.exe, mas a conexão precisa de uma sessão habilitada no Studio.

## Escopo da versão 1.0

Aventura cooperativa de exploração, sem PvP ou compras: tutorial curto, três experiências iniciais de adaptação, guardião introdutório, oito santuários, acampamentos, adaptações para os seis slots, ascensão ao Zênite, guardião final, epílogo e exploração livre com descobertas opcionais. Objetivos e desbloqueios são pessoais e persistidos; cenário e combate são compartilhados.

Implementação: registros compartilhados para campanha e objetivos; serviços novos para jornada e encontro final; integração incremental nas autoridades existentes. Migração aditiva v1 → v2 no mesmo DataStore, sem apagar progresso. Interface nativa Luau, coerente com o mundo, em português, com áreas de toque e rolagem.

## Critério de entrega

Build real `.rbxl` e fontes; testes de campanha completa, rejeição de ações remotas inválidas, migração e recompensas únicas; embalagem verificada. Publicação pública depende da conta do criador e da revisão das exigências atuais do Roblox. Testes no motor, dispositivos e nuvem só são marcados aprovados quando executados.
