# -*- coding: utf-8 -*-
"""El lote entero de arte de PixelLab para Bilbo City, reanudable.

Qué pide
--------
* **7 siluetas** (`pixellab.SETS`) con `create_character`: una generación cada una, ocho
  direcciones, con los colores de plantilla para que el repintado del juego siga valiendo.
* **4 animaciones de plantilla** por silueta (andar, correr, puñetazo, muerte), una
  generación por dirección.
* **9 pares de terreno** con `create_topdown_tileset`: los suelos que el juego junta.
* **Mobiliario de calle** (`PROP` del juego), **18 chasis** de vehículo y **10 edificios
  singulares** con `create_map_object`, una generación cada pieza.

Cómo se comporta
----------------
* Todo lo que se pide queda en `dist/pixellab/lote.json` con su id. Si se corta a
  mitad, se relanza y sigue por donde iba: nada se pide dos veces.
* La cuenta tiene diez huecos de trabajo y otros procesos los usan. Las animaciones se
  encolan por direcciones sueltas según haya hueco, y no se rinde: espera y vuelve.
* Al final baja todo a `dist/pixellab/` (hojas de personaje en zip, tilesets y objetos
  en PNG). `dist/` no se versiona: la traída al formato del juego es el paso siguiente.

    export PIXELLAB_API_KEY=...
    python3 herramientas/sprites/lote.py            # todo
    python3 herramientas/sprites/lote.py estado     # cuánto hay pedido y cuánto queda
"""
import json, os, re, sys, time

sys.path.insert(0, os.path.dirname(__file__))
import pixellab_mcp as P
from pixellab import SETS

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SALIDA = os.path.join(RAIZ, 'dist', 'pixellab')
LOTE = os.path.join(SALIDA, 'lote.json')
BASE = 'https://api.pixellab.ai/mcp'
HUECOS = 10

DIRECCIONES = ['south', 'east', 'north', 'west', 'south-east', 'north-east', 'north-west', 'south-west']
ANIMACIONES = {'andar': 'walking-8-frames', 'correr': 'running-6-frames',
               'punetazo': 'lead-jab', 'muerte': 'falling-back-death'}

# Los colores de plantilla, en palabras: cada parte de un color que no se parece a otro.
PLANTILLA = ('vivid magenta upper garment, vivid green lower garment, vivid cyan shoes, '
             'short vivid blue hair, plain tan skin, bare head, no bag, no hat')
ESTILO_CHAR = dict(body_type='humanoid', mode='standard', n_directions=8, size=32,
                   view='low top-down', outline='single color black outline',
                   shading='flat shading', detail='low detail')

SUELOS = {   # (abajo, arriba, transición)
    'asfalto_acera':   ('dark grey worn asphalt road, 1990s spanish city street',
                        'light grey concrete pavement slabs with granite kerb', 'granite kerb stone edge'),
    'acera_adoquin':   ('light grey concrete pavement slabs', 'grey granite cobblestones, old town street', None),
    'acera_hierba':    ('light grey concrete pavement slabs', 'trimmed park grass', 'low stone border'),
    'ria_muelle':      ('murky green-grey estuary water with slow ripples', 'concrete dock quay with iron bollards', 'quay wall edge'),
    'hierba_ria':      ('murky green-grey estuary water with slow ripples', 'trimmed park grass', 'muddy river bank'),
    'obra_acera':      ('brown building-site dirt with tyre tracks', 'light grey concrete pavement slabs', 'temporary fence line'),
    'asfalto_via':     ('dark grey worn asphalt road', 'railway track on grey ballast, steel rails', None),
    'acera_plaza':     ('light grey concrete pavement slabs', 'red brick plaza paving in a herringbone pattern', None),
    'monte_roca':      ('green mountain scrub with heather', 'grey limestone rock outcrop', 'mossy rock edge'),
}
ESTILO_SUELO = dict(tile_size={'width': 32, 'height': 32}, mode='standard', view='low top-down',
                    outline='selective outline', shading='basic shading', detail='low detail',
                    transition_size=0.2)

