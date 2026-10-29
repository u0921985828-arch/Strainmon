# python3 -I tools/sprites/a-mano/kaia_vc.py [--ver DIR]  (Python 3 + Pillow; no va en los scripts de npm)
# Lo de la pared de servicio de las carpas de KAIA en la vista C (lo pidió el usuario: «el extractor y el intractor… se verá… en la
# vista C, dependiendo de dónde esté la mesa colocada», «lo más realista posible… coherencia y lógica»), dibujado a mano sobre la tira
# de la pared de la derecha de la plantilla (carpa-c-pared, VCA.lado = 44 columnas): la columna u es la de u px desde la esquina de
# atrás y la pared va de la fila 4 (el techo) al suelo, en la fila 138,4 + 0,8 u (de la 140, al fondo, a la 159 en u 26: lo de más
# adelante queda por debajo de la pantalla). Todo en perspectiva: lo de arriba y lo de abajo de cada cosa a su alto relativo h de esa
# pared (y = 4 + h × (suelo − 4)), así que sus cantos de arriba y de abajo bajan hacia delante como el suelo. Con los tonos de la tira
# (#b2b8c4 al fondo, #a2a9b6 en medio, #7e8694 delante, #6c7482 las rayas, #2a2b30 y #1e1f23 lo oscuro, #3a3c44 la cremallera,
# #f2f4f8 el brillo). Medidas de verdad: la pared tiene 2 m de fondo en 38 columnas (unos 0,19 px/cm) y 2 m de alto en unas 150 filas
# (0,75 px/cm):
#  · kc-serv-puerta, la puerta lateral de unos 80 × 155 cm (u 6 a 21, de h 0,22 al suelo): la cremallera en U invertida, abierta por
#    abajo, con su cinta, el tirador en la esquina de arriba y las dos cintas de velcro para recogerla.
#  · kc-serv-ventana, la ventana de malla de unos 40 × 27 cm, abajo y delante (u 26 a 33, h 0,58 a 0,70): el marco, la malla a
#    cuadros y, encima, la solapa enrollada con sus dos cintas.
#  · kc-serv-manga, la manga del intractor (la boca de 250 mm, abajo, debajo de la ventana: u 27 a 32, h 0,80 a 0,92): de lado es una
#    elipse alta y estrecha; el aro con el cordón, la tela fruncida y, dentro, la boca del tubo de aluminio con sus anillos, por donde
#    entra el aire limpio del intractor de fuera.
#  · kc-filtrof-28 y -39, el extractor con su filtro de carbón tumbado de frente a fondo (vista.gd kc_filtro_en: en las de 4 m, con
#    cuatro LED a lo ancho, entre las dos cuerdas de un LED no cabe tumbado de lado): la tapa redonda del filtro (del Ø del de lado del
#    mismo largo, extra-c-filtro-28 y -39 de equipo_c.py: 12 y 15 px), con su aro y su brillo arriba a la izquierda, y debajo, algo
#    desde abajo, la chapa perforada del cuerpo que se va al fondo; detrás, el tubo flexible que sube del extractor al techo y las dos
#    cintas del techo a sus lados (celda de 48 × 48 como la de lado: lo de abajo en la fila 47 y el tubo en las columnas 22 a 25).
# La de la izquierda es la misma en espejo (vista.gd kc_servicio). También pega los LED de 720 W de las carpas de KAIA (equipo_c.py:
# foco-c-led720-75 y -36, un poco más estrechos que su ancho, para que se vean separados) en godot/arte/carpa.png + carpa.json (la
# vista C lee de ahí, no del atlas): los del servicio en una franja nueva debajo de lo que había, con su sitio en la tira en «off».
import json, os, sys
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.chdir(R)
from PIL import Image

SUELO = 138.4
B, M, D, RA, K, KK, CR, BR = ('#b2b8c4', '#a2a9b6', '#7e8694', '#6c7482', '#2a2b30', '#1e1f23', '#3a3c44', '#f2f4f8')

def c(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) + (255,)

def y(u, h):
    """la fila a alto relativo h (0, el techo; 1, el suelo) en la columna u"""
    return int(round(4 + h * (SUELO + .8 * u - 4) + 1e-9))

