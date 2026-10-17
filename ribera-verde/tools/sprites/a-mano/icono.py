# python3 -I tools/sprites/a-mano/icono.py  (Python 3 + Pillow; no va en los scripts de npm)
# El icono de la app (lanzador de Android), dibujado a mano en código: una hoja de cannabis de 7 foliolos dentados, verde
# fresco (los verdes del cogollo de la Genoteca), con la luz arriba a la izquierda, sobre un cielo de noche con el halo del
# foco detrás y, abajo, la ribera: la orilla de hierba y el río.
#  · art/icono/icono-48.png: el icono clásico (48 × 48 px de arte = 48 dp, esquinas redondeadas), para Android 7 y para
#    mdpi…xxxhdpi a ×1…×4.
#  · art/icono/icono-fondo-72.png y icono-delante-72.png: las dos capas del icono adaptativo (Android 8+), 72 × 72 px de
#    arte = 108 dp a 1,5 dp por píxel (×6 → 432 px). Lo que se ve son los 48 del medio, igual que el clásico; la hoja va
#    entera dentro del círculo que no recorta ninguna máscara (66 dp = 44 px de radio 22) y el fondo sigue hasta el borde.
#  · art/icono/icono-play-512.png: el de la ficha de Google Play (las dos capas, los 64 px del medio a ×8).
#  · godot/arranque.png: el clásico a ×4 (192 px), icono del proyecto y de la pantalla de arranque de la app de Godot.
#  · art/icono/vista.png: hoja de revisión (el clásico a ×1…×4 y el adaptativo con máscara redonda, de ardilla y cuadrada).
# Idempotente: el dibujo sale siempre igual (sin azar).
import math, os, sys
from PIL import Image, ImageDraw

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
SAL = os.path.join(RAIZ, 'art', 'icono')

