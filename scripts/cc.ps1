# cc.ps1  (A TESTAR)  Use "cc" no lugar de "claude".
# Abre o Claude normal (conta Pro). Se a sessao terminar por limite, oferece continuar a MESMA sessao pelo FreeLLMAPI.
# Depende do hook StopFailure (scripts/claude-limite-hook.cjs) registrado em ~/.claude/settings.json (ver docs/plano-troca-de-conta-gateway.md).
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args2)

$sinais = Join-Path ([IO.Path]::GetTempPath()) 'claude-limite'
$inicio = Get-Date
& claude @Args2

if (-not (Test-Path $sinais)) { return }
$cwd = (Get-Location).Path
$s = Get-ChildItem $sinais -Filter '*.json' -ErrorAction SilentlyContinue |
     Where-Object { $_.LastWriteTime -ge $inicio } | Sort-Object LastWriteTime -Descending |
     ForEach-Object { Get-Content $_ -Raw | ConvertFrom-Json } |
     Where-Object { [IO.Path]::GetFullPath($_.cwd).TrimEnd([char]92) -ieq [IO.Path]::GetFullPath($cwd).TrimEnd([char]92) } | Select-Object -First 1
if (-not $s) { return }

Write-Host "O Claude parou por limite ($($s.tipo)) na sessao $($s.session_id)." -ForegroundColor Yellow
$r = Read-Host 'Continuar a mesma sessao pelo FreeLLMAPI? (S/n)'
if ($r -match '^(n|N)') { return }
Remove-Item (Join-Path $sinais "$($s.session_id).json") -ErrorAction SilentlyContinue
& (Join-Path $PSScriptRoot 'claude-free.ps1') -Sessao $s.session_id
