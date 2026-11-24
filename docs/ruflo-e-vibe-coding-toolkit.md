# Ruflo e Vibe Coding Toolkit (extras de 21/10/2026)

Os dois entram no `instalar.ps1` (passos 2 e 3). Nenhum dos dois guarda chave ou senha.

## Vibe Coding Toolkit
- **Link:** https://github.com/soumatheusgomes/vibe-coding-toolkit (MIT, ~1,8 mil estrelas)
- **O que é:** **não é plugin.** É um conjunto de documentos, prompts e modelos para preparar a máquina e iniciar ou melhorar projetos com Claude Code e Codex. O código fica no seu projeto; o repositório só guarda a "receita".
- **Como ficou instalado:** clone raso em `%USERPROFILE%\.claude\extras\vibe-coding-toolkit` (só para consulta offline). O script faz isso sozinho.
- **Como usar** (abra o agente na pasta do projeto e cole):
  - Projeto novo (Next.js): `Read https://raw.githubusercontent.com/soumatheusgomes/vibe-coding-toolkit/main/docs/prompts/11-next-project-bootstrap.md and execute setup in this directory.` e na linha seguinte `Project: [nome, problema, público, fluxos, restrições].`
  - Projeto existente: `Read https://raw.githubusercontent.com/soumatheusgomes/vibe-coding-toolkit/main/docs/prompts/12-existing-project-setup.md and execute the entire "Prompt" section block in this project, starting with brainstorming.`
  - Preparar a máquina: `docs/03-environment-setup.md` e o prompt 10.
- **Cuidado:** o prompt 12 manda o agente instalar e configurar coisas no projeto (hooks, skills, MCPs). Rode primeiro numa cópia ou numa branch, e leia o plano antes de aprovar. Em projeto que já tem estrutura própria, prefira só consultar os documentos.
- **Atualizar:** `git -C "%USERPROFILE%\.claude\extras\vibe-coding-toolkit" pull`.
- **Remover:** apague a pasta acima.

## Ruflo
- **Link:** https://github.com/ruvnet/ruflo (MIT, ~78 mil estrelas, atualizado todo dia). Enxame de agentes, memória entre sessões e servidor MCP para o Claude Code.
- **O que foi instalado:** só o **`ruflo-core@ruflo`** (versão 0.2.11, escopo de usuário). Não instalei `ruflo-console`, `ruflo-mods`, `ruflo-swarm` nem `ruflo-rag-memory`: o próprio README avisa que os mods rodam sem sandbox e com as suas permissões.
- **Comandos:** `/ruflo-status` e `/witness`; agentes `coder`, `researcher`, `reviewer`, `witness-curator`; servidor MCP `ruflo`.

### O que li antes de instalar (e o que isso significa)
O plugin registra **hooks em toda chamada de Bash, Write, Edit e MultiEdit** (antes e depois). Cada hook roda `scripts/ruflo-hook.cjs`, que:
1. usa o `ruflo` ou `claude-flow` local, se existir;
2. **senão baixa e roda `npx --yes ruflo@latest`**, sem fixar versão;
3. sempre termina com sucesso (nunca bloqueia nem mostra erro), e o código chama isso de "telemetria" de melhor esforço. Conferi o destino: ver a seção abaixo.

Consequências práticas:
- Pacote npm sem versão fixa rodando a cada edição e a cada comando, **em todos os projetos e sessões**, vendo o que você digita no Bash. Se o pacote for comprometido, ele roda na sua máquina.
- Cada chamada pode ficar mais lenta, e a maior parte do trabalho nem usa o ruflo.

### O que a "telemetria" envia de verdade (conferido no código do pacote `@claude-flow/cli` 3.59.7, em 21/10/2026)
- **Seu código, comandos, prompts e caminhos não são enviados.** Os hooks gravam o que acontece **só no disco**, na pasta `.claude-flow/` do projeto (comandos, edições, resultados). Isso fica "em repouso" na sua máquina: se um comando tinha uma senha, ela pode ficar lá. Ponha `.claude-flow/` no `.gitignore` dos projetos.
- **Eventos de funil** (`POST funnel.ruv.io/v1/events`) só saem se você der o consentimento "telemetry"; o padrão é **desligado**. O esquema é fechado (lista fixa de eventos, data sem hora, sem campo para prompt, comando, caminho ou nome de repositório).
- **O que sai sem você pedir:** uma busca (`GET funnel.ruv.io/v1/messages`) de mensagens promocionais, sem enviar dados seus além do IP e do User-Agent `ruflo-funnel/messages`. Desligada por `RUFLO_FUNNEL=0`.
- Outras saídas (federação, `http_fetch`, roteamento em nuvem, memória hospedada, compartilhar dados de treino) só existem se você ativar ou chamar.
- **Conclusão:** não é vazamento de conteúdo. O risco real era outro: **rodar `npx ruflo@latest` (sem versão fixa) a cada chamada**, que é cadeia de suprimentos.

### Configuração aplicada (mantém todas as funções)
1. **Versão fixa e local:** `npm install -g ruflo@3.59.7`. Com o binário local, os hooks e o servidor MCP não baixam mais nada.
2. **Variáveis de usuário** (já aplicadas com `setx`; reabra o Claude): `RUFLO_HOOK_SKIP_NPX=1` e `RUFLO_MCP_SKIP_NPX=1` (proíbem o `@latest`) e `RUFLO_FUNNEL=0` (desliga a busca de mensagens promocionais).
3. **Atualizar de propósito:** leia o changelog e rode `npm install -g ruflo@<nova versão>`.
4. **Limite conhecido:** o npm bloqueou os scripts nativos de instalação (`better-sqlite3`, `onnxruntime-node`, `argon2`…). Se alguma função de memória/vetores falhar, rode `ruflo-doctor` (skill do plugin) e só então libere com `npm install -g --allow-scripts=<pacote> ruflo@3.59.7`.
- **Desligar sem desinstalar:** `claude plugin disable ruflo-core@ruflo`. Remover: `claude plugin uninstall ruflo-core@ruflo`, `claude plugin marketplace remove ruflo` e `npm uninstall -g ruflo`.

### Quando faz sentido
Ruflo é pesado e pensado para orquestrar muitos agentes. Para o dia a dia com Superpowers e o Codex, ele **não é necessário**. Instalado por pedido; reavalie depois de usar o `/ruflo-status` por uns dias.
