# Extras do Claude Code: guia completo de instalação (Windows)

Versão 3 · 12/10/2026 · Windows 11 · Claude Code 2.1.289
Nesta pasta:
- `LEIA-ME.md`: este guia.
- `instalar.ps1`: instala quase tudo sozinho.
- `verificar.ps1`: confere o que está instalado, sem mexer em nada.
- `jarvis\jarvis_show.py`: o modo "duas palmas" do Jarvis.

---

## ⚠️ Antes de tudo: use um PowerShell normal

O app do Claude (aba Code) desvia para uma pasta privada dele tudo o que é criado em `AppData`.
Se o Graphify, o Agent Reach, o Strix, o yt-dlp ou o OpenJarvis forem instalados de dentro do app, **eles só funcionam dentro do Claude**.

- Rode o script num **PowerShell aberto pelo Menu Iniciar**.
- **Não peça ao Claude para rodar o script.** Além do desvio de pastas, o modo automático do Claude bloqueia instalações em massa,
  a flag `--allow-scripts` do npm e mudanças na configuração do próprio Claude.
- O script tem uma trava: se perceber que está dentro de um app, ele avisa e para.

## Resumo em 4 passos

1. Leve esta pasta para a outra máquina. Ela está no GitHub: https://github.com/gugaibarros-cpu/setup-extras-claude
   - Com o `gh`: `gh repo clone gugaibarros-cpu/setup-extras-claude`.
   - Sem GitHub: **Code → Download ZIP** e copie o ZIP.
2. **Menu Iniciar → digite "PowerShell" → abra.** Vá até a pasta e rode:
   ```
   cd "CAMINHO\DESTA\PASTA"
   powershell -ExecutionPolicy Bypass -File .\instalar.ps1
   ```
3. Feche e abra o Claude e o terminal. Confira com `powershell -ExecutionPolicy Bypass -File .\verificar.ps1`.
4. Faça a **Parte 3** (logins e chaves), só o que for usar.

---

## Parte 1: antes de começar

- **Claude Code** instalado e com login feito. Teste com `claude --version`.
  Se não tiver: `irm https://claude.ai/install.ps1 | iex`, depois rode `claude` uma vez para fazer login.
- **winget** (já vem no Windows 11).
- **Espaço livre:** uns 35 GB com tudo (`gpt-oss:20b` 13 GB + `gemma4:e4b` 6,6 GB + Jarvis com voz ~3 GB). Sem modelos locais, uns 8 GB.
- O script instala sozinho: Git, Node.js, uv, Bun, FFmpeg, GitHub CLI e Ollama.
- O **Docker não é instalado**. Só o Strix precisa dele (ver 3.8).

## Parte 2: rodar o script

Abra o `instalar.ps1` no Bloco de Notas para escolher o que instalar (logo no topo):

| Opção | Padrão | O que faz |
|-------|--------|-----------|
| `$INSTALAR_OLLAMA` | `$true` | Ollama + modelo local grátis. Precisa de placa de vídeo com ~16 GB |
| `$MODELO_OLLAMA` | `'gpt-oss:20b'` | Baixa 13 GB. Placa de 8 GB: troque por `'qwen3:8b'` |
| `$INSTALAR_FREELLMAPI` | `$true` | Baixa do GitHub, confere o SHA-256 e instala (o instalador não tem assinatura digital) |
| `$INSTALAR_OPENJARVIS` | `$true` | Jarvis: assistente local com voz em português (~3 GB) |
| `$MODELO_JARVIS` | `'gemma4:e4b'` | O "cérebro" do Jarvis, 6,6 GB. Máquina fraca: `'gemma4:e2b'` |
| `$INSTALAR_REA` | `$true` | Engenharia reversa de apps com agentes |

- Leva de 15 a 30 minutos. A maior parte do tempo é o download do modelo local.
- Pode rodar de novo quantas vezes quiser: o que já está instalado é pulado.
- No fim aparecem os plugins, cada ferramenta com **OK** ou **FALTANDO**, e a lista do que falhou.

---

## Parte 3: passos manuais (o script não faz)

