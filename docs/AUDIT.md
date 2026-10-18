# Auditoria inicial — 17/10/2026

Realizada antes da implementação, em `/home/yanscholze/Documentos/Roblox`.

- Conteúdo inicial completo: somente `Prompt.txt`, 16.477 bytes. O conteúdo coincide com o anexo, exceto pela quebra de linha final.
- Nenhum código, arquivo Roblox, arquivo Rojo, dependência, configuração funcional ou AGENTS.md encontrado no projeto ou nos ancestrais examinados.
- A pasta não pertence a repositório Git. `git status` informou ausência de repositório. Nenhuma alteração anterior de código precisava ser mesclada.
- Disponíveis: Python 3, Node, Git, CMake, Make, compilador C++, curl, unzip, Wine e Flatpak.
- Não disponíveis inicialmente no PATH: Rojo, Luau, Lune, Selene, StyLua, Aftman, Rokit e Cargo.
- Roblox Studio encontrado na instalação Flatpak de Vinegar, versão local `version-4f087c32742644ab`; Sober também instalado. Nenhum processo de Studio em execução foi identificado. Presença do executável não foi tratada como teste do motor.
- Nenhuma credencial foi consultada. Não foram usados APIs autenticados, login ou publicação.
- Decisão: projeto novo Rojo, Luau sem framework, módulos por responsabilidade, registros compartilhados, mapa/rig construídos por primitives e arquivos de lugar independentes do plugin Rojo.
- Ferramentas de build foram adicionadas localmente em `.tools/`, com releases públicos oficiais e lockfile. Não houve instalação de sistema ou mudança no Vinegar.

## Preservação e escopo

`Prompt.txt` foi mantido integralmente. Somente arquivos novos relacionados ao MVP foram adicionados. `ADAPTWorld` é uma área explicitamente gerada do jogo e pode ser recriada pelo bootstrap; outras áreas de um lugar futuro não são apagadas.

O bloqueio atual de validação é a ausência de uma sessão interativa de Studio controlável pelas ferramentas desta conversa. Não se tentou contornar isso lendo credenciais, instalando plugins globais, alterando a instalação do Studio ou publicando. A alternativa implementada é build real, execução offline dos módulos, inspeção de instâncias e roteiro manual de playtest.