MUEBLES = {   # nombre en el juego -> descripción
    'farola': 'cast iron street lamp post, spanish city', 'semaforo': 'traffic light on a grey pole',
    'arbol': 'london plane street tree with round canopy', 'arbolPodado': 'pollarded plane tree, bare trunk with knobbly stumps',
    'contenedor': 'green wheeled rubbish container, closed lid', 'contenedor2': 'yellow wheeled recycling container, closed lid',
    'papelera': 'small metal litter bin on a post', 'banco': 'wooden and iron public bench',
    'marquesina': 'bus shelter with glass panels and a flat roof', 'cabina': 'blue public telephone booth, 1990s',
    'bolardo': 'short cast iron bollard', 'valla': 'temporary metal building-site fence panel',
    'andamio': 'metal scaffolding with wooden planks', 'pales': 'stack of wooden pallets',
    'cono': 'orange traffic cone', 'grua': 'tall yellow construction tower crane',
    'contMaritimo': 'rusty red shipping container', 'bidon': 'blue steel oil drum',
    'toldo': 'striped shop awning, red and white', 'terraza': 'bar terrace table with two chairs',
    'placa': 'blue and white enamel street name plate', 'deposito': 'rooftop water tank on legs',
    'climatizador': 'rooftop air conditioning unit', 'antenaTv': 'rooftop television aerial',
    'tendedero': 'rooftop washing line with hanging clothes', 'caseta': 'small rooftop stair hut',
    'chimenea': 'brick chimney stack', 'lucernario': 'rooftop glass skylight',
}
VEHICULOS = {   # nombre -> (descripción, largo, ancho); largo horizontal, morro a la derecha
    'utilitario': ('small 1990s hatchback car', 32, 18), 'berlina': ('1990s family saloon car', 38, 18),
    'ranchera': ('1990s estate car', 40, 18), 'furgoCorta': ('short panel van', 36, 20),
    'furgoLarga': ('long panel van', 44, 20), 'deportivo': ('low 1990s sports coupe', 38, 17),
    'todoterreno': ('boxy off-road 4x4', 38, 21), 'taxi': ('white taxi saloon with a red stripe and roof sign', 38, 18),
    'patrulla': ('white and red police patrol car with a light bar', 38, 18),
    'ambulancia': ('white ambulance van with a red cross and blue lights', 44, 21),
    'basura': ('rear-loading rubbish truck', 46, 21), 'autobus': ('red city bus', 56, 22),
    'camionObra': ('yellow tipper truck', 46, 21), 'moto': ('motorbike with rider', 20, 11),
    'bomberos': ('red fire engine with a ladder', 50, 22), 'grua': ('municipal tow truck with a crane arm', 44, 20),
    'microbus': ('small red minibus', 42, 20), 'furgonPoli': ('red and white police van with a grille', 44, 21),
}
EDIFICIOS = {   # nombre -> descripción, en 128x128
    'sanmames': 'old 1990s football stadium with a big steel arch over the main stand, rectangular pitch',
    'arriaga': 'neo-baroque opera theatre with a mansard roof and a rounded facade',
    'ayto': '19th century city hall with a clock tower and a formal facade',
    'abando': 'grand railway terminus with a wide glass arch and a stone facade',
    'catedral': 'gothic cathedral with a single spire and a cloister',
    'alhondiga': 'large old brick wine warehouse with a flat roof, city block sized',
    'bellasartes': 'fine arts museum, classical stone building with a modern glass wing',
    'begonia': 'hilltop basilica with a tall single bell tower',
    'deustuni': 'long 19th century university building with a central dome',
    'obraGuggen': 'museum under construction, steel skeleton, cranes and site huts by a river',
}
ESTILO_OBJ = dict(view='low top-down', outline='selective outline', shading='basic shading', detail='low detail')


def _carga():
    if os.path.exists(LOTE):
        return json.load(open(LOTE))
    return {'personajes': {}, 'animaciones': {}, 'suelos': {}, 'muebles': {}, 'vehiculos': {}, 'edificios': {}}


def _guarda(l):
    os.makedirs(SALIDA, exist_ok=True)
    json.dump(l, open(LOTE, 'w'), indent=1, ensure_ascii=False)


def _log(*a):
    print(time.strftime('%H:%M:%S'), *a, flush=True)


def _ocupados():
    t = P.llamar('list_jobs')
    m = re.match(r'(\d+) jobs?', t)
    return int(m.group(1)) if m else 0


def _con_hueco(fn, n=1):
    """Ejecuta la petición cuando haya n huecos; si el servidor rebota, espera y vuelve."""
    while True:
        libres = HUECOS - _ocupados()
        if libres >= n:
            try:
                return fn()
            except RuntimeError as e:
                if 'job slots' not in str(e):
                    raise
                _log('rebote:', str(e)[:70])
        time.sleep(30)


