# python3 -I tools/sprites/a-mano/gestos.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.54.1 (lo pidió el usuario: «eso no son sprites en condiciones en el mismo estilo que los muebles del juego»): el plano de cerca
# de cada acción, dibujado a mano con el contorno de los muebles (#2a2a34), la luz arriba a la izquierda y 3-4 tonos por material,
# como el almacén y el móvil. El juego (trama.gd, `_gesto_spr`) compone el fondo y mueve las piezas por el reloj.
#  · Fondos (gs_fondo, 128 × 80, ancla arriba a la izquierda): gs-f-carpa (la carpa plateada por dentro, con la bandeja y la luz),
#    gs-f-mesa (la mesa de la tía contra la pared), gs-f-cuarto (el salón de noche, el sofá), gs-f-calle (la pared de ladrillo y la
#    acera), gs-f-cama-n y gs-f-cama-d (la cama de noche y de siesta), gs-f-huerta (la huerta al sol); acc-f-<cerradura>
#    (acc_fondo, 104 × 84), la puerta de cada cerradura y la persiana de la nave.
#  · Piezas (gs_g 48 × 48, gs_m 24 × 24, gs_s 8 × 8): la maceta de tela, seca y regada, la tierra de la huerta (gs-tierra), la
#    planta en vegetativo y en flor, el brote, las manos con la regadera, el pulverizador, la botella de abono, el esqueje, las
#    tijeras de podar, el cogollo con hojas y pelado, el pincel, el porro, la pipa, el bong, el vapo, el mechero, el humo,
#    la bolsita, los billetes, la cabeza dormida y la Z.
# Sale a art/crudo/gestos/<sprite>/unica/00.png (después, node tools/sprites/procesar.js gestos --atlas --atlas-dir godot/arte)
import os, sys, glob, math
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

K = '#2a2a34'
SAL = {}
def sale(n, L): SAL[n] = L

# ── rampas, de sombra a brillo ──
PIEL = ('#8a5a3c', '#b07a54', '#d09a70', '#e8bc94')
MANGA = ('#6a1c22', '#9a2a32', '#c83c44', '#e86a6a')        # la sudadera roja del protagonista
MANGA_C = ('#1e3a5a', '#2a5080', '#3a6aa8', '#6a9ad0')      # el cliente, de azul
HOJA = ('#1e3a1a', '#2f5a26', '#4f8a3a', '#78b450', '#a8d878')
TALLO = ('#3a5a24', '#5a7a34', '#7a9a48')
COG = ('#4a6a2a', '#6a8e3a', '#8ab456', '#b4d47c')
PISTILO = ('#a8582a', '#d9853a', '#f0a858')
TRICOMA = '#f4f0dc'
TIERRA = ('#2a1e16', '#3e2c1e', '#56402a', '#6e5236')
MOJADA = ('#1a120c', '#2a1e14', '#3a2a1c', '#4a3624')
TELA = ('#18181e', '#26262e', '#363640', '#4a4a56')
MET = ('#4a525e', '#6e7884', '#9aa6b2', '#cad4dc')          # el metal galvanizado
AGUA = ('#2a5a9a', '#3a6ab0', '#7aaae0', '#d0e8ff')
MYLAR = ('#7a808a', '#9aa0aa', '#b8bec8', '#d8dce4', '#eef0f4')
MAD = ('#5a3a20', '#8a5a32', '#c8935a', '#e0b07a')
VIDRIO = ('#6a8a94', '#9ab8c0', '#c4dce2', '#eef8fa')
HUMO = ('#8a8a94', '#aeaeb8', '#d0d0d8', '#ececf0')
BRASA = ('#8a2010', '#e04a20', '#f8a040', '#fff0a0')
BILLETE = ('#4a6a3a', '#6a9050', '#9cc07a', '#cfe4b0')      # el de 50, verde pálido, sin marca
BOLSA = ('#9aa8b0', '#c4d0d6', '#e4ecf0', '#ffffff')


def lz(w, h):
    return Lienzo(w, h)


def tono(r, v):
    """el color de la rampa r para un valor de luz v de 0 a 1"""
    return r[min(len(r) - 1, max(0, int(v * len(r))))]


def ovalo(L, cx, cy, rx, ry, r, luz=0.0, solo=None):
    """un óvalo sombreado como una bola: la luz arriba a la izquierda; luz suma brillo"""
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            nx, ny = (x + .5 - cx) / rx, (y + .5 - cy) / ry
            d = nx * nx + ny * ny
            if d > 1: continue
            if solo and not solo(x, y): continue
            nz = math.sqrt(1 - d)
            v = .5 + .45 * (-.55 * nx - .65 * ny) + .25 * nz - .2 + luz
            L.p(x, y, tono(r, v))


def caja(L, x, y, w, h, r, lado=True):
    """un bloque de frente: cara con su canto de luz arriba y a la izquierda, sombra abajo y a la derecha"""
    L.r(x, y, w, h, r[1])
    L.hl(x, x + w - 1, y, r[-1]); L.vl(x, y, y + h - 1, r[2])
    L.hl(x, x + w - 1, y + h - 1, r[0]); L.vl(x + w - 1, y + 1, y + h - 1, r[0])


def con(L):
    L.contorno(K)
    return L


def pieza(w, h, fn):
    L = lz(w, h); fn(L); return con(L)


def linea(L, x0, y0, x1, y1, c, g=1):
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for k in range(int(n) + 1):
        f = k / n
        L.r(round(x0 + (x1 - x0) * f), round(y0 + (y1 - y0) * f), g, g, c)


# ── las manos ──
def mano_puno(L, x, y, r=PIEL, manga=MANGA, izq=False, puno=True):
    """una mano cerrada de lado (13 × 10) que agarra algo, con el puño de la manga detrás; (x, y) arriba a la izquierda de la mano"""
    s = -1 if izq else 1
    mx = x + (13 if not izq else -8)
    # la manga
    for j in range(10):
        for i in range(9):
            xx = mx + i * (1 if not izq else 1)
            L.p(xx, y - 1 + j, tono(manga, .75 - j * .06 - (i * .03 if not izq else (8 - i) * .03)))
    L.vl(mx if not izq else mx + 8, y - 1, y + 8, manga[0])
    # la mano: el dorso redondo y los nudillos
    ovalo(L, x + 7, y + 4.5, 7, 5.2, r)
    for k in range(4):   # los dedos doblados, hacia abajo
        fx = x + 2 + k * 3
        L.r(fx, y + 6, 3, 3, r[1] if k % 2 else r[2]); L.p(fx, y + 6, r[3]); L.p(fx + 2, y + 8, r[0])
    if puno:
        L.r(x + 1, y + 2, 2, 4, r[1]); L.p(x + 1, y + 2, r[2])   # el pulgar por delante


def brazo(L, x0, y0, x1, y1, manga, g=8):
    """el antebrazo en manga, de (x0, y0) a (x1, y1), con su luz arriba"""
    n = max(abs(x1 - x0), abs(y1 - y0), 1)
    for k in range(int(n) + 1):
        f = k / n
        cx, cy = x0 + (x1 - x0) * f, y0 + (y1 - y0) * f
        for j in range(g):
            L.p(round(cx), round(cy) + j, tono(manga, .85 - j / g * .8))


