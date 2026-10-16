# python3 -I tools/sprites/a-mano/ocio.py  (Python 3 + Pillow; no va en los scripts de npm)
# 1.47 (lo pidió el usuario): todo de frente a 3/4, como los sofás y el billar de los clubs, nunca en isométrica.
#  · iconos-fumar (icono 16 × 16): el librillo de papel, los filtros, el tabaco de liar, el mechero (estanco); el grinder, la pipa
#    de cristal, el bong y el vaporizador (los del grow, en sus vitrinas). Genéricos, sin marcas.
#  · interior-estanco (casillas de 16 × 16): floorE (terrazo crema), iwT_est (pared crema con la moldura), iwB_est (el friso de
#    madera); floorV (la moqueta del reservado de GAUA).
#  · ocio-ancho (mueble_ancho, 48 × 48, base en (16, 47), centrado en x 24): la estantería de las cajetillas (colores lisos, sin
#    marcas), el mostrador con la vitrina de los mecheros, la vitrina del grow con los bongs y las pipas (iluminada), la mesa baja
#    de los clubs de dos casillas en cada estilo (w-mesita, w-mesita-<estilo>) y las escaleras de GAUA (la que sube y la que baja).
#  · ocio-alto (mueble_escala, 32 × 48): el humidificador de puros y el expositor giratorio del papel.
#  · ocio-16 (objeto_1x1): el rótulo de la T del estanco, colgado de la fachada.
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js <grupos> --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P, azar
from salon import suelo

SAL = {}
def sale(n, L, grupo):
    SAL.setdefault(grupo, {})[n] = L

K = '#2a2a34'
VID, VIDL, CROMO, CROMOD = '#a8d4e0', '#e0f4f8', '#c8ccd0', '#8a8e96'
W0, W1, W2, W3 = '#4a2e1c', '#62402a', '#74502e', '#a87646'

# ---------------------------------------------------------------------------------------------------------- iconos
def i_papel():
    L = Lienzo(16, 16)
    L.r(3, 5, 10, 7, '#b83a2c'); L.hl(3, 12, 5, '#d85a48'); L.hl(3, 12, 11, '#7a2018')     # la tapa del librillo
    L.r(4, 3, 8, 2, '#f4f4ee'); L.hl(4, 11, 3, '#ffffff')                                     # la hoja que asoma
    L.r(5, 7, 6, 2, '#f0d070')                                                                 # la franja de la tapa
    L.contorno(K); return L

def i_filtros():
    L = Lienzo(16, 16)
    L.r(3, 4, 10, 9, '#d8e8f0'); L.hl(3, 12, 4, '#f4f8fc'); L.vl(12, 5, 12, '#a8c0cc')       # la bolsita
    for x in (4, 7, 10):
        for y in (6, 9): L.r(x, y, 2, 2, '#ffffff'); L.p(x + 1, y + 1, '#d0ccc0')             # los filtros
    L.hl(3, 12, 3, '#3a7ad0')                                                                  # el cierre
    L.contorno(K); return L

def i_tabaco():
    L = Lienzo(16, 16)
    L.r(2, 5, 12, 8, '#3a5a3a'); L.hl(2, 13, 5, '#4e7a4e'); L.hl(2, 13, 12, '#22381e')        # la petaca
    L.r(2, 3, 12, 3, '#2e4a2e'); L.hl(3, 12, 3, '#4e7a4e')                                     # la solapa
    L.r(4, 8, 8, 3, '#c89a5a'); L.p(6, 9, '#8a5a2a'); L.p(9, 9, '#8a5a2a')                    # el tabaco por la ventana
    L.contorno(K); return L

def i_mechero():
    L = Lienzo(16, 16)
    L.r(5, 6, 6, 8, '#3a7ad0'); L.vl(5, 6, 13, '#6a9ae8'); L.vl(10, 6, 13, '#2a5aa0')          # el cuerpo
    L.r(5, 3, 6, 3, CROMO); L.hl(5, 10, 3, '#f0f0f4'); L.p(9, 4, CROMOD)                       # la cabeza
    L.r(6, 4, 2, 1, '#5a5e66')                                                                 # la ruedecita
    L.contorno(K); return L

