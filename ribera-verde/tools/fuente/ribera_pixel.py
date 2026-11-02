# Ribera Pixel · la fuente del juego, dibujada a mano y 100 % original. Cuatro estilos.
#   python3 -I tools/fuente/ribera_pixel.py [--salida <dir>]
#
# Lo pidió el usuario: fuentes pixel «que no den problemas de copyright, de las típicas letras de
# Pokémon», «inspírate en alguna más de las que te mandé» y «que tenga Bold, Regular, Cursiva…».
# Ninguna fuente ajena se modifica ni se calca (ver tools/fuente/LICENCIAS-ORIGEN.md): de las siete
# que mandó salieron las proporciones y el aire, y cada glifo está dibujado aquí píxel a píxel.
#
# Rejilla: 10 filas de mayúscula (0-9), altura de x 7 (3-9), descendentes 10-12, 7 px de ancho y
# avance fijo de 8 (monoespaciada, como las de pantalla de texto). El peso dibujado es el REGULAR,
# de trazo 1 px; los otros tres salen de él por código, que es lo que mantiene la familia coherente:
#   · Bold          cada píxel se engorda 1 px a la derecha (trazo 2, el peso de las VGA).
#   · Italic        el glifo se corre en diagonal por bandas de 3 filas (oblicua pixel perfect).
#   · Bold Italic   las dos cosas.
# Los acentos, la diéresis y la virgulilla se pegan por código sobre la letra (ACENTOS, VOCALES).
#
# Sale, en godot/fuentes/: RiberaPixel.ttf, -Bold.ttf, -Italic.ttf y -BoldItalic.ttf (cada píxel es
# un cuadrado exacto de la rejilla: a un tamaño múltiplo de 16 px no hay ni medio píxel de antialias)
# y la muestra en tools/fuente/muestra-ribera-pixel.png.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glifos_may import MAY       # noqa: E402
from glifos_min import MIN       # noqa: E402
from glifos_sig import CIF, SIG  # noqa: E402

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
P = lambda *a: os.path.join(RAIZ, *a)   # noqa: E731

ALTO = 10         # filas de la mayúscula
DESC = 3          # filas de descendente
ANCHO = 7         # ancho de la celda dibujada
MONO = 8          # avance fijo
BANDA = 3         # filas por escalón de la cursiva
NOMBRE = 'Ribera Pixel'
U = 60            # unidades de la fuente por píxel de la rejilla

ACENTOS = {
    'agudo': ('..#', '.#.'),
    'dieresis': ('#.#', '...'),
    'tilde': ('.##..#', '#..##.'),
}
VOCALES = {
    'Á': ('A', 'agudo'), 'É': ('E', 'agudo'), 'Í': ('I', 'agudo'), 'Ó': ('O', 'agudo'), 'Ú': ('U', 'agudo'),
    'Ü': ('U', 'dieresis'),
    'á': ('a', 'agudo'), 'é': ('e', 'agudo'), 'í': ('i', 'agudo'), 'ó': ('o', 'agudo'), 'ú': ('u', 'agudo'),
    'ü': ('u', 'dieresis'),
    'Ñ': ('N', 'tilde'), 'ñ': ('n', 'tilde'),
}
ESTILOS = {   # archivo: (nombre del estilo, engorda, inclina)
    'RiberaPixel.ttf': ('Regular', False, False),
    'RiberaPixel-Bold.ttf': ('Bold', True, False),
    'RiberaPixel-Italic.ttf': ('Italic', False, True),
    'RiberaPixel-BoldItalic.ttf': ('Bold Italic', True, True),
}


def tinta(ch):
    return ch not in '. '


def filas(g):
    """las filas del glifo, todas del ancho de la celda"""
    w = max(ANCHO, max(len(f) for f in g))
    return [f.ljust(w, '.') for f in g]


def engorda(f):
    """Bold: cada píxel se extiende 1 px a la derecha (dilatación horizontal)"""
    w = len(f[0])
    out = []
    for r in f:
        fila = ['.'] * (w + 1)
        for i, ch in enumerate(r):
            if tinta(ch):
                fila[i] = fila[i + 1] = '#'
        out.append(''.join(fila))
    return out


