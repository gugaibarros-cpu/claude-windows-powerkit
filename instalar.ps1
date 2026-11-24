# =====================================================================
#  instalar.ps1 - Instala os extras do Claude Code (Windows 10/11)
#  Versao 3 - 12/10/2026 (Jarvis com voz, conforme o guia @marcondes.ai)
#
#  COMO USAR - num PowerShell NORMAL (Menu Iniciar > digite "PowerShell"),
#  NAO no terminal de dentro do app do Claude (ele desvia as pastas do
#  AppData e as ferramentas so funcionariam dentro do Claude):
#
#      cd "CAMINHO\DESTA\PASTA"
#      powershell -ExecutionPolicy Bypass -File .\instalar.ps1
#
#  - Pode rodar de novo quantas vezes quiser: o que ja existe e pulado.
#  - Escolha o que instalar nas OPCOES abaixo ($true = instala, $false = pula).
#  - Para pular um plugin/skill avulso, ponha # no inicio da linha dele.
#  - Guia completo: LEIA-ME.md (mesma pasta).
# =====================================================================

# ------------------------------ OPCOES -------------------------------
$INSTALAR_OLLAMA     = $true          # modelo local gratis (precisa placa com ~16 GB de memoria de video)
$MODELO_OLLAMA       = 'gpt-oss:20b'  # ~13 GB. Placa com 8 GB: troque por 'qwen3:8b'
$INSTALAR_FREELLMAPI = $true          # app de bandeja que junta APIs gratis (instalador SEM assinatura digital)
$INSTALAR_OPENJARVIS = $true          # Jarvis: assistente local com voz em portugues (~3 GB + modelo)
$MODELO_JARVIS       = 'gemma4:e4b'   # ~6,6 GB (guia @marcondes.ai). Maquina fraca: 'gemma4:e2b'
$INSTALAR_REA        = $true          # engenharia reversa de apps com agentes
# ---------------------------------------------------------------------

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}   # acentos e simbolos certos na tela
$script:falhas = New-Object System.Collections.ArrayList

# Telemetria desligada para as ferramentas chamadas por este script
$env:DO_NOT_TRACK = '1'
$env:DISABLE_TELEMETRY = '1'
$env:NO_UPDATE_NOTIFIER = '1'
$env:AGENT_REACH_LANG = 'en'
$env:NO_COLOR = '1'
$env:HF_HUB_DISABLE_SYMLINKS_WARNING = '1'

function Passo([string]$t) { Write-Host "`n=== $t" -ForegroundColor Cyan }

function AtualizaPath {
    $env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' +
                [Environment]::GetEnvironmentVariable('PATH','User') + ';' +
                (Join-Path $env:USERPROFILE '.local\bin')
}

function Rodar([string]$nome, [scriptblock]$cmd) {
    Write-Host "-> $nome" -ForegroundColor Yellow
    $global:LASTEXITCODE = 0
    $saida = & $cmd 2>&1 | ForEach-Object { "$_" }
    $codigo = $LASTEXITCODE
    $saida | Select-Object -Last 3 | ForEach-Object { Write-Host "   $_" }
    # -1978335189 = winget "ja instalado / sem atualizacao" (nao e erro)
    if ($codigo -ne 0 -and $codigo -ne -1978335189) {
        [void]$script:falhas.Add($nome)
        Write-Host "   ** FALHOU (codigo $codigo) **" -ForegroundColor Red
    }
}

function InstalaWinget([string]$id, [string]$comando) {
    if ($comando -and (Get-Command $comando -ErrorAction SilentlyContinue)) {
        Write-Host "-> $id (ja instalado)"; return
    }
    Rodar "winget $id" ({ winget install --id $id -e --accept-source-agreements --accept-package-agreements --silent }.GetNewClosure())
}

function InstalaNpm([string]$pacote, [string]$comando) {
    if (Get-Command $comando -ErrorAction SilentlyContinue) { Write-Host "-> $pacote (ja instalado)"; return }
    Rodar "npm $pacote" ({ npm.cmd install -g $pacote }.GetNewClosure())
}

# ---------------------------------------------------------------------
Passo '0. Conferindo o ambiente'
# Trava: dentro do app do Claude, as pastas novas do AppData sao desviadas
# para uma pasta privada do app. Teste: cria uma pasta vazia e procura onde ela foi parar.
$teste = 'zz_instalar_teste_' + (Get-Random)
$pTeste = Join-Path $env:LOCALAPPDATA $teste
New-Item -ItemType Directory -Path $pTeste -ErrorAction SilentlyContinue | Out-Null
$desviado = [bool](Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -ErrorAction SilentlyContinue |
    Where-Object { Test-Path (Join-Path $_.FullName "LocalCache\Local\$teste") })
