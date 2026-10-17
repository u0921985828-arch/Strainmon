# python3 -I tools/sprites/a-mano/calle_plantas.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.57.2 (lo pidió el usuario: «en la carretera de cuando se inicia en la pantalla de carga, que se vea alguna planta en vegetativo,
# alguna floración, dependiendo del punto del año en el que esté y cómo sería el cultivo en exterior»): las plantas de exterior del
# huerto de la calle de la carga y del título, de frente a 16 px/m (el protagonista, 27 px = 1,70 m), por fases del calendario del
# norte: plántula (abril-mayo, 15 cm en su vaso), vegetativo joven (finales de mayo-junio, 50 cm), vegetativo grande (julio, 1,4 m),
# prefloración (agosto, 1,7 m con los pelos blancos), floración (septiembre, las colas engordando) y madura (octubre, pelos naranjas
# y las hojas grandes amarilleando); después, el tocón de lo cosechado.
#  · calle-plantas (mueble_escala, 32 × 48, base en (16, 47)): pext-0 … pext-5 y pext-6 (cortada)
# Sale a art/crudo/calle-plantas/<sprite>/unica/00.png (después, node tools/sprites/procesar.js calle-plantas --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#1e3a1a'                                         # el contorno, verde muy oscuro (las hojas no llevan negro)
HV = ('#2f6a2a', '#3f8a36', '#5aa848', '#7cc45e')     # la hoja viva
HA = ('#6a6a22', '#9a9430', '#c4b848', '#e0d070')     # la hoja amarilleando
TALLO = '#4a7a2e'
COG = ('#7aa84a', '#a8cc78', '#d4e8b4')               # el cogollo, de verde a escarcha
PB, PN = '#f4f4ee', '#d8782a'                         # los pelos blancos y naranjas

def hoja(L, x, y, s, c, R, lado=0):
    """una hoja palmeada de 5 o 7 dedos con su base en (x, y); s, el largo del dedo del medio"""
    for dx, dy, n in ((0, -1, s), (-1, -1, s - 1), (1, -1, s - 1), (-1, 0, max(1, s - 2)), (1, 0, max(1, s - 2))):
        for i in range(1, n + 1):
            L.p(x + dx * i, y + dy * i, c[1] if i < n else c[2])
    if s >= 3:
        L.p(x - 2, y - 3, c[2]); L.p(x + 2, y - 3, c[2])
    L.p(x, y, c[0])

def planta(alto, ancho, fase, sem):
    """la mata de navidad: la copa llena de hojas (más ancha abajo, el borde irregular), las hojas palmeadas que asoman por los
    lados y arriba, el tallo al pie; con flor, los cogollos en las puntas de las ramas y la cola de arriba"""
    L = Lienzo(32, 48); R = azar(sem)
    base, top = 46, 46 - alto
    pie = 2 if alto > 10 else 1
    L.vl(16, base - pie, base, TALLO)
    filas = []
    for y in range(top + 1, base - pie + 1):
        t = (y - top) / max(1, alto - pie)
        w = max(1, int(ancho / 2 * t ** .85 + (1 if R() < .35 else 0)))
        filas.append((y, w, t))
        for x in range(16 - w, 16 + w + 1):
            c = HV[1]
            if x < 16 - w // 3 and R() < .5: c = HV[2]                           # la luz por la izquierda
            if x > 16 + w // 2 and R() < .5: c = HV[0]
            if R() < .12: c = HV[0]
            if fase >= 5 and t > .5 and R() < .35: c = HA[1 if R() < .5 else 2]   # las grandes de abajo, amarilleando
            L.p(x, y, c)
    for n, (y, w, t) in enumerate(filas):                                      # las hojas que asoman por los lados
        if n % 3 == 1 and w >= 2:
            for lado in (-1, 1):
                c = HA if (fase >= 5 and t > .55 and R() < .6) else HV
                hoja(L, 16 + lado * (w + 1), y + 1, 2 if alto < 12 else 3, c, R)
    hoja(L, 16, top + 1, 2 if alto < 12 else 3, HV, R)                         # la punta
    if fase >= 3:
        ln = 2 if fase == 3 else (3 if fase == 4 else 4)
        for n, (y, w, t) in enumerate(filas):                                  # los cogollos de las ramas, en el borde de la copa
            if n % 4 == 2 and w >= 3 and t > .2:
                for lado in (-1, 1):
                    bx = 16 + lado * (w - 1)
                    L.r(bx - 1, y - ln + 1, 2, ln, COG[0]); L.vl(bx - (1 if lado > 0 else 0), y - ln + 1, y, COG[1])
                    if fase >= 4: L.p(bx, y - ln + 1, COG[2])
                    L.p(bx + lado, y - 1, PN if fase == 5 else PB)
                    if fase >= 4: L.p(bx - lado * 2, y - ln + 1, PN if fase == 5 or R() < .25 else PB)
        cl = 4 if fase == 3 else (7 if fase == 4 else 9)                         # la cola de arriba
        L.r(15, top - cl + 4, 3, cl, COG[0]); L.vl(16, top - cl + 4, top + 3, COG[1])
        if fase >= 4: L.vl(15, top - cl + 5, top + 1, COG[2])
        for q in range(0, cl, 2):
            L.p(14 if q % 4 else 18, top - cl + 4 + q, PN if fase == 5 else PB)
    L.contorno(K)
    return L

def plantula():
    """la plántula en su vaso de yogur con la tierra, protegida de los caracoles: cotiledones y el primer par de hojas"""
    L = Lienzo(32, 48)
    L.r(13, 42, 6, 5, '#e8e4dc'); L.hl(13, 18, 42, '#ffffff'); L.r(14, 43, 4, 1, '#5a3a24')
    L.vl(16, 37, 42, TALLO)
    L.p(14, 40, HV[2]); L.p(15, 40, HV[2]); L.p(17, 40, HV[2]); L.p(18, 40, HV[2])          # los cotiledones
    hoja(L, 14, 38, 2, HV, None); hoja(L, 18, 38, 2, HV, None)
    L.contorno(K)
    return L

def cortada():
    """lo que queda tras la cosecha: el tocón y las ramas bajas peladas, alguna hoja seca"""
    L = Lienzo(32, 48)
    L.vl(16, 38, 46, '#6a5a2e'); L.vl(17, 40, 46, '#5a4a24')
    for i in range(1, 4): L.p(16 - i, 42 - i // 2, '#6a5a2e'); L.p(17 + i, 43 - i // 2, '#6a5a2e')
    L.p(12, 45, HA[1]); L.p(13, 46, HA[0]); L.p(20, 46, HA[1])
    L.contorno('#3a2a14')
    return L

sale('pext-0', plantula(), 'calle-plantas')
for i, (a, w, f) in enumerate(((8, 10, 1), (22, 22, 2), (27, 26, 3), (29, 26, 4), (29, 26, 5))):
    sale('pext-%d' % (i + 1), planta(a, w, f, 5800 + i), 'calle-plantas')
sale('pext-6', cortada(), 'calle-plantas')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
