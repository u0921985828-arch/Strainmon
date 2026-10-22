# python3 -I tools/sprites/a-mano/bilbao.py [sprite ...]   (Python 3 + Pillow)
# Arte a mano de los mapas de Bilbao (lo pidió el usuario: «los mapas del juego hazlos los más parecidos y realistas a Bilbao centro
# y sus barrios, Zorroza no puede faltar»), con Datos.CAL, a 16 px/m y con el estilo de las fachadas aprobadas (mundo.py): de
# frente, opacas, la cubierta arriba y la planta baja abajo. Todo genérico y propio: ni marcas, ni logotipos, ni rótulos reales.
#  · torreZ / torreZ2: los bloques altos de Zorroza (6 × 9): siete plantas, cerramientos de aluminio, tendederos y bajos con persiana;
#  · ensB / ensB2: la casa del Ensanche (7 × 8): mansarda de pizarra con buhardillas, columnas de miradores blancos y la planta
#    baja de piedra con arcos;
#  · estacion: la estación de tren del barrio (8 × 4), de ladrillo y revoque, con el reloj y la marquesina;
#  · catedral: la fachada gótica con la aguja (6 × 9); teatro: el teatro de la ría (8 × 7); mercado: el mercado de la ribera
#    (8 × 5) con sus vidrieras; grua: la grúa de pórtico del muelle (4 × 7), sobre el hormigón;
#  · tiles-bilbao: la vía (horizontal y vertical), el paso a nivel, el adoquín del Casco Viejo y la losa del muelle;
#  · props-bilbao: la barandilla verde de la ría, el plátano en su alcorque (4 m) y la boca del metro de cristal (2 casillas).
# Sale a art/crudo/<grupo>/<sprite>/unica/NN.png; después, node tools/sprites/procesar.js <grupos> --atlas --atlas-dir godot/arte.
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, azar
import mundo as M

OUT = M.OUT
sale = M.sale
guarda = M.guarda_edificio
ALU, CR, CRL, MAR = '#c8ccd0', '#34404c', '#6f9fc4', '#2a2624'
HOR, HORL = '#9a9690', '#bab6ae'
BL, BLS = '#f4f4ee', '#c8ccd0'
PIZ = ('#4a5260', '#6a7484', '#30363f')            # pizarra de las mansardas
PIEDRA = M.PIEDRA


