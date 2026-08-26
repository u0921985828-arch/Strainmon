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
import argparse, base64, json, os, re, sys, time, zlib

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
    'piel':    ((224, 172, 128), 'plain tan skin'),
    'pelo':    ((  0,   0, 255), 'short vivid blue hair'),
    'torso':   ((255,   0, 255), 'vivid magenta'),
    'piernas': ((  0, 255,   0), 'vivid green'),
    'calzado': ((  0, 255, 255), 'vivid cyan'),
}
# La rampa de la paleta en la que se guarda cada parte. Tienen que ser disjuntas: es lo
# que permite repintar una parte sin tocar las demás.
# Se nombran por familia y no por apodo: la paleta de CONTEXT.md §18.6 viene ya en rampas
# de ocho tonos de oscuro a claro, que es exactamente lo que esto necesitaba y antes había
# que apañar juntando colores sueltos. La piel pasa de seis tonos a ocho.
RAMPAS = {
    'piel':    ['tez0', 'tez1', 'tez2', 'tez3', 'tez4', 'tez5', 'tez6', 'tez7'],
    'pelo':    ['ladrillo0', 'ladrillo1', 'ladrillo2', 'ladrillo3'],
    'torso':   ['ria2', 'ria3', 'ria4', 'ria5'],
    'piernas': ['verde2', 'verde3', 'verde4', 'verde5'],
    'calzado': ['luz2', 'luz3', 'luz4'],
    'contorno': ['tinta'],
}
# El contorno no se reconoce por ser oscuro, sino por ser oscuro **y no tener color**. Con
# la oscuridad a secas, el azul del pelo —que a plena intensidad tiene luminancia 29, por
# debajo de cualquier umbral razonable— se iba entero al contorno y el pelo desaparecía de
# la hoja: el arquetipo salía calvo y el repintado no tenía nada que repintar.
LUZ_CONTORNO = 46
SAT_CONTORNO = .45
# Por debajo de esto un píxel no tiene color suficiente para decir de qué parte es, y se
# reparte por vecindad en vez de por tono. El tono de plantilla más apagado es la piel, con
# 0,43: el umbral tiene que quedar por debajo de eso y por encima de un gris de sombra.
SAT_MINIMA = .22

# ── las siluetas ────────────────────────────────────────────────────────────────────
# El nombre es «lo de arriba _ lo de abajo», y el juego lo deduce igual de la ropa de cada
# arquetipo: manga larga, manga corta, abrigo o capucha; pantalón, falda o pantalón corto.
# Cambiar un nombre aquí sin cambiarlo allí deja la hoja sin usar — la batería lo mira.
# Exactamente tres trozos separados por coma —torso, piernas y calzado— porque `ropa_de`
# le pega a cada uno su color de plantilla por separado. Y ropa del 96, que es cuando pasa
# el juego: cazadora bomber y no parka técnica, chándal de algodón y no de licra.
SETS = {
    'largo_pantalon':   'a bomber jacket, straight leg jeans, ankle boots',
    'largo_falda':      'a wool jumper, a knee length skirt, flat shoes',
    'corto_pantalon':   'a short sleeved shirt, straight leg trousers, flat shoes',
    'corto_short':      'a short sleeved t-shirt, sports shorts, canvas trainers',
    'abrigo_pantalon':  'a long overcoat down to the knees, straight leg trousers, flat shoes',
    'abrigo_falda':     'a long open raincoat, a knee length skirt, flat shoes',
    'capucha_pantalon': 'a hooded sweatshirt with the hood down, cotton tracksuit trousers, trainers',
}

