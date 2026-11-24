# claude-free.ps1  (A TESTAR: escrito em 21/10/2026, ainda nao rodou com o FreeLLMAPI)
# Abre o Claude Code usando o FreeLLMAPI no lugar da conta Pro, so neste processo.
# A sessao anterior continua do mesmo ponto (o historico fica em %USERPROFILE%\.claude\projects).
#
# Uso, na pasta do projeto:
#   .\claude-free.ps1                  -> retoma a sessao mais recente deste projeto (--continue)
#   .\claude-free.ps1 -Sessao <id>     -> retoma uma sessao especifica (--resume <id>)
#   .\claude-free.ps1 -Nova            -> sessao nova
#   .\claude-free.ps1 -Modelo auto:coding
# Pre-requisito: variavel de usuario FREELLMAPI_API_KEY com a "unified key" (comeca com freellmapi-).
#   [Environment]::SetEnvironmentVariable('FREELLMAPI_API_KEY','freellmapi-...','User')   # uma vez, fora do chat
param(
    [string]$Sessao = '',
    [switch]$Nova,
    [string]$Modelo = 'auto',
    [string]$Url = 'http://localhost:31415'
)
$ErrorActionPreference = 'Stop'

if (-not $env:FREELLMAPI_API_KEY) { throw 'Defina FREELLMAPI_API_KEY (unified key do FreeLLMAPI). Veja docs/plano-troca-de-conta-gateway.md' }
try { $null = Invoke-WebRequest "$Url/v1/models" -Headers @{ Authorization = "Bearer $($env:FREELLMAPI_API_KEY)" } -UseBasicParsing -TimeoutSec 5 }
catch { throw "FreeLLMAPI nao respondeu em $Url. Abra o app pelo icone da bandeja e tente de novo." }

# HISTORICO: as sessoes ficam na pasta de configuracao do Claude (CLAUDE_CONFIG_DIR, padrao %USERPROFILE%\.claude).
# O 'freellmapi launch --profile X' usa OUTRA pasta (~\.claude\profiles\X), e por isso a conversa 'some'.
# Este script NUNCA troca de pasta: se CLAUDE_CONFIG_DIR estiver definida, avisa e para.
if ($env:CLAUDE_CONFIG_DIR) { throw "CLAUDE_CONFIG_DIR esta definida ($($env:CLAUDE_CONFIG_DIR)). Isso abriria outro historico. Limpe a variavel ou rode no terminal onde o claude normal usa a mesma pasta." }
$pasta = Join-Path $env:USERPROFILE '.claude\projects'
if (-not (Test-Path $pasta)) { throw "Nao achei ${pasta}: sem historico para continuar." }

# So para este processo: nao mexe nas variaveis do usuario nem na sua conta.
$env:ANTHROPIC_BASE_URL   = $Url
$env:ANTHROPIC_AUTH_TOKEN = $env:FREELLMAPI_API_KEY
$env:ANTHROPIC_MODEL      = $Modelo
$env:ANTHROPIC_SMALL_FAST_MODEL = $Modelo
Remove-Item Env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue

Write-Host "Claude Code via FreeLLMAPI ($Url, modelo '$Modelo'). Modelos gratis erram mais em ferramentas; o contexto deles e menor." -ForegroundColor Yellow
Write-Host 'Dica: rode /compact antes de pedir coisa grande se a sessao for longa.' -ForegroundColor DarkYellow

if ($Nova)        { claude }
elseif ($Sessao)  { claude --resume $Sessao }
else              { claude --continue }
