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

def rueda_lado(L, cx, cy, r, f):   # rueda de perfil: cubierta, llanta, radios en + o en × según el fotograma, buje
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            d = (x - cx) ** 2 + (y - cy) ** 2
            if d <= r * r + r: L.p(x, y, O if d > (r - 1) ** 2 + (r - 1) - 1 else None)
    if r >= 3:
        k = r - 2
        for i in range(1, k + 1):
            for x, y in (((cx + i, cy), (cx - i, cy), (cx, cy + i), (cx, cy - i)) if f == 0 else
                         ((cx + i, cy + i), (cx - i, cy - i), (cx + i, cy - i), (cx - i, cy + i))):
                if (x - cx) ** 2 + (y - cy) ** 2 <= k * k + 1: L.p(x, y, RADIO)
    L.p(cx, cy, ALU)

def rueda_frente(L, x, y0, y1, f):   # rueda vista de frente: una tira de 2 px de goma con el brillo que baja al girar
    for y in range(y0, y1 + 1):
        L.p(x, y, GOMA); L.p(x + 1, y, O)
    L.p(x, y0, O); L.p(x, y1, O)
    L.p(x, y0 + 1 + (f * 2 + 1) % max(1, y1 - y0 - 2), RADIO)

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
NEGRO, NEGRO_L, AZUL, AZUL_S = '#1e2026', '#3a3e48', '#2c5aa0', '#1e3a6a'
def moto(d, f):
    A, D = Lienzo(32, 32), Lienzo(32, 32)
    if d == 'east':
        rueda_lado(A, 7, 27, 3, f); rueda_lado(A, 24, 27, 3, f)
        A.r(6, 21, 12, 4, NEGRO_L); A.hl(6, 17, 21, NEGRO)             # el carenado de atrás
        A.r(9, 19, 8, 2, NEGRO); A.p(5, 22, '#c03028')                  # el asiento y el piloto
        A.r(12, 25, 9, 2, NEGRO); A.hl(12, 20, 25, NEGRO_L)            # la plataforma de los pies
        A.r(20, 17, 4, 9, AZUL); A.vl(20, 17, 25, AZUL_S)              # el escudo
        A.vl(24, 18, 26, GRIS)                                          # la horquilla
        A.p(25, 18, '#f8f4d8')                                          # el faro
        D.hl(19, 22, 15, O); D.hl(20, 22, 14, GOMA); D.p(19, 14, O); D.p(23, 14, O); D.hl(20, 22, 13, O)   # el puño
    elif d == 'south':   # de frente: el escudo azul, el faro y la rueda de delante le tapan las piernas
        rueda_frente(D, 15, 25, 30, f)
        D.r(12, 18, 8, 8, AZUL); D.vl(12, 18, 25, AZUL_S); D.vl(19, 18, 25, AZUL_S); D.hl(12, 19, 17, O)
        D.r(14, 20, 4, 2, '#f8f4d8')
        manillar(D, 17, 8, 23)
        A.r(13, 22, 6, 6, NEGRO_L)                                      # el carenado de atrás asoma por los lados
    else:   # north: el carenado de atrás con el piloto y la rueda, delante; el manillar, detrás
        manillar(A, 17, 8, 23)
        rueda_frente(D, 15, 26, 30, f)
        D.r(12, 20, 8, 6, NEGRO_L); D.hl(12, 19, 20, NEGRO); D.r(14, 22, 4, 2, '#c03028'); D.hl(12, 19, 26, O)
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

