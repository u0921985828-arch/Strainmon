# python3 -I tools/sprites/a-mano/vehiculos.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# Tanda 3 (1.13): el patinete y la bici del protagonista, dibujados a mano a la escala del personaje (celda personaje, 32 × 32,
# pies en la fila 30, como player/base), en dos capas que el juego pinta alrededor del protagonista (dibujarPJ):
#  · <v>-atras: lo que queda detrás de él (de lado, el cuadro entero; de frente o de espaldas, lo que queda más lejos);
#  · <v>-delante: lo que le tapa (el manillar en las manos, la rueda de delante o la de atrás que mira a la cámara).
# Dos fotogramas por dirección: los radios (y el pedal en la bici) cambian para que las ruedas giren al andar. Oeste = espejo
# del este (frameDe). Al ir montado el protagonista sube SUBE px (sobre la tabla o en el sillín; VEHICULOS.sube en 12c-salon).
#  · patinete: tabla de aluminio con lija negra, ruedas de 200 mm, barra y manillar con puños negros.
#  · bici: urbana de segunda mano, cuadro mostaza, ruedas de radios, sillín y manillar negros, pedal que gira.
#  · moto (1.43, la del concesionario): scooter de 125 cc negro con el escudo azul, plataforma para los pies y faro.
#  · utilitario, berlina y deportivo (1.43): los coches del concesionario, de juguete (ver coche()).
# Sale a art/crudo/vehiculos/<v>-<capa>/<dir>/0N.png (después, node tools/sprites/procesar.js vehiculos --atlas).
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

O = '#180e1e'        # contorno, el del protagonista
GOMA = '#2c333c'     # ruedas, lija, puños
GRIS = '#535b6b'     # barra, sombra del aluminio
ALU = '#9aa3ad'      # aluminio
BRILLO = '#d8dde2'   # reflejo
RADIO = '#6c7482'    # radios y buje
MOST = '#c8902c'     # cuadro de la bici
MOST_S = '#8a5a1c'   # su sombra

def linea(L, x0, y0, x1, y1, c):
    dx, dy = abs(x1 - x0), -abs(y1 - y0); sx = 1 if x0 < x1 else -1; sy = 1 if y0 < y1 else -1; e = dx + dy
    while True:
        L.p(x0, y0, c)
        if x0 == x1 and y0 == y1: return
        e2 = 2 * e
        if e2 >= dy: e += dy; x0 += sx
        if e2 <= dx: e += dx; y0 += sy

LLANTA = '#c4cad2'   # la llanta (1.43.1: las ruedas, con goma gorda y llanta, no solo el aro)

def rueda_lado(L, cx, cy, r, f):   # rueda de perfil: contorno, goma, llanta con el buje y los radios en + o en × según el fotograma
    rl = max(0, r - 2)
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = (x - cx) ** 2 + (y - cy) ** 2
            if d > r * r + r: continue
            if d > (r - 1) ** 2 + (r - 1): L.p(x, y, O)
            elif d > rl * rl + rl: L.p(x, y, GOMA)
            elif (x, y) == (cx, cy): L.p(x, y, GRIS)
            else:
                cruz = x == cx or y == cy
                L.p(x, y, RADIO if cruz == (f == 0) else LLANTA)

def rueda_frente(L, x, y0, y1, f, w=3):   # rueda vista de frente: la banda de goma, con su contorno y el dibujo que baja al girar
    for y in range(y0, y1 + 1):
        for i in range(w):
            L.p(x + i, y, O if i in (0, w - 1) or y in (y0, y1) else GOMA)
    for y in range(y0 + 1 + f, y1, 2):
        for i in range(1, w - 1): L.p(x + i, y, RADIO)

