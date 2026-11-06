# python3 -I tools/sprites/a-mano/concesionario.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# 1.43 (lo pidió el usuario): el concesionario del barrio alto, AUTOS RIBERA (un nombre inventado: sin marcas ni logos), y las
# bandejas de clones de la nave, dibujados a mano a 16 px/m como los locales (locales.py).
#  · La fachada (8 × 6 casillas): la cubierta plana con el peto y las máquinas, la banda azul con el rótulo, el escaparate de
#    cristal con los coches dentro y la puerta corredera de cristal de 2 casillas (recorte en x 48, y 64; corredera).
#  · Suelos y paredes: el porcelánico pulido de 60 × 60 con sus brillos, la pared de panel gris con la franja azul y el zócalo.
#  · Objetos: el rótulo de la pared (2 casillas), los carteles de precios, la pila de neumáticos, el expositor de folletos, la
#    máquina de café, la bandera de la entrada, el mostrador con el monitor y, en la nave, el estante de las bandejas de clones
#    (clonN-0 apagado, 1 con la balda de abajo y 2 con las dos, bajo sus tubos T5).
#  · Los coches de la exposición, de perfil a 16 px/m (celda de 5 casillas, la base en la de la izquierda): la moto de 125 cc
#    (2 m), el utilitario de 5 puertas (4 m), la berlina (4,8 m) y el deportivo (4,6 m, bajo, sobre la plataforma giratoria).
# Sale a art/crudo/<grupo>/<sprite>/unica/NN.png (después, node tools/sprites/procesar.js <grupos> --atlas).
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar
from mundo import puertas
from salon import suelo

K = '#2a2a34'                     # el contorno de los muebles (el de salon.py)
SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

LETRA = {'A': '111101111101101', 'U': '101101101101111', 'T': '111010010010010', 'O': '111101101101111', 'S': '111100111001111',
         'R': '110101110101101', 'I': '111010010010111', 'B': '110101110101110', 'E': '111100110100111', '%': '101001010100101',
         '0': '111101101101111', '1': '010110010010111', '2': '110001010100111', '3': '110001010001110', '9': '111101111001110',
         '€': '011100110100011', '.': '000000000000010'}
def rotulo(lz, x, y, txt, c):
    for ch in txt:
        if ch == ' ':
            x += 2; continue
        m = LETRA[ch]
        for j in range(5):
            for i in range(3):
                if m[j * 3 + i] == '1': lz.p(x + i, y + j, c)
        x += 4
    return x

def ancho(txt):
    return sum(2 if ch == ' ' else 4 for ch in txt) - 1

AZUL = ('#1e3a6a', '#2c5aa0', '#4a7ac8', '#8ab0e0')
CRIS = ('#3a4a5a', '#56708a', '#8aa8c0', '#c8dcec')     # el cristal: oscuro, medio, claro y el reflejo
ALU = ('#6c7482', '#9aa3ad', '#c8ccd0', '#e8ecf0')

# ---------------------------------------------------------------------------------------------------------- los coches
def rueda(L, cx, cy, r, llanta='#b8bec8'):
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = (x - cx) ** 2 + (y - cy) ** 2
            if d <= r * r + r: L.p(x, y, '#1e2026')
            if d <= (r - 2) ** 2 + 1: L.p(x, y, llanta)
    L.p(cx, cy, '#5a606c')
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        if r >= 4: L.p(cx + 2 * dx, cy + 2 * dy, '#7a8290')

