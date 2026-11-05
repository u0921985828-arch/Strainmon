# python3 -I tools/sprites/a-mano/revista.py  (Python 3 + Pillow; no va en los scripts de npm)
# EL ESQUEJE a la vista (lo pidió el usuario: «que los números se vean como revista, con portada y páginas dibujadas»): el arte de
# la revista, dibujado a mano, píxel a píxel, con el papel y la tinta de una revista de quiosco impresa a dos colores (tinta y
# verde). Nada se escala ni se suaviza. Todo con el ancla arriba a la izquierda.
#  · papel (64 × 64): la hoja, tileable, con su grano y sus fibras;
#  · mancheta / mancheta-en (unos 112-140 × 20): el nombre de la revista en cada idioma con letras de bloque dibujadas una por una, con su esqueje de remate;
#  · filete (32 × 5) y filete2 (32 × 3): las cenefas de la cabecera y de los pies, tileables;
#  · pt-<k> (104 × 72): las ocho ilustraciones de portada, según de qué vaya el titular del mes (planta, carpa, copa, barco, nave,
#    club, redada y feria);
#  · vg-<k> (36 × 32): las dieciséis viñetas de sección (noticias, entrevista, variedad, taller, anuncio, consultorio, banco de
#    pruebas, póster, mercado, Copa, agenda, clasificados, cartas, horóscopo, fe de errores y legal);
#  · cinta (24 × 24): la cinta de reclamo de la esquina de la portada; sello (24 × 24): el sello de la nota del banco de pruebas;
#  · grapa (6 × 12): las dos grapas del lomo; dobl (8 × 64): la sombra del doblez junto al lomo.
# Sale a godot/arte/revista.png + revista.json ({r: nombre → [x, y, w, h]}), que carga src/revista.gd (como arte/billar.png).
import os, sys, json, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

# la paleta, cerrada: dos tintas sobre papel
K0 = '#2b2a26'   # tinta
K1 = '#4a4840'   # tinta clara (medio tono)
K2 = '#6e6a5e'   # tinta muy clara (trama)
V0 = '#27551a'   # verde oscuro
V1 = '#3c7a28'   # verde (REV_COLOR de revista.gd)
V2 = '#6aa848'   # verde claro
R0 = '#a33b2a'   # rojo de la cabecera
P0 = '#efe6cf'   # papel
P1 = '#e4d9bd'   # papel en sombra
P2 = '#f7f2e2'   # papel al sol
SAL = {}
def sale(n, L): SAL[n] = L

def dib(L, filas, cols, x=0, y=0):
    for j, f in enumerate(filas):
        for i, ch in enumerate(f):
            if ch != '.': L.p(x + i, y + j, cols[ch])

def elipse(L, cx, cy, rx, ry, c, relleno=True):
    for j in range(-ry, ry + 1):
        for i in range(-rx, rx + 1):
            d = (i / rx) ** 2 + (j / ry) ** 2
            if d <= 1.0 and (relleno or d > .55):
                L.p(cx + i, cy + j, c)

def linea(L, x0, y0, x1, y1, c):
    n = max(abs(x1 - x0), abs(y1 - y0))
    for s in range(n + 1):
        t = s / max(1, n)
        L.p(round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t), c)

def trama(L, x, y, w, h, c, paso=2):
    """la trama de puntos de una ilustración impresa"""
    for j in range(h):
        for i in range(w):
            if (i + j) % paso == 0:
                L.p(x + i, y + j, c)

# ---------- el papel ----------
def papel(oscuro=False):
    L = Lienzo(64, 64)
    r = azar(7 if not oscuro else 11)
    base, som, sol = (P1, '#dacfb2', P0) if oscuro else (P0, P1, P2)
    L.r(0, 0, 64, 64, base)
    for y in range(64):
        for x in range(64):
            v = r()
            if v < .06: L.p(x, y, som)
            elif v > .965: L.p(x, y, sol)
    for _ in range(9):   # las fibras del papel
        x, y = int(r() * 60), int(r() * 60)
        n = 2 + int(r() * 4)
        for i in range(n):
            L.p((x + i) % 64, (y + (i >> 1)) % 64, som)
    return L

