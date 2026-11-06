# python3 -I tools/sprites/a-mano/detalle.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.48 (lo pidió el usuario: «el mapa lo quiero más realista, no estilo Minecraft sino más de RPG clásico» y «la calidad de los otros
# sprites también, que se note que es el sprite y lo que trae»): todo a mano, de frente a 3/4, sin marcas; el juego lo usa solo
# con Datos.CAL (pinta.gd), así las pantallas del HTML no cambian.
#  · exterior-mosaico (tile_mosaico, 256 × 16): los firmes de la calle en mosaicos de 64 × 64 cortados en 16 casillas (el juego coge
#    la (tx & 3) + 4 (ty & 3)), para que no se vea la rejilla de 16 en 16: mo-grass (la hierba con sus matitas), mo-flowers,
#    mo-tallgrass (la hierba alta en matas redondas), mo-walk (la acera de losas grandes), mo-plaza (las losas de la plaza, de
#    varios tamaños), mo-dirt (el camino de tierra liso), mo-roadT y mo-roadB (el asfalto con el bordillo de piedra). La hierba,
#    la plaza y la tierra con el mismo color de fondo que antes: las orillas (tileset-transiciones) siguen casando.
#  · detalle-alto (mueble_escala, 32 × 48, base en (16, 47)): los mostradores y las barras con lo que llevan encima, en tres
#    tramos (-0, -1, -2) que el juego alterna por la casilla: d-counter-shop y d-counter-growcity (la caja, los botes de abono y
#    el expositor de los sobres de semillas), d-counter-comisaria (los papeles, el sello, el monitor), d-barcounter (los grifos de
#    cerveza, las cañas, el servilletero y los pintxos), d-barraD (la cubitera con la botella, los cócteles, la coctelera), d-display
#    (la vitrina del grow con los sobres, los botes y un grinder) y las cajas: d-crate (de madera, abierta, con piezas) y
#    d-crate-puerto (las de pescado, de plástico, con hielo y pescado; también en los astilleros).
#  · detalle-16 (objeto_1x1): d-shelfW-shop (la balda con los botes de abono), d-shelfW-comisaria (los archivadores), d-sacos (los
#    sacos de sustrato con la hoja), d-bottles (la balda de las botellas del bar) y d-seto (el seto redondeado, con sus matas).
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js exterior-mosaico detalle-alto detalle-16
# --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#2a2a34'
CROMO, CROMOD, CROMOL = '#c8ccd0', '#8a8e96', '#f0f2f4'
VID, VIDL = '#a8d4e0', '#e0f4f8'

# ---------------------------------------------------------------------------------------------------------- firmes
HIERBA, HIERBA_O, HIERBA_C, HIERBA_L = '#84cc6c', '#62aa56', '#9cd884', '#b0e48c'

def mosaico(dibuja):
    """un dibujo de 64 × 64 cortado en 16 casillas, en tira de 256 × 16"""
    M = Lienzo(64, 64); dibuja(M)
    T = Lienzo(256, 16)
    for j in range(4):
        for i in range(4):
            for y in range(16):
                for x in range(16):
                    T.px[(i + 4 * j) * 16 + x, y] = M.px[i * 16 + x, j * 16 + y]
    return T

def puntos(sem, n, paso=16):
    """n puntos repartidos por una rejilla de paso (uno por celda, corrido al azar): ni en fila ni amontonados"""
    R = azar(sem); out = []
    celdas = [(x, y) for y in range(0, 64, paso) for x in range(0, 64, paso)]
    for k in range(n):
        cx, cy = celdas[(k * 7) % len(celdas)]
        out.append((cx + 2 + int(R() * (paso - 5)), cy + 2 + int(R() * (paso - 5))))
    return out

def mata(L, x, y):
    """la matita de la hierba: dos briznas oscuras y la punta clara"""
    L.p(x, y + 1, HIERBA_O); L.p(x + 2, y + 1, HIERBA_O); L.p(x + 1, y + 2, HIERBA_O)
    L.p(x, y, HIERBA_C); L.p(x + 2, y, HIERBA_C)

