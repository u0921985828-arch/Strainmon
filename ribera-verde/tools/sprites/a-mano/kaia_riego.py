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
#  · depKm/depKmd y depKl/depKld, los de las carpas de 4 × 2 y de 4 × 4, a su tamaño de verdad (lo pidió el usuario: «los depósitos
#    se deben de dibujar de diferentes tamaños también… lo más realista posible»), unos 25 L por salida del goteo: el bidón de 200 L
#    (56 × 94 cm, 9 × 15 px) con sus dos nervios y sus dos tapones y el depósito de 400 L (69 × 106 cm, 11 × 17 px) con tres nervios
#    y la tapa grande de rosca en el centro, a mano en el estilo del bidón (mismos tonos, mismo contorno), los dos sobre bloques de
#    hormigón como él, para que el grifo quede abajo del todo y a la misma altura (37 cm, la fila 41) que el de 100 L: la manguera
#    del goteo sale siempre por el mismo sitio. De más de una casilla de alto, pero sin pisar nada (sus carpas no tienen otro
#    depósito encima).
# Celda mueble_escala de 32 × 48 con el pie en (16, 47). Sale a art/crudo/kaia-riego/<sprite>/unica/00.png (después,
# node tools/sprites/procesar.js kaia-riego --atlas --atlas-dir godot/arte)
import json, os, sys, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
from carpas import filas, P
from lienzo import Lienzo
from salon import suelo
from huerta_mej import AZ, LA, HO, K

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

def deposito(w, hc, bloques, tapa, izq=False):
    """el depósito azul de w px de ancho y hc de alto de cuerpo, como el bidón de la huerta: el borde de arriba redondo, la luz por la
    izquierda, los nervios, los tapones (dos) o la tapa de rosca (tapa), el grifo de latón en la fila 41 hacia su carpa (a la derecha
    o, con izq, a la izquierda, en las mismas columnas que el bidón en espejo) y los bloques (bloques, desde la columna del cuerpo)"""
    L = Lienzo(32, 48)
    yb = 43; yt = yb - hc + 1
    x0 = 12 if izq else 20 - w; x1 = x0 + w - 1
    for b in bloques:
        x = x0 + (w - 3 - b if izq else b)
        L.r(x, 44, 3, 3, HO[1]); L.hl(x, x + 2, 44, HO[2]); L.vl(x + 2, 45, 46, HO[0])
    L.r(x0, yt, w, hc, AZ[1]); L.hl(x0 + 1, x1 - 1, yt - 1, AZ[1])
    L.vl(x0, yt, yb, AZ[2]); L.vl(x0 + 1, yt, yb, AZ[3]); L.vl(x1, yt, yb, AZ[0]); L.vl(x1 - 1, yt + 1, yb, AZ[0])
    L.hl(x0 + 1, x1 - 1, yt, AZ[2])
    n = 3 if tapa else 2
    for i in range(1, n + 1): L.hl(x0 + 2, x1, yt + round(i * hc / (n + 1)), AZ[0])
    L.hl(x0 + 1, x1 - 1, yb, AZ[0])
    if tapa:
        c = (x0 + x1) // 2
        L.r(c - 2, yt - 2, 5, 1, AZ[0]); L.hl(c - 1, c + 1, yt - 3, AZ[2]); L.p(c - 2, yt - 3, AZ[0]); L.p(c + 2, yt - 3, AZ[0])
    else:
        L.p(x0 + 2, yt - 2, AZ[0]); L.p(x1 - 2, yt - 2, AZ[0])
    if izq: L.r(10, 41, 2, 1, LA[1]); L.p(10, 42, LA[0]); L.p(11, 40, LA[2])
    else: L.r(20, 41, 2, 1, LA[1]); L.p(21, 42, LA[0]); L.p(20, 40, LA[2])
    L.contorno(K); suelo(L, x0, x1, K)
    return L.im

def espejo_grifo(im):
    """el de la derecha de su carpa: el grifo y los cantos en espejo, pero el cuerpo y los bloques (columnas 12 a 19, simétricas) con
    la luz por la izquierda, como todo el juego"""
    out = im.transpose(Image.FLIP_LEFT_RIGHT)
    out.paste(im.crop((12, 0, 20, 48)), (12, 0))
    return out

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
    guarda(espejo_grifo(celda(b, 0)), 'depKd')   # el de la derecha de su carpa, con el grifo hacia ella
    for spr, w, hc, bl, tapa in (('depKm', 9, 15, (0, 5), False), ('depKl', 11, 17, (0, 4, 8), True)):
        guarda(deposito(w, hc, bl, tapa), spr); guarda(deposito(w, hc, bl, tapa, True), spr + 'd')

if __name__ == '__main__':
    main()
