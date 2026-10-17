# python3 -I tools/sprites/a-mano/bajo.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.44 (lo pidió el usuario: «los sprites y todo para crear el piso bajo, donde se cultivan, se secan, almacenan y se crean
# microdosis y comestibles»): lo que le falta al bajo de Txomin, a 16 px/m como el resto. Nada de método ni de dosis: cosas genéricas.
#  · Objetos altos (objeto_alto, 32 × 32, pies en (16, 31)):
#    armS-<b>-<m>-<c>: el armario de almacén (metálico, 90 × 180 cm, tres baldas): arriba los botes de cristal con las setas secas,
#      en medio las cajitas blancas de las microdosis y abajo las cajas de los bombones; cada piso por lo lleno, de 0 a 2.
#    mesaS-<e>-<m>: la mesa de trabajo de acero (120 × 80 cm) con la báscula y, si las tienes, la encapsuladora (la placa de
#      agujeros con su tapa) y los moldes de silicona con la tableta de chocolate.
#  · Objeto de 1 casilla (objeto_1x1): deshidS-<0|1>, el deshidratador blanco de bandejas apiladas, apagado o con setas y el piloto.
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js bajo-alto bajo-16 --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

K = '#2a2a34'   # el contorno de los muebles (el de salon.py)
SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

AC = ('#4a4e56', '#7a7e88', '#a8acb4', '#ccd0d6')   # el acero, de sombra a brillo
CR = ('#cfe2e6', '#a6c0c6')                          # el cristal de los botes
SETA = ('#8a6a4a', '#6a4a2a', '#a8865a')             # lo seco, pardo y arrugado

def bote(L, x, y):
    """un bote de cristal de 1 L (4 × 6 px) con la tapa negra y las setas secas dentro"""
    L.r(x, y + 1, 4, 5, CR[0]); L.vl(x + 3, y + 1, y + 5, CR[1]); L.hl(x, x + 3, y, '#2a2a30')
    L.r(x, y + 3, 4, 3, SETA[0]); L.p(x + 1, y + 3, SETA[2]); L.p(x + 2, y + 4, SETA[1]); L.p(x + 3, y + 5, SETA[1])

def cajita(L, x, y):
    """la cajita blanca de las microdosis (3 × 4 px) con su banda azul, sin marca"""
    L.r(x, y, 3, 4, '#f0f0ea'); L.vl(x + 2, y, y + 3, '#c8c8c0'); L.hl(x, x + 2, y + 1, '#4a7ac0')

def bombones(L, x, y):
    """la caja de los bombones (5 × 3 px): cartón crema con la tapa de color chocolate"""
    L.r(x, y, 5, 3, '#e8d8b8'); L.hl(x, x + 4, y, '#6a3a20'); L.p(x + 2, y + 1, '#8a4a28')

def armS(b, m, c):
    """el armario de almacén de acero con tres baldas (b: los botes, m: las microdosis, c: los bombones; 0 vacío, 1 a medias,
    2 lleno) y las puertas abiertas a los lados"""
    L = Lienzo(32, 32); x0, x1, y0 = 8, 23, 3
    L.r(x0, y0, x1 - x0 + 1, 29, AC[1]); L.r(x0 + 1, y0 + 1, x1 - x0 - 1, 27, '#2e3036')       # el cuerpo y su fondo
    L.hl(x0, x1, y0, AC[3]); L.vl(x0, y0, 31, AC[2]); L.vl(x1, y0, 31, AC[0])
    L.vl(x0 - 2, y0 + 1, 30, AC[2]); L.vl(x0 - 1, y0 + 1, 30, AC[1])                          # las puertas abiertas
    L.vl(x1 + 1, y0 + 1, 30, AC[1]); L.vl(x1 + 2, y0 + 1, 30, AC[0])
    L.p(x0 - 2, 17, '#2a2a30'); L.p(x1 + 2, 17, '#2a2a30')                                   # los tiradores
    for y in (11, 19, 27):                                                                    # las baldas
        L.hl(x0 + 1, x1 - 1, y, AC[2]); L.hl(x0 + 1, x1 - 1, y + 1, AC[0])
    for k in range((0, 2, 3)[b]):
        bote(L, x0 + 1 + k * 5, 5)
    for k in range((0, 2, 4)[m]):
        cajita(L, x0 + 1 + k * 4, 15)
    for k in range((0, 1, 2)[c]):
        bombones(L, x0 + 2 + k * 7, 24)
        if c == 2: bombones(L, x0 + 2 + k * 7, 21)
    L.hl(x0, x1, 31, AC[0])
    L.contorno(K)
    return L

