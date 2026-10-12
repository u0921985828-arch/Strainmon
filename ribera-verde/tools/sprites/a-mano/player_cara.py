# python3 -I tools/sprites/a-mano/player_cara.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# La cabeza del jugador igual en todos los fotogramas (1.11). PixelLab dibujó cada fotograma con su cara: en unos los ojos se juntan
# (bizco: los brillos por dentro), en otros se abre la boca, la gorra cambia de forma o un ojo se queda en un píxel. Aquí se toma una
# cabeza por dirección, la del primer paso (walk/<dir>/00), y en la de frente se le dibuja a mano la cara (ojos finos de 1 × 2, sin
# brillo, a la misma distancia del centro, la frente sin la sombra de la visera, que parecía una ceja, y la boca centrada); de lado,
# la del primer paso ya mira bien (el cuello, sin sombra). Después se pega en cada fotograma sobre la fila de la camiseta (la cabeza
# sube y baja con el cuerpo) y en la columna en que casa el pecho (la cabeza va con el cuerpo, sin bailar de lado). De lado, la sombra
# marrón del cuello en la camiseta pasa a rojo oscuro (con el cuello parecía barba). De espaldas no hay cara: se queda como está.
# En las acciones solo se pega donde la cabeza está derecha y sin nada delante: de frente, los fotogramas de DE_FRENTE (la mano en
# la nariz, la regadera por encima de la cabeza o la cabeza hacia el móvil se quedan como están); de lado, donde la cabeza de antes casa con la nueva.
# El idle era cada fotograma una postura (de lado, el cuerpo encogía 2 px; de espaldas, los pies bajaban): ahora es la de base
# (base/<dir>/00, de pie, a la altura de andar) respirando, con la cabeza 1 px más abajo en la segunda mitad, también de espaldas.
# Lee y escribe art/procesado/player (repetirlo da lo mismo); después, node tools/sprites/procesar.js --atlas. Si se vuelve a
# procesar el grupo player desde art/crudo, hay que pasar otra vez este script.
import os, sys, glob
from PIL import Image

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'procesado', 'player')
ANIMS = ('base', 'walk', 'run')
ACCIONES = ('cosechar', 'oler', 'plantar', 'regar', 'telefono', 'vender')
DIRS = ('south', 'east', 'west')
PARECIDO = .8   # en las acciones de lado, lo que tiene que casar la cabeza de antes con la nueva (de 0 a 1) para cambiarla
DE_FRENTE = {'oler': (0, 1, 7), 'regar': (0, 1, 2, 6, 7), 'telefono': (0, 5)}   # las que no salen, todos
CAMISETA = {(200, 56, 56), (160, 48, 48)}
COL = {'A': (24, 14, 30), 'G': (74, 42, 42), 'I': (122, 90, 58), 'F': (232, 184, 148), 'J': (244, 244, 244), 'K': (160, 48, 48)}
# la cara de frente, de la fila de debajo de la visera a la barbilla (14 de ancho, desde el contorno izquierdo; '.' = transparente)
CARA = ['AGFFFFFFFFFFGA',
        'AGFFAFFFFAFFGA',
        'AFFFAFFFFAFFFA',
        'AFFFFFFFFFFFFA',
        '.AFFFFFFFFFFA.',
        '..AFFFIIFFFA..',
        '...AIFFFFIA...']

def abre(f): return Image.open(f).convert('RGBA')

def camiseta(im):   # la primera fila con la camiseta (3 píxeles rojos o más; la boca lleva uno): encima, la cabeza con el cuello
    for y in range(im.height):
        if sum(im.getpixel((x, y))[:3] in CAMISETA and im.getpixel((x, y))[3] > 0 for x in range(im.width)) >= 3: return y
    raise ValueError('sin camiseta')

def cabeza(im):   # {(x, y): color} de lo que hay encima de la camiseta, y (relativa a esa fila)
    s = camiseta(im)
    return {(x, y - s): im.getpixel((x, y)) for y in range(s) for x in range(im.width) if im.getpixel((x, y))[3]}

