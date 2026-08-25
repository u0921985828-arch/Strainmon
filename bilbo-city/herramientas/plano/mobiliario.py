#!/usr/bin/env python3
"""Compara las medidas del mobiliario urbano entre el HTML y Forja.cs.

Cada pieza de la calle sale de su medida en metros y se forja a 20 px/m. Esa tabla está
escrita en los dos sitios, y es justo el tipo de cosa que se queda distinta sin que nadie lo
vea: el HTML pasa la batería y Unity plantaría papeleras de dos metros.

    python3 herramientas/plano/mobiliario.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Arte' / 'Forja.cs'

def delHtml():
    s = HTML.read_text()
    bloque = re.search(r'const MOB_M=\{(.*?)\};', s, re.S).group(1)
    return {m.group(1): (float(m.group(2)), float(m.group(3)))
            for m in re.finditer(r'(\w+):\[([\d.]+),([\d.]+)\]', bloque)}

def delCs():
    s = CS.read_text()
    bloque = re.search(r'MedidasMob = new Dictionary<string, float\[\]> \{(.*?)\n    \};', s, re.S).group(1)
    return {m.group(1): (float(m.group(2)), float(m.group(3)))
            for m in re.finditer(r'\{"(\w+)", new\[\]\{([\d.]+)f,([\d.]+)f\}\}', bloque)}

def main():
    h, c = delHtml(), delCs()
    faltan = sorted(set(h) - set(c))
    sobran = sorted(set(c) - set(h))
    distintos = sorted(k for k in set(h) & set(c) if h[k] != c[k])
    for k in faltan:    print('  FALLO %s no está en Forja.cs' % k)
    for k in sobran:    print('  FALLO %s sobra en Forja.cs' % k)
    for k in distintos: print('  FALLO %s: %s en el HTML y %s en Unity' % (k, h[k], c[k]))
    if faltan or sobran or distintos:
        print('\n%d piezas no cuadran' % (len(faltan)+len(sobran)+len(distintos)))
        return 1
    print('  ok    %d piezas de mobiliario con la misma medida en los dos' % len(h))
    return 0

sys.exit(main())
