#!/usr/bin/env python3
"""Recomprime PNG sin pérdida (mismos píxeles, menos bytes) y comprueba que no haya
PNG hinchados. El arte del juego viaja crudo dentro del paquete (importer="keep"), así que
cada byte de más del PNG es un byte de más en la APK.

  python3 tools/png-opt.py godot/arte            # recomprime lo que gane algo
  python3 tools/png-opt.py --check godot/arte    # no toca nada; sale con 1 si alguno adelgaza >2 %
"""
import io
import sys
from pathlib import Path

from PIL import Image

MARGEN = 0.02   # por debajo de esto no merece la pena reescribir


def recomprime(f: Path):
    """Devuelve (bytes_antes, bytes_despues, datos) o None si no gana nada."""
    antes = f.stat().st_size
    im = Image.open(f)
    im.load()
    buf = io.BytesIO()
    im.save(buf, "PNG", optimize=True)
    datos = buf.getvalue()
    # mismos píxeles, siempre: si no, no se toca
    if Image.open(io.BytesIO(datos)).convert("RGBA").tobytes() != im.convert("RGBA").tobytes():
        return None
    return antes, len(datos), datos


def main() -> int:
    args = sys.argv[1:]
    check = "--check" in args
    dirs = [a for a in args if not a.startswith("--")] or ["godot/arte"]
    archivos = sorted(p for d in dirs for p in Path(d).rglob("*.png"))
    if not archivos:
        print("png-opt: no hay PNG en %s" % ", ".join(dirs))
        return 1
    gordos, ganado, tocados = [], 0, 0
    for f in archivos:
        r = recomprime(f)
        if not r:
            continue
        antes, despues, datos = r
        if despues >= antes * (1 - MARGEN):
            continue
        gordos.append((f, antes, despues))
        ganado += antes - despues
        if not check:
            f.write_bytes(datos)
            tocados += 1
    for f, antes, despues in gordos:
        print("  %-40s %9d → %9d  (−%d %%)" % (f, antes, despues, round(100 * (antes - despues) / antes)))
    if check:
        print("png-opt: %d de %d PNG adelgazan (%.2f MB)" % (len(gordos), len(archivos), ganado / 1048576))
        return 1 if gordos else 0
    print("png-opt: %d de %d PNG recomprimidos, %.2f MB menos" % (tocados, len(archivos), ganado / 1048576))
    return 0


if __name__ == "__main__":
    sys.exit(main())
