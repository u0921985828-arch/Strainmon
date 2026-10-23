# python3 -I tools/sprites/a-mano/player_cara.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# La cabeza del jugador igual en todos los fotogramas (1.11). PixelLab dibujó cada fotograma con su cara: en unos los ojos se juntan
# (bizco: los brillos por dentro), en otros se abre la boca, la gorra cambia de forma o un ojo se queda en un píxel. Aquí se toma una
# cabeza por dirección, la del primer paso (walk/<dir>/00), y en la de frente se le dibuja a mano la cara (los ojos de `CARA`, a la
# misma distancia del centro, la frente sin la sombra de la visera, que parecía una ceja, y la boca centrada); de lado,
# la del primer paso ya mira bien (el cuello, sin sombra). Después se pega en cada fotograma sobre la fila de la camiseta (la cabeza
# sube y baja con el cuerpo) y en la columna en que casa el pecho (la cabeza va con el cuerpo, sin bailar de lado). De lado, la sombra
# marrón del cuello en la camiseta pasa a rojo oscuro (con el cuello parecía barba). De espaldas no hay cara: se queda como está.
# En las acciones solo se pega donde la cabeza está derecha y sin nada delante: de frente, los fotogramas de DE_FRENTE (la mano en
# la nariz, la regadera por encima de la cabeza o la cabeza hacia el móvil se quedan como están); de lado, donde la cabeza de antes casa con la nueva.
# Los ojos (1.11, opción C): los mismos en todos los fotogramas. De frente, el párpado de 3 px y debajo blanco, iris y blanco (en
# `CARA`); de lado, el párpado de 2 y debajo el blanco detrás y el iris delante. PixelLab los dibujó cada uno a su manera (de lado,
# el blanco al lado de la pupila, saltones): `ojos` pasa a piel el blanco del ojo (dentro de lo ancho de la gorra y encima de la
# camiseta, hasta que no quede; el brillo de la regadera, `BRILLO`, se queda), busca la pupila (lo oscuro con cara a los dos lados) y dibuja el ojo desde su píxel de arriba; si la pupila subía hasta
# la gorra, ese píxel pasa a piel; el que mira abajo (el párpado de 2 × 1, con piel debajo) también se abre: de lado, el de más
# delante; de frente, centrado en el de la derecha del par. Va en la cabeza de lado (`plantilla`), en las acciones de lado donde la
# cabeza no se cambia y en las de frente de `OJOS_SUR` (con 0, solo el blanco a piel: mira al móvil, el párpado basta); donde la
# cara se ve y no hay pupila que buscar, el ojo va a mano (`A_MANO`). El iris (`R`) marca lo ya dibujado: repetirlo da lo mismo.
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
OJOS_SUR = {'regar': ((3, 4, 5), 1), 'telefono': ((3,), 0)}   # de frente sin la cabeza nueva, con los ojos blancos (1: se dibuja el ojo)
BRILLO = {('regar', 'south'): {(7, 14), (8, 14), (9, 14), (7, 15), (8, 15)}}   # x, y: el blanco que no es del ojo
A_MANO = {('vender', 'east', 2): ((15, 13, 'F'), (16, 13, 'A'), (17, 13, 'A'), (16, 14, 'J'), (17, 14, 'R')),   # x, y, color: el ojo de vender/east/03
          ('cosechar', 'east', 2): ((16, 16, 'A'), (17, 16, 'A'), (16, 17, 'J'), (17, 17, 'R')),   # el de cosechar/east/03
          ('plantar', 'east', 2): ((19, 15, 'F'), (17, 16, 'J'), (18, 16, 'R')),   # mirando abajo: el párpado ya está
          ('regar', 'south', 3): ((12, 14, 'A'), (13, 14, 'A'), (12, 15, 'R'), (13, 15, 'J')),   # el ojo izquierdo, 5 px a la izquierda del
          ('regar', 'south', 4): ((12, 16, 'R'), (13, 16, 'J')),                                 # derecho (como en `CARA`), con el brazo de
          ('regar', 'south', 5): ((12, 16, 'R'), (13, 16, 'J'))}                                 # la regadera tapando el blanco de fuera