def m_grass(L):
    L.r(0, 0, 64, 64, HIERBA)
    for (x, y) in puntos(4801, 16): mata(L, x % 62, y % 62)
    for (x, y) in puntos(4809, 10, 32): mata(L, (x + 9) % 62, (y + 5) % 62)
    R = azar(4802)
    for _ in range(18): L.p(int(R() * 64), int(R() * 64), HIERBA_C)

def m_flowers(L):
    m_grass(L)
    for k, (x, y) in enumerate(puntos(4803, 7)):
        c = ('#f4f4ee', '#e04848', '#f0d860')[k % 3]
        x, y = x % 61 + 1, y % 61 + 1
        for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)): L.p(x + dx, y + dy, c)
        L.p(x, y, '#f0a030' if c != '#f0d860' else '#c86a20'); L.p(x, y + 2, HIERBA_O)

def m_tallgrass(L):
    L.r(0, 0, 64, 64, HIERBA)
    for j in range(8):
        for i in range(8):
            x, y = i * 8, j * 8
            # una mata redonda de 8 × 8: tres hojas en punta con el borde oscuro, como un ramillete
            for (a, b, h) in ((1, 3, 5), (3, 1, 7), (5, 3, 5)):
                for k in range(h):
                    L.p(x + a, y + b + k, '#4ea04e' if k else HIERBA_C)
                    L.p(x + a + 1, y + b + k + 1, '#3f8a46')
            L.hl(x, x + 7, y + 7, '#3f8a46'); L.p(x + 3, y + 2, HIERBA_L)

def m_dirt(L):
    L.r(0, 0, 64, 64, '#c48a52')
    # lo pidió el usuario («me parece muy plano… lo haría más imperfecto»): manchas de tierra más húmeda y más seca, de borde
    # irregular (elipses con mordiscos por el azar) y que casan de un mosaico al siguiente (x e y módulo 64)
    R = azar(4810)
    for (cx, cy, rx, ry, c) in ((12, 18, 9, 5, '#bc8450'), (44, 10, 7, 4, '#cc9660'), (38, 44, 11, 6, '#bc8450'),
                                (8, 52, 6, 4, '#cc9660'), (56, 30, 5, 3, '#b47c48'), (24, 34, 4, 3, '#cc9660')):
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
                if d <= 1 and (d < 0.6 or R() < 0.55):
                    L.p(x % 64, y % 64, c)
    for (x0, y0, pasos) in ((30, 22, ((1, 0), (1, 1), (1, 0), (1, 1), (1, 0))), (2, 40, ((1, 1), (1, 0), (1, 0), (1, -1)))):
        x, y = x0, y0
        for (dx, dy) in pasos:   # dos grietas finas, con el labio de abajo claro
            L.p(x % 64, y % 64, '#a0744c'); L.p(x % 64, (y + 1) % 64, '#dca476')
            x += dx; y += dy
    R = azar(4804)
    for _ in range(26):
        x, y = int(R() * 63), int(R() * 63)
        L.p(x, y, '#b47c48')
    for (x, y) in puntos(4805, 6):   # las piedrecitas, con su luz
        L.p(x % 63, y % 63, '#a0744c'); L.p(x % 63 + 1, y % 63, '#a0744c'); L.p(x % 63, (y % 63) - 1, '#dca476')

def m_walk(L):
    """la acera de losas de 32 × 16 a matajuntas, cada una con su luz arriba y su sombra abajo"""
    L.r(0, 0, 64, 64, '#dcd6c6')
    for f in range(4):
        y = f * 16; off = 16 if f % 2 else 0
        L.hl(0, 63, y, '#ece6d6'); L.hl(0, 63, y + 15, '#c8c0ae')
        for x in range(off, 64 + off, 32):
            xx = x % 64
            L.vl(xx, y, y + 15, '#c8c0ae'); L.vl((xx + 1) % 64, y, y + 14, '#ece6d6')
    R = azar(4806)
    for _ in range(14): L.p(int(R() * 64), int(R() * 64), '#d2ccba')

