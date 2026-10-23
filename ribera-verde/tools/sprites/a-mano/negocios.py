# python3 -I tools/sprites/a-mano/negocios.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.45 (lo pidió el usuario: «que tú puedas acceder a ese sitio y controlarlo desde ahí… el taller, bien diseñado, el foso
# también… tanto el taller como los demás negocios que puedes alquilar»; y «un cuartucho con una cama pequeña, una mesita, un
# escritorio con una silla y un armario», y en el club «el almacén»): los seis locales por dentro, a 16 px/m como el resto.
# Todo genérico, sin marcas ni rótulos de nadie.
#  · negocios-16 (objeto_1x1, 16 × 16, pies en (8, 15)): cajaL (la caja registradora en su mostrador), fregona (el cubo con la
#    fregona), neumT (neumáticos apilados), compT (el compresor), aspiraL (el aspirador industrial), fichasL (la máquina de
#    fichas), barrilT (barriles de cerveza), prensaQ (la prensa de quesos), amasaP (la amasadora), lavaL (la lavadora de carga
#    frontal), secaL (la secadora), cambioL (la máquina de cambio), mesaC (el escritorio pequeño del cuartucho)
#  · negocios-alto (objeto_alto, 32 × 32, pies en (16, 31)): armR (el armario ropero), recambT (la estantería de recambios),
#    prodL (los bidones de productos), curaQ (la estantería de curación con los quesos), panP (el estante de los panes),
#    tabique (el tabique de pladur del cuartucho, de canto), almC-<0|1|2> (el almacén del club por lo lleno)
#  · negocios-coche (vehiculo_expo, 80 × 48, 5 casillas): elevT y fosoT (1.46) y boxL (1.47, el box de lavado con el utilitario)
#  · negocios-ancho (mueble_ancho, 48 × 48, pies en (16, 47); la casilla de la derecha, <k>2, no se pinta): elevT (el elevador de
#    dos columnas con un coche subido), fosoT / fosoB (el foso, la mitad de arriba y la de abajo), bancoT (el banco de trabajo con
#    el tornillo y el panel de herramientas), cubaQ (la cuba de cuajar), mostrQ
#    (el mostrador de los quesos), hornoP (el horno de leña), mostrP (el mostrador del pan), doblaL (la mesa de doblar)
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js negocios-16 negocios-alto
# negocios-ancho --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P
from concesionario import utilitario, berlina

K = '#2a2a34'   # el contorno de los muebles (el de salon.py)
SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

AC = ('#4a4e56', '#7a7e88', '#a8acb4', '#ccd0d6')   # el acero
MA = ('#4a2e1c', '#74502e', '#a87646', '#c8955a')   # la madera
RJ = ('#7a1e1e', '#b83030', '#e05a4a')              # el rojo de taller
AM = ('#a07a10', '#e0b030', '#f4d870')              # el amarillo de seguridad
SOMBRA = '#00000040'

def sombra(L, x0, x1, y):
    for x in range(x0, x1 + 1):
        if L.g(x, y) is None or L.g(x, y)[3] == 0:
            L.p(x, y, SOMBRA)

def cajaL():
    L = Lienzo(16, 16)
    L.r(1, 9, 14, 6, MA[1]); L.hl(1, 14, 9, MA[3]); L.hl(1, 14, 14, MA[0])           # el mostrador
    L.r(4, 4, 8, 5, '#3a3a42'); L.r(5, 5, 4, 2, '#7ac08a'); L.p(10, 5, '#e0b030')    # la caja, con su pantalla
    L.hl(4, 11, 8, '#5a5a62'); L.p(6, 7, '#c8c8c0'); L.p(8, 7, '#c8c8c0')
    L.r(10, 2, 2, 2, '#5a5a62')                                                       # el visor del cliente
    L.contorno(K); sombra(L, 1, 14, 15)
    return L

def fregona():
    L = Lienzo(16, 16)
    L.r(4, 9, 8, 6, '#2a6ac0'); L.hl(4, 11, 9, '#5a9ae0'); L.hl(4, 11, 14, '#1a4a8a')  # el cubo
    L.r(9, 8, 3, 2, '#e8e8e0')                                                        # el escurridor
    L.vl(7, 0, 10, '#c8b088'); L.r(5, 9, 5, 2, '#e8e0c8')                             # el palo y la fregona
    L.contorno(K)
    return L

