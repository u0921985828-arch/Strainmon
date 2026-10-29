# python3 -I tools/sprites/a-mano/kaia_carpa.py  (Python 3 + Pillow)
# Las carpas de la sala de cultivo de KAIA, hechas como las de casa (lo pidió el usuario: «así no son las carpas, como te he dicho
# que las haga, de como están hechas en casa»): salen de la carpa de 150 del piso (carpa-g150-mapa, de PixelLab, ya procesada) como
# carpas.py saca la de 80 y la de 120, repitiendo solo columnas y filas que ya están en el sprite (misma paleta, mismo contorno):
# negras y cerradas, el techo a medio fondo con su lado de luz a la izquierda y el de sombra a la derecha, la barra plateada del
# armazón y la puerta con su cremallera. A 16 px/m como en casa: el frente, su alto real (2 m, 32 filas; la de sala, 2,5 m) y el
# techo, por el fondo (8 filas por metro; la de sala, toda su huella).
#  · la de 150 (24 × 40): columnas 0 poste de luz, 1-2 tela de luz, 3 cremallera, 4-9 la puerta, 10 cremallera, 11 tela de luz,
#    12-22 el lado de sombra, 23 poste; filas 0-1 canto del techo, 2-6 techo, 7 barra plateada, 8-38 el frente (la puerta de la 11 a
#    la 38) y 39 el pie.
#  · kcs, la de 200 × 200 (32 × 48); kcm, la de 400 × 200 con dos puertas (64 × 48); kcl, la de 400 × 400 (64 × 64); kcx, la de
#    sala de 1.300 × 700 × 250 con la puerta para entrar andando en la casilla 6 (208 × 112), la luz hasta pasada la puerta.
# Celda carpa_kc de 80 × 80 (kcs, kcm, kcl) y carpa_kx de 208 × 112 (kcx), con la base en la fila de abajo y el mueble en sus
# casillas desde x 0. El tubo de extracción de cada una a la pared lo pinta el juego (kaiacult.gd, como el de casa).
# Sale a art/crudo/kaia-carpa/<kcs|kcm|kcl>/unica/00.png y art/crudo/kaia-carpa-sala/kcx/unica/00.png (después,
# node tools/sprites/procesar.js kaia-carpa kaia-carpa-sala --atlas --atlas-dir godot/arte)
import os, sys, glob, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
from carpas import columnas, filas, lee
from lienzo import P

LUZ = 1                      # una columna de tela de luz (techo claro, frente liso)
TECHO = (2, 6)               # las filas del techo que se alargan

def estira(a, b, n):
    """n índices repartidos de a a b (los dos incluidos), cada uno repetido lo que toque"""
    return [a + (i * (b - a + 1)) // n for i in range(n)]

def puerta(n):
    """la puerta de n columnas: cremallera, la tela de dentro (4-9) y cremallera"""
    return [3] + estira(4, 9, n - 2) + [10]

def cols_kc(w):
    """las columnas de la carpa de w metros: la mitad de luz con su puerta (dos en las de 4 m) y la mitad de sombra"""
    px = w * 16
    if w == 2:
        luz = [0, 1, 2] + puerta(11) + [11]
    else:
        luz = [0, 1, 2] + puerta(11) + [LUZ] * 5 + puerta(11) + [11]
    return luz + estira(12, 22, px - len(luz) - 1) + [23]

def cols_sala(px, xp, wp, xs):
    """la de sala: tela de luz, la puerta de wp columnas en xp, tela de luz hasta xs y el lado de sombra hasta el poste"""
    c = [0, 1, 2] + [LUZ] * (xp - 3) + puerta(wp)
    c += [LUZ] * (xs - len(c) - 1) + [11]
    return c + estira(12, 22, px - len(c) - 1) + [23]

def rows(techo, frente, puerta_h=28):
    """las filas: el techo de `techo` filas (con su barra) y el frente de `frente`, con la puerta de puerta_h filas"""
    t = [0, 1] + estira(TECHO[0], TECHO[1], techo - 3) + [7]
    cuerpo = puerta_h - 2                                           # la puerta: filas 11-12 de arriba y su cuerpo (13-38)
    f = [8] + estira(9, 10, frente - 4 - cuerpo) + [11, 12] + estira(13, 38, cuerpo) + [39]
    return t + f

# el armazón por debajo del techo, en las grandes (cada 2 m más o menos): los travesaños, una arista de luz con los colores del techo
LUZ_DE = {(0x45, 0x47, 0x4e): ((0x4c, 0x55, 0x60), (0x30, 0x30, 0x38)), (0x30, 0x30, 0x38): ((0x45, 0x47, 0x4e), (0x20, 0x20, 0x24))}

def armazon(im, techo, xs=(), ys=()):
    px = im.load()
    def arista(x, y, luz):
        c = px[x, y]
        if c[3] and c[:3] in LUZ_DE:
            px[x, y] = LUZ_DE[c[:3]][0 if luz else 1] + (255,)
    for y in ys:                                                    # a lo ancho: luz arriba, sombra debajo
        for x in range(1, im.width - 1):
            arista(x, y, True)
    for x in xs:                                                    # hacia el fondo: luz a la izquierda, sombra a la derecha
        for y in range(2, techo - 1):
            if y in ys or y - 1 in ys: continue
            arista(x, y, True); arista(x + 1, y, False)
    return im

def en_celda(im, w, h):
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    out.paste(im, (0, h - im.height), im)
    return out

def guarda(im, asset, spr):
    d = P('art', 'crudo', asset, spr, 'unica')
    os.makedirs(d, exist_ok=True)
    for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
    im.save(os.path.join(d, '00.png'))
    print(asset, spr, im.size, im.getbbox(), len({p for p in im.get_flattened_data() if p[3]}), 'colores')

NIVELES = {'kcs': (2, 2), 'kcm': (4, 2), 'kcl': (4, 4)}   # ancho y fondo (m), 2 m de alto

if __name__ == '__main__':
    g = lee('art/procesado/carpas-mapa/carpa-g150-mapa/unica/00.png')
    assert g.size == (24, 40), g.size
    for v in glob.glob(P('art', 'crudo', 'kaia-carpa', 'kc*')):   # las de antes (abiertas, kcs-<n>…), fuera
        shutil.rmtree(v)
    for spr, (w, d) in NIVELES.items():
        im = filas(columnas(g, cols_kc(w)), rows(d * 8, 32))
        if d == 4:
            armazon(im, d * 8, ys=(d * 4 - 1,))                          # la de 400 × 400, el travesaño de en medio
        assert im.size == (w * 16, d * 8 + 32), (spr, im.size)
        guarda(en_celda(im, 80, 80), 'kaia-carpa', spr)
    # la de sala: 13 × 7 casillas, 2,5 m de alto (40 filas) y el techo hasta el fondo de su huella (72); la puerta de 2 m (32 filas)
    # en la casilla 6 (x 96, la de C.puerta en kaia_cult.py), de 14 columnas de tela entre sus cremalleras
    im = filas(columnas(g, cols_sala(208, 97, 14, 150)), rows(72, 40, 32))
    armazon(im, 72, ys=(19, 39, 58))
    assert im.size == (208, 112), im.size
    guarda(im, 'kaia-carpa-sala', 'kcx')
