# python3 -I tools/sprites/a-mano/pixellab_negocios.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.47 (lo pidió el usuario, con fotos de referencia del taller, la panadería, el bar y la lavandería, y «¿por qué no estás usando
# la API de PixelLab?»): los muebles de esos cuatro locales salen de PixelLab (create_1_direction_object, vista de arriba a 3/4,
# solo con texto: las fotos no se subieron, llevan marcas), guardados tal cual en tools/sprites/pixellab-negocios/<nombre>.png.
# Aquí se ajustan a 16 px/m (el protagonista mide 27 px = 1,70 m): cada uno a su escala (vecino más próximo), con la base abajo y
# centrado en su casilla (alto) o en sus dos casillas (ancho).
#  · negocios-pl-alto (celda mueble_escala, 32 × 48): una casilla
#  · negocios-pl-ancho (celda mueble_ancho, 48 × 48): dos casillas (la segunda, <nombre>2 en el mapa)
#  · negocios-pl-coche (celda vehiculo_expo, 80 × 48): e-elevT, el elevador del taller con las columnas azules (las de la foto),
#    recoloreado del de negocios.py; el juego lo cambia por el de siempre solo con Datos.CAL (_arte_obj)
# e-stool y e-recambT: también por _arte_obj, con el mismo nombre de objeto (el taburete del bar y la estantería de recambios).
# Después: node tools/sprites/procesar.js negocios-pl-alto negocios-pl-ancho negocios-pl-coche --atlas --atlas-dir godot/arte
import os, sys, glob
from PIL import Image
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
P = lambda *a: os.path.join(RAIZ, *a)
SRC = P('tools', 'sprites', 'pixellab-negocios')

# nombre en el juego: (png de PixelLab, escala, casillas de ancho, medida real que se busca)
PIEZAS = {
    'lavaN': ('lavaN', .75, 1, 'lavadora industrial de 1 m de ancho y 1,4 de alto'),
    'secaN': ('secaN', .75, 1, 'secadora industrial de 1 m de ancho y 1,4 de alto'),
    'kioskL': ('kioskL', .8, 1, 'la caja de pago de 60 cm y 1,6 m'),
    'cestaL': ('cestaL', .85, 1, 'el carro de la ropa de 70 cm'),
    'rackP': ('rackP', .8, 1, 'el carro de bandejas de 1 m y 1,6 m'),
    'aceiteT': ('aceiteT', .7, 1, 'la recogedora de aceite de 1,4 m'),
    'carroT': ('carroT', .85, 1, 'el carro de herramientas de 1 m'),
    'cajasT': ('cajasT', .75, 1, 'las cajas de 60 cm'),
    'cafeT': ('cafeT', .75, 1, 'la cafetera en su mueble de 1 m'),
    'mesaT': ('mesaT', .85, 1, 'la mesa de pino de 80 cm con sus sillas'),
    'e-stool': ('stool', .75, 1, 'el taburete de 75 cm'),
    'hornoN': ('hornoN', 1, 2, 'el horno de pisos de 1,8 m'),
    'e-recambT': ('recambT', 1, 2, 'la estantería de recambios de 1,8 m'),
    'barraN': ('barraN', .68, 2, 'la barra de pintxos de 2 m con la vitrina'),
    'botN': ('botN', .7, 2, 'el botellero de 1,9 m con los vasos'),
    'estP': ('estP', .7, 2, 'el estante del pan de 1,9 m con los cestos'),
    'mostrN': ('mostrN', .7, 2, 'el mostrador de 2 m con las campanas y la cafetera'),
    'doblaN': ('doblaN', .7, 2, 'la mesa de doblar de 2 m'),
    'mesaP': ('mesaP', .7, 2, 'la mesa de acero de 1,9 m con la masa'),
}

# el elevador: lo rojo de las columnas, a azul (la luz de atrás del coche, (192, 48, 40), se queda)
AZUL = {(184, 48, 48): (48, 96, 184), (122, 30, 30): (30, 56, 122), (224, 90, 74): (74, 130, 224)}

def escala(im, f):
    bb = im.getbbox(); im = im.crop(bb)
    if f == 1:
        return im
    w, h = max(1, round(im.width * f)), max(1, round(im.height * f))
    out = im.resize((w, h), Image.NEAREST)
    return out

def binaria(im):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    return im

def en_celda(im, n):
    cw, ch, cx = (32, 48, 16) if n == 1 else (48, 48, 24)
    out = Image.new('RGBA', (cw, ch))
    out.paste(im, (cx - im.width // 2, ch - im.height), im)
    return out

def sale(grupo, n, im):
    d = P('art', 'crudo', grupo, n, 'unica'); os.makedirs(d, exist_ok=True)
    for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
    im.save(os.path.join(d, '00.png'))
    print(grupo, n, im.getbbox())

if __name__ == '__main__':
    for n, (f, k, c, _) in PIEZAS.items():
        im = binaria(Image.open(os.path.join(SRC, f + '.png')).convert('RGBA'))
        sale('negocios-pl-alto' if c == 1 else 'negocios-pl-ancho', n, en_celda(binaria(escala(im, k)), c))
    el = Image.open(P('art', 'procesado', 'negocios-coche', 'elevT', 'unica', '00.png')).convert('RGBA')
    px = el.load()
    for y in range(el.height):
        for x in range(el.width):
            p = px[x, y]
            if p[3] and p[:3] in AZUL:
                px[x, y] = AZUL[p[:3]] + (p[3],)
    sale('negocios-pl-coche', 'e-elevT', el)