def _lienzo(n):
    """create_map_object no baja de 32; se redondea a múltiplo de 8 para que el trozo transparente sea regular."""
    return max(32, (n + 8 + 7) // 8 * 8)


def personajes(l):
    for nombre, ropa in SETS.items():
        if nombre in l['personajes']:
            continue
        desc = f'plain standing person wearing {ropa}, {PLANTILLA}'
        t = _con_hueco(lambda: P.llamar('create_character', dict(description=desc, name=nombre, **ESTILO_CHAR)))
        l['personajes'][nombre] = P._id(t); _guarda(l)
        _log('personaje', nombre, l['personajes'][nombre])


def suelos(l):
    for nombre, (abajo, arriba, trans) in SUELOS.items():
        if nombre in l['suelos']:
            continue
        args = dict(lower_description=abajo, upper_description=arriba, **ESTILO_SUELO)
        if trans:
            args['transition_description'] = trans
        else:
            args['transition_size'] = 0.0
        t = _con_hueco(lambda: P.llamar('create_topdown_tileset', args))
        l['suelos'][nombre] = P._id(t); _guarda(l)
        _log('suelo', nombre, l['suelos'][nombre])


def objetos(l, clave, tabla, tam):
    for nombre, v in tabla.items():
        if nombre in l[clave]:
            continue
        desc, w, h = tam(v)
        t = _con_hueco(lambda: P.llamar('create_map_object', dict(description=desc + ', seen from above',
                                                                  width=w, height=h, **ESTILO_OBJ)))
        l[clave][nombre] = P._id(t); _guarda(l)
        _log(clave, nombre, l[clave][nombre])


def _listo(cid):
    return 'status: completed' in P.llamar('get_character', {'character_id': cid})


def animaciones(l):
    """Cada animación por direcciones sueltas, las que quepan; se apunta el grupo para seguir en él."""
    for nombre, cid in l['personajes'].items():
        while not _listo(cid):
            time.sleep(30)
        for anim, plantilla in ANIMACIONES.items():
            k = nombre + '/' + anim
            est = l['animaciones'].setdefault(k, {'grupo': None, 'hechas': []})
            faltan = [d for d in DIRECCIONES if d not in est['hechas']]
            while faltan:
                libres = HUECOS - _ocupados()
                if libres < 1:
                    time.sleep(30); continue
                lote = faltan[:libres]
                args = dict(character_id=cid, template_animation_id=plantilla, animation_name=anim, directions=lote)
                if est['grupo']:
                    args['animation_group_id'] = est['grupo']
                try:
                    t = P.llamar('animate_character', args)
                except RuntimeError as e:
                    if 'job slots' not in str(e):
                        raise
                    time.sleep(20); continue
                m = re.search(r'group: ([0-9a-f-]+)', t)
                if m:
                    est['grupo'] = m.group(1)
                est['hechas'] += lote; faltan = [d for d in faltan if d not in lote]
                _guarda(l); _log('anim', k, lote)


def bajar(l):
    P.esperar(40)
    def _baja(url, destino):
        """Idempotente y tolerante: lo que ya está no se vuelve a pedir; un 423 (aún procesando)
        o un corte del proxy se apuntan y se sigue con el resto. Relanzar el script lo completa."""
        if os.path.exists(destino):
            return
        try:
            P.bajar(url, destino); _log('bajado', os.path.basename(destino))
        except Exception as e:
            _log('pendiente', os.path.basename(destino), str(e)[:80])
    for nombre, cid in l['personajes'].items():
        _baja(f'{BASE}/characters/{cid}/spritesheet', os.path.join(SALIDA, 'personajes', nombre + '.zip'))
    for nombre, tid in l['suelos'].items():
        _baja(f'{BASE}/tilesets/{tid}/image?inline=true', os.path.join(SALIDA, 'suelos', nombre + '.png'))
    for clave in ('muebles', 'vehiculos', 'edificios'):
        for nombre, oid in l[clave].items():
            _baja(f'{BASE}/map-objects/{oid}/download', os.path.join(SALIDA, clave, nombre + '.png'))
    _log('bajado todo a', SALIDA)


def estado(l):
    hechas = sum(len(v['hechas']) for v in l['animaciones'].values())
    print(f"personajes {len(l['personajes'])}/{len(SETS)} · animaciones {hechas}/{len(SETS)*len(ANIMACIONES)*8} direcciones"
          f" · suelos {len(l['suelos'])}/{len(SUELOS)} · muebles {len(l['muebles'])}/{len(MUEBLES)}"
          f" · vehículos {len(l['vehiculos'])}/{len(VEHICULOS)} · edificios {len(l['edificios'])}/{len(EDIFICIOS)}")


if __name__ == '__main__':
    l = _carga()
    if len(sys.argv) > 1 and sys.argv[1] == 'estado':
        estado(l); sys.exit()
    P.iniciar()
    _log(P.llamar('get_balance').splitlines()[1])
    personajes(l)
    suelos(l)
    objetos(l, 'muebles', MUEBLES, lambda d: (d, 32, 32))
    objetos(l, 'vehiculos', VEHICULOS, lambda v: (v[0] + ', facing right, straight top-down view', _lienzo(v[1]), _lienzo(v[2])))
    objetos(l, 'edificios', EDIFICIOS, lambda d: (d, 128, 128))
    animaciones(l)
    bajar(l)
    estado(l)
    _log(P.llamar('get_balance').splitlines()[1])
