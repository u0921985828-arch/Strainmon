# 🎮 Strainmon — Lógica del juego y manifiesto de sprites

Documento que fija **qué hace el juego** (sistemas y estados) y, de ahí, **qué
sprites hacen falta** para producirlos. Todo original (sin Habbo/Sulake).

## 1. Concepto

Sandbox isométrico single-player (todo NPC), rollo GTA-lite + cultivo. Eres un
**pheno hunter / grower-dealer**: recorres la ciudad, consigues genéticas
(cepas landrace), las cultivas en tu grow-room por fases, las cruzas para crear
fenotipos nuevos, y las vendes a clientes/NPCs. Progresas por **prestigio**
(catálogo/Strain-dex) y **dinero** (economía dealer).

## 2. Bucle central

Explorar (ciudad iso) → conseguir cepa (parterres silvestres / mercado / NPCs)
→ cultivar (grow-room, 5 fases) → cosechar (propaga clones) → cruzar (lab,
genética) → **vender** (mercado o trato callejero con clientes) → prestigio +
dinero → desbloquear salas/equipo/regiones.

## 3. Sistemas (estado actual)

| Sistema | Estado | Nota |
|---|---|---|
| Motor isométrico (proyección, profundidad) | ✅ | `iso.js` |
| Movimiento + cámara + colisión (lista blanca) | ✅ | `isogame.js` |
| Salas + puertas/warps (apt, calle, mercado, lab) | ✅ | |
| **IA de NPCs** (roles, deambular con colisión, estados idle/walk) | ✅ | `updateNPCs` |
| **Economía dealer** (trato callejero: cliente compra cepa) | ✅ (base) | `dealWith` |
| Genética / cepas / cruces / Strain-dex | ✅ | reutilizado |
| Cultivo por fases (5) con maceta constante | ✅ | `garden.js` + arte real |
| Ciclo día/noche, estaciones, clima, eventos raros | ✅ | |
| Guardado localStorage | ✅ | |
| NPC rutinas por horario, reputación/heat | 🔜 | fase 2 |
| Salas decorables (colocar muebles/macetas) | 🔜 | |
| Ciudad grande + más edificios | 🔜 | |

## 4. Roles de NPC (definen sprites de personaje)

| Rol | Comportamiento | Interacción |
|---|---|---|
| `player` | control directo | — |
| `dealer` | fijo cerca de su sitio | diálogo (mercado negro) |
| `neighbor` | deambula poco | diálogo/lore |
| `customer` | pasea | **compra** una cepa de tu banco (premium) |
| `walker` | pasea (peatón) | flavor |
| `merchant` | fijo (mercado) | tienda |
| `botanist` | fijo (lab) | investigación/cruces |
| `cop` 🔜 | patrulla | sube "heat" si trapicheas cerca |

**Estados de animación por personaje:** `idle` + `walk` (2 fotogramas), en **4
direcciones** isométricas (NE, NW, SE, SW). Opcional: `deal`/`talk` (1 pose).

## 5. MANIFIESTO DE SPRITES (derivado de la lógica)

Convención: fondo magenta `#FF00FF` (chroma en post), pixel-art, contorno 1px
`#20161f`, luz cenital. Se generan en lámina y se recortan (pipeline existente).

### 5.1 Personajes — iso, ~28×40 px, 4 dir × 3 frames (idle, pasoA, pasoB)
Lámina por personaje: 4 filas (SE, SW, NW, NE) × 3 columnas.
Archivos: `char_<rol>_<dir>_<frame>.png` o lámina `charsheet_<rol>.png`.
- `player` (grower con gorra/mochila)
- `dealer`, `neighbor`, `merchant`, `botanist`
- `customer` ×3 variantes de aspecto
- `walker` ×2 variantes
- `cop` 🔜

### 5.2 Mobiliario iso (objeto sobre 1 tile, base anclada abajo)
~48×56 px, transparente. Archivos: `furni_<nombre>.png`.
- `grow_bench` (mesa de cultivo), `pot_empty`, `pot_plant` (billboard de fase — ya lo cubren las 90 fases)
- `pc_desk`, `bed`, `lab_table`, `shop_counter`
- `lamp`, `bench`, `trash`, `sign`, `plant_decor`, `rug`

### 5.3 Tiles iso (rombo 64×32) por tema
Archivos: `tile_<tema>_<tipo>.png`.
- Temas: `room` (parquet/baldosa), `street` (asfalto/acera), `grass` (parterre)
- Tipos: `floor`, `floor_alt`, `edge`, `flowerbed`, `road`, `crosswalk`

### 5.4 Estructura iso
`wall_<tema>` (cubo pared), `facade_<tipo>` (fachada de edificio), `door_<tema>`,
`window`, `roof`.

### 5.5 UI / iconos (16×16) — ya existen los base
`icon_seed`, `icon_clone`, `icon_scissors`, `icon_credits`, `icon_prestige`…

## 6. Prioridad de producción

1. **`player` + `customer`/`walker`** (4 dir): lo que más se ve moviéndose.
2. `dealer/neighbor/merchant/botanist`.
3. Mobiliario iso principal (`grow_bench`, `pc_desk`, `bed`, `lab_table`, `shop_counter`, `lamp`).
4. Tiles iso por tema (room/street/grass) para sustituir los rombos planos.
5. Fachadas/paredes iso.

## 7. Integración

- Los personajes se dibujan en la **capa de actores** (billboard anclado a la
  base del tile) con selección de fila por `dir` y columna por `frame` (idle/walk).
- El mobiliario reemplaza los cubos de color actuales (`drawObject`).
- Los tiles reemplazan `floorDiamond`/`cube` procedurales.
- Pipeline de generación: `scripts/gen-sprites.mjs` (Gemini) → `post-sprites.mjs`
  (chroma/recorte) → módulo inline base64 → cableado.
