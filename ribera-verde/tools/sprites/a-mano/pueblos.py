# python3 -I tools/sprites/a-mano/pueblos.py [sprite ...]   (Python 3 + Pillow)
# Los hitos de los pueblos de siempre (lo pidió el usuario: «toca también los otros para que sean de jugabilidad… que no sea todo el
# mismo esquema de pueblo» y «más natural, que no sea tan cuadrado. Pero que los píxeles sean perfectos»), con Datos.CAL, a 16 px/m,
# de frente y con el estilo de las fachadas aprobadas (mundo.py, bilbao.py). Alfa binario: fuera de la silueta, transparente (debajo,
# el suelo de su casilla: las casillas «hito_<suelo>» de tools/pueblos.py, que pinta.gd dibuja como ese suelo).
#  · lavadero (4 × 3): el lavadero cubierto de Ribera Verde, junto al río: tejado a dos aguas sobre postes y la pila de piedra con agua;
#  · fronton (6 × 3): la pared del frontón de Mendialde, encalada, con la chapa de abajo y las rayas pintadas;
#  · ermita (4 × 4): la ermita de Mendialde, encalada, con la espadaña y su campana, el óculo y la puerta en arco (2 casillas);
#  · faro (2 × 5): el faro del espigón de Puerto Viejo, blanco con dos fajas rojas, la linterna y la cúpula;
#  · chimenea (2 × 6): la chimenea de la fundición vieja de Valdehierro, de ladrillo, con sus anillos y la corona;
#  · gruaT (4 × 7): la grúa de pórtico de bilbao.py sin el muelle de debajo, para los astilleros;
#  · después de la revisión (cada pueblo, el suyo): reloj (2 × 5), la torre del reloj de la plaza de Ibarbide; prensa (2 × 2), el
#    quiosco de prensa del Ensanche, y colmenas (3 × 2), el colmenar de Errotabarri.
# Sale a art/crudo/edificio-<sprite>/base/unica/00.png; después, node tools/sprites/procesar.js <ids> --atlas --atlas-dir godot/arte.
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, azar
import mundo as M
import bilbao as B

CAL0, CAL1, CAL2, CAL3 = '#ece6d6', '#f8f4ea', '#cfc6b0', '#8a8068'      # encalado: base, luz, sombra, contorno
MAD, MADL, MADS = '#7a5230', '#9a6c40', '#4e321c'                        # madera
PIE, PIEL, PIES = '#9a9488', '#b8b2a4', '#6e685c'                        # piedra gris del país
AG, AGL, AGS = '#4a78a0', '#7aa8cc', '#2e5272'                           # agua
LAD, LADL, LADS, LADO = '#a04a34', '#bc6446', '#7a3426', '#4a2016'       # ladrillo
NEG = '#26262e'


def lavadero():
    W, H = 64, 48
    lz = Lienzo(W, H)
    M.tejas(lz, 0, 2, W, 12, M.TEJA, alto=4, paso=6, sem=71)          # el tejado a dos aguas (de frente, el faldón)
    for x in range(W):                                                  # la cumbrera, un poco combada
        lz.p(x, 1 + (1 if 8 < x < W - 8 else 0), M.TEJA[2])
    lz.hl(0, W - 1, 14, MADS); lz.hl(1, W - 2, 15, MAD)                # el alero
    lz.r(3, 16, W - 6, 14, PIES)                                       # la pared del fondo, en sombra
    B.piedra(lz, 3, 16, W - 6, 14, (PIES, '#5a554a', PIE), sem=72, bw=10, bh=4)
    for x in (2, 30, 59):                                               # los postes
        lz.r(x, 15, 3, 18, MAD); lz.vl(x, 15, 32, MADL); lz.vl(x + 2, 15, 32, MADS)
    lz.r(1, 31, W - 2, 3, AGS)                                          # la pila: el agua, el borde y la piedra
    lz.r(2, 32, W - 4, 2, AG)
    for x in range(4, W - 4, 7):
        lz.hl(x, x + 2, 32, AGL)
    lz.hl(0, W - 1, 34, PIEL); lz.hl(0, W - 1, 35, PIE)
    B.piedra(lz, 0, 36, W, 10, (PIE, PIES, PIEL), sem=73, bw=12, bh=5)
    for x in range(6, W - 6, 13):                                       # las losas inclinadas de frotar
        lz.hl(x, x + 7, 36, PIEL); lz.hl(x + 1, x + 6, 37, CAL2)
    lz.hl(1, W - 2, 46, PIES); lz.hl(2, W - 3, 47, '#4a463e')
    return lz


