# -*- coding: utf-8 -*-
"""Cliente del MCP de PixelLab, y traída de arte al formato del juego.

Por qué esto y no `pixellab.py`
-------------------------------
`pixellab.py` habla con la API v1 a pelo: un extremo, texto -> imagen, y 385 llamadas
para vestir el juego. Sigue sirviendo, pero se le quedó corto por dos sitios:

* la API v1 **rechaza lienzos de menos de 32x32 de área** (24x32 son 768 px y devuelve
  422), que es justo la celda del juego;
* y por debajo del MCP hay 110 herramientas que la v1 no expone: personajes con ocho
  rotaciones y animaciones de plantilla, tilesets Wang cenitales con autotileado por
  esquinas, juegos de camino, objetos de mapa con fondo transparente y mapas enteros.

Un personaje con `create_character` cuesta **una** generación y trae las ocho
direcciones; cada animación de plantilla cuesta una por dirección. Contra las 55
llamadas por silueta de antes, es otro orden de magnitud.

Qué respeta del proyecto
------------------------
* **No entra un PNG en el repositorio.** Lo que se guarda es índice de paleta por píxel,
  comprimido, igual que la trama de la ciudad.
* **Los 61 colores mandan.** Todo pasa por `cuantizar`, que es el mismo criterio de
  cercanía que usa el juego.
* Los personajes se piden con los **colores de plantilla** de `pixellab.py` (magenta el
  torso, verde las piernas, cian el calzado, azul el pelo, tez natural), para que el
  repintado por índices siga valiendo y una silueta siga vistiendo a treinta y cuatro.

Uso
---
    export PIXELLAB_API_KEY=...
    python3 herramientas/sprites/pixellab_mcp.py saldo
    python3 herramientas/sprites/pixellab_mcp.py herramientas          # las 110, por nombre
    python3 herramientas/sprites/pixellab_mcp.py llamar get_character '{"character_id":"..."}'
    python3 herramientas/sprites/pixellab_mcp.py muestra salida/       # el lote de prueba

Dos cosas de la casa que cuestan una tarde si no se saben:

* **`backblaze.pixellab.ai` está cortado** desde este entorno (403 del proxy). Las
  descargas van por `api.pixellab.ai/mcp/...`, que sirve lo mismo: `/spritesheet` para
  personajes, `/tilesets/<id>/image?inline=true`, `/map-objects/<id>/download`.
* **Ocho trabajos a la vez por cuenta.** Si la cuenta ya está generando, `animate_character`
  contesta «need 8 job slots» y no encola nada. `esperar()` no lo arregla: hay que mirar
  `list_jobs` antes de pedir ocho direcciones de golpe.
"""
import json, os, sys, time, urllib.error, urllib.request

URL = os.environ.get('PIXELLAB_MCP', 'https://api.pixellab.ai/mcp')
_ses = {'id': None}


def _clave():
    k = os.environ.get('PIXELLAB_API_KEY', '')
    if not k:
        raise SystemExit('falta PIXELLAB_API_KEY en el entorno (nunca en el repositorio)')
    return k


def _post(cuerpo, intentos=4):
    """El servidor corta la conexión de vez en cuando; se reintenta con espera creciente."""
    cab = {'Content-Type': 'application/json',
           'Accept': 'application/json, text/event-stream',
           'Authorization': 'Bearer ' + _clave()}
    if _ses['id']:
        cab['Mcp-Session-Id'] = _ses['id']
    for n in range(intentos):
        try:
            req = urllib.request.Request(URL, json.dumps(cuerpo).encode(), cab)
            with urllib.request.urlopen(req, timeout=600) as r:
                sid = r.headers.get('Mcp-Session-Id')
                if sid:
                    _ses['id'] = sid
                crudo = r.read().decode()
            break
        except (urllib.error.URLError, ConnectionError):
            if n == intentos - 1:
                raise
            time.sleep(2 ** n)
    for linea in crudo.splitlines():                 # respuesta en SSE: «data: {...}»
        linea = linea.strip()
        if linea.startswith('data: '):
            linea = linea[6:]
        if linea.startswith('{'):
            d = json.loads(linea)
            if 'result' in d or 'error' in d:
                return d
    return {}


def iniciar():
    _post({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize',
           'params': {'protocolVersion': '2025-06-18', 'capabilities': {},
                      'clientInfo': {'name': 'bilbo-city', 'version': '1'}}})
    _post({'jsonrpc': '2.0', 'method': 'notifications/initialized'})


def llamar(nombre, args=None):
    """Llama una herramienta y devuelve su texto. Un error del servidor es una excepción."""
    d = _post({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/call',
               'params': {'name': nombre, 'arguments': args or {}}})
    r = d.get('result', {})
    t = '\n'.join(c.get('text', '') for c in r.get('content', []) if c.get('type') == 'text')
    if r.get('isError') or 'error' in d:
        raise RuntimeError(nombre + ': ' + (t or json.dumps(d)[:300]))
    return t


def herramientas():
    d = _post({'jsonrpc': '2.0', 'id': 3, 'method': 'tools/list'})
    return [(t['name'], (t.get('description') or '').split('\n')[0])
            for t in d.get('result', {}).get('tools', [])]


