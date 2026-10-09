# Mapa de Ribera Verde

> Generado automáticamente con `node tools/generar-docs.js`. Coordenadas (x, y) en casillas de 16 px; (0,0) es la esquina superior izquierda.

Leyenda: `.` suelo/hierba · `*` flores · `"` hierba alta (ladrones ×3, a cualquier hora) · `:` tierra · `-` acera · `=` carretera · `%` carretera rota (baches y parches) · `_` hormigón · `,` pista de tierra · `+` plaza · `~` agua · `H` puente · `#` muelle
`^` tejado · `█` pared/ventana · `D` puerta · `T` árbol · `Y` manzano · `b` arbusto · `$` arbusto con objeto oculto · `i` objeto en el suelo · `f` valla · `S` cartel · `L` farola · `n` banco · `O` fuente · `c` cajas · `@` personaje · `M` monte (el bosque de los lindes) · `h` seto · `A` parada del autobús
Interiores: `B` cama · `P` ordenador · `G` mesa de genética · `t` mesa · `F` nevera · `K` carpa (mueble: el armario de 60 u 80 en x 8, la carpa de 100 o 150 en x 10-11 y la de 120 en x 2-3; sus plazas se ven por dentro, en la vista de carpa) · `C` mostrador · `s` estantería · `d` expositor · `x` taburete · `J` gramola · `v` ventana/póster · `m` felpudo (salida)

## Barrio (exterior) — 40 × 30

```
    0         1         2         3         
    0123456789012345678901234567890123456789
 0  MMMMMMMMMMM--MMMMMMMMMMMMMMMMMMMMMMMMMMM
 1  MMMMMMMMMMM--MMMMMMMMMMMMMMMMMMMMMMMMMMM
 2  M..*......*--.........*........*....*..M
 3  M.^^^^^^^..--.^^^^^^^..^^^^^^^..^^^^^^.M
 4  M.^^^^^^^.S--.^^^^^^^..^^^^^^^..^^^^^^.M
 5  M.███████..--.███████..███████..██████.M
 6  M.███████..--.███████..███████..██████.M
 7  M.███████..--.███████..███████..██████.M
 8  M.███D███S.--S███D███.S███D███..██DD██.M
 9  M----------L---------L---------L-------M
10  M======================================M
11  M======================================M
12  M-------A-@----------------------------M
13  MfffS::fffff.....S+++++.......fffffffffM
14  M.*..::..*....L+++++@+++++L....~~~~~~~~M
15  MT...::.......++++@++++@+++.T..~~~~~~~~M
16  M....::..$....++n+++++++n++*...~~~#####M
17  M..n.::.......++++++++@++++....~~~####cM
18  M..@.::""""..*+++@+++++++++..S.~~~####cM
19  M..*.::""""...++++++O++++++----HHH####SM
20  MT...::""""...+++++++++++++----HHH######
21  M""".::....T..+++++++@+++++....~~~###@##
22  M""".::.*...*.++n+++++++n++....~~~#####M
23  M""".::.......+i+++++++++++....~~~#####M
24  M.T..::...$...L+++++++++++L..T.~~~##i##M
25  M....::.i*.....................~~~c####M
26  M.$.*::........................~~~~~~~~M
27  M....::...*..*....*.........T..~~~~~~~~M
28  M...T.......T....T..T..T.*T....~~~~~~~~M
29  MhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhM
```

- puerta (5,8) → home (5,6)
- puerta (17,8) → shop (4,6)
- puerta (26,8) → bar (4,6)
- puerta (34,8) → txaro (4,6)
- puerta (35,8) → txaro (5,6)
- puerta (11,0) → alto (11,28)
- puerta (12,0) → alto (12,28)
- puerta (39,20) → astilleros (1,20)
- puerta (39,21) → astilleros (1,21)

## Barrio alto (exterior, al norte) — 40 × 30

