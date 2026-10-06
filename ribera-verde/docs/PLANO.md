# Plano de Ribera Verde (1.8.0)

Inventario de todo lo que ocupa sitio en el juego (mapas, edificios, muebles, carpas, macetas, plantas, focos y
personajes), medido contra su tamaño real. En la 1.7.0 sirvió para decidir la escala; en la 1.8.0 se aplicó la
**opción A** (sección 5) y este documento queda como referencia de medidas.

- Imágenes: `docs/plano/town.png`, `home.png`, `shop.png`, `bar.png` (rejilla, coordenadas y rótulos) y
  `docs/plano/escala.png` (todos los sprites junto al jugador sobre la misma línea de suelo).
- Datos: `docs/plano/medidas.json` (posiciones de cada mapa y las 47 medidas de abajo).
- Se regenera con `npm run plano` (`tools/plano.js`): pinta los mapas con el motor del juego y mide la caja opaca de
  cada fotograma del atlas, así que el plano siempre coincide con lo que se ve.

## 1. Patrón de escala

| Magnitud | Valor |
|---|---|
| Casilla | 16 × 16 px |
| Escala de los mapas | **1 casilla = 16 px = 1 m** (el jugador mide 27 px = 1,69 m frente a 1,75 m reales: ×0,96) |
| Escala de la vista de carpa | **64 px = 1 m** (la pantalla de 240 × 160 muestra 3,75 × 2,5 m; la carpa de 150 × 200 cm cabe entera) |
| Pantalla | 240–400 × 160 px = 15–25 × 10 m de mundo a la vista (el ancho depende del móvil) |
| Personajes | celda 32 × 32, pies en (16, 30); adultos de 27–28 px |
| Vista | mapas: cenital oblicua (3/4), el ancho se mide de frente; vista de carpa: de frente |
| Tolerancia | ×0,75–×1,33 coherente · ×0,5–×2,5 estilizado · fuera de eso, incoherente |

## 2. Mapas

| Mapa | Casillas | Qué hay (x, y) |
|---|---|---|
| Barrio (`town`) | 40 × 30 | Edificios de 7 × 6 en y 3–8: piso (2), growshop (14), bar (23); bloque gris 6 × 6 (32). Puertas: piso (5,8), growshop (17,8), bar (26,8). Calle: acera y 9, calzada y 10–11, acera y 12. Parque de los Sauces (1,13)–(11,27), con hierba alta en (7–10, 18–20) y (1–3, 21–23). Plaza (14,13)–(26,24), con la fuente en (20,19). Ría (31–38, 14–28), muelle (34–38, 16–25) y puente (31–33, 19–20). |
| Piso (`home`) | 12 × 8 (72 m²) | Paredes en y 0–1, suelo de 12 × 6 m. Cama (0,2–3), planta (1,2), ordenador (4,2), mesas de genética (5,2) y (6,2), mesa (3,5), nevera (0,6) y planta (11,7). Sitio A (8,2), 1 casilla: el armario 60. Sitio B (10–11,2), 2 casillas: la carpa 100 (en x 10) o la 150 (x 10–11). Salida en (5,7). |
| Growshop (`shop`) | 10 × 8 | Estanterías (0,1) y (8,1), mostrador (2–7, 3), expositores (0,5) y (9,5), Kiko (4,2). Salida en (4,7). |
| Bar El Ancla (`bar`) | 10 × 8 | Botellero (0–3, 1), barra (0–3, 3), taburetes (1,4) y (3,4), mesas (8,2) y (7,5), gramola (9,2). Josune (2,2), Toño (5,4) y Baltasar (7,4). Salida en (4,7). |

**NPC del barrio:** Begoña (10,12), Txaro (3,18), Unai (17,18), Darko (20,14), Jurado (18,15), Molina (23,15), agente (22,17),
Patxi (21,21) e Iñaki (37,21).

**Objetos del barrio:**
- A la vista: spray (8,25), fertilizante (36,24) y bocata (15,23).
- Escondidos en arbustos: Acapulco Gold (2,26), 50 € (9,16) e insecticida (10,24).