def azotea(lz, W, sem, alto=26):
    """azotea vista desde arriba: grava, casetón, antenas y el aparato del aire; pretil"""
    R = azar(sem)
    lz.r(0, 0, W, alto, HOR)
    for _ in range(W * alto // 9):
        lz.p(int(R() * W), int(R() * alto), HORL if R() < .5 else '#7a766e')
    lz.caja(W - 30, 3, 22, alto - 10, HOR, MAR); lz.r(W - 29, 4, 20, 3, HORL)
    lz.caja(8, 6, 12, 9, ALU, MAR); lz.hl(10, 17, 9, '#7a766e')
    for x in (30, 40):
        if x < W - 34:
            lz.vl(x, 2, alto - 12, MAR); lz.hl(x - 3, x + 3, 5, MAR); lz.hl(x - 2, x + 2, 9, MAR)
    lz.r(0, alto - 4, W, 4, HORL); lz.hl(0, W - 1, alto - 1, MAR)


TORRES = {'torreZ': ('#a04a34', '#c8b8a0', '#bc6446', '#7a3426', 'ladrillo'),
          'torreZ2': ('#d8c49a', '#c0aa7e', '#e8dab8', '#8c7650', 'revoque')}


def torre(k):
    """bloque alto de Zorroza (6 × 9): azotea, siete plantas de ventanas de aluminio con persiana, cerramientos de terraza,
    ropa tendida y aparatos del aire, y los bajos: una persiana metálica y el portal de aluminio"""
    lz = Lienzo(96, 144)
    C0, C1, C2, C3, tipo = TORRES[k]
    R = azar(700 + len(k))
    azotea(lz, 96, 701 + len(k))
    if tipo == 'ladrillo':
        M.ladrillos(lz, 0, 26, 96, 90, (C0, C1, C2, C3), sem=703)
    else:
        lz.r(0, 26, 96, 90, C0)
        for _ in range(240):
            lz.p(int(R() * 96), 26 + int(R() * 90), C1)
    lz.r(0, 26, 96, 2, C3)
    for p in range(7):
        y = 29 + p * 12
        lz.hl(0, 95, y + 11, HORL if tipo == 'ladrillo' else C3)          # forjado
        for i, x in enumerate((5, 27, 53, 75)):
            if (p + i) % 3 == 1 and i in (1, 2):                            # terraza cerrada de aluminio
                lz.caja(x - 3, y + 1, 22, 10, CRL, ALU)
                for xx in range(x + 2, x + 18, 5):
                    lz.vl(xx, y + 2, y + 9, ALU)
                lz.r(x - 3, y + 7, 22, 3, ALU)
                continue
            M.ventana(lz, x, y + 1, 14, 9, ALU, CR, CRL, C3, cruz=False)
            lz.vl(x + 7, y + 2, y + 9, ALU)
            baja = int(R() * 6)
            lz.r(x + 1, y + 2, 12, baja, '#7c8088')                          # persiana a su altura
            for yy in range(y + 2, y + 2 + baja, 2):
                lz.hl(x + 1, x + 12, yy, '#5a5e66')
            if (p * 5 + i) % 7 == 3:                                         # tendedero con ropa
                lz.hl(x - 1, x + 15, y + 10, MAR)
                for xx, c in ((x, '#e04848'), (x + 5, '#4a92e0'), (x + 10, '#f0d070')):
                    lz.r(xx, y + 11, 3, 3, c) if p < 6 else None
            elif (p * 3 + i) % 5 == 2:                                       # aparato del aire
                lz.caja(x + 2, y + 9, 9, 4, ALU, '#5a5e66')
    lz.r(0, 113, 96, 31, '#3a3a40')                                         # los bajos
    lz.r(0, 113, 96, 3, HORL)
    lz.r(4, 118, 44, 4, '#5a5e66'); lz.r(5, 122, 42, 22, '#7c8088')       # persiana metálica de un local
    for y in range(123, 144, 2):
        lz.hl(5, 46, y, '#5a5e66')
    for x, c in ((9, '#e04848'), (13, '#4a92e0'), (18, '#5ab868')):          # pintadas
        lz.hl(x, x + 3, 130 + (x % 3), c)
    lz.r(58, 117, 26, 27, ALU)                                              # portal de aluminio y cristal
    lz.caja(60, 119, 22, 25, CR, MAR); lz.vl(71, 120, 143, MAR); lz.p(62, 121, CRL); lz.p(63, 121, CRL); lz.p(73, 121, CRL)
    lz.caja(88, 122, 5, 8, '#e0b040', MAR)                                  # buzón / telefonillo
    lz.r(0, 141, 96, 3, '#5a5e66')
    return lz


ENSANCHES = {'ensB': ('#d6c6a4', '#c2b08a', '#8c7a56'), 'ensB2': ('#d4a08c', '#bc8874', '#7a5040')}


def mirador_col(lz, x, y0, n, paso, c):
    """columna de miradores blancos, uno por planta, con su peana"""
    for p in range(n):
        y = y0 + p * paso
        M.mirador(lz, x, y, 22, paso - 5, (BL, BLS, c[2]))


def ensanche(k):
    """casa del Ensanche bilbaíno (7 × 8): mansarda de pizarra con dos buhardillas, cornisa, cuatro plantas con dos columnas de
    miradores blancos y balcones de hierro en medio, y la planta baja de piedra con dos arcos (escaparates) y el portal"""
    W, H = 112, 128
    lz = Lienzo(W, H)
    C0, C1, C2 = ENSANCHES[k]
    R = azar(800 + len(k))
    M.tejas(lz, 0, 0, W, 24, PIZ, alto=3, paso=5, sem=801)                  # mansarda de pizarra
    for x in (24, 74):                                                      # buhardillas
        lz.r(x - 1, 4, 16, 2, PIZ[2]); lz.caja(x, 6, 14, 14, BL, PIZ[2])
        M.ventana(lz, x + 3, 9, 8, 9, BLS, CR, CRL, PIZ[2], cruz=True)
    lz.r(0, 24, W, 4, BL); lz.hl(0, W - 1, 27, C2); lz.hl(0, W - 1, 24, BLS)   # cornisa
    for x in range(2, W, 4):
        lz.p(x, 28, BLS)
    lz.r(0, 29, W, 67, C0)
    for _ in range(220):
        lz.p(int(R() * W), 29 + int(R() * 67), C1)
    for y in (45, 61, 77):
        lz.hl(0, W - 1, y, C1)                                              # impostas
    mirador_col(lz, 6, 31, 4, 16, (BL, BLS, C2))
    mirador_col(lz, W - 28, 31, 4, 16, (BL, BLS, C2))
    for p in range(4):                                                      # balcones del centro
        y = 31 + p * 16
        for x in (40, 58):
            lz.r(x - 2, y, 16, 13, PIEDRA[2])
            M.ventana(lz, x, y + 1, 12, 11, C2, CR, CRL, C1, cruz=False)
            lz.vl(x + 6, y + 2, y + 11, C2)
        lz.r(36, y + 12, 38, 2, MAR); lz.hl(36, 73, y + 8, '#26262e')
        for x in range(36, 74, 3):
            lz.vl(x, y + 9, y + 11, '#26262e')
        if p % 2:
            lz.p(39, y + 7, '#e04848'); lz.p(40, y + 7, '#5ab868'); lz.p(70, y + 7, '#e04848')
    M.sillar(lz, 0, 96, W, 32, PIEDRA, bw=10, bh=5, sem=803)               # planta baja de piedra
    lz.hl(0, W - 1, 96, PIEDRA[1])
    for ax in (6, 82):                                                      # arcos con escaparate
        for y in range(100, H - 2):
            for x in range(ax, ax + 24):
                dx = x + .5 - (ax + 12)
                if y < 112 and dx * dx + (y - 112) ** 2 > 12 * 12:
                    continue
                lz.p(x, y, PIEDRA[2] if abs(dx) > 10 or y < 102 else CR)
        lz.r(ax + 4, 116, 16, 1, C2); lz.p(ax + 6, 110, CRL); lz.p(ax + 7, 110, CRL)
        lz.r(ax + 5, 120, 14, 2, '#e0b84a' if ax < 50 else '#c04848')
    lz.r(44, 100, 24, 28, PIEDRA[2])                                        # portal de madera
    lz.r(47, 103, 18, 25, M.MADERA[0]); lz.vl(56, 104, 127, M.MADERA[1])
    lz.hl(47, 64, 103, M.MADERA[1]); lz.p(54, 116, '#e0b040'); lz.p(58, 116, '#e0b040')
    lz.r(0, H - 3, W, 3, PIEDRA[1])
    return lz


def estacion():
    """la estación del barrio (8 × 4): tejado de pizarra a cuatro aguas con el reloj, muros de ladrillo con recercados claros,
    ventanas en arco, la puerta y la marquesina de hierro a lo largo"""
    W, H = 128, 64
    lz = Lienzo(W, H)
    LAD = ('#a04a34', '#c8b8a0', '#bc6446', '#7a3426')
    M.tejas(lz, 0, 0, W, 20, PIZ, alto=3, paso=5, sem=901)
    lz.caja(56, 2, 16, 16, BL, MAR)                                         # reloj
    lz.r(58, 4, 12, 12, BL); lz.vl(64, 6, 10, MAR); lz.hl(64, 67, 10, MAR); lz.p(64, 4, MAR); lz.p(64, 15, MAR)
    lz.r(0, 20, W, 3, BL); lz.hl(0, W - 1, 22, BLS)
    M.ladrillos(lz, 0, 23, W, 41, LAD, sem=903)
    for x in (0, 40, 84, 124):
        lz.r(x, 23, 4, 41, '#e8dcc0')
    for x in (10, 26, 92, 108):                                            # ventanas en arco
        lz.r(x - 2, 30, 14, 2, '#e8dcc0')
        M.ventana(lz, x, 32, 10, 14, BLS, CR, CRL, LAD[3], cruz=True)
        lz.hl(x, x + 9, 31, '#e8dcc0')
    lz.r(50, 32, 28, 32, '#e8dcc0')                                         # la puerta
    lz.caja(53, 35, 22, 29, CR, '#3a5a4a'); lz.vl(64, 36, 63, '#3a5a4a'); lz.p(55, 37, CRL); lz.p(56, 37, CRL)
    for x in range(0, W, 2):                                                # marquesina de hierro con su sombra
        lz.p(x, 24, '#3a5a4a')
    lz.r(0, 25, W, 2, '#4e7a64')
    for x in range(2, W, 16):
        lz.vl(x, 27, 31, '#3a5a4a')
    lz.r(0, 61, W, 3, '#5a5e66')
    return lz


def catedral():
    """fachada gótica (6 × 9): la aguja calada en el centro, pináculos, el rosetón, la portada apuntada con arquivoltas y los
    contrafuertes; piedra arenisca"""
    W, H = 96, 144
    lz = Lienzo(W, H)
    P0, P1, P2, P3 = '#c8b894', '#a89870', '#e4d8b8', '#6e6248'
    R = azar(951)
    lz.r(0, 0, W, H, HOR)                                                   # detrás de la aguja: la cubierta, desde arriba
    M.tejas(lz, 0, 0, W, 40, PIZ, alto=3, paso=5, sem=953)
    for y in range(0, 60):                                                  # la aguja
        hw = max(1, (y * 11) // 60)
        lz.hl(48 - hw, 47 + hw, y, P0)
        lz.p(48 - hw, y, P3); lz.p(47 + hw, y, P1)
        if y % 6 == 3 and hw > 3:
            lz.hl(48 - hw + 2, 47 + hw - 2, y, P3)
    lz.r(47, 0, 2, 3, '#e0b040')
    sillar_c = (P0, P1, P2)
    M.sillar(lz, 0, 56, W, 88, sillar_c, bw=12, bh=6, sem=955)
    for x in (0, 22, 68, 90):                                               # contrafuertes con pináculo
        lz.r(x, 48, 6, 96, P2); lz.vl(x + 5, 48, 143, P1)
        for y in range(40, 48):
            hw = (y - 40) // 3
            lz.hl(x + 3 - hw, x + 2 + hw, y, P2)
    lz.hl(0, W - 1, 56, P3)
    cx, cy, r = 48, 76, 13                                                  # rosetón
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** .5
            if d <= r:
                lz.p(x, y, P3 if d > r - 2 else ('#c04848' if int(d) % 4 == 0 else '#4a72b4' if (x + y) % 3 else '#e0b84a'))
    for a in range(8):                                                      # radios
        import math
        for t in range(2, r - 1):
            lz.p(cx + int(math.cos(a * math.pi / 4) * t), cy + int(math.sin(a * math.pi / 4) * t), P3)
    for x in (8, 76):                                                       # ventanales apuntados de los lados
        for y in range(70, 100):
            for xx in range(x, x + 12):
                dx = abs(xx + .5 - (x + 6))
                if y < 78 and dx > (y - 70) * .75 + 1:
                    continue
                lz.p(xx, y, CR if 1 < dx < 5.5 else P3)
        lz.vl(x + 6, 74, 99, P3)
    for k in range(3):                                                      # portada con arquivoltas
        for y in range(98 - k * 3, H - 3):
            for x in range(30 - k * 3, 66 + k * 3):
                dx = abs(x + .5 - 48)
                lim = 18 + k * 3
                if y < 116 and dx > (y - (98 - k * 3)) * 1.1 + 2:
                    continue
                if dx < lim:
                    lz.p(x, y, (P3, P1, P2)[k] if k else P1)
    for y in range(104, H - 3):
        for x in range(36, 60):
            dx = abs(x + .5 - 48)
            if y < 116 and dx > (y - 104) * 1.1 + 1:
                continue
            lz.p(x, y, '#4a3020' if dx > 1 else P3)
    lz.r(46, 104, 4, 10, P2)                                                # el parteluz con su imagen
    lz.r(0, H - 3, W, 3, P3)
    for _ in range(80):
        lz.p(int(R() * W), 56 + int(R() * 85), P1)
    return lz


def teatro():
    """el teatro de la ría (8 × 7): cúpulas de pizarra en las esquinas, balaustrada, frontón con el escudo propio, tres arcos
    grandes con columnas, los ventanales del piso noble y la escalinata"""
    W, H = 128, 112
    lz = Lienzo(W, H)
    P0, P1, P2, P3 = '#e2d6bc', '#c4b694', '#f2ead6', '#7a6c50'
    R = azar(971)
    M.tejas(lz, 0, 0, W, 26, PIZ, alto=3, paso=5, sem=973)
    for x in (2, 104):                                                      # cúpulas de las esquinas
        for y in range(0, 22):
            hw = min(11, 3 + y // 2)
            lz.hl(x + 11 - hw, x + 10 + hw, y, PIZ[0] if y % 3 else PIZ[2])
        lz.r(x + 10, 0, 2, 3, '#e0b040')
    for y in range(4, 26):                                                  # frontón
        hw = min(30, (y - 4) * 2)
        lz.hl(64 - hw, 63 + hw, y, P2)
    lz.caja(58, 12, 12, 10, '#4a72b4', P3); lz.r(62, 14, 4, 6, '#e0b040')  # escudo propio
    lz.r(0, 26, W, 5, P2)                                                   # balaustrada
    for x in range(2, W, 4):
        lz.vl(x, 27, 30, P3)
    lz.hl(0, W - 1, 31, P3)
    lz.r(0, 32, W, 80, P0)
    for _ in range(200):
        lz.p(int(R() * W), 32 + int(R() * 78), P1)
    for i, x in enumerate((8, 30, 52, 74, 96)):                             # piso noble: ventanales con frontón curvo
        lz.r(x - 2, 36, 24, 2, P2)
        for y in range(34, 37):
            lz.hl(x + 2, x + 17, y, P2)
        M.ventana(lz, x, 38, 20, 22, P3, CR, CRL, P1, cruz=True)
        lz.r(x - 2, 60, 24, 3, P2); lz.hl(x - 2, x + 21, 59, '#26262e')
    for x in range(0, W, 22):                                               # pilastras
        lz.r(x, 32, 4, 32, P2); lz.vl(x + 3, 32, 63, P1)
    lz.r(0, 64, W, 4, P2); lz.hl(0, W - 1, 67, P3)                          # entablamento
    for i, ax in enumerate((10, 46, 82)):                                   # tres arcos grandes
        for y in range(70, H - 6):
            for x in range(ax, ax + 36):
                dx = x + .5 - (ax + 18)
                if y < 88 and dx * dx + (y - 88) ** 2 > 18 * 18:
                    continue
                lz.p(x, y, P2 if abs(dx) > 15 else CR if y > 74 else P3)
        lz.r(ax + 6, 84, 24, 1, P3); lz.p(ax + 8, 80, CRL); lz.p(ax + 9, 80, CRL)
        lz.vl(ax + 18, 76, H - 7, P3)
    for x in (6, 42, 78, 118):                                              # columnas
        lz.r(x, 68, 5, 38, P2); lz.vl(x + 4, 68, 105, P1); lz.r(x - 1, 68, 7, 2, P3)
    for j, y in enumerate((H - 6, H - 4, H - 2)):                           # escalinata
        lz.r(0, y, W, 2, (P1, P2, P3)[j])
    return lz


def mercado():
    """el mercado de la ribera (8 × 5): cubierta plana con el cuerpo central más alto, el hormigón claro, las vidrieras de
    colores en vertical y las puertas de cristal con su marquesina"""
    W, H = 128, 80
    lz = Lienzo(W, H)
    H0, H1, H2, H3 = '#e8e0cc', '#cfc6ae', '#f4efe2', '#7a705a'
    azotea(lz, W, 991, alto=18)
    lz.r(40, 0, 48, 20, H0); lz.hl(40, 87, 19, H3); lz.r(40, 0, 48, 3, H2)   # cuerpo central
    for x in range(44, 86, 6):
        lz.r(x, 5, 3, 12, '#4a72b4')
    lz.r(0, 20, W, 60, H0)
    lz.hl(0, W - 1, 20, H3)
    for x in range(0, W, 16):                                               # pilares y vidrieras
        lz.r(x, 20, 4, 56, H2); lz.vl(x + 3, 20, 75, H1)
        if 44 <= x <= 76:
            continue
        for y in range(24, 54):
            for xx in range(x + 5, x + 15):
                c = ('#4a72b4', '#e0b84a', '#c04848', '#5ab868')[((xx // 3) + (y // 5)) % 4]
                lz.p(xx, y, c if (xx + y) % 5 else CR)
        lz.hl(x + 5, x + 14, 54, H3)
    lz.r(44, 22, 40, 6, '#3a5a4a')                                          # rótulo sin letras: la franja verde
    for x in range(48, 82, 4):
        lz.r(x, 24, 2, 2, '#e8e0cc')
    lz.r(40, 30, 48, 2, H3)                                                 # marquesina
    lz.r(44, 34, 40, 46, ALU)
    for x in (46, 66):
        lz.caja(x, 36, 18, 44, CR, MAR); lz.p(x + 2, 38, CRL); lz.p(x + 3, 38, CRL); lz.vl(x + 9, 37, 79, MAR)
    for x0 in (2, 86):                                                      # puestos a la vista por abajo
        lz.r(x0, 58, 40, 18, '#5a5e66')
        for x in range(x0 + 2, x0 + 38, 6):
            lz.r(x, 64, 4, 3, ('#e04848', '#f0d070', '#5ab868', '#e08a3a')[(x // 6) % 4])
    lz.r(0, 77, W, 3, '#5a5e66')
    return lz


def grua():
    """grúa de pórtico del muelle (4 × 7) sobre el hormigón: las patas, la cabina amarilla y la pluma hacia arriba"""
    W, H = 64, 112
    lz = Lienzo(W, H)
    R = azar(1001)
    lz.r(0, 0, W, H, '#8e8a84')                                             # el muelle, debajo
    for _ in range(500):
        lz.p(int(R() * W), int(R() * H), '#a6a29a' if R() < .5 else '#76726c')
    for y in range(0, H, 16):
        lz.hl(0, W - 1, y, '#6a665e')
    AM, AMS, AML = '#d8a830', '#a07a20', '#f0c850'
    lz.r(12, 100, 40, 4, '#5a5e66'); lz.hl(10, 54, 104, MAR)                # carriles
    for x in (14, 44):                                                      # patas en A
        for y in range(40, 100):
            lz.p(x + (y - 40) // 12, y, AM); lz.p(x + 1 + (y - 40) // 12, y, AMS)
            lz.p(x + 6 - (y - 40) // 12, y, AM)
        for y in range(46, 100, 9):
            lz.hl(x, x + 6, y, AMS)
    lz.r(10, 34, 44, 8, AM); lz.hl(10, 53, 34, AML); lz.hl(10, 53, 41, AMS)  # viga
    lz.caja(22, 20, 20, 14, AM, AMS); lz.caja(26, 23, 12, 7, CRL, MAR)     # cabina
    lz.r(26, 23, 3, 2, BL)
    for y in range(0, 22):                                                  # la pluma, en celosía
        x = 40 + (22 - y) // 3
        lz.p(x, y, AM); lz.p(x + 3, y, AMS)
        if y % 4 == 0:
            lz.hl(x, x + 3, y, AMS)
    lz.vl(48, 0, 30, MAR)                                                   # el cable con el gancho
    lz.r(47, 30, 3, 3, MAR)
    return lz


# ------------------------------------------------------------------------------------------------------------- casillas
BAL, BALL, BALS = '#7a7268', '#948c80', '#5a544c'                          # balasto
TRAV, TRAVL = '#5a4232', '#7a5a42'                                          # traviesas
RIEL, RIELL = '#6a6e74', '#c8ccd0'


def via(vertical=False, paso=False):
    lz = Lienzo(64, 16)
    for v in range(4):
        R = azar(1100 + v * 7 + (50 if vertical else 0)); x0 = v * 16
        lz.r(x0, 0, 16, 16, BAL)
        for _ in range(40):
            lz.p(x0 + int(R() * 16), int(R() * 16), BALL if R() < .5 else BALS)
        if paso:                                                            # paso a nivel: losas de goma entre los carriles
            lz.r(x0, 0, 16, 16, '#4a4a50')
            for i in range(0, 16, 4):
                if vertical:
                    lz.hl(x0, x0 + 15, i, '#3a3a40')
                else:
                    lz.vl(x0 + i, 0, 15, '#3a3a40')
        else:
            for i in range(1, 16, 4):                                       # traviesas
                if vertical:
                    lz.r(x0 + 1, i, 14, 2, TRAV); lz.hl(x0 + 1, x0 + 14, i, TRAVL)
                else:
                    lz.r(x0 + i, 1, 2, 14, TRAV); lz.vl(x0 + i, 1, 14, TRAVL)
        for c in (4, 11):                                                   # carriles
            if vertical:
                lz.vl(x0 + c, 0, 15, RIEL); lz.vl(x0 + c - 1, 0, 15, RIELL)
            else:
                lz.hl(x0, x0 + 15, c, RIEL); lz.hl(x0, x0 + 15, c - 1, RIELL)
        if v == 2 and not paso:
            lz.p(x0 + 7, 7, '#c8b070'); lz.p(x0 + 8, 8, '#c8b070')          # una colilla / papel
    return lz


def adoquin():
    """adoquín de granito del Casco Viejo: 0 limpio, 1 con un charco, 2 con una tapa, 3 gastado"""
    lz = Lienzo(64, 16)
    A, AL, AS = '#9a9488', '#b6b0a2', '#6e6a60'
    for v in range(4):
        R = azar(1200 + v * 11); x0 = v * 16
        lz.r(x0, 0, 16, 16, AS)
        for fy in range(0, 16, 4):
            off = 2 if (fy // 4) % 2 else 0
            for fx in range(-off, 16, 5):
                for y in range(fy, fy + 3):
                    for x in range(max(0, fx), min(16, fx + 4)):
                        lz.p(x0 + x, y, AL if y == fy else A)
        for _ in range(6):
            lz.p(x0 + int(R() * 16), int(R() * 16), AS)
        if v == 1:
            M.mancha(lz, x0 + 3, 6, 9, 4, '#6a8ea0', R); lz.hl(x0 + 6, x0 + 8, 7, '#a8d0e4')
        elif v == 2:
            lz.caja(x0 + 4, 4, 8, 8, '#5a5e66', MAR); lz.hl(x0 + 6, x0 + 9, 7, MAR); lz.hl(x0 + 6, x0 + 9, 9, MAR)
    return lz


def muelle():
    """losa de piedra del muelle de la ría: sillares grandes y alguna argolla"""
    lz = Lienzo(64, 16)
    for v in range(4):
        x0 = v * 16
        M.sillar(lz, x0, 0, 16, 16, ('#a8a294', '#6e6a60', '#c4beb0'), bw=16, bh=8, sem=1300 + v)
        if v == 3:
            lz.caja(x0 + 6, 5, 5, 5, '#a8a294', MAR)
    return lz


# ------------------------------------------------------------------------------------------------------------- objetos
def baranda():
    """barandilla de la ría (1 m): pasamanos y barrotes de hierro pintados de verde oscuro, con su sombra"""
    lz = Lienzo(16, 16)
    V, VL, VS = '#2f5a48', '#4e8068', '#1e3a30'
    lz.r(0, 2, 16, 2, VL); lz.hl(0, 15, 4, VS)
    for x in range(1, 16, 3):
        lz.vl(x, 5, 13, V)
    lz.hl(0, 15, 9, V)
    lz.hl(0, 15, 14, VS)
    return lz


def platano():
    """plátano de sombra en su alcorque (4 m): la copa podada en bola, el tronco moteado de crema y oliva y la reja de hierro"""
    lz = Lienzo(32, 64)
    R = azar(77)
    H0, H1, H2, H3 = '#2e5a2c', '#467a36', '#68983e', '#8cb456'
    cx, cy = 16, 20
    for y in range(64):
        for x in range(32):
            dx, dy = (x - cx) / 14.5, (y - cy) / 15.0
            d = dx * dx + dy * dy + (R() - .5) * .18
            if d < 1:
                lz.p(x, y, H3 if d < .45 and dx + dy < -.3 else H2 if dx + dy < .1 else H1 if d < .8 else H0)
    for _ in range(40):                                          # grumos de hoja
        x, y = int(4 + R() * 24), int(8 + R() * 24)
        if lz.lleno(x, y):
            lz.p(x, y, H0 if R() < .5 else H3)
    T, TL, TS = '#a49a7a', '#d6cfae', '#6a6448'
    lz.r(14, 33, 4, 26, T)
    for y in range(33, 59):
        lz.p(17, y, TS)
        if R() < .35:
            lz.p(14 + int(R() * 3), y, TL)
    lz.vl(12, 30, 34, TS); lz.vl(19, 30, 34, TS)               # las dos ramas que salen a la copa
    lz.r(8, 58, 16, 5, '#3a3a3c')                               # el alcorque: la reja
    for x in range(9, 23, 2):
        lz.vl(x, 59, 61, '#5c5c60')
    lz.hl(8, 23, 63, '#26262a')
    lz.contorno('#1e3a2a')
    return lz


def metro():
    """la boca del metro (3 m × 2 casillas): la concha de cristal y acero que baja a la estación, con su luz"""
    lz = Lienzo(48, 48)
    AC, ACS, VI, VIL = '#9aa4ac', '#5a646c', '#8cc0dc', '#d0eaf6'
    for y in range(14, 46):                                                 # la concha, de lado: más alta atrás
        t = (y - 14) / 32
        x1 = 2 + int(28 * (1 - (1 - t) ** 2))
        for x in range(2, x1 + 1):
            lz.p(x, y, VI if (x + y) % 7 else VIL)
        lz.p(x1, y, AC); lz.p(x1 + 1, y, ACS)
    for x in range(2, 31, 6):
        for y in range(14, 46):
            if lz.lleno(x, y):
                lz.p(x, y, AC)
    lz.r(2, 44, 30, 2, ACS)
    lz.r(4, 38, 10, 6, '#3a3a40')                                           # la escalera que baja
    for y in range(38, 44, 2):
        lz.hl(4, 13, y, '#5a5e66')
    lz.caja(34, 18, 6, 26, ACS, MAR); lz.r(35, 20, 4, 6, '#e04040')         # el poste con la señal roja (sin letras)
    lz.r(36, 22, 2, 2, BL)
    return lz


SPRITES = {
    'torres': lambda: [guarda('edificio-' + k, torre(k)) for k in TORRES],
    'ensanches': lambda: [guarda('edificio-' + k, ensanche(k)) for k in ENSANCHES],
    'estacion': lambda: guarda('edificio-estacion', estacion()),
    'catedral': lambda: guarda('edificio-catedral', catedral()),
    'teatro': lambda: guarda('edificio-teatro', teatro()),
    'mercado': lambda: guarda('edificio-mercado', mercado()),
    'grua': lambda: guarda('edificio-grua', grua()),
    'tiles': lambda: [sale(f(), 'tiles-bilbao', k) for k, f in (('via', via), ('viaV', lambda: via(True)), ('viaX', lambda: via(False, True)),
                                                               ('viaXV', lambda: via(True, True)), ('adoq', adoquin), ('muelleP', muelle))],
    'props': lambda: [sale(baranda(), 'props-bilbao', 'baranda'), sale(platano(), 'props-bilbao-alto', 'platano'), sale(metro(), 'props-bilbao-ancho', 'metroB')],
}

if __name__ == '__main__':
    for k in sys.argv[1:] or list(SPRITES):
        SPRITES[k]()
    for f in OUT:
        print(f)
