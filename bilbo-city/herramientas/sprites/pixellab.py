# -*- coding: utf-8 -*-
"""
Trae los sprites del juego desde la API de PixelLab y los deja listos para jugar.

Cómo encaja
-----------
El juego forja su arte por código. Esto no lo sustituye: lo adelanta. Lo que baje de
PixelLab se cuantiza a los 48 colores de la paleta, se empaqueta en la hoja que el juego
ya sabe leer —8 direcciones × 14 poses— y se escribe en el bloque SPRITES del HTML. Un
arquetipo que no esté en la hoja se sigue forjando por código, así que nunca se queda un
personaje sin dibujar y se puede traer de dos en dos.

No entran PNG en el repositorio: la hoja va como un índice de paleta por píxel,
comprimida y en base64, igual que la trama de la ciudad. El archivo del juego sigue
siendo uno solo y el arte sigue atado a la paleta.

Uso
---
    export PIXELLAB_API_KEY=...
    python3 herramientas/sprites/pixellab.py --que protagonista,ertzaina
    python3 herramientas/sprites/pixellab.py --simular          # sin red ni clave

`--simular` no llama a nadie: dibuja siluetas de relleno con el mismo tamaño y el mismo
recorrido, y sirve para comprobar que empaquetado, compresión, escritura y carga en el
juego funcionan antes de gastar una sola llamada.

Todo lo que baja se guarda en `cache/`, que no va al repositorio: repetir una tirada no
vuelve a pagarla, y cambiar solo el empaquetado no cuesta nada.

Aviso sobre la API
------------------
Los nombres de los extremos y de los campos están todos en API_* aquí abajo, en un solo
sitio, porque son lo único que puede haber cambiado desde que se escribió esto. Si la
llamada devuelve algo inesperado, el error trae el cuerpo entero de la respuesta: es más
rápido leerlo que adivinar.
"""
import argparse, base64, json, os, re, sys, time, urllib.error, urllib.request, zlib

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
HTML = os.path.join(RAIZ, 'referencia', 'bilbo-city.html')
CACHE = os.path.join(os.path.dirname(__file__), 'cache')

# ── la API ──────────────────────────────────────────────────────────────────────────
API_BASE      = os.environ.get('PIXELLAB_API_BASE', 'https://api.pixellab.ai/v1')
API_GENERAR   = '/generate-image-pixflux'      # texto -> pixel art
API_GIRAR     = '/rotate'                      # una vista -> otra vista
API_SALDO     = '/balance'
CAMPO_IMAGEN  = 'image'                        # respuesta: {"image": {"base64": "..."}}

# ── qué se pide ─────────────────────────────────────────────────────────────────────
# El juego dibuja desde arriba y algo escorado, así que la vista es cenital alta. Las
# descripciones van en inglés porque es lo que entiende el modelo; los nombres, no.
VISTA = 'high top-down'
ESTILO = ('16-bit pixel art sprite, top-down GTA-style, dark muted 1990s Bilbao, '
          'flat shading, black outline, transparent background')

PERSONAJES = {
    'protagonista': 'young man, black leather jacket, jeans, basque txapela beret, boots',
    'ertzaina':     'basque police officer, red beret, dark blue uniform, utility belt',
    'maton':        'heavy set thug, bomber jacket, black cap, tracksuit trousers',
    'maton2':       'skinny thug, grey hoodie up, tracksuit, trainers',
}

# Las ocho direcciones del juego, en su orden: 0 es sur y se gira en sentido antihorario.
DIRECCIONES = ['south', 'south-east', 'east', 'north-east',
               'north', 'north-west', 'west', 'south-west']
# Las catorce poses, en el orden en que el juego las apila en la hoja.
POSES = ['quieto', 'andar1', 'andar2', 'andar3', 'andar4',
         'correr1', 'correr2', 'correr3', 'correr4',
         'pega1', 'pega2', 'apunta', 'dispara', 'herido']
ACCION = {
    'quieto': 'standing still', 'andar': 'walking', 'correr': 'running',
    'pega': 'punching forward', 'apunta': 'aiming a pistol',
    'dispara': 'firing a pistol', 'herido': 'staggering, hurt',
}


