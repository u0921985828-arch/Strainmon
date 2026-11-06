# python3 -I tools/sprites/a-mano/fachada_puerta.py  (Python 3 + Pillow; no va en los scripts de npm)
# La casa gris con puerta (1.10): la fachada aprobada (procesado/edificio-gray/base) con las dos ventanas de abajo separadas 9 px
# hacia los lados, para que la puerta (la del piso, 32 × 32 en x 32, y 64, sin su pared) quepa entera entre las dos. Solo mueve
# píxeles que ya están en la fachada: misma paleta. Sale a art/crudo/edificio-gray-puerta/base/unica/00.png (después,
# node tools/sprites/procesar.js edificio-gray-puerta --atlas)
import os
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
PARED = (246, 232, 200, 255)
DX = 9                        # lo que se separa cada ventana
FILAS = range(67, 95)         # planta baja, del friso al zócalo (la última fila, la del suelo, no se toca)
VENT = [(13, 41, -DX), (53, 81, DX)]   # columnas de cada ventana (con su sombra) y hacia dónde va

def main():
    base = Image.open(os.path.join(ROOT, 'art/procesado/edificio-gray/base/unica/00.png')).convert('RGBA')
    p = base.load()
    out = base.copy()
    q = out.load()
    # 1: la planta baja, lisa entre el borde izquierdo (x 0) y la bajante (x 92-95), quitando ventanas y manchas
    for y in FILAS:
        for x in range(1, 92):
            q[x, y] = PARED
    # 2: las manchas que había fuera de las ventanas, en su sitio (las de debajo de la puerta las tapa la puerta)
    for y in FILAS:
        for x in list(range(1, 13)) + list(range(42, 53)) + list(range(82, 92)):
            q[x, y] = p[x, y]
    # 3: cada ventana, 9 px hacia fuera (solo lo que no es pared lisa: marco, contraventanas, cristal, alféizar y sombra)
    for x0, x1, d in VENT:
        for y in FILAS:
            for x in range(x0, x1 + 1):
                if p[x, y] != PARED:
                    q[x + d, y] = p[x, y]
    os.makedirs(os.path.join(ROOT, 'art/crudo/edificio-gray-puerta/base/unica'), exist_ok=True)
    out.save(os.path.join(ROOT, 'art/crudo/edificio-gray-puerta/base/unica/00.png'))

if __name__ == '__main__':
    main()
