# python3 -I tools/sprites/a-mano/casa.py  (Python 3 + Pillow; no va en los scripts de npm)
# Lámina 15 (1.27, reformas del piso): el suelo y las paredes que se piden por la tienda online (REFORMA, 12c-salon) y la alfombra
# del salón, en casillas de 16 × 16 a 16 px/m como las del piso (interior-home, las de serie). Las que son un cambio de color salen de
# las de serie (mismo dibujo): la tarima de nogal y el vinílico gris (el suelo), y la pintura verde salvia y azul grisáceo (la pared,
# sin las rayas del papel). Las otras, dibujadas aquí:
#  · floor-3: porcelánico de dibujo hidráulico (blanco, gris y verde): un rosetón cada 50 cm, que al juntarse hace la flor de 4.
#  · iwT_home-3 / iwB_home-3: plaqueta de ladrillo visto (7 × 2 px y 1 de llaga, a matajunta), seguida de una fila a la otra; la
#    moldura del techo y el rodapié, los de serie.
#  · alf<v><q>[-<suelo>]: la alfombra de 180 × 140 cm (29 × 22 px, centrada en 2 × 2 casillas; q: a b / c d) sobre cada suelo:
#    0 bereber crema (rombos y flecos), 1 persa granate (cenefa azul con filo dorado y medallón) y 2 lisa gris (filo y cenefa).
# Sale a art/crudo/casa-reforma/<sprite>/unica/00.png (después, node tools/sprites/procesar.js casa-reforma --atlas)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
from lienzo import Lienzo, P, rgb, azar

SAL = {}
def sale(n, L):
    SAL[n] = L

def serie(n):
    """la casilla de serie (interior-home), como Lienzo"""
    im = Image.open(P('art', 'crudo', 'interior-home', n, 'unica', '00.png')).convert('RGBA')
    L = Lienzo(16, 16)
    for y in range(16):
        for x in range(16):
            L.px[x, y] = im.getpixel((x, y))
    return L

def hx(c):
    return '#%02x%02x%02x' % tuple(max(0, min(255, v)) for v in c[:3])

def menos(base, d):
    """base (#rrggbb) menos d en cada canal (d: un número o tres)"""
    b = rgb(base); d = d if isinstance(d, tuple) else (d, d, d)
    return hx((b[0] - d[0], b[1] - d[1], b[2] - d[2]))

# ---------- el suelo ----------
# floor de serie: a #e6bc80 (la lama), c #d9af76 (la veta), b #c7a472 (la junta)
FLOOR = ('#e6bc80', '#d9af76', '#c7a472')
def suelo_color(lama, veta, junta):
    return serie('floor').cambia(dict(zip(FLOOR, (lama, veta, junta))))

def hidraulico():
    L = Lienzo(16, 16); B, G, V, S = '#e4e0d6', '#b8bab4', '#6a907a', '#d2cec4'
    for y in range(16):
        for x in range(16):
            dx, dy = abs(x % 8 - 3.5), abs(y % 8 - 3.5); m = max(dx, dy)
            if m == .5: c = V                                         # el botón del centro
            elif dx == dy: c = G if m < 3 else V                      # las diagonales grises y, en la esquina, el verde (con las de al
            elif m == 3.5: c = S                                      # lado, la flor de 4); la llaga de la baldosa, apenas más oscura
            else: c = B
            L.p(x, y, c)
    return L

SUELOS = [None, suelo_color('#8a5e3c', '#7e5434', '#62422a'),     # 1 tarima de nogal
          suelo_color('#b0aca4', '#a6a29a', '#8c8880'),           # 2 vinílico gris piedra
          hidraulico()]                                           # 3 baldosa hidráulica

# ---------- la pared ----------
# iwT_home: e #ead8b4 el papel, f #e0ceaa sus rayas; la moldura del techo: a #d1bf9b, b #c0ae8a, c #ac9a76, d #8c7a5f (de más claro
# a más oscuro, el papel menos 25, 42, 62 y 94/94/85). iwB_home: el papel y, abajo, el rodapié (#dfdfe1 y #fffffe), que no cambia
E, F = '#ead8b4', '#e0ceaa'
MOLD = (('#d1bf9b', 25), ('#c0ae8a', 42), ('#ac9a76', 62), ('#8c7a5f', (94, 94, 85)))
def pintura(base):
    mapa = {E: base, F: base}                                     # la pintura, lisa: sin las rayas del papel
    for c, d in MOLD: mapa[c] = menos(base, d)
    return serie('iwT_home').cambia(mapa), serie('iwB_home').cambia(mapa)