CAMISETA = {(200, 56, 56), (160, 48, 48)}
GORRA = {(42, 138, 90), (90, 168, 96)}
COL = {'A': (24, 14, 30), 'G': (74, 42, 42), 'I': (122, 90, 58), 'F': (232, 184, 148), 'J': (244, 244, 244), 'K': (160, 48, 48), 'R': (92, 58, 40)}
# la cara de frente, de la fila de debajo de la visera a la barbilla (14 de ancho, desde el contorno izquierdo; '.' = transparente)
CARA = ['AGFFFFFFFFFFGA',
        'AGFAAAFFAAAFGA',
        'AFFJRJFFJRJFFA',
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
    im = abre(os.path.join(RAIZ, 'walk', d, '00.png'))
    if d != 'south': ojos(im, d)
    c = cabeza(im)
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

def ojos(im, d, dibuja=1, deja=()):   # los ojos de la opción C en im (ver arriba); devuelve cuántos ha dibujado (o los blancos quitados)
    s = camiseta(im); F, A, J, R = (COL[k] + (255,) for k in 'FAJR')
    px = lambda x, y: im.getpixel((x, y)) if 0 <= x < im.width and 0 <= y < im.height and im.getpixel((x, y))[3] else None
    gx = [x for y in range(s) for x in range(im.width) if (px(x, y) or (0,))[:3] in GORRA]
    if not gx or any(px(x, y) == R for y in range(s) for x in range(im.width)): return 0
    caja = [(x, y) for y in range(s) for x in range(min(gx), max(gx) + 1)]
    blancos = set()
    while True:
        n = [p for p in caja if p not in deja and px(*p) == J and F in (px(p[0] + 1, p[1]), px(p[0] - 1, p[1]), px(p[0], p[1] + 1), px(p[0], p[1] - 1))]
        if not n: break
        for p in n: im.putpixel(p, F); blancos.add(p)
    if not dibuja: return len(blancos)
    pup = {(x, y) for x, y in caja if px(x, y) == A and px(x - 1, y) == F and px(x + 1, y) == F}
    grupos = []   # la pupila: lo oscuro con piel a los dos lados, por grupos que se tocan
    for p in sorted(pup, key=lambda p: (p[1], p[0])):
        g = next((g for g in grupos if any(abs(p[0] - q[0]) <= 1 and abs(p[1] - q[1]) <= 1 for q in g)), None)
        (g.append(p) if g else grupos.append([p]))
    if d != 'south':   # de lado, un ojo: el de más delante
        f = 1 if d == 'east' else -1
        grupos = sorted(grupos, key=lambda g: -f * g[0][0])[:1]
    abajo = [(x, y) for x, y in caja if y + 1 < s and px(x, y) == A and px(x + 1, y) == A and px(x - 1, y) == F and px(x + 2, y) == F
             and px(x, y + 1) == F and px(x + 1, y + 1) == F]   # el ojo mirando abajo (2 × 1, solo el párpado), si debajo hay piel
    if not grupos and abajo:
        if d != 'south': x, y = max(abajo, key=lambda p: f * p[0]); grupos = [[(x + (f > 0), y)]]   # el de delante
        else:   # de frente, centrado en el de la derecha del par, si cabe (piel a su derecha, arriba y abajo)
            grupos = [[(x + 1, y)] for x, y in abajo if px(x + 2, y + 1) == F][:1]
    for g in grupos:
        x, y = g[0]
        for q in g: im.putpixel(q, F)
        if px(x, y - 1) == A and px(x - 1, y - 1) != A and px(x + 1, y - 1) != A and px(x, y - 2) and px(x, y - 2) != A: im.putpixel((x, y - 1), F)
        if d == 'south':
            for i in (-1, 0, 1): im.putpixel((x + i, y), A)
            for i, c in ((-1, J), (0, R), (1, J)): im.putpixel((x + i, y + 1), c)
        else:
            for p, c in (((x, y), A), ((x - f, y), A), ((x - f, y + 1), J), ((x, y + 1), R)): im.putpixel(p, c)
    return len(grupos)

def ojosF(f, d, dibuja=1, mano=(), deja=()):
    im = abre(f); antes = im.tobytes(); n = ojos(im, d, dibuja, deja)
    for x, y, k in mano: im.putpixel((x, y), COL[k] + (255,)); n = n or 1
    if im.tobytes() != antes: im.save(f)
    return n

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
        if d != 'south' and fs: print(' ojos', [ojosF(f, d, 1, A_MANO.get((a, d, i), ())) for i, f in enumerate(fs)])
for a, (ii, dib) in OJOS_SUR.items(): print(a, 'south ojos', [ojosF(os.path.join(RAIZ, a, 'south', '%02d.png' % i), 'south', dib, A_MANO.get((a, 'south', i), ()), BRILLO.get((a, 'south'), ())) for i in ii])
for d in ('north',) + DIRS: respira(d)
