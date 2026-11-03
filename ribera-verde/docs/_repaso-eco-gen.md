# Repaso 0.76 · lo que quedaba en «4 · Economía» y «5 · Genética y estadísticas»

Los seis hallazgos marcados «recomendado» de esas dos secciones de [REPASO-ESTRUCTURA.md](REPASO-ESTRUCTURA.md), uno por uno:
qué se cambió y dónde, la cifra antes → después, la prueba que lo comprueba, o la medida por la que se descarta.

Todo va detrás de `Datos.CAL` y con claves nuevas en `godot/datos/datos.json` (`topec`, `calorg`, `basec`, `limc`), que escribe
`tools/repaso_eco_gen.py` (idempotente, una sola línea, como el resto). El HTML sigue congelado: sin CAL, cifra a cifra lo de
antes. Prueba nueva: `godot/tests/repaso_eco_gen.gd` → **52 comprobaciones, 0 fallos**.

Batería comprobada: `economia` en verde · `genetica` 34/0 · `cannadex` 31/0 · `negocios` 351/0 · `rarezas` 54/0 · `nave` 32/0 ·
`clubs` 81/0 · `familias` 258/0 · `pendientes` 32/0 · `historia` 120 pasos (120 OK), 85 diferencias, **todas** `S.molS`
(regresión de la 0.77, anterior a esta tanda; cerrada después con el parche (a): `historia` 120 pasos, 0 diferencias).

---

## 4 · Economía

### 4.1 · «La deuda deja de importar en el capítulo 5» — aplicado (el parche (b), ya en `trama.gd`)

La medida (bloque 1 de la prueba nueva):

| Qué | Cifra |
|---|---|
| Al por mayor (Iñaki), 1.000 g/día al 4,00 €/g | 4.000 €/día |
| Plazo del capítulo 5: 12.000 € en 10 días | **3,00 días** de carga |
| Plazo del capítulo 7: 15.000 € en 7 días | **3,75 días** |
| Lo que queda de deuda al llegar al capítulo 5 (27.000 €) | **6,75 días** de los 17 de plazo |
| Un ciclo de la nave (4 mesas de LED), que se alquila justo en el capítulo 5 | 19.584 €, más que todo el plazo |

El hallazgo es real y **ya está aplicado**: `PLAZO_PCT` = 0,5 en `datos.json` (lo escribe `tools/repaso_eco_gen.py`) y
`plazo_due(ch)` en `src/trama.gd`, usada en el plazo del capítulo 5, en el SMS de Toño y con la marca `S.plazoS` al cobrar un
plazo (el parche (b) de abajo, tal cual). Comprobado: `economia` en verde (los tres perfiles) y `historia` 120 pasos, 0
diferencias. Se descartó de entrada subir la deuda en seco: `tests/economia.gd` deja al jugador torpe con
125 € al acabar, así que cualquier coste fijo nuevo lo deja sin saldar. La salida coherente es un plazo que suba con lo
facturado, que al que va justo no le toca: medido con `tests/economia.gd` instrumentado, los tres perfiles facturan entre
**5.949 € y 9.430 €** entre un plazo y el siguiente, mientras que el que tira de la nave o de Iñaki a diario factura 40.000 €
en la misma ventana. Con `PLAZO_PCT` = 0,5 el suelo de 12.000 € no se mueve para los tres perfiles (0,5 × 9.430 = 4.715 €) y al
fuerte le pide 20.000 €: medio plazo de verdad.

### 4.1b · «La calidad se acumula hasta ×2,21 y los documentos dicen +15 %» — se actualizan los documentos

De las dos salidas que admitía el hallazgo se elige la segunda (el juego se queda como está, los documentos lo cuentan):
`calidad()` está en `src/mundo.gd`, bloqueado, y además la cadena es deliberada —cada eslabón es una fase del oficio y ninguno
sale gratis—, el otro extremo ya castiga (verde recién cortado, ×0,35) y el arbitraje ya está cerrado (`cp`: lo comprado hecho
no cobra prima). Medido (bloque 2):

