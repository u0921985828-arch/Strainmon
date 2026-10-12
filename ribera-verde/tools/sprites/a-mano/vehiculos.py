# python3 -I tools/sprites/a-mano/vehiculos.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# Tanda 3 (1.13): el patinete y la bici del protagonista, dibujados a mano a la escala del personaje (celda personaje, 32 × 32,
# pies en la fila 30, como player/base), en dos capas que el juego pinta alrededor del protagonista (dibujarPJ):
#  · <v>-atras: lo que queda detrás de él (de lado, el cuadro entero; de frente o de espaldas, lo que queda más lejos);
#  · <v>-delante: lo que le tapa (el manillar en las manos, la rueda de delante o la de atrás que mira a la cámara).
# Dos fotogramas por dirección: los radios (y el pedal en la bici) cambian para que las ruedas giren al andar. Oeste = espejo
# del este (frameDe). Al ir montado el protagonista sube SUBE px (sobre la tabla o en el sillín; VEHICULOS.sube en 12c-salon).
#  · patinete: tabla de aluminio con lija negra, ruedas de 200 mm, barra y manillar con puños negros.
#  · bici: urbana de segunda mano, cuadro mostaza, ruedas de radios, sillín y manillar negros, pedal que gira.
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
        rueda_lado(A, 7, 26, 4, f); rueda_lado(A, 24, 26, 4, f)
        bb = (15, 27)
        for (x0, y0, x1, y1), c in ((((7, 26, 15, 27)), MOST_S), (((7, 26, 13, 20)), MOST_S), (((15, 27, 13, 20)), MOST),
                                     (((13, 20, 21, 20)), MOST), (((15, 27, 21, 21)), MOST), (((21, 20, 24, 26)), MOST)):
            linea(A, x0, y0, x1, y1, c)
        A.hl(11, 15, 19, O); A.hl(12, 14, 18, GOMA); A.p(11, 18, O); A.p(15, 18, O); A.hl(12, 14, 17, O)   # el sillín
        A.vl(21, 18, 19, GRIS)
        A.p(bb[0], bb[1], GOMA)
        # la biela y el pedal (del lado de la cámara, delante de la pierna): arriba-delante o abajo-atrás según el fotograma
        px, py = (17, 26) if f == 0 else (13, 28)
        linea(D, bb[0], bb[1], px, py, GRIS); D.hl(px - 1, px + 1, py, O)
        D.hl(19, 22, 18, O); D.hl(20, 22, 17, GOMA); D.p(19, 17, O); D.p(23, 17, O); D.hl(20, 22, 16, O)   # el puño
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

SUBE = {'patinete': 3, 'bici': 5}

def escribe(raiz=None):
    raiz = raiz or P('art', 'crudo', 'vehiculos')
    for v, fn in (('patinete', patinete), ('bici', bici)):
        for d in ('south', 'east', 'north'):
            for f in (0, 1):
                for capa, L in zip(('atras', 'delante'), fn(d, f)):
                    o = os.path.join(raiz, v + '-' + capa, d); os.makedirs(o, exist_ok=True)
                    L.im.save(os.path.join(o, '%02d.png' % f))

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
