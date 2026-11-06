# python3 -I tools/sprites/a-mano/titulo.py  (Python 3 + Pillow; no va en los scripts de npm)
# El logotipo del juego, dibujado a mano en código (lo pidió el usuario: «molaría hacer un sprite del título del juego, como
# estaba antes puesto, no ahora que está así como muy simple… Tiene que ser un título visual para poder utilizarlo en las fotos
# de publicidad»). Las letras de rótulo de rotulos.py en dos líneas, doradas y biseladas con el contorno y la sombra proyectada,
# sobre una placa verde con marco, y una hojita de siete foliolos a cada lado de la segunda línea.
#  · godot/arte/titulo.png + titulo.json: «logo», que pinta _pinta_titulo (src/ui.gd) a escala entera sobre la calle
#    del fondo, y «logo-placa», el mismo sobre su placa, para el gráfico destacado de la ficha (tests/capturas.gd).
#  · art/titulo/vista.png: hoja de revisión (×1 y ×4).
# Idempotente: el dibujo sale siempre igual (sin azar). Nada se escala ni se suaviza.
import json, math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P
import rotulos

# el dorado del título de siempre (ui.gd) con su bisel, el contorno y la placa verde de debajo
ORO, ORO_LUZ, ORO_SOM = '#e8c24a', '#ffe680', '#a8761e'
BORDE, PROY = '#10301c', '#0a1e10'
PLACA, PLACA_LUZ, PLACA_SOM = '#1b4a2a', '#2a7a40', '#102e1c'
# la hojita: los verdes del cogollo de la Genoteca, como en el icono de la app
HOJA_OSC, HOJA_MED, HOJA_CLA, HOJA_LUZ = '#2e6a2e', '#4a9a3a', '#78c850', '#b4ec80'

LINEAS = ['LANDRACE', 'HUNTERS']   # el nombre del juego, igual en todos los idiomas · i18n-no
SEP = 2                            # entre letras
AIRE = 4                           # el aire de la placa alrededor del texto
HOJA_R = 11                        # el radio de la hojita (lienzo de 2r + 1)
PROY_D = 2                         # lo que cuelga la sombra proyectada de rotulos.bisel
# los siete foliolos de la hojita: ángulo desde arriba, largo y medio ancho máximo
FOLIOLOS = [(0, 11, 1.9), (-34, 9, 1.7), (34, 9, 1.7), (-68, 7, 1.4), (68, 7, 1.4), (-102, 5, 1.1), (102, 5, 1.1)]


def hojita():
    """una hoja de siete foliolos en un lienzo de 2·HOJA_R + 1, con la luz arriba a la izquierda y su contorno"""
    n = 2 * HOJA_R + 1
    L = Lienzo(n, n)
    bx, by = HOJA_R, n - 3                      # donde nacen los foliolos
    for k, (gr, largo, ancho) in enumerate(FOLIOLOS):
        a = math.radians(gr)
        dx, dy = math.sin(a), -math.cos(a)
        nx, ny = -dy, dx
        lado = nx * -0.62 + ny * -0.78          # de qué lado le da la luz
        for u in range(largo * 4 + 1):          # a cuartos de píxel por el eje del foliolo
            t = u / (largo * 4.0)
            if t >= 1:
                break
            f = math.sin(math.pi * t ** 0.78) ** 1.1
            w = ancho * f * (0.76 + 0.24 * ((u / 7.0) % 1))   # con los dientes hacia la punta
            for v in range(-int(w * 4) - 1, int(w * 4) + 2):
                vv = v / 4.0
                if abs(vv) > w:
                    continue
                x = int(round(bx + dx * t * largo + nx * vv))
                y = int(round(by + dy * t * largo + ny * vv))
                c = HOJA_MED
                if abs(vv) < w * 0.34 and 0.12 < t < 0.88:
                    c = HOJA_CLA                # la vena
                elif (vv < 0) == (lado > 0):
                    c = HOJA_LUZ if lado > 0.2 or vv < 0 else HOJA_MED
                if t < 0.2:
                    c = HOJA_OSC
                L.p(x, y, c)
    for j in range(3):                          # el tallo
        L.p(bx, by + j, HOJA_OSC)
    L.contorno(BORDE)
    return L


def logo(placa=False):
    """el logotipo: las dos líneas de letras biseladas con una hojita a cada lado de la de abajo y, si se pide (el gráfico
    destacado de la ficha), sobre una placa verde con marco. En la pantalla de inicio va suelto, sobre la calle del fondo."""
    ls = [rotulos.rotulo(t, ORO, ORO_LUZ, ORO_SOM, BORDE, SEP, PROY) for t in LINEAS]
    hj = hojita()
    txtw = max(ls[0].w, ls[1].w - PROY_D + 2 * (hj.w + 3))
    alto = ls[0].h + ls[1].h - 2               # las dos líneas, pegadas por el aire del contorno
    m = (AIRE + 2) if placa else 0
    w, h = txtw + 2 * m, alto + 2 * m
    L = Lienzo(w, h)
    if placa:
        L.caja(0, 0, w, h, PLACA, BORDE)       # la placa
        L.hl(2, w - 3, 1, PLACA_LUZ)           # su bisel: la luz arriba, la sombra abajo
        L.vl(1, 2, h - 3, PLACA_LUZ)
        L.hl(2, w - 3, h - 2, PLACA_SOM)
        L.vl(w - 2, 2, h - 3, PLACA_SOM)
    y = m
    for i, l in enumerate(ls):
        # se centra el cuerpo de las letras, no el lienzo: la sombra proyectada cuelga 2 px a la derecha y,
        # contándola, el rótulo quedaba 1 px escorado a la izquierda (tests/titulo_ui.gd lo mide en pantalla)
        cw = l.w - PROY_D
        x = (w - cw) // 2
        if i == 1:                             # la hojita a los dos lados de la línea de abajo
            L.pega(hj, x - hj.w - 3, y + (l.h - hj.h) // 2)
            L.pega(hj.espejo(), x + cw + 3, y + (l.h - hj.h) // 2)
        L.pega(l, x, y)
        y += l.h - 2
    return L


def main():
    o, pl = logo(), logo(True)
    hoja = Lienzo(max(o.w, pl.w), o.h + pl.h)
    hoja.pega(o, 0, 0)
    hoja.pega(pl, 0, o.h)
    sitio = {'logo': [0, 0, o.w, o.h], 'logo-placa': [0, o.h, pl.w, pl.h]}
    hoja.guarda('godot', 'arte', 'titulo.png')
    with open(P('godot', 'arte', 'titulo.json'), 'w') as f:
        json.dump({'r': sitio}, f, separators=(',', ':'))
    imp = P('godot', 'arte', 'titulo.png.import')
    if not os.path.exists(imp):
        open(imp, 'w').write('[remap]\n\nimporter="keep"\n')
    os.makedirs(P('art', 'titulo'), exist_ok=True)
    v = Lienzo(o.w * 5, o.h * 7)
    v.r(0, 0, v.w, v.h, '#101418')
    v.pega(o, (v.w - o.w) // 2, 4)
    from PIL import Image
    g = o.im.resize((o.w * 4, o.h * 4), Image.NEAREST)
    v.im.paste(g, ((v.w - g.width) // 2, o.h + 10), g)
    v.guarda('art', 'titulo', 'vista.png')
    print('titulo.png %d × %d · logo %d × %d · con placa %d × %d' % (hoja.w, hoja.h, o.w, o.h, pl.w, pl.h))


main()