def m_plaza(L):
    """losas de piedra de varios tamaños, juntas suaves, una luz en el canto de arriba"""
    L.r(0, 0, 64, 64, '#e8d6b0')
    filas = ((0, 16, (0, 24, 44)), (16, 12, (10, 34, 52)), (28, 20, (0, 20, 40)), (48, 16, (14, 30, 50)))
    for (y, h, xs) in filas:
        L.hl(0, 63, y, '#f2e4c4'); L.hl(0, 63, (y + h - 1) % 64, '#d6c29a')
        for x in xs:
            L.vl(x, y, y + h - 1, '#d6c29a'); L.vl((x + 1) % 64, y + 1, y + h - 2, '#f2e4c4')
    R = azar(4807)
    for _ in range(16): L.p(int(R() * 64), int(R() * 64), '#dcc8a2')

ASF, ASF_O, ASF_C = '#4a515c', '#424852', '#545c68'
def asfalto(L):
    L.r(0, 0, 64, 64, ASF)
    R = azar(4808)
    for _ in range(60): L.p(int(R() * 64), int(R() * 64), ASF_O if R() < .5 else ASF_C)

def bordillo(L, y0, arriba):
    """el bordillo de piedra (3 filas) con sus juntas cada 16 y la sombra en el asfalto"""
    L.r(0, y0, 64, 3, '#a8a8b0')
    L.hl(0, 63, y0 if arriba else y0 + 2, '#c8c8d0')
    for x in range(0, 64, 16): L.vl(x, y0, y0 + 2, '#8a8a94')
    L.hl(0, 63, y0 + 3 if arriba else y0 - 1, '#3c3c44')

def m_roadT(L):
    asfalto(L)
    for f in range(4):
        bordillo(L, f * 16, True)
        for x in range(2, 64, 32): L.r(x, f * 16 + 14, 14, 2, '#f0c838')   # la raya discontinua del medio
        for x in range(2, 64, 32): L.hl(x, x + 13, f * 16 + 14, '#f8dc68')

def m_roadB(L):
    asfalto(L)
    for f in range(4): bordillo(L, f * 16 + 13, False)

for n, f in (('mo-grass', m_grass), ('mo-flowers', m_flowers), ('mo-tallgrass', m_tallgrass), ('mo-dirt', m_dirt),
             ('mo-walk', m_walk), ('mo-plaza', m_plaza), ('mo-roadT', m_roadT), ('mo-roadB', m_roadB)):
    sale(n, mosaico(f), 'exterior-mosaico')

def traspuesto(f):
    """el mismo firme girado a lo vertical (x ↔ y): la calle de norte a sur, con el bordillo a un lado y la raya en el otro"""
    def d(L):
        M = Lienzo(64, 64); f(M)
        for y in range(64):
            for x in range(64):
                L.px[x, y] = M.px[y, x]
    return d

# Las calles transversales del Ensanche de Bilbao (lo pidió el usuario: «la estructura del mapa que se parezca al lugar»): mo-roadL y
# mo-roadR, la calzada de norte a sur (el bordillo a la izquierda o a la derecha), y mo-roadX, el asfalto del cruce, sin bordillo ni raya
for n, f in (('mo-roadL', traspuesto(m_roadT)), ('mo-roadR', traspuesto(m_roadB)), ('mo-roadX', asfalto)):
    sale(n, mosaico(f), 'exterior-mosaico')

