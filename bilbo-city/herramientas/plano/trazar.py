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

NX, NY = 56, 36             # celdas del atlas (mapa 224x144, celda de 4 casillas)
RAIZ = pathlib.Path(__file__).resolve().parents[2]
HTML = RAIZ / 'referencia' / 'bilbo-city.html'
CS   = RAIZ / 'unity' / 'BilboCity' / 'Assets' / 'Scripts' / 'Ciudad' / 'Ciudad.cs'

# Contorno de lo urbanizado, en celdas. Bilbao es un valle largo y estrecho tumbado de
# este a oeste: la mancha sigue la ría y se mete por los vallecitos laterales —
# Txurdinaga al noreste, Rekalde al sur, Zorrotza al oeste. Por eso el mapa es
# rectangular: en un cuadrado el valle no cabe sin deformarlo.
VALLE = [(40,0),(48,1),(53,4),(55,9),(54,14),(50,15),(52,19),(53,24),(51,29),
         (47,33),(43,35),(39,33),(36,29),(33,34),(29,35),(26,31),(22,33),(18,34),
         (14,31),(11,33),(6,34),(2,31),(1,25),(5,22),(4,19),(7,17),(4,14),
         (6,11),(11,9),(12,5),(17,3),(21,6),(26,4),(33,2)]

# Centro de cada barrio. El peso encoge (<1) o agranda (>1) su reparto: el Casco Viejo
# es pequeño de verdad y Txurdinaga y Rekalde son extensos.
SEMILLAS = [('D',(17, 9)), ('U',(33, 9)), ('G',(41,11)), ('T',(48, 6)), ('S',(46,15)),
            ('O',(9,26)), ('X',(31,17)), ('C',(45,19)), ('A',(37,20)), ('I',(28,22)),
            ('P',(25,21)), ('E',(22,24)), ('B',(18,27)), ('M',(43,25)), ('R',(33,28))]
PESO = {'C':.85,'P':.5,'E':.55,'X':.75,'O':1.15,'T':1.15,'S':.95,'G':.95,
        'R':1.1,'B':1.05,'D':1.2,'U':1.05,'M':.95}

# Zorrotzaurre va aparte: es la isla entre la ría y el Canal de Deusto, y un reparto
# por cercanía la dejaría a caballo de las dos orillas.
ISLA = [(6,19),(16,18),(17,20),(15,23),(7,23),(5,21)]

# Los parques grandes, uno a uno. En el plano municipal el verde dentro de la ciudad
# pesa tanto como el monte de alrededor, y sin ellos todo sale gris.
PARQUES = [
    [(23,20),(27,20),(28,23),(24,23)],        # Doña Casilda
    [(43,15),(47,15),(47,18),(43,18)],        # Etxebarria, sobre el Casco Viejo
    [(47,8),(52,8),(52,12),(47,12)],          # Europa, en Txurdinaga
    [(28,26),(32,26),(32,29),(28,29)],        # Ametzola
    [(13,11),(17,11),(17,14),(13,14)],        # Deusto, la campa de la universidad
]

# La ría, en casillas del mapa (la misma polilínea que dibuja el juego). Sirve para que
# ningún barrio salte de orilla: en Bilbao el Casco Viejo está en una margen y el
# Ensanche en la otra, y un reparto por cercanía sin esto los mezcla.
RIA = [(223,76),(212,80),(202,84),(192,82),(182,76),(172,70),(162,64),(150,60),
       (138,58),(126,58),(114,60),(102,64),(90,70),(78,78),(66,86),(54,92),
       (42,92),(32,86),(24,76),(16,64),(8,52),(0,44)]
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
            if x*4+2 >= 76:
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