def coche(L, x0, perfil, carro, cristal_y, ruedas, r, pintura, faro=True, techo=None):
    """un coche de perfil mirando a la derecha: perfil = [(x, y_arriba)] de la carrocería por columnas (de x0 en adelante, hasta
    la base 44); pintura = (sombra, medio, claro, brillo). Las ventanas, entre cristal_y y la línea de cintura (carro)"""
    S0, S1, S2, S3 = pintura
    xs = [p[0] for p in perfil]
    for i in range(len(perfil) - 1):
        (xa, ya), (xb, yb) = perfil[i], perfil[i + 1]
        for x in range(xa, xb):
            t = (x - xa) / max(1, xb - xa)
            y = round(ya + (yb - ya) * t)
            L.vl(x, y, 43, S1)
            L.p(x, y, S3 if y < carro else S2)
    xe = xs[-1]
    for x in range(xs[0], xe):
        L.p(x, 43, S0); L.p(x, 42, S0)                                # los bajos
        if L.lleno(x, carro): L.p(x, carro, S2)                       # la línea de cintura, con brillo
        if L.lleno(x, carro + 1): L.p(x, carro + 1, S3)
    # las ventanas: lo que queda por encima de la cintura y por debajo del techo, en cristal, con el pilar central
    for x in range(xs[0] + 1, xe - 1):
        for y in range(cristal_y, carro):
            if L.lleno(x, y) and L.lleno(x, y - 1) and L.lleno(x - 1, y) and L.lleno(x + 1, y):
                L.p(x, y, CRIS[1] if (x + y) % 7 else CRIS[3])
    if techo:
        for x in techo: L.vl(x, cristal_y - 1, carro - 1, S0)       # los pilares
    for (cx, cy) in ruedas:                                          # los pasos de rueda y las ruedas
        for y in range(cy - r - 1, 44):
            for x in range(cx - r - 1, cx + r + 2):
                if (x - cx) ** 2 + (y - cy) ** 2 <= (r + 1) ** 2 + r: L.p(x, y, '#141418')
        rueda(L, cx, cy, r)
    if faro:
        L.r(xe - 3, carro + 2, 2, 2, '#f8f4d8'); L.p(xe - 1, carro + 2, '#e8e0a0')   # el faro
        L.r(xs[0] + 1, carro + 2, 2, 2, '#c03028')                                   # el piloto
    L.contorno(K)
    for x in range(xs[0] - 1, xe + 2):                                # la sombra en el suelo
        if not L.lleno(x, 46): L.p(x, 46, '#3a3a44')

def utilitario():
    """el utilitario de 5 puertas (4,0 m: 64 px; 1,5 m de alto), blanco hielo, con el portón trasero casi vertical"""
    L = Lienzo(80, 48)
    perfil = [(6, 33), (8, 26), (12, 23), (34, 22), (44, 23), (52, 29), (64, 31), (69, 33), (70, 40)]
    coche(L, 6, perfil, 31, 24, ((17, 41), (58, 41)), 4, ('#9aa0a8', '#d8dde4', '#eef2f6', '#ffffff'), techo=(33,))
    return L

def berlina():
    """la berlina diésel (4,8 m: 77 px; 1,45 m), gris plomo metalizado, con el maletero escalonado"""
    L = Lienzo(80, 48)
    perfil = [(1, 32), (3, 29), (12, 28), (20, 22), (44, 21), (54, 28), (68, 30), (76, 32), (77, 40)]
    coche(L, 1, perfil, 30, 23, ((15, 41), (63, 41)), 4, ('#2a2e36', '#4a505c', '#6a7280', '#a8b0bc'), techo=(37,))
    return L

def deportivo():
    """el deportivo (4,6 m: 74 px; 1,15 m), rojo, bajo y en cuña, con el alerón; encima de la plataforma giratoria"""
    L = Lienzo(80, 48)
    for x in range(1, 79):                                           # la plataforma: un disco gris claro visto de canto
        L.p(x, 44, '#c8ccd0'); L.p(x, 45, '#8a8e96')
    L.hl(4, 75, 43, '#e8ecf0')
    perfil = [(3, 33), (5, 30), (16, 29), (26, 24), (40, 23), (52, 30), (72, 34), (76, 36), (77, 40)]
    coche(L, 3, perfil, 33, 25, ((16, 40), (62, 40)), 4, ('#6a1418', '#b8202a', '#e04048', '#ff9890'), techo=())
    L.r(2, 27, 8, 2, '#1e2026'); L.vl(5, 29, 31, '#1e2026')          # el alerón
    for x in (30, 33, 36): L.p(x, 37, '#1e2026')                      # la toma de aire
    return L

def moto():
    """la moto de 125 cc, scooter (2 m: 32 px; 1,15 m), negra con el escudo azul, sobre su caballete"""
    L = Lienzo(80, 48)
    rueda(L, 10, 41, 4); rueda(L, 31, 41, 4)
    N0, N1, N2 = '#1e2026', '#3a3e48', '#5a606c'
    L.r(8, 33, 18, 5, N1); L.hl(8, 25, 33, N2)                       # el carenado de atrás y la plataforma
    L.r(12, 30, 11, 3, N0); L.hl(12, 22, 30, N2)                     # el asiento
    L.r(24, 25, 6, 13, AZUL[1]); L.vl(24, 25, 37, AZUL[0]); L.vl(29, 25, 37, AZUL[2])   # el escudo
    L.vl(29, 20, 25, N2); L.hl(27, 32, 20, N0); L.p(33, 20, '#c8ccd0')                  # el manillar y el espejo
    L.r(29, 22, 3, 2, '#f8f4d8')                                     # el faro
    L.vl(31, 26, 37, ALU[1])                                         # la horquilla
    L.p(7, 34, '#c03028'); L.p(7, 35, '#c03028')                     # el piloto
    L.contorno(K)
    for x in range(4, 37):
        if not L.lleno(x, 46): L.p(x, 46, '#3a3a44')
    return L

