# python3 -I tools/sprites/a-mano/muelle_obras.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.52 (lo pidió el usuario: «el barrio del puerto viejo… comenzar destartalado… ir reformándolo poco a poco, edificio por edificio…
# montar otro club ahí»): el muelle de la cofradía, abandonado, a 16 px/m.
#  · Fachadas en ruina (las de mundo.py, de las casas marineras del muelle): la pintura desvaída y desconchada, con la piedra a la
#    vista, chorretones de óxido y humedad debajo de las ventanas y los cristales tapiados con tablones. edificio-<casa>-ruina.
#  · El club del muelle, KAIA, en la casa blanca rehabilitada: la fachada de mundo.py con la placa de latón y la hoja en la puerta.
#  · dockR: el pantalán podrido, con tablones rotos y el agua por el hueco (muelle-tiles).
# Sale a art/crudo/<grupo>/… (después, node tools/sprites/procesar.js edificio-marinera3-ruina edificio-marinera4-ruina
# edificio-marinera5-ruina edificio-marinera6-ruina edificio-club-kaia muelle-tiles --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar, rgb
from PIL import Image

def carga(k):
    im = Image.open(P('art', 'crudo', 'edificio-' + k, 'base', 'unica', '00.png')).convert('RGBA')
    L = Lienzo(im.width, im.height); L.im = im; L.px = im.load()
    return L

def lum(c):
    return (c[0] * 3 + c[1] * 6 + c[2]) / 10

def pared(L):
    """el color de la pared: el más repetido de los opacos"""
    n = {}
    for y in range(L.h):
        for x in range(L.w):
            c = L.g(x, y)
            if c[3]:
                n[c[:3]] = n.get(c[:3], 0) + 1
    return max(n, key=n.get)

