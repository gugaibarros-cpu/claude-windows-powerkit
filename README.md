# setup-extras-claude

Instalação dos extras do Claude Code no Windows: plugins, skills, ferramentas de linha de comando,
roteadores de LLM grátis (OmniRoute, FreeLLMAPI), modelos locais (Ollama) e o Jarvis com voz em português.

**Comece pelo [LEIA-ME.md](LEIA-ME.md).** Resumo:

1. Baixe esta pasta (**Code → Download ZIP**, ou `gh repo clone gugaibarros-cpu/setup-extras-claude`).
   O repositório é público, sem chaves nem senhas.
2. Num **PowerShell normal** (Menu Iniciar, não o terminal de dentro do app do Claude):
   ```
   powershell -ExecutionPolicy Bypass -File .\instalar.ps1
   ```
3. Confira: `powershell -ExecutionPolicy Bypass -File .\verificar.ps1`
4. Faça os passos manuais da Parte 3 do LEIA-ME (logins e chaves).

| Arquivo | O que é |
|---------|---------|
| `LEIA-ME.md` | Guia completo, com os serviços de LLM grátis e pagos e a solução dos problemas conhecidos |
| `instalar.ps1` | Instala quase tudo; pode rodar de novo quantas vezes quiser |
| `verificar.ps1` | Confere o que está instalado, sem mexer em nada |
| `jarvis/jarvis_show.py` | Modo "duas palmas" do Jarvis |
| `docs/ruflo-e-vibe-coding-toolkit.md` | Os dois extras de 21/10: o que são, o risco dos hooks do Ruflo e como reduzi-lo |
| `docs/avaliacao-lista-40-ferramentas.md` | Avaliação de 40 ferramentas (03/11): o que foi aplicado, o que fica para depois e o que foi descartado, com os motivos |
| `docs/claude-desktop-com-chave-api.md` | Guia: usar a chave de API da Anthropic no app Claude Desktop quando o limite acaba, por gateway local (a testar) |
| `docs/plano-troca-de-conta-gateway.md` | Plano: do Claude Pro para o FreeLLMAPI quando os créditos acabarem, mantendo as sessões |
| `scripts/claude-free.ps1` | Abre o Claude Code pelo FreeLLMAPI e retoma a sessão (a testar) |
| `scripts/cc.ps1` + `scripts/claude-limite-hook.cjs` | `cc` no lugar de `claude`: se parar por limite, continua a mesma sessão pelo FreeLLMAPI (a testar) |

Nenhuma chave de API ou senha fica neste repositório. Elas são colocadas à mão em cada máquina.
