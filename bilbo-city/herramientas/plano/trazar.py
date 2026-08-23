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

# Lo urbanizado NO es un polígono: es la unión de corredores. Bilbao crece por el fondo
# del valle y trepa por los vallecitos laterales, así que la mancha es ramificada, con
# cuñas de monte metiéndose hasta muy adentro entre barrio y barrio. Con un contorno
# cerrado salía un borrón convexo; con corredores sale la forma de verdad.
#
# Cada corredor es una polilínea en celdas y un radio, también en celdas, que puede ir
# cambiando a lo largo: (x, y, radio). El radio se interpola entre puntos, así que un
# brazo puede nacer ancho en el valle y morir estrecho ladera arriba.
CORREDORES = [
    # el fondo del valle, de Bolueta (este) a Zorrotza y Erandio (oeste), siguiendo la ría
    [(111,41,13),(101,38,14),(92,34,15),(84,31,15),(75,28,14),(65,23,13),
     (58,19,13),(52,18,13),(45,19,13),(40,22,13),(34,23,12),(26,21,11),
     (18,15,10),(10,8,8),(4,3,6)],
    # Deusto: San Pedro, Ibarrekolanda, Arangoiti y San Ignacio, margen derecha
    [(38,20,9),(30,15,10),(23,12,9),(16,9,8),(10,7,6)],
    # Matiko, Ciudad Jardín y Uribarri, trepando a Artxanda
    [(66,17,9),(64,11,8),(62,6,6),(60,2,4)],
    # Zurbaran-Arabella y Begoña, ladera arriba desde el Arenal
    [(78,20,8),(82,15,8),(84,10,6)],
    # Txurdinaga y Otxarkoaga, el vallecito del noreste
    [(88,24,8),(95,21,9),(101,16,9),(105,11,8),(108,7,5)],
    # Santutxu, Solokoetxe, Atxuri y Bolueta, la margen derecha aguas arriba
    [(80,28,8),(86,31,9),(91,34,9),(97,37,8),(103,40,6)],
    # Casco Viejo, Bilbao la Vieja, Miribilla, San Adrián y La Peña, hacia el sureste
    [(72,28,8),(72,35,9),(74,42,10),(78,48,9),(82,54,7)],
    # Rekalde: Ametzola, Iralabarri, Errekaldeberri y Larraskitu, el valle del sur
    [(56,32,10),(55,39,11),(58,46,11),(58,53,10),(56,60,7)],
    # Basurtu, Altamira y Masustegi, al suroeste
    [(46,30,10),(41,34,11),(34,39,10),(28,44,8)],
    # Olabeaga y Zorrotza, ría abajo por la margen izquierda
    [(32,32,9),(24,32,9),(16,31,8),(10,33,6)],
]

def enCiudad(px, py):
    """Cae dentro de algún corredor. El radio se interpola a lo largo de la polilínea."""
    for c in CORREDORES:
        for i in range(len(c)-1):
            x1,y1,r1 = c[i]; x2,y2,r2 = c[i+1]
            dx,dy = x2-x1, y2-y1
            L2 = dx*dx + dy*dy
            t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px-x1)*dx + (py-y1)*dy) / L2))
            qx,qy = x1+dx*t, y1+dy*t
            if math.hypot(px-qx, py-qy) <= r1 + (r2-r1)*t: return True
    return False

