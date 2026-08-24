# -*- coding: utf-8 -*-
"""
Trae de PixelLab las siluetas del juego y las deja listas para jugar.

Qué se baja, y por qué así
--------------------------
No se baja un personaje: se baja una **silueta**. Una chaqueta con pantalón, un abrigo
largo, una falda, un mono de faena. De cada silueta salen después todos los vecinos que
la comparten, porque lo que la hoja trae pintado son colores de plantilla —cada parte del
cuerpo en su propia rampa de la paleta— y el juego la repinta por índices: la chaqueta al
color de esa chaqueta, el pantalón al suyo, la piel a la suya. El pelo largo, el gorro y
la bolsa no se bajan nunca: se forjan encima, que es justo lo que multiplicaría las hojas
por setenta si viniera dibujado.

Y de cada silueta se baja menos de lo que se ve:

* **cinco direcciones de ocho.** Oeste es este del revés, y lo mismo las dos diagonales.
* **once dibujos de dieciséis poses.** Los dos pasos de apoyo del andar son el mismo
  dibujo, las dos zancadas de la carrera también, y disparar es apuntar con el fogonazo
  encima y un píxel de retroceso, que lo pone el juego.

Sale a 55 imágenes por silueta. Siete siluetas visten a los treinta y cuatro arquetipos
—385 llamadas para el juego entero— y el vecino número treinta y cinco no cuesta ninguna.
Para comparar: pedir cuatro personajes enteros, de ocho direcciones y dieciséis poses,
eran 512 llamadas y vestían a cuatro.

Uso
---
    export PIXELLAB_API_KEY=...
    python3 herramientas/sprites/pixellab.py --que largo_pantalon,abrigo_pantalon
    python3 herramientas/sprites/pixellab.py --simular          # sin red ni clave
    python3 herramientas/sprites/pixellab.py --coste            # solo la cuenta

`--simular` no llama a nadie: dibuja monigotes de relleno con los mismos colores de
plantilla y el mismo recorrido, y sirve para comprobar que el troceado, el repintado, la
compresión, la escritura y la carga en el juego funcionan antes de gastar una llamada.

Bajar una sola silueta ya es jugable: el juego busca la más parecida a la ropa de cada
arquetipo y, si no hay ninguna, lo forja como siempre. Nunca se queda nadie sin dibujar.

No entran PNG en el repositorio: la hoja va como un índice de paleta por píxel, comprimida
y en base64, igual que la trama de la ciudad.

Aviso sobre la API
------------------
Los nombres de los extremos y de los campos están todos en API_* aquí abajo, en un solo
sitio, porque son lo único que puede haber cambiado desde que se escribió esto. Si la
llamada devuelve algo inesperado, el error trae el cuerpo entero de la respuesta: es más
rápido leerlo que adivinar.
"""
import argparse, base64, json, os, re, sys, zlib

RAIZ = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
HTML = os.path.join(RAIZ, 'referencia', 'bilbo-city.html')
CACHE = os.path.join(os.path.dirname(__file__), 'cache')

# ── la API ──────────────────────────────────────────────────────────────────────────
API_BASE      = os.environ.get('PIXELLAB_API_BASE', 'https://api.pixellab.ai/v1')
API_GENERAR   = '/generate-image-pixflux'      # texto -> pixel art
API_SALDO     = '/balance'
CAMPO_IMAGEN  = 'image'                        # respuesta: {"image": {"base64": "..."}}

# ── colores de plantilla ────────────────────────────────────────────────────────────
# Cada parte del cuerpo se pide de un color que no se parece a ningún otro, y el
# empaquetado clasifica cada píxel por el más cercano en tono. No es el aspecto final: es
# un estarcido. Lo que se guarda ya va con la rampa de la paleta que le toca a esa parte,
# y el juego la repinta a los colores de cada vecino.
#
# La piel se queda natural a propósito. Pedirle a un generador una cara magenta le sale
# mal, y de todas formas un tono carne no se confunde con un magenta, un verde ni un cian.
CLAVES = {
    'piel':    ((224, 172, 128), 'natural tan skin'),
    'pelo':    ((  0,   0, 255), 'bright blue hair, short'),
    'torso':   ((255,   0, 255), 'bright magenta'),
    'piernas': ((  0, 255,   0), 'bright green'),
    'calzado': ((  0, 255, 255), 'bright cyan'),
}
# La rampa de la paleta en la que se guarda cada parte. Tienen que ser disjuntas: es lo
# que permite repintar una parte sin tocar las demás.
RAMPAS = {
    'piel':    ['piel6', 'piel5', 'piel4', 'piel3', 'piel2', 'piel1'],
    'pelo':    ['pelo1', 'pelo2', 'pelo3', 'pelo4'],
    'torso':   ['azulO', 'azul', 'azulL'],
    'piernas': ['verdeO', 'verde', 'verdeL'],
    'calzado': ['maderaO', 'madera', 'maderaL'],
    'contorno': ['negro'],
}
LUZ_CONTORNO = 46          # por debajo de esto un píxel es contorno, no color

