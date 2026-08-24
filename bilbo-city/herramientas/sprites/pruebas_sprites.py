#!/usr/bin/env python3
"""Pruebas del empaquetador de sprites, sin red y sin clave.

Lo que hace pixellab.py no se puede comprobar mirando el resultado: la hoja son índices
de paleta comprimidos, y si el reparto por partes se equivoca no hay ningún error — sale
un personaje con media manga del color de la piel y nadie ata cabos hasta verlo en el
juego. Aquí se le dan colores fabricados, con sus sombras y sus brillos, y se comprueba
que cada uno acaba en la rampa que le toca.

    python3 herramientas/sprites/pruebas_sprites.py
"""
import io, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pixellab as PL

fallos, bien = [], []


def ok(cond, queja):
    if not cond:
        fallos.append(queja)
    return cond


def celda(pintado):
    """Una celda de prueba: un dict {(x,y): (r,g,b)} sobre fondo transparente."""
    class Px:
        def __getitem__(self, xy):
            r = pintado.get(xy)
            return (r[0], r[1], r[2], 255) if r else (0, 0, 0, 0)
    return Px()


def sombras(rgb):
    """El mismo color como lo devolvería un generador: apagado, normal y con brillo."""
    oscuro = tuple(int(c * .55) for c in rgb)
    claro = tuple(min(255, int(c + (255 - c) * .35)) for c in rgb)
    return [oscuro, rgb, claro]


# ── 1 · cada color de plantilla cae en su parte, también sombreado ──────────────────
# Es la prueba que faltaba: el azul del pelo tiene luminancia 29 a plena intensidad, y con
# un umbral de contorno por oscuridad se iba entero al contorno. El pelo desaparecía de la
# hoja y el arquetipo salía calvo, sin un solo error por ninguna parte.
for parte, (rgb, _) in PL.CLAVES.items():
    for i, tono in enumerate(sombras(rgb)):
        pintado = {(x, y): tono for x in range(4, 8) for y in range(4, 8)}
        partes, _ = PL._reparte(celda(pintado), 12, 12)
        cual = partes[5][5]
        ok(cual == parte,
           '%s en su tono %d sale como «%s»' % (parte, i, cual or 'nada'))
bien.append('%d colores de plantilla, con sombra y brillo, caen en su parte'
            % len(PL.CLAVES))

# ── 2 · el contorno se reconoce por no tener color, no por ser oscuro ───────────────
for negro in ((11, 14, 18), (0, 0, 0), (30, 32, 35)):
    partes, _ = PL._reparte(celda({(5, 5): negro}), 12, 12)
    ok(partes[5][5] == 'contorno', 'un negro de contorno %s sale como «%s»'
       % (negro, partes[5][5]))
azul = PL.CLAVES['pelo'][0]
partes, _ = PL._reparte(celda({(5, 5): tuple(int(c * .4) for c in azul)}), 12, 12)
ok(partes[5][5] == 'pelo', 'una sombra del pelo se la come el contorno')
bien.append('el contorno se separa de las sombras oscuras con color')

# ── 3 · lo desvaído se contagia del vecino, no se reparte por tono ──────────────────
# Un gris suelto se parece más a la piel que a nada, así que repartido por tono un brillo
# en el hombro salía de color carne en mitad de la chaqueta.
magenta = PL.CLAVES['torso'][0]
pintado = {(x, y): magenta for x in range(3, 9) for y in range(3, 9)}
pintado[(5, 5)] = (150, 150, 152)                       # un brillo apagado dentro
partes, cuentas = PL._reparte(celda(pintado), 12, 12)
ok(partes[5][5] == 'torso', 'un brillo dentro del torso sale como «%s»' % partes[5][5])
ok(cuentas['desvaidos'] == 1 and cuentas['sueltos'] == 0,
   'el recuento de desvaídos no cuadra: %s' % cuentas)
gris = {(x, y): (150, 150, 152) for x in range(3, 9) for y in range(3, 9)}
_, cuentas = PL._reparte(celda(gris), 12, 12)
ok(cuentas['sueltos'] > 0, 'una celda entera desvaída no avisa de nada')
bien.append('los píxeles sin color se contagian del vecino, y si no hay vecino se cuentan')

