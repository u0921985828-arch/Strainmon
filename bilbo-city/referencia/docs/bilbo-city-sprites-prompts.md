# BILBO CITY — Pack de prompts para sprites pixel art

Sustituye los sprites generados por código (`spriteChar`, `spriteCoche`, `tAsfalto`…) por arte real
manteniendo exactamente la misma rejilla, así el intercambio es un `drawImage` distinto y nada más.

---

## 0. Contrato técnico (no negociable)

| Elemento | Tamaño nativo | Tamaño en juego | Notas |
|---|---|---|---|
| Tile de suelo | 64×64 | 32×32 | Tileable en los 4 lados |
| Tile de tejado | 64×64 | 32×32 | Tileable, sin sombra proyectada |
| Personaje (frame) | 64×80 | 16×20 | Pies en el píxel inferior centro |
| Coche | 144×80 | 36×20 | Morro apuntando a la **derecha** (0 rad) |
| Prop (farola/árbol/contenedor) | 64×64 | variable | Base anclada abajo-centro |

Todo se genera a resolución nativa y se reduce con **nearest-neighbor** (`image-rendering: pixelated`).

---

## 1. MASTER STYLE PROMPT (pegar al inicio de TODOS los prompts)

```
Top-down orthographic pixel art sprite, hard-edge pixels, absolutely no anti-aliasing,
no gradients, no outlines softer than 1px. Exactly 3-tone cel shading per material
(base / shadow / highlight), light source from the upper-left at 45 degrees.
Transparent background (alpha), no drop shadow baked in, no ground plane, no border,
no text, no watermark. Sprite centered with 2px of empty margin.
Rendered at 64x64 native pixel resolution for nearest-neighbor downscale.
Muted industrial northern-Spain palette, overcast daylight, slightly desaturated.
```

## 2. PALETA BLOQUEADA (repetir literalmente en cada prompt individual)

```
Strict palette, use ONLY these hex values:
#0b0e12 #1c2229 #33383e #4a444c #655f55 #7b7669 #8d99a4 #e6e2d6
#6b5d52 #5c5a63 #7a5f52 #566060 #6e6656
#3c6338 #1c4652 #2a6473
#b7451f #e8c547 #4f9d69 #9d5fa8 #4d9de0
#e0b48c #c69068 #8d6142 #2a2018
```

---

## 3. GRUPO A — Personajes (ciclos de andar)

Un sheet por personaje. **4 direcciones × 3 fotogramas** (idle, paso izq, paso der),
dispuestos en rejilla 3 columnas × 4 filas, orden de filas: abajo, arriba, izquierda, derecha.

### A1 · Protagonista (con txapela)
```
[MASTER] [PALETA]
Character walk-cycle sprite sheet, 3 columns x 4 rows grid, each cell 64x80 pixels,
cells separated by transparent gutters. Row order: facing down, facing up,
facing left, facing right. Column order: idle stance, left foot forward, right foot forward.
Subject: a working-class man in his thirties, black wool txapela (Basque beret),
navy blue work jacket #1f3a5f, dark trousers, worn boots. Sturdy build, plain face,
no accessories. Consistent silhouette across every cell, head at identical height in all frames.
```

### A2–A6 · Peatones (5 variantes)
Mismo prompt que A1 cambiando solo el bloque `Subject:`, y **sin txapela**:

| # | Subject: |
|---|---|
| A2 | an older woman in a maroon raincoat #7a3030, grey bun, canvas shopping bag |
| A3 | a young woman in a green windbreaker #3d6b4a, light brown ponytail, backpack |
| A4 | a man in a purple hoodie #5b4a76, dark skin, short black hair, hands in pockets |
| A5 | a dockworker in an orange hi-vis vest #b7451f, hard hat, heavy boots |
| A6 | a teenager in a teal tracksuit #2f6a72, cap worn backwards, thin build |

### A7 · NPCs de interior (frame único, mirando abajo)
Un solo cell 64×80, `facing down, idle stance`:
- **Josu, barman**: white shirt, rolled sleeves, dark apron, moustache, towel over shoulder
- **Mikel, parroquiano**: brown corduroy jacket, red scarf, flat cap, holding a small wine glass
- **Iker, mecánico**: navy overalls, oil-stained, short beard, wrench in hand
- **Bego, pescatera**: white coat, rubber apron, hair tied back, blue gloves
- **Amaia, casera**: grey cardigan, glasses on a chain, folder under one arm

---

## 4. GRUPO B — Vehículos (vista cenital, morro a la derecha)

```
[MASTER] [PALETA]
Top-down orthographic car sprite, 144x80 native pixels, viewed from directly above at 90 degrees.
The vehicle points to the RIGHT of the image (front bumper at the right edge).
Visible from above: roof, windshield, rear window, both side mirrors, four wheels,
headlights at the front, tail lights at the rear. No perspective, no tilt, no reflections.
Vehicle: {DESCRIPCIÓN}
```

