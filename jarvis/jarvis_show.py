"""jarvis-show: bata duas palmas para abrir o Jarvis por voz.

Uso:
  jarvis-show            escuta o microfone; 2 palmas -> jingle, interface web e conversa por voz
  jarvis-show --listar   lista os microfones
  jarvis-show --teste    mostra o volume ao vivo, para ajustar a sensibilidade

Variaveis (no cmd: set VAR=valor | no PowerShell: $env:VAR="valor"):
  JARVIS_CLAP_THRESH  pico minimo da palma, de 0 a 1 (padrao 0.30). Subir = menos sensivel.
  JARVIS_MIC          numero ou parte do nome do microfone (padrao: o do Windows)
  JARVIS_SEM_WEB=1    nao abre a interface web
"""

import os
import subprocess
import sys
import time
import urllib.request
import webbrowser
from collections import deque
from pathlib import Path

import numpy as np
import sounddevice as sd

BASE = Path(__file__).resolve().parent
JARVIS = BASE / ".venv" / ("Scripts/jarvis.exe" if os.name == "nt" else "bin/jarvis")
TAXA = 16000
BLOCO = 512                      # 32 ms por leitura
LIMIAR = float(os.environ.get("JARVIS_CLAP_THRESH", "0.30"))
INTERVALO = (0.15, 0.9)          # tempo entre a 1a e a 2a palma, em segundos
MESMA_PALMA = 0.12               # leituras mais proximas que isso sao o mesmo estalo
WEB = "http://127.0.0.1:8000"


def escolher_mic():
    valor = os.environ.get("JARVIS_MIC", "").strip()
    if not valor:
        return None
    if valor.isdigit():
        return int(valor)
    for i, d in enumerate(sd.query_devices()):
        if d["max_input_channels"] > 0 and valor.lower() in d["name"].lower():
            return i
    sys.exit(f"Microfone '{valor}' nao encontrado. Rode: jarvis-show --listar")


def listar():
    for i, d in enumerate(sd.query_devices()):
        if d["max_input_channels"] > 0:
            print(f"{i:3}  {d['name']}  ({sd.query_hostapis(d['hostapi'])['name']})")
    print(f"\nPadrao do Windows: {sd.default.device[0]}")


def teste(mic):
    print(f"Fale e bata palmas. A palma precisa passar de {LIMIAR}. Ctrl+C para sair.")
    with sd.InputStream(device=mic, channels=1, samplerate=TAXA, blocksize=BLOCO) as s:
        while True:
            x, _ = s.read(BLOCO)
            pico = float(np.abs(x).max())
            barra = "#" * int(min(pico, 1.0) * 50)
            marca = "PALMA" if pico >= LIMIAR else "     "
            print(f"\r{pico:0.2f} {marca} {barra:<50}", end="", flush=True)


class DetectorDePalmas:
    """Recebe blocos de audio e diz quando ouviu duas palmas seguidas."""

    def __init__(self, limiar=LIMIAR):
        self.limiar = limiar
        self.historico = deque(maxlen=10)   # volume dos ultimos ~320 ms
        self.ultima = -10.0
        self.t = 0.0

    def alimentar(self, x):
        self.t += len(x) / TAXA
        pico = float(np.abs(x).max())
        rms = float(np.sqrt(np.mean(np.square(x))))
        fundo = float(np.median(self.historico)) if self.historico else 0.01
        self.historico.append(rms)
        # Palma = estalo forte E repentino em relacao ao som recente (fala alta continua nao conta)
        if pico < self.limiar or pico < 8 * max(fundo, 1e-3):
            return False
        if self.t - self.ultima < MESMA_PALMA:
            return False
        if INTERVALO[0] <= self.t - self.ultima <= INTERVALO[1]:
            self.ultima = -10.0
            return True
        self.ultima = self.t
        return False


def esperar_palmas(mic):
    print(f"Ouvindo... bata 2 palmas (sensibilidade {LIMIAR}). Ctrl+C para sair.")
    detector = DetectorDePalmas()
    with sd.InputStream(device=mic, channels=1, samplerate=TAXA, blocksize=BLOCO) as s:
        while True:
            x, _ = s.read(BLOCO)
            if detector.alimentar(x[:, 0]):
                return               # sai do "with": o microfone fica livre para a conversa


def tocar_jingle():
    for nome in ("jingle.mp3", "jingle.wav"):
        arq = BASE / "voz" / "assets" / nome
        if arq.exists():
            try:
                import soundfile as sf
                dados, taxa = sf.read(str(arq), dtype="float32")
                sd.play(dados, taxa)
                sd.wait()
            except Exception as e:
                print(f"Nao consegui tocar {arq.name}: {e}")
            return


def abrir_web():
    if os.environ.get("JARVIS_SEM_WEB") == "1":
        return

    def no_ar():
        try:
            urllib.request.urlopen(WEB, timeout=2)
            return True
        except Exception:
            return False

    if not no_ar():
        subprocess.run([str(JARVIS), "start"], cwd=BASE, timeout=120,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for _ in range(30):
            if no_ar():
                break
            time.sleep(1)
    webbrowser.open(WEB)


def main():
    args = sys.argv[1:]
    if "--listar" in args:
        return listar()
    mic = escolher_mic()
    if "--teste" in args:
        try:
            teste(mic)
        except KeyboardInterrupt:
            print()
        return
    try:
        while True:
            esperar_palmas(mic)
            print("\nPalmas! Abrindo o Jarvis...")
            tocar_jingle()
            abrir_web()
            subprocess.run([str(JARVIS), "chat", "--voice"], cwd=BASE)
            print("\nConversa encerrada. Voltando a ouvir as palmas.")
    except KeyboardInterrupt:
        print("\nAte mais.")


if __name__ == "__main__":
    main()
