# Plano de Ribera Verde (1.10, en desarrollo)

Inventario de todo lo que ocupa sitio en el juego (mapas, edificios, muebles, carpas, macetas, plantas, focos, extras y
personajes), medido contra su tamaño real. En la 1.7.0 sirvió para decidir la escala; en la 1.8.0 se aplicó la
**opción A** (sección 5). En P2 del [plan de producción](PLAN-PRODUCCION.md) la vista de carpa pasó a la **B**
(sección 6): carpa abierta en 3/4 a 48 px/m.

- Imágenes: `docs/plano/town.png`, `home.png`, `shop.png`, `bar.png` y, desde la 1.10, `alto.png`, `astilleros.png`,
  `txaro.png`, `comisaria.png` y `almacen.png` (rejilla, coordenadas y rótulos),
  `docs/plano/escala.png` (todos los sprites junto al jugador sobre la misma línea de suelo) y
  `docs/plano/vista-b.png` (las 5 carpas abiertas de la vista B).
- Datos: `docs/plano/medidas.json` (posiciones de cada mapa y las 69 medidas de abajo).
- Se regenera con `npm run plano` (`tools/plano.js`): pinta los mapas y la vista B con el motor del juego y mide la
  caja opaca de cada fotograma, así que el plano siempre coincide con lo que se ve. La tabla de la sección 3 sale de
  `medidas.json`.

## 1. Patrón de escala

| Magnitud | Valor |
|---|---|
| Casilla | 16 × 16 px |
| Escala de los mapas | **1 casilla = 16 px = 1 m** (el jugador mide 27 px = 1,69 m frente a 1,75 m reales: ×0,96) |
| Escala de la vista de carpa B | **48 px = 1 m de ancho y de alto, 24 px/m de fondo** (3/4, como el piso; lo de atrás se corre 6 px/m a la derecha). La carpa de 150 × 100 × 200 cm mide 72 × 120 px |
| Pantalla | 240–400 × 160 px = 15–25 × 10 m de mundo a la vista (el ancho depende del móvil) |
| Personajes | celda 32 × 32, pies en (16, 30); adultos de 27–28 px |
| Vista | mapas: cenital oblicua (3/4), el ancho se mide de frente; vista de carpa B: 3/4, recortada |
| Tolerancia | ×0,75–×1,33 coherente · ×0,5–×2,5 estilizado · fuera de eso, incoherente |

## 2. Mapas

| Mapa | Casillas | Qué hay (x, y) |
|---|---|---|
| Barrio (`town`) | 40 × 30 | Edificios de 7 × 6 en y 3–8: piso (2), growshop (14), bar (23); casa de Txaro, gris, 6 × 6 (32). Puertas: piso (5,8), growshop (17,8), bar (26,8) y casa de Txaro (34–35,8). Al barrio alto, por el camino del norte (11–12, 0); a los astilleros, por el muelle (39, 20–21). Calle: acera y 9, calzada y 10–11, acera y 12. Parque de los Sauces (1,13)–(11,27), con hierba alta en (7–10, 18–20) y (1–3, 21–23). Plaza (14,13)–(26,24), con la fuente en (20,19). Ría (31–38, 14–28), muelle (34–38, 16–25) y puente (31–33, 19–20). |
| Piso (`home`) | 12 × 8 (72 m²) | Paredes en y 0–1, con ventanas en (6,1) y (9,1) y el diploma en (7,1); suelo de 12 × 6 m. Cama (0,2–3), planta (1,2), ordenador (4,2), mesas de genética (5,2) y (6,2), mesa (3,5), nevera (0,6) y planta (11,7). Sitio A (8,2), 1 casilla: el armario 60 o el 80. Sitio B (10–11,2), 2 casillas: la carpa 100 (en x 10) o la 150 (x 10–11). Sitio C (2–3,2), 2 casillas: la carpa 120, cuando ya hay carpa en B. Salida en (5,7). |
| Growshop (`shop`) | 10 × 8 | Estanterías (0,1) y (8,1), mostrador (2–7, 3), expositores (0,5) y (9,5), Kiko (4,2). Salida en (4,7). |
| Bar El Ancla (`bar`) | 10 × 8 | Botellero (0–3, 1), barra (0–3, 3), taburetes (1,4) y (3,4), mesas (8,2) y (7,5), gramola (9,2). Josune (2,2), Toño (5,4) y Baltasar (7,4). Salida en (4,7). |
| Barrio alto (`alto`, 1.10) | 40 × 30 | Plaza del Ensanche (3–19, 4–17) con la fuente en (11,11) y 4 bancos. Comisaría gris 6 × 6 (24, 13–18), puerta ancha en (26–27,18). Jardines (22–38, 3–11) y flores (31–37, 14–18). Calle: acera y 20, calzada y 21–22, acera y 23. Camino al barrio en (11–12, 24–29). Arbusto con 80 € en (2,10). |
| Astilleros (`astilleros`, 1.10) | 40 × 30 | Tierra; astilleros cerrados (24–37, 4–10) con valla; almacén gris 6 × 6 (16, 8–13), puerta ancha en (18–19,13). Hierba alta en (2–6, 3–7) y (30–35, 13–15). Muelle de carga en y 19–22 y dos diques (6–8 y 26–28, 23–27); agua abajo. Darko (24,16) desde el capítulo 7. Bolsa con 2 sprays en (4,5). |
| Casa de Txaro (`txaro`, 1.10) | 10 × 8 | Cama (0,2–3), mesa (5,4), nevera (9,6) y plantas. Txaro (6,3) desde su primera misión. Salida en (4,7). |
| Comisaría (`comisaria`, 1.10) | 10 × 8 | Estanterías, mostrador (2–7, 3) y bancos (0,5) y (9,5). Molina (4,2) desde el capítulo 5. Salida en (4,7). |
| Almacén (`almacen`, 1.10) | 10 × 8 | Cajas en las esquinas, mesa (5,4) y taburete (4,4). Toño (5,2) mientras hay un encargo de Baltasar. Salida en (4,7). |

