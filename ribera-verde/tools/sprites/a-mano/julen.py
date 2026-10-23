# python3 -I tools/sprites/a-mano/julen.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# Julen, el hijo de Kiko (1.23): el dibujo de Kiko (aprobado) con el pelo castaño oscuro, la camiseta naranja y vaqueros. Kiko
# comparte tonos entre el pelo, la piel y el pantalón, así que se cambian por zonas del alto del dibujo (como recolor.py):
# · PELO, por encima de CUELLO (el pelo largo le llega a los hombros);
# · CAMISETA, en todo el dibujo (el verde solo es de la camiseta);
# · PANTALON, por debajo de CINTURA.
# Copia base e idle de art/procesado/kiko en art/procesado/julen; repetirlo da lo mismo. Después, node tools/sprites/procesar.js
# --atlas (va en art/manifest.json con su «cubre»).
import os, sys, glob
from PIL import Image

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'procesado')
ORIGEN, NUEVO, ANIMS = 'kiko', 'julen', ('base', 'idle')
PELO = {'#d8a868': '#7a5236', '#c8a068': '#684430', '#e6bc80': '#8e6442', '#a8805a': '#523424'}
CAMISETA = {'#3f8a46': '#c8642c', '#2a6a40': '#9a4422'}
PANTALON = {'#8c6a46': '#34405e', '#a8805a': '#46557a', '#c8a068': '#5a6a90', '#d8a868': '#5a6a90', '#e6bc80': '#6a7aa0'}
CUELLO, CINTURA = .55, .73
rgb = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
tabla = lambda d: {rgb(a): rgb(b) for a, b in d.items()}
P, C, T = tabla(PELO), tabla(CAMISETA), tabla(PANTALON)

if __name__ == '__main__':
    n = 0
    for a in ANIMS:
        for f in sorted(glob.glob(os.path.join(RAIZ, ORIGEN, a, '*', '*.png'))):
            im = Image.open(f).convert('RGBA'); px = im.load()
            ys = [y for y in range(im.height) if any(px[x, y][3] for x in range(im.width))]
            t, b = ys[0], ys[-1]; alto = b - t + 1
            for y in range(im.height):
                r = (y - t) / alto
                for x in range(im.width):
                    p = px[x, y]
                    if not p[3]: continue
                    c = p[:3]
                    d = C.get(c) or (P.get(c) if r < CUELLO else T.get(c) if r >= CINTURA else None)
                    if d: px[x, y] = d + (p[3],)
            out = f.replace(os.sep + ORIGEN + os.sep, os.sep + NUEVO + os.sep)
            os.makedirs(os.path.dirname(out), exist_ok=True); im.save(out); n += 1
    print(NUEVO, n, 'fotogramas')
