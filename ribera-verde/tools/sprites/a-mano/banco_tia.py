# python3 -I tools/sprites/a-mano/banco_tia.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# ESTUDIO tanda 1 (lo pidió el usuario: «mete mano a las mejoras que hablamos»): el banco de semillas de la tía, el cuarto de atrás
# de la asociación (banco-rv), a 16 px/m y de frente a 3/4 como los muebles de los locales (nunca isométrico). Genérico, sin marcas
# ni letras. Muebles de 2 casillas (mueble_ancho, 48 × 48, base en (16, 47) y el mueble centrado en x 24; la casilla de la derecha,
# o + "2", no se pinta):
#  · btFichero: el fichero de madera de la tía (140 × 110 cm), 16 cajoncitos con su tirador de latón y su etiqueta, y encima la
#    lata de galletas del manzano y el cuaderno azul
#  · btCamara: la cámara fría de dos puertas de cristal (120 × 185 cm), con los sobres de semillas en sus baldas y el piloto verde
#  · btArchivo: la estantería del archivo (160 × 190 cm) con cajas de cartón y cuadernos de colores
#  · btLab: la mesa del laboratorio (160 cm), con el microscopio, la lupa de brazo, las placas y el cuaderno
#  · btMostrador: el mostrador de los socios (140 × 100 cm), con la urna de los sobres, el montón de sobres y el timbre
#  · btCata: la mesa de catas (160 cm), de madera, con cuatro tarros de cristal, la lupa y la libreta
#  · btTapado: lo que aún no se ha restaurado: un mueble tapado con una sábana gris de polvo y dos cajas al lado
#  · btPlaca: la placa de la pared (de la fila de la pared, como la foto de la tía): madera con la chapa de latón y una hoja grabada
# Sale a art/crudo/banco-tia/<sprite>/unica/00.png (después, node tools/sprites/procesar.js banco-tia --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P
from salon import suelo

K = '#2a2a34'                                        # el contorno de los muebles (el de salon.py)
MA = ('#3e2614', '#5e3c20', '#7e5630', '#a07448')    # la madera vieja de la tía
LT = ('#7a5a1a', '#b8902e', '#e8c860')               # el latón
AC = ('#4a4e56', '#7a7e88', '#a8acb4', '#d4d8de')    # el acero
VI = ('#7aa0ac', '#a6c8d0', '#d2eaee')               # el cristal
CA = ('#8a6a3e', '#b08a52', '#cfae76')               # el cartón
SOBRES = ('#d8c89a', '#c8a870', '#e4d8b4', '#b89a62')   # los sobres de papel
GRUPO = 'banco-tia'

SAL = {}
def sale(n, L):
    SAL[n] = L

def patas(L, x0, x1, y0, y1, c):
    for x in (x0, x1): L.vl(x, y0, y1, c)

