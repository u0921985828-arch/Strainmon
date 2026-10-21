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

PULGAR = ['..kkkkkk',   # la yema sobre la rueda, con la uña; la llama, dos píxeles a la derecha
	'.kssssUk',
	'kssssUUk',
	'ssssDDkk',
	'sssDkk']
def pulgar(im):
	px = im.load(); W, H = im.size
	fl = [(x, y, px[x, y]) for x in range(W) for y in range(7) if px[x, y][3] and (px[x, y][0] > 200 and px[x, y][2] < 100 or x >= 33)]
	for x, y, c in fl:
		px[x, y] = (0, 0, 0, 0)
	for x, y, c in fl:
		px[x + 2, y] = c
	tono = {'k': (0, 0, 0, 255), 's': (230, 166, 128, 255), 'D': (205, 124, 102, 255), 'U': (244, 200, 176, 255)}
	for j, fila in enumerate(PULGAR):
		for i, ch in enumerate(fila):
			if ch in tono:
				px[28 + i, 5 + j] = tono[ch]
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
	if n == 'gm-mech1-ab':   # lo pidió el usuario («a la hora de encender el mechero, desaparece el dedo gordo»): el pulgar, encima de la rueda
		im = pulgar(im)
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

# cada cerradura, su llave (lo pidió el usuario: «el tipo de llave también que concuerde con la cerradura»): la cabeza de PixelLab
# repintada con el metal de cada una y la hoja nueva a mano: la de serreta del portal, las de seguridad con cazoletas (los locales;
# los clubs, con la cabeza negra), la de gorjas de la puerta blindada (el franco) y las de candado (la nave, grande; el bajo, pequeña)
import colorsys
K=(0,0,0,255)
PAL={  # (oscuro, medio, claro, brillo)
 'latón': [(122,82,30),(176,128,52),(218,174,84),(246,218,140)],
 'níquel':[(92,96,104),(150,156,166),(196,202,210),(236,240,246)],
 'acero': [(52,56,64),(88,94,104),(126,134,146),(176,184,196)],
 'negro': [(20,20,24),(40,40,46),(62,62,70),(96,96,106)],
}
TIPOS={  # cabeza, hoja, forma de la hoja, largo
 'portal': ('latón','latón','serreta',18),
 'local':  ('níquel','níquel','puntos',18),
 'club':   ('negro','níquel','puntos',18),
 'franco': ('acero','acero','gorjas',18),
 'nave':   ('níquel','níquel','candado',14),
 'setas':  ('latón','latón','candado',11),
}
def es_laton(c):
	r,g,b,a=c
	if a<128: return False
	h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
	return 0.085<=h<=0.17 and s>0.35 and v>0.3
def lum(c): return (c[0]*3+c[1]*6+c[2])/10
def llave_tipo(im, tipo, girada):
	im=im.copy(); px=im.load(); W,H=im.size
	cab,hoja,forma,L=TIPOS[tipo]
	yt=18 if girada else 17   # la raya de arriba de la hoja
	xb=20 if girada else 18   # donde la hoja entra en la cabeza
	# 1 · la cabeza: lo de latón de la zona de la llave, por su luz, a la paleta
	for x in range(0,30):
		for y in range(12,H):
			c=px[x,y]
			if es_laton(c):
				l=lum(c); p=PAL[cab]
				px[x,y]=p[0 if l<110 else 1 if l<160 else 2 if l<200 else 3]+(255,)
	# 2 · fuera la hoja vieja
	for x in range(0,xb):
		for y in range(yt-1,min(H,yt+7)):
			px[x,y]=(0,0,0,0)
	# 3 · la hoja nueva, de xb hacia la izquierda
	p=PAL[hoja]
	x0=xb-L
	def put(x,y,c):
		if 0<=x<W and 0<=y<H: px[x,y]=c if len(c)==4 else c+(255,)
	if forma in('serreta','puntos','candado'):
		alto=3 if forma!='puntos' else 4
		for x in range(x0,xb):
			put(x,yt,K); put(x,yt+alto+1,K)
			put(x,yt+1,p[3] if forma!='puntos' else p[2])
			for j in range(2,alto+1): put(x,yt+j,p[1] if j<alto else p[0])
		# la punta, en bisel
		put(x0,yt,(0,0,0,0)); put(x0-1,yt+1,K); put(x0-1,yt+2,K)
		if alto==4: put(x0-1,yt+3,K)
		put(x0,yt+alto+1,(0,0,0,0)); put(x0,yt+alto,K)
		if forma=='serreta':   # los dientes, por abajo
			for x in range(x0+2,xb-3):
				if (x-x0)%3!=2: put(x,yt+alto+1,p[1]); put(x,yt+alto+2,K)
				if (x-x0)%3==0: put(x,yt+alto+2,p[0]); put(x,yt+alto+3,K)
		elif forma=='puntos':  # las cazoletas de la llave de seguridad
			for x in range(x0+2,xb-2,3): put(x,yt+2,p[0]); put(x+1,yt+3,p[0])
		else:   # candado: dientes cortos
			for x in range(x0+2,xb-2,2): put(x,yt+alto+1,p[1]); put(x,yt+alto+2,K)
	elif forma=='gorjas':   # caña redonda y el paletón doble en la punta
		for x in range(x0+5,xb):
			put(x,yt+1,K); put(x,yt+2,p[3]); put(x,yt+3,p[1]); put(x,yt+4,K)
		for x in range(x0,x0+6):
			for y in range(yt-2,yt+8): put(x,y,p[1] if (y-yt)%3 else p[2])
			put(x,yt-3,K); put(x,yt+8,K)
		for y in range(yt-2,yt+8): put(x0-1,y,K); put(x0+6,y,K if not (yt+1<=y<=yt+4) else p[1])
		put(x0+2,yt-2,K); put(x0+2,yt-1,K); put(x0+3,yt+7,K); put(x0+3,yt+6,K)   # las muescas
	return im
LLAVES_V = ('nave', 'setas')   # las de candado, de pie, como acc-llave-v0/v1
def llaves():
	for t in TIPOS:
		for i in (0, 1):
			d0 = os.path.join(R, 'art', 'crudo', 'gestos', 'acc-llave-%d' % i, 'unica', '00.png')
			im = llave_tipo(Image.open(d0).convert('RGBA'), t, i == 1)
			n = 'acc-llave-%s-%d' % (t, i)
			if t in LLAVES_V:
				im = im.rotate(-90, expand=True)
				n = 'acc-llave-%s-v%d' % (t, i)
			d = os.path.join(R, 'art', 'crudo', 'gestos', n, 'unica')   # sin recortar: la mano, donde la de serie; os.makedirs(d, exist_ok=True)
			im.save(os.path.join(d, '00.png'))
			yield n, im.size

if __name__ == '__main__':
	tam = {n: sale(n, *v) for n, v in ELEGIDAS.items()}
	tam.update(dict(llaves()))
	json.dump({k: list(v) for k, v in tam.items()}, open(os.path.join(C, '..', 'tamanos.json'), 'w'), indent=1)