**NPC del barrio:** Begoña (10,12), Txaro (3,18), Unai (17,18), Darko (20,14), Jurado (18,15), Molina (23,15), agente (22,17),
Patxi (21,21) e Iñaki (37,21).

**Objetos del barrio:**
- A la vista: spray (8,25), abono (36,24) y bocata (15,23).
- Escondidos en arbustos: Acapulco Gold (2,26), 50 € (9,16) e insecticida (10,24).

**Carpas del piso:** muebles sólidos que se usan con A desde la casilla de delante; dentro, la vista de carpa B.
`home.png` sale con las tres montadas (armario 80, carpa 150 y carpa 120).

| Carpa | Real | En el piso | En la vista B | Plazas | Focos |
|---|---|---|---|---|---|
| Armario 60 × 60 | 0,6 × 0,6 × 1,6 m | 1 casilla (A) | 2 en 1 fila | 2 | hasta 250 W |
| Armario 80 × 80 | 0,8 × 0,8 × 1,8 m | 1 casilla (A) | 2 delante y 1 detrás, centrada | 3 | hasta 400 W |
| Carpa 100 × 100 | 1 × 1 × 2 m | 1 casilla (B) | 2 × 2 (en rejilla, a 50 cm) | 4 | hasta 480 W |
| Carpa 150 × 100 | 1,5 × 1 × 2 m | 2 casillas (B) | 3 × 2 | 6 | hasta 720 W |
| Carpa 120 × 120 | 1,2 × 1,2 × 2 m | 2 casillas (C) | 3 × 2 | 6 | hasta 720 W |

## 3. Medidas (sprite en juego frente a tamaño real)

En negrita, lo que se sale de ×0,75–×1,33. «Frente»: ancho de la carpa abierta de un poste a otro.