| # | O quê | Para quê | Seção |
|---|-------|----------|-------|
| 1 | Login no GitHub | Agent Reach ler o GitHub | 3.1 |
| 2 | OmniRoute: senha e provedores | Usar LLMs grátis | 3.2 |
| 3 | Criar as chaves dos serviços de LLM | Idem | 3.3 |
| 4 | FreeLLMAPI: colar as chaves | Opcional (faz o mesmo que o OmniRoute) | 3.4 |
| 5 | Modelo local no OmniRoute | Se instalou o Ollama | 3.5 |
| 6 | Jarvis: microfone e modo palmas | Opcional | 3.6 |
| 7 | rea: análise de executáveis | Opcional | 3.7 |
| 8 | Strix: Docker + chave | Opcional | 3.8 |
| 9 | Task Observer: ativação completa | Opcional | 3.9 |
| 10 | Agent Reach: canais extras | Opcional | 3.10 |
| 11 | Ponytail: "status line" | Opcional | Na 1ª sessão o Claude oferece. Pode recusar. |

### 3.1 Login no GitHub
`gh auth login` → GitHub.com → HTTPS → "Login with a web browser". Confira com `gh auth status`.

### 3.2 OmniRoute (roteador de LLMs, porta 20128)
1. Num terminal, rode `omniroute` e deixe a janela aberta. Na primeira vez ele demora. A mensagem "Server did not respond within 60s" é normal.
2. Abra http://localhost:20128 e entre com a senha inicial **`CHANGEME`**. **Troque a senha na hora**, nas configurações do painel.
3. **Segurança:** na inicialização **não** pode aparecer "SECURITY: listening on 0.0.0.0".
   O script grava `OMNIROUTE_SERVER_HOST=127.0.0.1` em `%USERPROFILE%\.omniroute\.env`, para só este PC acessar.
   Se o aviso aparecer, confira essa linha nesse arquivo e reinicie com `omniroute restart`.
4. Para conectar um provedor: **Provedores → nome do provedor → "+ Adicionar Conexão" → cole a chave → Salvar.**
5. Logo depois, clique em **"Importar de /models"** para puxar a lista real de modelos. Se o botão estiver cinza, aperte **F5**.
6. Para abrir um Claude Code usando um modelo grátis: `omniroute run claude --model groq/qwen/qwen3.8-27b`. Para parar o servidor: `omniroute stop`.

### 3.3 Serviços de LLM (todos os que configuramos)

**Grátis, testados em 12/10/2026:**

| Serviço | Onde criar a chave | Custo | Modelo que funcionou (nome no OmniRoute) | Observação |
|---------|--------------------|-------|------------------------------------------|------------|
| **Groq** | https://console.groq.com/keys | Grátis, sem cartão | `groq/qwen/qwen3.8-27b` (0,3 s) · `groq/openai/gpt-oss-120b` | O mais rápido |
| **Google AI Studio** (Gemini) | https://aistudio.google.com/apikey | Grátis num projeto **sem faturamento** | `gemini/gemini-3.8-flash` · `gemini/gemini-3.1-flash-lite` | No grátis o Google pode usar o que você envia. O 2.5 Pro não está disponível para contas novas |
| **NVIDIA NIM** | https://build.nvidia.com → seu perfil → API Keys | Grátis (cadastro por e-mail) | `nvidia/moonshotai/kimi-k3` | Bom para código. O DeepSeek por lá chegou a levar 2 min |
| **OpenRouter** | https://openrouter.ai/keys | Grátis: 50 pedidos por dia nos modelos `:free` | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` | Limite por minuto: erro 429 quer dizer espere 1 a 2 min. Os provedores podem usar os seus prompts |
| **Ollama** (no seu PC) | Não precisa de chave | Grátis, sem limite, privado | `ollama/gpt-oss:20b` · `gemma4:e4b` (o do Jarvis) | O único bom para material confidencial. Precisa de placa com 16 GB |

**Pagos (conecte quando quiser):**

