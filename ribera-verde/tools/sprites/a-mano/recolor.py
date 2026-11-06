# python3 -I tools/sprites/a-mano/recolor.py [carpeta]  (Python 3 + Pillow; no va en los scripts de npm)
# Personajes nuevos a partir de otros nuestros, cambiando colores exactos (1.21):
# · miren: la de cliente5 (la del pelo rojo largo) con el pelo canoso y el top verde: la amiga de la tía Maite (Errotabarri).
# · darko-combate: el ladrón 1 de combate (64 px) con la sudadera negra, el pañuelo rojo y el pantalón oscuro: Darko en las peleas
#   (antes peleaba con el del ladrón).
# Un color con «+» cambia solo en el cuerpo (debajo de CUELLO de su alto, como npc_cara.py): el blanco del top es el de los ojos.
# Copia art/procesado/<origen> en art/procesado/<nuevo> (todas sus animaciones) con los colores de `CAMBIOS`; repetirlo da lo mismo.
# Después, node tools/sprites/procesar.js --atlas (los dos van en art/manifest.json, con su «cubre»).
import os, sys, glob
from PIL import Image

RAIZ = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', 'art', 'procesado')
NUEVOS = {
    'miren': ('cliente5', {'#7a2626': '#b8b8c0', '#4a1028': '#84848e', '#f8f8f8': '#5a9a6a+', '#bca69c': '#3e7a50+'}),
    'darko-combate': ('ladron1-combate', {'#4a4a5a': '#34343c', '#2e2e3a': '#222228', '#2a2a30': '#1e1e24', '#3a3a44': '#2a2a32',
                                          '#26262e': '#1a1a1e', '#6a7480': '#b02828', '#4a515c': '#303038', '#2c333c': '#222228'}),
}
rgb = lambda h: tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))
CUELLO = .42

for nuevo, (origen, cambios) in NUEVOS.items():
    tb = {rgb(a): (rgb(b), b.endswith('+')) for a, b in cambios.items()}; n = 0
    for f in sorted(glob.glob(os.path.join(RAIZ, origen, '*', '*', '*.png'))):
        im = Image.open(f).convert('RGBA'); px = im.load()
        ys = [y for y in range(im.height) if any(px[x, y][3] for x in range(im.width))]
        cu = ys[0] + round((ys[-1] - ys[0] + 1) * CUELLO) if ys else 0
        for y in range(im.height):
            for x in range(im.width):
                p = px[x, y]
                if p[3] and p[:3] in tb and (y >= cu or not tb[p[:3]][1]): px[x, y] = tb[p[:3]][0] + (255,)
        o = os.path.join(RAIZ, nuevo, os.path.relpath(f, os.path.join(RAIZ, origen)))
        os.makedirs(os.path.dirname(o), exist_ok=True); im.save(o); n += 1
    print(nuevo, n, 'fotogramas')