def btFichero():
    """el fichero de la tía: 22 × 18 px de frente y la tapa a medio fondo (3 px); 4 × 4 cajoncitos de 5 × 4 con el tirador y la
    etiqueta blanca; encima, la lata de galletas oxidada y el cuaderno azul"""
    L = Lienzo(48, 48)
    x0, x1 = 13, 34
    L.r(x0, 26, x1 - x0 + 1, 3, MA[2]); L.hl(x0, x1, 26, MA[3])                       # la tapa
    L.r(x0, 29, x1 - x0 + 1, 17, MA[1]); L.hl(x0, x1, 29, MA[0])
    for j in range(4):
        for i in range(4):
            cx, cy = x0 + 1 + i * 5, 30 + j * 4
            L.r(cx, cy, 4, 3, MA[2]); L.hl(cx, cx + 3, cy, MA[3])                     # el cajoncito
            L.hl(cx + 1, cx + 2, cy + 1, '#ece4cc')                                    # la etiqueta
            L.p(cx + 1, cy + 2, LT[1]); L.p(cx + 2, cy + 2, LT[2])                     # el tirador
    L.vl(x1, 29, 45, MA[0])
    L.r(x0 + 2, 21, 7, 5, '#8a4a2a'); L.hl(x0 + 2, x0 + 8, 21, '#b06a3a')              # la lata, con el óxido
    L.p(x0 + 4, 23, '#c48a4a'); L.p(x0 + 7, 24, '#5e2e1a'); L.hl(x0 + 2, x0 + 8, 22, '#6e3a20')
    L.r(x0 + 12, 24, 7, 2, '#2e4e8a'); L.hl(x0 + 12, x0 + 18, 24, '#4a72b8'); L.vl(x0 + 12, 24, 25, '#1e3460')   # el cuaderno azul
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def btCamara():
    """la cámara fría de dos puertas (19 × 30 px): el marco de acero, el cristal con las baldas y los sobres de colores, las
    asas, el piloto verde arriba y la rejilla de abajo"""
    L = Lienzo(48, 48)
    x0, x1 = 14, 33
    L.r(x0, 15, x1 - x0 + 1, 31, AC[1]); L.hl(x0, x1, 15, AC[3]); L.vl(x0, 15, 45, AC[2]); L.vl(x1, 15, 45, AC[0])
    L.r(x0 + 2, 16, x1 - x0 - 3, 3, AC[0]); L.p(x0 + 3, 17, '#5ee07a'); L.p(x0 + 5, 17, '#2a6a3a')   # el panel con el piloto
    for d in range(2):                                                                # las dos puertas de cristal
        dx0 = x0 + 1 + d * 9
        L.r(dx0, 20, 8, 22, VI[0]); L.vl(dx0, 20, 41, AC[2]); L.vl(dx0 + 7, 20, 41, AC[2]); L.hl(dx0, dx0 + 7, 20, AC[2]); L.hl(dx0, dx0 + 7, 41, AC[2])
        for k, by in enumerate((25, 31, 37)):                                         # las baldas con los sobres
            L.hl(dx0 + 1, dx0 + 6, by, AC[3])
            for s in range(3):
                L.r(dx0 + 1 + s * 2, by - 3, 2, 3, SOBRES[(s + k + d) % 4])
        L.vl(dx0 + 2, 21, 23, VI[2]); L.p(dx0 + 3, 21, VI[1])                         # el brillo del cristal
        L.vl(dx0 + (6 if d == 0 else 1), 28, 32, AC[3])                               # el asa
    L.r(x0 + 2, 43, x1 - x0 - 3, 2, AC[0])
    for x in range(x0 + 3, x1 - 2, 2): L.p(x, 43, AC[2])                             # la rejilla
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def btArchivo():
    """la estantería del archivo (26 × 30 px): cuatro baldas de madera con cajas de cartón y cuadernos de colores"""
    L = Lienzo(48, 48)
    x0, x1 = 11, 36
    L.r(x0, 15, x1 - x0 + 1, 31, MA[0])
    L.vl(x0, 15, 45, MA[2]); L.vl(x1, 15, 45, MA[1]); L.hl(x0, x1, 15, MA[3])
    CU = ('#3a5a9a', '#9a3a3a', '#3a7a4a', '#c8a040', '#6a4a8a', '#2e4e8a')
    for j, by in enumerate((22, 29, 36, 44)):
        L.hl(x0 + 1, x1 - 1, by, MA[2]); L.hl(x0 + 1, x1 - 1, by + 1, MA[1])
        x = x0 + 2
        n = 0
        while x < x1 - 2:
            if (j + n) % 3 == 0 and x + 6 < x1:                                       # una caja de cartón con su asa
                L.r(x, by - 5, 6, 5, CA[1]); L.hl(x, x + 5, by - 5, CA[2]); L.vl(x + 5, by - 5, by - 1, CA[0])
                L.hl(x + 2, x + 3, by - 3, '#4a3a22'); x += 7
            else:                                                                     # unos cuadernos de pie
                for c in range(3):
                    if x + c < x1 - 1:
                        L.vl(x + c, by - 5 + (c == 1), by - 1, CU[(j * 2 + n + c) % len(CU)])
                x += 4
            n += 1
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def btLab():
    """la mesa del laboratorio (26 px): el tablero blanco a medio fondo, las patas de acero, el microscopio, la lupa de brazo con
    su flexo, tres placas de cultivo y el cuaderno abierto"""
    L = Lienzo(48, 48)
    x0, x1 = 11, 36
    L.r(x0, 32, x1 - x0 + 1, 4, '#dcdcd4'); L.hl(x0, x1, 32, '#f0f0ea')              # el tablero
    L.r(x0, 36, x1 - x0 + 1, 2, AC[1])
    patas(L, x0 + 1, x1 - 1, 38, 46, AC[0])
    L.hl(x0 + 1, x1 - 1, 43, AC[1])                                                   # el travesaño
    mx = x0 + 4                                                                       # el microscopio
    L.r(mx, 31, 5, 2, '#2a2a30'); L.vl(mx + 1, 24, 30, '#3a3a42'); L.r(mx + 1, 23, 3, 2, '#2a2a30')
    L.vl(mx + 3, 26, 30, '#c8c8d0'); L.p(mx + 2, 28, '#5a5a64'); L.r(mx, 29, 4, 1, '#5a5a64')
    lx = x1 - 6                                                                       # la lupa de brazo
    L.vl(lx + 4, 22, 31, AC[0]); L.hl(lx, lx + 4, 22, AC[0]); L.r(lx - 2, 22, 4, 3, AC[2]); L.r(lx - 1, 23, 2, 1, VI[2])
    for i, c in enumerate(('#e8d878', '#d8e8c0', '#f0d0c0')):                         # las placas de cultivo
        L.hl(x0 + 11 + i * 3, x0 + 12 + i * 3, 32, c); L.p(x0 + 11 + i * 3, 33, '#b8b8b0')
    L.r(x0 + 11, 34, 6, 2, '#f8f4e8'); L.vl(x0 + 14, 34, 35, '#a8a498')               # el cuaderno abierto
    L.contorno(K); suelo(L, x0 + 1, x1 - 1, K)
    return L