# ---------- la mancheta: el nombre de la revista, letra a letra ----------
# cada letra, 11 × 16 con trazo de 3 px y serifa; solo las seis que hacen falta
GL = {
 'E': ['XXXXXXXXXXX', 'XXXXXXXXXXX', 'XXX........', 'XXX........', 'XXX........', 'XXX........',
       'XXXXXXXXX..', 'XXXXXXXXX..', 'XXX........', 'XXX........', 'XXX........', 'XXX........',
       'XXX........', 'XXX........', 'XXXXXXXXXXX', 'XXXXXXXXXXX'],
 'L': ['XXX........', 'XXX........', 'XXX........', 'XXX........', 'XXX........', 'XXX........',
       'XXX........', 'XXX........', 'XXX........', 'XXX........', 'XXX........', 'XXX........',
       'XXX........', 'XXX........', 'XXXXXXXXXXX', 'XXXXXXXXXXX'],
 'S': ['.XXXXXXXXX.', 'XXXXXXXXXXX', 'XXX......XX', 'XXX........', 'XXX........', 'XXXX.......',
       '.XXXXXXXX..', '..XXXXXXXX.', '........XXX', '........XXX', '........XXX', 'XX.......XX',
       'XXX.....XXX', 'XXXXXXXXXX.', '.XXXXXXXXX.', '..XXXXXX...'],
 'Q': ['..XXXXXXX..', '.XXXXXXXXX.', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX',
       'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX..XX.XXX', 'XXX...XXXXX', 'XXX....XXXX',
       '.XXXXXXXXX.', '..XXXXXXXX.', '.......XXXX', '........XXX'],
 'U': ['XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX',
       'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX',
       'XXX.....XXX', 'XXXX...XXXX', '.XXXXXXXXX.', '..XXXXXXX..'],
 'J': ['....XXXXXXX', '....XXXXXXX', '........XXX', '........XXX', '........XXX', '........XXX',
       '........XXX', '........XXX', '........XXX', '........XXX', '........XXX', 'XX......XXX',
       'XXX....XXX.', 'XXXX..XXXX.', '.XXXXXXXX..', '..XXXXXX...'],
 'T': ['XXXXXXXXXXX', 'XXXXXXXXXXX', '....XXX....', '....XXX....', '....XXX....', '....XXX....',
       '....XXX....', '....XXX....', '....XXX....', '....XXX....', '....XXX....', '....XXX....',
       '....XXX....', '....XXX....', '....XXX....', '....XXX....'],
 'H': ['XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX',
       'XXXXXXXXXXX', 'XXXXXXXXXXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX',
       'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX'],
 'C': ['..XXXXXXX..', '.XXXXXXXXX.', 'XXX.....XXX', 'XXX........', 'XXX........', 'XXX........',
       'XXX........', 'XXX........', 'XXX........', 'XXX........', 'XXX........', 'XXX........',
       'XXX.....XXX', 'XXX.....XXX', '.XXXXXXXXX.', '..XXXXXXX..'],
 'I': ['XXXXXXXXXXX', 'XXXXXXXXXXX', '....XXX....', '....XXX....', '....XXX....', '....XXX....',
       '....XXX....', '....XXX....', '....XXX....', '....XXX....', '....XXX....', '....XXX....',
       '....XXX....', '....XXX....', 'XXXXXXXXXXX', 'XXXXXXXXXXX'],
 'N': ['XXXX....XXX', 'XXXX....XXX', 'XXXXX...XXX', 'XXXXX...XXX', 'XXXXXX..XXX', 'XXXXXX..XXX',
       'XXX.XXX.XXX', 'XXX.XXX.XXX', 'XXX..XXXXXX', 'XXX..XXXXXX', 'XXX...XXXXX', 'XXX...XXXXX',
       'XXX....XXXX', 'XXX....XXXX', 'XXX.....XXX', 'XXX.....XXX'],
 'G': ['..XXXXXXX..', '.XXXXXXXXX.', 'XXX.....XXX', 'XXX........', 'XXX........', 'XXX........',
       'XXX..XXXXXX', 'XXX..XXXXXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX', 'XXX.....XXX',
       'XXX.....XXX', 'XXX.....XXX', '.XXXXXXXXX.', '..XXXXXXX..'],
}

