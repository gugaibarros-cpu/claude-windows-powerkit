# =====================================================================
#  verificar.ps1 - Confere se os extras do Claude Code estao instalados
#  Rode num PowerShell NORMAL (Menu Iniciar), nao dentro do app do Claude:
#      powershell -ExecutionPolicy Bypass -File .\verificar.ps1
#  Nao instala nem altera nada. Tire um print do resultado se algo der FALTA.
# =====================================================================

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}
$env:NO_COLOR = '1'
$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')
$script:ok = 0; $script:falta = 0

function Linha([string]$nome, [bool]$passou, [string]$detalhe = '') {
    if ($passou) { $script:ok++ } else { $script:falta++ }
    Write-Host ("{0,-28} {1,-5} {2}" -f $nome, $(if ($passou) { 'OK' } else { 'FALTA' }), $detalhe) -ForegroundColor $(if ($passou) { 'Green' } else { 'Red' })
}
function Versao([string]$cmd, [string[]]$arg = @('--version')) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { return $null }
    $global:LASTEXITCODE = 0
    $v = (& $cmd @arg 2>&1 | ForEach-Object { "$_" } | Where-Object { $_ -match '\d' } | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -and -not $v) { return $null }
    if ($v) { return $v.Trim() } else { return 'ok' }
}

# Dentro do app do Claude o resultado engana (pastas do AppData desviadas)
$teste = 'zz_verificar_' + (Get-Random); $p = Join-Path $env:LOCALAPPDATA $teste
New-Item -ItemType Directory -Path $p -ErrorAction SilentlyContinue | Out-Null
$desviado = [bool](Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -ErrorAction SilentlyContinue | Where-Object { Test-Path (Join-Path $_.FullName "LocalCache\Local\$teste") })
Remove-Item $p -Force -ErrorAction SilentlyContinue
if ($desviado) { Write-Host 'ATENCAO: rodando DENTRO de um app. Abra um PowerShell normal para um resultado confiavel.' -ForegroundColor Yellow }

Write-Host "`n=== Ferramentas" -ForegroundColor Cyan
foreach ($c in 'claude','git','node','uv','bun','ffmpeg','gh','playwright-cli','graphify','agent-reach','yt-dlp','strix','omniroute','rea','ollama','jarvis') {
    $a = if ($c -eq 'ffmpeg') { @('-version') } else { @('--version') }
    $v = Versao $c $a
    Linha $c ([bool]$v) $(if ($v) { $v.Substring(0, [Math]::Min(60, $v.Length)) } else { 'comando nao encontrado' })
}
Linha 'jarvis-show' ([bool](Get-Command jarvis-show -ErrorAction SilentlyContinue))

Write-Host "`n=== Claude Code" -ForegroundColor Cyan
$pl = (claude plugin list 2>&1 | ForEach-Object { "$_" } | Select-String 'enabled').Count
Linha 'plugins ativos (esperado 15)' ($pl -ge 15) "$pl ativos"
foreach ($n in 'ruflo-core','claude-hud','claude-md-management','codex@openai-codex') {
    Linha "plugin $n" ([bool](claude plugin list 2>&1 | ForEach-Object { "$_" } | Select-String ([regex]::Escape($n))))
}
$c7 = claude mcp list 2>&1 | ForEach-Object { "$_" } | Select-String '^context7:'
Linha 'context7 registrado (MCP)' ([bool]($c7 -match 'Connected')) $(if ($c7) { 'conectado' } else { 'rode: claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp' })
$mcp = claude mcp list 2>&1 | ForEach-Object { "$_" } | Select-String '^rea:'
Linha 'rea registrado (MCP)' ([bool]($mcp -match 'Connected')) $(if ($mcp) { 'conectado' } else { 'rode: rea setup --client claude_code --yes' })
$sk = Join-Path $env:USERPROFILE '.claude\skills'
foreach ($s in 'find-skills','web-design-guidelines','task-observer','playwright-cli','graphify','agent-reach','reverse-engineer-anything','apple-look','apple-motion') {
    Linha "skill $s" (Test-Path (Join-Path $sk "$s\SKILL.md"))
}
$tel = Join-Path $env:USERPROFILE '.claude-mem\telemetry.json'
Linha 'Claude-Mem sem telemetria' ((Test-Path $tel) -and ((Get-Content $tel -Raw) -match '"enabled"\s*:\s*false') -and ((Get-Content $tel -Raw) -match '"installId"'))

Write-Host "`n=== Servicos de LLM" -ForegroundColor Cyan
$oenv = Join-Path $env:USERPROFILE '.omniroute\.env'
Linha 'OmniRoute fechado p/ rede' ((Test-Path $oenv) -and (Select-String -Path $oenv -Pattern '^OMNIROUTE_SERVER_HOST=127\.0\.0\.1' -Quiet))
Linha 'FreeLLMAPI instalado' (Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\freellmapi-desktop\FreeLLMAPI.exe'))
$om = $false; try { Invoke-RestMethod http://127.0.0.1:11434/api/version -TimeoutSec 3 | Out-Null; $om = $true } catch {}
Linha 'Ollama respondendo' $om $(if (-not $om) { 'abra o app Ollama (bandeja)' } else { '' })
if ($om) {
    $mods = (Invoke-RestMethod http://127.0.0.1:11434/api/tags -TimeoutSec 5).models.name
    Linha 'modelos locais' ([bool]$mods) ($mods -join ', ')
}

Write-Host "`n=== Jarvis (OpenJarvis)" -ForegroundColor Cyan
$jd = Join-Path $env:USERPROFILE 'jarvis'
Linha 'pasta jarvis' (Test-Path (Join-Path $jd '.venv\Scripts\jarvis.exe')) $jd
Linha 'jarvis_show.py' (Test-Path (Join-Path $jd 'jarvis_show.py'))
$cfg = Join-Path $env:USERPROFILE '.openjarvis\config.toml'
if (Test-Path $cfg) {
    $t = Get-Content $cfg -Raw
    Linha 'modelo do Jarvis' ($t -match 'default_model\s*=') ([regex]::Match($t, 'default_model\s*=\s*"([^"]+)"').Groups[1].Value)
    Linha 'voz pt-BR (pf_dora)' ($t -match 'voice_id\s*=\s*"pf_dora"')
    Linha 'perfil de seguranca' ($t -match 'profile\s*=\s*"personal"')
} else { Linha 'config do Jarvis' $false 'rode o instalar.ps1' }
Linha 'interface web compilada' (Test-Path (Join-Path $jd 'src\openjarvis\server\static\index.html'))

Write-Host "`n=== Contas" -ForegroundColor Cyan
$gh = gh auth status 2>&1 | ForEach-Object { "$_" } | Select-String 'Logged in'
Linha 'GitHub (gh auth login)' ([bool]$gh)

Write-Host ''
Write-Host "Resultado: $script:ok OK, $script:falta FALTA" -ForegroundColor $(if ($script:falta) { 'Yellow' } else { 'Green' })
if (-not $env:CLAUDECODE) { Read-Host 'Enter para fechar' | Out-Null }
