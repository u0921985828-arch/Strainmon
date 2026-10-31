# El protagonista de espaldas tecleando, de PixelLab (lo pidió el usuario: «Has primero el Sprite del jugador con los brazos puestos
# y después lo sientas en la silla, pidiendo su Sprite por detrás»). Entrada: tools/sprites/pixellab-teclea/crudo/<grupo>-<n>.png,
# el candidato elegido entre 64 de create_image_pro (referencias: su fotograma base de espaldas y la pose; paleta: la del base):
# los codos abiertos a la altura de la cintura y los antebrazos hacia delante (en pantalla, hacia arriba y hacia dentro), con las
# manos delante del pecho, en el teclado. Aquí solo se le ponen los colores exactos del base, para que la ropa (ROPA, ropa_c)
# los cambie: la gorra y el pelo a su tono, la camiseta clara con la sombra en los cantos y el pantalón vaquero desde el cinturón.
# Salida: art/crudo/<grupo>/teclea/north/00.png y, ya encajado, art/procesado/<grupo>/teclea/north/00.png: los pies en la fila de los
# de su fotograma base de espaldas y el centro en el del lienzo (como lo encaja procesar.js), sin pasar por procesar.js (al grupo
# entero ya le pasaron player_cara.py, player_pelo.py y player_ropa.py). Después: node tools/sprites/procesar.js --atlas --atlas-dir godot/arte
import os
from PIL import Image

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
CRUDO = {'player': 'player-6.png', 'player-f': 'player-f-22.png'}
CLARA, SOMBRA = (0xc8, 0x38, 0x39), (0xa0, 0x30, 0x31)       # la camiseta (ROPA.camiseta)
VAQUERO, BRILLO = (0x36, 0x46, 0x6f), (0x6c, 0x74, 0x83)     # el pantalón (ROPA.pantalon)
OSCURO, GRIS = (0x2c, 0x33, 0x3c), (0x53, 0x5b, 0x6b)        # como lo dibuja PixelLab
TONO = {(0x2a, 0x8a, 0x5a): (0x2a, 0x8a, 0x5b), (0x7a, 0x5a, 0x3a): (0x7a, 0x5a, 0x3b)}   # gorra y pelo, al tono del base

def colores(im):
    w, h = im.size
    px = im.load()
    rgb = lambda x, y: px[x, y][:3] if 0 <= x < w and 0 <= y < h and px[x, y][3] else None
    for y in range(h):
        for x in range(w):
            c = rgb(x, y)
            if c in TONO:
                px[x, y] = TONO[c] + (255,)
    # el cinturón: la primera fila gris o con el brillo por debajo de la camiseta; de ahí abajo, el vaquero
    cint = min((y for y in range(h // 2, h) for x in range(w) if rgb(x, y) in (GRIS, BRILLO)), default=h)
    camis = [(x, y) for y in range(h) for x in range(w) if rgb(x, y) == SOMBRA]
    for x, y in camis:   # la sombra solo en los cantos (junto al brazo o al contorno); lo demás, claro
        canto = any(rgb(x + d, y) not in (SOMBRA, CLARA) for d in (-1, 1))
        px[x, y] = (SOMBRA if canto else CLARA) + (255,)
    for y in range(cint, h):
        for x in range(w):
            c = rgb(x, y)
            if c == OSCURO:
                px[x, y] = VAQUERO + (255,)
            elif c == GRIS:
                px[x, y] = BRILLO + (255,)
    return im

def pelo(im):   # el del chico, como player_pelo.py: sus tonos solo por encima del cuello; debajo (sombras), los de antes, y el
    px = im.load()   # marrón suelto en medio de la camiseta (entre dos píxeles de camiseta), su sombra
    s = next(y for y in range(im.height) if sum(px[x, y][3] > 0 and px[x, y][:3] in (CLARA, SOMBRA) for x in range(im.width)) >= 3)
    for y in range(s - 1, im.height):
        for x in range(im.width):
            c = px[x, y][:3]
            if px[x, y][3] and c in PELO_DEBAJO:
                suelto = y >= s and 0 < x < im.width - 1 and all(px[x + d, y][:3] in (CLARA, SOMBRA) for d in (-1, 1))
                px[x, y] = (SOMBRA if suelto else PELO_DEBAJO[c]) + (255,)
    return im

PELO_DEBAJO = {(0x4a, 0x2a, 0x2b): (0x4a, 0x2a, 0x2a), (0x7a, 0x5a, 0x3b): (0x7a, 0x5a, 0x3a)}

def encaja(im, base):
    x0, y0, x1, y1 = im.getbbox()
    dx, dy = im.width // 2 - (x0 + x1) // 2, base.getbbox()[3] - y1
    o = Image.new('RGBA', im.size, (0, 0, 0, 0))
    o.alpha_composite(im, (dx, dy))
    return o

for g, f in CRUDO.items():
    im = colores(Image.open(os.path.join(R, 'tools', 'sprites', 'pixellab-teclea', 'crudo', f)).convert('RGBA'))
    if g == 'player':
        im = pelo(im)
    for k in ('crudo', 'procesado'):
        d = os.path.join(R, 'art', k, g, 'teclea', 'north')
        os.makedirs(d, exist_ok=True)
        if k == 'procesado':
            im = encaja(im, Image.open(os.path.join(R, 'art', 'procesado', g, 'base', 'north', '00.png')).convert('RGBA'))
        im.save(os.path.join(d, '00.png'))
    print(g, im.getbbox())
