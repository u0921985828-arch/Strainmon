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

def altoHtml():
    s = HTML.read_text()
    bloque = re.search(r'const ALTO_SINGULAR=\{(.*?)\};', s, re.S).group(1)
    return {m.group(1): int(m.group(2)) for m in re.finditer(r'(\w+):(\d+)', bloque)}

def altoCs():
    s = CS.read_text()
    bloque = re.search(r'AltoSingular = new Dictionary<string,float> \{(.*?)\n    \};', s, re.S).group(1)
    return {m.group(1): int(m.group(2)) for m in re.finditer(r'\{"(\w+)", (\d+)\}', bloque)}

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
    # La altura no la usa el dibujo, la usa la sombra: la torre Iberdrola son 165 m y a
    # media tarde su sombra cruza Abandoibarra. Si las dos tablas se separan, en Unity la
    # torre proyecta como un portal y aquí no lo ve nadie.
    ah, ac = altoHtml(), altoCs()
    malas = sorted(set(ah) ^ set(ac)) + sorted(k for k in set(ah) & set(ac) if ah[k] != ac[k])
    if malas:
        for k in malas:
            print('  altura no cuadra: %-11s HTML %s m · Unity %s m'
                  % (k, ah.get(k, '—'), ac.get(k, '—')))
        sys.exit('las alturas de los singulares no cuadran entre el HTML y Unity')
    print('%d edificios singulares cuadran entre el HTML y Unity, medida y altura' % len(h))

main()
