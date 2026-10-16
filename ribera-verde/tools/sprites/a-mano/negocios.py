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
#  · negocios-ancho (mueble_ancho, 48 × 48, pies en (16, 47); la casilla de la derecha, <k>2, no se pinta): elevT (el elevador de
#    dos columnas con un coche subido), fosoT / fosoB (el foso, la mitad de arriba y la de abajo), bancoT (el banco de trabajo con
#    el tornillo y el panel de herramientas), boxL (el box de lavado con un coche y la espuma), cubaQ (la cuba de cuajar), mostrQ
#    (el mostrador de los quesos), hornoP (el horno de leña), mostrP (el mostrador del pan), doblaL (la mesa de doblar)
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js negocios-16 negocios-alto
# negocios-ancho --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

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

def coche(L, x0, y0, col=('#2a4a7a', '#3a64a0', '#6a94c8')):
    """un utilitario de perfil, de juguete (28 × 12 px): carrocería, cristales y las ruedas gordas"""
    C0, C1, C2 = col
    L.r(x0 + 6, y0, 14, 5, C1); L.hl(x0 + 7, x0 + 18, y0, C2)                      # la cabina
    L.r(x0 + 8, y0 + 1, 5, 3, '#a8d0e0'); L.r(x0 + 14, y0 + 1, 5, 3, '#a8d0e0')     # los cristales
    L.r(x0, y0 + 5, 28, 5, C1); L.hl(x0, x0 + 27, y0 + 5, C2); L.hl(x0, x0 + 27, y0 + 9, C0)
    L.p(x0 + 27, y0 + 6, '#f4e8a0'); L.p(x0, y0 + 6, '#c03030')                    # los faros
    for cx in (x0 + 6, x0 + 21):
        L.r(cx - 3, y0 + 8, 6, 5, '#1a1a1e'); L.r(cx - 1, y0 + 9, 2, 2, '#9a9ea8')

# ---------- lo de todos ----------
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
    """el almacén del club: estantería de acero de 2 m con las cajas de cartón y los tarros por lo lleno (0, 1 o 2)"""
    L = Lienzo(32, 32); x0, x1 = 6, 25
    for x in (x0, x1): L.vl(x, 2, 30, AC[1])
    for y in (9, 17, 25): L.hl(x0, x1, y, AC[2]); L.hl(x0 + 1, x1 - 1, y + 1, AC[0])
    L.hl(x0, x1, 2, AC[3])
    if n >= 1:
        for x in range(x0 + 2, x1 - 3, 5):                                            # los tarros de arriba
            L.r(x, 5, 3, 4, '#cfe2e6'); L.r(x, 7, 3, 2, '#5a8a3a'); L.hl(x, x + 2, 4, '#2a2a30')
        L.r(x0 + 2, 20, 7, 5, '#c8a070'); L.hl(x0 + 2, x0 + 8, 20, '#e0bc8a'); L.vl(x0 + 5, 20, 24, '#a07a50')
    if n >= 2:
        for x in range(x0 + 2, x1 - 2, 4):                                            # los botes de las extracciones
            L.r(x, 14, 3, 3, '#2a2a30'); L.hl(x, x + 2, 14, '#d89a18')
        L.r(x0 + 11, 20, 7, 5, '#c8a070'); L.hl(x0 + 11, x0 + 17, 20, '#e0bc8a')
        L.r(x0 + 3, 28, 12, 2, '#c8a070')
    L.contorno(K); sombra(L, x0, x1, 31)
    return L

# ---------- el taller (Valdehierro) ----------
def elevT():
    """el elevador de dos columnas (3 t): las columnas rojas, los brazos y un utilitario subido a 1,2 m"""
    L = Lienzo(48, 48)
    for x in (8, 37):
        L.r(x, 8, 3, 39, RJ[1]); L.vl(x, 8, 46, RJ[2]); L.vl(x + 2, 8, 46, RJ[0])
        L.hl(x - 1, x + 3, 46, AC[0])
    L.hl(8, 39, 8, RJ[0])                                                             # el travesaño de arriba
    L.hl(11, 36, 30, AC[1]); L.hl(11, 36, 31, AC[0])                                  # los brazos
    coche(L, 10, 17)
    L.r(20, 42, 8, 2, AM[1]); L.hl(20, 27, 42, AM[2])                                 # la marca del suelo
    L.contorno(K)
    return L