def i_grinder():
    L = Lienzo(16, 16)
    L.r(3, 5, 10, 3, '#5aa04a'); L.hl(3, 12, 5, '#84cc6c')                                     # la tapa
    L.r(3, 8, 10, 5, '#3f8a46'); L.hl(3, 12, 10, '#2a5a30'); L.vl(3, 8, 12, '#5aa04a')         # el cuerpo, en piezas
    for x in range(4, 12, 2): L.p(x, 6, '#2a5a30')                                             # el moleteado
    L.contorno(K); return L

def i_pipa():
    L = Lienzo(16, 16)
    L.r(2, 6, 6, 5, '#5a9ad0'); L.hl(3, 6, 6, '#a8d4f0'); L.p(4, 8, '#2a2a34')                # la cazoleta
    L.r(8, 8, 6, 2, '#5a9ad0'); L.hl(8, 13, 8, '#a8d4f0')                                      # la boquilla
    L.p(3, 9, '#e060c0'); L.p(6, 10, '#e060c0'); L.p(11, 9, '#e060c0')                         # las vetas del cristal
    L.contorno(K); return L

def i_bong():
    L = Lienzo(16, 16)
    L.r(6, 1, 4, 9, VID); L.vl(6, 1, 9, VIDL)                                                  # el tubo
    L.r(4, 10, 8, 4, VID); L.hl(4, 11, 10, VIDL); L.r(5, 12, 6, 2, '#6aa8c0')                 # la base con el agua
    L.p(11, 8, CROMOD); L.p(12, 7, CROMOD); L.p(12, 6, CROMO)                                  # la cazoleta
    L.contorno(K); return L

def i_vapo():
    L = Lienzo(16, 16)
    L.r(5, 3, 6, 11, '#3a3c44'); L.vl(5, 3, 13, '#5a5e66'); L.hl(5, 10, 3, '#5a5e66')          # el cuerpo
    L.r(6, 1, 4, 2, '#1e2026')                                                                  # la boquilla
    L.p(8, 6, '#40e0a0'); L.p(7, 6, '#40e0a0')                                                  # la luz
    L.r(7, 9, 2, 2, CROMOD)                                                                     # el botón
    L.contorno(K); return L

# ---------------------------------------------------------------------------------------------------------- casillas
def floorE():
    L = Lienzo(16, 16); R = azar(4771)
    L.r(0, 0, 16, 16, '#e0d4bc')
    for _ in range(18): L.p(int(R() * 16), int(R() * 16), ('#c8b89c', '#a89880', '#f0e8d4')[int(R() * 3)])
    L.hl(0, 15, 15, '#c4b498'); L.vl(15, 0, 15, '#c4b498')
    return L

def iwT_est():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 16, '#efe4c8')
    L.r(0, 0, 16, 2, '#7a3a2a'); L.hl(0, 15, 2, '#5a2a1e')                                       # la moldura granate
    return L

def iwB_est():
    L = Lienzo(16, 16)
    L.r(0, 0, 16, 5, '#efe4c8')
    L.r(0, 5, 16, 11, W1); L.hl(0, 15, 5, W3); L.hl(0, 15, 6, W2)                                # el friso
    for x in (0, 8): L.vl(x, 7, 14, W0); L.r(x + 2, 8, 4, 5, W2)                                 # los cuarterones
    L.hl(0, 15, 15, W0)
    return L

def floorV():
    L = Lienzo(16, 16); R = azar(4772)
    L.r(0, 0, 16, 16, '#3a1a4a')
    for _ in range(16): L.p(int(R() * 16), int(R() * 16), '#4a2a5e' if R() < .6 else '#2e1238')
    return L

# ---------------------------------------------------------------------------------------------------------- muebles de 2 casillas
CAJ = (('#f4f4ee', '#c83a2c'), ('#f4f4ee', '#3a6ac8'), ('#d8b048', '#8a6a18'), ('#f4f4ee', '#3f8a46'), ('#2a2a34', '#c8ccd0'),
       ('#c83a2c', '#f4f4ee'), ('#5a4a8a', '#f4f4ee'), ('#f4f4ee', '#e08a2a'))
