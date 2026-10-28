# python3 -I tools/sprites/a-mano/kaia_carpa.py  (Python 3 + Pillow)
# La carpa grande de la sala de cultivo de KAIA (lo pidió el usuario: «como en casa, cultivo con carpas, pero más grandes de primeras»):
# la de 240 × 240 × 200 cm a 16 px/m (38 px de ancho y 32 de alto), plateada y abierta de frente como la de las madres (carpa_abierta
# de locales.py), con sus dos LED de 720 W encendidos, el extractor de 250 mm con el filtro de carbón encima del techo y el tubo de
# aluminio que sube al techo de la sala; de 0 a 9 plantas en macetas de tela de 25 L, en tres filas (carpaKG-<n>). Celda carpa_grande
# de 64 × 64 con la base en el centro de la casilla de abajo a la izquierda (16, 63): el mueble, centrado en sus 3 casillas (x 32).
# Sale a art/crudo/kaia-carpa/<sprite>/unica/00.png (después, node tools/sprites/procesar.js kaia-carpa --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

K = '#2a2a34'                       # el contorno de los muebles (el de salon.py y locales.py)
P0, P1, P2 = '#8a8e96', '#c8ccd0', '#e8ecf0'
AL0, AL1, AL2 = '#8a8a90', '#b4b6bc', '#dcdee2'   # el aluminio del tubo
HOJAS = ('#2e5a2a', '#3f7a3a', '#5aa04a', '#84cc6c')
COG = '#e8e0b0'

# las nueve plazas, de atrás adelante: (centro x, base y)
PLAZAS = [(19, 51), (30, 51), (41, 51), (24, 56), (35, 56), (45, 56), (19, 61), (30, 61), (41, 61)]   # a tresbolillo

def planta(L, cx, yb, i):
    """una planta en flor de 1,2 m (12 filas) en su maceta de tela de 25 L: la mata en cono, las colas claras y los cogollos"""
    alto = 8
    fila = i // 3                                                      # la de atrás, más en sombra
    for j in range(alto):
        w = (1, 2, 3, 3, 4, 4, 3, 3)[alto - 1 - j]
        y = yb - 4 - j
        L.hl(cx - w, cx + w, y, HOJAS[(1 if fila else 0) + (j + i) % 2])
        L.p(cx - w, y, HOJAS[0]); L.p(cx + w, y, HOJAS[0])
    for (dx, dy) in ((0, -11), (-2, -8), (2, -9)):
        L.p(cx + dx, yb + dy, COG)
    L.p(cx - 1, yb - 6, HOJAS[3]); L.p(cx + 2, yb - 5, HOJAS[3] if fila else HOJAS[2])
    L.r(cx - 2, yb - 3, 5, 4, '#2a2a30'); L.hl(cx - 2, cx + 2, yb - 3, '#4a4a52')   # la maceta de tela

def carpa(n):
    L = Lienzo(64, 64)
    x0, x1, y0, yb = 13, 50, 31, 62
    # encima del techo: el filtro de carbón tumbado, el extractor en línea y el tubo que sube al techo de la sala
    L.caja(16, 24, 12, 7, '#4a4e56', '#2a2e34'); L.hl(17, 26, 25, '#6a6e76')          # el filtro
    for x in range(18, 27, 2): L.vl(x, 26, 29, '#3a3e44')                             # su malla
    L.r(28, 26, 3, 3, AL1)                                                             # el manguito
    L.caja(31, 24, 9, 7, '#2e3238', '#1e2226'); L.hl(32, 38, 25, '#4a5058')            # el extractor
    L.p(35, 27, '#c8a040')
    for y in range(0, 24):                                                             # el tubo de aluminio, que sube
        L.hl(33, 37, y, AL1); L.p(33, y, AL0); L.p(37, y, AL0)
        if y % 3 == 0: L.hl(34, 36, y, AL2)
    # la carpa, plateada, abierta de frente
    L.r(x0, y0, x1 - x0 + 1, yb - y0 + 1, P1); L.hl(x0, x1, y0, P2)
    L.r(x0 + 2, y0 + 5, x1 - x0 - 3, yb - y0 - 5, '#1e1a22')                         # por dentro, oscura
    L.r(x0 + 2, y0 + 3, x1 - x0 - 3, 2, P0)                                             # la tela de delante, enrollada arriba
    for x in range(x0 + 2, x1 - 1, 3): L.p(x, y0 + 3, P2)
    L.vl(x0, y0, yb, P0); L.vl(x1, y0, yb, P0); L.vl((x0 + x1) // 2, y0, y0 + 2, P0)  # el armazón
    for cx in (22, 40):                                                                 # los dos LED de barras, encendidos
        L.vl(cx - 4, y0 + 1, y0 + 5, '#3a3a40'); L.vl(cx + 4, y0 + 1, y0 + 5, '#3a3a40')
        L.r(cx - 6, y0 + 6, 13, 2, '#f4f4ee'); L.hl(cx - 6, cx + 6, y0 + 8, '#fff2b0')
    for y in range(y0 + 9, yb):                                                         # la luz, que abre hacia abajo
        w = 7 + (y - y0 - 9) // 2
        for cx in (22, 40):
            L.hl(max(x0 + 2, cx - w), min(x1 - 2, cx + w), y, '#2e2a34')
    for i, (cx, b) in enumerate(PLAZAS[:n]):
        planta(L, cx, b, i)
    L.hl(x0 + 2, x1 - 2, yb, '#3a3a40')
    L.contorno(K)
    for x in range(64):                                                                 # apoya en el suelo
        if L.lleno(x, 62) and not L.lleno(x, 63): L.p(x, 63, K)
    return L

if __name__ == '__main__':
    for n in range(10):
        d = P('art', 'crudo', 'kaia-carpa', f'carpaKG-{n}', 'unica')
        os.makedirs(d, exist_ok=True)
        for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
        L = carpa(n); L.im.save(os.path.join(d, '00.png'))
        print('kaia-carpa', f'carpaKG-{n}', L.im.getbbox(), len(L.colores()), 'colores')