def lienzo():
    return Image.new('RGBA', (44, 160), (0, 0, 0, 0))

def p(im, x, yy, col):
    if 0 <= x < im.width and 0 <= yy < im.height:
        im.putpixel((x, yy), c(col))

# la tela de la puerta, un tono más oscura que la de la pared (es otro paño, cosido por su cremallera): de la tira de la plantilla
OSCURO = {B: M, M: '#929aa8', D: RA, RA: '#5c6372', BR: B}

def tira():
    j = json.load(open(os.path.join(R, 'godot', 'arte', 'carpa.json'), encoding='utf-8'))
    x0, y0, w, h = j['sprites']['carpa-c-pared'][0]
    pa = Image.open(os.path.join(R, 'godot', 'arte', 'carpa.png')).convert('RGBA').crop((x0, y0, x0 + w, y0 + h))
    return pa.crop((196, 0, 240, 160))

def puerta():
    im = lienzo()
    u0, u1, h0 = 6, 21, .22
    fondo = lambda u: min(159, y(u, 1) - 1)
    t = tira()
    for u in range(u0 + 2, u1 - 1):                               # el paño de la puerta
        for yy in range(y(u, h0) + 2, fondo(u) + 1):
            q = '#%02x%02x%02x' % t.getpixel((u, yy))[:3]
            if q in OSCURO:
                p(im, u, yy, OSCURO[q])
    for u in range(u0, u1 + 1):                                   # el canto de arriba: la cremallera y, debajo, su cinta
        p(im, u, y(u, h0), CR if u % 2 else K)
        p(im, u, y(u, h0) - 1, RA)
        if u0 < u < u1:
            p(im, u, y(u, h0) + 1, D)
    for u, cinta in ((u0, 1), (u1, -1)):                          # los dos lados, hasta el suelo, con la cinta por dentro
        for yy in range(y(u, h0) + 1, fondo(u) + 1):
            p(im, u, yy, CR if yy % 2 else K)
            for uc, col in ((u + cinta, D), (u - cinta, RA)):     # cada columna, hasta su suelo (baja hacia delante)
                if yy <= fondo(uc):
                    p(im, uc, yy, col)
    for u in (u0, u1):                                            # las esquinas, redondeadas
        p(im, u, y(u, h0), RA)
    yt = y(u0 + 1, h0)
    p(im, u0 + 1, yt, BR); p(im, u0 + 2, yt, BR)                  # el tirador: el carro y la lengüeta colgando
    p(im, u0 + 1, yt + 1, RA); p(im, u0 + 2, yt + 1, K)
    for yy in range(yt + 2, yt + 5):
        p(im, u0 + 2, yy, K)
    p(im, u0 + 2, yt + 5, BR)
    for u in (u0 + 4, u1 - 4):                                    # las cintas de velcro de recogerla, colgando del canto
        for yy in range(y(u, h0) + 2, y(u, h0) + 9):
            p(im, u, yy, K if yy < y(u, h0) + 8 else CR)
        p(im, u + 1, y(u, h0) + 2, RA)
    return im

def ventana():
    im = lienzo()
    u0, u1, h0, h1 = 26, 33, .58, .70
    for u in range(u0, u1 + 1):
        a, b = y(u, h0), y(u, h1)
        for yy in range(a, b + 1):
            borde = u in (u0, u1) or yy in (a, b)
            if borde:
                p(im, u, yy, K)
            else:
                p(im, u, yy, KK if (u + yy) % 2 else CR)          # la malla
        p(im, u, a - 1, RA)                                       # la solapa enrollada encima: su sombra, el rollo y su brillo
        p(im, u, a - 2, B)
        p(im, u, a - 3, BR if u % 3 == 0 else B)
        p(im, u, a - 4, M)
        p(im, u, a - 5, RA)
    for u in (u0 + 2, u1 - 2):                                    # sus dos cintas, por encima del rollo
        for yy in range(y(u, h0) - 6, y(u, h0)):
            p(im, u, yy, K)
    return im

