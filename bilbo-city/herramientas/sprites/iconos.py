# -*- coding: utf-8 -*-
"""Los cuarenta y tres iconos del HUD, pedidos a PixelLab.

Por qué
-------
Los iconos eran lo último que quedaba forjado a mano en la interfaz: cuarenta y tres
dibujos de rectángulos de `generarIconos()`. A 24 píxeles un rectángulo se lee, pero no
dice qué es: el puño parecía una caja, el pintxo una tostada y el plato una moneda. Un
icono tiene que entenderse sin leyenda y de un vistazo, que para eso está.

Qué pide
--------
Una generación por icono con `create_image_pixflux` a 96x96 —el generador no trabaja a
24, y bajar de 96 a 24 por mayoría sale más limpio que pedir 24 directamente—, con
`no_background` y con los **61 colores forzados** por `color_image_base64`: una tira de
61x1 con la paleta del juego, escalada, que el generador lee como paleta obligada. Así lo
que vuelve ya está casi en casa y el redondeo al color más cercano casi no mueve nada.

Dos no se piden, se derivan, porque son **la otra mitad de una pareja** y una pareja
tiene que leerse como pareja:

* `estrellaOff` es `estrella` en gris: son las cinco estrellas de busca y se miran juntas.
* `ojoTachado` es `ojo` apagado y con el tachón encima: si fueran dos dibujos distintos,
  al cambiar de estado parecería que cambia el icono, no el estado.

Lo que respeta
--------------
* **No entra un PNG en el repositorio.** Esto baja a `dist/pixellab/iconos/`, que no se
  versiona. Quien los mete en el juego es `arte.py`, y lo que escribe es índice de paleta.
* **Reanudable**: lo pedido queda en `dist/pixellab/iconos/iconos.json` con su id. Si se
  corta a mitad, se relanza y sigue; nada se pide dos veces.

    export PIXELLAB_API_KEY=...
    python3 herramientas/sprites/iconos.py            # lo que falte
    python3 herramientas/sprites/iconos.py estado     # cuánto hay y cuánto queda
    python3 herramientas/sprites/iconos.py --rehacer pintxo,plato   # repetir alguno
"""
import base64, io, json, os, re, sys, time

sys.path.insert(0, os.path.dirname(__file__))
import pixellab_mcp as P
import pixellab as PL

RAIZ = PL.RAIZ
SALIDA = os.path.join(RAIZ, 'dist', 'pixellab', 'iconos')
ESTADO = os.path.join(SALIDA, 'iconos.json')
LADO = 96        # a lo que genera PixelLab
DESTINO = 24     # y a lo que vive en el juego; lo lee arte.py al traerlos
SEMILLA = 1996
HUECOS = 8

# El rabo que lleva cada petición. El estilo no se negocia por icono: o van los cuarenta
# y tres iguales o el HUD parece una bolsa de cromos.
ESTILO = (', single centred object, flat colour game HUD icon, '
          'thick black outline, plain, no text, no letters, no background')

# Qué es cada icono, dicho en una línea. El orden es el de `generarIconos()` en el juego.
DESCRIPCIONES = {
    # armas
    'punos':        'a pair of clenched bare fists raised to fight, three-quarter view',
    'bate':         'a wooden baseball bat with a taped grip, held diagonally',
    'pistola':      'a black semi-automatic handgun pointing right, side view',
    'uzi':          'a compact black submachine gun with a long magazine and silver bolt, side view',
    'escopeta':     'a pump action shotgun, thick grey barrel and brown wooden stock, horizontal',
    # un curro, un icono
    'reparto':      'a red delivery scooter with a cargo box on the back, side view',
    'lonja':        'a wooden fish market crate full of silvery fish',
    'taxi':         'a yellow taxi roof sign lamp box with a black base, front view',
    'obra':         'a yellow construction hard hat',
    'puerto':       'a tall red harbour gantry crane with a hanging hook, container port',
    'mudanza':      'a brown cardboard moving box sealed with packing tape',
    'recado':       'a brown paper errand bag with a rolled top',
    'fuga':         'a green running man emergency exit figure, side view',
    'llaveInglesa': 'a steel adjustable wrench lying diagonally',
    'furgo':        'a white delivery van, side view',
    'deportivo':    'a red sports car, side view',
    # marcas de la interfaz
    'diana':        'a red and white shooting target with a crosshair',
    'aviso':        'a yellow warning triangle with an exclamation mark',
    'meta':         'a black and white chequered finish flag on a pole',
    'libro':        'an open hardback book with red covers',
    'contrato':     'a signed paper contract held on a clipboard',
    'llave':        'a golden door key lying horizontally',
    'prohibido':    'a red circular no-entry sign with a white diagonal bar',
    'movil':        'a 1990s mobile phone with a blue screen, front view',
    # consumibles
    'pintxo':       'a slice of bread with topping pinned by a cocktail stick, basque pintxo',
    'botellin':     'a small green glass beer bottle with a paper label',
    'botiquin':     'a white first aid kit case with a red cross',
    'ojo':          'a big almond shaped eye, white sclera, round blue iris and black pupil, front view',
    'camisa':       'a light blue buttoned shirt laid flat',
    'pantalon':     'a pair of dark blue jeans laid flat',
    'zapato':       'a brown leather shoe, side view',
    'gorra':        'a red baseball cap, side view',
    'bus':          'a red city bus, side view',
    'metro':        'the front of a red metro train, two big windows and two headlights, front view',
    'tren':         'a green diesel train locomotive, side view',
    'plato':        'a round white dinner plate with a fried egg and two sausages, seen from above',
    'cargador':     'a black power bank battery brick with a green charge light, front view',
    # HUD
    'estrella':     'a solid five-pointed star, bright orange red',
    'euro':         'a golden euro currency symbol',
    'energia':      'a blue lightning bolt',
    'hambre':       'a fork and a spoon side by side, cutlery',
}
# Los que no se piden: se sacan de su pareja al traerlos (lo hace arte.py).
DERIVADOS = {'estrellaOff': 'estrella', 'ojoTachado': 'ojo'}
TODOS = list(DESCRIPCIONES) + list(DERIVADOS)


