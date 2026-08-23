#!/usr/bin/env python3
"""Traza el atlas de barrios de Bilbao y lo escribe dentro del prototipo HTML.

El atlas no se escribe a mano: se declara la mancha urbana del plano municipal y
dónde cae el centro de cada barrio, y de ahí sale la rejilla de 40x40 celdas. Así
mover un barrio es mover un punto, no reescribir cuarenta líneas de letras.

    python3 herramientas/plano/trazar.py          # reescribe el ATLAS del HTML
    python3 herramientas/plano/trazar.py --ver    # solo lo imprime, no toca nada

Después hay que mirar el plano:  node herramientas/html/plano.js
"""
import math, re, sys, pathlib

NX, NY = 112, 72            # celdas del atlas (mapa 448x288, celda de 4 casillas)
RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Ciudad' / 'Ciudad.cs'

# Contorno de lo urbanizado, en celdas. Bilbao es un valle largo y estrecho tumbado de
# este a oeste: la mancha sigue la ría y se mete por los vallecitos laterales —
# Txurdinaga al noreste, Rekalde al sur, Zorrotza al oeste. Por eso el mapa es
# rectangular: en un cuadrado el valle no cabe sin deformarlo.
VALLE = [(80,0),(96,2),(106,8),(110,18),(108,28),(100,30),(104,38),(106,48),(102,58),
         (94,66),(86,70),(78,66),(72,58),(66,68),(58,70),(52,62),(44,66),(36,68),
         (28,62),(22,66),(12,68),(4,62),(2,50),(10,44),(8,38),(14,34),(8,28),
         (12,22),(22,18),(24,10),(34,6),(42,12),(52,8),(66,4)]

# Centro de cada barrio. El peso encoge (<1) o agranda (>1) su reparto: el Casco Viejo
# es pequeño de verdad y Txurdinaga y Rekalde son extensos.
SEMILLAS = [('D',(34,18)), ('U',(66,18)), ('G',(82,22)), ('T',(96,12)), ('S',(92,30)),
            ('O',(18,52)), ('X',(62,34)), ('C',(90,38)), ('A',(74,40)), ('I',(56,44)),
            ('P',(50,42)), ('E',(44,48)), ('B',(36,54)), ('M',(86,50)), ('R',(66,56))]
PESO = {'C':.85,'P':.5,'E':.55,'X':.75,'O':1.15,'T':1.15,'S':.95,'G':.95,
        'R':1.1,'B':1.05,'D':1.2,'U':1.05,'M':.95}

# Zorrotzaurre va aparte: es la isla entre la ría y el Canal de Deusto, y un reparto
# por cercanía la dejaría a caballo de las dos orillas.
ISLA = [(12,38),(32,36),(34,40),(30,46),(14,46),(10,42)]

# Los parques grandes, uno a uno. En el plano municipal el verde dentro de la ciudad
# pesa tanto como el monte de alrededor, y sin ellos todo sale gris.
PARQUES = [
    [(46,40),(54,40),(56,46),(48,46)],        # Doña Casilda
    [(86,30),(94,30),(94,36),(86,36)],        # Etxebarria, sobre el Casco Viejo
    [(94,16),(104,16),(104,24),(94,24)],          # Europa, en Txurdinaga
    [(56,52),(64,52),(64,58),(56,58)],        # Ametzola
    [(26,22),(34,22),(34,28),(26,28)],        # Deusto, la campa de la universidad
]

# La ría, en casillas del mapa (la misma polilínea que dibuja el juego). Sirve para que
# ningún barrio salte de orilla: en Bilbao el Casco Viejo está en una margen y el
# Ensanche en la otra, y un reparto por cercanía sin esto los mezcla.
RIA = [(446,152),(424,160),(404,168),(384,164),(364,152),(344,140),(324,128),(300,120),
       (276,116),(252,116),(228,120),(204,128),(180,140),(156,156),(132,172),(108,184),
       (84,184),(64,172),(48,152),(32,128),(16,104),(0,88)]
NORTE = set('DUGTS')          # margen derecha, la de Deusto y Begoña
SUR    = set('XCAIPEBMR')     # margen izquierda, la del Ensanche
def riaEnX(mx):
    """Y de la ría a esa X. Solo vale en el tramo este-oeste, que es monótono."""
    for i in range(len(RIA)-1):
        (x1,y1),(x2,y2) = RIA[i], RIA[i+1]
        if x2 <= mx <= x1: return y1 + (y2-y1)*(mx-x1)/(x2-x1)
    return None

def dentro(px, py, poly):
    d = False; n = len(poly)
    for i in range(n):
        x1,y1 = poly[i]; x2,y2 = poly[(i+1) % n]
        if (y1 > py) != (y2 > py) and px < (x2-x1)*(py-y1)/(y2-y1)+x1: d = not d
    return d

def trazar():
    g = [['F']*NX for _ in range(NY)]
    for y in range(NY):
        for x in range(NX):
            if not dentro(x+.5, y+.5, VALLE): continue
            # margen: al este del meandro la ría parte la ciudad en dos y cada barrio
            # es de una orilla. Al oeste se dobla sobre sí misma y ahí no aplica.
            orilla = None
            if x*4+2 >= 152:
                ry = riaEnX(x*4+2)
                if ry is not None: orilla = NORTE if y*4+2 < ry else SUR
            mejor, md = None, 1e9
            for ch,(sx,sy) in SEMILLAS:
                if orilla is not None and ch not in orilla: continue
                d = math.hypot(x-sx, y-sy) / PESO.get(ch, 1.0)
                if d < md: md, mejor = d, ch
            if mejor: g[y][x] = mejor
    for y in range(NY):
        for x in range(NX):
            if dentro(x+.5, y+.5, ISLA): g[y][x] = 'Z'
    for poly in PARQUES:
        for y in range(NY):
            for x in range(NX):
                if g[y][x] != 'F' and dentro(x+.5, y+.5, poly): g[y][x] = 'P'
    return g

def main():
    g = trazar()
    lit = 'const ATLAS=[\n' + ''.join(" '%s',\n" % ''.join(r) for r in g) + '];'
    if '--ver' in sys.argv:
        print(lit); return
    # Los dos ficheros se escriben aquí para que no puedan divergir: el atlas es el
    # mismo dato en JS y en C#, y mantenerlo a mano por duplicado acaba mal.
    s = HTML.read_text()
    nuevo, n = re.subn(r"const ATLAS=\[\n(?: '[A-Z]+',\n)+\];", lit, s, count=1)
    if n != 1: sys.exit('no encontré el bloque ATLAS en %s' % HTML)
    HTML.write_text(nuevo)

    litcs = ('    static readonly string[] ATLAS = {\n'
             + ''.join('        "%s",\n' % ''.join(r) for r in g) + '    };')
    c = CS.read_text()
    nuevo, n = re.subn(r'    static readonly string\[\] ATLAS = \{\n(?:        "[A-Z]+",\n)+    \};',
                       litcs, c, count=1)
    if n != 1: sys.exit('no encontré el bloque ATLAS en %s' % CS)
    CS.write_text(nuevo)
    letras = sorted({c for r in g for c in r})
    print('atlas escrito en el HTML y en Ciudad.cs · %d barrios + monte · %s' % (len(letras)-1, ''.join(letras)))

main()