def rotulo(txt, c=V0, som=K1):
    w = 0
    for ch in txt:
        w += 4 if ch == ' ' else 12
    L = Lienzo(w + 1, 18)
    x = 0
    for ch in txt:
        if ch == ' ':
            x += 4
            continue
        dib(L, GL[ch], {'X': som}, x + 1, 2)   # la sombra de la letra, 1 px abajo a la derecha
        dib(L, GL[ch], {'X': c}, x, 1)
        x += 12
    return L

def mancheta(txt='EL ESQUEJE'):
    rt = rotulo(txt)
    L = Lienzo(rt.w + 14, 20)
    L.pega(rt, 13, 0)
    # el esqueje de remate: el tallo cortado en diagonal con dos hojas y un brote
    linea(L, 5, 17, 7, 6, V0)
    linea(L, 6, 17, 8, 6, V1)
    for s, (dx, dy) in enumerate(((-1, -1), (1, -1))):
        bx, by = 7 + dx, 11 + dy * 2
        for i in range(4):
            linea(L, bx, by, bx + dx * (3 + i), by - 2 - (i >> 1), V1 if i % 2 else V0)
    elipse(L, 8, 5, 2, 3, V2)
    L.p(8, 4, P2)
    return L

def filete(doble=True):
    L = Lienzo(32, 5 if doble else 3)
    L.hl(0, 31, 0, K0)
    if doble:
        L.hl(0, 31, 4, K0)
        L.hl(0, 31, 2, K2)
        for x in range(2, 32, 8):   # los rombos
            L.p(x, 2, K0); L.p(x - 1, 2, K0); L.p(x + 1, 2, K0)
            L.p(x, 1, K0); L.p(x, 3, K0)
    else:
        L.hl(0, 31, 2, K2)
    return L

def grapa():
    L = Lienzo(6, 12)
    L.r(1, 0, 4, 2, K1)
    L.r(1, 10, 4, 2, K1)
    L.vl(1, 0, 11, K2)
    L.vl(4, 0, 11, K1)
    return L

def doblez():
    L = Lienzo(8, 64)
    for y in range(64):
        for x in range(8):
            L.p(x, y, ['#d4c9ac', '#dccfb4', P1, P1, P0, P0, P2, P0][x])
    return L

# ---------- las nueve viñetas de sección (36 × 32) ----------
def _vg():
    return Lienzo(36, 32)

def vg_nw():   # noticias: el periódico doblado con sus columnas
    L = _vg()
    L.caja(3, 5, 28, 23, P2, K0)
    L.hl(5, 28, 8, K0); L.hl(5, 28, 9, K0)
    for x in (6, 15, 24):
        for y in range(12, 26, 2):
            L.hl(x, x + 7, y, K2)
    L.r(15, 12, 8, 6, K1)
    L.hl(4, 30, 28, K1)
    L.vl(31, 6, 28, K1)
    return L

