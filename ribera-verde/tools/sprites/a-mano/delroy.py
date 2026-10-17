# python3 -I tools/sprites/a-mano/delroy.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# Delroy (1.32), el «tío» jamaicano que nunca lo fue de papeles: el compañero de la tía Maite. El dibujo de Kiko (aprobado) de
# mayor, con las rastas y la barba canosas, la piel oscura y de don: camisa crema con una cadena fina de oro, pantalón de pinzas
# gris marengo y botas de ante color camel con la suela de crepé clara (nada de los colores de la bandera). Como julen.py, por zonas
# del alto del dibujo, porque Kiko comparte tonos entre el pelo, la piel y la ropa:
# · PELO (y barba), por encima de CUELLO, con las rastas: una columna de cada dos, un tono más oscura, por debajo de la coronilla;
# · TORSO, entre CUELLO y CINTURA (las manos, con la piel; la cadena, de oro, en CADENA);
# · PANTALON, entre CINTURA y PIE, y BOTAS, desde PIE.
# Copia base, idle y fumar de art/procesado/kiko en art/procesado/delroy; repetirlo da lo mismo. Después,
# node tools/sprites/procesar.js delroy --atlas (va en art/manifest.json con su «cubre»).
import os, sys, glob
from PIL import Image

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'procesado')
ORIGEN, NUEVO, ANIMS = 'kiko', 'delroy', ('base', 'idle', 'fumar')
PIEL = {'#d49a74': '#8a5a3c', '#6c4632': '#5a3626'}
PELO = {'#d8a868': '#b4b0a8', '#c8a068': '#9a968e', '#a8805a': '#7a7670', '#e6bc80': '#d8d4cc', '#8c6a46': '#9a968e'}
CAMISA = {'#3f8a46': '#e8e0c8', '#2a6a40': '#c4b898', '#3c3434': '#c4b898'}
MANOS = {'#a8805a': '#5a3626', '#c8a068': '#8a5a3c', '#8c6a46': '#5a3626', '#e6bc80': '#8a5a3c'}
PANTALON = {'#a8805a': '#4a4c56', '#8c6a46': '#3a3c44', '#c8a068': '#5c5e6a', '#6c4632': '#3a3c44', '#3c3434': '#3a3c44', '#e6bc80': '#5c5e6a',
            '#d8a868': '#b08250'}   # el tobillo, de lado: ya es la bota
BOTAS = {'#e6bc80': '#d8b07a', '#8c6a46': '#b08250', '#a8805a': '#b08250', '#c8a068': '#d8b07a', '#6c4632': '#5a3626',
         '#3c3434': '#5a3626', '#dcd6c6': '#efe2c0', '#d49a74': '#d8b07a', '#d8a868': '#d8b07a'}
ORO, RASTA = '#d0a840', '#9a968e'
CORONILLA, CADENA, CUELLO, CINTURA, PIE = .12, (.5, .6), .55, .73, .92
rgb = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
tabla = lambda d: {rgb(a): rgb(b) for a, b in d.items()}
Pi, Pe, Ca, Ma, Pa, Bo = tabla(PIEL), tabla(PELO), tabla(CAMISA), tabla(MANOS), tabla(PANTALON), tabla(BOTAS)
GRIS, NEGRO, RUBIO = rgb(PELO['#d8a868']), rgb('#3c3434'), rgb('#d8a868')

def viste(im, frente=False):
    px = im.load()
    ys = [y for y in range(im.height) if any(px[x, y][3] for x in range(im.width))]
    t, b = ys[0], ys[-1]; alto = b - t + 1
    for y in range(im.height):
        r = (y - t) / alto
        for x in range(im.width):
            p = px[x, y]
            if not p[3]: continue
            c = p[:3]
            if r >= PIE: d = Bo.get(c)
            elif r >= CINTURA: d = Pa.get(c) or Ca.get(c) or Pi.get(c)
            elif c == NEGRO and CADENA[0] < r < CADENA[1]: d = rgb(ORO)
            elif r >= CUELLO: d = Ca.get(c) or Pi.get(c) or Ma.get(c) or (GRIS if c == RUBIO else None)   # el pelo que cae a los hombros
            else:
                d = Ca.get(c) or Pi.get(c) or Pe.get(c)
                if d == GRIS and r > CORONILLA and x % 2: d = rgb(RASTA)          # las rastas
            if d: px[x, y] = d + (p[3],)
    return rastas(im, t, frente)