def _celda_forja():
    """La celda que usa la forja del juego, leída del propio juego.

    No se pone a mano. La forja dibuja la figura en una caja de 20×26 y le deja un margen
    alrededor para el puñetazo, el fogonazo, los gorros altos y el contorno; si la hoja
    traída viniera más pequeña que esa celda, el juego recortaría los arquetipos que sí
    forja y nadie ataría cabos.
    """
    s = open(HTML, encoding='utf-8').read()
    m = re.search(r'const MG_X=(\d+), MG_ARR=(\d+), MG_ABA=(\d+);', s)
    if not m:
        raise SystemExit('no encuentro los márgenes de la forja en el HTML')
    mx, arr, aba = (int(g) for g in m.groups())
    return 20 + mx * 2, 26 + arr + aba


CEL_W, CEL_H = _celda_forja()  # medida de cada casilla de la hoja


def paleta():
    """Los 48 colores del juego, leídos del propio juego."""
    s = open(HTML, encoding='utf-8').read()
    i = s.index('const C={')
    bloque = s[i:s.index('};', i)]
    vistos, fuera = set(), []
    for h in re.findall(r"'(#[0-9a-fA-F]{6})'", bloque):
        if h.lower() in vistos:
            continue
        vistos.add(h.lower())
        fuera.append((int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)))
    return fuera


def _pedir(ruta, cuerpo, clave):
    pet = urllib.request.Request(
        API_BASE + ruta, data=json.dumps(cuerpo).encode(),
        headers={'Content-Type': 'application/json', 'Authorization': 'Bearer ' + clave})
    try:
        with urllib.request.urlopen(pet, timeout=180) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        detalle = e.read().decode('utf8', 'replace')[:2000]
        raise SystemExit(f'PixelLab respondió {e.code} a {ruta}:\n{detalle}')
    except urllib.error.URLError as e:
        raise SystemExit(f'no se llega a {API_BASE}{ruta}: {e.reason}\n'
                         '¿Hay salida a internet desde aquí? En el contenedor de Claude '
                         'suele estar cerrada; se ejecuta en local.')


def _imagen(resp):
    v = resp.get(CAMPO_IMAGEN)
    if isinstance(v, dict):
        v = v.get('base64') or v.get('data')
    if not isinstance(v, str):
        raise SystemExit('la respuesta no trae imagen donde se esperaba. Cuerpo:\n'
                         + json.dumps(resp)[:2000])
    return base64.b64decode(re.sub(r'^data:[^,]+,', '', v))


def genera(desc, direccion, accion, clave, simular):
    """Un PNG de un personaje mirando a una dirección y haciendo algo."""
    etiqueta = f'{desc}|{direccion}|{accion}|{CEL_W}x{CEL_H}'
    nombre = os.path.join(CACHE, re.sub(r'\W+', '_', etiqueta)[:120] + '.png')
    if os.path.exists(nombre):
        return open(nombre, 'rb').read()
    if simular:
        datos = _silueta(direccion, accion)
    else:
        resp = _pedir(API_GENERAR, {
            'description': f'{desc}, {accion}, {ESTILO}',
            'image_size': {'width': CEL_W, 'height': CEL_H},
            'view': VISTA, 'direction': direccion,
            'no_background': True, 'outline': 'single color black outline',
        }, clave)
        datos = _imagen(resp)
    os.makedirs(CACHE, exist_ok=True)
    open(nombre, 'wb').write(datos)
    return datos


