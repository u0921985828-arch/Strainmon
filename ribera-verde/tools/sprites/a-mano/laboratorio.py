# python3 -I tools/sprites/a-mano/laboratorio.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# El laboratorio del banco de semillas de la tía (lo pidió el usuario: «El laboratorio debe parecer un laboratorio de verdad, no los
# materiales de labo y ya, las normas que tienes que tener en un laboratorio real»): la sala lab-rv a 16 px/m y de frente a 3/4,
# como los demás muebles (nunca isométrico). Genérico, sin marcas ni letras; los carteles, con pictogramas.
#  · interior-lab (casillas de 16 × 16): floorLab (el vinilo continuo, sin juntas, gris claro), floorLabL (con la línea amarilla de
#    seguridad a la izquierda: la antesala y la zona de trabajo), iwT_lab / iwB_lab (el azulejo blanco y, abajo, la media caña)
#  · lab-alto (mueble_escala, 32 × 48, base en (16, 47)): de pared (fila 1), labNormas (el cartel de las normas: bata, gafas y
#    guantes obligatorios; no comer, no beber, no fumar), labBotiquin, labLavaojos (el lavaojos de emergencia con su señal verde) y
#    labExtintor (el de CO2 con su señal); de suelo, labPercha (las batas, las gafas y la caja de guantes), labPila (el lavamanos
#    de pedal con el jabón y el papel), labDucha (la ducha de emergencia, del techo, con su tirador), labAutoclave (el de 50 L, con
#    el manómetro), labEstufa (la estufa de germinación con las placas), labNevera (la nevera de muestras con la señal amarilla),
#    labResiduos (el contenedor amarillo de residuos biológicos y el de cortantes) y puertaLab / puertaLabP (la puerta blanca con
#    su ventanuco y las señales de EPI; precintada, con la cinta)
#  · lab-ancho (mueble_ancho, 48 × 48): labFlujo (la cabina de flujo laminar de 150 cm), labMicro (la poyata del microscopio, de
#    resina negra con los armarios blancos) y labBalanza (la de la balanza de precisión con su urna, el pHmetro y los frascos)
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js interior-lab lab-alto lab-ancho --atlas
# --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar
from salon import suelo

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#2a2a34'
BL = ('#a8b0b6', '#c8d0d4', '#e4e8ea', '#f6f8f8')   # el blanco de los aparatos y del azulejo
AC = ('#4a4e56', '#7a7e88', '#a8acb4', '#d4d8de')   # el acero
VI = ('#7aa0ac', '#a6c8d0', '#d2eaee')              # el cristal
AM = ('#a07a10', '#e0b030', '#f4d870')              # el amarillo de seguridad
VE = ('#1e6a3e', '#2e9a5a', '#6ec88a')              # el verde de las señales de emergencia
RJ = ('#7a1e1e', '#b83030', '#e05a4a')              # el rojo
AZ = ('#1e3e7a', '#2e5aa8', '#6a92d8')              # el azul de las señales de obligación
RN = ('#1e1e24', '#2e2e36', '#44444e')              # la resina negra de las poyatas
VN = ('#b4b8b6', '#c4c8c6', '#d2d6d4')              # el vinilo del suelo

# ---------------------------------------------------------------------------------------------------------- las casillas
def floorLab():
    L = Lienzo(16, 16); R = azar(9101)
    L.r(0, 0, 16, 16, VN[1])
    for _ in range(14): L.p(int(R() * 16), int(R() * 16), VN[0] if R() < .5 else VN[2])
    return L

def floorLabL():
    """el vinilo con la línea amarilla de 10 cm a la izquierda (la frontera de la antesala)"""
    L = floorLab()
    L.r(0, 0, 3, 16, AM[1]); L.vl(0, 0, 15, AM[2]); L.vl(2, 0, 15, AM[0])
    return L

def azulejo(L, y0, y1):
    L.r(0, y0, 16, y1 - y0 + 1, BL[3])
    for y in range(y0, y1 + 1):
        if y % 4 == 3: L.hl(0, 15, y, BL[1])
    for x in (3, 7, 11, 15):
        L.vl(x, y0, y1, BL[1])