| Lote | Calidad |
|---|---|
| Seco, sin nada | ×1,00 |
| Recién cortado | ×0,35 |
| Curado + manicurado + afinado en el camarote | ×1,35 |
| … con las ocho semanas en tarro | ×2,21 |
| … con las tres técnicas de EL ESQUEJE | ×2,44 |
| … con aroma único | ×3,04 |
| … y variedad rara (`SHINY`, 1 de cada 500) | ×15,22 |

Documentos al día (a mano, en el generado **y** en su plantilla; no se ha ejecutado `npm run docs` ni `npm run analisis`):
`docs/ECONOMIA.md` + `tools/generar-docs.js` (dos viñetas nuevas en «Vender»: la cadena entera con sus cifras y los clubs de
4.2), `docs/ANALISIS.md` (el aviso de las cifras con CAL) y `docs/GENETICA.md` (ver 5.4). Si algún día se quiere tope, el parche
está al final.

### 4.2 · «Los clubs dominan a Iñaki» — aplicado

| Qué | Antes | Después |
|---|---|---|
| Lo que compra un club al día | 200 g fijos (`MERCADO.club.tope`) | 100 g sin conocerte → 130 g de socio (`MERCADO.club.topec` {min 100, max 130, rel 50}, por `S.rel`); los cinco a tope, 650 g, por debajo del kilo de Iñaki |
| Calor de la entrega | 1, con 5 g o con 200 | 1 + 1 por cada 75 g (`CLUB.calorg`): 1,67 por 50 g, 2,73 por 130 g (0,021 por gramo, frente a los 0,012 del por mayor) |
| Una parada en el mejor club | 200 g × 6 €/g = 1.200 € | 300 g × 6 €/g = 1.800 € |
| Una carga de Iñaki | 1.000 g × 4 €/g = 4.000 € | igual (10 kg en el imperio) |

Dónde: `src/movil.gd`, `club_tope(k)` nueva y usada en el tope por día de `vender_club` (`resto_mer("club_" + k, …)`), más el
calor por gramos en la misma función. Cada canal queda con su sitio: el club paga mejor el gramo (6 € frente a 4 al 20 % de
THC) pero mueve poco y hay que ganárselo club por club (los de fuera piden `CLUB.confia` 15 con encargado y presidente, así que
al principio solo compra el de tu barrio: 900 €/día, menos de un cuarto de una carga de Iñaki); de socio, los cinco juntos
llegan a 9.000 €/día, por encima del primer rango de Iñaki y muy por debajo del imperio. Por gramo, el club sigue siendo más
discreto (0,010 frente a 0,012). Pruebas: bloque 3 de la prueba nueva, `clubs` 81/0, `negocios` 351/0, `economia` en verde.

---

## 5 · Genética y estadísticas

### 5.1 · «`IVS.base [6,18]` arranca por debajo del punto neutro · el generador y las placas no pueden hacer falta nunca» — aplicado

| Qué | Antes | Después |
|---|---|---|
| IV de una línea nueva | `IVS.base` [6, 18]: media 12,26 de los 416 IV de las 104 líneas, `iv_f` **−0,25** | `IVS.basec` [10, 22]: media 16,26, `iv_f` **+0,02** (el punto neutro es 16) |
| Potencia contratada del piso | `ENERGIA.casa.lim` 5.750 W, con 5.320 W a tope: nunca se pasa | `limc` 4.600 W: a tope sobran 720 W |
| Potencia contratada de la nave | `ENERGIA.nave.lim` 15.000 W, con 5.760 W a tope | `limc` 4.600 W: a tope sobran 1.160 W |

