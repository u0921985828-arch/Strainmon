# 🧩 Strainmon — Kits de piezas con Pixel Lab

Sistema para exprimir la API de **Pixel Lab** generando **sets de piezas
intercambiables** en vez de sprites sueltos: cuerpos, cabezas, caras, pelos,
gorros, carrocerías, ruedas, piezas de calzada, módulos de edificio… y luego
**componerlos** para sacar infinitas variantes sin volver a llamar a la API.

Un personaje no se genera: se **monta**. 8 cuerpos × 4 cabezas × 5 caras ×
6 pelos × 5 gorros × 5 objetos, con tintes de piel/ropa/pelo, dan más de
**145 000 combinaciones por dirección** con solo 130 imágenes generadas.

---

## 1. Cadena de montaje

```
prompts/kits/<kit>.json        catálogo declarativo de ranuras y piezas
        │  gen-kit.mjs         → llama a la API pieza a pieza
assets/gen_kits/<kit>/         PNGs sueltos + manifest.json
        │  pack-kit.mjs        → recorta, limpia motas y empaqueta
        ├─ atlas.png/.json     lámina + rectángulos
        ├─ atlas.js            lo mismo inline (funciona desde file://)
        └─ preview_<ranura>.png hojas de contacto para revisar a ojo
        │  kit-export.mjs      → hornea recetas concretas
        └─ out/<nombre>_<1..4>.png + módulo inline tipo src/charart.js
```

En el navegador, `src/kitgen.js` (`PH.kitgen`) compone recetas en vivo y
`tools/kit-lab.html` es el laboratorio visual para trastear y exportar.

## 2. Puesta en marcha

```bash
echo "TU_KEY" > .secrets/pixellab.key     # nunca se commitea (.gitignore)
node scripts/pixellab.mjs balance         # comprueba key y saldo

node scripts/gen-kit.mjs character --dry  # plan + nº de llamadas, sin gastar
node scripts/gen-kit.mjs character --only head,hair --limit 12
node scripts/pack-kit.mjs character
open tools/kit-lab.html                   # componer, aleatorizar, exportar
node scripts/kit-export.mjs character --random 6 --module charart.gen.js
```

### Sin key ni créditos (pruebas)

```bash
node scripts/kit-mock-server.mjs 8787 &
PIXELLAB_BASE_URL=http://127.0.0.1:8787/v1 PIXELLAB_API_KEY=test \
  node scripts/gen-kit.mjs character --yes
```

El simulador devuelve formas planas de colores: sirve para validar anclajes,
apilado y composición, no para ver arte.

## 3. Kits incluidos

| Kit | Ranuras | Piezas | Llamadas | Para qué |
|---|---|---|---|---|
| `character` | espalda, cuerpo, cabeza, cara, pelo, gorro, en mano | 35 | 131 | Jugador y NPCs |
| `road` | pieza, detalle | 20 | 21 | Calles, aceras, caminos |
| `building` | planta baja, piso (repetible), remate, añadido | 23 | 47 | Edificios de altura variable |
| `vehicle` | ruedas, carrocería, techo, frontal, trasera | 24 | 97 | Coches, furgonetas, camiones |
| `props` | objeto, encima | 21 | 43 | Mobiliario urbano |

Los prompts van **en inglés** (el modelo responde bastante mejor); títulos y
documentación, en español.

## 4. Anatomía de un kit

```jsonc
{
  "extends": "_common.json",          // estilo y ajustes compartidos
  "id": "character",
  "canvas": { "width": 64, "height": 96 },   // lienzo de composición
  "directions": ["south-east", "south-west", "north-west", "north-east"],
  "api": { "engine": "bitforge", "size": { "width": 48, "height": 64 },
           "view": "high top-down", "isometric": true, "styleStrength": 55 },
  "style": "prefijo de dirección de arte que va en todos los prompts",
  "styleAnchor": { "prompt": "pieza patrón que fija el estilo del kit" },
  "tints": { "cloth": [{ "id": "azul", "h": 95, "s": 1, "l": 1 }] },
  "slots": [{
    "id": "head", "z": 30,
    "place": [32, 38],                // punto del lienzo donde cae el ancla
    "anchor": "bottom-center",        // qué punto de la pieza es el ancla
    "size": { "width": 32, "height": 32 },
    "tint": "skin",                   // grupo de recoloreado
    "optional": false,                // si es opcional, puede quedar vacía
    "dirs": ["south-east"],           // limitar a ciertas direcciones (caras)
    "repeat": { "min": 0, "max": 4, "stepY": -52 },  // apilable (pisos)
    "stackAfter": "floor",            // se coloca encima de lo apilado
    "prompt": "plantilla con {v}",
    "parts": [{ "id": "round", "title": "Redonda", "prompt": "…" }]
  }]
}
```

**Anclaje:** cada pieza se recorta a su contenido y se coloca por su ancla, no
por el lienzo con el que se generó. Así da igual que el modelo centre el objeto
de forma distinta en cada imagen. Para retoques finos, crea
`assets/gen_kits/<kit>/anchors.json`:

```json
{ "head": { "place": [32, 40], "parts": { "round": { "nudge": [0, -1] } } } }
```

**Tintes:** el recoloreado es un desplazamiento HSL **píxel a píxel** (no un
filtro), así que el pixel art no se difumina ni pierde el contorno.

## 5. Coste y control de gasto

- `--dry` imprime el plan y el número de llamadas sin tocar la red.
- Más de 40 llamadas de golpe exige `--yes` (o `--limit N`).
- Cada respuesta se cachea en `.cache/pixellab/` por hash del cuerpo: repetir
  una tanda no vuelve a pagar. `--force` la ignora.
- `--dirs rotate` genera solo la dirección base y saca las demás con `/rotate`:
  más barato y mucho más coherente entre vistas.
- El gasto real de cada pieza queda anotado en `manifest.json`.

## 6. La API (v1) que usamos

Base `https://api.pixellab.ai/v1`, cabecera `Authorization: Bearer <key>`.

| Endpoint | Uso aquí |
|---|---|
| `POST /generate-image-pixflux` | pieza patrón de estilo (solo texto) |
| `POST /generate-image-bitforge` | resto de piezas, con `style_image` = patrón |
| `POST /rotate` | otras direcciones a partir de la vista base |
| `POST /inpaint` | variantes de una pieza ya generada |
| `GET /balance` | saldo |

Límite del modelo: el lienzo de **cada pieza** no puede superar un área de
400×400 px (el lienzo de composición sí puede ser mayor). La `description`
está limitada a 1000 caracteres; `kit-lib.mjs` recorta por palabra si hace falta.

## 7. Propiedad intelectual

Todo lo generado aquí es **original**. Los prompts describen formas genéricas
y prohíben explícitamente texto, logotipos y marcas. No se usan ni imitan
assets con copyright de terceros. Identidad propia: **STRAINBOY**.
