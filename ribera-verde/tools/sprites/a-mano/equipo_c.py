# python3 -I tools/sprites/a-mano/equipo_c.py  (Python 3 + Pillow; no va en los scripts de npm)
# El equipo de la vista C que faltaba (1.10, P3), dibujado a mano con la paleta de la campana y la maceta aprobadas (imagen A):
#  · carpa-c-focos-led: los LED a su ancho en cada carpa (FOCO_CM × Z: 1,02 en la de 60, 0,88 en la de 80 y 0,78 en las de 200 cm),
#    todos de barras (1.10: como los de 720 W de 8 barras; 3, 4, 6 y 8 barras), vistos de frente y algo desde abajo (como la campana:
#    se ve la cara que alumbra), colgados de sus cuerdas con trinquete; y el CFL
#    de las carpas de 200 cm (foco-c-cfl-25), la campana aprobada (foco-c-cfl-36) con columnas y filas quitadas, sin colores nuevos.
#    Celda foco_c (48 × 16) y, los de 480 y 720 (carpa-c-focos-led-ancho), foco_c_ancho (80 × 16): la boca en la última fila, centrada (ajuste exacto).
#  · carpa-c-macetas-b: tela de 11 L (gris), plástico de 18 L (la de 7 L aprobada, más ancha y más alta) y tela de 25 L (beis),
#    celda maceta_c (32 × 32), la base centrada en (16, 31).
#  · carpa-c-extras: ventilador de pinza (4 fotogramas de aspas), filtro de carbón con su extractor (2 largos), garrafa de riego
#    (5 altos; el agua la pone el motor en los píxeles «dentro», #2a3a44), llave del goteo y el depósito en pequeño (el nivel, el motor).
# Sale a art/crudo/<grupo>/<sprite>/unica/NN.png (después, node tools/sprites/procesar.js <grupo> --atlas)
import os, sys, glob, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, rgb
from PIL import Image

K = '#000000'                                                  # contorno (el de la campana y la maceta)
M0, M1, M2, M3, MC = '#202e34', '#304046', '#3d4c4e', '#7a8584', '#655a48'   # metal de la campana: sombra, medio, luz, brillo y reflejo cálido
C0, C1 = '#1c1d22', '#3a3c44'                                  # cuerda y trinquete
LB, LR = '#ffffff', '#f8d8ff'                                 # diodos encendidos: blanco y rosa claro (apagados, gris: vcApagado)
SAL = {}                                                       # grupo → {sprite: [Lienzo, …]}

def sale(grupo, n, *fs):
    SAL.setdefault(grupo, {})[n] = list(fs)

def cuerdas(L, xs, y1, tr=True):   # cuerdas del techo (fila 0) a la fila y1, con su trinquete a media altura
    for x in xs:
        L.vl(x, 0, y1, C0)
        if tr: L.r(x - 1, 3, 3, 2, C1); L.p(x - 1, 3, M3)

# ---------- focos LED ----------
def barras(w, n, cw=48, driver=True):
    """LED de barras (como los de 720 W de 8 barras): n barras de fondo a fondo, delgadas y con aire entre ellas, unidas por el
    travesaño de delante y colgadas de 4 cuerdas (se ven 2); la fuente, encima en el centro. De frente y algo desde abajo: el travesaño,
    la punta de cada barra y su cara de diodos encendida (blanca y rosa), y entre barra y barra se ve el techo de la carpa"""
    L = Lienzo(cw, 16); x0 = (cw - w) // 2; x1 = x0 + w - 1; bw = 5 if w >= 60 else 4
    cuerdas(L, (x0 + 1, x1 - 1), 10)
    if driver:
        dw = max(6, round(w * .18)); dx = (cw - dw) // 2
        L.caja(dx, 6, dw, 4, M1, K); L.hl(dx + 1, dx + dw - 2, 7, M2); L.p(dx + dw - 2, 8, '#e8644c'); L.p(dx + 1, 8, M3)
    L.hl(x0, x1, 10, K); L.hl(x0 + 1, x1 - 1, 11, M2); L.p(x0, 11, K); L.p(x1, 11, K); L.p(x0 + 1, 11, M3)   # travesaño
    L.hl(x0, x1, 12, K)
    for i in range(n):
        bx = x0 + round(i * (w - bw) / (n - 1)); bx1 = bx + bw - 1
        L.hl(bx + 1, bx1 - 1, 12, M1)                                     # la punta de la barra, bajo el travesaño
        for y in (12, 13, 14, 15): L.p(bx, y, K); L.p(bx1, y, K)
        for y in (13, 14, 15):                                            # su cara: diodos blancos (espectro completo) con algún rosa
            for x in range(bx + 1, bx1): L.p(x, y, LR if (x + 2 * y) % 3 == 0 else LB)
    return L

