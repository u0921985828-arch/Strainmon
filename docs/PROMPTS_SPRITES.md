# 🎨 Strainmon — Kit de prompts para sprites

Guía para generar sprites coherentes que encajen en el motor **sin retoques**.
Copia el **BLOQUE DE ESTILO** al principio de cada prompt y añade el bloque concreto del asset.

## Reglas técnicas (obligatorias para que entren en el juego)

- **Fondo transparente** (PNG con alfa). Nada de fondo de cuadrícula ni blanco.
- **Sin antialias / sin desenfoque**: píxeles duros, bordes nítidos (pixel-perfect).
- **Tamaño exacto** por tipo de asset (abajo). Encuadrado y centrado.
- **Paleta limitada** 16-bit tipo GBA (cálida, saturación media, sombras suaves).
- **Contorno oscuro** de 1px en personajes y criaturas (color casi negro violáceo `#20161f`).
- **Luz cenital** (desde arriba); sombra elíptica sutil bajo el objeto.
- Estilo **original**, inspirado en RPG de Game Boy Advance. **No** imitar ninguna franquicia ni personaje existente.

### BLOQUE DE ESTILO (pégalo siempre primero)

```
Pixel art 16-bit estilo Game Boy Advance, original. Fondo transparente,
sin antialias, píxeles nítidos, contorno oscuro de 1px (#20161f),
sombreado suave con luz cenital, paleta cálida limitada. Vista cenital
ligera (top-down). Sprite único centrado. Sin texto, sin marca de agua,
sin fondo de cuadrícula.
```

---

## 1) Criaturas-cepa "Strainmon" — **48×48 px**

Cada cepa landrace es una **criatura-planta en maceta de terracota** con carácter
(cara amable: dos ojos, sonrisa; brazos-hoja). El **cogollo/cabeza** lleva el color
del fenotipo; el cuerpo es verde planta. Plantilla parametrizable:

```
[BLOQUE DE ESTILO]
Criatura-planta de cannabis en maceta de terracota, 48x48. Cuerpo verde
regordete con dos brazos hechos de hojas de abanico, cara simpática (ojos
grandes con brillo, sonrisa, mejillas). Cabeza en forma de cogollo/flor de
color {COLOR}. Hojas de tipo {HOJA}. Personalidad {RASGO}. Región de origen
{REGION}. Escarchada de tricomas si es resinosa. Pose frontal, idle.
```

Rellena por cepa (ejemplos del juego):

| Cepa | {COLOR} | {HOJA} | {RASGO} | {REGION} |
|---|---|---|---|---|
| Kush Ancestral | verde-púrpura | ancha (índica) | robusta, serena | Hindú Kush nevado |
| Afgana Púrpura | púrpura intenso | ancha | soñolienta | valles de Afganistán |
| Oro de Acapulco | ámbar dorado | digitada (sativa) | alegre, soleada | costa tropical |
| Malawi Dorada | oro/lima | digitada larga | enérgica | sabana africana |
| Tailandesa | verde lima | muy estrecha | espigada, curiosa | selva húmeda |
| Charas de Chitral | verde/ámbar | ancha | pegajosa (resina) | cuevas de montaña |
| Rifeña Kif | verde seco | media serrada | rústica | montañas áridas del Rif |
| Rojo de Panamá | carmesí/púrpura | digitada | tropical, vivaz | istmo selvático |
| Jamaicana Costera | lima/turquesa | palmada | relajada, playera | costa caribeña |
| Nepalí de Montaña | púrpura | ancha | mística (incienso) | Himalaya |
| Cepa Primigenia (mítica) | oro + obsidiana | digitada | ancestral, aura sagrada | origen desconocido |

> Consejo: genera una **base neutra verde** y luego pide **recolores** del cogollo
> (verde, lima, ámbar, oro, púrpura, violeta, carmesí, azur, turquesa, magenta,
> obsidiana negro, blanco albino) para cubrir todos los fenotipos con una sola forma.

**Variantes de mutación** (opcionales, mismas 48×48):
- Gigantismo: más grande, con “cuernos” de hoja. · Enanismo: mini y compacta.
- Variegación: parches crema sin clorofila. · Cristalina: cubierta de escarcha blanca.
- Bioluminiscente: aura brillante suave. · Quimera: cabeza partida en dos colores.

