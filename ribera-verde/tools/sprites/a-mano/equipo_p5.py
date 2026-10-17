# python3 -I tools/sprites/a-mano/equipo_p5.py  (Python 3 + Pillow; no va en los scripts de npm)
# Láminas 12 y 13 del plan de producción (1.10, P5), dibujadas a mano:
#  · iconos-equipo (celda icono, 16 × 16): armario, carpa, led (de barras), ventilador, filtro, garrafa y goteo, para la tienda, la mochila y
#    la lista de plantas (icono(nombre) los busca aquí si no están en «iconos»). Contorno oscuro, 3 tonos con la luz arriba a la
#    izquierda, como los iconos aprobados.
#  · props-escala (celda mueble_escala, 32 × 48, base en (16, 47)): la nevera (obj:fridge, 60 × 180 cm) y las cajas de 40 cm
#    (obj:crate: dos abajo y una encima) a 16 px/m, el frente a su ancho y alto reales y la tapa vista desde arriba a medio fondo,
#    como las carpas del piso.
# Sale a art/crudo/<grupo>/<sprite>/unica/00.png (después, node tools/sprites/procesar.js <grupo> --atlas)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

K = '#2a2a34'                                                  # contorno de los iconos aprobados
SAL = {}

def sale(grupo, n, L):
    SAL.setdefault(grupo, {})[n] = L

# ---------- lámina 12: iconos ----------
T0, T1, T2, T3 = '#1c1d22', '#2e3038', '#45474e', '#6a6e78'   # tela negra de la carpa: sombra, medio, luz y brillo
PL0, PL1, PL2 = '#8a909c', '#b2b8c4', '#d4d8e2'                # mylar del techo
def tienda(w, h):
    """carpa cerrada de frente: techo plateado, tela negra, la puerta de cremallera en U y los postes"""
    L = Lienzo(16, 16); x0 = (16 - w) // 2; x1 = x0 + w - 1; y0 = 15 - h
    L.r(x0, y0, w, 2, PL1); L.hl(x0, x1, y0, PL2)
    L.r(x0, y0 + 2, w, h - 2, T1)
    L.vl(x0, y0 + 2, 14, T2); L.vl(x1, y0 + 2, 14, T0)
    cx = (x0 + x1) // 2
    for y in range(y0 + 4, 14): L.p(cx - 2, y, T3); L.p(cx + 2, y, T3)
    L.hl(cx - 2, cx + 2, y0 + 3, T3)
    L.p(cx + 2, y0 + 5, PL2)                                   # el tirador
    L.contorno(K)
    return L

def led():
    """LED de barras (1.10, como los de 720 W) visto desde abajo: 4 barras con la cara de diodos encendida (blanca, algún rosa) y aire
    entre ellas, los travesaños de delante y de detrás, la fuente encima y dos cuerdas"""
    L = Lienzo(16, 16)
    L.vl(3, 0, 4, T1); L.vl(12, 0, 4, T1)
    L.r(6, 2, 4, 2, '#304046'); L.p(8, 2, '#e8644c')
    L.hl(1, 14, 4, '#3d4c4e'); L.hl(1, 14, 13, '#3d4c4e'); L.p(1, 4, '#7a8584')   # travesaños
    for bx in (1, 5, 9, 13):                                    # barras de 2 px con 2 de aire
        for y in range(5, 13):
            for x in (bx, bx + 1): L.p(x, y, '#f8d8ff' if (x + 2 * y) % 3 == 0 else '#ffffff')
    L.contorno(K)
    return L

def ventilador():
    """ventilador de pinza: rejilla redonda con 3 aspas y la pinza abajo"""
    L = Lienzo(16, 16); cx, cy = 7.5, 6.5
    for y in range(16):
        for x in range(16):
            d = ((x + .5 - 8) ** 2 + (y + .5 - 7) ** 2) ** .5
            if d <= 6: L.p(x, y, '#e8eaee' if d > 5 else '#5a5e68')
    for x, y in ((7, 3), (8, 3), (8, 4), (11, 7), (11, 8), (10, 8), (4, 9), (5, 9), (5, 10), (6, 5), (9, 10), (4, 6)):
        L.p(x, y, '#c8ccd6')
    L.r(7, 6, 2, 2, '#26262e')
    for y in range(1, 13):
        for x in range(2, 14):
            if L.lleno(x, y) and (x + y) % 3 == 0 and L.g(x, y)[:3] == (90, 94, 104): L.p(x, y, '#45474e')
    L.r(7, 13, 2, 1, '#45474e'); L.r(5, 14, 6, 1, '#26262e')
    L.contorno(K)
    return L