def iwT_lab():
    L = Lienzo(16, 16); azulejo(L, 0, 15)
    return L

def iwB_lab():
    """el azulejo y, abajo, la media caña de vinilo que sube a la pared (sin rincones donde se acumule nada)"""
    L = Lienzo(16, 16); azulejo(L, 0, 12)
    L.r(0, 13, 16, 3, VN[0]); L.hl(0, 15, 13, VN[2])
    return L

# ---------------------------------------------------------------------------------------------------------- las señales
def circulo(L, cx, cy, c, borde):
    """un círculo de 5 × 5 px (la señal)"""
    for dy in range(-2, 3):
        a = 1 if abs(dy) == 2 else 2
        L.hl(cx - a, cx + a, cy + dy, c)
    if borde:
        for (dx, dy) in ((-1, -2), (0, -2), (1, -2), (-2, -1), (2, -1), (-2, 0), (2, 0), (-2, 1), (2, 1), (-1, 2), (0, 2), (1, 2)):
            L.p(cx + dx, cy + dy, borde)

def prohibido(L, cx, cy, dentro):
    circulo(L, cx, cy, '#f4f4ee', RJ[1])
    L.p(cx, cy, dentro)
    L.p(cx - 1, cy - 1, RJ[1]); L.p(cx + 1, cy + 1, RJ[1])   # la barra

def obligacion(L, cx, cy, dibujo):
    circulo(L, cx, cy, AZ[1], None)
    for dx, dy in dibujo: L.p(cx + dx, cy + dy, '#f4f4ee')

# ---------------------------------------------------------------------------------------------------------- los de pared
def labNormas():
    """el cartel de las normas (60 × 50 cm, 12 × 10 px a 1,4 m): tres señales azules de obligación (la bata, las gafas y los
    guantes) y tres rojas de prohibición (la comida, la bebida y el tabaco)"""
    L = Lienzo(32, 48)
    x0, y0 = 10, 17                                                                       # con el contorno, dentro de su casilla
    L.r(x0, y0, 13, 13, '#f8f8f4'); L.hl(x0, x0 + 12, y0, BL[2])
    obligacion(L, x0 + 2, y0 + 3, ((0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)))            # la bata
    obligacion(L, x0 + 6, y0 + 3, ((-1, 0), (1, 0), (0, 0)))                             # las gafas
    obligacion(L, x0 + 10, y0 + 3, ((0, -1), (-1, 0), (0, 0), (0, 1)))                   # el guante
    prohibido(L, x0 + 2, y0 + 9, '#c8a060')                                              # comer
    prohibido(L, x0 + 6, y0 + 9, '#4a92e0')                                              # beber
    prohibido(L, x0 + 10, y0 + 9, '#a8acb4')                                             # fumar
    L.contorno(K)
    return L

def labBotiquin():
    """el botiquín blanco de pared (40 × 30 cm) con la cruz verde"""
    L = Lienzo(32, 48)
    L.r(12, 22, 8, 7, BL[3]); L.hl(12, 19, 22, '#ffffff'); L.hl(12, 19, 28, BL[1]); L.vl(19, 22, 28, BL[1])
    L.vl(15, 23, 27, VE[1]); L.vl(16, 23, 27, VE[1]); L.hl(13, 18, 25, VE[1]); L.hl(13, 18, 24, VE[1])   # la cruz
    L.contorno(K)
    return L

def labLavaojos():
    """el lavaojos de pared: la señal verde cuadrada con el ojo y la gota, la palangana de acero con las dos boquillas y la
    palanca de empuje (a 1 m)"""
    L = Lienzo(32, 48)
    L.r(12, 16, 8, 8, VE[1]); L.hl(13, 18, 19, '#f4f4ee'); L.p(13, 20, '#f4f4ee'); L.p(18, 20, '#f4f4ee')
    L.hl(14, 17, 21, '#f4f4ee'); L.p(15, 20, VE[0]); L.p(16, 20, VE[0]); L.p(18, 17, '#a6c8d0')   # el ojo y la gota
    L.r(10, 29, 12, 3, AC[2]); L.hl(10, 21, 29, AC[3]); L.hl(11, 20, 31, AC[0])           # la palangana
    L.r(13, 27, 2, 2, VE[1]); L.r(17, 27, 2, 2, VE[1])                                    # las boquillas con su tapa
    L.vl(16, 32, 35, AC[1]); L.r(20, 32, 2, 3, VE[2]); L.vl(21, 32, 34, VE[0])           # el tubo y la palanca
    L.contorno(K)
    return L

