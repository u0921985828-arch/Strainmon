# germinando y plántula dibujadas a mano con sellos ASCII (piezas.txt). La planta de vegetativo, floración y lista es la planta A
# (planta_a.py); los demás sellos de piezas.txt son de la híbrida de la 1.10 P3, sustituida
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