def inclina(f, base):
    """Italic: cada banda de BANDA filas se corre 1 px según sube.

    `base` es la fila de la línea de base dentro del glifo: el corrimiento es 0 ahí y crece hacia
    arriba, así que la letra se apoya en su sitio y solo se tumba; los descendentes quedan detrás.
    """
    n = len(f)
    w = len(f[0])
    corre = [max(0, (base - j + BANDA - 1) // BANDA) for j in range(n)]
    extra = max(corre) if corre else 0
    out = []
    for j, r in enumerate(f):
        fila = ['.'] * (w + extra)
        for i, ch in enumerate(r):
            if tinta(ch):
                fila[i + corre[j]] = '#'
        out.append(''.join(fila))
    return out


def con_acento(base, tipo):
    """la letra con su acento encima, centrado sobre su tinta (la virgulilla, sobre la celda)"""
    f = filas(base)
    w = len(f[0])
    ac = ACENTOS[tipo]
    if tipo == 'tilde':
        c = w // 2
    else:
        col = [i for i in range(w) if any(tinta(r[i]) for r in f)]
        c = (col[0] + col[-1]) // 2 if col else w // 2
    out = []
    for r in ac:
        fila = ['.'] * w
        for i, ch in enumerate(r):
            x = c - len(r) // 2 + i
            if tinta(ch) and 0 <= x < w:
                fila[x] = '#'
        out.append(''.join(fila))
    cuerpo = list(f)
    if base is MIN.get('i') or base is MIN.get('j'):   # la i y la j pierden el punto con acento
        cuerpo[0] = '.' * w
    return tuple(out + cuerpo)


def mapa(bold=False, italic=False):
    """carácter → (filas que sube el dibujo, filas). La línea de base va bajo la fila ALTO−1."""
    crudo = {}
    for d in (MAY, MIN, CIF, SIG):
        for k, v in d.items():
            crudo[k] = (0, filas(v))
    for k, (b, t) in VOCALES.items():
        base = MAY.get(b) or MIN.get(b) or CIF.get(b)
        crudo[k] = (-len(ACENTOS[t]), filas(con_acento(base, t)))
    g = {}
    for k, (dy, f) in crudo.items():
        if bold:
            f = engorda(f)
        if italic:
            f = inclina(f, ALTO - 1 - dy)
        g[k] = (dy, f)
    return g


def png(g, texto, u=1):
    """rasteriza una línea de texto (para la muestra y el QA)"""
    from PIL import Image
    alto = ALTO + DESC + 5
    im = Image.new('RGBA', (max(len(texto), 1) * MONO * u + 4 * u, alto * u), (0, 0, 0, 0))
    px = im.load()
    for n, c in enumerate(texto):
        if c not in g:
            c = '?'
        dy, f = g[c]
        x0 = n * MONO
        for j, fila in enumerate(f):
            for i, ch in enumerate(fila):
                if not tinta(ch):
                    continue
                for a in range(u):
                    for b in range(u):
                        xx, yy = (x0 + i) * u + a, (j + 3 + dy) * u + b
                        if 0 <= xx < im.width and 0 <= yy < im.height:
                            px[xx, yy] = (235, 235, 230, 255)
    return im


def ttf(g, destino, estilo):
    """escribe el TTF: cada píxel, un cuadrado exacto de U unidades"""
    from fontTools.fontBuilder import FontBuilder
    from fontTools.pens.ttGlyphPen import TTGlyphPen
    orden = ['.notdef', '.null', 'space']
    glifos, anchos, cmap = {}, {}, {}
    pen = TTGlyphPen(None)
    pen.moveTo((0, 0)); pen.lineTo((0, U * ALTO)); pen.lineTo((U * 6, U * ALTO)); pen.lineTo((U * 6, 0))
    pen.closePath()
    glifos['.notdef'] = pen.glyph()
    anchos['.notdef'] = (U * MONO, 0)
    glifos['.null'] = TTGlyphPen(None).glyph()
    anchos['.null'] = (0, 0)
    glifos['space'] = TTGlyphPen(None).glyph()
    anchos['space'] = (U * MONO, 0)
    cmap[0x20] = 'space'
    for c in sorted(g, key=ord):
        if c == ' ':
            continue
        dy, f = g[c]
        n = 'uni%04X' % ord(c)
        p = TTGlyphPen(None)
        for j, fila in enumerate(f):
            i = 0
            while i < len(fila):
                if not tinta(fila[i]):
                    i += 1
                    continue
                k = i
                while k < len(fila) and tinta(fila[k]):   # un contorno por tramo seguido
                    k += 1
                y1 = (ALTO - (j + dy)) * U
                p.moveTo((i * U, y1 - U)); p.lineTo((i * U, y1))
                p.lineTo((k * U, y1)); p.lineTo((k * U, y1 - U))
                p.closePath()
                i = k
        glifos[n] = p.glyph()
        anchos[n] = (U * MONO, 0)
        cmap[ord(c)] = n
        orden.append(n)
    fb = FontBuilder(U * 16, isTTF=True)
    fb.setupGlyphOrder(orden)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glifos)
    fb.setupHorizontalMetrics(anchos)
    fb.setupHorizontalHeader(ascent=U * 12, descent=-U * 4)
    fb.setupNameTable({
        'familyName': NOMBRE, 'styleName': estilo,
        'uniqueFontIdentifier': '%s %s 1.0' % (NOMBRE, estilo),
        'fullName': ('%s %s' % (NOMBRE, '' if estilo == 'Regular' else estilo)).strip(),
        'psName': 'RiberaPixel-' + estilo.replace(' ', ''), 'version': 'Version 1.0',
        'copyright': 'Copyright WolfCade. Dibujada a mano para Landrace Hunters.',
        'designer': 'WolfCade',
        'licenseDescription': 'Fuente original de WolfCade, dibujada pixel a pixel para Landrace Hunters. '
                              'Uso libre dentro del juego y de sus materiales.',
    })
    cursiva = 'Italic' in estilo
    negrita = 'Bold' in estilo
    fb.setupOS2(sTypoAscender=U * 12, sTypoDescender=-U * 4, usWinAscent=U * 14, usWinDescent=U * 4,
                sxHeight=U * 7, sCapHeight=U * ALTO, fsType=0,
                usWeightClass=700 if negrita else 400,
                fsSelection=(1 if cursiva else 0) | (32 if negrita else 0) |
                            (64 if estilo == 'Regular' else 0))
    fb.setupPost(isFixedPitch=1, italicAngle=-14.0 if cursiva else 0.0)
    fb.font['head'].macStyle = (1 if negrita else 0) | (2 if cursiva else 0)
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    fb.save(destino)
    return destino


LINEAS = ['LANDRACE HUNTERS', 'Cosecha la Haze: 27,5 % · 1.200 €',
          'ñÑ áéíóú ü ¿? ¡! «» ▲▼◀▶ ★ ≈ → 0123456789',
          'El zorro ágil brincó sobre el perro, ¿eh?']


def main(argv):
    dest = P('godot', 'fuentes')
    if '--salida' in argv:
        dest = argv[argv.index('--salida') + 1]
    mapas = {}
    for arch, (estilo, b, i) in ESTILOS.items():
        g = mapa(b, i)
        mapas[estilo] = g
        print('%s %s: %d glifos → %s' % (NOMBRE, estilo, len(g), ttf(g, os.path.join(dest, arch), estilo)))
    from PIL import Image
    ims = []
    for estilo in ('Regular', 'Bold', 'Italic', 'Bold Italic'):
        ims.append(png(mapas[estilo], LINEAS[1], 3))
    for t in (LINEAS[0], LINEAS[2], LINEAS[3]):
        ims.append(png(mapas['Regular'], t, 3))
    W = max(i.width for i in ims) + 16
    H = sum(i.height for i in ims) + 6 * len(ims)
    hoja = Image.new('RGBA', (W, H), (24, 24, 30, 255))
    y = 4
    for i in ims:
        hoja.alpha_composite(i, (8, y))
        y += i.height + 6
    m = (P('tools', 'fuente', 'muestra-ribera-pixel.png') if dest == P('godot', 'fuentes')
         else os.path.join(dest, 'muestra-ribera-pixel.png'))
    hoja.save(m)
    print('muestra: %s' % m)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
