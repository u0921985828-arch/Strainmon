# python3 -I tools/sprites/sprgen_revista.py   (Python 3 + Pillow; no va en los scripts de npm)
# Las piezas de EL ESQUEJE que vienen del generador de sprites (lo pidió el usuario: «me refería pues al tema de la revista,
# el papel, las hojas, que eso no los tenemos ya creados» y «molaría hacer banners de publicidad, no que sean solo texto,
# publicidad de Kiko por ejemplo, de algún Club, de la discoteca Gaua también por ejemplo, comercios locales»).
# Entrada: tools/sprites/sprgen-revista/crudo/
#   · <k>.png (104 × 56): los diez banners de los anunciantes, sin una sola letra (el texto lo pone el juego debajo).
#   · papel.png (96 × 96): la textura del papel de la revista, de la que sale el tile de 64 × 64 sin costura.
#   · sobre.png (48 × 64): el sobre del regalo de la semilla.
# Proceso: alfa binario, cuantización a la paleta cerrada de tools/sprites/a-mano/revista.py (dos tintas sobre papel: nada
# de colores nuevos, que la hoja de arte la mide tools/sprites/paleta.js) y, en el papel, la costura cosida por
# desplazamiento (se parte el tile en cuatro y se cruzan los cuadrantes, de modo que los cantos que se tocan al tilear
# son los que ya estaban dentro de la imagen).
# Salida: tools/sprites/sprgen-revista/piezas/<n>.png, que carga tools/sprites/a-mano/revista.py y empaqueta en
# godot/arte/revista.png + revista.json.
import os, sys
from PIL import Image

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
CRUDO = os.path.join(R, 'tools', 'sprites', 'sprgen-revista', 'crudo')
PIEZAS = os.path.join(R, 'tools', 'sprites', 'sprgen-revista', 'piezas')

# la paleta cerrada de la revista (la misma de tools/sprites/a-mano/revista.py)
K0, K1, K2 = '#2b2a26', '#4a4840', '#6e6a5e'
V0, V1, V2 = '#27551a', '#3c7a28', '#6aa848'
R0 = '#a33b2a'
P0, P1, P2 = '#efe6cf', '#e4d9bd', '#f7f2e2'
TODA = [K0, K1, K2, V0, V1, V2, R0, P0, P1, P2]
SOLO_PAPEL = [P0, P1, P2, K2]          # el papel: tres tonos de hoja y la mota de tinta
SOBRE_RAMPA, SOBRE_CORTES = [K0, K1, P1, P0, P2], [75, 120, 165, 205]   # el sobre de kraft, por luminancia

# los diez banners: su clave en el juego y el anunciante al que van
BANNERS = {'kiko': 'kiko', 'ibar': 'ibar', 'chatarra': 'chatarra', 'lonja': 'lonja', 'molino': 'molino',
           'estanco': 'estanco', 'autos': 'autos', 'feder': 'feder', 'club': 'club', 'gaua': 'gaua'}


def rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def cerca(c, pal):
    """el color de la paleta más próximo, con el verde pesando más (así lo ve el ojo)"""
    return min(pal, key=lambda p: 2 * (p[0] - c[0]) ** 2 + 4 * (p[1] - c[1]) ** 2 + 3 * (p[2] - c[2]) ** 2)


def cuantiza(im, pal):
    """alfa binario y cada píxel al color más próximo de la paleta"""
    pr = [rgb(h) for h in pal]
    im = im.convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                px[x, y] = (0, 0, 0, 0)
            else:
                px[x, y] = cerca((r, g, b), pr) + (255,)
    return im


def cuantiza_lum(im, rampa, cortes):
    """por luminancia: para el sobre de kraft, que en la paleta de la revista no tiene su tono medio cálido (cuantizado
    por color se iba entero a la tinta clara). De oscuro a claro: contorno, sombra, papel del sobre y papel al sol."""
    pr = [rgb(h) for h in rampa]
    im = im.convert('RGBA')
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a < 128:
                px[x, y] = (0, 0, 0, 0)
                continue
            lum = .299 * r + .587 * g + .114 * b
            i = 0
            while i < len(cortes) and lum >= cortes[i]:
                i += 1
            px[x, y] = pr[i] + (255,)
    return im