| Grupo | Sprite | px | Eje | En juego | Real | Ratio |
|---|---|---|---|---|---|---|
| Personajes | Jugador | 16×27 | alto | 1,69 m | 1,75 m | ×0,96 |
|  | Kiko | 18×28 | alto | 1,75 m | 1,78 m | ×0,98 |
|  | Baltasar | 16×27 | alto | 1,69 m | 1,8 m | ×0,94 |
|  | Txaro | 16×28 | alto | 1,75 m | 1,55 m | ×1,13 |
|  | Unai (niño) | 14×28 | alto | 1,75 m | 1,35 m | ×1,30 |
|  | Agente | 16×28 | alto | 1,75 m | 1,8 m | ×0,97 |
| Mobiliario | Cama | 19×32 | ancho | 1,19 m | 0,9 m | ×1,32 |
|  | Nevera | 18×31 | ancho | 1,13 m | 0,6 m | **×1,88** |
|  | Ordenador | 16×15 | ancho | 1 m | 1,2 m | ×0,83 |
|  | Mesa genética | 16×15 | ancho | 1 m | 1,2 m | ×0,83 |
|  | Mesa genética 2 | 16×14 | ancho | 1 m | 1,2 m | ×0,83 |
|  | Mesa | 14×13 | ancho | 0,88 m | 0,8 m | ×1,09 |
|  | Planta deco | 14×16 | alto | 1 m | 0,9 m | ×1,11 |
|  | Estantería | 16×9 | ancho | 1 m | 0,9 m | ×1,11 |
|  | Mostrador | 16×16 | alto | 1 m | 1 m | ×1,00 |
|  | Expositor | 14×15 | ancho | 0,88 m | 0,8 m | ×1,09 |
|  | Botellero | 16×11 | ancho | 1 m | 1 m | ×1,00 |
|  | Taburete | 8×14 | alto | 0,88 m | 0,75 m | ×1,17 |
|  | Mesa de bar | 14×14 | ancho | 0,88 m | 0,7 m | ×1,25 |
|  | Gramola | 12×24 | ancho | 0,75 m | 0,7 m | ×1,07 |
|  | Cajas | 14×15 | ancho | 0,88 m | 0,6 m | **×1,46** |
| Cultivo (piso, 16 px/m) | Armario 60×60 | 10×31 | ancho | 0,63 m | 0,6 m | ×1,04 |
|  | Armario 80×80 | 13×35 | ancho | 0,81 m | 0,8 m | ×1,02 |
|  | Carpa 100×100 | 16×39 | ancho | 1 m | 1 m | ×1,00 |
|  | Carpa 120×120 | 19×42 | ancho | 1,19 m | 1,2 m | ×0,99 |
|  | Carpa 150×100 | 24×39 | ancho | 1,5 m | 1,5 m | ×1,00 |
| Vista de carpa B (48 px/m) | Armario 60 | 33×93 | frente | 0,58 m | 0,6 m | ×0,97 |
|  | Armario 80 | 44×108 | frente | 0,79 m | 0,8 m | ×0,99 |
|  | Carpa 100 | 55×122 | frente | 1 m | 1 m | ×1,00 |
|  | Carpa 120 | 66×127 | frente | 1,21 m | 1,2 m | ×1,01 |
|  | Carpa 150 | 79×122 | frente | 1,5 m | 1,5 m | ×1,00 |
|  | Maceta 7 L | 11×15 | ancho | 0,23 m | 0,22 m | ×1,04 |
|  | Maceta 11 L | 12×17 | ancho | 0,25 m | 0,25 m | ×1,00 |
|  | Maceta 18 L | 14×20 | ancho | 0,29 m | 0,3 m | ×0,97 |
|  | Maceta 25 L | 17×20 | ancho | 0,35 m | 0,35 m | ×1,01 |
|  | CFL 125 | 17×10 | ancho | 0,35 m | 0,35 m | ×1,01 |
|  | Sodio 250 | 22×9 | ancho | 0,46 m | 0,45 m | ×1,02 |
|  | Sodio 400 | 24×9 | ancho | 0,5 m | 0,5 m | ×1,00 |
|  | Sodio 600 | 26×9 | ancho | 0,54 m | 0,55 m | ×0,98 |
|  | LED 100 | 12×6 | ancho | 0,25 m | 0,25 m | ×1,00 |
|  | LED 200 | 14×6 | ancho | 0,29 m | 0,3 m | ×0,97 |
|  | LED 480 | 29×6 | ancho | 0,6 m | 0,6 m | ×1,01 |
|  | LED 720 | 48×6 | ancho | 1 m | 1 m | ×1,00 |
|  | Ventilador | 9×14 | ancho | 0,19 m | 0,2 m | ×0,94 |
|  | Filtro y extractor | 31×10 | ancho | 0,65 m | 0,65 m | ×0,99 |
|  | Depósito de goteo | 14×24 | alto | 0,5 m | 0,5 m | ×1,00 |
|  | Germinando (índica) | 9×5 | alto | 0,1 m | 0,05 m | **×2,08** |
|  | Plántula (índica) | 10×15 | alto | 0,31 m | 0,15 m | **×2,08** |
|  | Vegetativo (índica) | 20×17 | alto | 0,35 m | 0,35 m | ×1,01 |
|  | Floración (índica) | 28×25 | alto | 0,52 m | 0,55 m | ×0,95 |
|  | Lista (índica) | 30×30 | alto | 0,63 m | 0,65 m | ×0,96 |
|  | Germinando (sativa) | 9×5 | alto | 0,1 m | 0,05 m | **×2,08** |
|  | Plántula (sativa) | 10×15 | alto | 0,31 m | 0,15 m | **×2,08** |
|  | Vegetativo (sativa) | 18×22 | alto | 0,46 m | 0,45 m | ×1,02 |
|  | Floración (sativa) | 24×35 | alto | 0,73 m | 0,75 m | ×0,97 |
|  | Lista (sativa) | 28×42 | alto | 0,88 m | 0,9 m | ×0,97 |
|  | Germinando (híbrida) | 9×5 | alto | 0,1 m | 0,05 m | **×2,08** |
|  | Plántula (híbrida) | 10×15 | alto | 0,31 m | 0,15 m | **×2,08** |
|  | Vegetativo (híbrida) | 18×19 | alto | 0,4 m | 0,4 m | ×0,99 |
|  | Floración (híbrida) | 24×28 | alto | 0,58 m | 0,6 m | ×0,97 |
|  | Lista (híbrida) | 28×33 | alto | 0,69 m | 0,7 m | ×0,98 |
| Exterior | Árbol | 18×24 | alto | 1,5 m | 6 m | **×0,25** |
|  | Farola | 6×56 | alto | 3,5 m | 4 m | ×0,88 |
|  | Banco | 16×12 | ancho | 1 m | 1,8 m | **×0,56** |
|  | Fuente | 26×27 | ancho | 1,63 m | 3 m | **×0,54** |
|  | Arbusto | 14×11 | ancho | 0,88 m | 1,2 m | **×0,73** |
|  | Valla | 16×12 | alto | 0,75 m | 1 m | ×0,75 |
|  | Edificio (piso) | 112×96 | ancho | 7 m | 14 m | **×0,50** |
|  | Edificio (bar) | 112×96 | ancho | 7 m | 14 m | **×0,50** |