def mesaC():
    """el escritorio pequeño del cuartucho: tablero de pino, el flexo, una libreta y la silla metida debajo"""
    L = Lienzo(16, 16)
    L.r(1, 7, 14, 3, MA[2]); L.hl(1, 14, 7, MA[3]); L.hl(1, 14, 9, MA[0])
    L.vl(2, 10, 15, MA[1]); L.vl(13, 10, 15, MA[1])
    L.vl(11, 2, 6, AC[1]); L.r(9, 1, 3, 2, '#e0b030')                                 # el flexo
    L.r(3, 5, 4, 2, '#f0f0e8'); L.p(4, 5, '#4a7ac0')                                  # la libreta
    L.r(5, 11, 6, 2, '#3a3a42'); L.vl(5, 13, 15, '#2a2a30'); L.vl(10, 13, 15, '#2a2a30')   # la silla
    L.contorno(K)
    return L

def armR():
    """el armario ropero de una puerta y media (80 × 190 cm): melamina de haya, los tiradores y el espejo"""
    L = Lienzo(32, 32); x0, x1 = 9, 22
    L.r(x0, 2, x1 - x0 + 1, 29, MA[2]); L.hl(x0, x1, 2, MA[3]); L.vl(x1, 3, 30, MA[1])
    L.vl(16, 4, 29, MA[0])                                                            # la junta de las puertas
    L.r(x0 + 2, 5, 4, 12, '#b8d0d8'); L.vl(x0 + 2, 5, 16, '#e0f0f4')                 # el espejo
    L.p(15, 17, AC[3]); L.p(17, 17, AC[3])                                            # los tiradores
    L.hl(x0, x1, 30, MA[0])
    L.contorno(K); sombra(L, x0, x1, 31)
    return L

def tabique():
    """el tabique de pladur de canto (10 cm), de suelo a techo: el canto blanco y la cara en sombra"""
    L = Lienzo(32, 32)
    L.r(13, 0, 6, 31, '#d8d4c8'); L.hl(13, 18, 0, '#f0ece0'); L.vl(18, 1, 30, '#b8b4a8')
    L.hl(13, 18, 29, '#8a8478'); L.hl(13, 18, 30, '#6a6458')                          # el rodapié
    L.contorno(K)
    return L

def almC(n):
    """el almacén del club: estantería de acero de 2 m de alto y 0,9 m de ancho (una casilla, lo pidió el usuario: «son muy anchas
    para la baldosa»), con las cajas de cartón y los tarros por lo lleno (0, 1 o 2); en fila, los contornos se tocan como en un almacén"""
    L = Lienzo(32, 32); x0, x1 = 9, 22
    for x in (x0, x1): L.vl(x, 2, 30, AC[1])
    for y in (9, 17, 25): L.hl(x0, x1, y, AC[2]); L.hl(x0 + 1, x1 - 1, y + 1, AC[0])
    L.hl(x0, x1, 2, AC[3])
    if n >= 1:
        for x in (x0 + 2, x0 + 7):                                                     # los tarros de arriba
            L.r(x, 5, 3, 4, '#cfe2e6'); L.r(x, 7, 3, 2, '#5a8a3a'); L.hl(x, x + 2, 4, '#2a2a30')
        L.r(x0 + 2, 20, 5, 5, '#c8a070'); L.hl(x0 + 2, x0 + 6, 20, '#e0bc8a'); L.vl(x0 + 4, 20, 24, '#a07a50')
    if n >= 2:
        for x in (x0 + 2, x0 + 6, x0 + 10):                                            # los botes de las extracciones
            L.r(x, 14, 2, 3, '#2a2a30'); L.hl(x, x + 1, 14, '#d89a18')
        L.r(x0 + 7, 20, 5, 5, '#c8a070'); L.hl(x0 + 7, x0 + 11, 20, '#e0bc8a')
        L.r(x0 + 2, 28, 10, 2, '#c8a070')
    L.contorno(K); sombra(L, x0, x1, 31)
    return L

