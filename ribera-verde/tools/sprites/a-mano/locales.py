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
#    la mesa de cultivo de 240 × 120 cm con su barra de LED en las cinco fases (vacía, plántulas, vegetativo, flor y cogollos).
# Sale a art/crudo/<grupo>/<sprite>/unica/NN.png (después, node tools/sprites/procesar.js <grupos> --atlas)
import os, sys, glob
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
def rotulo(lz, x, y, txt, c):
    for ch in txt:
        if ch == ' ':
            x += 2; continue
        m = LETRA[ch]; an = len(m) // 5
        for j in range(5):
            for i in range(an):
                if m[j * an + i] == '1': lz.p(x + i, y + j, c)
        x += an + 1
    return x

def ancho(txt):
    return sum(2 if ch == ' ' else len(LETRA[ch]) // 5 + 1 for ch in txt) - 1

def placa(lz, x, y, txt, fondo, borde, letra):
    w = ancho(txt) + 4
    lz.caja(x, y, w, 9, fondo, borde)
    rotulo(lz, x + 2, y + 2, txt, letra)

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

FACHADAS = {'club-itsaso': club_itsaso, 'club-fundicion': club_fundicion, 'club-kalea': club_kalea, 'club-ensanche': club_ensanche, 'disco': disco}

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

def mesaN(fase):
    """la mesa de cultivo de 240 × 120 cm (38 px), de bandeja con desagüe, con seis macetas y la barra de LED colgada encima;
    fase: 0 vacía, 1 plántulas, 2 vegetativo, 3 flor y 4 cogollos"""
    L = Lienzo(48, 48); R = azar(17 + fase); M0, M1, M2 = '#4a525a', '#8c98a2', '#bcc6ce'
    x0, x1 = 5, 42
    # la barra de LED, de dos cables
    L.vl(8, 0, 4, '#3a3a40'); L.vl(39, 0, 4, '#3a3a40')
    L.r(6, 5, 36, 2, '#3a3a40'); L.hl(7, 40, 6, '#fff0f8' if fase else '#6a6a72')
    L.r(x0, 35, 38, 3, '#e8e8ec'); L.hl(x0, x1, 35, '#ffffff'); L.hl(x0, x1, 37, '#a8acb4')   # la bandeja blanca
    L.r(x0 + 1, 38, 36, 2, M1)                                      # el bastidor
    for x in (x0 + 1, x0 + 18, x1 - 2): L.r(x, 40, 2, 6, M1); L.vl(x, 40, 45, M2)
    for i in range(6):                                              # las macetas negras, de 6 px
        cx = x0 + 4 + i * 6
        L.r(cx - 2, 30, 5, 5, '#2a2a30'); L.hl(cx - 2, cx + 2, 30, '#4a4a52'); L.hl(cx - 1, cx + 1, 31, '#5a4030')
        if fase == 0: continue
        if fase == 1:
            L.p(cx, 29, G3); L.p(cx - 1, 28, G3); L.p(cx + 1, 28, G2)
            continue
        alto = {2: 8, 3: 15, 4: 18}[fase]
        for j in range(alto):                                       # el tallo con sus pisos de hojas
            y = 29 - j; w = max(1, (alto - j) // 3 if fase == 2 else 2 + (alto - j) // 5)
            L.p(cx, y, G1)
            if j % 3 == 1:
                L.hl(cx - w, cx + w, y, G2); L.p(cx - w, y - 1, G3); L.p(cx + w, y - 1, G2)
        if fase >= 3:                                               # las flores en la punta y en las ramas
            for (dx, dy) in ((0, -alto + 1), (-2, -alto + 5), (2, -alto + 6), (-2, -alto + 10), (2, -alto + 11)):
                x, y = cx + dx, 29 + dy
                c = '#c8e8a8' if fase == 3 else '#a8d080'
                L.r(x, y, 2 if fase == 4 else 1, 3 if fase == 4 else 2, c)
                L.p(x, y, '#f4f4ee' if fase == 3 else PIS)
                if fase == 4: L.p(x + 1, y + 1, '#e8ffe0')
    L.contorno(K)
    suelo(L, x0, x1, K)
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
             ('barraD', barraD), ('neon', neon), ('mesaV', mesaV), ('cordon', cordon), ('cordonF', lambda: cordon(True))):
    sale(n, f(), 'locales-16')
for n, f in (('estanteN', estanteN), ('secadero', secadero), ('altavoz', altavoz)):
    sale(n, f(), 'locales-alto')
for n, f in (('billar', billar), ('sofaF', sofaF), ('sofaV', lambda: sofaF(TERCIO)), ('sofaB', lambda: sofa_atras(CHESTER)),
             ('cabina', cabina), ('escritorio', escritorio)):
    sale(n, f(), 'locales-ancho')
for i in range(5): sale(f'mesaN-{i}', mesaN(i), 'locales-ancho')

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
