# Plano: do Claude Pro pessoal para o FreeLLMAPI quando os créditos acabarem

Status: **PLANO** (21/10/2026). Nada disso foi testado com o FreeLLMAPI de verdade; o que está marcado "a verificar" precisa de teste antes de confiar.

## O que você pediu
1. Manter **todas as sessões** (não perder o histórico ao trocar).
2. Usar os **créditos do Claude Pro pessoal** enquanto houver.
3. Quando acabarem, **trocar para o FreeLLMAPI** (modelos gratuitos).

## O que descobri (fatos que moldam o plano)
- **As sessões são arquivos locais** (`%USERPROFILE%\.claude\projects\<projeto>\<id>.jsonl`). Quem escolhe o modelo é o processo que as abre, então dá para abrir a **mesma sessão** com outro backend: `claude --continue` (a mais recente do projeto) ou `claude --resume <id>`. Essa é a base do plano.
- **O Claude Code aceita um backend alternativo por variável de ambiente** (`ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_MODEL`). Valendo só para o processo que as recebe, a conta Pro nem é tocada.
- **O FreeLLMAPI fala o formato Anthropic** (`/v1/messages`) e tem cadeia de fallback entre provedores, contadores de limite por chave e o modelo `auto` (README dele). A porta do app de bandeja no Windows é **31415** (a 3001 é só Docker/código-fonte), como no LEIA-ME.
- **Termos de uso:** passar o login da assinatura Pro por um proxy de terceiros **pode violar os termos** da Anthropic (já avisado no LEIA-ME, seção 3.3). Por isso o plano **não** coloca o gateway "na frente" da conta Pro.

## Por que o histórico sumiu na troca (diagnóstico de 21/10)
O `freellmapi launch --profile <nome>` (e o `setup-claude --profile`) abre o Claude com **`CLAUDE_CONFIG_DIR=~/.claude/profiles/<nome>`**, uma pasta de configuração **separada**. As sessões ficam em `<pasta de config>\projects\`, então a conversa de `~/.claude/projects` **não aparece** no perfil. A conversa não foi apagada: está na pasta original. Conferi o código do `freellmapi` 0.8.2: sem `--profile` ele usa a pasta padrão.
**Regra do plano: nunca trocar a pasta de configuração.** Troca-se só o backend (`ANTHROPIC_BASE_URL` e a chave) no processo, e o `claude-free.ps1` **para com erro** se `CLAUDE_CONFIG_DIR` estiver definida.
Recuperar a conversa de ontem: abra o `claude` normal na mesma pasta do projeto e use `/resume` (ou `claude --resume`). Se ainda não voltar, procure o `.jsonl` em `~/.claude/projects/` e `~/.claude/profiles/*/projects/` e copie para a pasta padrão.

## Decisão de desenho (revisada: o gateway é sempre o reserva)
Você quer que o gateway **nunca deixe o trabalho travar**. Isso se faz em camadas, **sem passar o login do Pro por um proxy de terceiros** (risco de termos de uso):

| Camada | Como o reserva entra | Automático? |
|--------|----------------------|:---:|
| **Claude Code** | `cc` no lugar de `claude`: quando o turno termina por limite, o hook grava um sinal e o `cc` oferece continuar **a mesma sessão** pelo FreeLLMAPI | quase (1 tecla S/n) |

## Fases

### Fase 0: preparar o FreeLLMAPI (uma vez por máquina, só você faz)
Você já tem isso na máquina pessoal. Nesta máquina: instalar (`instalar.ps1`), colar as chaves na página **Keys** do app (chaves novas, nomeadas "FreeLLMAPI"), copiar a "unified key" e gravar **fora do chat**:
`[Environment]::SetEnvironmentVariable('FREELLMAPI_API_KEY','freellmapi-...','User')` (reabra o terminal).
**Pronto quando:** `curl http://localhost:31415/v1/models -H "Authorization: Bearer %FREELLMAPI_API_KEY%"` lista modelos.

### Fase 1: troca manual que preserva o histórico (`scripts/claude-free.ps1`, a testar)
Na pasta do projeto: `.\scripts\claude-free.ps1` (continua a sessão mais recente) ou `-Sessao <id>`. Volta ao Pro abrindo o `claude` normal e `--continue`.
**Testes, numa pasta descartável:** (1) responde uma pergunta e o painel do app mostra o provedor; (2) uma sessão criada no Pro é retomada e o modelo "lembra"; (3) a mesma sessão reabre no Pro com o que foi dito no gratuito; (4) uma tarefa com ferramentas (ler, editar, rodar teste) funciona. **Pelo teste 2, confirmar que a conversa de antes não some.**

### Fase 2: aviso e retomada quase automática (`cc.ps1` + hook, a testar)
1. Registrar o hook em `~/.claude/settings.json` (**você aprova a mudança**; mudar configuração é decisão sua):
```json
{ "hooks": { "StopFailure": [ { "matcher": "rate_limit|overloaded|billing_error", "hooks": [ { "type": "command", "command": "node C:/CAMINHO/claude-windows-powerkit/scripts/claude-limite-hook.cjs" } ] } ] } }
```
2. Usar `cc` no lugar de `claude` (função no perfil do PowerShell: `function cc { & C:\CAMINHO\claude-windows-powerkit\scripts\cc.ps1 @args }`).
3. **A verificar com um limite real:** (a) se o esgotamento do plano Pro chega como `rate_limit` (a documentação não diz); o `payloads.log` em `%TEMP%\claude-limite` guarda o que o hook recebeu, para ajustar o `matcher`; (b) se o hook dispara no limite semanal.
O hook foi testado só com um payload falso: grava o sinal e o log, não envia nada para fora e não altera o modelo nem a conta.


### Fase 4 (opcional): automático total com API paga
OmniRoute com combo: Anthropic por **chave de API** (teto de gasto) → grátis. Gasta API, não o Pro. Só se você quiser.

## Riscos e como lidar
- **Qualidade e ferramentas:** modelos grátis erram mais em edição de vários arquivos e uso de ferramentas. Use-os para leitura, texto e tarefas pequenas; deixe o trabalho pesado para quando o Pro voltar.
- **Histórico com blocos do Claude** (raciocínio assinado, formatos próprios): outro modelo pode rejeitar ou ignorar partes. **A verificar** no critério 2 da Fase 1. Se travar: `/compact` antes de trocar, ou abrir sessão nova com um resumo.
- **Contexto menor** nos modelos grátis: rode `/compact` antes de trocar numa sessão longa.
- **Privacidade:** Google, OpenRouter e outros grátis podem registrar ou usar o que você envia. **Não use o gateway com arte inédita, conteúdo de cliente ou segredo.** Para material confidencial, só o Ollama local.
- **Limites diários baixos** (ex.: 50 pedidos/dia no OpenRouter grátis): o app faz o fallback entre chaves, mas a soma é pequena.
- **Segurança:** a unified key só em variável de usuário; o app só aceita este PC; nunca escrever chave no repositório.

## Próximos passos
1. Você: recuperar a conversa de ontem (`/resume`) e aprovar o hook (Fase 2).
2. Eu e você: testar as Fases 1 e 2 e corrigir os scripts.
