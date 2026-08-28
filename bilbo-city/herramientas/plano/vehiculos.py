#!/usr/bin/env python3
"""Compara la punta de cada chasis entre el HTML y Unity.

La tabla existía solo en el prototipo: en el puerto todo coche se creaba con `vmax: 11f`
fijo, así que el autobús de línea corría lo mismo que el deportivo y comprarse un deportivo
por 1600 € no cambiaba nada. Ahora está en los dos sitios, y esto vigila que siga igual.

    python3 herramientas/plano/vehiculos.py
"""
import re, sys, pathlib

RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Entidades' / 'Vehiculo.cs'

def delHtml():
    bloque = re.search(r'const VMAX_VEH=\{(.*?)\};', HTML.read_text(), re.S).group(1)
    return {m.group(1): int(m.group(2)) for m in re.finditer(r'(\w+):(\d+)', bloque)}

def delCs():
    bloque = re.search(r'KmH = new Dictionary<string, int> \{(.*?)\n    \};',
                       CS.read_text(), re.S).group(1)
    return {m.group(1): int(m.group(2)) for m in re.finditer(r'\{"(\w+)",\s*(\d+)\}', bloque)}

def main():
    h, c = delHtml(), delCs()
    fallos  = ['%s no está en Vehiculo.cs' % k for k in sorted(set(h) - set(c))]
    fallos += ['%s sobra en Vehiculo.cs' % k for k in sorted(set(c) - set(h))]
    fallos += ['%s: %d km/h en el HTML y %d en Unity' % (k, h[k], c[k])
               for k in sorted(set(h) & set(c)) if h[k] != c[k]]
    for f in fallos: print('  FALLO ' + f)
    if fallos:
        print('\n%d chasis no cuadran' % len(fallos))
        return 1
    print('  ok    %d chasis con la misma punta en los dos' % len(h))
    return 0

sys.exit(main())
