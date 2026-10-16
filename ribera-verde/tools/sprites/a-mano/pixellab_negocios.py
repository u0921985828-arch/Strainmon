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

# 1.49 (lo pidió el usuario: «recuerda cómo deben ser los sprites», con la skill del director de sprites y fotos de la lavandería y de
# una cafetera de dos grupos): todos rehechos en PixelLab de frente (alzado recto, vista sidescroller; los de dos casillas, 3/4 de frente),
# nunca girados ni isométricos; spec en tools/sprites/director/negocios-frente/spec.yaml y QA con tools/sprite_qa.py.
# nombre en el juego: (png de PixelLab, alto en px a 16 px/m, casillas de ancho, medida real, px que sube del suelo —colgado de la pared—)
PIEZAS = {
    'lavaN': ('lavaN', 22, 1, 'lavadora industrial de 14 kg, 1,4 m', 0),
    'secaN': ('secaN', 26, 1, 'secadora industrial de 18 kg, 1,6 m', 0),
    'kioskL': ('kioskL', 12, 1, 'el cambiador de monedas en la pared, 75 cm', 12),
    'cestaL': ('cestaL', 17, 1, 'la mesa alta de patas negras con el cesto, 1,05 m', 0),
    'rackP': ('rackP', 26, 1, 'el carro de bandejas de 1,6 m', 0),
    'aceiteT': ('aceiteT', 22, 1, 'la recogedora de aceite de 1,4 m', 0),
    'carroT': ('carroT', 16, 1, 'el carro de herramientas de 1 m', 0),
    'cajasT': ('cajasT', 12, 1, 'las cajas de 75 cm', 0),
    'mesaT': ('mesaT', 14, 1, 'la mesa de pino de 80 cm con sus sillas', 0),
    'e-stool': ('stool', 12, 1, 'el taburete de 75 cm', 0),
    'hornoN': ('hornoN', 29, 2, 'el horno de pisos de 1,8 m', 0),
    'e-recambT': ('recambT', 29, 2, 'la estantería de recambios de 1,8 m', 0),
    'barraN': ('barraN', 20, 2, 'la barra de pintxos de 1,25 m con la vitrina', 0),
    'botN': ('botN', 30, 2, 'el botellero de 1,9 m con los vasos', 0),
    'estP': ('estP', 30, 2, 'el estante del pan de 1,9 m con los cestos', 0),
    'mostrN': ('mostrN', 22, 2, 'el mostrador de 1,4 m con las campanas y la cafetera', 0),
    'doblaN': ('doblaN', 19, 2, 'la mesa de doblar de 1,2 m con la ropa', 0),
    'mesaP': ('mesaP', 20, 2, 'la mesa de acero de 1,25 m con la masa', 0),
}
# en el grupo detalle-alto, por mapa (_detalle_obj): la bancada de tres asientos de la lavandería en lugar del banco
DETALLE = {
    'd-bench-loc-ibar': ('bench', 13, 'la bancada metálica de tres asientos, 80 cm'),
}
# la cafetera de dos grupos (50 cm) encima de su mueble bajo (90 cm): las dos de PixelLab, juntas aquí
CAFE = (('cafeT', 9), ('mueble', 14))
PAPELERA = ('papelL', 10)   # la papelera de la foto, a la izquierda de la mesa alta (cestaL); a la derecha va la bancada

# el elevador: lo rojo de las columnas, a azul (la luz de atrás del coche, (192, 48, 40), se queda)
AZUL = {(184, 48, 48): (48, 96, 184), (122, 30, 30): (30, 56, 122), (224, 90, 74): (74, 130, 224)}

def escala(im, alto):
    im = im.crop(im.getbbox())
    f = alto / im.height
    return im.resize((max(1, round(im.width * f)), alto), Image.NEAREST)

def binaria(im):
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
    return im

def en_celda(im, n, sube=0):
    cw, ch, cx = (32, 48, 16) if n == 1 else (48, 48, 24)
    out = Image.new('RGBA', (cw, ch))
    out.paste(im, (cx - im.width // 2, ch - im.height - sube), im)
    return out

def sale(grupo, n, im):
    d = P('art', 'crudo', grupo, n, 'unica'); os.makedirs(d, exist_ok=True)
    for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
    im.save(os.path.join(d, '00.png'))
    print(grupo, n, im.getbbox())

def lee(f):
    return binaria(Image.open(os.path.join(SRC, f + '.png')).convert('RGBA'))

if __name__ == '__main__':
    for n, (f, h, c, _, sube) in PIEZAS.items():
        im = binaria(escala(lee(f), h))
        if n == 'cestaL':
            pa = binaria(escala(lee(PAPELERA[0]), PAPELERA[1]))
            junta = Image.new('RGBA', (im.width + 1 + pa.width, h))
            junta.paste(pa, (0, h - pa.height), pa)
            junta.paste(im, (pa.width + 1, 0), im)
            im = junta
        sale('negocios-pl-alto' if c == 1 else 'negocios-pl-ancho', n, en_celda(im, c, sube))
    for n, (f, h, _) in DETALLE.items():
        sale('detalle-alto', n, en_celda(binaria(escala(lee(f), h)), 1))
    (fc, hc), (fm, hm) = CAFE
    cafe, mueble = binaria(escala(lee(fc), hc)), binaria(escala(lee(fm), hm))
    junta = Image.new('RGBA', (max(cafe.width, mueble.width), hc + hm - 1))
    junta.paste(mueble, ((junta.width - mueble.width) // 2, hc - 1), mueble)
    junta.paste(cafe, ((junta.width - cafe.width) // 2, 0), cafe)
    sale('negocios-pl-alto', 'cafeT', en_celda(junta, 1))
    el = Image.open(P('art', 'procesado', 'negocios-coche', 'elevT', 'unica', '00.png')).convert('RGBA')
    px = el.load()
    for y in range(el.height):
        for x in range(el.width):
            p = px[x, y]
            if p[3] and p[:3] in AZUL:
                px[x, y] = AZUL[p[:3]] + (p[3],)
    sale('negocios-pl-coche', 'e-elevT', el)
