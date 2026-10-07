# python3 -I tools/sprites/a-mano/mundo.py [sprite ...]   (Python 3 + Pillow; no va en los scripts de npm)
# Arte a mano del mundo (1.10), sin PixelLab, a 16 px/m de alto como los personajes y con la paleta de lo aprobado:
#  · árbol alto (5 m, 80 px), para la calle, los parques y el monte;
#  · fachadas por bioma: la comisaría del barrio alto (piedra), la nave del almacén de los astilleros, el caserío de los
#    pueblos (Mendialde y Errotabarri), las casas marineras de Puerto Viejo, el bloque de ladrillo y la fábrica de Valdehierro;
#  · la marquesina del autobús.
# Sale a art/crudo/<grupo>/<sprite>/unica/NN.png; después, node tools/sprites/procesar.js <grupos> --atlas.
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, azar, rgb

OUT = []


def sale(lz, grupo, sprite, n=0):
    OUT.append(lz.guarda('art', 'crudo', grupo, sprite, 'unica', '%02d.png' % n))


# ---------------------------------------------------------------------------------------------------------------- árbol
# hoja: la rampa del árbol aprobado (prop-arbol) de oscuro a claro, y su contorno
HOJA = ['#1e3a2a', '#0f6b2b', '#3c8a2a', '#5f971e', '#6fb04a', '#9bd35a']
TRONCO = ['#3a2414', '#4a2c1c', '#6a421c', '#7e5630']


def copa(lz, grumos, sem, luz=(-0.62, -0.78)):
    """grumos: [(cx, cy, r)], de atrás adelante. Cada grumo, sombreado con la luz de arriba a la izquierda, con el borde de
    abajo a la derecha más oscuro para que se separe del de detrás; luego textura de hojitas"""
    R = azar(sem)
    for k, (cx, cy, r) in enumerate(grumos):
        for y in range(int(cy - r - 1), int(cy + r + 2)):
            for x in range(int(cx - r - 1), int(cx + r + 2)):
                dx, dy = x + .5 - cx, y + .5 - cy
                d = math.hypot(dx, dy)
                if d > r:
                    continue
                n = (dx * luz[0] + dy * luz[1]) / r          # -1 sombra … 1 luz
                borde = d > r - 1.6 and (dx > -r * .3 or dy > -r * .3)
                v = 2.6 + n * 2.0 + (R() - .5) * .9
                if borde:
                    v = min(v, 1.4)
                v -= max(0, (cy + dy) - 60) * 0.03            # la copa, más oscura abajo
                i = max(1, min(5, int(round(v))))
                lz.p(x, y, HOJA[i])
    # hojitas: pares de píxeles claros arriba a la izquierda de cada grumo y oscuros abajo
    for (cx, cy, r) in grumos:
        for _ in range(int(r * r * .22)):
            a = R() * math.tau
            d = r * math.sqrt(R()) * .85
            x, y = int(cx + math.cos(a) * d), int(cy + math.sin(a) * d)
            c = lz.g(x, y)
            if not c[3]:
                continue
            idx = [rgb(h) for h in HOJA].index(c) if c in [rgb(h) for h in HOJA] else 3
            if math.cos(a) * luz[0] + math.sin(a) * luz[1] > .1 and idx >= 3:
                lz.p(x, y, HOJA[min(5, idx + 1)]); lz.p(x + 1, y, HOJA[min(5, idx + 1)])
            elif idx <= 3:
                lz.p(x, y, HOJA[max(1, idx - 1)]); lz.p(x, y + 1, HOJA[max(1, idx - 1)])


def tronco(lz, x0, y0, y1, w0, w1):
    """tronco de la base (y1, ancho w1) a la cruz (y0, ancho w0), centrado en x0, con la luz a la izquierda"""
    for y in range(y0, y1 + 1):
        t = (y - y0) / max(1, y1 - y0)
        w = round(w0 + (w1 - w0) * t * t)
        xa = x0 - w // 2
        for i in range(w):
            c = TRONCO[2]
            if i == 0:
                c = TRONCO[3]
            elif i >= w - 2:
                c = TRONCO[1]
            lz.p(xa + i, y, c)
        lz.p(xa - 1, y, TRONCO[0]); lz.p(xa + w, y, TRONCO[0])
    # vetas
    R = azar(7)
    for _ in range(10):
        y = y0 + int(R() * (y1 - y0 - 3)) + 1
        x = x0 - 1 + int(R() * 2)
        lz.p(x, y, TRONCO[1]); lz.p(x, y + 1, TRONCO[1])