# las rastas (1.33, lo pidió el usuario: «tiene que tener rastas»): el pelo, de la frente para abajo, en cordones de 2 px con 1 de
# hueco oscuro entre cordón y cordón, retorcidos (una vuelta más oscura cada 3 filas, corrida en cada cordón); la barba no (lo que
# queda entre la piel de la cara en su fila). Los cordones que cuelgan a los lados bajan de 1 a 4 filas más, cada uno lo suyo
# (LARGO), por encima del contorno, de lo vacío y de la camisa (por los hombros) pero no de la piel, y con su contorno. De frente,
# además, un cordón a cada lado del cuello que cae por delante del pecho (PECHO filas, sobre la camisa).
CORDON, VUELTA, HUECO, LUZ = rgb('#b4b0a8'), rgb('#8a867e'), rgb('#5e5a54'), rgb('#cfcbc2')
CABELLO = {rgb(c) for c in ('#b4b0a8', '#9a968e', '#7a7670', '#d8d4cc')}
CARA = {rgb(c) for c in ('#8a5a3c', '#5a3626')}
CONTORNO, FRENTE, LARGO, PECHO = rgb('#180e1e'), .2, (3, 1, 4, 2, 3, 2, 1, 4), 4
def rastas(im, t, frente=False):
    px = im.load(); W, H = im.size
    cam = next((y for y in range(H) if sum(px[x, y][3] > 0 and px[x, y][:3] in Ca.values() for x in range(W)) >= 3), H)
    pelo = lambda x, y: 0 <= x < W and 0 <= y < H and px[x, y][3] > 0 and px[x, y][:3] in CABELLO
    loc = {}
    for y in range(t, cam):
        cara = [x for x in range(W) if px[x, y][3] and px[x, y][:3] in CARA]
        for x in range(W):
            if not pelo(x, y) or (y - t) < FRENTE * (cam - t) * .5: continue
            if cara and min(cara) < x < max(cara) and (y - t) > FRENTE * (cam - t): continue   # la barba
            loc[(x, y)] = 1
    for (x, y) in loc:
        k = x % 3
        if k == 2: c = HUECO
        elif (y + x // 3) % 3 == 0: c = VUELTA
        else: c = LUZ if k == 0 and (y + x // 3) % 3 == 1 else CORDON
        px[x, y] = c + (255,)
    for x in range(W):                                                      # las puntas, colgando
        ys = [y for (a, y) in loc if a == x]
        if not ys or x % 3 == 2: continue
        y = max(ys)
        if y < t + (cam - t) * .55: continue
        for j in range(1, LARGO[x % len(LARGO)] + 1):
            q = px[x, y + j] if y + j < H else (0, 0, 0, 0)
            if q[3] and q[:3] != CONTORNO and q[:3] not in Ca.values(): break
            px[x, y + j] = (VUELTA if (y + j + x // 3) % 3 == 0 else CORDON) + (255,)
            for dx in (-1, 1):
                if 0 <= x + dx < W and not px[x + dx, y + j][3]: px[x + dx, y + j] = CONTORNO + (255,)
        else:
            if y + j + 1 < H and not px[x, y + j + 1][3]: px[x, y + j + 1] = CONTORNO + (255,)
    if frente:
        xs = [x for (x, y) in loc if y == cam - 1]
        for x, s in ((min(xs, default=-9) + 2, 1), (max(xs, default=-9) - 2, -1)):
            if x < 0: continue
            for j in range(PECHO):
                y = cam - 1 + j
                if y >= H or px[x, y][:3] not in set(Ca.values()) | {CONTORNO}: break
                px[x, y] = (VUELTA if (y + x // 3) % 3 == 0 else CORDON) + (255,)
                if px[x + s, y][:3] in Ca.values(): px[x + s, y] = CONTORNO + (255,)
    return im

if __name__ == '__main__':
    n = 0
    for a in ANIMS:
        for f in sorted(glob.glob(os.path.join(RAIZ, ORIGEN, a, '*', '*.png'))):
            im = viste(Image.open(f).convert('RGBA'), os.path.basename(os.path.dirname(f)) == 'south')
            out = f.replace(os.sep + ORIGEN + os.sep, os.sep + NUEVO + os.sep)
            os.makedirs(os.path.dirname(out), exist_ok=True); im.save(out); n += 1
    print(NUEVO, n, 'fotogramas')
