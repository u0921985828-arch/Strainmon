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

def _esqueje(L, x, y):
    """el esqueje de remate: el tallo cortado en diagonal con dos hojas y un brote"""
    linea(L, x, y + 11, x + 2, y, V0)
    linea(L, x + 1, y + 11, x + 3, y, V1)
    for dx, dy in ((-1, -1), (1, -1)):
        bx, by = x + 2 + dx, y + 5 + dy * 2
        for i in range(4):
            linea(L, bx, by, bx + dx * (3 + i), by - 2 - (i >> 1), V1 if i % 2 else V0)
    elipse(L, x + 3, y - 1, 2, 3, V2)
    L.p(x + 3, y - 2, P2)

def mancheta(txt='EL ESQUEJE'):
    """la cabecera, a dos líneas como la de cualquier revista de quiosco: el artículo encima y el nombre grande debajo, con el
    esqueje de remate a su izquierda. A una sola línea no cabe en una hoja A4 del lienzo (115 px)."""
    pa = txt.split(' ')
    r1 = rotulo(pa[0]) if len(pa) > 1 else None
    r2 = rotulo(pa[-1])
    L = Lienzo(r2.w + 15, 36 if r1 else 20)
    if r1:
        L.pega(r1, 15, 0)
        L.hl(15 + r1.w + 2, r2.w + 13, 9, K2)   # el filete que acompaña al artículo
        L.pega(r2, 15, 17)
        _esqueje(L, 4, 23)
    else:
        L.pega(r2, 15, 0)
        _esqueje(L, 4, 6)
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

# ---------- el arte del juego ----------
# Las ilustraciones de la revista no se vuelven a dibujar: se montan con los sprites que ya tiene el juego (godot/arte/atlas.png +
# atlas.json), recortados y puestos sobre el papel (lo pidió el usuario: «lo lógico sería utilizar los sprites que ya tenemos
# disponibles en el repositorio del juego para hacer la revista»). Nada se escala: solo se recorta, se centra y se pega.
_AT = [None, None]

def atlas():
    if _AT[0] is None:
        from PIL import Image as _I
        _AT[0] = json.load(open(P('godot', 'arte', 'atlas.json')))
        _AT[1] = _I.open(P('godot', 'arte', 'atlas.png')).convert('RGBA')
    return _AT[0]

def cel(k, x=0, y=0, w=None, h=None):
    """un recorte del atlas del juego, como Lienzo (x, y, w, h dentro del fotograma)"""
    f = atlas()['frames'][k]
    w = f['w'] - x if w is None else w
    h = f['h'] - y if h is None else h
    L = Lienzo(w, h)
    L.im.paste(_AT[1].crop((f['x'] + x, f['y'] + y, f['x'] + x + w, f['y'] + y + h)), (0, 0))
    L.px = L.im.load()
    return L

def ajusta(L):
    """el sprite sin el aire de alrededor"""
    b = L.im.getbbox()
    return L.recorta(b[0], b[1], b[2] - b[0], b[3] - b[1]) if b else L

def _fondo(w=104, h=72, c=P2):
    L = Lienzo(w, h)
    L.r(0, 0, w, h, c)
    return L

