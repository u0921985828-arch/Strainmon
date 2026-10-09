# -*- coding: utf-8 -*-
"""Las celdas, dibujadas en SVG y capturadas a píxeles con Chromium.

Por qué SVG, si ya había un rasterizador
----------------------------------------
Porque un SVG es texto y se escribe aquí, pero **se fotografía**: se dibuja grande y con
curvas de verdad, y la foto se reduce a la celda de 24×29. El rasterizador de `cuerpos.py`
sabe hacer cápsulas y superelipses y poco más; con trazados se puede dibujar el hombro
cayendo, la solapa, el bajo de la chaqueta o el flequillo, que no son ni un círculo ni un
rectángulo.

No es «un `<rect>` por píxel». Eso sería escribir el mapa de bits en otro envase y no
ahorraría nada. Aquí el SVG va en **unidades de celda con decimales** —una cabeza es un
trazado de cuatro curvas, no ciento cuarenta rectángulos— y quien decide qué píxel se
enciende es la captura.

Qué sale de aquí
----------------
Los mismos caracteres de `trazos.py`, así que todo lo de después —vestir las siete
siluetas, el volumen calculado, el empaquetado— no se entera. Los huesos son los de
`cuerpos.huesos()`: un solo esqueleto para las dos vías, así que no pueden desfasarse.

Cómo se captura
---------------
Las 55 celdas van a **una sola página** en rejilla y se hace **una sola foto**, a ×16 y con
`shape-rendering=crispEdges` para que Chromium no suavice: cada submuestra sale de un color
plano y exacto, y la reducción por mayoría es una cuenta, no una adivinanza. Después se
recorta. Abrir el navegador cincuenta y cinco veces tardaba medio minuto; así tarda dos
segundos.

Hace falta node y el Chromium de `herramientas/html/node_modules`. Cuando no estén, el
empaquetador tira del rasterizador de `cuerpos.py`, que no necesita nada.
"""

import json
import os
import subprocess
import sys

import cuerpos

AQUI = os.path.dirname(os.path.abspath(__file__))
CAPTURA = os.path.join(AQUI, 'capturar.js')
ZOOM = 16                      # a cuánto se dibuja antes de reducir
LLENO = ZOOM * ZOOM // 2       # con media celda cubierta, el píxel es del cuerpo

# Un color plano e inconfundible por parte. No son los de plantilla: aquí solo hacen de
# etiqueta, y lo que vuelve de la foto se traduce al alfabeto de `trazos`.
TINTA = {'s': '#ff0000', 'h': '#00ff00', 't': '#0000ff',
         'r': '#ffff00', 'p': '#ff00ff', 'c': '#00ffff'}
DE_TINTA = {tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)): k for k, v in TINTA.items()}


def _n(v):
    """Un número corto. Un SVG con quince decimales por coordenada no se lee."""
    return ('%.2f' % v).rstrip('0').rstrip('.')


def _catmull(ps, n, cerrada=False):
    """Muestrea una curva que **pasa por** los puntos, no que los esquiva.

    Catmull-Rom. Es la diferencia entre una curva y la de antes: suavizando por puntos
    medios, los vértices son solo tirones y una figura de cinco puntos se encoge a la
    mitad — la mata de pelo se quedaba en dos filas.
    """
    m = len(ps)
    fuera = []
    tramos = m if cerrada else m - 1
    for i in range(tramos):
        p0 = ps[(i - 1) % m] if cerrada else ps[max(0, i - 1)]
        p1, p2 = ps[i % m], ps[(i + 1) % m]
        p3 = ps[(i + 2) % m] if cerrada else ps[min(m - 1, i + 2)]
        for k in range(n):
            t = k / n
            t2, t3 = t * t, t * t * t
            fuera.append(tuple(
                .5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t
                      + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t2
                      + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t3)
                for j in (0, 1)))
    if not cerrada:
        fuera.append(tuple(ps[-1]))
    return fuera


def _poligono(ps):
    """Un trazado cerrado por puntos. A ×16 un polígono denso ya es una curva."""
    d = ['M %s %s' % (_n(ps[0][0]), _n(ps[0][1]))]
    d += ['L %s %s' % (_n(x), _n(y)) for x, y in ps[1:]]
    return ' '.join(d) + ' Z'


