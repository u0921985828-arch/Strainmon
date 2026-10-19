# python3 -I tools/sprites/a-mano/movil.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.51 (lo pidió el usuario: «cuando le das al móvil no aparece ningún icono… que fuese una pantalla de un móvil, con el diseño
# del juego, estilo a cuando abres la caja fuerte»): el móvil por dentro, a mano, con el contorno y la luz de los visores del almacén.
# Todo con el ancla arriba a la izquierda (0, 0); el juego pone encima la hora, la batería, los avisos y el marco del elegido:
#  · mv-movil (80 × 120): la carcasa negra con sus cantos, el altavoz, la cámara, los botones del lado y la pantalla (70 × 100 en
#    (5, 9)) con el fondo verde de la casa: una hoja de siete foliolos en sombra;
#  · mv-<app> (18 × 18): los iconos de las aplicaciones, cuadrados redondeados de color con su dibujo en blanco: llamar (el
#    auricular), kiko (la maceta con su brote), sms (el sobre), gente (dos cabezas), plantilla (la carpeta con pinza), banca (la
#    tarjeta), tienda (el carro), cal (la hoja del mes) y mapa (el plano doblado con la chincheta).
# Sale a art/crudo/movil/<sprite>/unica/00.png (después, node tools/sprites/procesar.js movil --atlas)
import os, sys, glob, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

K = '#2a2a34'
SAL = {}
def sale(n, L): SAL[n] = L

def redondo(L, x, y, w, h, r, c):
    """un rectángulo con las esquinas redondeadas (radio r)"""
    for j in range(h):
        for i in range(w):
            dx = max(0, r - i - 1, i - (w - r)); dy = max(0, r - j - 1, j - (h - r))
            if dx * dx + dy * dy <= r * r - r * .4: L.p(x + i, y + j, c)

# ---------- el móvil ----------
C0, C1, C2, C3 = '#101014', '#1c1c24', '#2e2e3a', '#4a4a58'   # la carcasa, de sombra a brillo
V0, V1, V2 = '#0e2a1c', '#143826', '#1c4a32'                  # el fondo de pantalla, verde de la casa
def movil():
    L = Lienzo(80, 120)
    redondo(L, 0, 0, 80, 120, 9, C0)
    redondo(L, 1, 1, 78, 118, 8, C1)
    for x in range(8, 72): L.p(x, 1, C3)                       # el canto con la luz arriba a la izquierda
    for y in range(8, 112): L.p(1, y, C2)
    L.r(79, 30, 1, 8, C2); L.r(79, 44, 1, 14, C2)              # los botones del lado
    L.r(31, 4, 18, 2, C0); L.hl(32, 47, 4, '#3a3a46')          # el altavoz
    L.r(53, 4, 2, 2, '#30406a'); L.p(53, 4, '#7088c0')         # la cámara
    # la pantalla: el verde de la casa y, en sombra, una hoja de siete foliolos
    L.r(5, 9, 70, 100, V0)
    for j in range(100):
        for i in range(70):
            if (i * 3 + j * 2) % 23 == 0: L.p(5 + i, 9 + j, V1)
    cx, cy = 40, 74
    for a, ln in ((-90, 22), (-55, 19), (-125, 19), (-22, 14), (-158, 14), (12, 9), (168, 9)):
        r = math.radians(a)
        for t in range(ln):
            ancho = max(0, int(round(2.6 * math.sin(math.pi * t / ln))))
            px, py = cx + math.cos(r) * t, cy + math.sin(r) * t
            for k in range(-ancho, ancho + 1):
                L.p(int(round(px - math.sin(r) * k)), int(round(py + math.cos(r) * k)), V2)
    L.vl(40, 74, 84, V2)
    L.r(5, 9, 70, 8, '#0a1e14')                                # la barra de arriba
    L.r(29, 104, 22, 2, '#5a7a68')                             # la barra de inicio
    return L

# ---------- las aplicaciones ----------
B = '#f6f6ee'
def app(c0, c1, c2):
    L = Lienzo(18, 18)
    redondo(L, 0, 0, 18, 18, 4, K)
    redondo(L, 1, 1, 16, 16, 3, c1)
    L.hl(4, 13, 1, c2); L.vl(1, 4, 13, c2)
    L.hl(4, 13, 16, c0); L.vl(16, 4, 13, c0)
    return L

def dibujo(L, filas, cols):
    for j, f in enumerate(filas):
        for i, ch in enumerate(f):
            if ch != '.': L.p(3 + i, 3 + j, cols[ch])

def llamar():
    L = app('#1e7a3a', '#2fa04e', '#6cd88a')
    dibujo(L, ['............',
               '.ww.........',
               'wwww........',
               'wwww........',
               '.ww.........',
               '..ww........',
               '...ww.......',
               '....ww..ww..',
               '.....wwwwww.',
               '......wwww..',
               '............',
               '............'], {'w': B})
    return L

