# python3 -I tools/sprites/a-mano/almacen.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.36 (lo pidió el usuario: «Quiero para los visores sprites del estilo de todo el juego» y «una ventana para ver lo que estás
# seleccionando»): la caja fuerte y la nevera por dentro, a mano, con la luz y el contorno de los muebles del piso. Todo con el
# ancla arriba a la izquierda (0, 0): el juego pone encima lo que cambia (lo lleno de cada tarro, las etiquetas, las barras):
#  · alm-caja (168 × 100): el acero de la caja, el fondo cepillado, el tabique, la bandeja de los billetes, el cajón y dos baldas
#    de madera para los tarros;
#  · alm-nevera (152 × 120): la nevera blanca por dentro, la luz, la fila de GUARDAR arriba, siete baldas de cristal y la guía de
#    lo llena que está;
#  · alm-panel (60 × 100): la ventana del elegido: el visor oscuro y las tres ranuras de las barras;
#  · alm-tarro, alm-tarro-s (18 × 25): el cristal del tarro de cogollos, con la tapa de latón (y la dorada del fenotipo estrella),
#    hueco por dentro para que se vea lo que lleva; alm-bote (12 × 12), el bote pequeño de los extractos, con la tapa de aluminio;
#  · alm-mas (18 × 25): GUARDAR en la caja, el tarro abierto y vacío con el más; alm-guardar (44 × 11), el botón de la nevera;
#  · alm-fajo (15 × 8): un fajo de billetes con su faja;
#  · alm-ic-thc/-cu/-mc/-g/-eur (7 × 7): los iconos de las barras (tricoma, tarro, tijeras, pesa y moneda);
#  · los mismos al doble (-g), para la ventana: alm-tarro-g, alm-tarro-s-g, alm-bote-g, alm-mas-g y alm-fajo-g.
# Sale a art/crudo/almacen/<sprite>/unica/00.png (después, node tools/sprites/procesar.js almacen --atlas)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

K = '#2a2a34'   # el contorno de los muebles (el de salon.py)
SAL = {}
def sale(n, L): SAL[n] = L

# ---------- la caja fuerte por dentro ----------
A0, A1, A2, A3, A4 = '#0c0d10', '#15171c', '#2a2d34', '#3a3e46', '#5a5e68'   # el acero, de sombra a brillo
M0, M1, M2 = '#3a2c1c', '#6a5236', '#8a6e4a'                                 # la madera de las baldas
def caja():
    L = Lienzo(168, 100)
    L.r(0, 0, 168, 100, A2); L.hl(1, 166, 1, A4); L.vl(1, 1, 98, A3); L.vl(166, 1, 98, '#1a1c22'); L.hl(1, 166, 98, '#1a1c22')   # el marco, biselado
    for (x, y) in ((2, 2), (164, 2), (2, 96), (164, 96)): L.r(x, y, 2, 2, '#7a7e88'); L.p(x, y, '#a8acb4')                   # los remaches
    L.r(4, 4, 160, 92, A1)
    for x in range(8, 164, 6): L.vl(x, 6, 95, '#1b1e24')                       # el fondo cepillado
    L.hl(4, 163, 4, A0); L.hl(4, 163, 5, '#111317'); L.vl(4, 4, 95, A0)        # la sombra de dentro
    L.r(62, 4, 2, 92, A2); L.vl(62, 4, 95, A3)                                 # el tabique
    # la izquierda: la bandeja de los billetes (sobre la que van los fajos) y el cajón de abajo con su tirador
    L.r(6, 62, 54, 2, A3); L.hl(6, 59, 62, A4); L.hl(6, 59, 64, A0)
    L.r(8, 82, 49, 10, A3); L.hl(8, 56, 82, A4); L.hl(8, 56, 91, '#2a2d34'); L.vl(8, 82, 91, A4)
    L.r(28, 85, 9, 4, '#8a8e96'); L.hl(28, 36, 85, '#c0c4cc'); L.hl(28, 36, 88, '#5a5e66')
    # la derecha: dos baldas de madera (los tarros se apoyan en y = 33 y 67), con sus escuadras
    for y in (33, 67):
        L.r(66, y, 96, 3, M1); L.hl(66, 161, y, M2); L.hl(66, 161, y + 3, M0)
        for x in (68, 158): L.vl(x, y + 3, y + 5, A4); L.p(x + 1, y + 4, A3)
    return L

