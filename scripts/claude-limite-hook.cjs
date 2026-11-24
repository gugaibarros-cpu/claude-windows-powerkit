// Hook StopFailure do Claude Code (A TESTAR com um limite real).
// Quando o turno termina por limite/erro de API, grava um arquivo-sinal com o id da sessao e a pasta.
// O wrapper cc.ps1 le o sinal depois que o Claude fecha e oferece continuar pelo FreeLLMAPI.
// Nao envia nada para fora, nao mexe na conta e nao muda o modelo: so escreve em %TEMP%\claude-limite.
const fs = require('fs');
const path = require('path');
const os = require('os');

let raw = '';
process.stdin.on('data', (d) => (raw += d));
process.stdin.on('end', () => {
  try {
    const p = JSON.parse(raw || '{}');
    const dir = path.join(os.tmpdir(), 'claude-limite');
    fs.mkdirSync(dir, { recursive: true });
    // O nome exato do campo do tipo de erro nao esta documentado: guardamos o payload inteiro para conferir.
    const tipo = String(p.error_type || p.error || p.matcher || p.reason || 'desconhecido');
    const sinal = { session_id: p.session_id || '', cwd: p.cwd || process.cwd(), tipo, em: new Date().toISOString() };
    if (!sinal.session_id) return;
    fs.writeFileSync(path.join(dir, `${sinal.session_id}.json`), JSON.stringify(sinal));
    fs.appendFileSync(path.join(dir, 'payloads.log'), JSON.stringify({ em: sinal.em, payload: p }) + '\n');
  } catch { /* hook nunca pode atrapalhar o Claude */ }
});
