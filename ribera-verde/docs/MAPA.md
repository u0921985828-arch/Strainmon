# Mapa de Ribera Verde

> Generado automáticamente con `node tools/generar-docs.js`. Coordenadas (x, y) en casillas de 16 px; (0,0) es la esquina superior izquierda.

Leyenda: `.` suelo/hierba · `*` flores · `"` hierba alta (ladrones ×3, a cualquier hora) · `:` tierra · `-` acera · `=` carretera · `+` plaza · `~` agua · `H` puente · `#` muelle
`^` tejado · `█` pared/ventana · `D` puerta · `T` árbol · `b` arbusto · `$` arbusto con objeto oculto · `i` objeto en el suelo · `f` valla · `S` cartel · `L` farola · `n` banco · `O` fuente · `c` cajas · `@` personaje
Interiores: `B` cama · `P` ordenador · `G` mesa de genética · `t` mesa · `F` nevera · `o` suelo del armario · `1-6` macetas · `C` mostrador · `s` estantería · `d` expositor · `x` taburete · `J` gramola · `v` ventana/póster · `m` felpudo (salida)

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

- puerta (5,8) → home (5,8)
- puerta (17,8) → shop (4,6)
- puerta (26,8) → bar (4,6)

## Piso de la tía Maite — 12 × 10

```
    0         1 
    012345678901
 0  ████████████
 1  ██v███v██v██
 2  .B.PGG.....p
 3  .B.....oooo.
 4  .......1o2o.
 5  .......oooo.
 6  ...t...3o4o.
 7  .F.....oooo.
 8  p......5o6o.
 9  .....m......
```

- salida (5,9) pulsando abajo → town (5,9)

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
| i_fert | town (36,24) | bolsa en el suelo | 3 × FERTILIZANTE |
| i_boc | town (15,23) | bolsa en el suelo | 2 × BOCATA |
| h_acap | town (2,26) | oculto en arbusto (pulsa A delante) | 2 semillas de ACAPULCO ORO |
| h_50 | town (9,16) | oculto en arbusto (pulsa A delante) | 50 € arrugados |
| h_ins | town (10,24) | oculto en arbusto (pulsa A delante) | 1 × INSECTICIDA |

## Carteles

- **town:9,8** — Calle Ribera, 3. · Piso de la tía Maite.
- **town:13,8** — GROWSHOP KIKO · Semillas, abonos y consejos gratis.
- **town:22,8** — BAR EL ANCLA · Pintxos, kalimotxo y negocios turbios.
- **town:4,13** — PARQUE DE LOS SAUCES · Prohibido pisar el césped. Nadie hace caso.
- **town:17,13** — PLAZA DE RIBERA VERDE · Fuente inaugurada en 1987.
- **town:29,18** — MUELLE VIEJO → · Cuidado con las gaviotas.

## Tienda de Kiko

| Artículo | Precio | Desde cap. | Nota |
|---|---|---|---|
| Semilla Ría Skunk | 15 € | 1 |  |
| Semilla Limón Haze | 25 € | 2 |  |
| Semilla Txoko Kush | 30 € | 2 |  |
| Semilla Niebla Blue | 40 € | 3 |  |
| Semilla Mango Rompeolas | 35 € | 3 |  |
| Semilla Púrpura Monte | 50 € | 4 |  |
| Fertilizante | 15 € | 1 | Una dosis por planta: +25% de cosecha. |
| Insecticida | 20 € | 1 | Elimina una plaga de araña roja. |
| Bocata | 6 € | 1 | Recupera 15 de vida. En combate o desde la mochila. |
| Spray de pimienta | 25 € | 2 | En combate: 12-16 de daño seguro a un ladrón. |
| Maceta extra | 150 € | 2 | Una maceta más en el armario (máximo 6). |
| Lámpara LED | 500 € | 3 | +30% de cosecha y algo más de THC. Para siempre. |
