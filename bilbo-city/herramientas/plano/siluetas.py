#!/usr/bin/env python3
"""Comprueba que las hojas de silueta son las mismas en el HTML y en Unity.

Es la trampa de siempre con dos implementaciones. El bloque SPRITES lo escriben los dos a
la vez `herramientas/sprites/pixellab.py`, pero basta con regenerar y commitear solo uno
—o con editar a mano el que "solo era un byte"— para que el prototipo y el juego vistan
distinto. Y no sale ningún error: sale un peatón con otra chaqueta.

Compara cuatro cosas, y cada una tapa un agujero distinto:

* la **celda**, porque las capas de encima —pelo, gorro, bolsa— se forjan en la celda de
  la forja y se posan sobre la cabeza que trae la hoja: con otra medida, el gorro flota;
* las **rampas**, que son las que permiten repintar una parte sin tocar las demás;
* los **nombres** de las hojas, porque una hoja que no se llama como la silueta que el
  juego deduce de la ropa no la usa nadie y no se entera nadie;
* y los **bytes** de cada hoja, que es lo único que de verdad se ve.

    python3 herramientas/plano/siluetas.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Arte' / 'Siluetas.cs'
FORJA = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Arte' / 'ForjaChar.cs'


def bloque(ruta):
    s = ruta.read_text()
    a, b = '/*<<<SPRITES*/', '/*SPRITES>>>*/'
    if a not in s or b not in s:
        sys.exit('no encuentro el bloque SPRITES en %s' % ruta)
    return s[s.index(a) + len(a):s.index(b)]


def delHtml():
    t = bloque(HTML)
    m = re.search(r'cel:\[(\d+),(\d+)\]', t)
    cel = (int(m.group(1)), int(m.group(2))) if m else None
    rampas = {n: [int(v) for v in idx.split(',') if v.strip()]
              for n, idx in re.findall(r'(\w+):\[([\d,]*)\]', t[t.index('rampas:'):])}
    hojas = {}
    for n, cuerpo in re.findall(r'(\w+): \[\n(.*?)\]\.join', t, re.S):
        hojas[n] = ''.join(re.findall(r"'([^']*)'", cuerpo))
    return cel, rampas, hojas


def delCs():
    t = bloque(CS)
    m = re.search(r'CelW = (\d+), CelH = (\d+)', t)
    cel = (int(m.group(1)), int(m.group(2))) if m else None
    rampas, hojas = {}, {}
    i = t.find('Rampas')
    if i >= 0:
        for n, idx in re.findall(r'\{ "(\w+)", new\[\] \{ ([\d, ]*)\} \}', t[i:]):
            rampas[n] = [int(v) for v in idx.split(',') if v.strip()]
    j = t.find('_hojas')
    if j >= 0:
        for n, cuerpo in re.findall(r'\{ "(\w+)", new\[\] \{\n(.*?)\} \}', t[j:], re.S):
            hojas[n] = ''.join(re.findall(r'"([^"]*)"', cuerpo))
    return cel, rampas, hojas


def celda_forja():
    """La celda que declara la forja de Unity, para que la hoja no venga de otra medida."""
    s = FORJA.read_text()
    m = re.search(r'MG_X = (\d+), MG_ARR = (\d+), MG_ABA = (\d+);', s)
    if not m:
        sys.exit('no encuentro los márgenes de la forja en %s' % FORJA)
    mx, arr, aba = (int(g) for g in m.groups())
    return 20 + mx * 2, 26 + arr + aba


def main():
    ch, rh, hh = delHtml()
    cc, rc, hc = delCs()
    fallos = []
    if ch != cc:
        fallos.append('  la celda no cuadra: HTML %s · Unity %s' % (ch, cc))
    elif ch is not None and ch != celda_forja():
        fallos.append('  la celda de la hoja %s no es la de la forja de Unity %s: '
                      'regenera el bloque' % (ch, celda_forja()))
    for k in sorted(set(rh) | set(rc)):
        if rh.get(k) != rc.get(k):
            fallos.append('  rampa %-9s HTML %s · Unity %s' % (k, rh.get(k), rc.get(k)))
    for k in sorted(set(hh) | set(hc)):
        if k not in hc:
            fallos.append('  falta en Unity la silueta %s' % k)
        elif k not in hh:
            fallos.append('  sobra en Unity la silueta %s' % k)
        elif hh[k] != hc[k]:
            fallos.append('  la silueta %s no trae los mismos bytes (%d vs %d caracteres)'
                          % (k, len(hh[k]), len(hc[k])))
    if fallos:
        print('\n'.join(fallos))
        sys.exit('las hojas de silueta no cuadran entre el HTML y Unity — '
                 'rehazlas: python3 herramientas/sprites/pixellab.py --mano')
    print('celda %dx%d · %d rampas · %d siluetas (%.0f KB) iguales en los dos'
          % (ch[0], ch[1], len(rh), len(hh), sum(len(v) for v in hh.values()) / 1024))


if __name__ == '__main__':
    main()
