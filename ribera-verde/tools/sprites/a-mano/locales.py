# python3 -I tools/sprites/a-mano/locales.py  (Python 3 + Pillow; no va en los scripts de npm)
# Lámina 16 (1.30): los locales en los que se entra como en una casa, dibujados a mano a 16 px/m como el piso y el bar.
#  · Fachadas con puerta (salen de las de mundo.py, con su rótulo): los cuatro clubs (Itsaso en una marinera de Puerto Viejo, el de
#    la Fundición con una puerta peatonal en el portón, Kalea en el Casco Viejo y el del Ensanche en un bajo con el toldo verde) y
#    la discoteca GAUA (el bajo de un bloque del Ensanche, negro, con el neón y la puerta doble acolchada).
#  · Suelos y paredes (casillas de 16 × 16): el club (parqué de tablero, pared verde y zócalo de madera), la nave de cultivo
#    (hormigón pulido y chapa grecada con la viga), la discoteca (baldosa negra, paneles acolchados con la tira de LED) y la pista
#    de baile (paneles de colores, tira de 4 variantes).
#  · Objetos de 1 casilla (objeto_1x1): la vitrina del dispensario, los tarros y la pizarra de la pared, las normas del club, el
#    taquero, la mesita baja, la barra de la discoteca, el neón de la luna, la mesa del reservado y el cordón; altos (objeto_alto):
#    el estante de abonos, el secadero de red y el altavoz.
#  · Muebles de 2 casillas (mueble_ancho, base en (16, 47), centrados en x 24): el billar con la lámpara de tres pantallas colgada,
#    los sofás chester (de frente y por detrás), el sofá de terciopelo del reservado, la cabina del DJ, el escritorio de la nave y
#    la mesa de cultivo de 240 × 120 cm con dos LED de barras encima (1.31, como los de las carpas), apagados y encendidos, y sus plantas aparte (1.31: plantasN, en los colores
#    de la planta A para el tono de cada variedad, por fase y porte).
# Sale a art/crudo/<grupo>/<sprite>/unica/NN.png (después, node tools/sprites/procesar.js <grupos> --atlas)
import os, sys, glob, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar
import mundo
from mundo import puertas, ventana, PIEDRA, MADERA
from salon import sofa as sofa_atras, suelo

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#2a2a34'                     # el contorno de los muebles (el de salon.py)

# ---------------------------------------------------------------------------------------------------------- letras
# una letra propia de 3 × 5 (la N y la M, de 4) para los rótulos
LETRA = {'C': '111100100100111', 'L': '100100100100111', 'U': '101101101101111', 'B': '110101110101110', 'G': '111100101101111',
         'A': '111101111101101', 'I': '111010010010111', 'T': '111010010010010', 'S': '111100111001111', 'O': '111101101101111',
         'K': '101101110101101', 'E': '111100110100111', 'N': '10011101101110011001', 'R': '110101110101101', 'Z': '111001010100111'}
TILDE = {'Ó': 'O'}                # 1.32: la vocal con su tilde, dos píxeles en diagonal encima
def rotulo(lz, x, y, txt, c):
    for ch in txt:
        if ch == ' ':
            x += 2; continue
        if ch in TILDE:
            ch = TILDE[ch]; lz.p(x + 1, y - 1, c); lz.p(x + 2, y - 2, c)
        m = LETRA[ch]; an = len(m) // 5
        for j in range(5):
            for i in range(an):
                if m[j * an + i] == '1': lz.p(x + i, y + j, c)
        x += an + 1
    return x

