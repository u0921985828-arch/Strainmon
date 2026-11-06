# Ribera Pixel · la fuente del juego, dibujada a mano y 100 % original.
#   python3 -I tools/fuente/ribera_pixel.py [--salida <dir>]
# Lo pidió el usuario: fuentes pixel «que no den problemas de copyright, de las típicas letras de una franquicia comercial».
# Ninguna fuente ajena se modifica ni se calca: las siete que mandó solo sirvieron para ver qué le gusta
# (alto de caja, grosor, aire). Cada glifo está dibujado píxel a píxel en glifos_may/min/sig.py.
#
# Rejilla: caja de 7 filas para la mayúscula (0-6), altura de x 5 (2-6), descendentes 7-8. Trazo de 1 px,
# anchos variables (es proporcional, no monoespaciada) y 1 px de separación entre letras.
# Los acentos se pegan por código sobre la vocal (ACENTOS), así que todos caen a la misma altura.
#
# Dos pesos (lo pidió el usuario: «con tener la regular y la negrita, vale… lo de la cursiva igual lo
# quitamos»; el juego no usa cursiva). Se dibuja el REGULAR y la negrita sale de él por código, que es
# lo que mantiene la familia coherente:
#   · Bold          cada píxel se engorda 1 px a la derecha (trazo 2; el avance crece con el glifo).
# `inclina` se queda en el archivo por si algún día hace falta una cursiva: no se usa.
#
# Sale: arte/fuente/RiberaPixel.ttf (bitmap trazado a contornos cuadrados; cada píxel es un cuadrado
# exacto de la rejilla, así que al tamaño múltiplo de 10 px no hay ni medio píxel de antialias)
# y arte/fuente/muestra.png.
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from glifos_may import MAY       # noqa: E402
from glifos_min import MIN       # noqa: E402
from glifos_sig import CIF, SIG  # noqa: E402

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
P = lambda *a: os.path.join(RAIZ, *a)   # noqa: E731

ALTO = 7          # filas de la mayúscula
DESC = 2          # filas de descendente
SEP = 1           # píxeles entre letras
ESPACIO = 4       # el ancho del espacio (con 3 el número se pegaba a la palabra: «Agua70 %»)
BANDA = 3         # filas por escalón de la cursiva
NOMBRE = 'Ribera Pixel'
ESTILOS = {   # archivo: (nombre del estilo, engorda, inclina)
    'RiberaPixel.ttf': ('Regular', False, False),
    'RiberaPixel-Bold.ttf': ('Bold', True, False),
}

# tilde, diéresis y virgulilla, pegadas encima de la letra base (fila −2 sobre su caja)
ACENTOS = {
    'agudo': ('..x.', '.x..'),
    'dieresis': ('x.x.', '....'),
    'tilde': ('.xx.x.', 'x..x..'),
}
VOCALES = {
    'Á': ('A', 'agudo'), 'É': ('E', 'agudo'), 'Í': ('I', 'agudo'), 'Ó': ('O', 'agudo'), 'Ú': ('U', 'agudo'),
    'Ü': ('U', 'dieresis'),
    'á': ('a', 'agudo'), 'é': ('e', 'agudo'), 'í': ('i', 'agudo'), 'ó': ('o', 'agudo'), 'ú': ('u', 'agudo'),
    'ü': ('u', 'dieresis'),
    'Ñ': ('N', 'tilde'), 'ñ': ('n', 'tilde'),
}


def filas(g):
    """las filas del glifo como lista de cadenas, todas del mismo ancho"""
    w = max(len(f) for f in g)
    return [f.ljust(w, '.') for f in g]


def recorta(f, tipo='cuerpo'):
    """quita las columnas vacías de los lados; devuelve (filas, ancho).

    Las cifras no se recortan: su relleno es lo que las centra en la caja tabular.
    """
    if tipo == 'cifra':
        return f, len(f[0])
    cols = [i for i in range(len(f[0])) if any(r[i] == 'x' for r in f)]
    if not cols:
        return f, len(f[0])
    a, b = cols[0], cols[-1] + 1
    return [r[a:b] for r in f], b - a


