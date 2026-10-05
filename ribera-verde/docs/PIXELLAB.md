# Sprites con PixelLab

Kit para cambiar el arte procedural por sprites generados con el MCP de PixelLab sin tocar la lógica del juego. Funciona así: un prompt maestro, una paleta fija que se repite en cada prompt y cuatro grupos (personajes, crecimiento de plantas, piezas de entorno y combate). Se genera a 64 px de base y se reduce ×4 con vecino más próximo.

## Tamaños que espera el motor

| Pieza | Tamaño en juego | Generar a | Notas |
|---|---|---|---|
| Casilla de suelo u objeto | 16 × 16 | 64 × 64 | El objeto lleva fondo transparente y se pinta encima del suelo |
| Personaje | 16 × 20 | 64 × 80 | Pies y sombra en las 2 filas inferiores. Se dibuja 4 px por encima de su casilla |
| Planta en maceta | 16 × 26 | 64 × 104 | Base de la maceta en las 6 filas inferiores. Se dibuja 10 px por encima de su casilla |
| Combate | 48 × 60 (personaje ×3) | 64 × 80 | Basta con el personaje de frente (enemigos) y de espaldas (jugador) |
| Bolsa de objeto | 16 × 16 | 64 × 64 | — |

**Personajes:** 3 direcciones (abajo, arriba, izquierda; la derecha es el espejo de la izquierda) × 3 fotogramas (quieto, paso con la pierna izquierda, paso con la derecha). Hoja de 3 columnas × 3 filas.

**Plantas:** 5 fases (germinando, plántula, vegetativo, floración, lista) × 4 variantes (sana, con plaga, seca por falta de agua, seca y con plaga), más 1 planta muerta. Hoja de 5 columnas × 4 filas + 1 celda.

## Prompt maestro

Copia este bloque al principio de cada prompt:

```
Top-down 3/4 view pixel art, 16-bit handheld RPG style (early-2000s portable console look),
hard-edge pixels, no anti-aliasing, no dithering gradients, 1px dark outline #26262e,
3-tone cel shading (base, shadow, highlight), transparent background,
64x64 native canvas designed for 4x nearest-neighbor downscale to 16x16,
use ONLY the locked palette below, no text, no logos,
original design not based on any existing game, character or brand.
```

## Paleta fija

Repítela en cada prompt:

```
LOCKED PALETTE: outline #26262e | grass #84cc6c #62aa56 #b0e48c #3f8a46 | dirt #dcc08a #c4a46c #ecd6a4 |
sidewalk #dcd6c6 #bcb4a2 #eeeadc | asphalt #6c7482 #5e6674 #7e8694 #4a515c, road line #f0d860 |
water #4a92e0 #76b4f2 #b4dcfa #3474c4 | wood #c48a52 #a46e40 #dcac6c #74502e |
roofs red #d65a4a, green #46a262, blue #4a72c2, grey #8a92a2 | walls #f0dcae #d8ecc4 #d4dbe8 #e4cec4 |
glass #7cbcec #a8dcf0 | skin #f6c8a0 #e8b088 #d49a74 #b07850 #8a5a3a | white #f8f8f0 | accent red #e04040
```

## Grupo 1 · Personajes (ciclos de paseo)

Plantilla: `[prompt maestro] + [paleta] + "Character walk cycle sprite sheet, 3 columns (idle, left step, right step) x 3 rows (facing down, facing up, facing left), chibi proportions (big head ~45% of height), 64x80 per frame: " + descripción`.

