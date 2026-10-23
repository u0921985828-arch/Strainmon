#!/usr/bin/env python3
# Ribera Verde — 1.56: la pantalla del viaje (lo pidió el usuario: «en el autobús no hay animación, como tampoco en los demás
# vehículos; como una pantalla de carga, pero que sea el vehículo andando recto desde una vista de perfil»). Pixel art propio,
# dibujado a mano en código: el autobús de la comarca, el scooter 125, el utilitario, la berlina y el superdeportivo del
# concesionario (con los colores de vehiculos.py), de perfil y mirando a la derecha, a 14 px/m; las ruedas aparte, en 4
# fotogramas que giran; y los fondos que se repiten (el monte, los caseríos y los árboles, el quitamiedos y la carretera).
# Sin marcas ni rótulos de verdad. Sale directo a Godot: godot/arte/viaje.png + viaje.json (no va al atlas).
#   python3 -I tools/sprites/a-mano/viaje.py [--ver <png>]
import json, math, os, sys
from PIL import Image, ImageDraw

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..'))
SALIDA = os.path.join(RAIZ, 'godot', 'arte')

O = '#180e1e'          # contorno, el del protagonista
GOMA, GOMA_L = '#2c333c', '#454d58'
LLANTA, LLANTA_S, BUJE = '#c4cad2', '#8a929c', '#6c7482'
VIDRIO, VIDRIO_S, REFLEJO = '#9cc0dc', '#6f94b4', '#eef6fc'
INT = '#23272f'
FARO, PILOTO = '#f8f0c0', '#d03028'
# el protagonista (player): gorra, piel, camiseta, pantalón
GORRA, GORRA_S, PIEL, PIEL_S, CAMI, CAMI_S, PANT = '#5aa861', '#2a8a5b', '#e8b894', '#c48e6a', '#c83839', '#a03031', '#36466f'
PINTURA = {'utilitario': ('#eceef0', '#b8bec6', '#ffffff'), 'berlina': ('#6a7280', '#4a5160', '#9aa2ae'),
           'deportivo': ('#d02a2a', '#8e1818', '#ff6a5a'), 'moto': ('#2c5aa0', '#1e3a6a', '#4a7cc4')}


def hexrgb(c):
    c = c.lstrip('#')
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


class Lienzo:
    def __init__(self, w, h):
        self.im = Image.new('RGBA', (w, h), (0, 0, 0, 0))
        self.d = ImageDraw.Draw(self.im)

    def r(self, x, y, w, h, c):
        if w > 0 and h > 0:
            self.d.rectangle([x, y, x + w - 1, y + h - 1], fill=hexrgb(c))

    def p(self, x, y, c):
        if 0 <= x < self.im.width and 0 <= y < self.im.height:
            self.im.putpixel((x, y), hexrgb(c))

    def hl(self, x0, x1, y, c):
        self.r(x0, y, x1 - x0 + 1, 1, c)

    def vl(self, x, y0, y1, c):
        self.r(x, y0, 1, y1 - y0 + 1, c)

    def poly(self, pts, c):
        self.d.polygon(pts, fill=hexrgb(c))

    def contorno(self, c=O):
        # 1 px por fuera de todo lo opaco (sin diagonales)
        im = self.im
        a = im.split()[3].load()
        W, H = im.size
        out = []
        for y in range(H):
            for x in range(W):
                if a[x, y]:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < W and 0 <= ny < H and a[nx, ny]:
                        out.append((x, y))
                        break
        for q in out:
            im.putpixel(q, hexrgb(c))