def _pon(L, o, y, dx=0):
    """centra el sprite a lo ancho de la ilustración"""
    L.pega(o, (L.w - o.w) // 2 + dx, y)
    return o

def _cielo(L, hasta, c='#bcd4e2'):
    L.r(0, 0, L.w, hasta, c)
    for x in range(0, L.w, 5):          # las nubes de la trama
        L.p(x + (x // 5) % 3, 6, '#d8e8f2')

# Las plantas de las carpas son las de la vista C (celda carpa-c-plantas-a: planta-c-<porte>-<ancho>, el 2 en el nombre es
# vegetativo), no las vistas desde arriba de las mesas de la nave (lo dijo el usuario: «en el cultivo en las carpas, las plantas
# no son así»). Sus cogollos van en la rampa clave magenta, que el motor tiñe con el color de la variedad: aquí lo mismo.
COG_RAMPA = ('#ff5cff', '#d020c8', '#80107a')
COG_MES = '#a8d055'          # el verde claro de la variedad del mes

def _hex(c):
    c = c.lstrip('#')
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))

def _mez(a, b, t):
    A, B = _hex(a), _hex(b)
    return '#%02x%02x%02x' % tuple(int(A[i] + (B[i] - A[i]) * t) for i in range(3))

def impreso(L, c=K0):
    """el arte del juego, impreso: el negro de los sprites pasa a la tinta de la revista (en el papel no hay negro puro)"""
    t = _hex(c)
    for y in range(L.h):
        for x in range(L.w):
            q = L.px[x, y]
            if q[3] and q[0] + q[1] + q[2] <= 60:
                L.px[x, y] = t + (255,)
    return L

def tinte_cog(L, c=COG_MES):
    """pasa la rampa clave del cogollo al color de la variedad (clara, media y oscura)"""
    d = {_hex(COG_RAMPA[0]): _hex(_mez(c, '#ffffff', .45)),
         _hex(COG_RAMPA[1]): _hex(c),
         _hex(COG_RAMPA[2]): _hex(_mez(c, '#102014', .5))}
    for y in range(L.h):
        for x in range(L.w):
            q = L.px[x, y]
            if q[3] and q[:3] in d:
                L.px[x, y] = d[q[:3]] + (255,)
    return L

def planta_c(porte='i', ancho=38, i=0, veg=False, c=COG_MES):
    """la planta de la vista de carpa: su porte (i índica, h híbrida, s sativa), su fotograma de alto y su color"""
    k = 'carpa-c-plantas-a/planta-c-%s%s-%d/unica/%02d' % (porte, '2' if veg else '', ancho, i)
    L = ajusta(cel(k))
    return L if veg else tinte_cog(L, c)

def planta_cabe(porte, ancho, hmax, veg=False, c=COG_MES):
    """la planta más alta de ese porte que cabe en hmax (los fotogramas bajan de 2 en 2 filas)"""
    ult = None
    for i in range(15):
        k = 'carpa-c-plantas-a/planta-c-%s%s-%d/unica/%02d' % (porte, '2' if veg else '', ancho, i)
        if k not in atlas()['frames']:
            break
        L = planta_c(porte, ancho, i, veg, c)
        ult = L
        if L.h <= hmax:
            return L
    return ult

def pt_planta():   # la carpa por dentro: la pared plateada, las macetas y las plantas bajo el foco
    L = _fondo()
    pa = cel('carpa-c-fondo/carpa-c-pared/unica/00')
    L.pega(pa.recorta((pa.w - 104) // 2, pa.h - 72, 104, 72), 0, 0)   # el centro de la pared, con su suelo
    fo = ajusta(cel('carpa-c-focos-led-ancho/foco-c-led720-75/unica/00'))
    _pon(L, fo.recorta(0, 6, fo.w, 10), 0)                            # la campana del LED, asomando por arriba
    mc = ajusta(cel('carpa-c-macetas-b/maceta-c-tela25-27/unica/00'))
    for dx, py, pl in ((-34, 58, planta_cabe('i', 32, 26, True)),     # dos en vegetativo, detrás
                       (34, 58, planta_cabe('i', 32, 26, True)),
                       (0, 71, planta_cabe('i', 38, 42))):            # y la del mes, en flor, delante
        L.pega(mc, (104 - mc.w) // 2 + dx, py - mc.h)
        L.pega(pl, (104 - pl.w) // 2 + dx, py - mc.h - pl.h + 8)
    return L

def pt_carpa():   # el taller: el equipo de la carpa (filtro, ventilador, depósito y garrafa) con una madre
    L = _fondo()
    pa = cel('carpa-c-fondo/carpa-c-pared/unica/00')
    L.pega(pa.recorta((pa.w - 104) // 2, pa.h - 72, 104, 72), 0, 0)
    fi = ajusta(cel('carpa-c-extras/extra-c-filtro-39/unica/00'))
    ve = ajusta(cel('carpa-c-extras/extra-c-vent/unica/00'))
    dp = ajusta(cel('carpa-c-extras/extra-c-deposito/unica/00'))
    ga = ajusta(cel('carpa-c-extras/extra-c-garrafa-29/unica/00'))
    L.pega(fi, 2, 3)                      # el filtro de carbón, colgado
    L.pega(ve, 104 - ve.w - 3, 4)         # el ventilador de pinza
    L.pega(dp, 104 - dp.w - 2, 70 - dp.h) # el depósito del goteo
    L.pega(ga, 4, 70 - ga.h)              # y la garrafa
    mc = ajusta(cel('carpa-c-macetas-b/maceta-c-tela11-20/unica/00'))
    pl = planta_cabe('h', 32, 30, True)   # la madre, en vegetativo
    _pon(L, mc, 70 - mc.h)
    _pon(L, pl, 70 - mc.h - pl.h + 6)
    return L

def pt_copa():   # la Copa: el jurado delante del podio, con el cogollo premiado
    L = _fondo()
    _suelo(L, 68)
    for i, (x, w, h) in enumerate(((10, 26, 12), (39, 26, 20), (68, 26, 8))):
        L.caja(x, 68 - h, w, h, P1, K0)
        trama(L, x + 1, 69 - h, w - 2, h - 2, K2, 3)
    cg = tinte_cog(ajusta(cel('cogollos-genoteca/legendario/unica/00')), '#b088d8')
    _pon(L, cg, 48 - cg.h - 20 + 20, 0)
    ju = ajusta(cel('jurado/base/south/00'))
    for dx in (-30, 30):
        L.pega(ju, (L.w - ju.w) // 2 + dx, 68 - ju.h)
    return L

def pt_barco():   # el pesquero del muelle, en la ría
    L = _fondo()
    _cielo(L, 56)
    ba = ajusta(cel('puerto-barcoP/barcoP/unica/00'))
    ba = ba.recorta(ba.w - 104, 0, 104, min(46, ba.h))   # la superestructura: caseta, puente y cubierta
    L.pega(ba, 0, 58 - ba.h)
    for yy in range(58, 72):                          # la ría
        L.hl(0, L.w - 1, yy, '#2e5a6a' if (yy // 2) % 2 else '#27505e')
    for x in range(0, L.w, 7):
        L.p(x + (x // 7) % 3, 62, '#6a9aa8')
        L.p(x + 2, 68, '#6a9aa8')
    return L

def pt_nave():   # la nave de Valdehierro, por fuera
    L = _fondo()
    _cielo(L, 34)
    nv = ajusta(cel('edificio-nave/base/unica/00'))
    if nv.h > 66:
        nv = nv.recorta(0, nv.h - 66, nv.w, 66)
    _pon(L, nv, 72 - 4 - nv.h)
    _suelo(L, 71)
    return L

def pt_club():   # el club de la Kale Zaharra, con su socio en la puerta
    L = _fondo()
    _cielo(L, 30)
    cb = ajusta(cel('edificio-club-kalea/base/unica/00'))
    if cb.h > 64:
        cb = cb.recorta(0, cb.h - 64, cb.w, 64)
    _pon(L, cb, 72 - 6 - cb.h)
    pj = ajusta(cel('cliente1/base/south/00')) if 'cliente1/base/south/00' in atlas()['frames'] else None
    if pj:
        L.pega(pj, 70, 72 - 4 - pj.h)
    _suelo(L, 71)
    return L

def pt_redada():   # la redada: la comisaría y los municipales en la puerta
    L = _fondo()
    _cielo(L, 26)
    cm = ajusta(cel('edificio-comisaria/base/unica/00'))
    if cm.h > 62:
        cm = cm.recorta(0, cm.h - 62, cm.w, 62)
    _pon(L, cm, 72 - 8 - cm.h)
    po = ajusta(cel('cop/base/south/00'))
    for dx in (-26, 24):
        L.pega(po, (L.w - po.w) // 2 + dx, 72 - 5 - po.h)
    _suelo(L, 71)
    return L

def pt_feria():   # la feria de semillas: el mercado de la Ribera
    L = _fondo()
    _cielo(L, 20)
    mr = cel('edificio-mercadoR/base/unica/00')
    b = mr.im.getbbox()
    mr = mr.recorta(b[0] + ((b[2] - b[0]) - 104) // 2, b[1], 104, min(64, b[3] - b[1]))
    L.pega(mr, 0, 72 - 8 - mr.h)
    cl = ajusta(cel('cliente3/base/south/00')) if 'cliente3/base/south/00' in atlas()['frames'] else None
    if cl:
        for dx in (-34, 30):
            L.pega(cl, (L.w - cl.w) // 2 + dx, 72 - 5 - cl.h)
    _suelo(L, 71)
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
        sale('pt-' + k, impreso(f()))
    for k, f in PS.items():
        sale('ps-' + k, impreso(f()))
    return SAL

# ---------- las tres láminas del póster central (104 × 56) ----------
# La variedad del mes a toda plana, con su porte: la índica compacta y ancha, la sativa espigada y el híbrido en medio (ataque de
# la revisión: el póster repetía la lámina de la portada). La elige rev_pst_pl() por el % índica de la variedad.
def _ps(porte, ancho=38, hmax=60):
    """la lámina del póster: la planta de la vista de carpa con ese porte, en su maceta y con la pared de la carpa"""
    L = _fondo(104, 80)
    pa = cel('carpa-c-fondo/carpa-c-pared/unica/00')
    L.pega(pa.recorta((pa.w - 104) // 2, pa.h - 80, 104, 80), 0, 0)
    mc = ajusta(cel('carpa-c-macetas-b/maceta-c-tela25-27/unica/00'))
    pl = planta_cabe(porte, ancho, hmax)
    _pon(L, mc, 79 - mc.h)
    ph = min(pl.h, 60)
    _pon(L, pl.recorta(0, max(0, pl.h - ph), pl.w, ph), 79 - mc.h - ph + 8)
    L.contorno(K2)
    return L

def ps_ind():    # índica: baja, ancha y de cola gorda
    return _ps('i', 38, 44)

def ps_sat():    # sativa: alta y espigada
    return _ps('s', 32, 60)

def ps_hib():    # el híbrido, en medio
    return _ps('h', 38, 52)

PS = {'ind': ps_ind, 'sat': ps_sat, 'hib': ps_hib}

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