```
    0         1         2         3         
    0123456789012345678901234567890123456789
 0  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 1  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 2  M......................................M
 3  M...T...T.....T...T.........T..........M
 4  M..*****************....T........T.....M
 5  M..L+++++++++++++++L..........*........M
 6  M.b+++++++++++++++++.....*...........T.M
 7  M..+++++++++++++++++b.S........T..*....M
 8  M..++++n+++++++n++++......T...n........M
 9  M..+++++++++++++++++............*..T...M
10  M.$+++++++++++++++++.......*.T.........M
11  M..++++++++O++++++++...................M
12  M..+++++++++++++++++b..........fffffff.M
13  M..+++++++++++++++++....^^^^^^.........M
14  M.b++++n+++++++n++++....^^^^^^.*****b*.M
15  M..+++++++++++++++++....██████.*b*****.M
16  M..+++++++++++++++++....██████.*******.M
17  M..L+++++++++++++++L....██████.****b**.M
18  M.........S--...........██DD██.*******.M
19  M..........--..........S-------........M
20  M-----L----------L--------------L------M
21  M======================================M
22  M======================================M
23  M--------------------------------------M
24  M..........--.b...b...b...b...b...b....M
25  M..T.......--...T...........T.......T..M
26  M....*.....--......*..........*........M
27  M......T...--.......T...........T......M
28  M.T........--...........*..............M
29  Mhhhhhhhhhh--hhhhhhhhhhhhhhhhhhhhhhhhhhM
```

- puerta (11,29) → town (11,1)
- puerta (12,29) → town (12,1)
- puerta (26,18) → comisaria (4,6)
- puerta (27,18) → comisaria (5,6)

## Astilleros (exterior, al este del muelle) — 40 × 30

```
    0         1         2         3         
    0123456789012345678901234567890123456789
 0  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 1  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 2  M::::::::::::::::::::::::::::::::::::::M
 3  M:"""""::.T...:::::::::::::::::::::::::M
 4  M:"""""::...T.::::::::::ffffffffffffff:M
 5  M:""i"":::::::::::::::::fcc::::::::ccf:M
 6  M:""""":::::::::::::::::fc::::::::::cf:M
 7  M:""""":::::::::::::::::f::::::::::::f:M
 8  M:::::::::::::L:^^^^^^::f:::c::::c:::f:M
 9  M:::::::::::::::^^^^^^::f::::::::::::f:M
10  M:T:::::::::::::██████::ffffff::ffffff:M
11  M:::::::::::::::██████:::::::::::::::::M
12  M:::::::::::::::██████:::::::::::::::::M
13  M::::::::::::::S██DD██::::::::"""""":::M
14  M:::::::::::::::::::::::::::::"""""":T:M
15  M:::::::::c:::::::::::::::::::"""""":::M
16  M:::::::::cc::::::::::::@::::::::::::::M
17  M::cc:::::::::::::::::c::::::::::::::::M
18  M:S::::::::::::::::::::::::::::::ccc:::M
19  M########L##########L##########L#######M
20  #######################################M
21  #######################################M
22  M######################################M
23  ~~~~~~###~~~~~~~~~~~~~~~~~###~~~~~~~~~~~
24  ~~~~~~###~~~~~~~~~~~~~~~~~###~~~~~~~~~~~
25  ~~~~~~###~~~~~~~~~~~~~~~~~###~~~~~~~~~~~
26  ~~~~~~###~~~~~~~~~~~~~~~~~###~~~~~~~~~~~
27  ~~~~~~#c#~~~~~~~~~~~~~~~~~#c#~~~~~~~~~~~
28  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
29  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

- puerta (0,20) → town (38,20)
- puerta (0,21) → town (38,21)
- puerta (18,13) → almacen (4,6)
- puerta (19,13) → almacen (5,6)

## Mendialde (pueblo de caseríos, de donde eres; el prólogo) — 48 × 34

```
    0         1         2         3         4       
    012345678901234567890123456789012345678901234567
 0  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 1  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 2  MMMMMMMMM...MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 3  M..MMMM..b...MMMMMMMMMMM..T...^^^^^^.MMMMMMMMMMM
 4  M..............T.MMMMM........^^^^^^....MMMMMMMM
 5  M...............^^^^^^^^......██████.....MMMMMMM
 6  M..^^^^^^^^.....^^^^^^^^......██████.....MMMMMMM
 7  M..^^^^^^^^.....████████......██████Y.........MM
 8  M..████████.....████████......................MM
 9  M..████████.....████████...._______...^^^^....MM
