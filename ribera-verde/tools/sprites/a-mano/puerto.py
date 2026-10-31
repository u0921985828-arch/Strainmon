# python3 -I tools/sprites/a-mano/puerto.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.51 (lo pidió el usuario: «un mapa lateral en Puerto Viejo, un mini puerto para hacer envíos… invertir en un barco, empezando por
# uno pequeño»): el muelle de la cofradía a 16 px/m, como el piso.
#  · Barcos amarrados de costado, vistos de frente a 3/4 (el casco de babor y un poco de cubierta, nunca isométricos), a su eslora:
#    barcoT, la txalupa de 6 m de la tía Maite (celda barco_6, 112 × 64), con su nombre en la amura; barcoP, el pesquero de bajura de
#    10 m (barco_10, 176 × 64), con el puente, el pórtico y las redes; barcoA, el atunero de 14 m (barco_14, 240 × 80), con el puente
#    alto, el palo y las cañas. La base, la línea de flotación, en la fila de abajo; ancla en (8, h − 1) como los coches del taller.
#  · Objetos altos (objeto_alto, 32 × 32, pies en (16, 31)): noray (el bolardo de hierro del amarre, con su cabo), redes (un montón de
#    red verde con boyas) y nasas (nasas apiladas de malla y madera).
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js puerto-barcoT puerto-barcoP puerto-barcoA
# puerto-alto --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

K = '#26262e'
SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

# letras de 3 × 5 para el nombre del barco
LET = {'M': ['101', '111', '111', '101', '101'], 'A': ['010', '101', '111', '101', '101'], 'I': ['111', '010', '010', '010', '111'],
       'T': ['111', '010', '010', '010', '010'], 'E': ['111', '100', '110', '100', '111'], 'N': ['101', '111', '111', '111', '101'],
       'R': ['110', '101', '110', '101', '101'], 'O': ['111', '101', '101', '101', '111'], 'S': ['111', '100', '111', '001', '111'],
       'B': ['110', '101', '110', '101', '110'], 'U': ['101', '101', '101', '101', '111'], 'Z': ['111', '001', '010', '100', '111'],
       'G': ['111', '100', '101', '101', '111'], 'L': ['100', '100', '100', '100', '111'], 'K': ['101', '101', '110', '101', '101'],
       ' ': ['000'] * 5}
def texto(L, x, y, t, c):
    for ch in t:
        for j, f in enumerate(LET[ch]):
            for i, b in enumerate(f):
                if b == '1':
                    L.p(x + i, y + j, c)
        x += 4

