# python3 -I tools/sprites/a-mano/carpa_c.py  (Python 3 + Pillow; no va en los scripts de npm)
# La vista C (la carpa por dentro) con la tela plateada (mylar) y el armazón negro de las carpas aprobadas del piso y de la vista B
# (1.10, aprobada el 2026-10-08 como «prueba B»). Misma geometría que la imagen A, para que todo lo demás de la vista C siga igual:
# pared del fondo x 44-195 e y 3-140 (vcFondo la recorta al ancho de cada carpa), laterales de 44 px (fijos, con los postes del
# fondo en sus 2 últimas columnas, que si no se irían con el recorte) y suelo y 141-159. El suelo dibujado se abre 24 px por lado
# (el de la imagen A, unos 16, los que usa el motor para colocar las macetas): la diferencia no se ve con las macetas puestas.
#  · carpa-c-pared: dibujada en código. Mylar con vetas verticales (como la vista B) y algún brillo; laterales más oscuros hacia
#    delante; bandeja blanca con su rejilla; techo, postes y bordes en el negro del armazón; la cremallera de la puerta abierta.
#  · carpa-c-luz: la de la imagen A (art/procesado) sin los brillos pintados en las cortinas (los laterales por encima del suelo);
#    el cono y el charco del suelo, igual. Se puede pasar más de una vez (borrar lo borrado no cambia nada).
# Sale a art/crudo/carpa-c-fondo/carpa-c-<pared|luz>/unica/00.png (después, node tools/sprites/procesar.js carpa-c-fondo --atlas)
import os
from PIL import Image
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..')
P_ = lambda *a: os.path.join(ROOT, *a)
W, H = 240, 160
N0, N1, N2 = (30, 31, 35), (42, 43, 48), (58, 60, 68)                 # armazón negro
P = [(108, 116, 130), (126, 134, 148), (162, 169, 182), (178, 184, 196), (200, 204, 214), (242, 244, 248), (248, 248, 248)]
hs = lambda x, k=0: ((x * 73856093) ^ (k * 19349663)) & 1023               # hash fijo por columna
im = Image.new('RGBA', (W, H), N1 + (255,)); p = im.load()
def pon(x, y, c):
    if 0 <= x < W and 0 <= y < H: p[x, y] = c + (255,)
XL, XR, YT, YB = 44, 195, 3, 140                                           # pared del fondo (con sus postes)
def diag(y):                                                               # borde del suelo en el lateral izquierdo, de (42,140) a (18,159)
    return XL - 2 - (y - YB) * 24 / 19
# laterales: tela plateada de lado, más oscura hacia delante; las arrugas son verticales (en un punto de fuga siguen verticales)
for x in range(4, XL - 2):
    t = (x - 4) / (XL - 4)                                                 # 0 delante, 1 al fondo
    base = P[1] if t < .3 else (P[2] if t < .7 else P[3])
    for y in range(4, H):
        if x < diag(y) or y <= YB:
            c = base
            k = hs(x, 1) % 9
            if k == 0: c = P[min(len(P) - 1, P.index(base) + 2)]
            elif k == 1: c = P[max(0, P.index(base) - 1)]
            pon(x, y, c); pon(W - 1 - x, y, c)
# pared del fondo: mylar con vetas verticales (como la vista B) y algún brillo
for x in range(XL, XR + 1):
    k = hs(x, 2) % 11
    for y in range(YT, YB):
        c = P[4]
        if k in (0, 1): c = P[5]
        elif k == 2: c = P[3]
        if k == 0 and hs(x, y // 6) % 5 == 0: c = P[6]
        pon(x, y, c)
    # sombra bajo el techo y junto al suelo
    for y in range(YT, YT + 3): pon(x, y, P[3])
    for y in range(YB - 3, YB): pon(x, y, P[3] if hs(x, 7) % 3 else P[2])
# suelo: la bandeja blanca con su rejilla (líneas a lo largo hacia el fondo y travesaños más juntos al fondo)
for y in range(YB + 1, H):
    xa = diag(y)
    for x in range(int(xa) + 1, W - int(xa) - 1):
        c = P[5]
        u = (x - 120) / (120 - xa)                                         # -1..1 a lo ancho
        if abs((u * 7) - round(u * 7)) < .07: c = P[3]
        pon(x, y, c)
for y in (143, 147, 152, 158):
    xa = diag(y)
    for x in range(int(xa) + 1, W - int(xa) - 1): pon(x, y, P[3])
# esquinas y armazón negro: techo, postes del fondo, borde del suelo, postes de delante
for x in range(W):
    for y in range(0, YT): pon(x, y, N1)
    pon(x, YT, N2)
# los postes del fondo van en las 2 últimas columnas de cada lateral (vcFondo recorta la pared del fondo al ancho de la carpa)
for y in range(YT, YB + 1):
    for x in (XL - 2, XL - 1): pon(x, y, N1); pon(W - 1 - x, y, N1)
for x in range(XL - 2, XR + 3): pon(x, YB, N1)
for y in range(YB, H):
    xa = round(diag(y))
    for d in (0, 1): pon(xa - d, y, N1); pon(W - 1 - xa + d, y, N1)
for x in range(0, 4):
    for y in range(H): pon(x, y, N0 if x < 2 else N1); pon(W - 1 - x, y, N0 if x < 2 else N1)
# las cremalleras de la puerta abierta, a cada lado (la tela recogida contra el poste de delante)
for y in range(4, H):
    for x in (4, 5):
        c = P[0] if x == 4 else P[1]
        if (y // 2) % 2: c = N2
        pon(x, y, c); pon(W - 1 - x, y, c)

def guarda(im, capa):
    f = P_('art', 'crudo', 'carpa-c-fondo', 'carpa-c-' + capa, 'unica', '00.png')
    os.makedirs(os.path.dirname(f), exist_ok=True); im.save(f)

guarda(im, 'pared')
luz = Image.open(P_('art', 'procesado', 'carpa-c-fondo', 'carpa-c-luz', 'unica', '00.png')).convert('RGBA'); q = luz.load()
for y in range(141):
    for x in list(range(0, 44)) + list(range(196, 240)): q[x, y] = (0, 0, 0, 0)
guarda(luz, 'luz')
