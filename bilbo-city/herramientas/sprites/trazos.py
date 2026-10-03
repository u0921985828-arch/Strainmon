# -*- coding: utf-8 -*-
"""Las siluetas dibujadas a mano, píxel a píxel, sin red y sin clave.

Por qué existe esto
-------------------
`pixellab.py` sabe pedir las 385 celdas y empaquetarlas, pero necesita salir a internet y
una clave. Esto es la tercera fuente del mismo empaquetador —`api`, `sim` y `mano`— y no
necesita ninguna de las dos: las celdas están escritas aquí.

No es SVG. Un SVG de pixel art es un `<rect>` por píxel, así que el formato no ahorra
nada: lo caro no es el envase, es **decidir cada píxel**, y después habría que rasterizar
a índices de paleta igual. Lo que sí ahorra es escribir esos píxeles como texto, porque
así se leen y se corrigen a ojo en cualquier editor, que es justo lo que un `<rect
x="7" y="12" width="1" height="1"/>` no deja hacer.

El alfabeto
-----------
Un carácter por píxel, ocho en total::

    .  nada          #  contorno negro
    s  piel          h  pelo
    t  torso         r  brazo (manga)
    p  pierna        c  calzado

**El brazo va aparte del torso** porque es lo que separa manga larga de manga corta: la
misma celda vale para las dos y el antebrazo se vuelve piel sin dibujarla otra vez.

**Los tonos no se escriben.** Solo la forma. La luz la pone `_sombrea` a partir del mapa,
siempre igual —clara arriba y a la izquierda, oscura abajo y a la derecha, que es la luz
de todo el juego—, y eso es mejor que sombrearlas a mano: cincuenta y cinco celdas
sombreadas a ojo no salen iguales entre sí, y el baile se ve al animarlas.

Una celda, siete siluetas
-------------------------
Lo que se escribe es **el cuerpo**, no el vecino: una figura con la chaqueta a la cadera y
el pantalón entero. Las otras seis siluetas salen de esa por regla (`viste`), que es la
misma idea que ya sostiene el repintado — el abrigo baja el torso hasta la rodilla, la
falda cierra el hueco entre las piernas, el pantalón corto sube el bajo y deja la
pantorrilla al aire. Por eso se escriben 55 celdas y no 385.
"""

# Qué parte del cuerpo es cada carácter. El contorno y el vacío no son partes.
PARTES = {'s': 'piel', 'h': 'pelo', 't': 'torso', 'r': 'brazo',
          'p': 'piernas', 'c': 'calzado'}
VACIO, CONTORNO = '.', '#'


def rejilla(texto):
    """De texto a lista de listas de caracteres, sin sorpresas de ancho.

    Una fila corta no se rellena en silencio: una celda con una fila de 23 caracteres es
    una errata, y rellenarla mueve medio dibujo un píxel sin decirlo.
    """
    filas = [f for f in texto.strip('\n').split('\n')]
    ancho = max(len(f) for f in filas)
    malas = [i for i, f in enumerate(filas) if len(f) != ancho]
    if malas:
        raise ValueError('filas de ancho distinto: %s (esperaba %d)'
                         % (', '.join(str(m) for m in malas), ancho))
    return [list(f) for f in filas]


def _banda(rej, ch):
    """Primera y última fila donde aparece un carácter. (None, None) si no está."""
    filas = [y for y, f in enumerate(rej) if ch in f]
    return (filas[0], filas[-1]) if filas else (None, None)


def _maciza(rej, ch, minimo=3):
    """Como `_banda`, pero sin contar las filas en las que ese carácter apenas asoma.

    Hace falta para la rodilla. De frente, el muslo va **detrás** del tronco y de la
    pierna solo asoman dos píxeles a cada lado de la cadera: midiendo la rodilla contra
    esas migas sale medio palmo más arriba de donde está, y el pantalón corto acababa
    empezando por encima del faldón — o sea, sin un solo píxel de pantalón a la vista.
    """
    filas = [y for y, f in enumerate(rej) if f.count(ch) >= minimo]
    return (filas[0], filas[-1]) if filas else (None, None)