def con_acento(base, tipo):
    """la vocal con su acento encima: sube el glifo DOS filas y pinta el acento centrado arriba"""
    f = filas(base)
    w = len(f[0])
    ac = ACENTOS[tipo]
    # el acento se centra sobre los píxeles de la primera fila con tinta (el asta de la i, el cuenco de la o)
    if tipo == 'tilde':
        c = w // 2
    else:
        tinta = [i for i in range(w) if any(r[i] == 'x' for r in f)]
        c = (tinta[0] + tinta[-1]) // 2 if tinta else w // 2
    out = []
    for r in ac:
        fila = ['.'] * w
        for i, ch in enumerate(r):
            x = c - len(r) // 2 + i
            if ch == 'x' and 0 <= x < w:
                fila[x] = 'x'
        out.append(''.join(fila))
    # la i y la j pierden su punto cuando llevan acento
    cuerpo = list(f)
    if base is MIN.get('i') or base is MIN.get('j'):
        cuerpo[0] = '.' * w
    return tuple(out + cuerpo)


def engorda(f):
    """Bold: cada píxel se extiende 1 px a la derecha (dilatación horizontal, trazo 2)"""
    w = len(f[0])
    out = []
    for r in f:
        fila = ['.'] * (w + 1)
        for i, ch in enumerate(r):
            if ch == 'x':
                fila[i] = fila[i + 1] = 'x'
        out.append(''.join(fila))
    return out