LADRILLO = ('#a8503a', '#b45c42', '#9c4834', '#ba664a'); LLAGA = '#cfc6b6'
def ladrillo(L, filas, y0):
    """plaqueta de ladrillo en las filas dadas de L; y0: la fila de la pared entera (de iwT a iwB) de la primera"""
    for k, y in enumerate(filas):
        Y = y0 + k; hil, r = Y // 3, Y % 3
        for x in range(16):
            X = x + (hil % 2) * 4; c2 = (X // 8) % 2
            if r == 2 or X % 8 == 7: L.p(x, y, LLAGA); continue
            b = LADRILLO[(hil * 3 + c2 * 5 + hil // 2) % 4]
            L.p(x, y, b if r == 0 else menos(b, 14))
    return L

def ladrillo_visto():
    T, B = serie('iwT_home'), serie('iwB_home')
    return ladrillo(T, range(5, 16), 0), ladrillo(B, range(0, 11), 11)

PAREDES = [None, pintura('#b2c4a6'), pintura('#aabac6'), ladrillo_visto()]   # 1 verde salvia, 2 azul grisáceo, 3 ladrillo visto

# ---------- la alfombra (180 × 140 cm: 29 × 22 px en x 2-30 e y 5-26 de las 2 × 2 casillas) ----------
X0, X1, Y0, Y1 = 2, 30, 5, 26
def alfombra(v):
    L = Lienzo(32, 32)
    dentro = lambda x, y, m: X0 + m <= x <= X1 - m and Y0 + m <= y <= Y1 - m
    if v == 0:                                                    # bereber crema: rombos de lana oscura y flecos a los lados cortos
        for y in range(Y0, Y1 + 1):
            for x in range(X0, X1 + 1):
                i, j = x - X0, y - Y0
                c = '#cfc5ac' if not dentro(x, y, 1) else ('#6a5848' if dentro(x, y, 3) and ((i + j) % 6 == 0 or (i - j) % 6 == 0) else '#e4dcc6')
                L.p(x, y, c)
        for y in range(Y0 + 1, Y1, 2): L.p(X0 - 1, y, '#efe8d6'); L.p(X1 + 1, y, '#efe8d6')
    elif v == 1:                                                  # persa granate: cenefa azul, filo dorado y medallón en el centro
        cx, cy = (X0 + X1) / 2, (Y0 + Y1) / 2
        for y in range(Y0, Y1 + 1):
            for x in range(X0, X1 + 1):
                if not dentro(x, y, 1): c = '#5a1a20'
                elif not dentro(x, y, 3): c = '#24305a'
                elif not dentro(x, y, 4): c = '#c8a24e'
                else:
                    d = abs(x - cx) / 1.4 + abs(y - cy)
                    c = '#c8a24e' if d < 1.5 else '#24305a' if d < 4 else '#c8a24e' if d < 5 else '#8c2c30'
                    if (x - X0 - 6) % 9 == 0 and (y - Y0 - 6) % 5 == 0 and d >= 5: c = '#b0484a'
                L.p(x, y, c)
        for y in range(Y0 + 1, Y1, 2): L.p(X0 - 1, y, '#e8e0cc'); L.p(X1 + 1, y, '#e8e0cc')
    else:                                                         # lisa gris: el filo, una cenefa más clara y el pelo moteado
        r = azar(707)
        for y in range(Y0, Y1 + 1):
            for x in range(X0, X1 + 1):
                c = '#6c6f74' if not dentro(x, y, 1) else '#94979c' if dentro(x, y, 2) and not dentro(x, y, 3) else ('#8c8f94' if r() < .18 else '#84878c')
                L.p(x, y, c)
    return L

def sobre(suelo, rug):
    """la alfombra sobre 2 × 2 casillas del suelo, y sus 4 trozos (a b / c d)"""
    F2 = Lienzo(32, 32)
    for oy in (0, 16):
        for ox in (0, 16): F2.pega(suelo, ox, oy)
    F2.pega(rug, 0, 0)
    return [F2.recorta(ox, oy, 16, 16) for oy in (0, 16) for ox in (0, 16)]

for i in range(1, 4):
    sale(f'floor-{i}', SUELOS[i]); sale(f'iwT_home-{i}', PAREDES[i][0]); sale(f'iwB_home-{i}', PAREDES[i][1])
for f in range(4):
    base = SUELOS[f] if f else serie('floor')
    for v in range(3):
        for q, T in zip('abcd', sobre(base, alfombra(v))):
            sale(f'alf{v}{q}' + (f'-{f}' if f else ''), T)

def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'casa-reforma', n, 'unica'); os.makedirs(d, exist_ok=True)
        for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
        L.im.save(os.path.join(d, '00.png'))
    print('casa-reforma', len(SAL), 'casillas')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