def recorta_centro(im, w, h):
    x = (im.width - w) // 2
    y = (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def sin_costura(im, n=64):
    """el tile sin costura: se recorta al centro y se cruzan los cuatro cuadrantes, de modo que los cantos que se
    tocan al tilear ya casaban dentro de la imagen; los dos ejes del medio se suavizan con el píxel de al lado."""
    c = recorta_centro(im, n, n)
    m = n // 2
    o = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    o.paste(c.crop((m, m, n, n)), (0, 0))
    o.paste(c.crop((0, m, m, n)), (m, 0))
    o.paste(c.crop((m, 0, n, m)), (0, m))
    o.paste(c.crop((0, 0, m, m)), (m, m))
    px = o.load()
    for y in range(n):                 # el eje vertical del medio, cosido con su vecino de la izquierda
        px[m, y] = px[m - 1, y]
    for x in range(n):                 # y el horizontal
        px[x, m] = px[x, m - 1]
    return o


def grano(crudo, n=64, base=P0, pal=None):
    """el tile del papel: el tono base y, encima, el grano del crudo repartido por igual. Del crudo salen los tonos y
    cuánto pesa cada uno (su proporción de píxeles); el sitio de cada mota lo da un hash de la casilla, así que es
    siempre el mismo, no se agrupa en manchas y al tilear no se ve el ladrillo. La mota, siempre suelta."""
    pal = pal or SOLO_PAPEL
    q = cuantiza(crudo.convert('RGBA'), pal)
    px = q.load()
    cuenta = {}
    for y in range(q.height):
        for x in range(q.width):
            c = px[x, y][:3]
            cuenta[c] = cuenta.get(c, 0) + 1
    tot = sum(cuenta.values())
    t = rgb(base)
    motas = sorted((c for c in cuenta if c != t), key=lambda c: -cuenta[c])
    o = Image.new('RGBA', (n, n), t + (255,))
    po = o.load()
    puesto = [[False] * n for _ in range(n)]
    for c in motas:
        cuantas = int(round(cuenta[c] / tot * n * n))
        sem = c[0] * 7349 + c[1] * 1709 + c[2] * 547
        i, dados = 0, 0
        while dados < cuantas and i < cuantas * 40:
            h1 = (sem + i * 2654435761) & 0xffffffff
            x, y = (h1 >> 7) % n, (h1 >> 19) % n
            i += 1
            if puesto[x][y] or puesto[(x - 1) % n][y] or puesto[(x + 1) % n][y] \
               or puesto[x][(y - 1) % n] or puesto[x][(y + 1) % n]:
                continue            # la mota, suelta: nunca pegada a otra
            puesto[x][y] = True
            po[x, y] = c + (255,)
            dados += 1
    return o


def marco(im, c=K2):
    """el filete de tinta clara del borde, como las ilustraciones impresas a mano (L.contorno(K2))"""
    t = rgb(c) + (255,)
    px = im.load()
    for x in range(im.width):
        px[x, 0] = t
        px[x, im.height - 1] = t
    for y in range(im.height):
        px[0, y] = t
        px[im.width - 1, y] = t
    return im


def arte():
    """{nombre de la pieza: Image}, ya cuantizada y lista para empaquetar"""
    o = {}
    for k, n in sorted(BANNERS.items()):
        f = os.path.join(CRUDO, k + '.png')
        im = Image.open(f).convert('RGBA')
        if im.size != (104, 56):
            im = recorta_centro(im, 104, 56)
        o['ban-' + n] = marco(cuantiza(im, TODA))
    o['papel'] = grano(Image.open(os.path.join(CRUDO, 'papel.png')))
    s = Image.open(os.path.join(CRUDO, 'sobre.png')).convert('RGBA')
    o['sobre'] = cuantiza_lum(s, SOBRE_RAMPA, SOBRE_CORTES)
    return o


def main():
    os.makedirs(PIEZAS, exist_ok=True)
    A = arte()
    for n in sorted(A):
        A[n].save(os.path.join(PIEZAS, n + '.png'))
    print('%d piezas en tools/sprites/sprgen-revista/piezas/' % len(A))
    if len(sys.argv) > 1:              # una hoja de revisión a 4× con todas en columna
        anc = max(im.width for im in A.values())
        alt = sum(im.height + 2 for im in A.values())
        h = Image.new('RGBA', (anc, alt), (20, 20, 20, 255))
        y = 0
        for n in sorted(A):
            h.paste(A[n], (0, y), A[n])
            y += A[n].height + 2
        h.resize((anc * 4, alt * 4), 0).save(sys.argv[1])
        print(sys.argv[1])


if __name__ == '__main__':
    main()
