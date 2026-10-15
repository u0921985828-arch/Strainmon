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
# (1.36.2: alm-cog-* y alm-x-*, lo de dentro, abajo)
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

def tarro(tapa, w=18, h=25):
    """18 × 25 (por dentro: x 1-16, y 4-23); 1.43.6, el de 10 L del camarote, 22 × 31 (por dentro: x 1-20, y 4-29)"""
    L = Lienzo(w, h); cuerpo(L, w, h, tapa); return L

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

def mas(w=18, h=25):
    """GUARDAR en la caja: el tarro abierto, vacío, con el más verde (1.43.6: y el de 10 L del camarote)"""
    L = Lienzo(w, h)
    L.r(1, 4, w - 2, h - 5, '#1d2428')
    cuerpo(L, w, h, None)
    L.hl(2, w - 3, 2, VI1); L.hl(3, w - 4, 3, VI3)                                             # la boca abierta
    dx, dy = (w - 18) // 2, (h - 25) // 2
    L.r(8 + dx, 9 + dy, 3, 11, '#2a5a30'); L.r(4 + dx, 13 + dy, 11, 3, '#2a5a30')              # el más, con su sombra
    L.r(7 + dx, 8 + dy, 3, 11, '#58d080'); L.r(3 + dx, 12 + dy, 11, 3, '#58d080'); L.p(7 + dx, 8 + dy, '#a8f0c0'); L.p(3 + dx, 12 + dy, '#a8f0c0')
    return L

