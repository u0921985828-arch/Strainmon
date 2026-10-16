# python3 -I tools/sprites/a-mano/negocios2.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.47 (lo pidió el usuario, con fotos de referencia del taller, la panadería, el bar y la lavandería): el suelo y las paredes
# de cuatro de los locales alquilables, a mano y genéricos (sin marcas ni rótulos de nadie); los muebles de esos locales salen de
# PixelLab (tools/sprites/a-mano/pixellab_negocios.py, ajustados a 16 px/m).
#  · interior-negocios (casillas de 16 × 16):
#    taller: floorTa (resina epoxi azul con brillo), iwT_taller (pared blanca con el tubo azul del aire), iwB_taller (la franja
#      azul, blanca y roja y el zócalo azul)
#    panadería: floorPa (baldosa gris clara de 50 cm), iwT_pan (blanco con la moldura), iwB_pan (azulejo de metro blanco)
#    bar: floorTb (pizarra oscura), iwT_tab (pintura gris azulada), iwB_tab (el machihembrado de pino a media altura)
#    lavandería: floorLv (tarima laminada gris), iwT_lav (azul con burbujas blancas), iwB_lav (azul con el zócalo blanco)
# Sale a art/crudo/interior-negocios/<casilla>/unica/00.png (después, node tools/sprites/procesar.js interior-negocios --atlas)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

SAL = {}
def sale(n, L, grupo='interior-negocios'):
    SAL.setdefault(grupo, {})[n] = L

# ---------- el taller ----------
def floorTa():
    """resina epoxi azul: lisa, con motas y algún brillo de los fluorescentes"""
    L = Lienzo(16, 16); R = azar(4701)
    L.r(0, 0, 16, 16, '#3a62a8')
    for _ in range(4): L.p(int(R() * 16), int(R() * 16), '#3e66ac')   # casi lisa: la resina no tiene juntas
    for x in range(2, 6): L.p(x, 3, '#4670b4')                       # el brillo de los fluorescentes
    return L

def iwT_taller():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#e4e6e8')
    L.r(0, 0, 16, 2, '#9a9ea4'); L.hl(0, 15, 2, '#c4c8cc')           # el techo
    L.hl(0, 15, 6, '#3a7ad0'); L.hl(0, 15, 7, '#2a5aa0')              # el tubo del aire comprimido
    L.r(7, 5, 2, 4, '#8a8e94')                                         # su abrazadera
    return L

def iwB_taller():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#e4e6e8')
    L.r(0, 5, 16, 2, '#2a5ab0'); L.hl(0, 15, 7, '#f4f4f4'); L.r(0, 8, 16, 1, '#c03030')   # la franja azul, blanca y roja
    L.r(0, 11, 16, 5, '#2a5ab0'); L.hl(0, 15, 11, '#3a6ac0'); L.hl(0, 15, 15, '#1a3a78')  # el zócalo
    return L

# ---------- la panadería ----------
def floorPa():
    L = Lienzo(16, 16); R = azar(4702)
    L.r(0, 0, 16, 16, '#d4d2cc')
    for _ in range(14): L.p(int(R() * 16), int(R() * 16), '#c8c6c0' if R() < .5 else '#dedcd6')
    L.hl(0, 15, 7, '#b4b2ac'); L.hl(0, 15, 15, '#b4b2ac'); L.vl(7, 0, 15, '#b4b2ac'); L.vl(15, 0, 15, '#b4b2ac')
    return L

def iwT_pan():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#f2f0ea')
    L.r(0, 0, 16, 3, '#d8d4c8'); L.hl(0, 15, 3, '#bab6aa')            # la moldura
    return L

def iwB_pan():
    """azulejo de metro (10 × 5 cm, a 16 px/m de 2 × 1, aquí de 4 × 2 para que se lea) a matajuntas"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#f6f6f2')
    for y in range(0, 14, 2):
        L.hl(0, 15, y + 1, '#d6d6d0')
        for x in range((y // 2) % 2 * 2, 16, 4): L.p(x, y, '#d6d6d0')
    L.r(0, 14, 16, 2, '#a8a49a')                                       # el rodapié
    return L

# ---------- el bar ----------
def floorTb():
    L = Lienzo(16, 16); R = azar(4703)
    L.r(0, 0, 16, 16, '#3c3e44')
    for _ in range(20): L.p(int(R() * 16), int(R() * 16), '#46484e' if R() < .5 else '#34363a')
    L.hl(0, 15, 15, '#2a2c30'); L.vl(15, 0, 15, '#2a2c30')
    return L

def iwT_tab():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#aab4c2')
    L.r(0, 0, 16, 2, '#e8e2d0'); L.hl(0, 15, 2, '#c8c2b0')            # el techo crema
    return L

def iwB_tab():
    """el machihembrado de pino en horizontal hasta media altura, con el remate"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 4, '#aab4c2')
    L.r(0, 4, 16, 2, '#b88a52'); L.hl(0, 15, 4, '#d0a46a')            # el remate
    for y in range(6, 15):
        L.hl(0, 15, y, '#e0c08a' if y % 3 else '#c09a62')
    for x in (5, 13): L.p(x, 8, '#b08a58'); L.p(x, 11, '#b08a58')      # los nudos
    L.hl(0, 15, 15, '#8a6a40')
    return L

# ---------- la lavandería ----------
def floorLv():
    """tarima laminada gris en tablas de 4 px de ancho y 16 de largo, a la contra, con las juntas suaves"""
    L = Lienzo(16, 16); T = ('#8e9092', '#96989a', '#888a8c', '#929496')
    for y in range(16):
        f = y // 4
        for x in range(16):
            c = '#7c7e80' if y % 4 == 3 else T[f]
            if y % 4 != 3 and x == (f * 5) % 16: c = '#7c7e80'
            L.p(x, y, c)
    return L

def iwT_lav():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#2a5ac8')
    L.r(0, 0, 16, 2, '#e8ecf4'); L.hl(0, 15, 2, '#c4cad8')
    for (x, y, r) in ((4, 8, 2), (12, 12, 1)):  # las burbujas blancas, pocas
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                if dx * dx + dy * dy <= r * r + r: L.p(x + dx, y + dy, '#e8f0ff')
        L.p(x - r // 2, y - r // 2, '#ffffff')
    L.p(9, 5, '#a8c0f0')
    return L

def iwB_lav():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#2a5ac8')
    L.p(4, 3, '#e8f0ff'); L.p(10, 6, '#e8f0ff'); L.p(11, 6, '#e8f0ff')
    L.r(0, 12, 16, 4, '#f0f2f6'); L.hl(0, 15, 12, '#ffffff'); L.hl(0, 15, 15, '#c4c8d0')  # el zócalo blanco
    return L

for f in (floorTa, iwT_taller, iwB_taller, floorPa, iwT_pan, iwB_pan, floorTb, iwT_tab, iwB_tab, floorLv, iwT_lav, iwB_lav):
    sale(f.__name__, f())

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