def rueda(d, f):
    # rueda de diámetro d, fotograma f de 4: goma, llanta con sombra, buje y una marca que gira
    L = Lienzo(d, d)
    c = (d - 1) / 2
    for y in range(d):
        for x in range(d):
            r = math.hypot(x - c, y - c)
            if r <= c + .45:
                L.p(x, y, O if r > c - .55 else (GOMA if r > c * .62 else (LLANTA if r > c * .28 else BUJE)))
    for y in range(d):
        for x in range(d):
            r = math.hypot(x - c, y - c)
            if c * .3 < r <= c * .62 and y > c + 1:
                L.p(x, y, LLANTA_S)
            if c * .62 < r <= c - .55 and y < c - c * .4 and x < c:
                L.p(x, y, GOMA_L)
    # los radios (2 marcas opuestas) giran 45° por fotograma (con 4, media vuelta: se lee igual que una vuelta)
    for k in (0, 1):
        a = math.pi / 4 * f + math.pi * k
        for t in (.34, .48, .58):
            L.p(round(c + math.cos(a) * c * t), round(c + math.sin(a) * c * t), BUJE)
    return L.im


def persona_perfil(L, x, y, s=1):
    # el protagonista sentado, de perfil, mirando a la derecha: cabeza (gorra con visera), cuello, hombro; (x, y): arriba de la gorra
    L.r(x, y, 6, 2, GORRA); L.hl(x + 1, x + 4, y, '#7cc882'); L.r(x + 6, y + 1, 2, 1, GORRA_S)   # la visera, hacia delante
    L.r(x, y + 2, 6, 4, PIEL); L.p(x + 5, y + 3, O); L.p(x + 6, y + 4, PIEL)                    # la cara, el ojo, la nariz
    L.r(x, y + 2, 2, 3, '#4a2e22'); L.p(x + 1, y + 3, PIEL_S)                                  # el pelo de la nuca y la oreja
    L.r(x + 1, y + 6, 3, 1, PIEL_S)
    L.r(x - 1, y + 7, 7, 3 * s, CAMI); L.hl(x - 1, x + 5, y + 7, '#e04a4a'); L.r(x - 1, y + 9, 2, 3 * s - 2, CAMI_S)


def pasajero(L, x, y, pelo, ropa):
    L.r(x, y, 5, 2, pelo); L.r(x, y + 2, 5, 3, '#d8a47e'); L.r(x, y + 2, 1, 2, pelo)
    L.r(x - 1, y + 5, 7, 4, ropa)


# ---------- el autobús de la comarca: de PixelLab, al estilo de los muebles (lo pidió el usuario: «el sprite del bus, más del
# estilo del juego, muebles con PixelLab»). Blanco con la franja verde, sin rótulos; recortado y a 28 colores
# (tools/sprites/pixellab-viaje/bus.png, 148 × 41; el 2.º de los cuatro candidatos, el que eligió el usuario). Aquí solo se sientan los pasajeros y el protagonista en las ventanas. ----------
PIXELLAB = os.path.join(RAIZ, 'tools', 'sprites', 'pixellab-viaje')
BUS_VENT = (7, 25, 43, 62, 80, 98)       # el primer píxel de cristal de cada ventana (de atrás adelante)
BUS_Y = 12                                # la fila de arriba de las cabezas


def autobus():
    L = Lienzo(1, 1)
    L.im = Image.open(os.path.join(PIXELLAB, 'bus.png')).convert('RGBA')
    L.d = ImageDraw.Draw(L.im)
    gente = [('#3a2a20', '#4a6aa0'), ('#9a9a9a', '#8a5a9a'), ('#1a1a1a', '#d8b040'), None, ('#7a4a2a', '#50a070')]
    for xw, g in zip(BUS_VENT, gente):
        if g:
            pasajero(L, xw + 5, BUS_Y + 1, *g)
    persona_perfil(L, BUS_VENT[-1] + 5, BUS_Y)       # el protagonista, delante, junto a la puerta
    return L.im, {'ruedas': [[26, 40, 14], [110, 40, 14]], 'suelo': 47, 'faro': [145, 32]}


