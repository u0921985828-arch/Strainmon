# La mesa y el taco de la bola 8 de PixelLab (lo pidió el usuario: «Hazlo con sprites de PixelLab mejor»).
# Entrada: tools/sprites/pixellab-billar/crudo/mesa-0.png (168 × 92, la elegida de 4 de create_image_pro: la mesa desde arriba con
# bandas de nogal, cantoneras de latón, diamantes, cojines y seis troneras) y taco-4.png (64 × 16, el elegido de 16: el taco en
# horizontal con la punta a la derecha).
# La mesa se rehace a la medida del juego por trozos (billar8.gd: el tapete W × H = 168 × 84 y 11 px de banda y cojín alrededor):
# las cuatro esquinas con su tronera, tal cual; las bandas, con una columna (o fila) lisa repetida y los diamantes cada W/8 (H/4);
# las troneras del medio, en el centro; el paño, con sus dos verdes por casilla (sin las manchas del original).
# El taco, girado en 64 ángulos (vecino más cercano) con la punta apuntada en cada uno.
# Salida: godot/arte/billar.png + billar.json ({r: nombre → [x, y, w, h], v: {taco-i: [px, py]}}, la punta del taco i).
import os, json, math
from PIL import Image

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
C = os.path.join(R, 'tools', 'sprites', 'pixellab-billar', 'crudo')
W, H, B = 168, 84, 11          # el tapete y la banda (madera 7 + cojín 4)
NT = 64                        # ángulos del taco

M = Image.open(os.path.join(C, 'mesa-0.png')).convert('RGBA')
mx0, my0, mx1, my1 = M.getbbox()   # 9, 4, 158, 86
mw, mh = mx1 - mx0, my1 - my0
M = M.crop((mx0, my0, mx1, my1))
FIELTRO = (14, 116, 67, 255)
FIELTRO2 = (11, 106, 63, 255)

def hs(x, y):
    h = (x * 374761393 + y * 668265263) & 0xffffffff
    h = ((h ^ (h >> 13)) * 1274126177) & 0xffffffff
    return (h ^ (h >> 16)) / 4294967295.0

def mesa():
    TW, TH = W + 2 * B, H + 2 * B
    o = Image.new('RGBA', (TW, TH), (0, 0, 0, 0))
    # el paño
    for y in range(B, B + H):
        for x in range(B, B + W):
            o.putpixel((x, y), FIELTRO2 if hs(x, y) < 0.18 else FIELTRO)
    # las bandas: arriba y abajo, una columna lisa (x 30 del original); izquierda y derecha, una fila lisa (y 36)
    col_t = [M.getpixel((30, y)) for y in range(B)]
    col_b = [M.getpixel((30, mh - B + y)) for y in range(B)]
    fil_l = [M.getpixel((x, 36)) for x in range(B)]
    fil_r = [M.getpixel((mw - B + x, 36)) for x in range(B)]
    for x in range(TW):
        for y in range(B):
            o.putpixel((x, y), col_t[y])
            o.putpixel((x, TH - B + y), col_b[y])
    for y in range(TH):
        for x in range(B):
            o.putpixel((x, y), fil_l[x])
            o.putpixel((TW - B + x, y), fil_r[x])
    # los diamantes: el del original (3 × 3 en la madera) cada W/8 arriba y abajo y cada H/4 a los lados
    claro = (248, 207, 154, 255)
    medio = (238, 185, 113, 255)
    def diamante(cx, cy):
        for dx, dy, c in [(0, 0, medio), (-1, 0, claro), (1, 0, claro), (0, -1, claro), (0, 1, claro)]:
            o.putpixel((cx + dx, cy + dy), c)
    for i in (1, 2, 3, 5, 6, 7):
        diamante(B + round(W * i / 8), 4)
        diamante(B + round(W * i / 8), TH - 5)
    for i in (1, 2, 3):
        diamante(4, B + round(H * i / 4))
        diamante(TW - 5, B + round(H * i / 4))
    # las esquinas, tal cual (20 × 20 con la tronera)
    E = 20
    def pega(q, dx, dy):   # dentro del paño, solo lo oscuro de la tronera (el paño del original lleva manchas)
        for j in range(q.height):
            for i in range(q.width):
                c = q.getpixel((i, j))
                x, y = dx + i, dy + j
                if B <= x < B + W and B <= y < B + H and sum(c[:3]) > 90:
                    continue
                if c[3]:
                    o.putpixel((x, y), c)
    for (sx, sy, dx, dy) in [(0, 0, 0, 0), (mw - E, 0, TW - E, 0), (0, mh - E, 0, TH - E), (mw - E, mh - E, TW - E, TH - E)]:
        pega(M.crop((sx, sy, sx + E, sy + E)), dx, dy)
    # las troneras del medio: su trozo, centrado
    cm = mw // 2
    for (sy, dy) in [(0, 0), (mh - B - 4, TH - B - 4)]:
        pega(M.crop((cm - 10, sy, cm + 11, sy + B + 4)), TW // 2 - 10, dy)
    return o

def tacos():
    T = Image.open(os.path.join(C, 'taco-4.png')).convert('RGBA')
    T = T.crop(T.getbbox())
    tw, th = T.size
    punta = (tw - 0.5, th / 2.0)
    out = []
    for i in range(NT):
        a = 2 * math.pi * i / NT
        im = T.rotate(-math.degrees(a), resample=Image.NEAREST, expand=True)
        cx, cy = tw / 2.0, th / 2.0
        rx, ry = punta[0] - cx, punta[1] - cy
        px = rx * math.cos(a) - ry * math.sin(a) + im.width / 2.0
        py = rx * math.sin(a) + ry * math.cos(a) + im.height / 2.0
        bb = im.getbbox()
        im = im.crop(bb)
        out.append((im, [round(px - bb[0], 1), round(py - bb[1], 1)]))
    return out

if __name__ == '__main__':
    me = mesa()
    tc = tacos()
    # el atlas: la mesa arriba y los tacos en filas debajo
    AW = max(me.width, 256)
    x, y, fila = 0, me.height + 1, 0
    pos = []
    for im, _ in tc:
        if x + im.width > AW:
            x, y, fila = 0, y + fila + 1, 0
        pos.append((x, y))
        x += im.width + 1
        fila = max(fila, im.height)
    A = Image.new('RGBA', (AW, y + fila), (0, 0, 0, 0))
    A.paste(me, (0, 0))
    r = {'mesa': [0, 0, me.width, me.height]}
    v = {}
    for i, ((im, p), q) in enumerate(zip(tc, pos)):
        A.paste(im, q)
        r['taco-%d' % i] = [q[0], q[1], im.width, im.height]
        v['taco-%d' % i] = p
    dest = os.path.join(R, 'godot', 'arte')
    A.save(os.path.join(dest, 'billar.png'))
    json.dump({'r': r, 'v': v, 'banda': B, 'nt': NT}, open(os.path.join(dest, 'billar.json'), 'w'))
    print('billar.png', A.size, len(tc), 'tacos')
