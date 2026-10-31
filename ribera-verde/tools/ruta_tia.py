"""La ruta de la tía (lo pidió el usuario: «que haya cosas para hacer en cada pueblo… que la historia tenga algo que ver»; con
Datos.CAL): en cada pueblo de la comarca, alguien que conoció a la tía Maite, junto al sitio propio del pueblo, con un recado
(los de D.SECUNDARIAS, con «tia») y, hecho, su testimonio (la «huella»): con RUTA_TIA.min, una prueba más en la oposición a la
patente del Acto III (acto3.gd). Escribe en godot/datos/datos.json: quita los recados con «tia» y los vuelve a poner, y RUTA_TIA.
	python3 -I tools/ruta_tia.py
"""
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, "godot", "datos", "datos.json")

RUTA = [
	{"id": "t_fronton", "ch": 2, "a": {"map": "mendialde", "x": 22, "y": 20, "look": "oldman", "n": "PELLO", "dir": "right"},
		"t": "Las semillas del frontón", "d": "Pello, junto al frontón de Mendialde, cambiaba semillas con tu tía. Llévale 3 g de lo tuyo.",
		"pide": {"tipo": "g", "g": 3}, "premio": {"e": 40, "rep": 2},
		"txt": ["¿Eres de la familia de Maite? Tienes su cara de pedir perdón por adelantado.", "Cada octubre subía con un sobre de semillas y las cambiábamos aquí, contra el frontón, por las mías de maíz.", "Tráeme 3 gramos de lo que cultivas. Quiero saber si te ha dejado la mano."],
		"fin": ["Esto lo ha criado alguien con paciencia. Como ella.", "Si alguna vez te preguntan desde cuándo se reparten esas semillas por aquí, di que Pello las cambia desde el 91. Lo firmo donde haga falta."],
		"ya": "Desde el 91, en este frontón. No se me olvida.",
		"h": "Pello: las semillas de la tía se cambian en el frontón de Mendialde desde 1991."},
	{"id": "t_faro", "ch": 3, "a": {"map": "puerto", "x": 34, "y": 19, "look": "vecina", "n": "ROSARIO", "dir": "right"},
		"b": {"map": "alto", "x": 17, "y": 9, "look": "socia", "n": "SOCIA", "dir": "down"},
		"t": "Las cartas del faro", "d": "Rosario, la viuda del farero de Puerto Viejo, guardaba cartas de tu tía. Lleva el paquete a una socia de la asociación, en el barrio alto.",
		"pide": {"tipo": "lleva"}, "premio": {"e": 60, "rep": 2},
		"txt": ["Mi marido llevó el faro treinta años. Tu tía le escribía desde Jamaica, desde la India, desde donde fuera.", "En cada carta venían semillas pegadas con celo. Él las guardaba en la lata de las galletas.", "Las cartas son de la asociación, no mías. Llévaselas a la socia del barrio alto, la del kiosko."],
		"txtb": ["¿Cartas de Maite? A ver… Sí, es su letra.", "Aquí pone la fecha de cada semilla y de dónde venía. Esto vale más que la sede entera."],
		"fin": ["Las guardo en la asociación. Si un día alguien dice que esas semillas son suyas, aquí están las fechas."],
		"ya": "Las cartas del faro, a buen recaudo.",
		"h": "Las cartas del faro: cada semilla con su fecha y su origen, de puño y letra de la tía."},
	{"id": "t_chimenea", "ch": 3, "a": {"map": "valdehierro", "x": 26, "y": 21, "look": "obrero", "n": "ESTEBAN", "dir": "up"},
		"t": "Los de la fundición", "d": "Esteban, jubilado de la fundición de Valdehierro, junto a la chimenea. Quiere 5 g para los compañeros.",
		"pide": {"tipo": "g", "g": 5}, "premio": {"e": 120, "rep": 2},
		"txt": ["En la huelga del 92 estuvimos cuarenta días dentro. Tu tía subía cada semana con una bolsa para las espaldas.", "No cobraba. Decía que lo pagaríamos cuando hubiese convenio.", "Seguimos quedando los jueves debajo de la chimenea. ¿Nos traes 5 gramos?"],
		"fin": ["Como entonces. Esto se reparte entre todos.", "La planta que nos traía la cultivaba con semillas suyas, de las de la lata. Lo sabe media Valdehierro."],
		"ya": "Los jueves, aquí, debajo de la chimenea.",
		"h": "Esteban: en la huelga del 92 la tía repartía en la fundición lo que sacaba de sus semillas."},
	{"id": "t_colmenas", "ch": 4, "a": {"map": "errotabarri", "x": 16, "y": 5, "look": "ane", "n": "ITZIAR", "dir": "left"},
		"t": "Entre las colmenas", "d": "Itziar, la del colmenar de Errotabarri, quiere 3 g de una índica (60 % o más).",
		"pide": {"tipo": "g", "g": 3, "ind": 60}, "premio": {"e": 80, "rep": 2},
		"txt": ["Tu tía sembraba entre mis colmenas. Las abejas no se acercan a la flor, pero el polen se lo llevan a casa.", "Me pagaba en semillas. De índicas, que son las que aguantan el frío de aquí.", "Tráeme 3 gramos de una índica y te cuento lo que me dejó apuntado."],
		"fin": ["Esto huele a lo que ella sacaba de aquí.", "Me dejó un cuaderno de campo: qué sembraba cada año entre las colmenas. Te lo leo cuando quieras, y lo leo en voz alta delante de quien haga falta."],
		"ya": "El cuaderno del colmenar sigue en el cajón.",
		"h": "Itziar: el cuaderno del colmenar apunta lo que la tía sembraba en Errotabarri, año por año."},
	{"id": "t_prensa", "ch": 4, "a": {"map": "ibarbide", "x": 23, "y": 16, "look": "granny", "n": "PILAR", "dir": "left"},
		"t": "El periódico del 98", "d": "Pilar, la del quiosco de prensa del Casco Viejo, guarda algo de tu tía. Quiere 2 g.",
		"pide": {"tipo": "g", "g": 2}, "premio": {"e": 60, "rep": 1},
		"txt": ["Este quiosco era de mi padre. En el 98 vendió todos los periódicos de la Copa en una mañana.", "Salía tu tía en la foto, con el diploma del segundo premio y con aquel jamaicano.", "Me quedé uno. Te lo cambio por 2 gramos, que el periódico no me quita el insomnio."],
		"fin": ["Toma. Mira el pie de foto: «Maite, de Ribera Verde, segunda en la Copa con una Haze de semilla propia».", "Semilla propia, pone. En el 98. Que nadie te diga otra cosa."],
		"ya": "El del 98 ya lo tienes tú.",
		"h": "El periódico del 98: «Maite, de Ribera Verde, segunda en la Copa con una Haze de semilla propia»."},
	{"id": "t_grua", "ch": 5, "a": {"map": "astilleros", "x": 26, "y": 18, "look": "obrero", "n": "JOSEBA", "dir": "right"},
		"t": "La cabina de la grúa", "d": "Joseba, el último gruista de los astilleros, quiere 10 g de más del 18 % de THC.",
		"pide": {"tipo": "g", "g": 10, "thc": 18}, "premio": {"e": 300, "rep": 3},
		"txt": ["Esta grúa no se mueve desde que cerraron. Yo tengo la llave de la cabina.", "Cuando la policía apretaba, tu tía guardaba ahí arriba lo suyo. Nadie sube a una grúa parada.", "Tráeme 10 gramos buenos, de más del 18, y te digo qué dejó allí."],
		"fin": ["Arriba quedó una caja de madera con sus sobres. Las fechas de los sobres empiezan en el 89.", "Se lo dije a la asociación y lo tienen apuntado. Lo que es de ella, de ella era antes que de nadie."],
		"ya": "La grúa, quieta. La caja, en la asociación.",
		"h": "Joseba: los sobres de la cabina de la grúa empiezan en 1989, antes que cualquier registro."},
]

RUTA_TIA = {"_": "La ruta de la tía (tools/ruta_tia.py): los recados de D.SECUNDARIAS con «tia»; min, los testimonios que hacen una prueba del Acto III; todos, el aviso de Delroy.",
	"min": 3, "todos": {"rep": 3}}

def main():
	with open(DATOS, encoding="utf-8") as f:
		D = json.load(f)
	S = [s for s in D["SECUNDARIAS"] if not s.get("tia")]
	for r in RUTA:
		r = dict(r)
		r["tia"] = 1
		S.append(r)
	D["SECUNDARIAS"] = S
	D["RUTA_TIA"] = RUTA_TIA
	with open(DATOS, "w", encoding="utf-8") as f:
		json.dump(D, f, ensure_ascii=False, separators=(",", ":"))
	print("ruta de la tía: %d recados en %s" % (len(RUTA), ", ".join(r["a"]["map"] for r in RUTA)))

if __name__ == "__main__":
	main()