Dónde: `src/cultivo.gd` (`iv_linea` lee `IVS.basec` con CAL) y `src/copa.gd` (`ener_lim(sitio)` nueva, usada en `exceso_w` y en
el texto de la tienda). Las placas (`ENERGIA.pl`, 2.500 W) cubren el exceso del piso y el generador (`ENERGIA.gen`, 5.000 W) el
de la nave: los dos tienen por fin para qué estar. El abanico de los IV es el mismo (12 puntos), así que una línea sigue
pudiendo salir buena o mala; solo deja de nacer lastrada. Pruebas: bloques 4 y 5; `genetica` 34/0 (su bloque 1 lee `basec` con
CAL) y `familias` 258/0 (su bloque 4 pone a cero y restaura también `limc`).

### 5.2 · «79 de las 87 variedades están dominadas: no hay motivo para cultivarlas» — descartado, con la medida

La dominancia es cierta: **79 de 87** están dominadas en las cuatro cifras (THC, rinde, días de flor y resistencia). La
conclusión, no: **ninguna de las 87 se queda sin motivo para cultivarla**. De las 79 dominadas, **79** están en una familia de
la CannaDex (`FAMILIAS`, cuyo bono solo se cobra con la familia completa), **46** son madre o padre de una receta y **31** van
en una de las seis colecciones del banco de la tía. A eso se suman las rarezas, los IV y la caza por estación. Y arreglarlo
«de verdad» sería retocar las cuatro cifras de variedades reales publicadas, que es justo lo que el proyecto no hace (nada
inventado). Queda como regresión en el bloque 6 de la prueba nueva (`sin_motivo.is_empty()`), que además comprueba que cada
familia solo lleva variedades que existen.

### 5.3 · «Las rarezas se heredan 8 veces peor en las feminizadas · "Doble cosecha" no hace nada en la nave ni en KAIA» — aplicado

| Qué | Antes | Después |
|---|---|---|
| Fijar una rareza en una línea feminizada | hacía falta semilla, y una feminizada solo la da hermafrodita (`SEMILLA_HERMA` 0,12): 33,3 cosechas frente a las 4 de una regular (**×8,33**) | con los esquejes de la madre: **4 cosechas**, como la regular |
| «Doble cosecha» en una mesa de la nave o de KAIA | la mesa rebrotada arrancaba igual que con clones (`NAVE.clon`): **×1,06** por día de ciclo | arranca en `NAVE.clon + 0,5 × (1 − NAVE.clon)`: **×1,20**, lo mismo que en el piso |

Dónde: `src/cultivo.gd` (`ra_sin_semilla(sid)`: con CAL, las de `FEM`), `src/granja.gd` y `src/venta.gd` (la cosecha propia y la
del gerente llaman a `hereda_ra` también sin semilla en una feminizada) y `src/venta.gd` + `src/kaiacult.gd` (`prog_rebrote()`,
que usan las dos cosechas de mesa). Pruebas: bloques 7 y 8; `rarezas` 54/0 (su comprobación «sin semillas, la línea no la
aprende» se invierte para la feminizada, con el comentario del repaso) y `nave` 32/0.

### 5.4 · «`docs/GENETICA.md` y `docs/ANALISIS.md` describen la fórmula antigua» — aplicado

- `docs/GENETICA.md` + `tools/generar-docs.js`: la sección «Lo que añade la versión de Godot» pasa a 0.78 y cuenta las
  fórmulas de verdad: los factores que se suman a la cosecha (IV de producción, familia, técnicas de EL ESQUEJE, rasgos raros) y
  al THC (IV de potencia, familia, revista, resinosa y el techo común `Cultivo.THC_TOPE`), los cuatro IV con `IVS.basec` y su
  punto neutro (con la cifra de antes, `iv_f` −0,25), las rarezas con lo de 5.3 y las raras y autoflorecientes.
- `docs/ECONOMIA.md` + `tools/generar-docs.js`: las dos viñetas de 4.1b y 4.2.
- `docs/ANALISIS.md`: el aviso de las cifras con CAL añade los clubs, los IV, la potencia contratada y la cadena de la calidad
  (el texto de ese documento es a mano; `tools/analisis-riesgos.js` solo rehace las tablas).

El generado y la plantilla quedan con el mismo texto (comprobado) y `node --check tools/generar-docs.js` pasa.