# ---------- los coches: de juguete como en la calle (cortos y redondos), a escala de perfil ----------
def coche(k):
    pin, pin_s, pin_l = PINTURA[k]
    if k == 'utilitario':
        W, H, techo, cin, xv, xp, ruedas = 58, 26, 2, 12, (14, 40), (7, 50), [[13, 22, 12], [45, 22, 12]]
    elif k == 'berlina':
        W, H, techo, cin, xv, xp, ruedas = 70, 25, 3, 12, (19, 50), (10, 60), [[15, 21, 12], [56, 21, 12]]
    else:   # deportivo, descapotable y bajo
        W, H, techo, cin, xv, xp, ruedas = 66, 22, 7, 11, (24, 42), (11, 58), [[14, 18, 12], [53, 18, 12]]
    L = Lienzo(W, H)
    base = H - 6
    # la carrocería baja (de morro a culo, con las esquinas redondas) y el capó
    L.poly([(1, cin + 2), (3, cin), (W - 6, cin), (W - 2, cin + 2), (W - 1, cin + 4), (W - 1, base), (1, base)], pin)
    L.r(2, cin, W - 8, 1, pin_l)
    L.r(1, base - 3, W - 1, 3, pin_s)
    if k == 'deportivo':
        L.poly([(xv[0], cin), (xv[0] + 6, techo + 1), (xv[0] + 9, techo + 1), (xv[0] + 9, cin)], VIDRIO)   # el parabrisas, sin techo
        L.r(xv[0] + 6, techo, 3, 1, '#2a2d34')
        persona_perfil(L, xv[0] - 9, cin - 8)
        L.r(xv[0] - 13, cin - 1, 4, 2, INT); L.r(xv[0] + 10, cin, 12, 1, pin_l)
        L.poly([(4, cin), (8, cin - 3), (14, cin - 3), (14, cin)], pin)   # el alerón y la joroba de atrás
        L.r(2, cin - 4, 9, 1, '#202228')
    else:
        # el habitáculo: techo redondo, cristales, montante, y el protagonista al volante
        L.poly([(xp[0], cin), (xp[0] + 5, techo + 1), (xp[0] + 8, techo), (xp[1] - 13, techo), (xp[1] - 9, techo + 1), (xp[1], cin)], pin)
        L.hl(xp[0] + 7, xp[1] - 12, techo, pin_l)
        L.poly([(xp[0] + 3, cin - 1), (xp[0] + 7, techo + 2), (xv[1] - 14, techo + 2), (xv[1] - 14, cin - 1)], VIDRIO_S)
        L.poly([(xv[1] - 12, cin - 1), (xv[1] - 12, techo + 2), (xp[1] - 10, techo + 2), (xp[1] - 3, cin - 1)], VIDRIO)
        L.r(xv[1] - 14, techo + 1, 2, cin - techo - 1, pin_s)
        persona_perfil(L, xv[1] - 10, techo + 3)
        L.r(xv[1] - 11, cin - 2, 12, 2, VIDRIO)                    # la ventanilla por delante del hombro
        L.hl(xp[0] + 8, xv[1] - 16, techo + 3, REFLEJO); L.hl(xv[1] - 9, xp[1] - 11, techo + 3, REFLEJO)
        L.r(xv[1] - 13, cin + 1, 1, base - cin - 3, pin_s)        # la junta de las puertas
        L.r(xv[1] - 9, cin + 3, 3, 1, '#2a2d34')                   # el tirador
    L.r(W - 4, cin + 2, 3, 2, FARO); L.r(1, cin + 2, 2, 2, PILOTO)
    L.r(1, base - 1, W - 1, 1, '#2a2d34'); L.r(W - 5, base - 2, 4, 1, '#535b6b'); L.r(1, base - 2, 4, 1, '#535b6b')
    for cx, cy, d in ruedas:
        L.d.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=(0, 0, 0, 0))
        L.d.arc([cx - 8, cy - 8, cx + 8, cy + 8], 180, 360, fill=hexrgb('#2a2d34'))
    L.contorno()
    return L.im, {'ruedas': ruedas, 'suelo': ruedas[0][1] + ruedas[0][2] // 2, 'faro': [W - 1, cin + 3]}


def moto():
    pin, pin_s, pin_l = PINTURA['moto']
    W, H = 34, 36
    L = Lienzo(W, H)
    # el scooter: el escudo de delante, la plataforma, el asiento sobre el motor y el baúl
    L.poly([(24, 13), (27, 12), (29, 22), (28, 27), (24, 27)], pin)          # el escudo
    L.r(25, 6, 2, 7, '#3a3e48'); L.r(22, 6, 6, 2, '#2a2d34')                 # la barra del manillar y el manillar
    L.r(9, 26, 17, 2, pin_s)                                                   # la plataforma
    L.poly([(3, 20), (6, 18), (16, 18), (17, 21), (14, 29), (3, 29)], pin)    # el carenado del motor
    L.r(4, 18, 11, 1, pin_l)
    L.r(4, 16, 13, 3, '#1e2026'); L.hl(5, 15, 16, '#3a3e48')                  # el asiento
    L.r(0, 12, 6, 6, '#3a3e48'); L.hl(1, 4, 12, '#535b6b')                    # el baúl
    L.r(28, 15, 2, 2, FARO); L.r(1, 22, 2, 2, PILOTO)
    # el piloto: casco verde con visera ahumada, la camiseta, los brazos al manillar y las piernas a la plataforma
    L.r(9, 0, 9, 7, GORRA); L.hl(10, 16, 0, '#7cc882'); L.r(15, 2, 3, 3, '#3a4250'); L.p(16, 2, REFLEJO); L.r(9, 5, 2, 2, GORRA_S)
    L.r(10, 7, 6, 1, PIEL_S)
    L.r(8, 8, 8, 8, CAMI); L.r(8, 8, 2, 8, CAMI_S); L.hl(9, 15, 8, '#e04a4a')
    L.r(15, 9, 8, 2, CAMI); L.r(22, 8, 2, 2, PIEL)                            # el brazo y la mano en el puño
    L.r(10, 15, 10, 3, PANT); L.r(18, 18, 3, 8, PANT); L.r(18, 25, 5, 2, '#f4f4f4'); L.hl(18, 22, 26, '#3a3e48')   # rodilla, espinilla, zapatilla
    ruedas = [[7, 30, 10], [27, 30, 10]]
    L.contorno()
    return L.im, {'ruedas': ruedas, 'suelo': 35, 'faro': [30, 16]}


# ---------- los fondos (se repiten cada 192 px; el motor los tiñe de tarde y de noche) ----------
def monte():
    L = Lienzo(192, 40)
    def perfil(f, a, b, c, y0):
        return [y0 - int(a * math.sin(x / 192 * 2 * math.pi * f) + b * math.sin(x / 192 * 2 * math.pi * (f * 2 + 1) + 1.3) + c * math.sin(x / 192 * 2 * math.pi * 7 + .4)) for x in range(192)]
    lejos = perfil(2, 9, 5, 2, 22)
    cerca = perfil(3, 6, 4, 2, 31)
    for x in range(192):
        L.vl(x, max(0, lejos[x]), 39, '#8aa6b8')
        L.vl(x, max(0, cerca[x]), 39, '#5e8a6a')
        if x % 3 == 0:
            L.p(x, cerca[x] + 2, '#4f7a5c')
    for x in range(192):
        L.p(x, max(0, lejos[x]), '#a8c0cc')
    return L.im


# los pueblos de detrás (lo pidió el usuario: «los pueblos que se ven al iniciar el juego, que se parezcan más al juego», y luego «que no
# todos los pueblos sean iguales y que, por lo alejadas que estén las casas de la carretera, se vean más o menos pequeñas»): las
# fachadas, los árboles y los setos del propio juego, sacados del atlas de Godot (godot/arte/atlas.png). Un pueblo por tipo (el rural de
# los caseríos, el de la costa, el de las naves, el barrio y la ciudad), cada uno en dos capas: la de junto a la carretera, a su
# tamaño, y la de lejos, a la mitad, más arriba y más despacio. Cada capa se repite cada PUEBLO_W px
PUEBLO_W = 704
CERCA_H, CERCA_BASE = 130, 118          # la capa de junto a la carretera: alto y la fila del suelo (el pie de las casas)
LEJOS_H, LEJOS_BASE = 88, 60            # la de lejos
A = 'prop-arbol-alto/tree'; A2 = 'prop-arbol-alto2/tree2'; MZ = 'prop-manzano/manzano'
def e(k): return 'edificio-%s/base' % k
# (marco del atlas, x: la izquierda de las casas, el centro de los árboles); los de lejos, en px de la mitad
PUEBLOS = {
    'rural': {
        'cerca': [(A, 30), (e('caserio'), 54), (MZ, 300), (e('borda'), 420), (A2, 520), (e('caserio3'), 560)],
        'lejos': [(e('borda'), 10), (A2, 90), (e('caserio3'), 120), (e('caserio'), 260), (MZ, 340), (A, 380), (e('borda'), 420), (e('caserio2'), 520), (A2, 660)],
        'prado': '#7cbc64'},
    'costa': {
        'cerca': [(e('marinera'), 20), (e('marinera2'), 84), (A2, 200), (e('marinera5'), 330), (e('marinera6'), 410), (MZ, 560), (e('marinera3'), 600)],
        'lejos': [(e('marinera4'), 0), (e('marinera'), 64), (e('marinera2'), 128), (e('marinera6'), 192), (A, 270), (e('marinera3'), 310), (e('marinera5'), 374),
                  (e('marinera'), 454), (e('marinera4'), 518), (A2, 610), (e('marinera6'), 640)],
        'prado': '#8cc46c'},
    'industria': {
        'cerca': [(e('nave'), 16), (A, 200), (e('fabrica'), 300), (e('garaje'), 430), (A2, 560), (e('garaje'), 620)],
        'lejos': [(e('fabrica'), 0), (e('nave'), 140), (A2, 262), (e('ladrillo'), 290), (e('fabrica'), 420), (A, 570), (e('nave'), 600)],
        'prado': '#82b45e'},
    'barrio': {
        'cerca': [(e('home'), 10), (A, 160), (e('garaje'), 300), (e('gray'), 420), (MZ, 560), (A2, 650)],
        'lejos': [(e('bloque'), 0), (e('ladrillo'), 132), (e('bloque2'), 250), (A, 392), (e('gray'), 420), (e('bloque'), 520), (A2, 670)],
        'prado': '#7cbc64'},
    'ciudad': {
        'cerca': [(e('casco'), 0), (e('casco2'), 64), (A2, 190), (e('ladrillo'), 300), (A, 470), (e('casco3'), 540), (e('casco2'), 620)],
        'lejos': [(e('bloque'), 0), (e('bloque2'), 128), (e('casco3'), 256), (e('bloque'), 336), (e('casco'), 464), (e('bloque2'), 528), (e('casco2'), 656)],
        'prado': '#86b86a'},
}
NEBLINA = ('#a8c0cc', 0.22)              # lo de lejos, algo más claro, del color del monte del fondo


def del_atlas():
    hoja = Image.open(os.path.join(SALIDA, 'atlas.png')).convert('RGBA')
    j = json.load(open(os.path.join(SALIDA, 'atlas.json')))
    return lambda k: hoja.crop((j['frames'][k]['x'], j['frames'][k]['y'], j['frames'][k]['x'] + j['frames'][k]['w'], j['frames'][k]['y'] + j['frames'][k]['h']))


REMATE = 22                              # filas que le faltan por arriba a la fábrica del atlas (el tejado sin canto y la chimenea sin boca)
CUMBRE = REMATE - 6                      # la fila de la cumbrera: la chapa sube 5 filas más que en el atlas
NEGRO, LADRILLO_C = (42, 38, 36, 255), (122, 52, 38, 255)
CORONA = ((200, 196, 188, 255), (150, 148, 144, 255))   # el hormigón de la corona, luz y sombra


def remata(k, im):
    # la fábrica del atlas acaba en la fila 0 a mitad de tejado: le sigue la chapa hacia arriba (cada 9 filas se repite) con su
    # cumbrera oscura y la chimenea (x 98–111) sube muy por encima, perfilada contra el cielo, con su corona de hormigón; el atlas
    # no se toca
    if k != e('fabrica'):
        return im
    w, h = im.size
    out = Image.new('RGBA', (w, h + REMATE), (0, 0, 0, 0))
    out.alpha_composite(im, (0, REMATE))
    src, px = im.load(), out.load()
    for y in (0, 1):                      # la tira negra con la que se cortaba arriba, ladrillo como debajo
        for x in range(99, 111):
            px[x, y + REMATE] = src[x, y + 9]
    for y in range(CUMBRE + 1, REMATE):   # la chapa, por su periodo
        for x in range(w):
            px[x, y] = src[x, (y - REMATE) % 9]
    for x in range(w):
        px[x, CUMBRE] = NEGRO
    for y in range(4, REMATE):            # el fuste, con el ladrillo de las filas 9-17 (el mismo periodo que la chapa)
        for x in range(98, 112):
            px[x, y] = src[x, 9 + (y - REMATE) % 9]
    for y in range(4, CUMBRE):            # por encima del tejado, su contorno
        px[97, y] = px[112, y] = NEGRO
    for x in range(95, 115):              # la corona: más ancha que el fuste, hormigón con su canto, y la boca debajo
        px[x, 0] = NEGRO
        px[x, 1] = NEGRO if x in (95, 114) else CORONA[0]
        px[x, 2] = NEGRO if x in (95, 114) else CORONA[1]
        px[x, 3] = NEGRO
    for x in range(98, 112):
        px[x, 4] = LADRILLO_C
    return out


def mitad(im):
    # a la mitad sin perder el estilo: cada 2 × 2 da el color de su paleta que más se repite (el contorno gana a los demás si está), y
    # transparente solo si lo son 3 o 4 de los 4
    w, h = im.width // 2, im.height // 2
    src = im.load()
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    px = out.load()
    for y in range(h):
        for x in range(w):
            cs = [src[2 * x + dx, 2 * y + dy] for dy in (0, 1) for dx in (0, 1)]
            op = [c for c in cs if c[3] >= 128]
            if len(op) < 2:
                continue
            osc = [c for c in op if sum(c[:3]) < 150]
            if osc and len(osc) >= 2:
                px[x, y] = osc[0][:3] + (255,); continue
            cuenta = {}
            for c in op:
                cuenta[c[:3]] = cuenta.get(c[:3], 0) + 1
            px[x, y] = max(cuenta, key=lambda c: (cuenta[c], -sum(c))) + (255,)
    return out


def neblina(im):
    r0, g0, b0 = (int(NEBLINA[0][i:i + 2], 16) for i in (1, 3, 5))
    t = NEBLINA[1]
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (round(r + (r0 - r) * t), round(g + (g0 - g) * t), round(b + (b0 - b) * t), a)
    return im


def prado(L, base, h, c):
    claro = '#%02x%02x%02x' % tuple(min(255, int(c[i:i + 2], 16) + 32) for i in (1, 3, 5))
    oscuro = '#%02x%02x%02x' % tuple(int(int(c[i:i + 2], 16) * 0.86) for i in (1, 3, 5))
    L.r(0, base - 6, PUEBLO_W, h - base + 6, c); L.r(0, base - 6, PUEBLO_W, 1, claro)
    for x in range(0, PUEBLO_W, 7):
        L.p(x, base - 2 + (x * 13) % 9 if base - 2 + (x * 13) % 9 < h else h - 1, oscuro)


def pueblo(tipo, marco):
    P = PUEBLOS[tipo]
    # junto a la carretera
    L = Lienzo(PUEBLO_W, CERCA_H)
    prado(L, CERCA_BASE, CERCA_H, P['prado'])
    seto = marco('prop-seto/seto/unica/00')
    for x in range(0, PUEBLO_W, 16):          # el seto corrido delante del prado
        L.im.alpha_composite(seto, (x, CERCA_H - 16))
    for k, x in P['cerca']:
        im = remata(k, marco(k + '/unica/00'))
        x0 = x if k.startswith('edificio') else x - im.width // 2
        L.im.alpha_composite(im, (x0, CERCA_BASE - im.height))
    cerca_im = L.im
    # lejos: las casas a la mitad, sobre su prado, con la neblina
    L = Lienzo(PUEBLO_W, LEJOS_H)
    for k, x in P['lejos']:
        im = mitad(remata(k, marco(k + '/unica/00')))
        x0 = x if k.startswith('edificio') else x - im.width // 2
        L.im.alpha_composite(im, (x0, LEJOS_BASE - im.height))
    neblina(L.im)
    fondo = Lienzo(PUEBLO_W, LEJOS_H)
    prado(fondo, LEJOS_BASE, LEJOS_H, '#6ea870')
    neblina(fondo.im)
    fondo.im.alpha_composite(L.im)
    return cerca_im, fondo.im


def cerca():
    # el quitamiedos de delante (bionda con sus postes), sobre la cuneta
    L = Lienzo(64, 16)
    L.r(0, 8, 64, 8, '#7cbc64'); L.r(0, 8, 64, 1, '#5e9a50')
    for x in (6, 38):
        L.r(x, 3, 3, 11, '#6c7482'); L.vl(x, 3, 13, '#9aa3ad')
    L.r(0, 4, 64, 4, '#b8c0c8'); L.r(0, 4, 64, 1, '#e4e8ee'); L.r(0, 7, 64, 1, '#7a828c')
    L.hl(0, 63, 5, '#d0d6dc')
    for x in range(2, 64, 9):
        L.p(x, 13 + x % 3, '#9cd47c')
    return L.im


def carretera():
    # 32 px: el arcén, el asfalto con su grano y la raya discontinua del medio
    L = Lienzo(32, 34)
    L.r(0, 0, 32, 2, '#c8ccd2')                      # la línea del borde de enfrente
    L.r(0, 2, 32, 30, '#5c6472')
    for i in range(23):
        L.p((i * 11) % 32, 3 + (i * 7) % 28, '#6c7482')
        L.p((i * 5 + 3) % 32, 3 + (i * 13) % 28, '#525a68')
    L.r(0, 15, 18, 2, '#eceee8')                     # la raya
    L.r(0, 30, 32, 2, '#eceee8')                     # la línea del borde de este lado
    L.r(0, 32, 32, 2, '#7a7e86')
    return L.im


def main():
    piezas = {}
    meta = {}
    im, m = autobus(); piezas['bus'] = im; meta['bus'] = m
    for k in ('utilitario', 'berlina', 'deportivo'):
        im, m = coche(k); piezas[k] = im; meta[k] = m
    im, m = moto(); piezas['moto'] = im; meta['moto'] = m
    for d in (10, 12, 14, 16):
        for f in range(4):
            piezas['rueda-%d-%d' % (d, f)] = rueda(d, f)
    for k in ('nube-0', 'nube-1', 'nube-2', 'nube-3', 'sol', 'luna'):     # el cielo, de PixelLab
        piezas[k] = Image.open(os.path.join(PIXELLAB, k + '.png')).convert('RGBA')
    piezas['monte'] = monte()
    marco = del_atlas()
    for t in PUEBLOS:
        piezas['pueblo-' + t], piezas['lejos-' + t] = pueblo(t, marco)
    piezas['cerca'] = cerca(); piezas['carretera'] = carretera()
    # la hoja: por filas, de arriba abajo
    W = max(200, max(im.width for im in piezas.values()))
    x = y = fila = 0
    rects = {}
    for k, im in piezas.items():
        if x + im.width > W:
            x = 0; y += fila + 1; fila = 0
        rects[k] = [x, y, im.width, im.height]
        x += im.width + 1; fila = max(fila, im.height)
    hoja = Image.new('RGBA', (W, y + fila), (0, 0, 0, 0))
    for k, im in piezas.items():
        hoja.paste(im, tuple(rects[k][:2]))
    os.makedirs(SALIDA, exist_ok=True)
    hoja.save(os.path.join(SALIDA, 'viaje.png'))
    with open(os.path.join(SALIDA, 'viaje.json'), 'w') as f:
        json.dump({'r': rects, 'v': meta}, f, separators=(',', ':'))
    if '--ver' in sys.argv:
        hoja.resize((hoja.width * 4, hoja.height * 4), Image.NEAREST).save(sys.argv[sys.argv.index('--ver') + 1])
    print('viaje: %d piezas, hoja %dx%d' % (len(piezas), hoja.width, hoja.height))


if __name__ == '__main__':
    main()