def labExtintor():
    """el extintor de CO2 de 5 kg colgado a 1 m, con la boquilla de trompa y la señal roja encima"""
    L = Lienzo(32, 48)
    L.r(13, 17, 6, 6, RJ[1]); L.hl(14, 17, 19, '#f4f4ee'); L.vl(15, 18, 21, '#f4f4ee')    # la señal
    L.r(14, 27, 4, 10, RJ[1]); L.vl(14, 27, 36, RJ[2]); L.vl(17, 27, 36, RJ[0]); L.hl(14, 17, 30, '#f4f4ee')
    L.hl(14, 17, 26, AC[1]); L.p(15, 25, AC[0]); L.vl(19, 26, 31, RN[1]); L.r(19, 31, 2, 3, RN[2])   # la válvula y la trompa
    L.hl(13, 18, 33, AC[0])                                                               # el soporte
    L.contorno(K)
    return L

# ---------------------------------------------------------------------------------------------------------- los de suelo
def labPercha():
    """la percha de la antesala: el tablero con cuatro ganchos, dos batas blancas colgadas, las gafas de seguridad colgando de su
    goma y, al lado, el dispensador de guantes de nitrilo azules; abajo, el cubo de las fundas usadas"""
    L = Lienzo(32, 48)
    L.r(9, 14, 14, 2, AC[1]); L.hl(9, 22, 14, AC[3])                                      # el tablero (con el contorno, en su casilla)
    for x in (10, 14, 18, 21): L.p(x, 16, AC[0])
    for bx in (9, 14):                                                                    # las batas
        L.r(bx, 17, 5, 17, BL[3]); L.vl(bx, 17, 33, BL[2]); L.vl(bx + 4, 18, 33, BL[1]); L.vl(bx + 2, 19, 33, BL[1])
        L.hl(bx + 1, bx + 3, 17, BL[1]); L.p(bx + 1, 24, BL[1]); L.p(bx + 3, 27, BL[1])   # el cuello y los bolsillos
    L.hl(19, 21, 19, '#3a3a44'); L.r(19, 20, 4, 2, VI[2]); L.p(21, 20, VI[0])             # las gafas
    L.r(19, 24, 4, 5, AZ[1]); L.hl(19, 22, 24, AZ[2]); L.hl(20, 22, 25, '#1a2a58'); L.p(21, 26, '#7aa6f0')   # los guantes
    L.r(18, 39, 5, 7, AC[1]); L.hl(18, 22, 39, AC[3]); L.vl(22, 39, 45, AC[0])            # el cubo
    L.contorno(K); suelo(L, 18, 22, K)
    return L

def labPila():
    """el lavamanos de acero de pie (45 cm), con el pedal y el grifo de caño alto; en la pared, el jabón y el papel"""
    L = Lienzo(32, 48)
    L.r(10, 14, 5, 7, BL[3]); L.hl(10, 14, 14, '#ffffff'); L.r(11, 19, 3, 2, '#e8c860')   # el dispensador de jabón
    L.r(17, 14, 6, 6, BL[2]); L.hl(17, 22, 14, BL[3]); L.r(18, 19, 4, 3, '#f8f8f4')        # el papel
    L.vl(15, 24, 31, AC[2]); L.hl(13, 15, 24, AC[2]); L.p(13, 25, AC[1])                   # el caño
    L.r(9, 31, 14, 3, AC[2]); L.hl(9, 22, 31, AC[3]); L.hl(10, 21, 33, AC[0])             # la pila
    L.r(13, 34, 6, 10, AC[1]); L.vl(13, 34, 43, AC[2]); L.vl(18, 34, 43, AC[0])           # el pie
    L.r(18, 43, 4, 2, RN[1]); L.hl(18, 21, 43, RN[2])                                    # el pedal
    L.contorno(K); suelo(L, 13, 21, K)
    return L