10  MY.████████.Y...████████.Y.._______...^^^^....MM
11  M..███DD███.................__........████b...MM
12  M...__________________________________████....MM
13  MM..__________________________________........MM
14  MM""""""""...__.........b..*..............Y...MM
15  MM"""""""".*.__.....*..........T.*.......*....MM
16  MMffffffff...__......................T.......TMM
17  ================================================
18  ================================================
19  M.S.........,,....++A+++++++++..^^^^^^.fff.ffffM
20  M..^^^^^^^^.,,..T.++++++++++++..^^^^^^.f""""""fM
21  M..^^^^^^^^.,,....L+++@++++++L..██████.f""""""fM
22  M..████████.,,T...++++++O+++++..██████.f""""""fM
23  M..████████.,,..*.+++n+++++n++..██████.ffffffffM
24  M..████████T,,....++++++++++++*...,,..........MM
25  M..████████.,,..b..++++++++++.....,,.......^^^^M
26  M..,,,,,,,,,,,......++++++++...b..,,.......^^^^M
27  MTM........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,████M
28  MMMM..........,,,,,,,,,,,,,,,,,,,,,,,,,,,,,████M
29  MMMMMMM......................................MMM
30  MMMMMMM........Y.....Y.....Y.....Y..*........MMM
31  MMMMMMM..*........Y.....Y.....Y.....Y.T.......MM
32  MMMMMMM..........Y.....Y.....Y................MM
33  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
```

- puerta (6,11) → casa-ama (4,6)
- puerta (7,11) → casa-ama (5,6)

## Caserío de la familia, en Mendialde — 10 × 8

```
    0         
    0123456789
 0  ██████████
 1  ██v████v██
 2  B........p
 3  B.........
 4  .....t....
 5  ..........
 6  .........F
 7  p...m.....
```

- salida (4,7) pulsando abajo → mendialde (6,12)

## Puerto Viejo (ciudad pequeña, pesquera) — 40 × 24

```
    0         1         2         3         
    0123456789012345678901234567890123456789
 0  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 1  MMMMMMMMMMMM^^^^^MMMMMMMMMMMMMMM^^^^^.MM
 2  M^^^^MMM^^^^^^^^^^^^^^^^^MMM^^^^^^^^^.MM
 3  M^^^^^^^^^^^█████^^^^^^^^^^^^^^^█████.MM
 4  M████^^^█████████████████^^^█████████.TM
 5  M████████████████████████████████████.MM
 6  M████████████████████████████████████bMM
 7  M████████████████████████████████████.MM
 8  M--------------------------------------M
 9  M.S++L+++++++++L+++A+++++++L+++++++L++MM
10  M.++++++++++++++++++++++++++++++++++++MM
11  M.++++++++++++@+++++++++++++++++++++++MM
12  M.++++++++++++++++++++++++++++++++++++MM
13  MM++++++++++++++++++++++++++++++++++++MM
14  MM++T++++++n++++++n++++++++++n+++++++T.M
15  Mfffff+++fffffffffffff+++fffffff+++ffffM
16  ~~~~~~###~~~~~~~~~~~~~###~~~~~~~###~~~~~
17  ~~~~~~###~~~~~~~~~~~~~###~~~~~~~###~~~~~
18  ~~~~~~###~~~~~~~~~~~~~###~~~~~~~##c~~~~~
19  ~~~~~~###~~~~~~~~~~~~~###~~~~~~~###~~~~~
20  ~~~~~~##c~~~~~~~~~~~~~##c~~~~~~~~~~~~~~~
21  ~~~~~~###~~~~~~~~~~~~~#c#~~~~~~~~~~~~~~~
22  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
23  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

## Valdehierro (ciudad pequeña, del hierro) — 40 × 24