# ── las siluetas ────────────────────────────────────────────────────────────────────
# El nombre es «lo de arriba _ lo de abajo», y el juego lo deduce igual de la ropa de cada
# arquetipo: manga larga, manga corta, abrigo o capucha; pantalón, falda o pantalón corto.
# Cambiar un nombre aquí sin cambiarlo allí deja la hoja sin usar — la batería lo mira.
SETS = {
    'largo_pantalon': 'long sleeved jacket, long trousers, ankle boots',
    'largo_falda':    'long sleeved jumper, knee length skirt, flat shoes',
    'corto_pantalon': 'short sleeved shirt, long trousers, flat shoes',
    'corto_short':    'short sleeved t-shirt, shorts, trainers',
    'abrigo_pantalon':  'long overcoat down to the knees, long trousers, flat shoes',
    'abrigo_falda':     'long open coat, knee length skirt, flat shoes',
    'capucha_pantalon': 'hooded sweatshirt with the hood down, tracksuit trousers, trainers',
}

VISTA = 'high top-down'
# La descripción es del aspecto que queremos, no de la obra de nadie. Pedirle a un
# generador el estilo de un juego con dueño es hacerle producir algo derivado de ese
# juego, y ese algo acabaría dentro del nuestro. Lo que va aquí es lo mismo que dice
# referencia/ESTILO.md, en inglés y con sus propias palabras.
ESTILO = ('16-bit pixel art sprite, high top-down view of a character, chunky proportions '
          'with a large head, flat shading, light from the upper left, single-colour black '
          'outline, transparent background, bare head, no hat, no bag, no backpack')

# Las ocho direcciones del juego, en su orden: 0 es sur y se gira en sentido antihorario.
DIRECCIONES = ['south', 'south-east', 'east', 'north-east',
               'north', 'north-west', 'west', 'south-west']
PEDIDAS = 5                                   # las cinco primeras; el resto son espejo
ESPEJO = {5: 3, 6: 2, 7: 1}                   # noroeste<-nordeste, oeste<-este, so<-se

# Los once dibujos que hay que pedir, y en cuál cae cada una de las dieciséis poses.
DIBUJOS = {
    'quieto':  'standing still',
    'andarA':  'walking, left leg forward',
    'andarP':  'walking, legs together at mid stride',
    'andarB':  'walking, right leg forward',
    'correrA': 'running fast, left leg forward, leaning ahead',
    'correrB': 'running fast, right leg forward, leaning ahead',
    'pega1':   'punching forward, arm half extended',
    'pega2':   'punching forward, arm fully extended',
    'apunta':  'aiming a pistol forward with both hands',
    'herido':  'staggering backwards, hurt',
    'agacha':  'crouching low, sneaking',
}
DE_POSE = {
    'quieto': 'quieto',
    'andar1': 'andarA', 'andar2': 'andarP', 'andar3': 'andarB', 'andar4': 'andarP',
    'correr1': 'correrA', 'correr2': 'correrB', 'correr3': 'correrA', 'correr4': 'correrB',
    'pega1': 'pega1', 'pega2': 'pega2',
    'apunta': 'apunta', 'dispara': 'apunta',
    'herido': 'herido', 'agacha': 'agacha', 'agacha2': 'agacha',
}
# Las poses que repiten dibujo no quedan clavadas: se desplazan un píxel. El retroceso del
# disparo y el balanceo del que anda agachado los pone esto, no una llamada más.
DESPLAZA = {'dispara': -1, 'agacha2': 1}


def _texto_html():
    return open(HTML, encoding='utf-8').read()


def _poses():
    """Las poses, en el orden en que el juego las apila en la hoja.

    No se ponen a mano. La lista creció al meter el sigilo —dos fotogramas de agachado— y
    una hoja con las de antes le sobran dos filas al juego: la descarta al cargarla y se
    forja todo, sin decir por qué. Se lee del juego y no puede desfasarse.
    """
    m = re.search(r'const ORDEN_POSES=\[(.*?)\];', _texto_html(), re.S)
    if not m:
        raise SystemExit('no encuentro ORDEN_POSES en el HTML')
    return re.findall(r"'([a-z0-9]+)'", m.group(1))


