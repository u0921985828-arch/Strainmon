#!/usr/bin/env python3
"""Los singulares de Bilbo City tal como estaban en 1996, generados con PixelLab.

Las descripciones salen de dos sitios: las notas de `PLANO_SINGULAR` del propio juego
(medidas y rasgos) y lo contrastado por internet sobre cada edificio real (fuentes en
`docs/referencias-singulares.md`). Nada de fotos de terceros entra ni como referencia de
imagen: la única referencia de imagen posible es el dibujo en planta del propio juego.

Uso:  edificios96.py [mapa|pro <nombre>|bajar|estado]
  mapa   → `create_map_object` (1 generación cada uno) con vista cenital alta.
  pro    → `create_image_pro` (20-40 generaciones) con el dibujo del juego como referencia
           de huella; para los que `mapa` no respeta la planta.
  bajar  → descarga los PNG a dist/pixellab/edificios96/.
Manifiesto propio (dist/pixellab/edificios96.json) para no pisar el de lote.py.
"""
import base64, json, os, sys, time
sys.path.insert(0, os.path.dirname(__file__))
import pixellab_mcp as P

RAIZ = os.path.join(os.path.dirname(__file__), '..', '..')
DIST = os.path.join(RAIZ, 'dist', 'pixellab')
MANIFIESTO = os.path.join(DIST, 'edificios96.json')
JUEGO = os.path.join(DIST, 'singulares-juego')     # los dibujos del propio juego (singulares.js)

VISTA = 'straight top-down roof plan seen from directly above, no perspective, no facade'

# nombre -> (descripción en inglés para el generador, ancho, alto). Las medidas en metros
# son las reales; el lienzo guarda la proporción de la huella.
EDIFICIOS = {
 'sanmames': ("old 1990s football stadium, rectangular bowl 175 by 145 metres: green grass "
   "pitch with mowing stripes and white lines in the centre, four grey concrete stands joined "
   "at the corners, the long west main stand and east stand covered by flat grey roofs, the two "
   "short end stands uncovered showing rows of red seats, one huge white steel arch spanning the "
   "whole length of the main stand roof, four floodlight pylons at the corners, concrete esplanade "
   "around", 176, 144),
 'arriaga': ("neo-baroque opera theatre of 1890, 60 by 45 metres: horseshoe auditorium under a "
   "dark slate mansard roof, two polygonal corner towers with slate domes flanking the main "
   "facade, a central pediment with a clock, a taller rectangular stage house box at the back, "
   "iron and glass entrance canopy along the front, cream sandstone walls", 128, 96),
 'ayto': ("eclectic city hall of 1892, 78 by 45 metres: symmetrical rectangular block, a tall "
   "square clock tower with a slate spire on the central axis of the front facade, two lateral "
   "pavilions with slate mansard roofs and small corner cupolas, inner light wells, ochre "
   "sandstone walls with white stone trim, formal entrance stairs facing a riverside quay",
   160, 96),
 'abando': ("monumental 1948 classicist railway terminus, 180 by 80 metres: a U-shaped "
   "five-storey pale stone head building at the front, behind it a long semicircular barrel "
   "vault train shed of grey steel on lattice arches with a glazed ridge skylight, a huge "
   "stained glass window on the shed end wall above the entrance, platforms and railway tracks "
   "fanning out from the open back of the shed", 224, 96),
 'catedral': ("gothic cathedral of the 14th century, 62 by 32 metres: latin cross with a long "
   "nave, short transept, polygonal apse with ambulatory, grey stone roofs with buttresses, a "
   "single square tower with a tall neo-gothic spire at the west front, a small square cloister "
   "attached to the south side, dark grey sandstone, hemmed in by narrow old town streets",
   128, 64),
 'begonia': ("hilltop basilica, 60 by 28 metres: long three-nave church with a polygonal apse "
   "at the east end, brown clay tile pitched roofs, a single tall square neo-gothic bell tower "
   "with a pointed spire at the west facade, grey stone walls, paved plaza in front", 128, 64),
 'merca': ("1929 riverside covered market hall, 130 by 40 metres: long rectangular cream "
   "rendered building with large round arched windows on the long sides, flat roof broken by "
   "rows of sawtooth skylights with north facing glass, small corner pavilions, quay along one "
   "long side", 208, 64),
 'alhondiga': ("1909 municipal wine warehouse, abandoned in 1996, 76 by 76 metres: square block "
   "filling a whole city block, red brick and grey reinforced concrete facades with a decorative "
   "cornice, four small corner turrets with a military look, flat dark roof with three inner "
   "open courtyards side by side, weathered and partly boarded up", 128, 128),
 'almacenes': ("1990s department store on a city avenue, 100 by 62 metres: massive rectangular "
   "concrete block, flat grey roof crowded with two rows of air conditioning units and "
   "ventilation ducts, a long mustard yellow sign band running along the street edge, dark "
   "entrance canopy along the avenue", 160, 96),
 'obraGuggen': ("1996 construction site of a titanium clad museum by a river, 150 by 110 "
   "metres: curved steel skeleton of twisted volumes rising from concrete slabs, two tall tower "
   "cranes with long jibs, stacks of titanium panels, site huts, fenced perimeter, muddy ground "
   "with truck tracks, a half built tower next to a road bridge, river quay along one side",
   176, 128),
}
ESTILO = dict(view='high top-down', outline='selective outline', shading='basic shading',
              detail='medium detail')