def estanteE():
    """la estantería de las cajetillas detrás del mostrador (2 m × 2,2 m): madera, cinco baldas y las cajetillas de colores lisos"""
    L = Lienzo(48, 48); x0, x1 = 8, 39; R = azar(4773)
    L.r(x0, 11, 32, 36, W0); L.r(x0, 11, 32, 3, W2); L.hl(x0, x1, 11, W3)                          # el copete
    L.vl(x0, 14, 46, W2); L.vl(x1, 14, 46, W1); L.vl(23, 14, 46, W1); L.vl(24, 14, 46, W2)
    for i, y in enumerate((20, 26, 32, 38, 44)):
        L.hl(x0 + 1, x1 - 1, y, W3)                                                                 # la balda
        for x in range(x0 + 2, x1 - 1, 3):
            if x in (22, 23, 24, 25): continue
            a, b = CAJ[int(R() * len(CAJ))]
            L.r(x, y - 4, 2, 4, a); L.hl(x, x + 1, y - 2, b)                                         # la cajetilla y su franja
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def mostrE():
    """el mostrador del estanco (2 m × 1 m): el frente de madera con la vitrina de los mecheros, y encima la caja y el expositor"""
    L = Lienzo(48, 48); x0, x1 = 8, 39
    L.r(x0, 31, 32, 3, W3); L.hl(x0, x1, 31, '#c8955a')                                              # el tablero
    L.r(x0, 34, 32, 12, W1); L.hl(x0, x1, 45, W0)
    L.r(x0 + 3, 35, 26, 7, VID); L.hl(x0 + 3, x1 - 3, 35, VIDL)
    L.hl(x0 + 3, x1 - 3, 42, CROMOD); L.vl(x0 + 3, 35, 42, CROMOD); L.vl(x1 - 3, 35, 42, CROMOD)
    for j, x in enumerate(range(x0 + 5, x1 - 4, 2)):                                                # los mecheros en fila
        L.r(x, 38, 1, 3, ('#c83a2c', '#3a7ad0', '#3f8a46', '#e0b040', '#e060c0')[j % 5]); L.p(x, 37, CROMO)
    L.r(x0 + 3, 26, 9, 5, '#3a3c44'); L.r(x0 + 4, 27, 7, 2, '#5aa04a'); L.hl(x0 + 3, x0 + 11, 26, '#5a5e66')  # la caja registradora
    L.r(x1 - 10, 27, 8, 4, '#2a2a34'); L.hl(x1 - 10, x1 - 3, 27, CROMOD)                              # el expositor de librillos
    for j, x in enumerate(range(x1 - 9, x1 - 3, 2)): L.r(x, 28, 1, 2, ('#b83a2c', '#f4f4ee', '#3a6ac8')[j % 3])
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def vitrinaP():
    """la vitrina del grow (2 m × 1,9 m): cristal con el marco negro, la luz arriba y cuatro baldas con bongs, pipas, grinders y vapos"""
    L = Lienzo(48, 48); x0, x1 = 8, 39
    L.r(x0, 16, 32, 31, '#2a2a34'); L.r(x0 + 2, 18, 28, 27, '#d8eef4')                               # el marco y el fondo iluminado
    L.hl(x0 + 2, x1 - 2, 18, '#ffffff')                                                               # la tira de luz
    L.vl(23, 18, 44, '#2a2a34'); L.vl(24, 18, 44, '#3a3a44')                                          # las dos puertas
    for y in (25, 32, 39): L.hl(x0 + 2, x1 - 2, y, '#a8c8d4')                                         # las baldas de cristal
    # arriba, los bongs
    for x, c in ((11, '#a8d4e0'), (16, '#a8e0b8'), (27, '#d0b0e8'), (33, '#a8d4e0')):
        L.r(x, 19, 2, 5, c); L.r(x - 1, 22, 4, 3, c); L.p(x + 2, 21, CROMOD)
    # las pipas
    for x, c in ((11, '#5a9ad0'), (16, '#e060c0'), (27, '#40c0a0'), (32, '#e0b040')):
        L.r(x, 29, 3, 2, c); L.r(x + 3, 30, 2, 1, c); L.p(x + 1, 29, '#2a2a34')
    # los grinders
    for x, c in ((11, '#3f8a46'), (15, '#8a8e96'), (27, '#c83a2c'), (31, '#3a7ad0')):
        L.r(x, 35, 3, 3, c); L.hl(x, x + 2, 35, '#f4f4ee')
    # los vapos y sus cajas
    for x in (11, 16, 28, 33): L.r(x, 41, 2, 4, '#3a3c44'); L.p(x, 42, '#40e0a0')
    L.p(x0 + 3, 20, '#ffffff'); L.p(x0 + 4, 21, '#ffffff')                                            # el reflejo
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def mesa_ancha(W, extra):
    """la mesa baja de los sofás (1,4 m × 45 cm) de frente a 3/4, como los sofás: el tablero visto un poco desde arriba, el canto y
    las patas; y lo de encima"""
    L = Lienzo(48, 48); x0, x1 = 13, 34; T0, T1, T2, T3 = W
    L.r(x0, 38, 22, 4, T2); L.hl(x0, x1, 38, T3)                                                      # el tablero, en perspectiva
    L.r(x0, 42, 22, 2, T1); L.hl(x0, x1, 43, T0)                                                      # el canto
    for x in (x0 + 1, x1 - 1): L.vl(x, 44, 46, T0)                                                    # las patas
    extra(L)
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def cosas_club(L):
    L.r(16, 37, 4, 2, CROMOD); L.p(17, 37, '#3a3a40')                                                 # el cenicero
    L.r(22, 36, 3, 3, '#3f8a46'); L.hl(22, 24, 36, '#84cc6c')                                          # el grinder
    L.r(28, 38, 3, 1, '#f4f4ee'); L.p(31, 38, '#b83a2c')                                               # el librillo

