# Claude Desktop com chave de API da Anthropic (quando o limite do plano acaba)

Status: **guia, ainda não testado de ponta a ponta** (03/11/2026). Fontes: documentação oficial do Claude Code (autenticação e gateway) e do Claude Desktop on 3P (configuração de gateway), lidas em 03/11.

## O que a documentação confirma
- O aplicativo **não lê** `ANTHROPIC_API_KEY` nem `apiKeyHelper`. Isso vale para o terminal, não para o app. Sessões na nuvem também ficam de fora.
- O app tem uma **configuração de inferência de terceiros**, que é o mecanismo que o FreeLLMAPI usa. O gateway precisa falar o formato Messages da Anthropic: `POST /v1/messages` com streaming e uso de ferramentas é obrigatório; `GET /v1/models` é opcional (sem ele, informe os modelos em `inferenceModels`).
- Com essa configuração ativa, o app não oferece ambientes na nuvem da Anthropic, e o Remote Control fica indisponível.

## Passo a passo (o gateway guarda a chave, o app só conhece o endereço)
1. **Chave de API:** crie uma em console.anthropic.com, com **limite de gasto mensal** definido lá. A chave só entra **no gateway**, nunca no chat nem em arquivo do repositório.
2. **Gateway local:** o OmniRoute (já no `LEIA-ME`, seção 3.2) escuta em `http://localhost:20128`. No painel dele: Provedores → Anthropic → "+ Adicionar Conexão" → cole a chave → "Importar de /models". Crie um **combo** com estratégia `priority`: 1º um modelo Claude pela sua chave, 2º os gratuitos que você já conectou (Groq, Gemini, etc.) como reserva. O OmniRoute também aceita `auto`, que escolhe sozinho.
3. **App:** Help → Troubleshooting → **Enable Developer Mode** (o app reinicia). Depois Developer → **Configure Third-Party Inference…**, seção Connection:
   - Gateway base URL: `http://localhost:20128`
   - Gateway API key: a chave do próprio OmniRoute (não a da Anthropic)
   - Credential kind: Static API key
   - Gateway auth scheme: Bearer (ou x-api-key, se o gateway pedir)
   - Se o gateway não listar os modelos, preencha `inferenceModels` com o nome do combo.
4. **Voltar à assinatura:** desligar a configuração no mesmo formulário e reiniciar o app. O gateway só é usado enquanto a configuração está ativa.

## Cuidados
- **Custo:** o gateway precisa **preservar o cache de prompt** (`cache_control`). Se ele tirar isso, cada turno reprocessa a conversa inteira a custo cheio. Conferir: depois do 1º pedido, `cache_read_input_tokens` deve ficar bem acima de zero nos logs do gateway.
- **Histórico:** as sessões ficam em disco, mas **não verifiquei** se o app mostra as sessões antigas com a configuração de terceiros ligada.
- **Privacidade:** com o OmniRoute usando modelos gratuitos como reserva, o conteúdo da conversa vai para esses serviços. Para material sigiloso, deixe só a Anthropic no combo.
- **Não verificado:** se o OmniRoute implementa o formato Messages com streaming e ferramentas como o app exige (o `omniroute run claude` sugere que sim); o formulário do app com `http://` local (o FreeLLMAPI já funcionou assim para você); o comportamento do combo quando a chave da Anthropic atinge o teto de gasto.

## Alternativas
- **Terminal:** `ANTHROPIC_API_KEY` no PowerShell e `claude --continue`. Funciona sem gateway e preserva a sessão.
- **Login do Console:** no terminal, `/login` com a conta do Console Anthropic troca a cobrança para a API, sem chave solta.
- **Codex:** `/codex:rescue` (plugin instalado) ou `codex exec` seguem como reserva sem custo de API da Anthropic.