def bajar(url, destino, intentos=4):
    """Descarga con reintento: el proxy corta conexiones de vez en cuando (reset by peer).
    Un 423 (todavía procesando) o un 404 se devuelven al llamante sin reintentar."""
    req = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + _clave()})
    for i in range(intentos):
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                datos = r.read()
            break
        except urllib.error.HTTPError:
            raise
        except (urllib.error.URLError, ConnectionError, TimeoutError):
            if i == intentos - 1:
                raise
            time.sleep(2 ** (i + 1))
    os.makedirs(os.path.dirname(destino) or '.', exist_ok=True)
    open(destino, 'wb').write(datos)
    return len(datos)


def esperar(vueltas=12):
    """Espera a que la cuenta se quede sin trabajos. Devuelve lo último que contó."""
    for _ in range(vueltas):
        t = llamar('wait_for_jobs')
        if 'nothing else is running' in t or '0 still running' in t:
            return t
    return t


# ── al formato del juego ────────────────────────────────────────────────────────────
def cuantizar(im, pal):
    """Cada píxel al más cercano de los 61; lo transparente se queda transparente."""
    im = im.convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                px[x, y] = (0, 0, 0, 0)
                continue
            c = min(pal, key=lambda c: (c[0]-r)**2 + (c[1]-g)**2 + (c[2]-b)**2)
            px[x, y] = (c[0], c[1], c[2], 255)
    return im


def indices(im, pal):
    """La imagen como índices de paleta, 0 = transparente, el resto índice+1."""
    im = im.convert('RGBA')
    px = im.load()
    orden = {c: i + 1 for i, c in enumerate(pal)}
    return [0 if px[x, y][3] < 128 else orden[px[x, y][:3]]
            for y in range(im.height) for x in range(im.width)]


MUESTRA_MUEBLES = [
    ('farola',     'cast iron street lamp post, spanish city, seen from above'),
    ('contenedor', 'green wheeled rubbish container, closed lid, seen from above'),
    ('banco',      'wooden and iron public bench, seen from above'),
    ('cabina',     'blue public telephone booth, 1990s, seen from above'),
    ('papelera',   'small metal litter bin on a post, seen from above'),
    ('arbol',      'london plane street tree with round canopy, seen from above'),
]


def muestra(salida):
    """El lote de prueba: una silueta, un tileset de calle y seis muebles urbanos."""
    iniciar()
    print(llamar('get_balance').splitlines()[1])
    ids = {}
    ids['personaje'] = _id(llamar('create_character', {
        'description': ('plain standing person, vivid magenta jacket, vivid green trousers, '
                        'vivid cyan shoes, short vivid blue hair, plain tan skin, no accessories'),
        'name': 'Silueta chaqueta-pantalon', 'body_type': 'humanoid', 'mode': 'standard',
        'n_directions': 8, 'size': 32, 'view': 'low top-down',
        'outline': 'single color black outline', 'shading': 'flat shading',
        'detail': 'low detail'}))
    ids['tileset'] = _id(llamar('create_topdown_tileset', {
        'lower_description': 'dark grey worn asphalt road, 1990s spanish city street',
        'upper_description': 'light grey concrete pavement slabs with granite kerb',
        'tile_size': {'width': 32, 'height': 32}, 'mode': 'standard', 'view': 'low top-down',
        'outline': 'selective outline', 'shading': 'basic shading', 'detail': 'low detail',
        'transition_size': 0.2, 'transition_description': 'granite kerb stone edge'}))
    for nom, desc in MUESTRA_MUEBLES:
        ids[nom] = _id(llamar('create_map_object', {
            'description': desc, 'width': 32, 'height': 32, 'view': 'low top-down',
            'outline': 'selective outline', 'shading': 'basic shading', 'detail': 'low detail'}))
    esperar()
    base = 'https://api.pixellab.ai/mcp'
    bajar(f"{base}/characters/{ids['personaje']}/spritesheet", os.path.join(salida, 'personaje.zip'))
    bajar(f"{base}/tilesets/{ids['tileset']}/image?inline=true", os.path.join(salida, 'tileset.png'))
    for nom, _ in MUESTRA_MUEBLES:
        bajar(f"{base}/map-objects/{ids[nom]}/download", os.path.join(salida, 'obj-' + nom + '.png'))
    json.dump(ids, open(os.path.join(salida, 'ids.json'), 'w'), indent=1)
    print('->', salida, len(ids), 'piezas')
    return ids


def _id(texto):
    for l in texto.splitlines():
        if l.startswith('id: '):
            return l[4:].strip()
    raise RuntimeError('la respuesta no trae id:\n' + texto[:300])


if __name__ == '__main__':
    orden = sys.argv[1] if len(sys.argv) > 1 else 'saldo'
    if orden == 'saldo':
        iniciar(); print(llamar('get_balance'))
    elif orden == 'herramientas':
        iniciar()
        for n, d in herramientas():
            print(f'{n:32} {d[:80]}')
    elif orden == 'llamar':
        iniciar()
        print(llamar(sys.argv[2], json.loads(sys.argv[3]) if len(sys.argv) > 3 else {}))
    elif orden == 'muestra':
        muestra(sys.argv[2] if len(sys.argv) > 2 else 'muestra-pixellab')
    else:
        raise SystemExit(__doc__)
