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
#  · props-bilbao: la barandilla verde de la ría, la papelera, el bolardo, el plátano en su alcorque (4 m), la boca del metro de cristal,
#    los contenedores, la boca de la escalera del paso subterráneo de Zorroza y su ascensor averiado (2 casillas);
#  · suelo-bilbao: la tapa de registro, el imbornal y el paso de cebra, que el mapa pone a ritmo fijo (BILBAO.DEC; no al azar).
# Sale a art/crudo/<grupo>/<sprite>/unica/NN.png; después, node tools/sprites/procesar.js <grupos> --atlas --atlas-dir godot/arte.
import math
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
          'torreZ2': ('#d8c49a', '#c0aa7e', '#e8dab8', '#8c7650', 'revoque'),
          'bloqueZ': ('#c88c6c', '#b07658', '#dca484', '#7a4a34', 'revoque'),
          'bloqueZ2': ('#b4643e', '#d0bca0', '#c87c54', '#7a3e26', 'ladrillo')}
ALTO_TORRE = {'bloqueZ': 80, 'bloqueZ2': 80}                                # los bloques bajos de la avenida (6 × 5)


def torre(k):
    """bloque alto de Zorroza (6 × 9): azotea, siete plantas de ventanas de aluminio con persiana, cerramientos de terraza,
    ropa tendida y aparatos del aire, y los bajos: una persiana metálica y el portal de aluminio"""
    H = ALTO_TORRE.get(k, 144)
    lz = Lienzo(96, H)
    C0, C1, C2, C3, tipo = TORRES[k]
    R = azar(700 + len(k))
    a = 26 if H > 100 else 12                                               # la azotea, menos honda en los bajos
    azotea(lz, 96, 701 + len(k), alto=a)
    if tipo == 'ladrillo':
        M.ladrillos(lz, 0, a, 96, H - 31 - a, (C0, C1, C2, C3), sem=703)
    else:
        lz.r(0, a, 96, H - 31 - a, C0)
        for _ in range(240 * (H - 31 - a) // 90):
            lz.p(int(R() * 96), a + int(R() * (H - 31 - a)), C1)
    lz.r(0, a, 96, 2, C3)
    for p in range((H - 33 - a) // 12):
        y = a + 3 + p * 12
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
    b = H - 144                                                             # los bajos, al pie
    lz.r(0, b + 113, 96, 31, '#3a3a40')                                         # los bajos
    lz.r(0, b + 113, 96, 3, HORL)
    lz.r(4, b + 118, 44, 4, '#5a5e66'); lz.r(5, b + 122, 42, 22, '#7c8088')       # persiana metálica de un local
    for y in range(b + 123, H, 2):
        lz.hl(5, 46, y, '#5a5e66')
    for x, c in ((9, '#e04848'), (13, '#4a92e0'), (18, '#5ab868')):          # pintadas
        lz.hl(x, x + 3, b + 130 + (x % 3), c)
    lz.r(58, b + 117, 26, 27, ALU)                                              # portal de aluminio y cristal
    lz.caja(60, b + 119, 22, 25, CR, MAR); lz.vl(71, b + 120, H - 1, MAR); lz.p(62, b + 121, CRL); lz.p(63, b + 121, CRL); lz.p(73, b + 121, CRL)
    lz.caja(88, b + 122, 5, 8, '#e0b040', MAR)                                  # buzón / telefonillo
    lz.r(0, H - 3, 96, 3, '#5a5e66')
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
    """el teatro de la ría (8 × 7): cúpulas de pizarra en las esquinas, balaustrada, frontón con su óculo liso (sin escudo), tres arcos
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
    lz.caja(58, 12, 12, 10, P1, P3); lz.r(61, 14, 6, 6, CR); lz.hl(61, 66, 14, CRL)   # el óculo, de piedra y cristal: sin escudo
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


def grua(fondo=True):
    """grúa de pórtico del muelle (4 × 7) sobre el hormigón: las patas, la cabina amarilla y la pluma hacia arriba; sin fondo, sola
    (la de los astilleros, pueblos.py)"""
    W, H = 64, 112
    lz = Lienzo(W, H)
    R = azar(1001)
    if fondo:
        lz.r(0, 0, W, H, '#8e8a84')                                         # el muelle, debajo
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




# ------------------------------------------------------------------------------------------------------- edificios icónicos
# Lo pidió el usuario: «además de tener edificios icónicos, para que sea una experiencia más realista». Cada uno, un homenaje de forma
# (la silueta y los materiales por los que se reconoce el sitio), dibujado aquí a mano: ni rótulos, ni escudos, ni letras reales.

PB, PBL, PBS, PBO = '#dccdaa', '#ece2c8', '#b8a882', '#6e6248'             # piedra arenisca clara
LAD = ('#a04a34', '#c8b8a0', '#bc6446', '#7a3426')                           # ladrillo rojo
VERDE, VERDEL, VERDES = '#3a6a52', '#5a9474', '#24463a'                     # hierro pintado de verde
ZINC, ZINCL, ZINCS = '#6c8a8c', '#94b0ae', '#4a6264'                         # cúpulas de cinc


def arco(lz, ax, w, y0, y1, c, borde=None):
    """hueco en arco de medio punto: de ax a ax + w, con la clave en y0 y el pie en y1; borde, la rosca de 1 px"""
    r = w / 2
    for y in range(y0, y1 + 1):
        for x in range(ax, ax + w):
            dx = x + .5 - (ax + r)
            yc = y0 + r
            if y < yc and dx * dx + (y + .5 - yc) ** 2 > r * r:
                continue
            fuera = y < yc and dx * dx + (y + .5 - yc) ** 2 > (r - 1.2) ** 2
            lz.p(x, y, borde if borde and (fuera or abs(dx) > r - 1.2) else c)


def apuntado(lz, ax, w, y0, y1, c, borde=None):
    """hueco en arco apuntado (gótico)"""
    r = w * .85
    cx = ax + w / 2
    for y in range(y0, y1 + 1):
        for x in range(ax, ax + w):
            dx = abs(x + .5 - cx)
            yc = y0 + r * .8
            if y < yc:
                d = math.hypot(dx + (r - w / 2), y + .5 - yc)
                if d > r:
                    continue
                if borde and d > r - 1.2:
                    lz.p(x, y, borde)
                    continue
            lz.p(x, y, borde if borde and dx > w / 2 - 1.2 else c)


def cupula(lz, cx, y0, r, alto, c=(ZINC, ZINCL, ZINCS), pinaculo='#e0b040'):
    """cúpula de cinc vista de frente: media elipse con sus nervios y el remate"""
    for y in range(alto):
        hw = r * math.sqrt(max(0, 1 - ((alto - y) / alto) ** 2))
        x0, x1 = int(round(cx - hw)), int(round(cx + hw)) - 1
        if x1 < x0:
            continue
        lz.hl(x0, x1, y0 + y, c[0])
        lz.p(x0, y0 + y, c[1]); lz.p(x1, y0 + y, c[2])
        if hw > 3:
            lz.p(int(cx) - 1 - int(hw / 2), y0 + y, c[1]); lz.p(int(cx) + int(hw / 2), y0 + y, c[2])
    lz.vl(int(cx) - 1, y0 - 3, y0, pinaculo); lz.vl(int(cx), y0 - 3, y0, pinaculo)


def piedra(lz, x, y, w, h, c=(PB, PBS, PBL), sem=1, bw=12, bh=6):
    M.sillar(lz, x, y, w, h, c, bw=bw, bh=bh, sem=sem)


def frontis(lz, cx, y0, hw, alto, c, sombra):
    """frontón triangular"""
    for y in range(alto):
        w = int(hw * (y + 1) / alto)
        lz.hl(cx - w, cx + w - 1, y0 + y, c)
    lz.hl(cx - hw, cx + hw - 1, y0 + alto, sombra)


def balaustrada(lz, x0, x1, y, c, sombra):
    lz.hl(x0, x1, y, c); lz.hl(x0, x1, y + 3, c)
    for x in range(x0 + 1, x1, 3):
        lz.vl(x, y + 1, y + 2, sombra)
    lz.hl(x0, x1, y + 4, sombra)


def iglesia_torre(lz, x, w, y0, y1, c, campana=True):
    """torre de campanario de piedra: cuerpo, el vano de las campanas y la cornisa"""
    piedra(lz, x, y0, w, y1 - y0, c, sem=x + y0, bw=8, bh=5)
    lz.hl(x, x + w - 1, y0, c[2])
    if campana:
        arco(lz, x + w // 2 - 4, 8, y0 + 4, y0 + 15, CR, c[1])
        lz.r(x + w // 2 - 2, y0 + 9, 4, 4, '#b08a3a')


# ---- Casco Viejo
def sanNicolas():
    """la iglesia barroca del Arenal (6 × 7): dos torres con chapitel de cinc a los lados, el cuerpo de piedra con el frontón
    curvo, la hornacina, el rosetón y la portada en arco, de cara al Arenal"""
    W, H = 96, 112
    lz = Lienzo(W, H)
    M.tejas(lz, 0, 0, W, 30, PIZ, alto=3, paso=5, sem=1501)
    for x in (0, 72):                                                       # las torres
        iglesia_torre(lz, x, 24, 28, H, (PB, PBS, PBL))
        cupula(lz, x + 12, 10, 11, 18)
        lz.r(x + 2, 26, 20, 3, PBL); lz.hl(x + 2, x + 21, 28, PBO)
        apuntado(lz, x + 8, 8, 60, 76, CR, PBO)
    piedra(lz, 24, 34, 48, H - 34, (PB, PBS, PBL), sem=1503)
    for y in range(18, 36):                                                 # frontón curvo
        hw = int(24 * math.sqrt(max(0, 1 - ((36 - y) / 18) ** 2)))
        lz.hl(48 - hw, 47 + hw, y, PBL)
    lz.hl(24, 71, 35, PBO)
    for y in range(18, 36):
        hw = int(24 * math.sqrt(max(0, 1 - ((36 - y) / 18) ** 2)))
        lz.p(48 - hw, y, PBO); lz.p(47 + hw, y, PBO)
    cx, cy, r = 48, 50, 8                                                   # óculo
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = math.hypot(x + .5 - cx, y + .5 - cy)
            if d <= r:
                lz.p(x, y, PBO if d > r - 1.5 else CR if d > 3 else CRL)
    lz.r(42, 26, 12, 8, PBS); lz.r(45, 27, 6, 7, '#8a7a5a')                 # la hornacina, con su imagen
    for x in (28, 64):                                                      # pilastras
        lz.r(x, 36, 4, H - 36, PBL); lz.vl(x + 3, 36, H - 1, PBS)
    arco(lz, 36, 24, 74, H - 4, '#4a3020', PBO)                             # la portada
    lz.vl(48, 86, H - 4, '#2e2016')
    lz.r(0, H - 3, W, 3, PBO)
    return lz


def kiosko():
    """el templete de la música del Arenal (3 × 2): cubierta de cinc en pabellón, el friso calado, las columnas de hierro, la
    barandilla y el zócalo de piedra, sobre la plaza"""
    W, H = 48, 32
    lz = Lienzo(W, H)
    lz.r(0, 0, W, H, '#e8d6b0')                                             # la plaza, alrededor
    for y in range(0, 9):                                                   # la cubierta
        hw = 8 + y * 2
        lz.hl(24 - hw, 23 + hw, y, ZINC if y % 3 else ZINCS)
        lz.p(24 - hw, y, ZINCL)
    lz.vl(23, 0, 2, '#e0b040'); lz.vl(24, 0, 2, '#e0b040')
    lz.r(4, 9, 40, 3, VERDE)                                                # el friso calado
    for x in range(5, 44, 3):
        lz.p(x, 10, VERDEL)
    lz.r(5, 12, 38, 9, '#3a3a40')                                           # dentro, en sombra
    for x in (5, 14, 23, 33, 42):                                           # las columnas
        lz.vl(x, 12, 22, VERDE); lz.vl(x + 1, 12, 22, VERDES)
    lz.r(3, 21, 42, 2, VERDE)                                               # la barandilla
    for x in range(4, 44, 2):
        lz.vl(x, 23, 24, VERDES)
    piedra(lz, 2, 25, 44, 6, (PB, PBS, PBL), sem=1511, bw=8, bh=3)
    lz.hl(2, 45, 31, PBO)
    for x in (20, 21, 22, 23, 24, 25, 26, 27):                              # los escalones
        lz.p(x, 26, PBL)
    return lz


PORT = ('#e4d6b4', '#cbbb94', '#f2ead6', '#7a6c50')                          # la piedra de la plaza porticada


def plaza_frente(W, H, sem, centro=False):
    """un lado de la plaza porticada (de frente): cubierta de teja, dos pisos de balcones iguales y la arquería de abajo"""
    P0, P1, P2, P3 = PORT
    lz = Lienzo(W, H)
    M.tejas(lz, 0, 0, W, 14, M.TEJA, alto=4, paso=6, sem=sem)
    lz.r(0, 14, W, H - 14, P0)
    lz.r(0, 14, W, 2, P2); lz.hl(0, W - 1, 16, P3)
    R = azar(sem)
    for _ in range(W * H // 80):
        lz.p(int(R() * W), 17 + int(R() * (H - 20)), P1)
    for x in range(4, W - 8, 16):                                           # balcones
        M.ventana(lz, x + 1, 19, 10, 13, P3, CR, CRL, P1, cruz=False)
        lz.vl(x + 6, 20, 31, P3)
        lz.r(x - 1, 32, 14, 2, '#26262e')
        for xx in range(x, x + 13, 2):
            lz.vl(xx, 30, 31, '#26262e')
    if centro:                                                              # el cuerpo de en medio, con su frontón
        c = W // 2
        frontis(lz, c, 2, 26, 12, P2, P3)
        lz.r(c - 26, 14, 52, 22, P2)
        for x in (c - 22, c - 6, c + 10):
            M.ventana(lz, x, 18, 12, 14, P3, CR, CRL, P1, cruz=True)
        lz.r(c - 6, 6, 12, 6, P1)
    lz.hl(0, W - 1, 36, P3)
    for x in range(0, W, 16):                                               # la arquería
        lz.r(x, 37, 16, H - 37, P0)
        arco(lz, x + 2, 12, 40, H - 1, '#3a3a40', P3)
        lz.r(x, 37, 2, H - 37, P2)
    lz.r(0, H - 2, W, 2, P1)
    return lz


def plaza_ala():
    """el ala de la plaza porticada que se ve desde arriba (2 × 6): la cubierta a dos aguas a lo largo, con el alero de cada lado"""
    lz = Lienzo(32, 96)
    P0, P1, P2, P3 = PORT
    for y in range(96):
        for x in range(32):
            c = M.TEJA[0] if (x + (y // 4) * 3) % 6 else M.TEJA[2]
            if (y % 4) == 3:
                c = M.TEJA[2]
            lz.p(x, y, c)
    lz.vl(15, 0, 95, M.TEJA[1]); lz.vl(16, 0, 95, M.TEJA[2])                # la cumbrera
    lz.vl(0, 0, 95, P3); lz.vl(31, 0, 95, P3)
    lz.r(0, 80, 32, 16, P0); lz.hl(0, 31, 80, P3)                           # la punta, de frente: un arco del pórtico
    arco(lz, 10, 12, 83, 95, '#3a3a40', P3)
    return lz


def cascoB(k):
    """casa estrecha de las Siete Calles (3 × 4): teja, alero con canecillos, un piso con balcón de hierro y ropa, y la lonja"""
    W, H = 48, 64
    C0, C1, C2 = {'cascoB': ('#d8b860', '#bc9c48', '#6a5424'), 'cascoB2': ('#9cb8a4', '#7e9c88', '#3e5a48')}[k]
    lz = Lienzo(W, H)
    M.tejas(lz, 0, 0, W, 14, M.TEJA, alto=4, paso=6, sem=1520 + len(k))
    lz.r(0, 14, W, 2, M.MADERA[0])
    for x in range(1, W, 4):
        lz.p(x, 16, M.MADERA[1])
    lz.r(0, 17, W, 21, C0)
    R = azar(1522 + len(k))
    for _ in range(40):
        lz.p(int(R() * W), 17 + int(R() * 20), C1)
    lz.r(0, 17, 2, 47, PIEDRA[1])
    for x in (8, 28):
        M.ventana(lz, x, 19, 11, 15, C2, CR, CRL, C1, cruz=False)
        lz.vl(x + 5, 20, 32, C2)
    lz.r(5, 34, 38, 2, M.MADERA[0]); lz.hl(5, 42, 30, '#26262e')            # el balcón corrido
    for x in range(5, 43, 3):
        lz.vl(x, 31, 33, '#26262e')
    lz.hl(9, 20, 29, '#26262e')                                             # el tendedero
    for x, c in ((10, '#e04848'), (14, '#f4f4ee'), (18, '#4a92e0')):
        lz.r(x, 30, 3, 3, c) if k == 'cascoB' else None
    M.sillar(lz, 0, 38, W, 26, PIEDRA, bw=10, bh=5, sem=1525)
    arco(lz, 6, 16, 42, H - 1, CR, PIEDRA[1])
    lz.r(9, 54, 10, 2, '#e0b84a' if k == 'cascoB' else '#c04848')
    lz.r(30, 44, 12, 20, M.MADERA[0]); lz.vl(36, 45, H - 1, M.MADERA[1])
    return lz


def catedral4():
    """la catedral gótica entre las Siete Calles (4 × 6): la aguja calada sobre la fachada, el rosetón, los contrafuertes con
    pináculo y la portada apuntada, de cara a su plaza"""
    W, H = 64, 96
    lz = Lienzo(W, H)
    P0, P1, P2, P3 = '#c8b894', '#a89870', '#e4d8b8', '#6e6248'
    M.tejas(lz, 0, 0, W, 30, PIZ, alto=3, paso=5, sem=1531)
    for y in range(0, 40):                                                  # la aguja
        hw = max(1, (y * 8) // 40)
        lz.hl(32 - hw, 31 + hw, y, P0)
        lz.p(32 - hw, y, P3); lz.p(31 + hw, y, P1)
        if y % 5 == 2 and hw > 2:
            lz.hl(32 - hw + 2, 31 + hw - 2, y, P3)
    lz.r(31, 0, 2, 2, '#e0b040')
    M.sillar(lz, 0, 36, W, H - 36, (P0, P1, P2), bw=10, bh=5, sem=1533)
    for x in (0, 14, 46, 60):                                               # contrafuertes con pináculo
        lz.r(x, 32, 4, H - 32, P2); lz.vl(x + 3, 32, H - 1, P1)
        for y in range(26, 32):
            hw = (y - 26) // 3
            lz.hl(x + 2 - hw, x + 1 + hw, y, P2)
    lz.hl(0, W - 1, 36, P3)
    cx, cy, r = 32, 50, 9                                                   # rosetón
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = math.hypot(x + .5 - cx, y + .5 - cy)
            if d <= r:
                lz.p(x, y, P3 if d > r - 1.5 else ('#c04848' if int(d) % 3 == 0 else '#4a72b4' if (x + y) % 3 else '#e0b84a'))
    for a in range(8):
        for t in range(2, r - 1):
            lz.p(cx + int(math.cos(a * math.pi / 4) * t), cy + int(math.sin(a * math.pi / 4) * t), P3)
    for x in (5, 50):                                                       # ventanales de los lados
        apuntado(lz, x, 8, 44, 66, CR, P3)
    apuntado(lz, 20, 24, 64, H - 3, '#4a3020', P3)                          # la portada
    lz.vl(32, 74, H - 3, P2)
    lz.r(0, H - 3, W, 3, P3)
    return lz


def mercadoR():
    """el mercado de la Ribera, a lo largo de la orilla (14 × 4): la cubierta plana con los tres cuerpos más altos, hormigón
    claro con las vidrieras de colores en vertical y las puertas de cristal con su marquesina en el centro (doorX 23: x 96–127)"""
    W, H = 224, 64
    lz = Lienzo(W, H)
    H0, H1, H2, H3 = '#e8e0cc', '#cfc6ae', '#f4efe2', '#7a705a'
    azotea(lz, W, 1541, alto=14)
    for c0, w, al in ((6, 44, 15), (86, 52, 17), (170, 46, 14)):            # los tres cuerpos altos, cada uno a su altura
        lz.r(c0, 0, w, al, H0); lz.hl(c0, c0 + w - 1, al - 1, H3); lz.r(c0, 0, w, 2, H2)
        for x in range(c0 + 4, c0 + w - 4, 6):
            lz.r(x, 4, 3, al - 7, '#4a72b4')
    lz.r(0, 16, W, 48, H0)
    lz.hl(0, W - 1, 16, H3)
    for x in range(0, W, 16):                                               # pilares y vidrieras
        lz.r(x, 16, 4, 46, H2); lz.vl(x + 3, 16, 61, H1)
        if 88 <= x <= 128:
            continue
        for y in range(20, 44):
            for xx in range(x + 5, x + 15):
                c = ('#4a72b4', '#e0b84a', '#c04848', '#5ab868')[((xx // 3) + (y // 5)) % 4]
                lz.p(xx, y, c if (xx + y) % 5 else CR)
        lz.hl(x + 5, x + 14, 44, H3)
    lz.r(92, 18, 40, 5, '#3a5a4a')                                          # la franja verde, sin letras
    for x in range(96, 130, 4):
        lz.r(x, 20, 2, 2, H0)
    lz.r(88, 25, 48, 2, H3)                                                 # marquesina
    lz.r(92, 28, 40, 36, ALU)
    for x in (96, 112):                                                     # las dos hojas, encima de las dos casillas de la puerta
        lz.caja(x, 30, 16, 34, CR, MAR); lz.p(x + 2, 32, CRL); lz.p(x + 3, 32, CRL); lz.vl(x + 8, 31, 63, MAR)
    for x0 in (4, 46, 142, 184):                                            # puestos a la vista por abajo
        lz.r(x0, 48, 36, 13, '#5a5e66')
        for x in range(x0 + 2, x0 + 34, 6):
            lz.r(x, 52, 4, 3, ('#e04848', '#f0d070', '#5ab868', '#e08a3a')[(x // 6) % 4])
    lz.r(0, 61, 92, 3, '#5a5e66'); lz.r(132, 61, W - 132, 3, '#5a5e66')
    return lz


def sanAnton():
    """la iglesia gótica junto al puente (6 × 6): la torre de campanas con el remate barroco a la izquierda, la nave con los
    contrafuertes y el ventanal apuntado, y la portada de cara a la ría"""
    W, H = 96, 96
    lz = Lienzo(W, H)
    P = ('#bcae8c', '#968866', '#d8ccae')
    M.tejas(lz, 24, 0, 72, 30, M.TEJA, alto=4, paso=6, sem=1551)
    iglesia_torre(lz, 0, 26, 18, H, P)                                      # la torre
    for y in range(0, 18):                                                  # el remate: cúpula de piedra y linterna
        hw = int(12 * math.sqrt(max(0, 1 - ((18 - y) / 14) ** 2))) if y > 4 else 2
        lz.hl(13 - hw, 12 + hw, y, P[0] if y % 4 else P[1])
    lz.r(12, 0, 2, 3, '#e0b040')
    lz.r(0, 17, 26, 2, P[2]); lz.hl(0, 25, 19, P[1])
    apuntado(lz, 9, 8, 56, 72, CR, P[1])
    piedra(lz, 26, 30, 70, H - 30, P, sem=1553)
    for x in (26, 50, 74, 92):                                              # contrafuertes
        lz.r(x, 26, 4, H - 26, P[2]); lz.vl(x + 3, 26, H - 1, P[1])
    for x in (34, 80):
        apuntado(lz, x, 10, 36, 62, CR, P[1])
        lz.vl(x + 5, 42, 62, P[1])
    apuntado(lz, 54, 18, 54, H - 3, '#4a3020', P[1])                        # la portada
    lz.vl(63, 66, H - 3, '#2e2016')
    lz.r(0, H - 3, W, 3, P[1])
    return lz


# ---- Abando
def chavarri():
    """el palacio neoflamenco de la plaza (7 × 5): ladrillo rojo con bandas de piedra blanca, los hastiales escalonados y las
    torrecillas de pizarra de las esquinas"""
    W, H = 112, 80
    lz = Lienzo(W, H)
    M.tejas(lz, 0, 0, W, 22, PIZ, alto=3, paso=5, sem=1561)
    for cx in (34, 78):                                                     # hastiales escalonados
        for i in range(5):
            hw = 6 + i * 3
            lz.r(cx - hw, 4 + i * 4, hw * 2, 4, LAD[0])
            lz.r(cx - hw, 4 + i * 4, 2, 4, BL); lz.r(cx + hw - 2, 4 + i * 4, 2, 4, BL)
        lz.r(cx - 2, 0, 4, 4, BL)
        M.ventana(lz, cx - 4, 10, 8, 9, BL, CR, CRL, LAD[3], cruz=True)
    for x in (0, 96):                                                       # torrecillas con el chapitel
        for y in range(0, 18):
            hw = max(1, y * 8 // 18)
            lz.hl(x + 8 - hw, x + 7 + hw, y, PIZ[0] if y % 3 else PIZ[2])
        lz.r(x + 7, 0, 2, 2, '#e0b040')
    M.ladrillos(lz, 0, 22, W, 58, LAD, sem=1563)
    for x in (0, 96):
        lz.r(x, 18, 16, 62, LAD[2]); lz.vl(x + 15, 18, 79, LAD[3])
    for y in (22, 44, 62):                                                  # bandas de piedra blanca
        lz.r(0, y, W, 2, BL); lz.hl(0, W - 1, y + 2, BLS)
    for p, y in enumerate((27, 48)):
        for x in range(4, W - 10, 16):
            lz.r(x - 1, y - 1, 12, 14, BL)
            M.ventana(lz, x, y, 10, 12, BL, CR, CRL, LAD[3], cruz=True)
    arco(lz, 44, 24, 64, H - 1, '#4a3020', BL)                              # la puerta
    for x in (8, 24, 80, 96):
        M.ventana(lz, x, 67, 10, 10, BL, CR, CRL, LAD[3], cruz=True)
    lz.r(0, H - 2, W, 2, PIEDRA[1])
    return lz


def carlton():
    """el hotel de la plaza (7 × 7): piedra blanca, la mansarda de pizarra con la cúpula central y las de las esquinas, cinco
    plantas de balcones y la planta baja con los arcos"""
    W, H = 112, 112
    lz = Lienzo(W, H)
    B0, B1, B2, B3 = '#f0ebdc', '#d8d0bc', '#fbf8ee', '#8a826e'
    M.tejas(lz, 0, 12, W, 20, PIZ, alto=3, paso=5, sem=1571)
    lz.r(0, 0, W, 12, '#8e8a84')                                            # detrás: la azotea
    cupula(lz, 56, 4, 16, 20)
    for cx in (10, 102):
        cupula(lz, cx, 12, 9, 14)
    for x in (30, 76):                                                      # buhardillas
        lz.caja(x, 18, 8, 12, B0, B3); lz.r(x + 2, 21, 4, 7, CR)
    lz.r(0, 32, W, 4, B2); lz.hl(0, W - 1, 35, B3)                          # cornisa
    lz.r(0, 36, W, 76, B0)
    R = azar(1573)
    for _ in range(160):
        lz.p(int(R() * W), 36 + int(R() * 50), B1)
    for p in range(4):
        y = 38 + p * 12
        for x in range(4, W - 6, 14):
            M.ventana(lz, x, y, 9, 9, B2, CR, CRL, B1, cruz=False)
            lz.vl(x + 4, y + 1, y + 8, B2)
            if p in (0, 2):
                lz.hl(x - 1, x + 9, y + 9, '#26262e')
    for x in range(0, W, 28):                                               # las pilastras de la esquina
        lz.r(x, 36, 3, 50, B2)
    M.sillar(lz, 0, 86, W, 26, (B1, B3, B2), bw=10, bh=5, sem=1575)
    for ax in range(4, W - 16, 22):                                         # arcos de la planta baja
        arco(lz, ax, 16, 89, H - 1, CR, B3)
    lz.r(44, 84, 24, 3, '#3a3a40')                                          # la marquesina de la entrada
    lz.r(0, H - 2, W, 2, B3)
    return lz


def diputacion():
    """el palacio de la Gran Vía (8 × 6): piedra con mucho adorno, la crestería y las figuras de arriba, el balcón de en medio
    con columnas y el almohadillado de abajo con la puerta"""
    W, H = 128, 96
    lz = Lienzo(W, H)
    P0, P1, P2, P3 = '#cfc6b0', '#aea48c', '#e8e2d2', '#6a6250'
    M.tejas(lz, 0, 6, W, 18, PIZ, alto=3, paso=5, sem=1581)
    lz.r(0, 0, W, 6, '#8e8a84')
    for x in range(6, W - 4, 20):                                           # figuras y pináculos de la crestería
        lz.r(x, 14, 4, 10, P2); lz.r(x + 1, 11, 2, 3, P1)
    frontis(lz, 64, 4, 24, 18, P2, P3)
    lz.r(58, 10, 12, 10, P1); lz.hl(58, 69, 10, P2); lz.hl(58, 69, 19, P3)   # el remate, moldura lisa de piedra: ni escudo ni blasón
    lz.r(60, 8, 3, 3, P2); lz.r(65, 8, 3, 3, P2)
    lz.r(0, 24, W, 72, P0)
    lz.r(0, 24, W, 3, P2); lz.hl(0, W - 1, 27, P3)
    for y in (30, 50):                                                      # dos pisos de ventanales con su frontón
        for x in range(6, W - 14, 18):
            if 46 <= x <= 76:
                continue
            frontis(lz, x + 6, y - 4, 7, 3, P2, P3)
            M.ventana(lz, x, y, 12, 15, P3, CR, CRL, P1, cruz=True)
    for x in (46, 56, 66, 76):                                              # el balcón de las columnas
        lz.r(x, 28, 5, 40, P2); lz.vl(x + 4, 28, 67, P1)
    lz.r(50, 30, 6, 36, CR); lz.r(60, 30, 6, 36, CR); lz.r(70, 30, 6, 36, CR)
    balaustrada(lz, 42, 85, 64, P2, P3)
    M.sillar(lz, 0, 70, W, 26, (P1, P3, P0), bw=14, bh=6, sem=1583)         # el almohadillado
    arco(lz, 52, 24, 72, H - 1, '#4a3020', P3)
    for x in (10, 30, 90, 110):
        arco(lz, x, 10, 74, 90, CR, P3)
    lz.r(0, H - 2, W, 2, P3)
    return lz


def camposE():
    """el teatro modernista (8 × 7): fachada crema con el gran arco de herradura en medio, la tracería de hierro que lo llena
    como una ola, las torrecillas y las vidrieras de colores"""
    W, H = 128, 112
    lz = Lienzo(W, H)
    C0, C1, C2, C3 = '#eadcbc', '#d2c09a', '#f8f0dc', '#8a7650'
    lz.r(0, 0, W, 14, '#8e8a84')
    for cx in (12, 116):                                                    # torrecillas
        cupula(lz, cx, 4, 10, 14, (C1, C2, C3))
    lz.r(0, 14, W, H - 14, C0)
    R = azar(1591)
    for _ in range(200):
        lz.p(int(R() * W), 14 + int(R() * (H - 16)), C1)
    for x in (0, 104):
        lz.r(x, 14, 24, H - 14, C2); lz.vl(x + 23, 14, H - 1, C1)
        for y in (24, 46, 68):
            M.ventana(lz, x + 7, y, 10, 14, C3, CR, CRL, C1, cruz=True)
    cx, top = 64, 18                                                        # el arco de herradura
    for y in range(top, H - 4):
        for x in range(32, 96):
            dx = x + .5 - cx
            yc = top + 30
            rr = 30
            if y < yc + 10:
                d = math.hypot(dx, y + .5 - yc)
                if d > rr:
                    continue
            elif abs(dx) > 24:
                continue
            lz.p(x, y, C3 if (y < yc + 10 and math.hypot(dx, y + .5 - yc) > rr - 2.5) or abs(dx) > 22 else CR)
    for i in range(140):                                                    # la tracería en ola, de hierro
        t = i / 140 * math.pi * 3
        x = int(cx + math.cos(t) * (22 - i / 10))
        y = int(top + 30 + math.sin(t) * (22 - i / 10))
        if 0 <= x < W and top < y < H:
            lz.p(x, y, VERDEL)
            lz.p(x + 1, y, VERDE)
    for y in range(64, H - 6, 6):
        for x in range(44, 84, 8):
            lz.r(x, y, 4, 3, ('#4a72b4', '#e0b84a', '#c04848', '#5ab868')[(x // 8 + y // 6) % 4])
    lz.r(48, H - 26, 32, 22, '#4a3020'); lz.vl(64, H - 25, H - 5, '#2e2016')   # la puerta, en sus dos casillas (rel 48-80)
    lz.r(0, H - 4, W, 4, C3)
    return lz


def torreBBVA():
    """la torre de oficinas de la plaza (6 × 14): granito oscuro y franjas de cristal ahumado, la coronación con las antenas y el
    vestíbulo de cristal abajo"""
    W, H = 96, 224
    lz = Lienzo(W, H)
    G0, G1, G2 = '#4a4e56', '#3a3e46', '#62666e'
    VI, VIL = '#2c3c4c', '#5a7a94'
    lz.r(0, 0, W, 18, '#7a7e86')                                            # la azotea, desde arriba
    lz.caja(14, 2, 30, 12, '#8e9298', MAR); lz.caja(54, 4, 26, 10, '#8e9298', MAR)
    for x in (24, 66):
        lz.vl(x, 0, 6, MAR)
    lz.r(0, 18, W, 6, G2); lz.hl(0, W - 1, 23, G1)
    lz.r(0, 24, W, H - 50, G0)
    for y in range(26, H - 28, 6):                                          # las franjas de cristal
        lz.r(4, y, W - 8, 4, VI)
        for x in range(4, W - 4, 9):
            lz.vl(x, y, y + 3, G1)
        if (y // 6) % 4 == 0:
            lz.hl(6, 30, y, VIL)
    for x in (0, W - 4):                                                    # las aristas
        lz.r(x, 24, 4, H - 50, G2)
    lz.r(0, H - 26, W, 4, G2)
    lz.r(0, H - 22, W, 22, VI)                                              # el vestíbulo
    for x in range(0, W, 12):
        lz.vl(x, H - 22, H - 1, G1)
    lz.hl(4, 40, H - 20, VIL); lz.r(36, H - 16, 24, 16, '#1e2a36')
    lz.r(0, H - 2, W, 2, G1)
    return lz


def abandoE():
    """la estación de la plaza (8 × 7): la fachada de piedra con la gran vidriera de colores en medio, el reloj encima y los
    dos cuerpos de los lados, y la marquesina sobre las puertas"""
    W, H = 128, 112
    lz = Lienzo(W, H)
    M.tejas(lz, 0, 0, W, 20, PIZ, alto=3, paso=5, sem=1601)
    frontis(lz, 64, 2, 36, 18, PB, PBO)
    lz.caja(56, 6, 16, 12, BL, MAR); lz.vl(64, 8, 12, MAR); lz.hl(64, 67, 12, MAR)   # el reloj
    piedra(lz, 0, 20, W, H - 20, (PB, PBS, PBL), sem=1603)
    lz.hl(0, W - 1, 20, PBO)
    cx, top = 64, 24                                                        # la vidriera, en arco
    for y in range(top, 84):
        for x in range(30, 98):
            dx = x + .5 - cx
            yc = top + 34
            if y < yc and dx * dx + (y + .5 - yc) ** 2 > 34 * 34:
                continue
            borde = (y < yc and dx * dx + (y + .5 - yc) ** 2 > 32 * 32) or abs(dx) > 32
            if borde:
                lz.p(x, y, PBO)
                continue
            fr = (x - 30) // 7 + (y - top) // 6
            c = ('#4a72b4', '#e0b84a', '#c04848', '#5ab868', '#8a5ab4', '#6fb4d4')[fr % 6]
            lz.p(x, y, MAR if (x - 30) % 7 == 0 or (y - top) % 6 == 0 else c)
    for x in (4, 106):                                                      # los cuerpos de los lados
        lz.r(x - 2, 20, 22, H - 20, PBL)
        for y in (28, 52):
            M.ventana(lz, x + 3, y, 12, 16, PBO, CR, CRL, PBS, cruz=True)
    lz.r(20, 86, 88, 4, VERDE); lz.hl(20, 107, 89, VERDES)                  # la marquesina
    for x in range(22, 106, 14):
        lz.vl(x, 90, H - 3, VERDES)
    for x in range(26, 104, 14):
        lz.caja(x, 92, 10, H - 94, CR, MAR)
    lz.r(0, H - 2, W, 2, PBO)
    return lz


def concordia():
    """la estación modernista de la ría (4 × 6): la fachada de hierro verde y cerámica de colores, el gran ventanal en arco con
    su tracería, el reloj y los pináculos"""
    W, H = 64, 96
    lz = Lienzo(W, H)
    lz.r(0, 0, W, 12, '#8e8a84')
    for x in (4, 56):                                                       # pináculos
        lz.r(x, 2, 4, 14, VERDE); lz.r(x + 1, 0, 2, 2, '#e0b040')
    lz.r(0, 12, W, H - 12, '#e8dcc0')
    for y in range(12, H, 6):                                               # la cerámica, a cuadros
        for x in range(0, W, 6):
            if (x // 6 + y // 6) % 2 and (x < 10 or x > 52):
                lz.r(x, y, 6, 6, '#6fb4a4')
    lz.r(10, 12, 44, 4, VERDE); lz.hl(10, 53, 15, VERDES)
    lz.caja(24, 18, 16, 14, BL, VERDES); lz.vl(32, 20, 25, MAR); lz.hl(32, 35, 25, MAR)   # el reloj
    arco(lz, 12, 40, 34, 80, CR, VERDE)                                     # el ventanal
    for x in range(16, 52, 6):
        lz.vl(x, 40, 80, VERDE)
    for y in range(46, 80, 8):
        lz.hl(13, 50, y, VERDE)
    lz.p(18, 44, CRL); lz.p(19, 44, CRL)
    lz.r(10, 81, 44, 3, VERDE)
    for x in (16, 36):
        lz.caja(x, 84, 12, H - 85, CR, VERDES)
    lz.r(0, H - 2, W, 2, VERDES)
    return lz


# ---- Zorroza y La Punta
def milagrosa():
    """la iglesia del barrio (6 × 8): ladrillo, la torre de campanas alta a la derecha con su aguja, la nave con el hastial y el
    ventanal, y la puerta en arco a la plaza"""
    W, H = 96, 128
    lz = Lienzo(W, H)
    M.tejas(lz, 0, 30, 66, 22, M.TEJA, alto=4, paso=6, sem=1611)
    lz.r(0, 0, 66, 30, '#e8d6b0')                                           # detrás, la plaza
    for y in range(30, 54):                                                 # el hastial
        hw = (y - 30) * 33 // 24
        lz.hl(33 - hw, 32 + hw, y, LAD[0])
    M.ladrillos(lz, 0, 54, 66, H - 54, LAD, sem=1613)
    apuntado(lz, 25, 16, 58, 90, CR, LAD[1])
    lz.vl(33, 64, 90, LAD[1])
    arco(lz, 21, 24, 98, H - 3, '#4a3020', LAD[1])
    lz.r(66, 22, 30, H - 22, LAD[0])                                        # la torre
    M.ladrillos(lz, 66, 22, 30, H - 22, LAD, sem=1615)
    for y in range(0, 24):                                                  # la aguja
        hw = max(1, y * 15 // 24)
        lz.hl(81 - hw, 80 + hw, y, PIZ[0] if y % 4 else PIZ[2])
    lz.vl(80, 0, 3, '#e0b040')
    lz.r(66, 22, 30, 3, LAD[1])
    arco(lz, 73, 16, 30, 52, CR, LAD[1])
    lz.r(77, 40, 8, 6, '#b08a3a')
    for y in (64, 90):
        M.ventana(lz, 76, y, 10, 14, LAD[1], CR, CRL, LAD[3], cruz=False)
    lz.r(0, H - 3, W, 3, LAD[3])
    return lz


def iglesiaZ():
    """la parroquia del barrio de Zorroza (6 × 8), genérica: la nave de hormigón y ladrillo de los años sesenta con el tejado a dos
    aguas bajo, la vidriera alta de la fachada en franjas, la puerta bajo la marquesina y el campanario exento de hormigón a la
    derecha, prismático, con el hueco de la campana arriba y una cruz sencilla"""
    W, H = 96, 128
    lz = Lienzo(W, H)
    HO, HOO, HOL = '#c8c2b4', '#9a9488', '#e0dace'
    lz.r(0, 0, 64, 40, '#e8d6b0')                                           # detrás, la plaza
    M.tejas(lz, 0, 40, 64, 14, PIZ, alto=3, paso=6, sem=1621)               # el tejado bajo
    for y in range(40, 54):                                                 # el hastial, poco inclinado
        hw = 18 + (y - 40)
        lz.hl(32 - hw, 31 + hw, y, HO)
    M.ladrillos(lz, 0, 54, 64, H - 54, LAD, sem=1623)
    lz.r(0, 54, 64, 3, HOL); lz.r(0, 54, 4, H - 54, HO); lz.r(60, 54, 4, H - 54, HO)
    for i, x in enumerate(range(14, 50, 6)):                                # la vidriera en franjas verticales
        lz.r(x, 60, 4, 34, CR if i % 2 else '#8ab0c8'); lz.hl(x, x + 3, 60, CRL)
    lz.r(12, 58, 40, 2, HOO); lz.r(12, 94, 40, 2, HOO)
    lz.r(16, 100, 32, 3, HOO); lz.r(20, 103, 24, H - 106, '#4a3020')        # la marquesina y la puerta
    lz.vl(32, 103, H - 4, '#2a1c14')
    for x in range(72, 90):                                                 # el campanario exento, prismático
        lz.vl(x, 8, H - 3, HOL if x < 75 else HO if x < 86 else HOO)
    lz.r(74, 18, 14, 14, '#3a3a42'); lz.r(79, 22, 4, 6, '#b08a3a')          # el hueco de la campana
    lz.r(72, 8, 18, 3, HOO); lz.vl(81, 0, 8, HOO); lz.hl(78, 84, 3, HOO)    # el remate con la cruz sencilla
    for y in range(40, H - 8, 12):
        lz.hl(72, 89, y, HOO)
    lz.r(0, H - 3, W, 3, LAD[3])
    return lz


def apeadero():
    """el apeadero de la vía estrecha (4 × 3): la caseta con la marquesina de chapa, la ventanilla y el banco"""
    W, H = 64, 48
    lz = Lienzo(W, H)
    M.chapa(lz, 0, 0, W, 12, ('#c8ccd0', '#9aa0a8', '#6a7078'))
    lz.r(0, 12, W, 3, '#5a5e66')
    lz.r(0, 15, W, H - 15, '#d8c49a')
    lz.r(6, 18, 22, 27, '#c0aa7e')
    M.ventana(lz, 9, 21, 16, 10, ALU, CR, CRL, '#8c7650', cruz=True)
    lz.r(36, 18, 22, 30, '#8a949c'); lz.caja(38, 20, 18, 28, CR, '#5a646c'); lz.vl(47, 21, 47, '#5a646c')
    lz.r(6, 38, 22, 3, M.MADERA[1]); lz.vl(8, 41, 45, MAR); lz.vl(25, 41, 45, MAR)   # el banco
    lz.r(0, H - 2, W, 2, '#5a5e66')
    return lz


def molino():
    """el molino de harinas de la punta (8 × 9): la batería de silos de hormigón a la izquierda, el edificio de molienda alto
    con sus filas de ventanucos, la torre de elevadores y los tubos"""
    W, H = 128, 144
    lz = Lienzo(W, H)
    S0, S1, S2, S3 = '#c8c2b4', '#a8a294', '#e0dace', '#6e6a60'
    lz.r(0, 0, W, 10, '#8e8a84')
    for i, x in enumerate((0, 16, 32, 48)):                                 # los silos
        for xx in range(x, x + 16):
            t = (xx - x) / 15
            c = S2 if t < .25 else S0 if t < .6 else S1 if t < .85 else S3
            lz.vl(xx, 14, H - 6, c)
        for y in range(10, 14):
            hw = 6 + (y - 10)
            lz.hl(x + 8 - hw, x + 7 + hw, y, S0)
    lz.r(0, 22, 64, 3, S3)
    for y in range(40, H - 10, 22):
        lz.hl(0, 63, y, S1)
    lz.r(64, 4, 64, H - 4, '#d8cfb6')                                       # la molienda
    lz.r(64, 4, 64, 3, '#efe8d4'); lz.hl(64, 127, 7, S3)
    for y in range(14, H - 30, 14):
        for x in range(70, 124, 12):
            M.ventana(lz, x, y, 7, 8, S3, CR, CRL, S1, cruz=False)
    lz.r(96, 0, 18, 14, S1); lz.caja(98, 2, 14, 10, S0, S3)                 # la torre de elevadores
    for y in range(20, 60):                                                 # el tubo que baja a los silos
        lz.p(62 + (y - 20) // 6, y, '#9a7a4a'); lz.p(63 + (y - 20) // 6, y, '#7a5a34')
    lz.r(80, H - 26, 32, 26, '#5a5e66')                                     # el muelle de carga: el portón, en sus dos casillas (rel 80-112)
    for y in range(H - 25, H, 2):
        lz.hl(81, 110, y, '#7c8088')
    lz.vl(80, H - 26, H - 1, '#3e4248'); lz.vl(111, H - 26, H - 1, '#3e4248')
    lz.r(0, H - 4, W, 4, S3)
    return lz


# ---- props y casillas
def estatua():
    """la estatua de bronce de la plaza (1 × 1, alta): el pedestal de piedra con la placa sin letras y la figura de pie, verde
    de tanta lluvia"""
    lz = Lienzo(32, 64)
    B0, B1, B2 = '#4a7a68', '#2e5446', '#7aaa94'
    lz.r(8, 38, 16, 20, PB); lz.vl(23, 38, 57, PBS); lz.r(6, 36, 20, 3, PBL); lz.r(6, 57, 20, 5, PBS)
    lz.r(11, 44, 10, 6, '#8a7a5a')                                          # la placa, sin letras
    lz.r(13, 8, 6, 6, B0); lz.p(13, 8, B2)                                  # la cabeza
    lz.r(11, 14, 10, 14, B0); lz.vl(20, 14, 27, B1); lz.vl(11, 14, 27, B2)  # el cuerpo, con la levita
    lz.r(8, 15, 3, 10, B0); lz.r(21, 15, 3, 3, B0); lz.r(23, 12, 2, 4, B0)   # los brazos: uno señala
    lz.r(12, 28, 3, 9, B1); lz.r(17, 28, 3, 9, B0)
    lz.r(10, 35, 12, 2, B1)
    lz.contorno('#1e2a26')
    return lz


def puenteV():
    """el tablero del puente de piedra (de norte a sur): losas con la junta y el bordillo a los lados, las cuatro iguales"""
    lz = Lienzo(64, 16)
    for v in range(4):
        x0 = v * 16
        M.sillar(lz, x0, 0, 16, 16, ('#b4ac9a', '#7a7464', '#ccc6b4'), bw=8, bh=16, sem=1700)
    return lz


ICONOS = {'sanNicolas': sanNicolas, 'kiosko': kiosko, 'plazaN': lambda: plaza_frente(256, 64, 1531, True),
          'plazaS': lambda: plaza_frente(112, 64, 1533), 'plazaL': plaza_ala, 'plazaR': plaza_ala,
          'cascoB': lambda: cascoB('cascoB'), 'cascoB2': lambda: cascoB('cascoB2'), 'catedral': catedral4, 'mercadoR': mercadoR,
          'sanAnton': sanAnton, 'chavarri': chavarri, 'carlton': carlton, 'diputacion': diputacion, 'camposE': camposE,
          'torreBBVA': torreBBVA, 'abandoE': abandoE, 'concordia': concordia, 'milagrosa': milagrosa, 'iglesiaZ': iglesiaZ, 'apeadero': apeadero,
          'molino': molino}


# ------------------------------------------------------------------------------------------------------------- casillas
BAL, BALL, BALS = '#7a7268', '#948c80', '#5a544c'                          # balasto
TRAV, TRAVL = '#5a4232', '#7a5a42'                                          # traviesas
RIEL, RIELL = '#6a6e74', '#c8ccd0'


def via(vertical=False, paso=False, estrecha=False, fin=None):
    """la vía de ancho ibérico (los carriles a 7 px) o, estrecha, la de ancho métrico (a 5 px, traviesas más cortas); con `fin`
    ('o' a la izquierda, 'n' arriba, 's' abajo), la topera del final de la línea en ese lado (el apeadero de cabecera)"""
    lz = Lienzo(64, 16)
    for v in range(4):
        R = azar(1100 + (50 if vertical else 0)); x0 = v * 16          # las cuatro, iguales: nada al azar
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
                    a, b = (3, 12) if estrecha else (1, 14)
                    lz.r(x0 + a, i, b - a + 1, 2, TRAV); lz.hl(x0 + a, x0 + b, i, TRAVL)
                else:
                    a, b = (3, 12) if estrecha else (1, 14)
                    lz.r(x0 + i, a, 2, b - a + 1, TRAV); lz.vl(x0 + i, a, b, TRAVL)
        for c in ((5, 10) if estrecha else (4, 11)):                                                   # carriles
            if vertical:
                lz.vl(x0 + c, 0, 15, RIEL); lz.vl(x0 + c - 1, 0, 15, RIELL)
            else:
                lz.hl(x0, x0 + 15, c, RIEL); lz.hl(x0, x0 + 15, c - 1, RIELL)
        if fin:
            topera(lz, x0, fin)
    return lz


def anden(lado):
    """el andén del apeadero: losas de hormigón, el bordillo claro del lado de la vía ('n', 'o' o 'e') y la raya amarilla de seguridad"""
    lz = Lienzo(64, 16)
    for v in range(4):
        R = azar(1150); x0 = v * 16                                           # las cuatro, iguales
        lz.r(x0, 0, 16, 16, '#b4b0a6')
        for _ in range(10):
            lz.p(x0 + int(R() * 16), int(R() * 16), '#c4c0b6' if R() < .5 else '#a29e94')
        for t in range(16):                                                 # las juntas de las losas, cada 8
            lz.p(x0 + 7, t, '#9a968c'); lz.p(x0 + t, 7, '#9a968c'); lz.p(x0 + t, 15, '#9a968c'); lz.p(x0 + 15, t, '#9a968c')
        for t in range(16):
            for u, c in ((0, '#e4e0d4'), (1, '#e4e0d4'), (2, '#8a8680'), (4, '#e8c020')):
                if lado == 'n':
                    lz.p(x0 + t, u, c)
                elif lado == 'o':
                    lz.p(x0 + u, t, c)
                else:
                    lz.p(x0 + 15 - u, t, c)
    return lz


def topera(lz, x0, fin):
    """la topera: los carriles cortados y la viga a franjas rojas y blancas sobre dos pies, a 2 px del canto"""
    for t in range(4):                                                      # hasta la viga, balasto sin carriles
        for u in range(16):
            if fin == 'o':
                lz.p(x0 + t, u, BAL)
            else:
                lz.p(x0 + u, t if fin == 'n' else 15 - t, BAL)
    for u in range(2, 14):                                                  # la viga, a franjas de 2
        c = '#d83a30' if (u // 2) % 2 else '#f0ece4'
        for t in (4, 5):
            if fin == 'o':
                lz.p(x0 + t, u, c)
            else:
                lz.p(x0 + u, t if fin == 'n' else 15 - t, c)
    for u in (2, 13):                                                       # los pies, oscuros, hacia fuera
        for t in (2, 3, 4, 5):
            if fin == 'o':
                lz.p(x0 + t, u, '#2a2a30')
            else:
                lz.p(x0 + u, t if fin == 'n' else 15 - t, '#2a2a30')
    for u in range(2, 14):                                                  # el canto de la viga
        if fin == 'o':
            lz.p(x0 + 6, u, '#2a2a30')
        else:
            lz.p(x0 + u, 6 if fin == 'n' else 9, '#2a2a30')


def adoquin():
    """adoquín de granito del Casco Viejo, las cuatro iguales (las tapas y los imbornales, en su sitio: suelo-bilbao)"""
    lz = Lienzo(64, 16)
    A, AL, AS = '#9a9488', '#b6b0a2', '#6e6a60'
    for v in range(4):
        R = azar(1200); x0 = v * 16
        lz.r(x0, 0, 16, 16, AS)
        for fy in range(0, 16, 4):
            off = 2 if (fy // 4) % 2 else 0
            for fx in range(-off, 16, 5):
                for y in range(fy, fy + 3):
                    for x in range(max(0, fx), min(16, fx + 4)):
                        lz.p(x0 + x, y, AL if y == fy else A)
        for _ in range(6):
            lz.p(x0 + int(R() * 16), int(R() * 16), AS)
    return lz


def muelle():
    """losa de piedra del muelle de la ría: sillares grandes, las cuatro iguales"""
    lz = Lienzo(64, 16)
    for v in range(4):
        x0 = v * 16
        M.sillar(lz, x0, 0, 16, 16, ('#a8a294', '#6e6a60', '#c4beb0'), bw=16, bh=8, sem=1300)
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


# ------------------------------------------------------------------------------- lo del suelo, en su sitio (suelo-bilbao)
# No van en las tiras (el juego elige la variante al azar): son calcomanías que el mapa pone donde tocan (BILBAO.DEC), encima de la
# casilla, a ritmo fijo: la tapa del registro por el centro del carril, el imbornal junto al bordillo, el paso de cebra en los cruces.
HIE, HIEL, HIES = '#4a4c52', '#6c7078', '#2c2e32'


def tapa():
    """la tapa de registro de fundición (60 cm): redonda, con su cuadrícula y el aro"""
    lz = Lienzo(16, 16)
    for y in range(16):
        for x in range(16):
            d = (x - 7.5) ** 2 + (y - 7.5) ** 2
            if d < 4.6 ** 2:
                lz.p(x, y, HIES if d > 3.8 ** 2 else HIEL if (x + y) % 3 == 0 else HIE)
    lz.hl(5, 10, 7, HIES); lz.vl(7, 5, 10, HIES)
    return lz


def imbornal(abajo=False):
    """el imbornal (la rejilla del desagüe) pegado al bordillo: arriba en la casilla de arriba de la calzada, abajo en la de abajo"""
    lz = Lienzo(16, 16)
    y0 = 12 if abajo else 0
    lz.r(3, y0, 10, 4, HIES)
    for x in range(4, 12, 2):
        lz.vl(x, y0 + 1, y0 + 2, HIEL)
    lz.hl(3, 12, y0 + (0 if abajo else 3), HIE)
    return lz


def cebra():
    """el paso de cebra: bandas blancas paralelas al bordillo, una cada 5 px (tres por casilla), con un margen a cada lado"""
    lz = Lienzo(16, 16)
    for y in (1, 6, 11):
        lz.r(1, y, 14, 3, '#e8e8e0'); lz.hl(1, 14, y + 2, '#c4c4bc')
    return lz


# ------------------------------------------------------------------------------- el mobiliario urbano (props-bilbao)
def papelera():
    """la papelera de la acera (1 m): cubo verde con su aro y el poste"""
    lz = Lienzo(16, 16)
    V, VL, VS = '#3c6e4e', '#5e9670', '#24463a'
    lz.vl(7, 12, 15, '#3a3a3c'); lz.vl(8, 12, 15, '#5c5c60')
    lz.r(4, 4, 8, 8, V); lz.vl(4, 4, 11, VS); lz.vl(10, 4, 11, VL)
    lz.hl(4, 11, 4, VL); lz.hl(3, 12, 3, '#26262a'); lz.r(5, 5, 6, 1, '#1a1a1c')
    lz.contorno('#1e2a24')
    return lz


def bolardo():
    """el bolardo de fundición (80 cm) de las esquinas y los pasos"""
    lz = Lienzo(16, 16)
    lz.r(6, 6, 4, 9, '#3e4046'); lz.vl(6, 6, 14, '#26282c'); lz.vl(8, 6, 14, '#6c7078')
    lz.r(5, 4, 6, 2, '#4e5058'); lz.hl(6, 9, 3, '#6c7078')
    lz.hl(5, 10, 15, '#1e1e22')
    lz.contorno('#1a1a1e')
    return lz


def contenedores():
    """los contenedores de la acera (2 casillas): el de resto, gris, y el de envases, amarillo, con su tapa"""
    lz = Lienzo(48, 48)
    for x0, (c, cl, cs) in ((4, ('#5c6268', '#7c848a', '#3a3e44')), (22, ('#d8b43a', '#ecd06a', '#a08020'))):
        lz.r(x0, 30, 16, 15, c); lz.vl(x0, 30, 44, cs); lz.vl(x0 + 15, 30, 44, cs)
        lz.r(x0 - 1, 26, 18, 4, cl); lz.hl(x0 - 1, x0 + 16, 29, cs)
        lz.r(x0 + 5, 33, 6, 2, cs)
        lz.r(x0 + 1, 45, 3, 2, '#1e1e22'); lz.r(x0 + 12, 45, 3, 2, '#1e1e22')
    lz.contorno('#1e1e22')
    return lz


# ------------------------------------------------------------------------------- el paso subterráneo de Zorroza (props-bilbao-ancho)
# (lo pidió el usuario: «que bajes unas escaleras y aparezcas en las del otro lado, sin cambiar el mapa… en la estación de tren de
# Zorroza el ascensor no funciona»): la boca de la escalera, de 2 casillas, vista desde arriba a medio fondo, que baja hacia la
# derecha (cada peldaño más oscuro hasta la boca del túnel) con su murete y su barandilla; y el ascensor de cristal, averiado.
def escalera():
    """la boca de la escalera (2 m × 1 m): siete peldaños de hormigón bajando hacia el este (huella clara, tabica oscura), la
    pared de dentro que se ve cada vez más alta según baja, el murete de arriba de frente con su pasamanos, el bordillo de abajo
    y, al fondo, la boca oscura del paso"""
    lz = Lienzo(48, 48)
    y0, y1 = 33, 45                                                         # el hueco, dentro de la fila de la casilla (32 a 47)
    for i in range(7):                                                      # siete peldaños de 4 px, cada uno más hondo y oscuro
        x = 10 + i * 4
        t = i / 6
        c = tuple(int(a + (b - a) * t) for a, b in ((0xa8, 0x4a), (0xa4, 0x47), (0x9c, 0x42)))
        hx = lambda v: '#%02x%02x%02x' % tuple(max(0, min(255, q)) for q in v)
        pared = 1 + i * 2                                                   # la pared de dentro, por encima del peldaño
        lz.r(x, y0, 4, y1 - y0 + 1, hx(c))
        lz.vl(x, y0 + pared, y1, hx(tuple(q + 24 for q in c)))              # el canto de la huella
        lz.vl(x + 3, y0 + pared, y1, hx(tuple(q - 30 for q in c)))          # la tabica, en sombra
        lz.r(x, y0, 4, pared, hx(tuple(q - 46 for q in c)))                 # la pared de dentro, en sombra
        lz.hl(x, x + 3, y0 + pared, hx(tuple(q - 60 for q in c)))
    lz.r(38, y0, 2, y1 - y0 + 1, '#121214')                                 # la boca del túnel
    lz.r(8, 28, 32, 5, '#b4b0a8'); lz.hl(8, 39, 28, '#d2cec6'); lz.hl(8, 39, 32, '#7a7670')   # el murete de arriba, de frente
    for x in range(10, 40, 7):
        lz.vl(x, 24, 27, '#5c6268')                                        # los postes del pasamanos
    lz.hl(8, 39, 23, '#7c848a'); lz.hl(8, 39, 24, '#5c6268')
    lz.hl(8, 39, 46, '#b4b0a8'); lz.hl(8, 39, 47, '#7a7670')                # el bordillo de abajo
    lz.vl(8, 33, 45, '#c8c4bc'); lz.vl(9, 33, 45, '#8a8680')                 # el canto de la entrada, por donde se pisa
    return lz


def ascensor():
    """el ascensor de la estación (2 m × 2,6 m), de cristal y acero, parado: la cabina abajo, las puertas cerradas con la cinta de
    obra cruzada y la luz roja encendida (sin letras)"""
    lz = Lienzo(48, 48)
    AC, ACS, ACL, VI, VIL = '#9aa4ac', '#5a646c', '#c4ccd2', '#7cb0cc', '#b8dcec'
    lz.r(9, 6, 30, 41, ACS)                                                 # la torre
    lz.r(11, 8, 26, 22, VI)                                                 # el cristal, con los reflejos
    for x in range(11, 37):
        for y in range(8, 30):
            if (x - y) % 9 in (0, 1):
                lz.p(x, y, VIL)
    lz.vl(24, 8, 29, AC); lz.hl(11, 36, 18, AC)
    lz.r(9, 4, 30, 3, ACL); lz.hl(9, 38, 6, ACS)                            # la tapa
    lz.r(13, 31, 22, 15, '#8a949c')                                         # las puertas, cerradas
    lz.vl(24, 31, 45, ACS); lz.hl(13, 34, 31, ACL)
    for i in range(22):                                                     # la cinta de obra, en aspa
        for x, y in ((13 + i, 32 + i * 13 // 21), (34 - i, 32 + i * 13 // 21)):
            c = '#e8c020' if (i // 3) % 2 else '#202024'
            lz.p(x, y, c); lz.p(x, y + 1, c)
    lz.caja(36, 33, 3, 6, ACS, '#2a2e32'); lz.p(37, 34, '#e83a30'); lz.p(37, 35, '#a02020')   # la botonera, con la luz roja
    lz.hl(9, 38, 46, '#2a2e32')
    lz.contorno('#1e1e22')
    return lz


SPRITES = {
    'torres': lambda: [guarda('edificio-' + k, torre(k)) for k in TORRES],
    'ensanches': lambda: [guarda('edificio-' + k, ensanche(k)) for k in ENSANCHES],
    'estacion': lambda: guarda('edificio-estacion', estacion()),
    'iconos': lambda: [guarda('edificio-' + k, f()) for k, f in ICONOS.items()],
    'iconos2': lambda: [sale(estatua(), 'props-bilbao-alto', 'estatua'), sale(puenteV(), 'tiles-bilbao', 'puenteV')],
    'teatro': lambda: guarda('edificio-teatro', teatro()),
    'mercado': lambda: guarda('edificio-mercado', mercado()),
    'grua': lambda: guarda('edificio-grua', grua()),
    'tiles': lambda: [sale(f(), 'tiles-bilbao', k) for k, f in (('via', via), ('viaV', lambda: via(True)), ('viaX', lambda: via(False, True)),
                                                               ('viaXV', lambda: via(True, True)),
                                                               ('viaE', lambda: via(estrecha=True)), ('viaEX', lambda: via(False, True, True)),
                                                               ('viaEV', lambda: via(True, estrecha=True)), ('viaEF', lambda: via(estrecha=True, fin='o')),
                                                               ('viaEFN', lambda: via(True, estrecha=True, fin='n')), ('viaEFS', lambda: via(True, estrecha=True, fin='s')),
                                                               ('andenN', lambda: anden('n')), ('andenO', lambda: anden('o')), ('andenE', lambda: anden('e')), ('adoq', adoquin), ('muelleP', muelle))],
    'props': lambda: [sale(baranda(), 'props-bilbao', 'baranda'), sale(papelera(), 'props-bilbao', 'papelera'), sale(bolardo(), 'props-bilbao', 'bolardo'),
                      sale(platano(), 'props-bilbao-alto', 'platano'), sale(metro(), 'props-bilbao-ancho', 'metroB'),
                      sale(contenedores(), 'props-bilbao-ancho', 'contenedores'), sale(escalera(), 'props-bilbao-ancho', 'escZ'),
                      sale(ascensor(), 'props-bilbao-ancho', 'ascensorZ')],
    'suelo': lambda: [sale(f(), 'suelo-bilbao', k) for k, f in (('tapa', tapa), ('imbT', imbornal), ('imbB', lambda: imbornal(True)), ('cebra', cebra))],
}

if __name__ == '__main__':
    for k in sys.argv[1:] or list(SPRITES):
        SPRITES[k]()
    for f in OUT:
        print(f)