# ---------------------------------------------------------------------------------------------------------- objetos 1 × 1
def d_seto():
    """el seto de 1 m: matas redondas (círculos de 5 px cada 8, que casan de una casilla a otra) con el borde oscuro, la luz arriba
    a la izquierda y la sombra abajo a la derecha; el pie, oscuro, con su sombra en el suelo"""
    L = Lienzo(16, 16)
    O, D, M, C, LL = '#2c6e36', '#3f8a46', '#4ea04e', '#6ac060', '#9ae080'
    def dentro(x, y):
        if 7 <= y <= 13: return True
        return any((x - cx) ** 2 + (y - 6) ** 2 <= 26 for cx in (-4, 4, 12, 20))
    for y in range(16):
        for x in range(16):
            if not dentro(x, y): continue
            c = M
            for cx in (-4, 4, 12, 20):
                dx, dy = x - cx, y - 6
                if dx * dx + dy * dy <= 26 and y <= 9:
                    if (dx + 2) ** 2 + (dy + 2) ** 2 <= 5: c = LL if (dx + 2) ** 2 + (dy + 2) ** 2 <= 1 else C
                    elif dx >= 2 and dy >= 1: c = D
            if not dentro(x, y - 1): c = O
            L.p(x, y, c)
    for x in range(16):   # entre mata y mata, la sombra que baja
        if x % 8 == 0: L.p(x, 8, D); L.p(x, 9, D)
    L.hl(0, 15, 12, D); L.hl(0, 15, 13, D); L.hl(0, 15, 14, O); L.hl(0, 15, 15, '#1e4a26')
    for x in (3, 11): L.p(x, 11, D); L.p(x + 1, 12, M)
    return L

def d_shelf(cosas):
    L = Lienzo(16, 16)
    L.r(0, 13, 16, 2, '#a87646'); L.hl(0, 15, 13, '#c89a62'); L.hl(0, 15, 15, '#62402a')   # la balda
    L.p(2, 15, '#4a2e1c'); L.p(13, 15, '#4a2e1c')
    cosas(L)
    return L

def botes_abono(L):
    for i, (c, cl, t) in enumerate((('#3a9a4a', '#6ac87a', 'g'), ('#d06a2a', '#f09a5a', 'f'), ('#5a6ad0', '#8a9af0', 'p'), ('#e8e4d8', '#ffffff', 'b'))):
        x = 1 + i * 4
        L.r(x, 6, 3, 7, c); L.vl(x, 6, 12, cl); L.r(x, 4, 3, 2, '#2a2a34' if t != 'b' else '#3a7ad0')    # el bote y su tapón
        L.r(x, 8, 3, 2, '#f4f4ee'); L.p(x + 1, 9, c)                                                          # la etiqueta, sin marca

def archivadores(L):
    for i, c in enumerate(('#3a5ab0', '#c03a3a', '#3a8a4a', '#d0a030', '#3a5ab0')):
        x = 1 + i * 3
        L.r(x, 3, 3, 10, c); L.vl(x, 3, 12, '#2a2a34'); L.r(x + 1, 5, 1, 2, '#f4f4ee'); L.p(x + 1, 10, '#e8e8e0')