Remove-Item $pTeste -Force -ErrorAction SilentlyContinue
if ($desviado) {
    Write-Host 'PARE: este PowerShell esta rodando DENTRO de um app (ex.: o app do Claude).' -ForegroundColor Red
    Write-Host 'Abra um PowerShell normal pelo Menu Iniciar e rode este script de novo.'
    exit 1
}
Write-Host '-> PowerShell normal: ok'

Push-Location $env:USERPROFILE   # skills vao para o usuario, nao para a pasta atual
AtualizaPath
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host 'Claude Code nao encontrado. Instale primeiro com:' -ForegroundColor Red
    Write-Host '    irm https://claude.ai/install.ps1 | iex'
    Write-Host 'Depois faca login (rode "claude" uma vez) e rode este script de novo.'
    Pop-Location; exit 1
}
claude --version

# ---------------------------------------------------------------------
Passo '1. Pre-requisitos (winget)'
InstalaWinget 'Git.Git'           'git'      # Claude Code no Windows precisa do Git Bash
InstalaWinget 'OpenJS.NodeJS.LTS' 'node'     # npx skills, Playwright, OmniRoute, rea
InstalaWinget 'astral-sh.uv'      'uv'       # ferramentas Python (Graphify, Agent Reach, Strix, OpenJarvis)
InstalaWinget 'Oven-sh.Bun'       'bun'      # Claude-Mem
InstalaWinget 'Gyan.FFmpeg'       'ffmpeg'   # Brag (videos)
InstalaWinget 'GitHub.cli'        'gh'       # Agent Reach (canal GitHub)
if ($INSTALAR_OLLAMA -or $INSTALAR_OPENJARVIS) { InstalaWinget 'Ollama.Ollama' 'ollama' }
AtualizaPath

# ---------------------------------------------------------------------
Passo '2. Marketplaces de plugins'
# Forca HTTPS no git SO durante este script (sem chave SSH o plugin agent-skills falha)
$env:GIT_CONFIG_COUNT   = '2'
$env:GIT_CONFIG_KEY_0   = 'url.https://github.com/.insteadOf'; $env:GIT_CONFIG_VALUE_0 = 'git@github.com:'
$env:GIT_CONFIG_KEY_1   = 'url.https://github.com/.insteadOf'; $env:GIT_CONFIG_VALUE_1 = 'ssh://git@github.com/'

$marketplaces = @(
    'anthropics/claude-plugins-official'              # oficial: claude-code-setup, superpowers
    'thedotmack/claude-mem'                           # Claude-Mem
    'https://github.com/addyosmani/agent-skills.git'  # Agent Skills (Addy Osmani)
    'DietrichGebert/ponytail'                         # Ponytail
    'latent-spaces/brag'                              # Brag
    'Leonxlnx/taste-skill'                            # TasteSkill + Image to Code
    'pbakaus/impeccable'                              # Impeccable
    'ruvnet/ruflo'                                    # Ruflo (so o ruflo-core; ver docs/ruflo-e-vibe-coding-toolkit.md)
    'jarrodwatts/claude-hud'                          # claude-hud (barra de status; rode /hud depois)
    'openai/codex-plugin-cc'                          # Codex dentro do Claude Code (/codex:*); NUNCA ligue --enable-review-gate
)
foreach ($m in $marketplaces) { Rodar "marketplace $m" ({ claude plugin marketplace add $m }.GetNewClosure()) }

# ---------------------------------------------------------------------
Passo '3. Plugins'
$plugins = @(
    'claude-code-setup@claude-plugins-official'
    'superpowers@claude-plugins-official'
    'claude-mem@thedotmack'
    'agent-skills@addy-agent-skills'
    'ponytail@ponytail'
    'brag@brag'
    'taste-skill@taste-skill'
    'impeccable@impeccable'
    'ruflo-core@ruflo'
    'claude-md-management@claude-plugins-official'
    'claude-hud@claude-hud'
    'codex@openai-codex'
)
foreach ($p in $plugins) { Rodar "plugin $p" ({ claude plugin install $p }.GetNewClosure()) }