# ── 4 · las rampas no comparten color ───────────────────────────────────────────────
pal, por_nombre = PL.paleta()
ramp = PL.rampas(por_nombre)                 # revienta solo si se pisan
usados = [v for l in ramp.values() for v in l]
ok(len(usados) == len(set(usados)), 'dos partes comparten rampa')
ok(all(0 < v <= len(pal) for v in usados), 'una rampa apunta fuera de la paleta')
bien.append('%d rampas de plantilla sobre %d colores, sin pisarse'
            % (len(ramp), len(pal)))

# Y los colores de plantilla tienen que estar lejos unos de otros en matiz: si dos se
# acercan, una sombra de uno se clasifica como el otro y no hay forma de notarlo mirando.
matices = {p: PL._tono(rgb) for p, (rgb, _) in PL.CLAVES.items()}
peor = min(((PL._dista(a, b), x, y) for x, a in matices.items()
            for y, b in matices.items() if x < y), default=(360, '', ''))
ok(peor[0] >= 45, 'los colores de plantilla de %s y %s están a %d° — muy juntos'
   % (peor[1], peor[2], peor[0]))
bien.append('los %d colores de plantilla se separan %d° en el peor caso'
            % (len(matices), peor[0]))


# ── 4 bis · la paleta que se le manda a PixelLab es exactamente la de las rampas ────
# `color_image` es lo que convierte el estarcido en certeza: al generador se le da la lista
# cerrada de colores que puede usar. Si esa lista se desviara de las rampas que luego se
# escriben en la hoja, el reparto por partes volvería a ser una apuesta — y en silencio.
b64, ntonos = PL.png_plantilla(pal, ramp)
from PIL import Image
import base64 as _b64
im = Image.open(io.BytesIO(_b64.b64decode(b64))).convert('RGB')
en_png = set(im.getdata())
en_rampas = set(pal[i - 1] for l in ramp.values() for i in l)
ok(en_png == en_rampas,
   'la paleta que se manda no coincide con las rampas: sobran %s, faltan %s'
   % (sorted(en_png - en_rampas), sorted(en_rampas - en_png)))
ok(ntonos == len(en_rampas), 'el recuento de tonos de la plantilla no cuadra')
bien.append('la paleta forzada lleva los %d tonos de las rampas, ni uno más' % ntonos)

# ── 4 ter · la semilla es estable y distinta por silueta ────────────────────────────
# Todas las celdas de una silueta van con la misma semilla: es lo que hace que las 55
# imágenes parezcan la misma persona. Y tiene que salir del nombre, no del reloj, o
# repetir una tirada devolvería a otro vecino.
ok(PL.semilla('largo_pantalon') == PL.semilla('largo_pantalon'), 'la semilla no es estable')
semillas = {PL.semilla(k) for k in PL.SETS}
ok(len(semillas) == len(PL.SETS), 'dos siluetas comparten semilla')
bien.append('%d semillas estables, una por silueta' % len(semillas))

# ── 4 quater · los píxeles sueltos se limpian, el contorno no ──────────────────────
sucio = [['torso'] * 9 for _ in range(9)]
sucio[4][4] = 'piernas'                                   # un punto perdido en la manga
n = PL._limpia(sucio, 9, 9)
ok(sucio[4][4] == 'torso' and n == 1, 'un píxel suelto sobrevive dentro de otra parte')
linea = [[''] * 9 for _ in range(9)]
for y in range(9):
    linea[y][4] = 'contorno'                              # una línea de contorno de 1 px
PL._limpia(linea, 9, 9)
ok(all(linea[y][4] == 'contorno' for y in range(9)), 'la limpieza se come el contorno')
bien.append('los píxeles sueltos se reasignan al vecino y el contorno se respeta')

# ── 4 quinquies · la figura pisa donde tiene que pisar ─────────────────────────────
# Unos píxeles de diferencia entre un fotograma y el siguiente se ven como un bote al
# andar. El juego ancla la celda por abajo, así que la fila de los pies tiene que ser la
# misma en las 128 casillas de la hoja.
def coloca(x0, y0):
    m = [[''] * PL.CEL_W for _ in range(PL.CEL_H)]
    for y in range(y0, y0 + 6):
        for x in range(x0, x0 + 4):
            m[y][x] = 'piernas' if y < y0 + 4 else 'calzado'
    return m