def btMostrador():
    """el mostrador de los socios (22 × 16 px): madera con el frente de lamas, la urna de cristal de los sobres, el montón de
    sobres y el timbre de latón"""
    L = Lienzo(48, 48)
    x0, x1 = 13, 34
    L.r(x0, 29, x1 - x0 + 1, 3, MA[3]); L.hl(x0, x1, 29, '#c49468')                  # el tablero
    L.r(x0, 32, x1 - x0 + 1, 14, MA[1])
    for x in range(x0 + 2, x1 - 1, 3): L.vl(x, 33, 44, MA[0])                         # las lamas
    L.hl(x0, x1, 45, MA[0])
    ux = x0 + 2                                                                       # la urna con los sobres
    L.r(ux, 21, 8, 8, VI[0]); L.hl(ux, ux + 7, 21, VI[2]); L.vl(ux, 21, 28, VI[1])
    for i in range(4): L.r(ux + 1 + i * 2 - (i > 1), 25 - (i % 2), 2, 3, SOBRES[i])
    L.hl(ux + 2, ux + 5, 21, '#4a4a54')                                               # la ranura
    L.r(x0 + 12, 27, 5, 2, SOBRES[1]); L.hl(x0 + 12, x0 + 16, 27, SOBRES[2]); L.hl(x0 + 12, x0 + 16, 28, SOBRES[3])   # el montón
    L.r(x1 - 4, 27, 3, 2, LT[1]); L.p(x1 - 3, 26, LT[2]); L.hl(x1 - 4, x1 - 2, 28, LT[0])   # el timbre
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def btCata():
    """la mesa de catas (26 px), de madera: cuatro tarros de cristal con cogollos y tapas de colores, la lupa y la libreta"""
    L = Lienzo(48, 48)
    x0, x1 = 11, 36
    L.r(x0, 32, x1 - x0 + 1, 3, MA[3]); L.hl(x0, x1, 32, '#c49468')
    L.r(x0, 35, x1 - x0 + 1, 2, MA[1])
    patas(L, x0 + 1, x1 - 1, 37, 46, MA[0])
    for i, t in enumerate(('#c04848', '#e0b040', '#4a8a5a', '#6a4a8a')):              # los tarros
        tx = x0 + 2 + i * 5
        L.r(tx, 26, 4, 6, VI[1]); L.vl(tx, 26, 31, VI[2]); L.hl(tx, tx + 3, 25, t)
        L.r(tx + 1, 28, 2, 3, '#6e9a48'); L.p(tx + 2, 28, '#8ab858'); L.p(tx + 1, 29, '#c8a060')
    L.r(x1 - 5, 30, 3, 2, VI[2]); L.p(x1 - 2, 31, MA[0])                              # la lupa
    L.r(x1 - 6, 33, 4, 1, '#f4ecd4')                                                  # la libreta
    L.contorno(K); suelo(L, x0 + 1, x1 - 1, K)
    return L