# ── la maceta y las plantas ──
KEY = {(128, 16, 122, 255): '#4e7a2e', (208, 32, 200, 255): '#86b44e', (255, 92, 255, 255): '#c2e088'}   # la rampa clave del cogollo, en verde


def de_png(*ruta):
    """un sprite ya procesado de la vista C (art/procesado), con los cogollos de la rampa clave en un verde de cogollo"""
    im = Image.open(P('art', 'procesado', *ruta)).convert('RGBA')
    L = lz(*im.size)
    for y in range(im.height):
        for x in range(im.width):
            c = im.getpixel((x, y))
            if c[3] > 127: L.p(x, y, KEY.get((c[0], c[1], c[2], 255), (c[0], c[1], c[2], 255)))
    return L


def maceta(moj=False):
    """la maceta de tela de 11 L de la vista C (32 × 32), seca o recién regada: la tierra más oscura y con brillos"""
    L = de_png('carpa-c-macetas-b', 'maceta-c-tela11-26', 'unica', '00.png')
    if moj:
        x0, y0, x1, y1 = L.im.getbbox()
        for y in range(y0, y0 + 7):
            for x in range(x0, x1):
                r, g, b, a = L.g(x, y)
                if a and r > g > b and r - b > 12:
                    L.p(x, y, (int(r * .6), int(g * .58), int(b * .6), 255))
        for (dx, dy) in ((6, 3), (12, 4), (18, 3), (22, 4)):
            if L.g(x0 + dx, y0 + dy)[3]: L.p(x0 + dx, y0 + dy, AGUA[2])
    return L

def hoja_palmeada(L, cx, cy, s, ang, r=HOJA, n=5):
    """una hoja de cannabis (n foliolos) desde (cx, cy), de largo s, abierta hacia ang (radianes)"""
    for k in range(n):
        a = ang + (k - (n - 1) / 2) * .42
        largo = s * (1 - abs(k - (n - 1) / 2) * .22)
        for i in range(int(largo)):
            f = i / max(largo, 1)
            ancho = max(0, int(2.4 * math.sin(f * math.pi)))
            px, py = cx + math.cos(a) * i, cy + math.sin(a) * i
            for w in range(-ancho, ancho + 1):
                qx, qy = px - math.sin(a) * w * .8, py + math.cos(a) * w * .8
                v = .55 + (-.3 * w / 3) + (.15 if k < n / 2 else -.05) - f * .1
                L.p(round(qx), round(qy), tono(r[1:], v))
            L.p(round(px), round(py), r[1] if i > 1 else r[0])       # el nervio


def planta(flor=False):
    """la planta A de la vista C (40 × 96, el pie en la fila 95): en vegetativo la más alta, en flor la de 52 px"""
    if flor: return de_png('carpa-c-plantas-a', 'planta-c-h-38', 'unica', '10.png')
    return de_png('carpa-c-plantas-a', 'planta-c-h2-38', 'unica', '00.png')

def brote():
    """el brote de la vista C (40 × 96, el pie en la fila 95)"""
    return de_png('carpa-c-plantas-a', 'planta-c-h1-18', 'unica', '00.png')

# ── las herramientas ──
def regadera(incl):
    """la mano con la regadera de metal (48 × 48), recta (0) o inclinada (1), el pitorro a la izquierda"""
    L = lz(48, 48)
    C = lz(48, 48)   # la regadera sola, para girarla
    caja(C, 18, 20, 18, 16, MET)
    for y in range(21, 35): C.p(19, y, MET[3]); C.p(34, y, MET[0])
    C.hl(19, 34, 26, MET[2]); C.hl(19, 34, 27, MET[0])               # el aro
    linea(C, 18, 32, 5, 20, MET[1], 2); linea(C, 18, 33, 6, 21, MET[0])   # el pitorro
    C.r(2, 17, 4, 5, MET[2]); C.vl(2, 17, 21, MET[0]); C.hl(2, 5, 17, MET[3])   # la alcachofa
    for k in range(3): C.p(2, 18 + k, MET[0])
    for a in range(0, 180, 6):   # el asa de arriba
        x = 27 + math.cos(math.radians(a)) * 8; y = 20 - math.sin(math.radians(a)) * 9
        C.r(round(x), round(y), 2, 1, MET[1] if a > 90 else MET[2])
    con(C)
    g = math.radians(28 if incl else 0)
    for y in range(48):   # el giro, alrededor del asa
        for x in range(48):
            sx = 27 + (x - 27) * math.cos(g) - (y - 18) * math.sin(g)
            sy = 18 + (x - 27) * math.sin(g) + (y - 18) * math.cos(g)
            c = C.g(int(round(sx)), int(round(sy)))
            if c[3]: L.px[x, y] = c
    mano_puno(L, 20, 6)
    return con(L)


def spray(apreta):
    """la mano con el pulverizador blanco (48 × 48), la boquilla a la izquierda; apreta: el gatillo dentro"""
    L = lz(48, 48)
    B = ('#9aa0a8', '#c8ccd2', '#e8eaee', '#ffffff')
    caja(L, 20, 18, 12, 24, B)                                       # la botella
    for y in range(26, 41): L.p(21, y, B[3])
    L.r(21, 30, 10, 10, '#7ab0d8'); L.hl(21, 30, 30, '#a8d0f0'); L.vl(30, 30, 39, '#5a8ab8')   # el líquido
    L.r(22, 12, 9, 6, '#c03a3a'); L.hl(22, 30, 12, '#e86060'); L.vl(30, 13, 17, '#8a2020')   # el cabezal rojo
    L.r(13, 13, 9, 3, '#c03a3a'); L.hl(13, 21, 13, '#e86060'); L.p(12, 14, '#4a1a1a')        # la boquilla
    gx = 21 if apreta else 18
    L.r(gx, 17, 2, 6, '#8a2020'); L.p(gx, 17, '#c03a3a')                              # el gatillo
    con(L)
    mano_puno(L, 22, 16)
    return con(L)


def botella(incl):
    """la botella de abono (24 × 24) con su etiqueta sin marca, recta o volcada hacia la izquierda"""
    C = lz(24, 24)
    G = ('#1e4a2a', '#2a6a3a', '#3a8a4c', '#6ab07a')
    caja(C, 7, 8, 10, 14, G)
    for y in range(9, 21): C.p(8, y, G[3])
    C.r(9, 4, 6, 4, G[1]); C.hl(9, 14, 4, G[2])                      # el cuello
    C.r(9, 2, 6, 2, '#e8e0c8'); C.hl(9, 14, 2, '#ffffff')            # el tapón
    C.r(8, 12, 8, 6, '#f0e8d0'); C.hl(8, 15, 12, '#ffffff'); L2 = C   # la etiqueta, con una hoja dibujada
    for (x, y) in ((11, 14), (12, 13), (13, 14), (12, 15), (12, 16)): L2.p(x, y, '#4f8a3a')
    con(C)
    if not incl: return C
    L = lz(24, 24)
    for y in range(24):
        for x in range(24):   # 90° a la izquierda: la boca abajo a la izquierda
            c = C.g(y, 23 - x)
            if c[3]: L.px[x, y] = c
    return L


