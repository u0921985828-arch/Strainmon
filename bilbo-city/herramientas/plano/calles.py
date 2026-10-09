#!/usr/bin/env python3
"""Comprueba que el callejero es el mismo en el HTML y en Unity.

Cada calle lleva sus puntos de paso escritos en dos sitios: la tabla CALLES del prototipo
y la tabla Calles de Callejero.cs. Es la misma trampa que con los sitios y con los
singulares: el HTML pasa la batería, el C# no se ejecuta aquí, y Unity acaba nombrando la
Gran Vía por otro sitio sin que nadie lo vea.

    python3 herramientas/plano/calles.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Ciudad' / 'Callejero.cs'

def delHtml():
    s = HTML.read_text()
    d = {}
    for m in re.finditer(r"\{n:'([^']+)',\s*v:\[([^\]]*(?:\][^\]]*)*?)\]\},", s):
        pts = [tuple(map(int, p)) for p in re.findall(r'\[(\d+),(\d+)\]', m.group(2))]
        if pts: d[m.group(1)] = pts
    return d

def delCs():
    s = CS.read_text()
    d = {}
    for m in re.finditer(r'C\("([^"]+)",\s*([0-9,\s]+)\)', s):
        n = [int(v) for v in re.findall(r'\d+', m.group(2))]
        d[m.group(1)] = [(n[i], n[i+1]) for i in range(0, len(n)-1, 2)]
    return d

def main():
    h, c = delHtml(), delCs()
    if not h:
        sys.exit('no encontré ninguna calle en %s' % HTML)
    faltan    = sorted(set(h) - set(c))
    sobran    = sorted(set(c) - set(h))
    distintos = sorted(k for k in set(h) & set(c) if h[k] != c[k])
    if faltan or sobran or distintos:
        for k in faltan:    print('  falta en Unity: %s' % k)
        for k in sobran:    print('  sobra en Unity: %s' % k)
        for k in distintos: print('  no cuadra: %-24s HTML %s · Unity %s' % (k, h[k], c[k]))
        sys.exit('el callejero no cuadra entre el HTML y Unity')
    print('%d calles cuadran entre el HTML y Unity' % len(h))

main()