def btTapado():
    """un mueble tapado con una sábana gris de polvo (22 × 22 px): los pliegues que caen hasta el suelo, el polvo de arriba y,
    al lado, dos cajas de cartón"""
    L = Lienzo(48, 48)
    S0, S1, S2, S3 = '#7a7a76', '#9a9a94', '#b8b6ae', '#d0cec4'
    x0, x1 = 12, 31
    for y in range(24, 46):                                                           # la sábana, más ancha abajo
        a = 0 if y > 27 else 27 - y
        for x in range(x0 + a, x1 - a + 1):
            c = S2
            if (x - x0) % 6 == 0 and y > 29: c = S0                                   # los pliegues
            elif (x - x0) % 6 in (1, 5) and y > 29: c = S1
            if y == 45 and (x * 3) % 5 == 0: c = S1                                   # el bajo arrugado
            L.p(x, y, c)
    L.hl(x0 + 3, x1 - 3, 24, S3); L.hl(x0 + 2, x0 + 6, 25, S3)                        # el polvo de arriba
    for x, y in ((x0 + 5, 26), (x0 + 12, 25), (x0 + 16, 27)): L.p(x, y, '#e8e6dc')
    L.r(33, 38, 6, 8, CA[1]); L.hl(33, 38, 38, CA[2]); L.vl(38, 38, 45, CA[0]); L.hl(33, 38, 41, '#c8b890')   # las cajas
    L.r(34, 33, 4, 5, CA[0]); L.hl(34, 37, 33, CA[1])
    L.contorno(K); suelo(L, x0, 38, K)
    return L

def btPlaca():
    """la placa de la pared (como la foto de la tía, de la fila de la pared): el tablero de madera de 24 × 12 con el canto claro,
    la chapa de latón con los tornillos y, grabada, una hoja de cinco puntas con su semilla debajo; sin letras"""
    L = Lienzo(48, 48)
    x0, x1, y0, y1 = 12, 35, 32, 44
    L.r(x0, y0, x1 - x0 + 1, y1 - y0 + 1, MA[1])
    L.hl(x0, x1, y0, MA[3]); L.vl(x0, y0, y1, MA[2]); L.hl(x0, x1, y1, MA[0]); L.vl(x1, y0, y1, MA[0])
    L.r(x0 + 3, y0 + 2, x1 - x0 - 5, y1 - y0 - 3, LT[1]); L.hl(x0 + 3, x1 - 3, y0 + 2, LT[2]); L.hl(x0 + 3, x1 - 3, y1 - 2, LT[0])
    for x, y in ((x0 + 4, y0 + 3), (x1 - 4, y0 + 3), (x0 + 4, y1 - 3), (x1 - 4, y1 - 3)): L.p(x, y, LT[0])   # los tornillos
    cx = 24
    L.vl(cx, y0 + 4, y0 + 8, LT[0])                                                   # la hoja grabada: el nervio
    for dx, dy in ((-1, 5), (-2, 6), (-3, 7), (1, 5), (2, 6), (3, 7), (-1, 7), (1, 7)):   # las cuatro puntas de los lados
        L.p(cx + dx, y0 + dy, LT[0])
    L.p(cx, y0 + 3, LT[0])
    L.hl(cx - 1, cx + 1, y0 + 9, LT[0])                                               # la semilla
    return L

for n, f in (('btFichero', btFichero), ('btCamara', btCamara), ('btArchivo', btArchivo), ('btLab', btLab), ('btMostrador', btMostrador),
             ('btCata', btCata), ('btTapado', btTapado), ('btPlaca', btPlaca)):
    sale(n, f())

def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, GRUPO, n) if raiz else P('art', 'crudo', GRUPO, n, 'unica')
        os.makedirs(d, exist_ok=True)
        for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
        L.im.save(os.path.join(d, '00.png'))
        print(GRUPO, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