def tira_paleta():
    """Los 61 colores en un PNG, que es como se fuerza la paleta en el generador."""
    from PIL import Image
    cols, _ = PL.paleta()
    im = Image.new('RGB', (len(cols), 1))
    im.putdata([tuple(c) for c in cols])
    im = im.resize((len(cols) * 4, 4), Image.NEAREST)
    b = io.BytesIO()
    im.save(b, 'PNG')
    return base64.b64encode(b.getvalue()).decode()


def _estado():
    if os.path.exists(ESTADO):
        return json.load(open(ESTADO, encoding='utf-8'))
    return {}


def _guardar(e):
    os.makedirs(SALIDA, exist_ok=True)
    json.dump(e, open(ESTADO, 'w', encoding='utf-8'), indent=1, sort_keys=True)


def _url(texto):
    """De lo que contesta la herramienta, el enlace a la imagen."""
    m = re.search(r'https?://\S+?/download', texto) or re.search(r'https?://\S+?\.png', texto)
    return m.group(0).rstrip(').,') if m else None


def _job(texto):
    m = re.search(r'job_id:\s*(\S+)', texto)
    return m.group(1) if m else None


def encargar(k, pal, estado):
    """Pide la generación y apunta el trabajo. No espera: la cuenta admite varios a la vez."""
    t = P.llamar('create_image_pixflux', {
        'description': DESCRIPCIONES[k] + ESTILO,
        'width': LADO, 'height': LADO, 'no_background': True,
        'outline': 'single color black outline', 'shading': 'flat shading',
        'detail': 'low detail', 'color_image_base64': pal, 'seed': SEMILLA})
    j = _job(t)
    if not j:
        raise SystemExit('%s: la respuesta no trae job_id:\n%s' % (k, t[:600]))
    estado[k] = {'ok': False, 'job': j}
    _guardar(estado)
    return j


def recoger(k, estado, vueltas=40):
    """Espera a que el trabajo acabe y baja el PNG. Devuelve los bytes bajados."""
    destino = os.path.join(SALIDA, k + '.png')
    job = estado[k]['job']
    for _ in range(vueltas):
        t = P.llamar('get_image', {'job_id': job})
        if not t.startswith('status: processing'):
            break
        time.sleep(5)
    else:
        raise SystemExit('%s (%s) no termina' % (k, job))
    u = _url(t) or (P.URL + '/images/' + job + '/download')
    n = P.bajar(u, destino)
    estado[k] = {'ok': True, 'job': job, 'bytes': n}
    _guardar(estado)
    return n


def main():
    global SEMILLA
    rehacer = set()
    args = sys.argv[1:]
    while args and args[0].startswith('--'):
        if args[0] == '--rehacer':
            rehacer = set(args[1].split(','))
        elif args[0] == '--semilla':
            SEMILLA = int(args[1])      # otra semilla es otro dibujo del mismo encargo
        else:
            raise SystemExit('no s\u00e9 qu\u00e9 es ' + args[0])
        args = args[2:]
    estado = _estado()
    if args and args[0] == 'estado':
        hay = [k for k in DESCRIPCIONES if os.path.exists(os.path.join(SALIDA, k + '.png'))]
        print('%d de %d pedidos, %d derivados, faltan %d: %s'
              % (len(hay), len(DESCRIPCIONES), len(DERIVADOS),
                 len(DESCRIPCIONES) - len(hay),
                 ' '.join(k for k in DESCRIPCIONES if k not in hay) or '—'))
        return
    for k in rehacer:
        estado.pop(k, None)
        p = os.path.join(SALIDA, k + '.png')
        if os.path.exists(p):
            os.remove(p)
    P.iniciar()
    pal = tira_paleta()
    falta = [k for k in DESCRIPCIONES
             if not (os.path.exists(os.path.join(SALIDA, k + '.png')) and estado.get(k, {}).get('ok'))]
    print('%d iconos por pedir' % len(falta), flush=True)
    # De ocho en ocho: es lo que admite la cuenta a la vez, y pedir de uno en uno
    # esperando los treinta segundos de cada uno son veinte minutos de nada.
    for t0 in range(0, len(falta), HUECOS):
        tanda = falta[t0:t0 + HUECOS]
        for k in tanda:
            if not estado.get(k, {}).get('job'):
                encargar(k, pal, estado)
        for k in tanda:
            n = recoger(k, estado)
            print('  %-14s %d B' % (k, n), flush=True)
    print('listo: %s' % SALIDA)


if __name__ == '__main__':
    main()
