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
	# 0.56 (lo pidió el usuario: «molaría que la vista sea POV»): en primera persona, tu antebrazo entra en diagonal desde la esquina
	# de abajo a la derecha con la herramienta en la mano, arriba a la izquierda (canto 'pov': la manga toca el canto de abajo y el derecho)
	'gm-regar': ('pv-regar2-15.png', 'pov', 0),
	'gm-spray': ('pv-spray-5.png', 'pov', 0),
	'gm-abono': ('pv-abono2-12.png', 'pov', 0),
	'gm-tij-a': ('pv-tij-6.png', 'pov', 0),
	'gm-tij-c': ('pv-tijc-0.png', 'pov', 'caja:pv-tij-6.png'),   # el mismo recorte que las abiertas: la mano no salta al cerrar
	'gm-semilla': ('pv-semilla-1.png', 'pov', 0),
	'gm-vacia': ('pv-vacia-0.png', 'pov', 0),
	'gm-porro': ('pv-porro-1.png', 'pov', 0),
	'gm-pipa': ('pv-pipa-0.png', 'pov', 0),
	'gm-vapo': ('pv-vapo-0.png', 'pov', 0),
	'gm-billete': ('pv-billete-0.png', 'pov', 0),
	'gm-bolsita': ('pv-bolsita-0.png', 'pov', 0),
	'gm-pincel': ('pv-pincel-0.png', 'pov', 0),
	# la mano del cliente, enfrente: la misma girada media vuelta, desde la esquina de arriba a la izquierda, con la manga azul
	'gm-billete-i': ('pv-billete-0.png', 'pov-i', 'vuelta'),
	'gm-bolsita-i': ('pv-bolsita-0.png', 'pov-i', 'vuelta'),
	# tu otra mano con el mechero, en espejo, desde la esquina de abajo a la izquierda: encendido y el mismo sin la llama
	'gm-mech1-ab': ('pv-mech-0.png', 'pov-ab', 0),
	'gm-mech0-ab': ('pv-mech-0.png', 'pov-ab', 'apaga'),
}
MANGA = [(105, 14, 55), (121, 26, 59)]   # la de llave-0 (oscura, clara): todas las mangas igual
MANGA_CLI = [(38, 52, 104), (52, 72, 136)]

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

def manga(im, pal):
	"""los rojos de la manga, a los dos tonos de la de llave-0 (o a los del cliente) por su luz"""
	px = im.load(); W, H = im.size
	es = lambda c: c[0] > 85 and c[1] < 45 and c[0] - c[1] > 60
	cols = sorted({px[x, y][:3] for x in range(W) for y in range(H) if px[x, y][3] and es(px[x, y])}, key=sum)
	if not cols:
		return im
	corte = (sum(cols[0]) + sum(cols[-1])) / 2
	for x in range(W):
		for y in range(H):
			c = px[x, y]
			if c[3] and es(c):
				px[x, y] = pal[1 if sum(c[:3]) > corte else 0] + (255,)
	return im

def sale(n, f, canto, giro):
	caja = None
	im = limpia(Image.open(os.path.join(C, f)).convert('RGBA'))
	if giro == 'espejo':
		im = manga(im.transpose(Image.FLIP_LEFT_RIGHT), MANGA_CLI)
	elif giro == 'vuelta':
		im = manga(im.rotate(180), MANGA_CLI)
	elif giro == 'apaga':   # fuera la llama: lo naranja y amarillo por encima del mechero morado
		px = im.load(); W, H = im.size
		caja = im.getbbox()   # el mismo recorte que el encendido: no salta al cambiar
		mor = [(x, y) for x in range(W) for y in range(H) if px[x, y][3] and px[x, y][2] > 120 and px[x, y][0] < 170 and px[x, y][2] > px[x, y][1] + 40]
		top = min(y for x, y in mor)
		x0 = min(x for x, y in mor) - 3; x1 = max(x for x, y in mor) + 1
		for x in range(max(0, x0), min(W, x1 + 1)):
			for y in range(top):
				px[x, y] = (0, 0, 0, 0)
	elif isinstance(giro, str) and giro.startswith('caja:'):
		caja = limpia(Image.open(os.path.join(C, giro[5:])).convert('RGBA')).getbbox()
		caja = tuple(min(a, b) if i < 2 else max(a, b) for i, (a, b) in enumerate(zip(caja, im.getbbox())))
		giro = 'apaga'   # recorta con la caja
	elif giro:
		im = im.rotate(giro, expand=True)   # 90°: sin perder píxeles
	if n.startswith('gm-') and giro not in ('espejo', 'vuelta'):
		im = manga(im, MANGA)
	im = im.crop(caja if giro == 'apaga' else im.getbbox())
	if n.startswith('gm-mech'):   # la mano izquierda: el puño a la izquierda del mechero, sin tapar la del porro
		im = im.transpose(Image.FLIP_LEFT_RIGHT)
	if n == 'gm-vacia':   # la edición sin la semilla trae colores de más: a los de la mano con semilla
		ref = Image.open(os.path.join(R, 'art', 'crudo', 'gestos', 'gm-semilla', 'unica', '00.png')).convert('RGBA')
		pal = sorted({c[:3] for c in ref.getdata() if c[3]})
		px = im.load()
		for x in range(im.width):
			for y in range(im.height):
				c = px[x, y]
				if c[3]:
					px[x, y] = min(pal, key=lambda q: sum((q[i] - c[i]) ** 2 for i in range(3))) + (255,)
	d = os.path.join(R, 'art', 'crudo', 'gestos', n, 'unica'); os.makedirs(d, exist_ok=True)
	im.save(os.path.join(d, '00.png'))
	px = im.load(); W, H = im.size
	if canto == 'der':
		ok = any(px[W - 1, y][3] for y in range(H))
	elif canto == 'izq':
		ok = any(px[0, y][3] for y in range(H))
	elif canto == 'pov-i':   # la manga, en la fila de arriba (el cliente) o en la de abajo (las tuyas), del lado de su esquina
		ok = any(px[x, 0][3] for x in range(W // 2))
	elif canto == 'pov':
		ok = any(px[x, H - 1][3] for x in range(W // 2, W))
	elif canto == 'pov-ab':
		ok = any(px[x, H - 1][3] for x in range(W // 2))
	else:
		ok = any(px[x, H - 1][3] for x in range(W))
	cols = len({px[x, y][:3] for x in range(W) for y in range(H) if px[x, y][3]})
	print(n, im.size, cols, 'colores', 'manga en el canto' if ok else 'SIN MANGA EN EL CANTO')
	return im.size

if __name__ == '__main__':
	tam = {n: sale(n, *v) for n, v in ELEGIDAS.items()}
	json.dump({k: list(v) for k, v in tam.items()}, open(os.path.join(C, '..', 'tamanos.json'), 'w'), indent=1)
