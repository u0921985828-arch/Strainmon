# hoja de abanico con contorno: foliolos lanceolados (anchos al 40 %, en punta), cada uno con su contorno oscuro, cara de la luz
# (arriba a la izquierda) clara y la otra en sombra, nervio central más oscuro. Se rasteriza por píxel con submuestreo
import math
def hoja(n=7, largo=11.0, ancho=2.2, abre=100, caida=2.5, giro=0, pec=3):
    hojas = []
    g0 = math.radians(giro)
    for k in range(n):
        a = -abre + k * 2 * abre / (n - 1)
        L = largo * (1 - .58 * (abs(a) / abre) ** 1.5); w = ancho * (1 - .35 * abs(a) / abre)
        hojas.append((math.radians(a) + g0, L, w, abs(a)))
    def centro(th, L, s, cae):
        ux, uy = math.sin(th), -math.cos(th)
        return ux * L * s, uy * L * s + cae * s * s
    # z: el del medio encima; los de los lados debajo
    orden = sorted(range(n), key=lambda k: -hojas[k][3])
    lab = {}
    R = int(largo + 4)
    for py in range(-R, R + 1):
        for px in range(-R, R + 1):
            best = None
            for k in orden:
                th, L, w, aa = hojas[k]; cae = caida * (abs(math.sin(th - g0)) + .1) if aa > 10 else 0
                cnt = 0; side = 0
                for sy in (-.25, .25):
                    for sx_ in (-.25, .25):
                        X, Y = px + sx_, py + sy; dmin = 9; sbest = 0; vbest = 0
                        for i in range(41):
                            s = i / 40; cx, cy = centro(th, L, s, cae); d = math.hypot(X - cx, Y - cy)
                            if d < dmin:
                                dmin = d; sbest = s
                                ux, uy = math.sin(th), -math.cos(th); vbest = (X - cx) * (-uy) + (Y - cy) * ux
                        wl = w * math.sin(math.pi * min(1, sbest * 1.05)) ** .65 if sbest > .02 else .3
                        if dmin <= max(.35, wl / 2): cnt += 1; side += vbest
                if cnt >= 2: best = (k, side / cnt)
            if best: lab[(px, py)] = best
    pts = {}
    for (x, y), (k, v) in lab.items():
        th = hojas[k][0]; ux, uy = math.sin(th), -math.cos(th)
        # lado de la luz: la normal que apunta arriba a la izquierda
        nx, ny = -uy, ux; luz = (nx * -1 + ny * -1) > 0
        vv = v if luz else -v                                 # > 0: hacia la luz
        c = 'L' if vv > -.45 else 'M'
        if abs(v) < .2 and math.hypot(x, y) > 2: c = 'M'
        if vv > .9: c = 'H'
        pts[(x, y)] = c
    # puntas claras
    for k, (th, L, w, aa) in enumerate(hojas):
        cae = caida * (abs(math.sin(th - g0)) + .1) if aa > 10 else 0
        cx, cy = centro(th, L, .93, cae); p = (round(cx), round(cy))
        if p in pts: pts[p] = 'H'
    # separar foliolos: si un vecino es de otro foliolo que está encima, este píxel pasa a contorno
    zk = {k: i for i, k in enumerate(orden)}
    for (x, y), (k, v) in list(lab.items()):
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            o = lab.get((x + dx, y + dy))
            if o and o[0] != k and zk[o[0]] > zk[k] and math.hypot(x, y) > 2.2: pts[(x, y)] = 'O'
    for i in range(pec): pts[(0, i)] = 'D'
    out = {}
    for (x, y), c in pts.items():
        out[(x, y)] = c
    for (x, y), c in list(pts.items()):
        if c == 'O': continue
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in pts: out[q] = 'O'
    return out
def ver(pts):
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]; x0, y0 = min(xs), min(ys)
    g = [['.'] * (max(xs) - x0 + 1) for _ in range(max(ys) - y0 + 1)]
    for (x, y), c in pts.items(): g[y - y0][x - x0] = c
    return [''.join(r) for r in g]
