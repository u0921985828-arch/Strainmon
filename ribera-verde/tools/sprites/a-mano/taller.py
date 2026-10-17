# python3 -I tools/sprites/a-mano/taller.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.57.2 (lo pidió el usuario: «está muy vacío, molaría meterle otro tipo de suelo en diferentes zonas… el atrezzo deja que desear»):
# el taller de Valdehierro por zonas, a 16 px/m y de frente a 3/4 como el resto de los muebles (nunca isométrico). Genérico, sin marcas.
#  · interior-taller (casillas de 16 × 16): floorTc / floorTc2 / floorTc3 (el hormigón de los puestos: liso, con una mancha de
#    aceite y con una rodada), floorTcR (el hormigón con la línea amarilla a la derecha, el borde del puesto), floorTcT (con la línea
#    arriba), floorTd (el sumidero de rejilla), floorTg (la goma antifatiga, delante del banco y del lavabo) y floorTr (el gres de la
#    espera, de 50 cm)
#  · taller-alto (mueble_escala, 32 × 48, base en (16, 47)): mangT (el enrollador de la manguera del aire, en la pared), calT (el
#    calendario de pared), lavabT (el lavabo de acero de 90 cm con el papel), rackT (la estantería de ruedas nuevas de 1,8 m),
#    extinT (el extintor de 6 kg en su soporte, con la placa), bidonT (el bidón de 200 L, 90 cm), gatoT (el gato de carretilla),
#    gruaT (la grúa de motores plegada, 1,7 m), cajonT (el armario de herramientas de 1,1 m con la caja encima), sillaT (las sillas
#    de la espera) y cafeM (la máquina de café de 1,8 m)
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js interior-taller taller-alto --atlas
# --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar
from salon import suelo

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#2a2a34'
AC = ('#4a4e56', '#7a7e88', '#a8acb4', '#ccd0d6')   # el acero
RJ = ('#7a1e1e', '#b83030', '#e05a4a')              # el rojo de taller
AM = ('#a07a10', '#e0b030', '#f4d870')              # el amarillo de seguridad
NG = ('#1e1e24', '#2e2e36', '#44444e')              # el negro de la goma y las ruedas
HO = ('#76787a', '#828486', '#8e9092', '#9a9c9e')   # el hormigón

# ---------------------------------------------------------------------------------------------------------- el suelo
def hormigon(sem):
    L = Lienzo(16, 16); R = azar(sem)
    L.r(0, 0, 16, 16, HO[2])
    for _ in range(22): L.p(int(R() * 16), int(R() * 16), HO[1] if R() < .55 else HO[3])   # el árido y el polvo
    return L

def floorTc():
    return hormigon(5701)

def floorTc2():
    """con una mancha de aceite: el cerco más oscuro y el centro casi negro, irregular"""
    L = hormigon(5702)
    for y in range(5, 13):
        for x in range(3, 14):
            d = ((x - 8.2) / 5.2) ** 2 + ((y - 8.6) / 3.6) ** 2
            if d < .45: L.p(x, y, '#3e3c3a')
            elif d < 1: L.p(x, y, '#5e5c5a')
    L.p(12, 4, '#5e5c5a'); L.p(13, 4, '#5e5c5a'); L.p(2, 13, '#5e5c5a')                     # las gotas de alrededor
    return L

def floorTc3():
    """con la rodada de un neumático, en diagonal"""
    L = hormigon(5703)
    for i in range(16):
        y = 3 + i // 2
        if i % 3: L.p(i, y, HO[0]); L.p(i, y + 3, HO[0])
    return L

def floorTcR():
    L = hormigon(5704)
    L.r(13, 0, 2, 16, AM[1]); L.vl(13, 0, 15, AM[2])                                         # la línea amarilla del borde del puesto
    return L

def floorTcT():
    L = hormigon(5705)
    L.r(0, 1, 16, 2, AM[1]); L.hl(0, 15, 1, AM[2])
    return L

