# python3 -I tools/sprites/a-mano/interiores_bilbao.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# (lo pidió el usuario: «el teatro, pues igual molaría hacer un mapa en el que se vea el teatro. También nos tendríamos que currar unos
# cuantos sprites para poder hacer el visual del teatro… a la iglesia también»): el teatro, las iglesias y el mercado de la Ribera por
# dentro (tools/bilbao.py, BILBAO.IN), a 16 px/m y de frente a 3/4 como los muebles de los locales (nunca isométrico). Genérico y
# propio: sin rótulos, escudos, marcas ni obras reales (los carteles, de colores y formas; el decorado, un paisaje cualquiera).
#  · interior-bilbao (casillas de 16 × 16): el teatro (floorTeat, la moqueta granate; tablado, las tablas del escenario; escalonT;
#    iwT_teat e iwB_teat, el damasco con la moldura dorada y el zócalo de madera; iwB_teatP, la columna del proscenio; iwB_teatF, la
#    boca del escenario con las candilejas), la iglesia (floorIg, las losas; presbI, el mármol del presbiterio; escalonI; alfombraI,
#    la alfombra del pasillo; iwT_ig, la sillería con la vidriera; iwB_ig, la sillería) y el mercado (floorMe, el terrazo; iwT_me, los
#    ventanales; iwB_me, el azulejo con la cenefa)
#  · interior-bilbao-alto (mueble_escala, 32 × 48, base en (16, 47)): butaca, telonI/telonD, cartelT/cartelT2, plantaT, cirioI,
#    bancoI, columnaI, velasI, cepilloI, pilaI, taburMe y cajasMe
#  · interior-bilbao-ancho (mueble_ancho, 48 × 48, base en (16, 47); la casilla de la derecha, k + '2', no se pinta): decoT, palcoT,
#    taquillaT, retabloI, retabloB, cruzZ, altarI, confesI y los puestos del mercado (puestoFr, Pe, Ca, Qu, Ve, Pa, Fl, Es) y barraMe;
#    y después de la revisión, el panel de salidas de las estaciones (panelE), la rueda del molino de mareas (ruedaM) y, de las altas,
#    la máquina de billetes (maquinaE)
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js interior-bilbao interior-bilbao-alto
# interior-bilbao-ancho --atlas --atlas-dir godot/arte)
import os, sys, glob, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar
from salon import suelo

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#2a2a34'
GR = ('#3e0e16', '#5e1620', '#7e2230', '#a03a44')      # el granate del teatro
OR = ('#8a6418', '#c49a30', '#e8c860', '#fff0a8')      # el dorado
MA = ('#4a2e1a', '#6a4426', '#8a5c34', '#ae7c4c')      # la madera oscura
TA = ('#7a5430', '#9a6c3c', '#b8884e', '#d4a468')      # las tablas
PI = ('#6e6a62', '#8e8a80', '#aeaaa0', '#cac6bc')      # la piedra
BL = ('#c8ccd0', '#e4e6e8', '#f6f6f2')
VI = ('#2a4a9a', '#c03a3a', '#e8b83a', '#3a9a5a', '#7a3a9a')   # la vidriera


# ------------------------------------------------------------------------------------------------------------------ casillas
def floorTeat():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, GR[1])
    for y in range(16):                                  # el dibujo de la moqueta: rombos pequeños
        for x in range(16):
            if (x + y) % 8 == 0 or (x - y) % 8 == 0:
                L.p(x, y, GR[2])
    for x, y in ((4, 4), (12, 12), (12, 4), (4, 12)):
        L.p(x, y, OR[0])
    return L

def tablado():
    L = Lienzo(16, 16)
    for j, y in enumerate(range(0, 16, 4)):
        L.r(0, y, 16, 4, TA[1] if j % 2 else TA[2])
        L.hl(0, 15, y + 3, TA[0])
        xs = 5 + j * 6 % 16
        L.vl(xs, y, y + 2, TA[0])                        # las juntas de las tablas, a matajuntas
        L.p((xs + 7) % 16, y + 1, TA[3])
    return L

def escalonT():
    L = tablado()
    L.r(0, 8, 16, 8, TA[0]); L.hl(0, 15, 8, TA[3]); L.hl(0, 15, 12, TA[2]); L.hl(0, 15, 15, MA[0])
    return L