# ---------------------------------------------------------------------------------------------------------- la fachada
def fachada():
    """AUTOS RIBERA (8 × 6): cubierta plana con el peto y dos máquinas de clima, banda azul con el rótulo, escaparate de cristal con
    dos coches dentro, la puerta corredera de cristal (casillas 3-4) y el zócalo de piedra artificial"""
    lz = Lienzo(128, 96); R = azar(71)
    G0, G1, G2 = '#8a8e96', '#a8acb4', '#c0c4ca'
    lz.r(0, 0, 128, 22, G1)                                         # la cubierta, de grava
    for _ in range(260):
        x, y = int(R() * 128), int(R() * 21)
        lz.p(x, y, G0 if R() < .5 else G2)
    lz.r(0, 0, 128, 2, '#d8dce0'); lz.r(0, 0, 2, 22, '#d8dce0'); lz.r(126, 0, 2, 22, '#d8dce0')   # el peto
    for mx in (16, 92):                                             # las máquinas del clima
        lz.caja(mx, 6, 18, 11, '#dfe3e8', '#6c7482'); lz.r(mx + 2, 8, 8, 7, '#8a8e96')
        for yy in range(8, 15, 2): lz.hl(mx + 2, mx + 9, yy, '#5a606c')
        lz.r(mx + 12, 9, 4, 4, '#b8bcc4')
    lz.r(0, 22, 128, 3, '#d8dce0'); lz.hl(0, 127, 25, '#8a8e96')    # el canto del forjado
    lz.r(0, 26, 128, 14, AZUL[1]); lz.hl(0, 127, 26, AZUL[2]); lz.hl(0, 127, 39, AZUL[0])   # la banda con el rótulo
    t = 'AUTOS RIBERA'
    rotulo(lz, (128 - ancho(t)) // 2, 30, t, '#f4f4ee')
    lz.hl((128 - ancho(t)) // 2, (128 + ancho(t)) // 2, 36, AZUL[3])
    lz.r(0, 40, 128, 50, '#e8ecf0')                                 # el panel blanco
    for (x, w) in ((4, 40), (84, 40)):                              # el escaparate, con un coche dentro de cada lado
        lz.caja(x, 44, w, 42, CRIS[0], ALU[0])
        lz.r(x + 1, 45, w - 2, 40, CRIS[1])
        lz.r(x + 1, 70, w - 2, 15, '#8a8e96')                         # el suelo de dentro
        c = '#b8202a' if x < 50 else '#d8dde4'
        lz.r(x + 6, 66, w - 12, 8, c); lz.r(x + 12, 61, w - 24, 5, c); lz.r(x + 13, 62, w - 26, 3, CRIS[2])
        for wx in (x + 10, x + w - 11): lz.r(wx, 72, 5, 4, '#1e2026')
        lz.vl(x + w // 2, 45, 84, ALU[1])                             # el montante
        for k in range(5): lz.p(x + 3 + k, 47 + k, CRIS[3]); lz.p(x + w // 2 + 4 + k, 48 + k, CRIS[3])   # los reflejos
    lz.caja(48, 62, 32, 28, CRIS[0], ALU[0])                        # la puerta corredera, de dos hojas de cristal
    lz.r(49, 63, 30, 26, CRIS[1]); lz.vl(63, 63, 88, ALU[1]); lz.vl(64, 63, 88, ALU[1])
    for k in range(5): lz.p(52 + k, 66 + k, CRIS[3]); lz.p(68 + k, 66 + k, CRIS[3])
    lz.r(48, 58, 32, 4, ALU[1]); lz.hl(48, 79, 58, ALU[2])           # el cajón del motor de la puerta
    lz.r(0, 90, 128, 6, '#b8b2a6'); lz.hl(0, 127, 90, '#d8d2c6'); lz.hl(0, 127, 95, '#8a8478')   # el zócalo
    return lz, puertas(lz, 48, 64, (1, 0, 30, 25), 'doble')

# ---------------------------------------------------------------------------------------------------------- suelo y paredes
def floorK():
    """el porcelánico pulido de 60 × 60 (casi 10 px): gris perla con la junta fina y un brillo en diagonal"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#dcdfe4')
    L.hl(0, 15, 0, '#c4c8ce'); L.vl(0, 0, 15, '#c4c8ce'); L.hl(0, 15, 8, '#c8ccd2'); L.vl(8, 0, 15, '#c8ccd2')
    for k in range(4): L.p(3 + k, 5 - k, '#f0f2f6'); L.p(11 + k, 13 - k, '#f0f2f6')
    return L

def iwT_conce():
    """la pared de arriba: el falso techo con los downlights y el panel gris claro"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#d8dce2')
    L.r(0, 0, 16, 4, '#f0f2f4'); L.hl(0, 15, 4, '#a8acb4')
    L.r(7, 1, 3, 2, '#fff8d8')                                      # el downlight
    L.vl(15, 5, 15, '#c4c8ce')
    return L

def iwB_conce():
    """la pared de abajo: la franja azul y el zócalo de aluminio"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#d8dce2')
    L.r(0, 4, 16, 3, AZUL[1]); L.hl(0, 15, 4, AZUL[2])
    L.vl(15, 0, 12, '#c4c8ce')
    L.r(0, 13, 16, 3, ALU[1]); L.hl(0, 15, 13, ALU[2])
    return L

# ---------------------------------------------------------------------------------------------------------- objetos
def rotuloK():
    """el rótulo de la pared (2 casillas, como la foto de la asociación): AUTOS en grande y RIBERA debajo, en una placa azul"""
    L = Lienzo(48, 48)
    L.caja(7, 22, 34, 16, AZUL[1], AZUL[0]); L.hl(8, 39, 23, AZUL[2])
    rotulo(L, 24 - ancho('AUTOS') // 2, 25, 'AUTOS', '#f4f4ee')
    rotulo(L, 24 - ancho('RIBERA') // 2, 31, 'RIBERA', AZUL[3])
    L.contorno(K)
    return L

def preciosK():
    """el cartel de la oferta: un coche en silueta y el «0 %» de la financiación"""
    L = Lienzo(16, 16)
    L.r(2, 1, 12, 13, '#f4f4ee'); L.r(2, 1, 12, 3, AZUL[1])
    L.r(4, 6, 8, 2, '#b8202a'); L.r(6, 5, 4, 1, '#b8202a'); L.p(5, 8, K); L.p(10, 8, K)
    rotulo(L, 4, 9, '0', '#2a2a34'); rotulo(L, 8, 9, '%', '#c03028')
    L.contorno(K)
    return L

def ruedasK():
    """cuatro neumáticos apilados, de canto: la goma negra con el dibujo y el canto de la llanta asomando"""
    L = Lienzo(16, 16)
    for i in range(4):
        y = 13 - i * 3
        L.r(3, y - 1, 10, 3, '#1e2026'); L.hl(4, 11, y - 1, '#3a3e48')
        for x in range(4, 12, 2): L.p(x, y, '#2e3038')
    L.r(5, 2, 6, 1, '#7a8290')
    L.contorno(K)
    return L

def catalogoK():
    """el expositor de folletos: la columna de aluminio con tres bolsillos"""
    L = Lienzo(16, 16)
    L.vl(7, 4, 15, ALU[0]); L.vl(8, 4, 15, ALU[1]); L.hl(5, 10, 15, ALU[0])
    for i, y in enumerate((2, 6, 10)):
        L.r(4, y, 8, 4, (AZUL[1], '#b8202a', '#d8dde4')[i]); L.hl(4, 11, y, '#f4f4ee'); L.r(4, y + 3, 8, 1, ALU[2])
    L.contorno(K)
    return L

def cafeK():
    """la máquina de café de la sala (1,8 m): la columna negra, la pantalla, los botones y el hueco del vaso"""
    L = Lienzo(32, 32)
    L.r(10, 3, 12, 28, '#2a2c32'); L.vl(21, 3, 30, '#1a1c20'); L.hl(10, 21, 3, '#4a4e56')
    L.r(12, 6, 8, 5, '#6f9fc4'); L.hl(13, 18, 8, '#c8dcec')           # la pantalla
    for y in (13, 15, 17):
        L.p(13, y, '#e0b040'); L.p(15, y, '#e8ecf0'); L.p(17, y, '#e8ecf0')
    L.r(13, 21, 6, 6, '#141418'); L.r(15, 24, 2, 3, '#f4f4ee')       # el hueco y el vaso
    L.contorno(K)
    return L

def banderaK():
    """la bandera de la entrada (3 m): el mástil y la banderola vertical azul con la franja blanca"""
    L = Lienzo(32, 32)
    L.vl(15, 0, 31, ALU[0]); L.vl(16, 0, 31, ALU[2]); L.hl(13, 18, 31, ALU[0])
    L.r(17, 1, 7, 18, AZUL[1]); L.vl(23, 1, 18, AZUL[0]); L.r(17, 7, 7, 3, '#f4f4ee')
    L.hl(17, 23, 1, AZUL[2])
    L.contorno(K)
    return L

def mesaK():
    """el mostrador (2 casillas): el frente blanco con la franja azul, el tablero gris y el monitor con el teclado"""
    L = Lienzo(48, 48); x0, x1 = 9, 38
    L.r(x0, 35, 30, 12, '#eef0f4'); L.hl(x0, x1, 35, '#d8dce2'); L.r(x0, 40, 30, 2, AZUL[1])
    L.r(x0 - 1, 33, 32, 2, '#8a8e96'); L.hl(x0 - 1, x1 + 1, 33, '#b8bcc4')
    L.r(26, 24, 10, 7, '#1e2026'); L.r(27, 25, 8, 5, '#4a7ac8'); L.hl(28, 33, 26, '#8ab0e0'); L.vl(30, 31, 32, '#3a3e48')   # el monitor
    L.r(14, 31, 8, 2, '#f4f4ee'); L.hl(15, 20, 31, '#c8ccd0')        # los papeles
    L.contorno(K)
    suelo(L, x0, x1, K)
    return L

# ---------------------------------------------------------------------------------------------------------- la nave
def clonN(n):
    """el estante de las bandejas de clones de la nave (2 m, 2 casillas): dos baldas, cada una con su tubo T5 y dos bandejas de
    alvéolos con la tapa; con n = 1 la de abajo llena, con 2 las dos, y los tubos encendidos (18/6) si hay alguna"""
    L = Lienzo(48, 48); M0, M1, M2 = '#4a525a', '#8c98a2', '#bcc6ce'
    x0, x1 = 9, 38
    on = n > 0
    for x in (x0, x1): L.vl(x, 20, 46, M0)
    for i, y in enumerate((21, 33)):
        lleno = (i == 1 and n >= 1) or (i == 0 and n >= 2)
        L.hl(x0 + 1, x1 - 1, y, M1); L.hl(x0 + 2, x1 - 2, y + 1, '#f4f8ec' if on else '#9aa0a8')   # el tubo T5
        if on:
            L.hl(x0 + 2, x1 - 2, y + 2, '#e4ecd8')
        for (a, b) in ((x0 + 2, x0 + 14), (x0 + 16, x1 - 2)):
            L.r(a, y + 9, b - a + 1, 2, '#1c1c22'); L.hl(a, b, y + 9, '#3a3c44')   # la bandeja
            L.hl(a + 1, b - 1, y + 4, '#c8dcf0'); L.vl(a, y + 5, y + 8, '#a8c0d8'); L.vl(b, y + 5, y + 8, '#a8c0d8')   # la tapa
            L.p(a + 2, y + 5, '#e8f4ff')
            if lleno:
                for x in range(a + 2, b - 1, 2):
                    L.p(x, y + 8, '#3f8a46'); L.p(x, y + 7, '#6ab04a' if (x // 2) % 2 else '#3f8a46')
        L.hl(x0, x1, y + 11, M2); L.hl(x0, x1, y + 12, M1)            # la balda
    L.contorno(K)
    suelo(L, x0, x1, K)
    return L

b, ps = fachada()
sale('base', b, 'edificio-conce')
for i, p in enumerate(ps): sale(f'puerta{i:02d}', p, 'edificio-conce')
for n, f in (('floorK', floorK), ('iwT_conce', iwT_conce), ('iwB_conce', iwB_conce)):
    sale(n, f(), 'interior-locales')
for n, f in (('preciosK', preciosK), ('ruedasK', ruedasK), ('catalogoK', catalogoK)):
    sale(n, f(), 'locales-16')
for n, f in (('cafeK', cafeK), ('banderaK', banderaK)):
    sale(n, f(), 'locales-alto')
for n, f in (('rotuloK', rotuloK), ('mesaK', mesaK)):
    sale(n, f(), 'locales-ancho')
for i in range(3): sale(f'clonN-{i}', clonN(i), 'locales-ancho')
for n, f in (('expoU', utilitario), ('expoM', berlina), ('expoS', deportivo), ('expoMo', moto)):
    sale(n, f(), 'conce-expo')

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