**Carpas del piso:** muebles sólidos que se usan con A desde la casilla de delante; dentro, la vista de carpa.

| Carpa | Real | En el piso | En la vista | Plazas | Focos |
|---|---|---|---|---|---|
| Armario 60 × 60 | 0,6 × 0,6 × 1,6 m | 1 casilla | 2 en 1 fila | 2 | hasta 250 W |
| Carpa 100 × 100 | 1 × 1 × 2 m | 1 casilla | 2 × 2 (fila de atrás al tresbolillo) | 4 | hasta 480 W |
| Carpa 150 × 100 | 1,5 × 1 × 2 m | 2 casillas | 3 × 2 | 6 | hasta 720 W |

## 3. Medidas (sprite en juego frente a tamaño real)

| Grupo | Sprite | px | Eje | En juego | Real | Ratio |
|---|---|---|---|---|---|---|
| Personajes | Jugador | 16×27 | alto | 1,69 m | 1,75 m | ×0,96 |
| | Kiko | 18×28 | alto | 1,75 m | 1,78 m | ×0,98 |
| | Baltasar | 16×27 | alto | 1,69 m | 1,80 m | ×0,94 |
| | Agente | 16×28 | alto | 1,75 m | 1,80 m | ×0,97 |
| | Txaro | 16×28 | alto | 1,75 m | 1,55 m | **×1,13** |
| | Unai (niño) | 14×28 | alto | 1,75 m | 1,35 m | **×1,30** |
| Mobiliario | Cama | 19×32 | ancho | 1,19 m | 0,9 m | ×1,32 |
| | Nevera | 18×31 | ancho | 1,13 m | 0,6 m | **×1,88** |
| | Ordenador / mesas de genética | 16×15 | ancho | 1 m | 1,2 m | ×0,83 |
| | Mesa | 14×13 | ancho | 0,88 m | 0,8 m | ×1,09 |
| | Planta decorativa | 14×16 | alto | 1 m | 0,9 m | ×1,11 |
| | Estantería | 16×9 | ancho | 1 m | 0,9 m | ×1,11 |
| | Mostrador | 16×11 | alto | 0,69 m | 1 m | ×0,69 |
| | Expositor | 14×15 | ancho | 0,88 m | 0,8 m | ×1,09 |
| | Botellero | 16×11 | ancho | 1 m | 1 m | ×1,00 |
| | Taburete | 8×14 | alto | 0,88 m | 0,75 m | ×1,17 |
| | Mesa de bar | 14×14 | ancho | 0,88 m | 0,7 m | ×1,25 |
| | Gramola | 12×16 | ancho | 0,75 m | 0,7 m | ×1,07 |
| | Cajas | 14×15 | ancho | 0,88 m | 0,6 m | ×1,46 |
| Cultivo (piso, 16 px/m) | Armario 60 × 60 | 10×31 | ancho | 0,63 m | 0,6 m | ×1,04 |
| | Carpa 100 × 100 | 16×39 | ancho | 1 m | 1 m | ×1,00 |
| | Carpa 150 × 100 | 24×39 | ancho | 1,5 m | 1,5 m | ×1,00 |
| Vista de carpa (64 px/m) | Armario 60 × 60 | 42×105 | ancho | 0,66 m | 0,6 m | ×1,09 |
| | Carpa 100 × 100 | 68×133 | ancho | 1,06 m | 1 m | ×1,06 |
| | Carpa 150 × 100 | 100×133 | ancho | 1,56 m | 1,5 m | ×1,04 |
| | Maceta 7 L | 15×13 | ancho | 0,23 m | 0,22 m | ×1,07 |
| | Maceta 11 L | 17×15 | ancho | 0,27 m | 0,25 m | ×1,06 |
| | Maceta 18 L | 19×16 | ancho | 0,30 m | 0,30 m | ×0,99 |
| | Maceta 25 L | 24×18 | ancho | 0,38 m | 0,35 m | ×1,07 |
| | Germinando (Skunk #1) | 13×9 | alto | 0,14 m | 0,06 m | ×2,34 |
| | Plántula | 25×21 | alto | 0,33 m | 0,16 m | ×2,05 |
| | Vegetativo | 32×48 | alto | 0,75 m | 0,40 m | ×1,88 |
| | Floración | 32×48 | alto | 0,75 m | 0,78 m | ×0,96 |
| | Lista | 32×48 | alto | 0,75 m | 0,88 m | ×0,85 |
| | Foco CFL | 22×29 | ancho | 0,34 m | 0,45 m | ×0,76 |
| | Foco sodio | 30×23 | ancho | 0,47 m | 0,55 m | ×0,85 |
| | Panel LED | 30×25 | ancho | 0,47 m | 0,6 m | ×0,78 |
| Exterior | Árbol | 18×24 | alto | 1,5 m | 6 m | **×0,25** |
| | Farola | 6×27 | alto | 1,69 m | 4 m | **×0,42** |
| | Banco | 16×12 | ancho | 1 m | 1,8 m | ×0,56 |
| | Fuente | 26×27 | ancho | 1,63 m | 3 m | ×0,54 |
| | Arbusto | 14×11 | ancho | 0,88 m | 1,2 m | ×0,73 |
| | Valla | 16×12 | alto | 0,75 m | 1 m | ×0,75 |
| | Edificios (piso, bar) | 112×96 | ancho | 7 m | 14 m | ×0,50 |

## 4. Qué sale del plano (1.8.0)

1. **Personajes adultos, muebles y carpas: coherentes.** Están entre ×0,8 y ×1,3 en el piso (1 m = 16 px) y en la
   vista de carpa (1 m = 64 px). En la 1.7.0 la zona de cultivo iba a ×2,5–×5; ahora las carpas son muebles de 1–2
   casillas a ×1 y lo de dentro (macetas, plantas, focos) se mide en la vista.
2. **El crecimiento, estilizado.** Las plantas de la vista son el arte de cepas de Strainmon (`../assets/plants`,
   18 cepas × 5 fases) sin su tiesto y a ×0,45. Germinando y plántula salen ×2–×2,3 (para que se vean) y el
   vegetativo tardío ya alcanza el alto de la floración (×1,9); floración y lista, a escala. Dentro de la tolerancia
   «estilizado».
3. **El piso, a tamaño real.** 12 × 8 casillas (72 m² con paredes; 12 × 6 m de suelo), frente a 240 m² de la 1.7.0.
4. **Siguen fuera de escala, sin tocar:** la nevera (×1,9), las cajas (×1,5), la cama (×1,3), los personajes que no
   cambian de altura (Unai ×1,3, Txaro ×1,13) y el exterior comprimido (árboles ×0,25, farolas ×0,42, edificios ×0,5),
   que es la convención del género.

## 5. Decisión: opción A (1.8.0)

De las tres opciones de la 1.7.0 (A: vista de carpa a escala de detalle · B: interiores a ×2, más de 600
generaciones · C: ajuste dentro del estilo, 60–80 generaciones) se eligió y aplicó la **A**:

- **Piso a 1 casilla = 1 m** (12 × 8). Las carpas son muebles (`carpa`): armario 60 y carpa 100 de 1 casilla, carpa
  150 de 2, en los sitios A (8,2) y B (10,2). Sprites `carpa-<t>-mapa` (celda `carpa_mapa` 32 × 48).
- **Vista de carpa** (`src/js/09b-carpa.js`): A delante de una carpa la abre de frente a 64 px/m, sobre el fondo
  `cuarto-cultivo`, con `carpa-<t>-vista` (celda 104 × 136), `maceta-vista-<k>` (32 × 24), las plantas
  `planta-vista` (48 × 64) y los focos. La cruceta elige plaza o foco, A cuida (`potAction`) o cambia el foco
  (`carpaAction`) y B sale. El tiempo no corre mientras se mira.
- **Arte:** 4 generaciones de PixelLab (pixflux img2img, strength 130, sobre huellas procedurales) para carpas del
  mapa, carpas de la vista, macetas y fondo; las plantas, importadas de Strainmon. Previsión inicial: 120–180.
- **Retirado:** carpas de la 1.6/1.7 (`carpa-<t>`, `-fuera`), `mesa-cultivo`, `macetas` y `planta-fases`.