def _rellena(rej, y, ch):
    """Cierra el hueco de una fila entre el primer y el último píxel con cuerpo.

    Es lo que convierte dos piernas en una falda: no se añade tela por fuera, se tapa el
    aire de en medio.
    """
    con = [x for x, c in enumerate(rej[y]) if c not in (VACIO, CONTORNO)]
    if not con:
        return
    for x in range(con[0], con[-1] + 1):
        if rej[y][x] == VACIO:
            rej[y][x] = ch


def viste(rej, ropa):
    """El cuerpo escrito, vestido de una de las siete siluetas.

    Todo se mide sobre la propia celda —dónde empieza la pierna, dónde acaba el brazo— y
    no sobre números fijos: agachado las bandas no caen donde de pie, y una constante
    vestiría al que corre con el abrigo a la altura del tobillo.
    """
    r = [fila[:] for fila in rej]
    y0p, y1p = _banda(rej, 'p')
    y0r, y1r = _banda(rej, 'r')
    y0t, _ = _banda(rej, 't')
    # La rodilla, a mitad de la pierna. Es donde acaban el abrigo y la falda, que es lo
    # que los hace legibles a esta escala: un abrigo al tobillo y una falda al tobillo son
    # el mismo rectángulo.
    m0p, m1p = _maciza(rej, 'p')
    rodilla = m0p + (m1p - m0p) // 2 if m0p is not None else None
    # El codo, a mitad del brazo: por debajo es antebrazo y la manga corta lo deja al aire.
    codo = y0r + (y1r - y0r) // 2 if y0r is not None else None

    def manga(corta):
        if codo is None or not corta:
            return
        for y in range(codo + 1, y1r + 1):
            for x, c in enumerate(r[y]):
                if c == 'r':
                    r[y][x] = 's'

    def pierna(desde, ch):
        """De esa fila hacia abajo, la pierna pasa a ser otra cosa (piel, normalmente)."""
        for y in range(desde, y1p + 1):
            for x, c in enumerate(r[y]):
                if c == 'p':
                    r[y][x] = ch

    def prenda(hasta, ch, medio=None, vuelo=0):
        """Baja una prenda del torso hasta esa fila, cerrando el hueco entre las piernas.

        `medio` es lo que va por la raja de delante: con la gabardina abierta, la falda.
        Sin franja del medio la rampa `piernas` se quedaría sin un píxel en esas filas.

        `vuelo` la ensancha. Una falda cerrada del ancho exacto de las dos piernas es un
        pantalón sin raja: lo que la hace falda es que cae más ancha que la pierna.
        """
        for y in range(y0p, hasta + 1):
            for x, c in enumerate(r[y]):
                if c == 'p':
                    r[y][x] = ch
            _rellena(r, y, ch)
            for _ in range(vuelo):
                con = [x for x, c in enumerate(r[y]) if c == ch]
                if not con:
                    continue
                for x in (con[0] - 1, con[-1] + 1):
                    if 0 <= x < len(r[y]) and r[y][x] == VACIO:
                        r[y][x] = ch
            if medio:
                con = [x for x, c in enumerate(r[y]) if c not in (VACIO, CONTORNO)]
                cx = (con[0] + con[-1]) // 2
                for x in (cx, cx + 1):
                    if r[y][x] == ch:
                        r[y][x] = medio

    if ropa == 'largo_pantalon':
        pass                                   # el cuerpo tal cual se escribió
    elif ropa == 'corto_pantalon':
        manga(True)
    elif ropa == 'corto_short':
        manga(True)
        pierna(max(y0p + 2, rodilla - 1), 's')  # el bajo, un dedo por encima de la rodilla
    elif ropa == 'largo_falda':
        prenda(rodilla + 1, 'p', vuelo=1)      # un bloque macizo y con vuelo
        pierna(rodilla + 2, 's')               # y la pantorrilla al aire
    elif ropa == 'abrigo_pantalon':
        prenda(rodilla, 't')
    elif ropa == 'abrigo_falda':
        prenda(rodilla + 1, 't', medio='p', vuelo=1)   # abierta, con su falda
        pierna(rodilla + 2, 's')
    elif ropa == 'capucha_pantalon':
        # La capucha caída: un bulto de tela sobre los hombros. Un píxel más ancho en las
        # dos primeras filas del torso se lee como eso desde cualquiera de las ocho
        # direcciones, que es más de lo que consigue dibujarla solo por detrás.
        for y in (y0t, y0t + 1):
            if y >= len(r):
                continue
            con = [x for x, c in enumerate(r[y]) if c in ('t', 'r')]
            if not con:
                continue
            for x in (con[0] - 1, con[-1] + 1):
                if 0 <= x < len(r[y]) and r[y][x] == VACIO:
                    r[y][x] = 't'
    else:
        raise KeyError('silueta sin regla de vestido: %s' % ropa)
    return r