def floorTd():
    """el sumidero: la canaleta de rejilla de acero a lo ancho, para el agua y lo que gotea"""
    L = hormigon(5706)
    L.r(0, 6, 16, 5, AC[0]); L.hl(0, 15, 6, AC[2]); L.hl(0, 15, 10, NG[1])
    for x in range(1, 16, 2): L.vl(x, 7, 9, NG[0])
    return L

def floorTg():
    """la goma antifatiga negra con sus estrías, con el canto en bisel"""
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, NG[1])
    for y in range(2, 15, 3): L.hl(1, 14, y, NG[2])
    L.hl(0, 15, 0, '#3a3a44'); L.hl(0, 15, 15, NG[0])
    return L

def floorTr():
    """el gres beige de la espera, en baldosas de 50 cm con la junta gris"""
    L = Lienzo(16, 16); R = azar(5707)
    L.r(0, 0, 16, 16, '#d6c8a8')
    for _ in range(12): L.p(int(R() * 16), int(R() * 16), '#cabc9c' if R() < .5 else '#e0d4b6')
    for v in (7, 15): L.hl(0, 15, v, '#a8a090'); L.vl(v, 0, 15, '#a8a090')
    return L

# ---------------------------------------------------------------------------------------------------------- los muebles
def mangT():
    """el enrollador de la manguera del aire (60 cm), colgado de la pared: la caja amarilla, el tambor y la manguera que baja"""
    L = Lienzo(32, 48)
    L.r(10, 22, 12, 11, AM[1]); L.hl(10, 21, 22, AM[2]); L.hl(10, 21, 32, AM[0])
    L.r(12, 24, 8, 7, NG[1]); L.r(14, 26, 4, 3, AC[1]); L.p(15, 27, AC[3])                     # el tambor con la manguera dada vueltas
    L.vl(16, 33, 41, '#3a7ad0'); L.vl(17, 33, 41, '#2a5aa0'); L.r(15, 42, 4, 2, AC[2])          # la manguera azul y su tope
    L.contorno(K)
    return L

def calT():
    """el calendario de pared (40 × 60 cm): la foto de un coche de rally de los noventa, sin marca, y la hoja del mes"""
    L = Lienzo(32, 48)
    L.vl(16, 18, 19, AC[0])                                                                    # el clavo
    L.r(12, 20, 9, 14, '#f4f4ee')
    L.r(13, 21, 7, 5, '#8ab4d8'); L.r(13, 24, 7, 2, '#6a8a4a')                                 # el cielo y el monte de la foto
    L.r(14, 23, 5, 2, RJ[1]); L.p(14, 25, NG[0]); L.p(18, 25, NG[0])                           # el coche
    for y in (28, 30, 32):
        for x in range(13, 20, 2): L.p(x, y, '#9a9ea4')
    L.p(17, 30, RJ[1])                                                                         # un día en rojo
    L.contorno(K)
    return L

def lavabT():
    """el lavabo de acero de taller (90 cm): la pila honda en su pie, el grifo de codo, el jabón y el papel en la pared"""
    L = Lienzo(32, 48)
    L.r(9, 32, 14, 4, AC[2]); L.hl(9, 22, 32, AC[3]); L.r(10, 33, 12, 2, AC[1])               # la pila
    L.r(14, 36, 4, 10, AC[1]); L.vl(14, 36, 45, AC[2])                                         # el pie
    L.vl(15, 28, 31, AC[3]); L.hl(15, 18, 28, AC[3]); L.p(18, 29, AC[1])                       # el grifo
    L.r(19, 25, 3, 6, '#3f8a46'); L.hl(19, 21, 25, '#5aa060')                                 # el jabón de taller
    L.r(9, 19, 6, 6, '#2e5aa8'); L.hl(9, 14, 19, '#4a7ad0'); L.r(10, 25, 4, 3, '#4a7ad0')      # el rollo de papel azul
    L.contorno(K); suelo(L, 13, 18, K)
    return L

