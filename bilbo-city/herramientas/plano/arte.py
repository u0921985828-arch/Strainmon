#!/usr/bin/env python3
"""Comprueba que el arte traído es el mismo en el HTML y en Unity.

La trampa es la de siempre con dos implementaciones. El bloque ARTE lo escriben los dos a
la vez `herramientas/sprites/arte.py`, pero basta con regenerar y commitear solo uno —o
con tocar a mano el que «solo era un byte»— para que el prototipo y el juego pinten
ciudades distintas. Y no sale ningún error: sale una catedral en un sitio y un rectángulo
gris en el otro.

Compara tres cosas, y cada una tapa un agujero distinto:

* las **familias**, porque una que esté en un lado y no en el otro es media integración;
* el **tamaño** de cada pieza, que es lo que decide el escalado al dibujarla —un singular
  se estira hasta la caja que le haya cabido, así que con otra medida sale deformado—;
* y los **bytes**, que es lo único que de verdad se ve.

    python3 herramientas/plano/arte.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Arte' / 'Traido.cs'


def bloque(ruta):
    s = ruta.read_text()
    a, b = '/*<<<ARTE*/', '/*ARTE>>>*/'
    if a not in s or b not in s:
        sys.exit('no encuentro el bloque ARTE en %s' % ruta)
    return s[s.index(a) + len(a):s.index(b)]


def delHtml():
    t = bloque(HTML)
    fuera = {}
    # Las familias se trocean por dónde empieza cada una y no con una expresión que
    # intente casar la llave de cierre: el cuerpo lleva corchetes y llaves por todas
    # partes, y una expresión así se pasa de largo en cuanto una pieza cambie de forma.
    marcas = [(m.group(1), m.start()) for m in re.finditer(r'(\w+):\{\n', t)]
    for i, (fam, ini) in enumerate(marcas):
        fin = marcas[i + 1][1] if i + 1 < len(marcas) else len(t)
        piezas = {}
        for n, w, h, trozos in re.findall(
                r"(\w+):\[(\d+),(\d+),\[\n(.*?)\]\.join\(''\)\]", t[ini:fin], re.S):
            piezas[n] = (int(w), int(h), ''.join(re.findall(r"'([^']*)'", trozos)))
        fuera[fam] = piezas
    return fuera


def delCs():
    t = bloque(CS)
    fuera = {}
    for fam, cuerpo in re.findall(
            r'Dictionary<string, Estampa> (\w+)\s*=\s*new Dictionary<string, Estampa> \{\n(.*?)\n    \};',
            t, re.S):
        piezas = {}
        for n, w, h, trozos in re.findall(
                r'\{ "(\w+)", new Estampa\((\d+), (\d+), new\[\] \{\n(.*?) \}\) \}', cuerpo, re.S):
            piezas[n] = (int(w), int(h), ''.join(re.findall(r'"([^"]*)"', trozos)))
        fuera[fam.lower()] = piezas
    return fuera


def main():
    h, c = delHtml(), delCs()
    fallos = []
    for fam in sorted(set(h) | set(c)):
        if fam not in c:
            fallos.append('  falta en Unity la familia %s' % fam); continue
        if fam not in h:
            fallos.append('  sobra en Unity la familia %s' % fam); continue
        for k in sorted(set(h[fam]) | set(c[fam])):
            if k not in c[fam]:
                fallos.append('  %s/%s: falta en Unity' % (fam, k))
            elif k not in h[fam]:
                fallos.append('  %s/%s: sobra en Unity' % (fam, k))
            elif h[fam][k][:2] != c[fam][k][:2]:
                fallos.append('  %s/%s: HTML %dx%d · Unity %dx%d'
                              % (fam, k, h[fam][k][0], h[fam][k][1],
                                 c[fam][k][0], c[fam][k][1]))
            elif h[fam][k][2] != c[fam][k][2]:
                fallos.append('  %s/%s: no trae los mismos bytes (%d vs %d caracteres)'
                              % (fam, k, len(h[fam][k][2]), len(c[fam][k][2])))
    if fallos:
        print('\n'.join(fallos))
        sys.exit('el arte traído no cuadra entre el HTML y Unity — rehazlo: '
                 'python3 herramientas/sprites/arte.py')
    piezas = sum(len(v) for v in h.values())
    peso = sum(len(p[2]) for v in h.values() for p in v.values()) / 1024
    print('%d familias · %d piezas (%.0f KB) iguales en los dos'
          % (len(h), piezas, peso) if piezas else
          'el bloque ARTE está vacío en los dos: todo forjado')


if __name__ == '__main__':
    main()