def inclina(f, base):
    """Italic: cada banda de BANDA filas se corre 1 px según sube.

    `base` es la fila de la línea de base dentro del dibujo: el corrimiento es 0 ahí y crece hacia
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
            if ch == 'x':
                fila[i + corre[j]] = 'x'
        out.append(''.join(fila))
    return out


def tabular(d):
    """las diez cifras, al mismo avance: la más ancha manda y las demás se centran en esa caja.

    Así los precios y las columnas de números cuadran unos debajo de otros («1.200 €» y «150 €»).
    """
    rec = {}
    for k, v in d.items():
        rec[k] = recorta(filas(v))
    w = max(w2 for _, w2 in rec.values())
    out = {}
    for k, (f, w2) in rec.items():
        izq = (w - w2) // 2
        out[k] = tuple('.' * izq + r + '.' * (w - w2 - izq) for r in f)
    return out


def mapa(bold=False, italic=False):
    """carácter → filas, con la línea de base siempre bajo la fila ALTO−1 del cuerpo"""
    g = {}
    for d in (MAY, MIN, SIG):
        for k, v in d.items():
            g[k] = ('cuerpo', filas(v))
    for k, v in tabular(CIF).items():
        g[k] = ('cifra', filas(v))
    for k, (b, t) in VOCALES.items():
        base = MAY.get(b) or MIN.get(b) or CIF.get(b)
        g[k] = ('alto', filas(con_acento(base, t)))
    if not (bold or italic):
        return g
    for k, (tipo, f) in list(g.items()):
        if bold:
            f = engorda(f)
        if italic:
            f = inclina(f, (ALTO - 1) + (0 if tipo == 'cuerpo' else 2))
        g[k] = (tipo, f)
    return g


def avance(f, w):
    return w + SEP if w else ESPACIO


def png(g, texto, u=1):
    """rasteriza una línea de texto en una imagen de Pillow (para la muestra y el QA)"""
    from PIL import Image
    piezas, an = [], 0
    for c in texto:
        if c not in g:
            c = '?'
        tipo, f = g[c]
        rf, w = recorta(f, tipo)
        piezas.append((tipo, rf, w))
        an += avance(rf, w)
    alto = ALTO + DESC + 2
    im = Image.new('RGBA', (max(an, 1) * u, alto * u), (0, 0, 0, 0))
    px = im.load()
    x = 0
    for tipo, f, w in piezas:
        dy = -2 if tipo == 'alto' else 0    # con acento, el cuerpo baja 0 y el acento sube 2 filas
        for j, fila in enumerate(f):
            for i, ch in enumerate(fila):
                if ch != 'x':
                    continue
                for a in range(u):
                    for b in range(u):
                        xx, yy = (x + i) * u + a, (j + 2 + dy) * u + b
                        if 0 <= xx < im.width and 0 <= yy < im.height:
                            px[xx, yy] = (235, 235, 230, 255)
        x += avance(f, w)
    return im


def ttf(g, destino, estilo='Regular'):
    """escribe el TTF: cada píxel, un cuadrado exacto; 1 px = 100 unidades (upm 1000)"""
    from fontTools.fontBuilder import FontBuilder
    from fontTools.pens.ttGlyphPen import TTGlyphPen
    U = 100
    base_fila = ALTO + 1            # la fila de la línea de base dentro de la caja del dibujo
    orden = ['.notdef', '.null', 'space']
    nombres, glifos, anchos, cmap = {}, {}, {}, {}
    pen = TTGlyphPen(None)
    pen.moveTo((0, 0)); pen.lineTo((0, U * 7)); pen.lineTo((U * 4, U * 7)); pen.lineTo((U * 4, 0)); pen.closePath()
    glifos['.notdef'] = pen.glyph()
    anchos['.notdef'] = (U * 5, 0)
    glifos['.null'] = TTGlyphPen(None).glyph()
    anchos['.null'] = (0, 0)
    glifos['space'] = TTGlyphPen(None).glyph()
    anchos['space'] = (U * 3, 0)
    cmap[0x20] = 'space'
    for c in sorted(g, key=ord):
        if c == ' ':
            continue
        tipo, f = g[c]
        rf, w = recorta(f, tipo)
        n = 'uni%04X' % ord(c)
        nombres[c] = n
        dy = -2 if tipo == 'alto' else 0
        p = TTGlyphPen(None)
        for j, fila in enumerate(rf):
            i = 0
            while i < len(fila):
                if fila[i] != 'x':
                    i += 1
                    continue
                k = i
                while k < len(fila) and fila[k] == 'x':   # un contorno por tramo seguido: menos puntos
                    k += 1
                x0, x1 = i * U, k * U
                y1 = (base_fila - (j + dy)) * U
                y0 = y1 - U
                p.moveTo((x0, y0)); p.lineTo((x0, y1)); p.lineTo((x1, y1)); p.lineTo((x1, y0)); p.closePath()
                i = k
        glifos[n] = p.glyph()
        anchos[n] = (avance(rf, w) * U, 0)
        cmap[ord(c)] = n
        orden.append(n)
    fb = FontBuilder(1000, isTTF=True)
    fb.setupGlyphOrder(orden)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glifos)
    fb.setupHorizontalMetrics(anchos)
    # el alto de línea, centrado en la mayúscula (lo pidió el usuario: «todos los textos, centrados»):
    # la caja va de −2 a +9 y la mayúscula, de 0 a 7, así que su centro (3,5) es el de la caja
    fb.setupHorizontalHeader(ascent=U * 9, descent=-U * 2)
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
    fb.setupOS2(sTypoAscender=U * 9, sTypoDescender=-U * 2, usWinAscent=U * 9, usWinDescent=U * 2,
                sxHeight=U * 5, sCapHeight=U * 7, fsType=0,
                usWeightClass=700 if negrita else 400,
                fsSelection=(1 if cursiva else 0) | (32 if negrita else 0) |
                            (64 if estilo == 'Regular' else 0))
    fb.setupPost(isFixedPitch=0, italicAngle=-14.0 if cursiva else 0.0)
    fb.font['head'].macStyle = (1 if negrita else 0) | (2 if cursiva else 0)
    os.makedirs(os.path.dirname(destino), exist_ok=True)
    fb.save(destino)
    return destino


def main(argv):
    dest = P('godot', 'fuentes')
    if '--salida' in argv:
        dest = argv[argv.index('--salida') + 1]
    mapas = {}
    for arch, (estilo, b, i) in ESTILOS.items():
        g = mapa(b, i)
        mapas[estilo] = g
        print('%s %s: %d glifos → %s' % (NOMBRE, estilo, len(g),
                                         ttf(g, os.path.join(dest, arch), estilo)))
    from PIL import Image
    lineas = ['LANDRACE HUNTERS', 'Cosecha la Haze: 27,5 % · 1.200 €',
              'ñÑ áéíóú ü ¿? ¡! «» ▲▼◀▶ ★ ≈ → 0123456789',
              'El zorro ágil brincó sobre el perro, ¿eh?']
    ims = [png(mapas[e], lineas[1], 4) for e in ('Regular', 'Bold')]
    ims += [png(mapas['Regular'], t, 4) for t in (lineas[0], lineas[2], lineas[3])]
    W = max(i.width for i in ims) + 16
    H = sum(i.height for i in ims) + 16 * len(ims)
    hoja = Image.new('RGBA', (W, H), (24, 24, 30, 255))
    y = 8
    for i in ims:
        hoja.alpha_composite(i, (8, y))
        y += i.height + 16
    m = (P('tools', 'fuente', 'muestra-ribera-pixel.png') if dest == P('godot', 'fuentes')
         else os.path.join(dest, 'muestra-ribera-pixel.png'))
    hoja.save(m)
    print('muestra: %s' % m)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