def arbol():
    lz = Lienzo(64, 96)
    tronco(lz, 32, 52, 95, 4, 8)
    # raíces: dos lóbulos al pie
    for x, y in ((26, 94), (27, 93), (37, 94), (36, 93), (26, 95), (37, 95)):
        lz.p(x, y, TRONCO[1])
    lz.p(25, 95, TRONCO[0]); lz.p(38, 95, TRONCO[0])
    # ramas que se ven entre los grumos de abajo
    for (xa, ya, xb, yb) in ((32, 60, 22, 50), (32, 58, 43, 49), (31, 54, 28, 42), (33, 55, 37, 43)):
        n = max(abs(xb - xa), abs(yb - ya))
        for k in range(n + 1):
            x = round(xa + (xb - xa) * k / n); y = round(ya + (yb - ya) * k / n)
            lz.p(x, y, TRONCO[1]); lz.p(x + 1, y, TRONCO[2])
    grumos = [(32, 16, 12), (21, 24, 11), (43, 24, 11), (32, 28, 14), (16, 38, 10), (48, 38, 10), (25, 42, 12),
              (40, 42, 12), (32, 48, 10), (20, 52, 8), (45, 52, 8)]
    copa(lz, grumos, 11)
    # huecos entre grumos de abajo: se ve la rama
    for (x, y) in ((27, 57), (28, 57), (37, 57), (38, 56), (32, 58), (33, 58)):
        if lz.g(x, y)[3]:
            lz.p(x, y, HOJA[0])
    lz.contorno(HOJA[0])
    # el contorno no tapa el tronco por debajo de la copa
    return lz


def monte(sem, grumos):
    """el borde de los mapas: árboles de copa baja y espesa (3 m), pensados para ir pegados de 16 en 16 px y formar una
    linde continua; casi no se les ve el tronco"""
    lz = Lienzo(48, 48)
    tronco(lz, 24, 36, 47, 4, 6)
    copa(lz, grumos, sem)
    lz.contorno(HOJA[0])
    return lz


MONTES = {
    'monte': (21, [(24, 12, 9), (14, 19, 8), (34, 19, 8), (24, 22, 11), (12, 30, 8), (36, 30, 8), (24, 33, 10)]),
    'monte2': (37, [(21, 14, 9), (32, 15, 8), (13, 23, 8), (29, 24, 11), (17, 32, 9), (37, 31, 8), (26, 35, 8)]),
}


def seto():
    """seto de 1 m (16 px) para el borde de abajo: liso por los lados (se repite de 16 en 16) y con bultos arriba"""
    lz = Lienzo(16, 16)
    R = azar(5)
    tope = [3, 2, 2, 2, 3, 3, 2, 1, 1, 2, 2, 3, 3, 2, 2, 3]
    for x in range(16):
        for y in range(tope[x], 16):
            v = 4.2 - (y - tope[x]) * .28 + (R() - .5) * 1.1
            lz.p(x, y, HOJA[max(1, min(5, int(round(v))))])
        lz.p(x, tope[x] - 1, HOJA[0])
    for x in range(16):
        lz.p(x, 15, HOJA[1])
    for _ in range(14):
        x, y = int(R() * 15), 4 + int(R() * 9)
        lz.p(x, y, HOJA[5] if R() < .5 else HOJA[2])
    return lz


def guarda_edificio(grupo, base, puerta=None):
    sale(base, grupo, 'base')
    for i, p in enumerate(puerta or []):
        sale(p, grupo, 'puerta', i)


SPRITES = {'arbol': lambda: sale(arbol(), 'prop-arbol-alto', 'tree'),
           'monte': lambda: [sale(monte(*MONTES[k]), 'prop-monte', k) for k in MONTES],
           'seto': lambda: sale(seto(), 'prop-seto', 'seto')}

# ------------------------------------------------------------------------------------------------------------ fachadas
# De frente, como las aprobadas (edificio-home, -gray, -shop, -bar): 2 filas de tejado arriba (32 px), con su alero en sombra,
# y la pared debajo; ventanas con marco, cristal con brillo arriba a la izquierda y sombra abajo a la derecha. Opacas (debajo
# están las losetas del tejado y de la pared). Cada una con 15 colores como mucho; la puerta, recortes de 32 × 32 de la base
# (el 0 cerrada, igual que la base; 1-3 abriéndose) en la casilla de la puerta, como en building().
OSCURO = '#26262e'      # el interior al abrir la puerta (el de calco.js y la puerta del piso)