def _curva(ps):
    """Una forma cerrada que pasa por sus puntos."""
    return _poligono(_catmull(ps, 10, cerrada=True))


import math


def tramo(puntos, radios, n=10):
    """Un miembro: el contorno de una polilínea con un grosor que se afila.

    La línea de en medio se curva (Catmull-Rom), así que el codo y la rodilla se redondean
    sin dibujarlos; el radio interpola a lo largo, y las dos puntas se cierran con medio
    círculo. Sale un polígono denso, que a ×16 es una curva.
    """
    eje = _catmull(list(puntos), n)
    largo = len(eje)
    rs = []
    for i in range(largo):
        t = i / (largo - 1) * (len(radios) - 1)
        j = min(int(t), len(radios) - 2)
        rs.append(radios[j] + (radios[j + 1] - radios[j]) * (t - j))

    def normal(i):
        a, b = eje[max(0, i - 1)], eje[min(largo - 1, i + 1)]
        dx, dy = b[0] - a[0], b[1] - a[1]
        d = math.hypot(dx, dy) or 1.
        return -dy / d, dx / d

    izq = [(p[0] + normal(i)[0] * rs[i], p[1] + normal(i)[1] * rs[i])
           for i, p in enumerate(eje)]
    der = [(p[0] - normal(i)[0] * rs[i], p[1] - normal(i)[1] * rs[i])
           for i, p in enumerate(eje)]

    def casquete(centro, r, desde, hacia):
        """Medio círculo de `desde` a su opuesto, **por el lado de `hacia`**.

        El sentido no da igual: girando al revés, el casquete se mete por encima del propio
        miembro, el polígono se cruza y la regla de relleno le abre un agujero. Se veía
        como un brazo de un píxel y una pierna que acababa antes del tobillo.
        """
        a0 = math.atan2(desde[1], desde[0])
        giro = (math.atan2(hacia[1], hacia[0]) - a0) % (2 * math.pi)
        signo = 1 if giro < math.pi else -1
        return [(centro[0] + math.cos(a0 + signo * math.pi * k / 8) * r,
                 centro[1] + math.sin(a0 + signo * math.pi * k / 8) * r)
                for k in range(1, 8)]

    def tangente(i):
        nx, ny = normal(i)
        return ny, -nx                  # la normal girada: apunta hacia delante

    nx, ny = normal(largo - 1)
    punta = casquete(eje[-1], rs[-1], (nx, ny), tangente(largo - 1))
    nx, ny = normal(0)
    tx, ty = tangente(0)
    talon = casquete(eje[0], rs[0], (-nx, -ny), (-tx, -ty))
    return _poligono(izq + punta + list(reversed(der)) + talon)


def torso(h):
    """El tronco: hombros que caen, cintura metida y cadera. Cinco puntos por costado.

    Es lo que más se nota frente a la cápsula de `cuerpos.py`: una cápsula tiene el mismo
    ancho arriba que abajo y acaba en casquete redondo, y eso es una lata, no un torso.
    """
    (ax, ay, ar), (bx, by, br) = h['torso']
    cintura = (ay + by) * .58
    cr = br * .96                       # metida, pero poco: a 24 pixeles una avispa es una grieta
    izq = [(ax - ar * .50, ay - ar * .70),   # el trapecio, subiendo al cuello
           (ax - ar, ay + .4),               # el hombro, lo más ancho
           (ax - cr, cintura),               # la cintura, metida
           (bx - br, by),                    # la cadera
           (bx - br * .90, by + br * .8)]    # el bajo
    der = [(bx + br * .90, by + br * .8),
           (bx + br, by),
           (ax + cr, cintura),
           (ax + ar, ay + .4),
           (ax + ar * .50, ay - ar * .70)]
    return _curva(izq + der)


def cabeza(h):
    """La cabeza: ancha en el cráneo y un pelo más estrecha en la mandíbula."""
    cx, cy, rx, ry = h['cabeza']
    return _curva([(cx - rx * .55, cy - ry),       # coronilla
                   (cx - rx, cy - ry * .25),       # sien
                   (cx - rx * .88, cy + ry * .55), # mandíbula
                   (cx - rx * .42, cy + ry),       # barbilla
                   (cx + rx * .42, cy + ry),
                   (cx + rx * .88, cy + ry * .55),
                   (cx + rx, cy - ry * .25),
                   (cx + rx * .55, cy - ry)])


