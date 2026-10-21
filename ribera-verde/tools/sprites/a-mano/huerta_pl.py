# python3 -I tools/sprites/a-mano/huerta_pl.py  (Python 3 + Pillow; no va en los scripts de npm)
# Lo pidió el usuario: «El cultivo tiene que ser igual que en la nave digamos, pero solo que no hay focos, está únicamente la luz del
# sol. No van por macetas sino que se plantan en el suelo pero se hacen más grandes cada planta y la distancia de una a otra es de una
# baldosa, en los bancales que has hecho en el mapa, bien centradas». Las plantas de la huerta de la tía como las de las mesas de la
# nave (locales.py, planta_mesa: vistas desde arriba a medio fondo, en los colores de la planta A para que el juego les ponga el tono
# de hoja y el color de cogollo de la variedad), pero en la tierra, sin maceta, y grandes: a 16 px/m, la planta hecha ocupa los 2 × 2 m
# de su sitio del bancal (la índica, 2 m de ancho y 1,4 de alto; la sativa, 1,6 y 2; la híbrida, entre las dos). Por pisos de ramas,
# de abajo arriba, cada uno con sus hojas de abanico alrededor (las de detrás, en sombra; las de delante, a la luz de arriba a la
# izquierda), el tallo, el alcorque de tierra mientras es pequeña y, en flor, las colas en la punta de cada rama.
#  · huerta-pl (planta_huerta, 48 × 56; el pie del tallo en (24, 40), el centro de su sitio de 2 × 2 casillas; el ancla (16, 55),
#    el centro de abajo de la casilla de abajo a la izquierda): hg-<porte i|h|s>-<fase 1-5>: 1 la plántula, 2 creciendo, 3 el
#    arbusto en vegetativo, 4 en flor (las colas pequeñas, con los pelos blancos), 5 madura (las colas gordas, con los pelos naranjas,
#    y las hojas de abajo amarillas). La seca la pinta el juego en pardos (_seca en pinta.gd).
# Sale a art/crudo/huerta-pl/<sprite>/unica/00.png (después, node tools/sprites/procesar.js huerta-pl --atlas --atlas-dir godot/arte)
import os, sys, glob, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

# la paleta de la planta A (exporta.py), la misma que las de la nave: hojas D M L H, tallo T S, contorno O, cogollo P Q R, pelos N F
PO, PD, PM, PL, PH, PT, PS = '#0d2620', '#1b4630', '#2f7038', '#57a33e', '#94d255', '#71984a', '#3b5a2e'
PP, PQ, PR, PN, PF = '#ff5cff', '#d020c8', '#80107a', '#f08a3c', '#f2f4dc'
AMA = {PL: '#c8b040', PM: '#a08a2a', PH: '#e0d070', PD: '#7a6a20'}   # las hojas de abajo de la madura (huerto.py)
TIERRA = ('#4a3020', '#5a3c22', '#6e4a2a', '#906238')               # el alcorque, como la tierra cavada (SURCO_V de pinta.gd)
W, H, BX, BY = 48, 56, 24, 40

PORTE = {   # la copa por fase (semiejes en px; la de la planta hecha, 2 × 2 m), sus lóbulos (dx, dy, rx, ry en partes de la copa),
            # la hoja de abanico grande (hacia arriba; T la punta de los dedos, c la hoja, + el rabillo) y las colas (ancho, alto)
    'i': dict(rx={2: 6, 3: 13, 4: 14, 5: 14}, ry={2: 4.5, 3: 9, 4: 10, 5: 10}, fr=6,
              lob=[(-.45, .15, .58, .62), (.45, .15, .58, .62), (0, -.2, .62, .72), (0, .32, .62, .6)],
              hoja=('...T...', '.T.c.T.', 'T.ccc.T', '.ccccc.', '..ccc..', '...+...'), cola=(3, 6), colas=7),
    'h': dict(rx={2: 5.5, 3: 12, 4: 13, 5: 13}, ry={2: 5, 3: 11, 4: 12, 5: 12}, fr=6,
              lob=[(-.42, .2, .58, .58), (.42, .2, .58, .58), (0, -.25, .6, .7), (0, .35, .62, .55)],
              hoja=('...T...', '.T.c.T.', 'T.ccc.T', '..ccc..', '..ccc..', '...+...'), cola=(3, 7), colas=6),
    's': dict(rx={2: 4.5, 3: 10, 4: 11, 5: 11}, ry={2: 6, 3: 13, 4: 15, 5: 15}, fr=5,
              lob=[(-.4, .3, .6, .5), (.4, .3, .6, .5), (0, -.3, .55, .7), (0, .4, .62, .5)],
              hoja=('...T...', '...c...', '.T.c.T.', 'T.ccc.T', '..ccc..', '...c...', '...+...'), cola=(2, 9), colas=5),
}
CHICA = {   # la hoja pequeña (la de las plantas de la nave): para la textura de la copa y la planta joven
    'i': ('T.T.T', 'TcccT', '.c+c.'),
    'h': ('..T..', 'T.c.T', '.ccc.', '..+..'),
    's': ('..T..', '..c..', 'T.c.T', '.ccc.', '..+..'),
}