def w_mesita():
    return mesa_ancha(('#4a2e1c', '#62402a', '#74502e', '#a87646'), cosas_club)

def w_mesita_kalea():
    def e(L):
        L.r(17, 35, 2, 3, '#f0e8d0'); L.p(17, 34, '#f0d070'); L.p(17, 33, '#ffb040')                   # la vela
        L.r(22, 36, 4, 2, '#a85a3a'); L.p(23, 36, '#6a3a24')                                            # el cenicero de barro
        L.r(28, 36, 2, 2, '#3f8a46')
    L = mesa_ancha(('#2e1e12', '#4a3020', '#6a4a30', '#8a6440'), e)
    return L

def w_mesita_itsaso():
    """el baúl de marinero de mesa: madera con los flejes de latón y una botella con un barco dentro"""
    L = Lienzo(48, 48); x0, x1 = 13, 34; B0, B1, B2 = '#5a3a20', '#8a5e34', '#a87646'
    L.r(x0, 37, 22, 3, B2); L.hl(x0, x1, 37, '#c8955a')                                               # la tapa, vista desde arriba
    L.r(x0, 40, 22, 6, B1); L.hl(x0, x1, 45, B0); L.hl(x0, x1, 40, B0)
    for x in (x0 + 3, x1 - 3): L.vl(x, 37, 45, '#c8a040')                                             # los flejes
    L.r(23, 42, 2, 2, '#c8a040')                                                                       # el cierre
    L.r(19, 34, 7, 3, VID); L.hl(19, 25, 34, VIDL); L.p(26, 35, B1); L.p(21, 35, '#f4f4ee'); L.p(22, 35, B0)  # la botella y el barco
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def w_mesita_fundicion():
    """dos bidones de 200 L con un tablón encima"""
    L = Lienzo(48, 48); x0, x1 = 12, 35; B0, B1, B2 = '#5a2418', '#8a3a24', '#a84e30'
    for bx in (14, 27):
        L.r(bx, 39, 7, 8, B1); L.vl(bx, 39, 46, B2); L.vl(bx + 6, 39, 46, B0); L.hl(bx, bx + 6, 42, B0); L.p(bx + 3, 44, '#c88a4a')
    L.r(x0, 36, 24, 3, '#a87646'); L.hl(x0, x1, 36, '#c8955a'); L.hl(x0, x1, 38, '#5a3a24')            # el tablón
    L.r(19, 34, 3, 2, CROMOD); L.p(20, 34, '#3a3a40')                                                  # el cenicero de lata
    L.r(27, 33, 2, 3, '#8a5a2a'); L.p(27, 32, '#c8a040')                                               # la botella
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def w_mesita_ensanche():
    """la mesa de centro de cristal con patas de acero, una revista y una planta"""
    L = Lienzo(48, 48); x0, x1 = 13, 34
    L.r(x0, 38, 22, 3, VID); L.hl(x0, x1, 38, VIDL); L.hl(x0, x1, 41, '#8ab4c0')
    for x in (x0 + 1, x1 - 1): L.vl(x, 42, 46, CROMOD)
    L.hl(x0 + 2, x1 - 2, 44, CROMO)                                                                    # la balda de abajo
    L.r(17, 36, 6, 2, '#e8e4d8'); L.hl(17, 22, 36, '#c04848')                                          # la revista
    L.r(27, 36, 3, 2, '#f4f4ee'); L.p(27, 35, '#3f8a46'); L.p(28, 34, '#5aa04a'); L.p(29, 35, '#3f8a46')
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def escaleraD():
    """la escalera de GAUA al reservado (2 m): sube hacia el fondo, peldaños negros con la tira de luz y las barandillas de cromo"""
    L = Lienzo(48, 48); x0, x1 = 9, 38
    for i in range(7):                                                                                 # de abajo (cerca) a arriba (lejos)
        y = 44 - i * 5; a = i // 2
        L.r(x0 + 2 + a, y - 3, 26 - 2 * a, 4, '#1e1628'); L.hl(x0 + 2 + a, x1 - 2 - a, y - 3, '#3a3448')
        L.hl(x0 + 2 + a, x1 - 2 - a, y, '#40e0f0' if i % 2 == 0 else '#ff4fc8')
    for s in (0, 1):                                                                                   # las barandillas
        xa, xb = (x0, x0 + 3) if s == 0 else (x1, x1 - 3)
        for y in range(10, 46):
            x = round(xa + (xb - xa) * (46 - y) / 36)
            L.p(x, y, CROMO)
        for y in (46, 28, 10): L.vl(round(xa + (xb - xa) * (46 - y) / 36), y - 6 if y > 10 else y, y, CROMOD)
    L.contorno(K)
    return L