# Ruflo: versao FIXA e local (os hooks do plugin sao npx ruflo@latest sem isso) + sem download automatico + sem mensagens promocionais
Rodar 'ruflo 3.59.7 (fixo)' ({ npm install -g ruflo@3.59.7 }.GetNewClosure())
foreach ($kv in @(@('RUFLO_HOOK_SKIP_NPX','1'), @('RUFLO_MCP_SKIP_NPX','1'), @('RUFLO_FUNNEL','0'))) { [Environment]::SetEnvironmentVariable($kv[0], $kv[1], 'User') }

# context7 (MCP remoto, 2 ferramentas; a pergunta e o nome da biblioteca vao para a Upstash; nao rode npx ctx7 setup)
Rodar 'context7 (MCP)' ({ claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp }.GetNewClosure())


# Vibe Coding Toolkit: so documentos e prompts (nao e plugin); fica em ~/.claude/extras para consulta
$vct = Join-Path $env:USERPROFILE '.claude\extras\vibe-coding-toolkit'
if (-not (Test-Path $vct)) { New-Item -ItemType Directory -Force (Split-Path $vct) | Out-Null; Rodar 'vibe-coding-toolkit' ({ git clone --depth 1 https://github.com/soumatheusgomes/vibe-coding-toolkit $vct }.GetNewClosure()) }

# Claude-Mem: desliga a telemetria (PostHog) antes da 1a sessao
$cm = Join-Path $env:USERPROFILE '.claude-mem'
New-Item -ItemType Directory -Force $cm | Out-Null
# Formato que o Claude-Mem aceita: sem installId ele descarta o arquivo e volta a telemetria ligada
$tf = Join-Path $cm 'telemetry.json'
$iid = [guid]::NewGuid().ToString()
try { $velhoTel = Get-Content $tf -Raw -ErrorAction Stop | ConvertFrom-Json; if ($velhoTel.installId) { $iid = $velhoTel.installId } } catch {}
[IO.File]::WriteAllText($tf, ([ordered]@{ installId = $iid; enabled = $false; decidedAt = (Get-Date).ToUniversalTime().ToString('o') } | ConvertTo-Json))
Write-Host '-> Claude-Mem: telemetria desligada'

# ---------------------------------------------------------------------
Passo '4. Skills avulsas (npx skills)'
Rodar 'Find Skills'           { npx.cmd -y skills add vercel-labs/skills --skill find-skills -g -a claude-code -y --copy }
Rodar 'Web Design Guidelines' { npx.cmd -y skills add vercel-labs/agent-skills --skill web-design-guidelines -g -a claude-code -y --copy }
Rodar 'Task Observer'         { npx.cmd -y skills add rebelytics/one-skill-to-rule-them-all --skill task-observer -g -a claude-code -y --copy }

# Skills de design da Apple. Os dois repositorios usam o mesmo nome (apple-design),
# entao aqui viram apple-look (HIG, para apps) e apple-motion (WWDC, movimento na web).
$skDir = Join-Path $env:USERPROFILE '.claude\skills'
$tmpA = Join-Path $env:TEMP ('apple-skills-' + (Get-Random))
Rodar 'Apple look (baixar)'   ({ git clone --depth 1 https://github.com/dickwu/apple-design-skill.git (Join-Path $tmpA 'look') }.GetNewClosure())
Rodar 'Apple motion (baixar)' ({ git clone --depth 1 https://github.com/emilkowalski/skills.git (Join-Path $tmpA 'emil') }.GetNewClosure())
foreach ($par in @(@('look', 'apple-look'), @('emil\skills\apple-design', 'apple-motion'))) {
    $de = Join-Path $tmpA $par[0]
    $para = Join-Path $skDir $par[1]
    if (Test-Path (Join-Path $de 'SKILL.md')) {
        New-Item -ItemType Directory -Force $para | Out-Null
        Get-ChildItem $de -Force | Where-Object { $_.Name -notin '.git', '.github' } | Copy-Item -Destination $para -Recurse -Force
        $sf = Join-Path $para 'SKILL.md'
        [IO.File]::WriteAllText($sf, ([IO.File]::ReadAllText($sf) -replace '(?m)^name:\s*apple-design\s*$', "name: $($par[1])"))
        Write-Host "-> skill $($par[1]) instalada"
    } else {
        [void]$script:falhas.Add($par[1])
    }
}
Remove-Item $tmpA -Recurse -Force -ErrorAction SilentlyContinue

# ---------------------------------------------------------------------
Passo '5. Ferramentas de linha de comando'
InstalaNpm '@playwright/cli@latest' 'playwright-cli'
AtualizaPath
Rodar 'Playwright CLI (skill)'  { playwright-cli install --skills --global }

# --force: refaz a instalacao mesmo se o atalho ja existir (ex.: criado de dentro do app do Claude)
Rodar 'uv: PATH'                { uv tool update-shell }
Rodar 'Graphify'                { uv tool install --force graphifyy }      # graphifyy com DOIS y
AtualizaPath
Rodar 'Graphify (skill)'        { graphify install }

Rodar 'yt-dlp'                  { uv tool install --force 'yt-dlp[default]' }
$yc = Join-Path $env:USERPROFILE '.config\yt-dlp'
New-Item -ItemType Directory -Force $yc | Out-Null
$ycf = Join-Path $yc 'config'
if (-not (Test-Path $ycf)) { [IO.File]::WriteAllText($ycf, "--js-runtimes node`n") }
elseif (-not (Select-String -Path $ycf -Pattern 'js-runtimes' -Quiet)) { [IO.File]::AppendAllText($ycf, "`n--js-runtimes node`n") }

# Agent Reach: SEMPRE do GitHub (o "agent-reach" do PyPI e de outro autor)
Rodar 'Agent Reach'             { uv tool install --force 'git+https://github.com/Panniantong/Agent-Reach' }
AtualizaPath
Rodar 'Agent Reach (setup)'     { agent-reach install --env=auto --system }

# Strix: precisa de Python 3.12+ (o uv baixa sozinho)
uv python install 3.12 2>&1 | Out-Null
Rodar 'Strix'                   { uv tool install --force strix-agent --python 3.12 }

# OmniRoute: o npm 12+ bloqueia scripts de instalacao; esta lista libera SO estes pacotes.
# Se o npm avisar de outro pacote bloqueado, rode de novo com o nome dele incluido.
if (-not (Get-Command omniroute -ErrorAction SilentlyContinue)) {
    Rodar 'OmniRoute' { npm.cmd install -g omniroute '--allow-scripts=omniroute,keytar,onnxruntime-node,@parcel/watcher,@swc/core,protobufjs,esbuild' }
} else { Write-Host '-> OmniRoute (ja instalado)' }
# Seguranca: por padrao o OmniRoute abre para a rede inteira (0.0.0.0) sem exigir chave.
# Esta linha faz ele aceitar so conexoes deste computador.
$od = Join-Path $env:USERPROFILE '.omniroute'
New-Item -ItemType Directory -Force $od | Out-Null
$oenv = Join-Path $od '.env'
if (-not (Test-Path $oenv)) { [IO.File]::WriteAllText($oenv, "OMNIROUTE_SERVER_HOST=127.0.0.1`n") }
elseif (-not (Select-String -Path $oenv -Pattern '^OMNIROUTE_SERVER_HOST=' -Quiet)) { [IO.File]::AppendAllText($oenv, "`nOMNIROUTE_SERVER_HOST=127.0.0.1`n") }
Write-Host '-> OmniRoute: so aceita conexoes locais (127.0.0.1)'

if ($INSTALAR_REA) {
    InstalaNpm 'rea-agents' 'rea'
    AtualizaPath
    Rodar 'rea: registrar no Claude Code' { rea setup --client claude_code --yes }
}

# ---------------------------------------------------------------------
if ($INSTALAR_OLLAMA -or $INSTALAR_OPENJARVIS) {
    Passo '6. Ollama (modelos locais)'
    AtualizaPath
    $ollamaOk = $false
    try { Invoke-RestMethod http://127.0.0.1:11434/api/version -TimeoutSec 3 | Out-Null; $ollamaOk = $true } catch {}
    if (-not $ollamaOk) {
        $app = Join-Path $env:LOCALAPPDATA 'Programs\Ollama\ollama app.exe'
        if (Test-Path $app) { Start-Process -FilePath $app }
        for ($i = 0; $i -lt 60 -and -not $ollamaOk; $i++) {
            Start-Sleep -Seconds 1
            try { Invoke-RestMethod http://127.0.0.1:11434/api/version -TimeoutSec 2 | Out-Null; $ollamaOk = $true } catch {}
        }
    }
    if ($ollamaOk) {
        Write-Host '-> Ollama rodando (so aceita conexoes deste PC)'
        if ($INSTALAR_OLLAMA)     { Rodar "Ollama: baixar $MODELO_OLLAMA (pode demorar)" { ollama pull $MODELO_OLLAMA } }
        if ($INSTALAR_OPENJARVIS) { Rodar "Ollama: baixar $MODELO_JARVIS (pode demorar)" { ollama pull $MODELO_JARVIS } }
    } else {
        [void]$script:falhas.Add('Ollama nao iniciou')
        Write-Host '   ** Ollama nao respondeu. Abra o app "Ollama" e rode o script de novo. **' -ForegroundColor Red
    }
}

# ---------------------------------------------------------------------
if ($INSTALAR_FREELLMAPI) {
    Passo '7. FreeLLMAPI (app de bandeja)'
    $flExe = Join-Path $env:LOCALAPPDATA 'Programs\freellmapi-desktop\FreeLLMAPI.exe'
    if (Test-Path $flExe) {
        Write-Host '-> FreeLLMAPI (ja instalado)'
    } else {
        try {
            $rel = Invoke-RestMethod 'https://api.github.com/repos/tashfeenahmed/freellmapi/releases/latest' -Headers @{ 'User-Agent' = 'instalar.ps1' }
            $a = $rel.assets | Where-Object { $_.name -match '^FreeLLMAPI-Setup-.*\.exe$' } | Select-Object -First 1
            $dl = Join-Path $env:TEMP $a.name
            Write-Host "-> baixando $($a.name) ($([math]::Round($a.size/1MB)) MB) do GitHub oficial"
            Invoke-WebRequest $a.browser_download_url -OutFile $dl -UseBasicParsing
            $h = 'sha256:' + (Get-FileHash $dl -Algorithm SHA256).Hash.ToLower()
            if ($a.digest -and $h -ne $a.digest) {
                Remove-Item $dl -Force
                [void]$script:falhas.Add('FreeLLMAPI: SHA-256 nao confere')
                Write-Host '   ** SHA-256 NAO confere com o GitHub. Arquivo apagado, nada foi instalado. **' -ForegroundColor Red
            } else {
                Write-Host '-> SHA-256 confere com o GitHub. Instalando...'
                Start-Process -FilePath $dl -ArgumentList '/S' -Wait
                Remove-Item $dl -Force -ErrorAction SilentlyContinue
                if (Test-Path $flExe) { Start-Process -FilePath $flExe; Write-Host '-> FreeLLMAPI instalado e aberto (icone na bandeja)' }
                else { [void]$script:falhas.Add('FreeLLMAPI') }
            }
        } catch {
            [void]$script:falhas.Add('FreeLLMAPI')
            Write-Host "   ** FALHOU: $($_.Exception.Message) **" -ForegroundColor Red
        }
    }
}

# ---------------------------------------------------------------------
if ($INSTALAR_OPENJARVIS) {
    Passo '8. Jarvis (OpenJarvis com voz em portugues - guia @marcondes.ai)'
    # Fica em %USERPROFILE%\jarvis (fora do AppData). Exige Python 3.10-3.13: o uv usa um 3.13 proprio.
    $jd = Join-Path $env:USERPROFILE 'jarvis'
    if (-not (Test-Path (Join-Path $jd '.git'))) {
        Rodar 'Jarvis: baixar' ({ git clone --filter=blob:none https://github.com/open-jarvis/OpenJarvis.git $jd }.GetNewClosure())
    } else {
        Rodar 'Jarvis: atualizar' ({ git -C $jd pull --ff-only }.GetNewClosure())
    }
    uv python install 3.13 2>&1 | Out-Null
    Push-Location $jd
    # desktop = servidor + ouvidos (faster-whisper); voice = boca (Kokoro) e microfone
    Rodar 'Jarvis: dependencias + voz (demora)' { uv sync --python 3.13 --extra desktop --extra voice }
    Pop-Location
    $jx = Join-Path $jd '.venv\Scripts\jarvis.exe'
    if (-not (Test-Path (Join-Path $env:USERPROFILE '.openjarvis\config.toml'))) {
        Rodar 'Jarvis: configurar' ({ & $jx _bootstrap --write-config --engine ollama --model $MODELO_JARVIS }.GetNewClosure())
    }
    Rodar "Jarvis: modelo $MODELO_JARVIS" ({ & $jx config set intelligence.default_model $MODELO_JARVIS }.GetNewClosure())
    Rodar 'Jarvis: perfil de seguranca'   ({ & $jx config set security.profile personal }.GetNewClosure())
    Rodar 'Jarvis: voz pf_dora (pt-BR)'   ({ & $jx config set speech.voice_id pf_dora }.GetNewClosure())
    Rodar 'Jarvis: ouvir em portugues'    ({ & $jx config set speech.language pt }.GetNewClosure())
    # Interface web: o projeto pede npm 11; com o npm 12 basta ignorar a checagem de versao
    Push-Location (Join-Path $jd 'frontend')
    Rodar 'Jarvis: interface web (instalar)' { npm.cmd install --engine-strict=false }
    Rodar 'Jarvis: interface web (compilar)' { npm.cmd run build }
    Pop-Location
    # Modo show (2 palmas): arquivo que vem nesta pasta de instalacao
    Copy-Item (Join-Path $PSScriptRoot 'jarvis\jarvis_show.py') $jd -Force
    New-Item -ItemType Directory -Force (Join-Path $jd 'voz\assets') | Out-Null
    # Comandos para usar de qualquer pasta
    $lb = Join-Path $env:USERPROFILE '.local\bin'
    New-Item -ItemType Directory -Force $lb | Out-Null
    [IO.File]::WriteAllText((Join-Path $lb 'jarvis.cmd'), "@echo off`r`n`"%USERPROFILE%\jarvis\.venv\Scripts\jarvis.exe`" %*`r`n")
    [IO.File]::WriteAllText((Join-Path $lb 'jarvis-show.cmd'), "@echo off`r`n`"%USERPROFILE%\jarvis\.venv\Scripts\python.exe`" `"%USERPROFILE%\jarvis\jarvis_show.py`" %*`r`n")
    Write-Host '-> comandos: jarvis, jarvis-show'
    # Versao anterior deste script instalava em %LOCALAPPDATA%\OpenJarvis: tira do PATH
    $velho = Join-Path $env:LOCALAPPDATA 'OpenJarvis\bin'
    $up = [Environment]::GetEnvironmentVariable('Path', 'User')
    $novo = (($up -split ';') | Where-Object { $_ -and ([Environment]::ExpandEnvironmentVariables($_) -ine $velho) }) -join ';'
    if ($novo -ne $up) { [Environment]::SetEnvironmentVariable('Path', $novo, 'User'); Write-Host "-> PATH: tirada a instalacao antiga ($velho)" }
    if (Test-Path (Join-Path $env:LOCALAPPDATA 'OpenJarvis')) {
        Write-Host "   A pasta antiga $env:LOCALAPPDATA\OpenJarvis nao e mais usada e pode ser apagada (~600 MB)." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------
Passo 'Resumo'
AtualizaPath
claude plugin list
Write-Host ''
$cmds = @('playwright-cli', 'graphify', 'agent-reach', 'yt-dlp', 'strix', 'omniroute')
if ($INSTALAR_REA) { $cmds += 'rea' }
if ($INSTALAR_OLLAMA -or $INSTALAR_OPENJARVIS) { $cmds += 'ollama' }
if ($INSTALAR_OPENJARVIS) { $cmds += 'jarvis'; $cmds += 'jarvis-show' }
foreach ($c in $cmds) {
    $ok = [bool](Get-Command $c -ErrorAction SilentlyContinue)
    Write-Host ("{0,-15} {1}" -f $c, $(if ($ok) { 'OK' } else { 'FALTANDO' })) -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
}
if ($INSTALAR_FREELLMAPI) {
    $ok = Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\freellmapi-desktop\FreeLLMAPI.exe')
    Write-Host ("{0,-15} {1}" -f 'FreeLLMAPI', $(if ($ok) { 'OK' } else { 'FALTANDO' })) -ForegroundColor $(if ($ok) { 'Green' } else { 'Red' })
}
Write-Host ''
if ($script:falhas.Count) {
    Write-Host "Itens com falha: $($script:falhas -join ', ')" -ForegroundColor Red
    Write-Host 'Rode o script de novo. Se continuar, veja "Problemas conhecidos" no LEIA-ME.md.'
} else {
    Write-Host 'Tudo instalado.' -ForegroundColor Green
}
Write-Host 'AGORA: feche e abra o Claude e o terminal. Depois faca a Parte 3 do LEIA-ME.md (chaves e logins).'
Pop-Location
if (-not $env:CLAUDECODE) { Read-Host 'Enter para fechar' | Out-Null }