# ── el bulto ───────────────────────────────────────────────────────────────────────
# Lo que sigue es lo que separa un monigote de un personaje: la forma se escribe a mano,
# pero el volumen no se escribe, se calcula. Cincuenta y cinco celdas sombreadas a ojo no
# salen iguales entre sí y el baile se ve al animarlas; calculadas, sí.

# De dónde viene la luz: de arriba y a la izquierda, como en todo el juego. Normalizada,
# para poder hacer el producto escalar con la normal sin dividir cada vez.
LUZ = (-0.70710678, -0.70710678)
# Hasta dónde se mira para saber si un píxel está en el canto o en el centro de una masa.
FONDO = 3


def _normal(rej, x, y, parte):
    """Hacia dónde mira la superficie en ese píxel, como si el cuerpo fuera un bulto.

    Un dibujo de píxeles no tiene normales, pero tiene vecinos: se suman las direcciones
    de los que **no** son de esta parte, ponderadas por lo cerca que están, y eso apunta
    hacia fuera. En el centro de una masa se anulan entre sí y sale (0,0), que es justo lo
    que se quiere decir con «aquí no hay canto».
    """
    sx = sy = 0.0
    for dy in range(-2, 3):
        for dx in range(-2, 3):
            if dx == 0 and dy == 0:
                continue
            nx, ny = x + dx, y + dy
            dentro = (0 <= ny < len(rej) and 0 <= nx < len(rej[ny])
                      and PARTES.get(rej[ny][nx]) == parte)
            if not dentro:
                peso = 1.0 / (dx * dx + dy * dy)
                sx += dx * peso
                sy += dy * peso
    largo = (sx * sx + sy * sy) ** .5
    return (sx / largo, sy / largo) if largo else (0.0, 0.0)


def _fondo(rej, x, y, parte):
    """A cuántos píxeles del borde de su parte está. 1 es el canto; FONDO, el centro."""
    for r in range(1, FONDO + 1):
        for dy in range(-r, r + 1):
            for dx in range(-r, r + 1):
                if max(abs(dx), abs(dy)) != r:
                    continue
                nx, ny = x + dx, y + dy
                if not (0 <= ny < len(rej) and 0 <= nx < len(rej[ny])
                        and PARTES.get(rej[ny][nx]) == parte):
                    return r
    return FONDO


# Partes distintas que comparten rampa de color: sin una costura oscura entre ellas, el
# brazo y el torso se funden en un solo bloque y la figura se queda cuadrada.
PEGADAS = (('torso', 'brazo'), ('brazo', 'torso'))


def _costura(rej, x, y, parte):
    """Si toca, por el lado, a otra parte que se pinta de su mismo color."""
    for dx, dy in ((-1, 0), (1, 0)):
        nx, ny = x + dx, y + dy
        if 0 <= ny < len(rej) and 0 <= nx < len(rej[ny]):
            otra = PARTES.get(rej[ny][nx])
            if otra and otra != parte and (parte, otra) in PEGADAS:
                return True
    return False


def _tapado(rej, x, y, parte):
    """Si tiene encima o a su izquierda otra parte del cuerpo, que le hace sombra.

    Es lo que mete el hueco bajo la barbilla, la axila y el bajo del abrigo. Sin esto, dos
    partes pegadas se tocan con dos cantos claros y la figura se aplana.
    """
    for dx, dy in ((-1, 0), (0, -1), (-1, -1), (1, -1), (-1, 1)):
        nx, ny = x + dx, y + dy
        if 0 <= ny < len(rej) and 0 <= nx < len(rej[ny]):
            otra = PARTES.get(rej[ny][nx])
            if otra and otra != parte:
                return True
    return False