def escaleraDB():
    """la escalera que baja del reservado a la pista: el hueco con los primeros peldaños y la barandilla de cromo alrededor"""
    L = Lienzo(48, 48); x0, x1 = 9, 38
    L.r(x0 + 2, 38, 26, 9, '#0e0a14')                                                                  # el hueco
    for i in range(3):
        y = 39 + i * 3
        L.hl(x0 + 3 + i, x1 - 3 - i, y, '#3a3448'); L.hl(x0 + 3 + i, x1 - 3 - i, y + 1, '#40e0f0' if i % 2 == 0 else '#ff4fc8')
    L.hl(x0, x1, 32, CROMO); L.hl(x0, x1, 33, CROMOD)                                                  # el pasamanos de atrás
    for x in (x0, x0 + 10, x1 - 10, x1): L.vl(x, 32, 46, CROMOD); L.p(x, 32, '#f0f0f4')
    L.vl(x0, 33, 46, CROMO); L.vl(x1, 33, 46, CROMO)
    L.contorno(K)
    return L

# ---------------------------------------------------------------------------------------------------------- de una casilla, altos
def humidor():
    """el humidificador de puros (60 cm × 1,6 m): madera con la puerta de cristal y las cajas de puros dentro"""
    L = Lienzo(32, 48); x0, x1 = 8, 23
    L.r(x0, 21, 16, 26, W1); L.r(x0, 21, 16, 2, W3); L.hl(x0, x1, 46, W0)
    L.r(x0 + 2, 24, 12, 18, '#5a3a24'); L.hl(x0 + 2, x1 - 2, 24, '#8a5a34')
    for y in (29, 35, 41): L.hl(x0 + 2, x1 - 2, y, W3)
    for y in (26, 32, 38):
        for x in (x0 + 3, x0 + 8): L.r(x, y, 4, 3, '#c89a5a'); L.hl(x, x + 3, y, '#e0c08a'); L.p(x + 1, y + 1, '#b83a2c')
    L.p(x0 + 3, 25, VIDL); L.p(x0 + 4, 26, VIDL)
    L.r(x1 - 2, 32, 1, 3, '#c8a040')                                                                   # el tirador
    L.contorno(K); suelo(L, x0, x1, K)
    return L