| Archivo | {DESCRIPCIÓN} |
|---|---|
| `car_hatch_red.png` | small 1990s European hatchback, faded red #c23b22, slightly dented |
| `car_sedan_blue.png` | boxy compact sedan, steel blue #3f6f8f |
| `car_sedan_white.png` | white compact sedan #c9c9c9, taxi roof sign, checkered side stripe |
| `car_wagon_green.png` | small estate wagon, dark green #3f8f6f, roof rack |
| `van_white.png` | short-wheelbase panel van, off-white #d8d4c4, no windows in the cargo area |
| `car_sport_yellow.png` | low wide sports coupé, yellow #e8c547, black bonnet stripe |
| `car_police.png` | white and blue Basque police patrol car, roof lightbar with a red pod and a blue pod, blue chequered side stripe |

Para la luz de la policía: genera **dos** variantes idénticas cambiando solo el lightbar
(izquierda azul encendida / derecha roja encendida) y alterna a 6 fps.

---

## 5. GRUPO C — Tiles de entorno (tileables)

```
[MASTER] [PALETA]
Seamless tileable top-down texture tile, exactly 64x64 native pixels.
The tile must repeat perfectly on all four edges with no visible seam.
No objects that break the tiling, no centered focal element, even value distribution.
Texture: {DESCRIPCIÓN}
```

| Archivo | {DESCRIPCIÓN} |
|---|---|
| `t_asphalt.png` | worn dark asphalt road surface with fine gravel speckle, small cracks |
| `t_sidewalk.png` | grey-beige concrete paving slabs in a regular grid, chipped corners |
| `t_grass.png` | short municipal park grass with scattered darker tufts |
| `t_water_1.png` | dark green-blue estuary water, calm horizontal ripple bands |
| `t_water_2.png` | same estuary water, ripple bands offset half a tile vertically |
| `t_bridge.png` | grey concrete bridge deck with expansion joints and a metal kerb strip |
| `t_roof_a.png` | brown clay roof tiles seen from above, regular rows |
| `t_roof_b.png` | flat grey gravel roof with a service hatch pattern |
| `t_roof_c.png` | brick red roof tiles, older and more irregular |
| `t_roof_d.png` | flat green-grey industrial roof with metal seams |
| `t_roof_e.png` | flat sandy roof with skylights and a small AC unit |
| `t_floor_wood.png` | worn dark wooden tavern floorboards, horizontal planks |
| `t_floor_tile.png` | old apartment floor, small beige ceramic tiles |
| `t_wall_brick.png` | interior wall seen from above as a solid brick block, top face lit |

---

## 6. GRUPO D — Props y mobiliario (frame único, base abajo-centro)

```
[MASTER] [PALETA]
Single top-down object sprite on transparent background, 64x64 native pixels.
Object seen from directly above, base anchored at the bottom-center of the frame.
Object: {DESCRIPCIÓN}
```

**Calle:** farola municipal de brazo curvo · contenedor de basura verde con tapa ·
árbol de copa redonda · banco de madera · buzón · bolardo de hormigón ·
señal de stop vista desde arriba · alcantarilla.

**Bar:** barra de madera oscura (tile 64×64, tileable en horizontal) ·
mesa redonda con dos vasos y un plato de pintxos · taburete · máquina de café.

**Piso:** cama individual con edredón azul · armario de madera · mesa con mantel ·
televisión pequeña.

**Taller:** coche elevado sobre plataforma · carro de herramientas rojo ·
neumáticos apilados · bidón de aceite.

**Mercado:** mostrador de pescado con hielo y pescado azul · caja de plástico apilable ·
báscula colgante · toldo a rayas rojas y blancas.

---

## 7. Integración en el código

1. Guarda cada PNG y sustituye la función generadora por una carga:

```js
const SPR = {};
function cargar(nombre, ruta){
  return new Promise(r=>{ const i=new Image(); i.onload=()=>{SPR[nombre]=i;r();}; i.src=ruta; });
}
await Promise.all([
  cargar('player_sheet','art/player.png'),
  cargar('t_asphalt','art/t_asphalt.png'),
  // …
]);
```

2. Para los sheets de personaje, recorta con `drawImage` de 9 argumentos:

```js
// celda (col=frame, fila=dir) de 16x20 en el sheet ya reducido
ctx.drawImage(SPR.player_sheet, fr*16, dir*20, 16, 20, x-8, y-14, 16, 20);
```

3. Mantén `ctx.imageSmoothingEnabled = false` y `image-rendering: pixelated`.

4. Si el modelo devuelve el arte con anti-alias, pásalo por este cuantizador antes de usarlo:
   reducir a la paleta bloqueada por distancia euclídea en RGB y forzar alpha binario (0 o 255).

---

## 8. Control de calidad antes de meter un sprite

- [ ] ¿Fondo realmente transparente, sin halo gris en los bordes?
- [ ] ¿Todos los colores están en la paleta bloqueada?
- [ ] ¿La cabeza queda a la misma altura en los 12 frames del personaje?
- [ ] ¿El tile repite sin costura al ponerlo 3×3?
- [ ] ¿El coche apunta a la derecha?
- [ ] Al reducir a tamaño de juego, ¿sigue leyéndose la silueta?
