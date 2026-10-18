# Arquitetura e extensão

## Fluxo de autoridade

`WorldService` gera ou reutiliza o cenário gravado, volumes e pontos de spawn. Na etapa World Foundation, Terrain é incorporado durante o build e a decoração fica no arquivo; Play reutiliza o modelo compatível. Veja `WORLD_FOUNDATION.md` para a extensão do pipeline. `EssenceService` verifica os jogadores a cada 0,15 s, reclama cada cristal antes de entregar sua energia e agenda respawn. Cristais raros exigem a habilidade NightVision no servidor, mesmo se um cliente modificar sua aparência.

`PlayerService` concentra perfil e evolução. Energia suficiente cria uma escolha com token único e IDs elegíveis. A seleção valida token, opção, nível e saldo, desconta o threshold anterior, incrementa o nível e substitui apenas o slot escolhido. Energia excedente permanece e pode abrir outra escolha imediatamente. Escolhas pendentes são reconstruídas após reconexão a partir do saldo salvo; o token não é persistido.

`CharacterService` constrói e reaplica o Blank. `AbilityService` verifica loadout, chão, parede marcada, vetor finito, orçamento e tempo desde o último input. Durante habilidades, o servidor controla a física via LinearVelocity e ownership; ao parar, restitui o controle normal. `GuardianService` calcula dano e recompensas, com cooldown e distância no servidor.

`PersistenceService` é independente da UI e dos modelos. `AnalyticsService` aceita um sink opcional, falha sem interromper o jogo e registra milestones uma vez por perfil. `DebugService` exige Studio ou UserId permitido em cada chamada.

O cliente renderiza snapshots; os controllers separam UI, entrada, feedback e visão noturna. Objetos ocultos começam com Transparency 1 no servidor. A alteração local de Transparency e a iluminação local não concedem recompensa nem afetam outros clientes.

## Remotes

| Remote | Direção e validação |
| --- | --- |
| State, Feedback | Servidor → cliente; snapshots e feedback |
| RequestState | Cliente → servidor; rate limit de 1/s, burst 3 |
| Choose | Token e ID presentes na oferta, saldo e requisitos; 2/s, burst 4 |
| Ability | Modo permitido, Vector3 finito, magnitude normalizada; 15/s, burst 20; requisitos verificados continuamente |
| Attack | 3/s, burst 4; cooldown próprio, HP, distância, vida e linha de visão |
| Codex | Milestone; 0,5/s, burst 2 |
| Setting | Apenas chaves booleanas já existentes; 2/s, burst 3 |
| Debug | 2/s, burst 4; autorização repetida no servidor |

Não existe remote para conceder Essence, energia, nível ou recompensas. O watchdog de movimento barra saltos de posição grosseiros e invalida interação por 2 s após correção. Não promete cobrir todas as formas de manipulação física.

## Adicionar uma adaptação

1. Adicione uma definição com ID estável em `src/shared/Adaptations.luau`.
2. Declare slot, descrição, raridade, requisitos, tags e synergyTags.
3. Reutilize um visual `Wings`, `Claws` ou `Eyes`, com cor e escala próprias.
4. Reutilize uma habilidade `Glide`, `Climb` ou `NightVision`, declarando multiplicadores. Variantes não exigem lógica nova.
5. Para comportamento realmente novo, adicione um handler no AbilityService e o controle correspondente no cliente. Para um visual novo, estenda o construtor visual do CharacterService. Mantenha a decisão de conceder/verificar a habilidade no servidor.
6. Verifique que o pool elegível sempre permite as opções pretendidas. Hoje existem seis definições em três slots e nenhuma adaptação já equipada é oferecida. A UI suporta até três opções e o servidor aceita apenas a oferta emitida.
7. Execute `python3 scripts/check.py`, teste seleção, substituição de slot e respawn no Studio.

Progression não enumera os IDs disponíveis: trabalha com o registro e os requisitos. O requisito inicial suportado é `minLevel`. Se adicionar requisitos por tags ou descobertas, centralize sua validação na regra de elegibilidade e também na confirmação da escolha.

## Adicionar uma synergy

Adicione um ID em `src/shared/Synergies.luau`, uma lista `requiredTags` e metadados para o Codex. As tags devem existir em `synergyTags` das adaptações equipadas. Combinações não dependem de IDs específicos.

O cálculo, descoberta e Codex são genéricos. O efeito atualmente suportado é `bonusGlideSeconds`; um efeito distinto precisa de um handler. `secret = true` documenta a intenção; no MVP todas as synergies desconhecidas são ocultadas no Codex. O dado estar em Shared não constitui segredo contra inspeção do código pelo cliente.

## Adicionar uma área

1. Registre ID, nome, `priority`, centro, tamanho, posição segura e dica em `Areas.luau`.
2. Construa sua geometria no WorldService e acrescente pontos à lista de Essence se desejar.
3. A detecção usa AABB e prioridade decrescente, para subáreas vencerem Wilds. Descoberta, persistência, Codex e teleporte administrativo passam a aceitar o novo ID automaticamente.
4. Se precisar, acrescente um botão DEV e uma dica contextual no HUD. Esses atalhos são opcionais para o funcionamento da área.
5. Paredes escaláveis usam `CollectionService:AddTag(part, "Climbable")`. Objetos ocultos usam `NightVisionRevealable`, Transparency 1 e, se forem coletáveis, requisito de servidor.

Os volumes são de detecção, não portões. O acesso vem da geometria e das habilidades. O gerador recria somente `workspace.ADAPTWorld` ao iniciar.

## Dados salvos

DataStore padrão `ADAPT_Profile_v1`, chave `u_<UserId>`:

```lua
{
    version = 1,
    data = {
        version = 1,
        level = 0,
        energy = 0,
        equipped = { Back = "Wings" },
        discovered = { Wings = true },
        synergies = { Moondrift = true },
        areas = { Wilds = true },
        milestones = { FIRST_ESSENCE = true },
        settings = { sound = true, reducedMotion = false },
    },
    session = { id = "server-session-guid", expires = 1234567890 },
}
```

O lease vale 180 s e é renovado pelo autosave de 60 s. Load/save usam UpdateAsync com até três tentativas. A callback não faz yield. Save cria um snapshot sanitizado. Saída e BindToClose tentam salvar e liberar o lease. Shutdown aguarda até 25 s. Requests de save são serializados por perfil e um autosave anterior à saída não pode reclamar um lease já liberado.

Se load falhar, defaults são temporários e não graváveis. Um schema de envelope mais novo não é rebaixado. Sanitização rejeita valores não finitos, IDs desconhecidos e slots incorretos. Uma sessão que perde o lease deixa de salvar e desconecta o jogador para evitar divergência persistente. Se um processo cair sem liberar, outra sessão só entra após o lease expirar.

Não se salva a cada coleta. Em uma queda abrupta pode-se perder o progresso desde o último autosave; falhas prolongadas de API também podem impedir salvar. Não existe promessa de persistência real antes do teste manual com APIs.

## Fontes técnicas

API física: [LinearVelocity](https://create.roblox.com/docs/reference/engine/classes/LinearVelocity). Entrada e botões de toque: [ContextActionService](https://create.roblox.com/docs/reference/engine/classes/ContextActionService). Persistência: [Data stores](https://create.roblox.com/docs/cloud-services/data-stores). Build: [Rojo](https://rojo.space/docs/v7/getting-started/installation/). Adapter offline: [Lune Roblox](https://lune-org.github.io/docs/api-reference/roblox/).