def papelE():
    """el expositor giratorio del papel de fumar (1,5 m): el pie, la barra y los librillos colgados en tres pisos"""
    L = Lienzo(32, 48); R = azar(4774)
    L.r(11, 45, 10, 2, '#3a3c44'); L.vl(15, 22, 45, CROMOD); L.vl(16, 22, 45, CROMO)
    for y in (24, 31, 38):
        L.hl(9, 22, y, CROMOD)
        for x in range(9, 23, 3):
            L.r(x, y + 1, 2, 4, ('#b83a2c', '#f4f4ee', '#3a6ac8', '#e0b040', '#3f8a46', '#2a2a34')[int(R() * 6)]); L.p(x, y + 1, '#ffffff')
    L.r(13, 19, 6, 3, '#b83a2c'); L.hl(13, 18, 19, '#f0d070')                                          # el cartelito, sin letras
    L.contorno(K); suelo(L, 9, 22, K)
    return L

def rotuloE():
    """el rótulo del estanco: la placa granate con la T amarilla, colgada de su palomilla"""
    L = Lienzo(16, 16)
    L.hl(1, 14, 1, '#3a3a40'); L.vl(1, 1, 3, '#3a3a40')                                                # la palomilla
    L.r(3, 3, 11, 12, '#7a2a24'); L.hl(3, 13, 3, '#9a3a30'); L.hl(3, 13, 14, '#5a1a14')
    L.r(5, 5, 7, 2, '#f0c030'); L.r(7, 7, 3, 6, '#f0c030'); L.hl(5, 11, 5, '#ffe070')                 # la T
    L.contorno(K)
    return L

for n, f in (('papel', i_papel), ('filtros', i_filtros), ('tabaco', i_tabaco), ('mechero', i_mechero), ('grinder', i_grinder),
             ('pipa', i_pipa), ('bong', i_bong), ('vapo', i_vapo)):
    sale(n, f(), 'iconos-fumar')
for n, f in (('floorE', floorE), ('iwT_est', iwT_est), ('iwB_est', iwB_est), ('floorV', floorV)):
    sale(n, f(), 'interior-estanco')
for n, f in (('estanteE', estanteE), ('mostrE', mostrE), ('vitrinaP', vitrinaP), ('w-mesita', w_mesita), ('w-mesita-kalea', w_mesita_kalea),
             ('w-mesita-itsaso', w_mesita_itsaso), ('w-mesita-fundicion', w_mesita_fundicion), ('w-mesita-ensanche', w_mesita_ensanche),
             ('escaleraD', escaleraD), ('escaleraDB', escaleraDB)):
    sale(n, f(), 'ocio-ancho')
sale('humidor', humidor(), 'ocio-alto'); sale('papelE', papelE(), 'ocio-alto')
sale('rotuloE', rotuloE(), 'ocio-16')

def escribe(raiz=None):
    for g, S in SAL.items():
        for n, L in S.items():
            d = os.path.join(raiz, g, n) if raiz else P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe(sys.argv[1] if len(sys.argv) > 1 else None)