def tejas(lz, x0, y0, w, h, c, alto=4, paso=8, sem=3):
    """tejas en hileras: c = (base, luz, sombra); la junta de cada hilera en sombra y las llagas al tresbolillo"""
    base, luz, som = c
    R = azar(sem)
    lz.r(x0, y0, w, h, base)
    for y in range(y0, y0 + h):
        f = (y - y0) % alto
        if f == alto - 1:
            lz.hl(x0, x0 + w - 1, y, som)
        elif f == 0:
            for x in range(x0, x0 + w):
                if R() < .45:
                    lz.p(x, y, luz)
        k = (y - y0) // alto
        for x in range(x0 + (k % 2) * (paso // 2), x0 + w, paso):
            if f < alto - 1:
                lz.p(x, y, som)


def sillar(lz, x0, y0, w, h, c, bw=12, bh=6, sem=5):
    """sillería: c = (piedra, junta, luz); bloques al tresbolillo con el canto de arriba a la izquierda en luz"""
    pie, jun, luz = c
    R = azar(sem)
    lz.r(x0, y0, w, h, pie)
    for y in range(y0, y0 + h):
        f = (y - y0) % bh
        k = (y - y0) // bh
        if f == bh - 1:
            lz.hl(x0, x0 + w - 1, y, jun)
            continue
        for x in range(x0 - (k % 2) * (bw // 2), x0 + w, bw):
            lz.p(x, y, jun)
            if f == 0:
                lz.hl(max(x0, x + 1), min(x0 + w - 1, x + 3), y, luz)
    for _ in range(w * h // 60):
        lz.p(x0 + int(R() * w), y0 + int(R() * h), jun if R() < .5 else luz)


def ladrillos(lz, x0, y0, w, h, c, sem=9):
    """ladrillo de 8 × 3 con su llaga: c = (ladrillo, mortero, luz, sombra)"""
    lad, mor, luz, som = c
    R = azar(sem)
    lz.r(x0, y0, w, h, lad)
    for y in range(y0, y0 + h):
        f = (y - y0) % 4
        k = (y - y0) // 4
        if f == 3:
            lz.hl(x0, x0 + w - 1, y, mor)
            continue
        for x in range(x0 - (k % 2) * 4, x0 + w, 8):
            lz.p(x, y, mor)
            if f == 2:
                lz.hl(max(x0, x + 1), min(x0 + w - 1, x + 7), y, som)
        for x in range(x0, x0 + w):
            if f == 0 and R() < .12:
                lz.p(x, y, luz)


def chapa(lz, x0, y0, w, h, c, paso=4):
    """chapa grecada en vertical: c = (luz, media, sombra)"""
    luz, med, som = c
    for x in range(x0, x0 + w):
        k = (x - x0) % paso
        lz.vl(x, y0, y0 + h - 1, luz if k == 0 else som if k == paso - 1 else med)


def ventana(lz, x, y, w, h, marco, cristal, brillo, sombra, cruz=True, alfeizar=None):
    """ventana con marco de 1 px, cruz, brillo arriba a la izquierda y sombra de 1 px abajo y a la derecha (en la pared)"""
    lz.r(x + 1, y + 1, w, h, sombra)
    lz.caja(x, y, w, h, cristal, marco)
    if cruz:
        lz.vl(x + w // 2, y + 1, y + h - 2, marco)
        lz.hl(x + 1, x + w - 2, y + h // 2 - 1, marco)
    lz.p(x + 2, y + 2, brillo); lz.p(x + 3, y + 2, brillo); lz.p(x + 2, y + 3, brillo)
    if alfeizar:
        lz.hl(x - 1, x + w, y + h, alfeizar)


def puertas(base, cx, cy, hueco, modo):
    """4 fotogramas de 32 × 32 recortados de la base en (cx, cy): el 0 cerrada; en el 1-3 se ve el interior (OSCURO) dentro de
    hueco = (x, y, w, h), relativo al recorte. modo: 'doble' (se abren las dos hojas desde el centro), 'corredera' (la hoja se
    corre a la derecha) o 'simple' (se abre hacia dentro desde la derecha: queda la hoja cada vez más estrecha a la izquierda)"""
    hx, hy, hw, hh = hueco
    out = []
    for i in range(4):
        p = base.recorta(cx, cy, 32, 32)
        if i:
            if modo == 'doble':
                a = round(hw * i / 7)
                c0 = hx + hw // 2 - a
                for yy in range(hy, hy + hh):
                    p.hl(c0, c0 + 2 * a - 1, yy, OSCURO)
            elif modo == 'corredera':
                d = round(hw * i / 4.5)
                hoja = base.recorta(cx + hx, cy + hy, hw, hh)
                p.r(hx, hy, hw, hh, OSCURO)
                p.pega(hoja.recorta(0, 0, hw - d, hh), hx + d, hy)
            else:
                a = round((hw - 2) * i / 4)
                for yy in range(hy, hy + hh):
                    p.hl(hx + hw - a, hx + hw - 1, yy, OSCURO)
        out.append(p)
    return out


def comisaria():
    """comisaría del barrio alto (6 × 6): sillería clara, cornisa, tejado de pizarra, rejas abajo, placa azul y doble puerta
    de madera bajo un arco de piedra; puerta ancha en las casillas 2-3 (recorte en x 32, y 64)"""
    lz = Lienzo(96, 96)
    PIZ = ('#4e5664', '#6c7686', '#363c48')
    PIE = ('#cfc8b8', '#8a8274', '#e8e2d4')
    CR, BR, MAR, NEG = '#6f9fc4', '#b8dcf0', '#3a3640', '#26262e'
    tejas(lz, 0, 0, 96, 26, PIZ, alto=4, paso=6, sem=13)
    lz.hl(0, 95, 0, PIZ[1])
    lz.r(0, 26, 96, 2, PIZ[2])                      # alero en sombra
    lz.r(0, 28, 96, 3, PIE[2]); lz.hl(0, 95, 31, PIE[1])   # cornisa
    sillar(lz, 0, 32, 96, 60, PIE, sem=17)
    lz.r(0, 32, 96, 2, PIE[1])                      # sombra de la cornisa
    lz.r(0, 90, 96, 6, '#b0a898'); lz.hl(0, 95, 90, PIE[2]); lz.hl(0, 95, 95, PIE[1])   # zócalo
    for x in (10, 74):                              # planta de arriba
        lz.r(x - 2, 37, 16, 2, PIE[2])              # dintel
        ventana(lz, x, 39, 12, 15, MAR, CR, BR, PIE[1], alfeizar=PIE[2])
    lz.caja(36, 38, 24, 13, '#2c4c94', MAR)         # placa azul con un escudo propio (una estrella sobre dos franjas)
    lz.hl(38, 57, 47, '#f4f4ee'); lz.hl(38, 57, 49, '#f4f4ee')
    for (x, y) in ((47, 40), (48, 40), (46, 41), (47, 41), (48, 41), (49, 41), (45, 42), (46, 42), (47, 42), (48, 42), (49, 42), (50, 42),
                   (46, 43), (47, 43), (48, 43), (49, 43), (46, 44), (49, 44)):
        lz.p(x, y, '#e0b040')
    for x in (8, 72):                               # planta baja: ventanas con reja
        ventana(lz, x, 62, 16, 18, MAR, CR, BR, PIE[1], cruz=False, alfeizar=PIE[2])
        for xx in range(x + 3, x + 15, 3):
            lz.vl(xx, 63, 78, MAR)
        lz.hl(x + 1, x + 14, 66, MAR); lz.hl(x + 1, x + 14, 75, MAR)
    # arco de piedra y doble puerta (hueco 24 × 25 en x 36, y 71)
    for y in range(64, 96):
        for x in range(33, 63):
            dx = x + .5 - 48
            if y < 72 and dx * dx + (y - 72) ** 2 * 1.8 > 15 * 15:
                continue
            lz.p(x, y, PIE[2] if (x + y) % 7 else PIE[1])
    for y in range(67, 96):
        for x in range(36, 60):
            dx = x + .5 - 48
            if y < 72 and dx * dx + (y - 72) ** 2 * 1.8 > 12 * 12:
                continue
            lz.p(x, y, '#5a3a24')
    for y in range(67, 96):                          # tablas y junta entre las hojas
        for x in (39, 43, 52, 56):
            if lz.g(x, y)[:3] == (0x5a, 0x3a, 0x24):
                lz.p(x, y, '#7a5234')
    lz.vl(47, 66, 95, MAR); lz.vl(48, 66, 95, '#7a5234')
    lz.p(45, 82, '#e0b040'); lz.p(50, 82, '#e0b040')
    lz.r(32, 93, 32, 3, '#b0a898'); lz.hl(32, 63, 93, PIE[2])   # escalón
    lz.r(46, 58, 4, 5, '#2c4c94'); lz.r(47, 59, 2, 3, BR); lz.hl(45, 50, 63, MAR)   # farol azul sobre la puerta
    return lz, puertas(lz, 32, 64, (4, 3, 24, 28), 'doble')


def nave():
    """almacén de los astilleros (6 × 6): nave de chapa grecada con óxido, tejado de chapa verde, ventanal corrido arriba,
    rótulo con el número y puerta corredera ancha en las casillas 2-3 (recorte en x 32, y 64)"""
    lz = Lienzo(96, 96)
    TEJ = ('#7c9a9a', '#5f7e80', '#445e60')
    PAR = ('#a9b4bc', '#8c98a2', '#6a7580')
    OX, OXL, MAR = '#9a5a34', '#c07a44', '#2e3238'
    R = azar(23)
    chapa(lz, 0, 0, 96, 27, TEJ, paso=5)
    for y in range(0, 27, 9):
        lz.hl(0, 95, y, TEJ[2])                      # solapes de las chapas
    lz.r(0, 27, 96, 2, MAR); lz.hl(0, 95, 29, '#6a7580')   # canalón
    chapa(lz, 0, 30, 96, 66, PAR, paso=4)
    lz.r(0, 30, 96, 2, PAR[2])
    for _ in range(70):                              # chorreones de óxido desde los remaches y abajo
        x = int(R() * 96); y0 = 30 + int(R() * 50); n = 2 + int(R() * 7)
        for y in range(y0, min(96, y0 + n)):
            lz.p(x, y, OX if R() < .7 else OXL)
    for x in range(0, 96):
        if R() < .5:
            lz.p(x, 94, OX); lz.p(x, 95, OX)
        lz.p(x, 93, OX if R() < .3 else lz.g(x, 93))
    lz.r(4, 36, 88, 8, MAR)                          # ventanal corrido
    for x in range(5, 91, 6):
        lz.r(x, 37, 5, 6, '#9fb8c4'); lz.p(x, 37, '#e8e8e0')
    lz.hl(4, 91, 44, PAR[2])
    lz.caja(30, 48, 36, 11, '#e8e8e0', MAR)          # rótulo: «3» y una franja
    for (x, y) in ((45, 50), (46, 50), (47, 50), (48, 50), (48, 51), (47, 52), (48, 53), (48, 54), (45, 55), (46, 55), (47, 55), (48, 55), (48, 54)):
        lz.p(x, y, MAR)
    lz.r(51, 50, 12, 2, OX); lz.r(51, 53, 9, 2, OX); lz.r(33, 50, 9, 6, OX)
    # puerta corredera (hueco 26 × 28 en x 35, y 68), con su guía arriba
    lz.r(33, 64, 34, 3, MAR)
    lz.r(35, 68, 26, 28, '#c8a050')
    for y in range(70, 96, 4):
        lz.hl(35, 60, y, '#8e6e34')
    lz.vl(35, 68, 95, '#8e6e34'); lz.vl(60, 68, 95, '#8e6e34')
    lz.r(38, 80, 2, 4, MAR)                          # tirador
    for _ in range(14):
        lz.p(35 + int(R() * 26), 68 + int(R() * 28), OX)
    lz.r(68, 60, 4, 3, MAR); lz.r(69, 63, 2, 2, '#f0d070')   # aplique con rejilla
    return lz, puertas(lz, 32, 64, (3, 4, 26, 28), 'corredera')


SPRITES['comisaria'] = lambda: guarda_edificio('edificio-comisaria', *comisaria())
SPRITES['nave'] = lambda: guarda_edificio('edificio-nave', *nave())


TEJA = ('#b04a32', '#d06a44', '#7a2e22')        # teja roja (la del caserío, las marineras y el piso)


def teja_arabe(lz, x0, y0, w, h, c=TEJA, sem=31):
    """teja árabe: canales en vertical (lomo en luz, canal en sombra) con el solape de cada hilera cada 7 px"""
    base, luz, som = c
    R = azar(sem)
    for y in range(y0, y0 + h):
        f = (y - y0) % 7
        for x in range(x0, x0 + w):
            k = (x - x0 + ((y - y0) // 7) % 2 * 3) % 6
            col = luz if k in (0, 1) else som if k == 5 else base
            if f == 6:
                col = som if k != 0 else base
            elif f == 0 and k in (1, 2) and R() < .5:
                col = luz
            lz.p(x, y, col)


def letras(lz, x, y, txt, c):
    """rótulo con una letra propia de 3 × 5"""
    F = {'F': '111100110100100', 'U': '101101101101111', 'N': '10011101101110011001', 'D': '110101101101110', 'I': '111010010010111',
         'C': '111100100100111', 'O': '111101101101111', 'A': '111101111101101', 'L': '100100100100111'}
    for ch in txt:
        if ch == 'Ó':                                 # la tilde, encima de la O
            lz.p(x + 1, y - 1, c)
            ch = 'O'
        m = F[ch]
        an = len(m) // 5                              # 3 de ancho; la N, 4
        for j in range(5):
            for i in range(an):
                if m[j * an + i] == '1':
                    lz.p(x + i, y + j, c)
        x += an + 1


def caserio(variante=0):
    """caserío de los pueblos (8 × 6): teja árabe, canecillos, planta de arriba de entramado con balconada de madera y
    geranios, abajo encalado con esquinas de sillar y portalón de piedra en arco (puerta ancha en las casillas 3-4: recorte
    en x 48, y 64). variante 1: contraventanas rojas y cal crema"""
    lz = Lienzo(128, 96)
    MAD = ('#4a2c1c', '#6a421c', '#7e5630')
    CAL, CALS = '#f2eee2', '#d8d0bc'
    PIE = ('#b8ad98', '#8a7f6c', CAL)
    VER, CR, FL = '#3c7a3c', '#34404c', '#e04848'
    teja_arabe(lz, 0, 0, 128, 26)
    lz.r(0, 26, 128, 4, MAD[0])                      # alero con canecillos
    for x in range(2, 128, 8):
        lz.r(x, 27, 3, 2, MAD[2])
    lz.r(0, 30, 128, 66, CAL)
    R = azar(41)
    for _ in range(60):
        lz.p(int(R() * 128), 31 + int(R() * 62), CALS)
    lz.hl(0, 127, 30, CALS)
    # entramado de la planta de arriba (y 31-58)
    lz.r(0, 31, 128, 2, MAD[1]); lz.r(0, 57, 128, 2, MAD[1])
    for x in (0, 22, 44, 82, 104, 125):
        lz.r(x, 31, 3, 27, MAD[1]); lz.vl(x, 31, 57, MAD[2])
    for (xa, xb) in ((3, 21), (107, 124)):           # tornapuntas en los paños de las esquinas
        for k in range(26):
            x = xa + round((xb - xa) * k / 25) if xa < 60 else xb - round((xb - xa) * k / 25)
            lz.p(x, 57 - k, MAD[1]); lz.p(x + 1, 57 - k, MAD[1])
    for x in (54, 70):                               # dos ventanas con contraventanas sobre la balconada
        ventana(lz, x, 36, 10, 14, MAD[0], CR, '#6f9fc4', CALS)
        lz.r(x - 5, 36, 4, 14, VER); lz.r(x + 11, 36, 4, 14, VER)
        lz.vl(x - 4, 37, 48, MAD[0]); lz.vl(x + 13, 37, 48, MAD[0])
    for x in (28, 96):
        ventana(lz, x, 38, 10, 11, MAD[0], CR, '#6f9fc4', CALS)
    # balconada de madera (x 46-81) con geranios
    lz.r(46, 50, 36, 2, MAD[2]); lz.r(46, 56, 36, 3, MAD[0])
    for x in range(47, 81, 3):
        lz.vl(x, 52, 55, MAD[1])
    for x in range(48, 80, 5):
        lz.p(x, 49, FL); lz.p(x + 1, 48, FL); lz.p(x + 2, 49, FL); lz.p(x + 1, 49, VER)
    # planta baja: esquinas de sillar, ventanas con contraventana y macetas, portalón en arco
    for y in range(59, 92, 6):
        k = (y - 59) // 6 % 2
        lz.caja(0, y, 8 + 4 * k, 6, PIE[0], PIE[1]); lz.caja(120 - 4 * k, y, 8 + 4 * k, 6, PIE[0], PIE[1])
    for x in (20, 98):
        ventana(lz, x, 66, 10, 13, MAD[0], CR, '#6f9fc4', CALS, alfeizar=PIE[1])
        lz.r(x - 5, 66, 4, 13, VER); lz.r(x + 11, 66, 4, 13, VER)
        lz.r(x - 1, 80, 12, 3, MAD[1]); lz.p(x + 1, 79, FL); lz.p(x + 5, 79, FL); lz.p(x + 8, 79, FL)
    for y in range(62, 96):                          # arco de dovelas
        for x in range(47, 81):
            dx = x + .5 - 64
            if y < 76 and dx * dx + (y - 76) ** 2 * 1.1 > 17 * 17:
                continue
            lz.p(x, y, PIE[0] if ((x // 4) + (y // 5)) % 2 else PIE[1])
    for y in range(65, 96):
        for x in range(51, 77):
            dx = x + .5 - 64
            if y < 76 and dx * dx + (y - 76) ** 2 * 1.1 > 13 * 13:
                continue
            lz.p(x, y, MAD[1] if (x - 51) % 5 else MAD[0])
    lz.vl(63, 64, 95, MAD[0])
    lz.r(0, 92, 128, 4, PIE[1]); lz.hl(0, 127, 92, PIE[0])   # zócalo de piedra
    lz.r(47, 92, 34, 4, PIE[0])                       # umbral
    if variante:
        lz.cambia({VER: '#a83a2e', CAL: '#ece0c4', CALS: '#d2c4a4'})
    return lz, puertas(lz, 48, 64, (3, 1, 26, 28), 'doble')


MARINERAS = {'marinera': ('#3f8a5a', '#2f6e46', '#1f4c30'), 'marinera2': ('#3c6eb4', '#2c5490', '#1e3a66'),
             'marinera3': ('#b8403a', '#94302c', '#66201e'), 'marinera4': ('#e0b84a', '#b8923a', '#7c6024')}


def marinera(k):
    """casa marinera de Puerto Viejo (4 × 6): estrecha, pintada de un color (k), recercados blancos, balcón de hierro del
    color y puerta de la planta baja (no se entra)"""
    lz = Lienzo(64, 96)
    C0, C1, C2 = MARINERAS[k]
    BL, BLS, CR, CRL = '#f4f4ee', '#c8ccd0', '#2e3c4c', '#6f9fc4'
    PIE = ('#9c9488', '#6c665e')
    tejas(lz, 0, 0, 64, 24, TEJA, alto=4, paso=6, sem=7 + len(k))
    lz.r(0, 24, 64, 2, TEJA[2]); lz.r(0, 26, 64, 3, BL); lz.hl(0, 63, 28, BLS)   # alero blanco
    lz.r(0, 29, 64, 67, C0)
    R = azar(53)
    for _ in range(40):
        lz.p(int(R() * 64), 30 + int(R() * 60), C1)
    lz.hl(0, 63, 29, C1)
    lz.r(0, 29, 3, 67, PIE[0]); lz.vl(2, 29, 95, PIE[1])   # medianera de piedra
    # arriba: balconera con recercado y balcón
    lz.r(20, 32, 24, 26, BL); lz.vl(44, 33, 58, BLS)
    ventana(lz, 23, 35, 18, 21, C2, CR, CRL, C1, cruz=False)
    lz.vl(32, 36, 54, C2); lz.hl(24, 39, 44, C2)
    lz.r(14, 55, 36, 2, C2); lz.hl(14, 49, 50, C2)
    for x in range(15, 49, 3):
        lz.vl(x, 51, 54, C2)
    lz.r(14, 57, 36, 1, BLS)
    lz.p(16, 49, '#e04848'); lz.p(17, 48, '#e04848'); lz.p(46, 49, '#e04848'); lz.p(47, 48, '#e04848')
    # abajo: ventana, puerta (casillas 1-2, centrada en x 32) y ventana
    for x in (6, 48):
        lz.r(x - 2, 64, 14, 18, BL)
        ventana(lz, x, 66, 10, 13, C2, CR, CRL, C1)
    lz.r(22, 66, 20, 30, BL)
    lz.r(25, 69, 14, 27, C2)
    for y in (72, 81):
        lz.caja(27, y, 10, 7, C1, C2)
    lz.p(36, 84, BL)                                  # pomo
    lz.r(0, 92, 64, 4, PIE[0]); lz.hl(0, 63, 92, PIE[1])
    return lz


def ladrillo():
    """bloque de ladrillo de Valdehierro (7 × 6): azotea vista desde arriba (grava, depósito, antenas y casetón), pretil,
    ladrillo, ventanas de aluminio (una con ropa tendida y otra con el aparato del aire), persiana de una tienda y portal"""
    lz = Lienzo(112, 96)
    LAD = ('#a04a34', '#c8b8a0', '#bc6446', '#7a3426')
    HOR, HORL, MAR = '#9a9690', '#bab6ae', '#2a2624'
    ALU, CR, CRL = '#c8ccd0', '#34404c', '#6f9fc4'
    PER, PERS = '#7c8088', '#5a5e66'
    R = azar(61)
    lz.r(0, 0, 112, 26, HOR)                          # azotea
    for _ in range(320):
        lz.p(int(R() * 112), int(R() * 26), HORL if R() < .5 else PERS)
    lz.caja(70, 3, 24, 16, HOR, MAR); lz.r(71, 4, 22, 3, HORL)   # casetón de la escalera
    lz.caja(10, 6, 14, 12, ALU, MAR); lz.hl(11, 22, 7, HORL)   # depósito
    for x in (36, 48):
        lz.vl(x, 2, 14, MAR); lz.hl(x - 3, x + 3, 5, MAR); lz.hl(x - 2, x + 2, 9, MAR)   # antenas
    lz.r(0, 22, 112, 4, HORL); lz.hl(0, 111, 25, MAR)   # pretil
    lz.r(0, 26, 112, 2, PERS)
    ladrillos(lz, 0, 28, 112, 68, LAD)
    lz.r(0, 28, 112, 2, LAD[3])
    for i, x in enumerate((10, 49, 88)):
        lz.r(x - 2, 34, 18, 2, HORL)                  # dintel
        ventana(lz, x, 36, 14, 16, ALU, CR, CRL, LAD[3], alfeizar=HORL)
        lz.hl(x + 1, x + 12, 40, PERS)                # persiana a medio bajar
        lz.r(x + 1, 37, 12, 3, PER)
    lz.hl(47, 64, 56, MAR)                            # cuerda con ropa tendida
    for x, c in ((49, '#e04848'), (54, '#4a92e0'), (59, '#f0d070')):
        lz.r(x, 57, 4, 5, c)
    lz.caja(90, 54, 12, 7, ALU, PERS); lz.hl(92, 99, 57, PERS)   # aparato del aire
    lz.r(4, 62, 40, 4, PERS)                          # cajón de la persiana
    lz.r(5, 66, 38, 30, PER)
    for y in range(67, 96, 2):
        lz.hl(5, 42, y, PERS)
    lz.caja(4, 58, 40, 4, '#4a92e0', MAR)             # rótulo de la tienda
    lz.r(54, 60, 22, 36, ALU)                         # portal de aluminio y cristal
    lz.caja(56, 62, 18, 34, CR, MAR); lz.vl(65, 63, 95, MAR); lz.p(58, 64, CRL); lz.p(59, 64, CRL); lz.p(67, 64, CRL)
    for i, x in enumerate((84, 98)):
        ventana(lz, x, 68, 10, 12, ALU, CR, CRL, LAD[3], alfeizar=HORL)
    lz.r(0, 93, 112, 3, PERS)
    return lz


def fabrica():
    """fábrica vieja de Valdehierro (8 × 6): cubierta en diente de sierra (bandas de vidrio y de chapa) con la chimenea
    de ladrillo dentro de la franja del tejado, rótulo, pilastras, ventanales de hierro y portón de chapa (no se entra)"""
    lz = Lienzo(128, 96)
    LAD = ('#a04a34', '#c8b8a0', '#bc6446', '#7a3426')
    TJ, TJL, TJS, MAR = '#4e5258', '#6a7078', '#363a40', '#2a2624'
    HI, VI, VIS = '#3a4a56', '#8fb0c0', '#5c7c8c'
    POR, PORL, ROT = '#4e6a5a', '#6a8a76', '#e8e4d8'
    for y in range(0, 27):                            # dientes de sierra: vidrio inclinado y chapa
        f = y % 9
        lz.hl(0, 127, y, VI if f < 2 else VIS if f == 2 else TJS if f == 8 else TJ if f < 6 else TJL)
    for x in range(0, 128, 8):
        for y in range(0, 27):
            if y % 9 < 3:
                lz.p(x, y, HI)
    lz.r(98, 0, 14, 30, LAD[0])                        # chimenea: ladrillo con anillo claro y boca oscura
    ladrillos(lz, 98, 2, 14, 28, LAD, sem=71)
    lz.r(97, 0, 16, 2, MAR); lz.r(98, 8, 14, 2, LAD[1]); lz.vl(98, 0, 29, LAD[3]); lz.vl(111, 0, 29, LAD[3])
    lz.r(0, 27, 128, 3, TJS)
    ladrillos(lz, 0, 30, 128, 66, LAD, sem=73)
    for x in (0, 31, 62 + 32, 124):                   # pilastras
        lz.r(x, 30, 4, 66, LAD[2]); lz.vl(x + 3, 30, 95, LAD[3])
    lz.caja(36, 31, 56, 9, ROT, MAR)
    letras(lz, 45, 33, 'FUNDICIÓN', MAR)
    for x in (8, 100):                                # ventanales de hierro con cuarterones
        lz.caja(x, 44, 18, 22, VI, HI)
        for xx in range(x + 6, x + 18, 6):
            lz.vl(xx, 45, 64, HI)
        for yy in range(51, 66, 7):
            lz.hl(x + 1, x + 16, yy, HI)
        lz.r(x + 1, 45, 5, 6, VIS); lz.r(x + 13, 59, 4, 6, VIS)
        lz.hl(x - 1, x + 18, 66, LAD[1])
    lz.r(40, 44, 48, 3, LAD[3])                       # dintel de hierro del portón
    lz.r(44, 47, 40, 49, POR)
    for x in range(44, 84, 5):
        lz.vl(x, 47, 95, PORL)
    lz.vl(63, 47, 95, MAR); lz.vl(64, 47, 95, MAR)
    for y in (52, 70, 88):
        for x in range(46, 82, 6):
            lz.p(x, y, PORL)
    lz.r(0, 93, 128, 3, TJS)
    return lz


def parada():
    """poste de la parada del autobús (3 m): señal azul con un autobús propio, banda amarilla y horarios"""
    lz = Lienzo(16, 48)
    PO, POS, AZ, BL, MAR, AM, HO = '#7c848e', '#4c545e', '#2c5aa0', '#f4f4ee', '#26262e', '#f0d050', '#d8dce0'
    lz.r(7, 14, 2, 33, PO); lz.vl(8, 14, 46, POS)
    lz.r(5, 45, 6, 3, POS)
    lz.caja(1, 0, 14, 14, AZ, MAR)
    lz.r(4, 3, 8, 6, BL); lz.r(5, 4, 3, 2, AZ); lz.r(9, 4, 2, 2, AZ); lz.p(5, 9, MAR); lz.p(10, 9, MAR)   # autobús
    lz.r(2, 11, 12, 2, AM)
    lz.caja(3, 18, 10, 12, HO, MAR)
    for y in (20, 22, 24, 26):
        lz.hl(5, 10, y, POS)
    return lz


SPRITES['caserio'] = lambda: [guarda_edificio('edificio-caserio', *caserio(0)), guarda_edificio('edificio-caserio2', *caserio(1))]
SPRITES['marinera'] = lambda: [guarda_edificio('edificio-' + k, marinera(k)) for k in MARINERAS]
SPRITES['ladrillo'] = lambda: guarda_edificio('edificio-ladrillo', ladrillo())
SPRITES['fabrica'] = lambda: guarda_edificio('edificio-fabrica', fabrica())
SPRITES['parada'] = lambda: sale(parada(), 'prop-parada', 'parada')


if __name__ == '__main__':
    pedidos = sys.argv[1:] or list(SPRITES)
    for k in pedidos:
        SPRITES[k]()
    for f in OUT:
        print(f)
