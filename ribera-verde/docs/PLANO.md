# Plano de Ribera Verde (1.7.0)

Inventario de todo lo que ocupa sitio en el juego (mapas, edificios, muebles, carpas, bandejas, macetas, plantas, focos
y personajes), medido contra su tamaño real, para decidir **una sola escala** antes de rehacer arte.

- Imágenes: `docs/plano/town.png`, `home.png`, `shop.png`, `bar.png` (rejilla, coordenadas y rótulos) y
  `docs/plano/escala.png` (todos los sprites junto al jugador sobre la misma línea de suelo).
- Datos: `docs/plano/medidas.json` (posiciones de cada mapa y las 45 medidas de abajo).
- Se regenera con `npm run plano` (`tools/plano.js`): pinta los mapas con el motor del juego y mide la caja opaca de
  cada fotograma del atlas, así que el plano siempre coincide con lo que se ve.

## 1. Patrón de escala

| Magnitud | Valor |
|---|---|
| Casilla | 16 × 16 px |
| Escala de referencia | **1 casilla = 1 m** (el jugador mide 27 px = 1,69 m frente a 1,75 m reales: ×0,96) |
| Pantalla | 240–400 × 160 px = 15–25 × 10 m de mundo a la vista (el ancho depende del móvil) |
| Personajes | celda 32 × 32, pies en (16, 30); adultos de 27–28 px |
| Vista | cenital oblicua (3/4): el ancho se mide de frente; la altura visible suma alto y fondo |
| Tolerancia | ×0,75–×1,33 coherente · ×0,5–×2,5 estilizado · fuera de eso, incoherente |

## 2. Mapas

| Mapa | Casillas | Qué hay (x, y) |
|---|---|---|
| Barrio (`town`) | 40 × 30 | Edificios de 7 × 6 en y 3–8: piso (2), growshop (14), bar (23); bloque gris 6 × 6 (32). Puertas: piso (5,8), growshop (17,8), bar (26,8). Calle: acera y 9, calzada y 10–11, acera y 12. Parque de los Sauces (1,13)–(11,27), con hierba alta en (7–10, 18–20) y (1–3, 21–23). Plaza (14,13)–(26,24), con la fuente en (20,19). Ría (31–38, 14–28), muelle (34–38, 16–25) y puente (31–33, 19–20). |
| Piso (`home`) | 20 × 12 | Cama (1,2–3), ordenador (3,2), mesas de genética (4,2) y (5,2), mesa (3,6), nevera (1,7) y plantas (11,2), (0,8) y (19,10). Sitio A (7,2) de 4 de ancho: el armario 60. Sitio B (12,2) de 8 de ancho: la carpa 100 (6) o la carpa 150 (8). Salida en (5,11). |
| Growshop (`shop`) | 10 × 8 | Estanterías (0,1) y (8,1), mostrador (2–7, 3), expositores (0,5) y (9,5), Kiko (4,2). Salida en (4,7). |
| Bar El Ancla (`bar`) | 10 × 8 | Botellero (0–3, 1), barra (0–3, 3), taburetes (1,4) y (3,4), mesas (8,2) y (7,5), gramola (9,2). Josune (2,2), Toño (5,4) y Baltasar (7,4). Salida en (4,7). |

**NPC del barrio:** Begoña (10,12), Txaro (3,18), Unai (17,18), Darko (20,14), Jurado (18,15), Molina (23,15), agente (22,17),
Patxi (21,21) e Iñaki (37,21).

**Objetos del barrio:**
- A la vista: spray (8,25), fertilizante (36,24) y bocata (15,23).
- Escondidos en arbustos: Acapulco Gold (2,26), 50 € (9,16) e insecticida (10,24).

**Carpas del piso:**

| Carpa | Real | En el juego | Plazas | Focos |
|---|---|---|---|---|
| Armario 60 × 60 | 0,6 × 0,6 × 1,6 m | 4 × 5 casillas | 2 | hasta 250 W |
| Carpa 100 × 100 | 1 × 1 × 2 m | 6 × 5 casillas | 4 | hasta 480 W |
| Carpa 150 × 100 | 1,5 × 1 × 2 m | 8 × 5 casillas | 6 | hasta 720 W |

Las tres tienen el mismo trazado: pared del fondo en las filas 0–1, bandeja en la fila 2, pasillo en la fila 3 y frente con la puerta en la fila 4.

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
| Cultivo | Armario 60 × 60 | 48×72 | ancho | 3 m | 0,6 m | **×5,00** |
| | Carpa 100 × 100 | 80×72 | ancho | 5 m | 1 m | **×5,00** |
| | Carpa 150 × 100 | 112×72 | ancho | 7 m | 1,5 m | **×4,67** |
| | Bandeja (2 plazas) | 32×11 | ancho | 2 m | 0,6 m | **×3,33** |
| | Maceta 7 L | 10×11 | ancho | 0,63 m | 0,22 m | **×2,84** |
| | Maceta 11 L | 12×14 | ancho | 0,75 m | 0,25 m | **×3,00** |
| | Maceta 18 L | 14×14 | ancho | 0,88 m | 0,30 m | **×2,92** |
| | Maceta 25 L | 14×14 | ancho | 0,88 m | 0,35 m | ×2,50 |
| | Germinando (con maceta) | 16×19 | alto | 1,19 m | 0,25 m | **×4,75** |
| | Plántula | 16×25 | alto | 1,56 m | 0,35 m | **×4,46** |
| | Vegetativo | 26×30 | alto | 1,88 m | 0,6 m | **×3,13** |
| | Floración | 22×30 | alto | 1,88 m | 1 m | ×1,88 |
| | Lista | 24×32 | alto | 2 m | 1,1 m | ×1,82 |
| | Foco CFL | 22×29 | ancho | 1,38 m | 0,45 m | **×3,06** |
| | Foco sodio | 30×23 | ancho | 1,88 m | 0,55 m | **×3,41** |
| | Panel LED | 30×25 | ancho | 1,88 m | 0,6 m | **×3,13** |
| Exterior | Árbol | 18×24 | alto | 1,5 m | 6 m | **×0,25** |
| | Farola | 6×27 | alto | 1,69 m | 4 m | **×0,42** |
| | Banco | 16×12 | ancho | 1 m | 1,8 m | ×0,56 |
| | Fuente | 26×27 | ancho | 1,63 m | 3 m | ×0,54 |
| | Arbusto | 14×11 | ancho | 0,88 m | 1,2 m | ×0,73 |
| | Valla | 16×12 | alto | 0,75 m | 1 m | ×0,75 |
| | Edificios (piso, bar) | 112×96 | ancho | 7 m | 14 m | ×0,50 |

