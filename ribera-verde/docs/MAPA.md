# Mapa de Ribera Verde

> Generado automáticamente con `node tools/generar-docs.js`. Coordenadas (x, y) en casillas de 16 px; (0,0) es la esquina superior izquierda.

Leyenda: `.` suelo/hierba · `*` flores · `"` hierba alta (ladrones ×3, a cualquier hora) · `:` tierra · `-` acera · `=` carretera · `+` plaza · `~` agua · `H` puente · `#` muelle
`^` tejado · `█` pared/ventana · `D` puerta · `T` árbol · `b` arbusto · `$` arbusto con objeto oculto · `i` objeto en el suelo · `f` valla · `S` cartel · `L` farola · `n` banco · `O` fuente · `c` cajas · `@` personaje
Interiores: `B` cama · `P` ordenador · `G` mesa de genética · `t` mesa · `F` nevera · `K` carpa (mueble: el armario de 60 u 80 en x 8, la carpa de 100 o 150 en x 10-11 y la de 120 en x 2-3; sus plazas se ven por dentro, en la vista de carpa) · `C` mostrador · `s` estantería · `d` expositor · `x` taburete · `J` gramola · `v` ventana/póster · `m` felpudo (salida)

## Barrio (exterior) — 40 × 30

```
    0         1         2         3         
    0123456789012345678901234567890123456789
 0  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 1  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 2  T..*......*.*.........*........*....*..T
 3  T.^^^^^^^.....^^^^^^^..^^^^^^^..^^^^^^.T
 4  T.^^^^^^^.....^^^^^^^..^^^^^^^..^^^^^^.T
 5  T.███████.....███████..███████..██████.T
 6  T.███████.....███████..███████..██████.T
 7  T.███████.....███████..███████..██████.T
 8  T.███D███S...S███D███.S███D███..██████.T
 9  T----------L---------L---------L-------T
10  T======================================T
11  T======================================T
12  T---------@----------------------------T
13  TfffS::fffff.....S+++++.......fffffffffT
14  T.*..::..*....L+++++@+++++L....~~~~~~~~T
15  TT...::....T..++++@++++@+++.T..~~~~~~~~T
16  T....::..$....++n+++++++n++*...~~~#####T
17  Tb.n.::.......++++++++@++++....~~~####cT
18  T..@.::""""..*+++@+++++++++..S.~~~####cT
19  T..*.::""""...++++++O++++++----HHH#####T
20  TT...::""""...+++++++++++++----HHH#####T
21  T""".::....T..+++++++@+++++....~~~###@#T
22  T""".::.*...*.++n+++++++n++....~~~#####T
23  T""".::.......+i+++++++++++....~~~#####T
24  T.T..::...$...L+++++++++++L..T.~~~##i##T
25  T....::.i*.....................~~~c####T
26  T.$.*::....T..T..T..T..T..T....~~~~~~~~T
27  T....::.T.*..*....*.........T..~~~~~~~~T
28  T........................*.....~~~~~~~~T
29  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

- puerta (5,8) → home (5,6)
- puerta (17,8) → shop (4,6)
- puerta (26,8) → bar (4,6)

## Piso de la tía Maite — 12 × 8 (1 casilla = 1 m; con el armario de 60 y la carpa de 150)

```
    0         1 
    012345678901
 0  ████████████
 1  ██████vv█v██
 2  Bp..PGG.K.KK
 3  B...........
 4  ............
 5  ...t........
 6  F...........
 7  .....m.....p
```

- salida (5,7) pulsando abajo → town (5,9)

## Growshop Kiko — 10 × 8

```
    0         
    0123456789
 0  ██████████
 1  ss██v███ss
 2  ....@.....
 3  ..CCCCCC..
 4  ..........
 5  d........d
 6  ..........
 7  p...m....p