for x0, y0 in ((2, 2), (25, 28), (14, 15)):
    m = coloca(x0, y0)
    dx, dy = PL._encuadra(m, PL.CEL_W, PL.CEL_H)
    ok(y0 + 5 + dy == PL.BASE_PIES,
       'los pies quedan en la fila %d y no en la %d' % (y0 + 5 + dy, PL.BASE_PIES))
    ok(abs((x0 + 1 + dx) - PL.EJE_X) <= 1,
       'el eje queda en x=%d y no en %d' % (x0 + 1 + dx, PL.EJE_X))
# Y el brazo estirado del puñetazo no descentra el cuerpo: se centra por las piernas.
m = coloca(14, 15)
for x in range(18, 30):
    m[17][x] = 'torso'
ok(PL._encuadra(m, PL.CEL_W, PL.CEL_H)[0] == dx,
   'el brazo del puñetazo descentra la figura')
bien.append('los pies caen siempre en la fila %d y el eje en x=%d, brazo estirado incluido'
            % (PL.BASE_PIES, PL.EJE_X))

# ── 5 · todas las poses del juego tienen dibujo, y ninguno sobra ────────────────────
sin = [p for p in PL.POSES if p not in PL.DE_POSE]
ok(not sin, 'poses del juego sin dibujo: %s' % ', '.join(sin))
usados = set(PL.DE_POSE[p] for p in PL.POSES)
ok(usados <= set(PL.DIBUJOS), 'dibujos pedidos que no existen: %s'
   % ', '.join(sorted(usados - set(PL.DIBUJOS))))
ok(not (set(PL.DIBUJOS) - usados), 'dibujos que se bajarían sin usarse: %s'
   % ', '.join(sorted(set(PL.DIBUJOS) - usados)))
bien.append('%d poses del juego salen de %d dibujos, sin sobrar ninguno'
            % (len(PL.POSES), len(usados)))

# ── 6 · el espejo y la repetición de poses arman la hoja de verdad ──────────────────
# Se monta una hoja simulada entera y se comprueba su estructura: es lo que convierte 55
# imágenes en 8 direcciones × 16 poses. Si el espejo se hiciera al revés, el juego pintaría
# a todo el mundo mirando al lado contrario y la batería del HTML no lo vería.
import contextlib
with contextlib.redirect_stdout(io.StringIO()):      # 55 líneas de avance que aquí sobran
    hoja = PL.hoja('largo_pantalon', '', True, pal, ramp)
W, H = PL.CEL_W * 8, PL.CEL_H
fila = lambda fy, d, y: bytes(hoja[(fy * H + y) * W + d * PL.CEL_W:
                                   (fy * H + y) * W + (d + 1) * PL.CEL_W])
i = {p: n for n, p in enumerate(PL.POSES)}
for destino, fuente in PL.ESPEJO.items():
    mal = [y for y in range(H) if fila(0, destino, y) != fila(0, fuente, y)[::-1]]
    ok(not mal, 'la dirección %d no es el espejo de la %d' % (destino, fuente))
mal = [y for y in range(H) if fila(i['andar2'], 0, y) != fila(i['andar4'], 0, y)]
ok(not mal, 'los dos pasos de apoyo del andar no comparten dibujo')
mal = [y for y in range(H - 1)
       if fila(i['dispara'], 0, y) != fila(i['apunta'], 0, y + 1)]
ok(not mal, 'disparar no es apuntar con un píxel de retroceso')
ok(len(hoja) == W * H * len(PL.POSES), 'la hoja no mide 8 direcciones × %d poses'
   % len(PL.POSES))
bajos = set()
for fy, pose in enumerate(PL.POSES):
    for d in range(8):
        filas = [y for y in range(H) if any(fila(fy, d, y))]
        if filas:
            bajos.add(max(filas) - PL.DESPLAZA.get(pose, 0))
ok(len(bajos) == 1, 'la fila de los pies baila entre casillas: %s' % sorted(bajos))
ok(bajos == {PL.BASE_PIES}, 'los pies no caen en la fila %d sino en %s'
   % (PL.BASE_PIES, sorted(bajos)))
bien.append('la hoja sale de %d dibujos: 3 direcciones en espejo y %d poses repetidas'
            % (len(usados) * PL.PEDIDAS, len(PL.POSES) - len(usados)))

for b in bien:
    print('  ok    ' + b)
for f in fallos:
    print('  FALLO ' + f)
print('\n%s' % ('%d fallos' % len(fallos) if fallos else 'el empaquetador de sprites está bien'))
sys.exit(1 if fallos else 0)