# ---------- el camarote por dentro (1.43.6, lo pidió el usuario: «botes más grandes de cristal con bóvedas de humedad») ----------
# alm-camarote (168 × 100): el machihembrado de pino de la buhardilla, la luz de la ventana de tejado y dos baldas de la estantería
# metálica, con sus montantes perforados; los tarros de 10 L (22 × 31) se apoyan en y = 37 y 83, seis por balda
def camarote():
    L = Lienzo(168, 100)
    PINO = ('#c89c64', '#b08452', '#8a6640', '#d8b07a')
    for x in range(168):
        c = PINO[0] if x % 6 else PINO[2]
        if x % 6 == 1: c = PINO[3]
        L.vl(x, 0, 99, c)
    for y in range(0, 100, 3):
        for x in range(2 + (y // 3) % 4, 168, 23): L.p(x, y, PINO[1])                         # las vetas
    L.r(56, 0, 56, 3, '#f4f0d8'); L.hl(60, 107, 3, '#e8dcb8'); L.hl(64, 103, 4, '#dccc9e')    # la luz de la ventana de tejado
    L.r(0, 0, 168, 2, '#4e341e'); L.r(0, 96, 168, 4, '#4e341e'); L.hl(0, 167, 96, '#7a5432')  # las vigas
    for x in (2, 162):                                                                         # los montantes perforados
        L.r(x, 2, 4, 94, '#5a646e'); L.vl(x, 2, 95, '#8c98a2'); L.vl(x + 3, 2, 95, '#3a4048')
        for y in range(6, 94, 5): L.p(x + 1, y, '#2a2e34'); L.p(x + 2, y, '#2a2e34')
    for y in (37, 83):                                                                         # las baldas de chapa
        L.r(4, y, 160, 4, '#7e8a94'); L.hl(4, 163, y, '#b4bec6'); L.hl(4, 163, y + 3, '#3a4048')
        L.hl(6, 161, y + 4, '#6e5434')                                                         # su sombra en la pared
    return L

def higro():
    """el icono de la humedad (7 × 7): una gota"""
    L = Lienzo(7, 7)
    L.p(3, 0, '#4e9ad8'); L.hl(2, 4, 1, '#4e9ad8'); L.hl(1, 5, 2, '#4e9ad8'); L.r(1, 3, 5, 3, '#4e9ad8'); L.hl(2, 4, 6, '#2e6aa0')
    L.p(2, 3, '#b4dcfa'); L.p(2, 4, '#8ec0ec')
    L.contorno(K)
    return L

def etiqueta():
    """la etiqueta de papel (10 × 4) escrita a mano; el juego le pone el sello verde del curado a la derecha"""
    L = Lienzo(10, 4)
    L.r(0, 0, 10, 4, '#f0ead8'); L.hl(0, 9, 3, '#cfc6aa'); L.vl(9, 0, 3, '#dcd4bc')
    L.hl(1, 5, 1, '#5a5448'); L.p(3, 1, '#f0ead8'); L.hl(1, 3, 2, '#8a8474'); L.hl(5, 6, 2, '#8a8474')
    return L


# ---------- lo de dentro (1.36.2, lo pidió el usuario: «sprites realistas», pelados y sin pelar, y cada extracción) ----------
# Cuatro niveles por lo lleno (1-4: un cuarto, medio, tres cuartos, lleno) y dibujados a su tamaño (s = 1) y al doble con más
# detalle (s = 2, -g), no escalados. Ancla arriba a la izquierda del hueco del tarro: 16 × 20 los cogollos y 10 × 7 los botes.
#  · alm-cog-p-N / alm-cog-s-N: los cogollos, pelados (manicurados: redondos, prietos y con toda la escarcha a la vista) y sin
#    pelar (con las hojitas de azúcar asomando, verdes y escarchadas en la punta). El color lo pone el juego (el de la variedad,
#    un rectángulo debajo): el sprite deja transparente el cuerpo de cada cogollo y pinta encima la sombra, la escarcha y los
#    pelos; lo vacío de encima va en el gris de dentro del tarro.
#  · alm-x-<tipo>-N: cada extracción como es (fuentes en el CHANGELOG), con su color, sobre lo vacío:
#    rosin: fresco, ámbar translúcido y cristalino como savia espesa, plano como un líquido, con su brillo; rosin-cu: curado
#    en frío, opaco y cremoso («badder»), de crema a tostado claro, con la superficie batida; seco (dry sift): polvo de arena
#    rubio-tostado, en montón; ice (bubble hash secado): arena rubia en grumos; charas: bolas oscuras, casi negras por fuera,
#    amasadas a mano, con brillo de grasa; hash (kief prensado): placas marrones apiladas con el canto más claro; moon
#    (moonrock): cogollos bañados en aceite y rebozados en kief, rocas verdes con costra arenosa; stat (static): polvo finísimo,
#    casi blanco, de pura cabeza de tricoma.
VACIO = '#2a343a'
def azar_px(x, y, sem=0): return (x * 73 + y * 151 + x * y * 7 + sem * 977) % 97
NIV = (1, 2, 3, 4)

def cogollos(n, pelado, s, W=None, H=None):
    W, H = W or 16 * s, H or 20 * s
    L = Lienzo(W, H); L.r(0, 0, W, H, VACIO)
    alto = round(H * n / 4)                                                                    # hasta dónde llegan
    r = 3.4 * s
    # los cogollos, de abajo arriba en filas a tresbolillo; entran los que caben por debajo de su nivel
    nugs = []
    filas = int(H / (r * 1.45)) + 2
    for fi in range(filas):
        cy = H - r * .9 - fi * r * 1.45
        off = (r * .95) if fi % 2 else 0
        cx = -r * .3 + off
        while cx < W + r:
            j = azar_px(int(cx * 3), fi, 5) % 7 - 3
            nugs.append((cx + j * s * .25, cy + (azar_px(fi, int(cx), 2) % 3 - 1) * s * .3, r * (.86 + azar_px(int(cx), fi, 9) % 5 * .06)))
            cx += r * 1.9
    nugs = [q for q in nugs if q[1] - q[2] * .55 >= H - alto]
    nugs.sort(key=lambda q: q[1])                                                              # los de abajo, delante
    for (cx, cy, rr) in nugs:
        for y in range(int(cy - rr) - 1, int(cy + rr) + 2):
            for x in range(int(cx - rr) - 1, int(cx + rr) + 2):
                dx, dy = x + .5 - cx, (y + .5 - cy) * 1.08; d = (dx * dx + dy * dy) ** .5
                if d > rr or not (0 <= x < W and 0 <= y < H): continue
                q = azar_px(x, y, s)
                if d > rr - .9 * s and dx + dy > -.3 * rr: L.p(x, y, '#1c2418')               # la sombra con el de delante
                elif d > rr - 1.6 * s and dx + dy > .5 * rr and q % 3 == 0: L.p(x, y, '#3a4a2c')  # el lado en sombra
                elif dx + dy < -.35 * rr and d > .3 * rr and q % (3 if pelado else 5) == 0:
                    L.p(x, y, '#e4ecd0' if q % 4 else '#ffffff')                                 # la escarcha, arriba a la izquierda
                elif not pelado and d > rr - 1.2 * s and q % 4 == 0: L.p(x, y, '#46742e')        # sin pelar: hoja por fuera
                elif s == 2 and q % 17 == 0: L.p(x, y, '#c8d4b0')                               # tricomas sueltos
                else: L.px[x, y] = (0, 0, 0, 0)                                                  # el color de la variedad
        # los pelos (pistilos), naranjas, rizados hacia fuera
        for k in range(2 if pelado else 3):
            q = azar_px(int(cx * 7), int(cy * 3), k)
            ang = (q % 8) * .785; import math
            x0, y0 = cx + math.cos(ang) * rr * .45, cy + math.sin(ang) * rr * .45
            for t in range(1 + s):
                L.p(int(x0 + math.cos(ang) * t), int(y0 + math.sin(ang) * t), '#d8782c' if t < s else '#b85a20')
        if not pelado:                                                                          # las hojitas de azúcar asomando
            for k in range(3):
                q = azar_px(int(cx * 5), int(cy * 11), k + 3)
                ang = -2.9 + k * 1.3 + (q % 5 - 2) * .2; import math
                largo = int((2.2 + q % 3 * .6) * s)
                for t in range(largo):
                    px = int(cx + math.cos(ang) * (rr * .7 + t)); py = int(cy + math.sin(ang) * (rr * .7 + t))
                    c = '#3e6a2a' if t < largo - 1 else ('#d8e2c0' if q % 2 else '#5a8a3c')
                    L.p(px, py, c)
                    if s == 2 and t < largo - 2: L.p(px + 1, py, '#3c6a2c')
    return L

def extracto(tipo, n, s):
    W, H = 10 * s, 7 * s
    L = Lienzo(W, H)
    alto = max(s, round(H * n / 4))
    top = H - alto
    import math
    if tipo == 'rosin':                                                                         # savia ámbar, plana, translúcida
        for y in range(top, H):
            for x in range(W):
                c = '#c88a14' if (y - top) < alto * .5 else '#a8680c'
                if x == 0 or x == W - 1: c = '#8a5208'
                L.p(x, y, c)
        L.hl(0, W - 1, top, '#f0c048'); L.p(0, top - 1 if top else top, '#e0b040'); L.p(W - 1, top - 1 if top else top, '#e0b040')   # el menisco
        for y in range(top + 1, H - 1): L.p(1 + s, y, '#ffe08a') if (y - top) % 3 != 2 else None   # el brillo
        L.p(W - 2 - s, top + 1 if top + 1 < H else top, '#fff4c0')
        if s == 2:
            for (x, y) in ((6, top + 3), (12, top + 5), (15, top + 2)):
                if y < H: L.p(x, y, '#e8a828')                                                   # las burbujitas de aire
    elif tipo == 'rosin-cu':                                                                    # badder: cremoso y opaco, batido
        for x in range(W):
            hx = top - (1 if azar_px(x, 0, 3) % 3 == 0 and top > 0 else 0)
            for y in range(hx, H):
                q = azar_px(x, y, 4)
                c = '#ecd08a' if q % 4 else '#f6e2a8'
                if y == hx: c = '#fbecc0'
                if q % 13 == 0: c = '#d4b064'
                L.p(x, y, c)
        L.vl(0, top, H - 1, '#d4b064'); L.vl(W - 1, top, H - 1, '#c4a050')
    elif tipo in ('seco', 'ice', 'stat'):                                                       # polvos: en montón o en grumos
        base, claro, oscuro = {'seco': ('#c8a868', '#e2c888', '#a08448'), 'ice': ('#d8bc74', '#eed69a', '#b0904c'),
                                'stat': ('#efe2b4', '#fff8e0', '#d6c690')}[tipo]
        for x in range(W):
            cx = (x + .5 - W / 2) / (W / 2)
            monte = 0 if tipo == 'stat' and n == 4 else round(alto * .28 * (cx * cx)) if tipo != 'ice' else (azar_px(x, 1, 6) % 3 == 0) * s
            for y in range(top + monte, H):
                q = azar_px(x, y, 7 if tipo == 'seco' else 8)
                c = base
                if q % 3 == 0: c = claro
                elif q % 5 == 0: c = oscuro
                if tipo == 'stat' and q % 2: c = base if q % 7 else '#ffffff'
                L.p(x, y, c)
            if top + monte < H: L.p(x, top + monte, claro)
        if tipo == 'ice':                                                                       # los grumos, con su sombra
            for k in range(n + 1):
                gx, gy = (2 + k * 3) % (W - 2), H - 2 - (k * 2) % max(1, alto - 1)
                if gy >= top: L.r(gx, gy, s + 1, s, claro); L.hl(gx, gx + s, gy + s, oscuro)
    elif tipo in ('charas', 'moon'):                                                            # bolas a mano / rocas rebozadas
        cuantas = {1: 1, 2: 2, 3: 4, 4: 6}[n]
        rr = (1.9 if tipo == 'charas' else 2.1) * s
        pos = [(W * .3, H - rr), (W * .72, H - rr * .95), (W * .5, H - rr * 2.3), (W * .12, H - rr * 2.1), (W * .88, H - rr * 2.2), (W * .32, H - rr * 3.4)]
        for (cx, cy) in pos[:cuantas]:
            for y in range(int(cy - rr) - 1, int(cy + rr) + 2):
                for x in range(int(cx - rr) - 1, int(cx + rr) + 2):
                    dx, dy = x + .5 - cx, y + .5 - cy; d = (dx * dx + dy * dy) ** .5
                    if d > rr: continue
                    q = azar_px(x, y, 11)
                    if tipo == 'charas':
                        c = '#2c1a0e' if dx + dy > 0 else '#4a2e18'
                        if dx + dy < -rr * .8: c = '#7a5232'                                       # el brillo de la grasa
                        if q % 9 == 0: c = '#5a3a1e'
                    else:
                        c = '#4a5a24' if q % 3 else '#2e3818'                                     # el cogollo bajo el aceite
                        if q % 2 == 0 or dx + dy < -rr * .3: c = '#c8b070' if q % 3 else '#e2d08c'   # la costra de kief
                        if dx + dy > rr * .6 and q % 2: c = '#3a3010'
                    L.p(x, y, c)
    elif tipo == 'hash':                                                                        # placas prensadas, apiladas
        gr = max(1, round(1.6 * s))
        y = H
        for k in range(n):
            ancho = W - (k % 2) * s - s
            x0 = (W - ancho) // 2 + (s if k % 2 else 0)
            y -= gr
            if y < 0: break
            L.r(x0, y, ancho, gr, '#6e4424'); L.hl(x0, x0 + ancho - 1, y, '#9a6a3a')            # la cara de arriba, más clara
            L.p(x0, y, '#4a2c16'); L.p(x0 + ancho - 1, y + gr - 1, '#3a2010')
            if s == 2: L.p(x0 + 3 + k * 2, y + 1, '#845630'); L.p(x0 + ancho - 5, y + 2, '#5a3820')
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
sale('alm-etiqueta', etiqueta())
for g, s in (('', 1), ('-g', 2)):
    for n in NIV:
        for p in ('p', 's'): sale('alm-cog-%s-%d%s' % (p, n, g), cogollos(n, p == 'p', s))
        for t in ('rosin', 'rosin-cu', 'seco', 'ice', 'charas', 'hash', 'moon', 'stat'): sale('alm-x-%s-%d%s' % (t, n, g), extracto(t, n, s))
for n in ('thc', 'cu', 'mc', 'g', 'eur'): sale('alm-ic-' + n, icono(n))
sale('alm-ic-hr', higro())
sale('alm-camarote', camarote()); sale('alm-tarro-xl', tarro(LATON, 22, 31)); sale('alm-tarro-xl-s', tarro(ORO, 22, 31)); sale('alm-mas-xl', mas(22, 31))
for n in NIV:
    for p in ('p', 's'): sale('alm-cog-%s-%d-xl' % (p, n), cogollos(n, p == 'p', 1, 20, 26))
for n in ('alm-tarro', 'alm-tarro-s', 'alm-bote', 'alm-mas', 'alm-fajo', 'alm-etiqueta'): sale(n + '-g', doble(SAL[n]))

def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'almacen', n, 'unica'); os.makedirs(d, exist_ok=True)
        for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
        L.im.save(os.path.join(d, '00.png'))
        print('almacen', n, L.im.size, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