```
    0         1         2         3         
    0123456789012345678901234567890123456789
 0  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 1  M....M.......MMMMM......MMMM.....MMMM..M
 2  M-^^^^^^^-^^^^^^:::^^^^^^^---^^^^^^^^--M
 3  M-^^^^^^^-^^^^^^:::^^^^^^^---^^^^^^^^--M
 4  M-███████-██████:::███████---████████--M
 5  M-███████-██████:c:███████---████████--M
 6  M-███████-██████:::███████---████████--M
 7  M-███████-██████c::███████---████████--M
 8  M-S------L--------L---------L----------M
 9  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
10  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
11  M-----L-------A---------L--------------M
12  M-------------------fffffffS--fffffffffM
13  M-^^^^^^^-^^^^^^^---f:::::::::::::::::fM
14  M-^^^^^^^-^^^^^^^---f::cc:::@:::::::::fM
15  M-███████-███████---f::c:::::::::cc:::fM
16  M-███████-███████---f:::::::::::::c:::fM
17  M-███████-███████---f:::::::::""""::::fM
18  M-███████-███████---f:::::::::""""::c:fM
19  M-------------------f:::::c:::""""::::fM
20  M.......n.........--f::::::::::c::::::fM
21  M.................--f:::::::T:::::::::fM
22  M....T....T...T...--fffffffffffffffffffM
23  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
```

## Errotabarri (pueblo del molino) — 36 × 24

```
    0         1         2         3     
    012345678901234567890123456789012345
 0  MMMMMMMMMMMMMMMMM~~~MMMMMMMMMMMMMMMM
 1  MMMMMMMMMMMMMMMMM~~~MMMMMMMMMMMMMMMM
 2  MMMMMMMMMMMMMMM.M~~~MMMMMMMMMMMMMMMM
 3  MMM.^^^^^^^^.*....~~~MMMMMM...MMMMMM
 4  MMM.^^^^^^^^......~~~..^^^^^^..MMMMM
 5  MMM.████████......~~~..^^^^^^.MMMMMM
 6  MMM.████████.Y....~~~..██████.*M..MM
 7  MMM.████████......~~~..██████.....MM
 8  MM..████████b.....~~~T.██████......M
 9  MM.....,,.....Y..~~~.....,,...T....M
10  MMS....,,.......~~~......,,.b......M
11  ,,,,,,,,,,,,,,,,HHH,,,,,,,,,,,,,,,,,
12  ,,,,,,,,,,,,,,,,HHH,,,,,,,,,,,,,,,,,
13  MM....A.....b...~~~.b......^^^^^^,,M
14  MMY.*......*..@..~~~.......^^^^^^,,M
15  MM.ffffffff....*.~~~..^^^^.██████,,M
16  MM.f""""""f......~~~..^^^^.██████,,M
17  MM.f""""""f......~~~*.████.██████,,M
18  MM.f""""""f.Y....~~~..████S......,,M
19  MM.ffffffff......~~~.......,,,,,,,,M
20  MM...............~~~....*..,,,,,,,,M
21  MM....*......T...~~~.....b........MM
22  MMMMMMM..........~~~MMMMMMMMMMMTMMMM
23  MMMMMMMMMMMMMMMMMM~~~MMMMMMMMMMMMMMM
```

## Piso de la tía Maite — 18 × 8 (1 casilla = 1 m; con el armario de 60, la carpa de 150 y el salón amueblado)

```
    0         1       
    012345678901234567
 0  ██████████████████
 1  ██████vv█v█████v██
 2  Bp..PGG.K.KK.??.??
 3  B.................
 4  c.................
 5  ...t.........??...
 6  F.................
 7  .....m...........p
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

## Casa de la abuela Txaro — 10 × 8

```
    0         
    0123456789
 0  ██████████
 1  ██v████v██
 2  Bp.......p
 3  B.....@...
 4  .....t....
 5  ..........
 6  .........F
 7  p...m.....
```

- salida (4,7) pulsando abajo → town (34,9)

## Comisaría del barrio alto — 10 × 8

```
    0         
    0123456789
 0  ██████████
 1  ss██v███ss
 2  ....@.....
 3  ..CCCCCC..
 4  ..........
 5  n........n
 6  ..........
 7  p...m....p
```

- salida (4,7) pulsando abajo → alto (26,19)

## Almacén de los astilleros — 10 × 8

```
    0         
    0123456789
 0  ██████████
 1  ██████v███
 2  cc...@..cc
 3  c........c
 4  ....xt....
 5  ..........
 6  c.......cc
 7  ....m.....