---

## Parches exactos para los archivos bloqueados

### (a) `godot/src/trama.gd` línea 870 — quita las 85 diferencias de `historia` (regresión de la 0.77) · APLICADO

`S.molS` se crea sin CAL, y el oráculo compara el `S` entero: 85 pasos dicen «S.molS: sobra en godot». `cuota_molina()`
(`granja.gd`) ya devuelve `D.SOBORNO` sin CAL y lee `S.get("molS", 0)`, así que el guardia no cambia nada del juego:

```gdscript
			S.molS = S.get("sales", 0)   # 0.77: desde aquí se cuenta lo facturado para la cuota siguiente
```

```gdscript
			if Datos.CAL:   # 0.78: sin CAL no se crea la clave (el oráculo del HTML compara S entero)
				S.molS = S.get("sales", 0)   # 0.77: desde aquí se cuenta lo facturado para la cuota siguiente
```

### (b) `godot/src/trama.gd` — el plazo que sube con lo facturado (hallazgo 4.1) · APLICADO

`datos.json` (en `tools/repaso_eco_gen.py`): `D["PLAZO_PCT"] = 0.5`. Función nueva, junto a `dias_plazo`:

```gdscript
# 0.78 (repaso 4 · Economía): el plazo no se queda en la cifra pactada cuando el negocio ya mueve miles al día. Don Baltasar
# pide lo pactado o la mitad de lo facturado desde el plazo anterior, lo que sea más, y lo que pide de más sube la deuda (el
# último plazo sigue siendo lo que quede). Los tres perfiles de tests/economia.gd facturan 5.949-9.430 € entre plazos, así que
# el suelo de 12.000 € no se les mueve; el que tira de la nave o de Iñaki a diario factura 40.000 € en la misma ventana.
func plazo_due(ch: int) -> int:
	var base: int = int(D.PLAZOS[str(ch)])
	if not Datos.CAL or not D.has("PLAZO_PCT"):
		return base
	var fact: float = maxf(0, float(S.get("sales", 0)) - float(S.get("plazoS", 0)))
	return int(maxf(float(base), Datos.jsround(fact * float(D.PLAZO_PCT))))
```

En `check_story` (línea 1686), el plazo del capítulo 5:

```gdscript
		S.due = int(D.PLAZOS["5"])
		S.deadline = S.day + dias_plazo(5)
```

```gdscript
		S.due = plazo_due(5)
		S.debt += S.due - int(D.PLAZOS["5"])   # lo que pide de más se suma a la deuda
		S.deadline = S.day + dias_plazo(5)
```

y el SMS de Toño de la línea siguiente, con `Datos.eur(S.due)` en vez de `Datos.eur(D.PLAZOS["5"])`. Al cobrar un plazo
(línea 961, `S.due = 0`), la marca para el siguiente: `if Datos.CAL: S.plazoS = S.get("sales", 0)`. Después hay que pasar
`tests/economia.gd` (los tres perfiles) y `tests/historia.gd`.

### (c) `godot/src/mundo.gd` — tope de la calidad, solo si se prefiere esa rama de 4.1b

```gdscript
	if Datos.CAL and float(b.get("cp", 0)) > 0:
		q = 1 + (q - 1) * (1 - minf(1, float(b.cp)))
	return q
```

```gdscript
	if Datos.CAL and float(b.get("cp", 0)) > 0:
		q = 1 + (q - 1) * (1 - minf(1, float(b.cp)))
	return minf(q, float(D.get("CALIDAD_TOPE", 99.0)) * (float(D.SHINY.x) if Datos.CAL and b.get("sh") else 1.0)) if Datos.CAL else q
```

con `D["CALIDAD_TOPE"] = 1.5` en `datos.json` (el ×5 de la rara queda fuera del tope, que es un premio de 1 de cada 500). Si se
aplica, hay que rehacer la viñeta de `docs/ECONOMIA.md` y el bloque 2 de `tests/repaso_eco_gen.gd`.