def manga():
    im = lienzo()
    u0, u1, h0, h1 = 27, 32, .80, .92
    cu = (u0 + u1) / 2
    a, b = y(cu, h0), y(cu, h1)
    cy, ry, rx = (a + b) / 2, (b - a) / 2, (u1 - u0) / 2
    for u in range(u0 - 1, u1 + 2):
        for yy in range(a - 1, b + 2):
            d = ((u - cu) / (rx + .5)) ** 2 + ((yy - cy) / (ry + .5)) ** 2
            di = ((u - cu) / (rx - .6)) ** 2 + ((yy - cy) / (ry - 2.2)) ** 2 if rx > .6 else 9
            dt = ((u - cu) / max(.6, rx - 1.6)) ** 2 + ((yy - cy) / (ry - 4.5)) ** 2
            if d > 1:
                continue
            if di > 1:                                            # la tela fruncida del aro, con sus pliegues
                p(im, u, yy, K if d > .78 else (B if (yy + u) % 3 else RA))
            elif dt > 1:                                          # la boca del tubo de aluminio, con sus anillos
                p(im, u, yy, BR if yy % 3 == 0 else B)
            else:
                p(im, u, yy, KK)                                  # dentro, el tubo hacia el intractor
    for yy in range(int(cy) - 1, int(cy) + 5):                    # el cordón, atado y colgando por delante
        p(im, u1 + 2, yy, BR if yy == int(cy) - 1 else RA)
    p(im, u1 + 1, int(cy) - 1, BR)
    return im

def filtrof(df):
    """el extractor con su filtro tumbado de frente a fondo (df, el Ø de la tapa en px), en una celda de 48 × 48"""
    im = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
    x0 = 24 - df // 2; x1 = x0 + df - 1; y1 = 45; y0 = y1 - df + 1; cx, cy, r = (x0 + x1) / 2, (y0 + y1) / 2, df / 2
    for x in (x0, x1):                                            # las cintas, del techo (y0 − 12) a la mitad de la tapa
        for yy in range(y0 - 12, int(cy) + 1):
            p(im, x, yy, '#1c1d22')
    for yy in range(y0 - 12, y0 + 2):                             # el tubo flexible (aluminio, con sus aros), detrás de la tapa
        for x in range(22, 26):
            p(im, x, yy, '#c8ccd2' if yy % 2 else '#8a9098')
        p(im, 21, yy, '#000000'); p(im, 26, yy, '#000000')
    for yy in (46, 47):                                           # el cuerpo de chapa perforada, algo desde abajo, que se va al fondo
        a, b = x0 + 1 + (yy - 46), x1 - 1 - (yy - 46)
        for x in range(a, b + 1):
            q = '#000000' if x in (a, b) or yy == 47 else ('#3a3e44' if (x + yy) % 2 else '#5a5e64')
            p(im, x, yy, q)
    for yy in range(y0, y1 + 1):                                  # la tapa: aro negro, chapa, brillo arriba a la izquierda y sombra
        for x in range(x0, x1 + 1):
            d = ((x - cx) ** 2 + (yy - cy) ** 2) ** .5
            if d > r:
                continue
            if d > r - 1.1:
                q = '#000000'
            elif d > r - 2.2:
                q = '#8a8e94' if (x - cx) + (yy - cy) < -1 else ('#2a2e34' if (x - cx) + (yy - cy) > 1 else '#5a5e64')
            elif abs(d - r * .45) < .55:
                q = '#3a3e44'                                     # el aro estampado de la tapa
            else:
                q = '#5a5e64'
            p(im, x, yy, q)
    p(im, int(cx) - 1, int(cy) - 1, '#8a8e94')                    # el remache del centro
    p(im, int(cx), int(cy), '#2a2e34')
    return im