| Serviço | Onde criar a chave | Custo | Observação |
|---------|--------------------|-------|------------|
| **Claude** (Anthropic) | https://console.anthropic.com → API Keys | Pago por uso | Prefira a chave de API. Usar a assinatura Pro/Max por login num proxy de terceiros pode violar os termos |
| **ChatGPT** (OpenAI) | https://platform.openai.com/api-keys | Pago por uso | A assinatura Plus **não** inclui a API |
| **Gemini pago** | https://aistudio.google.com/apikey, num projeto **com faturamento** | Pago por uso | Libera o `gemini-3.1-pro-preview`, e os dados não são usados para treino |
| Cerebras | https://cloud.cerebras.ai | Pede US$ 5 para liberar a API | Não conectado |
| SambaNova | https://cloud.sambanova.ai | Exige cartão | Não conectado |
| Mistral | https://console.mistral.ai | Pede plano Pro. O "Experiment" grátis exige liberar treino com os seus prompts | Não conectado |

**Não funcionaram ("sem chave"):** OpenCode Free (bloqueia uso fora do app dele), Pollinations (agora pede chave), UncloseAI (modelo não existe).
**Evite** os revendedores que prometem "Claude/GPT grátis" (xKiro, AgentRouter, BazaarLink, BluesMinds, Api.airforce, LLM7): os seus prompts passam por terceiros desconhecidos.

**Qual modelo usar:**

| Para… | Modelo |
|-------|--------|
| Privado e sem limite | `ollama/gpt-oss:20b` |
| Resposta rápida | `groq/qwen/qwen3.8-27b` |
| Melhor qualidade grátis | `gemini/gemini-3.8-flash` |
| Código e ferramentas | `nvidia/moonshotai/kimi-k3` |
| O maior modelo | `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free` |

**Cuidados com as chaves:**
- Dê um nome a cada chave (ex.: "OmniRoute", "FreeLLMAPI") e use uma chave diferente por app. Se uma vazar, você apaga só aquela.
- Guarde as chaves num gerenciador de senhas: cada site só mostra a chave na hora em que ela é criada.
- **Nunca cole chaves no chat do Claude.** O Claude-Mem grava tudo o que você digita.

### 3.4 FreeLLMAPI (porta 31415)
1. O script já instala. Para instalar à mão: baixe `FreeLLMAPI-Setup-<versão>.exe` em https://github.com/tashfeenahmed/freellmapi/releases/latest
   O instalador **não tem assinatura digital**, então o Windows pode avisar.