# LED 100 (25 cm): 26 en la de 60, 22 en la de 80, 20 en las de 200 · LED 200 (30 cm): 31, 26 y 23 · 480 (60): 47 · 720 (100): 78
# todos de barras: 3 el de 100, 4 el de 200, 6 el de 480 y 8 el de 720
sale('carpa-c-focos-led', 'foco-c-led100-26', barras(26, 3, driver=False))
sale('carpa-c-focos-led', 'foco-c-led100-20', barras(20, 3, driver=False))
sale('carpa-c-focos-led', 'foco-c-led200-30', barras(30, 4))
sale('carpa-c-focos-led', 'foco-c-led200-24', barras(24, 4))
sale('carpa-c-focos-led-ancho', 'foco-c-led480-47', barras(47, 6, 80))   # 47 no cabe en la de 48 sin tocar el borde
sale('carpa-c-focos-led-ancho', 'foco-c-led720-78', barras(78, 8, 80))

# CFL de las carpas de 200 cm (35 cm × 0,78 = 27): la campana aprobada sin 9 columnas ni 3 filas (repartidas, ni el contorno ni el
# tubo), 25 px (con 27, el armario 80, de 31, se quedaría esta y no la de 34); sin colores nuevos
def quita(im, cols, filas):
    w, h = im.size; xs = [x for x in range(w) if x not in cols]; ys = [y for y in range(h) if y not in filas]
    o = Image.new('RGBA', (len(xs), len(ys)), (0, 0, 0, 0))
    for j, y in enumerate(ys):
        for i, x in enumerate(xs): o.putpixel((i, j), im.getpixel((x, y)))
    return o