def iwT_teat():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, GR[1])
    L.r(0, 0, 16, 3, OR[0]); L.hl(0, 15, 1, OR[1]); L.hl(0, 15, 3, OR[2])   # la moldura dorada del techo
    for cx, cy in ((4, 9), (12, 9)):                     # el damasco: flores de lis sin escudo, un dibujo repetido
        L.vl(cx, cy - 3, cy + 3, GR[2]); L.hl(cx - 2, cx + 2, cy, GR[2]); L.p(cx - 1, cy - 2, GR[2]); L.p(cx + 1, cy - 2, GR[2])
        L.p(cx, cy - 4, GR[3])
    return L

def iwB_teat():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 8, GR[1])
    L.p(4, 2, GR[2]); L.p(12, 2, GR[2]); L.hl(3, 5, 3, GR[2]); L.hl(11, 13, 3, GR[2])
    L.hl(0, 15, 7, OR[1]); L.hl(0, 15, 8, OR[0])          # el listón dorado
    L.r(0, 9, 16, 7, MA[1])                               # el zócalo de madera, en paneles
    L.caja(1, 10, 6, 5, MA[2], MA[0]); L.caja(9, 10, 6, 5, MA[2], MA[0])
    L.hl(0, 15, 15, MA[0])
    return L

def iwB_teatP():
    """la columna del proscenio: dorada, con la caña estriada sobre el granate"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, GR[0])
    L.r(3, 0, 10, 16, OR[1])
    for x in (5, 8, 11): L.vl(x, 0, 15, OR[0])
    L.vl(4, 0, 15, OR[2]); L.vl(12, 0, 15, OR[0])
    return L

def iwB_teatF():
    """la boca del escenario: el canto de las tablas arriba, el faldón de madera y las candilejas encendidas"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 4, TA[2]); L.hl(0, 15, 0, TA[3]); L.hl(0, 15, 3, TA[0])
    L.r(0, 4, 16, 12, MA[1]); L.hl(0, 15, 15, MA[0])
    for x in (2, 10):                                    # la candileja: la tapa y la luz cálida
        L.r(x, 4, 4, 2, K); L.r(x + 1, 6, 2, 1, OR[3]); L.p(x, 6, OR[2]); L.p(x + 3, 6, OR[2])
    L.caja(1, 9, 6, 5, MA[2], MA[0]); L.caja(9, 9, 6, 5, MA[2], MA[0])
    return L

def floorIg():
    L = Lienzo(16, 16); R = azar(8101)
    L.r(0, 0, 16, 16, PI[2])
    for _ in range(18): L.p(int(R() * 16), int(R() * 16), PI[1] if R() < .5 else PI[3])
    L.hl(0, 15, 7, PI[1]); L.hl(0, 15, 15, PI[1]); L.vl(7, 0, 7, PI[1]); L.vl(15, 8, 15, PI[1])   # las losas grandes, a matajuntas
    return L