```

- salida (4,7) pulsando abajo → astilleros (18,14)

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
| txaro | town | (3,18) | no | `!S.flags.txaro` |
| txaro | txaro | (6,3) | no | `!!S.flags.txaro` |
| inaki | town | (37,21) | no | `S.ch>=2` |
| cop | town | (22,17) | radio 3 | `S.ch>=2` |
| darko | town | (20,14) | no | `(S.ch>=2&&S.ch<7&&!S.flags.darko1)||S.ch===6` |
| darko2 | astilleros | (24,16) | no | `S.ch>=7` |
| molina | town | (23,15) | no | `S.ch>=5&&!S.flags.molina1` |
| molina | comisaria | (4,2) | no | `S.ch>=5&&!!S.flags.molina1` |
| tono2 | almacen | (5,2) | no | `!!S.encargo` |
| jurado | town | (18,15) | no | `S.ch===6` |
| vecina | mendialde | (22,21) | radio 1 | siempre |
| excursionista | errotabarri | (14,14) | radio 2 | siempre |
| turista | puerto | (14,11) | radio 2 | siempre |
| obrero | valdehierro | (28,14) | radio 1 | siempre |

Los **clientes** ($) aparecen cada día desde el capítulo 2 en casillas de acera, plaza y tierra: en el barrio, 4 + reputación/15 (+1 desde el capítulo 4, máximo 10); en los astilleros, 2 (3 desde el capítulo 4), estudiantes y currelas, que pagan el gramo un 20 % más; en el barrio alto, desde el capítulo 3, 2 (3 desde el 4), pijos y turistas; en Puerto Viejo, 2 (3 desde el 4), turistas, currelas y estudiantes; en Valdehierro, 2 (3 desde el 4), estudiantes y currelas; y en los pueblos, 1: un currela en Mendialde y un currela o un turista en Errotabarri.

## Autobús de la comarca

En el poste de cada parada (`A`), de 7:00 a 21:00. Cada parada está a un tramo de Ribera Verde; entre dos de fuera se suman los dos tramos. El reloj corre lo que dura el viaje. El primero (Mendialde → Ribera Verde, en el prólogo) lo paga ama.

| Parada | Posición | Llegas a | Desde Ribera Verde |
|---|---|---|---|
| Ribera Verde | town (8,12) | (7,12) | — |
| Puerto Viejo | puerto (19,9) | (20,9) | 25 min · 2 € |
| Valdehierro | valdehierro (14,11) | (15,11) | 20 min · 2 € |
| Mendialde | mendialde (20,19) | (21,19) | 40 min · 3 € |
| Errotabarri | errotabarri (6,13) | (7,13) | 30 min · 3 € |

**Zonas** (`ZONAS` y `PATRULLAS`): factor de ladrones y de precio en cada mapa de fuera, y los agentes que patrullan de día y de noche (desde el capítulo 2). Ribera Verde: ladrones ×1, precio ×1, 1/2 agentes · Barrio alto: ladrones ×0,5, precio ×1, 2/2 agentes · Astilleros: ladrones ×2, precio ×1,2, 1/1 agentes · Puerto Viejo: ladrones ×0,6, precio ×1,15, 1/1 agentes · Valdehierro: ladrones ×1,4, precio ×0,9, 1/1 agentes · Mendialde: ladrones ×0,1, precio ×1, 0/0 agentes · Errotabarri: ladrones ×0,1, precio ×1, 0/0 agentes. Dentro de las casas no hay encuentros.

## Objetos

| id | Posición | Tipo | Contenido |
|---|---|---|---|
| i_spray | town (8,25) | bolsa en el suelo | 2 × SPRAY DE PIMIENTA |
| i_fert | town (36,24) | bolsa en el suelo | 3 dosis de ABONO |
| i_boc | town (15,23) | bolsa en el suelo | 2 × BOCATA |
| h_acap | town (2,26) | oculto en arbusto (pulsa A delante) | 2 semillas de ACAPULCO GOLD |
| h_50 | town (9,16) | oculto en arbusto (pulsa A delante) | 50 € en billetes doblados |
| h_ins | town (10,24) | oculto en arbusto (pulsa A delante) | 1 tratamiento de INSECTICIDA |
| i_ast | astilleros (4,5) | bolsa en el suelo | 2 × SPRAY DE PIMIENTA |
| h_alto | alto (2,10) | oculto en arbusto (pulsa A delante) | 80 € en un sobre arrugado |

## Carteles

- **town:9,8** — Calle Ribera, 3. · Piso de la tía Maite.
- **town:13,8** — GROWSHOP KIKO · Semillas, abonos y consejos gratis.
- **town:22,8** — BAR EL ANCLA · Pintxos y menú del día.
- **town:4,13** — PARQUE DE LOS SAUCES · Horario: de 7:00 a 23:00.
- **town:17,13** — PLAZA DE RIBERA VERDE · Fuente inaugurada en 1987.
- **town:29,18** — MUELLE VIEJO → · Peligro: borde sin barandilla.
- **town:10,4** — ↑ BARRIO ALTO · Plaza del Ensanche · Comisaría.
- **town:38,19** — ASTILLEROS DE RIBERA → · Zona industrial. Sin salida.
- **alto:10,18** — PLAZA DEL ENSANCHE · Urbanizada en 1964.
- **alto:22,7** — JARDINES DEL ENSANCHE · No pisar el césped.
- **alto:23,19** — COMISARÍA DE RIBERA · Atención al público: de 9:00 a 14:00.
- **astilleros:15,13** — ALMACÉN 3 · Propiedad privada. Prohibido el paso.
- **astilleros:2,18** — ASTILLEROS DE RIBERA · Cerrados desde 1992.
- **mendialde:2,19** — MENDIALDE · Caseríos, huertas y la parada del autobús.
- **puerto:2,9** — PUERTO VIEJO · Cofradía de pescadores desde 1890.
- **valdehierro:2,8** — VALDEHIERRO · Ciudad del hierro desde 1911.
- **valdehierro:27,12** — SOLAR DE LA FUNDICIÓN · Propiedad privada. Prohibido el paso.
- **errotabarri:2,10** — ERROTABARRI · El pueblo del molino.
- **errotabarri:26,18** — ERROTA ZAHARRA · Molino harinero del siglo XVIII.

## Tienda de Kiko

| Artículo | Precio | Desde cap. | Nota |
|---|---|---|---|
| Semillas Skunk #1 | 5 € | 1 |  |
| Semillas Lemon Haze | 9 € | 2 |  |
| Semillas Super Skunk | 10 € | 2 |  |
| Semillas Blueberry | 8 € | 3 |  |
| Semillas Big Bud | 7 € | 3 |  |
| Semillas Lemon Skunk | 8 € | 3 |  |
| Semillas Cheese | 9 € | 3 |  |
| Semillas Purple Afghani | 8 € | 4 |  |
| Semillas Kali Mist | 10 € | 4 |  |
| Semillas California Orange | 8 € | 4 |  |
| Semillas Chemdawg | 12 € | 5 |  |
| Abono de floración 1 L | 14 € | 1 | 4 dosis. Una por planta: +25 % de cosecha, con el pH corregido (sin pH−, ×0,5). |
| Abono de crecimiento 1 L | 12 € | 1 | 4 dosis. Una por planta en crecimiento: crece un 15 % más deprisa hasta florecer (sin pH−, ×0,5). |
| pH− 250 ml | 6 € | 1 | 10 dosis. Se gasta una con cada dosis de abono: baja el pH del agua del grifo (7,5) a 6,2. Sin él, el abono rinde ×0,5; sin medidor, a ojo (×0,75). |
| Medidor de pH y EC | 35 € | 2 | Mide el pH y la EC del riego: con pH−, el abono rinde entero, y en PLANTAS ves la EC y el pH de cada maceta. |
| Insecticida de neem 500 ml | 12 € | 1 | 3 tratamientos. Cada uno elimina una plaga de araña roja. |
| Bocata | 5 € | 1 | Recupera 15 de vida. En combate o desde la mochila. |
| Spray de pimienta | 15 € | 2 | En combate: 12-16 de daño seguro a un ladrón. |
| Maceta de tela 11 L | 3 € | 1 | 11 L · hasta 92 g por planta · cosecha +5% · crece +5% · riego ×1,25 · menos plagas · Se cambia en una plaza vacía de la carpa. |
| Maceta de plástico 18 L | 2 € | 2 | 18 L · hasta 144 g por planta · crece −5% · riego ×0,8 · Se cambia en una plaza vacía de la carpa. |
| Maceta de tela 25 L | 4 € | 3 | 25 L · hasta 210 g por planta · cosecha +5% · riego ×1,1 · menos plagas · Se cambia en una plaza vacía de la carpa. |
| Foco LED 100 W | 110 € | 1 | 100 W · ilumina 60×60 cm · 0,65 g/W (0,81 abonando) · crece +5% · THC +0,3 · riego ×1 · Luz: 39 kWh (6 €) al día con plantas. · Aguanta en carpas de 60, 80, 100, 120 y 150. |
| Ventilador de pinza | 20 € | 1 | Mueve el aire de la carpa: plagas ×0,7, moho ×0,5 y crecen un 3 % más. Gasta 25 W día y noche. · Uno por carpa. |
| Garrafas de riego | 15 € | 1 | Una garrafa con gotero junto a cada maceta: riega sola la planta que baja del 50 % de agua y le dura media cosecha. Se rellenan desde la vista de carpa. · Una tanda por carpa. |
| Extractor 100 mm con filtro | 75 € | 1 | Saca el aire de la carpa por un filtro de carbón: sin olor, menos calor y menos humedad. Mueve 250 m³/h; cada carpa pide su volumen × 60 por hora (× 1,3 por el filtro) y más con focos que calientan. Corto de caudal, huele algo. Gasta 35 W día y noche. · Uno por carpa. |
| Extractor 125 mm con filtro | 110 € | 2 | Saca el aire de la carpa por un filtro de carbón: sin olor, menos calor y menos humedad. Mueve 400 m³/h; cada carpa pide su volumen × 60 por hora (× 1,3 por el filtro) y más con focos que calientan. Corto de caudal, huele algo. Gasta 75 W día y noche. · Uno por carpa. |
| Extractor 150 mm con filtro | 190 € | 3 | Saca el aire de la carpa por un filtro de carbón: sin olor, menos calor y menos humedad. Mueve 750 m³/h; cada carpa pide su volumen × 60 por hora (× 1,3 por el filtro) y más con focos que calientan. Corto de caudal, huele algo. Gasta 110 W día y noche. · Uno por carpa. |
| Intractor 100 mm | 45 € | 2 | Mete aire fresco de fuera por abajo: el extractor rinde entero (sin él, un 15 % menos). Gasta 25 W día y noche. · Uno por carpa. |
| Riego por goteo | 1.200 € | 4 | Depósito grande con bomba y goteros para toda la carpa: riega solo cada planta que baja del 50 % de agua y, con la carpa llena de tierra, dura unas cinco cosechas. Se rellena desde la vista de carpa. Con él, las garrafas sobran. · Uno por carpa. |
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
| Termohigrómetro | 12 € | 1 | Temperatura y humedad de la sala, de día y de noche: se ven en PLANTAS (START). · Uno para la sala: Kiko lo deja puesto. |
| Calefactor | 35 € | 2 | Termostato: si la sala baja de 20 °C, la sube hasta 6 °C. Gasta 1.500 W mientras calienta. · Uno para la sala: Kiko lo deja puesto. |
| Humidificador | 40 € | 2 | Si la humedad baja del 45 %, la sube hasta 15 puntos. Gasta 30 W. · Uno para la sala: Kiko lo deja puesto. |
| Deshumidificador | 190 € | 3 | Si la humedad pasa del 55 %, la baja hasta 20 puntos: contra el moho en floración. Gasta 250 W. · Uno para la sala: Kiko lo deja puesto. |
| Aire acondicionado portátil | 320 € | 3 | Termostato: si la sala pasa de 26 °C, la baja hasta 12 °C. Gasta 900 W mientras enfría. · Uno para la sala: Kiko lo deja puesto. |
| Bolsa de deporte | 35 € | 3 | Llevas encima hasta 3 kg de cogollos y rosin (la mochila, 1 kg). |
| Maleta con ruedas | 90 € | 5 | Llevas encima hasta 10 kg de cogollos y rosin. |
| Prensa de rosin | 250 € | 3 | Prensa manual de calor (1.10): de 5 g de cogollo, 1 g de rosin con el triple de THC. Se usa en la mesa del piso. Lo compran los catadores. |
