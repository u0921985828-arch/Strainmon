# Las vallas por piezas (lo pidió el usuario: «Las vallas tienen que ser tanto en dirección izquierda y derecha como alante a
# atrás, como x, y, porque si no no conectan entre ellas cuando se cambia la dirección»): la valla de madera (fence) y la
# barandilla de la ría (baranda), cada una en 16 piezas por sus vecinas de la misma clase (N = 1, E = 2, S = 4, O = 8).
# Lo de los lados (E, O) sale del sprite aprobado tal cual (su mitad izquierda o derecha); lo de delante y detrás (N, S) es la
# valla vista a lo largo, a 3/4 desde arriba: el larguero como una franja estrecha con su poste en medio.
#   python3 -I tools/sprites/a-mano/vallas.py   → art/crudo/vallas/<clase>-<máscara>/unica/00.png
# Después, node tools/sprites/procesar.js vallas --atlas --atlas-dir godot/arte.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
from lienzo import Lienzo, P
import mundo as M

OUT = M.OUT
N, E, S, O = 1, 2, 4, 8


def carga(*ruta):
    im = Image.open(P(*ruta)).convert('RGBA')
    lz = Lienzo(im.width, im.height)
    for y in range(im.height):
        for x in range(im.width):
            c = im.getpixel((x, y))
            if c[3] > 127:
                lz.p(x, y, (c[0], c[1], c[2], 255))
    return lz


def copia(lz, src, x0, x1):
    for y in range(16):
        for x in range(x0, x1 + 1):
            if src.lleno(x, y):
                lz.p(x, y, src.g(x, y))


# ------------------------------------------------------------------------------------------------------------ madera
FK, FB, FC, FM, FS = '#202024', '#3a2a20', '#c49464', '#b07a4a', '#74502e'   # contorno, borde, cara, medio, sombra


def poste_madera(lz, y0=3):
    """el poste de en medio (x 6..9) de su punta a los pies, con los dos largueros marcados"""
    for y in range(y0, 16):
        lz.p(6, y, FB); lz.p(9, y, FB)
        lz.p(7, y, FC if y > y0 else FK); lz.p(8, y, FM if y > y0 else FK)
    lz.hl(7, 8, y0 + 1, FC)
    for y in (7, 12):
        lz.hl(6, 9, y, FK)
    lz.hl(6, 9, 15, FK)


def largo_madera(lz, y0, y1):
    """la valla vista a lo largo: los dos largueros de canto, una franja de 4 px con su sombra a la derecha"""
    for y in range(y0, y1 + 1):
        lz.p(6, y, FK); lz.p(7, y, FC); lz.p(8, y, FM); lz.p(9, y, FS); lz.p(10, y, FK)


def fence(m, base):
    lz = Lienzo(16, 16)
    if m in (0, E | O):
        return base
    if m & O:
        copia(lz, base, 0, 5)
    if m & E:
        copia(lz, base, 10, 15)
    if m & N:
        largo_madera(lz, 0, 4)
    if m & S:
        largo_madera(lz, 8, 15)
    poste_madera(lz)
    if m in (E, O):   # el remate solo: el poste de en medio del sprite aprobado
        copia(lz, base, 6, 9)
    return lz


# ------------------------------------------------------------------------------------------------------- barandilla
VK, VL, V = '#1e3a30', '#4e8068', '#2f5a48'   # sombra, pasamanos, hierro


def poste_baranda(lz):
    lz.r(7, 1, 2, 14, V); lz.hl(7, 8, 1, VL); lz.hl(6, 9, 2, VL); lz.hl(6, 9, 3, VK); lz.hl(7, 8, 14, VK)


def largo_baranda(lz, y0, y1):
    """la barandilla vista a lo largo: el pasamanos de frente (claro) con su canto en sombra y los barrotes debajo"""
    for y in range(y0, y1 + 1):
        lz.p(6, y, VK); lz.p(7, y, VL); lz.p(8, y, VL); lz.p(9, y, VK)
        if y % 3 == 0:
            lz.p(10, y, V)


def baranda(m, base):
    lz = Lienzo(16, 16)
    if m in (0, E | O, E, O):
        return base
    if m & O:
        copia(lz, base, 0, 7)
    if m & E:
        copia(lz, base, 8, 15)
    if m & N:
        largo_baranda(lz, 0, 3)
    if m & S:
        largo_baranda(lz, 3, 15)
    poste_baranda(lz)
    return lz


SPRITES = {
    'fence': lambda b=None: [M.sale(fence(m, carga('art', 'procesado', 'props-16', 'fence', 'unica', '00.png')), 'vallas', 'fence-%d' % m) for m in range(16)],
    'baranda': lambda b=None: [M.sale(baranda(m, carga('art', 'procesado', 'props-bilbao', 'baranda', 'unica', '00.png')), 'vallas', 'baranda-%d' % m) for m in range(16)],
}

if __name__ == '__main__':
    for k in sys.argv[1:] or list(SPRITES):
        SPRITES[k]()
    print(len(OUT), 'piezas')