def d_sacos():
    L = Lienzo(16, 16)
    for (x, y, w, h, c, co) in ((0, 5, 8, 10, '#6a4a2a', '#4a321c'), (7, 3, 8, 12, '#3a6a3a', '#24462a'), (4, 8, 8, 8, '#8a5a32', '#5a3a1c')):
        L.r(x, y, w, h, c); L.hl(x, x + w - 1, y, co); L.vl(x, y, y + h - 1, co)
        L.r(x + 2, y + 3, w - 4, 3, '#f0ecdc'); L.p(x + w // 2, y + 4, '#3a9a4a'); L.p(x + w // 2 - 1, y + 4, '#62c86a')   # la etiqueta con la hoja
        L.hl(x + 1, x + w - 2, y + 1, '#2a2a34')                                                                        # el cosido
    L.contorno(K); return L

def d_bottles():
    L = Lienzo(16, 16)
    for yb in (5, 11):   # dos baldas
        L.r(0, yb + 1, 16, 1, '#a87646'); L.hl(0, 15, yb + 1, '#c89a62')
    for i, (c, cl, y0, cuello) in enumerate((('#2a6a3a', '#4a9a5a', 0, 2), ('#c8962a', '#f0c860', 1, 1), ('#c8dce4', '#ffffff', 0, 2), ('#7a2a3a', '#b04a5a', 1, 1))):
        x = 1 + i * 4
        L.r(x, y0 + 2, 3, 4 - y0, c); L.p(x + 1, y0, c); L.p(x + 1, y0 + 1, c); L.vl(x, y0 + 2, 5, cl); L.p(x + 1, 4, '#f4f4ee')
    for i, (c, cl) in enumerate((('#b0b8c0', '#ffffff'), ('#d07a2a', '#f0a050'), ('#2a3a6a', '#4a5a9a'), ('#c8962a', '#f0c860'))):
        x = 1 + i * 4
        L.r(x, 8, 3, 3, c); L.vl(x, 8, 10, cl); L.p(x + 1, 6, c); L.p(x + 1, 7, c); L.p(x + 1, 9, '#f4f4ee')
    return L

sale('d-seto', d_seto(), 'detalle-16')
sale('d-shelfW-shop', d_shelf(botes_abono), 'detalle-16')
sale('d-shelfW-growcity', d_shelf(botes_abono), 'detalle-16')
sale('d-shelfW-comisaria', d_shelf(archivadores), 'detalle-16')
sale('d-sacos', d_sacos(), 'detalle-16')
sale('d-bottles', d_bottles(), 'detalle-16')

# ---------------------------------------------------------------------------------------------------------- mostradores (32 × 48)
X0, X1 = 8, 23   # lo dibujado, de x 8 a 23 (una casilla): los tramos casan de uno a otro
def mostrador(tapa, tapa_c, frente, frente_o, frente_c, zocalo, extra=None):
    """el mostrador de 1 m: la tapa a medio fondo (3 filas), el frente en paneles y el zócalo; el tramo casa por los lados"""
    L = Lienzo(32, 48)
    L.r(X0, 27, 16, 3, tapa); L.hl(X0, X1, 27, tapa_c); L.hl(X0, X1, 30, frente_o)
    L.r(X0, 31, 16, 14, frente); L.vl(X1, 31, 44, frente_o); L.vl(X0, 31, 44, frente_c)
    L.r(X0 + 2, 33, 12, 10, frente_c); L.r(X0 + 3, 34, 10, 8, frente)   # el panel con su moldura
    L.r(X0, 45, 16, 3, zocalo); L.hl(X0, X1, 47, '#1e1e26')
    if extra: extra(L)
    return L

def caja_reg(L, cuerpo='#5a5e66'):
    L.r(10, 21, 9, 6, cuerpo); L.hl(10, 18, 21, '#7a7e86'); L.r(11, 22, 4, 2, '#7ad0a0')   # la caja registradora, con la pantalla
    for x in (16, 17): L.p(x, 22, '#d0d4d8'); L.p(x, 24, '#d0d4d8')
    L.r(10, 25, 9, 2, '#3a3c44'); L.p(13, 26, '#f0c838')

def botes_mostrador(L):
    for i, (c, cl) in enumerate((('#3a9a4a', '#6ac87a'), ('#d06a2a', '#f09a5a'), ('#5a6ad0', '#8a9af0'))):
        x = 10 + i * 4
        L.r(x, 21, 3, 6, c); L.vl(x, 21, 26, cl); L.r(x, 19, 3, 2, '#2a2a34'); L.r(x, 23, 3, 2, '#f4f4ee')

def sobres(L):
    L.r(10, 17, 12, 10, '#e8e4d8'); L.vl(10, 17, 26, '#bcb4a2'); L.hl(10, 21, 17, '#ffffff')   # el expositor de los sobres
    for j in range(2):
        for i in range(3):
            c = ('#3a9a4a', '#a04ac0', '#d0a030', '#3a7ad0', '#d05050', '#4ac0a0')[i + j * 3]
            L.r(11 + i * 4, 18 + j * 4, 3, 3, c); L.p(12 + i * 4, 19 + j * 4, '#f4f4ee')

def papeles(L):
    L.r(10, 23, 7, 4, '#f4f4ee'); L.hl(10, 16, 23, '#ffffff'); L.hl(11, 15, 25, '#a8b0c0'); L.r(9, 26, 9, 1, '#d8d8d0')   # la pila de papeles
    L.r(18, 23, 3, 2, '#c03a3a'); L.r(19, 21, 1, 2, '#62402a')                                                       # el sello

def monitor(L):
    L.r(10, 17, 12, 9, '#3a3c44'); L.hl(10, 21, 17, '#5a5e66'); L.r(11, 18, 10, 7, '#2a2c34')   # el monitor de espaldas
    L.r(15, 26, 2, 1, '#5a5e66')

def bandeja(L):
    L.r(10, 24, 11, 3, '#c8a040'); L.hl(10, 20, 24, '#f0c860')   # la bandeja de documentos
    L.r(11, 22, 8, 2, '#f4f4ee'); L.hl(11, 18, 22, '#ffffff')

def grifos(L):
    L.r(9, 18, 14, 2, CROMO); L.hl(9, 22, 18, CROMOL)   # la barra de los grifos
    for x, c in ((11, '#c03a3a'), (16, '#3a7ad0'), (20, '#f0c838')):
        L.r(x, 13, 2, 5, c); L.p(x, 13, '#ffffff')   # la palanca
        L.r(x, 20, 2, 3, CROMOD); L.p(x, 22, CROMO)   # el caño
    L.r(9, 26, 14, 1, '#3a3c44')   # el escurridor

def canas(L):
    for x in (10, 15):   # dos cañas
        L.r(x, 19, 4, 7, '#f0b040'); L.vl(x, 19, 25, '#f8d880'); L.r(x, 18, 4, 2, '#fcfcf4'); L.vl(x + 3, 19, 25, '#c88a20')
    L.r(20, 22, 2, 4, '#ffffff'); L.p(20, 21, '#e8e8e0'); L.p(21, 21, '#e8e8e0')   # el servilletero

def pintxos(L):
    L.r(9, 25, 14, 2, '#e8e8e0'); L.hl(9, 22, 25, '#ffffff')   # la fuente
    for x, c in ((10, '#d8a050'), (14, '#5a8a3a'), (18, '#c05040')):
        L.r(x, 22, 3, 3, '#f0d8a0'); L.r(x, 21, 3, 1, c); L.p(x + 1, 19, '#a87646'); L.p(x + 1, 20, '#a87646')   # el pan, lo de encima y el palillo

def cubitera(L):
    L.r(10, 21, 7, 6, CROMO); L.vl(10, 21, 26, CROMOL); L.vl(16, 21, 26, CROMOD); L.hl(10, 16, 21, '#e0f4f8')   # la cubitera
    L.r(12, 14, 3, 8, '#2a5a3a'); L.vl(12, 14, 21, '#4a8a5a'); L.r(12, 13, 3, 2, '#f0c838')                     # la botella con el papel dorado
    L.r(18, 23, 3, 4, VID); L.p(19, 22, VIDL); L.p(18, 26, '#ffffff')                                            # un vaso

def cocteles(L):
    for x, c in ((10, '#e04a8a'), (16, '#4ac0e0')):
        L.hl(x, x + 4, 19, VIDL); L.hl(x + 1, x + 3, 20, c); L.p(x + 2, 21, c)   # la copa en V
        L.vl(x + 2, 22, 25, VID); L.hl(x + 1, x + 3, 26, VID)
        L.p(x + 4, 17, '#f0f0f4'); L.p(x + 3, 18, '#f0f0f4')                      # la pajita
    L.p(13, 20, '#f0c838')

def coctelera(L):
    L.r(11, 18, 4, 9, CROMO); L.vl(11, 18, 26, CROMOL); L.vl(14, 18, 26, CROMOD); L.r(12, 16, 2, 2, CROMOD)   # la coctelera
    L.r(17, 22, 4, 5, VID); L.vl(17, 22, 26, VIDL); L.r(18, 23, 2, 2, '#f0a030')                               # un vaso con hielo
    L.p(18, 21, '#ffffff')

# el grow de Kiko: madera con la franja verde; GROW IBARBIDE: blanco con el verde
def tramos(nombre, piezas, *colores, franja=None):
    for i, f in enumerate(piezas):
        def extra(L, f=f):
            if franja: L.r(X0, 31, 16, 2, franja); L.hl(X0, X1, 31, '#9ae08a')
            f(L)
        sale('%s-%d' % (nombre, i), mostrador(*colores, extra=extra), 'detalle-alto')

tramos('d-counter-shop', (caja_reg, botes_mostrador, sobres), '#c8a070', '#e0bc8a', '#8a5a32', '#62402a', '#a0703e', '#3a2a1c', franja='#3a9a4a')
tramos('d-counter-growcity', (caja_reg, botes_mostrador, sobres), '#f0f0ec', '#ffffff', '#e0e0dc', '#a8aca8', '#f4f4f0', '#3a3c44', franja='#3a9a4a')
tramos('d-counter-comisaria', (papeles, monitor, bandeja), '#d8d0c0', '#ece6d6', '#7a8290', '#5a6270', '#8a929e', '#2a2e36')
tramos('d-barcounter', (grifos, canas, pintxos), '#6a4a2a', '#8a6a42', '#4a2e1c', '#2e1c10', '#62402a', '#c8a040')

def barra_disco(f):
    def extra(L):
        L.hl(X0, X1, 31, '#4af0f0'); L.hl(X0, X1, 32, '#2aa0b0')   # el neón del canto
        L.r(X0, 41, 16, 1, '#a04ae0')                                # la luz de abajo
        f(L)
    return mostrador('#24202e', '#3a3448', '#16141c', '#0a0a10', '#1e1a26', '#a04ae0', extra=extra)
for i, f in enumerate((cubitera, cocteles, coctelera)):
    sale('d-barraD-%d' % i, barra_disco(f), 'detalle-alto')

def vitrina_grow(k):
    """la vitrina de 1 m del grow: el mueble de madera y la urna de cristal con lo que se vende dentro, iluminada"""
    L = Lienzo(32, 48)
    L.r(X0, 36, 16, 12, '#8a5a32'); L.vl(X0, 36, 47, '#a0703e'); L.vl(X1, 36, 47, '#62402a'); L.hl(X0, X1, 47, '#3a2a1c')
    L.r(X0 + 3, 38, 10, 7, '#a0703e'); L.r(X0 + 4, 39, 8, 5, '#8a5a32')
    L.r(X0, 19, 16, 17, '#c8e8f0'); L.r(X0 + 1, 20, 14, 15, '#e8f6fa')                               # la urna
    L.hl(X0, X1, 19, CROMO); L.vl(X0, 19, 35, CROMOD); L.vl(X1, 19, 35, CROMOD); L.hl(X0, X1, 27, CROMO)   # el marco y la balda
    L.hl(X0 + 1, X1 - 1, 20, '#ffffff')                                                                # la luz de dentro
    if k == 0:
        for i, c in enumerate(('#3a9a4a', '#a04ac0', '#d0a030')):   # los sobres de semillas, de pie
            L.r(X0 + 2 + i * 4, 22, 3, 5, c); L.r(X0 + 3 + i * 4, 23, 1, 2, '#f4f4ee')
        L.r(X0 + 3, 31, 4, 4, '#5aa04a'); L.hl(X0 + 3, X0 + 6, 31, '#84cc6c')            # un grinder
        L.r(X0 + 9, 29, 3, 6, '#5a6ad0'); L.r(X0 + 9, 28, 3, 1, '#2a2a34'); L.r(X0 + 9, 31, 3, 2, '#f4f4ee')   # un bote
    else:
        L.r(X0 + 2, 22, 3, 5, '#d06a2a'); L.r(X0 + 2, 21, 3, 1, '#2a2a34'); L.r(X0 + 2, 23, 3, 2, '#f4f4ee')  # botes de abono
        L.r(X0 + 6, 22, 3, 5, '#3a9a4a'); L.r(X0 + 6, 21, 3, 1, '#2a2a34'); L.r(X0 + 6, 23, 3, 2, '#f4f4ee')
        L.r(X0 + 11, 21, 2, 6, '#4a4c54'); L.p(X0 + 11, 22, '#7ad0a0')                                    # el medidor de pH
        L.r(X0 + 2, 31, 10, 4, '#f0f0ec'); L.hl(X0 + 2, X0 + 11, 31, '#3a9a4a')                          # una caja de tamices
        L.r(X0 + 4, 32, 6, 2, '#d8e8d8')
    L.p(X0 + 13, 21, '#ffffff'); L.p(X0 + 12, 22, '#ffffff')   # el brillo del cristal
    L.contorno(K)
    return L
for i in range(2):
    sale('d-display-%d' % i, vitrina_grow(i), 'detalle-alto')

def caja_madera():
    """una caja de madera de 60 cm, abierta, con lo que trae: piezas y una bolsa, sobre la paja"""
    L = Lienzo(32, 48)
    L.r(X0 + 1, 34, 14, 14, '#b88a52')
    for y in (36, 41, 46): L.hl(X0 + 1, X0 + 14, y, '#8a6236')                       # las tablas
    L.vl(X0 + 1, 34, 47, '#8a6236'); L.vl(X0 + 14, 34, 47, '#8a6236'); L.vl(X0 + 7, 37, 45, '#a07a46')
    L.r(X0 + 2, 32, 12, 2, '#e0c070'); L.p(X0 + 3, 31, '#e0c070'); L.p(X0 + 11, 31, '#f0d890')        # la paja
    L.r(X0 + 3, 29, 4, 4, '#8a8e96'); L.hl(X0 + 3, X0 + 6, 29, '#c8ccd0'); L.p(X0 + 4, 31, '#5a5e66')  # una pieza de metal
    L.r(X0 + 8, 27, 5, 6, '#4a6a9a'); L.hl(X0 + 8, X0 + 12, 27, '#6a8aba'); L.p(X0 + 10, 26, '#2a3a5a')   # una bolsa
    L.r(X0 + 4, 39, 7, 2, '#3a3c44')                                                                      # la plantilla, sin letras
    L.contorno(K)
    return L

def cajas_pescado():
    """dos cajas de pescado de plástico, una encima de otra; la de arriba, abierta (se ve por dentro, a 3/4), con hielo y dos
    pescados (genéricos: el lomo azulado, la tripa plateada, el ojo y la cola)"""
    L = Lienzo(32, 48)
    for y0, c, co in ((39, '#3a7ad0', '#2a5aa0'), (31, '#e8ecf0', '#a8b0bc')):
        L.r(X0, y0, 16, 8 if y0 == 39 else 8, c); L.hl(X0, X1, y0, co); L.hl(X0, X1, y0 + 7, co)
        L.r(X0 + 2, y0 + 3, 3, 2, co); L.r(X0 + 11, y0 + 3, 3, 2, co)   # las asas
    L.r(X0, 47, 16, 1, '#1e3a6a')
    L.r(X0, 25, 16, 6, '#c8ccd4'); L.r(X0 + 1, 26, 14, 5, '#e8f6fa')   # la boca de la caja, por dentro, llena de hielo
    for (x, y) in ((X0 + 2, 29), (X0 + 9, 30), (X0 + 13, 27), (X0 + 5, 30)): L.p(x, y, '#ffffff')
    for x0, y0, d in ((X0 + 2, 26, 1), (X0 + 6, 28, -1)):
        xs = range(x0, x0 + 8)
        for k, x in enumerate(xs):
            L.p(x, y0, '#3a5a8a'); L.p(x, y0 + 1, '#c8d4e0')   # el lomo y la tripa
        cab, cola = (x0 + 7, x0) if d > 0 else (x0, x0 + 7)
        L.p(cab, y0, '#2a2a34'); L.p(cab, y0 + 1, '#e8a0a0')                  # el ojo y la agalla
        L.p(cola - d, y0 - 1, '#3a5a8a'); L.p(cola - d, y0 + 2, '#3a5a8a')     # la cola
    L.contorno(K)
    return L

sale('d-crate', caja_madera(), 'detalle-alto')
sale('d-crate-puerto', cajas_pescado(), 'detalle-alto')
sale('d-crate-astilleros', cajas_pescado(), 'detalle-alto')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.size, len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