def filtro():
    """filtro de carbón: cilindro de chapa perforada con el extractor encima y el tubo"""
    L = Lienzo(16, 16)
    L.r(6, 0, 4, 2, '#b2b8c4'); L.hl(6, 9, 1, '#8a909c')
    L.r(5, 2, 6, 3, '#45474e'); L.hl(5, 10, 2, '#6a6e78')
    L.r(3, 5, 10, 10, '#5e6068')
    L.vl(3, 5, 14, '#787a82'); L.vl(4, 5, 14, '#787a82'); L.vl(12, 5, 14, '#3a3c44'); L.vl(11, 5, 14, '#45474e')
    for y in range(6, 14, 2):
        for x in range(4 + (y // 2) % 2, 12, 2): L.p(x, y, '#2e3036')
    L.hl(3, 12, 5, '#9a9ca4'); L.hl(3, 12, 14, '#3a3c44')
    L.contorno(K)
    return L

def garrafa():
    """garrafa de riego translúcida con asa, tapón con gotero y el agua a media altura"""
    L = Lienzo(16, 16)
    L.r(4, 3, 8, 12, '#e6eef2')
    L.r(4, 9, 8, 6, '#9ab8cc'); L.hl(4, 11, 9, '#b8d0de')
    L.vl(4, 3, 14, '#ffffff'); L.vl(11, 3, 14, '#c0ccd4')
    L.r(9, 1, 3, 2, '#e6eef2'); L.p(10, 1, '#c0ccd4')          # el asa
    L.r(5, 1, 3, 2, '#3a7ad0'); L.p(5, 1, '#6aa0e8')            # el tapón
    L.vl(6, 0, 0, '#1c1d22')                                    # el gotero
    L.contorno(K)
    return L

def goteo():
    """riego por goteo: depósito con su mirilla, la bomba y la manguera con dos goteros"""
    L = Lienzo(16, 16)
    L.r(1, 2, 8, 11, '#3a3c44'); L.vl(1, 2, 12, '#5e6068'); L.hl(1, 8, 2, '#787a82')
    L.r(3, 4, 2, 7, '#16263a'); L.r(3, 7, 2, 4, '#8ec8f0')     # la mirilla con el agua
    L.r(6, 10, 3, 3, '#202e34'); L.p(7, 11, '#e8644c')          # la bomba
    L.hl(9, 14, 12, '#1c1d22'); L.hl(9, 14, 11, '#4a4c54')
    for x in (11, 14):
        L.p(x, 13, '#1c1d22'); L.p(x, 15, '#8ec8f0')            # gotero y su gota
    L.contorno(K)
    return L

sale('iconos-equipo', 'armario', tienda(9, 14))
sale('iconos-equipo', 'carpa', tienda(14, 12))
sale('iconos-equipo', 'led', led())
sale('iconos-equipo', 'ventilador', ventilador())
sale('iconos-equipo', 'filtro', filtro())
sale('iconos-equipo', 'garrafa', garrafa())
sale('iconos-equipo', 'goteo', goteo())

# ---------- lámina 13: muebles a escala (16 px/m) ----------
def nevera():
    """nevera de 60 × 180 × 60 cm: frente de 10 × 29 px y la tapa de 5 (medio fondo), congelador abajo, tiradores y rejilla"""
    L = Lienzo(32, 48); x0, x1 = 11, 20; yt, yf = 13, 18                # tapa (filas 13-17) y frente (18-47)
    B0, B1, B2, B3 = '#7a8494', '#a8b2c0', '#d0d8e2', '#eef2f6'
    L.r(x0, yt, 10, 5, B2); L.hl(x0, x1, yt, B3); L.hl(x0, x1, yt + 4, B1)
    L.r(x0, yf, 10, 30, B2)
    L.vl(x0, yf, 47, B3); L.vl(x1, yf, 47, B1); L.vl(x1 - 1, yf, 47, B2)
    L.hl(x0, x1, 37, B0)                                          # la puerta del frigorífico arriba, la del congelador abajo
    L.vl(x1 - 2, yf + 3, yf + 10, B0); L.vl(x1 - 2, 40, 43, B0)   # tiradores
    L.hl(x0 + 1, x1 - 1, 46, B1); L.hl(x0 + 2, x1 - 2, 47, B0)    # rejilla del zócalo
    L.p(x0 + 2, yf + 2, '#4a9ae0')                                # el piloto
    o = Lienzo(32, 48); o.pega(L, 0, 0); o.contorno('#3a3e48')
    for x in range(x0, x1 + 1): o.p(x, 47, '#3a3e48')             # apoya en el suelo: la última fila, contorno
    return o

def cajas():
    """cajas de 40 cm (madera, como las de la conservera): dos abajo y una encima, frente de 6 × 6 y tapa de 3"""
    L = Lienzo(32, 48); M0, M1, M2, M3 = '#5a3a1e', '#8a5a2c', '#b07a40', '#d4a060'
    def caja(x, y):                                               # (x, y): esquina de arriba a la izquierda de la tapa
        L.r(x, y, 7, 3, M2); L.hl(x, x + 6, y, M3)
        L.r(x, y + 3, 7, 7, M1)
        L.hl(x, x + 6, y + 3, M3); L.hl(x, x + 6, y + 6, M0); L.hl(x, x + 6, y + 9, M0)
        L.vl(x, y + 3, y + 9, M2); L.vl(x + 6, y + 3, y + 9, M0)
    caja(9, 37); caja(16, 37); caja(12, 30)
    L.contorno('#2a1a0e')
    for x in range(8, 24):
        if L.lleno(x, 46) and not L.lleno(x, 47): L.p(x, 47, '#2a1a0e')
    return L

sale('props-escala', 'fridge', nevera())
sale('props-escala', 'crate', cajas())

def escribe():
    for g, S in SAL.items():
        for n, L in S.items():
            d = P('art', 'crudo', g, n, 'unica'); os.makedirs(d, exist_ok=True)
            for f in glob.glob(os.path.join(d, '*.png')): os.remove(f)
            L.im.save(os.path.join(d, '00.png'))
            print(g, n, L.im.getbbox(), len(L.colores()), 'colores')

if __name__ == '__main__':
    escribe()