def manillar(L, y, x0=6, x1=25):   # de frente o de espaldas: la barra (fila y) con su brillo encima y un puño de 2 px a cada lado
    L.hl(x0 + 2, x1 - 2, y, GRIS); L.hl(x0 + 2, x1 - 2, y - 1, ALU); L.p((x0 + x1) // 2, y - 1, BRILLO)
    for x in (x0, x0 + 1, x1 - 1, x1): L.p(x, y - 1, GOMA); L.p(x, y, O)

# ---------- patinete (SUBE 3: la tabla, a 3 px del suelo) ----------
def patinete(d, f):
    A, D = Lienzo(32, 32), Lienzo(32, 32)
    if d == 'east':
        rueda_lado(A, 8, 28, 2, f); rueda_lado(A, 23, 28, 2, f)
        A.hl(7, 22, 27, O); A.hl(8, 21, 26, GOMA); A.hl(8, 21, 25, O); A.p(7, 26, O); A.p(22, 26, O)   # la tabla con la lija
        A.p(10, 27, ALU); A.p(16, 27, ALU)
        for y in range(19, 26): A.p(22 - (y < 21), y, ALU if y % 3 else BRILLO); A.p(23 - (y < 21), y, O)   # la barra, algo inclinada
        D.hl(19, 22, 20, O); D.hl(19, 21, 19, GOMA); D.p(18, 19, O); D.p(22, 19, O); D.hl(19, 21, 18, O)   # el puño, en las manos
    elif d == 'south':   # de frente: la tabla se va hacia atrás (arriba) y delante quedan la rueda, la barra y el manillar
        A.r(14, 22, 4, 6, GOMA); A.vl(13, 22, 27, O); A.vl(18, 22, 27, O); A.hl(14, 17, 21, O)
        rueda_frente(D, 15, 26, 30, f)
        D.vl(15, 20, 25, ALU); D.vl(16, 20, 25, GRIS)
        manillar(D, 20)
    else:   # north, de espaldas: el manillar queda detrás de él (asoman los puños) y la tabla y la rueda de atrás, delante
        manillar(A, 20)
        D.r(14, 26, 4, 2, GOMA); D.hl(14, 17, 28, O); D.vl(13, 26, 27, O); D.vl(18, 26, 27, O)
        rueda_frente(D, 15, 28, 30, f)
    return A, D

# ---------- bici (SUBE 5: el sillín, a la altura de la cadera) ----------
def bici(d, f):
    A, D = Lienzo(32, 32), Lienzo(32, 32)
    if d == 'east':
        # corta (1.13): de rueda a rueda, 17 px (8-24), casi una casilla, para no invadir las de al lado
        rueda_lado(A, 11, 27, 3, f); rueda_lado(A, 21, 27, 3, f)
        bb = (15, 28)
        for (x0, y0, x1, y1), c in ((((11, 27, 15, 28)), MOST_S), (((11, 27, 14, 21)), MOST_S), (((15, 28, 14, 21)), MOST),
                                     (((14, 21, 19, 21)), MOST), (((15, 28, 19, 22)), MOST), (((19, 21, 21, 27)), MOST)):
            linea(A, x0, y0, x1, y1, c)
        A.hl(12, 16, 19, O); A.hl(13, 15, 18, GOMA); A.p(12, 18, O); A.p(16, 18, O); A.hl(13, 15, 17, O)   # el sillín
        A.vl(19, 19, 20, GRIS)
        A.p(bb[0], bb[1], GOMA)
        # la biela y el pedal (del lado de la cámara, delante de la pierna): arriba-delante o abajo-atrás según el fotograma
        px, py = (17, 27) if f == 0 else (13, 29)
        linea(D, bb[0], bb[1], px, py, GRIS); D.hl(px - 1, px + 1, py, O)
        D.hl(18, 21, 18, O); D.hl(19, 21, 17, GOMA); D.p(18, 17, O); D.p(22, 17, O); D.hl(19, 21, 16, O)   # el puño
    elif d == 'south':   # de frente: la rueda de delante y la horquilla le tapan las piernas; el manillar, en las manos
        rueda_frente(D, 15, 21, 30, f)
        D.vl(14, 20, 26, MOST); D.vl(17, 20, 26, MOST_S); D.hl(14, 17, 19, MOST)
        manillar(D, 18)
        # la rueda de atrás asoma por debajo, detrás de las piernas
        A.vl(15, 24, 28, GOMA); A.vl(16, 24, 28, O)
    else:   # north: la rueda de atrás con el guardabarros, delante; el manillar, detrás (asoman los puños)
        manillar(A, 18)
        rueda_frente(D, 15, 22, 30, f)
        D.hl(14, 17, 21, MOST); D.p(14, 22, MOST_S); D.p(17, 22, MOST_S); D.hl(14, 17, 20, O)   # el guardabarros
        D.p(13, 21, O); D.p(18, 21, O)
    return A, D

# ---------- moto (1.43, SUBE 6: el asiento del scooter de 125 cc del concesionario, negro con el escudo azul) ----------
NEGRO, NEGRO_L, AZUL, AZUL_S, AZUL_L = '#1e2026', '#3a3e48', '#2c5aa0', '#1e3a6a', '#4a7cc4'
# 1.43.1 (lo pidió el usuario: «montando en la moto parece una bici»): un scooter de juguete, gordito, con las ruedas pequeñas y
# gordas, el culo redondo, el escudo y el piso tapado; él va sentado (VEHICULOS.moto.corta: de la cadera para arriba, sube 3).
def moto(d, f):
    A, D, B = Lienzo(32, 32), Lienzo(32, 32), Lienzo(32, 32)
    if d == 'east':
        for y, x0, x1 in ((19, 6, 13), (20, 5, 14), (21, 4, 15), (22, 4, 15), (23, 4, 16), (24, 5, 20), (25, 6, 20)):
            B.hl(x0, x1, y, NEGRO_L if y < 21 else NEGRO)              # el culo redondo y el piso tapado, hasta el escudo
        for y in range(12, 26):                                         # el escudo, curvo hacia delante
            xa = 18 + (y > 15) + (y > 20); B.hl(xa, xa + 3, y, AZUL); B.p(xa, y, AZUL_S); B.p(xa + 3, y, AZUL_L)
        B.hl(21, 26, 22, AZUL); B.hl(22, 26, 21, AZUL_L)                # el guardabarros de delante
        B.contorno(O)
        A.r(7, 17, 8, 2, NEGRO); A.hl(7, 14, 17, NEGRO_L)               # el asiento, detrás de él
        A.vl(20, 9, 12, GRIS)                                           # la barra del manillar
        _pega(D, B)
        D.p(4, 21, '#d03028'); D.r(22, 15, 2, 2, '#f8f4d8')            # el piloto y el faro
        D.hl(6, 13, 21, '#5a5f6c')                                      # el brillo del culo
        rueda_lado(D, 8, 27, 3, f); rueda_lado(D, 23, 27, 3, f)
        D.hl(19, 22, 10, O); D.hl(20, 22, 9, GOMA); D.p(19, 9, O); D.p(23, 9, O); D.hl(20, 22, 8, O)   # el puño, en las manos
    elif d == 'south':   # de frente: el escudo azul ancho con el faro le tapa las piernas; la rueda de delante, gorda
        for y in range(16, 27):
            m = 5 if y < 18 else 6
            B.hl(16 - m, 15 + m, y, AZUL); B.p(16 - m, y, AZUL_S); B.p(15 + m, y, AZUL_S)
        B.hl(12, 19, 16, AZUL_L)
        B.contorno(O)
        _pega(D, B)
        D.r(14, 19, 4, 3, '#f8f4d8'); D.hl(14, 17, 19, '#fffef0')      # el faro
        rueda_frente(D, 14, 26, 30, f, 4)
        manillar(D, 15, 7, 24)
        D.p(7, 12, GRIS); D.p(24, 12, GRIS); D.r(6, 10, 2, 2, NEGRO_L); D.r(24, 10, 2, 2, NEGRO_L)   # los espejos
        A.r(9, 22, 14, 5, NEGRO_L)                                      # el culo asoma por los lados
    else:   # north: el culo redondo con el piloto y la rueda gorda, delante; el manillar con los espejos, detrás
        manillar(A, 15, 7, 24)
        A.r(6, 10, 2, 2, NEGRO_L); A.r(24, 10, 2, 2, NEGRO_L)
        for y, x0, x1 in ((20, 10, 21), (21, 9, 22), (22, 8, 23), (23, 8, 23), (24, 8, 23), (25, 9, 22), (26, 10, 21)):
            B.hl(x0, x1, y, NEGRO_L if y < 22 else NEGRO)
        B.contorno(O)
        _pega(D, B)
        D.r(13, 23, 6, 2, '#d03028'); D.hl(11, 20, 21, '#5a5f6c')
        rueda_frente(D, 14, 27, 30, f, 4)
    return A, D

# ---------- coches (1.43, el utilitario, la berlina y el superdeportivo del concesionario, para la calle) ----------
# Más bajos que el protagonista de pie, como de juguete; él va sentado (VEHICULOS.sube negativo: baja 6 px) y el juego solo pinta
# sus VEHICULOS.corta filas de arriba (la cabeza y los hombros). Los de techo (utilitario y berlina) lo llevan por encima de la
# cabeza: se le ve por los cristales, que son una trama de puntos claros (sin transparencias) con un par de reflejos; el
# superdeportivo es descapotable (sin techo, con el parabrisas bajo) y se le ve de pecho para arriba. Tres capas en dos:
#  · atras: el interior (oscuro) y el respaldo, detrás de él;
#  · delante: la carrocería con su contorno, el techo y los montantes, los cristales, las luces y las ruedas.
INT, INT_L, ASIENTO = '#23272f', '#343a45', '#4a4f5c'
VIDRIO, REFLEJO = '#b8d4ea', '#eef6fc'
FARO, PILOTO = '#f8f0c0', '#d03028'
PINTURA = {'utilitario': ('#eceef0', '#b8bec6', '#ffffff'), 'berlina': ('#6a7280', '#4a5160', '#9aa2ae'), 'deportivo': ('#d02a2a', '#8e1818', '#ff6a5a')}

def _pega(D, B):
    for y in range(B.h):
        for x in range(B.w):
            c = B.g(x, y)
            if c[3]: D.p(x, y, c)

def _vidrio(D, B, pts):   # el cristal: dos reflejos en diagonal en la esquina de arriba, para que a él se le vea bien la cara
    pts = [q for q in pts if not B.lleno(*q)]
    if not pts: return
    mx = min(x for x, y in pts); my = min(y for x, y in pts); h = max(y for x, y in pts) - my + 1
    for x, y in pts:
        t = x - mx + y - my
        if y - my < max(3, h // 2) and t in (2, 3, 6):
            D.p(x, y, REFLEJO if t != 6 else VIDRIO)
    for x in sorted(set(x for x, y in pts))[::3]:   # el borde de goma del cristal, arriba
        D.p(x, my, VIDRIO)

# 1.43.1 (lo pidió el usuario: «no tan realistas, que son demasiado grandes; un estilo y una escala lógica con el personaje»):
# de juguete, cortos y redondos, con la burbuja de la cabina, los faros redondos y las ruedas gordas con llanta.
#   (x0, x1) la carrocería; (c0, c1) la cabina abajo; el morro y la cola (alto de su línea de arriba)
FORMA = {'utilitario': (5, 26, 8, 21, 20, 19), 'berlina': (3, 28, 8, 20, 20, 20), 'deportivo': (3, 28, 0, 0, 21, 21)}

def coche(k, d, f):
    A, D, B = Lienzo(32, 32), Lienzo(32, 32), Lienzo(32, 32)
    C, CS, CL = PINTURA[k]
    x0, x1, c0, c1, ymorro, ycola = FORMA[k]
    techo = k != 'deportivo'
    cin = 22                                                            # la cintura: de aquí abajo, la carrocería le tapa
    vid = []
    if d == 'east':
        for x in range(x0, x1 + 1):
            top = cin if c0 <= x <= c1 or not techo and x0 + 4 <= x <= x1 - 5 else (ymorro if x > c1 else ycola)
            if not techo: top = cin - (x >= x1 - 5) - (x <= x0 + 3)
            if x in (x0, x1): top += 2
            elif x in (x0 + 1, x1 - 1): top += 1
            for y in range(top, 28):
                B.p(x, y, CS if y >= 26 else C)
            B.p(x, top, CL)
        if techo:
            for y in range(7, cin):                                    # la burbuja: el montante de atrás y el parabrisas, curvos
                h = cin - y
                xa = c0 + (1 if h > 12 else 0) + (1 if h > 14 else 0)
                xb = c1 - (h > 4) - (h > 8) - (h > 11) - (h > 13)
                B.p(xa, y, C); B.p(xb, y, C)
                for x in range(xa + 1, xb):
                    A.p(x, y, INT if y < 14 else INT_L); vid.append((x, y))
            B.hl(c0 + 3, c1 - 5, 6, CL)                                # el techo redondo
        else:
            for y in range(16, cin):                                   # el parabrisas, bajo e inclinado
                xw = 21 - (cin - y) // 2
                B.p(xw, y, '#2a2d34'); vid.append((xw + 1, y))
            A.r(7, 15, 4, 7, ASIENTO); A.vl(6, 16, 21, INT)            # el respaldo, detrás de él
            B.hl(x0, x0 + 4, 18, '#202228'); B.vl(x0 + 2, 19, 20, '#202228')   # el alerón
        for cx in (x0 + 5, x1 - 5):                                    # los pasos de rueda
            for y in range(23, 28):
                for x in range(cx - 4, cx + 5):
                    if (x - cx) ** 2 + (y - 27) ** 2 <= 22: B.p(x, y, INT)
        B.contorno(O)
        _pega(D, B)
        _vidrio(D, B, vid)
        D.r(x1 - 1, cin + 1, 1, 2, FARO); D.r(x0 + 1, cin + 1, 1, 2, PILOTO)
        D.hl(c0 + 4, c0 + 6, cin + 2, CS)                              # la manilla
        rueda_lado(D, x0 + 5, 27, 3, f); rueda_lado(D, x1 - 5, 27, 3, f)
    else:
        sur = d == 'south'
        bx0, bx1 = 5, 26
        for y in range(cin - (0 if techo else 1), 28):
            m = 2 if y == cin - (0 if techo else 1) else 1 if y == cin + 1 - (0 if techo else 1) else 0
            B.hl(bx0 + m, bx1 - m, y, CS if y >= 26 else C)
        B.hl(bx0 + 2, bx1 - 2, cin - (0 if techo else 1), CL)
        if techo:
            for y in range(7, cin):
                h = cin - y
                ia = 7 + (h > 6) + (h > 11) + (h > 14); ib = 24 - (h > 6) - (h > 11) - (h > 14)
                B.p(ia, y, C); B.p(ib, y, C)
                for x in range(ia + 1, ib):
                    A.p(x, y, INT if sur else INT_L); vid.append((x, y))
            B.hl(10, 21, 6, CL)
            A.r(10, 11, 12, 10, ASIENTO if not sur else INT_L)         # los respaldos (de espaldas) o el fondo del coche
        else:
            if sur:
                for y in range(19, cin - 1):
                    B.p(8, y, '#2a2d34'); B.p(23, y, '#2a2d34')
                    for x in range(9, 23): vid.append((x, y))
                B.hl(8, 23, 18, '#2a2d34')
                A.r(10, 14, 12, 7, ASIENTO); A.hl(11, 20, 14, INT_L)   # el respaldo, detrás de él
            else:
                A.r(10, 15, 12, 6, ASIENTO)
                B.hl(5, 26, 18, '#202228'); B.vl(7, 19, 20, '#202228'); B.vl(24, 19, 20, '#202228')   # el alerón
        B.contorno(O)
        _pega(D, B)
        _vidrio(D, B, vid)
        if sur:
            for xa in (7, 22):                                         # los faros redondos
                D.r(xa, cin + 1, 3, 3, FARO); D.p(xa + 1, cin + 1, '#fffef0'); D.p(xa, cin + 1, CS); D.p(xa + 2, cin + 3, CS)
            D.r(12, cin + 3, 8, 2, '#2a2d34'); D.hl(13, 18, cin + 3, '#535b6b')   # la rejilla
        else:
            for xa in (7, 22):
                D.r(xa, cin + 1, 3, 2, PILOTO)
            D.r(13, cin + 2, 6, 2, '#f0f0e8')                          # la matrícula
        for xa in (4, 24):                                             # las ruedas gordas, asomando por abajo
            rueda_frente(D, xa, 26, 30, f, 4)
    return A, D

SUBE = {'patinete': 3, 'bici': 5, 'moto': 3, 'utilitario': -4, 'berlina': -4, 'deportivo': -2}

def escribe(raiz=None):
    raiz = raiz or P('art', 'crudo', 'vehiculos')
    for v, fn in (('patinete', patinete), ('bici', bici), ('moto', moto)) + tuple((k, (lambda k: lambda d, f: coche(k, d, f))(k)) for k in PINTURA):
        for d in ('south', 'east', 'north'):
            for f in (0, 1):
                for capa, L in zip(('atras', 'delante'), fn(d, f)):
                    o = os.path.join(raiz, v + '-' + capa, d); os.makedirs(o, exist_ok=True)
                    L.im.save(os.path.join(o, '%02d.png' % f))

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