# ---------- el taller (Valdehierro) ----------
def elevT():
    """1.46 (lo pidió el usuario: «usa esas medidas… a escala»): el elevador de cuatro columnas a 16 px/m, de 5 m (80 px), con
    las rampas a 1,2 m (19 px) y el utilitario de 4 m del concesionario (concesionario.py) subido encima"""
    L = Lienzo(80, 48); sube = 19
    c = utilitario()
    for y in range(0, 48 - sube):
        for x in range(80):
            v = c.g(x, y + sube)
            if v is not None and v[3] and y + sube < 46: L.p(x, y, '#%02x%02x%02x' % v[:3])
    for x in (2, 74):                                                                # las columnas de 2,1 m (34 px)
        L.r(x, 12, 4, 34, RJ[1]); L.vl(x, 12, 45, RJ[2]); L.vl(x + 3, 12, 45, RJ[0])
        L.r(x - 1, 45, 6, 2, AC[0]); L.hl(x - 1, x + 4, 12, RJ[0])
    L.r(0, 30, 4, 7, AC[1]); L.hl(0, 3, 30, AC[3])                                   # el motor con el grupo hidráulico
    L.r(1, 32, 2, 2, AM[1])
    for x0, x1 in ((2, 77),):                                                        # la rampa (pista) y su travesaño
        L.r(x0, 27, x1 - x0 + 1, 3, AC[1]); L.hl(x0, x1, 27, AC[3]); L.hl(x0, x1, 29, AC[0])
        L.r(x0, 30, 6, 2, AC[0]); L.r(x1 - 5, 30, 6, 2, AC[0])
    L.vl(5, 30, 44, '#2a2a30')                                                       # la manguera del hidráulico
    L.hl(10, 69, 46, AM[1])                                                          # la marca amarilla del suelo
    for x in range(10, 70, 4): L.p(x, 46, '#1a1a1e')
    L.contorno(K)
    return L