# ---------- la nevera por dentro ----------
# 1.36.1 (lo pidió el usuario: «poco realistas»): la junta de goma gris alrededor, el plástico blanco con las paredes de los lados
# en sombra, el fondo más frío abajo con sus nervios, el plafón de la luz con su resplandor, la rejilla del aire, y cada balda de
# cristal con su canto verdoso y el perfil blanco de delante, apoyada en sus guías y con su sombra en el fondo
def nevera():
    L = Lienzo(152, 120)
    L.r(0, 0, 152, 120, '#d4dce2'); L.hl(1, 150, 0, '#eef3f6'); L.vl(0, 1, 118, '#eef3f6'); L.hl(1, 150, 119, '#9aa6ae'); L.vl(151, 1, 118, '#9aa6ae')
    L.r(1, 1, 150, 2, '#8e989f'); L.r(1, 117, 150, 2, '#8e989f'); L.r(1, 1, 2, 118, '#8e989f'); L.r(149, 1, 2, 118, '#8e989f')   # la junta
    L.hl(2, 149, 2, '#a8b2b8'); L.vl(2, 2, 117, '#a8b2b8')
    for (x, y) in ((3, 3), (148, 3), (3, 116), (148, 116)): L.p(x, y, '#a8b2b8')                # las esquinas redondas
    FONDO = ('#f4f8fa', '#eef4f7', '#e8f0f4', '#e2ebf0', '#dce6ec')                             # el fondo, más frío abajo
    for y in range(4, 116):
        c = FONDO[min(4, (y - 4) * 5 // 112)]
        L.hl(4, 147, y, c)
    for x in range(30, 136, 26): L.vl(x, 20, 115, '#e0e9ee')    # los nervios del fondo
    for (x, c) in ((3, '#bccad2'), (4, '#cad6dd'), (5, '#d6e0e6')): L.vl(x, 4, 115, c)          # la pared izquierda
    for (x, c) in ((138, '#d6e0e6'), (139, '#cad6dd'), (140, '#bccad2')): L.vl(x, 4, 115, c)    # la derecha (con el visor)
    L.hl(4, 147, 3, '#b4c2ca'); L.hl(4, 147, 4, '#cdd8de')                                     # el techo
    L.r(62, 3, 28, 4, '#c4ced4'); L.hl(63, 88, 3, '#dbe3e8'); L.r(65, 5, 22, 2, '#fffbe6'); L.hl(66, 85, 5, '#ffffff')   # el plafón
    for (x0, x1, y, c) in ((58, 93, 7, '#f8f8ec'), (54, 97, 8, '#f6f8f0'), (50, 101, 9, '#f5f8f4')): L.hl(x0, x1, y, c)   # su luz
    for y in (8, 10, 12):                                                                         # la rejilla del aire
        L.hl(108, 130, y, '#b8c6ce'); L.hl(108, 130, y + 1, '#fafcfd')
    def balda(y):
        L.hl(4, 137, y, '#bfe0e6'); L.hl(6, 135, y, '#d4eef2')                                   # el canto del cristal
        for x in range(12, 136, 31): L.p(x, y, '#ffffff'); L.p(x + 1, y, '#ffffff')              # sus brillos
        L.hl(4, 137, y + 1, '#fbfcfd'); L.p(4, y + 1, '#e2e8ec'); L.p(137, y + 1, '#e2e8ec')     # el perfil blanco
        L.hl(6, 135, y + 2, '#d2dde3')                                                            # su sombra en el fondo
        L.r(3, y - 1, 3, 3, '#9eb0ba'); L.hl(3, 5, y - 1, '#c2d0d8')                            # las guías
        L.r(138, y - 1, 3, 3, '#9eb0ba'); L.hl(138, 140, y - 1, '#c2d0d8')
    balda(17)                                                                                     # la de GUARDAR
    for s in range(7):                                                                            # siete baldas, una por extracción
        y = 19 + s * 14
        L.r(5, y + 2, 7, 10, '#c6d2d8'); L.r(6, y + 3, 5, 8, '#eef2f4')                         # el portaetiquetas
        if s < 6: balda(y + 13)
    L.hl(4, 147, 116, '#c2ced5'); L.hl(4, 147, 115, '#e8eef2')                                  # el suelo
    L.r(141, 18, 7, 98, '#4a545c'); L.vl(141, 18, 115, '#6a747c'); L.hl(141, 147, 18, '#6a747c')   # el visor de lo lleno que está
    L.r(142, 19, 5, 96, '#1c2428'); L.vl(146, 19, 114, '#283238')
    for y in range(30, 114, 12): L.p(142, y, '#4a6070')                                          # sus marcas
    return L

# ---------- la ventana del elegido ----------
def panel():
    L = Lienzo(60, 100)
    L.r(0, 0, 60, 100, A2); L.hl(1, 58, 1, A4); L.vl(1, 1, 98, A3); L.vl(58, 1, 98, '#1a1c22'); L.hl(1, 58, 98, '#1a1c22')
    L.r(4, 4, 52, 58, A1); L.hl(4, 55, 4, A0); L.vl(4, 4, 61, A0); L.hl(4, 55, 62, A4)
    for y in range(6, 60, 2): L.hl(5, 55, y, '#171a20')                       # el visor, de rayas finas
    for (x0, x1, y) in ((14, 46, 56), (10, 50, 57), (8, 52, 58)): L.hl(x0, x1, y, '#22262e')   # la peana
    for i in range(3):                                                        # las ranuras de las barras
        y = 66 + i * 10
        L.r(3, y - 2, 9, 9, A1); L.r(14, y - 1, 42, 7, A1); L.hl(14, 55, y - 1, A0); L.hl(14, 55, y + 5, A3)
    return L

# ---------- los tarros ----------
# 1.36.1 (lo pidió el usuario: «poco realistas»): tarros de cristal de verdad, con la tapa de rosca estriada más ancha que el
# cuello, los hombros y el culo redondos, el culo de cristal grueso y los brillos; por dentro, el juego pinta lo que llevan
# (alm-cogos: los cogollos apilados, con su escarcha, sus pelos y las grietas entre uno y otro; alm-copa, la de arriba, irregular)
# y la etiqueta de papel escrita a mano (alm-etiqueta)
VI0, VI1, VI2, VI3, VI4 = '#6e8c98', '#8eaab6', '#a8c4ce', '#c8dce4', '#e8f4f8'   # el cristal, de sombra a brillo
def cuerpo(L, w, h, tapa):
    """el cristal de w × h: la tapa (3 filas, si la hay), el cuello (fila 3), los hombros (4) y el culo (h − 2 y h − 1)"""
    if tapa:
        t0, t1, t2 = tapa
        L.hl(3, w - 4, 0, t2); L.p(2, 0, None); L.hl(2, w - 3, 1, t1); L.hl(3, w - 4, 0, t2)
        for x in range(2, w - 2):
            L.p(x, 1, t1 if x % 2 else t0)                                                       # las estrías
            L.p(x, 2, t0)
        L.p(2, 1, t0); L.p(3, 1, t2); L.p(w - 3, 1, t0)
    L.hl(3, w - 4, 3, VI2); L.p(3, 3, VI1); L.p(w - 4, 3, VI0)                                 # el cuello con la rosca
    L.p(1, 4, VI1); L.p(2, 4, VI3); L.p(w - 3, 4, VI2); L.p(w - 2, 4, VI0)                     # los hombros
    L.vl(0, 5, h - 3, VI1); L.vl(w - 1, 5, h - 3, VI0)                                          # los lados
    L.p(1, 5, VI2)
    L.p(1, h - 2, VI1); L.p(w - 2, h - 2, VI0)                                                  # el culo redondo
    L.hl(2, w - 3, h - 1, VI0); L.hl(3, w // 2, h - 1, VI1)                                     # el cristal grueso de abajo
    L.vl(2, 6, h - 5, VI4); L.vl(3, 6, 6 + (h - 12) // 4, VI4)                                  # los brillos
    L.vl(w - 3, 7, 7 + (h - 12) // 3, VI3); L.p(w - 3, h - 4, VI3)

def tarro(tapa):
    """18 × 25 (por dentro: x 1-16, y 4-23)"""
    L = Lienzo(18, 25); cuerpo(L, 18, 25, tapa); return L

def bote():
    """el bote de los extractos, de 12 × 12 (por dentro: x 1-10, y 4-10): bajo, ancho y de boca ancha, con la tapa negra de rosca
    tan ancha como el cristal y el culo grueso"""
    L = Lienzo(12, 12)
    L.hl(2, 9, 0, '#62626e'); L.hl(1, 10, 1, '#2e2e36'); L.hl(1, 10, 2, '#141418'); L.p(2, 1, '#62626e')
    for x in (4, 7, 10): L.p(x, 1, '#1e1e24')                                                   # las estrías
    L.hl(1, 10, 3, VI3); L.p(1, 3, VI1); L.p(10, 3, VI0)                                       # el labio del cristal
    L.vl(0, 3, 9, VI1); L.vl(11, 3, 9, VI0)
    L.p(1, 10, VI1); L.p(10, 10, VI0); L.hl(2, 9, 11, VI0); L.hl(3, 6, 11, VI1)               # el culo, redondo y grueso
    L.vl(2, 5, 8, VI4); L.p(9, 5, VI3); L.p(9, 6, VI3)                                         # los brillos
    return L

def mas():
    """GUARDAR en la caja: el tarro abierto, vacío, con el más verde"""
    L = Lienzo(18, 25)
    L.r(1, 4, 16, 20, '#1d2428')
    cuerpo(L, 18, 25, None)
    L.hl(2, 15, 2, VI1); L.hl(3, 14, 3, VI3)                                                   # la boca abierta
    L.r(8, 9, 3, 11, '#2a5a30'); L.r(4, 13, 11, 3, '#2a5a30')                                  # el más, con su sombra
    L.r(7, 8, 3, 11, '#58d080'); L.r(3, 12, 11, 3, '#58d080'); L.p(7, 8, '#a8f0c0'); L.p(3, 12, '#a8f0c0')
    return L

# los cogollos por dentro (16 × 20): sin color (lo pone el juego, el de la variedad); aquí, solo las grietas oscuras entre
# cogollo y cogollo, la escarcha de los tricomas arriba a la izquierda de cada uno y algún pelo naranja
GRIETA, ESCARCHA, ESCARCHA2, PELO = '#20261c', '#eef2dc', '#c4d0ac', '#d0742a'
NUC = [(3, 1, 3.4), (11, 2, 3.6), (7, 6, 3.4), (1, 8, 3), (14, 8, 3.2), (4, 12, 3.6), (11, 13, 3.4), (1, 18, 3), (8, 18, 3.6), (15, 19, 3)]
def cogos():
    """cada cogollo, de atrás adelante: el borde de abajo y de la derecha en sombra (la grieta con el de delante) y la escarcha
    arriba a la izquierda"""
    L = Lienzo(16, 20); h = lambda x, y: (x * 73 + y * 151 + x * y * 7) % 97
    for (a, b, r) in NUC:
        for y in range(20):
            for x in range(16):
                dx, dy = x - a, y - b; d = (dx * dx + dy * dy) ** .5
                if d > r + .5: continue
                if d > r - .6 and dx + dy > -1.5: L.p(x, y, GRIETA)
                elif d > r - .6: L.p(x, y, ESCARCHA2 if h(x, y) % 2 else None) if L.g(x, y)[3] else None
                elif dx + dy < -1 and d >= 1 and h(x, y) % 3 == 0: L.p(x, y, ESCARCHA)
                elif L.g(x, y)[3]: L.px[x, y] = (0, 0, 0, 0)                                    # lo de detrás queda tapado
    for (x, y) in ((7, 7), (12, 14), (3, 2), (4, 13), (14, 9)): L.p(x, y, PELO)
    return L
def copa():
    """lo de arriba (16 × 3): en el color de dentro del tarro vacío, para que la cima de los cogollos no sea una raya"""
    L = Lienzo(16, 3)
    for x, d in enumerate((2, 1, 0, 0, 1, 2, 1, 0, 0, 0, 1, 2, 1, 0, 1, 2)):
        L.vl(x, 0, d - 1, '#2a343a') if d else None
    return L
def etiqueta():
    """la etiqueta de papel (10 × 4) escrita a mano; el juego le pone el sello verde del curado a la derecha"""
    L = Lienzo(10, 4)
    L.r(0, 0, 10, 4, '#f0ead8'); L.hl(0, 9, 3, '#cfc6aa'); L.vl(9, 0, 3, '#dcd4bc')
    L.hl(1, 5, 1, '#5a5448'); L.p(3, 1, '#f0ead8'); L.hl(1, 3, 2, '#8a8474'); L.hl(5, 6, 2, '#8a8474')
    return L

# las letras de 3 × 5 del botón
LETRAS = {'G': ['###', '#..', '#.#', '#.#', '###'], 'U': ['#.#', '#.#', '#.#', '#.#', '###'], 'A': ['.#.', '#.#', '###', '#.#', '#.#'],
          'R': ['##.', '#.#', '##.', '#.#', '#.#'], 'D': ['##.', '#.#', '#.#', '#.#', '##.'], '+': ['...', '.#.', '###', '.#.', '...']}
def letras(L, x, y, txt, c, sombra):
    for ch in txt:
        if ch == ' ': x += 2; continue
        for j, fila in enumerate(LETRAS[ch]):
            for i, v in enumerate(fila):
                if v == '#': L.p(x + i, y + j + 1, sombra); L.p(x + i, y + j, c)
        x += 4

def guardar():
    L = Lienzo(44, 11)
    L.r(1, 0, 42, 11, '#3f8a46'); L.vl(0, 1, 9, '#3f8a46'); L.vl(43, 1, 9, '#2a5a30')
    L.hl(1, 42, 0, '#58c070'); L.hl(1, 42, 10, '#2a5a30'); L.vl(1, 1, 9, '#58c070')
    letras(L, 5, 3, '+ GUARDAR', '#ffffff', '#24502a')
    return L

def fajo():
    L = Lienzo(15, 8)
    L.r(0, 0, 15, 8, '#4f8f52'); L.hl(0, 14, 0, '#7cc07a')
    for y in (2, 4, 6): L.hl(0, 14, y, '#5f9f62')                            # los billetes, uno sobre otro
    L.hl(0, 14, 7, '#2f5f34'); L.vl(14, 1, 7, '#3f7f44')
    L.r(6, 0, 3, 8, '#e6d58a'); L.vl(8, 0, 7, '#c8b468'); L.p(7, 3, '#b09848')   # la faja
    L.p(2, 3, '#a8e0a0'); L.p(11, 5, '#a8e0a0')
    return L

# ---------- los iconos de las barras (7 × 7) ----------
def icono(n):
    L = Lienzo(7, 7)
    if n == 'thc':      # un tricoma: el tallo y la cabeza de resina
        L.vl(3, 3, 6, '#c8c0a0'); L.r(2, 0, 3, 3, '#f4e8b0'); L.p(2, 0, '#ffffff'); L.p(4, 2, '#d8b040')
    elif n == 'cu':     # un tarro con la tapa
        L.r(1, 0, 5, 1, '#b08a3a'); L.r(1, 1, 5, 6, '#9fb6c0'); L.r(2, 3, 3, 3, '#6fae4a'); L.p(2, 2, '#e4f2f6')
    elif n == 'mc':     # las tijeras
        L.p(1, 0, '#d0d4d8'); L.p(2, 1, '#d0d4d8'); L.p(5, 0, '#d0d4d8'); L.p(4, 1, '#d0d4d8'); L.p(3, 2, '#ffffff')
        L.p(2, 3, '#e06a30'); L.p(4, 3, '#e06a30'); L.r(1, 4, 2, 2, '#e06a30'); L.r(4, 4, 2, 2, '#e06a30'); L.p(1, 4, '#f09060')
    elif n == 'g':      # la pesa
        L.r(2, 0, 3, 1, '#8a8e96'); L.r(1, 1, 5, 1, '#8a8e96'); L.r(0, 2, 7, 5, '#5a5e66'); L.hl(1, 5, 2, '#a8acb4'); L.p(3, 4, '#2a2d34')
    elif n == 'eur':    # la moneda
        L.r(1, 0, 5, 7, '#d8b048'); L.r(0, 1, 7, 5, '#d8b048'); L.hl(1, 5, 0, '#f4d878'); L.vl(0, 1, 5, '#f4d878')
        L.vl(2, 2, 4, '#8a6a2a'); L.hl(3, 4, 2, '#8a6a2a'); L.hl(3, 4, 4, '#8a6a2a'); L.hl(1, 3, 3, '#8a6a2a')
    L.contorno(K)
    return L

def doble(L):
    D = Lienzo(L.im.width * 2, L.im.height * 2)
    D.im = L.im.resize((L.im.width * 2, L.im.height * 2), 0); D.px = D.im.load()
    return D

LATON = ('#8a6a2a', '#b08a3a', '#d8b860')
ORO = ('#c09020', '#f0c040', '#f8e080')
sale('alm-caja', caja()); sale('alm-nevera', nevera()); sale('alm-panel', panel())
sale('alm-tarro', tarro(LATON)); sale('alm-tarro-s', tarro(ORO)); sale('alm-bote', bote()); sale('alm-mas', mas())
sale('alm-guardar', guardar()); sale('alm-fajo', fajo())
sale('alm-cogos', cogos()); sale('alm-copa', copa()); sale('alm-etiqueta', etiqueta())
for n in ('thc', 'cu', 'mc', 'g', 'eur'): sale('alm-ic-' + n, icono(n))
for n in ('alm-tarro', 'alm-tarro-s', 'alm-bote', 'alm-mas', 'alm-fajo', 'alm-cogos', 'alm-copa', 'alm-etiqueta'): sale(n + '-g', doble(SAL[n]))

def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'almacen', n, 'unica'); os.makedirs(d, exist_ok=True)
        for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
        L.im.save(os.path.join(d, '00.png'))
        print('almacen', n, L.im.size, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
