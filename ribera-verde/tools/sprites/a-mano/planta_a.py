# planta A (baja, como en las fotos): despuntada y en mainline. El tallo sube unas filas y se abre en una corona de 6 ramas en V.
# Floración y lista (flor): cada rama con su tramo pelado abajo (lollipop), nudos con yemas en pares cruzados y la cola en la punta;
# las 6 colas en zigzag (3 detrás, más altas; 3 delante, más bajas), con aire entre las puntas. Vegetativo (veg): la misma corona sin
# cogollos ni lollipop: hojas de abanico en cada nudo hasta abajo y un brote en cada punta.
# La genética manda en la forma: ind (0 sativa … 1 índica) da el ancho y el número de foliolos, el internudo y la forma de las colas
import os, sys, functools
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import prim
from cola2 import cola2
@functools.lru_cache(None)
def hoja(*a): return prim.hoja(*a)
OSC = {'H': 'L', 'L': 'M', 'M': 'D'}   # hoja de detrás, en sombra
X38 = [8, 17, 27, 12, 22, 31]   # x de las 6 puntas en el dibujo de 38 de ancho (3 detrás, 3 delante)
class Lienzo:
    def __init__(s, H, W, ind, M=8):
        s.H, s.W, s.M, s.ind = H, W, M, ind; s.GW, s.GH = W + 2 * M, H + M
        s.g = [['.'] * s.GW for _ in range(s.GH)]
        s.nf = 9 if ind < .25 else 7; s.anc = round(1.6 + 1.2 * ind, 1); s.extra = round(2 * (1 - ind))
        s.sx = W // 2 - 1
        s.xs = [s.sx + round((x - 18) * W / 38) for x in X38]
    def put(s, x, y, c):
        x += s.M; y += s.M
        if 0 <= x < s.GW and 0 <= y < s.GH: s.g[y][x] = c
    def pieza(s, pts):   # cada pieza con su contorno
        for (x, y) in pts:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if (x + dx, y + dy) not in pts: s.put(x + dx, y + dy, 'O')
        for (x, y), c in pts.items(): s.put(x, y, c)
    def hojap(s, L, gi, x, y, pec=2, osc=False):   # hoja de abanico; si no cabe, se endereza, se acorta y, si aún no, se mete hacia dentro
        W = s.W
        for g2, L2 in [(gi, L), (gi * .8, L), (gi * .6, L), (gi * .8, L - 1), (gi * .5, L - 1), (gi * .3, L - 2), (0, L - 2)]:
            hp = hoja(s.nf, L2 + s.extra, s.anc, 95, 2.5, round(g2), pec)
            if all(1 <= x + dx <= W - 2 for (dx, dy) in hp): break
        else:
            x += max(0, 1 - min(x + dx for dx, _ in hp)) - max(0, max(x + dx for dx, _ in hp) - (W - 2))
        s.pieza({(x + dx, y + dy): (OSC.get(c, c) if osc else c) for (dx, dy), c in hp.items() if c != 'O'})
    def linea(s, x0, y0, x1, y1, c):
        n = 4 * (abs(y1 - y0) + abs(x1 - x0) + 1)
        for j in range(n + 1):
            t = j / n; s.put(round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t), c)
    def fin(s, estricto=True):
        g, M, W, GW, GH = s.g, s.M, s.W, s.GW, s.GH
        borde = [(xx, yy) for yy in range(GH) for xx in range(GW) if g[yy][xx] == '.' and any(
            0 <= xx + dx < GW and 0 <= yy + dy < GH and g[yy + dy][xx + dx] not in '.O' for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
        for xx, yy in borde: g[yy][xx] = 'O'
        fuera = [(x - M, y - M) for y in range(GH) for x in list(range(M)) + list(range(M + W, GW)) if g[y][x] != '.']
        if fuera and estricto: raise ValueError('se sale del ancho %d: %s' % (W, fuera[:6]))
        g = [r[M:M + W] for r in g]
        while all(c == '.' for c in g[0]): g.pop(0)
        return [''.join(r) for r in g]
# yema en flor: racimo de cálices (luz arriba a la izquierda), pelos (estigmas) naranjas y algún tricoma blanco
YEMA = {1: ['.P.', 'PQ.', 'QRn', '.R.'], 2: ['..P.', '.PQ.', 'PFQR', 'QNnR', '.RR.'], 3: ['..P..', '.PQ..', 'PFQQ.', 'PQQRn', 'QNnRR', '.RRR.']}
def flor(H=62, W=38, ind=.5, estricto=True):
    """H filas sin el contorno de arriba (el dibujo mide H + 1)"""
    L_ = Lienzo(H, W, ind); put, pieza, hojap, sx = L_.put, L_.pieza, L_.hojap, L_.sx
    f = lambda v: round(H * v); hub = H - 5
    for yy in range(hub, H): put(sx, yy, 'T'); put(sx + 1, yy, 'S')
    k = 1 + .3 * (1 - ind)                                   # sativa: colas más largas
    w0 = 4 + round(2 * ind)                                  # sativa: colas finas; índica: gordas
    xs = L_.xs
    R = [(xs[0], 0, f(.07), round(f(.24) * k)), (xs[1], 0, 0, round(f(.27) * k)), (xs[2], 0, f(.04), round(f(.25) * k)),
         (xs[3], 1, f(.24), round(f(.21) * k)), (xs[4], 1, f(.21), round(f(.22) * k)), (xs[5], 1, f(.26), round(f(.2) * k))]
    def yema(t, cx, cy):
        st = YEMA[t]; h = len(st); w = len(st[0])
        pieza({(cx - w // 2 + i, cy - h // 2 + j): c for j, r in enumerate(st) for i, c in enumerate(r) if c != '.'})
    def colap(x, top, L, w, sem):
        st = cola2(L, w, sem, 2, 3 if ind >= .4 else 2); ww = max(p[0] for p in st) + 1
        pieza({(x - ww // 2 + px, top + py): v for (px, py), v in st.items()})
    ent = 4 if ind >= .5 else 5                              # internudo: la sativa, más estirada
    def rama(i, x, fondo, top, L):
        yb = top + L - 1                                     # pie de la cola
        yfin = f(.55) if fondo == 0 else f(.62)              # el último nudo con yema; por debajo, rama pelada (lollipop)
        c = 'S' if fondo == 0 else 'T'
        L_.linea(sx + (x > sx), hub, x, yfin + 1, c)
        for yy in range(yb, yfin + 2): put(x, yy, c)
        d = -1 if x < sx else 1
        # nudos de abajo arriba: pares cruzados (decusados). En uno, las dos yemas a los lados con su hoja de abanico hacia
        # fuera; en el siguiente, girado 90°, una delante y otra detrás (la de delante tapa la rama). Más pequeñas cuanto más abajo
        nud = list(range(yb + ent, yfin + 1, ent))
        for kk, y in reversed(list(enumerate(nud))):
            t = 3 if kk == 0 else 2 if kk == 1 else 1
            if (kk + i) % 2 == 0:
                hojap(10 if kk == len(nud) - 1 else 8, d * 70, x + d, y + 1)
                yema(t, x - d * (t // 2 + 2), y); yema(t, x + d * (t // 2 + 2), y)
            else:
                yema(t, x, y)
        if abs(x - sx) > 8 * W / 38: hojap(9, d * 75, x + d * 2, top + L // 2 + 2)   # hoja de la cola, por detrás, hacia fuera
        colap(x, top, L, w0 + fondo, i + 1)
        if fondo and nud: hojap(10, d * 80, x + d, nud[-1] + 2)   # delante: la hoja grande del nudo de abajo, hacia fuera
    for i, r in enumerate(R):
        if r[1] == 0: rama(i, *r)
    for i, r in enumerate(R):
        if r[1] == 1: rama(i, *r)
    return L_.fin(estricto)
def veg(H=36, W=38, ind=.5, estricto=True):
    """vegetativo despuntado: la corona de 6 ramas sin cogollos ni lollipop; en cada rama dos hojas de abanico grandes hacia fuera
    (las de las ramas de detrás, en sombra) y un brote en la punta. Pocas hojas y grandes: que se lea cada abanico"""
    L_ = Lienzo(H, W, ind); put, pieza, hojap, sx = L_.put, L_.pieza, L_.hojap, L_.sx
    f = lambda v: round(H * v); hub = H - 3
    for yy in range(hub, H): put(sx, yy, 'T'); put(sx + 1, yy, 'S')
    xs = L_.xs
    R = [(xs[0], 0, f(.08)), (xs[1], 0, f(.0)), (xs[2], 0, f(.05)), (xs[3], 1, f(.16)), (xs[4], 1, f(.13)), (xs[5], 1, f(.18))]
    def brote(x, y):   # brote de la punta: hojas nuevas hacia arriba
        hp = hoja(5, 5, max(1.5, L_.anc - .5), 60, 0, 0, 1)
        pieza({(x + dx, y + dy): c for (dx, dy), c in hp.items() if c != 'O'})
    def rama(i, x, fondo, top):
        c = 'S' if fondo == 0 else 'T'
        L_.linea(sx + (x > sx), hub, x, top + 3, c)
        d = -1 if x < sx else 1
        if abs(x - sx) <= 2: d = -1 if i < 3 else 1      # la del centro: detrás a la izquierda, delante a la derecha
        for g, L, a in ((.62, 10, 75), (.3, 8, 55)):      # de abajo arriba: la de abajo, más grande y más abierta
            y = round(top + 3 + (hub - top - 3) * g); xn = round(x + (sx - x) * g)
            hojap(L, d * a, xn + d, y, osc=not fondo)
        brote(x, top + 3)
    for d in (-1, 1): hojap(10, d * 80, sx + (d > 0) + d, hub - 1, osc=True)   # el par de abajo, detrás de todo
    for i, r in enumerate(R):
        if r[1] == 0: rama(i, *r)
    for i, r in enumerate(R):
        if r[1] == 1: rama(i, *r)
    return L_.fin(estricto)
