# python3 -I tools/sprites/a-mano/kaia_carpa.py  (Python 3 + Pillow)
# Las carpas de la sala de cultivo de KAIA, hechas como las de casa (lo pidió el usuario: «así no son las carpas, como te he dicho
# que las haga, de como están hechas en casa»): salen de la carpa de 150 del piso (carpa-g150-mapa, de PixelLab, ya procesada) como
# carpas.py saca la de 80 y la de 120, repitiendo solo columnas y filas que ya están en el sprite (misma paleta, mismo contorno):
# negras y cerradas, el techo a medio fondo con su lado de luz a la izquierda y el de sombra a la derecha, la barra plateada del
# armazón y la puerta con su cremallera. A 16 px/m como en casa: el frente, su alto real (2 m, 32 filas; la de sala, 2,5 m) y el
# techo, por el fondo (8 filas por metro; la de sala, toda su huella).
#  · la de 150 (24 × 40): columnas 0 poste de luz, 1-2 tela de luz, 3 cremallera, 4-9 la puerta, 10 cremallera, 11 tela de luz,
#    12-22 el lado de sombra, 23 poste; filas 0-1 canto del techo, 2-6 techo, 7 barra plateada, 8-38 el frente (la puerta de la 11 a
#    la 38) y 39 el pie.
#  · kcs, la de 200 × 200 (32 × 48); kcm, la de 400 × 200 con dos puertas (64 × 48); kcl, la de 400 × 400 (64 × 64), y, con el
#    servicio a la izquierda, kcsi, kcmi y kcli; kcx, la de
#    sala de 1.300 × 700 × 250 con la puerta para entrar andando en la casilla 6 (208 × 112), la luz hasta pasada la puerta.
# Celda carpa_kc de 80 × 80 (kcs, kcm, kcl) y carpa_kx de 208 × 112 (kcx), con la base en la fila de abajo y el mueble en sus
# casillas desde x 0. El tubo de extracción de cada una a la pared lo pinta el juego (kaiacult.gd, como el de casa).
# Sale a art/crudo/kaia-carpa/<kcs|kcm|kcl>/unica/00.png y art/crudo/kaia-carpa-sala/kcx/unica/00.png (después,
# node tools/sprites/procesar.js kaia-carpa kaia-carpa-sala --atlas --atlas-dir godot/arte)
import os, sys, glob, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
from carpas import columnas, filas, lee
from lienzo import P

LUZ = 1                      # una columna de tela de luz (techo claro, frente liso)
TECHO = (2, 6)               # las filas del techo que se alargan

