# Avaliação da lista de 40 ferramentas (03/11/2026)

Lista recebida: 8 grupos de harness, skills, memória, ferramentas e economia de tokens. Cinco agentes leram **só** README, manifestos, hooks, `.mcp.json` e scripts de instalação via GitHub (nada foi instalado nem executado durante a avaliação). Critérios: peso de contexto (o limite semanal aperta), segurança (nada de `npx` sem versão fixa em toda chamada, nada de telemetria que envie código, nada que mexa em credenciais sem necessidade) e conflito com o que já está instalado.

## Aplicado em 03/11/2026
| Item | O que foi feito | Escopo e segurança |
|---|---|---|
| **rtk 1.0.1 → 1.1.0** | Binário baixado de `github.com/rtk-ai/rtk/releases/tag/v1.1.0` (`rtk-x86_64-pc-windows-msvc.zip`), SHA-256 conferido (`c9a8f7a8…a6f`), substituído em `~/.local/bin/rtk.exe` (backup em `rtk.exe.bak-1.0.1`) | Correções de hooks, permissões e build Windows. Telemetria continua desligada (não rodar `rtk telemetry enable`). Não usar as `rc` de 1.2.0 |
| **rtk gain** | O banco `%LOCALAPPDATA%\rtk\history.db` estava corrompido ("database disk image is malformed"). Movido para `history.db.old` e `history.db.corrompido-20261103`; o rtk recriou e o `rtk gain` voltou | Só afeta o histórico de economia |
| **claude-md-management** (oficial) | `claude plugin install claude-md-management@claude-plugins-official` | 1 skill e 1 comando, sem hooks, MCP nem rede |
| **claude-hud** (barra de status) | `claude plugin marketplace add jarrodwatts/claude-hud` e `claude plugin install claude-hud@claude-hud` (v0.15.1) | **Falta o passo seu:** `/reload-plugins` e `/hud`, que troca a `statusLine` do settings depois de pedir confirmação. Não habilitar `--extra-cmd` (`CLAUDE_HUD_ALLOW_EXTRA_CMD` fica indefinida). Desligar numa sessão: `CLAUDE_HUD_DISABLE=1`. Requer Node ≥ 22.18 (a máquina tem 24.19) |
| **superpowers 6.4.2 → 7.0.1** | `claude plugin update superpowers@superpowers-dev` | O brainstorming foi reescrito na 7.0.0 e a 7.0.1 corrigiu hooks no Windows. Vale só depois de reiniciar o Claude. Voltar: reinstalar a versão anterior pelo marketplace se o fluxo novo atrapalhar |
| **context7** (MCP remoto) | `claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp` | 2 ferramentas (`resolve-library-id`, `query-docs`). O nome da biblioteca e a pergunta de código vão para a Upstash. Sem chave: limite menor. **Não** rodar `npx ctx7 setup`. Remover: `claude mcp remove context7` |

Backups feitos antes: `~/.claude/settings.json.bak-20261103` e `~/.claude.json.bak-20261103`.

