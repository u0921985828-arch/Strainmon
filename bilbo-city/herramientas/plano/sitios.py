#!/usr/bin/env python3
"""Comprueba —o sincroniza— las pistas de los sitios entre el HTML y Ciudad/Estado.cs.

Cada sitio lleva la coordenada que le da el plano municipal, y el juego busca desde ahí
la casilla pisable más cercana. Esa coordenada está escrita en los dos sitios, y cada vez
que se movió algo se quedaron distintas: el HTML pasaba la batería y Unity habría puesto
los sitios en otro lado sin que nadie lo viera, porque el C# no se ejecuta aquí.

    python3 herramientas/plano/sitios.py          # comprueba, falla si no cuadran
    python3 herramientas/plano/sitios.py --fijar  # copia las del HTML al C#
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Juego' / 'Estado.cs'

def delHtml():
    s = HTML.read_text()
    return {m.group(1): (int(m.group(2)), int(m.group(3)))
            for m in re.finditer(r"\{id:'([a-z]+)'[^}]*?cerca:\[(\d+),(\d+)\]", s)}

def delCs():
    s = CS.read_text()
    return {m.group(1): (int(m.group(2)), int(m.group(3)))
            for m in re.finditer(r"S\(\"([a-z]+)\",\s*\"[^\"]+\",\s*[^,]+,\s*(?:null|\"[a-z]+\"),"
                                 r"\s*(\d+)\s*,\s*(\d+)", s)}

def main():
    h, c = delHtml(), delCs()
    faltan = sorted(set(h) - set(c))
    sobran = sorted(set(c) - set(h))
    distintos = sorted(k for k in set(h) & set(c) if h[k] != c[k])

    if '--fijar' in sys.argv:
        s = CS.read_text()
        for k in distintos:
            x, y = h[k]
            s, n = re.subn(r"(S\(\"%s\",\s*\"[^\"]+\",\s*[^,]+,\s*(?:null|\"[a-z]+\"),\s*)\d+\s*,\s*\d+" % k,
                           lambda m: "%s%4d,%4d" % (m.group(1), x, y), s, count=1)
            if n != 1: sys.exit('no pude reescribir el sitio %s en %s' % (k, CS))
        CS.write_text(s)
        print('sincronizados %d sitios' % len(distintos))
        return

    if faltan or sobran or distintos:
        for k in faltan:    print('  falta en Unity:      %s %s' % (k, h[k]))
        for k in sobran:    print('  sobra en Unity:      %s %s' % (k, c[k]))
        for k in distintos: print('  no cuadra: %-12s HTML %s · Unity %s' % (k, h[k], c[k]))
        sys.exit('los sitios no cuadran entre el HTML y Unity (arréglalo con --fijar)')
    print('%d sitios cuadran entre el HTML y Unity' % len(h))

main()
