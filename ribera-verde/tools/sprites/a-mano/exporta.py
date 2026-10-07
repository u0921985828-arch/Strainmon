# python3 -I tools/sprites/a-mano/exporta.py art/crudo/carpa-c-plantas-h  (Python 3 + Pillow; no va en los scripts de npm)
# Escribe la híbrida en la paleta A (verde frío) con los cogollos en la rampa clave magenta (el motor les pone el color de la variedad),
# ya en la celda planta_c_alta (48 × 112, ajuste exacto) con el tallo en las columnas 23-24 y la base en la última fila: así el tallo no
# se mueve de una fase a otra. Floración y lista (planta-c-h-24) y vegetativo (planta-c-h2-24) van dibujados a cada alto, un fotograma por
# alto (el 00, el más alto): más alta = más nudos, y el motor elige el de su alto en vez de quitarle filas (vcAltura). Plántula y germinando,
# uno solo
import sys, os, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from planta import planta, plantula, germinando
from PIL import Image
PAL = {'O': '#0d2620', 'D': '#1b4630', 'M': '#2f7038', 'L': '#57a33e', 'H': '#94d255', 'T': '#71984a', 'S': '#3b5a2e',   # hoja y tallo (H y T a 90° de tono: más amarillos, test:arte los tomaría por luz pintada)
       'F': '#f2f4dc', 'N': '#f08a3c', 'n': '#b45a28',                                                                  # punta y pistilos
       'P': '#ff5cff', 'Q': '#d020c8', 'R': '#80107a'}                                                                  # cogollo (clave)
CW, CH, TALLO = 48, 112, 23
def imagen(filas, tallo):   # tallo: columna del tallo en el dibujo
    im = Image.new('RGBA', (CW, CH), (0, 0, 0, 0)); x0, y0 = TALLO - tallo, CH - len(filas)
    for y, r in enumerate(filas):
        for x, c in enumerate(r):
            if c in PAL: im.putpixel((x0 + x, y0 + y), tuple(int(PAL[c][i:i + 2], 16) for i in (1, 3, 5)) + (255,))
    return im
def altos(flor, H0, H1):   # un dibujo por alto, del más alto al más bajo (planta(H) mide H filas o, sin flor, alguna menos: sin repetir)
    vistos = {}
    for H in range(H0, H1 - 1, -1):
        f = planta(H, flor=flor); vistos.setdefault(len(f), f)
    return list(vistos.values())
SPR = {'planta-c-h-24': (altos(True, 99, 40), 11), 'planta-c-h2-24': (altos(False, 54, 20), 11), 'planta-c-h1-18': ([plantula()], 8), 'planta-c-h0-8': ([germinando()], 3)}
for k, (fs, tallo) in SPR.items():
    d = os.path.join(sys.argv[1], k, 'unica'); os.makedirs(d, exist_ok=True)
    for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
    for i, f in enumerate(fs): imagen(f, tallo).save(os.path.join(d, '%02d.png' % i))
    print(k, len(fs), 'fotogramas,', 'de', len(fs[0]), 'a', len(fs[-1]), 'filas')