# ── Tabla de barrios ────────────────────────────────────────────────────────────────
# sp = separación entre calles a lo largo · spy = a lo ancho · w = ancho de calle
# ang = giro de la trama en grados · curva y onda = cuánto y cada cuánto serpentea
#
# Bilbao no está a escuadra: las calles siguen la ladera y el río, así que cada barrio
# tiene su rumbo. El ancho de calle no baja de 3: con 2, la trama girada deja pasos que
# un peatón cruza y un coche no, y la batería lo caza en la mediana de conducción.
BARRIOS = [
    ('C', 'Casco Viejo',   10, 9,  3, 1, 2, 12, 3, 11, 'denso',      '#6b4a2e'),
    # Abando es el Ensanche: retícula cerrada, manzanas casi cuadradas y sin curvatura.
    # Es el único barrio de Bilbao trazado a tiralíneas y tiene que notarse de lejos.
    ('A', 'Abando',        20, 19, 3, 5, 3, 31, 0, 40, 'senorial',   '#4a4f5c'),
    ('I', 'Indautxu',      19, 18, 3, 2, 6, 30, 1, 34, 'senorial',   '#55505f'),
    ('X', 'Abandoibarra',  25, 22, 3, 7, 1, 20, 2, 40, 'abierto',    '#5f6b74'),
    ('D', 'Deusto',        19, 12, 3, 3, 5,  8, 4, 30, 'bloques',    '#4e5a52'),
    ('Z', 'Zorrotzaurre',  20, 16, 3, 2, 2, 14, 2, 30, 'industrial', '#6b5f45'),
    ('O', 'Olabeaga',      26, 20, 3, 6, 4, 40, 5, 26, 'industrial', '#5a5340'),
    ('S', 'Santutxu',      13, 20, 3, 4, 1, 55, 6, 20, 'bloques',    '#5c4a3a'),
    ('G', 'Begoña',        17, 12, 3, 6, 7, 65, 7, 18, 'bloques',    '#57505a'),
    ('U', 'Uribarri',      13, 22, 3, 0, 3, 48, 6, 20, 'bloques',    '#4f5a63'),
    ('T', 'Txurdinaga',    19, 15, 3, 2, 5, 35, 8, 22, 'bloques',    '#4d5750'),
    ('M', 'Miribilla',     17, 19, 3, 9, 2, 20, 5, 24, 'senorial',   '#525a63'),
    ('B', 'Basurto',       17, 13, 3, 4, 6, 12, 3, 28, 'bloques',    '#4e5548'),
    ('R', 'Rekalde',       12, 10, 3, 7, 4, 40, 5, 18, 'denso',      '#584c46'),
]

def tablaJS():
    f = " {0}:{{n:'{1}',{2}sp:{3},spy:{4},w:{5}, ox:{6}, oy:{7}, ang:{8}, curva:{9}, onda:{10}, estilo:'{11}',{12}tinte:'{13}'}},"
    out = []
    for b in BARRIOS:
        out.append(f.format(b[0], b[1], ' '*max(1, 14-len(b[1])), *b[2:11],
                            ' '*max(1, 13-len(b[10])), b[11]))
    out.append(" P:{n:'Parque',        verde:1, estilo:'parque', tinte:'#46603f'},")
    out.append(" E:{n:'San Mamés',     estadio:1, sp:16,w:3, ox:0, oy:0, estilo:'abierto', tinte:'#4a5f52'},")
    out.append(" F:{n:'Los montes',    verde:1, monte:1, estilo:'monte', tinte:'#3f5a3c'},")
    return 'const ZONAS={\n' + '\n'.join(out) + '\n};'

def tablaCS():
    f = ("        {{'{0}', new Zona{{ Nombre=\"{1}\",{2}Sp={3}, Spy={4}, W={5}, Ox={6}, Oy={7}, "
         "Ang={8}, Curva={9}, Onda={10}, Estilo=\"{11}\",{12}Tinte=Paleta.H(\"{13}\") }}}},")
    out = ['    public static readonly Dictionary<char, Zona> Zonas = new Dictionary<char, Zona> {']
    for b in BARRIOS:
        out.append(f.format(b[0], b[1], ' '*max(1, 15-len(b[1])), *b[2:11],
                            ' '*max(1, 14-len(b[10])), b[11]))
    out.append('        {\'P\', new Zona{ Nombre="Parque",       Verde=true, Estilo="parque", Tinte=Paleta.H("#46603f") }},')
    out.append('        {\'E\', new Zona{ Nombre="San Mamés",    Estadio=true, Sp=16, W=3, Estilo="abierto", Tinte=Paleta.H("#4a5f52") }},')
    out.append('        {\'F\', new Zona{ Nombre="Los montes",   Verde=true, Monte=true, Estilo="monte", Tinte=Paleta.H("#3f5a3c") }},')
    out.append('    };')
    return '\n'.join(out)