def pelo(h, direccion):
    """La mata: la cabeza recortada por donde acaba el pelo, con su flequillo.

    De frente el corte baja por la frente y sube en pico en el medio; de perfil corre hacia
    la nuca y deja la cara; de espaldas tapa todo menos un dedo de nuca. Es lo único que
    distingue las cinco direcciones de una misma vista, así que aquí se gana lo que no se
    puede ganar en ningún otro sitio.
    """
    cx, cy, rx, ry = h['cabeza']
    dx, corte = {'south':      (0.0, -.18),
                 'south-east': (-.20, -.06),
                 'east':       (-.38, .34),
                 'north-east': (-.18, .66),
                 'north':      (0.0, .80)}[direccion]
    cx += rx * dx
    y = cy + ry * corte
    # El borde de abajo: las patillas caen, las entradas suben y en medio queda el pico.
    # Con tres puntos y poca amplitud; con mucha, la cabeza sale con forma de corazón.
    return _curva([(cx - rx * 1.25, cy + ry * .45),
                   (cx - rx * .80, y + ry * .16),
                   (cx - rx * .34, y - ry * .10),
                   (cx + rx * .34, y - ry * .10),
                   (cx + rx * .80, y + ry * .16),
                   (cx + rx * 1.25, cy + ry * .45),
                   (cx + rx * 1.35, cy - ry * 1.7),
                   (cx - rx * 1.35, cy - ry * 1.7)])


def zapato(h, i):
    """El pie: cuña, fina en el talón y gruesa en la puntera."""
    t, p = h['tobillo'][i], h['punta'][i]
    return tramo([t, p], [GRUESO_PIE[0], GRUESO_PIE[1]])


GRUESO_PIE = (1.25, 1.45)


def svg(dibujo, direccion, zoom=ZOOM):
    """Una celda entera, en SVG. El orden de pintado es el orden de profundidad."""
    h = cuerpos.huesos(dibujo, direccion)
    vista = cuerpos.VISTA_DE[direccion]
    br = cuerpos.GRUESO['brazo']
    pr = cuerpos.GRUESO['pierna']
    lejos = None if vista == 'frente' else 0
    cerca = 1 if lejos == 0 else None
    partes = []
    pon = lambda ch, d: partes.append('<path d="%s" fill="%s"/>' % (d, TINTA[ch]))

    def brazo(i):
        pon('r', tramo([h['hombro'][i], h['codo'][i], h['mano'][i]], list(br)))

    def pierna(i):
        pon('p', tramo([h['cadera'][i], h['rodilla'][i], h['tobillo'][i]], list(pr)))
        pon('c', zapato(h, i))

    delante = dibujo in cuerpos.DELANTE
    if not delante:
        brazo(0)
        brazo(1)
    for i in ((lejos, cerca) if lejos is not None else (0, 1)):
        pierna(i)
    pon('t', torso(h))
    cu = h['cuello']
    pon('s', tramo([cu, (cu[0], cu[1] + .6)], [1.35, 1.5]))
    if delante:
        brazo(0)
        brazo(1)
    # La cabeza y, recortado dentro de ella, el pelo. El recorte es lo que impide que la
    # mata se salga del cráneo, que es el fallo clásico de dibujarla como una mancha suelta.
    cab = cabeza(h)
    ident = 'c%s_%s' % (dibujo, direccion.replace('-', ''))
    partes.append('<clipPath id="%s"><path d="%s"/></clipPath>' % (ident, cab))
    pon('s', cab)
    partes.append('<g clip-path="url(#%s)"><path d="%s" fill="%s"/></g>'
                  % (ident, pelo(h, direccion), TINTA['h']))
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
            'viewBox="0 0 %d %d" shape-rendering="crispEdges">%s</svg>'
            % (cuerpos.ANCHO * zoom, cuerpos.ALTO * zoom,
               cuerpos.ANCHO, cuerpos.ALTO, ''.join(partes)))