VISTA = 'high top-down'
# La descripción es del aspecto que queremos, no de la obra de nadie. Pedirle a un
# generador el estilo de un juego con dueño es hacerle producir algo derivado de ese juego,
# y ese algo acabaría dentro del nuestro.
#
# El vocabulario sale de CONTEXT.md §18.5, que ya fija cómo se le habla al generador:
# «8-bit indexed palette, hard pixel edges, no anti-aliasing, no outline glow,
# orthographic top-down at 45 degrees, 1996 period accurate». No se inventa otro aquí.
#
# Solo hay un punto donde esto se aparta del documento a propósito. §18.5 pide una paleta
# «muted overcast northern Spain» y aquí se piden colores saturados. No es contradicción:
# lo que se le pide al generador es el **estarcido**, no el aspecto final. Las partes del
# cuerpo tienen que llegar separables por tono, y un magenta apagado se confunde con la
# piel. Lo apagado lo pone el repintado, que manda cada rampa a la paleta del juego.
#
# Y aquí no va ni un «no»: lo que no queremos vive en NEGATIVO. Mezclados, el «no» compite
# con lo que sí queremos y encima el generador dibuja lo que se le nombra.
ESTILO = ('8-bit indexed pixel art sprite of one single character, full body, centred, '
          'feet near the bottom edge, orthographic top-down view at 45 degrees, '
          'chunky proportions with a large head, flat blocks of saturated colour, '
          'hard pixel edges, light from the upper left, single colour black outline, '
          'transparent background, bare head, Spain 1996')
# Lo que NO queremos, en su propio campo.
NEGATIVO = ('gradient, dithering, soft shading, anti-aliasing, outline glow, blurry, '
            'motion blur, 3d render, photo, realistic, watermark, text, signature, '
            'extra limbs, cropped, cut off, ground shadow, drop shadow, scenery, '
            'multiple characters, hat, cap, helmet, bag, backpack')
# Palabras que no pueden aparecer en ninguna descripción positiva porque están en la
# negativa. La lista va a mano y no sacada de NEGATIVO: «outline» está en las dos con
# sentidos distintos —queremos contorno, no queremos que brille— y comparar palabra por
# palabra la marcaría. Estas son las que sí son contradicción se miren como se miren.
PROHIBIDAS = ('hat', 'cap', 'helmet', 'bag', 'backpack', 'gradient', 'dithering',
              'shadow', 'scenery', 'blurry')
GUIA = 8                   # cuánto se le aprieta para que siga el texto
# Por debajo de esto la figura va medio sin contorno, y sobre el hormigón de la ciudad
# —del mismo gris que media ropa— se deshace. Se avisa; no se repasa, que un contorno
# repasado encima del que ya está queda de dos píxeles y a esta escala es peor.
BORDE_MINIMO = .6
_GASTO = [0.]              # lo que lleva gastado la tirada, según la propia API


def semilla(ropa):
    """La semilla de una silueta. Estable, y distinta para cada una.

    Todas las celdas de una silueta van con la misma: es lo que hace que las 55 imágenes
    parezcan la misma persona en vez de 55 personas distintas haciendo cada una una pose.
    Se saca del nombre para que repetir una tirada dé lo mismo.
    """
    return zlib.crc32(ropa.encode()) % 100000

# Las ocho direcciones del juego, en su orden: 0 es sur y se gira en sentido antihorario.
DIRECCIONES = ['south', 'south-east', 'east', 'north-east',
               'north', 'north-west', 'west', 'south-west']
PEDIDAS = 5                                   # las cinco primeras; el resto son espejo
ESPEJO = {5: 3, 6: 2, 7: 1}                   # noroeste<-nordeste, oeste<-este, so<-se

