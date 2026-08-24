# -*- coding: utf-8 -*-
"""Prueba la extracción del callejero sin tener el plano municipal.

El plano no está en el repositorio —norma nuestra— así que `extraer.py` no se puede
ejecutar aquí y su parte nueva se quedaría sin comprobar hasta que alguien la corriera en
su máquina con el PDF delante. Eso es justo la clase de código que se pudre.

Así que se fabrica un PDF de mentira con la misma pinta que el de verdad: rótulos de calle
repetidos a lo largo de su calle, un equipamiento escrito encima de una manzana, un número
suelto y el nombre de un barrio. Y se comprueba que sale lo que tiene que salir.

    python3 herramientas/plano/pruebas_extraer.py
"""
import os, sys, pathlib
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import pymupdf
import extraer as E

fallos = []


def ok(cond, msg):
    if not cond:
        fallos.append(msg)


def rejilla_falsa():
    """Una ciudad de mentira: una avenida de este a oeste y una manzana debajo."""
    rej = bytearray([E.EDIF]) * (E.MW * E.MH)
    for y in range(380, 386):
        for x in range(200, 1200):
            rej[y * E.MW + x] = E.CALLE
    return rej


def punto_de(gx, gy):
    """De casilla del juego a punto de PDF: la inversa de a_casilla()."""
    ex = (E.RECORTE[2] - E.RECORTE[0]) / E.MW
    ey = (E.RECORTE[3] - E.RECORTE[1]) / E.MH
    return E.RECORTE[0] + (gx + .5) * ex, E.RECORTE[1] + (gy + .5) * ey


def pdf_falso(rotulos):
    doc = pymupdf.open()
    pag = doc.new_page(width=E.RECORTE[2] + 200, height=E.RECORTE[3] + 200)
    for texto, gx, gy in rotulos:
        x, y = punto_de(gx, gy)
        pag.insert_text((x, y), texto, fontname='helv', fontsize=7)
    return pymupdf.open('pdf', doc.tobytes())


rej = rejilla_falsa()
pdf = pdf_falso([
    # Una avenida larga, rotulada cuatro veces y a propósito en desorden: el extractor
    # tiene que ordenarlas a lo largo del eje, que si no los puntos de paso van en zigzag.
    ('GRAN VIA', 900, 383), ('GRAN VIA', 300, 383),
    ('GRAN VIA', 600, 383), ('GRAN VIA', 1100, 383),
    ('ERCILLA', 500, 383),                    # una calle con un solo rótulo
    ('ERCILLA 12', 505, 383),                 # el mismo, con número: mismo nombre
    ('POLIDEPORTIVO', 700, 200),              # equipamiento: lejos de la calle, fuera
    ('SANTUTXU', 400, 383),                   # un barrio: tiene su tabla, fuera
    ('27', 800, 383),                         # un número suelto, fuera
    ('B', 850, 383),                          # una letra de cuadrícula, fuera
])
calles = dict(E.calles_de(pdf, rej))

ok('Gran Via' in calles, 'no salió la avenida rotulada varias veces')
ok('Ercilla' in calles, 'no salió la calle de un solo rótulo')
ok('Polideportivo' not in calles, 'se coló un equipamiento, que está lejos de la calle')
ok('Santutxu' not in calles, 'se coló un barrio')
ok('27' not in calles and 'B' not in calles, 'se coló un número o una letra de cuadrícula')

if 'Gran Via' in calles:
    v = calles['Gran Via']
    ok(len(v) == 4, 'la avenida salió con %d puntos de paso, no 4' % len(v))
    ok(v == sorted(v), 'los puntos de paso no están ordenados a lo largo de la calle: %s' % (v,))
    ok(all(380 <= y <= 386 for _, y in v), 'algún punto de paso cayó fuera de la calle')

if 'Ercilla' in calles:
    # Dos rótulos a cinco casillas son el mismo sitio escrito dos veces.
    ok(len(calles['Ercilla']) == 2,
       'los dos rótulos pegados de Ercilla no se fundieron: %s' % (calles['Ercilla'],))

# Y que lo emitido sea código válido en los dos lados.
js = E.bloque_calles_js(list(calles.items()))
cs = E.bloque_calles_cs(list(calles.items()))
ok(js.startswith('const CALLES=[') and js.rstrip().endswith('];'), 'el bloque JS no cierra')
ok('C("Gran Via"' in cs, 'el bloque C# no trae la avenida')
ok(js.count('{n:') == len(calles), 'el bloque JS no trae todas las calles')

if fallos:
    for f in fallos:
        print('  FALLO ' + f)
    sys.exit('%d fallos en la extracción del callejero' % len(fallos))
print('la extracción del callejero saca %d calles del plano de mentira, y descarta lo que no lo es'
      % len(calles))
