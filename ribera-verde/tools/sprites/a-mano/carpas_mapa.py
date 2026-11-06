# python3 -I tools/sprites/a-mano/carpas_mapa.py  (Python 3 + Pillow; no va en los scripts de npm)
# Retoque a mano (1.10) de las carpas del piso vistas desde fuera (misc:carpa-<t>-mapa, aprobadas): a 16 px/m el frente ya
# tiene su ancho y su alto reales (60/80/100/120/150 cm de ancho; 160/180/200 de alto), pero el techo, que va a medio fondo
# como la nevera y los muebles (fondo × 0,5 × 16 px/m), se quedaba corto en las de 1 m o más de fondo. Este script le añade
# las filas que le faltan (copia una fila del medio del techo, sin tocar el frente ni el ancho) hasta su medida:
#   p60 60 cm → 5 px · p80 80 → 6 · m100 100 → 8 · m120 120 → 10 · g150 100 → 8   (filas del techo, con el canto claro)
# Lee el sprite aprobado de art/procesado (va en el repo) y escribe el recorte en art/crudo/<grupo>/carpa-<t>-mapa/unica/00.png;
# después, node tools/sprites/procesar.js carpas-mapa carpas-medias-mapa --atlas. Si el techo ya mide lo suyo, no cambia nada.
import os, sys
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import P

FONDO = {'p60': 60, 'p80': 80, 'm100': 100, 'm120': 120, 'g150': 100}
GRUPO = {'p60': 'carpas-mapa', 'm100': 'carpas-mapa', 'g150': 'carpas-mapa', 'p80': 'carpas-medias-mapa', 'm120': 'carpas-medias-mapa'}

def lum(px): return .299 * px[0] + .587 * px[1] + .114 * px[2]

def retoca(t, salida=None):
    src = P('art', 'procesado', GRUPO[t], 'carpa-%s-mapa' % t, 'unica', '00.png')
    im = Image.open(src).convert('RGBA'); im = im.crop(im.getbbox())
    w, h = im.size; cx = w // 4                      # la mitad de la luz (la derecha es la cara en sombra)
    # el canto claro del techo: la primera fila (desde arriba) que es clara en la mitad de la luz
    canto = next(y for y in range(h) if im.getpixel((cx, y))[3] and lum(im.getpixel((cx, y))) > 140)
    techo, quiere = canto + 1, round(FONDO[t] * .5 * 16 / 100)
    falta = max(0, quiere - techo)
    o = Image.new('RGBA', (w, h + falta))
    fila = max(1, techo // 2)                       # una fila del cuerpo del techo (ni el borde de arriba ni el canto)
    o.paste(im.crop((0, 0, w, fila + 1)), (0, 0))
    for i in range(falta): o.paste(im.crop((0, fila, w, fila + 1)), (0, fila + 1 + i))
    o.paste(im.crop((0, fila + 1, w, h)), (0, fila + 1 + falta))
    d = salida or P('art', 'crudo', GRUPO[t], 'carpa-%s-mapa' % t, 'unica'); os.makedirs(d, exist_ok=True)
    o.save(os.path.join(d, '00.png'))
    print(t, 'techo', techo, '→', techo + falta, 'px · alto', h, '→', h + falta, '· ancho', w, 'px =', round(w * 100 / 16), 'cm')

if __name__ == '__main__':
    for t in FONDO: retoca(t, os.path.join(sys.argv[1], t) if len(sys.argv) > 1 else None)