def _carga():
    try:
        with open(MANIFIESTO) as f:
            return json.load(f)
    except FileNotFoundError:
        return {'mapa': {}, 'pro': {}}


def _guarda(m):
    """Funde con lo que haya en disco: `mapa` y `pro` pueden correr a la vez."""
    os.makedirs(DIST, exist_ok=True)
    disco = _carga()
    for k in ('mapa', 'pro'):
        disco.setdefault(k, {}).update(m.get(k, {}))
    m.clear(); m.update(disco)
    with open(MANIFIESTO, 'w') as f:
        json.dump(m, f, indent=1)


def _llamar_paciente(nombre, args, intentos=12):
    """Reintenta con 'rate limit' y 'job slots', que el cliente devuelve como texto sin isError."""
    for i in range(intentos):
        try:
            t = P.llamar(nombre, args)
        except RuntimeError as e:          # el cliente lanza cuando el servidor marca isError
            t = str(e)
            if 'rate limit' not in t and 'job slots' not in t:
                raise
        if 'rate limit' in t or 'job slots' in t:
            time.sleep(20 + 10 * i); continue
        return t
    raise RuntimeError('sin hueco tras %d intentos: %s' % (intentos, t[:120]))


def mapa(solo=None):
    m = _carga()
    for nombre, (desc, w, h) in EDIFICIOS.items():
        if nombre in m['mapa'] or (solo and nombre != solo):
            continue
        t = _llamar_paciente('create_map_object', dict(description=desc + ', ' + VISTA,
                                                       width=w, height=h, **ESTILO))
        m['mapa'][nombre] = P._id(t); _guarda(m)
        print(time.strftime('%H:%M:%S'), 'mapa', nombre, m['mapa'][nombre], flush=True)
        time.sleep(8)


def pro(nombre):
    """create_image_pro con el dibujo del juego como referencia de huella (20-40 generaciones)."""
    m = _carga()
    desc, w, h = EDIFICIOS[nombre]
    with open(os.path.join(JUEGO, nombre + '.png'), 'rb') as f:
        b64 = base64.b64encode(f.read()).decode()
    args = dict(description='pixel art, ' + desc + ', ' + VISTA + ', same footprint and layout as the reference plan',
                width=w, height=h, no_background=False,
                reference_images=[{'base64': b64, 'usage': 'building footprint plan, keep its outline and layout'}])
    t = _llamar_paciente('create_image_pro', args)
    m['pro'][nombre] = t.split('job_id: ')[1].split()[0] if 'job_id: ' in t else P._id(t)
    _guarda(m)
    print(time.strftime('%H:%M:%S'), 'pro', nombre, m['pro'][nombre], t[:200], flush=True)


def bajar():
    m = _carga()
    dest = os.path.join(DIST, 'edificios96'); os.makedirs(dest, exist_ok=True)
    for nombre, oid in m['mapa'].items():
        f = os.path.join(dest, nombre + '.png')
        if os.path.exists(f):
            continue
        try:
            P.bajar(P.URL + '/map-objects/%s/download' % oid, f); print('bajado', nombre)
        except Exception as e:
            print('pendiente', nombre, e)
    for nombre, jid in m['pro'].items():          # pro devuelve cuatro variantes por trabajo
        for i in range(4):
            f = os.path.join(dest, '%s-pro%d.png' % (nombre, i))
            if os.path.exists(f):
                continue
            try:
                P.bajar(P.URL + '/images/%s/download?index=%d' % (jid, i), f); print('bajado', nombre, i)
            except Exception as e:
                print('pendiente', nombre, i, e); break


if __name__ == '__main__':
    P.iniciar()
    orden = sys.argv[1] if len(sys.argv) > 1 else 'mapa'
    if orden == 'mapa':
        mapa(sys.argv[2] if len(sys.argv) > 2 else None)
    elif orden == 'pro':
        pro(sys.argv[2])
    elif orden == 'bajar':
        bajar()
    elif orden == 'estado':
        print(json.dumps(_carga(), indent=1))
