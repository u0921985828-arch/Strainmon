# python3 -I tools/sprites/a-mano/gestos.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.54.1 (lo pidió el usuario: «eso no son sprites en condiciones en el mismo estilo que los muebles del juego»): el plano de cerca
# de cada acción, dibujado a mano con el contorno de los muebles (#2a2a34), la luz arriba a la izquierda y 3-4 tonos por material,
# como el almacén y el móvil. El juego (trama.gd, `_gesto_spr`) compone el fondo y mueve las piezas por el reloj.
#  · Fondos (gs_fondo, 128 × 80, ancla arriba a la izquierda): gs-f-carpa (la carpa plateada por dentro, con la bandeja y la luz),
#    gs-f-mesa (la mesa de la tía contra la pared), gs-f-cuarto (el salón de noche, el sofá), gs-f-calle (la pared de ladrillo y la
#    acera), gs-f-cama-n y gs-f-cama-d (la cama de noche y de siesta).
#  · Piezas (gs_g 48 × 48, gs_m 24 × 24, gs_s 8 × 8): la maceta de tela, seca y regada, la planta en vegetativo y en flor, el brote,
#    las manos con la regadera, el pulverizador, la botella de abono, el esqueje, las tijeras de podar, el cogollo con hojas y
#    pelado, el pincel, el porro, la pipa, el bong, el vapo, el mechero, el humo, la bolsita, los billetes, la cabeza dormida y la Z.
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
    L = lz(48, 24)
    ovalo(L, 10, 12, 6, 6, MAD)                                                 # la cazoleta
    L.r(6, 6, 9, 2, '#2a1a10'); L.hl(6, 14, 6, MAD[0])                          # la boca, con lo de dentro
    linea(L, 15, 15, 30, 12, MAD[1], 2); linea(L, 15, 14, 30, 11, MAD[2])       # la caña
    L.r(30, 10, 4, 3, '#1a1a1e')
    con(L)
    mano_puno(L, 26, 8)
    return con(L)


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


# ── dormir ──
def dormido(resp):
    """la cabeza en la almohada con los ojos cerrados y la gorra en la mesilla (48 × 24); resp: el pecho arriba"""
    L = lz(48, 24)
    ovalo(L, 18, 12, 7, 6.5, PIEL)
    for x in (14, 15, 20, 21): L.p(x, 12, PIEL[0])                   # los ojos cerrados
    L.p(18, 15, PIEL[1]); L.p(19, 16, '#a85a4a')
    for x in range(11, 26):   # el pelo, castaño
        for y in range(5, 9 - (1 if 14 < x < 22 else 0)):
            L.p(x, y, '#5a3a24' if y > 5 else '#7a5236')
    con(L)
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

# ── a la salida ──
sale('gs-f-carpa', f_carpa()); sale('gs-f-mesa', f_mesa()); sale('gs-f-cuarto', f_cuarto()); sale('gs-f-calle', f_calle())
sale('gs-f-cama-n', f_cama(False)); sale('gs-f-cama-d', f_cama(True))
sale('gs-maceta', maceta()); sale('gs-maceta-m', maceta(True))
sale('gs-planta-v', planta()); sale('gs-planta-f', planta(True))
sale('gs-regadera-0', regadera(0)); sale('gs-regadera-1', regadera(1))
sale('gs-spray-0', spray(0)); sale('gs-spray-1', spray(1))
sale('gs-bong', bong())
sale('gs-dormido', dormido(0))
sale('gs-porro', porro()); sale('gs-pipa', pipa()); sale('gs-vapo-0', vapo(0)); sale('gs-vapo-1', vapo(1))
sale('gs-bolsita', bolsita()); sale('gs-mano-billete', mano_billete())
sale('gs-bolsita-c', bolsita(MANGA_C).espejo()); sale('gs-billete-m', mano_billete(MANGA).espejo())
sale('gs-brote', brote()); sale('gs-botella-0', botella(0)); sale('gs-botella-1', botella(1))
sale('gs-tijeras-0', tijeras(1)); sale('gs-tijeras-1', tijeras(0))
sale('gs-esqueje', esqueje()); sale('gs-vaso', vaso()); sale('gs-cola', cola()); sale('gs-cola-p', cola(True))
sale('gs-pincel', pincel()); sale('gs-mechero-0', mechero(0)); sale('gs-mechero-1', mechero(1))
for n in range(3): sale('gs-humo-%d' % n, humo(n)); sale('gs-bruma-%d' % n, bruma(n))
sale('gs-billete', billete()); sale('gs-fajo', billete(4)); sale('gs-mano', mano_abierta())
sale('gs-gota', gota()); sale('gs-hojita', hojita()); sale('gs-bicho', bicho()); sale('gs-burbuja', burbuja()); sale('gs-z', zeta())



def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'gestos', n, 'unica'); os.makedirs(d, exist_ok=True)
        for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
        L.im.save(os.path.join(d, '00.png'))
        print('gestos', n, L.im.size, len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