def _reduce(px, x0, y0, zoom):
    """De la foto a la celda, por mayoría de submuestras. La misma regla que `cuerpos`."""
    filas = []
    for y in range(cuerpos.ALTO):
        fila = []
        for x in range(cuerpos.ANCHO):
            cuenta = {}
            for sy in range(zoom):
                for sx in range(zoom):
                    c = px[x0 + x * zoom + sx, y0 + y * zoom + sy][:3]
                    ch = DE_TINTA.get(c)
                    if ch:
                        cuenta[ch] = cuenta.get(ch, 0) + 1
            total = sum(cuenta.values())
            fila.append(cuerpos.VACIO if total < LLENO else
                        max(cuenta.items(), key=lambda kv: (kv[1], kv[0]))[0])
        filas.append(''.join(fila))
    return '\n'.join(filas)


def rejillas(zoom=ZOOM, guarda=None):
    """Las 55 celdas: una página, una foto, y a recortar.

    Devuelve {dibujo: {dirección: rejilla}}, listo para `trazos.viste`. `guarda` deja la
    foto en bruto en un PNG, que es lo que hay que mirar cuando un trazado sale raro: en la
    foto se ve la curva, y en la celda ya solo se ven veinticuatro píxeles.
    """
    from PIL import Image
    celdas = [(dib, d) for dib in cuerpos.DIBUJOS for d in cuerpos.DIRS]
    peticion = {'ancho': cuerpos.ANCHO * zoom, 'alto': cuerpos.ALTO * zoom,
                'columnas': len(cuerpos.DIRS),
                'svg': [svg(dib, d, zoom) for dib, d in celdas]}
    salida = subprocess.run(['node', CAPTURA], input=json.dumps(peticion),
                            capture_output=True, text=True, cwd=AQUI)
    if salida.returncode:
        raise SystemExit('no se pudo capturar el SVG:\n' + (salida.stderr or '')[-800:])
    import base64
    import io
    im = Image.open(io.BytesIO(base64.b64decode(salida.stdout.strip()))).convert('RGB')
    if guarda:
        im.save(guarda)
    px = im.load()
    fuera = {}
    for n, (dib, d) in enumerate(celdas):
        cx, cy = n % len(cuerpos.DIRS), n // len(cuerpos.DIRS)
        fuera.setdefault(dib, {})[d] = _reduce(px, cx * cuerpos.ANCHO * zoom,
                                               cy * cuerpos.ALTO * zoom, zoom)
    return fuera


CELDAS = os.path.join(AQUI, 'celdas.py')
CABECERA = '''# -*- coding: utf-8 -*-
"""Las 55 celdas reveladas. **Generado por `vector.py --escribe`; no se edita a mano.**

La fuente son los trazados de `vector.py` sobre los huesos de `cuerpos.py`. Esto es la
foto ya recortada, y se guarda en el repositorio porque dibujarla necesita node y el
Chromium de Playwright, y el empaquetador tiene que poder correr sin ninguno de los dos.

Después de tocar un hueso o un trazado:

    python3 herramientas/sprites/vector.py --escribe
"""

CELDAS = {
'''


def escribe():
    """Revela las 55 celdas y las deja en `celdas.py`, listas para el empaquetador."""
    r = rejillas()
    trozos = [CABECERA]
    for dib in cuerpos.DIBUJOS:
        trozos.append(" '%s': {\n" % dib)
        for d in cuerpos.DIRS:
            trozos.append("  '%s': \"\"\"\n%s\n\"\"\",\n" % (d, r[dib][d]))
        trozos.append(' },\n')
    trozos.append('}\n')
    with open(CELDAS, 'w') as f:
        f.write(''.join(trozos))
    return r


if __name__ == '__main__':
    if '--escribe' in sys.argv:
        r = escribe()
        print('%d dibujos × %d direcciones -> %s'
              % (len(r), len(cuerpos.DIRS), os.path.relpath(CELDAS)))
    else:
        destino = sys.argv[1] if len(sys.argv) > 1 else None
        r = rejillas(guarda=destino)
        print('%d dibujos × %d direcciones capturados de SVG'
              % (len(r), len(cuerpos.DIRS)))
        if destino:
            print('-> %s' % destino)
        print(r['quieto']['south'])
