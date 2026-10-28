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

# Por niveles (lo pidió el usuario: «4 de 2×2, luego 2 de 4×2, luego una de 4×4»): la carpa de w × d m a 16 px/m, de frente con 2 m de
# alto (32 px) y el techo a 4 px por metro de fondo, plateada y abierta, con un LED de barras por columna de plantas, el extractor y el
# filtro encima y un tramo de tubo que va a la pared; de 0 a todas sus plantas en rejilla (kcs-<n>, kcm-<n>, kcl-<n>). Celda carpa_kc de 80 × 80
# con la base en el centro de la casilla de abajo a la izquierda (8, 79): el mueble ocupa sus w casillas desde x 0.
TUBO = 6
NIVELES = {'kcs': (2, 2, 2, 2), 'kcm': (4, 2, 4, 2), 'kcl': (4, 4, 4, 4)}   # ancho, fondo (m), columnas y filas de plantas

def carpa_kc(w, d, cols, filas, n):
    L = Lienzo(80, 80)
    x0, x1, yb = 1, w * 16 - 2, 78
    y0 = yb - 31                                                    # el frente, 2 m
    yt = y0 - d * 4                                                 # el techo, por el fondo
    cx = (x0 + x1) // 2
    # encima del techo: el filtro de carbón, el extractor y el tubo que sube al techo de la sala
    fx = cx - 12 if w > 2 else cx - 10
    L.caja(fx, yt - 7, 10, 7, '#4a4e56', '#2a2e34'); L.hl(fx + 1, fx + 8, yt - 6, '#6a6e76')
    for x in range(fx + 2, fx + 9, 2): L.vl(x, yt - 5, yt - 2, '#3a3e44')
    L.r(fx + 10, yt - 5, 2, 3, AL1)
    L.caja(fx + 12, yt - 7, 8, 7, '#2e3238', '#1e2226'); L.hl(fx + 13, fx + 18, yt - 6, '#4a5058'); L.p(fx + 15, yt - 4, '#c8a040')
    for y in range(yt - 7 - TUBO, yt - 7):                          # el tubo, que sube un tramo y se va hacia la pared (no tapa lo de detrás)
        L.hl(fx + 13, fx + 17, y, AL1); L.p(fx + 13, y, AL0); L.p(fx + 17, y, AL0)
        if y % 3 == 0: L.hl(fx + 14, fx + 16, y, AL2)
    L.hl(fx + 12, fx + 18, yt - 8 - TUBO, AL0); L.hl(fx + 13, fx + 17, yt - 9 - TUBO, AL2)   # la boca, de canto
    # el techo, plateado, con sus costuras
    L.r(x0, yt, x1 - x0 + 1, y0 - yt, P2); L.hl(x0, x1, y0 - 1, P1)
    for x in range(x0 + 4, x1, 8): L.vl(x, yt + 1, y0 - 2, P1)
    # el frente, abierto
    L.r(x0, y0, x1 - x0 + 1, yb - y0 + 1, P1)
    L.r(x0 + 2, y0 + 5, x1 - x0 - 3, yb - y0 - 5, '#1e1a22')
    L.r(x0 + 2, y0 + 3, x1 - x0 - 3, 2, P0)
    for x in range(x0 + 2, x1 - 1, 3): L.p(x, y0 + 3, P2)
    L.vl(x0, yt, yb, P0); L.vl(x1, yt, yb, P0)
    paso = (x1 - x0 - 3) / cols
    cxs = [int(x0 + 2 + paso * (c + .5)) for c in range(cols)]
    for c in cxs:                                                   # un LED de barras por columna, encendido
        L.vl(c - 3, y0 + 1, y0 + 5, '#3a3a40'); L.vl(c + 3, y0 + 1, y0 + 5, '#3a3a40')
        L.r(c - 5, y0 + 6, 11, 2, '#f4f4ee'); L.hl(c - 5, c + 5, y0 + 8, '#fff2b0')
    for y in range(y0 + 9, yb):
        ww = 5 + (y - y0 - 9) // 2
        for c in cxs:
            L.hl(max(x0 + 2, c - ww), min(x1 - 2, c + ww), y, '#2e2a34')
    sitio = []                                                      # de delante atrás: la de delante, la primera que se llena
    for f in range(filas - 1, -1, -1):
        b = yb - 1 - (filas - 1 - f) * (12 // filas + 1)
        dx = int(paso / 4) * (1 if (filas - 1 - f) % 2 else -1) if filas > 1 else 0   # a tresbolillo, dentro de la carpa
        for c in range(cols):
            sitio.append((cxs[c] + dx, b, 0 if f == filas - 1 else 3))
    for cx_, b, i in sorted(sitio[:n], key=lambda q: q[1]):        # se pintan de atrás adelante
        planta(L, cx_, b, i)
    L.hl(x0 + 2, x1 - 2, yb, '#3a3a40')
    L.contorno(K)
    for x in range(80):
        if L.lleno(x, 78) and not L.lleno(x, 79): L.p(x, 79, K)
    return L

if __name__ == '__main__':
    for spr, (w, d, cols, filas) in NIVELES.items():
        for n in range(cols * filas + 1):
            dd = P('art', 'crudo', 'kaia-carpa', f'{spr}-{n}', 'unica')
            os.makedirs(dd, exist_ok=True)
            for v in glob.glob(os.path.join(dd, '*.png')): os.remove(v)
            L = carpa_kc(w, d, cols, filas, n); L.im.save(os.path.join(dd, '00.png'))
            print('kaia-carpa', f'{spr}-{n}', L.im.getbbox(), len(L.colores()), 'colores')