## 4. Qué sale del plano

1. **Personajes adultos y muebles: coherentes.** Están entre ×0,8 y ×1,3, así que 1 casilla = 1 m funciona.
   - Se salen la nevera (×1,9; debería medir 10–12 px de ancho), las cajas (×1,5) y, por poco, la cama (×1,3).
   - Las «mesitas» de cultivo de la 1.6 eran taburetes de 16 px por plaza: dentro de la carpa ×5 parecían de otra escala.
     En la 1.7 hay una bandeja continua por carpa (procedural, con la paleta de la carpa). Sigue a ×3,3 porque acompaña a la carpa.
2. **La zona de cultivo está entre 2,5 y 5 veces por encima de todo lo demás.**
   - Un armario de 60 cm ocupa 3 m de ancho visible.
   - Las macetas van a ×2,5–×3 y los focos a ×3–×3,4.
   - Una plántula mide casi lo mismo que el jugador (×4,5).
   - El motivo: cada plaza es una casilla (se usa con A delante), así que la carpa crece con el número de plantas.
3. **El crecimiento está aplastado.**
   - De germinando a lista, el sprite pasa de 19 a 32 px (×1,7). En la realidad pasa de 0,25 a 1,1 m (×4,4).
   - Las plantas pequeñas sobran de tamaño y las grandes se quedan cortas frente a su maceta.
4. **El exterior va comprimido.**
   - Árboles ×0,25, farolas ×0,42, bancos y fuente ×0,55, edificios ×0,5.
   - Es la convención del género (el barrio cabe en pocas pantallas), pero choca con unos interiores a ×1.
5. **Los personajes no cambian de altura.** Unai (un niño) y Txaro (una señora mayor) miden lo mismo que un adulto. Deberían medir unos 22 y 25 px.
6. **El piso es enorme.**
   - 20 × 12 casillas son 240 m², contra 60–80 m² de un piso real.
   - Lo hincha la zona de cultivo: las dos carpas ocupan 12 × 5 casillas, la cuarta parte del piso.

## 5. Propuesta de orden (a decidir)

Tres maneras de dejar una sola escala. El coste está en generaciones de PixelLab, con el mismo cálculo que `tools/sprites/validar.js`.

### A · Vista de carpa a escala de detalle (recomendada)

**El piso pasa a escala 1 casilla = 1 m.**
- Las carpas pasan a ser muebles: armario 60 de 1 × 2 casillas, carpa 100 de 1 × 2 y carpa 150 de 2 × 2 (ratio ≤ ×1,7).
- El piso puede ordenarse como uno real: entrada, salón, dormitorio, cocina y un **cuarto de cultivo** con las carpas y la mesa de genética juntas.

**Al pulsar A en una carpa se abre su vista frontal: una escena compuesta a 240 px, como el combate.**
- Escala de la vista: 1 m = 64 px, así que la pantalla muestra 3,75 × 2,5 m y la carpa de 150 × 200 cm (96 × 128 px) cabe entera.
- Lo que ya está a escala y se reutiliza: las macetas actuales (7 L = 14 px) y los focos (30 px ≈ 0,47 m).
- Lo que hay que hacer: plantas de 16 a 70 px de alto, con todo el crecimiento.
- Se elige la plaza con la cruceta. Regar, abonar, cosechar y cambiar foco o maceta siguen igual.

**Coste**
- Arte: 3 carpas por fuera (pequeñas), 3 interiores frontales y un lote de plantas altas, unas **120–180 generaciones**.
- Código: escena nueva y adaptar `test-historia` (las plazas dejan de ser casillas del mapa).

### B · Escala única ×2 en interiores

- 1 casilla = 0,5 m en el piso, la tienda y el bar.
- Mapas interiores de 40 × 24 y muebles y personajes al doble.
- Coste: rehacer los 36 personajes con sus animaciones, **más de 600 generaciones**. No compensa.

### C · Ajuste dentro del estilo actual (la más barata)

- Se mantienen las carpas de 4 a 8 casillas.
- Plantas reescaladas por fase (de 8 a 32 px) sin arte nuevo.
- Nevera y cajas recortadas.
- Unai a 22 px y Txaro a 25 px (2 personajes).
- Árboles de 2 × 3 casillas y farolas de 40 px (1 lote).
- Coste: unas **60–80 generaciones**. El cultivo sigue ×3–×5, pero dentro de él todo guarda proporción.

**Pendiente de decidir: A, B o C.** Con la decisión, el plano se rehace (`npm run plano`) y sirve de lista de trabajo.