def fronton():
    W, H = 96, 48
    lz = Lienzo(W, H)
    lz.r(0, 0, W, H, CAL0)
    R = azar(81)
    for _ in range(W * H // 14):                                        # el revoco, con su grano
        lz.p(int(R() * W), int(R() * H), CAL2 if R() < .6 else CAL1)
    lz.hl(0, W - 1, 0, PIES); lz.hl(0, W - 1, 1, PIE); lz.hl(0, W - 1, 2, PIEL)   # la albardilla
    for y in range(3, 30):                                              # la mancha de los pelotazos, en el centro
        for x in range(30, 66):
            if R() < .05 + .04 * (1 - abs(x - 48) / 18):
                lz.p(x, y, CAL3 if R() < .2 else CAL2)
    lz.r(0, 36, W, 6, '#3c6a4c'); lz.hl(0, W - 1, 36, '#5a8c68'); lz.hl(0, W - 1, 41, '#24402e')   # la chapa
    for x in range(0, W, 12):
        lz.vl(x, 37, 40, '#24402e')
    lz.hl(0, W - 1, 34, '#c84030')                                      # la raya de la falta, roja
    for x in (2, 93):                                                   # las rayas verticales de los lados
        lz.vl(x, 3, 33, '#c84030')
    for y in range(42, H):                                              # el zócalo de piedra
        lz.hl(0, W - 1, y, PIES if y == 42 else PIE if y < H - 1 else '#4a463e')
    for x in range(0, W, 9):
        lz.vl(x, 43, 46, PIES)
    for y in range(3, 42):                                              # el canto de la pared izquierda, de lado
        lz.p(0, y, CAL3); lz.p(1, y, CAL2)
        lz.p(W - 1, y, CAL3)
    return lz


def ermita():
    W, H = 64, 64
    lz = Lienzo(W, H)
    # la espadaña con la campana (arriba, en medio)
    lz.caja(26, 0, 12, 14, CAL0, CAL3)
    B.arco(lz, 28, 8, 3, 11, NEG)
    lz.r(30, 6, 4, 4, '#b08a30'); lz.hl(29, 34, 10, '#7a5a20'); lz.p(31, 6, '#e0c060')
    lz.hl(25, 38, 13, CAL3)
    # el tejado a dos aguas (el piñón de frente) y la fachada encalada
    for y in range(12, 26):
        w = 6 + (y - 12) * 2
        lz.hl(32 - w, 31 + w, y, M.TEJA[0] if (y - 12) % 4 != 3 else M.TEJA[2])
        lz.p(32 - w, y, M.TEJA[2]); lz.p(31 + w, y, M.TEJA[2])
        lz.p(33 - w, y, M.TEJA[1]); lz.p(30 + w, y, M.TEJA[1])
    lz.hl(2, W - 3, 26, M.TEJA[2])
    lz.r(4, 27, W - 8, 35, CAL0)
    R = azar(91)
    for _ in range(260):
        lz.p(4 + int(R() * (W - 8)), 27 + int(R() * 35), CAL2 if R() < .7 else CAL1)
    for y in range(27, 62, 6):                                          # las esquinas de sillar
        for x0 in (4, W - 10):
            w = 6 if (y // 6) % 2 else 4
            xx = x0 if x0 == 4 else W - 4 - w
            lz.caja(xx, y, w, 6, PIEL, PIES)
    lz.hl(4, W - 5, 27, CAL3)
    # el óculo
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            d = dx * dx + dy * dy
            if d <= 12:
                lz.p(32 + dx, 34 + dy, PIES if d > 6 else NEG if d > 1 else '#5a6a80')
    # la puerta en arco, de dos casillas (16..47 en x: la casilla de la puerta y la de al lado)
    B.arco(lz, 21, 22, 40, 62, PIEL)
    B.arco(lz, 23, 18, 42, 62, MAD)
    lz.vl(32, 50, 62, MADS)
    for x in (25, 29, 35, 39):
        lz.vl(x, 48, 62, MADS)
    lz.p(30, 56, '#c8a040'); lz.p(34, 56, '#c8a040')
    lz.hl(2, W - 3, 62, PIES); lz.hl(2, W - 3, 63, '#4a463e')        # el escalón
    lz.hl(20, 43, 62, PIEL)
    return lz


def faro():
    W, H = 32, 80
    lz = Lienzo(W, H)
    BLA, BLS, ROJ, ROJS = '#f2f0ea', '#c8c4ba', '#c43a2a', '#8a2418'
    for y in range(20, 72):                                             # la torre, en troncocono
        hw = 7 + (y - 20) * 3 // 52
        rojo = 34 <= y < 42 or 54 <= y < 62
        for x in range(16 - hw, 16 + hw):
            c = (ROJ if rojo else BLA) if x < 16 + hw - 3 else (ROJS if rojo else BLS)
            lz.p(x, y, c)
        lz.p(16 - hw - 1, y, NEG); lz.p(16 + hw, y, NEG)
    for y in (26, 48):                                                  # los ventanucos
        lz.r(15, y, 3, 4, NEG); lz.p(15, y, '#5a6a80')
    lz.r(13, 64, 6, 8, MADS); lz.vl(16, 64, 71, MAD)                  # la puerta
    lz.hl(5, 26, 19, NEG); lz.hl(6, 25, 18, '#5a5e66')                # el balcón
    for x in range(6, 26, 3):
        lz.vl(x, 14, 17, NEG)
    lz.hl(6, 25, 14, NEG)
    lz.caja(10, 6, 12, 9, '#f0d878', NEG)                              # la linterna, con la luz dentro
    lz.vl(16, 7, 13, '#c8a030'); lz.r(12, 8, 2, 2, '#fff4c0')
    for y in range(0, 6):                                               # la cúpula
        hw = 2 + y
        lz.hl(16 - hw, 15 + hw, y, ROJS if y < 2 else ROJ)
        lz.p(16 - hw - 1, y, NEG); lz.p(16 + hw, y, NEG)
    lz.p(16, 0, NEG); lz.p(15, 0, NEG)
    lz.r(3, 72, 26, 8, PIE)                                             # la base de piedra
    lz.hl(3, 28, 72, PIEL); lz.hl(3, 28, 79, PIES)
    for x in range(5, 28, 6):
        lz.vl(x, 73, 78, PIES)
    lz.vl(2, 72, 79, NEG); lz.vl(29, 72, 79, NEG)
    return lz


def chimenea():
    W, H = 32, 96
    lz = Lienzo(W, H)
    R = azar(101)
    for y in range(6, 82):                                              # el fuste, que se estrecha hacia arriba
        hw = 5 + (y - 6) * 4 // 76
        for x in range(16 - hw, 16 + hw):
            fila = (y // 3) % 2
            c = LADS if (y % 3 == 2) else (LAD if (x + fila * 2) % 5 else LADS)
            if x >= 16 + hw - 2:
                c = LADO if y % 3 == 2 else LADS
            elif x == 16 - hw and R() < .5:
                c = LADL
            lz.p(x, y, c)
        lz.p(16 - hw - 1, y, NEG); lz.p(16 + hw, y, NEG)
    for y in (24, 46, 66):                                              # los anillos de hierro
        hw = 5 + (y - 6) * 4 // 76
        lz.hl(16 - hw - 1, 16 + hw, y, '#3a3a40'); lz.hl(16 - hw, 15 + hw, y - 1, '#5a5e66')
    lz.r(8, 0, 16, 6, LAD)                                              # la corona
    lz.hl(8, 23, 0, NEG); lz.hl(9, 22, 1, '#2a2020'); lz.hl(8, 23, 5, LADO)
    lz.vl(7, 0, 5, NEG); lz.vl(24, 0, 5, NEG)
    for x in range(9, 23, 3):
        lz.p(x, 3, LADL)
    lz.r(3, 82, 26, 14, LAD)                                            # el pedestal
    for y in range(82, 96, 3):
        lz.hl(3, 28, y, LADS)
    lz.r(3, 82, 26, 2, PIEL); lz.hl(3, 28, 95, LADO)
    lz.vl(2, 82, 95, NEG); lz.vl(29, 82, 95, NEG)
    lz.caja(12, 86, 8, 10, '#3a3a40', NEG)                             # el registro tapiado
    return lz


def reloj():
    """la torre del reloj de la plaza de Ibarbide (2 × 5): sillería, la esfera blanca con sus agujas, el chapitel de pizarra y,
    abajo, el banco corrido de piedra y la puertecilla"""
    W, H = 32, 80
    lz = Lienzo(W, H)
    R = azar(131)
    for y in range(18, 74):                                             # el fuste de sillería
        for x in range(5, 27):
            c = PIE if (x + (y // 6) * 3) % 9 else PIES
            if y % 6 == 0:
                c = PIES
            elif x >= 24:
                c = PIES
            elif x == 5 and R() < .5:
                c = PIEL
            lz.p(x, y, c)
        lz.p(4, y, NEG); lz.p(27, y, NEG)
    lz.hl(3, 28, 17, NEG); lz.hl(4, 27, 18, PIEL)                      # la cornisa
    for y in range(26, 42):                                             # la esfera
        for x in range(6, 26):
            d = (x - 15.5) ** 2 + (y - 33.5) ** 2
            if d <= 56:
                lz.p(x, y, NEG if d > 42 else '#f4f0e4')
    for i in range(12):
        import math
        a = i * math.pi / 6
        lz.p(int(round(15.5 + 5.2 * math.sin(a))), int(round(33.5 - 5.2 * math.cos(a))), '#5a5e66')
    lz.vl(15, 29, 33, NEG); lz.hl(16, 18, 34, NEG); lz.p(15, 34, '#c43a2a')   # las agujas
    for y in range(0, 17):                                              # el chapitel de pizarra, con su veleta
        hw = 1 + y * 12 // 16
        lz.hl(16 - hw, 15 + hw, y, '#3a4250' if (y % 3) else '#2a2e38')
        lz.p(16 - hw, y, '#5a6274'); lz.p(15 + hw, y, NEG)
    lz.vl(15, 0, 2, NEG)
    lz.r(12, 46, 8, 10, '#3a3e48'); lz.hl(12, 19, 46, NEG)            # el ventanal de la campana
    lz.r(14, 48, 4, 5, '#b08a30')
    lz.r(12, 62, 8, 12, MADS); lz.vl(15, 62, 73, MAD); lz.p(17, 68, '#c8a040')   # la puertecilla
    lz.r(0, 74, W, 6, PIEL); lz.hl(0, W - 1, 74, CAL1); lz.hl(0, W - 1, 79, PIES)   # el banco corrido
    lz.vl(0, 74, 79, NEG); lz.vl(W - 1, 74, 79, NEG)
    return lz


def prensa():
    """el quiosco de prensa del Ensanche (2 × 2): la caseta verde con el tejadillo, el mostrador con los periódicos doblados y las
    revistas colgadas (de colores, sin letras)"""
    W, H = 32, 32
    lz = Lienzo(W, H)
    VE, VEL, VES = '#2e6a48', '#4a8a62', '#1c4430'
    lz.r(1, 2, 30, 5, VES); lz.hl(1, 30, 2, VEL); lz.hl(0, 31, 6, NEG)        # el tejadillo
    for x in range(2, 30, 4):
        lz.vl(x, 3, 5, VE)
    lz.r(3, 7, 26, 15, VE); lz.vl(3, 7, 21, VEL); lz.vl(28, 7, 21, VES)
    for i, c in enumerate(('#c84030', '#e8b83a', '#3a6ab0', '#e0e0d8', '#9a3a8a', '#4aa060')):   # las revistas colgadas
        x = 5 + i * 4
        lz.r(x, 9, 3, 5, c); lz.p(x, 9, NEG); lz.p(x + 2, 9, NEG)
    lz.r(5, 15, 22, 6, '#1a2a22')                                      # el hueco, con el quiosquero en sombra
    lz.r(1, 21, 30, 4, MAD); lz.hl(1, 30, 21, MADL); lz.hl(1, 30, 24, MADS)   # el mostrador
    for x in range(3, 29, 5):                                           # los periódicos doblados
        lz.r(x, 19, 4, 2, '#e8e4d8'); lz.hl(x, x + 3, 20, '#a8a498')
    lz.r(3, 25, 26, 6, VES); lz.hl(3, 28, 25, VE)
    lz.hl(1, 30, 31, NEG); lz.vl(0, 7, 31, NEG); lz.vl(31, 7, 31, NEG)
    return lz


def colmenas():
    """el colmenar de Errotabarri (3 × 2): tres colmenas de madera de colores sobre su banco de piedra, con la piquera y alguna
    abeja suelta"""
    W, H = 48, 32
    lz = Lienzo(W, H)
    lz.r(0, 26, W, 6, PIE); lz.hl(0, W - 1, 26, PIEL); lz.hl(0, W - 1, 31, PIES)   # el banco de piedra
    for x in range(4, W, 11):
        lz.vl(x, 27, 30, PIES)
    for i, (c, cl, cs) in enumerate((('#d8b04a', '#ecc868', '#a88030'), ('#5a8ab0', '#7aaad0', '#3a6080'), ('#c86a4a', '#e08a68', '#985038'))):
        x = 2 + i * 15
        y = 8 + (i % 2) * 2
        lz.r(x, y, 14, 18 - (i % 2) * 2, c); lz.vl(x, y, 25, cl); lz.vl(x + 13, y, 25, cs)
        lz.hl(x, x + 13, y + 6, cs); lz.hl(x, x + 13, y + 12, cs)       # las alzas
        lz.r(x - 1, y - 3, 16, 3, '#8a8478'); lz.hl(x - 1, x + 14, y - 3, '#aaa498')   # la tapa de chapa
        lz.r(x + 4, 23, 6, 2, NEG)                                      # la piquera
        lz.vl(x - 1, y, 25, NEG); lz.vl(x + 14, y, 25, NEG)
    for x, y in ((9, 3), (25, 2), (40, 5), (33, 21), (20, 6)):          # las abejas
        lz.p(x, y, '#e8b83a'); lz.p(x + 1, y, NEG)
    return lz


SPRITES = {'lavadero': lavadero, 'fronton': fronton, 'ermita': ermita, 'faro': faro, 'chimenea': chimenea,
           'gruaT': lambda: B.grua(fondo=False), 'reloj': reloj, 'prensa': prensa, 'colmenas': colmenas}

if __name__ == '__main__':
    for k in sys.argv[1:] or list(SPRITES):
        B.guarda('edificio-' + k, SPRITES[k]())
    for f in M.OUT:
        print(f)