2. Abra pelo **ícone na bandeja** do Windows. Pelo navegador (http://localhost:31415) ele pede login.
   Ele só aceita conexões deste PC. A porta 3001 que aparece na documentação dele só vale para Docker e código-fonte.
3. Na página **Keys**, cole as chaves. Crie chaves novas só para ele, com o nome "FreeLLMAPI".
4. A sua "unified key" aparece no app e começa com `freellmapi-`.
5. Nomes de modelo: `auto` (ele escolhe sozinho), ou o nome sem o provedor na frente: `gemini-3.8-flash`, `openai/gpt-oss-120b`, `nvidia/nemotron-3-ultra-550b-a55b`.
   Os nomes `claude-opus-4-5` e parecidos da lista são **apelidos para modelos grátis**, não o Claude de verdade.
6. Para abrir um Claude Code por ele: `npx freellmapi launch --url http://localhost:31415 --api-key SUA-UNIFIED-KEY`
   Não use `setup-claude` sem `--profile`: ele faria **todas** as sessões do Claude usarem modelos grátis.

### 3.5 Modelo local no OmniRoute (Ollama)
1. O script instala o Ollama e baixa o modelo. O Ollama fica na bandeja e só aceita conexões deste PC.
2. No OmniRoute: **Provedores → Ollama → "+ Adicionar Conexão"** → deixe a URL `http://localhost:11434/v1` e a chave vazia → **Salvar** → **"Importar de /models"**.
3. Use `ollama/gpt-oss:20b`. A primeira resposta demora uns 30 s. Testado numa AMD RX 9060 XT 16 GB: 100% na placa, ~23 tokens/s.
4. Enquanto está carregado, o modelo ocupa uns 12 GB da memória de vídeo. Antes de usar ComfyUI ou jogos, feche o Ollama na bandeja.

### 3.6 Jarvis (OpenJarvis com voz em português)
Montado conforme o guia **"Jarvis Local", de @marcondes.ai**: ouve com o faster-whisper, pensa com o `gemma4:e4b` e fala com o Kokoro, na voz `pf_dora`.
Tudo roda no PC, sem conta e sem internet. Projeto: https://github.com/open-jarvis/OpenJarvis (Hazy Research / Stanford).

**O que o script já deixa pronto:**
- A pasta `%USERPROFILE%\jarvis`, com voz, modelo `gemma4:e4b` e interface web compilada.
- A configuração em `%USERPROFILE%\.openjarvis\config.toml`: perfil de segurança `personal`, voz `pf_dora`, idioma `pt`.
  O perfil `personal` **aumenta** a proteção: oculta dados pessoais, limita requisições e deixa o servidor só neste PC.
- Os comandos `jarvis` e `jarvis-show`, que funcionam em qualquer pasta.

**Passos seus:**
1. **Microfone:** Configurações do Windows → Privacidade e segurança → Microfone → deixe ligado para os aplicativos da área de trabalho.
2. Teste a voz: `jarvis chat --voice`. Fale, espere o silêncio, e ele responde falando.
3. **Modo show (duas palmas):**
   - Calibre antes: `jarvis-show --teste` mostra o volume ao vivo. A palma precisa passar do número da sensibilidade (padrão 0,30).
   - Depois rode `jarvis-show` e bata **2 palmas**. Ele toca o jingle, abre a interface web e começa a conversa por voz. Quando a conversa termina, ele volta a esperar palmas.
   - Para mudar a sensibilidade: `set JARVIS_CLAP_THRESH=0.45` no cmd, ou `$env:JARVIS_CLAP_THRESH="0.45"` no PowerShell. Número maior = menos sensível.
   - Para escolher o microfone: `jarvis-show --listar` e depois `set JARVIS_MIC=Fifine` (número ou parte do nome).
   - Áudio de abertura (opcional): coloque `jingle.mp3` em `%USERPROFILE%\jarvis\voz\assets\`. Pode ser um áudio exportado do ElevenLabs.

**Uso no dia a dia:**

| Comando | O que faz |
|---------|-----------|
| `jarvis` | Conversa por texto no terminal |
| `jarvis ask "Resuma o meu dia em três prioridades"` | Uma pergunta só |
| `jarvis chat --voice` | Conversa por voz |
| `jarvis start` / `jarvis stop` | Liga/desliga a interface web em http://127.0.0.1:8000 |
| `jarvis-show` | Modo show: 2 palmas abrem tudo |
| `jarvis doctor` | Diagnóstico. Rode primeiro quando algo der errado |

**Vozes:**

| Voz | Custo | Como usar |
|-----|-------|-----------|
| Kokoro `pf_dora` (padrão) | Grátis, local | Já vem configurada |
| OpenAI | Chave de API | `set OPENAI_API_KEY=...` e depois `jarvis config set speech.tts_backend openai_tts` |
| Cartesia | Chave de API | `set CARTESIA_API_KEY=...` e depois `jarvis config set speech.tts_backend cartesia` |
| ElevenLabs | Chave de API | Não vem pronto. Use um mp3 exportado como `jingle.mp3`, ou peça ao Claude um backend novo |
| Voltar para a grátis | — | `jarvis config set speech.tts_backend kokoro` |

Dica do guia: use uma semana a voz grátis antes de decidir se vale pagar a premium.

**Notas:**
- Para trocar o modelo: `jarvis config set intelligence.default_model gemma4:e2b` (mais leve) ou `gpt-oss:20b` (mais forte e mais lento).
- A primeira resposta demora uns 40 s porque o modelo carrega. As próximas são bem mais rápidas.
- O aviso "No module named 'openjarvis_rust'" é normal: é um componente opcional que só compila com o Rust.

### 3.7 rea (engenharia reversa com agentes)
1. O script instala o `rea-agents` e registra no Claude Code. Se esse passo falhar, rode você mesmo: `rea setup --client claude_code --yes`
2. Sem nada a mais, ele já analisa apps JavaScript/Electron e binários Go.
3. Para executáveis nativos (.exe, .dll), ele precisa de um desses:
   - **Ghidra**, grátis (no Windows o suporte ainda é experimental e precisa de JDK)
   - **IDA**, pago
   - O Hopper não roda no Windows.
4. Conferir: `rea doctor`. Remover: `rea uninstall`.
5. Use só em programas seus ou que você tem autorização para analisar.

### 3.8 Strix (testes de segurança com IA)
1. Instale o Docker Desktop: `winget install --id Docker.DockerDesktop -e`. Pede admin, usa WSL2 e pode pedir reinício.
   Empresas grandes (mais de 250 pessoas ou de US$ 10 mi de faturamento) precisam de licença paga do Docker.
2. Abra o Docker Desktop e espere ficar "running".
3. No mesmo terminal em que vai rodar o Strix:
   ```
   $env:STRIX_LLM   = "anthropic/claude-sonnet-5-5"   # ou outro modelo
   $env:LLM_API_KEY = "SUA-CHAVE"
   ```
4. Use só em sistemas seus ou com autorização: `strix --target .\minha-app`

### 3.9 Task Observer (opcional)
Ele já vem instalado, e o próprio skill pede para ser usado no início das sessões. A "ativação completa" é um bloco de texto longo
que vai no `CLAUDE.md` global e faz ele rodar em **toda** sessão (gasta tokens sempre). Só faça se quiser mesmo:
1. Abra `%USERPROFILE%\.claude\skills\task-observer\references\environments.md`.
2. Copie o bloco abaixo do título **"The activation block"**.
3. Cole no fim de `%USERPROFILE%\.claude\CLAUDE.md`, com uma linha **`# task-observer`** logo antes.
   Sem esse título, o bloco fica dentro da seção do Graphify, e o `graphify install` (que o script roda) **apaga** o bloco.
4. Troque, usando barras `/`:
   - `[ABSOLUTE PATH]` por uma pasta **fora do OneDrive**, sem espaços. Exemplo: `C:/Users/SEU-USUARIO/task-observer`
   - `<skill directory>` por `C:/Users/SEU-USUARIO/.claude/skills/task-observer`
   - `[PROJECTS ROOT]` pela pasta dos seus projetos

### 3.10 Agent Reach: canais extras (opcional)
- Já funcionam: páginas web, YouTube, RSS, V2EX e Bilibili. Depois do `gh auth login`, o GitHub também.
- Para os outros: `agent-reach install --env=auto --system --channels=twitter,reddit`
- Twitter e Reddit pedem **cookies** de login. A própria documentação recomenda uma **conta secundária**, porque há risco de banimento.
- Ver o que está ativo: `agent-reach doctor`

---

## Parte 4: conferir se deu certo

**O jeito fácil:** rode `powershell -ExecutionPolicy Bypass -File .\verificar.ps1` num PowerShell normal. Ele mostra **OK** ou **FALTA** para cada item, sem mexer em nada.

Conferir à mão:
1. `claude plugin list` deve mostrar estes 8 com `√ enabled`:
   `agent-skills`, `brag`, `claude-code-setup`, `claude-mem`, `impeccable`, `ponytail`, `superpowers`, `taste-skill`.
2. `claude mcp list` deve mostrar o `rea` conectado.
3. Abra o Claude e digite `/`. Devem aparecer, entre outros: `/ponytail`, `/impeccable`, `/brag`, `/graphify`, `/playwright-cli`, `/web-design-guidelines`, `/apple-look`, `/apple-motion`.
   Para usar os skills da Apple, cite o nome no pedido. Ex.: "Use the apple-motion skill to review the animations in this page" ou "Use the apple-look skill to review this screen (What / Why / Fix)".
4. Claude-Mem: depois de abrir uma sessão, http://localhost:37777 deve abrir o visualizador.
5. `agent-reach doctor` deve listar os canais com ✅.
6. `jarvis doctor` deve mostrar "Python 3.13", "Default model gemma4:e4b (on ollama)", "Speech backend faster-whisper ready" e "Security profile 'personal' active".
   Teste: `jarvis ask "Em uma frase, quem é você?"`
7. Para testar um modelo, use o "Parque Infantil" da página do provedor no OmniRoute.

---

## O que é cada item

| Item | Link | Tipo | O que faz |
|------|------|------|-----------|
| Claude Code Setup | https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup | Plugin oficial | Analisa um projeto e sugere hooks, skills e MCPs |
| Superpowers | https://github.com/obra/superpowers | Plugin | Fluxo de dev: brainstorm → plano → TDD → revisão |
| Claude-Mem | https://github.com/thedotmack/claude-mem | Plugin + serviço | Memória entre sessões (visualizador em localhost:37777) |
| Agent Skills | https://github.com/addyosmani/agent-skills | Plugin | Comandos `/agent-skills:spec`, `:plan`, `:build`, `:review`… |
| Ponytail | https://github.com/DietrichGebert/ponytail | Plugin | Modo "dev sênior preguiçoso": código mínimo (`/ponytail off` desliga) |
| Brag | https://github.com/latent-spaces/brag | Plugin | Gera um vídeo de lançamento do projeto (`/brag`) |
| TasteSkill + Image to Code | https://www.tasteskill.dev · https://github.com/Leonxlnx/taste-skill | Plugin (13 skills) | Design de frontend sem cara de IA |
| Impeccable | https://github.com/pbakaus/impeccable | Plugin | Design: `/impeccable init`, `audit`, `polish`… |
| Ruflo (ruflo-core) | https://github.com/ruvnet/ruflo | Plugin | Enxame de agentes e memória para o Claude Code. **Os hooks rodam `npx ruflo@latest` sem versão fixa**: leia `docs/ruflo-e-vibe-coding-toolkit.md` (ver o guia: versão fixa + variáveis RUFLO_*) |
| Vibe Coding Toolkit | https://github.com/soumatheusgomes/vibe-coding-toolkit | Documentos e prompts | Não é plugin. Clone em `~/.claude/extras/vibe-coding-toolkit`; prompts para preparar a máquina e iniciar/melhorar projetos |
| claude-md-management | https://github.com/anthropics/claude-plugins-official | Plugin | Audita e mantém os `CLAUDE.md` (`/claude-md-management:revise-claude-md`). 1 skill e 1 comando, sem hooks |
| claude-hud | https://github.com/jarrodwatts/claude-hud | Plugin | Barra de status com contexto, limite de uso, ferramentas e agentes. Rode `/hud` uma vez; nunca habilite `--extra-cmd` |
| Codex no Claude Code (codex-plugin-cc) | https://github.com/openai/codex-plugin-cc | Plugin | `/codex:review`, `/codex:rescue`, `/codex:status`, `/codex:result`. Usa o login do Codex que já existe. **Nunca ligue a review gate** |
| context7 | https://github.com/upstash/context7 | MCP remoto | Documentação atual de bibliotecas (2 ferramentas). As perguntas vão para a Upstash. Remover: `claude mcp remove context7` |
| Find Skills | https://github.com/vercel-labs/skills | Skill | Procura e instala outras skills (`npx skills find …`) |
| Web Design Guidelines | https://github.com/vercel-labs/agent-skills/tree/main/skills/web-design-guidelines | Skill | Revisa UI contra as diretrizes da Vercel |
| Task Observer | https://github.com/rebelytics/one-skill-to-rule-them-all | Skill | Observa as sessões e sugere melhorias nas skills |
| apple-look | https://github.com/dickwu/apple-design-skill | Skill | Regras visuais da Apple (Human Interface Guidelines, 123 páginas) para **apps**: espaçamento, tipografia, cor, controles, acessibilidade. Num site, use só como revisão dos fundamentos |
| apple-motion | https://github.com/emilkowalski/skills/tree/main/skills/apple-design | Skill | Regras de movimento da Apple (WWDC "Designing Fluid Interfaces") para a **web**: molas, resposta no toque, animações interrompíveis |
| Playwright CLI | https://github.com/microsoft/playwright-cli | CLI + skill | Automação de navegador que gasta poucos tokens |
| Graphify | https://github.com/Graphify-Labs/graphify | CLI + skill | Transforma uma pasta num grafo de conhecimento (`/graphify .`) |
| Agent Reach | https://github.com/Panniantong/agent-reach | CLI + skill | Lê web, YouTube, GitHub, RSS, Twitter, Reddit… |
| rea | https://github.com/morluto/rea | CLI + MCP + skill | Engenharia reversa de apps e executáveis com agentes |
| Strix | https://github.com/usestrix/strix | CLI | Agente de teste de segurança (precisa de Docker) |
| OmniRoute | https://github.com/diegosouzapw/OmniRoute | CLI + servidor | Roteador de LLMs com fallback automático (porta 20128) |
| FreeLLMAPI | https://github.com/tashfeenahmed/freellmapi | App de bandeja | Junta os planos grátis de vários LLMs num endpoint só (porta 31415) |
| Ollama | https://ollama.com | App de bandeja | Roda modelos no seu PC (porta 11434) |
| Jarvis (OpenJarvis) | https://github.com/open-jarvis/OpenJarvis · guia @marcondes.ai | CLI + voz + interface web | Assistente pessoal local com voz em português e modo "duas palmas" (`jarvis`, `jarvis-show`) |

Plano: `docs/plano-troca-de-conta-gateway.md` (Claude Pro → FreeLLMAPI).

### Listas de referência (não têm o que instalar)

| Lista | Link | Como usar |
|-------|------|-----------|
| Awesome Free LLM APIs | https://github.com/mnfst/awesome-free-llm-apis | Consulta: onde pegar chaves grátis para o OmniRoute e o FreeLLMAPI |
| Public APIs | https://github.com/public-apis/public-apis | Consulta: APIs grátis de clima, filmes, finanças, NASA… |
| Awesome Design MD | https://github.com/VoltAgent/awesome-design-md | Dentro de um projeto: `npx getdesign add linear.app` cria um `DESIGN.md`. Depois diga ao Claude: "leia o DESIGN.md antes de mexer na UI". Ver modelos: `npx getdesign list` |

### Melhorias futuras (anotado, não instalado)

| Item | Link | O que é | Por que ficou para depois |
|------|------|---------|---------------------------|
| colibri | https://github.com/JustVugg/colibri | Roda modelos MoE de ponta no seu próprio hardware, lendo os "especialistas" do modelo direto do disco (motor em C, sem dependências) | Cada modelo ocupa de dezenas a centenas de GB. Vale quando houver um SSD com bastante espaço sobrando |

---

## Avisos importantes

- **Consumo de tokens.** Alguns itens rodam em **toda** sessão. Numa conta com poucos tokens, desligue o que não usar:
  - **Claude-Mem** é o mais pesado: usa o Haiku do seu plano para resumir cada ação. Desligar: `claude plugin disable claude-mem@thedotmack`
  - **Ponytail** muda o estilo de todas as respostas. Desligar na hora: `/ponytail off`. De vez: `claude plugin disable ponytail@ponytail`
  - **Superpowers** é rígido: faz muitas perguntas e exige testes antes do código.
  - **Superpowers** e **Agent Skills** fazem coisas parecidas. Se ficar confuso, desligue um dos dois.
  - **Agent Reach** assume qualquer pesquisa na web.
- **OmniRoute** vem de fábrica aberto para a rede, sem exigir chave e com a senha `CHANGEME`. O script fecha para a rede; trocar a senha é com você (3.2).
- **FreeLLMAPI**: o instalador não tem assinatura digital. O script só instala se o SHA-256 bater com o publicado no GitHub.
- **Impeccable**: no primeiro uso, baixa do GitHub um programa assinado (`impeccable-windows-x64.exe`). Se o antivírus reclamar, é ele.
- **Telemetria**: o script desliga a do Claude-Mem. Para desligar também a do Impeccable e a do `npx skills`, rode uma vez `setx DO_NOT_TRACK 1` (opcional).
- **Nomes de pacote parecidos (cuidado):** **nunca** rode `pip install agent-reach` (é outro projeto) nem `pip install graphify`. O nome certo é `graphifyy`, com dois "y".

## Problemas conhecidos

| Erro | Solução |
|------|---------|
| Ferramenta funciona no Claude mas não no terminal (ou o contrário) | Foi instalada de dentro do app do Claude. Rode o `instalar.ps1` de novo num PowerShell normal |
| O script diz "PARE: este PowerShell esta rodando DENTRO de um app" | Abra o PowerShell pelo Menu Iniciar e rode de lá |
| "uv trampoline failed to canonicalize script path" | O atalho existe, mas a ferramenta não. Reinstale com `--force`, ex.: `uv tool install --force graphifyy` (o script já usa `--force`) |
| `agent-skills`: "Host key verification failed" | O script já resolve, forçando HTTPS só durante a execução. Se instalar à mão, rode antes, na mesma janela: `$env:GIT_CONFIG_COUNT='1'; $env:GIT_CONFIG_KEY_0='url.https://github.com/.insteadOf'; $env:GIT_CONFIG_VALUE_0='git@github.com:'` |
| "npx não pode ser carregado… execução de scripts desabilitada" | Use `npx.cmd` e `npm.cmd` no lugar de `npx` e `npm` |
| uv: "Missing expected target directory for Python minor version link" | Rode o mesmo comando de novo. Se continuar, você está dentro do app do Claude: use um PowerShell normal |
| npm: "install-scripts … Run npm install -g --allow-scripts=…" | Copie e rode o comando que o próprio npm sugeriu |
| OmniRoute: "SECURITY: listening on 0.0.0.0" | Ver 3.2, passo 3 |
| OmniRoute: botão "Importar de /models" cinza | Aperte F5 na página |
| Modelo dá "does not exist" ou erro 410 | A lista está velha: clique em "Importar de /models" |
| Erro 429 / "cooling down" | Limite grátis do provedor. Espere 1 a 2 min ou use outro modelo |
| Jarvis: "requires 3.10 - 3.13" | Use o `instalar.ps1`, que usa um Python 3.13 próprio pelo `uv` |
| Jarvis: erro 401 em `integrate.api.nvidia.com` | Falta a configuração: rode `instalar.ps1` de novo, ou `jarvis _bootstrap --write-config --engine ollama --model gemma4:e4b` |
| Jarvis: `npm install` da interface dá "EBADENGINE … npm <12" | O projeto pede npm 11. Use `npm install --engine-strict=false` (o script já faz) |
| Jarvis: microfone ou voz mudos | Libere o microfone nas Configurações do Windows (Privacidade → Microfone) e confira com `jarvis-show --listar` |
| Jarvis: a palma não pega ou dispara sozinha | Rode `jarvis-show --teste` e ajuste `JARVIS_CLAP_THRESH` (maior = menos sensível) |
| Jarvis: o Kokoro reclama do espeak (raro) | `winget install -e --id eSpeak-NG.eSpeak-NG`, depois `setx PHONEMIZER_ESPEAK_LIBRARY "C:\Program Files\eSpeak NG\libespeak-ng.dll"` e abra um terminal novo |
| Jarvis: o Ollama não responde | Abra o app Ollama (bandeja, ao lado do relógio) ou rode `ollama serve` |
| `rea setup` bloqueado quando o Claude tenta rodar | É proteção do Claude. Rode você mesmo: `rea setup --client claude_code --yes` |
| Comando "não reconhecido" logo depois de instalar | Feche e abra o terminal (o PATH só atualiza em janela nova) |
| `agent-reach doctor` responde em chinês | É só o idioma da saída. Rode antes `$env:AGENT_REACH_LANG='en'` |

## Como remover algo

- Plugin: `claude plugin uninstall nome@marketplace` (ex.: `claude plugin uninstall ponytail@ponytail`)
- Skill avulsa: apague a pasta em `%USERPROFILE%\.claude\skills\<nome>`
- Ferramentas Python: `uv tool uninstall graphifyy` (vale também para `agent-reach`, `strix-agent` e `yt-dlp`)
- Ferramentas npm: `npm uninstall -g @playwright/cli omniroute rea-agents` (para o rea, rode antes `rea uninstall`)
- OmniRoute (dados): apague `%USERPROFILE%\.omniroute`
- FreeLLMAPI e Ollama: Configurações do Windows → Aplicativos → desinstalar. Modelos do Ollama: `ollama rm gpt-oss:20b`
- Jarvis:
  - `jarvis stop`
  - apague `%USERPROFILE%\jarvis` e `%USERPROFILE%\.openjarvis`
  - apague `jarvis.cmd` e `jarvis-show.cmd` de `%USERPROFILE%\.local\bin`
  - modelo: `ollama rm gemma4:e4b`
- Instalação antiga do Jarvis (versão 2 deste guia): apague `%LOCALAPPDATA%\OpenJarvis`. Ela não é mais usada.

## Se precisar de ajuda do Claude na outra máquina

Cole isto numa sessão nova, na pasta deste guia:

> Leia o LEIA-ME.md desta pasta. Eu já rodei o instalar.ps1 num PowerShell normal. Me ajude só com [o passo X da Parte 3 / este erro: …].
> Não reinstale nada que já está funcionando e não peça minhas chaves no chat.