def rackT():
    """la estantería de ruedas nuevas (1,8 m): dos baldas de tubo con las ruedas de pie, de canto"""
    L = Lienzo(32, 48)
    L.vl(6, 18, 46, AC[1]); L.vl(25, 18, 46, AC[1]); L.vl(7, 18, 46, AC[0]); L.vl(26, 18, 46, AC[0])
    for y in (31, 45):
        L.hl(6, 26, y, AC[2])
        for x in (8, 14, 20):
            L.r(x, y - 12, 5, 12, NG[1]); L.vl(x, y - 12, y - 1, NG[0]); L.vl(x + 4, y - 12, y - 1, NG[0])
            for j in range(y - 11, y - 1, 2): L.hl(x + 1, x + 3, j, NG[2])                     # el dibujo de la banda
            L.r(x + 1, y - 9, 3, 2, '#f4f4ee')                                                 # la etiqueta de medida
    L.contorno(K); suelo(L, 6, 26, K)
    return L

def extinT():
    """el extintor rojo de 6 kg colgado en su soporte, con la placa cuadrada encima"""
    L = Lienzo(32, 48)
    L.r(12, 18, 8, 8, RJ[1]); L.r(13, 19, 6, 6, '#f4f4ee'); L.r(15, 20, 2, 4, RJ[1])           # la placa
    L.r(13, 31, 6, 13, RJ[1]); L.vl(13, 31, 43, RJ[2]); L.vl(18, 31, 43, RJ[0])                # la botella
    L.r(14, 29, 4, 2, NG[1]); L.hl(13, 18, 28, NG[2]); L.vl(19, 29, 38, NG[1])                 # la válvula y la manguera
    L.r(14, 35, 4, 4, '#f4f4ee')                                                               # la etiqueta
    L.contorno(K)
    return L

def bidonT():
    """el bidón de 200 L (90 cm): negro, con los dos aros, la tapa y el embudo"""
    L = Lienzo(32, 48)
    L.r(9, 32, 14, 14, '#2e3a5a'); L.vl(9, 32, 45, '#465a86'); L.vl(22, 32, 45, '#1e2840')
    for y in (36, 41): L.hl(9, 22, y, '#1e2840'); L.hl(9, 22, y - 1, '#5a6e9a')
    L.r(9, 29, 14, 3, '#3a4a70'); L.hl(9, 22, 29, '#5a6e9a')                                   # la tapa
    L.r(17, 26, 3, 3, AC[1]); L.hl(16, 20, 26, AC[2])                                           # el embudo
    L.r(11, 37, 5, 3, AM[1])                                                                   # la etiqueta de residuo
    L.contorno(K); suelo(L, 9, 22, K)
    return L