def _sombrea(rej, x, y, parte, tonos):
    """Qué tono de la rampa le toca a ese píxel, de 0 (el más oscuro) a `tonos`-1.

    Tres cosas y en este orden: hacia dónde mira la superficie —que es casi todo—, si está
    en el canto o en el fondo de la masa —el centro de un brazo es tono medio aunque el
    brazo entero mire a la luz— y si tiene otra parte encima tapándole.

    Y una cuarta que parece un error y no lo es: el canto de abajo a la derecha, el más
    oscuro de todos, sube un punto. Es el rebote del suelo, y es lo que impide que la
    figura se pegue al fondo como un recorte.
    """
    nx, ny = _normal(rej, x, y, parte)
    cara = nx * LUZ[0] + ny * LUZ[1]   # +1 mirando a la luz, -1 dándole la espalda
    fondo = _fondo(rej, x, y, parte)
    t = .5 + (.42 if fondo < FONDO else .16) * cara
    if _tapado(rej, x, y, parte):
        t -= .16
    if cara < -.35 and fondo == 1:
        t += .13
    if _costura(rej, x, y, parte):
        return 0                       # la raya del sobaco: la más oscura de la rampa
    t = min(1., max(0., t))
    return int(round(t * (tonos - 1)))


def _estrecha(rej, y, ch):
    """Le quita un píxel por cada lado a lo que haya de ese carácter en esa fila."""
    con = [x for x, c in enumerate(rej[y]) if c == ch]
    if len(con) < 4:
        return
    for x in (con[0], con[-1]):
        rej[y][x] = VACIO


def talla(rej):
    """El cuerpo escrito, con cintura y con tobillos. Antes de vestirlo.

    Un cuerpo escrito a base de rectángulos es un rectángulo: hombros, cintura y cadera
    del mismo ancho. Con meter la cintura dos píxeles y afilar la pantorrilla, la misma
    celda deja de leerse como una caja y empieza a leerse como alguien.

    Se mide sobre el propio dibujo, no con filas fijas: agachado el torso tiene siete
    filas y no diez, y una constante le pondría la cintura en el cuello.

    **Antes de `viste`**, no después: con el abrigo puesto, la banda del torso llega a la
    rodilla y el sesenta por ciento de esa banda cae en el faldón.
    """
    r = [f[:] for f in rej]
    y0t, y1t = _banda(rej, 't')
    if y0t is not None and y1t - y0t >= 4:
        cintura = y0t + int((y1t - y0t) * .6)
        for y in (cintura, cintura + 1):
            if y <= y1t:
                _estrecha(r, y, 't')
    y0p, y1p = _banda(rej, 'p')
    if y0p is not None and y1p - y0p >= 3:
        for y in (y1p - 1, y1p):
            _estrecha(r, y, 'p')
    return r


def _esquina(rej, x, y):
    """Si ese píxel es una esquina de 90° del perfil, y por tanto sobra.

    Un cuerpo escrito con rectángulos tiene las esquinas cuadradas de los rectángulos; un
    hombro, una punta del pelo o un zapato no las tienen. Se quita el píxel que tiene dos
    lados contiguos al aire y los otros dos con cuerpo: eso redondea el perfil sin tocar
    nada de dentro, y no puede partir la figura en dos porque los dos lados que se quedan
    siguen tocándose por la diagonal.
    """
    def hay(dx, dy):
        nx, ny = x + dx, y + dy
        return (0 <= ny < len(rej) and 0 <= nx < len(rej[ny])
                and rej[ny][nx] != VACIO)
    for ax, ay in ((-1, 0), (1, 0)):
        for bx, by in ((0, -1), (0, 1)):
            if not hay(ax, ay) and not hay(bx, by) and hay(-ax, -ay) and hay(-bx, -by):
                return True
    return False