def coche(k, d, f):
    A, D, B = Lienzo(32, 32), Lienzo(32, 32), Lienzo(32, 32)
    C, CS, CL = PINTURA[k]
    techo = k != 'deportivo'
    vid = []
    if d == 'east':
        top = {}   # la línea de arriba de la carrocería por columna (capó, cintura y maletero)
        for x in range(1, 31):
            top[x] = 22 if x <= 7 else (23 if x <= 23 else 21 + max(0, x - 27))
        if k == 'deportivo':
            for x in range(1, 31): top[x] = 23 if 6 <= x <= 22 else 22 + (x > 27)
        for x in range(1, 31):
            for y in range(top[x], 29):
                B.p(x, y, CS if y >= 26 else C)
            B.p(x, top[x], CL)
        if techo:
            for y in range(9, 23):   # el montante de atrás (inclinado) y el parabrisas (más inclinado)
                xa = 8 + (22 - y) // 6
                xb = 23 - (22 - y) // 4
                B.p(xa, y, C); B.p(xa + 1, y, CS); B.p(xb, y, C)
                for x in range(xa + 2, xb):
                    A.p(x, y, INT if y < 15 else INT_L); vid.append((x, y))
            B.hl(9, 21, 8, C); B.hl(10, 20, 7, CL)                    # el techo
        else:
            for y in range(17, 23):                                    # el parabrisas bajo, inclinado
                B.p(22 - (22 - y) // 2, y, '#2a2d34')
                for x in range(21 - (22 - y) // 2, 23 - (22 - y) // 2): vid.append((x, y))
            A.r(6, 16, 3, 7, ASIENTO); A.vl(5, 17, 22, INT)            # el respaldo, detrás de él
            B.r(1, 21, 4, 1, C); B.p(1, 20, CS); B.hl(1, 3, 20, '#202228')   # el alerón
        B.contorno(O)
        _pega(D, B)
        _vidrio(D, B, vid)
        D.p(30, 23, FARO); D.p(1, 23, PILOTO)
        D.hl(12, 14, 25, CS)                                           # la manilla
        rueda_lado(D, 8, 28, 3, f); rueda_lado(D, 24, 28, 3, f)
    else:
        sur = d == 'south'
        x0, x1 = 2, 29
        cin = 23 if techo else 22                                      # la cintura: de aquí abajo, la carrocería le tapa
        for y in range(cin, 29):
            for x in range(x0 + (y < cin + 2), x1 + 1 - (y < cin + 2)):
                B.p(x, y, CS if y >= 26 else C)
        B.hl(x0 + 1, x1 - 1, cin, CL)
        if techo:
            for y in range(9, cin):
                ia = 6 + (cin - y) // 5; ib = 25 - (cin - y) // 5
                B.p(ia, y, C); B.p(ia + 1, y, CS); B.p(ib, y, C); B.p(ib - 1, y, CS)
                for x in range(ia + 2, ib - 1):
                    A.p(x, y, INT if sur else INT_L); vid.append((x, y))
            B.hl(9, 22, 8, C); B.hl(10, 21, 7, CL)
            A.r(9, 12, 14, 9, ASIENTO if not sur else INT_L)           # los respaldos (de espaldas) o el fondo del coche
        else:
            if sur:
                for y in range(20, cin):
                    B.p(6, y, '#2a2d34'); B.p(25, y, '#2a2d34')
                    for x in range(7, 25): vid.append((x, y))
                B.hl(6, 25, 19, '#2a2d34')
                A.r(9, 15, 14, 7, ASIENTO); A.hl(10, 21, 15, INT_L)          # el respaldo, detrás de él
            else:
                A.r(9, 16, 14, 6, ASIENTO)
                B.r(4, 20, 24, 1, '#202228'); B.p(4, 21, '#202228'); B.p(27, 21, '#202228')   # el alerón
        B.contorno(O)
        _pega(D, B)
        _vidrio(D, B, vid)
        if sur:
            for xa in (4, 24):
                D.r(xa, cin + 3, 4, 2, FARO)
            D.r(11, cin + 3, 10, 3, '#2a2d34'); D.hl(11, 20, cin + 4, '#535b6b')   # la rejilla
            D.r(13, 27, 6, 1, '#f0f0e8')                              # la matrícula
        else:
            for xa in (4, 24):
                D.r(xa, cin + 3, 4, 2, PILOTO)
            D.r(13, cin + 4, 6, 2, '#f0f0e8')
        for xa in (3, 26):
            D.r(xa, 28, 3, 3, GOMA); D.hl(xa, xa + 2, 30, O)
            if f: D.p(xa + 1, 29, RADIO)
    return A, D

SUBE = {'patinete': 3, 'bici': 5, 'moto': 6, 'utilitario': -6, 'berlina': -6, 'deportivo': -2}

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