def tejado(L):
    """la última fila del tejado: hasta donde llega el color más repetido de las 12 de arriba"""
    n = {}
    for y in range(12):
        for x in range(L.w):
            c = L.g(x, y)
            if c[3]: n[c[:3]] = n.get(c[:3], 0) + 1
    if not n: return 0
    t = max(n, key=n.get); u = 0
    for y in range(L.h // 2):
        if any(L.g(x, y)[:3] == t for x in range(L.w)): u = y
    return u

def ruina(k, sem):
    L = carga(k); R = azar(sem); W = pared(L)
    T = tejado(L)
    cerca0 = lambda c: c[3] and sum(abs(c[i] - W[i]) for i in range(3)) < 70
    cerca = lambda c, y=99: cerca0(c)
    # 1 · los cristales: tablones de madera vieja en horizontal, con su clavo
    vid = [(x, y) for y in range(L.h) for x in range(L.w) if L.g(x, y)[3] and lum(L.g(x, y)) < 95 and L.g(x, y)[2] >= L.g(x, y)[0]]
    tab = ('#8a6a44', '#6e5234', '#a08058')
    for (x, y) in vid:
        L.p(x, y, tab[(y // 2) % 2] if y % 2 else '#4a3624')
    for (x, y) in vid:
        if (x * 7 + y * 3) % 23 == 0: L.p(x, y, '#c8c0b0')
    # 2 · la pintura desvaída: hacia el gris y más oscura, a manchas
    for y in range(L.h):
        for x in range(L.w):
            c = L.g(x, y)
            if y > T and cerca(c):
                g = lum(c); f = .45 + .1 * ((x // 3 + y // 4) % 2)
                L.p(x, y, tuple(int((c[i] * (1 - f) + g * f) * .86) for i in range(3)) + (255,))
    # 3 · desconchones: la piedra y el ladrillo a la vista
    for _ in range(6):
        x0, y0 = int(R() * (L.w - 8)), int(16 + R() * (L.h - 24))
        w, h = 3 + int(R() * 5), 2 + int(R() * 3)
        for j in range(h):
            for i in range(w):
                if (i in (0, w - 1) and j in (0, h - 1)) or not cerca(L.g(x0 + i, y0 + j)) and L.g(x0 + i, y0 + j)[3] == 0:
                    continue
                if L.g(x0 + i, y0 + j)[3] and lum(L.g(x0 + i, y0 + j)) > 60:
                    L.p(x0 + i, y0 + j, '#9a5a42' if (j + (i // 3)) % 2 else '#8a7a68')
    # 4 · chorretones de óxido y humedad bajo los alféizares
    for (x, y) in vid:
        if not (x, y + 1) in vid and L.g(x, y + 3)[3] and R() < .25:
            for j in range(3, 3 + int(3 + R() * 6)):
                c = L.g(x, y + j)
                if c[3] and lum(c) > 70:
                    L.p(x, y + j, tuple(int(c[i] * .72) for i in range(3)) + (255,))
    # 5 · grietas
    for _ in range(3):
        x, y = int(4 + R() * (L.w - 8)), int(20 + R() * (L.h - 30))
        for _ in range(8):
            if L.g(x, y)[3] and lum(L.g(x, y)) > 60:
                L.p(x, y, '#3a3430')
            x += 1 if R() < .5 else -1; y += 1
    return L

def kaia():
    """la casa blanca rehabilitada: la placa de latón con KAIA sobre la puerta y la hoja en el cristal"""
    L = carga('marinera5')
    W = pared(L)
    # la puerta: el bloque de color de abajo en el centro; la placa, encima
    cx = L.w // 2
    pc = L.g(cx, L.h - 8)                      # la puerta: su color, de abajo arriba hasta donde deja de serlo
    y0 = L.h - 8
    while y0 > 0 and sum(abs(L.g(cx, y0 - 1)[i] - pc[i]) for i in range(3)) < 60:
        y0 -= 1
    y0 -= 2                                     # el recercado de encima
    yp = 85                                    # encima del recercado de la puerta (de y = 84 abajo)
    L.r(cx - 9, yp - 6, 18, 6, '#7a5a1e'); L.r(cx - 8, yp - 5, 16, 4, '#d8b048'); L.hl(cx - 8, cx + 7, yp - 5, '#f0d880')
    let = {'K': ['101', '110', '101'], 'A': ['010', '111', '101'], 'I': ['1', '1', '1']}
    x = cx - 7
    for ch in 'KAIA':
        for j, f in enumerate(let[ch]):
            for i, b in enumerate(f):
                if b == '1': L.p(x + i, yp - 4 + j, '#3a2a0e')
        x += len(let[ch][0]) + 1
    # el farol de cada lado
    for fx in (cx - 13, cx + 12):
        L.r(fx, yp - 4, 2, 4, '#26262e'); L.p(fx, yp - 3, '#f8e070'); L.p(fx + 1, yp - 2, '#f8d040')
    return L

def dockR():
    """el pantalán podrido: los tablones de dock con dos rotos y el agua por el hueco"""
    im = Image.open(P('art', 'procesado', 'tiles-exterior', 'dock', 'unica', '00.png')).convert('RGBA')
    L = Lienzo(16, 16); L.im = im.copy(); L.px = L.im.load()
    for y in range(5, 10):
        for x in range(3, 9):
            L.p(x, y, '#3a6a9a' if (x + y) % 3 else '#5a8ac0')
    L.hl(3, 8, 4, '#3a2a1a'); L.hl(3, 8, 10, '#3a2a1a')
    for x in (3, 5, 7): L.p(x, 9, '#5a4028')        # astillas
    for (x, y) in ((11, 6), (12, 7), (13, 8), (10, 12)): L.p(x, y, '#2e2418')   # grietas
    for x in range(10, 15): L.p(x, 13, '#6a7a40' if x % 2 else '#4a5a30')        # verdín
    return L

SAL = {}
for k, s in (('marinera3', 31), ('marinera4', 32), ('marinera5', 33), ('marinera6', 34)):
    SAL['edificio-%s-ruina' % k] = ruina(k, s)
SAL['edificio-club-kaia'] = kaia()

def escribe():
    for g, L in SAL.items():
        d = P('art', 'crudo', g, 'base', 'unica'); os.makedirs(d, exist_ok=True)
        for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
        L.im.save(os.path.join(d, '00.png')); print(g, L.im.size, len(L.colores()), 'colores')
    d = P('art', 'crudo', 'muelle-tiles', 'dockR', 'unica'); os.makedirs(d, exist_ok=True)
    D = dockR(); D.im.save(os.path.join(d, '00.png')); print('muelle-tiles dockR', len(D.colores()), 'colores')

if __name__ == '__main__':
    escribe()