## Avaliar depois (só com necessidade concreta)
| Item | Por que fica para depois |
|---|---|
| openai/codex-plugin-cc | **Leitura a fundo em 03/11:** os scripts não têm nenhuma URL externa (só um broker local em processo separado, que fala com o `codex app-server` e usa o seu login do Codex), sem dependências de runtime e sem telemetria própria. Hooks: SessionStart e SessionEnd (5 s, sobem e derrubam o broker) e Stop (timeout 900 s, mas só age se a "review gate" for ligada, o que vem desligado). Último commit em 08/07/2026 (manutenção lenta, 546 issues). Traz `/codex:review`, `/codex:adversarial-review`, `/codex:rescue`, `/codex:transfer`, `/codex:status`, `/codex:result` e `/codex:cancel`, com trabalhos em segundo plano dentro da sessão. Se entrar: **nunca** `/codex:setup --enable-review-gate` (vira laço e gasta cota). **Instalado em 03/11/2026** (`codex@openai-codex` 1.0.6, escopo de usuário; `setup` confirmou Codex 0.155.1, login ChatGPT ativo e review gate desligada). Cobre o reserva do Codex e a revisão cruzada sem sair da sessão; desinstalar com `claude plugin uninstall codex@openai-codex` se os hooks pesarem |
| colbymchenry/codegraph | Grafo de código local com 1 ferramenta MCP, o mais limpo da memória. Telemetria ligada por padrão (`CODEGRAPH_TELEMETRY=0`, `DO_NOT_TRACK=1`), instalar por npm com versão fixa e `codegraph install --no-permissions`. Só se um projeto grande doer em tokens |
| OthmanAdi/planning-with-files | Hooks em 6 eventos (inclui PreToolUse em quase toda ferramenta), terceiro sistema de hooks ao lado do ruflo-core e do rtk; ~90 ms por fork no Windows |
| firecrawl, github-mcp-server | O `web_research` do BuildPartner e a CLI `gh` já cobrem |
| coleam00/Archon | Programa à parte para pipelines repetíveis; telemetria PostHog ligada (`ARCHON_TELEMETRY_DISABLED=1`) |
| wshobson/agents | Catálogo de 94 plugins; no máximo pinçar um de nicho. Nunca o marketplace todo, nunca `protect-mcp` |
| ponytail 5.2.0 → 5.3.3 | **Feito em 03/11:** atualizado; o registro por turno (`ledger`) e o envio de nomes (`sendNames`) foram desligados com `claude plugin configure ponytail@ponytail --values-stdin` (`{"ledger":"false","sendNames":"false"}`); webhook vazio. Vale após reiniciar |
| session-report, commit-commands, playground, plugin-dev, LSPs | Repetem codeburn, regras de commit, skills existentes |

## Descartado
- **Harness concorrente do que já existe:** gstack, ECC, oh-my-claudecode (hooks em todo evento, centenas de skills, disputam o papel do superpowers e do ruflo).
- **Memória que repete o que foi removido ou pesa demais:** claude-mem (nada muda o motivo da remoção; agora ainda tem sincronização em nuvem opcional), agentmemory (54 ferramentas MCP, `@latest`), beads (segundo sistema de tarefas), graphify (duplica o codegraph com mais superfície), repomix como plugin (MCP via `npx @latest`; a CLI avulsa com versão fixa serve se precisar).
- **Gateways de conta e provedor:** cc-switch e claude-code-router (mexem em credenciais e config global e duplicam o plano de reserva por FreeLLMAPI; o cc-switch usa assinaturas fora do cliente oficial, o que pode violar os termos), multica (Docker, Postgres e telemetria), vibe-kanban (projeto encerrando).
- **Economia de tokens:** headroom (disputa o hook de Bash com o rtk, Python 3.13, telemetria ligada) e caveman (o ponytail já cobre; o próprio README mostra ganho de 3% sobre "seja conciso"; o instalador usa `npx @latest`).
- **Skills e plugins oficiais redundantes:** ui-ux-pro-max (quarto sistema de design), anthropics/skills (já carregado como `anthropic-skills`), hookify, security-guidance, ralph-loop, os estilos de saída, code-review, pr-review-toolkit, feature-dev, code-simplifier, frontend-design, skill-creator, e os MCPs github, playwright e serena como plugins.
- **Só leitura, não é ferramenta:** learn-claude-code, andrej-karpathy-skills (já coberto 3 vezes), system-prompts-and-models-of-ai-tools (GPL-3.0, origem duvidosa), claude-code-best-practice, awesome-claude-skills e awesome-mcp-servers (consulta).

## Mantidos como estão
taste-skill, mattpocock-skills e agent-skills (o mais pesado em contexto: primeiro a podar se faltar token, depois o mattpocock).

## Limites desta avaliação
Os agentes leram metadados e arquivos de configuração, não auditaram o código inteiro. Telemetria de gstack, ECC e oh-my-claudecode, número de ferramentas MCP de serena, github e playwright, e o diff de hooks do superpowers 7.x **não foram verificados**. As economias de tokens citadas por caveman, headroom e rtk são alegações dos autores.

## Cofre Obsidian
Nenhuma ferramenta da lista é a certa: o cofre é Markdown com índices. Recomendação: `INDEX.md` por pasta e links entre notas, lidos com Read e Grep pelo Claude Code; se crescer além do que o Grep aguenta, o codegraph entra como índice de código.
