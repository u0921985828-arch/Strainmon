# Los gestos con mano de PixelLab (lo pidió el usuario: «la regadera y la mano flotan… molaría hacerlas con sprites de PixelLab»).
# Entrada: tools/sprites/pixellab-gestos/crudo (las candidatas elegidas, tal como salen de create_image_pro / edit_image_pro_flash).
# Salida: art/crudo/gestos/<nombre>/unica/00.png, recortados a lo que se ve y con la manga tocando el canto (derecho o de abajo),
# para que el brazo entre siempre desde el borde del plano. Después: node tools/sprites/procesar.js gestos --atlas --atlas-dir godot/arte
import os, sys, json
from PIL import Image

R = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
C = os.path.join(R, 'tools', 'sprites', 'pixellab-gestos', 'crudo')
ELEGIDAS = {   # nombre en el atlas: (archivo, canto de la manga, giro en grados)
	'gs-regar': ('regar-3.png', 'der', 0),
	'acc-llave-0': ('llave-0.png', 'der', 0),
	'acc-llave-1': ('llave-gira.png', 'der', 0),
	'acc-llave-v0': ('llave-0.png', 'aba', -90),   # el candado: la llave sube desde abajo
	'acc-llave-v1': ('llave-gira.png', 'aba', -90),
	'acc-dedo': ('dedo-8.png', 'aba', 0),
}

def gris(c):
	r, g, b, a = c
	return a and max(r, g, b) - min(r, g, b) < 18 and min(r, g, b) > 150

def limpia(im):
	"""fuera la columna gris clara que deja PixelLab en el canto derecho y lo semitransparente"""
	px = im.load(); W, H = im.size
	for x in range(W - 1, W - 4, -1):
		col = [px[x, y] for y in range(H) if px[x, y][3]]
		if col and all(gris(c) for c in col):
			for y in range(H): px[x, y] = (0, 0, 0, 0)
	for x in range(W):
		for y in range(H):
			r, g, b, a = px[x, y]
			px[x, y] = (r, g, b, 255) if a >= 128 else (0, 0, 0, 0)
	return im

def sale(n, f, canto, giro):
	im = limpia(Image.open(os.path.join(C, f)).convert('RGBA'))
	if giro:
		im = im.rotate(giro, expand=True)   # 90°: sin perder píxeles
	im = im.crop(im.getbbox())
	d = os.path.join(R, 'art', 'crudo', 'gestos', n, 'unica'); os.makedirs(d, exist_ok=True)
	im.save(os.path.join(d, '00.png'))
	px = im.load(); W, H = im.size
	if canto == 'der':
		ok = any(px[W - 1, y][3] for y in range(H))
	else:
		ok = any(px[x, H - 1][3] for x in range(W))
	cols = len({px[x, y][:3] for x in range(W) for y in range(H) if px[x, y][3]})
	print(n, im.size, cols, 'colores', 'manga en el canto' if ok else 'SIN MANGA EN EL CANTO')
	return im.size

if __name__ == '__main__':
	tam = {n: sale(n, *v) for n, v in ELEGIDAS.items()}
	json.dump({k: list(v) for k, v in tam.items()}, open(os.path.join(C, '..', 'tamanos.json'), 'w'), indent=1)
