#!/usr/bin/env python3
"""Comprueba que los edificios singulares miden lo mismo en el HTML y en Unity.

El estadio, la catedral, el Ayuntamiento y los demás llevan escrita su medida real en
casillas, y esa medida está en dos ficheros: la tabla PLANO_SINGULAR del prototipo y la
tabla DePlano de Singulares.cs. Es exactamente la trampa en la que ya se cayó con las
coordenadas de los sitios: el HTML pasa la batería, el C# no se ejecuta aquí, y Unity
acaba pintando un Guggenheim de otro tamaño sin que nadie lo vea.

    python3 herramientas/plano/singulares.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Ciudad' / 'Singulares.cs'

def delHtml():
    s = HTML.read_text()
    return {m.group(1): (int(m.group(2)), int(m.group(3)))
            for m in re.finditer(r"^ ([a-z]+):\[(\d+),(\d+),\(T,W,H", s, re.M)}

def delCs():
    s = CS.read_text()
    return {m.group(1): (int(m.group(2)), int(m.group(3)))
            for m in re.finditer(r'\{"([a-z]+)",\s*new Plano_ \{ W = (\d+), H = (\d+),', s)}

def main():
    h, c = delHtml(), delCs()
    if not h:
        sys.exit('no encontré ningún singular en %s' % HTML)
    faltan    = sorted(set(h) - set(c))
    sobran    = sorted(set(c) - set(h))
    distintos = sorted(k for k in set(h) & set(c) if h[k] != c[k])
    if faltan or sobran or distintos:
        for k in faltan:    print('  falta en Unity: %-11s %dx%d' % (k, *h[k]))
        for k in sobran:    print('  sobra en Unity: %-11s %dx%d' % (k, *c[k]))
        for k in distintos: print('  no cuadra: %-11s HTML %dx%d · Unity %dx%d'
                                  % (k, *h[k], *c[k]))
        sys.exit('los singulares no cuadran entre el HTML y Unity')
    print('%d edificios singulares cuadran entre el HTML y Unity' % len(h))

main()
