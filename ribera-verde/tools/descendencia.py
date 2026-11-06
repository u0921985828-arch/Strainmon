# Landrace Hunters — la descendencia (lo pidió el usuario: «más que más landraces me refería a meter más
# descendencias»; solo con Datos.CAL). No añade ni una variedad a la lista: añade formas de sacar línea nueva
# de lo que ya cultivas. Escribe DESC en godot/datos/datos.json:
#  · corte: guardar una madre buena con nombre propio, para que sus esquejes repitan ese fenotipo exacto;
#  · clon: polinizar el clon de una madre con el de otra, en el carro de esquejes: la línea no se pierde al cosechar;
#  · s1: autofecundar una línea tuya (S1): no mezcla nada de fuera, fija lo que ya tenía;
#  · bx: retrocruzar el hijo con su madre (BX1, BX2): cada vuelta lo acerca más a ella;
#  · ibl: con la línea ya estable y dos selecciones, queda fijada del todo y deja de variar.
# Nada de método real: el juego dice lo que se juega, nunca cómo se hace.
#   python3 -I tools/descendencia.py
import json, os

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATOS = os.path.join(RAIZ, 'godot', 'datos', 'datos.json')

DESC = {
	# el corte de madre: se guarda el fenotipo exacto de una planta tuya y cada esqueje suyo sale igual
	"corte": {
		"n": "Corte de madre",
		"d": "Guardas esta planta como madre con nombre propio: cada esqueje suyo sale exactamente igual que ella.",
		"tope": 4,              # cuántos cortes se pueden tener guardados
		"v": 55,                # el vigor con el que entra al armario una madre metida desde un corte (hay que criarla)
		"nom": "{s} · corte {n}",
		"via": "Corte de una madre tuya",
	},
	# polinizar entre clones, en el carro de esquejes: gasta los dos esquejes y solo cuaja uno al día
	"clon": {
		"n": "Polinizar entre clones",
		"d": "Dos esquejes pinchados en el carro: uno da el polen y el otro la semilla. Gastas los dos y las madres siguen vivas.",
		"sem": 3,               # semillas que salen
		"dias": 1,              # días que tiene que pasar entre dos polinizaciones del carro
		"via": "Cruce entre clones",
	},
	# S1: la línea consigo misma. No sube generación (no es un cruce): fija lo suyo
	"s1": {
		"n": "Autofecundación (S1)",
		"d": "La línea consigo misma: no entra nada de fuera. Sale más parecida a la madre y con sus rasgos más fijados.",
		"gasta": 2,             # semillas que gasta
		"sem": 2,               # semillas que salen (neto cero: no multiplica)
		"dias": 3,              # días que ocupa el laboratorio
		"tope": 2,              # autofecundaciones por línea: pasadas estas, la línea ya está fijada hasta donde llega el S1
		"iv": 2,                # lo que sube cada valor oculto de la línea
		"ra": 1,                # cuánto sube el nivel de fijación de cada rareza
		"suf": "S1",
		"via": "Autofecundación (S1)",
	},
	# BX: el hijo con su madre. Cada vuelta acerca más la descendencia a la madre
	"bx": {
		"n": "Retrocruce (BX)",
		"d": "Cruzas el hijo con su propia madre: lo que salga se parece mucho más a ella, y a la segunda vuelta, casi del todo.",
		"m": [75, 88],          # el % de la madre en cada vuelta (BX1, BX2)
		"gasta": 1,             # semillas que gasta de cada
		"sem": 2,               # semillas que salen
		"dias": 2,              # días que ocupa el laboratorio
		"suf": "BX{n}",
		"via": "Retrocruce (BX)",
	},
	# IBL: con la línea ya estable y dos selecciones de semilla, queda fijada y deja de variar
	"ibl": {
		"n": "Línea fijada (IBL)",
		"d": "Dos selecciones seguidas de la misma línea estable: queda fijada del todo y todas sus plantas salen iguales.",
		"sel": 2,               # selecciones que pide
		"gasta": 1,             # semillas que gasta
		"sem": 2,               # semillas que salen
		"dias": 2,              # días que ocupa el laboratorio
		"sigma": 0.03,          # lo que varía una planta suya (la estable varía 0,06)
		"iv": 26,               # el suelo de sus cuatro valores ocultos
		"suf": "IBL",
		"via": "Línea fijada (IBL)",
	},
}

def main():
	s = open(DATOS, encoding='utf8').read()
	D = json.loads(s)
	assert DESC["corte"]["tope"] >= 2 and DESC["clon"]["sem"] >= 1
	assert 0 < DESC["corte"]["v"] < 100 and DESC["clon"]["dias"] >= 1
	assert DESC["s1"]["sem"] <= DESC["s1"]["gasta"] and DESC["s1"]["tope"] >= 1
	for v in ("s1", "bx", "ibl"):
		assert DESC[v]["dias"] >= 1 and DESC[v]["gasta"] >= 1
	assert DESC["bx"]["m"] == sorted(DESC["bx"]["m"]) and DESC["bx"]["m"][-1] < 100
	assert 0 < DESC["ibl"]["sigma"] < float(D["GENETICA"]["estable"]["sigma"])
	assert DESC["ibl"]["iv"] <= 31 and DESC["s1"]["ra"] <= int(D["RAREZAS"]["fija"])
	D["DESC"] = DESC
	# la línea fijada es un tipo de genética más: varía menos que la estable (cultivo.gd tipo_gen)
	D["GENETICA"]["ibl"] = {
		"n": "Línea fijada (IBL)",
		"sigma": DESC["ibl"]["sigma"],
		"si": 0,
		"uno": 60000,
		"d": "fijada a conciencia: dos selecciones seguidas y ni una planta se sale de la madre",
	}
	t = json.dumps(D, ensure_ascii=False, separators=(',', ':'))
	if t != s:
		open(DATOS, 'w', encoding='utf8').write(t)
	print("descendencia: %d vías · corte hasta %d · BX %s · IBL sigma %s" %
	      (4, DESC["corte"]["tope"], "/".join(str(m) for m in DESC["bx"]["m"]), DESC["ibl"]["sigma"]))

main()