def ancho(txt):
    return sum(2 if ch == ' ' else len(LETRA[TILDE.get(ch, ch)]) // 5 + 1 for ch in txt) - 1

def placa(lz, x, y, txt, fondo, borde, letra):
    w, h = ancho(txt) + 4, 10 if any(ch in TILDE for ch in txt) else 9   # con tilde, una fila más
    lz.caja(x, y, w, h, fondo, borde)
    rotulo(lz, x + 2, y + h - 7, txt, letra)

# ---------------------------------------------------------------------------------------------------------- fachadas
LATON = ('#c8a040', '#6a5020', '#2a2018')

def club_itsaso():
    """el club de Puerto Viejo, en la marinera azul (4 × 6): la placa de latón sobre la puerta, una hoja en el cristal y el farol;
    la puerta en las casillas 1-2 (recorte en x 16, y 64)"""
    lz = mundo.marinera('marinera2')
    placa(lz, 24, 58, 'CLUB', *LATON)
    lz.r(28, 72, 8, 6, '#c8d8d0'); lz.hl(28, 35, 72, '#e8f0ec')
    for (x, y) in ((31, 73), (32, 73), (30, 74), (31, 74), (32, 74), (33, 74), (31, 75), (32, 75), (29, 75), (34, 75), (31, 76)):
        lz.p(x, y, '#3f8a46')
    lz.r(43, 62, 3, 4, '#2a2a34'); lz.p(44, 63, '#f0d070'); lz.p(44, 64, '#f0d070')   # el farol
    return lz, puertas(lz, 16, 64, (9, 5, 14, 27), 'simple')

def club_fundicion():
    """el club de Valdehierro, en la fundición vieja (8 × 6): una puerta peatonal en el portón de chapa, la placa encima con su
    aplique; la puerta en las casillas 3-4 (recorte en x 48, y 64)"""
    lz = mundo.fabrica()
    MAR = '#2a2624'
    lz.caja(56, 69, 16, 27, '#3a5446', MAR)                        # la puerta peatonal, cortada en el portón
    lz.r(57, 70, 14, 26, '#45604f')
    lz.caja(59, 72, 10, 6, '#f0d070', MAR); lz.hl(60, 67, 73, '#f8e8a8')   # el ventanuco, con luz dentro
    lz.vl(57, 70, 95, '#5a7a66'); lz.r(68, 82, 2, 3, '#c8a040')    # el canto y la manilla
    placa(lz, 55, 58, 'CLUB', '#e8e4d8', MAR, MAR)
    lz.r(62, 54, 4, 3, MAR); lz.hl(62, 65, 57, '#f0d070')          # el aplique
    return lz, puertas(lz, 48, 64, (9, 6, 14, 26), 'simple')

def club_kalea():
    """el club del Casco Viejo (4 × 6): la lonja con el cristal esmerilado y la hoja, el portal de madera corrido a la casilla 3 y
    la placa en la piedra (recorte en x 32, y 64: la puerta va con dx −8)"""
    lz = mundo.casco('casco', 4, 6, 91)
    H = 96
    for y in range(H - 27, H - 1):                                 # el portal viejo, tapado con la piedra del recercado
        for x in range(46, 62):
            lz.p(x, y, PIEDRA[2] if (x + y) % 9 else PIEDRA[1])
    lz.r(50, H - 25, 10, 25, MADERA[0]); lz.vl(55, H - 24, H - 1, MADERA[1]); lz.p(57, H - 12, '#e0b040')
    lz.r(51, H - 23, 3, 6, '#7a5232'); lz.r(56, H - 23, 3, 6, '#7a5232')
    for y in range(H - 27, H - 2):                                 # la lonja: esmerilado y una hoja verde en el centro
        for x in range(7, 21):
            if lz.g(x, y)[:3] == (0x2e, 0x3c, 0x4c): lz.p(x, y, '#c8d8d0')
    for (x, y) in ((13, 80), (14, 80), (12, 81), (13, 81), (14, 81), (15, 81), (13, 82), (14, 82), (11, 82), (16, 82), (13, 83), (14, 84)):
        lz.p(x, y, '#3f8a46')
    placa(lz, 27, 72, 'CLUB', *LATON)
    return lz, puertas(lz, 32, 64, (18, 7, 10, 25), 'simple')

def bajo(lz, x0, x1, c='#3a3a40'):
    """vacía el bajo de un bloque del Ensanche (y 82-108) entre x0 y x1"""
    lz.r(x0, 82, x1 - x0 + 1, 27, c)

def club_ensanche():
    """el club del Ensanche, en el bajo izquierdo del bloque gris (8 × 7): toldo verde con el rótulo, el escaparate esmerilado y
    la puerta de cristal en la casilla 2 (recorte en x 24, y 80)"""
    lz = mundo.bloque('bloque2')
    ALU = '#c8ccd0'
    bajo(lz, 2, 61)
    lz.r(2, 82, 60, 6, '#2f6a4a'); lz.hl(2, 61, 82, '#4a8a62')
    for x in range(2, 62): lz.p(x, 88, '#2f6a4a' if (x // 3) % 2 else '#1f4a30')   # el fleco del toldo
    rotulo(lz, 25, 83, 'CLUB', '#e8e4d8')
    lz.caja(5, 91, 24, 18, '#c8d8d0', ALU); lz.hl(6, 27, 92, '#e8f0ec')   # el escaparate esmerilado con la hoja
    for (x, y) in ((16, 96), (17, 96), (15, 97), (16, 97), (17, 97), (18, 97), (16, 98), (17, 98), (14, 98), (19, 98), (16, 99), (17, 100)):
        lz.p(x, y, '#3f8a46')
    lz.caja(33, 91, 14, 21, '#34404c', ALU); lz.vl(34, 92, 111, '#4a5a6a'); lz.p(35, 93, '#6f9fc4'); lz.p(36, 93, '#6f9fc4')
    lz.r(44, 100, 1, 4, ALU)                                        # el tirador
    lz.caja(50, 97, 5, 7, '#8a8e96', '#3a3a40'); lz.r(51, 98, 3, 2, '#2a2a34'); lz.p(52, 101, '#e0b040'); lz.p(52, 102, '#e0b040')   # el portero automático
    return lz, puertas(lz, 24, 80, (10, 12, 12, 20), 'simple')

NEON, NEON2, NEGRO = '#ff4fc8', '#40e0f0', '#141018'
LUNA = [(2, 0), (3, 0), (1, 1), (0, 2), (0, 3), (0, 4), (1, 5), (2, 6), (3, 6), (4, 5), (2, 1), (1, 2), (1, 3), (1, 4), (2, 5)]   # 7 px de alto
LETRA_G = {'G': ['01110', '10000', '10000', '10111', '10001', '10001', '01110'], 'A': ['01110', '10001', '10001', '11111', '10001', '10001', '10001'],
           'U': ['10001', '10001', '10001', '10001', '10001', '10001', '01110']}
def disco():
    """la discoteca GAUA (el bajo izquierdo del bloque crema, 8 × 7): fachada negra, el neón rosa con la luna azul, el marco de luz
    y la puerta doble acolchada en las casillas 1-2 (recorte en x 16, y 80)"""
    lz = mundo.bloque('bloque')
    bajo(lz, 0, 63, NEGRO)
    lz.hl(0, 63, 82, '#2a2236'); lz.r(62, 82, 4, 30, '#cfc3ac')
    x = 19
    for ch in 'GAUA':
        for j, fila in enumerate(LETRA_G[ch]):
            for i, b in enumerate(fila):
                if b == '1': lz.p(x + i, 84 + j, NEON)
        x += 7
    for (dx, dy) in LUNA: lz.p(8 + dx, 84 + dy, NEON2)              # la luna en cuarto creciente, azul
    lz.p(52, 85, NEON2); lz.p(51, 86, NEON2); lz.p(53, 86, NEON2); lz.p(52, 87, NEON2)   # la estrella
    lz.r(20, 93, 24, 19, NEON2)                                     # el marco de luz
    lz.caja(21, 94, 22, 18, '#2a1e30', '#0a0810')                   # la puerta doble acolchada
    for y in range(96, 111, 3):
        for xx in range(23 + (y // 3) % 2 * 2, 41, 4): lz.p(xx, y, '#3e2e48')
    lz.vl(31, 95, 111, '#0a0810'); lz.vl(32, 95, 111, '#0a0810')
    lz.r(29, 101, 1, 4, '#c8ccd0'); lz.r(34, 101, 1, 4, '#c8ccd0')
    for xx in (6, 54):                                              # los focos de suelo
        lz.r(xx, 109, 4, 3, '#2a2236'); lz.hl(xx, xx + 3, 108, '#8a50e0')
    return lz, puertas(lz, 16, 80, (5, 14, 22, 18), 'doble')

def asociacion():
    """la Asociación Cannábica Ribera Verde (1.32), en el barrio alto: la casa alta de almagre del Casco Viejo (5 × 7) con el bajo
    de la asociación: la lonja tapiada con la piedra, la ventana de cuarterones esmerilada con la hoja, la placa de latón encima y el
    portal de la derecha, pintado de verde (recorte en x 48, y 80: la puerta va con dx −8)"""
    lz = mundo.casco('casco3', 5, 7, 93)
    H = 112
    for y in range(H - 29, H - 3):                                 # la lonja, tapiada con la piedra del recercado
        for x in range(2, 30):
            if lz.g(x, y)[:3] not in [tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) for h in PIEDRA]:
                lz.p(x, y, PIEDRA[2] if (x + y) % 9 else PIEDRA[1])
    placa(lz, 7, H - 31, 'ASOCIACIÓN', *LATON)
    lz.caja(8, H - 20, 36, 15, '#c8d8d0', MADERA[0]); lz.hl(9, 42, H - 19, '#e8f0ec')   # la ventana esmerilada, de cuarterones
    for x in (17, 26, 35): lz.vl(x, H - 19, H - 7, MADERA[0])
    lz.hl(9, 42, H - 13, MADERA[0])
    for (x, y) in ((21, 99), (22, 99), (20, 100), (21, 100), (22, 100), (23, 100), (21, 101), (22, 101), (19, 101), (24, 101), (21, 102), (22, 103)):
        lz.p(x, y, '#3f8a46')
    lz.hl(7, 44, H - 5, PIEDRA[1])                                  # el alféizar
    lz.r(64, H - 25, 10, 25, '#2f5a3a'); lz.vl(69, H - 24, H - 1, '#1f4a30')   # el portal, verde
    lz.r(65, H - 23, 3, 8, '#3f7a4e'); lz.r(70, H - 23, 3, 8, '#3f7a4e'); lz.p(71, H - 12, '#e0b040')
    return lz, puertas(lz, 48, 80, (16, 7, 10, 25), 'simple')

FACHADAS = {'club-itsaso': club_itsaso, 'club-fundicion': club_fundicion, 'club-kalea': club_kalea, 'club-ensanche': club_ensanche, 'disco': disco, 'asociacion': asociacion}

# ---------------------------------------------------------------------------------------------------------- suelos y paredes
def floorC():
    """parqué de tablero: cuadros de 8 × 8 con dos lamas, en horizontal y en vertical a la contra"""
    L = Lienzo(16, 16); A, B, J, V = '#9a6a3c', '#a87646', '#6e4a2a', '#8a5e36'
    for y in range(16):
        for x in range(16):
            hor = ((x // 8) + (y // 8)) % 2 == 0
            u, v = (x % 8, y % 8) if hor else (y % 8, x % 8)
            c = J if v in (3, 7) else (B if v < 3 else A)
            if u in (2, 6) and v == 1: c = V
            L.p(x, y, c)
    return L

VERDE = ('#2e5a44', '#36664e', '#24483a', '#1a3628')
def iwT_club():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, VERDE[0])
    for y in range(6, 16, 4):
        for x in range((y // 4) % 2 * 2, 16, 4): L.p(x, y, VERDE[1])  # el estampado del papel
    L.r(0, 0, 16, 3, '#3a2618'); L.hl(0, 15, 1, '#5a3a24'); L.hl(0, 15, 3, '#74502e'); L.hl(0, 15, 4, VERDE[3])   # la moldura
    return L

def iwB_club():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 5, VERDE[0])
    for x in range(2, 16, 4): L.p(x, 2, VERDE[1])
    L.hl(0, 15, 4, VERDE[2])
    L.hl(0, 15, 5, '#a87646'); L.hl(0, 15, 6, '#74502e')            # el tope del zócalo
    L.r(0, 7, 16, 7, '#5a3a24')                                     # el zócalo de cuarterones
    L.caja(2, 8, 12, 5, '#62402a', '#4a2e1c'); L.hl(3, 12, 9, '#74502e')
    L.r(0, 14, 16, 2, '#2e1e12'); L.hl(0, 15, 14, '#4a2e1c')
    return L

def floorN():
    L = Lienzo(16, 16); R = azar(311)
    L.r(0, 0, 16, 16, '#8e8e8a')
    for _ in range(26): L.p(int(R() * 16), int(R() * 16), '#9a9a96' if R() < .55 else '#84847f')
    L.vl(15, 0, 15, '#76766f'); L.hl(0, 15, 15, '#76766f')            # la junta de la losa (1 × 1 m)
    L.p(4, 6, '#7c7c76'); L.p(5, 6, '#7c7c76'); L.p(5, 7, '#7c7c76')  # una mancha
    return L

CHAPA = ('#a9b4bc', '#8c98a2', '#6a7580')
def iwT_nave():
    L = Lienzo(16, 16)
    mundo.chapa(L, 0, 0, 16, 16, CHAPA, paso=4)
    L.r(0, 0, 16, 5, '#4a525a'); L.hl(0, 15, 0, '#6a737c'); L.hl(0, 15, 4, '#30363c')   # la viga
    for x in (3, 11): L.p(x, 2, '#9aa4ac')                          # los tornillos
    L.hl(0, 15, 5, CHAPA[2])
    return L

def iwB_nave():
    L = Lienzo(16, 16)
    mundo.chapa(L, 0, 0, 16, 11, CHAPA, paso=4)
    L.r(0, 11, 16, 5, '#9a9690'); L.hl(0, 15, 11, '#bab6ae'); L.hl(0, 15, 15, '#7a7670')   # el murete de hormigón
    L.p(6, 8, '#9a5a34'); L.p(6, 9, '#9a5a34'); L.p(13, 6, '#9a5a34')
    return L

def floorD():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#18121f')
    L.vl(7, 0, 15, '#100c16'); L.vl(15, 0, 15, '#100c16'); L.hl(0, 15, 7, '#100c16'); L.hl(0, 15, 15, '#100c16')
    for (x, y) in ((2, 2), (3, 2), (2, 3), (10, 10), (11, 10), (10, 11)): L.p(x, y, '#2e2840')   # el brillo
    return L

def iwT_disco():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#1e1628')
    for y in range(6, 16):                                          # el acolchado en rombos
        for x in range(16):
            if (x + y) % 6 == 0 or (x - y) % 6 == 0: L.p(x, y, '#2a2036')
    L.r(0, 0, 16, 4, '#0e0a14'); L.hl(0, 15, 4, NEON); L.hl(0, 15, 5, '#5a1a50')   # la tira de LED rosa
    return L

def iwB_disco():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#1e1628')
    for y in range(0, 12):
        for x in range(16):
            if (x + y) % 6 == 0 or (x - y) % 6 == 0: L.p(x, y, '#2a2036')
    L.hl(0, 15, 12, '#1a4a56'); L.hl(0, 15, 13, NEON2); L.r(0, 14, 16, 2, '#0e0a14')   # el zócalo con la tira azul
    return L

PISTA = ['#e040a0', '#40c8e0', '#f0d040', '#8a50e0', '#40e090', '#2a2236']
def baile():
    """la pista de baile: 2 × 2 paneles de 7 × 7 por casilla, en 4 variantes (tira de 64 × 16)"""
    L = Lienzo(64, 16); R = azar(97)
    L.r(0, 0, 64, 16, '#0e0a14')
    for v in range(4):
        for (px, py) in ((0, 0), (8, 0), (0, 8), (8, 8)):
            c = PISTA[int(R() * len(PISTA))]
            x0, y0 = v * 16 + px, py
            L.r(x0, y0, 7, 7, c)
            if c != PISTA[-1]:
                L.hl(x0, x0 + 5, y0, '#ffffff' if c in (PISTA[2], PISTA[4]) else '#f8d8f0'); L.p(x0, y0 + 1, '#f8d8f0')
    return L

# ---------------------------------------------------------------------------------------------------------- objetos de 1 casilla
VID, VIDL, CROMO = '#a8d4e0', '#e0f4f8', '#c8ccd0'
G1, G2, G3, PIS = '#3f7a3a', '#5aa04a', '#84cc6c', '#e08a3a'

def tarro(L, x, y, tapa):
    """un tarro de cristal de 4 × 6 con un cogollo dentro y la tapa de color"""
    L.r(x, y + 1, 4, 5, VID); L.vl(x, y + 1, y + 5, VIDL)
    L.r(x + 1, y + 3, 2, 3, G2); L.p(x + 2, y + 3, G3); L.p(x + 1, y + 4, PIS)
    L.hl(x, x + 3, y, tapa)

def vitrina():
    """el mostrador del dispensario (1 m): mueble de madera y, encima, la urna de cristal con los tarros"""
    L = Lienzo(16, 16); W0, W1, W2 = '#4a2e1c', '#62402a', '#74502e'
    L.r(0, 9, 16, 7, W1); L.hl(0, 15, 9, W2); L.hl(0, 15, 15, W0)
    L.caja(2, 10, 12, 4, W1, W0)
    L.r(0, 2, 16, 7, VID); L.hl(0, 15, 2, CROMO); L.hl(0, 15, 8, CROMO); L.vl(0, 2, 8, CROMO); L.vl(15, 2, 8, CROMO)
    tarro(L, 2, 2, '#c04848'); tarro(L, 9, 2, '#e0b040')
    L.p(7, 4, VIDL); L.p(14, 3, VIDL)
    L.contorno(K)
    return L

def tarros():
    """la balda de la pared con tres tarros (ALZA la sube como las baldas de la tienda)"""
    L = Lienzo(16, 16)
    L.r(0, 12, 16, 2, '#74502e'); L.hl(0, 15, 12, '#a87646')
    L.p(2, 14, '#4a2e1c'); L.p(13, 14, '#4a2e1c')
    tarro(L, 1, 5, '#3f8a46'); tarro(L, 6, 5, '#c04848'); tarro(L, 11, 5, '#e0b040')
    L.contorno(K)
    return L

def pizarra():
    """la pizarra de la variedad del día: marco de madera, la hoja de tiza y las líneas del precio"""
    L = Lienzo(16, 16)
    L.caja(1, 2, 14, 12, '#2a3a30', '#74502e'); L.hl(1, 14, 2, '#a87646')
    T = '#e8e8e0'
    L.hl(3, 9, 4, T); L.hl(3, 7, 7, T); L.hl(3, 8, 9, T); L.hl(3, 6, 11, T)
    L.p(11, 5, G3); L.p(12, 6, G3); L.p(10, 6, G3); L.p(11, 7, G3); L.p(11, 8, G3); L.p(9, 7, G3); L.p(13, 7, G3)
    L.hl(10, 12, 11, '#f0d070')
    L.contorno(K)
    return L

def cartelC():
    """las normas del club: la hoja blanca con la cabecera verde, las líneas y el «+18» en rojo"""
    L = Lienzo(16, 16)
    L.r(3, 1, 10, 14, '#f4f4ee'); L.r(3, 1, 10, 3, '#2f6a4a'); L.hl(4, 11, 2, '#e8e4d8')
    for y in (6, 8, 10): L.hl(4, 11, y, '#8a8a92')
    L.r(9, 11, 3, 3, '#c04848'); L.p(10, 12, '#f4f4ee')
    L.contorno(K)
    return L

def fotoMaite():
    """la foto de la tía Maite (1.32; 1.33, más grande, de 2 casillas, como los muebles anchos: lo pidió el usuario): el marco de
    madera de 28 × 18 con su luz arriba y a la izquierda, la placa de latón, el paspartú y, en la foto, de color algo amarillento por
    los años, la tía de joven, con la melena castaña y la blusa morada, junto a Delroy, más alto, con las rastas negras hasta el pecho
    y la camisa crema, y entre los dos una planta en flor, en el campo, con los montes detrás"""
    L = Lienzo(48, 48)
    W0, W1, W2, W3 = '#4a2e18', '#74502e', '#a07040', '#c8955a'
    x0, x1, y0, y1 = 10, 37, 29, 46
    L.r(x0, y0, x1 - x0 + 1, y1 - y0 + 1, W1)                                     # el marco
    L.hl(x0, x1, y0, W3); L.vl(x0, y0, y1, W3); L.hl(x0 + 1, x1 - 1, y0 + 1, W2); L.vl(x0 + 1, y0 + 1, y1 - 1, W2)
    L.hl(x0, x1, y1, W0); L.vl(x1, y0, y1, W0)
    L.r(x0 + 2, y0 + 2, x1 - x0 - 3, y1 - y0 - 3, '#e8dcc0')                     # el paspartú
    px0, px1, py0, py1 = x0 + 3, x1 - 3, y0 + 3, y1 - 3                           # la foto: 22 × 12
    L.r(px0, py0, px1 - px0 + 1, 3, '#d4dccb'); L.r(px0, py0 + 3, px1 - px0 + 1, 2, '#e4dcbc')   # el cielo, más cálido abajo
    for x in range(px0, px1 + 1):                                                 # los montes
        h = 1 + (x * 7 % 5 > 2) + (x % 9 < 3)
        L.vl(x, py0 + 5 - h, py0 + 5, '#8c9a7a')
    L.r(px0, py0 + 6, px1 - px0 + 1, py1 - py0 - 5, '#6e7c4c')                    # el campo
    for x in range(px0, px1 + 1):
        L.p(x, py0 + 6 + (x % 3 == 0), '#86a05a')
        if x % 4 == 1: L.p(x, py1 - 1, '#56643c')
    # la planta en flor, en medio
    cx = 24
    L.vl(cx, py0 + 3, py1, '#4e6a34')
    for j, w in enumerate((1, 3, 2, 3, 3, 2, 1)):                                # una mata con las hojas abiertas, no un pino
        L.hl(cx - w, cx + w, py0 + 3 + j, '#5e8a3e' if j % 2 else '#6e9a48')
    for x, y in ((cx - 3, py0 + 3), (cx + 3, py0 + 3), (cx - 4, py0 + 6), (cx + 4, py0 + 6)): L.p(x, y, '#7eaa52')   # las puntas de las hojas
    for x, y in ((cx, py0 + 2), (cx - 2, py0 + 4), (cx + 2, py0 + 4), (cx - 1, py0 + 7), (cx + 2, py0 + 7)): L.p(x, y, '#c8b878')   # las colas
    # la tía Maite, a la izquierda: la melena castaña, la cara, la blusa morada
    mx = 18
    L.r(mx - 2, py0 + 1, 5, 2, '#6a4430'); L.p(mx - 1, py0 + 1, '#8a5e40'); L.vl(mx - 2, py0 + 3, py0 + 5, '#4e3020'); L.vl(mx + 2, py0 + 3, py0 + 5, '#4e3020')
    L.r(mx - 1, py0 + 3, 3, 2, '#d49a74'); L.p(mx - 1, py0 + 3, '#3a2a2a'); L.p(mx + 1, py0 + 3, '#3a2a2a'); L.p(mx, py0 + 4, '#b87a5a')
    L.p(mx, py0 + 5, '#c08a66')
    L.r(mx - 2, py0 + 6, 5, py1 - py0 - 5, '#7a4a8a'); L.vl(mx - 2, py0 + 6, py1, '#9a6aaa'); L.hl(mx - 1, mx + 1, py0 + 6, '#9a6aaa')
    L.p(mx + 3, py0 + 7, '#d49a74')                                               # la mano, hacia la planta
    # Delroy, a la derecha y más alto: las rastas negras hasta el pecho, la cara, la camisa crema
    dx = 29
    L.r(dx - 2, py0, 5, 2, '#2a1e18'); L.p(dx - 1, py0, '#4a3a2e'); L.p(dx + 1, py0, '#4a3a2e')
    for x, l in ((dx - 3, 6), (dx - 2, 7), (dx + 2, 7), (dx + 3, 5)):
        for y in range(py0 + 1, py0 + 1 + l): L.p(x, y, '#4a3a2e' if (y + x) % 3 == 0 else '#2a1e18')
    L.r(dx - 1, py0 + 2, 3, 3, '#8a5a3c'); L.p(dx - 1, py0 + 3, '#1e1410'); L.p(dx + 1, py0 + 3, '#1e1410'); L.p(dx, py0 + 4, '#f0e8d8')
    L.r(dx - 1, py0 + 5, 3, 1, '#2a1e18')                                         # la barba, aún negra
    L.r(dx - 1, py0 + 6, 3, py1 - py0 - 5, '#e8e0c8'); L.vl(dx + 1, py0 + 6, py1, '#c4b898')
    L.p(dx - 2, py0 + 7, '#e8e0c8'); L.p(dx - 3, py0 + 8, '#8a5a3c')              # el brazo, por los hombros de ella (detrás)
    L.r(21, y1 - 1, 6, 2, '#c8a040'); L.hl(21, 26, y1 - 1, '#e8c860')              # la placa de latón
    L.contorno(K)
    return L

def tacos():
    """el taquero de la pared: la tabla con cuatro tacos de pie y el triángulo colgado"""
    L = Lienzo(16, 16)
    L.r(2, 11, 12, 2, '#74502e'); L.hl(2, 13, 11, '#a87646')
    for i, x in enumerate((3, 6, 9, 12)):
        L.vl(x, 0, 12, '#dcb27a'); L.p(x, 0, '#4a7ac8' if i % 2 else '#f4f4ee'); L.vl(x, 9, 12, '#3a2618')
    L.r(2, 3, 12, 2, '#5a3a24'); L.hl(2, 13, 3, '#74502e')
    L.contorno(K)
    return L

def mesita():
    """la mesa baja de los sofás (45 cm): el tablero a medias, el cenicero, el grinder y el librillo"""
    L = Lienzo(16, 16); W0, W1, W2 = '#4a2e1c', '#74502e', '#a87646'
    L.r(1, 8, 14, 4, W1); L.hl(1, 14, 8, W2); L.hl(1, 14, 11, W0)
    L.r(1, 12, 14, 1, W0); L.vl(2, 12, 15, W0); L.vl(13, 12, 15, W0)
    L.r(3, 8, 4, 2, '#8a8e96'); L.p(4, 8, '#3a3a40')               # el cenicero
    L.r(8, 7, 3, 3, '#3f8a46'); L.hl(8, 10, 7, '#84cc6c')           # el grinder
    L.r(12, 9, 2, 1, '#f4f4ee')                                     # el librillo
    L.contorno(K)
    return L

def barraD():
    """la barra de la discoteca: frente negro acolchado, la tira azul debajo del tablero y el tablero de cristal"""
    L = Lienzo(16, 16)
    L.r(0, 2, 16, 3, '#3a3448'); L.hl(0, 15, 2, '#6a6080')
    L.hl(0, 15, 5, NEON2)
    L.r(0, 6, 16, 10, '#1e1628')
    for y in range(7, 15, 3):
        for x in range((y // 3) % 2 * 2, 16, 4): L.p(x, y, '#2e2440')
    L.hl(0, 15, 15, '#0e0a14')
    L.contorno(K)
    return L

def neon():
    """el neón de la pared: la luna rosa y la estrella azul, sobre su soporte"""
    L = Lienzo(16, 16)
    cx, cy = 7, 7
    for y in range(16):
        for x in range(16):
            d1 = (x - cx) ** 2 + (y - cy) ** 2; d2 = (x - cx - 3) ** 2 + (y - cy + 2) ** 2
            if 16 <= d1 <= 26 and d2 > 14: L.p(x, y, NEON)
    L.p(12, 10, NEON2); L.p(11, 11, NEON2); L.p(13, 11, NEON2); L.p(12, 12, NEON2); L.p(12, 11, '#e0f8ff')
    return L

def mesaV():
    """la mesa del reservado: baja, de cristal negro, con la cubitera, la botella y dos copas"""
    L = Lienzo(16, 16)
    L.r(1, 9, 14, 3, '#2a2236'); L.hl(1, 14, 9, '#4a4060'); L.r(2, 12, 12, 1, '#141018'); L.vl(3, 12, 15, '#141018'); L.vl(12, 12, 15, '#141018')
    L.r(5, 5, 5, 5, CROMO); L.vl(5, 5, 9, '#f4f4ee'); L.hl(5, 9, 5, '#8a8e96')   # la cubitera
    L.r(7, 1, 2, 4, '#2e5a3a'); L.p(7, 1, '#e0b040'); L.p(8, 1, '#e0b040')       # la botella
    L.vl(12, 6, 8, '#e0f4f8'); L.p(12, 5, '#f0d070'); L.vl(2, 6, 8, '#e0f4f8'); L.p(2, 5, '#f0d070')   # las copas
    L.contorno(K)
    return L

def cordon(fin=False):
    """el cordón del reservado: el poste cromado y la cuerda de terciopelo, que cuelga hasta el poste de la casilla de al lado"""
    L = Lienzo(16, 16)
    L.vl(3, 5, 14, CROMO); L.vl(4, 5, 14, '#8a8e96'); L.r(2, 4, 3, 2, '#f4f4ee'); L.hl(1, 6, 15, '#8a8e96')
    if not fin:
        for x in range(5, 16):
            L.p(x, 6 + (2 if 7 <= x <= 13 else 1 if x in (6, 14) else 0), '#a02848')
    L.contorno(K)
    return L

# ---------------------------------------------------------------------------------------------------------- objetos altos (32 × 32)
def estanteN():
    """la estantería metálica de los abonos (100 × 180 cm): azules de MEATZA, verdes de ORTUA BIO, los sacos de sustrato abajo"""
    L = Lienzo(32, 32); M0, M1, M2 = '#4a525a', '#8c98a2', '#bcc6ce'
    x0, x1 = 8, 23
    for y in (3, 11, 19, 27): L.hl(x0, x1, y, M2); L.hl(x0, x1, y + 1, M1)
    for x in (x0, x1): L.vl(x, 2, 31, M0)
    for i, x in enumerate(range(x0 + 2, x1 - 1, 4)):                # garrafas de 1 L
        c = '#3a6ab8' if i < 2 else '#3f8a46'
        L.r(x, 6, 3, 5, c); L.p(x + 1, 5, '#2a2a34'); L.p(x, 7, '#e8e8e0')
        c = '#3a6ab8' if i % 2 else '#3f8a46'
        L.r(x, 14, 3, 5, c); L.p(x + 1, 13, '#2a2a34'); L.p(x, 15, '#e8e8e0')
    L.r(x0 + 1, 21, 6, 6, '#8a6a42'); L.hl(x0 + 1, x0 + 6, 21, '#a8865a'); L.r(x0 + 2, 23, 3, 2, '#3f8a46')   # los sacos
    L.r(x0 + 8, 22, 6, 5, '#8a6a42'); L.hl(x0 + 8, x0 + 13, 22, '#a8865a'); L.r(x0 + 9, 24, 3, 2, '#e0b040')
    L.contorno(K)
    return L

def secadero():
    """el secadero de red (60 cm, 4 pisos) colgado del techo, con los cogollos tendidos"""
    L = Lienzo(32, 32); R = azar(51); N, NL = '#3a3a40', '#6a6a72'
    L.vl(16, 0, 5, N)
    for i, y in enumerate((7, 13, 19, 25)):
        L.hl(10, 22, y, NL); L.hl(9, 23, y + 1, N); L.p(9, y, N); L.p(23, y, N)
        for x in range(11, 22, 3):
            if R() < .8: L.p(x, y - 1, G2); L.p(x + 1, y - 1, '#7a9a4a' if i > 1 else G3)
        L.vl(9, y + 1, y + 6 if i < 3 else y + 1, NL); L.vl(23, y + 1, y + 6 if i < 3 else y + 1, NL)
    L.contorno(K)
    return L

def altavoz():
    """el altavoz de la pista (60 × 160 cm): el cajón de graves y la caja de arriba, con sus conos"""
    L = Lienzo(32, 32); C0, C1, C2 = '#141018', '#24202c', '#4a4458'
    L.r(10, 18, 12, 13, C1); L.hl(10, 21, 18, C2)
    for (cx, cy, r) in ((16, 25, 4),):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if d <= r * r: L.p(x, y, C0 if d > (r - 1) ** 2 else C2 if d > 2 else '#8a50e0')
    L.r(11, 4, 10, 14, C1); L.hl(11, 20, 4, C2)
    for (cx, cy, r) in ((16, 12, 3), (16, 7, 1)):
        for y in range(cy - r, cy + r + 1):
            for x in range(cx - r, cx + r + 1):
                d = (x - cx) ** 2 + (y - cy) ** 2
                if d <= r * r: L.p(x, y, C0 if d > (r - 1) ** 2 and r > 1 else C2)
    L.p(19, 16, NEON2)
    L.contorno(K)
    return L

# ---------------------------------------------------------------------------------------------------------- muebles de 2 casillas
def billar():
    """la mesa de billar de 210 × 120 cm (34 px) con el tapete a medio fondo, las troneras y unas bolas; encima, la lámpara de
    tres pantallas verdes colgada de dos cadenas, encendida"""
    L = Lienzo(48, 48); W0, W1, W2, W3 = '#3a2416', '#5a3a24', '#7a5232', '#a07040'
    T0, T1, T2 = '#1e5a36', '#2a7a4a', '#3a9a5e'
    x0, x1 = 7, 40
    L.r(x0, 26, 34, 10, W1); L.hl(x0, x1, 26, W3)                   # las bandas
    L.r(x0 + 2, 28, 30, 6, T1); L.hl(x0 + 2, x1 - 2, 28, T2); L.hl(x0 + 2, x1 - 2, 33, T0)   # el tapete
    for (x, y) in ((x0 + 1, 27), (23, 27), (24, 27), (x1 - 1, 27), (x0 + 1, 34), (23, 34), (24, 34), (x1 - 1, 34)): L.p(x, y, '#141418')
    for (x, y, c) in ((13, 30, '#f4f4ee'), (28, 31, '#e0b040'), (30, 30, '#c04848'), (31, 32, '#4a7ac8'), (33, 31, '#141418')): L.p(x, y, c)
    L.r(x0, 36, 34, 4, W2); L.hl(x0, x1, 36, W3); L.hl(x0, x1, 39, W0)   # el faldón
    for x in (x0 + 2, x1 - 4): L.r(x, 40, 3, 6, W1); L.vl(x, 40, 45, W2); L.hl(x - 1, x + 3, 46, W0)   # las patas
    # la lámpara: dos cadenas y la barra con las tres pantallas, con la luz debajo
    L.vl(12, 0, 9, '#4a4a52'); L.vl(35, 0, 9, '#4a4a52')
    L.r(10, 10, 28, 2, W1); L.hl(10, 37, 10, W3)
    for cx in (14, 24, 33):
        L.r(cx - 3, 12, 7, 3, '#2e6a3a'); L.hl(cx - 3, cx + 3, 12, '#4a9a5a'); L.hl(cx - 2, cx + 2, 15, '#fff2b0')
    L.contorno(K)
    suelo(L, x0, x1, K)
    return L

CHESTER = ('#1e3a28', '#2e5a3a', '#3e7a4e', '#5a9a6a', '#10200f')
TERCIO = ('#3a1a4a', '#5a2a6a', '#7a3a8e', '#9a5ab0', '#1a0a22')
def sofaF(tap=CHESTER):
    """el sofá chester de 2 plazas (180 cm) de frente: el respaldo capitoné, los brazos enrollados, los dos cojines y las patas"""
    L = Lienzo(48, 48); S0, S1, S2, S3, SC = tap
    x0, x1 = 10, 38
    L.r(x0 + 2, 29, 25, 9, S1); L.hl(x0 + 2, x1 - 2, 29, S3)        # el respaldo
    for y in (31, 34):
        for x in range(x0 + 4 + (y == 34) * 2, x1 - 2, 4): L.p(x, y, S0)   # los botones
    L.r(x0 + 3, 38, 23, 4, S2); L.hl(x0 + 3, x1 - 3, 38, S3)        # los cojines del asiento
    L.vl(24, 38, 41, S0)
    L.r(x0 + 3, 42, 23, 3, S1); L.hl(x0 + 3, x1 - 3, 44, S0)
    for x in (x0, x1 - 3):                                          # los brazos enrollados
        L.r(x, 33, 4, 12, S1); L.hl(x, x + 3, 33, S3); L.hl(x, x + 3, 34, S2); L.vl(x, 34, 44, S2); L.vl(x + 3, 35, 44, S0)
    L.p(x0 + 1, 45, '#3a2a1c'); L.p(x0 + 2, 45, '#3a2a1c'); L.p(x1 - 2, 45, '#3a2a1c'); L.p(x1 - 1, 45, '#3a2a1c')
    L.contorno(SC)
    suelo(L, x0, x1, SC)
    return L

def cabina():
    """la cabina del DJ (200 cm): el frente negro con la tira de luz y el rótulo, y encima los dos platos, la mesa y el portátil"""
    L = Lienzo(48, 48); C0, C1, C2 = '#141018', '#24202c', '#4a4458'
    x0, x1 = 8, 39
    L.r(x0, 30, 32, 3, C2); L.hl(x0, x1, 30, '#6a6080')               # el tablero
    for cx in (14, 33):                                             # los platos
        L.r(cx - 3, 28, 7, 3, '#3a3448'); L.hl(cx - 2, cx + 2, 28, '#6a6080'); L.p(cx, 29, '#c8ccd0')
    L.r(21, 28, 6, 3, '#2a2236')
    for x in (22, 24, 26): L.p(x, 29, '#f0d040' if x == 24 else NEON2)
    L.r(19, 24, 9, 4, '#8a8e96'); L.r(20, 25, 7, 2, '#3a5a9a')        # el portátil
    L.r(x0, 33, 32, 13, C1); L.hl(x0, x1, 33, NEON); L.hl(x0, x1, 45, C0)
    for y in range(35, 45, 3):
        for x in range(x0 + 1 + (y // 3) % 2 * 2, x1, 4): L.p(x, y, '#2e2440')
    x = rotulo(L, 15, 37, 'GAUA', NEON)
    L.contorno(K)
    suelo(L, x0, x1, K)
    return L

def escritorio():
    """la mesa de oficina de la nave (140 cm): el portátil, los papeles, la calculadora, el flexo y las carpetas"""
    L = Lienzo(48, 48); M0, M1, M2 = '#5a5e66', '#8a8e96', '#c4c8d0'
    x0, x1 = 13, 34
    L.r(x0, 33, 22, 3, '#c8b088'); L.hl(x0, x1, 33, '#e0cca4')        # el tablero (melamina)
    L.r(x0, 36, 22, 2, '#8a7458')
    L.r(x0, 38, 2, 8, M1); L.r(x1 - 1, 38, 2, 8, M1)
    L.r(x1 - 8, 38, 7, 7, M1); L.hl(x1 - 8, x1 - 2, 41, M0)          # la cajonera
    L.r(17, 28, 9, 5, '#3a3a40'); L.r(18, 29, 7, 3, '#4a8a5a')        # el portátil, con la hoja de cálculo
    L.hl(16, 26, 33, '#2a2a34')
    L.r(27, 31, 4, 2, '#f4f4ee'); L.p(28, 31, '#8a8a92')              # los papeles
    L.r(x0 + 1, 31, 2, 2, M0)                                       # la calculadora
    L.vl(32, 26, 32, M0); L.r(31, 25, 3, 2, '#e0b040')               # el flexo
    L.contorno(K)
    suelo(L, x0, x1, K)
    return L

def foco_mesa(L, x0, on, M0, M1, M2):
    """un LED de barras como los de las carpas (equipo_c.py, como los de 720 W de 8 barras) a 16 px/m: 100 cm, 16 px; colgado de dos
    cuerdas con su trinquete, la fuente encima en el centro, el travesaño de delante y las 8 barras de fondo a fondo, de 1 px con 1 de
    aire, vistas algo desde abajo: la cara de diodos, blanca con algún rosa encendida y gris apagada, y entre barra y barra, oscuro
    (1.32: subido 2 px, para que quepan las plantas, más grandes)"""
    x1 = x0 + 15
    for x in (x0 + 1, x1 - 1):
        L.vl(x, 0, 3, '#3a3a40'); L.p(x, 1, M1)
    L.r(x0 + 6, 1, 4, 2, M0); L.p(x0 + 7, 1, M1)                                  # la fuente
    L.hl(x0, x1, 3, M2); L.p(x0, 3, M1); L.p(x1, 3, M1)                           # el travesaño
    for y in (4, 5, 6):
        for x in range(x0, x1 + 1):
            if (x - x0) % 2: L.p(x, y, '#2a2a30')                                  # el aire entre barras
            elif on: L.p(x, y, '#f8d8ff' if (x + 2 * y) % 3 == 0 else '#ffffff')
            else: L.p(x, y, '#6a6a72' if y < 6 else '#4a4a52')

# el equipo de la nave (1.33, lo pidió el usuario): los focos de las mesas, aparte de la mesa (focoN-<tipo>-<0|1>, apagados y
# encendidos), colgados con las asas en las columnas 1 y 14 de la fila FOCO_ASA (el juego cuelga ahí las cuerdas de las poleas y los
# sube y baja con las plantas: 11j-locales), y lo que se compra para toda la nave: los extractores de la pared (extrN, de 250 mm;
# extrG, de 315), los filtros de carbón colgados (filtroN), el controlador de riego (ctrlN), el tanque de 1.000 L con su bomba
# (tanqueN) y la máquina de fertirrigación (riegoN)
FOCO_ASA = 9
def focoN(t, on):
    """un foco de la mesa, de 100 cm (16 px) y con la parte de abajo en la fila 15: led, el LED de barras de las carpas (foco_mesa);
    sodio, la campana de alas de gaviota con la bombilla tubular, naranja encendida; lec, dos reflectores cuadrados en un travesaño,
    cada uno con su bombilla de cerámica, blanca y algo violeta encendida"""
    L = Lienzo(16, 16); M0, M1, M2 = '#4a525a', '#8c98a2', '#bcc6ce'
    if t == 'led':
        A = Lienzo(16, 16); foco_mesa(A, 0, on, M0, M1, M2); L.pega(A, 0, FOCO_ASA)
    elif t == 'sodio':
        for x in (1, 14): L.vl(x, FOCO_ASA, FOCO_ASA + 2, '#3a3a40')
        L.r(6, FOCO_ASA, 4, 2, '#5a5e68'); L.p(7, FOCO_ASA, M1)                    # el portalámparas
        L.hl(3, 12, FOCO_ASA + 2, M2); L.hl(1, 14, FOCO_ASA + 3, '#c8ccd6'); L.hl(2, 7, FOCO_ASA + 3, '#e8eaf0')   # la campana
        L.hl(0, 15, FOCO_ASA + 4, '#8a8e98')
        L.hl(4, 11, FOCO_ASA + 5, '#ffb040' if on else '#6a6a72'); L.hl(6, 9, FOCO_ASA + 5, '#ffe0a0' if on else '#7a7a82')   # la bombilla
        if on: L.hl(5, 10, FOCO_ASA + 6, '#ff9a30')
    else:
        for x in (1, 14): L.vl(x, FOCO_ASA, FOCO_ASA + 1, '#3a3a40')
        L.hl(1, 14, FOCO_ASA + 1, '#5a5e68')                                       # el travesaño
        for cx in (4, 11):
            L.hl(cx - 3, cx + 3, FOCO_ASA + 2, '#8a8e98'); L.r(cx - 3, FOCO_ASA + 3, 7, 2, '#d8dce4'); L.p(cx - 3, FOCO_ASA + 3, '#f0f2f6')
            L.hl(cx - 3, cx + 3, FOCO_ASA + 5, '#6a6e78')
            L.hl(cx - 1, cx + 1, FOCO_ASA + 6, '#f4f6ff' if on else '#6a6a72'); L.p(cx, FOCO_ASA + 6, '#d8d0ff' if on else '#7a7a82')
    L.contorno(K)
    return L

def extractor(grande):
    """el extractor en línea de la pared, de 250 mm (11 px) o de 315 (13): la carcasa redonda con la rejilla y el motor, las abrazaderas,
    el tubo de aluminio corrugado que sube y sale por la pared, y su cable"""
    L = Lienzo(16, 16); d = 13 if grande else 11; r = d / 2; cx, cy = 8, 15 - r
    for y in range(16):
        for x in range(16):
            e = ((x + .5 - cx) ** 2 + (y + .5 - cy) ** 2) ** .5
            if e <= r: L.p(x, y, '#3a3c44' if e > r - 1.2 else '#5a5e68' if e > r - 2.4 else '#2a2c32')
    for a in range(0, 360, 45):                                                   # las aspas, detrás de la rejilla
        x = int(cx + math.cos(math.radians(a)) * (r - 3)); y = int(cy + math.sin(math.radians(a)) * (r - 3)); L.p(x, y, '#8a8e96')
    L.p(int(cx), int(cy), '#bcc6ce')
    L.hl(int(cx - r) + 1, int(cx + r) - 1, int(cy - r) + 1, '#7a7e86')             # el brillo de arriba
    L.r(6, 0, 4, int(cy - r), '#b8bcc4')                                          # el tubo, hacia arriba
    for y in range(0, int(cy - r), 2): L.hl(6, 9, y, '#8a8e96')
    L.contorno(K)
    return L

def filtroN():
    """un filtro de carbón (Ø 25 cm, 60 cm de largo) colgado del techo por dos cintas: la brida de arriba con la boca para el tubo,
    la malla negra perforada y la tapa de abajo"""
    L = Lienzo(16, 16)
    for x in (5, 10): L.vl(x, 0, 2, '#3a3a40')                                     # las cintas
    L.r(4, 3, 8, 2, '#8a8e96'); L.hl(4, 11, 3, '#bcc6ce'); L.r(6, 1, 4, 2, '#b8bcc4')   # la brida y la boca
    L.r(4, 5, 8, 9, '#2a2c32'); L.vl(4, 5, 13, '#3a3c44')
    for y in range(6, 13, 2):
        for x in range(5 + (y // 2) % 2, 11, 2): L.p(x, y, '#4a4c56')               # la malla
    L.hl(4, 11, 14, '#8a8e96')
    L.contorno(K)
    return L

def ctrlN():
    """el controlador de riego de la pared: la caja blanca con la pantalla verde, los botones, el piloto y los cables de las
    electroválvulas bajando"""
    L = Lienzo(16, 16)
    L.r(3, 3, 10, 10, '#e8e8e0'); L.vl(12, 3, 12, '#bcb4a2'); L.hl(3, 12, 12, '#bcb4a2')
    L.r(4, 4, 7, 3, '#2a5a3a'); L.hl(5, 8, 5, '#7ae08a')                          # la pantalla
    for x in (4, 6, 8): L.p(x, 8, '#5a5e68')
    L.p(10, 8, '#e04040'); L.r(5, 10, 6, 1, '#c8c4b8')
    for x in (5, 8, 11): L.vl(x, 13, 15, '#1c1d22')                               # los cables
    L.contorno(K)
    return L

def tanqueN():
    """el tanque de 1.000 L (100 × 120 cm, un IBC): la jaula de tubo galvanizado, el depósito blanco translúcido con la solución
    nutritiva (verde) hasta tres cuartos, el palé negro, la llave de abajo y la bomba con la manguera arriba"""
    L = Lienzo(32, 32); M0, M1, M2 = '#5a5e66', '#8a8e96', '#c4c8d0'
    x0, x1, y0, y1 = 8, 23, 9, 28
    L.r(x0, y0, 16, y1 - y0, '#e4e8e6'); L.r(x0 + 1, y0 + 6, 14, y1 - y0 - 6, '#8aa86a'); L.hl(x0 + 1, x1 - 1, y0 + 6, '#a8c488')   # el depósito y la solución
    L.vl(x0 + 2, y0 + 1, y1 - 1, '#f4f8f6')
    for x in (x0, x0 + 5, x0 + 10, x1): L.vl(x, y0, y1 - 1, M1)                    # la jaula
    for y in (y0, y0 + 6, y0 + 12, y1 - 1): L.hl(x0, x1, y, M1)
    L.hl(x0, x1, y0, M2)
    L.r(x0, y1, 16, 3, '#2a2a30'); L.hl(x0, x1, y1, '#4a4a52')                    # el palé
    L.r(x1 - 4, y1 - 3, 3, 2, '#3a3c44'); L.p(x1 - 3, y1 - 3, '#e0b040')            # la llave
    L.r(x0 + 4, y0 - 3, 5, 3, '#3a6ab8'); L.hl(x0 + 4, x0 + 8, y0 - 3, '#5a8ad8')     # la bomba
    L.hl(x0 + 9, x1 + 4, y0 - 2, '#1c1d22'); L.vl(x1 + 4, y0 - 2, y0 + 4, '#1c1d22')  # la manguera, hacia las mesas
    L.contorno(K)
    return L

def riegoN():
    """la máquina de fertirrigación: el armario gris con la pantalla, las tres bombas dosificadoras (A, B y pH) con sus botes encima
    y los tubos finos hacia el tanque"""
    L = Lienzo(32, 32); M0, M1, M2 = '#4a525a', '#8c98a2', '#bcc6ce'
    x0, x1, y0, y1 = 9, 22, 13, 30
    L.r(x0, y0, 14, y1 - y0 + 1, M1); L.hl(x0, x1, y0, M2); L.vl(x1, y0, y1, M0)
    L.r(x0 + 2, y0 + 2, 8, 4, '#2a3a5a'); L.hl(x0 + 3, x0 + 8, y0 + 3, '#6ac8f0'); L.hl(x0 + 3, x0 + 6, y0 + 4, '#7ae08a')   # la pantalla
    for i, c in enumerate(('#3a6ab8', '#c8a040', '#c04848')):                    # las dosificadoras y sus botes
        x = x0 + 1 + i * 4
        L.r(x, y0 + 8, 3, 3, '#3a3c44'); L.p(x + 1, y0 + 9, '#bcc6ce')
        L.r(x, y0 - 5, 3, 5, c); L.p(x + 1, y0 - 6, '#2a2a34'); L.p(x, y0 - 4, '#e8e8e0')
    L.hl(x0 + 1, x1 - 1, y1 - 2, M0)
    L.vl(x0 - 1, y0 + 9, y1, '#1c1d22')                                           # el tubo, hacia el tanque
    L.contorno(K)
    return L

# la mesa (1.32): las cinco macetas a tresbolillo, tres en la fila de delante (la de los trabajadores) y dos en la del fondo, en
# los huecos; x del centro y fila del culo de cada una, del fondo a delante (así se pintan sus plantas: las de delante tapan)
MACETAS_MESA = [(17, 30), (30, 30), (11, 35), (24, 35), (36, 35)]
BANDEJA = ('#ffffff', '#e8e8ec', '#c8ccd2', '#a8acb4')

def maceta_mesa(L, cx, yb):
    """una maceta cuadrada negra de 7 × 7 (unos 11 L) vista algo desde arriba: el borde (el de delante, con luz), la tierra y el
    cuerpo, un poco más estrecho abajo, con la luz a la izquierda"""
    x0 = cx - 3
    L.r(x0, yb - 6, 7, 3, '#4a4a52'); L.r(x0 + 1, yb - 5, 5, 1, '#5a4030')        # el borde y la tierra
    L.hl(x0, x0 + 6, yb - 3, '#6a6a72')                                           # el labio de delante
    L.r(x0, yb - 2, 7, 2, '#2a2a30'); L.r(x0 + 1, yb, 5, 1, '#2a2a30'); L.vl(x0, yb - 2, yb - 1, '#4a4a52')   # el cuerpo

def mesaN(fase):
    """la mesa de cultivo de 240 × 120 cm (38 px) vista desde arriba a medio fondo, como el billar (1.32): la bandeja blanca con su
    fondo acanalado hacia el desagüe, el canto de delante, el larguero y las tres patas, con el suelo entre ellas, y las cinco
    macetas a tresbolillo (MACETAS_MESA); los focos y las plantas van aparte (1.33: focoN; plantasN), encima; fase: 0 vacía y 1
    plantada (iguales desde la 1.33, que los focos van aparte)"""
    L = Lienzo(48, 48); M0, M1, M2 = '#4a525a', '#8c98a2', '#bcc6ce'; B0, B1, B2, B3 = BANDEJA
    x0, x1 = 5, 42
    L.hl(x0, x1, 25, B0); L.hl(x0 + 1, x1 - 1, 26, B3)                            # el borde del fondo
    L.r(x0 + 1, 27, 36, 9, B2)                                                    # el fondo de la bandeja
    for x in range(x0 + 3, x1 - 1, 4): L.vl(x, 27, 35, B3)                         # las acanaladuras, hacia el desagüe
    L.vl(x0, 25, 37, B0); L.vl(x1, 25, 37, B1)                                    # los bordes de los lados
    L.hl(x0, x1, 36, B0); L.hl(x0, x1, 37, B1); L.hl(x0, x1, 38, B3)               # el canto de delante
    L.r(x1 - 5, 37, 2, 2, '#4a4a52')                                              # el desagüe
    L.hl(x0 + 1, x1 - 1, 39, M1); L.hl(x0 + 1, x1 - 1, 40, M0)                     # el larguero
    for x in (x0 + 1, 23, x1 - 2): L.r(x, 41, 2, 5, M1); L.vl(x, 41, 45, M2)        # las patas
    for cx, yb in MACETAS_MESA: maceta_mesa(L, cx, yb)
    L.contorno(K)
    suelo(L, x0, x1, K)
    return L

# las plantas de la mesa (1.31; 1.32, más grandes y con copa: vistas desde arriba como la mesa, con la corona y las puntas, no en
# forma de pino), en los colores de la planta A (exporta.py: hojas D M L H, tallo S, contorno O, cogollo en la rampa clave P Q R,
# pelos N y tricomas F) para que el juego les ponga, como en la vista C, el tono de hoja y el color de cogollo de la variedad
# (vcTonos y la rampa de carpa-c-plantas-a). Cinco por mesa, una en cada maceta (MACETAS_MESA), cada una con su contorno, y las de
# delante encima de las del fondo. El porte, por el % índica (porteInd): i, ancha y baja, de hoja ancha y oscura y cogollos gordos;
# s, alta y estrecha, de hoja fina y clara, con las colas largas y finas; h, entre las dos. fase: 1 recién plantadas (los clones,
# iguales en los tres portes), 2 creciendo (la copa, con los brotes claros en las puntas), 3 en flor (las colas, pequeñas y con
# los pelos blancos) y 4 dando cogollos (las colas, gordas, con los pelos naranjas)
PO, PD, PM, PL, PH, PS = '#0d2620', '#1b4630', '#2f7038', '#57a33e', '#94d255', '#3b5a2e'
PP, PQ, PR, PN, PF = '#ff5cff', '#d020c8', '#80107a', '#f08a3c', '#f2f4dc'
COPA = {   # la copa por fase (semiejes), las colas (dx, dy desde lo alto de la copa; las del fondo, primero), la cola (ancho, alto)
           # y los tonos de las hojas (oscuro, medio, claro) y de su punta
    'i': dict(rx={2: 4.6, 3: 6.6, 4: 6.6}, ry={2: 3, 3: 4, 4: 4}, colas=[(-4, 1), (4, 1), (0, 0), (2, 3), (-2, 3)], cola=(3, 5),
              tonos=(PD, PM, PL, PL)),
    'h': dict(rx={2: 4, 3: 5.6, 4: 5.6}, ry={2: 3.6, 3: 5, 4: 5}, colas=[(-3, 1), (3, 1), (0, -1), (-2, 4), (2, 4)], cola=(3, 6),
              tonos=(PD, PM, PL, PH)),
    's': dict(rx={2: 3.2, 3: 4.5, 4: 4.5}, ry={2: 4, 3: 6, 4: 6}, colas=[(-3, 2), (3, 2), (0, -1), (-1, 5), (2, 5)], cola=(2, 8),
              tonos=(PM, PL, PL, PH)),
}
HOJA = {   # la hoja de abanico hacia arriba (T, la punta de los dedos; c, la hoja; +, el rabillo, donde se pega)
    'i': ('T.T.T', 'TcccT', '.c+c.'),
    'h': ('..T..', 'T.c.T', '.ccc.', '..+..'),
    's': ('..T..', '..c..', 'T.c.T', '.ccc.', '..+..'),
}

def hoja_mesa(L, x, y, porte, lado, c, cp):
    """una hoja de abanico de su porte pegada en (x, y) y vuelta hacia lado: 0 arriba, 1 a la derecha, −1 a la izquierda"""
    H = HOJA[porte]; h = len(H); ay = h - 1; ax = H[ay].index('+')
    for j, fila in enumerate(H):
        for i, ch in enumerate(fila):
            if ch == '.': continue
            dx, dy = i - ax, j - ay
            if lado: dx, dy = -dy * lado, dx                                       # girada a un lado
            L.p(x + dx, y + dy, cp if ch == 'T' else c)

def cola_mesa(L, x, y, w, h, fase):
    """una cola de w × h con la punta arriba en (x + w // 2, y): en flor (3), pequeña y con un pelo blanco en la punta; dando (4),
    gorda, con la luz a la izquierda (P), el cuerpo (Q), la sombra a la derecha y abajo (R), los pelos naranjas y un tricoma"""
    if fase == 3:
        w, h = max(1, w - 1), max(2, h - 2); y += 2
    for j in range(h):
        for i in range(w):
            if j == 0 and w > 1 and i != w // 2: continue                                  # la punta
            c = PQ
            if fase == 4 and w > 1:
                if i == 0: c = PP
                elif i == w - 1 or j == h - 1: c = PR
            L.p(x + i, y + j, c)
    t = x + w // 2
    if fase == 3:
        L.p(t, y - 1, PF); return
    L.p(t, y - 1, PN)
    for j in range(1, h - 1, 2): L.p(x + (j // 2) % 2 * (w - 1), y + j, PN)       # los pelos, a un lado y a otro
    if w > 2: L.p(x + 1, y + h - 2, PF)

def planta_mesa(cx, yb, fase, porte, R):
    """una planta en la maceta de centro cx y culo en la fila yb, en su propio lienzo con su contorno: la copa (oscura abajo y
    clara arriba), las hojas de abanico de los lados y de abajo, caídas por encima del borde de la maceta, y la corona: creciendo,
    las puntas con los brotes claros; en flor, las colas"""
    L = Lienzo(48, 48); t = yb - 5                                                # la fila de la tierra
    D, M, Cl, T = COPA[porte]['tonos']
    if fase == 1:   # el clon recién plantado: el tallo y dos pares de hojitas
        L.p(cx, t, PS); L.p(cx, t - 1, PS); L.p(cx - 1, t - 1, M); L.p(cx + 1, t - 1, M); L.p(cx - 2, t - 2, Cl); L.p(cx + 2, t - 2, Cl)
        L.p(cx, t - 2, M); L.p(cx - 1, t - 3, Cl); L.p(cx + 1, t - 3, Cl); L.p(cx, t - 3, PH)
        L.contorno(PO); return L
    C = COPA[porte]; rx, ry = C['rx'][fase], C['ry'][fase]; cy = t - ry
    for y in range(int(cy - ry) - 1, t + 1):                                      # la copa
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            u, v = (x - cx) / rx, (y - cy) / ry
            if u * u + v * v > 1.05: continue
            k = v * .85 + u * .3
            L.p(x, y, D if k > .4 else Cl if k < -.45 else M)
    for s in (-1, 1):                                                             # las hojas de los lados y las de abajo, caídas
        hoja_mesa(L, cx + s * round(rx), round(cy), porte, s, M, Cl)
        hoja_mesa(L, cx + s * round(rx * .6), t, porte, s, D, M)
    top = round(cy - ry)
    if fase == 2:   # las puntas: hojas hacia arriba con los brotes claros
        for dx in (-round(rx * .55), 0, round(rx * .55)):
            hoja_mesa(L, cx + dx, top + (1 if dx else 0), porte, 0, Cl, T)
        L.contorno(PO); return L
    for dx in (-round(rx * .7), round(rx * .7)):                                  # las hojas de arriba, entre las colas
        hoja_mesa(L, cx + dx, top + 2, porte, 0, M, Cl)
    w, h = C['cola']
    for dx, dy in C['colas']:
        cola_mesa(L, cx + dx - w // 2, top + dy - h + 2, w, h, fase)
    L.contorno(PO)
    return L

def plantasN(fase, porte):
    """las cinco plantas de una mesa, del fondo a delante"""
    L = Lienzo(48, 48); R = azar(31 + fase * 7 + 'ihs'.index(porte))
    for cx, yb in MACETAS_MESA:
        L.pega(planta_mesa(cx, yb, fase, porte, R), 0, 0)
    return L

# ---------------------------------------------------------------------------------------------------------- salida
for n, f in FACHADAS.items():
    base, ps = f()
    sale('base', base, 'edificio-' + n)
    for i, p in enumerate(ps): sale(f'puerta{i:02d}', p, 'edificio-' + n)
for n, f in (('floorC', floorC), ('iwT_club', iwT_club), ('iwB_club', iwB_club), ('floorN', floorN), ('iwT_nave', iwT_nave),
             ('iwB_nave', iwB_nave), ('floorD', floorD), ('iwT_disco', iwT_disco), ('iwB_disco', iwB_disco)):
    sale(n, f(), 'interior-locales')
sale('baile', baile(), 'interior-baile')
for n, f in (('vitrina', vitrina), ('tarros', tarros), ('pizarra', pizarra), ('cartelC', cartelC), ('tacos', tacos), ('mesita', mesita),
             ('barraD', barraD), ('neon', neon), ('mesaV', mesaV), ('cordon', cordon), ('cordonF', lambda: cordon(True)),
             ('extrN', lambda: extractor(False)), ('extrG', lambda: extractor(True)), ('filtroN', filtroN), ('ctrlN', ctrlN)):
    sale(n, f(), 'locales-16')
for t in ('led', 'sodio', 'lec'):
    for on in (0, 1): sale(f'focoN-{t}-{on}', focoN(t, on), 'locales-16')
for n, f in (('estanteN', estanteN), ('secadero', secadero), ('altavoz', altavoz), ('tanqueN', tanqueN), ('riegoN', riegoN)):
    sale(n, f(), 'locales-alto')
for n, f in (('billar', billar), ('sofaF', sofaF), ('sofaV', lambda: sofaF(TERCIO)), ('sofaB', lambda: sofa_atras(CHESTER)),
             ('cabina', cabina), ('escritorio', escritorio), ('fotoMaite', fotoMaite)):
    sale(n, f(), 'locales-ancho')
for i in range(2): sale(f'mesaN-{i}', mesaN(i), 'locales-ancho')
sale('plantasN-1', plantasN(1, 'h'), 'locales-ancho')
for f in (2, 3, 4):
    for p in 'ihs': sale(f'plantasN-{f}-{p}', plantasN(f, p), 'locales-ancho')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            if n.startswith('puerta'):
                d = os.path.join(raiz, g, 'puerta') if raiz else P('art', 'crudo', g, 'puerta', 'unica'); f = n[6:] + '.png'
            else:
                d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); f = '00.png'
            os.makedirs(d, exist_ok=True)
            if f == '00.png':
                for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, f))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
