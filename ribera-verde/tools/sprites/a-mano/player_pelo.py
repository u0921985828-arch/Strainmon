# python3 -I tools/sprites/a-mano/player_pelo.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# El pelo del jugador con color propio (1.21, ropa y pelo): PixelLab pintó el pelo con dos marrones que también salen en la cara
# (el de la sombra del cuello y el de la boca, la barbilla y las manos). Para poder cambiarle el color sin tocar la piel, los píxeles
# del pelo pasan a dos colores que solo usa el pelo (`PELO`, a 1 de azul de los de antes: no se nota): el marrón oscuro por encima
# de la fila del cuello (la de encima de la camiseta; en el cuello es sombra) y, de espaldas (north), también el marrón claro (de
# frente y de lado es la boca, la barbilla o la mano). Va después de player_cara.py y repetirlo da lo mismo; después,
# node tools/sprites/procesar.js --atlas. El juego cambia estos colores y los de la gorra, la camiseta y el pantalón (`ROPA`, 03-datos).
import os, sys, glob
from PIL import Image

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'procesado', 'player')
CAMISETA = {(200, 56, 56), (160, 48, 48)}
OSCURO, CLARO = (74, 42, 42), (122, 90, 58)
PELO = {OSCURO: (74, 42, 43), CLARO: (122, 90, 59)}

def camiseta(im):   # la primera fila con 3 píxeles de la camiseta o más (como en player_cara.py)
    for y in range(im.height):
        if sum(im.getpixel((x, y))[:3] in CAMISETA and im.getpixel((x, y))[3] > 0 for x in range(im.width)) >= 3: return y
    return None

n = 0
for f in sorted(glob.glob(os.path.join(RAIZ, '*', '*', '*.png'))):
    im = Image.open(f).convert('RGBA'); s = camiseta(im)
    if s is None: continue
    dirn = os.path.basename(os.path.dirname(f)); cambia = 0
    for y in range(s - 1):
        for x in range(im.width):
            p = im.getpixel((x, y))
            if p[3] and (p[:3] == OSCURO or (p[:3] == CLARO and dirn == 'north')):
                im.putpixel((x, y), PELO[p[:3]] + (255,)); cambia += 1
    if cambia: im.save(f); n += 1
print(f'pelo: {n} fotogramas')