def presbI():
    L = Lienzo(16, 16)
    for y in range(16):
        for x in range(16):
            L.p(x, y, '#ece6da' if ((x // 8) + (y // 8)) % 2 else '#b0a690')   # el mármol a cuadros blanco y ocre
    L.p(3, 2, '#d6cebc'); L.p(11, 10, '#d6cebc')
    return L

def escalonI():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, PI[3]); L.hl(0, 15, 0, BL[2]); L.hl(0, 15, 7, PI[1]); L.r(0, 8, 16, 8, PI[2]); L.hl(0, 15, 15, PI[0])
    return L

def alfombraI():
    L = floorIg()
    L.r(1, 0, 14, 16, '#9a1e26'); L.vl(1, 0, 15, OR[1]); L.vl(14, 0, 15, OR[1]); L.vl(2, 0, 15, '#6e1218'); L.vl(13, 0, 15, '#6e1218')
    for y in (3, 11): L.p(7, y, OR[2]); L.p(8, y, OR[2])
    return L

def iwT_ig():
    """la sillería con la vidriera ojival: cristales de colores emplomados, sin figuras"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, PI[2])
    L.hl(0, 15, 5, PI[1]); L.hl(0, 15, 11, PI[1]); L.vl(4, 0, 5, PI[1]); L.vl(12, 6, 11, PI[1])
    for y in range(2, 16):
        hw = 3 if y > 5 else y - 2
        for x in range(8 - hw, 8 + hw):
            L.p(x, y, VI[(x // 2 + y // 3) % 5] if (x + y) % 4 else K)
    L.vl(7, 4, 15, K)
    return L

def iwB_ig():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, PI[2])
    L.r(5, 0, 6, 9, VI[0]); L.vl(7, 0, 8, K); L.hl(5, 10, 4, K)
    for x in range(5, 11): L.p(x, 1, VI[(x + 1) % 5])
    L.hl(4, 11, 9, PI[0])
    L.hl(0, 15, 10, PI[1]); L.r(0, 12, 16, 4, PI[1]); L.hl(0, 15, 12, PI[3]); L.hl(0, 15, 15, PI[0])   # el zócalo
    return L

def floorMe():
    L = Lienzo(16, 16); R = azar(8131)
    L.r(0, 0, 16, 16, '#d8d2c4')
    for _ in range(40): L.p(int(R() * 16), int(R() * 16), ('#a89e8a', '#efe9dc', '#8a8274', '#c4b8a0')[int(R() * 4)])   # el terrazo
    L.hl(0, 15, 15, '#b8b0a0'); L.vl(15, 0, 15, '#b8b0a0')
    return L

def iwT_me():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#e8e4da')
    L.r(2, 3, 12, 13, '#3a5a7a'); L.r(3, 4, 10, 12, '#8ab8d8'); L.vl(7, 4, 15, '#3a5a7a'); L.vl(8, 4, 15, '#3a5a7a'); L.hl(3, 12, 9, '#3a5a7a')
    L.p(4, 5, '#d0ecff'); L.p(5, 5, '#d0ecff')
    return L

def iwB_me():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, BL[2])
    for y in range(0, 16, 4): L.hl(0, 15, y, BL[0])
    for y in range(0, 16, 4):
        for x in range(0 if (y // 4) % 2 else 2, 16, 4): L.vl(x, y, y + 3, BL[0])
    L.r(0, 6, 16, 2, '#2e7a4a'); L.hl(0, 15, 6, '#4a9a62')   # la cenefa verde
    L.hl(0, 15, 15, '#8a8a84')
    return L


# --------------------------------------------------------------------------------------------------------------- el teatro
def butaca():
    """la butaca de terciopelo (90 cm de respaldo: 15 px), de espaldas: el respaldo granate con el ribete, los brazos de madera"""
    L = Lienzo(32, 48)
    L.r(9, 33, 14, 12, GR[2]); L.hl(9, 22, 33, GR[3]); L.vl(9, 33, 44, GR[3]); L.vl(22, 33, 44, GR[1])
    L.r(10, 34, 12, 1, GR[3])
    L.r(8, 40, 2, 6, MA[2]); L.r(22, 40, 2, 6, MA[1])           # los brazos
    L.r(10, 45, 12, 2, GR[0])
    L.p(15, 38, GR[1]); L.p(16, 38, GR[1])                     # el capitoné
    L.contorno(K); suelo(L, 8, 23, K)
    return L

def telon(d):
    """el telón recogido a un lado (3 m: 48 px de alto, de la vara a las tablas): pliegues verticales de terciopelo y el
    alzapaño dorado; d = 'I' o 'D'"""
    L = Lienzo(32, 48)
    for x in range(8, 24):
        k = (x - 8) % 4
        c = (GR[1], GR[2], GR[3], GR[2])[k]
        L.vl(x, 0, 47, c)
    for y in range(28, 34):                                     # recogido por el alzapaño: se estrecha
        for x in range(8, 24):
            if abs(x - 15.5) > 8 - abs(y - 31) * 1.5 + 4:
                L.p(x, y, None)
    L.r(9, 30, 14, 2, OR[1]); L.hl(9, 22, 30, OR[2]); L.p(21 if d == 'I' else 10, 32, OR[1]); L.p(21 if d == 'I' else 10, 33, OR[2])
    L.r(8, 0, 16, 2, OR[0])                                    # la galería de arriba
    L.contorno(K)
    if d == 'D':
        L.espejo()
    return L

def cartel(k):
    """un cartel de función en su caballete (sin títulos reales: manchas de color y rayas de letra)"""
    L = Lienzo(32, 48)
    L.vl(10, 30, 46, MA[1]); L.vl(21, 30, 46, MA[1]); L.vl(16, 34, 46, MA[0])
    fondo, tinta, fig = (('#e8d8a8', '#3a2a5a', '#c03a3a'), ('#2a3a5a', '#f0e0b0', '#e8b83a'))[k]
    L.caja(9, 16, 14, 20, fondo, OR[0])
    L.r(11, 19, 10, 8, fig) if k == 0 else [L.p(x, y, fig) for y in range(18, 28) for x in range(11, 21) if (x - 16) ** 2 + (y - 23) ** 2 < 16]
    for y in (29, 31, 33): L.hl(11, 19 if y == 31 else 20, y, tinta)
    L.contorno(K); suelo(L, 9, 22, K)
    return L

def plantaT():
    L = Lienzo(32, 48)
    L.r(11, 38, 10, 8, '#8a4a2a'); L.hl(11, 20, 38, '#b8683a'); L.hl(11, 20, 45, '#5a2e1a')
    for i in range(7):
        a = -1.2 + i * .4
        for t in range(14):
            x, y = 16 + math.sin(a) * t * .9, 37 - t
            L.p(int(x), int(y), '#2e7a3e' if t % 3 else '#4cb05a')
    L.contorno(K); suelo(L, 11, 20, K)
    return L

def decoT():
    """un trozo del decorado del fondo (2 casillas): el cielo de tarde, los montes y el bastidor de madera abajo; casa con
    el de al lado"""
    L = Lienzo(48, 48)
    for y in range(18, 44):
        c = '#e8a86a' if y < 24 else '#f0c890' if y < 30 else '#9ac0d8'
        L.hl(8, 39, y, c)
    for x in range(8, 40):
        h = int(36 - 5 * math.sin(x / 6.0) - 2 * math.sin(x / 2.3))
        L.vl(x, h, 43, '#5a7a4a' if h > 33 else '#4a6a3e')
        L.vl(x, 41, 43, '#3a5a32')
    L.r(8, 44, 32, 4, MA[1]); L.hl(8, 39, 44, MA[3]); L.hl(8, 39, 47, MA[0])
    L.r(8, 16, 32, 2, MA[0])
    return L

def palcoT():
    """el palco de la pared (2 casillas): la baranda dorada con el terciopelo y la cortinilla, en lo alto"""
    L = Lienzo(48, 48)
    L.r(8, 16, 32, 12, GR[0])
    L.r(10, 18, 6, 10, GR[2]); L.r(32, 18, 6, 10, GR[2])      # las cortinillas recogidas
    L.r(6, 28, 36, 8, OR[1]); L.hl(6, 41, 28, OR[3]); L.hl(6, 41, 35, OR[0])
    for x in range(8, 40, 4): L.vl(x, 30, 34, OR[0])
    L.r(8, 36, 32, 3, GR[1]); L.hl(8, 39, 38, K)
    L.contorno(K)
    return L

def taquillaT():
    """la taquilla (2 casillas): el mostrador de madera con el cristal y el hueco, el rollo de entradas y la lamparita"""
    L = Lienzo(48, 48)
    L.r(8, 34, 32, 12, MA[2]); L.hl(8, 39, 34, MA[3]); L.r(8, 46, 32, 1, MA[0])
    L.caja(10, 37, 12, 7, MA[1], MA[0]); L.caja(26, 37, 12, 7, MA[1], MA[0])
    L.r(8, 18, 32, 16, '#9ac8e0'); L.vl(8, 18, 33, MA[1]); L.vl(39, 18, 33, MA[1]); L.hl(8, 39, 18, MA[1])
    L.r(18, 28, 12, 6, MA[0]); L.p(11, 20, '#d8f0ff'); L.p(12, 20, '#d8f0ff')
    L.r(33, 30, 4, 3, '#f0e0b0'); L.p(34, 29, '#c03a3a')           # el rollo de entradas
    L.vl(12, 24, 32, OR[0]); L.r(10, 22, 5, 2, OR[2])                # la lamparita
    L.contorno(K); suelo(L, 8, 39, K)
    return L


# --------------------------------------------------------------------------------------------------------------- la iglesia
def bancoI():
    """el banco de la iglesia (1 casilla de un banco largo, de espaldas: el respaldo de madera con el reclinatorio detrás)"""
    L = Lienzo(32, 48)
    L.r(8, 34, 16, 6, MA[2]); L.hl(8, 23, 34, MA[3]); L.hl(8, 23, 39, MA[0])
    L.r(8, 40, 16, 3, MA[1]); L.hl(8, 23, 42, MA[0])                 # el asiento, asomando
    L.r(8, 44, 16, 2, MA[0]); L.hl(8, 23, 44, MA[2])                 # el reclinatorio
    L.vl(8, 34, 46, MA[0]); L.vl(23, 34, 46, MA[0])
    return L

def columnaI():
    L = Lienzo(32, 48)
    L.r(10, 2, 12, 42, PI[2]); L.vl(10, 2, 43, PI[3]); L.vl(21, 2, 43, PI[0])
    for x in (13, 16, 19): L.vl(x, 4, 41, PI[1])
    L.r(8, 0, 16, 3, PI[3]); L.r(8, 43, 16, 4, PI[1]); L.hl(8, 23, 43, PI[3])
    L.contorno(K); suelo(L, 8, 23, K)
    return L

def cirioI():
    L = Lienzo(32, 48)
    L.r(14, 40, 4, 6, OR[1]); L.hl(12, 19, 45, OR[0]); L.vl(15, 26, 39, OR[1])
    L.r(13, 24, 6, 2, OR[2]); L.r(15, 14, 2, 10, '#f6f2e6'); L.p(15, 12, '#ffd060'); L.p(15, 13, '#ff9a30'); L.p(16, 13, '#ffd060')
    L.contorno(K); suelo(L, 12, 19, K)
    return L

def velasI():
    """el lampadario: la peana de hierro con las velas encendidas en gradas"""
    L = Lienzo(32, 48)
    L.vl(15, 30, 45, '#3a3a40'); L.vl(16, 30, 45, '#5a5a62'); L.hl(11, 20, 46, '#3a3a40')
    for j, y in enumerate((24, 29, 34)):
        x0 = 8 + j * 2; x1 = 23 - j * 2
        L.r(x0, y + 2, x1 - x0 + 1, 2, '#5a5a62'); L.hl(x0, x1, y + 2, '#8a8a92')
        for x in range(x0 + 1, x1, 3):
            L.r(x, y - 1, 1, 3, '#f6f2e6'); L.p(x, y - 2, '#ffb040')
    L.contorno(K); suelo(L, 11, 20, K)
    return L

def cepilloI():
    L = Lienzo(32, 48)
    L.vl(15, 36, 45, MA[0]); L.vl(16, 36, 45, MA[1]); L.hl(12, 19, 46, MA[0])
    L.caja(11, 28, 10, 9, MA[2], MA[0]); L.hl(13, 18, 30, K); L.r(14, 32, 4, 3, OR[1]); L.p(15, 33, K)   # la ranura y el candado
    L.contorno(K); suelo(L, 12, 19, K)
    return L

def pilaI():
    L = Lienzo(32, 48)
    L.r(14, 38, 4, 8, PI[2]); L.vl(14, 38, 45, PI[3]); L.r(11, 46, 10, 1, PI[1])
    for y in range(30, 38):
        hw = 7 - max(0, y - 33)
        L.hl(16 - hw, 15 + hw, y, PI[2] if y > 31 else PI[3])
    L.hl(10, 21, 31, '#6a9ac0'); L.hl(11, 20, 32, '#4a7aa0')
    L.contorno(K); suelo(L, 11, 20, K)
    return L

def retablo(estilo):
    """el retablo en la pared del fondo (2 casillas): calles y columnas doradas con nichos vacíos de color (sin imágenes);
    estilo 'I' gótico, 'B' barroco (más dorado y curvo)"""
    L = Lienzo(48, 48)
    L.r(8, 8, 32, 40, OR[1])
    for x in (8, 18, 29, 39): L.vl(x, 8, 47, OR[0])
    for x0 in (10, 20, 31):
        w = 8 if x0 != 20 else 9
        for y in range(12, 30):
            hw = w // 2 if y > 15 or estilo == 'B' else max(1, (y - 11) * w // 8)
            for x in range(x0 + w // 2 - hw, x0 + w // 2 + hw):
                L.p(x, y, '#2a3a6a' if x0 == 20 else '#5a1a22')
        L.r(x0, 33, w, 10, '#2a3a6a' if x0 != 20 else '#5a1a22')
    if estilo == 'B':
        for x in range(8, 40):
            L.p(x, 8 + int(3 * abs(math.sin((x - 8) / 5.0))), OR[3])
    else:
        for x0 in (8, 18, 29):
            L.vl(x0 + 5, 2, 8, OR[1]); L.p(x0 + 5, 1, OR[3])
    L.hl(8, 39, 31, OR[3]); L.hl(8, 39, 44, OR[3])
    L.contorno(K)
    return L

def cruzZ():
    """la pared del fondo de la parroquia: un paño de ladrillo visto con la cruz lisa de madera"""
    L = Lienzo(48, 48)
    for y in range(16, 48):
        for x in range(8, 40):
            L.p(x, y, '#a85a3a' if ((x + (4 if (y // 3) % 2 else 0)) % 8) and y % 3 else '#7a3e28')
    L.r(22, 18, 4, 26, MA[2]); L.vl(22, 18, 43, MA[3]); L.r(16, 24, 16, 4, MA[2]); L.hl(16, 31, 24, MA[3])
    L.contorno(K)
    return L

def altarI():
    """el altar de piedra (2 casillas) con el mantel blanco, el frontal bordado y dos candeleros"""
    L = Lienzo(48, 48)
    L.r(8, 36, 32, 11, PI[2]); L.hl(8, 39, 46, PI[0])
    L.r(8, 32, 32, 8, BL[2]); L.hl(8, 39, 32, '#ffffff'); L.hl(8, 39, 39, BL[0])
    L.r(18, 34, 12, 5, '#9a1e26'); L.hl(18, 29, 34, OR[2]); L.p(23, 36, OR[2]); L.p(24, 36, OR[2])
    for x in (11, 36):
        L.r(x, 26, 2, 6, OR[1]); L.r(x, 20, 2, 6, '#f6f2e6'); L.p(x, 19, '#ffb040')
    L.contorno(K); suelo(L, 8, 39, K)
    return L

def confesI():
    """el confesionario de madera (2 casillas, 2,2 m): la caseta con la puerta de celosía y la cortina del penitente"""
    L = Lienzo(48, 48)
    L.r(10, 12, 28, 34, MA[1]); L.r(8, 10, 32, 4, MA[2]); L.hl(8, 39, 10, MA[3])
    for x in range(14, 34, 2): L.vl(x, 4, 9, MA[0]) if x % 4 == 0 else None
    L.r(8, 6, 32, 4, MA[1]); L.hl(8, 39, 6, MA[3])
    L.caja(18, 16, 12, 28, MA[2], MA[0])                          # la puerta del confesor, con celosía
    for y in range(19, 28, 2):
        for x in range(20, 28, 2): L.p(x, y, MA[0])
    L.r(11, 18, 6, 26, '#5a1a22'); L.vl(11, 18, 43, '#7a2a32')     # las cortinas de los dos lados
    L.r(31, 18, 6, 26, '#5a1a22'); L.vl(36, 18, 43, '#3a0e16')
    L.r(10, 44, 28, 2, MA[0])
    L.contorno(K); suelo(L, 8, 39, K)
    return L


# --------------------------------------------------------------------------------------------------------------- el mercado
def puesto(cosas, toldo):
    """un puesto del mercado (2 casillas): el mostrador de acero con su frente de azulejo, el género encima en cajas o bandejas
    y la marquesina de color arriba"""
    L = Lienzo(48, 48)
    L.r(8, 36, 32, 10, BL[1]); L.hl(8, 39, 36, BL[2]); L.r(8, 46, 32, 1, '#8a8a84')
    for x in range(8, 40, 4): L.vl(x, 37, 45, BL[0])
    L.r(8, 34, 32, 2, '#a8acb4'); L.hl(8, 39, 34, '#ccd0d6')
    L.r(7, 10, 34, 4, toldo[0]); L.hl(7, 40, 10, toldo[1])
    for x in range(7, 41, 4): L.r(x, 14, 2, 2, toldo[0])
    L.vl(8, 14, 33, '#8a8a84'); L.vl(39, 14, 33, '#8a8a84')
    cosas(L)
    L.contorno(K); suelo(L, 8, 39, K)
    return L

def _caja(L, x, y, c):
    L.r(x, y + 2, 8, 4, '#c89a5a'); L.hl(x, x + 7, y + 5, '#8a6a3a')
    for i in range(0, 8, 2):
        L.p(x + i, y + 1, c[0]); L.p(x + i + 1, y + 1, c[1]); L.p(x + i, y, c[1])

def frutas(L):
    for i, c in enumerate((('#d02a2a', '#ff6a5a'), ('#f0a020', '#ffd060'), ('#4aa03a', '#8ad060'), ('#e8d040', '#fff080'))):
        _caja(L, 9 + i * 8, 28, c)

def pescado(L):
    L.r(9, 30, 30, 4, '#e8f4fa'); L.hl(9, 38, 30, '#ffffff')          # el hielo
    for x in range(10, 36, 6):
        L.r(x, 28, 5, 2, '#9aaabc'); L.p(x + 5, 28, '#7a8a9c'); L.p(x, 28, '#5a6a7c')
    L.r(30, 26, 4, 3, '#d86a4a')

def carne(L):
    L.r(9, 31, 30, 3, '#f0f0ea')
    for x in range(10, 36, 7): L.r(x, 29, 5, 3, '#b8323a'); L.p(x + 1, 29, '#e88a8a')
    for x in (14, 26): L.vl(x, 16, 24, '#8a8a84'); L.r(x - 1, 24, 3, 4, '#a8323a')   # los ganchos

def quesos(L):
    for x in (10, 19, 28):
        L.r(x, 27, 8, 5, '#f0d488'); L.hl(x, x + 7, 27, '#ffe8a8'); L.hl(x, x + 7, 31, '#c8a050'); L.p(x + 2, 29, '#c8a050')

def verduras(L):
    for i, c in enumerate((('#3a8a3a', '#6ac05a'), ('#e86a2a', '#ffa060'), ('#7a3a8a', '#a86ac0'), ('#c8b85a', '#e8d880'))):
        _caja(L, 9 + i * 8, 28, c)

def pan(L):
    for x in range(10, 38, 7):
        L.r(x, 29, 6, 3, '#c8883a'); L.hl(x, x + 5, 29, '#e8b060'); L.p(x + 2, 30, '#a86a2a')
    L.r(11, 24, 26, 2, '#8a5a2a')

def flores(L):
    for x in range(10, 38, 5):
        L.r(x, 30, 4, 4, '#3a4a5a'); L.vl(x + 1, 25, 29, '#3a8a3a')
        L.p(x + 1, 24, ('#e83a5a', '#f0d040', '#ffffff', '#c83ac0')[(x // 5) % 4]); L.p(x + 2, 25, '#e8a0b0')

def especias(L):
    for x in range(10, 38, 4):
        L.r(x, 29, 3, 4, ('#c83a1a', '#e8a020', '#7a5a2a', '#3a7a2a')[(x // 4) % 4]); L.hl(x, x + 2, 29, '#f0e0c0')

def barraMe():
    """la barra de pintxos del mercado (2 casillas): la madera, la vitrina con las bandejas y el grifo de cerveza"""
    L = Lienzo(48, 48)
    L.r(8, 34, 32, 12, MA[2]); L.hl(8, 39, 34, MA[3]); L.r(8, 46, 32, 1, MA[0])
    L.r(8, 26, 32, 8, '#cfe8f0'); L.hl(8, 39, 26, '#ffffff'); L.vl(8, 26, 33, '#8a8a84'); L.vl(39, 26, 33, '#8a8a84')
    for x in range(10, 38, 5):
        L.r(x, 30, 4, 2, '#e8c070'); L.p(x + 1, 29, ('#4a9a3a', '#c83a2a', '#f0e0a0')[(x // 5) % 3])
    L.vl(33, 18, 25, '#a8acb4'); L.r(32, 18, 3, 2, '#ccd0d6'); L.p(34, 21, '#e8b83a')
    L.contorno(K); suelo(L, 8, 39, K)
    return L

def taburMe():
    L = Lienzo(32, 48)
    L.r(11, 34, 10, 3, '#2a2a30'); L.hl(11, 20, 34, '#4a4a52')
    L.vl(12, 37, 46, '#5a5a62'); L.vl(19, 37, 46, '#5a5a62'); L.hl(12, 19, 42, '#5a5a62')
    L.contorno(K); suelo(L, 11, 20, K)
    return L

def cajasMe():
    L = Lienzo(32, 48)
    for j, y in enumerate((38, 31, 24)):
        x = 9 + (j % 2)
        L.r(x, y, 14, 7, '#c89a5a'); L.hl(x, x + 13, y, '#e8b878'); L.hl(x, x + 13, y + 6, '#8a6a3a'); L.vl(x + 4, y + 1, y + 5, '#8a6a3a'); L.vl(x + 9, y + 1, y + 5, '#8a6a3a')
    L.contorno(K); suelo(L, 9, 23, K)
    return L


# ------------------------------------------------------------------------------------------- la estación y el molino de mareas
def panelE():
    """el panel de salidas (2 casillas), colgado en la pared: la caja negra con las filas de puntos ámbar (sin letras) y el reloj"""
    L = Lienzo(48, 48)
    L.r(6, 14, 36, 22, '#1a1c22'); L.hl(6, 41, 14, '#3a3e48'); L.hl(6, 41, 35, '#0a0a0e')
    for j, y in enumerate(range(18, 33, 4)):
        for x in range(9, 38, 2):
            if (x * 7 + j * 5) % 11 < 8: L.p(x, y, '#e8a83a' if x < 30 else '#7ad86a')
        L.p(39, y, '#e8a83a')
    L.r(20, 8, 8, 6, '#e4e6e8'); L.vl(24, 9, 11, K); L.hl(24, 26, 11, K)   # el reloj, encima
    L.vl(24, 4, 7, '#5a5e66')
    L.contorno(K)
    return L

def maquinaE():
    """la máquina de billetes (1,7 m): el cuerpo gris con la pantalla, las teclas, la ranura y la bandeja"""
    L = Lienzo(32, 48)
    L.r(10, 20, 13, 26, '#8e949c'); L.vl(10, 20, 45, '#6a7078'); L.vl(22, 20, 45, '#b8bec6'); L.hl(10, 22, 20, '#c8ced6')
    L.r(12, 22, 9, 6, '#2a4a6a'); L.r(13, 23, 7, 4, '#5a9ac8'); L.p(14, 24, '#c8e8ff')
    for y in (30, 32):
        for x in (12, 14, 16): L.p(x, y, '#e4e6e8')
    L.r(18, 30, 3, 3, '#3a3e44'); L.r(12, 36, 9, 2, '#2a2a30'); L.r(12, 41, 9, 3, '#4a4e56')
    L.contorno(K); suelo(L, 10, 22, K)
    return L

def ruedaM():
    """la rueda del molino de mareas (2 casillas): la muela de piedra sobre su bancada de madera, la tolva encima y, abajo, el
    hueco del canal con el agua que la mueve"""
    L = Lienzo(48, 48)
    L.r(8, 38, 32, 8, '#2a4a6a'); L.hl(8, 39, 38, '#5a8ab0')        # el canal
    for x in range(10, 38, 5): L.p(x, 41, '#a8d0e8')
    L.r(6, 30, 36, 8, MA[1]); L.hl(6, 41, 30, MA[3]); L.hl(6, 41, 37, MA[0])   # la bancada
    for i in range(0, 13):                                         # la muela, redonda, de piedra
        w = int(math.sqrt(max(0, 36 - (i - 6) ** 2)) * 2)
        L.hl(24 - w, 23 + w, 17 + i, PI[2] if i < 5 else PI[1])
    L.hl(14, 33, 29, PI[0]); L.r(22, 21, 4, 3, PI[0])
    L.r(18, 8, 12, 8, MA[2]); L.hl(18, 29, 8, MA[3]); L.r(21, 14, 6, 3, MA[1])   # la tolva
    L.contorno(K); suelo(L, 6, 41, K)
    return L


TILES = (floorTeat, tablado, escalonT, iwT_teat, iwB_teat, iwB_teatP, iwB_teatF, floorIg, presbI, escalonI, alfombraI, iwT_ig, iwB_ig,
         floorMe, iwT_me, iwB_me)
for f in TILES:
    sale(f.__name__, f(), 'interior-bilbao')
for n, f in (('butaca', butaca), ('telonI', lambda: telon('I')), ('telonD', lambda: telon('D')), ('cartelT', lambda: cartel(0)),
             ('cartelT2', lambda: cartel(1)), ('plantaT', plantaT), ('cirioI', cirioI), ('bancoI', bancoI), ('columnaI', columnaI),
             ('velasI', velasI), ('cepilloI', cepilloI), ('pilaI', pilaI), ('taburMe', taburMe), ('cajasMe', cajasMe), ('maquinaE', maquinaE)):
    sale(n, f(), 'interior-bilbao-alto')
TOLDO = {'Fr': ('#3a8a3a', '#6ac05a'), 'Pe': ('#2a5a9a', '#5a8ac8'), 'Ca': ('#a82a2a', '#d85a5a'), 'Qu': ('#c89a2a', '#e8c85a'),
         'Ve': ('#5a8a2a', '#8ab85a'), 'Pa': ('#8a5a2a', '#b88a5a'), 'Fl': ('#a83a7a', '#d86aa8'), 'Es': ('#c86a2a', '#e89a5a')}
for k, f in (('Fr', frutas), ('Pe', pescado), ('Ca', carne), ('Qu', quesos), ('Ve', verduras), ('Pa', pan), ('Fl', flores), ('Es', especias)):
    sale('puesto' + k, puesto(f, TOLDO[k]), 'interior-bilbao-ancho')
for n, f in (('decoT', decoT), ('palcoT', palcoT), ('taquillaT', taquillaT), ('retabloI', lambda: retablo('I')), ('retabloB', lambda: retablo('B')),
             ('cruzZ', cruzZ), ('altarI', altarI), ('confesI', confesI), ('barraMe', barraMe), ('panelE', panelE), ('ruedaM', ruedaM)):
    sale(n, f(), 'interior-bilbao-ancho')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica')
            os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