| Personaje | Descripción para el prompt |
|---|---|
| Protagonista | young adult, green baseball cap (#2fa868, brim #1a6a40), dark brown hair #3a2a20, light skin, red t-shirt #e65040, navy jeans #36466e, dark sneakers |
| Kiko | hippie seed hunter in his 50s, long sandy hair #c48a3a and beard, tan skin, green shirt #5aa848, brown trousers #7a5a3a |
| Don Baltasar | bald loan shark in his 60s, short grey beard #9a9aa4, purple suit #4a2a5a over white shirt, dark trousers |
| Toño | big bald bodyguard, black moustache, black tracksuit #202024 |
| Darko | cocky young rival, black hoodie #202024 with hood up and red inner lining #c02828, dark trousers |
| Sargento Molina | police sergeant, navy cap with gold band #f0c040, blue shirt #6a8ac0, gold badge, grey moustache, navy trousers |
| Agente de patrulla | police officer, navy cap #1e2a5a, light blue shirt #8ab0e0, navy tie and trousers |
| Josune | bartender, black hair in a bun, white shirt with black vest #2a2a30, black trousers |
| Abuela Txaro | elderly woman, grey hair bun, round glasses, purple cardigan #8a5aa8, dark skirt |
| Iñaki | sailor, navy cap with white band, white sweater with blue stripes #3050a0, brown beard, navy trousers |
| Patxi | old man, bald with white beard, beige jacket #b8a070, brown trousers |
| Begoña | middle-aged neighbour, curly auburn hair #8a4a2a, pink blouse #e078a8, violet trousers #5a5a9a |
| Unai | kid, short black hair, yellow t-shirt #f0c838, blue shorts #4a6aa8 |
| Jurado | judge, short brown hair, glasses, charcoal suit #3a3a48, gold tie #c0a040 |
| Ladrón (base) | street thief, hood up, dark hoodie (variants #2a2a30, #3a2a4a, #2a3a2a, #4a2a2a), accent drawstrings, grey trousers |
| Clientes (×4) | generic townsfolk, varied hair (short, long, curly, bun, cap) and casual clothes from the palette |

## Grupo 2 · Hojas de crecimiento (plantas)

Plantilla: `[maestro] + [paleta] + "Cannabis plant growth-stage sprite sheet in a black fabric grow pot, 5 columns (sprout, seedling, vegetative bush, flowering with small buds, harvest-ready with big buds and sparkle) x 4 rows (healthy, infested with tiny red spider mites, thirsty with dry yellow leaves, thirsty and infested), plus one extra frame of a dead dry plant, 64x104 per frame, leaves green #3c9a3e / shadow #22662a / highlight #74d064, dry leaves #b8aa48 / shadow #8a7c30 / highlight #d8cc78, bud color: [COLOR]"`.

Sale una hoja por variedad cambiando `[COLOR]` (los colores están en [GENETICA.md](GENETICA.md)). Para empezar, con 5 basta: `#9bd35a` (Ría Skunk), `#e8e05a` (Limón Haze), `#7aa6e0` (Niebla Blue), `#a070d0` (Púrpura Monte) y `#e05050` (Dragón de Ribera). El resto se puede teñir por código.

## Grupo 3 · Piezas de entorno (tileables)

Plantilla: `[maestro] + [paleta] + "Seamless tileable 64x64 tile: " + pieza`. Las claves son los nombres en `TILES` (`src/js/01-tiles.js`).

- **Suelo exterior:**
  - `grass`: short grass with small tufts
  - `flowers`: grass with 4 tiny red, yellow and white flowers
  - `tallgrass`: dense tall grass blades (encounter zone)
  - `dirt`: packed dirt path
  - `walk`: light paving stones sidewalk
  - `roadT` / `roadB`: asphalt road, upper half with a dark curb on top and yellow dashed centre line at the bottom, and lower half with the curb at the bottom
  - `plaza`: warm beige square stone plaza
  - `water`: river water with small wave lines, 2 animation frames
  - `bridgeT` / `bridgeB`: wooden bridge planks with rail on top or bottom
  - `dock`: wooden pier planks
- **Edificios** (×4 colores: piso rojo, growshop verde, bar azul, gris):
  - `roofT_*`: shingle roof top row with ridge highlight
  - `roofB_*`: shingle roof bottom row with dark eave
  - `wall_*`: siding wall
  - `win_*`: wall with white-framed window
  - `door_*`: wall with door; wooden for the flat, glass for the growshop, dark wood for the bar
- **Interiores:**
  - `floor`: wood planks
  - `floorB`: dark wood planks
  - `floorS`: shop checker tiles
  - `tent`: reflective silver grow-tent floor
  - `mat`: red door mat
  - `iwT_*` / `iwB_*`: interior wall top and bottom in 3 wallpapers (cream, mint, wood)
- **Objetos** (fondo transparente):
  - *Barrio:* `tree` round leafy tree, `bush`, `fence` wooden, `sign` wooden signboard, `lamp` street lamp, `bench` park bench, `fountain` small stone fountain, `crate` fish crate.
  - *Piso:* `bedT`/`bedB` bed in 2 tiles, `pc` desk with old monitor, `lab`/`lab2` genetics table with microscope and flasks, `table` small wooden table, `fridge`, `plantDeco` potted monstera, `iwin` wall window, `poster` framed leaf poster.
  - *Growshop:* `shelfW` wall shelf with jars, `counter` shop counter, `display` seed packet rack.
  - *Bar:* `barcounter` dark bar counter, `bottles` bottle shelf, `stool` red bar stool, `btable` round bar table, `jukebox` retro jukebox.

## Grupo 4 · Combate (opcional)

- **Enemigos de frente**, 64 × 80: ladrón con capucha y agente, en pose de combate. Mismo prompt que el Grupo 1 pero con un solo fotograma, «front-facing battle pose».
- **Jugador de espaldas**, 64 × 80: «back view, battle stance».
- Los fondos de combate (calle de noche y de día) se dibujan por código. Se pueden dejar así.

## Cómo meterlos en el juego

1. Guarda los PNG reducidos en `assets/sprites/`: un PNG por clave de `TILES`, `char_<id>.png` por personaje y `plant_<id>.png` por variedad.
2. Amplía `tools/build.js` para incrustarlos como `data:` URI en un objeto `SPRITES` dentro del HTML, de modo que el juego siga siendo un único archivo.
3. En `buildTiles()`, si existe `SPRITES[clave]`, usa esa imagen en lugar de la función procedural. En `spriteFor(look, dir, frame)` y `plantSprite(p)`, recorta la celda de la hoja. La derecha sigue siendo el espejo de la izquierda.
4. No cambies los tamaños ni los desplazamientos de dibujo (−4 px los personajes y −10 px las plantas). Así no hay que tocar colisiones ni mapas.
5. `npm run build`, `npm test` y `npm run capturas` para comprobar el resultado.