def redondea(rej):
    """El perfil, sin sus esquinas cuadradas. Una sola pasada, y todas a la vez.

    A la vez y no una por una: quitándolas de una en una, la primera cambia el vecindario
    de la siguiente y se come el brazo entero fila a fila. Mirando todas sobre el dibujo
    original, se quita exactamente la capa de esquinas que había.
    """
    fuera = [f[:] for f in rej]
    for y, fila in enumerate(rej):
        for x, ch in enumerate(fila):
            if ch != VACIO and _esquina(rej, x, y):
                fuera[y][x] = VACIO
    return fuera


def pinta(rej, claves, ancho, alto, luces=None, redondear=False):
    """La celda escrita, redondeada, con volumen y con su contorno. Devuelve un PNG.

    `luces` es, por parte, la luminancia exacta de cada tono de la rampa de la paleta en
    la que va a acabar guardada. Dándoselas, la celda se pinta **ya en su rampa**: ocho
    tonos de piel y cuatro de chaqueta en vez de tres apaños, y el empaquetado los
    reconoce uno a uno en lugar de aplastarlos contra el más parecido. Sin ellas se pintan
    tres tonos, que es lo justo para mirar una prueba.

    `redondear` quita las esquinas cuadradas del perfil. Hace falta con una celda escrita
    a mano a base de rectángulos; con las que salen de `cuerpos`, no — vienen de rasterizar
    a ×4, y volver a limarlas les come el brazo.

    Los colores siguen siendo los de plantilla: el matiz manda, así el reparto por partes
    y el repintado por rampas se ejercitan igual vengan las celdas de donde vengan.
    """
    from PIL import Image
    if redondear:
        rej = redondea(rej)
    im = Image.new('RGBA', (ancho, alto), (0, 0, 0, 0))
    px = im.load()
    tonos = {}
    for parte, (rgb, _) in claves.items():
        objetivos = (luces or {}).get(parte)
        if objetivos:
            tonos[parte] = [_luminancia(rgb, o) + (255,) for o in sorted(objetivos)]
        else:
            tonos[parte] = [tuple(int(c * f) for c in rgb) + (255,)
                            for f in (.55, .8, 1.)]
    # El brazo no tiene color propio: lleva el del torso cuando es manga y el de la piel
    # cuando el escritor ya lo pasó a piel, que es lo que hace `viste`.
    tonos['brazo'] = tonos['torso']
    dy = (alto - len(rej)) // 2
    for y, fila in enumerate(rej):
        for x, ch in enumerate(fila):
            if ch == VACIO:
                continue
            X, Y = x + (ancho - len(fila)) // 2, y + dy
            if not (0 <= X < ancho and 0 <= Y < alto):
                continue
            if ch == CONTORNO:
                px[X, Y] = (0, 0, 0, 255)
                continue
            parte = PARTES[ch]
            rampa = tonos[parte]
            px[X, Y] = rampa[_sombrea(rej, x, y, parte, len(rampa))]
    # El contorno, alrededor de todo lo que se pintó. Va después y por vecindad, no a
    # mano: dibujarlo en el texto es doblar el trabajo y equivocarse en una esquina.
    fuera = [(x, y) for y in range(alto) for x in range(ancho)
             if not px[x, y][3] and any(
                 0 <= x + dx < ancho and 0 <= y + dy < alto and px[x + dx, y + dy][3]
                 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for x, y in fuera:
        px[x, y] = (0, 0, 0, 255)
    return im


def _luminancia(rgb, objetivo):
    """El color de plantilla llevado a esa luminancia exacta, sin cambiarle el matiz.

    Hacia abajo se multiplica, que mantiene matiz y saturación clavados. Hacia arriba no
    se puede —el azul puro ya está a tope— así que se mezcla con blanco, que sube el
    brillo y baja la saturación pero deja el matiz donde estaba, que es por lo único que
    el empaquetado reconoce la parte.
    """
    l = .299 * rgb[0] + .587 * rgb[1] + .114 * rgb[2]
    if objetivo <= l:
        f = objetivo / l if l else 0.
        return tuple(int(round(c * f)) for c in rgb)
    a = (objetivo - l) / (255. - l) if l < 255 else 0.
    return tuple(int(round(c + (255 - c) * a)) for c in rgb)