cfl = Image.open(P('art', 'procesado', 'carpa-c-focos-cfl', 'foco-c-cfl-36', 'unica', '00.png')).convert('RGBA').crop((7, 0, 41, 16))
c25 = quita(cfl, {3, 5, 8, 10, 23, 25, 27, 29, 31}, {2, 5, 8})
L = Lienzo(48, 16); o = Image.new('RGBA', (48, 16), (0, 0, 0, 0)); o.alpha_composite(c25, ((48 - c25.width) // 2, 16 - c25.height)); L.im = o; L.px = o.load()
sale('carpa-c-focos-led', 'foco-c-cfl-25', L)

# ---------- macetas ----------
# a la escala de la de 7 L aprobada (22 × 27 px para 22 × 20 cm a Z 1,02): ancho = diámetro × Z y alto = alto × Z × 1,3 (el borde
# y la tierra vistos desde arriba)
T0, T1, T2 = '#1e150c', '#3a2a1c', '#5a3a20'                   # tierra: sombra, media y terrón
def tela(w, h, tonos, sem):
    """maceta de tela: cilindro de lados rectos, borde vuelto y cosido arriba, asas a los lados, tierra dentro y la tela con su trama"""
    o, m, l, b = tonos                                          # sombra, medio, luz y brillo
    L = Lienzo(32, 32); iw = w - 2; x0 = 16 - iw // 2; x1 = x0 + iw - 1; e = max(5, round(w * .34)); y0 = 31 - (h - 2)
    rx, ry = iw / 2, e / 2; cx = x0 + rx; yc = y0 + ry; yb = 30 - 1
    den = lambda x, y, cy, a, bb: ((x + .5 - cx) / a) ** 2 + ((y + .5 - cy) / bb) ** 2 <= 1
    for y in range(y0, 31):
        for x in range(x0, x1 + 1):
            cuerpo = yc <= y <= yb or den(x, y, yb, rx, 1.6)
            if not cuerpo: continue
            u = (x + .5 - x0) / iw
            c = l if u < .22 else (o if u > .8 else m)
            if u < .1: c = b
            if (y - y0) % 3 == 2 and (x * 7 + y * 3 + sem) % 4 == 0 and c != o: c = m if c in (l, b) else o   # la trama de la tela
            if abs(u - .62) < .5 / iw: c = o                     # la costura
            L.p(x, y, c)
    for y in range(y0, y0 + e + 1):                              # la boca: borde vuelto (2 filas de delante) y la tierra
        for x in range(x0, x1 + 1):
            if den(x, y, yc, rx, ry):
                fuera = not den(x, y, yc, rx - 1.5, ry - 1.2)
                if fuera: L.p(x, y, b if y >= yc and (x + .5 - cx) < 0 else (l if y >= yc else m))
                else: L.p(x, y, T1 if y >= yc - .5 else (o if y < yc - ry + 2 else T0))
    for y in range(int(yc) + 1, min(31, int(yc) + 3)):            # el borde vuelto, por delante, más claro y cosido
        for x in range(x0, x1 + 1):
            if L.lleno(x, y) and not den(x, y, yc, rx, ry): L.p(x, y, l if (x + .5 - cx) < iw * .3 else m)
    for x in range(x0 + 2, x1 - 1, 3): L.p(x, int(yc) + 2, o)
    for i in range(4):                                           # terrones
        L.p(int(cx) - 3 + i * 2, int(yc) - (i % 2), T2)
    for s in (-1, 1):                                            # asas, a media altura del borde
        ax = x0 - 1 if s < 0 else x1 + 1
        L.r(ax, int(yc), 1, 3, o)
    L.contorno(K)
    return L

def estira(im, w, h, cols, filas):
    """la maceta aprobada a otro tamaño: repite columnas y filas del cuerpo (las de cols y filas, por turnos), sin colores nuevos"""
    xs = list(range(im.width)); ys = list(range(im.height)); i = 0
    while len(xs) < w: c = cols[i % len(cols)]; xs.insert(xs.index(c), c); i += 1
    i = 0
    while len(ys) < h: f = filas[i % len(filas)]; ys.insert(ys.index(f), f); i += 1
    o = Image.new('RGBA', (32, 32), (0, 0, 0, 0)); ox = 16 - w // 2; oy = 32 - h
    for j, y in enumerate(ys):
        for k, x in enumerate(xs): o.putpixel((ox + k, oy + j), im.getpixel((x, y)))
    L = Lienzo(32, 32); L.im = o; L.px = o.load(); return L

GRIS, BEIS = ('#2e3036', '#45474e', '#5e6068', '#787a82'), ('#5a4e38', '#7a6c50', '#988a6c', '#b0a280')
sale('carpa-c-macetas-b', 'maceta-c-tela11-26', tela(26, 29, GRIS, 1))
sale('carpa-c-macetas-b', 'maceta-c-tela11-20', tela(20, 22, GRIS, 2))
sale('carpa-c-macetas-b', 'maceta-c-tela25-27', tela(27, 26, BEIS, 3))
m7 = Image.open(P('art', 'procesado', 'carpa-c-macetas', 'maceta-c-22', 'unica', '00.png')).convert('RGBA').crop((5, 5, 27, 32))   # 22 × 27
sale('carpa-c-macetas-b', 'maceta-c-plastico18-26', estira(m7, 26, 31, [7, 14, 16, 5], [14, 18, 22, 16]))
sale('carpa-c-macetas-b', 'maceta-c-plastico18-23', estira(m7, 23, 29, [14], [14, 18]))

# ---------- extras ----------
# celda extra_c (48 × 48), cada dibujo con su base centrada en (24, 47) (ajuste exacto); el motor los pone por esa base
def extra():
    return Lienzo(48, 48)

def ventilador(rot):
    """ventilador de pinza: la cabeza de frente (rejilla, aro y 3 aspas giradas rot grados), el cuello y la pinza abajo"""
    L = extra(); cx, cy, R = 23.5, 33.5, 7
    for y in range(26, 42):
        for x in range(16, 32):
            dx, dy = x + .5 - 24, y + .5 - 34; r = math.hypot(dx, dy)
            if r > R: continue
            a = (math.degrees(math.atan2(dy, dx)) - rot) % 120
            if r > R - .9: c = K
            elif r > R - 1.9: c = M2 if dx + dy < -2 else M1
            elif r < 1.6: c = M3 if dx + dy < 0 else M2
            elif a < 42: c = M3 if a < 14 else '#5c6a6e'
            else: c = M0
            if R - 1.9 > r > 2 and abs(r - 3.6) < .45 and (x + y) % 2 == 0: c = K   # la rejilla
            L.p(x, y, c)
    L.r(23, 41, 2, 3, K); L.p(23, 42, M2)                      # el cuello
    L.caja(20, 44, 8, 4, M1, K); L.hl(21, 26, 45, M2); L.p(21, 46, M3)   # la pinza
    return L

def filtro(lf, df):
    """filtro de carbón (de chapa perforada) tumbado y colgado de 2 cintas, el extractor en línea a su izquierda y el tubo
    flexible que sube al techo; el filtro acaba en la columna 47"""
    L = extra(); x1 = 47; x0 = x1 - lf + 1; y1 = 47; y0 = y1 - df + 1
    L.caja(x0, y0, lf, df, '#5a5e64', K)
    for y in range(y0 + 1, y1):
        for x in range(x0 + 1, x1):
            if (x + (y // 2) % 2) % 2 == 0 and (y - y0) % 2 == 0: L.p(x, y, '#3a3e44')   # la chapa perforada
    L.hl(x0 + 1, x1 - 1, y0 + 1, '#8a8e94'); L.hl(x0 + 1, x1 - 1, y1 - 1, '#2a2e34')
    L.r(x1 - 2, y0 + 1, 1, df - 2, '#2a2e34')
    for x in (x0 + 3, x1 - 4):                                   # las cintas, del techo (fila 47 − 30) al filtro
        L.vl(x, y0 - 12, y0 - 1, C0)
    L.caja(x0 - 2, y0 - 1, 3, df + 2, M2, K)                     # la brida
    fw, fd = 8, df + 4; fx = x0 - 2 - fw + 1; fy = y0 - 2         # el extractor
    L.caja(fx, fy, fw, fd, M1, K); L.hl(fx + 1, fx + fw - 2, fy + 1, M2); L.p(fx + 2, fy + 3, '#e8644c')
    L.r(fx + 1, fy + fd // 2, fw - 2, 1, M0)
    tx = fx + 2                                                  # el tubo flexible (aluminio, con sus aros), sube hasta arriba del todo
    for y in range(y0 - 12, fy):
        L.r(tx, y, 4, 1, '#c8ccd2' if y % 2 else '#8a9098'); L.p(tx - 1, y, K); L.p(tx + 4, y, K)
    return L

def garrafa(h):
    """garrafa de riego de h px de alto (ancho 0,7 × h): plástico blanco translúcido («dentro» en #e6eef2, donde el motor pinta el agua
    hasta su nivel), asa a la derecha y tapón azul con el gotero a la izquierda"""
    L = extra(); w = round(h * .7); x0 = 24 - w // 2; x1 = x0 + w - 1; y0 = 48 - h
    L.caja(x0, y0 + 3, w, h - 3, '#e6eef2', '#7a8690')
    L.vl(x0 + 1, y0 + 4, 46, '#f6f9fa'); L.vl(x1 - 1, y0 + 4, 46, '#c4ccd2')   # brillo y sombra
    for y in range(y0 + 3 + (h - 3) // 3, 47, max(4, (h - 3) // 3)): L.hl(x0 + 2, x1 - 2, y, '#d2dade')   # nervios
    a = max(4, round(w * .45)); ax = x1 - a + 1                  # el asa, hueca
    L.hl(ax, x1 - 1, y0, '#7a8690'); L.vl(ax, y0, y0 + 3, '#7a8690'); L.vl(x1 - 1, y0, y0 + 3, '#7a8690'); L.hl(ax + 1, x1 - 2, y0 + 1, '#c4ccd2')
    L.r(x0 + 1, y0, 4, 3, '#3a6aa8'); L.hl(x0 + 1, x0 + 4, y0, '#6a9ad8'); L.p(x0 + 2, y0 - 1, C0)   # el tapón con el gotero
    return L

def llave():
    """la llave de paso del microtubo del goteo (5 × 3): cuerpo negro y palanca roja"""
    L = extra(); L.r(22, 46, 5, 2, C0); L.hl(23, 25, 46, '#4a4c54'); L.r(23, 44, 3, 2, '#b8322a'); L.hl(23, 25, 44, '#e8644c'); L.p(22, 44, K); L.p(26, 44, K)
    return L

def deposito():
    """el depósito del goteo en pequeño (13 × 20), para el nivel: azul, con su tapa, aros y la mirilla («vacía» #16263a; el motor
    pinta el agua hasta su nivel)"""
    L = extra(); x0, x1, y0 = 18, 30, 28
    L.caja(x0, y0 + 2, 13, 18, '#2e4a66', K)
    L.r(x0 + 1, y0 + 3, 2, 16, '#4a6a88'); L.r(x1 - 2, y0 + 3, 1, 16, '#24384e')
    for y in (y0 + 7, y0 + 12): L.hl(x0 + 1, x1 - 1, y, '#26405a')
    L.caja(x0 + 1, y0, 11, 3, '#5a7a98', K); L.hl(x0 + 5, x0 + 7, y0 + 1, C0)
    L.r(x0 + 5, y0 + 4, 3, 14, '#16263a')                        # la mirilla
    L.hl(x0 + 4, x0 + 8, y0 + 3, '#8a9aa8'); L.hl(x0 + 4, x0 + 8, y0 + 18, '#8a9aa8')
    return L

sale('carpa-c-extras', 'extra-c-vent', *[ventilador(r) for r in (0, 30, 60, 90)])
# filtro de 100 mm (Ø 17 × 30 cm: el armario 60 y el 80) y de 150 mm (Ø 20 × 50: las de 200 cm)
sale('carpa-c-extras', 'extra-c-filtro-28', filtro(28, 12))
sale('carpa-c-extras', 'extra-c-filtro-39', filtro(39, 15))
# garrafas de 5, 7, 12 y 16 L (25,6 a 37,7 cm de alto) en cada escala: de 20 a 29 px
for h in (20, 23, 26, 29): sale('carpa-c-extras', 'extra-c-garrafa-%d' % h, garrafa(h))
sale('carpa-c-extras', 'extra-c-llave', llave())
sale('carpa-c-extras', 'extra-c-deposito', deposito())

def escribe():
    for g, S in SAL.items():
        for n, fs in S.items():
            d = P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
            for i, L in enumerate(fs): L.im.save(os.path.join(d, '%02d.png' % i))
            print(g, n, len(fs), 'fotogramas', fs[0].im.getbbox())

if __name__ == '__main__':
    escribe()