def fosoT():
    """1.46: el foso a 16 px/m, de 5 m de largo (80 px) y 1,2 m de hondo, con el borde amarillo y negro, la escalera, la lámpara
    y la berlina de 4,8 m del concesionario aparcada encima, con una rueda a cada lado"""
    L = Lienzo(80, 48); x0, x1, y0, y1 = 1, 78, 37, 47
    L.r(x0, y0, x1 - x0 + 1, y1 - y0 + 1, '#2a2a30')
    L.r(x0 + 2, y0 + 2, x1 - x0 - 3, y1 - y0 - 1, '#16161a')
    for x in range(x0, x1 + 1):
        c = AM[1] if (x // 3) % 2 else '#1a1a1e'
        L.p(x, y0, c); L.p(x, y0 + 1, c); L.p(x, y1, c)
    for y in range(y0, y1 + 1):
        c = AM[1] if (y // 2) % 2 else '#1a1a1e'
        L.p(x0, y, c); L.p(x1, y, c)
    for y in range(y0 + 3, y1, 2): L.hl(x0 + 3, x0 + 7, y, AC[1])                     # la escalera
    L.vl(x0 + 3, y0 + 2, y1 - 1, AC[2]); L.vl(x0 + 7, y0 + 2, y1 - 1, AC[2])
    c = berlina(); baja = 6                                                           # el coche, sobre los bordes del foso
    for y in range(0, 46 - baja):
        for x in range(80):
            v = c.g(x, y + baja)
            if v is not None and v[3]: L.p(x, y, '#%02x%02x%02x' % v[:3])
    L.r(40, 42, 3, 2, '#f4e8a0'); L.p(41, 44, '#e0b030')                              # la lámpara de mano, al fondo
    L.r(58, 44, 7, 2, '#3a3a40'); L.hl(58, 64, 44, '#5a5a62')                         # la bandeja del aceite
    return L

def diagT():
    """1.46: la cabina de diagnosis en su carro (el ordenador, la pantalla y el cable al coche), sin marcas"""
    L = Lienzo(32, 32); x0, x1 = 9, 22
    L.r(x0, 14, 14, 15, AC[1]); L.vl(x0, 14, 28, AC[2]); L.vl(x1, 14, 28, AC[0])
    for y in (19, 24): L.hl(x0 + 1, x1 - 1, y, AC[0])
    L.r(x0 + 1, 3, 12, 9, '#2a2a30'); L.r(x0 + 2, 4, 10, 6, '#2a5a7a')                 # la pantalla
    L.hl(x0 + 3, x0 + 8, 6, '#7ad0e0'); L.hl(x0 + 3, x0 + 6, 8, '#58c070')
    L.vl(x0 + 6, 12, 13, AC[0])
    L.r(x0 + 2, 15, 8, 2, '#3a3a42')                                                   # el teclado
    L.vl(x1 + 1, 16, 26, '#1a1a1e'); L.p(x1 + 2, 26, '#e0b030')                        # el cable OBD
    for x in (x0 + 1, x1 - 1): L.p(x, 29, '#1a1a1e'); L.p(x, 30, '#1a1a1e')            # las ruedas
    L.contorno(K); sombra(L, x0, x1 + 2, 31)
    return L

def equiT():
    """1.46: la equilibradora de ruedas (0,9 m de alto): la caja, el eje con una rueda puesta y la tapa"""
    L = Lienzo(32, 32); x0, x1 = 8, 23
    L.r(x0, 17, 16, 13, AC[2]); L.hl(x0, x1, 17, AC[3]); L.vl(x1, 17, 29, AC[0])
    L.r(x0 + 2, 19, 5, 3, '#2a2a30'); L.p(x0 + 3, 20, '#e04040'); L.p(x0 + 5, 20, '#58c070')
    L.r(x0 + 3, 7, 10, 10, '#1e1e22'); L.r(x0 + 5, 9, 6, 6, '#3a3a40'); L.r(x0 + 7, 11, 2, 2, AC[3])   # la rueda en el eje
    L.r(x1 - 6, 5, 7, 3, RJ[1]); L.hl(x1 - 6, x1, 5, RJ[2])                             # la tapa levantada
    L.contorno(K); sombra(L, x0, x1, 31)
    return L

def bancoT():
    """el banco de trabajo (2 m) con el tornillo de banco, el panel perforado con las herramientas y la caja de cajones roja"""
    L = Lienzo(48, 48); x0, x1 = 9, 38
    L.r(x0, 6, 30, 18, '#8a7a5a')                                                     # el panel perforado
    for y in range(8, 23, 3):
        for x in range(x0 + 2, x1 - 1, 3): L.p(x, y, '#6a5a40')
    for i, x in enumerate(range(x0 + 3, x1 - 3, 4)):                                  # las llaves y los destornilladores
        L.vl(x, 9, 15 + i % 3, AC[3] if i % 2 else RJ[1]); L.p(x, 9, AC[2])
    L.r(x0, 28, 30, 3, MA[2]); L.hl(x0, x1, 28, MA[3]); L.hl(x0, x1, 30, MA[0])       # el tablero
    L.r(x0 + 2, 25, 5, 3, AC[1]); L.r(x0 + 3, 24, 3, 1, AC[2])                        # el tornillo
    L.r(x1 - 9, 31, 8, 13, RJ[1]); L.vl(x1 - 9, 31, 43, RJ[2])                        # la cajonera
    for y in (34, 37, 40): L.hl(x1 - 8, x1 - 2, y, RJ[0])
    for x in (x0 + 1, x0 + 14): L.vl(x, 31, 45, AC[1])
    L.contorno(K); sombra(L, x0, x1, 46)
    return L

def recambT():
    """la estantería de los recambios: cajas de filtros, bidones de aceite y las pastillas de freno, sin marcas"""
    L = Lienzo(32, 32); x0, x1 = 7, 24
    for x in (x0, x1): L.vl(x, 3, 30, AC[1])
    for y in (10, 18, 26): L.hl(x0, x1, y, AC[2])
    for i, x in enumerate(range(x0 + 2, x1 - 2, 4)):
        L.r(x, 5, 3, 5, ('#2a6ac0', '#e0b030', '#2a8a4a', '#c04040')[i % 4])          # los bidones
    for x in range(x0 + 1, x1 - 3, 5): L.r(x, 13, 4, 5, '#c8a070'); L.hl(x, x + 3, 13, '#e0bc8a')
    L.r(x0 + 2, 21, 6, 5, '#3a3a42'); L.r(x0 + 10, 22, 6, 4, AC[2])                   # una batería y los discos
    L.contorno(K); sombra(L, x0, x1, 31)
    return L

def neumT():
    """tres ruedas de 63 cm (10 px) tumbadas, una encima de otra (20 cm, 3 px cada una), con el agujero de la llanta arriba"""
    L = Lienzo(16, 16)
    for y in (11, 8, 5):
        L.r(3, y, 10, 3, '#2e2e36'); L.hl(3, 12, y, '#44444e'); L.hl(3, 12, y + 2, '#1e1e22')
        for x in (4, 7, 10): L.p(x, y + 1, '#1e1e22')                                    # el dibujo de la banda
    L.hl(5, 10, 3, '#44444e'); L.r(3, 4, 10, 2, '#3a3a42'); L.r(6, 4, 4, 2, '#0e0e10')    # la de arriba, con su hueco
    L.contorno(K); sombra(L, 3, 12, 15)
    return L

def compT():
    L = Lienzo(16, 16)
    L.r(1, 8, 14, 5, RJ[1]); L.hl(1, 14, 8, RJ[2]); L.hl(1, 14, 12, RJ[0])           # el calderín
    L.r(4, 4, 6, 4, AC[1]); L.hl(4, 9, 4, AC[2]); L.r(11, 5, 2, 2, AC[3])             # el motor y el manómetro
    L.p(3, 14, '#1a1a1e'); L.p(12, 14, '#1a1a1e')
    L.vl(14, 3, 8, '#3a3a40')                                                         # la manguera
    L.contorno(K)
    return L

# ---------- el lavadero (los astilleros) ----------
def boxL():
    """1.47 (lo pidió el usuario: «el mobiliario debe de ser a escala realista»): el box de lavado a 16 px/m, de 5 m de largo
    (80 px), con la pared de azulejo de 2,4 m (39 px), las mamparas de los lados, la lanza colgada de su brazo y el utilitario de
    4 m del concesionario (concesionario.py) dentro, con la espuma rosa; la rejilla del suelo de punta a punta"""
    L = Lienzo(80, 48)
    L.r(2, 8, 76, 37, '#d0e0e8')                                                    # la pared de azulejo
    for y in range(10, 44, 4): L.hl(2, 77, y, '#b0c4cc')
    for x in range(6, 78, 8): L.vl(x, 9, 44, '#c0d2da')
    for x in (0, 78):                                                               # las mamparas de los lados
        L.r(x, 6, 2, 41, AC[1]); L.vl(x, 6, 46, AC[3])
    L.hl(2, 77, 6, AC[2]); L.hl(2, 77, 7, AC[0])                                    # el perfil de arriba
    L.r(70, 9, 6, 8, '#3a3a42'); L.r(71, 10, 4, 2, '#e04040'); L.r(71, 13, 4, 1, AM[1])   # el programador de fichas
    L.hl(40, 69, 9, '#2a2a30'); L.vl(40, 9, 20, '#2a2a30'); L.r(39, 20, 3, 3, AC[2])     # el brazo giratorio y la lanza
    c = utilitario()
    for y in range(48):
        for x in range(80):
            v = c.g(x, y)
            if v is not None and v[3]: L.p(x, y, '#%02x%02x%02x' % v[:3])
    for (x, y) in ((14, 30), (20, 25), (28, 24), (36, 26), (46, 28), (54, 31), (62, 33), (24, 36), (40, 35), (58, 38)):   # la espuma
        L.r(x, y, 3, 2, '#f4d0e0'); L.p(x + 1, y, '#ffffff')
    L.contorno(K)
    for x in range(2, 78, 2): L.p(x, 47, '#6a8a9a')                                 # la rejilla del suelo
    return L

def aspiraL():
    L = Lienzo(16, 16)
    L.r(3, 5, 10, 9, AC[2]); L.hl(3, 12, 5, AC[3]); L.vl(12, 6, 13, AC[1])
    L.r(4, 3, 8, 2, '#2a6ac0'); L.p(7, 7, '#e0b030')
    L.vl(1, 4, 12, '#2a2a30'); L.hl(1, 3, 4, '#2a2a30')                               # la manguera
    L.p(4, 14, '#1a1a1e'); L.p(11, 14, '#1a1a1e')
    L.contorno(K)
    return L

def fichasL():
    L = Lienzo(16, 16)
    L.r(4, 2, 8, 13, '#2a6ac0'); L.vl(4, 2, 14, '#5a9ae0'); L.vl(11, 2, 14, '#1a4a8a')
    L.r(6, 4, 4, 3, '#e0f0f4'); L.r(6, 9, 4, 1, '#1a1a1e'); L.r(7, 11, 2, 2, AM[1])
    L.contorno(K)
    return L

def prodL():
    """los bidones de 25 L del champú, la cera y el desengrasante, en su medio palé (una casilla con el contorno)"""
    L = Lienzo(32, 32)
    L.r(9, 27, 14, 3, MA[1]); L.hl(9, 22, 27, MA[3])
    for i, (x, y) in enumerate(((10, 17), (14, 17), (18, 17), (12, 8), (16, 8))):
        c = ('#2a6ac0', '#e0e0d8', '#2a8a4a', '#e0b030', '#c04040')[i]
        L.r(x, y, 4, 10 if y == 17 else 9, c); L.vl(x, y, y + 8, '#ffffff60'); L.r(x + 1, y - 1, 2, 1, '#2a2a30')
    L.contorno(K); sombra(L, 9, 22, 31)
    return L

# ---------- la taberna (Puerto Viejo) ----------
def barrilT():
    L = Lienzo(16, 16)
    for x in (1, 8):
        L.r(x, 5, 7, 10, AC[2]); L.vl(x, 5, 14, AC[3]); L.vl(x + 6, 5, 14, AC[0])
        L.hl(x, x + 6, 7, AC[0]); L.hl(x, x + 6, 12, AC[0]); L.r(x + 2, 4, 3, 1, '#2a2a30')
    L.contorno(K)
    return L

# ---------- la quesería (Mendialde) ----------
def cubaQ():
    """la cuba de cuajar de acero (500 L) con la leche cuajada y la lira apoyada"""
    L = Lienzo(48, 48); x0, x1 = 9, 38
    L.r(x0, 28, 30, 12, AC[2]); L.hl(x0, x1, 28, AC[3]); L.hl(x0, x1, 39, AC[0])
    L.r(x0 + 2, 29, 26, 3, '#f4f0dc'); L.hl(x0 + 2, x1 - 2, 31, '#e0d8b8')            # la cuajada
    for x in (x0 + 2, x1 - 2): L.vl(x, 40, 45, AC[1])
    L.r(x1 - 6, 34, 4, 2, '#3a3a42')                                                  # el grifo
    L.vl(x0 + 6, 18, 30, AC[1]); L.r(x0 + 4, 14, 6, 5, AC[3])                         # la lira
    for y in (15, 17): L.hl(x0 + 4, x0 + 9, y, AC[1])
    L.contorno(K); sombra(L, x0, x1, 46)
    return L

def mostrQ():
    """el mostrador de la quesería con la vitrina y las cuñas de queso de oveja"""
    L = Lienzo(48, 48); x0, x1 = 8, 39
    L.r(x0, 34, 32, 12, MA[1]); L.hl(x0, x1, 34, MA[3]); L.hl(x0, x1, 45, MA[0])
    L.r(x0 + 1, 24, 30, 10, '#d8eef4'); L.hl(x0 + 1, x1 - 1, 24, '#ffffff')          # la vitrina
    for i, x in enumerate(range(x0 + 3, x1 - 4, 7)):
        L.r(x, 29, 5, 4, '#f0d890'); L.hl(x, x + 4, 29, '#a07a3a'); L.p(x + 4, 32, '#e0c070')
    L.r(x1 - 6, 20, 5, 4, '#3a3a42'); L.hl(x1 - 6, x1 - 2, 20, AC[3])                 # la báscula
    L.contorno(K)
    return L

def prensaQ():
    L = Lienzo(16, 16)
    L.r(2, 10, 12, 4, AC[2]); L.hl(2, 13, 10, AC[3])
    for x in (4, 9): L.r(x, 6, 4, 4, '#f4f0dc'); L.hl(x, x + 3, 6, '#ffffff')         # los moldes con el queso
    L.vl(2, 1, 9, AC[1]); L.vl(13, 1, 9, AC[1]); L.hl(2, 13, 2, AC[1]); L.vl(8, 2, 5, '#3a3a42')
    L.p(2, 15, '#1a1a1e'); L.p(13, 15, '#1a1a1e')
    L.contorno(K)
    return L

def curaQ():
    """la estantería de madera de la cámara de curación con las ruedas de queso (90 cm, una casilla con el contorno)"""
    L = Lienzo(32, 32); x0, x1 = 9, 22
    for x in (x0, x1): L.vl(x, 2, 30, MA[1])
    for y in (9, 17, 25): L.hl(x0, x1, y, MA[2]); L.hl(x0 + 1, x1 - 1, y + 1, MA[0])
    for y in (5, 13, 21):
        for x in range(x0 + 2, x1 - 3, 6):
            L.r(x, y, 5, 4, '#e0c070'); L.hl(x, x + 4, y, '#f4dc90'); L.hl(x, x + 4, y + 3, '#a07a3a')
    L.contorno(K); sombra(L, x0, x1, 31)
    return L

# ---------- la panadería (Errotabarri) ----------
def hornoP():
    """el horno de leña: la bóveda de piedra, la boca con las brasas y la pala apoyada"""
    L = Lienzo(48, 48); x0, x1 = 8, 39
    L.r(x0, 16, 32, 30, '#9a8a78'); L.hl(x0 + 4, x1 - 4, 12, '#9a8a78'); L.r(x0 + 2, 13, 28, 3, '#9a8a78')
    for y in range(18, 45, 4):
        for x in range(x0 + 1 + (y // 4) % 2 * 3, x1, 6): L.hl(x, x + 4, y, '#7a6a58')
    L.r(17, 28, 14, 10, '#1a1210'); L.hl(18, 29, 27, '#1a1210')                       # la boca
    for (x, c) in ((19, '#e05a20'), (22, '#f4a030'), (25, '#e05a20'), (27, '#f4d060')): L.r(x, 35, 2, 2, c)
    L.r(16, 38, 16, 2, '#6a5a48')                                                     # el umbral
    L.vl(x1 - 2, 14, 45, MA[2]); L.r(x1 - 4, 42, 5, 3, MA[1])                         # la pala
    L.contorno(K)
    return L

def mostrP():
    """el mostrador del pan: las hogazas, las barras en su cesto y la báscula"""
    L = Lienzo(48, 48); x0, x1 = 8, 39
    L.r(x0, 32, 32, 14, MA[1]); L.hl(x0, x1, 32, MA[3]); L.hl(x0, x1, 45, MA[0])
    for x in (x0 + 2, x0 + 9):
        L.r(x, 28, 6, 4, '#c88a40'); L.hl(x + 1, x + 4, 27, '#e0a858'); L.p(x + 2, 29, '#a06a28')
    L.r(x0 + 17, 26, 7, 6, '#a07a40')                                                 # el cesto
    for x in range(x0 + 18, x0 + 23, 2): L.vl(x, 20, 26, '#d8a050')
    L.r(x1 - 6, 28, 5, 4, AC[1]); L.hl(x1 - 6, x1 - 2, 28, AC[3])
    L.contorno(K)
    return L

def amasaP():
    L = Lienzo(16, 16)
    L.r(3, 4, 10, 10, '#e8e8e0'); L.vl(12, 4, 13, '#c8c8c0'); L.hl(3, 12, 4, '#ffffff')
    L.r(5, 6, 6, 4, AC[2]); L.r(6, 7, 4, 2, '#f0e0b0')                                # la cuba con la masa
    L.r(5, 1, 6, 3, '#e8e8e0'); L.vl(8, 3, 7, AC[1])                                  # el cabezal y el gancho
    L.p(4, 14, '#1a1a1e'); L.p(11, 14, '#1a1a1e')
    L.contorno(K)
    return L

def panP():
    """el estante de rejilla con las hogazas, las chapatas y las barras de pie"""
    L = Lienzo(32, 32); x0, x1 = 7, 24
    for x in (x0, x1): L.vl(x, 3, 30, AC[1])
    for y in (11, 19, 27): L.hl(x0, x1, y, AC[2])
    for x in range(x0 + 2, x1 - 3, 5): L.r(x, 7, 4, 4, '#c88a40'); L.hl(x, x + 3, 7, '#e0a858')
    for x in range(x0 + 1, x1 - 4, 6): L.r(x, 16, 6, 3, '#d89850'); L.hl(x, x + 5, 16, '#f0c070')
    for x in range(x0 + 2, x1 - 1, 2): L.vl(x, 20, 26, '#d8a050'); L.p(x, 20, '#f0c070')
    L.contorno(K); sombra(L, x0, x1, 31)
    return L

# ---------- la lavandería (Ibarbide) ----------
def lavaL(seca=False):
    L = Lienzo(16, 16)
    L.r(1, 1, 14, 14, '#e8e8e0'); L.hl(1, 14, 1, '#ffffff'); L.vl(14, 2, 14, '#c0c0b8')
    L.r(2, 2, 12, 2, '#c8c8c0'); L.p(11, 2, '#58c070'); L.p(4, 2, '#3a3a42')
    L.r(4, 6, 8, 7, AC[1]); L.r(5, 7, 6, 5, '#e0a0a0' if seca else '#7ab0d8')         # el ojo de buey con la ropa
    L.p(6, 8, '#ffffff'); L.p(9, 10, '#4a7ac0' if not seca else '#c06060')
    L.contorno(K)
    return L

def cambioL():
    L = Lienzo(16, 16)
    L.r(4, 1, 8, 14, AC[2]); L.vl(4, 1, 14, AC[3]); L.vl(11, 1, 14, AC[0])
    L.r(6, 3, 4, 3, '#1a3a2a'); L.p(7, 4, '#58c070'); L.r(6, 8, 4, 1, '#1a1a1e'); L.r(6, 11, 4, 2, '#3a3a42')
    L.contorno(K)
    return L

def doblaL():
    """la mesa de doblar: la ropa doblada en montones de colores y el cesto de plástico"""
    L = Lienzo(48, 48); x0, x1 = 9, 38
    L.r(x0, 30, 30, 3, '#e8e8e0'); L.hl(x0, x1, 30, '#ffffff'); L.hl(x0, x1, 32, '#b8b8b0')
    for x in (x0 + 1, x1 - 1): L.vl(x, 33, 45, AC[1])
    for i, x in enumerate((x0 + 2, x0 + 9, x0 + 16)):
        for j in range(3 - i % 2):
            L.r(x, 27 - j * 2, 6, 2, ('#4a7ac0', '#e0e0d8', '#c06060', '#58a070')[(i + j) % 4])
    L.r(x1 - 9, 22, 9, 8, '#4ab0c8'); L.hl(x1 - 9, x1 - 1, 22, '#7ad0e0')               # el cesto
    for y in (24, 26, 28): L.hl(x1 - 8, x1 - 2, y, '#2a8aa0')
    L.contorno(K); sombra(L, x0, x1, 46)
    return L

for n, f in (('cajaL', cajaL), ('fregona', fregona), ('mesaC', mesaC), ('neumT', neumT), ('compT', compT),
             ('aspiraL', aspiraL), ('fichasL', fichasL), ('barrilT', barrilT), ('prensaQ', prensaQ), ('amasaP', amasaP),
             ('lavaL', lavaL), ('cambioL', cambioL)):
    sale(n, f(), 'negocios-16')
sale('secaL', lavaL(True), 'negocios-16')
for n, f in (('armR', armR), ('tabique', tabique), ('recambT', recambT), ('diagT', diagT), ('equiT', equiT), ('prodL', prodL), ('curaQ', curaQ), ('panP', panP)):
    sale(n, f(), 'negocios-alto')
for i in range(3):
    sale(f'almC-{i}', almC(i), 'negocios-alto')
for n, f in (('bancoT', bancoT), ('cubaQ', cubaQ), ('mostrQ', mostrQ), ('hornoP', hornoP),
             ('mostrP', mostrP), ('doblaL', doblaL)):
    sale(n, f(), 'negocios-ancho')
sale('elevT', elevT(), 'negocios-coche')
sale('fosoT', fosoT(), 'negocios-coche')
sale('boxL', boxL(), 'negocios-coche')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