## 4. Qué sale del plano

1. **Personajes adultos, muebles y carpas: coherentes.** Entre ×0,8 y ×1,3 en el piso (1 m = 16 px); las 5 carpas
   cerradas, a ×1,0.
2. **Vista de carpa B: 29 de 35 piezas a escala** (×0,94–×1,06): carpas, macetas, focos, extras y las plantas
   de vegetativo a lista en sus 3 portes (índica 0,65 m, sativa 0,9 m e híbrida 0,7 m listas, despuntadas desde la 1.10). Solo germinando y
   plántula van a ×2, a propósito, para que se vean (5 y 15 cm reales darían 2 y 7 px).
3. **El piso, a tamaño real.** 12 × 8 casillas (72 m² con paredes; 12 × 6 m de suelo), frente a 240 m² de la 1.7.0.
4. **Siguen fuera de escala, sin tocar:** la nevera (×1,9) y las cajas (×1,5), que se rehacen en P5 (D5); la cama
   (×1,3), los personajes que no cambian de altura (Unai ×1,3, Txaro ×1,13) y el exterior comprimido (árboles ×0,25,
   edificios ×0,5), que es la convención del género. Los árboles piden arte nuevo (pendiente).
5. **Alturas corregidas en la 1.10** (retoque a mano, `tools/sprites/a-mano/alturas.py`, sin créditos): la farola
   pasa de 1,69 a 3,5 m (×0,88), el mostrador y la barra del bar de 0,69 a 1 m (la barra, ya más alta que los
   taburetes) y la gramola de 1 a 1,5 m. Lo que cuelga de la pared ya no se pinta a ras de suelo (`ALZA` en
   `01b-arte.js` y `pinta.gd`): las ventanas y los carteles (el diploma) a 0,9 m, las baldas de las plantas a
   1 m y el botellero a 1,05 m.

## 5. Decisión: opción A (1.8.0)

De las tres opciones de la 1.7.0 (A: vista de carpa a escala de detalle · B: interiores a ×2, más de 600
generaciones · C: ajuste dentro del estilo, 60–80 generaciones) se eligió y aplicó la **A**:

- **Piso a 1 casilla = 1 m** (12 × 8). Las carpas son muebles (`carpa`): armarios 60 y 80 y carpa 100 de 1 casilla,
  carpas 120 y 150 de 2, en los sitios A (8,2), B (10,2) y C (2,2). Sprites `carpa-<t>-mapa` (celda `carpa_mapa` 32 × 48).
- **Vista de carpa** (`src/js/09b-carpa.js`): A delante de una carpa la abre. La cruceta elige plaza o foco, A cuida
  (`potAction`) o cambia el foco y los extras (`carpaAction`) y B sale. El tiempo no corre mientras se mira.
- **Arte (1.8):** 4 generaciones de PixelLab (pixflux img2img, strength 130, sobre huellas procedurales) para carpas del
  mapa, carpas de la vista de frente, macetas y fondo; las plantas, importadas de Strainmon. Previsión inicial: 120–180.
- **Retirado:** carpas de la 1.6/1.7 (`carpa-<t>`, `-fuera`), `mesa-cultivo`, `macetas` y `planta-fases`.