def kiko():
    L = app('#7a4a1e', '#a86a30', '#d89a58')
    dibujo(L, ['.....g......',
               '....ggg.g...',
               '..g..g.gg...',
               '..gg.g.g....',
               '...ggggg....',
               '.....g......',
               '..wwwwwww...',
               '..wwwwwww...',
               '...wwwww....',
               '...wwwww....',
               '....www.....',
               '............'], {'w': B, 'g': '#9ce07a'})
    return L

def sms():
    L = app('#1e4a8a', '#3070c0', '#78a8e8')
    dibujo(L, ['............',
               '............',
               'wwwwwwwwwwww',
               'ww........ww',
               'w.w......w.w',
               'w..w....w..w',
               'w...wwww...w',
               'w..........w',
               'wwwwwwwwwwww',
               '............',
               '............',
               '............'], {'w': B})
    return L

def gente():
    L = app('#5a2a7a', '#8048a8', '#b888d8')
    dibujo(L, ['............',
               '.......ww...',
               '..ww..wwww..',
               '.wwww.wwww..',
               '.wwww..ww...',
               '..ww..wwwww.',
               '.wwww.wwwww.',
               'wwwwwwwwwwww',
               'wwwwwwwwwwww',
               '............',
               '............',
               '............'], {'w': B})
    return L

def plantilla():
    L = app('#8a6010', '#c08a20', '#e8c060')
    dibujo(L, ['....kkkk....',
               '.wwwkwwkwww.',
               '.wwwwwwwwww.',
               '.w........w.',
               '.w.kkkkkk.w.',
               '.w........w.',
               '.w.kkkkk..w.',
               '.w........w.',
               '.w.kkkkkk.w.',
               '.w........w.',
               '.wwwwwwwwww.',
               '............'], {'w': B, 'k': '#5a4010'})
    return L

def banca():
    L = app('#14306a', '#204a9a', '#5a80d0')
    dibujo(L, ['............',
               '............',
               'wwwwwwwwwwww',
               'wwwwwwwwwwww',
               'kkkkkkkkkkkk',
               'wwwwwwwwwwww',
               'wooww.wwwwww',
               'wooww.wwwwww',
               'wwwwwwwwwwww',
               '............',
               '............',
               '............'], {'w': B, 'k': K, 'o': '#e8c040'})
    return L

def tienda():
    L = app('#8a1e1e', '#c03030', '#e87070')
    dibujo(L, ['............',
               'ww..........',
               '.w..........',
               '.wwwwwwwwwww',
               '.ww.w.w.w.w.',
               '..wwwwwwwww.',
               '..w.w.w.ww..',
               '..wwwwwwww..',
               '..w.........',
               '..wwwwwwww..',
               '...ww...ww..',
               '...ww...ww..'], {'w': B})
    return L

def cal():
    L = app('#9a9a92', '#e8e8e0', '#ffffff')
    dibujo(L, ['..k.....k...',
               'rrkrrrrrkrrr',
               'rrrrrrrrrrrr',
               '............',
               '.k.k.k.k.k..',
               '............',
               '.k.k.k.r.k..',
               '............',
               '.k.k.k.k.k..',
               '............',
               '.k.k........',
               '............'], {'k': K, 'r': '#d03028'})
    return L

def mapa():
    L = app('#2a6a6a', '#3a9090', '#80c8c0')
    dibujo(L, ['.......rr...',
               '......rrrr..',
               'yyy.ccrrrrcc',
               'yyyycccrrccc',
               'yyyycccrrccc',
               'yyyyccccrccc',
               'yyyyccccccyc',
               'yygyyccccyyc',
               'yyggyyccyyyc',
               'yyygggyyyycc',
               'yyyyccccccc.',
               '............'], {'y': '#f0e0a8', 'c': '#d8c888', 'g': '#5aa050', 'r': '#e03838'})
    return L

def pisos():   # MAESTRO [9]: los pisos de venta, un bloque con su llave
    L = app('#6a3a20', '#b06a3a', '#e0a070')
    dibujo(L, ['..wwwwwww...',
               '..wbwbwbw...',
               '..wwwwwww...',
               '..wbwbwbw...',
               '..wwwwwww...',
               '..wbwbwbw...',
               '..wwwwwww...',
               '..wbwwwbw...',
               '..www.www.yy',
               '......yyyyky',
               '.........yy.',
               '............'], {'w': '#ffffff', 'b': '#4a2a18', 'y': '#f8d040', 'k': '#6a3a20'})
    return L

sale('mv-movil', movil())
for n, f in (('llamar', llamar), ('kiko', kiko), ('sms', sms), ('gente', gente), ('plantilla', plantilla), ('banca', banca),
             ('tienda', tienda), ('cal', cal), ('mapa', mapa), ('pisos', pisos)):
    sale('mv-' + n, f())

def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'movil', n, 'unica'); os.makedirs(d, exist_ok=True)
        for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
        L.im.save(os.path.join(d, '00.png'))
        print('movil', n, L.im.size, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
