# la híbrida (Skunk #1) dibujada a mano: sellos ASCII de hojas, cogollos y tallo (piezas.txt) montados por nudos. Abajo hojas de abanico
# grandes, en medio ramas con colas, arriba cogollos pegados y la cola; colas de 3 tamaños sin simetría, pistilos en pelos de 2 px y un borde
# oscuro abajo y a la derecha de los cogollos (la luz viene de arriba). Más alta = más nudos, nunca los mismos más largos
import os
D = os.path.dirname(os.path.abspath(__file__))
def sellos(path):
    S, k = {}, None
    for l in open(path).read().split('\n'):
        if l.startswith('#'): k = l[1:].split()[0]; S[k] = []
        elif l.strip() and k: S[k].append(l)
    return S
S = sellos(os.path.join(D, 'piezas.txt'))
esp = lambda s: [r[::-1] for r in s]
OSC = str.maketrans('HLMDO', 'LMDOO')
osc = lambda s, n=1: s if n <= 0 else osc([r.translate(OSC) for r in s], n - 1)
COG = set('PQRNnF')
def nudos(H, top, cada=9):
    """filas de los nudos, de abajo arriba: uno cada 5-10 filas, más juntos cuanto más arriba, hasta la cola (top)"""
    pasos = [cada, cada - 1, cada + 1, cada - 2, cada]
    ys, y, k = [], H - 2, 0
    while y > top + 3: ys.append(y); y -= max(5, pasos[k % len(pasos)] - (k // 3)); k += 1
    return ys
def planta(H, W=24, flor=True, cada=9, semilla=3):
    g = [['.'] * W for _ in range(H)]
    rnd = semilla
    def azar(n):
        nonlocal rnd; rnd = (rnd * 1103515245 + 12345) & 0x7fffffff; return rnd % n
    def pon(st, x, y):
        for j, r in enumerate(st):
            for i, c in enumerate(r):
                X, Y = x + i, y + j
                if c != '.' and 0 <= X < W and 0 <= Y < H: g[Y][X] = c
    def centrada(st, cx, yb): pon(st, cx - len(st[0]) // 2, yb - len(st) + 1)
    sx = W // 2 - 1
    cola = S['cola']; top = len(cola) - 4 if flor else 3
    ys = nudos(H, top, cada)
    n = len(ys); atras, ramas, colas, hojas = [], [], [], []
    for i, y in enumerate(ys):
        f = i / max(1, n - 1); lado = -1 if i % 2 == 0 else 1
        if not flor:
            G = S['hoja-grande2'] if f < .55 else (S['hoja-media'] if f < .85 else S['hoja-chica'])
            g2 = S['hoja-media'] if f < .55 else S['hoja-chica']
            dx = (-2 if lado < 0 else 3) + (-2 if f >= .55 and lado < 0 else 0) + (2 if f >= .55 and lado > 0 else 0)
            hojas.append((G, sx + dx, y))
            atras.append((osc(g2, 1), sx + (5 if lado < 0 else -4), y - 1))
            continue
        if f < .3:
            G = S['hoja-grande2']
            hojas.append((G, sx + (-2 if lado < 0 else 3), y))
            atras.append((osc(S['hoja-media'], 1), sx + (6 if lado < 0 else -5), y - 2))
        elif f < .75:
            hojas.append((S['hoja-grande2'] if f < .6 else S['hoja-media'], sx + (-3 if lado < 0 else 4), y))
            atras.append((osc(S['hoja-media'], 1), sx + (5 if lado < 0 else -4), y - 1))
            d = -lado; L = 3 if f < .55 else 2
            for t in range(1, L + 1): ramas.append((d, t, y - 1 - t))
            st = S['colita-a'] if azar(3) else S['colita-b']
            colas.append((st if d > 0 else esp(st), sx + (1 if d > 0 else 0) + d * (L + 1), y - L - 1))
            hojas.append((S['hoja-azucar'], sx + (1 if d > 0 else 0) + d * (L + 3), y - L - 3))
        else:
            hojas.append((S['hoja-chica'], sx + (-3 if lado < 0 else 4), y))
            st = S['colita-c'] if f > .9 else (S['colita-b'] if azar(2) else S['colita-a'])
            colas.append((st if lado < 0 else esp(st), sx + (-2 if lado > 0 else 3), y - 2))
    for st, cx, yb in atras: centrada(st, cx, yb)
    for yy in range(top, H): g[yy][sx] = 'S'; g[yy][sx + 1] = 'O'
    for d, t, yy in ramas: g[yy][sx + (1 if d > 0 else 0) + d * t] = 'S'
    for st, cx, yb in hojas: centrada(st, cx, yb)
    for st, cx, yb in colas: centrada(st, cx, yb)
    if flor: pon(cola, sx - len(cola[0]) // 2 + 1, 0)
    else:
        centrada(S['hoja-chica'], sx + 1, top + 4)
        for yy in range(top + 4, top + 7): g[yy][sx] = 'S'; g[yy][sx + 1] = 'O'
    # borde oscuro abajo y a la derecha de los cogollos
    for yy in range(H - 1, -1, -1):
        for xx in range(W - 1, -1, -1):
            if g[yy][xx] == '.' and ((yy and g[yy - 1][xx] in COG) or (xx and g[yy][xx - 1] in COG and g[yy][xx - 1] != 'n')): g[yy][xx] = 'O'
    while all(c == '.' for c in g[0]): g.pop(0)
    return [''.join(r) for r in g]
def germinando(): return [r.replace('SO', 'TS') for r in S['germinando']]
def plantula(H=30, W=18):
    """de abajo arriba, como de verdad: cotiledones redondos, un par de hojas de 1 foliolo, otro de 3, otro de 5-7 y el brote"""
    g = [['.'] * W for _ in range(H)]
    def pon(st, x, y):
        for j, r in enumerate(st):
            for i, c in enumerate(r):
                X, Y = x + i, y + j
                if c != '.' and 0 <= X < W and 0 <= Y < H: g[Y][X] = c
    def centrada(st, cx, yb): pon(st, cx - len(st[0]) // 2, yb - len(st) + 1)
    sx = W // 2 - 1
    for yy in range(3, H): g[yy][sx] = 'T'; g[yy][sx + 1] = 'S'
    COT = ['.HLL.', 'HLLMM', '.MMD.']
    centrada(COT, sx - 2, H - 4); centrada(esp(COT), sx + 3, H - 4)
    UNO = ['H...', '.LL.', '..MD']
    centrada(UNO, sx - 2, H - 10); centrada(esp(UNO), sx + 3, H - 10)
    TRES = ['...H...', '.H.L.H.', '..LML..', '...D...']
    centrada(osc(TRES, 0), sx - 3, H - 16); centrada(TRES, sx + 4, H - 16)
    centrada(S['hoja-chica'], sx - 3, H - 22); centrada(S['hoja-chica'], sx + 4, H - 22)
    centrada(['.H.H.', 'H.L.H', '.LMD.'], sx + 1, 4)
    while all(c == '.' for c in g[0]): g.pop(0)
    return [''.join(r) for r in g]