def pecho(im):   # lo que se ve en las 3 primeras filas de la camiseta, y relativa
    s = camiseta(im)
    return {(x, y - s) for y in range(s, min(s + 3, im.height)) for x in range(im.width) if im.getpixel((x, y))[3]}

def plantilla(d):
    im = abre(os.path.join(RAIZ, 'walk', d, '00.png')); c = cabeza(im)
    if d == 'south':
        bar = -2   # la barbilla: encima del cuello
        x0 = min(x for x, y in c if y == bar - 3)
        for j, fila in enumerate(CARA):
            for i, k in enumerate(fila):
                p = (x0 + i, bar - len(CARA) + 1 + j)
                if k == '.': c.pop(p, None)
                else: c[p] = COL[k] + (255,)
    else:   # de lado, el cuello sin la sombra marrón: con la del cuello de la camiseta parecía barba
        for (x, y), v in c.items():
            if y == -1 and v[:3] == COL['I']: c[(x, y)] = COL['F'] + (255,)
    return c, pecho(im)

def pega(f, d, accion=None):
    T, P = PL[d]; im = abre(f); s = camiseta(im); vieja = set(cabeza(im)); p = pecho(im)
    mueve = lambda S, k: {(x + k, y) for x, y in S}
    dx = max(range(-3, 4), key=lambda k: (len(mueve(P, k) & p) - len(mueve(P, k) ^ p) / 2, -abs(k)))
    parecido = len(mueve(T, dx) & vieja) / len(mueve(T, dx) | vieja)
    if accion and (accion[1] not in DE_FRENTE.get(accion[0], (accion[1],)) if d == 'south' else parecido < PARECIDO): return None
    xs = [x + dx for x, y in T]
    for y in range(s):   # la cabeza de antes, en las columnas de la nueva (al lado, el agua, el papel o la bolsa se quedan)
        for x in range(max(0, min(xs) - 1), min(im.width, max(xs) + 2)): im.putpixel((x, y), (0, 0, 0, 0))
    for (x, y), c in T.items():
        if 0 <= x + dx < im.width and 0 <= y + s: im.putpixel((x + dx, y + s), c)
    if d != 'south':   # la sombra marrón del cuello en las 2 primeras filas de la camiseta, a rojo oscuro
        cuello = {x + dx for x, y in T if y == -1}
        for y in range(s, min(s + 2, im.height)):
            for x in range(im.width):
                if im.getpixel((x, y))[:3] == COL['I'] and min(abs(x - c) for c in cuello) <= 1: im.putpixel((x, y), COL['K'] + (255,))
    im.save(f)
    return dx

def respira(d):   # idle: la postura de base (ya con la cabeza nueva) en todos; en la segunda mitad, la cabeza 1 px más abajo (sobre el cuello de la camiseta)
    fs = sorted(glob.glob(os.path.join(RAIZ, 'idle', d, '*.png')))
    im = abre(os.path.join(RAIZ, 'base', d, '00.png')); s = camiseta(im); baja = im.copy()
    for y in range(s, 0, -1):
        for x in range(im.width):
            if y < s or im.getpixel((x, y - 1))[3]: baja.putpixel((x, y), im.getpixel((x, y - 1)))
    for x in range(im.width): baja.putpixel((x, 0), (0, 0, 0, 0))
    for i, f in enumerate(fs): (baja if i >= len(fs) // 2 else im).save(f)

PL = {d: plantilla(d) for d in DIRS}
for a in ANIMS + ACCIONES:
    for d in DIRS:
        fs = sorted(glob.glob(os.path.join(RAIZ, a, d, '*.png')))
        if fs: print(a, d, [pega(f, d, (a, i) if a in ACCIONES else None) for i, f in enumerate(fs)])
for d in ('north',) + DIRS: respira(d)