def estira(a, b, n):
    """n índices repartidos de a a b (los dos incluidos), cada uno repetido lo que toque"""
    return [a + (i * (b - a + 1)) // n for i in range(n)]

def puerta(n):
    """la puerta de n columnas: cremallera, la tela de dentro (4-9) y cremallera"""
    return [3] + estira(4, 9, n - 2) + [10]

def cols_kc(w):
    """las columnas de la carpa de w metros: la mitad de luz con su puerta (dos en las de 4 m) y la mitad de sombra"""
    px = w * 16
    if w == 2:
        luz = [0, 1, 2] + puerta(11) + [11]
    else:
        luz = [0, 1, 2] + puerta(11) + [LUZ] * 5 + puerta(11) + [11]
    return luz + estira(12, 22, px - len(luz) - 1) + [23]

def cols_sala(px, xp, wp, xs):
    """la de sala: tela de luz, la puerta de wp columnas en xp, tela de luz hasta xs y el lado de sombra hasta el poste"""
    c = [0, 1, 2] + [LUZ] * (xp - 3) + puerta(wp)
    c += [LUZ] * (xs - len(c) - 1) + [11]
    return c + estira(12, 22, px - len(c) - 1) + [23]

def rows(techo, frente, puerta_h=28):
    """las filas: el techo de `techo` filas (con su barra) y el frente de `frente`, con la puerta de puerta_h filas"""
    t = [0, 1] + estira(TECHO[0], TECHO[1], techo - 3) + [7]
    cuerpo = puerta_h - 2                                           # la puerta: filas 11-12 de arriba y su cuerpo (13-38)
    f = [8] + estira(9, 10, frente - 4 - cuerpo) + [11, 12] + estira(13, 38, cuerpo) + [39]
    return t + f

# el armazón por debajo del techo, en las grandes (cada 2 m más o menos): los travesaños, una arista de luz con los colores del techo
LUZ_DE = {(0x45, 0x47, 0x4e): ((0x4c, 0x55, 0x60), (0x30, 0x30, 0x38)), (0x30, 0x30, 0x38): ((0x45, 0x47, 0x4e), (0x20, 0x20, 0x24))}

def armazon(im, techo, xs=(), ys=()):
    px = im.load()
    def arista(x, y, luz):
        c = px[x, y]
        if c[3] and c[:3] in LUZ_DE:
            px[x, y] = LUZ_DE[c[:3]][0 if luz else 1] + (255,)
    for y in ys:                                                    # a lo ancho: luz arriba, sombra debajo
        for x in range(1, im.width - 1):
            arista(x, y, True)
    for x in xs:                                                    # hacia el fondo: luz a la izquierda, sombra a la derecha
        for y in range(2, techo - 1):
            if y in ys or y - 1 in ys: continue
            arista(x, y, True); arista(x + 1, y, False)
    return im

# lo que tienen las carpas de verdad (lo pidió el usuario: «en esas carpas pues hay puertas laterales, ventilaciones, agujeros para
# extractor, intractor y eso»), con los siete tonos de la de 150 (en las de KAIA, solo la de sala los lleva en el frente; las otras, en
# la pared del lado, que sale en la vista C): la puerta lateral en el lado de sombra (la cremallera en U, más
# apagada que la del frente), las ventanas de malla de abajo con su solapa enrollada encima, y la boca de abajo del intractor (la
# manga con su cordón) con su tubo de aluminio hasta el intractor, en el suelo. El tubo de extracción sale por la boca del techo
# (lo pinta el juego, kaiacult.gd tubos_ext); la manguera del goteo entra por el canto de su lado, desde su depósito de fuera.
TONO = [(32, 32, 36), (48, 48, 56), (69, 71, 78), (76, 85, 96), (94, 96, 104), (138, 142, 152), (178, 184, 196)]

def pon(px, x, y, t):
    px[x, y] = TONO[t] + (255,)

def puerta_lat(px, x0, x1, y0, y1, luz=False):
    """la puerta lateral: la cremallera en U de x0 a x1 desde y0, abierta por abajo, con el tirador abajo a la izquierda (con luz,
    en la tela de luz: un tono más claro todo)"""
    z, e, t0, t1 = (4, 2, 5, 6) if luz else (2, 1, 4, 5)
    for y in range(y0 + 1, y1 + 1):
        pon(px, x0, y, z); pon(px, x1, y, z)
    for x in range(x0 + 1, x1):
        pon(px, x, y0, z)
    pon(px, x0 + 1, y0 + 1, e); pon(px, x1 - 1, y0 + 1, e)   # las esquinas, redondeadas por dentro
    pon(px, x0, y1 - 2, t0); pon(px, x0, y1 - 1, t1)        # el tirador

def ventana(px, x0, y0, w, h, luz):
    """la ventana de malla de w × h: el marco con velcro, la malla a cuadros y la solapa enrollada encima"""
    marco, a, b = (4, 0, 2) if luz else (2, 0, 1)
    for x in range(x0, x0 + w):
        pon(px, x, y0, marco); pon(px, x, y0 + h - 1, marco)
        pon(px, x, y0 - 1, 5 if (x - x0) % 2 == 0 else 4)   # la solapa, enrollada y atada
    for y in range(y0, y0 + h):
        pon(px, x0, y, marco); pon(px, x0 + w - 1, y, marco)
    for y in range(y0 + 1, y0 + h - 1):
        for x in range(x0 + 1, x0 + w - 1):
            pon(px, x, y, a if (x + y) % 2 else b)

def boca(px, x0, y0, luz):
    """la manga de 4 × 4 (125 mm) con su cordón: el aro y el agujero"""
    aro = 4 if luz else 2
    for x, y in ((1, 0), (2, 0), (0, 1), (3, 1), (0, 2), (3, 2), (1, 3), (2, 3)):
        pon(px, x0 + x, y0 + y, aro)
    for x, y in ((1, 1), (2, 1), (1, 2), (2, 2)):
        pon(px, x0 + x, y0 + y, 0)
    pon(px, x0 + 4, y0 + 2, 5)   # el cordón

def intractor(px, x0, yb, yp, luz):
    """la boca de abajo (x0, yp) y, de ella al suelo (yb), el tubo de aluminio y el intractor en línea: el aire limpio entra por abajo"""
    boca(px, x0, yp, luz)
    for y in range(yp + 4, yb - 3):
        pon(px, x0 + 1, y, 6); pon(px, x0 + 2, y, 5)
    for y in range(yb - 3, yb):                           # el intractor, de pie en el suelo, con su motor
        for x in range(x0, x0 + 4):
            pon(px, x, y, 1)
        pon(px, x0, y, 4); pon(px, x0 + 3, y, 0)
    pon(px, x0 + 1, yb - 2, 5); pon(px, x0 + 2, yb - 2, 5)

def puerta_frente(px, x0, x1, y0, yb):
    """la puerta de entrar en el lado de sombra (la de kcsi): como la de la tela de luz (el dobladillo de arriba, las dos cremalleras
    hasta el suelo y el umbral oscuro), un tono más apagada"""
    pon(px, x0, y0, 2); pon(px, x1, y0, 2)
    for x in range(x0 + 1, x1):
        pon(px, x, y0, 4)
    for y in range(y0 + 1, yb):
        pon(px, x0, y, 4); pon(px, x1, y, 4)
    for x in range(x0, x1 + 1):
        pon(px, x, yb, 0)

def detalles(im, w, frente, tipo):
    """los de cada carpa: frente = la primera fila del frente; la de abajo, im.height - 1"""
    px = im.load()
    yb = im.height - 1                                     # la fila del pie
    # el servicio (la puerta lateral, sus ventanas de malla y la manga del intractor) va en la pared del lado, la de kc_lado, como en
    # la vista C: en 3/4 de frente no se ve. En el frente, solo las puertas de entrar (y, en las de 400, la ventana de entre las dos)
    if tipo == 'si':                                       # la de 200 con el servicio a la izquierda (kcsi): la puerta, en el de sombra
        puerta_frente(px, 18, 28, frente + 3, yb)
    elif tipo == 'mi':                                     # las de 400 con el servicio a la izquierda (kcmi, kcli)
        for x0 in (34, 50):
            puerta_frente(px, x0, x0 + 10, frente + 3, yb)
        ventana(px, 45, yb - 8, 5, 5, False)               # entre las dos
    elif tipo != 's':                                      # las de 400: luz 0-30 (dos puertas), sombra 31-62
        ventana(px, 14, yb - 8, 5, 5, True)                # entre las dos puertas
    return im

def detalles_sala(im, xs):
    """la de sala: dos ventanas y dos intractores en la tela de luz, la puerta lateral pasada la de entrar y, a la derecha, la boca de
    servicio (BOCA_SALA), por la que entra la impulsión del riego y sale el drenaje, por encima del rincón del riego"""
    px = im.load()
    yb = im.height - 1
    for x in (14, 54):
        ventana(px, x, yb - 9, 14, 6, True)
    for x in (34, 74):
        intractor(px, x, yb, yb - 14, True)
    puerta_lat(px, xs + 4, xs + 18, yb - 32, yb - 1)
    bx, by = BOCA_SALA
    for y in range(by, by + 6):                            # la boca de servicio: la manga ancha con su aro
        for x in range(bx, bx + 8):
            borde = y in (by, by + 5) or x in (bx, bx + 7)
            if borde and (x, y) not in ((bx, by), (bx + 7, by), (bx, by + 5), (bx + 7, by + 5)):
                pon(px, x, y, 4)
            elif not borde:
                pon(px, x, y, 0)
    pon(px, bx + 8, by + 3, 5)                              # el cordón
    return im

# la boca de servicio de la de sala, en el sprite (x, y de su esquina; la de kaiacult.gd KC_BOCA): baja, a medio metro, justo encima
# del tubo de entrada del depósito de recogida, que está fuera con el tanque y el programador (kaia_cult.py, f2.fuera); el drenaje cae
# por su parte de abajo y la impulsión entra por su lado (kaiacult.gd red_fuera)
BOCA_SALA = (176, 100)

def en_celda(im, w, h):
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    out.paste(im, (0, h - im.height), im)
    return out

def guarda(im, asset, spr):
    d = os.path.join(os.environ['SALE'], asset, spr, 'unica') if os.environ.get('SALE') else P('art', 'crudo', asset, spr, 'unica')
    os.makedirs(d, exist_ok=True)
    for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
    im.save(os.path.join(d, '00.png'))
    print(asset, spr, im.size, im.getbbox(), len({p for p in im.get_flattened_data() if p[3]}), 'colores')

SOMBRA_SALA = 112             # la de sala: el lado de sombra, pasada la puerta de entrar (con la puerta lateral)
NIVELES = {'kcs': (2, 2), 'kcm': (4, 2), 'kcl': (4, 4)}   # ancho y fondo (m), 2 m de alto

if __name__ == '__main__':
    g = lee('art/procesado/carpas-mapa/carpa-g150-mapa/unica/00.png')
    assert g.size == (24, 40), g.size
    for v in ([] if os.environ.get('SALE') else glob.glob(P('art', 'crudo', 'kaia-carpa', 'kc*'))):   # las de antes (abiertas, kcs-<n>…), fuera
        shutil.rmtree(v)
    for spr, (w, d) in NIVELES.items():
        im = filas(columnas(g, cols_kc(w)), rows(d * 8, 32))
        if d == 4:
            armazon(im, d * 8, ys=(d * 4 - 1,))                          # la de 400 × 400, el travesaño de en medio
        assert im.size == (w * 16, d * 8 + 32), (spr, im.size)
        detalles(im, w, d * 8, spr[2])
        guarda(en_celda(im, 80, 80), 'kaia-carpa', spr)
    # la de 200 × 200 de al lado de la pared de la sala (kaia_cult.py: su depósito, a la izquierda): el servicio —la puerta lateral, la
    # ventana y el intractor— en el lado de su depósito y la puerta de entrar en el de sombra (kaiacult.gd sprite_local)
    im = filas(columnas(g, [0, 1, 2] + [LUZ] * 11 + [11] + estira(12, 22, 16) + [23]), rows(16, 32))
    detalles(im, 2, 16, 'si')
    guarda(en_celda(im, 80, 80), 'kaia-carpa', 'kcsi')
    # y las de 400 con el servicio a la izquierda (kcmi, kcli): el lado del servicio es el que tiene más sitio libre al lado
    # (kaiacult.gd kc_lado), así que cualquiera puede llevarlo a la izquierda; las puertas de entrar, en el de sombra
    for spr, d in (('kcmi', 2), ('kcli', 4)):
        im = filas(columnas(g, [0, 1, 2] + [LUZ] * 27 + [11] + estira(12, 22, 32) + [23]), rows(d * 8, 32))
        if d == 4:
            armazon(im, d * 8, ys=(d * 4 - 1,))
        assert im.size == (64, d * 8 + 32), (spr, im.size)
        detalles(im, 4, d * 8, 'mi')
        guarda(en_celda(im, 80, 80), 'kaia-carpa', spr)
    # la de sala: 13 × 7 casillas, 2,5 m de alto (40 filas) y el techo hasta el fondo de su huella (72); la puerta de 2 m (32 filas)
    # en la casilla 6 (x 96, la de C.puerta en kaia_cult.py), de 14 columnas de tela entre sus cremalleras
    im = filas(columnas(g, cols_sala(208, 97, 14, SOMBRA_SALA)), rows(72, 40, 32))
    armazon(im, 72, ys=(19, 39, 58))
    detalles_sala(im, SOMBRA_SALA)
    assert im.size == (208, 112), im.size
    guarda(im, 'kaia-carpa-sala', 'kcx')