def labDucha():
    """la ducha de emergencia: el tubo verde que baja del techo, el brazo con la regadera de plato, el tirador triangular
    colgado de su varilla, la señal verde y, en el suelo, el sumidero"""
    L = Lienzo(32, 48)
    L.vl(21, 0, 45, VE[1]); L.vl(22, 0, 45, VE[0])                                        # el tubo
    L.hl(13, 21, 3, VE[1]); L.hl(13, 21, 4, VE[0])                                        # el brazo
    L.r(10, 5, 8, 2, AC[2]); L.hl(10, 17, 5, AC[3]); L.hl(11, 16, 7, AC[1])               # la regadera
    L.vl(19, 5, 18, AC[0]); L.r(17, 19, 5, 1, AM[1]); L.p(18, 20, AM[1]); L.p(20, 20, AM[1]); L.p(19, 21, AM[1])   # el tirador
    L.r(8, 22, 6, 6, VE[1]); L.vl(10, 23, 26, '#f4f4ee'); L.hl(9, 12, 24, '#f4f4ee')       # la señal
    L.r(10, 43, 10, 3, AC[1]); L.hl(10, 19, 43, AC[2])                                    # el sumidero
    for x in range(11, 19, 2): L.p(x, 44, AC[0])
    L.contorno(K); suelo(L, 10, 22, K)
    return L