def sello(L, x, y, pat, lado, c, cp, solo_vacio=False):
    """la hoja pat con el rabillo en (x, y), vuelta hacia lado: 0 arriba, 1 a la derecha, −1 a la izquierda, 2 abajo"""
    h = len(pat); ay = next(j for j, f in enumerate(pat) if '+' in f); ax = pat[ay].index('+')
    for j, fila in enumerate(pat):
        for i, ch in enumerate(fila):
            if ch == '.': continue
            dx, dy = i - ax, j - ay
            if lado == 1: dx, dy = -dy, dx
            elif lado == -1: dx, dy = dy, -dx
            elif lado == 2: dx, dy = -dx, -dy
            if solo_vacio and L.lleno(x + dx, y + dy): continue
            L.p(x + dx, y + dy, cp if ch == 'T' else c)

def cola(L, x, y, w, h, fase):
    """la cola con la punta arriba en (x, y): en flor (4), pequeña y con los pelos blancos; madura (5), gorda, con la luz a la
    izquierda (P), el cuerpo (Q), la sombra a la derecha y abajo (R), los pelos naranjas y un tricoma"""
    if fase == 4:
        w, h = max(1, w - 1), max(3, h - 2); y += 2
    x0 = x - w // 2
    for j in range(h):
        for i in range(w):
            if j == 0 and w > 1 and i != w // 2: continue
            c = PQ
            if fase == 5 and w > 1:
                if i == 0: c = PP
                elif i == w - 1 or j == h - 1: c = PR
            L.p(x0 + i, y + j, c)
    if fase == 4:
        L.p(x, y - 1, PF)
        for j in range(2, h - 1, 3): L.p(x0 + (j // 3) % 2 * (w - 1), y + j, PF)
        return
    L.p(x, y - 1, PN)
    for j in range(1, h - 1, 2): L.p(x0 + (j // 2) % 2 * (w - 1), y + j, PN)
    if w > 2: L.p(x0 + 1, y + h - 2, PF)

def planta(porte, fase):
    C = PORTE[porte]
    G = Lienzo(W, H)   # la tierra (sin contorno)
    Pl = Lienzo(W, H)  # la planta (con su contorno)
    R = azar(11 + 7 * fase + 'ihs'.index(porte))
    if fase == 1:   # la plántula: el alcorque, el tallito y dos pares de hojas
        for y in range(BY - 2, BY + 3):
            for x in range(BX - 6, BX + 7):
                u, v = (x - BX) / 6.2, (y - BY) / 2.6
                if u * u + v * v <= 1: G.p(x, y, TIERRA[1] if v > .2 or u > .3 else TIERRA[2])
        G.hl(BX - 3, BX - 1, BY - 2, TIERRA[3])
        for y in range(BY - 4, BY + 1): Pl.p(BX, y, PT if y > BY - 3 else PS)
        sello(Pl, BX - 1, BY - 2, CHICA[porte], -1, PM, PL); sello(Pl, BX + 1, BY - 2, CHICA[porte], 1, PM, PL)
        sello(Pl, BX, BY - 4, CHICA[porte], 0, PL, PH)
        Pl.contorno(PO)
        G.pega(Pl, 0, 0)
        return G
    rx, ry = C['rx'][fase], C['ry'][fase]
    fr = C['fr'] if fase > 2 else 2
    cx, cy = BX, BY + fr - ry                                     # la copa: lo de delante, fr px por delante del pie
    def forma(x, y, m=1.0):   # ¿dentro de la copa? la sativa, más estrecha arriba; la índica, más ancha abajo
        u, v = (x - cx) / rx, (y - cy) / ry
        if porte == 's': u /= 1 - .32 * max(0, -v)
        elif porte == 'i': u /= 1 + .08 * max(0, v)
        else: u /= 1 - .15 * max(0, -v)
        return u * u + v * v <= m
    tonos = lambda q: ((PL, PH, PM) if q < -.5 else (PL, PL, PM) if q < -.15 else (PM, PL, PD) if q < .25 else (PM, PM, PD) if q < .55 else (PD, PM, None))
    # el suelo: el alcorque de la joven; la sombra de la mata, delante y a los lados del pie
    for y in range(BY - 3, BY + fr + 3):
        for x in range(BX - round(rx) - 2, BX + round(rx) + 3):
            u, v = (x - BX) / (rx * .9 + 2), (y - (BY + fr * .5)) / (fr * .5 + 2.5)
            if u * u + v * v <= 1: G.p(x, y, TIERRA[0] if v > -.3 else TIERRA[1])
    if fase == 2:
        G.hl(BX - round(rx) - 1, BX - round(rx) + 1, BY - 1, TIERRA[3])
    # la copa: el fondo oscuro y, de arriba abajo, racimos de hojas pequeñas, cada uno con su sombra debajo, a la luz de arriba a la
    # izquierda: los de abajo tapan el pie de los de arriba
    for y in range(round(cy - ry) - 1, round(cy + ry) + 2):
        for x in range(round(cx - rx) - 1, round(cx + rx) + 2):
            if forma(x, y): Pl.p(x, y, PD)
    pas = 4 if fase >= 3 else 3
    for gy, y in enumerate(range(round(cy - ry) + 1, round(cy + ry) + 1, 3)):
        for x in range(round(cx - rx) + (gy % 2) * pas // 2, round(cx + rx) + 1, pas):
            xx, yy = x + round(R() * 2 - 1), y + round(R() - .5)
            if not forma(xx, yy, .92): continue
            q = (yy - cy) / ry * .75 + (xx - cx) / rx * .45
            c, cp, sb = tonos(q)
            lado = 0 if R() < .6 else (-1 if xx < cx else 1)
            if sb: sello(Pl, xx, yy + 1, CHICA[porte], lado, sb, sb)
            sello(Pl, xx, yy, CHICA[porte], lado, c, cp)
    big = C['hoja'] if fase >= 3 else CHICA[porte]
    ama = (lambda c: AMA.get(c, c)) if fase == 5 else (lambda c: c)
    # las hojas grandes del borde: las de los lados en dos alturas y las de abajo, caídas por delante (en la madura, amarillas)
    for s in (-1, 1):
        for b in (-.2, .3):
            x = round(cx + s * rx * (.9 if b < 0 else .82)); y = round(cy + b * ry)
            c, cp, _ = tonos(b * .75 + s * .45)
            sello(Pl, x, y, big, s, c, cp, True)
    for k, dx in enumerate((-.6, -.2, .2, .6) if fase >= 3 else (-.45, .45)):
        x = round(cx + dx * rx); y = round(cy + ry * (.8 if abs(dx) < .5 else .6))
        sello(Pl, x, y, big, 2, ama(PD) if k % 2 else ama(PM), ama(PM) if k % 2 else ama(PL), True)
    if fase <= 3:   # creciendo: las puntas hacia arriba, con los brotes claros
        for dx in ((-.45, 0, .45) if fase == 3 else (0,)):
            x = round(cx + dx * rx); y = round(cy - ry * (.88 if dx == 0 else .68))
            sello(Pl, x, y, big if fase == 3 else CHICA[porte], 0, PL, PH, True)
    else:           # en flor: una cola en la punta de cada rama de la mitad de arriba de la copa y la de arriba, la más alta
        w, h = C['cola']
        pts = []
        for gy, y in enumerate(range(round(cy - ry * .75), round(cy + ry * .25), 4)):
            for x in range(round(cx - rx) + (gy % 2) * 3, round(cx + rx) + 1, 6):
                if forma(x, y, .62): pts.append((x, y))
        for x, y in pts:
            cola(Pl, x, y - h + 2, w, h, fase)
        cola(Pl, cx, round(cy - ry) - h + 1, w + (1 if w < 3 else 0), h + 3, fase)
    Pl.contorno(PO)
    G.pega(Pl, 0, 0)
    return G

SAL = {f'hg-{p}-{f}': planta(p, f) for p in 'ihs' for f in range(1, 6)}

def escribe(raiz=None):
    for n, L in SAL.items():
        d = os.path.join(raiz, n) if raiz else P('art', 'crudo', 'huerta-pl', n, 'unica'); os.makedirs(d, exist_ok=True)
        for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
        L.im.save(os.path.join(d, '00.png'))
        print('huerta-pl', n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
