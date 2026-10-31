# cola en racimos: cogollitos apilados (cada uno con su luz arriba a la izquierda y su sombra abajo a la derecha), el borde con
# bultos (cada cogollito, ancho arriba y estrecho abajo: las puntas de los cálices miran arriba y afuera; al revés, la cola
# parecía un racimo de peras), pelos naranjas y puntas de hoja de azúcar asomando entre racimos. P/Q/R = color de la cepa (claro/medio/oscuro)
def cola2(L, w=7, semilla=1, azucar=2, paso=3):
    r = [semilla * 7919 + 13]
    def azar(n):
        r[0] = (r[0] * 1103515245 + 12345) & 0x7fffffff; return (r[0] >> 8) % n
    pts = {}; c = w // 2
    nugs = []; y = 2
    while y < L - 4:
        nugs.append((y, (azar(3) - 1) if y > 2 else 0)); y += paso
    for k, (y0, ox) in reversed(list(enumerate(nugs))):
        prog = min(1, (y0 + 2) / 9)                 # los de arriba, más estrechos
        hws = [w / 2 - .4, w / 2, w / 2 - .5, w / 2 - 1.3]
        for i, hw in enumerate(hws):
            hw = max(.6, hw * (.45 + .55 * prog))
            for x in range(-4, w + 4):
                u = (x - c - ox) / max(hw, .5)
                if abs(x - c - ox) <= hw:
                    s = u * .8 + (i - .8) * .5
                    pts[(x, y0 + i)] = 'P' if s < -.3 else ('R' if s > .6 else 'Q')
        # pelos
        if azar(3) < 2:
            xs = [x for (x, yy) in pts if yy == y0 + 2]
            if len(xs) > 3:
                xp = min(xs) + 1 + azar(max(1, len(xs) - 3)); pts[(xp, y0 + 2)] = 'N'; pts[(xp + 1, y0 + 2)] = 'n'
    # punta
    pts[(c, 0)] = 'P'; pts[(c, 1)] = 'P'; pts[(c + 1, 1)] = 'Q'
    # hojas de azúcar entre racimos, alternando lados
    for k, (y0, ox) in enumerate(nugs[1:]):
        xs = [x for (x, yy) in pts if yy == y0]
        if not xs: continue
        d = -1 if (k + semilla) % 2 == 0 else 1
        x = (min(xs) if d < 0 else max(xs)) + d
        if azucar < 3:
            pts[(x, y0)] = 'L'; pts[(x + d, y0 - 1)] = 'H'
        else:   # hoja de azúcar larga hacia fuera y arriba, y una corta al otro lado
            pts[(x, y0)] = 'L'; pts[(x + d, y0 - 1)] = 'L'; pts[(x + 2 * d, y0 - 2)] = 'H'
            x2 = (max(xs) if d < 0 else min(xs)) - d
            if k % 2 == 0: pts[(x2, y0 + 1)] = 'L'; pts[(x2 - d, y0)] = 'H'
    yb = max(yy for _, yy in pts)
    for x in range(c - 2, c + 3): pts[(x, yb + 1)] = 'D' if abs(x - c) == 2 else 'R'
    pts[(c - 1, yb + 2)] = 'D'; pts[(c, yb + 2)] = 'M'; pts[(c + 1, yb + 2)] = 'D'
    x0 = min(x for x, _ in pts); y0 = min(y for _, y in pts)
    return {(x - x0, y - y0): v for (x, y), v in pts.items()}
def filas(pts):
    W = max(x for x, _ in pts) + 1; H = max(y for _, y in pts) + 1
    g = [['.'] * W for _ in range(H)]
    for (x, y), v in pts.items(): g[y][x] = v
    return [''.join(r) for r in g]
def contorno(f):
    W = len(f[0]) + 2; g = [['.'] * W] + [['.'] + list(r) + ['.'] for r in f] + [['.'] * W]
    b = [(x, y) for y in range(len(g)) for x in range(W) if g[y][x] == '.' and any(0 <= x + dx < W and 0 <= y + dy < len(g) and g[y + dy][x + dx] not in '.O' for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]
    for x, y in b: g[y][x] = 'O'
    return [''.join(r) for r in g]
if __name__ == '__main__':
    print('\n'.join(contorno(filas(cola2(20, 7, 1)))))
