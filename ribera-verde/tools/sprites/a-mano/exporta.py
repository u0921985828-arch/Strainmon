# python3 -I tools/sprites/a-mano/exporta.py art/crudo/carpa-c-plantas-a  (Python 3 + Pillow; no va en los scripts de npm)
# Escribe la planta A (planta_a.py) en la paleta A (verde frío) con los cogollos en la rampa clave magenta (el motor les pone el color de
# la variedad y a la hoja el tono de la variedad), ya en la celda planta_c_a (40 × 96, ajuste exacto) con el tallo en las columnas 19-20
# y la base en la última fila: así el tallo no se mueve de una fase a otra.
# Por porte (i índica, h híbrida, s sativa: ind .9, .5 y .1) y ancho (38: todas las carpas; 32: la fila de atrás de la de 120), floración
# y lista (planta-c-<porte>-<ancho>) y vegetativo (planta-c-<porte>2-<ancho>), un fotograma cada 2 px de alto (el 00, el más alto) entre
# los altos que se ven en las carpas (ALTOS); el motor elige el de su alto (vcAltura) y le quita la fila que sobre. Germinando y
# plántula, una sola para los tres portes
import sys, os, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import planta_a
from planta import plantula, germinando
from PIL import Image
PAL = {'O': '#0d2620', 'D': '#1b4630', 'M': '#2f7038', 'L': '#57a33e', 'H': '#94d255', 'T': '#71984a', 'S': '#3b5a2e',   # hoja y tallo (H y T a 90° de tono: más amarillos, test:arte los tomaría por luz pintada)
       'F': '#f2f4dc', 'N': '#f08a3c', 'n': '#b45a28',                                                                  # punta y pistilos
       'P': '#ff5cff', 'Q': '#d020c8', 'R': '#80107a'}                                                                  # cogollo (clave)
CW, CH, TALLO = 40, 96, 19
IND = {'i': .9, 'h': .5, 's': .1}
# alto del dibujo en px (de, a): floración y lista, vegetativo; con el ancho 32 la sativa no pasa de 80 (más alta, se sale del ancho)
ALTOS = {'i': ((40, 66), (24, 36)), 'h': ((44, 72), (28, 42)), 's': ((54, 92), (32, 46))}
def imagen(filas, tallo):   # tallo: columna del tallo en el dibujo
    im = Image.new('RGBA', (CW, CH), (0, 0, 0, 0)); x0, y0 = TALLO - tallo, CH - len(filas)
    for y, r in enumerate(filas):
        for x, c in enumerate(r):
            if c in PAL: im.putpixel((x0 + x, y0 + y), tuple(int(PAL[c][i:i + 2], 16) for i in (1, 3, 5)) + (255,))
    return im
def alto(fn, W, ind, T):   # el dibujo de T filas justas (flor(H) mide H + 1 y veg(H), algo más: el brote de las puntas)
    H = T - 1
    for _ in range(6):
        f = fn(H, W, ind)
        if len(f) == T: return f
        H += T - len(f)
    raise ValueError('sin dibujo de %d filas' % T)
def altos(fn, W, ind, a, b):   # un dibujo cada 2 px de alto, de b (el más alto) a a
    return [alto(fn, W, ind, T) for T in range(b, a - 1, -2)]
SPR = {}
for po, ind in IND.items():
    (fa, fb), (va, vb) = ALTOS[po]
    for W in (38, 32):
        SPR['planta-c-%s-%d' % (po, W)] = (altos(planta_a.flor, W, ind, fa, fb if W == 38 or po != 's' else 80), W // 2 - 1)
        SPR['planta-c-%s2-%d' % (po, W)] = (altos(planta_a.veg, W, ind, va, vb), W // 2 - 1)
SPR['planta-c-h1-18'] = ([plantula()], 8); SPR['planta-c-h0-8'] = ([germinando()], 3)
for k, (fs, tallo) in SPR.items():
    d = os.path.join(sys.argv[1], k, 'unica'); os.makedirs(d, exist_ok=True)
    for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
    for i, f in enumerate(fs): imagen(f, tallo).save(os.path.join(d, '%02d.png' % i))
    print(k, len(fs), 'fotogramas,', 'de', len(fs[0]), 'a', len(fs[-1]), 'filas')