## 6. Vista de carpa B (P2 del plan de producción)

Decisión D1 del [plan de producción](PLAN-PRODUCCION.md#0-decisiones-aprobadas): la carpa se ve como en la 1.6–1.7
(recortada: sin techo, sin frente y sin lateral derecho; se ven el fondo y la pared izquierda de mylar, el suelo, las
macetas, las plantas y el foco colgando) pero a escala real.

- **Escala:** 48 px/m de ancho y de alto y 24 px/m de fondo, en una escena de 240 px centrada con `OX()`. La carpa
  apoya la espalda en la pared del cuarto (y 126). Las medidas reales de cada carpa están en `CARPAS[t].cm`.
- **Plazas:** filas de `CARPAS[t].cols` macetas, la 0 delante y la 1 detrás. ◀ ▶ cambian de plaza, ▲ ▼ de fila y,
  desde la de atrás, ▲ elige el foco. Con una plaza de atrás elegida, la fila de delante se ve en transparencia.
- **Distancia segura (1.10):** cada maceta va en el centro de su parte de la carpa (una fila incompleta se reparte todo el
  ancho), lo más separada posible de las demás. Cada planta se dibuja de su tamaño real (`PLANTA_CM`), pero su copa,
  como mucho del círculo que no toca a ninguna vecina ni las paredes, menos 4 cm de aire (`q.cw`), y su alto, como
  mucho lo que deja el foco: alto de la carpa − 28 cm (el foco) − la distancia de seguridad del foco (`FOCO_SEP`) − el alto
  de la maceta (`q.ch`). Así una planta grande en una carpa llena se ve podada y doblada, como lo haría un cultivador.
  `npm run test:arte` comprueba en las 5 carpas, con cada foco y maceta, que nada se toca.

| Carpa | Plazas | Centros de las macetas (cm) | Entre centros | Del centro a la pared | Copa máx. | Alto máx. de la planta con cada foco (en la maceta más alta que admite) |
|---|---|---|---|---|---|---|
| Armario 60×60 | 2 | 15,30 · 45,30 | 30 cm | 15 cm | 26 cm | CFL 100 · Sodio 250 80 · LED 100 85 · LED 200 85 cm (tela 11 L) |
| Armario 80×80 | 3 | 20,20 · 60,20 · 40,60 | 40 cm | 20 cm | 36 cm | CFL 114 · Sodio 250 94 · Sodio 400 84 · LED 100 99 · LED 200 99 cm (18 L) |
| Carpa 100×100 | 4 | 25,25 · 75,25 · 25,75 · 75,75 | 50 cm | 25 cm | 46 cm | CFL 134 · Sodio 250 114 · Sodio 400 104 · LED 100 119 · LED 200 119 · LED 480 109 cm (18 L) |
| Carpa 120×120 | 6 | 20,30 · 60,30 · 100,30 · 20,90 · 60,90 · 100,90 | 40 cm | 20 cm | 36 cm | CFL 134 · Sodio 250 114 · Sodio 400 104 · Sodio 600 94 · LED 100 119 · LED 200 119 · LED 480 109 · LED 720 104 cm (18 L) |
| Carpa 150×100 | 6 | 25,25 · 75,25 · 125,25 · 25,75 · 75,75 · 125,75 | 50 cm | 25 cm | 46 cm | CFL 134 · Sodio 250 114 · Sodio 400 104 · Sodio 600 94 · LED 100 119 · LED 200 119 · LED 480 109 · LED 720 104 cm (18 L) |

Distancia de seguridad de la cima al foco: CFL 10 cm · Sodio 250 30 cm · LED 100 25 cm · LED 200 25 cm · Sodio 400 40 cm · LED 480 35 cm · Sodio 600 50 cm · LED 720 40 cm.
Las plantas más grandes, lista (despuntadas y en mainline, 1.10): índica 60 cm de ancho y 65 de alto, sativa 55 × 90 e híbrida 58 × 70.

- **Piezas procedurales** (son también las huellas de las láminas de P3–P4, `npm run sprites:huellas`): `carpa34`,
  `cuarto34`, `maceta34` (`MACETA_CM`), `planta34` por porte (`porteInd`: el % índica de cada planta; `PLANTA_CM`), `foco34` (`FOCO_CM`) y
  `extra34`. Un foco centrado a 28 cm del techo; su luz, recortada a la carpa y detrás de las plantas.
- **Estado:** el arte de plantas y carpas de la vista B **no está aprobado**: se pide en P3–P4 con una referencia nueva.
  Mientras tanto, la vista B se dibuja con el arte procedural también con el atlas, así que no se publica versión.