def _silueta(direccion, accion):
    """Un monigote de relleno para --simular: no vale para jugar, vale para probar."""
    from PIL import Image, ImageDraw
    im = Image.new('RGBA', (CEL_W, CEL_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tono = (60 + 12 * DIRECCIONES.index(direccion), 90, 120, 255)
    cx, base = CEL_W // 2, CEL_H - 4      # los pies, donde los pone la forja
    paso = 2 if 'walk' in accion or 'run' in accion else 0
    d.rectangle([cx - 4, base - 16, cx + 4, base - 4], fill=tono)          # torso
    d.ellipse([cx - 4, base - 24, cx + 4, base - 16], fill=(230, 200, 170, 255))
    d.rectangle([cx - 3 - paso, base - 4, cx - 1 - paso, base], fill=(40, 40, 50, 255))
    d.rectangle([cx + 1 + paso, base - 4, cx + 3 + paso, base], fill=(40, 40, 50, 255))
    return _png(im)


def _png(im):
    import io
    b = io.BytesIO()
    im.save(b, 'PNG')
    return b.getvalue()


def a_indices(png, pal):
    """PNG -> un byte por píxel: 0 transparente, y si no el color de paleta más cercano."""
    from PIL import Image
    import io
    im = Image.open(io.BytesIO(png)).convert('RGBA')
    if im.size != (CEL_W, CEL_H):
        im = im.resize((CEL_W, CEL_H), Image.NEAREST)
    fuera = bytearray(CEL_W * CEL_H)
    px = im.load()
    cache = {}
    for y in range(CEL_H):
        for x in range(CEL_W):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            k = (r, g, b)
            v = cache.get(k)
            if v is None:
                v = 1 + min(range(len(pal)),
                            key=lambda i: (pal[i][0]-r)**2 + (pal[i][1]-g)**2 + (pal[i][2]-b)**2)
                cache[k] = v
            fuera[y * CEL_W + x] = v
    return fuera


def hoja(nombre, desc, clave, simular, pal):
    """La hoja entera de un arquetipo: 8 columnas de dirección × 14 filas de pose."""
    ancho, alto = CEL_W * 8, CEL_H * len(POSES)
    rej = bytearray(ancho * alto)
    for fy, pose in enumerate(POSES):
        accion = ACCION[re.sub(r'\d+$', '', pose)]
        for fx, direccion in enumerate(DIRECCIONES):
            celda = a_indices(genera(desc, direccion, accion, clave, simular), pal)
            for y in range(CEL_H):
                i = (fy * CEL_H + y) * ancho + fx * CEL_W
                rej[i:i + CEL_W] = celda[y * CEL_W:(y + 1) * CEL_W]
            print(f'  {nombre:14s} {pose:8s} {direccion}', flush=True)
    return rej


def comprimir(datos):
    c = zlib.compressobj(9, zlib.DEFLATED, -15)          # deflate crudo, como la trama
    return base64.b64encode(c.compress(bytes(datos)) + c.flush()).decode()


def escribir(hojas):
    s = open(HTML, encoding='utf-8').read()
    a, b = '/*<<<SPRITES*/', '/*SPRITES>>>*/'
    i, j = s.index(a), s.index(b)
    filas = []
    for k, b64 in sorted(hojas.items()):
        trozos = ',\n'.join(f"  '{b64[t:t+108]}'" for t in range(0, len(b64), 108))
        filas.append(f" {k}: [\n{trozos}].join('')")
    cuerpo = ('/* Lo escribe herramientas/sprites/pixellab.py. Vacío = todo forjado. */\n'
              f'const SPR={{cel:[{CEL_W},{CEL_H}], hojas:{{\n' + ',\n'.join(filas) + '\n}};')
    open(HTML, 'w', encoding='utf-8').write(s[:i + len(a)] + '\n' + cuerpo + '\n' + s[j:])


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[1])
    ap.add_argument('--que', default=','.join(PERSONAJES), help='arquetipos, separados por coma')
    ap.add_argument('--clave', default=os.environ.get('PIXELLAB_API_KEY', ''))
    ap.add_argument('--simular', action='store_true', help='sin red: siluetas de relleno')
    a = ap.parse_args()
    if not a.simular and not a.clave:
        raise SystemExit('falta la clave: PIXELLAB_API_KEY o --clave')

    pal = paleta()
    quiere = [q.strip() for q in a.que.split(',') if q.strip()]
    desconocidos = [q for q in quiere if q not in PERSONAJES]
    if desconocidos:
        raise SystemExit('no sé quién es: ' + ', '.join(desconocidos))
    n = len(quiere) * len(POSES) * len(DIRECCIONES)
    print(f'{len(quiere)} arquetipos · {n} imágenes · celda {CEL_W}x{CEL_H} · '
          f'paleta de {len(pal)} colores' + (' · SIMULADO' if a.simular else ''))

    hojas = {}
    for k in quiere:
        hojas[k] = comprimir(hoja(k, PERSONAJES[k], a.clave, a.simular, pal))
    escribir(hojas)
    peso = sum(len(v) for v in hojas.values()) / 1024
    print(f'-> {HTML}  ({peso:.0f} KB de hojas)')
