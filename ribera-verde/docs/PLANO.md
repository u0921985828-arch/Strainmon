# Plano de Ribera Verde (1.10, en desarrollo)

Inventario de todo lo que ocupa sitio en el juego (mapas, edificios, muebles, carpas, macetas, plantas, focos, extras y
personajes), medido contra su tamaño real. En la 1.7.0 sirvió para decidir la escala; en la 1.8.0 se aplicó la
**opción A** (sección 5). En P2 del [plan de producción](PLAN-PRODUCCION.md) la vista de carpa pasó a la **B**
(sección 6): carpa abierta en 3/4 a 48 px/m.

- Imágenes: `docs/plano/town.png`, `home.png`, `shop.png`, `bar.png` (rejilla, coordenadas y rótulos),
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
| Barrio (`town`) | 40 × 30 | Edificios de 7 × 6 en y 3–8: piso (2), growshop (14), bar (23); bloque gris 6 × 6 (32). Puertas: piso (5,8), growshop (17,8), bar (26,8). Calle: acera y 9, calzada y 10–11, acera y 12. Parque de los Sauces (1,13)–(11,27), con hierba alta en (7–10, 18–20) y (1–3, 21–23). Plaza (14,13)–(26,24), con la fuente en (20,19). Ría (31–38, 14–28), muelle (34–38, 16–25) y puente (31–33, 19–20). |
| Piso (`home`) | 12 × 8 (72 m²) | Paredes en y 0–1, con ventanas en (6,1) y (9,1) y el diploma en (7,1); suelo de 12 × 6 m. Cama (0,2–3), planta (1,2), ordenador (4,2), mesas de genética (5,2) y (6,2), mesa (3,5), nevera (0,6) y planta (11,7). Sitio A (8,2), 1 casilla: el armario 60 o el 80. Sitio B (10–11,2), 2 casillas: la carpa 100 (en x 10) o la 150 (x 10–11). Sitio C (2–3,2), 2 casillas: la carpa 120, cuando ya hay carpa en B. Salida en (5,7). |
| Growshop (`shop`) | 10 × 8 | Estanterías (0,1) y (8,1), mostrador (2–7, 3), expositores (0,5) y (9,5), Kiko (4,2). Salida en (4,7). |
| Bar El Ancla (`bar`) | 10 × 8 | Botellero (0–3, 1), barra (0–3, 3), taburetes (1,4) y (3,4), mesas (8,2) y (7,5), gramola (9,2). Josune (2,2), Toño (5,4) y Baltasar (7,4). Salida en (4,7). |

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
| Carpa 100 × 100 | 1 × 1 × 2 m | 1 casilla (B) | 2 × 2 (fila de atrás al tresbolillo) | 4 | hasta 480 W |
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
|  | Mostrador | 16×11 | alto | 0,69 m | 1 m | **×0,69** |
|  | Expositor | 14×15 | ancho | 0,88 m | 0,8 m | ×1,09 |
|  | Botellero | 16×11 | ancho | 1 m | 1 m | ×1,00 |
|  | Taburete | 8×14 | alto | 0,88 m | 0,75 m | ×1,17 |
|  | Mesa de bar | 14×14 | ancho | 0,88 m | 0,7 m | ×1,25 |
|  | Gramola | 12×16 | ancho | 0,75 m | 0,7 m | ×1,07 |
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
|  | Vegetativo (índica) | 22×23 | alto | 0,48 m | 0,45 m | ×1,06 |
|  | Floración (índica) | 32×36 | alto | 0,75 m | 0,75 m | ×1,00 |
|  | Lista (índica) | 34×43 | alto | 0,9 m | 0,9 m | ×1,00 |
|  | Germinando (sativa) | 9×5 | alto | 0,1 m | 0,05 m | **×2,08** |
|  | Plántula (sativa) | 10×15 | alto | 0,31 m | 0,15 m | **×2,08** |
|  | Vegetativo (sativa) | 18×35 | alto | 0,73 m | 0,7 m | ×1,04 |
|  | Floración (sativa) | 28×59 | alto | 1,23 m | 1,2 m | ×1,02 |
|  | Lista (sativa) | 30×68 | alto | 1,42 m | 1,4 m | ×1,01 |
|  | Germinando (híbrida) | 9×5 | alto | 0,1 m | 0,05 m | **×2,08** |
|  | Plántula (híbrida) | 10×15 | alto | 0,31 m | 0,15 m | **×2,08** |
|  | Vegetativo (híbrida) | 20×27 | alto | 0,56 m | 0,55 m | ×1,02 |
|  | Floración (híbrida) | 28×45 | alto | 0,94 m | 0,95 m | ×0,99 |
|  | Lista (híbrida) | 30×52 | alto | 1,08 m | 1,1 m | ×0,98 |
| Exterior | Árbol | 18×24 | alto | 1,5 m | 6 m | **×0,25** |
|  | Farola | 6×27 | alto | 1,69 m | 4 m | **×0,42** |
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
   de vegetativo a lista en sus 3 portes (índica 0,9 m, sativa 1,4 m e híbrida 1,1 m listas). Solo germinando y
   plántula van a ×2, a propósito, para que se vean (5 y 15 cm reales darían 2 y 7 px).
3. **El piso, a tamaño real.** 12 × 8 casillas (72 m² con paredes; 12 × 6 m de suelo), frente a 240 m² de la 1.7.0.
4. **Siguen fuera de escala, sin tocar:** la nevera (×1,9) y las cajas (×1,5), que se rehacen en P5 (D5); la cama
   (×1,3), los personajes que no cambian de altura (Unai ×1,3, Txaro ×1,13) y el exterior comprimido (árboles ×0,25,
   farolas ×0,42, edificios ×0,5), que es la convención del género.

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
- **Plazas:** filas de `CARPAS[t].cols` macetas; la de delante y la de atrás al tresbolillo (una fila incompleta va
  centrada). ◀ ▶ cambian de plaza, ▲ ▼ de fila y, desde la de atrás, ▲ elige el foco.
- **Piezas procedurales** (son también las huellas de las láminas de P3–P4, `npm run sprites:huellas`): `carpa34`,
  `cuarto34`, `maceta34` (`MACETA_CM`), `planta34` por porte (`PORTE`, `PLANTA_CM`), `foco34` (`FOCO_CM`) y
  `extra34`. Un foco centrado a 28 cm del techo; su luz, recortada a la carpa y detrás de las plantas.
- **Estado:** el arte de plantas y carpas de la vista B **no está aprobado**: se pide en P3–P4 con una referencia nueva.
  Mientras tanto, la vista B se dibuja con el arte procedural también con el atlas, así que no se publica versión.
