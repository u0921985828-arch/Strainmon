# python3 -I tools/sprites/a-mano/kaia_riego.py  (Python 3 + Pillow; no va en los scripts de npm)
# El rincón del riego de la carpa de sala de KAIA, fuera de ella (lo pidió el usuario: «que tampoco sea el depósito… tendrá que estar
# fuera de las carpas y demás. Esas cosas hay que hacerlas con lógica»): en el paso de delante de la carpa, a la derecha de su
# puerta, sin montarse en ella (lo pidió también: que ningún objeto se superponga a otro), así que de una casilla de alto, 1 m a 16
# px/m. Salen de los de la sala de antes como carpas.py saca las carpas medianas, quitando filas del cuerpo que se repiten (misma
# paleta, mismo contorno):
#  · tanqueKB, el tanque bajo, del tanque de la nave (tanqueN, locales-alto): la tapa azul con su boca y el canto blanco de arriba y,
#    debajo, la mitad de abajo con el agua verde, la mirilla y el pie.
#  · riegoKB, el programador en su mueble bajo, del de la nave (riegoN): las tres dosificadoras, la pantalla, los botones y el pie.
#  · drenKB, el depósito de recogida bajo, del de la sala (o-drenKS, de PixelLab): el tubo de entrada arriba a la izquierda, la tapa,
#    la mirilla y, abajo a la derecha, la bomba que lo devuelve al tanque; de dos casillas, la suya y media de la de su derecha.
#  · depK y depKd, el depósito del goteo de cada carpa de la fase 1, fuera de ella, del bidón azul de la huerta (bidonA, huerta-mej)
#    con una fila del cuerpo menos (de 16 filas: dos seguidos, uno encima de otro, no se montan) y el grifo hacia su carpa: depK,
#    con el grifo a la derecha, a la izquierda de su carpa; depKd, en espejo, a su derecha.
# Celda mueble_escala de 32 × 48 con el pie en (16, 47). Sale a art/crudo/kaia-riego/<sprite>/unica/00.png (después,
# node tools/sprites/procesar.js kaia-riego --atlas --atlas-dir godot/arte)
import json, os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
from carpas import filas, P

ALTO = 16   # una casilla: nada por encima del pie de la carpa de sala

def celda(im, x0):
    """im (ya recortada a lo alto) en la celda de 32 × 48, con su pie en la fila de abajo y su columna 0 en x0"""
    out = Image.new('RGBA', (32, 48), (0, 0, 0, 0))
    out.paste(im, (x0, 48 - im.height), im)
    return out

def guarda(im, spr):
    d = P('art', 'crudo', 'kaia-riego', spr, 'unica')
    os.makedirs(d, exist_ok=True)
    for v in glob.glob(os.path.join(d, '*.png')): os.remove(v)
    im.save(os.path.join(d, '00.png'))
    print('kaia-riego', spr, im.size, im.getbbox(), len({p for p in im.get_flattened_data() if p[3]}), 'colores')

def main():
    tq = Image.open(P('art', 'procesado', 'locales-alto', 'tanqueN', 'unica', '00.png')).convert('RGBA')   # 32 × 32, de la fila 5 a la 31
    rg = Image.open(P('art', 'procesado', 'locales-alto', 'riegoN', 'unica', '00.png')).convert('RGBA')   # de la 6 a la 31
    J = json.load(open(P('godot', 'arte', 'kaia_pl.json'), encoding='utf-8'))
    x, y, w, h = J['r']['o-drenKS']
    dr = Image.open(P('godot', 'arte', 'kaia_pl.png')).convert('RGBA').crop((x, y, x + w, y + h))         # de la fila 2 a la 29
    assert tq.size == rg.size == dr.size == (32, 32), (tq.size, rg.size, dr.size)
    # el tanque: la tapa con su boca y el canto de arriba (5-9) y la mitad de abajo, con la mirilla (21-31)
    t = filas(tq, list(range(5, 10)) + list(range(21, 32)))
    # el programador: las dosificadoras (6-10), el canto y la pantalla (13-17), los botones (21-24) y el pie (30-31)
    r = filas(rg, list(range(6, 11)) + list(range(13, 18)) + list(range(21, 25)) + [30, 31])
    # el depósito: el tubo de entrada y el de la bomba (2-3), la tapa (7-10) y el cuerpo con la mirilla y la bomba (19-28)
    d = filas(dr, [2, 3] + list(range(7, 11)) + list(range(19, 29)))
    bd = Image.open(P('art', 'procesado', 'huerta-mej', 'bidonA', 'unica', '00.png')).convert('RGBA')   # de la 31 a la 47
    assert bd.size == (32, 48) and bd.getbbox()[1] == 31, bd.getbbox()
    # el bidón: la tapa (31-35) y el cuerpo sin la fila 36, que repite la 35, con el grifo y las patas (37-47)
    b = filas(bd, list(range(31, 36)) + list(range(37, 48)))
    for spr, im, x0 in (('tanqueKB', t, 0), ('riegoKB', r, -1), ('drenKB', d, 0), ('depK', b, 0)):   # el programador, una columna a la izquierda: sin tocar el depósito
        assert im.height == ALTO, (spr, im.height)
        guarda(celda(im, x0), spr)
    guarda(celda(b, 0).transpose(Image.FLIP_LEFT_RIGHT), 'depKd')   # el de la derecha de su carpa, con el grifo hacia ella

if __name__ == '__main__':
    main()