def _celda_forja():
    """La celda que usa la forja del juego, leída del propio juego.

    La forja dibuja la figura en una caja de 20×26 y le deja un margen alrededor para el
    puñetazo, el fogonazo, los gorros altos y el contorno; si la hoja traída viniera más
    pequeña que esa celda, el juego recortaría los arquetipos que sí forja y nadie ataría
    cabos.
    """
    m = re.search(r'const MG_X=(\d+), MG_ARR=(\d+), MG_ABA=(\d+);', _texto_html())
    if not m:
        raise SystemExit('no encuentro los márgenes de la forja en el HTML')
    mx, arr, aba = (int(g) for g in m.groups())
    return 20 + mx * 2, 26 + arr + aba


CEL_W, CEL_H = _celda_forja()
POSES = _poses()


def paleta():
    """Los 48 colores del juego con su nombre, leídos del propio juego.

    El orden y el descarte de repetidos son los mismos que hace el juego con su Set: el
    índice que se escribe en la hoja tiene que valer allí.
    """
    s = _texto_html()
    i = s.index('const C={')
    bloque = s[i:s.index('};', i)]
    fuera, por_nombre, vistos = [], {}, {}
    for nombre, h in re.findall(r"(\w+):'(#[0-9a-fA-F]{6})'", bloque):
        h = h.lower()
        if h not in vistos:
            vistos[h] = len(fuera)
            fuera.append((int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16)))
        por_nombre[nombre] = vistos[h]
    return fuera, por_nombre


def rampas(por_nombre):
    """Las rampas, en índices de hoja (el 0 es transparente, así que van +1)."""
    fuera = {}
    for parte, nombres in RAMPAS.items():
        faltan = [n for n in nombres if n not in por_nombre]
        if faltan:
            raise SystemExit('la paleta del juego no tiene: ' + ', '.join(faltan))
        fuera[parte] = [por_nombre[n] + 1 for n in nombres]
    usados = [v for l in fuera.values() for v in l]
    if len(usados) != len(set(usados)):
        raise SystemExit('dos partes comparten color de rampa: repintar una tocaría la otra')
    return fuera


def _luz(c):
    return .299 * c[0] + .587 * c[1] + .114 * c[2]


def _tono(c):
    """El color sin su brillo: (r,g,b) normalizado. Es lo que separa una parte de otra."""
    t = c[0] + c[1] + c[2] or 1
    return (c[0] / t, c[1] / t, c[2] / t)


def _clasificador():
    claves = [(p, _tono(rgb)) for p, (rgb, _) in CLAVES.items()]
    def cual(r, g, b):
        if _luz((r, g, b)) < LUZ_CONTORNO:
            return 'contorno'
        t = _tono((r, g, b))
        return min(claves, key=lambda k: sum((k[1][i] - t[i]) ** 2 for i in range(3)))[0]
    return cual


def _pedir(ruta, cuerpo, clave):
    import urllib.error, urllib.request
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
                         'suele estar cerrada; esto se ejecuta en local.')


def _imagen(resp):
    v = resp.get(CAMPO_IMAGEN)
    if isinstance(v, dict):
        v = v.get('base64') or v.get('data')
    if not isinstance(v, str):
        raise SystemExit('la respuesta no trae imagen donde se esperaba. Cuerpo:\n'
                         + json.dumps(resp)[:2000])
    return base64.b64decode(re.sub(r'^data:[^,]+,', '', v))


def genera(ropa, direccion, dibujo, clave, simular):
    """Un PNG de una silueta mirando a una dirección y haciendo algo."""
    # La procedencia va en la clave. Sin esto, un --simular previo —que es lo primero que
    # recomienda el LEEME— deja la caché llena de monigotes de relleno, y la tirada de
    # verdad los encuentra ahí, no llama a PixelLab ni una vez y termina diciendo que todo
    # ha ido bien. Se paga una tirada para acabar con el mismo dibujo de antes.
    etiqueta = f'{"sim" if simular else "api"}|{ropa}|{direccion}|{dibujo}|{CEL_W}x{CEL_H}'
    nombre = os.path.join(CACHE, re.sub(r'\W+', '_', etiqueta)[:120] + '.png')
    if os.path.exists(nombre):
        return open(nombre, 'rb').read()
    if simular:
        datos = _silueta(direccion, dibujo)
    else:
        colores = ', '.join(f'{CLAVES[p][1]} {ropa_de(ropa, p)}'.strip()
                            for p in ('torso', 'piernas', 'calzado'))
        resp = _pedir(API_GENERAR, {
            'description': (f'{colores}, {CLAVES["pelo"][1]}, {CLAVES["piel"][1]}, '
                            f'{DIBUJOS[dibujo]}, {ESTILO}'),
            'image_size': {'width': CEL_W, 'height': CEL_H},
            'view': VISTA, 'direction': direccion,
            'no_background': True, 'outline': 'single color black outline',
        }, clave)
        datos = _imagen(resp)
    os.makedirs(CACHE, exist_ok=True)
    open(nombre, 'wb').write(datos)
    return datos