def hx(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

# la hoja: verdes del cogollo de la Genoteca (salon.py) y su contorno
H_OSC, H_MED, H_CLA, H_LUZ, H_VENA = '#2e6a2e', '#4a9a3a', '#78c850', '#b4ec80', '#a4e070'
H_SOMBRA, CONTORNO = '#1e4a22', '#0c2014'
# el fondo: cielo de noche, halo del foco, orilla y río
CIELO = ['#0f2a2a', '#12322f', '#163b35', '#1a453c']
HALO, HALO2 = '#205244', '#1d4b40'
ESTRELLA = '#b4dcfa'
ORILLA, ORILLA2, ORILLA_OSC = '#3f8a46', '#62aa56', '#24502a'
AGUA, AGUA2, AGUA_OSC, ESPUMA = '#2f6fb8', '#4a92e0', '#23589a', '#76b4f2'

BASE = (24.0, 35.0)             # donde nacen los foliolos (en el lienzo de 48)
# foliolos: ángulo desde arriba (grados), largo y medio ancho máximo (px)
FOLIOLOS = [(0, 29, 4.3), (-31, 25, 3.9), (31, 25, 3.9), (-62, 20, 3.3), (62, 20, 3.3), (-96, 12, 2.4), (96, 12, 2.4)]
ORILLA_Y = 39                   # primera fila de la orilla en el lienzo de 48

def ancho(u, L, W):
    """medio ancho del foliolo a u px de su base: estrecho al nacer, ancho a 0,42 y en punta; dientes hacia la punta"""
    t = u / L
    if t <= 0 or t >= 1: return 0
    f = math.sin(math.pi * t ** 0.78) ** 1.1
    paso = 2.7 if L > 15 else 2.2
    diente = 0.74 + 0.26 * ((u / paso) % 1)
    return W * f * diente

def hoja():
    """lienzo 48 × 48: None fuera; dentro, (foliolo, lado, |v|/ancho, u/L) o 'tallo'"""
    M = [[None] * 48 for _ in range(48)]
    n = 4                         # submuestras por lado
    for y in range(48):
        for x in range(48):
            mejor, cuenta = None, 0
            for sy in range(n):
                for sx in range(n):
                    px, py = x + (sx + .5) / n, y + (sy + .5) / n
                    for k, (a, L, W) in enumerate(FOLIOLOS):
                        r = math.radians(a)
                        dx, dy = math.sin(r), -math.cos(r)
                        qx, qy = px - BASE[0], py - BASE[1]
                        u = qx * dx + qy * dy - 1.2
                        v = -qx * dy + qy * dx
                        w = ancho(u, L, W)
                        if w > 0 and abs(v) <= w:
                            cuenta += 1
                            if mejor is None or k < mejor[0]: mejor = (k, v, w, u, L)
                            break
            if cuenta >= 7:
                k, v, w, u, L = mejor
                # la v del centro del píxel para el sombreado
                a = math.radians(FOLIOLOS[k][0]); dx, dy = math.sin(a), -math.cos(a)
                qx, qy = x + .5 - BASE[0], y + .5 - BASE[1]
                vc = -qx * dy + qy * dx
                uc = qx * dx + qy * dy - 1.2
                M[y][x] = (k, vc, uc / L)
    # el tallo: de la base a la orilla, 2 px
    for y in range(int(BASE[1]) - 1, ORILLA_Y + 2):
        for x in (23, 24):
            if M[y][x] is None or y >= BASE[1]: M[y][x] = 'tallo'
    return M

def pinta_hoja(img, M, ox, oy):
    px = img.load()
    luz = (-0.62, -0.78)          # de arriba a la izquierda
    def dentro(x, y): return 0 <= x < 48 and 0 <= y < 48 and M[y][x] is not None
    for y in range(48):
        for x in range(48):
            c = M[y][x]
            if c is None: continue
            if c == 'tallo':
                col = H_MED if x == 23 else H_OSC
            else:
                k, v, t = c
                a = math.radians(FOLIOLOS[k][0]); dx, dy = math.sin(a), -math.cos(a)
                nx, ny = (-dy, dx) if v > 0 else (dy, -dx)     # normal del lado de este píxel
                lado = nx * luz[0] + ny * luz[1]
                if abs(v) < 0.62 and 0.06 < t < 0.9: col = H_VENA
                elif lado > 0.25: col = H_CLA
                elif lado > -0.25: col = H_MED if k else (H_CLA if v < 0 else H_MED)
                else: col = H_MED
                # el borde de dentro: la luz en el lado iluminado y la sombra en el otro
                borde = any(not dentro(x + ex, y + ey) for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                if borde and col != H_VENA:
                    col = H_LUZ if lado > 0.25 else (H_OSC if lado < -0.25 else col)
                # cerca de la base, más oscuro (se tapan unos a otros)
                if t < 0.16 and col != H_VENA: col = H_OSC
            px[ox + x, oy + y] = hx(col)
    # contorno de fuera
    for y in range(-1, 49):
        for x in range(-1, 49):
            if dentro(x, y): continue
            if any(dentro(x + ex, y + ey) for ex, ey in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                if 0 <= ox + x < img.width and 0 <= oy + y < img.height and (y < ORILLA_Y or not (22 <= x <= 25)):
                    px[ox + x, oy + y] = hx(CONTORNO)

def fondo(W, H, ox, oy):
    """el cielo, el halo, las estrellas, la orilla y el río, en coordenadas del lienzo de 48 corridas (ox, oy)"""
    img = Image.new('RGBA', (W, H))
    px = img.load()
    cx, cy = 24 + ox - .5, 23 + oy - .5
    for y in range(H):
        yl = y - oy                                   # fila en el lienzo de 48
        for x in range(W):
            # cielo en bandas de arriba abajo, con un tramado de damero entre bandas
            f = max(0.0, min(0.999, (yl + 12) / 52))
            b = f * len(CIELO); i = int(b)
            if b - i > 0.72 and (x + y) % 2 == 0 and i + 1 < len(CIELO): i += 1
            col = CIELO[i]
            # el halo del foco detrás de la hoja
            d = math.hypot(x - cx, y - cy)
            if d < 19: col = HALO
            elif d < 21 and (x + y) % 2 == 0: col = HALO2
            px[x, y] = hx(col)
    # estrellas (fijas)
    for sx, sy in ((5, 6), (40, 4), (43, 13), (8, 16), (-6, 2), (52, 8), (-4, 22), (54, 26), (30, -8), (12, -6)):
        x, y = sx + ox, sy + oy
        if 0 <= x < W and 0 <= y < H and math.hypot(x - cx, y - cy) > 21: px[x, y] = hx(ESTRELLA)
    # la orilla y el río
    for y in range(H):
        yl = y - oy
        for x in range(W):
            xl = x - ox
            if yl == ORILLA_Y: col = ORILLA2 if (xl // 3) % 4 else ORILLA
            elif yl == ORILLA_Y + 1: col = ORILLA
            elif yl == ORILLA_Y + 2: col = ORILLA_OSC
            elif yl > ORILLA_Y + 2:
                col = AGUA if (yl - ORILLA_Y) % 4 else AGUA_OSC
                # ondas: rayas cortas de espuma corridas de fila en fila
                if (yl - ORILLA_Y) % 3 == 1 and (xl + 5 * yl) % 11 < 3: col = AGUA2
                if (yl - ORILLA_Y) % 6 == 4 and (xl + 7 * yl) % 13 == 0: col = ESPUMA
            else: continue
            px[x, y] = hx(col)
    # la hierba que asoma por encima de la orilla
    for xl in range(-12, 60):
        if (xl * 7) % 5 == 0:
            x, y = xl + ox, ORILLA_Y - 1 + oy
            if 0 <= x < W and 0 <= y < H: px[x, y] = hx(ORILLA2)
    return img

def redondea(img, r):
    """esquinas redondeadas (sin antialias)"""
    W, H = img.size
    px = img.load()
    for y in range(H):
        for x in range(W):
            cx = min(max(x + .5, r), W - r); cy = min(max(y + .5, r), H - r)
            if (x + .5 - cx) ** 2 + (y + .5 - cy) ** 2 > r * r: px[x, y] = (0, 0, 0, 0)
    return img

def x(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)

def main():
    os.makedirs(SAL, exist_ok=True)
    M = hoja()
    # clásico
    cl = fondo(48, 48, 0, 0)
    pinta_hoja(cl, M, 0, 0)
    # las sombras de la hoja sobre la orilla (1 px bajo el contorno)
    redondea(cl, 7)
    cl.save(os.path.join(SAL, 'icono-48.png'))
    x(cl, 4).save(os.path.join(RAIZ, 'godot', 'arranque.png'))
    # adaptativo
    fo = fondo(72, 72, 12, 12)
    de = Image.new('RGBA', (72, 72))
    pinta_hoja(de, M, 12, 12)
    # la hoja tapa la orilla en el clásico; en la capa de delante el tallo llega hasta la orilla
    fo.save(os.path.join(SAL, 'icono-fondo-72.png'))
    de.save(os.path.join(SAL, 'icono-delante-72.png'))
    # Play: las dos capas, los 64 del medio a ×8
    comp = fo.copy(); comp.alpha_composite(de)
    x(comp.crop((4, 4, 68, 68)), 8).save(os.path.join(SAL, 'icono-play-512.png'))
    # hoja de revisión
    V = Image.new('RGBA', (48 * 10 + 50, 10 + 192 + 20 + 144 + 10), hx('#e8e8e0'))
    xo = 10
    for k in (1, 2, 3, 4):
        V.alpha_composite(x(cl, k), (xo, 10)); xo += 48 * k + 10
    xo = 10
    for forma in ('circulo', 'ardilla', 'cuadrado'):
        m = Image.new('L', (72 * 3, 72 * 3)); d = ImageDraw.Draw(m)
        a, b = 12 * 3, 60 * 3 - 1                                  # lo que se ve: los 48 del medio (72 dp)
        if forma == 'circulo': d.ellipse((a, a, b, b), 255)
        elif forma == 'ardilla': d.rounded_rectangle((a, a, b, b), 16 * 3, 255)
        else: d.rounded_rectangle((a, a, b, b), 4 * 3, 255)
        c3 = x(comp, 3); c3.putalpha(m)
        V.alpha_composite(c3.crop((a, a, b + 1, b + 1)), (xo, 222)); xo += 48 * 3 + 10
    V.save(os.path.join(SAL, 'vista.png'))
    # zona segura: todo lo opaco de la capa de delante dentro del círculo de radio 22 del centro (36, 36)
    peor = 0
    for y in range(72):
        for xx in range(72):
            if de.getpixel((xx, y))[3]: peor = max(peor, math.hypot(xx + .5 - 36, y + .5 - 36))
    print(f'icono: art/icono (48, 72 + 72, 512, vista) · delante hasta {peor:.1f} px del centro (máx. 22)')
    if peor > 22: sys.exit(1)

main()