def tijeras(abiertas):
    """las tijeras de podar (24 × 24), las hojas a la izquierda y los mangos naranjas a la derecha"""
    L = lz(24, 24)
    a = 4 if abiertas else 0
    for i in range(10):   # las hojas
        L.p(2 + i, 11 - a + (a * i) // 10, MET[3] if i < 8 else MET[2]); L.p(2 + i, 12 - a + (a * i) // 10, MET[1])
        L.p(2 + i, 13 + a - (a * i) // 10, MET[2]); L.p(2 + i, 14 + a - (a * i) // 10, MET[0])
    L.r(11, 11, 3, 4, MET[1]); L.p(12, 12, MET[3])                   # el eje
    O = ('#8a3a10', '#c85a1c', '#f08030', '#f8b070')
    for i in range(9):   # los mangos
        L.r(14 + i, 10 - i // 3 - (a // 2), 2, 2, tono(O, .7 - i * .04))
        L.r(14 + i, 14 + i // 3 + (a // 2), 2, 2, tono(O, .5 - i * .04))
    return con(L)


def esqueje():
    """el esqueje cortado (24 × 24): el tallo en bisel y dos hojas"""
    L = lz(24, 24)
    linea(L, 12, 22, 12, 6, TALLO[1]); L.vl(13, 8, 21, TALLO[2]); L.p(11, 22, TALLO[0])
    hoja_palmeada(L, 12, 10, 8, -2.4, n=5); hoja_palmeada(L, 13, 8, 7, -.7, n=5); hoja_palmeada(L, 12, 5, 4, -math.pi / 2, n=3)
    return con(L)


def vaso():
    """el vaso de agua para los esquejes (24 × 24)"""
    L = lz(24, 24)
    for y in range(6, 23):
        for x in range(6, 18):
            L.p(x, y, VIDRIO[2] if y < 11 else AGUA[2] if x > 7 else AGUA[3])
    L.vl(6, 6, 22, VIDRIO[3]); L.vl(17, 6, 22, VIDRIO[0]); L.hl(6, 17, 22, VIDRIO[0]); L.hl(6, 17, 11, AGUA[3])
    return con(L)


def cola(pelada=False):
    """la cola de cogollos (32 × 32) con las hojitas de azúcar (sin pelar) o limpia, con su rabito"""
    L = lz(32, 32)
    ovalo(L, 16, 12, 8, 10.5, COG)
    ovalo(L, 12, 19, 5.5, 6, COG, -.08)
    ovalo(L, 20, 17, 4.5, 5, COG, -.04)
    R = azar(91)
    for k in range(150):
        x, y = int(7 + R() * 18), int(2 + R() * 23)
        if L.lleno(x, y):
            q = R()
            L.p(x, y, PISTILO[int(R() * 3)] if q < .4 else TRICOMA if q < .62 else COG[3] if q < .8 else COG[0])
    L.vl(16, 24, 31, TALLO[1]); L.vl(17, 25, 30, TALLO[2])
    if not pelada:
        hoja_palmeada(L, 9, 15, 9, 2.7, n=3); hoja_palmeada(L, 23, 11, 9, -.35, n=3)
        hoja_palmeada(L, 11, 6, 6, -2.3, n=3); hoja_palmeada(L, 22, 21, 6, .5, n=3)
    return con(L)

def hojita():
    L = lz(8, 8)
    hoja_palmeada(L, 1, 6, 6, -.7, n=3)
    return con(L)


def pincel():
    """el pincel con el polen amarillo (24 × 24), la punta abajo a la izquierda"""
    L = lz(24, 24)
    linea(L, 8, 15, 21, 2, MAD[2], 2); linea(L, 9, 16, 22, 3, MAD[1])
    L.r(5, 14, 4, 4, MET[2]); L.p(5, 14, MET[3])
    for (x, y) in ((2, 18), (3, 19), (2, 20), (4, 18), (3, 21), (1, 19)): L.p(x, y, '#f0d040')
    L.r(3, 17, 3, 3, '#e0c030'); L.p(1, 21, '#f8e870')
    return con(L)


def gota():
    L = lz(8, 8)
    L.p(3, 1, AGUA[2]); L.r(2, 2, 3, 3, AGUA[1]); L.p(2, 2, AGUA[3]); L.hl(3, 4, 5, AGUA[0])
    return con(L)


def bruma(n):
    L = lz(24, 24)
    R = azar(5 + n)
    for k in range(5 + n * 3):
        ovalo(L, 4 + R() * 16, 6 + R() * 12, 2 + n * .6, 2 + n * .5, ('#c8dce8', '#dcecf4', '#f0f8fc'), .3)
    return con(L) if n == 0 else L


def bicho():
    L = lz(8, 8)
    L.r(3, 3, 2, 2, '#c03020'); L.p(3, 3, '#f06040'); L.p(2, 5, '#5a1010'); L.p(5, 5, '#5a1010'); L.p(2, 2, '#5a1010'); L.p(5, 2, '#5a1010')
    return L


# ── fumar ──
def porro():
    """la mano con el porro (48 × 24), la punta a la izquierda; la brasa la pone el juego"""
    L = lz(48, 24)
    for x in range(6, 26):   # el papel, un cono
        t = 2 if x < 18 else 1
        for y in range(11 - t, 12 + t):
            L.p(x, y, '#f4f0e6' if y < 11 else '#d8d2c4')
    L.r(24, 10, 4, 3, '#c8a878'); L.hl(24, 27, 10, '#e0c898')                # la boquilla de cartón
    L.r(4, 10, 2, 3, '#4a3a2a')                                                # la punta quemada
    con(L)
    mano_puno(L, 25, 6)
    return con(L)


def pipa():
    """la mano con la pipa de madera de una pieza (48 × 24): la cazoleta a la izquierda (la boca en (10, 5)), la caña que sale de su
    pie y la boquilla negra; la pipa por delante de los dedos, de un solo contorno"""
    L = lz(48, 24)
    mano_puno(L, 18, 14)   # la mano la coge por debajo de la caña, junto a la cazoleta
    con(L)
    c = lz(48, 24)
    for y in range(5, 18):   # la cazoleta: recta y con el culo redondo
        f = (y - 5) / 12
        rx = 5.2 if y <= 12 else 5.2 * math.sqrt(max(0, 1 - ((y - 12) / 5.6) ** 2))
        for x in range(4, 17):
            nx = (x + .5 - 10) / rx
            if abs(nx) > 1: continue
            c.p(x, y, tono(MAD, .72 - .35 * nx - .25 * f))
    c.hl(5, 15, 5, '#2a1a10'); c.hl(6, 14, 6, '#1a100a')                         # la boca, con lo de dentro
    c.p(6, 5, MAD[3]); c.p(14, 5, MAD[2])
    for x in range(14, 30):   # la caña, que sale del pie de la cazoleta y sube un poco
        y = 14 - (x - 14) * 2 // 16
        c.p(x, y, MAD[3]); c.p(x, y + 1, MAD[2]); c.p(x, y + 2, MAD[1])
    for x in range(30, 41):   # la boquilla negra, más fina, con su labio
        y = 12 - (x - 30) // 6
        c.p(x, y, '#4a4a54'); c.p(x, y + 1, '#1e1e24')
    c.r(29, 12, 1, 3, '#c8935a')                                                  # el anillo entre la caña y la boquilla
    c.p(41, 10, '#4a4a54'); c.p(41, 11, '#2a2a30')
    L.pega(con(c), 0, 0)
    return L


def bong():
    """el bong de cristal en la mesa (48 × 48), de pie: la base, el agua, el tubo y la cazoleta a la izquierda"""
    L = lz(48, 48)
    for y in range(30, 46):   # la base redonda
        f = (y - 30) / 16
        hw = int(6 + 9 * math.sin(f * math.pi / 2 + .3))
        for x in range(24 - hw, 24 + hw):
            v = .6 - (x - 24 + hw) / (2 * hw) * .5
            L.p(x, y, tono(VIDRIO, v) if y < 36 else tono(AGUA, v + .2))
    for y in range(4, 31):   # el tubo
        for x in range(19, 29):
            L.p(x, y, tono(VIDRIO, .75 - (x - 19) * .05))
    L.vl(20, 4, 44, VIDRIO[3]); L.hl(18, 29, 4, VIDRIO[3])
    linea(L, 16, 36, 9, 29, VIDRIO[1], 2)                                       # el tubo de la cazoleta
    L.r(5, 25, 6, 4, MET[1]); L.hl(5, 10, 25, MET[3]); L.r(6, 24, 4, 1, '#3a5a2a')   # la cazoleta con la hierba
    return con(L)


def vapo(led):
    """el vapo en la mano (48 × 24): el cuerpo negro con su piloto y la boquilla a la izquierda"""
    L = lz(48, 24)
    V = ('#14141a', '#24242c', '#3a3a46', '#5a5a68')
    caja(L, 8, 7, 18, 10, V)
    L.r(4, 9, 4, 6, '#c8ccd2'); L.hl(4, 7, 9, '#ffffff')
    L.r(14, 11, 2, 2, '#58e080' if led else '#1e4a2a')
    con(L)
    mano_puno(L, 24, 6)
    return con(L)


def mechero(llama):
    """el mechero de piedra en la mano (24 × 24), con la llama encima si llama"""
    L = lz(24, 24)
    caja(L, 7, 12, 8, 11, ('#6a1a7a', '#9a2aaa', '#c050d0', '#e090f0'))
    L.r(7, 9, 8, 3, MET[2]); L.hl(7, 14, 9, MET[3]); L.r(12, 8, 3, 2, MET[0])
    if llama:
        L.r(9, 5, 3, 4, BRASA[2]); L.r(10, 3, 1, 3, BRASA[3]); L.p(10, 7, '#5a8af0'); L.p(9, 5, BRASA[1])
    return con(L)


def humo(n):
    """una bocanada (24 × 24): de pequeña (0) a deshecha (2)"""
    L = lz(24, 24)
    if n == 0:
        ovalo(L, 12, 14, 4, 3.5, HUMO); ovalo(L, 15, 11, 3, 3, HUMO, .1)
    elif n == 1:
        ovalo(L, 10, 14, 5, 4, HUMO); ovalo(L, 15, 10, 5, 4.5, HUMO, .1); ovalo(L, 8, 9, 3, 3, HUMO, .15)
    else:
        for (x, y, r) in ((6, 15, 4), (13, 8, 5), (18, 15, 4), (11, 15, 3)):
            ovalo(L, x, y, r, r * .8, HUMO[1:], .15)
    return con(L) if n < 2 else L


def burbuja():
    L = lz(8, 8)
    L.p(3, 2, VIDRIO[3]); L.p(2, 3, VIDRIO[3]); L.p(4, 3, VIDRIO[1]); L.p(3, 4, VIDRIO[1])
    return L


# ── vender y pagar ──
def bolsita(manga=MANGA):
    """tu mano con la bolsita zip (48 × 24): los cogollos dentro y el cierre rojo"""
    L = lz(48, 24)
    caja(L, 4, 6, 14, 13, BOLSA)
    L.hl(4, 17, 8, '#d04040'); L.hl(4, 17, 9, '#ffffff')
    ovalo(L, 9, 14, 3.5, 3, COG); ovalo(L, 14, 15, 2.5, 2.5, COG, .1)
    for (x, y) in ((8, 13), (10, 15), (14, 14)): L.p(x, y, PISTILO[1])
    con(L)
    mano_puno(L, 15, 7, manga=manga)
    return con(L)


def billete(fajo=1):
    """un billete de 50 sin marca (20 × 10 en 24 × 24); fajo: unos cuantos uno encima de otro"""
    L = lz(24, 24)
    for k in range(fajo):
        y = 12 - k * 2
        caja(L, 2, y, 20, 10, BILLETE)
        L.r(9, y + 3, 6, 4, BILLETE[2]); L.p(11, y + 4, BILLETE[0]); L.p(12, y + 5, BILLETE[0])
        L.p(4, y + 2, BILLETE[0]); L.p(19, y + 7, BILLETE[0])
    return con(L)


def mano_billete(manga=MANGA_C):
    """la mano del cliente, de azul, con el billete (48 × 24), los dedos a la derecha (con manga=MANGA, la tuya, en espejo)"""
    L = lz(48, 24)
    caja(L, 26, 7, 16, 9, BILLETE); L.r(31, 9, 6, 4, BILLETE[2])
    con(L)
    M = lz(48, 24)
    mano_puno(M, 18, 7, manga=manga)
    M = con(M).espejo()
    L.pega(M, 0, 0)
    return L


def mano_abierta():
    """tu mano abierta, de frente, para contar (24 × 24)"""
    L = lz(24, 24)
    ovalo(L, 12, 15, 6, 6, PIEL)
    for k in range(4): L.r(7 + k * 3, 4 + int(abs(k - 1.5) * 1.4), 2, 9, PIEL[2 if k % 2 else 3]); L.p(8 + k * 3, 12, PIEL[1])
    L.r(4, 12, 3, 6, PIEL[2])
    for y in range(20, 24): L.hl(8, 16, y, MANGA[2] if y == 20 else MANGA[1])
    return con(L)


def semilla():
    """1.57.2 (lo pidió el usuario: «sería mejor echar una semilla al sembrar»): la semilla de cannabis (8 × 8), un óvalo pardo con
    las vetas oscuras"""
    L = lz(8, 8)
    for y, (x0, x1) in enumerate(((3, 4), (2, 5), (2, 5), (2, 5), (3, 4))):
        L.hl(x0, x1, y + 1, '#8a6a42')
    L.p(3, 2, '#b8955e'); L.p(3, 3, '#a8854e')
    L.p(4, 2, '#4a3420'); L.p(5, 3, '#4a3420'); L.p(2, 4, '#5a4028'); L.p(4, 4, '#5a4028'); L.p(3, 5, '#4a3420')
    return con(L)


def mano_pinza(abierta):
    """la mano que coge la semilla con el índice y el pulgar, desde arriba (24 × 24); abierta, los dedos se separan y la suelta"""
    L = lz(24, 24)
    for y in range(0, 6): L.hl(8, 16, y, MANGA[1] if y < 5 else MANGA[0])
    L.hl(9, 14, 1, MANGA[2])
    ovalo(L, 12, 10, 5, 4, PIEL)
    s = 2 if abierta else 0
    for y in range(12, 20):                                        # el índice, a la izquierda
        L.hl(9 - (s if y > 15 else 0), 10 - (s if y > 15 else 0), y, PIEL[2])
    L.p(9 - s, 19, PIEL[3])
    for y in range(12, 19):                                        # el pulgar, a la derecha
        L.hl(13 + (s if y > 15 else 0), 14 + (s if y > 15 else 0), y, PIEL[1] if y > 16 else PIEL[2])
    for k in range(2): L.vl(11 + k, 13, 14 + k, PIEL[1])           # los nudillos de los otros dedos, doblados
    return con(L)


# ── dormir ──
def dormido(resp):
    """el protagonista dormido en la cama de cerca (128 × 66, en el panel en (16, 30)): de lado, la mejilla en la almohada, el pelo
    hacia el cabecero, los ojos cerrados, la nariz y la oreja; el edredón tapado hasta la barbilla con la forma del cuerpo (el
    hombro, la cintura, la cadera, las rodillas y los pies), el embozo de la sábana y el brazo por encima; resp: el pecho arriba"""
    W, H = 128, 66
    D = ('#22325a', '#2e4478', '#3e5a9a', '#5a78b8')                            # el mismo edredón que el fondo
    PELO = ('#2a1a10', '#4a2e1a', '#6a4426', '#8a5c36')
    cab = lz(W, H)
    ovalo(cab, 20, 17, 9.5, 8.5, PELO)                                          # el pelo, hacia el cabecero
    ovalo(cab, 24.5, 19, 7.5, 6.5, PIEL, luz=.05)                                # la cara, de lado sobre la almohada
    for x in range(21, 30): cab.p(x, 13 - (1 if 23 < x < 28 else 0), PELO[2])   # el flequillo
    for x in range(22, 27): cab.p(x, 14, PELO[1])
    ovalo(cab, 20.5, 20, 2, 2.5, PIEL, luz=-.25); cab.p(20, 20, PIEL[0])         # la oreja
    for (x, y) in ((25, 17), (26, 18), (27, 18), (28, 17)): cab.p(x, y, '#4a2e22')   # el ojo cerrado
    cab.p(29, 16, '#4a2e22')
    for x in range(25, 29): cab.p(x, 15, PELO[1])                               # la ceja
    cab.p(32, 18, PIEL[2]); cab.p(32, 19, PIEL[1]); cab.p(31, 20, PIEL[0])      # la nariz
    cab.p(28, 20, '#e0a080'); cab.p(27, 20, '#e8b090')                          # la mejilla
    cab.p(29, 23, '#a85a4a'); cab.p(30, 23, '#8a4a3a')                          # la boca
    con(cab)
    sh = -1 if resp else 0
    pts = [(0, 28), (26, 28), (30, 25), (36, 19 + sh), (42, 18 + sh), (50, 22 + sh), (58, 25), (66, 22), (75, 20), (84, 22), (96, 25),
           (108, 26), (114, 24), (119, 23), (124, 26), (127, 28)]
    def arriba(x):
        for a, b in zip(pts, pts[1:]):
            if a[0] <= x <= b[0]:
                f = (x - a[0]) / max(1, b[0] - a[0])
                f = (1 - math.cos(f * math.pi)) / 2
                return a[1] + (b[1] - a[1]) * f
        return 28
    e = lz(W, H)
    for x in range(2, W):
        t = round(arriba(x)); d = arriba(x + 1) - arriba(x - 1)
        for y in range(t, H):
            v = .64 - max(0, y - 30) / 40 * .28 + (.12 if y - t < 2 else (.05 if y < 30 else 0))
            e.p(x, y, tono(D, v))
        e.p(x, t, D[3])
        if x < 31:   # el embozo de la sábana, doblado sobre el edredón
            for k in range(3): e.p(x, t + k, ('#ffffff', '#e4e8f0', '#b8bccc')[k])
    con(e)
    b = lz(W, H)   # el brazo por encima del edredón, del hombro a la cintura, con la mano
    brazo(b, 37, 19 + sh, 55, 24 + sh, MANGA, g=5)
    ovalo(b, 58.5, 26.5 + sh, 3.5, 2.6, PIEL)
    for k in range(3): b.p(56 + k, 28 + sh, PIEL[1])
    con(b)
    L = lz(W, H)
    L.pega(cab, 0, 0); L.pega(e, 0, 0); L.pega(b, 0, 0)
    return L


def zeta():
    L = lz(8, 8)
    for x in range(1, 7): L.p(x, 1, '#e8ecff'); L.p(x, 6, '#c8d0f0')
    for k in range(4): L.p(5 - k, 2 + k, '#e8ecff')
    return con(L)


# ── los fondos (128 × 80) ──
def f_carpa():
    """la carpa plateada de la vista C, de cerca: la pared del fondo y el suelo con su cuadrícula (144 × 96)"""
    P0 = de_png('carpa-c-fondo', 'carpa-c-pared', 'unica', '00.png')
    return P0.recorta(48, 64, 144, 96)

def f_mesa():
    """la mesa de madera de la tía contra la pared del piso (144 × 96): el tablero visto un poco desde arriba"""
    L = lz(144, 96)
    for y in range(46):   # la pared crema con su textura de gotelé y el zócalo
        for x in range(144):
            L.p(x, y, '#e8dcc0' if (x * 7 + y * 13) % 23 else '#dccfb0')
    L.r(0, 40, 144, 6, '#c8b490'); L.hl(0, 143, 40, '#f4ecd8'); L.hl(0, 143, 45, '#a89470')
    R = azar(23)
    for y in range(46, 86):   # el tablero, las tablas a lo largo con sus vetas
        for x in range(144):
            t = (y - 46) // 10                                                 # la tabla
            veta = (x + t * 37 + int(3 * math.sin(y * .7 + t))) % 23
            c = MAD[2] if t % 2 == 0 else '#bc8a52'
            if veta in (0, 11) or R() < .015: c = MAD[1]
            if y - 46 - t * 10 == 1: c = MAD[3]
            L.p(x, y, c)
    for y in (56, 66, 76): L.hl(0, 143, y, MAD[1])
    L.hl(0, 143, 46, MAD[0])
    L.r(0, 86, 144, 10, MAD[1]); L.hl(0, 143, 86, MAD[3]); L.hl(0, 143, 95, MAD[0])   # el canto de delante
    return L

def f_cuarto():
    """el salón a media luz (144 × 96): la ventana de noche, la lámpara de pie y el sofá azul de la casa"""
    L = lz(144, 96)
    for y in range(96):
        for x in range(144):
            L.p(x, y, '#3a3448' if y < 58 else '#4a3a30')
    L.r(0, 54, 144, 4, '#2a2436'); L.hl(0, 143, 54, '#4a4458')                  # el zócalo
    for y in range(58, 96, 6): L.hl(0, 143, y, '#3e3028')                      # la tarima
    caja(L, 12, 8, 36, 30, ('#3a2a1a', '#5a3e26', '#7a5a38', '#9a7a50'))        # la ventana
    for x in range(14, 46):
        for y in range(10, 36):
            L.p(x, y, '#1a2448' if (x * 3 + y) % 11 else '#22305a')
    L.r(14, 22, 32, 2, '#5a3e26'); L.r(29, 10, 2, 26, '#5a3e26')
    for (x, y) in ((17, 13), (40, 12), (23, 31), (42, 28), (35, 33)): L.p(x, y, '#f0f0ff')
    ovalo(L, 38, 16, 3, 3, ('#c8c890', '#f0f0c0', '#ffffe8'))
    for y in range(4, 54):   # la luz cálida de la lámpara en la pared, en trama
        for x in range(100, 144):
            d = math.hypot((x - 124) / 22, (y - 16) / 40)
            if d < 1 and (x + y) % 2 == 0: L.p(x, y, '#5a4a48' if d < .6 else '#4a4048')
    lamp = lz(144, 96)
    lamp.r(123, 20, 2, 46, '#2a2a30')                                           # el pie
    lamp.r(118, 64, 12, 2, '#2a2a30')
    for y in range(8, 20):                                                      # la pantalla
        hw = 4 + (y - 8) // 2
        for x in range(124 - hw, 124 + hw):
            lamp.p(x, y, tono(('#c8a060', '#e8c080', '#f8e0a8'), .9 - (x - 124 + hw) / (2 * hw) * .6))
    lamp.hl(118, 129, 19, '#fff0c0')
    L.pega(con(lamp), 0, 0)
    S = ('#22305a', '#2e4478', '#3e5a9a', '#5a78b8')                            # el sofá
    so = lz(144, 96)
    caja(so, 52, 42, 64, 22, S)                                                 # el respaldo
    for x in (72, 93): so.vl(x, 44, 62, S[0])
    caja(so, 48, 58, 72, 18, S)                                                 # el asiento
    so.hl(49, 118, 59, S[3]); so.vl(84, 60, 74, S[0])
    caja(so, 44, 50, 9, 28, S); caja(so, 115, 50, 9, 28, S)                     # los brazos
    so.r(50, 78, 3, 4, '#2a1a10'); so.r(116, 78, 3, 4, '#2a1a10')               # las patas
    L.pega(con(so), 0, 0)
    return L

def f_calle():
    """la pared de ladrillo de un portal y la acera (144 × 96), con la bajante y el bordillo"""
    L = lz(144, 96)
    R = azar(31)
    for y in range(66):
        for x in range(144):
            fila = y // 6; dx = 6 if fila % 2 else 0
            if y % 6 == 5 or (x + dx) % 12 == 11: c = '#8a7a6a'
            else: c = tono(('#6a2e22', '#8a3c2a', '#a44a34', '#bc5a40'), .55 + (R() - .5) * .3 - y / 66 * .2)
            L.p(x, y, c)
    b = lz(144, 96); caja(b, 120, 0, 5, 66, MET); b.r(118, 62, 9, 4, MET[1]); L.pega(con(b), 0, 0)   # la bajante
    for y in range(66, 96):
        for x in range(144):
            L.p(x, y, '#aaa8a0' if (x // 18 + (y - 66) // 9) % 2 == 0 else '#9e9c94')
    L.hl(0, 143, 66, '#c8c8c0'); L.hl(0, 143, 67, '#6a6a64')
    for x in range(0, 144, 18): L.vl(x, 68, 95, '#8a8880')
    return L

def f_cama(dia):
    """la cama del piso de cerca (144 × 96): la pared, la ventana (de noche o de día), el cabecero, la almohada y el edredón"""
    L = lz(144, 96)
    pared = '#4a4258' if not dia else '#e0d4c0'
    for y in range(96):
        for x in range(144):
            L.p(x, y, pared if (x * 5 + y * 3) % 29 else ('#443c50' if not dia else '#d8ccb6'))
    cielo = ('#141c3a', '#1e2a50') if not dia else ('#7ab8e8', '#a0d0f4')
    caja(L, 86, 6, 44, 32, ('#3a2a1a', '#5a3e26', '#7a5a38', '#9a7a50'))
    for x in range(88, 128):
        for y in range(8, 36):
            L.p(x, y, cielo[(x + y) % 7 == 0])
    L.r(88, 21, 40, 2, '#5a3e26'); L.r(107, 8, 2, 28, '#5a3e26')
    if dia: ovalo(L, 120, 14, 4, 4, ('#f0c040', '#f8d860', '#fff4b0'))
    else:
        ovalo(L, 118, 14, 3.5, 3.5, ('#c8c890', '#f0f0c0', '#ffffe8'))
        for (x, y) in ((92, 11), (100, 30), (94, 33), (124, 31)): L.p(x, y, '#f0f0ff')
    c = lz(144, 96)
    caja(c, 2, 30, 16, 66, MAD)                                                 # el cabecero
    for y in (40, 52): c.hl(4, 15, y, MAD[0])
    L.pega(con(c), 0, 0)
    a = lz(144, 96)
    ovalo(a, 36, 50, 18, 7, ('#b8bccc', '#d8dce6', '#eceef4', '#ffffff'))       # la almohada
    L.pega(con(a), 0, 0)
    D = ('#22325a', '#2e4478', '#3e5a9a', '#5a78b8')                            # el edredón azul, de lado
    e = lz(144, 96)
    for y in range(58, 96):
        for x in range(18, 144):
            v = .62 - (y - 58) / 38 * .3 + (.12 if y < 61 else 0)
            if (x - 18) % 22 in (0, 1) and y > 63: v -= .2
            e.p(x, y, tono(D, v))
    e.hl(18, 143, 58, D[3])
    L.pega(con(e), 0, 0)
    return L

# ── las puertas de abrir con llave (lo pidió el usuario: «los fondos del candado y de las cerraduras… se nota que no se ha creado
# con lo mismo»): 104 × 84 como el panel de acceso (ACC_W × ACC_H), la cerradura en el centro (52, 42), con el contorno y la luz
# arriba a la izquierda de los demás fondos; la llave y el candado los pinta el juego encima
LATON = ('#6a4a18', '#9a7228', '#c8a048', '#ecd078')
CROMO = ('#5a606a', '#8a929c', '#c0c8d0', '#eef2f6')
AW, AH, CX, CY = 104, 84, 52, 42

def jamba(L, x, w, r):
    """el marco a un lado: el canto de luz, la cara y la sombra que deja en la puerta"""
    caja(L, x, 0, w, AH, r)
    L.vl(x + w, 0, AH - 1, r[0])

def tornillo(L, x, y, r=LATON):
    L.p(x, y, r[0]); L.p(x - 1, y, r[3]); L.p(x, y - 1, r[3])

def bombin_redondo(L, r=LATON):
    ovalo(L, CX, CY - 2, 4.5, 4.5, r)
    L.r(CX - 3, CY - 2, 6, 2, K)

def f_puerta_portal():
    """el portal del piso: madera de tablas con veta, un cuarterón, el escudo largo de latón con el pomo y el bombín"""
    L = lz(AW, AH)
    R = azar(41)
    for y in range(AH):
        for x in range(AW):
            t = x // 13
            veta = (y + t * 29 + int(2 * math.sin(x * .9 + t))) % 19
            c = MAD[1] if t % 2 == 0 else '#7e522c'
            if veta in (0, 9) or R() < .02: c = MAD[0]
            if x % 13 == 0: c = '#4a3018'
            if x % 13 == 1: c = MAD[2]
            L.p(x, y, c)
    pan = lz(AW, AH)   # el cuarterón de arriba, en relieve
    caja(pan, 14, 6, 76, 20, ('#4a3018', MAD[1], MAD[2], MAD[3]))
    L.pega(pan, 0, 0)
    jamba(L, 0, 7, ('#3a2a1a', '#5a3e26', '#7a5a38', '#9a7a50'))
    e = lz(AW, AH)   # el escudo
    caja(e, CX - 8, CY - 22, 16, 44, LATON)
    for (x, y) in ((CX - 5, CY - 19), (CX + 4, CY + 18)): tornillo(e, x, y)
    ovalo(e, CX, CY - 14, 5, 4, LATON, .1)        # el pomo
    bombin_redondo(e)
    L.pega(con(e), 0, 0)
    return L

def f_puerta_local():
    """el local: perfil de aluminio, el cristal arriba con sus brillos, el panel de abajo y la placa estrecha con la manilla"""
    L = lz(AW, AH)
    for y in range(AH):
        for x in range(AW):
            L.p(x, y, tono(CROMO, .58 - y / AH * .18 + (.06 if (x + y) % 9 == 0 else 0)))
    cr = lz(AW, AH)   # el cristal, con la calle reflejada
    caja(cr, 8, 4, AW - 16, 30, CROMO)
    for y in range(6, 33):
        for x in range(10, AW - 10):
            c = tono(VIDRIO, .3 + (y - 6) / 27 * .25)
            if (x - y) % 23 in (0, 1, 2) or (x - y) % 23 == 6: c = VIDRIO[3]
            cr.p(x, y, c)
    L.pega(con(cr), 0, 0)
    caja(L, 8, 40, AW - 16, AH - 46, CROMO)
    jamba(L, 0, 6, CROMO)
    e = lz(AW, AH)
    caja(e, CX - 5, CY - 20, 10, 42, CROMO)
    caja(e, CX - 10, CY - 17, 20, 4, CROMO)       # la manilla
    caja(e, CX - 3, CY - 7, 6, 10, ('#101014', '#202024', '#9aa2aa', '#c8ccd4'))   # el bombín europeo
    e.r(CX - 2, CY - 3, 4, 1, K)
    L.pega(con(e), 0, 0)
    return L

def f_puerta_club():
    """el club: lacada en negro con el brillo en vertical, dos junquillos, el tirador y la roseta cromada"""
    L = lz(AW, AH)
    LACA = ('#121216', '#1e1e24', '#2c2c34', '#4a4a56')
    for y in range(AH):
        for x in range(AW):
            v = .3 + (.55 if 22 <= x <= 25 else 0) + (.3 if x in (21, 26) else 0) - y / AH * .1
            L.p(x, y, tono(LACA, v))
    for xx in (14, AW - 15):
        L.vl(xx, 0, AH - 1, LACA[0]); L.vl(xx + 1, 0, AH - 1, LACA[3])
    jamba(L, 0, 6, ('#2a1a10', '#3a2a1a', '#5a3e26', '#7a5a38'))
    e = lz(AW, AH)
    caja(e, CX - 13, CY - 19, 26, 4, CROMO)       # el tirador
    ovalo(e, CX, CY, 8, 8, CROMO)                 # la roseta
    e.r(CX - 2, CY - 4, 4, 7, K); e.r(CX - 1, CY - 3, 2, 5, CROMO[2]); e.p(CX - 1, CY - 1, K); e.p(CX, CY - 1, K)
    L.pega(con(e), 0, 0)
    return L

def f_puerta_franco():
    """el piso franco: blindada en gris acero, cuatro cuarterones en relieve y el escudo de seguridad redondo"""
    L = lz(AW, AH)
    AC = ('#2e333a', '#454c55', '#5c646e', '#7a838e')
    for y in range(AH):
        for x in range(AW):
            L.p(x, y, tono(AC, .45 + (.08 if (x * 3 + y * 7) % 31 == 0 else 0)))
    pan = lz(AW, AH)
    for (qx, qy) in ((10, 4), (AW // 2 + 4, 4), (10, AH // 2 + 2), (AW // 2 + 4, AH // 2 + 2)):
        caja(pan, qx, qy, AW // 2 - 14, AH // 2 - 7, AC)
    L.pega(pan, 0, 0)
    jamba(L, 0, 6, AC)
    e = lz(AW, AH)
    ovalo(e, CX, CY, 11, 11, CROMO)
    ovalo(e, CX, CY, 9, 9, ('#101014', '#1e1e24', '#2c2c34', '#3a3a44'))
    caja(e, CX - 4, CY - 6, 8, 12, ('#1e1e24', '#2c2c34', '#4a4a56', '#5a5a66'))   # la tapa giratoria, abierta
    e.r(CX - 1, CY - 6, 3, 10, '#050505'); e.r(CX - 3, CY - 3, 7, 3, '#050505')
    L.pega(con(e), 0, 0)
    return L

def pasador(L, y):
    """el pasador del candado, atornillado"""
    p = lz(AW, AH)
    caja(p, 0, y, AW, 5, MET)
    for x in (10, 30, AW - 31, AW - 11): tornillo(p, x, y + 2, MET)
    caja(p, CX - 4, y - 3, 8, 11, MET)            # la hembrilla del arco
    L.pega(con(p), 0, 0)

def f_persiana():
    """la nave: la persiana metálica de lamas, con su luz y su sombra en cada una, la guía al lado y el pasador"""
    L = lz(AW, AH)
    for y in range(AH):
        f = y % 6
        for x in range(AW):
            L.p(x, y, (MET[3], MET[2], MET[2], MET[1], MET[1], MET[0])[f])
    R = azar(53)
    for _ in range(40):
        x, y = int(R() * AW), int(R() * AH)
        L.p(x, y, '#8a6a4a')                       # la roña
    jamba(L, 0, 7, MET)
    pasador(L, CY - 6)
    return L

def f_puerta_bajo():
    """el bajo de las setas: la puerta de chapa gris con su cuarterón, algo de óxido, y el pasador"""
    L = lz(AW, AH)
    CH = ('#3e4446', '#555c5e', '#6a7274', '#8a9294')
    for y in range(AH):
        for x in range(AW):
            L.p(x, y, tono(CH, .45 - y / AH * .1))
    pan = lz(AW, AH)
    caja(pan, 12, 8, AW - 24, AH - 16, CH)
    L.pega(pan, 0, 0)
    R = azar(59)
    for _ in range(30):
        x, y = int(R() * AW), int(AH * .6 + R() * AH * .4)
        L.p(min(AW - 1, x), min(AH - 1, y), '#7a4a2a' if R() < .6 else '#9a6038')
    jamba(L, 0, 6, CH)
    pasador(L, CY - 6)
    return L

# ── la huerta (lo pidió el usuario: «El cultivo tiene que ser igual que en la nave digamos, pero solo que no hay focos, está
# únicamente la luz del sol. No van por macetas sino que se plantan en el suelo»): el plano de cerca al sol y la planta en la tierra ──
SUELO = ('#4a3020', '#5a3c22', '#6e4a2a', '#906238', '#b47c4c', '#d29a62')   # la tierra del bancal (surco y surcoV de pinta.gd)
SUELO_M = ('#24160c', '#30200f', '#3e2a16', '#52381e')                         # la del hoyo, regada
CIELO = ('#8cc4ec', '#a8d4f2', '#c4e2f6', '#dceef8')
MONTE = ('#1e4a2a', '#2a5e30', '#3a7a3a', '#5a9a48', '#86c060')

def f_huerta():
    """la huerta de la tía al sol (144 × 96): el cielo con dos nubes, el monte, el seto en matas y la tierra del bancal en surcos
    que se abren hacia delante, con la luz arriba a la izquierda"""
    L = lz(144, 96)
    R = azar(57)
    for y in range(30):
        for x in range(144):
            L.p(x, y, tono(CIELO, .1 + y / 30 * .85))
    for (cx, cy, w) in ((28, 7, 13), (100, 5, 17), (132, 12, 8)):
        for x in range(cx - w, cx + w + 1):
            for y in range(cy - 3, cy + 3):
                if ((x - cx) / w) ** 2 + ((y - cy + .5) / 2.6) ** 2 < 1: L.p(x, y, '#f6fbfd' if y < cy else '#e2eff7')
    mo = lz(144, 96)
    for i, cx in enumerate(range(-6, 152, 13)):   # el monte del fondo, en copas
        cy = 21 + (i * 5) % 7; r = 9 + (i * 3) % 4
        ovalo(mo, cx, cy, r, r * .85, MONTE[:4], -.15)
    mo.r(0, 26, 144, 10, MONTE[0])
    L.pega(mo, 0, 0)
    se = lz(144, 96)   # el seto de la huerta, en matas redondas
    for i, cx in enumerate(range(-3, 150, 8)):
        ovalo(se, cx, 33 + (i % 2), 5.5, 4.5, MONTE[1:], .1)
    se.r(0, 34, 144, 10, MONTE[1])
    for x in range(0, 144, 3): se.p(x + (x // 3) % 2, 36 + (x * 7) % 5, MONTE[2])
    L.pega(se, 0, 0)
    L.r(0, 44, 144, 52, SUELO[2])
    y = 44   # la tierra: surcos cada vez más anchos hacia delante (su loma al sol, la ladera y el fondo en sombra)
    k = 0
    while y < 96:
        h = int(3 + (y - 44) * .16)
        for j in range(h):
            t = j / h
            for x in range(144):
                w = int(round(.8 * math.sin(x * .09 + k * 1.7)))
                yy = y + j + w
                if yy < 44 or yy > 95: continue
                c = SUELO[4] if t < .2 else (SUELO[3] if t < .55 else (SUELO[2] if t < .85 else SUELO[1]))
                if x < 30 and t < .2 and k % 2: c = SUELO[5]
                r = R()
                if r < .03: c = SUELO[min(5, SUELO.index(c) + 1)]
                elif r < .06: c = SUELO[max(0, SUELO.index(c) - 1)]
                L.p(x, yy, c)
        y += h; k += 1
    L.hl(0, 143, 44, MONTE[0])   # la sombra del seto
    for (x, yy) in ((14, 52), (101, 58), (126, 79), (22, 88), (88, 90), (6, 70)):   # piedrecitas
        L.p(x, yy, '#a8a090'); L.p(x + 1, yy, '#7a7468')
    return L

def tierra(moj=False):
    """la planta en la tierra del bancal, en el sitio de la maceta (32 × 32; la planta sale de (16, 7)): el alcorque, un anillo de
    tierra suelta alrededor del pie con la luz arriba a la izquierda, el hoyo en medio (regado, oscuro y con brillos) y la sombra
    del anillo delante"""
    L = lz(32, 32)
    R = azar(61 if moj else 59)
    cx, cy, rx, ry = 16, 7.5, 14.5, 5.8
    for y in range(16):
        for x in range(32):
            nx, ny = (x + .5 - cx) / rx, (y + .5 - cy) / ry
            rr = math.hypot(nx, ny)
            if rr > 1:
                if ny > 0 and rr < 1.12 and abs(nx) < .9: L.p(x, y, SUELO[1])   # la sombra del anillo
                continue
            if rr < .58:   # el hoyo
                q = SUELO_M if moj else SUELO[1:5]
                c = q[2] if ny < -.2 else (q[1] if rr > .4 else q[2])
                if ny < -.25 and rr > .35: c = q[0]   # el borde de detrás, en sombra
                L.p(x, y, c)
                continue
            sg = 1 if rr > .8 else -1   # la ladera de fuera o la de dentro
            lam = sg * (-.6 * nx - .55 * ny) / max(rr, .01)
            alt = 1 - abs(rr - .8) / .22
            v = .5 + .42 * lam + .18 * alt + (R() - .5) * .12
            L.p(x, y, SUELO[max(0, min(5, int(v * 6)))])
    for (x, y) in ((6, 4), (25, 10), (9, 11), (22, 3)):   # terrones
        if L.g(x, y)[3]: L.p(x, y, SUELO[5]); L.p(x + 1, y, SUELO[3])
    if moj:
        for (x, y) in ((12, 6), (19, 8), (15, 9)):
            if L.g(x, y)[3]: L.p(x, y, AGUA[2])
    return L


# ── a la salida ──
sale('gs-f-carpa', f_carpa()); sale('gs-f-mesa', f_mesa()); sale('gs-f-cuarto', f_cuarto()); sale('gs-f-calle', f_calle())
sale('gs-f-cama-n', f_cama(False)); sale('gs-f-cama-d', f_cama(True))
sale('acc-f-portal', f_puerta_portal()); sale('acc-f-local', f_puerta_local()); sale('acc-f-club', f_puerta_club())
sale('acc-f-franco', f_puerta_franco()); sale('acc-f-nave', f_persiana()); sale('acc-f-setas', f_puerta_bajo())
sale('gs-maceta', maceta()); sale('gs-maceta-m', maceta(True))
sale('gs-f-huerta', f_huerta()); sale('gs-tierra', tierra()); sale('gs-tierra-m', tierra(True))
sale('gs-planta-v', planta()); sale('gs-planta-f', planta(True))
# 0.55: la regadera a mano ya no sale (gs-regar, de PixelLab)
sale('gs-spray-0', spray(0)); sale('gs-spray-1', spray(1))
sale('gs-bong', bong())
sale('gs-dormido-0', dormido(0)); sale('gs-dormido-1', dormido(1))
sale('gs-porro', porro()); sale('gs-pipa', pipa()); sale('gs-vapo-0', vapo(0)); sale('gs-vapo-1', vapo(1))
sale('gs-bolsita', bolsita()); sale('gs-mano-billete', mano_billete())
sale('gs-bolsita-c', bolsita(MANGA_C).espejo()); sale('gs-billete-m', mano_billete(MANGA).espejo())
sale('gs-brote', brote()); sale('gs-botella-0', botella(0)); sale('gs-botella-1', botella(1))
sale('gs-tijeras-0', tijeras(1)); sale('gs-tijeras-1', tijeras(0))
sale('gs-esqueje', esqueje()); sale('gs-vaso', vaso()); sale('gs-cola', cola()); sale('gs-cola-p', cola(True))
sale('gs-pincel', pincel()); sale('gs-mechero-0', mechero(0)); sale('gs-mechero-1', mechero(1))
for n in range(3): sale('gs-humo-%d' % n, humo(n)); sale('gs-bruma-%d' % n, bruma(n))
sale('gs-billete', billete()); sale('gs-fajo', billete(4)); sale('gs-mano', mano_abierta())
sale('gs-semilla', semilla()); sale('gs-pinza-0', mano_pinza(0)); sale('gs-pinza-1', mano_pinza(1))
sale('gs-gota', gota()); sale('gs-hojita', hojita()); sale('gs-bicho', bicho()); sale('gs-burbuja', burbuja()); sale('gs-z', zeta())



def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'gestos', n, 'unica'); os.makedirs(d, exist_ok=True)
        for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
        L.im.save(os.path.join(d, '00.png'))
        print('gestos', n, L.im.size, len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
