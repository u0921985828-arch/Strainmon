# python3 -I tools/sprites/a-mano/sala_fria.py  (Python 3 + Pillow)
# La sala fría del sótano (lo pidió el usuario: una habitación fría para las extracciones): el evaporador del equipo de frío en la pared
# (frioF: la caja blanca con sus dos ventiladores, las lamas y el termómetro a 4 °C) y la mesa de acero inoxidable (mesaF). 16 × 16,
# celda objeto_1x1, de frente; contorno de los muebles (#2a2a34). Sale a art/crudo/sala-fria/<sprite>/unica/00.png (después,
# node tools/sprites/procesar.js sala-fria --atlas --atlas-dir godot/arte)
import os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lienzo import Lienzo, P

K = '#2a2a34'
B0, B1, B2 = '#a8b0b8', '#d8dee4', '#f2f6f8'
AC0, AC1, AC2 = '#7a8088', '#b4bac2', '#e0e6ea'

def frio():
    L = Lienzo(16, 16)
    L.r(1, 3, 14, 8, B1); L.hl(1, 14, 3, B2); L.hl(1, 14, 10, B0)
    for cx in (5, 10):                                   # los dos ventiladores, con su rejilla
        L.r(cx - 2, 4, 5, 5, '#3a4048'); L.p(cx, 6, '#8a929a')
        L.p(cx - 1, 5, '#5a6068'); L.p(cx + 1, 7, '#5a6068')
    for x in range(2, 14, 2): L.p(x, 9, B0)              # las lamas de abajo
    L.r(13, 4, 1, 4, '#4a92e0'); L.p(13, 7, '#e8f4ff')   # el termómetro, frío
    L.hl(3, 12, 12, '#9ab0c0'); L.p(7, 13, '#9ab0c0')    # el aire frío que baja
    L.contorno(K)
    return L

def mesa():
    L = Lienzo(16, 16)
    L.r(1, 6, 14, 3, AC1); L.hl(1, 14, 6, AC2); L.hl(1, 14, 8, AC0)   # el tablero de acero
    L.p(4, 7, AC2); L.p(11, 7, AC2)
    for x in (2, 13):                                    # las patas y la balda de abajo
        L.vl(x, 9, 14, AC0)
    L.hl(2, 13, 12, AC1)
    L.r(5, 3, 3, 3, '#e8e8f0'); L.hl(5, 7, 3, '#ffffff')              # un bote de hielo
    L.r(9, 4, 4, 2, '#5aa04a'); L.p(10, 4, '#84cc6c')                 # un puñado de cogollos
    L.contorno(K)
    for x in range(16):
        if L.lleno(x, 14) and not L.lleno(x, 15): L.p(x, 15, K)
    return L

if __name__ == '__main__':
    for n, f in (('frioF', frio), ('mesaF', mesa)):
        d = P('art', 'crudo', 'sala-fria', n, 'unica')
        os.makedirs(d, exist_ok=True)
        for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
        L = f(); L.im.save(os.path.join(d, '00.png'))
        print('sala-fria', n, L.im.getbbox(), len(L.colores()), 'colores')