```

- salida (4,7) pulsando abajo → town (17,9)

## Bar El Ancla — 10 × 8

```
    0         
    0123456789
 0  ██████████
 1  ssss██v███
 2  ..@.....tJ
 3  CCCC......
 4  .x.x.@.@..
 5  .......t..
 6  ..........
 7  ....m.....
```

- salida (4,7) pulsando abajo → town (26,9)

## Personajes

| id | Mapa | Posición | Deambula | Aparece cuando |
|---|---|---|---|---|
| kiko | shop | (4,2) | no | siempre |
| josune | bar | (2,2) | no | siempre |
| baltasar | bar | (7,4) | no | siempre |
| tono | bar | (5,4) | no | `S.ch>=3&&S.ch<8` |
| begona | town | (10,12) | radio 2 | siempre |
| unai | town | (17,18) | radio 3 | siempre |
| patxi | town | (21,21) | no | siempre |
| txaro | town | (3,18) | no | siempre |
| inaki | town | (37,21) | no | `S.ch>=2` |
| cop | town | (22,17) | radio 3 | `S.ch>=2` |
| darko | town | (20,14) | no | `(S.ch>=2&&!S.flags.darko1)||S.ch===6` |
| molina | town | (23,15) | no | `S.ch>=5&&!S.protect` |
| jurado | town | (18,15) | no | `S.ch===6` |

Los **clientes** ($) aparecen cada día desde el capítulo 2 en casillas de acera, plaza y tierra (4 + reputación/15, +1 desde el capítulo 4, máximo 10).

## Objetos

| id | Posición | Tipo | Contenido |
|---|---|---|---|
| i_spray | town (8,25) | bolsa en el suelo | 2 × SPRAY DE PIMIENTA |
| i_fert | town (36,24) | bolsa en el suelo | 3 dosis de ABONO |
| i_boc | town (15,23) | bolsa en el suelo | 2 × BOCATA |
| h_acap | town (2,26) | oculto en arbusto (pulsa A delante) | 2 semillas de ACAPULCO GOLD |
| h_50 | town (9,16) | oculto en arbusto (pulsa A delante) | 50 € en billetes doblados |
| h_ins | town (10,24) | oculto en arbusto (pulsa A delante) | 1 tratamiento de INSECTICIDA |

## Carteles

- **town:9,8** — Calle Ribera, 3. · Piso de la tía Maite.
- **town:13,8** — GROWSHOP KIKO · Semillas, abonos y consejos gratis.
- **town:22,8** — BAR EL ANCLA · Pintxos y menú del día.
- **town:4,13** — PARQUE DE LOS SAUCES · Horario: de 7:00 a 23:00.
- **town:17,13** — PLAZA DE RIBERA VERDE · Fuente inaugurada en 1987.
- **town:29,18** — MUELLE VIEJO → · Peligro: borde sin barandilla.

## Tienda de Kiko

| Artículo | Precio | Desde cap. | Nota |
|---|---|---|---|
| Semillas Skunk #1 | 5 € | 1 |  |
| Semillas Lemon Haze | 9 € | 2 |  |
| Semillas OG Kush | 10 € | 2 |  |
| Semillas Blueberry | 8 € | 3 |  |
| Semillas Mango | 7 € | 3 |  |
| Semillas Purple Afghani | 8 € | 4 |  |
| Abono de floración 1 L | 14 € | 1 | 4 dosis. Una por planta: +25% de cosecha. |
| Insecticida de neem 500 ml | 12 € | 1 | 3 tratamientos. Cada uno elimina una plaga de araña roja. |
| Bocata | 5 € | 1 | Recupera 15 de vida. En combate o desde la mochila. |
| Spray de pimienta | 15 € | 2 | En combate: 12-16 de daño seguro a un ladrón. |
| Maceta de tela 11 L | 3 € | 1 | 11 L · hasta 92 g por planta · cosecha +5% · crece +5% · riego ×1,25 · menos plagas · Se cambia en una plaza vacía de la carpa. |
| Maceta de plástico 18 L | 2 € | 2 | 18 L · hasta 144 g por planta · crece −5% · riego ×0,8 · Se cambia en una plaza vacía de la carpa. |
| Maceta de tela 25 L | 4 € | 3 | 25 L · hasta 210 g por planta · cosecha +5% · riego ×1,1 · menos plagas · Se cambia en una plaza vacía de la carpa. |
| Foco LED 100 W | 110 € | 1 | 100 W · ilumina 60×60 cm · 0,65 g/W (0,81 abonando) · crece +5% · THC +0,3 · riego ×1 · Luz: 39 kWh (6 €) al día con plantas. · Aguanta en carpas de 60, 80, 100, 120 y 150. |
| Ventilador de pinza | 20 € | 1 | Mueve el aire de la carpa: plagas ×0,7. Gasta 25 W día y noche. · Uno por carpa. |
| Extractor con filtro de carbón | 110 € | 2 | Sin filtro, cada carpa con plantas en floración suma +2 de calor policial al día por el olor. Con él, nada. Gasta 75 W día y noche. · Uno por carpa. |
| Riego por goteo | 55 € | 3 | Depósito con goteros: el agua baja a la mitad de rápido. · Uno por carpa. |
| Foco sodio 250 W | 85 € | 2 | 250 W · ilumina 70×70 cm · 0,45 g/W (0,56 abonando) · crece +5% · THC +0,3 · riego ×1,3 · Luz: 98 kWh (16 €) al día con plantas. · Aguanta en carpas de 60, 80, 100, 120 y 150. |
| Foco LED 200 W | 220 € | 2 | 200 W · ilumina 80×80 cm · 0,7 g/W (0,88 abonando) · crece +10% · THC +0,6 · riego ×1,05 · Luz: 78 kWh (12 €) al día con plantas. · Aguanta en carpas de 60, 80, 100, 120 y 150. |
| Foco sodio 400 W | 100 € | 3 | 400 W · ilumina 100×100 cm · 0,5 g/W (0,63 abonando) · crece +5% · THC +0,5 · riego ×1,4 · Luz: 157 kWh (25 €) al día con plantas. · Aguanta en carpas de 80, 100, 120 y 150. |
| Foco LED 480 W | 500 € | 3 | 480 W · ilumina 120×120 cm · 0,8 g/W (1 abonando) · crece +10% · THC +1,0 · riego ×1,1 · Luz: 188 kWh (30 €) al día con plantas. · Aguanta en carpas de 100, 120 y 150. |
| Foco sodio 600 W | 120 € | 4 | 600 W · ilumina 120×120 cm · 0,55 g/W (0,69 abonando) · crece +5% · THC +0,7 · riego ×1,5 · Luz: 235 kWh (38 €) al día con plantas. · Aguanta en carpas de 120 y 150. |
| Foco LED 720 W | 950 € | 5 | 720 W · ilumina 150×150 cm · 0,85 g/W (1,06 abonando) · crece +15% · THC +1,4 · riego ×1,15 · Luz: 282 kWh (45 €) al día con plantas. · Aguanta en carpas de 120 y 150. |
| Armario 80×80 | 90 € | 3 | Cambia el armario de tu tía por uno de 80: 3 plantas, focos de hasta 400 W y macetas de hasta 18 L. Tus plantas, foco y macetas se quedan. |
| Carpa 100×100 | 120 € | 2 | Segunda carpa para el piso: 4 plantas, focos de hasta 480 W y macetas de hasta 25 L. Trae un CFL y macetas de 7 L. |
| Carpa 150×100 | 140 € | 4 | Cambia tu carpa de 100 por una de 150: 6 plantas y focos de hasta 720 W. Tus plantas, foco y macetas se quedan. |
| Carpa 120×120 | 150 € | 5 | Tercera carpa, junto a la cama: 6 plantas, focos de hasta 720 W y macetas de hasta 25 L. Trae un CFL y macetas de 7 L. Antes necesitas la del fondo. |