# Centro de cada barrio. El peso encoge (<1) o agranda (>1) su reparto: el Casco Viejo
# es pequeño de verdad y Txurdinaga y Rekalde son extensos.
SEMILLAS = [('D',(30, 9)), ('U',(66,11)), ('G',(83,20)), ('T',(99,19)), ('S',(91,34)),
            ('O',(24,33)), ('X',(60,20)), ('C',(71,28)), ('A',(58,23)), ('I',(53,30)),
            ('P',(50,27)), ('E',(46,31)), ('B',(38,35)), ('M',(74,43)), ('R',(57,45))]
PESO = {'C':.85,'P':.5,'E':.55,'X':.75,'O':1.15,'T':1.15,'S':.95,'G':.95,
        'R':1.1,'B':1.05,'D':1.2,'U':1.05,'M':.95}

# Zorrotzaurre va aparte: es la isla entre la ría y el Canal de Deusto, y un reparto
# por cercanía la dejaría a caballo de las dos orillas.
ISLA = [(27,20),(46,19),(48,22),(44,25),(28,25),(25,22)]

# Los parques grandes, uno a uno. En el plano municipal el verde dentro de la ciudad
# pesa tanto como el monte de alrededor, y sin ellos todo sale gris.
PARQUES = [
    [(46,25),(53,25),(54,30),(47,30)],        # Doña Casilda, entre Abando e Indautxu
    [(74,24),(80,24),(80,29),(74,29)],        # Etxebarria, sobre el Casco Viejo
    [(94,15),(102,15),(102,21),(94,21)],      # Europa, en Txurdinaga
    [(54,36),(60,36),(60,41),(54,41)],        # Ametzola
    [(26,13),(33,13),(33,18),(26,18)],        # la campa de Deusto
    [(66,44),(72,44),(72,49),(66,49)],        # el vivero de Miribilla
]

# La ría, en casillas del mapa (la misma polilínea que dibuja el juego). Sirve para que
# ningún barrio salte de orilla: en Bilbao el Casco Viejo está en una margen y el
# Ensanche en la otra, y un reparto por cercanía sin esto los mezcla.
RIA = [(445, 163),
       (404, 154),
       (369, 146),
       (346, 137),
       (326, 125),
       (302, 110),
       (282, 92),
       (262, 80),
       (238, 71),
       (215, 68),
       (196, 72),
       (180, 84),
       (165, 96),
       (148, 102),
       (130, 100),
       (114, 90),
       (96, 84),
       (84, 86),
       (55, 68),
       (35, 45),
       (17, 21),
       (6, 6)]
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
            if not enCiudad(x+.5, y+.5): continue
            # margen: al este del meandro la ría parte la ciudad en dos y cada barrio
            # es de una orilla. Al oeste se dobla sobre sí misma y ahí no aplica.
            orilla = None
            if x*4+2 >= 170:
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

    nuevo, n = re.subn(r"const ZONAS=\{\n(?: .:\{n:.*?\n)+\};", tablaJS(), nuevo, count=1)
    if n != 1: sys.exit('no encontré el bloque ZONAS en %s' % HTML)
    HTML.write_text(nuevo)

    litcs = ('    static readonly string[] ATLAS = {\n'
             + ''.join('        "%s",\n' % ''.join(r) for r in g) + '    };')
    c = CS.read_text()
    nuevo, n = re.subn(r'    static readonly string\[\] ATLAS = \{\n(?:        "[A-Z]+",\n)+    \};',
                       litcs, c, count=1)
    if n != 1: sys.exit('no encontré el bloque ATLAS en %s' % CS)
    nuevo, n = re.subn(r"    public static readonly Dictionary<char, Zona> Zonas = new Dictionary<char, Zona> \{\n(?:        \{'.'.*?\n)+    \};",
                       tablaCS(), nuevo, count=1)
    if n != 1: sys.exit('no encontré el bloque Zonas en %s' % CS)
    CS.write_text(nuevo)
    letras = sorted({c for r in g for c in r})
    print('atlas escrito en el HTML y en Ciudad.cs · %d barrios + monte · %s' % (len(letras)-1, ''.join(letras)))

main()
