#!/usr/bin/env python3
"""Compara la tabla de armas entre el HTML y Estado.cs.

Daño, alcance, cadencia, precio y munición están escritos en los dos sitios. Es la trampa
de siempre: el HTML pasa la batería, Unity no se ejecuta aquí, y las dos tablas se separan
sin que nadie lo vea. Ya pasó — el alcance del puño y el del bate se quedaron en el `1.0` y
el `1.4` que el HTML abandonó por engañosos (5,2 m y 7,2 m: se pegaba desde la otra acera).

    python3 herramientas/plano/armas.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Juego' / 'Estado.cs'

# Solo los números de juego: el color y el largo del sprite son cosa del dibujo de cada
# lado, y ahí las dos forjas no tienen por qué escribir lo mismo.
CAMPOS = {'dmg': 'Dmg', 'alc': 'Alc', 'cad': 'Cad', 'precio': 'Precio',
          'balas': 'Balas', 'pack': 'Pack', 'vel': 'Vel', 'spread': 'Spread',
          'disp': 'Disp'}
# Lo que no se escribe vale el de fábrica en los dos lados (`a.disp||1` en el HTML,
# `public int Disp = 1` en C#). Sin esto, no escribirlo se leería como una divergencia.
POR_DEFECTO = {'dmg': 0, 'alc': 0, 'cad': 0, 'precio': 0, 'balas': 0, 'pack': 0,
               'vel': 0, 'spread': 0, 'disp': 1}
NUM = r'-?[\d.]+'

def num(v):
    return round(float(v), 4)

def delHtml():
    s = HTML.read_text()
    bloque = re.search(r'const ARMAS=\[(.*?)\n\];', s, re.S).group(1)
    armas = {}
    # Cada arma es una entrada `{id:'x', ...}` que puede ocupar dos líneas. Se corta por el
    # `{id:` siguiente en vez de emparejar llaves, que dentro hay comas y comillas.
    trozos = re.split(r'\{id:', bloque)[1:]
    for t in trozos:
        ident = re.match(r"'(\w+)'", t).group(1)
        armas[ident] = {k: num(m.group(1)) if m else POR_DEFECTO[k]
                        for k in CAMPOS
                        for m in [re.search(r'\b%s:(%s)' % (k, NUM), t)]}
        armas[ident]['cuerpo'] = 'cuerpo:true' in t
    return armas

def delCs():
    s = CS.read_text()
    bloque = re.search(r'Todas = new List<Arma> \{(.*?)\n    \};', s, re.S).group(1)
    armas = {}
    for t in re.split(r'new Arma\{', bloque)[1:]:
        ident = re.search(r'Id="(\w+)"', t).group(1)
        armas[ident] = {k: num(m.group(1)) if m else POR_DEFECTO[k]
                        for k, cs in CAMPOS.items()
                        for m in [re.search(r'\b%s=(%s)f?' % (cs, NUM), t)]}
        armas[ident]['cuerpo'] = 'Cuerpo=true' in t
    return armas

def main():
    h, c = delHtml(), delCs()
    fallos = []
    for k in sorted(set(h) - set(c)): fallos.append('%s no está en Estado.cs' % k)
    for k in sorted(set(c) - set(h)): fallos.append('%s sobra en Estado.cs' % k)
    for k in sorted(set(h) & set(c)):
        for campo in sorted(set(h[k]) | set(c[k])):
            a, b = h[k].get(campo), c[k].get(campo)
            if a != b:
                fallos.append('%s.%s: %s en el HTML y %s en Unity' % (k, campo, a, b))
    for f in fallos: print('  FALLO ' + f)
    if fallos:
        print('\n%d valores de arma no cuadran' % len(fallos))
        return 1
    print('  ok    %d armas con los mismos números en los dos' % len(h))
    return 0

sys.exit(main())