def mesaS(e, m):
    """la mesa de trabajo de acero inoxidable (20 px de ancho, 13 de alto) con la báscula y, encima, la encapsuladora (e) y los
    moldes con la tableta de chocolate (m)"""
    L = Lienzo(32, 32); x0, x1, yt = 6, 25, 19
    L.r(x0, yt, x1 - x0 + 1, 3, AC[2]); L.hl(x0, x1, yt, AC[3]); L.hl(x0, x1, yt + 2, AC[0])     # el tablero
    for x in (x0 + 1, x1 - 1): L.vl(x, yt + 3, 31, AC[1])                                      # las patas
    L.hl(x0 + 1, x1 - 1, 28, AC[1])                                                            # la balda de abajo
    L.r(x0 + 3, 26, 4, 2, '#e8e8e0'); L.r(x1 - 6, 26, 4, 2, '#e8e8e0')                         # cajas de cartón vacías
    L.r(x0 + 1, yt - 2, 5, 2, '#3a3a40'); L.hl(x0 + 2, x0 + 4, yt - 2, '#9aa0a8'); L.p(x0 + 3, yt - 1, '#58c070')   # la báscula
    if e:
        L.r(x0 + 8, yt - 3, 6, 3, '#f4f4ee'); L.hl(x0 + 8, x0 + 13, yt - 3, '#c8c8c0')         # la encapsuladora: la placa
        for x in range(x0 + 9, x0 + 13): L.p(x, yt - 2, '#8a8e96')                             # y sus agujeros
        L.r(x0 + 8, yt - 5, 6, 1, '#e0dcd0')                                                   # la tapa, levantada
    if m:
        L.r(x1 - 5, yt - 2, 5, 2, '#c84a6a'); L.p(x1 - 4, yt - 2, '#e0708c'); L.p(x1 - 2, yt - 2, '#e0708c')   # el molde
        L.r(x1 - 9, yt - 1, 3, 1, '#5a2e18'); L.hl(x1 - 9, x1 - 7, yt - 2, '#7a4022')        # la tableta de chocolate
    L.contorno(K)
    return L

def deshidS(on):
    """el deshidratador de bandejas apiladas (40 cm): blanco, cinco pisos con su rejilla; encendido, las setas y el piloto"""
    L = Lienzo(16, 16)
    L.r(3, 4, 10, 11, '#f0f0ea'); L.vl(12, 4, 14, '#c8c8c0'); L.hl(3, 12, 4, '#ffffff')
    for y in (6, 8, 10, 12):
        L.hl(3, 12, y, '#c8c8c0')
        if on: L.p(5 + (y // 2) % 3, y - 1, SETA[0]); L.p(9 - (y // 2) % 2, y - 1, SETA[1])
    L.r(5, 2, 6, 2, '#e0e0d8'); L.hl(5, 10, 2, '#ffffff')                                      # la tapa con el motor
    L.p(8, 14, '#58c070' if on else '#5a5a5a')                                                 # el piloto
    L.hl(3, 12, 15, '#8a8a82')
    L.contorno(K)
    return L

for b in range(3):
    for m in range(3):
        for c in range(3):
            sale(f'armS-{b}-{m}-{c}', armS(b, m, c), 'bajo-alto')
for e in range(2):
    for m in range(2):
        sale(f'mesaS-{e}-{m}', mesaS(e, m), 'bajo-alto')
for i in range(2):
    sale(f'deshidS-{i}', deshidS(i), 'bajo-16')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
