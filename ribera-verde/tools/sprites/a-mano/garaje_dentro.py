# python3 -I tools/sprites/a-mano/garaje_dentro.py [raiz]  (Python 3 + Pillow; no va en los scripts de npm)
# (lo pidió el usuario: «un garaje por dentro, grande como el taller, pero que estén aparcados ahí los vehículos»): el garaje de la
# tía por dentro, a 16 px/m y de frente a 3/4 como los muebles del taller (nunca isométrico). Genérico, sin marcas.
#  · garaje-coche (vehiculo_expo, 80 × 48, base en (8, 47)): gS, el deportivo de la exposición sin la plataforma giratoria (en el
#    garaje, en el suelo); el utilitario, la berlina y la moto son los mismos de la exposición (expoU, expoM, expoMo)
#  · garaje-alto (mueble_escala, 32 × 48, base en (16, 47)): garrafasG (la estantería baja de 80 cm con dos garrafas de gasolina de
#    20 L, rojas, con su boca, el embudo y un trapo) y grifoG (el grifo de la pared con el enrollador de la manguera verde, la de
#    la huerta)
#  · garaje-suelo (tile, 16 × 16): floorGl, el hormigón del taller con la línea amarilla de las plazas por el medio de la casilla
#    (lo pidió el usuario: «si haces líneas de aparcamiento, que estén bien hechas»): con la línea a 0,5 m de las ruedas, cada
#    vehículo queda en el centro de su plaza de 3 m
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js garaje-suelo garaje-coche garaje-alto --atlas
# --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P
from salon import suelo
from concesionario import coche

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#2a2a34'
AC = ('#4a4e56', '#7a7e88', '#a8acb4', '#ccd0d6')   # el acero
RJ = ('#6e1a1a', '#b02a26', '#de4a3a', '#f08a70')   # el rojo de las garrafas
VE = ('#1e5a2a', '#2e8a3e', '#4cb05a')              # el verde de la manguera
LA = ('#7a5a1a', '#b8902e', '#e8c860')              # el latón del grifo

def deportivo_suelo():
    """el deportivo (4,6 m: 74 px; 1,15 m), rojo, bajo y en cuña, con el alerón; como el de la exposición, pero en el suelo"""
    L = Lienzo(80, 48)
    perfil = [(3, 33), (5, 30), (16, 29), (26, 24), (40, 23), (52, 30), (72, 34), (76, 36), (77, 40)]
    coche(L, 3, perfil, 33, 25, ((16, 40), (62, 40)), 4, ('#6a1418', '#b8202a', '#e04048', '#ff9890'), techo=())
    L.r(2, 27, 8, 2, '#1e2026'); L.vl(5, 29, 31, '#1e2026')          # el alerón
    for x in (30, 33, 36): L.p(x, 37, '#1e2026')                      # la toma de aire
    return L

def garrafa(L, x, y):
    """una garrafa de 20 L (35 × 47 cm: 6 × 8 px), de pie: el cuerpo rojo con el canto claro, el asa arriba y la boca con su tapón"""
    L.r(x, y + 2, 6, 6, RJ[1]); L.vl(x, y + 2, y + 7, RJ[2]); L.vl(x + 5, y + 2, y + 7, RJ[0])
    L.hl(x + 1, x + 4, y + 4, RJ[0]); L.p(x + 1, y + 3, RJ[3])        # la nervadura y el brillo
    L.r(x, y, 3, 2, RJ[1]); L.hl(x, x + 2, y, RJ[2])                  # el asa
    L.p(x + 4, y + 1, AC[0]); L.p(x + 5, y + 1, AC[1])                # la boca con el tapón

def garrafasG():
    """la estantería baja de acero (80 × 50 cm: 13 × 8 px) con dos garrafas de gasolina encima, y abajo el embudo y un trapo"""
    L = Lienzo(32, 48)
    x0, x1 = 9, 22
    for x in (x0, x1): L.vl(x, 39, 46, AC[0])                         # las patas
    for y in (38, 44):
        L.hl(x0, x1, y, AC[2]); L.hl(x0, x1, y + 1, AC[1])            # las dos baldas
    garrafa(L, x0 + 1, 30); garrafa(L, x0 + 7, 30)
    L.r(x0 + 2, 41, 3, 2, '#2e2e36'); L.p(x0 + 3, 43, '#2e2e36')      # el embudo negro
    L.r(x0 + 7, 42, 4, 2, '#c8a870'); L.hl(x0 + 7, x0 + 10, 42, '#e0c890')   # el trapo
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def grifoG():
    """el grifo de la pared (latón) con el enrollador de la manguera verde (40 cm de tambor: 6 px), colgado debajo"""
    L = Lienzo(32, 48)
    L.r(15, 19, 3, 2, LA[1]); L.hl(15, 17, 19, LA[2]); L.p(18, 20, LA[0])   # el grifo
    L.r(15, 18, 2, 1, '#c03028')                                             # la maneta
    L.r(10, 23, 12, 2, AC[1]); L.hl(10, 21, 23, AC[2])                       # el soporte
    for y in range(25, 33):                                                  # el tambor con la manguera dada vueltas
        for x in range(11, 21):
            d = ((x - 15.5) / 5) ** 2 + ((y - 28.5) / 4) ** 2
            if d <= 1: L.p(x, y, VE[1] if (x + y) % 3 else VE[2])
    L.r(15, 28, 2, 2, AC[0])                                                 # el eje
    L.vl(20, 29, 40, VE[1]); L.vl(21, 31, 40, VE[0]); L.r(19, 41, 3, 2, AC[2])   # la punta que cuelga, con la pistola
    L.contorno(K)
    return L

def floorGl():
    from taller import hormigon, AM
    L = hormigon(5707)
    L.r(0, 7, 16, 2, AM[1]); L.hl(0, 15, 7, AM[2])
    return L

sale('floorGl', floorGl(), 'garaje-suelo')
sale('gS', deportivo_suelo(), 'garaje-coche')
for n, f in (('garrafasG', garrafasG), ('grifoG', grifoG)):
    sale(n, f(), 'garaje-alto')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica')
            os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