def ropa_de(ropa, parte):
    """La prenda de esa parte dentro de la descripción de la silueta.

    La descripción va escrita como «lo de arriba, lo de abajo, el calzado», y a cada trozo
    se le pega delante su color de plantilla. Así el generador oye «bright magenta long
    sleeved jacket» y no un color suelto que no sabe dónde poner.
    """
    trozos = [t.strip() for t in SETS[ropa].split(',')]
    while len(trozos) < 3:
        trozos.append('')
    return {'torso': trozos[0], 'piernas': trozos[1], 'calzado': trozos[2]}[parte]


def _silueta(direccion, dibujo):
    """Un monigote de relleno para --simular: no vale para jugar, vale para probar.

    Va con los colores de plantilla de verdad, y con sombra y luz, para que el reparto por
    partes y el repintado por rampas se ejerciten igual que con un dibujo traído.
    """
    from PIL import Image, ImageDraw
    im = Image.new('RGBA', (CEL_W, CEL_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    def tres(parte):
        r, g, b = CLAVES[parte][0]
        return [tuple(int(c * f) for c in (r, g, b)) + (255,) for f in (.55, .8, 1.0)]
    torso, piernas, calzado = tres('torso'), tres('piernas'), tres('calzado')
    piel, pelo = tres('piel'), tres('pelo')
    cx, base = CEL_W // 2, CEL_H - 4
    paso = 2 if dibujo.startswith(('andar', 'correr')) else 0
    baja = 4 if dibujo == 'agacha' else 0
    d.rectangle([cx - 4, base - 16 + baja, cx + 4, base - 4], fill=torso[1])
    d.rectangle([cx - 4, base - 16 + baja, cx + 4, base - 14 + baja], fill=torso[2])
    d.rectangle([cx + 3, base - 16 + baja, cx + 4, base - 4], fill=torso[0])
    d.rectangle([cx - 3 - paso, base - 4, cx - 1 - paso, base - 1], fill=piernas[1])
    d.rectangle([cx + 1 + paso, base - 4, cx + 3 + paso, base - 1], fill=piernas[0])
    d.rectangle([cx - 3 - paso, base - 1, cx - 1 - paso, base], fill=calzado[1])
    d.rectangle([cx + 1 + paso, base - 1, cx + 3 + paso, base], fill=calzado[0])
    d.ellipse([cx - 4, base - 24 + baja, cx + 4, base - 16 + baja], fill=piel[2])
    d.rectangle([cx - 4, base - 25 + baja, cx + 4, base - 22 + baja], fill=pelo[1])
    return _png(im)


def _png(im):
    import io
    b = io.BytesIO()
    im.save(b, 'PNG')
    return b.getvalue()


def a_indices(png, pal, ramp, cual):
    """PNG -> un byte por píxel: 0 transparente, y si no la rampa de su parte.

    El color final no sale de buscar el más parecido entre los 48: sale de decidir primero
    qué parte del cuerpo es ese píxel, y luego colocar su brillo dentro de la rampa de esa
    parte. Es lo que hace que el repintado sea posible — con la búsqueda a secas, la
    manga y el pantalón acaban compartiendo color y ya no hay manera de separarlos.
    """
    from PIL import Image
    import io
    im = Image.open(io.BytesIO(png)).convert('RGBA')
    if im.size != (CEL_W, CEL_H):
        im = im.resize((CEL_W, CEL_H), Image.NEAREST)
    luces = {p: [_luz(pal[i - 1]) for i in idx] for p, idx in ramp.items()}
    fuera = bytearray(CEL_W * CEL_H)
    px, memo = im.load(), {}
    for y in range(CEL_H):
        for x in range(CEL_W):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            v = memo.get((r, g, b))
            if v is None:
                parte = cual(r, g, b)
                l = _luz((r, g, b))
                idx = ramp[parte]
                v = min(range(len(idx)), key=lambda i: abs(luces[parte][i] - l))
                v = idx[v]
                memo[(r, g, b)] = v
            fuera[y * CEL_W + x] = v
    return fuera


def hoja(nombre, clave, simular, pal, ramp):
    """La hoja entera de una silueta: 8 columnas de dirección × 16 filas de pose."""
    cual = _clasificador()
    ancho, alto = CEL_W * 8, CEL_H * len(POSES)
    rej = bytearray(ancho * alto)
    celdas = {}
    for dib in sorted(set(DE_POSE[p] for p in POSES)):
        for fx in range(PEDIDAS):
            celdas[(dib, fx)] = a_indices(
                genera(nombre, DIRECCIONES[fx], dib, clave, simular), pal, ramp, cual)
            print(f'  {nombre:15s} {dib:8s} {DIRECCIONES[fx]}', flush=True)
    for fy, pose in enumerate(POSES):
        dib, dy = DE_POSE[pose], DESPLAZA.get(pose, 0)
        for fx in range(8):
            fuente, esp = ESPEJO.get(fx, fx), fx in ESPEJO
            celda = celdas[(dib, fuente)]
            for y in range(CEL_H):
                oy = y + dy
                if not 0 <= oy < CEL_H:
                    continue
                fila = celda[oy * CEL_W:(oy + 1) * CEL_W]
                if esp:
                    fila = fila[::-1]
                i = (fy * CEL_H + y) * ancho + fx * CEL_W
                rej[i:i + CEL_W] = fila
    return rej


def comprimir(datos):
    c = zlib.compressobj(9, zlib.DEFLATED, -15)          # deflate crudo, como la trama
    return base64.b64encode(c.compress(bytes(datos)) + c.flush()).decode()


def escribir(hojas, ramp):
    s = _texto_html()
    a, b = '/*<<<SPRITES*/', '/*SPRITES>>>*/'
    i, j = s.index(a), s.index(b)
    filas = []
    for k, b64 in sorted(hojas.items()):
        trozos = ',\n'.join(f"  '{b64[t:t+108]}'" for t in range(0, len(b64), 108))
        filas.append(f" {k}: [\n{trozos}].join('')")
    ramps = ', '.join(f'{p}:[{",".join(str(v) for v in idx)}]' for p, idx in ramp.items())
    cuerpo = ('/* Lo escribe herramientas/sprites/pixellab.py. Vacío = todo forjado. */\n'
              f'const SPR={{cel:[{CEL_W},{CEL_H}],\n rampas:{{{ramps}}},\n hojas:{{\n'
              + ',\n'.join(filas) + '\n}};')
    open(HTML, 'w', encoding='utf-8').write(s[:i + len(a)] + '\n' + cuerpo + '\n' + s[j:])


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[1])
    ap.add_argument('--que', default=','.join(SETS), help='siluetas, separadas por coma')
    ap.add_argument('--clave', default=os.environ.get('PIXELLAB_API_KEY', ''))
    ap.add_argument('--simular', action='store_true', help='sin red: monigotes de relleno')
    ap.add_argument('--coste', action='store_true', help='solo la cuenta, no baja nada')
    a = ap.parse_args()

    quiere = [q.strip() for q in a.que.split(',') if q.strip()]
    desconocidos = [q for q in quiere if q not in SETS]
    if desconocidos:
        raise SystemExit('no sé qué silueta es: ' + ', '.join(desconocidos))
    faltan = [p for p in POSES if p not in DE_POSE]
    if faltan:
        raise SystemExit('poses del juego sin dibujo asignado: ' + ', '.join(faltan))

    pal, por_nombre = paleta()
    ramp = rampas(por_nombre)          # aquí revienta si dos partes comparten rampa
    dibujos = len(set(DE_POSE[p] for p in POSES))
    n = len(quiere) * dibujos * PEDIDAS
    entero = len(SETS) * dibujos * PEDIDAS
    print(f'{len(quiere)} siluetas · {dibujos} dibujos × {PEDIDAS} direcciones = {n} '
          f'imágenes · celda {CEL_W}x{CEL_H}' + (' · SIMULADO' if a.simular else ''))
    print(f'  ({len(POSES)} poses y 8 direcciones salen de ahí; el juego entero, '
          f'{len(SETS)} siluetas, son {entero})')
    if a.coste:
        print(f'  {len(ramp)} rampas de plantilla, sin un color compartido; '
              f'{len(POSES)} poses con dibujo asignado')
        sys.exit(0)
    if not a.simular and not a.clave:
        raise SystemExit('falta la clave: PIXELLAB_API_KEY o --clave')

    hojas = {}
    for k in quiere:
        hojas[k] = comprimir(hoja(k, a.clave, a.simular, pal, ramp))
    escribir(hojas, ramp)
    peso = sum(len(v) for v in hojas.values()) / 1024
    print(f'-> {HTML}  ({peso:.0f} KB de hojas)')