def casco(L, x0, x1, yc, yf, ca, cb, banda, cubierta, proa=8):
    """el casco de costado: de la popa (x0, recta) a la proa (x1, que sube en curva); yc la regala, yf la flotación.
    ca el blanco del costado, cb su sombra (la mitad de abajo), banda la franja de color bajo la regala, cubierta la tapa de arriba"""
    alto = yf - yc
    for x in range(x0, x1 + 1):
        t = (x - x1 + proa) / proa if x > x1 - proa else 0
        sube = int(round(3 * t * t))                     # la proa, más alta
        quilla = int(round(alto * .55 * t ** 1.6))       # y la quilla que se recoge hacia la roda
        y0 = yc - sube
        y1 = yf - quilla
        if y1 <= y0:
            continue
        L.vl(x, y0, y1, ca)
        L.vl(x, y0 + (y1 - y0) // 2 + 1, y1, cb)
        L.p(x, y0, cubierta)
        L.p(x, y0 + 1, banda)
        if y0 + 2 <= y1:
            L.p(x, y0 + 2, banda)
    L.vl(x0, yc, yf, cb)                                 # el espejo de popa, en sombra
    L.hl(x0, x1 - proa + 2, yf, '#3a3e46')               # la línea de flotación (el antifouling que asoma)
    L.hl(x0, x1 - proa, yf - 1, '#b8463a')

def agua(L, x0, x1, yf):
    """el reflejo y las ondas al pie del casco (sobre el agua de la casilla)"""
    for x in range(x0 - 2, x1 + 3, 3):
        L.p(x, yf + 1, '#b4dcfa')
    for x in range(x0, x1, 5):
        L.p(x + 1, yf + 2, '#76b4f2'); L.p(x + 2, yf + 2, '#76b4f2')

def ventanas(L, x, y, n, paso, c='#7ab0d8', b='#c8e4f4'):
    for i in range(n):
        L.r(x + i * paso, y, paso - 2, 3, c); L.p(x + i * paso, y, b)

def barcoT():
    """la txalupa de 6 m (96 px): casco blanco con la franja azul, cabina pequeña a popa, motor fueraborda, el nombre MAITE"""
    L = Lienzo(112, 64)
    yf, yc = 60, 47                                         # 0,8 m de francobordo
    x0, x1 = 6, 6 + 95
    # la cabina, a popa: 1,6 m sobre cubierta
    L.r(x0 + 8, yc - 22, 26, 22, '#e8e4dc'); L.vl(x0 + 8, yc - 22, yc - 1, '#c8c4bc'); L.hl(x0 + 8, x0 + 33, yc - 22, '#f8f6f0')
    L.r(x0 + 6, yc - 25, 30, 3, '#46749a'); L.hl(x0 + 6, x0 + 35, yc - 25, '#6a9ac2')    # el techo
    ventanas(L, x0 + 12, yc - 17, 3, 7)
    L.vl(x0 + 30, yc - 33, yc - 26, '#9aa2aa'); L.p(x0 + 30, yc - 34, '#e04040')        # la antena y su luz
    # el fueraborda, colgado del espejo
    L.r(x0 - 5, yc - 4, 5, 8, '#3a3e46'); L.hl(x0 - 5, x0 - 1, yc - 4, '#6c7482'); L.vl(x0 - 3, yc + 4, yf + 1, '#3a3e46')
    casco(L, x0, x1, yc, yf, '#f4f2ea', '#d8d4ca', '#3a6ea8', '#a46e40', proa=16)
    texto(L, x0 + 52, yc + 4, 'MAITE', '#26262e')
    # el balcón de proa y los cabos
    L.hl(x1 - 22, x1 - 6, yc - 5, '#b8bcc4'); L.vl(x1 - 22, yc - 5, yc - 1, '#b8bcc4'); L.vl(x1 - 6, yc - 7, yc - 3, '#b8bcc4')
    for i in range(4):
        L.p(x0 + 40 + i * 4, yc - 1, '#dcd6c6')                                            # la defensa
    L.r(x0 + 44, yc + 2, 3, 6, '#e04040'); L.r(x0 + 74, yc + 2, 3, 5, '#e04040')        # dos defensas rojas colgando
    L.contorno(K)
    agua(L, x0, x1, yf)
    return L

def barcoP():
    """el pesquero de bajura de 10 m (160 px): casco azul, regala blanca, el puente a proa, el pórtico de popa con la red y la maquinilla"""
    L = Lienzo(176, 64)
    yf, yc = 60, 43                                         # 1 m de francobordo
    x0, x1 = 6, 6 + 159
    # el puente: 2,4 m
    bx = x0 + 96
    L.r(bx, yc - 30, 38, 30, '#f4f2ea'); L.vl(bx, yc - 30, yc - 1, '#d8d4ca'); L.hl(bx, bx + 37, yc - 30, '#ffffff')
    L.r(bx - 2, yc - 33, 42, 3, '#c84a3a'); L.hl(bx - 2, bx + 39, yc - 33, '#e06a5a')
    ventanas(L, bx + 4, yc - 25, 4, 8, '#2e4a66', '#7ab0d8')
    L.r(bx + 10, yc - 14, 6, 13, '#d8d4ca'); L.p(bx + 14, yc - 8, '#9aa2aa')            # la puerta
    L.vl(bx + 30, yc - 41, yc - 34, '#9aa2aa'); L.hl(bx + 26, bx + 34, yc - 39, '#9aa2aa')  # el mástil con la cruceta
    L.p(bx + 30, yc - 42, '#f8e8a0'); L.r(bx + 22, yc - 38, 5, 2, '#3a3e46')             # la luz y el radar
    # el pórtico de popa y la red
    L.vl(x0 + 10, yc - 34, yc - 1, '#6c7482'); L.vl(x0 + 30, yc - 34, yc - 1, '#6c7482'); L.hl(x0 + 10, x0 + 30, yc - 34, '#6c7482')
    L.hl(x0 + 10, x0 + 30, yc - 33, '#4a5058')
    for y in range(yc - 30, yc - 2, 2):                                                     # la red colgada, en verde
        for x in range(x0 + 13 + (y % 4) // 2, x0 + 28, 2):
            L.p(x, y, '#3f8a46')
    L.r(x0 + 14, yc - 6, 14, 5, '#2e6a36')
    for x in (x0 + 15, x0 + 21, x0 + 26):
        L.p(x, yc - 31, '#f0a030'); L.p(x, yc - 30, '#d07a20')                              # los corchos
    L.r(x0 + 44, yc - 8, 12, 8, '#4a5058'); L.r(x0 + 46, yc - 11, 8, 3, '#6c7482')        # la maquinilla
    for x in range(x0 + 60, x0 + 92, 6):
        L.r(x, yc - 5, 5, 5, '#5a8ac0'); L.hl(x, x + 4, yc - 5, '#7aaae0')                 # las cajas de pescado
    casco(L, x0, x1, yc, yf, '#2e5a8a', '#244a72', '#f4f2ea', '#f4f2ea', proa=24)
    texto(L, x0 + 110, yc + 4, 'ITSASO', '#f4f2ea')
    for x in (x0 + 40, x0 + 80):
        L.r(x, yc + 2, 4, 7, '#e8e4dc')                                                     # defensas
    L.contorno(K)
    agua(L, x0, x1, yf)
    return L

def barcoA():
    """el atunero de 14 m (224 px): casco rojo y negro, el puente alto con el alerón, el palo con la cofa y las cañas de popa"""
    L = Lienzo(240, 80)
    yf, yc = 76, 56                                         # 1,25 m de francobordo
    x0, x1 = 8, 8 + 223
    bx = x0 + 120
    # la superestructura en dos pisos: 4 m
    L.r(bx, yc - 26, 60, 26, '#f4f2ea'); L.vl(bx, yc - 26, yc - 1, '#d8d4ca'); L.hl(bx, bx + 59, yc - 26, '#ffffff')
    ventanas(L, bx + 6, yc - 20, 6, 8, '#2e4a66', '#7ab0d8')
    L.r(bx + 8, yc - 44, 40, 18, '#f4f2ea'); L.vl(bx + 8, yc - 44, yc - 27, '#d8d4ca')
    L.r(bx + 4, yc - 47, 48, 3, '#26262e'); L.hl(bx + 4, bx + 51, yc - 47, '#4a5058')
    ventanas(L, bx + 11, yc - 40, 4, 9, '#2e4a66', '#9ad0f0')
    L.hl(bx + 48, bx + 58, yc - 30, '#b8bcc4'); L.vl(bx + 58, yc - 30, yc - 27, '#b8bcc4')  # el alerón
    # el palo con la cofa y las antenas
    L.vl(bx + 30, yc - 54, yc - 48, '#9aa2aa'); L.r(bx + 26, yc - 51, 9, 2, '#6c7482'); L.hl(bx + 22, bx + 38, yc - 53, '#9aa2aa')
    L.p(bx + 30, yc - 55, '#e04040'); L.vl(bx + 40, yc - 54, yc - 48, '#b8bcc4'); L.vl(bx + 20, yc - 52, yc - 48, '#b8bcc4')
    L.r(bx + 34, yc - 54, 6, 3, '#3a3e46')
    # la chimenea
    L.r(bx - 8, yc - 22, 7, 22, '#c84a3a'); L.r(bx - 8, yc - 25, 7, 3, '#26262e')
    # las cañas a popa, inclinadas, y los viveros
    for i, (a, b) in enumerate(((x0 + 6, yc - 46), (x0 + 14, yc - 50), (x0 + 22, yc - 44))):
        for s in range(0, 40):
            L.p(a + s // 4, yc - 2 - s * (yc - 2 - b) // 40, '#c8a868')
    for x in range(x0 + 40, x0 + 110, 14):
        L.r(x, yc - 6, 11, 6, '#4a72c2'); L.hl(x, x + 10, yc - 6, '#7aaae0')
    L.r(x0 + 112, yc - 10, 6, 10, '#6c7482')                                                # el cabrestante
    casco(L, x0, x1, yc, yf, '#c84a3a', '#a83a2e', '#26262e', '#f4f2ea', proa=34)
    L.hl(x0, x1 - 30, yf - 4, '#26262e'); L.hl(x0, x1 - 32, yf - 3, '#26262e')              # la franja negra de abajo
    texto(L, x0 + 156, yc + 5, 'MAITE BI', '#f4f2ea')
    for x in (x0 + 50, x0 + 100, x0 + 196):
        L.r(x, yc + 3, 5, 8, '#26262e')                                                     # neumáticos de defensa
    L.contorno(K)
    agua(L, x0, x1, yf)
    return L

def noray():
    """el bolardo de hierro fundido del amarre, negro y gastado, con el cabo blanco que baja al agua"""
    L = Lienzo(32, 32)
    L.r(11, 22, 10, 9, '#3a3e46'); L.vl(11, 22, 30, '#5a6068'); L.vl(20, 23, 30, '#26262e')
    L.r(9, 19, 14, 4, '#4a5058'); L.hl(9, 22, 19, '#6c7482')                              # la cabeza
    L.hl(10, 21, 31, '#26262e')
    for i in range(8):
        L.p(12 + i, 25 + (i % 2), '#e8e4dc')                                                # el cabo dado de vuelta
    L.vl(21, 26, 31, '#e8e4dc'); L.p(22, 30, '#c8c4bc')
    L.contorno(K)
    return L

def redes():
    """un montón de red de pesca verde con boyas naranjas y el plomo"""
    L = Lienzo(32, 32); R = azar(515)
    for y in range(20, 31):
        w = 12 - abs(y - 25) // 2 + (y - 20)
        for x in range(16 - w // 2, 16 + w // 2 + 1):
            if 0 <= x < 32:
                L.p(x, y, '#3f8a46' if (x + y) % 3 else '#2e6a36')
    for _ in range(14):
        L.p(int(R() * 18) + 7, int(R() * 9) + 21, '#62aa56')
    for (x, y) in ((9, 25), (16, 21), (22, 26), (13, 28)):
        L.r(x, y, 3, 2, '#f0a030'); L.p(x, y, '#f8c860')
    L.hl(6, 26, 30, '#4a5058')                                                             # la relinga de plomo
    L.contorno(K)
    return L

def nasas():
    """nasas de malla con aros de madera, tres apiladas"""
    L = Lienzo(32, 32)
    for (x, y) in ((4, 22), (17, 22), (10, 12)):
        L.r(x, y, 12, 9, '#c8c4a8')
        for i in range(x, x + 12, 2):
            L.vl(i, y, y + 8, '#9a9478')
        L.vl(x, y, y + 8, MAD := '#74502e'); L.vl(x + 11, y, y + 8, MAD); L.hl(x, x + 11, y, '#a46e40'); L.hl(x, x + 11, y + 8, MAD)
        L.r(x + 4, y + 3, 4, 3, '#26262e')                                                  # la boca
    L.contorno(K)
    return L

sale('barcoT', barcoT(), 'puerto-barcoT'); sale('barcoP', barcoP(), 'puerto-barcoP'); sale('barcoA', barcoA(), 'puerto-barcoA')
sale('noray', noray(), 'puerto-alto'); sale('redes', redes(), 'puerto-alto'); sale('nasas', nasas(), 'puerto-alto')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