def vg_var():   # la variedad del mes: un cogollo con su hoja
    L = _vg()
    for i in range(7):
        w = 9 - i
        y = 6 + i * 3
        elipse(L, 18, y, w, 3, V1)
        elipse(L, 18 - w // 2, y + 1, 3, 2, V0)
        elipse(L, 18 + w // 2, y + 1, 3, 2, V2)
    linea(L, 18, 26, 18, 31, K1)
    for dx in (-1, 1):
        linea(L, 18, 28, 18 + dx * 6, 24, V0)
        linea(L, 18, 28, 18 + dx * 5, 26, V1)
    L.contorno(K0)
    return L

def vg_tec():   # el taller: las tijeras de podar, cruzadas en el remache
    L = _vg()
    rx, ry = 18, 17   # el remache, donde se cruzan las dos hojas
    for dx in (-1, 1):
        linea(L, rx, ry, rx + dx * 7, 4, K0)          # la hoja, hacia arriba
        linea(L, rx + dx, ry, rx + dx * 8, 4, K1)     # su filo
        L.p(rx + dx * 7, 4, P2); L.p(rx + dx * 7, 5, P2)
        linea(L, rx, ry, rx - dx * 5, 24, K0)         # el brazo del mango, hacia abajo
        linea(L, rx + dx, ry, rx - dx * 4, 24, K1)
        elipse(L, rx - dx * 6, 26, 5, 4, K0, False)   # el anillo del mango
        elipse(L, rx - dx * 6, 26, 4, 3, K1, False)
    L.r(rx - 1, ry - 1, 3, 3, K0); L.p(rx, ry, K2)
    return L

def vg_merc():   # el mercado: la balanza con los dos platos
    L = _vg()
    L.vl(18, 6, 26, K0)
    L.hl(5, 31, 8, K0)
    L.r(13, 26, 11, 3, K0)
    for cx in (7, 29):
        linea(L, cx, 9, cx - 3, 14, K2)
        linea(L, cx, 9, cx + 3, 14, K2)
        elipse(L, cx, 15, 5, 2, K1)
        L.hl(cx - 4, cx + 4, 14, K0)
    elipse(L, 18, 5, 3, 3, V1)
    L.p(7, 12, V2); L.p(29, 12, V2)
    return L

def vg_copa():   # la Copa: el trofeo
    L = _vg()
    elipse(L, 18, 12, 9, 8, V1)
    L.r(9, 4, 19, 6, V1)
    L.hl(9, 27, 4, V0)
    for dx in (-1, 1):   # las asas
        elipse(L, 18 + dx * 12, 10, 4, 4, V0, False)
    L.r(16, 19, 5, 6, V0)
    L.r(11, 25, 15, 4, K0)
    L.r(13, 23, 11, 2, V0)
    trama(L, 11, 6, 8, 10, V2, 3)
    L.contorno(K0)
    return L

def vg_ag():   # la agenda: la hoja del mes con sus días
    L = _vg()
    L.caja(4, 6, 28, 23, P2, K0)
    L.r(5, 7, 26, 5, R0)
    for j in range(3):
        for i in range(6):
            L.r(7 + i * 4, 14 + j * 5, 3, 3, K2)
    L.r(19, 19, 3, 3, V1)
    L.p(9, 4, K1); L.p(26, 4, K1)
    L.vl(9, 3, 7, K1); L.vl(26, 3, 7, K1)
    return L

def vg_cls():   # los clasificados: el cartel con dos chinchetas
    L = _vg()
    L.caja(5, 5, 26, 22, P1, K0)
    for y in range(9, 24, 3):
        L.hl(8, 27, y, K2)
    L.hl(8, 20, 12, K0)
    elipse(L, 8, 7, 2, 2, R0)
    elipse(L, 28, 7, 2, 2, R0)
    for i in range(4):   # los flecos de abajo
        L.vl(8 + i * 6, 27, 30, K2)
    return L

def vg_car():   # cartas: el sobre abierto
    L = _vg()
    L.caja(4, 9, 28, 17, P2, K0)
    linea(L, 5, 10, 18, 19, K1)
    linea(L, 30, 10, 18, 19, K1)
    L.r(9, 13, 12, 2, K2)
    elipse(L, 26, 22, 4, 3, V1)
    L.p(26, 21, P2)
    return L

def vg_leg():   # legal: el mazo con la maza en su mango y el taco debajo
    L = _vg()
    linea(L, 14, 17, 27, 7, K0)     # el mango, de la maza hacia arriba a la derecha
    linea(L, 15, 18, 28, 8, K1)
    linea(L, 15, 19, 28, 9, K0)
    L.caja(6, 10, 13, 10, K1, K0)   # la maza, encajada en el arranque del mango
    L.hl(8, 16, 12, K2); L.hl(8, 16, 17, K0)
    L.vl(12, 11, 18, K0)
    L.r(8, 24, 20, 5, K0)           # el taco
    L.hl(10, 25, 25, K2)
    L.hl(9, 26, 28, K1)
    return L

# ---------- las viñetas de la parodia del género (lo pidió el usuario) ----------
def vg_ent():   # la entrevista: el micrófono de mano con su cable
    L = _vg()
    elipse(L, 18, 10, 6, 7, K1)
    elipse(L, 18, 9, 5, 5, K2)
    for j in range(5, 14, 2):      # la rejilla
        L.hl(13, 23, j, K0)
    L.r(15, 16, 7, 12, K1)         # el mango
    L.vl(16, 17, 27, K2)
    L.hl(14, 23, 16, K0)
    linea(L, 18, 28, 12, 31, K0)   # el cable
    linea(L, 12, 31, 25, 30, K0)
    L.contorno(K0)
    return L

def vg_con():   # el consultorio: la lupa sobre la carta del lector
    L = _vg()
    L.caja(2, 7, 24, 21, P2, K0)
    for y in range(11, 26, 3):
        L.hl(5, 22, y, K2)
    elipse(L, 23, 13, 8, 8, K0)
    elipse(L, 23, 13, 6, 6, P0)
    trama(L, 18, 9, 11, 9, P2, 2)
    linea(L, 28, 19, 34, 28, K0)   # el mango
    linea(L, 29, 18, 35, 27, K1)
    return L

def vg_tst():   # el banco de pruebas: el aparato con su pantalla y su dial
    L = _vg()
    L.caja(4, 7, 27, 21, K1, K0)
    L.caja(7, 10, 14, 9, V1, K0)   # la pantalla
    for x in range(9, 20, 3):
        L.vl(x, 12, 17, V0)
    elipse(L, 26, 14, 3, 3, P1)    # el dial
    L.p(26, 12, K0)
    for i in range(3):             # los botones
        L.r(7 + i * 5, 22, 3, 3, P1)
    L.r(23, 22, 5, 3, R0)
    L.hl(5, 30, 28, K2)
    return L

def vg_hor():   # el horóscopo: la luna y sus estrellas
    L = _vg()
    for j in range(-9, 10):
        for i in range(-9, 10):
            if (i / 9.) ** 2 + (j / 9.) ** 2 <= 1 and ((i - 7) / 9.) ** 2 + (j / 9.) ** 2 > 1:
                L.p(15 + i, 14 + j, V1 if (i + j) % 3 else V0)
    L.contorno(K0)
    for sx, sy, r in ((29, 5, 2), (32, 15, 1), (27, 25, 2), (6, 29, 1)):
        for d in range(-r, r + 1):
            L.p(sx + d, sy, V2)
            L.p(sx, sy + d, V2)
    return L

def vg_err():   # la fe de errores: la plana del mes pasado con su tachón y el lápiz
    L = _vg()
    L.caja(3, 4, 23, 24, P2, K0)
    for y in range(8, 26, 3):
        L.hl(6, 23, y, K2)
    for dy in (0, 1):              # el tachón
        linea(L, 6, 10 + dy, 23, 20 + dy, R0)
        linea(L, 23, 10 + dy, 6, 20 + dy, R0)
    linea(L, 33, 5, 24, 25, K1)    # el lápiz
    linea(L, 34, 6, 25, 26, R0)
    linea(L, 35, 7, 26, 27, K1)
    L.p(24, 26, K0); L.p(25, 27, K0)
    return L

def vg_anu():   # el anuncio: el megáfono y sus ondas
    L = _vg()
    for i in range(13):            # la bocina
        h = 3 + i
        L.vl(9 + i, 15 - h, 15 + h, V1 if i % 3 else V0)
    L.r(4, 12, 6, 7, K1)           # el cuerpo
    L.hl(4, 9, 11, K0)
    linea(L, 10, 25, 14, 30, K1)   # el asa
    for r in (4, 7, 10):           # las ondas
        for j in range(-r, r + 1):
            x = 23 + int(round((r * r - j * j) ** .5))
            if 0 <= x < 36 and 0 <= 15 + j < 32:
                L.p(x, 15 + j, V2)
    L.contorno(K0)
    return L

def vg_pst():   # el póster central: la lámina clavada con su chincheta
    L = _vg()
    L.caja(7, 5, 21, 25, P2, K0)
    L.r(9, 8, 17, 15, P1)
    elipse(L, 17, 15, 4, 6, V1)    # la matita de la lámina
    elipse(L, 17, 11, 2, 3, V2)
    L.vl(17, 18, 22, K1)
    for dx in (-1, 1):
        linea(L, 17, 19, 17 + dx * 4, 16, V0)
    for y in range(25, 29, 2):     # el pie de la lámina
        L.hl(10, 24, y, K2)
    elipse(L, 17, 5, 3, 3, R0)     # la chincheta
    L.p(17, 4, P2)
    return L

def cinta():   # la cinta de reclamo de la esquina de la portada (sin letras: tres rayas que las sugieren)
    L = Lienzo(24, 24)
    for j in range(24):
        for i in range(24):
            d = i - j
            if 9 <= d <= 18:
                L.p(i, j, R0 if 10 <= d <= 17 else K0)
    for k in range(3):             # las rayas
        x = 12 + k * 3
        y = x - 14
        for i in range(4):
            if 0 <= y + i < 24 and 0 <= x + i < 24:
                L.p(x + i, y + i, P2)
    return L

def sello():   # el sello de la nota del banco de pruebas
    L = Lienzo(24, 24)
    for j in range(24):
        for i in range(24):
            dx, dy = i - 11.5, j - 11.5
            r = (dx * dx + dy * dy) ** .5
            lim = 10.0 + 1.3 * math.cos(math.atan2(dy, dx) * 12)
            if r <= lim:
                L.p(i, j, R0 if r > lim - 2.5 else P2)
    L.hl(7, 16, 10, R0)
    L.hl(7, 16, 13, R0)
    L.contorno(K0)
    return L

VG = {'nw': vg_nw, 'var': vg_var, 'tec': vg_tec, 'merc': vg_merc, 'copa': vg_copa,
      'ag': vg_ag, 'cls': vg_cls, 'car': vg_car, 'leg': vg_leg,
      'ent': vg_ent, 'con': vg_con, 'tst': vg_tst, 'hor': vg_hor, 'err': vg_err, 'anu': vg_anu, 'pst': vg_pst}

# ---------- las ocho ilustraciones de portada (104 × 72) ----------
# el grabado de la portada: tinta y verde sobre el papel, con el marco de filete y la trama de los medios tonos
def _pt():
    return Lienzo(104, 72)

def _suelo(L, y, c=K1):
    L.hl(0, 103, y, c)
    for x in range(0, 104, 3):
        L.p(x, y + 1, K2)

def _planta(L, cx, base, alto, ancho, c0=V0, c1=V1, c2=V2):
    """una mata: el tallo, las ramas en abanico y las colas"""
    linea(L, cx, base, cx, base - alto, c0)
    linea(L, cx + 1, base, cx + 1, base - alto + 2, c1)
    n = 5
    for i in range(n):
        t = (i + 1) / n
        y = base - int(alto * t * .9)
        w = int(ancho * (1 - t * .55))
        for dx in (-1, 1):
            linea(L, cx, y, cx + dx * w, y - int(w * .45), c0 if i % 2 else c1)
            linea(L, cx, y + 1, cx + dx * (w - 2), y - int(w * .45) + 2, c1)
            elipse(L, cx + dx * w, y - int(w * .45), 3, 2, c2 if dx < 0 else c1)
    elipse(L, cx, base - alto - 2, 3, 5, c1)   # la cola
    elipse(L, cx - 1, base - alto - 3, 2, 3, c2)

def pt_planta():   # una planta en su maceta bajo el foco
    L = _pt()
    _suelo(L, 62)
    L.r(38, 10, 28, 5, K0)      # el foco
    L.r(44, 15, 16, 3, K1)
    L.vl(52, 2, 10, K2)
    for dx in range(-3, 4):      # la luz
        linea(L, 52 + dx * 4, 19, 52 + dx * 11, 34, '#f2e2a8')
    L.r(36, 50, 32, 12, K1)     # la maceta
    L.r(34, 48, 36, 3, K0)
    for x in range(38, 68, 4):
        L.vl(x, 51, 61, K2)
    _planta(L, 52, 50, 26, 18)
    return L

def pt_carpa():   # la carpa plateada abierta, con las plantas dentro
    L = _pt()
    _suelo(L, 66)
    L.caja(14, 10, 76, 56, '#4a4e54', K0)
    L.r(16, 12, 72, 52, '#5a5f66')
    L.r(20, 14, 64, 6, '#6e747c')        # la capota
    L.caja(26, 20, 52, 44, '#2a2e34', K0)   # la puerta abierta
    for x in (26, 78):
        L.vl(x, 20, 63, '#8a9098')
    for i, cx in enumerate((38, 52, 66)):
        _planta(L, cx, 60, 14 + i % 2 * 4, 9)
    L.r(34, 22, 36, 3, '#d8e0a0')        # el LED
    L.hl(34, 69, 25, K1)
    return L

def pt_copa():   # el podio de la Copa con el trofeo
    L = _pt()
    _suelo(L, 66)
    for i, (x, w, h) in enumerate(((10, 26, 14), (39, 26, 22), (68, 26, 10))):
        L.caja(x, 66 - h, w, h, P1, K0)
        trama(L, x + 1, 67 - h, w - 2, h - 2, K2, 3)
    vg = vg_copa()
    L.pega(vg, 34, 10)
    for dx in (-1, 1):   # las ramas de laurel
        for i in range(5):
            elipse(L, 52 + dx * (16 + i * 3), 24 + i * 6, 3, 2, V1)
    return L

def pt_barco():   # el pesquero en el muelle
    L = _pt()
    for y in range(52, 72):   # la ría
        c = '#2e5a6a' if (y // 2) % 2 else '#27505e'
        L.hl(0, 103, y, c)
    for x in range(0, 104, 7):
        L.p(x + (x // 7) % 3, 56, '#6a9aa8')
        L.p(x + 2, 62, '#6a9aa8')
    L.r(18, 42, 62, 10, K0)      # el casco
    L.r(20, 44, 58, 6, K1)
    linea(L, 18, 42, 12, 52, K0); linea(L, 80, 42, 86, 52, K0)
    L.r(34, 28, 24, 14, P1)      # la caseta
    L.caja(34, 28, 24, 14, P1, K0)
    L.r(38, 32, 6, 5, '#2e5a6a'); L.r(48, 32, 6, 5, '#2e5a6a')
    L.vl(66, 16, 42, K0)         # el palo
    linea(L, 66, 16, 58, 28, K2)
    L.r(62, 14, 9, 3, R0)
    return L

def pt_nave():   # la nave por dentro: las mesas en fila con sus focos
    L = _pt()
    L.r(0, 0, 104, 54, P1)
    L.hl(0, 103, 54, K0)
    trama(L, 0, 55, 104, 17, K2, 4)
    for i, (x, y, w) in enumerate(((8, 44, 36), (56, 44, 36), (20, 30, 28), (58, 30, 28))):
        L.caja(x, y, w, 7, K1, K0)         # la mesa
        for j in range(3):
            _planta(L, x + 8 + j * 10, y, 8, 5)
        L.r(x + 4, y - 16, w - 8, 3, '#d8e0a0')   # el LED
        L.vl(x + 8, y - 22, y - 16, K2)
        L.vl(x + w - 8, y - 22, y - 16, K2)
    return L

def pt_club():   # el club: la vitrina del dispensario con sus botes
    L = _pt()
    L.r(0, 0, 104, 72, P1)
    L.caja(10, 8, 84, 54, P2, K0)
    L.hl(11, 92, 30, K0)
    L.hl(11, 92, 46, K0)
    for fila, y in ((0, 28), (1, 44)):
        for i in range(6):
            x = 15 + i * 13
            L.caja(x, y - 11, 9, 11, P0, K1)      # el bote
            L.r(x + 1, y - 7, 7, 6, V1 if (i + fila) % 2 else V0)
            L.r(x + 2, y - 12, 5, 2, K1)
    L.r(10, 62, 84, 4, K1)
    L.r(40, 2, 24, 5, V0)
    return L

def pt_redada():   # la redada: la puerta forzada y la luz azul
    L = _pt()
    L.r(0, 0, 104, 72, '#1c2330')
    for i in range(5):   # la luz azul girando
        elipse(L, 52, 14, 30 - i * 5, 12 - i * 2, ['#3a5a8a', '#4a6ea8', '#5a86c8', '#7aa6e0', '#a8caf0'][i])
    L.caja(34, 28, 36, 44, '#3a3a42', K0)   # la puerta
    linea(L, 34, 40, 70, 34, K0)
    linea(L, 34, 41, 70, 35, '#6a6a72')
    for i in range(6):
        L.p(36 + i * 6, 42 + (i % 3), '#8a8a92')
    elipse(L, 64, 50, 2, 2, '#d8d8a0')
    L.r(0, 68, 104, 4, '#2a3240')
    return L

def pt_feria():   # la feria de semillas: el puesto con los sobres
    L = _pt()
    _suelo(L, 64)
    for i in range(7):   # el toldo a rayas
        L.r(8 + i * 13, 8, 13, 10, R0 if i % 2 else P2)
    L.hl(8, 98, 18, K0)
    L.caja(14, 44, 76, 20, P1, K0)    # el mostrador
    for i in range(5):
        x = 20 + i * 14
        L.caja(x, 36, 10, 8, P2, K0)   # los sobres
        L.r(x + 2, 38, 6, 2, V1 if i % 2 else V0)
    L.vl(10, 18, 64, K1); L.vl(94, 18, 64, K1)
    trama(L, 16, 46, 72, 16, K2, 3)
    return L

PT = {'planta': pt_planta, 'carpa': pt_carpa, 'copa': pt_copa, 'barco': pt_barco,
      'nave': pt_nave, 'club': pt_club, 'redada': pt_redada, 'feria': pt_feria}

# ---------- la hoja ----------
def arte():
    sale('papel', papel())
    sale('mancheta', mancheta())
    sale('mancheta-en', mancheta('THE CUTTING'))
    sale('filete', filete())
    sale('filete2', filete(False))
    sale('grapa', grapa())
    sale('dobl', doblez())
    sale('cinta', cinta())
    sale('sello', sello())
    for k, f in VG.items():
        sale('vg-' + k, f())
    for k, f in PT.items():
        sale('pt-' + k, f())
    return SAL

def main():
    A = arte()
    ns = sorted(A, key=lambda n: (-A[n].h, n))   # las más altas primero: filas compactas
    ANCHO = 256
    sitio, x, y, fila = {}, 0, 0, 0
    for n in ns:
        L = A[n]
        if x and x + L.w > ANCHO:
            x, y, fila = 0, y + fila, 0
        sitio[n] = [x, y, L.w, L.h]
        x += L.w
        fila = max(fila, L.h)
    alto = y + fila
    hoja = Lienzo(ANCHO, alto)
    for n in ns:
        hoja.pega(A[n], sitio[n][0], sitio[n][1])
    f = hoja.guarda('godot', 'arte', 'revista.png')
    with open(P('godot', 'arte', 'revista.json'), 'w') as o:
        json.dump({'r': {n: sitio[n] for n in sorted(sitio)}}, o, indent=0, sort_keys=True)
    print('revista.png %d × %d · %d piezas' % (ANCHO, alto, len(sitio)))
    if len(sys.argv) > 1:   # vista previa a 4× para revisarla
        hoja.im.resize((ANCHO * 4, alto * 4), 0).save(sys.argv[1])
        print(sys.argv[1])
    return f

if __name__ == '__main__':
    main()