**Nombres de archivo sugeridos:** `strain_<id>.png` (p. ej. `strain_SM-015.png`) o
`strain_base.png` + `bud_<color>.png` si haces recolores.

---

## 2) Fases de cultivo (invernadero) — **48×48 px**

Secuencia de una misma planta en maceta de terracota, 5 fases de izquierda a derecha
(pueden ser 5 archivos sueltos):

```
[BLOQUE DE ESTILO]
Planta de cannabis en maceta de terracota, 48x48, fase {FASE}:
1) Plántula: brote diminuto con dos cotiledones.
2) Vegetativo temprano: joven, pocas hojas de abanico.
3) Vegetativo tardío: grande, densa, verde oscuro.
4) Floración: cogollos con pistilos {COLOR} formándose.
5) Cosecha: cogollos gruesos y escarchados de tricomas blancos.
```

**Archivos:** `grow_1.png` … `grow_5.png` (reemplazan a `assets/sprites/plant_*.png`).

---

## 3) Personaje jugador — **16×16 px** (hoja de 4 direcciones × 3 fotogramas)

```
[BLOQUE DE ESTILO]
Personaje humano estilo cazador-botánico, 16x16 por fotograma. Gorra verde,
mochila, ropa de explorador. Hoja de sprites: filas = direcciones
(abajo, arriba, izquierda, derecha); columnas = 3 fotogramas de caminado
(quieto, paso izq, paso der). Proporción chibi (cabeza grande). Contorno 1px.
```

**Archivo:** `player.png` (rejilla 3×4, 48×64 px total) o 12 sprites `player_<dir>_<n>.png`.

---

## 4) NPCs — **16×16 px** (mínimo dirección "abajo"; ideal 4 direcciones)

Genera 6 con la misma plantilla del jugador, cambiando aspecto:

- `npc_mentora.png` — científica mayor, bata blanca, pelo canoso.
- `npc_coleccionista.png` — comerciante con lupa y ropa vistosa.
- `npc_criador.png` — cultivador con delantal y hoja en la oreja.
- `npc_genetista.png` — con gafas y tablet de ADN.
- `npc_nomada.png` — viajera del desierto con turbante.
- `npc_marinera.png` — pescadora costera con gorro.

---

## 5) Tiles de terreno — **16×16 px, tileables (bordes que casan)**

Cada bioma comparte estructura; pide el set por región. Base:

```
[BLOQUE DE ESTILO]
Tile de terreno 16x16, tileable sin costuras (los bordes deben repetir).
Vista cenital. Tipo: {TIPO}. Bioma: {BIOMA}. Variación sutil, sin elementos
que rompan el patrón al repetir.
```

**{TIPO} necesarios:** hierba, hierba_alta (más frondosa), camino, árbol, roca,
agua (+ variante orilla/espuma), arena, barro, nieve, hielo, lava, ceniza,
suelo_cueva, estalagmita, palmera, arbusto, flores, puente.

**{BIOMA}:** altiplano (pradera), selva (bosque), pantano (delta), desierto (rif),
nieve (kush), volcán (oaxaca), cueva (chitral), isla (jamaica), ciudad.

**Archivos:** `tile_<bioma>_<tipo>.png` (p. ej. `tile_nieve_arbol.png`).

---

## 6) Edificios y props de ciudad — **32×32 o 48×48 px**

`build_lab.png` (laboratorio/invernadero de cristal), `build_market.png` (mercado con toldo),
`build_house.png` (casa acogedora), `door.png` (16×16).

---

## 7) Iconos de objetos (mochila/mercado) — **16×16 px**, vista frontal

`item_frasco.png`, `item_tijeras.png`, `item_kitclon.png`, `item_dron.png`,
`item_lupa.png`, `item_medidor.png`, `item_semilla.png`, `item_clon.png`, `item_polen.png`.

---

## Cómo entregarlos

Súbelos (zip) manteniendo los **nombres sugeridos** y el **tamaño exacto**. Yo me
encargo de: recortar si hiciste hojas de sprites, generar el módulo inline en base64
y sustituir el arte procedural por tus sprites en render, encuentros, Strain-dex,
laboratorio e invernadero.

> Prioridad recomendada para máximo impacto visual: **(1) criaturas-cepa → (3) jugador →
> (5) tiles por bioma → (2) fases de cultivo → resto.**
