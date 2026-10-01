# -*- coding: utf-8 -*-
"""Vuelve a pedir, de verdad desde arriba, lo que el lote devolvió de perfil.

Qué pasó
--------
`lote.py` pidió los dieciocho vehículos y los veintiocho muebles con `view='low top-down'`
y «seen from above» en la descripción. Los muebles salieron bien —un árbol, un banco, un
contenedor vistos desde arriba y un poco escorados, que es la vista del juego—, pero **los
dieciocho vehículos volvieron de perfil**: un coche de alzado lateral, con las cuatro
ruedas de lado. En una ciudad cenital eso no se puede usar; no es que esté feo, es que no
es la vista.

Y cuatro muebles volvieron mal por otro motivo: la antena es un garabato, la placa de
calle trae letras inventadas —que además no entran en el repositorio—, el lucernario
parece un televisor y la caseta, una ruina.

Qué cambia aquí
---------------
* `view='high top-down'`, que es la que funcionó con los diez singulares.
* La descripción manda la vista antes que el objeto y repite lo que **no** se quiere ver:
  «from directly above», «roof», «no side view». Decirlo una vez no basta.
* Nada de texto: un rótulo lo rellena el generador con letras inventadas.

Lo pedido se guarda en `dist/pixellab/cenital.json` y se baja a
`dist/pixellab/vehiculos/` y `muebles/` **encima de lo anterior**: lo que vale es lo
último, y `arte.py` no tiene que saber que hubo dos tiradas.

    export PIXELLAB_API_KEY=...
    python3 herramientas/sprites/cenital.py          # pide lo que falte y baja
    python3 herramientas/sprites/cenital.py estado
"""
import json, os, sys, time

sys.path.insert(0, os.path.dirname(__file__))
import pixellab_mcp as P
from lote import VEHICULOS, HUECOS, _lienzo, _ocupados, _con_hueco, _log, SALIDA, BASE

MANIFIESTO = os.path.join(SALIDA, 'cenital.json')
ESTILO = dict(view='high top-down', outline='selective outline',
              shading='basic shading', detail='medium detail')
# La vista, delante y repetida. Detrás, lo que no se quiere ver.
ARRIBA = ('straight top-down view from directly above, looking straight down at the roof, '
          'orthographic floor plan view, no side view, no perspective, no text, no letters')

# Los cuatro muebles que volvieron mal, redescritos. La placa de calle pierde el rótulo:
# un generador lo rellena con letras inventadas y además un texto no entra en el juego.
MUEBLES = {
    'antenaTv': 'television aerial on a roof, thin vertical mast with horizontal bars',
    'placa': 'blank blue enamel plate with a white border on a wall, no writing',
    'lucernario': 'glass skylight on a flat roof, metal frame, four panes',
    'caseta': 'small square rooftop stair hut with a door and a flat roof',
}


def _carga():
    if os.path.exists(MANIFIESTO):
        return json.load(open(MANIFIESTO))
    return {'vehiculos': {}, 'muebles': {}}


def _guarda(m):
    os.makedirs(SALIDA, exist_ok=True)
    json.dump(m, open(MANIFIESTO, 'w'), indent=1, ensure_ascii=False)


def pide(m):
    for nombre, (desc, l, an) in VEHICULOS.items():
        if nombre in m['vehiculos']:
            continue
        texto = (ARRIBA + '; ' + desc + ' seen from directly above, only the roof and the '
                 'bonnet are visible, the wheels just peek out at the sides, '
                 'pointing to the right')
        t = _con_hueco(lambda: P.llamar('create_map_object', dict(
            description=texto, width=_lienzo(l), height=_lienzo(an), **ESTILO)))
        m['vehiculos'][nombre] = P._id(t); _guarda(m)
        _log('vehiculo', nombre, m['vehiculos'][nombre])
    for nombre, desc in MUEBLES.items():
        if nombre in m['muebles']:
            continue
        t = _con_hueco(lambda: P.llamar('create_map_object', dict(
            description=ARRIBA + '; ' + desc, width=32, height=32, **ESTILO)))
        m['muebles'][nombre] = P._id(t); _guarda(m)
        _log('mueble', nombre, m['muebles'][nombre])


def baja(m):
    P.esperar(40)
    for clave in ('vehiculos', 'muebles'):
        for nombre, oid in m[clave].items():
            destino = os.path.join(SALIDA, clave, nombre + '.png')
            try:
                P.bajar(f'{BASE}/map-objects/{oid}/download', destino)
                _log('bajado', clave, nombre)
            except Exception as e:
                _log('pendiente', nombre, str(e)[:80])


if __name__ == '__main__':
    P.iniciar()
    m = _carga()
    if len(sys.argv) > 1 and sys.argv[1] == 'estado':
        print('vehículos %d/%d · muebles %d/%d'
              % (len(m['vehiculos']), len(VEHICULOS), len(m['muebles']), len(MUEBLES)))
        sys.exit(0)
    pide(m)
    baja(m)
    _log(P.llamar('get_balance').strip().splitlines()[-1])