def foso(arriba):
    """el foso de 1,2 m: el hueco oscuro con el borde amarillo y negro; arriba, la escalera; abajo, la lámpara de mano"""
    L = Lienzo(48, 48); x0, x1, y0, y1 = 10, 37, 32, 47
    L.r(x0, y0, x1 - x0 + 1, y1 - y0 + 1, '#2a2a30')
    L.r(x0 + 2, y0, x1 - x0 - 3, y1 - y0 + 1, '#16161a')
    for y in range(y0, y1 + 1):
        c = AM[1] if (y // 2) % 2 else '#1a1a1e'
        L.p(x0, y, c); L.p(x0 + 1, y, c); L.p(x1, y, c); L.p(x1 - 1, y, c)
    if arriba:
        for x in range(x0, x1 + 1): L.p(x, y0, AM[1] if (x // 2) % 2 else '#1a1a1e')
        for y in range(y0 + 3, y1, 3): L.hl(x0 + 4, x0 + 9, y, AC[1])                  # los peldaños
        L.vl(x0 + 4, y0 + 2, y1, AC[2]); L.vl(x0 + 9, y0 + 2, y1, AC[2])
    else:
        for x in range(x0, x1 + 1): L.p(x, y1, AM[1] if (x // 2) % 2 else '#1a1a1e')
        L.r(26, 38, 3, 2, '#f4e8a0'); L.vl(27, 40, 44, '#e0b030')                     # la lámpara de mano
        L.r(16, 42, 4, 2, '#3a3a40')                                                  # la bandeja del aceite
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
    L = Lienzo(16, 16)
    for i, y in enumerate((11, 8, 5, 2)):
        L.r(2, y, 12, 3, '#1e1e22'); L.hl(3, 12, y, '#3a3a40'); L.hl(5, 10, y + 1, '#0e0e10')
    L.contorno(K); sombra(L, 2, 13, 15)
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
    """el box de lavado: el arco de la lanza, la pared de azulejo y un coche con la espuma rosa"""
    L = Lienzo(48, 48)
    L.r(8, 6, 32, 26, '#d0e0e8')
    for y in range(8, 30, 4): L.hl(8, 39, y, '#b0c4cc')
    L.r(10, 9, 4, 6, '#3a3a42'); L.vl(12, 15, 26, '#2a2a30'); L.r(11, 26, 3, 3, AC[2])   # la lanza colgada
    coche(L, 11, 30, ('#7a2020', '#b83030', '#e06060'))
    for (x, y) in ((14, 33), (18, 31), (24, 32), (30, 34), (35, 33), (20, 36)):        # la espuma
        L.r(x, y, 3, 2, '#f4d0e0'); L.p(x + 1, y, '#ffffff')
    L.contorno(K)
    for x in range(8, 40): L.p(x, 47, '#6a8a9a')                                      # la rejilla del suelo
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
    """los bidones de 25 L del champú, la cera y el desengrasante, en su palé"""
    L = Lienzo(32, 32)
    L.r(6, 27, 20, 3, MA[1]); L.hl(6, 25, 27, MA[3])
    for i, (x, y) in enumerate(((7, 17), (13, 17), (19, 17), (10, 8), (16, 8))):
        c = ('#2a6ac0', '#e0e0d8', '#2a8a4a', '#e0b030', '#c04040')[i]
        L.r(x, y, 6, 10 if y == 17 else 9, c); L.vl(x, y, y + 8, '#ffffff60'); L.r(x + 1, y - 1, 2, 1, '#2a2a30')
    L.contorno(K); sombra(L, 6, 25, 31)
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
    """la estantería de madera de la cámara de curación con las ruedas de queso"""
    L = Lienzo(32, 32); x0, x1 = 6, 25
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
for n, f in (('armR', armR), ('tabique', tabique), ('recambT', recambT), ('prodL', prodL), ('curaQ', curaQ), ('panP', panP)):
    sale(n, f(), 'negocios-alto')
for i in range(3):
    sale(f'almC-{i}', almC(i), 'negocios-alto')
for n, f in (('elevT', elevT), ('bancoT', bancoT), ('boxL', boxL), ('cubaQ', cubaQ), ('mostrQ', mostrQ), ('hornoP', hornoP),
             ('mostrP', mostrP), ('doblaL', doblaL)):
    sale(n, f(), 'negocios-ancho')
sale('fosoT', foso(True), 'negocios-ancho')
sale('fosoB', foso(False), 'negocios-ancho')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