def guarda(atlas):
    pj = os.path.join(R, 'godot', 'arte', 'carpa.json'); pp = os.path.join(R, 'godot', 'arte', 'carpa.png')
    j = json.load(open(pj, encoding='utf-8')); a = Image.open(pp).convert('RGBA')
    import equipo_c
    # los LED: en dos celdas libres de 80 × 16 (si ya estaban, en la suya)
    leds = {n: equipo_c.SAL['carpa-c-focos-led-ancho'][n][0].im for n in ('foco-c-led720-75', 'foco-c-led720-36')}
    libres = [(720, 96), (736, 112)]
    for n, im in leds.items():
        xy = tuple(j['sprites'][n][0][:2]) if n in j['sprites'] else libres.pop(0)
        if n not in j['sprites']:
            assert a.crop((xy[0], xy[1], xy[0] + 80, xy[1] + 16)).getbbox() is None, 'la celda de %s no está libre' % n
            for fs in j['sprites'].values():
                for x0, y0, w, h in fs:
                    assert x0 >= xy[0] + 80 or x0 + w <= xy[0] or y0 >= xy[1] + 16 or y0 + h <= xy[1], 'la celda es de otro sprite'
        a.paste(Image.new('RGBA', (80, 16), (0, 0, 0, 0)), xy); a.alpha_composite(im, xy)
        j['sprites'][n] = [[xy[0], xy[1], 80, 16]]
    # lo del servicio, recortado, en la franja de debajo (desde la fila 768) con su sitio en la tira
    H0 = 768
    hb = max(im.height if n.startswith('kc-filtrof-') else im.getbbox()[3] - im.getbbox()[1] for n, im in atlas.items())
    b = Image.new('RGBA', (a.width, H0 + hb), (0, 0, 0, 0)); b.paste(a.crop((0, 0, a.width, H0)), (0, 0)); a = b
    x = 0; off = {}
    for n, im in atlas.items():
        bb = (0, 0, im.width, im.height) if n.startswith('kc-filtrof-') else im.getbbox(); cr = im.crop(bb)   # el filtro, su celda entera
        a.alpha_composite(cr, (x, H0))
        j['sprites'][n] = [[x, H0, cr.width, cr.height]]
        off[n] = [bb[0], bb[1]]
        x += cr.width + 2
    j['off'] = off
    a.save(pp); json.dump(j, open(pj, 'w', encoding='utf-8'), ensure_ascii=False, separators=(',', ':'))
    print('carpa.png', a.size, off)

def ver(atlas, d):
    """cada cosa sobre la tira de la pared de la derecha y, en espejo, la de la izquierda, a 6 ×"""
    j = json.load(open(os.path.join(R, 'godot', 'arte', 'carpa.json'), encoding='utf-8'))
    x0, y0, w, h = j['sprites']['carpa-c-pared'][0]
    pa = Image.open(os.path.join(R, 'godot', 'arte', 'carpa.png')).convert('RGBA').crop((x0, y0, x0 + w, y0 + h))
    der = pa.crop((196, 0, 240, 160)); izq = pa.crop((0, 0, 44, 160))   # (la de la izquierda es la de la derecha en espejo)
    out = Image.new('RGBA', (44 * 4 + 12, 160), (255, 0, 255, 255))
    t = der.copy(); [t.alpha_composite(im) for im in atlas.values()]
    out.paste(t, (0, 0))
    t = izq.copy(); [t.alpha_composite(im.transpose(Image.FLIP_LEFT_RIGHT)) for im in atlas.values()]
    out.paste(t, (48, 0))
    t = der.copy(); t.alpha_composite(atlas['kc-serv-puerta']); t.alpha_composite(atlas['kc-serv-ventana'])
    out.paste(t, (96, 0))
    t = der.copy(); t.alpha_composite(atlas['kc-serv-manga']); t.alpha_composite(atlas['kc-serv-ventana'])
    out.paste(t, (144, 0))
    f = Image.new('RGBA', (100, 48), (90, 96, 110, 255))          # los dos filtros de frente
    f.alpha_composite(atlas['kc-filtrof-28'], (0, 0)); f.alpha_composite(atlas['kc-filtrof-39'], (50, 0))
    o2 = Image.new('RGBA', (max(out.width, 100), out.height + 52), (255, 0, 255, 255)); o2.paste(out, (0, 0)); o2.paste(f, (0, out.height + 4)); out = o2
    os.makedirs(d, exist_ok=True)
    out.resize((out.width * 6, out.height * 6), Image.NEAREST).save(os.path.join(d, 'kaia-vc.png'))

if __name__ == '__main__':
    atlas = {'kc-serv-puerta': puerta(), 'kc-serv-ventana': ventana(), 'kc-serv-manga': manga(), 'kc-filtrof-28': filtrof(12), 'kc-filtrof-39': filtrof(15)}
    if '--ver' in sys.argv:
        ver(atlas, sys.argv[sys.argv.index('--ver') + 1])
    else:
        guarda(atlas)
