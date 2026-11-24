# claude-api.ps1  (A TESTAR: escrito em 03/11/2026)
# Abre o Claude Code usando uma chave de API da Anthropic (cobranca por uso) no lugar da assinatura, so neste processo,
# e retoma a mesma sessao. Serve para continuar trabalhando quando o limite do plano acaba.
#
# Uso:
#   claude-api                      -> na pasta atual: claude --continue (sessao mais recente)
#   claude-api -Sessao <id>         -> retoma uma sessao especifica
#   claude-api -Nova                -> sessao nova
#   claude-api -Modelo opus         -> escolhe o modelo (padrao sonnet: custa bem menos por token)
#   claude-api -DryRun              -> mostra o que faria, sem abrir o Claude
# Pre-requisito: variavel de USUARIO ANTHROPIC_API_KEY_RESERVA com a chave (console.anthropic.com). O nome e diferente de
# ANTHROPIC_API_KEY de proposito: assim nenhuma outra sessao usa a chave sem voce pedir. Grave uma vez, fora do chat:
#   [Environment]::SetEnvironmentVariable('ANTHROPIC_API_KEY_RESERVA','sk-ant-...','User')   (e reabra o terminal)
# Defina um LIMITE DE GASTO mensal no console da Anthropic antes de usar.
param(
    [string]$Sessao = '',
    [switch]$Nova,
    [string]$Modelo = 'sonnet',
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

$chave = $env:ANTHROPIC_API_KEY_RESERVA
if (-not $chave) { throw 'Defina a variavel de usuario ANTHROPIC_API_KEY_RESERVA (chave da Anthropic). Veja o cabecalho deste script e docs/claude-desktop-com-chave-api.md' }
if ($chave -notmatch '^sk-ant-') { throw 'ANTHROPIC_API_KEY_RESERVA nao parece uma chave da Anthropic (deve comecar com sk-ant-).' }

# HISTORICO: nunca troca a pasta de configuracao do Claude (CLAUDE_CONFIG_DIR): as sessoes ficam la.
if ($env:CLAUDE_CONFIG_DIR) { throw "CLAUDE_CONFIG_DIR esta definida ($($env:CLAUDE_CONFIG_DIR)). Isso abriria outro historico. Limpe a variavel neste terminal." }
$pasta = Join-Path $env:USERPROFILE '.claude\projects'
if (-not (Test-Path $pasta)) { throw "Nao achei ${pasta}: sem historico para continuar." }

# So neste processo: nao mexe nas variaveis do usuario, no settings.json nem na assinatura. Outros gateways/tokens saem do caminho.
$env:ANTHROPIC_API_KEY = $chave
Remove-Item Env:ANTHROPIC_AUTH_TOKEN, Env:ANTHROPIC_BASE_URL, Env:ANTHROPIC_MODEL, Env:ANTHROPIC_SMALL_FAST_MODEL -ErrorAction SilentlyContinue

$args2 = @('--model', $Modelo)
if ($Nova) { } elseif ($Sessao) { $args2 += @('--resume', $Sessao) } else { $args2 += '--continue' }

Write-Host "Claude Code com chave de API (cobranca por uso), modelo '$Modelo', pasta: $((Get-Location).Path)" -ForegroundColor Yellow
Write-Host 'Na 1a vez ele pergunta se aceita usar a chave: responda Sim. Confira com /status. Para voltar a assinatura, feche este terminal.' -ForegroundColor DarkYellow
if ($DryRun) { Write-Host "[DryRun] claude $($args2 -join ' ')"; return }
& claude @args2