# Los once dibujos que hay que pedir, y en cuál cae cada una de las dieciséis poses.
# Desde arriba de una figura de 32 píxeles no se lee la cara: se lee el hombro, el paso y
# el bulto de la cabeza. Por eso cada dibujo dice qué hacen los brazos y las piernas, que
# es lo único que se distingue, y no qué expresión pone.
DIBUJOS = {
    'quieto':  'standing still, arms hanging at the sides',
    'andarA':  'mid walk, left leg forward and right arm forward',
    'andarP':  'mid walk, legs together passing each other, arms at the sides',
    'andarB':  'mid walk, right leg forward and left arm forward',
    'correrA': 'running, left leg forward, body leaning ahead, arms bent',
    'correrB': 'running, right leg forward, body leaning ahead, arms bent',
    'pega1':   'throwing a punch, fist just leaving the shoulder',
    'pega2':   'throwing a punch, arm extended forward, shoulders turned into it',
    'apunta':  'aiming a small pistol straight ahead with both arms',
    'herido':  'reeling from a blow, shoulders thrown back',
    'agacha':  'crouching low on the heels, head down, knees bent',
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
# disparo y el balanceo del que anda agachado los pone esto, no una llamada más. El signo
# es el del juego: negativo sube la figura, como el `y:-1` que la forja le da a `dispara`.
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
    # Y la escala a la que la forja sube esa caja. Estaba sin leer, así que el empaquetador
    # pedía celdas de 24×32 —la caja sin escalar— mientras el juego trabaja a 32×42, y
    # `cargarSprites` rechazaba toda hoja traída por «medidas raras»: la vía de PixelLab
    # estaba muerta sin que nadie lo viera, porque el juego siempre tiene la forja detrás.
    e = re.search(r'const PJ_N=(\d+), PJ_D=(\d+);', _texto_html())
    if not e:
        raise SystemExit('no encuentro la escala de la forja (PJ_N/PJ_D) en el HTML')
    pn, pd = (int(g) for g in e.groups())
    sc = lambda v: v * pn // pd            # la misma cuenta que sc() en el juego
    # Dónde pisa la figura y por dónde va su eje, en coordenadas de celda. La forja dibuja
    # en una caja de 20×26 dentro del margen: los pies caben en las dos últimas filas de
    # esa caja y el eje va por su mitad. El juego ancla la celda por abajo, así que estas
    # dos cifras son las que hacen que un personaje traído pise donde pisa uno forjado.
    return sc(20 + mx * 2), sc(26 + arr + aba), sc(arr + 25), sc(mx + 10)


CEL_W, CEL_H, BASE_PIES, EJE_X = _celda_forja()
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
    """El matiz, en grados. Es lo que separa una parte de otra.

    Y tiene que ser el matiz, no el color normalizado. Un generador ilumina aclarando hacia
    el blanco, y normalizando, un brillo del pelo azul —(89,89,255)— se acerca más al
    magenta del torso que al azul del que salió: media cabeza acababa repintada del color
    de la chaqueta. El matiz de ese brillo sigue siendo 240 clavados.
    """
    r, g, b = c[0] / 255., c[1] / 255., c[2] / 255.
    mx, mn = max(r, g, b), min(r, g, b)
    d = mx - mn
    if not d:
        return 0.
    if mx == r:
        h = 60 * (((g - b) / d) % 6)
    elif mx == g:
        h = 60 * ((b - r) / d + 2)
    else:
        h = 60 * ((r - g) / d + 4)
    return h


def _dista(a, b):
    """Lo que hay entre dos matices, contando que 350 y 10 están a veinte grados."""
    d = abs(a - b) % 360
    return min(d, 360 - d)


def _sat(c):
    """Cuánto color tiene, de 0 a 1. Un gris vale 0; el magenta de plantilla, 1."""
    m = max(c)
    return 0. if not m else (m - min(c)) / m


def _reparte(px, w, h):
    """Qué parte del cuerpo es cada píxel de una celda. '' = transparente.

    Por tono no basta, y esto es lo que más puede romperse sin avisar. Un generador
    sombrea, y una sombra apagada de una chaqueta magenta se acerca en tono a la piel
    mucho más que al magenta del que salió: repartiendo píxel a píxel, media manga acaba
    en la rampa de la piel y el repintado la deja de color carne para siempre. Así que van
    dos pasadas:

    1. Los píxeles **con color de verdad** se reparten por tono, que ahí no hay duda.
    2. Los **desvaídos** —grises, blancos de brillo, sombras apagadas— no se reparten por
       tono: se quedan con la parte del píxel clasificado que tengan más cerca. Un brillo
       en el hombro es torso porque está rodeado de torso, no porque su gris se parezca a
       nada.

    El contorno se saca antes por oscuridad y no siembra la segunda pasada: es negro y
    toca todas las partes a la vez, así que sembraría cualquier gris de contorno.
    """
    claves = [(p, _tono(rgb)) for p, (rgb, _) in CLAVES.items()]
    partes = [[''] * w for _ in range(h)]
    desvaidos, semillas = [], []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 128:
                continue
            c = (r, g, b)
            if _luz(c) < LUZ_CONTORNO and _sat(c) < SAT_CONTORNO:
                partes[y][x] = 'contorno'
            elif _sat(c) < SAT_MINIMA:
                partes[y][x] = '?'
                desvaidos.append((x, y))
            else:
                t = _tono(c)
                partes[y][x] = min(claves, key=lambda k: _dista(k[1], t))[0]
                semillas.append((x, y))
    # Los desvaídos se contagian de sus vecinos con color, por cercanía.
    cola, i = semillas[:], 0
    while i < len(cola):
        x, y = cola[i]; i += 1
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and partes[ny][nx] == '?':
                partes[ny][nx] = partes[y][x]
                cola.append((nx, ny))
    # Si la celda entera vino desvaída, no hay de quién contagiarse. Se le da la parte
    # que más manda y se cuenta: es justo lo que hay que mirar antes de gastar 385
    # llamadas con un texto que el generador no está respetando.
    sueltos = [(x, y) for x, y in desvaidos if partes[y][x] == '?']
    if sueltos:
        cuenta = {}
        for f in partes:
            for v in f:
                if v and v not in ('?', 'contorno'):
                    cuenta[v] = cuenta.get(v, 0) + 1
        manda = max(cuenta, key=cuenta.get) if cuenta else 'contorno'
        for x, y in sueltos:
            partes[y][x] = manda
    return partes, {'desvaidos': len(desvaidos), 'sueltos': len(sueltos),
                    'color': len(semillas)}


def png_plantilla(pal, ramp):
    """Un PNG con los colores de plantilla, para mandárselo a PixelLab como `color_image`.

    Es la pieza que convierte el estarcido de apuesta en certeza. Sin esto, se le pide al
    generador «magenta vivo» y se confía en que no lo apague; con esto, se le da la lista
    exacta de colores que puede usar, y lo que vuelve ya viene en las rampas de cada parte.
    El reparto por partes deja de tener que adivinar.

    Sale de las mismas rampas que se escriben en la hoja, así que no puede desfasarse de
    ellas: cada parte aporta sus tonos, más el negro del contorno.
    """
    from PIL import Image
    tonos = []
    for parte in list(CLAVES) + ['contorno']:
        for i in ramp[parte]:
            if pal[i - 1] not in tonos:
                tonos.append(pal[i - 1])
    lado = 8
    cols = min(8, len(tonos))
    filas = (len(tonos) + cols - 1) // cols
    im = Image.new('RGB', (cols * lado, filas * lado), tonos[0])
    px = im.load()
    for n, c in enumerate(tonos):
        cx, cy = (n % cols) * lado, (n // cols) * lado
        for y in range(lado):
            for x in range(lado):
                px[cx + x, cy + y] = c
    import io as _io
    b = _io.BytesIO()
    im.save(b, 'PNG')
    return base64.b64encode(b.getvalue()).decode(), len(tonos)


def _pedir(ruta, cuerpo, clave, intentos=4):
    """Una llamada a PixelLab, con reintentos.

    Los reintentos no son un lujo: una tirada son 385 llamadas seguidas, y sin esto un
    solo 429 a mitad de camino tiraba la tirada entera y dejaba a medias lo ya pagado.
    Se reintenta lo que puede arreglarse esperando —429 y los 5xx— y no lo que no: un 401
    por clave mala no mejora por insistir.
    """
    import urllib.error, urllib.request
    ultimo = ''
    for intento in range(intentos):
        pet = urllib.request.Request(
            API_BASE + ruta, data=json.dumps(cuerpo).encode(),
            headers={'Content-Type': 'application/json',
                     'Authorization': 'Bearer ' + clave})
        try:
            with urllib.request.urlopen(pet, timeout=180) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            detalle = e.read().decode('utf8', 'replace')[:2000]
            if e.code != 429 and e.code < 500:
                raise SystemExit(f'PixelLab respondió {e.code} a {ruta}:\n{detalle}')
            ultimo = f'{e.code}: {detalle[:200]}'
        except urllib.error.URLError as e:
            if intento == intentos - 1:
                raise SystemExit(
                    f'no se llega a {API_BASE}{ruta}: {e.reason}\n'
                    '¿Hay salida a internet desde aquí? En el contenedor de Claude '
                    'suele estar cerrada; esto se ejecuta en local.')
            ultimo = str(e.reason)
        espera = 2 ** intento
        print(f'  reintento {intento + 1}/{intentos} en {espera}s ({ultimo})', flush=True)
        time.sleep(espera)
    raise SystemExit(f'PixelLab no responde después de {intentos} intentos: {ultimo}')


def _imagen(resp):
    v = resp.get(CAMPO_IMAGEN)
    if isinstance(v, dict):
        v = v.get('base64') or v.get('data')
    if not isinstance(v, str):
        raise SystemExit('la respuesta no trae imagen donde se esperaba. Cuerpo:\n'
                         + json.dumps(resp)[:2000])
    return base64.b64decode(re.sub(r'^data:[^,]+,', '', v))


def saldo(clave):
    """Lo que queda en la cuenta, si se deja preguntar. Nunca aborta.

    Una tirada entera son 385 llamadas: enterarse de que no hay saldo a la mitad deja el
    trabajo hecho a medias y ya pagado. Pero esto es una comodidad, no un requisito —si el
    extremo cambió de nombre o no hay salida, se dice y se sigue: quien decide si tira es
    el que tiene la clave, no este aviso.
    """
    import urllib.error, urllib.request
    pet = urllib.request.Request(API_BASE + API_SALDO,
                                 headers={'Authorization': 'Bearer ' + clave})
    try:
        with urllib.request.urlopen(pet, timeout=20) as r:
            d = json.loads(r.read().decode())
        return d.get('usd', d.get('balance', d))
    except Exception as e:                      # noqa: BLE001 — cualquier fallo es «no sé»
        return f'no se ha podido consultar ({e.__class__.__name__}: {e})'


def genera(ropa, direccion, dibujo, clave, simular, plantilla=None):
    """Un PNG de una silueta mirando a una dirección y haciendo algo."""
    # La procedencia va en la clave. Sin esto, un --simular previo —que es lo primero que
    # recomienda el LEEME— deja la caché llena de monigotes de relleno, y la tirada de
    # verdad los encuentra ahí, no llama a PixelLab ni una vez y termina diciendo que todo
    # ha ido bien. Se paga una tirada para acabar con el mismo dibujo de antes.
    etiqueta = (f'{"sim" if simular else "api"}|{ropa}|{direccion}|{dibujo}'
                f'|{CEL_W}x{CEL_H}|{"pal" if plantilla else "libre"}')
    nombre = os.path.join(CACHE, re.sub(r'\W+', '_', etiqueta)[:120] + '.png')
    if os.path.exists(nombre):
        return open(nombre, 'rb').read()
    if simular:
        datos = _silueta(direccion, dibujo)
    else:
        # «wearing a long sleeved jacket in flat bright magenta» y no «bright magenta,
        # long sleeved jacket»: suelto, el color se le va a otra prenda o al fondo.
        colores = ', '.join(f'wearing {ropa_de(ropa, p)} in flat {CLAVES[p][1]}'
                            for p in ('torso', 'piernas', 'calzado') if ropa_de(ropa, p))
        cuerpo = {
            'description': (f'a person {colores}, with {CLAVES["pelo"][1]}, '
                            f'{CLAVES["piel"][1]}, {DIBUJOS[dibujo]}, {ESTILO}'),
            'negative_description': NEGATIVO,
            'image_size': {'width': CEL_W, 'height': CEL_H},
            'view': VISTA, 'direction': direccion,
            'no_background': True, 'outline': 'single color black outline',
            'shading': 'basic shading', 'detail': 'low detail',
            'text_guidance_scale': GUIA,
            # La misma semilla en las 55 celdas de una silueta. Sin esto, cada llamada
            # inventa una persona distinta y el que anda cambia de cara a cada paso.
            'seed': semilla(ropa),
        }
        if plantilla:
            cuerpo['color_image'] = {'type': 'base64', 'base64': plantilla}
        resp = _pedir(API_GENERAR, cuerpo, clave)
        _GASTO[0] += (resp.get('usage') or {}).get('usd') or 0
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
    # Contorno negro alrededor, como lo trae el arte de verdad. Sin él, el aviso de
    # «contorno solo en el 0% del perfil» saltaba en las 385 celdas del ensayo y dejaba de
    # significar nada: un aviso que salta siempre es un aviso que se ignora siempre.
    px = im.load()
    fuera = [(x, y) for y in range(CEL_H) for x in range(CEL_W)
             if not px[x, y][3] and any(
                 0 <= x + dx < CEL_W and 0 <= y + dy < CEL_H and px[x + dx, y + dy][3]
                 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for x, y in fuera:
        px[x, y] = (0, 0, 0, 255)
    return _png(im)


def _png(im):
    import io
    b = io.BytesIO()
    im.save(b, 'PNG')
    return b.getvalue()


def _limpia(partes, w, h):
    """Quita los píxeles sueltos: uno de una parte perdido dentro de otra.

    A treinta y cuatro píxeles de ancho, un punto de color pantalón en mitad de la manga
    no se lee como sombra: se lee como suciedad. Se reasigna al vecino que mande. El
    contorno se deja en paz — es una línea de un píxel de grueso, así que por definición
    tiene pocos vecinos suyos y limpiarlo sería borrarlo.
    """
    sueltos = 0
    for y in range(h):
        for x in range(w):
            v = partes[y][x]
            if not v or v == 'contorno':
                continue
            vecinos = {}
            iguales = 0
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    if not dx and not dy:
                        continue
                    nx, ny = x + dx, y + dy
                    if not (0 <= nx < w and 0 <= ny < h):
                        continue
                    n = partes[ny][nx]
                    if n == v:
                        iguales += 1
                    elif n and n != 'contorno':
                        vecinos[n] = vecinos.get(n, 0) + 1
            if iguales <= 1 and vecinos:
                manda = max(vecinos, key=vecinos.get)
                if vecinos[manda] >= 4:
                    partes[y][x] = manda
                    sueltos += 1
    return sueltos


def _encuadra(partes, w, h):
    """Cuánto hay que mover la figura para que pise donde tiene que pisar.

    Cada llamada devuelve al personaje colocado a su aire dentro de la celda, y unos
    píxeles arriba o abajo de diferencia entre un fotograma y el siguiente se ven como un
    bote: el que anda parece ir dando saltos, y al agacharse se hunde en el suelo. El
    juego ancla la celda por abajo, así que lo que tiene que coincidir es la fila de los
    pies.

    De lado se centra por las piernas, no por la silueta entera: al dar el puñetazo el
    brazo se estira medio cuerpo, y centrando por la caja el cuerpo se iría al lado
    contrario del golpe.
    """
    xs = [x for y in range(h) for x in range(w) if partes[y][x]]
    ys = [y for y in range(h) for x in range(w) if partes[y][x]]
    if not xs:
        return 0, 0
    piernas = [x for y in range(h) for x in range(w)
               if partes[y][x] in ('piernas', 'calzado')]
    eje = piernas or xs
    dx = EJE_X - (min(eje) + max(eje)) // 2
    dy = BASE_PIES - max(ys)
    # Mover no puede sacar nada de la celda: antes de cuadrar los pies, no perder la cabeza.
    dx = max(-min(xs), min(dx, w - 1 - max(xs)))
    dy = max(-min(ys), min(dy, h - 1 - max(ys)))
    return dx, dy


def _borde(partes, w, h):
    """Qué parte del perfil de la figura lleva contorno.

    La forja le pone contorno a todo lo suyo, y no por gusto: la gente cruza del asfalto a
    la acera y de la acera al parque, y una cazadora gris sobre hormigón gris sin borde se
    deshace. A un dibujo traído se le pide contorno, pero pedirlo no es tenerlo. Esto lo
    mide en vez de darlo por hecho — y no lo impone: repasar un contorno que ya está lo
    dejaría de dos píxeles, que a esta escala es peor que no tenerlo.
    """
    perfil = pintados = 0
    for y in range(h):
        for x in range(w):
            v = partes[y][x]
            if not v:
                continue
            fuera = any(not (0 <= x + dx < w and 0 <= y + dy < h)
                        or not partes[y + dy][x + dx]
                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if fuera:
                perfil += 1
                pintados += v == 'contorno'
    return pintados / perfil if perfil else 1.


def a_indices(png, pal, ramp):
    """PNG -> un byte por píxel: 0 transparente, y si no la rampa de su parte.

    El color final no sale de buscar el más parecido entre los 48: sale de decidir primero
    qué parte del cuerpo es ese píxel, y luego colocar su brillo dentro de la rampa de esa
    parte. Es lo que hace que el repintado sea posible — con la búsqueda a secas, la manga
    y el pantalón acaban compartiendo color y ya no hay manera de separarlos.

    Devuelve además el reparto, para poder mirarlo con --diag antes de gastar la tirada.
    """
    from PIL import Image
    import io
    im = Image.open(io.BytesIO(png)).convert('RGBA')
    if im.size != (CEL_W, CEL_H):
        im = im.resize((CEL_W, CEL_H), Image.NEAREST)
    px = im.load()
    partes, cuentas = _reparte(px, CEL_W, CEL_H)
    cuentas['sueltos_limpiados'] = _limpia(partes, CEL_W, CEL_H)
    dx, dy = _encuadra(partes, CEL_W, CEL_H)
    cuentas['movida'] = f'{dx:+d},{dy:+d}'
    cuentas['borde'] = round(_borde(partes, CEL_W, CEL_H), 2)
    luces = {p: [_luz(pal[i - 1]) for i in idx] for p, idx in ramp.items()}
    fuera = bytearray(CEL_W * CEL_H)
    reparto = {}
    for y in range(CEL_H):
        oy = y + dy
        if not 0 <= oy < CEL_H:
            continue
        for x in range(CEL_W):
            parte = partes[y][x]
            ox = x + dx
            if not parte or not 0 <= ox < CEL_W:
                continue
            reparto[parte] = reparto.get(parte, 0) + 1
            l = _luz(px[x, y][:3])
            idx = ramp[parte]
            fuera[oy * CEL_W + ox] = idx[min(range(len(idx)),
                                             key=lambda i: abs(luces[parte][i] - l))]
    reparto.update(cuentas)
    return fuera, reparto


def _avisa(nombre, dib, direccion, rep):
    """Lo que hay que ver antes de gastar las 385 llamadas.

    Dos maneras de que una tirada salga mal sin dar ningún error: que el generador se
    salte un color de plantilla —y entonces esa parte no aparece en el reparto, así que el
    repintado no tiene nada que repintar— y que lo devuelva todo apagado, y el reparto se
    apoye en la vecindad en vez de en el color.
    """
    faltan = [p for p in CLAVES if not rep.get(p)]
    avisos = []
    if faltan:
        avisos.append('sin ' + '/'.join(faltan))
    pintados = rep.get('color', 0) + rep.get('desvaidos', 0)
    if pintados and rep.get('desvaidos', 0) > pintados * .5:
        avisos.append('%d%% desvaído' % (100 * rep['desvaidos'] / pintados))
    if rep.get('sueltos'):
        avisos.append('%d píxeles sin parte' % rep['sueltos'])
    if rep.get('borde', 1) < BORDE_MINIMO:
        avisos.append('contorno solo en el %d%% del perfil' % (100 * rep['borde']))
    if avisos:
        print(f'  ¡ojo! {nombre} {dib} {direccion}: ' + ', '.join(avisos), flush=True)
    return bool(avisos)


def hoja(nombre, clave, simular, pal, ramp, diag=False, plantilla=None):
    """La hoja entera de una silueta: 8 columnas de dirección × 16 filas de pose."""
    ancho, alto = CEL_W * 8, CEL_H * len(POSES)
    rej = bytearray(ancho * alto)
    celdas, dudosas = {}, 0
    for dib in sorted(set(DE_POSE[p] for p in POSES)):
        for fx in range(PEDIDAS):
            celdas[(dib, fx)], rep = a_indices(
                genera(nombre, DIRECCIONES[fx], dib, clave, simular, plantilla), pal, ramp)
            print(f'  {nombre:15s} {dib:8s} {DIRECCIONES[fx]}', flush=True)
            if diag:
                print('     ' + '  '.join(f'{k} {v}' for k, v in sorted(rep.items())),
                      flush=True)
            dudosas += _avisa(nombre, dib, DIRECCIONES[fx], rep)
    if dudosas:
        print(f'  {nombre}: {dudosas} de {len(celdas)} celdas dudosas — mírala con '
              f'`node herramientas/html/personajes.js` antes de bajar las demás', flush=True)
    for fy, pose in enumerate(POSES):
        dib, dy = DE_POSE[pose], DESPLAZA.get(pose, 0)
        for fx in range(8):
            fuente, esp = ESPEJO.get(fx, fx), fx in ESPEJO
            celda = celdas[(dib, fuente)]
            for y in range(CEL_H):
                oy = y - dy
                if not 0 <= oy < CEL_H:
                    continue
                fila = celda[oy * CEL_W:(oy + 1) * CEL_W]
                if esp:
                    fila = fila[::-1]
                i = (fy * CEL_H + y) * ancho + fx * CEL_W
                rej[i:i + CEL_W] = fila
    return rej


def lamina(hojas, pal, ruta, esc=4):
    """Vuelca las hojas empaquetadas a un PNG, para poder mirarlas sin abrir el juego.

    Existe por una razón práctica: enseñar cómo ha quedado una tirada no debería obligar a
    compilar `node-canvas`. Lo que sale es la hoja **tal como se guardó**, con los colores
    de plantilla puestos en sus rampas — que es justo lo que hay que mirar para saber si el
    reparto por partes acertó. La piel en tonos carne, el pelo en marrones, el torso en
    azules, las piernas en verdes y el calzado en maderas. Una manga que salga en tonos
    carne es el reparto equivocándose, y aquí se ve de un vistazo.
    """
    from PIL import Image
    anchoc, altoc = CEL_W * 8, CEL_H * len(POSES)
    im = Image.new('RGB', (anchoc * len(hojas) + 8 * (len(hojas) - 1), altoc),
                   (24, 26, 30))
    px = im.load()
    for n, (nombre, rej) in enumerate(sorted(hojas.items())):
        ox = n * (anchoc + 8)
        for y in range(altoc):
            for x in range(anchoc):
                v = rej[y * anchoc + x]
                if v:
                    px[ox + x, y] = pal[(v - 1) % len(pal)]
                elif (x // 4 + y // 4) % 2:                  # damero: se ve el hueco
                    px[ox + x, y] = (34, 37, 42)
    if esc > 1:
        im = im.resize((im.width * esc, im.height * esc), Image.NEAREST)
    im.save(ruta)
    print(f'-> {ruta}  ({im.width}x{im.height}, {len(hojas)} siluetas)')


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
    ap.add_argument('--lamina', metavar='SALIDA.PNG',
                    help='vuelca las hojas a un PNG para mirarlas sin abrir el juego')
    ap.add_argument('--esc', type=int, default=4, help='aumento de --lamina')
    ap.add_argument('--diag', action='store_true',
                    help='el reparto por partes de cada celda, para ver si el '
                         'generador respetó los colores de plantilla')
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

    if not a.simular:
        print(f'  saldo de la cuenta: {saldo(a.clave)}')
    plantilla, ntonos = png_plantilla(pal, ramp)
    print(f'  paleta forzada de {ntonos} tonos: lo que vuelva ya viene en las rampas')
    crudas = {}
    for k in quiere:
        crudas[k] = hoja(k, a.clave, a.simular, pal, ramp, a.diag,
                         None if a.simular else plantilla)
    hojas = {k: comprimir(v) for k, v in crudas.items()}
    escribir(hojas, ramp)
    if a.lamina:
        lamina(crudas, pal, a.lamina, a.esc)
    peso = sum(len(v) for v in hojas.values()) / 1024
    gasto = f' · ${_GASTO[0]:.2f} gastados' if _GASTO[0] else ''
    print(f'-> {HTML}  ({peso:.0f} KB de hojas{gasto})')