def labAutoclave():
    """el autoclave de 50 L (60 × 100 cm, 10 × 16 px): el cuerpo de acero, la tapa redonda con el volante, el manómetro, el
    piloto y la bandeja de los botes de cristal encima"""
    L = Lienzo(32, 48)
    x0, x1 = 10, 22
    L.r(x0, 28, x1 - x0 + 1, 18, AC[2]); L.hl(x0, x1, 28, AC[3]); L.vl(x0, 28, 45, AC[3]); L.vl(x1, 28, 45, AC[0])
    for dy in range(-4, 5):                                                               # la tapa redonda
        a = [2, 3, 4, 4, 4, 4, 4, 3, 2][dy + 4]
        L.hl(16 - a, 16 + a, 36 + dy, AC[1])
    L.hl(14, 18, 36, AC[0]); L.vl(16, 34, 38, AC[0]); L.p(16, 36, AC[3])                  # el volante
    L.r(x0 + 1, 29, 3, 3, '#f4f4ee'); L.p(x0 + 2, 30, RJ[1])                              # el manómetro
    L.p(x1 - 2, 30, '#5ee07a')                                                            # el piloto
    for i in range(3): L.r(x0 + 2 + i * 3, 24, 2, 4, VI[1]); L.p(x0 + 2 + i * 3, 23, AM[1])   # los botes con su cinta
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def labEstufa():
    """la estufa de germinación (70 × 130 cm): el armario blanco con la puerta de cristal, cuatro baldas con placas de Petri y las
    semillas abiertas, la pantalla verde y la rejilla"""
    L = Lienzo(32, 48)
    x0, x1 = 10, 21
    L.r(x0, 25, x1 - x0 + 1, 21, BL[2]); L.hl(x0, x1, 25, BL[3]); L.vl(x1, 25, 45, BL[0])
    L.r(x0 + 1, 26, x1 - x0 - 1, 2, RN[1]); L.hl(x0 + 2, x0 + 4, 26, '#5ee07a')           # la pantalla
    L.r(x0 + 1, 29, x1 - x0 - 2, 14, VI[0]); L.vl(x0 + 2, 30, 41, VI[2])
    for by in (32, 36, 40):                                                               # las baldas y las placas
        L.hl(x0 + 1, x1 - 2, by, AC[3])
        for px in range(x0 + 3, x1 - 2, 3):
            L.hl(px, px + 1, by - 1, '#f0f0e0'); L.p(px + (by // 4) % 2, by - 2, '#8ab858')
    L.hl(x0 + 1, x1 - 1, 44, BL[0])
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def labNevera():
    """la nevera de muestras (60 × 180 cm): blanca, la puerta de cristal con las gradillas de tubos y los sobres, la cerradura y
    la señal amarilla triangular de riesgo arriba"""
    L = Lienzo(32, 48)
    x0, x1 = 10, 21
    L.r(x0, 17, x1 - x0 + 1, 29, BL[2]); L.hl(x0, x1, 17, BL[3]); L.vl(x1, 17, 45, BL[0]); L.vl(x0, 17, 45, BL[3])
    L.r(x0 + 1, 20, x1 - x0 - 2, 22, VI[0]); L.vl(x0 + 2, 21, 40, VI[2])
    for by in (26, 32, 38):
        L.hl(x0 + 1, x1 - 2, by, AC[3])
        for tx in range(x0 + 3, x1 - 2, 2): L.vl(tx, by - 3, by - 1, ('#e8c860', '#d8e8c0', '#c8a8e0')[(tx + by) % 3])
    L.vl(x1 - 1, 28, 32, AC[1]); L.p(x1 - 1, 34, AM[1])                                   # el asa y la cerradura
    L.p(15, 18, AM[1]); L.hl(14, 16, 19, AM[1]); L.p(15, 19, K)                          # la señal triangular
    L.hl(x0 + 1, x1 - 1, 44, BL[0])
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def labResiduos():
    """el contenedor amarillo de residuos biológicos (60 L, con tapa y pedal; la señal negra del riesgo) y, encima, el bote
    rojo de cortantes; al lado, el cubo gris de lo demás"""
    L = Lienzo(32, 48)
    L.r(8, 34, 9, 12, AM[1]); L.vl(8, 34, 45, AM[2]); L.vl(16, 34, 45, AM[0])
    L.r(8, 32, 9, 2, AM[0]); L.hl(8, 16, 32, AM[2])                                       # la tapa
    L.p(12, 38, K); L.p(11, 39, K); L.p(13, 39, K); L.p(12, 40, K)                        # la señal
    L.r(10, 28, 4, 4, RJ[1]); L.hl(10, 13, 28, RJ[2]); L.hl(11, 12, 28, '#f4f4ee')        # el de cortantes
    L.r(18, 37, 5, 9, AC[1]); L.hl(18, 22, 37, AC[3]); L.vl(22, 37, 45, AC[0])            # el cubo gris
    L.contorno(K); suelo(L, 8, 22, K)
    return L

def puerta(precinto):
    """la puerta del laboratorio: el marco gris, la hoja blanca de acero lacado con el ventanuco estrecho de cristal, la manilla de
    palanca, la placa de empuje, las tres señales azules de EPI y, cerrada, la cinta de precinto en aspa. Con el contorno, dentro de
    su casilla (x 8..23), como las de sotano.py: que no se monte encima de lo de al lado"""
    L = Lienzo(32, 48); t = 21
    L.r(9, t, 14, 48 - t, AC[0]); L.hl(9, 22, t, AC[1])                                    # el marco
    L.r(10, t + 2, 12, 46 - t, BL[3]); L.vl(10, t + 2, 47, '#ffffff'); L.vl(21, t + 2, 47, BL[1])
    L.r(15, t + 4, 3, 9, VI[1]); L.vl(15, t + 4, t + 12, VI[2]); L.hl(15, 17, t + 4, AC[2])   # el ventanuco
    for i, d in enumerate((((0, -1), (-1, 0), (0, 0), (1, 0), (0, 1)), ((-1, 0), (1, 0), (0, 0)), ((0, -1), (-1, 0), (0, 0), (0, 1)))):
        cy = t + 5 + i * 4
        L.r(11, cy - 1, 3, 3, AZ[1])
        for dx, dy in d: L.p(12 + dx, cy + dy, '#f4f4ee')
    L.r(18, t + 15, 3, 1, AC[1]); L.p(20, t + 16, AC[1]); L.p(18, t + 16, AC[2])          # la manilla
    L.r(11, t + 18, 4, 6, BL[1])                                                          # la placa de empuje
    L.hl(10, 21, 47, AC[0])
    if precinto:
        for i in range(12):
            y1 = t + 4 + i
            for x, y in ((10 + i, y1), (21 - i, y1)):
                L.p(x, y, AM[1] if (i // 2) % 2 == 0 else RN[0])
    L.contorno(K)
    return L

def labTaburete():
    """el taburete de laboratorio: el asiento redondo negro, la columna de gas y la base de cinco patas con ruedas"""
    L = Lienzo(32, 48)
    L.r(12, 35, 8, 2, RN[1]); L.hl(12, 19, 35, RN[2]); L.hl(13, 18, 37, RN[0])
    L.vl(16, 38, 43, AC[1]); L.vl(15, 38, 43, AC[2])
    L.hl(11, 20, 44, AC[0]); L.p(11, 45, RN[0]); L.p(20, 45, RN[0]); L.p(15, 45, RN[0])
    L.contorno(K); suelo(L, 11, 20, K)
    return L

# ---------------------------------------------------------------------------------------------------------- los de dos casillas
def poyata(L, x0, x1):
    """la poyata de laboratorio (90 cm de alto): la encimera de resina negra con su canto y los armarios blancos con tirador"""
    L.r(x0, 31, x1 - x0 + 1, 3, RN[1]); L.hl(x0, x1, 31, RN[2]); L.hl(x0, x1, 33, RN[0])
    L.r(x0 + 1, 34, x1 - x0 - 1, 12, BL[2]); L.hl(x0 + 1, x1 - 1, 45, BL[0])
    n = 3
    w = (x1 - x0 - 1) // n
    for i in range(n):
        ax = x0 + 1 + i * w
        L.vl(ax, 34, 44, BL[0]); L.hl(ax + 2, ax + w - 3, 35, AC[1])                     # la puerta y su tirador
    L.vl(x1 - 1, 34, 44, BL[0])

def labFlujo():
    """la cabina de flujo laminar (150 × 190 cm, 24 × 30 px): la carcasa blanca, el filtro de arriba con su rejilla, el panel con
    el piloto, la luz de dentro, el cristal de guillotina subido a media altura y, dentro, sobre el acero, las placas, las pinzas y
    el mechero; las patas con el bastidor"""
    L = Lienzo(48, 48)
    x0, x1 = 12, 35
    L.r(x0, 13, x1 - x0 + 1, 8, BL[2]); L.hl(x0, x1, 13, BL[3]); L.vl(x1, 13, 20, BL[0])   # el filtro
    for x in range(x0 + 2, x1 - 6, 2): L.vl(x, 15, 18, BL[1])                            # la rejilla
    L.r(x1 - 5, 15, 4, 4, RN[1]); L.p(x1 - 4, 16, '#5ee07a'); L.p(x1 - 2, 16, AM[1])      # el panel
    L.r(x0, 21, x1 - x0 + 1, 14, BL[1]); L.vl(x0, 21, 34, BL[3]); L.vl(x1, 21, 34, BL[0])
    L.r(x0 + 2, 22, x1 - x0 - 3, 11, '#e8f4f0'); L.hl(x0 + 2, x1 - 2, 22, '#ffffff')      # dentro, con la luz
    L.r(x0 + 2, 22, x1 - x0 - 3, 6, VI[1]); L.hl(x0 + 2, x1 - 2, 27, AC[2]); L.vl(x0 + 4, 23, 26, VI[2])   # el cristal
    L.hl(x0 + 2, x1 - 2, 32, AC[2])                                                       # la bandeja de acero
    for i in range(3): L.hl(x0 + 5 + i * 3, x0 + 6 + i * 3, 31, '#f0f0e0'); L.p(x0 + 5 + i * 3, 30, '#d8e8c0')   # las placas
    L.hl(x1 - 8, x1 - 5, 31, AC[1]); L.p(x1 - 4, 30, AC[1])                               # las pinzas
    L.r(x1 - 3, 29, 2, 3, AZ[1]); L.p(x1 - 3, 28, '#6a92d8')                              # el mechero
    L.r(x0, 35, x1 - x0 + 1, 2, BL[0])
    L.vl(x0 + 1, 37, 45, AC[0]); L.vl(x1 - 1, 37, 45, AC[0]); L.hl(x0 + 1, x1 - 1, 42, AC[1])   # las patas
    L.contorno(K); suelo(L, x0 + 1, x1 - 1, K)
    return L

def labMicro():
    """la poyata del microscopio (160 cm): el microscopio binocular, la lupa con su luz de anillo, la caja de portaobjetos y el
    cuaderno de laboratorio abierto"""
    L = Lienzo(48, 48)
    x0, x1 = 11, 36
    poyata(L, x0, x1)
    mx = x0 + 3                                                                           # el microscopio
    L.r(mx, 29, 7, 2, '#e4e8ea'); L.vl(mx + 5, 21, 28, '#d4d8de'); L.r(mx + 3, 20, 4, 2, '#e4e8ea')
    L.hl(mx + 1, mx + 3, 19, RN[1]); L.p(mx, 18, RN[1]); L.p(mx + 2, 18, RN[1])           # los oculares
    L.r(mx + 1, 25, 4, 1, AC[1]); L.p(mx + 2, 27, VI[2]); L.p(mx + 6, 26, AC[0])          # la platina y el mando
    lx = x0 + 13                                                                          # la lupa
    L.r(lx, 29, 5, 2, RN[1]); L.vl(lx + 4, 22, 28, AC[1]); L.r(lx, 22, 4, 3, RN[2]); L.hl(lx, lx + 3, 25, '#f4f4c8')
    L.r(x1 - 7, 29, 4, 2, '#3a5a9a'); L.hl(x1 - 7, x1 - 4, 29, '#5a7aba')                 # la caja de portaobjetos
    L.r(x1 - 3, 30, 3, 1, '#f8f4e8')                                                      # el cuaderno
    L.contorno(K); suelo(L, x0 + 1, x1 - 1, K)
    return L

def labBalanza():
    """la poyata de la balanza: la balanza de precisión con su urna de cristal y la pantalla, el pHmetro con el electrodo en su
    vaso, la gradilla con las pipetas y dos frascos lavadores"""
    L = Lienzo(48, 48)
    x0, x1 = 11, 36
    poyata(L, x0, x1)
    bx = x0 + 2                                                                           # la balanza
    L.r(bx, 28, 9, 3, '#e4e8ea'); L.hl(bx, bx + 8, 28, '#ffffff'); L.r(bx + 1, 29, 3, 1, '#5ee07a')
    L.r(bx + 1, 21, 7, 7, VI[1]); L.vl(bx + 1, 21, 27, VI[2]); L.hl(bx + 1, bx + 7, 21, AC[2])   # la urna
    L.hl(bx + 3, bx + 5, 27, AC[1])                                                       # el platillo
    px = x0 + 13                                                                          # el pHmetro
    L.r(px, 27, 4, 4, '#e4e8ea'); L.r(px + 1, 28, 2, 1, '#5ee07a'); L.vl(px + 5, 22, 29, RN[2])
    L.r(px + 4, 28, 3, 3, VI[1]); L.hl(px + 4, px + 6, 29, '#c8e0f0')                     # el vaso del electrodo
    gx = x1 - 7                                                                           # la gradilla con las pipetas
    L.hl(gx, gx + 3, 30, AC[1]); L.hl(gx, gx + 3, 27, AC[1])
    for i in range(3): L.vl(gx + i, 22 + i, 29, ('#f4f4ee', '#e8c860', '#a6c8d0')[i])
    for i in range(2): L.r(x1 - 2 - i * 0, 26 + i * 0, 2, 5, '#f4f4ee'); L.p(x1 - 2, 25, '#e05a4a')   # el frasco lavador
    L.contorno(K); suelo(L, x0 + 1, x1 - 1, K)
    return L

for f in (floorLab, floorLabL, iwT_lab, iwB_lab):
    sale(f.__name__, f(), 'interior-lab')
for f in (labNormas, labBotiquin, labLavaojos, labExtintor, labPercha, labPila, labDucha, labAutoclave, labEstufa, labNevera, labResiduos, labTaburete):
    sale(f.__name__, f(), 'lab-alto')
sale('puertaLab', puerta(False), 'lab-alto'); sale('puertaLabP', puerta(True), 'lab-alto')
for f in (labFlujo, labMicro, labBalanza):
    sale(f.__name__, f(), 'lab-ancho')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