def gatoT():
    """el gato de carretilla (90 cm × 30 cm de alto): el chasis rojo bajo, el brazo con el plato, las ruedas y la palanca"""
    L = Lienzo(32, 48)
    L.r(6, 40, 18, 5, RJ[1]); L.hl(6, 23, 40, RJ[2]); L.hl(6, 23, 44, RJ[0])
    L.r(18, 36, 6, 4, RJ[1]); L.r(19, 35, 5, 1, AC[2])                                          # el brazo y el plato
    L.r(7, 45, 3, 2, NG[1]); L.r(20, 45, 3, 2, NG[1])
    for i in range(10): L.p(6 - i // 2, 39 - i, AC[1])                                          # la palanca, de pie
    L.r(1, 28, 3, 2, NG[1])
    L.contorno(K); suelo(L, 1, 24, K)
    return L

def gruaT():
    """la grúa de motores plegada (1,7 m): la columna amarilla, la pluma con la cadena y el gancho, las patas con ruedas"""
    L = Lienzo(32, 48)
    L.r(9, 43, 16, 2, AM[0]); L.hl(9, 24, 43, AM[1])                                            # las patas
    L.r(9, 45, 2, 2, NG[1]); L.r(22, 45, 2, 2, NG[1])
    L.r(11, 20, 3, 23, AM[1]); L.vl(11, 20, 42, AM[2]); L.vl(13, 20, 42, AM[0])                 # la columna
    L.r(11, 18, 13, 3, AM[1]); L.hl(11, 23, 18, AM[2]); L.hl(11, 23, 20, AM[0])                 # la pluma
    L.r(14, 28, 2, 8, NG[2]); L.vl(15, 21, 27, AC[0])                                           # el cilindro hidráulico
    for y in range(21, 31, 2): L.p(22, y, AC[1]); L.p(22, y + 1, AC[0])                         # la cadena
    L.p(21, 31, AC[2]); L.p(22, 32, AC[2]); L.p(23, 31, AC[2])                                  # el gancho
    L.contorno(K); suelo(L, 9, 24, K)
    return L

def cajonT():
    """el armario de herramientas (70 cm × 1,1 m): siete cajones rojos con tirador de aluminio y la caja de encima abierta"""
    L = Lienzo(32, 48)
    L.r(8, 29, 16, 16, RJ[1]); L.vl(8, 29, 44, RJ[2]); L.vl(23, 29, 44, RJ[0])
    for i, y in enumerate((30, 32, 34, 36, 38, 41)):
        L.hl(9, 22, y + (1 if i == 5 else 0), RJ[0]); L.hl(12, 19, y + 1, AC[3])                 # las juntas y los tiradores
    L.r(8, 45, 2, 2, NG[1]); L.r(22, 45, 2, 2, NG[1])                                           # las ruedas
    L.r(9, 23, 14, 6, RJ[1]); L.hl(9, 22, 23, RJ[2]); L.hl(9, 22, 28, RJ[0])                    # la caja de encima
    L.r(10, 21, 12, 2, AC[1]); L.p(12, 20, AC[2]); L.p(15, 20, AC[2]); L.p(19, 20, AC[2])       # las llaves que asoman
    L.contorno(K); suelo(L, 8, 23, K)
    return L

def sillaT():
    """dos sillas de la espera de plástico gris sobre la viga de acero (45 cm de asiento), con una revista"""
    L = Lienzo(32, 48)
    for x in (6, 17):
        L.r(x, 28, 9, 9, '#8a96a6'); L.hl(x, x + 8, 28, '#a6b2c2')                              # el respaldo
        L.r(x, 37, 9, 3, '#76828f'); L.hl(x, x + 8, 37, '#a6b2c2')                              # el asiento
    L.hl(6, 25, 41, AC[1]); L.vl(9, 41, 46, AC[0]); L.vl(22, 41, 46, AC[0])                    # la viga y las patas
    L.r(19, 35, 5, 2, '#e0e4e8'); L.p(20, 35, RJ[1])                                            # la revista
    L.contorno(K); suelo(L, 6, 25, K)
    return L

def cafeM():
    """la máquina de café de 1,8 m: el frente negro con la foto de la taza, los botones, el panel y el hueco del vaso"""
    L = Lienzo(32, 48)
    L.r(8, 18, 16, 28, '#2e2e36'); L.vl(8, 18, 45, '#44444e'); L.vl(23, 18, 45, NG[0])
    L.r(10, 20, 9, 9, '#6a3a1e'); L.r(12, 23, 5, 4, '#f4f4ee'); L.hl(12, 16, 23, '#c89a5a')     # la foto de la taza de café
    for y in range(21, 29, 2): L.r(20, y, 2, 1, '#e0b030')                                       # los botones
    L.r(10, 31, 12, 3, '#3a6a4a'); L.r(11, 32, 4, 1, '#8ae0a0')                                 # el visor
    L.r(12, 37, 8, 5, NG[0]); L.r(15, 40, 2, 2, '#f4f4ee')                                       # el hueco del vaso con uno
    L.contorno(K); suelo(L, 8, 23, K)
    return L

for f in (floorTc, floorTc2, floorTc3, floorTcR, floorTcT, floorTd, floorTg, floorTr):
    sale(f.__name__, f(), 'interior-taller')
for f in (mangT, calT, lavabT, rackT, extinT, bidonT, gatoT, gruaT, cajonT, sillaT, cafeM):
    sale(f.__name__, f(), 'taller-alto')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
