# Strainmon (PHENO HUNTER) — CLAUDE.md

## MODO ABSOLUTO (directiva de trabajo por defecto)

Cuando el usuario escriba `[MODO:Absoluto]` (o pida "modo absoluto"):

Rol: Ejecutor final.

Reglas:
1. Cero charla / saludos / confirmaciones.
2. Salida = SOLO producto final 100% terminado.
3. PROHIBIDO emitir mensajes intermedios.
4. Excepción: bloqueo crítico → preguntar máx. 1 línea.
5. Estilo: frases ultracortas, máxima densidad técnica.

Variante `[MODO:Ejecutor_Absoluto]` (auditoría/refactor): mismas reglas + salida =
informe técnico directo + código refactorizado, sin relleno.

## Restricciones de propiedad intelectual (siempre)

- Prohibido usar assets/código de terceros con copyright: sprites de Pokémon,
  código de Habbo/Sulake, descompilaciones (p.ej. `pret/pokefirered`), wordmark
  "Nintendo/GAME BOY" ni el lema comercial. Modificar material con copyright =
  obra derivada = sigue infringiendo.
- Permitido: homenaje de forma/layout genérico + arte y código 100% originales.
  Identidad propia: **STRAINBOY** (verde), textos propios.

## Qué es el proyecto

Strainmon (nombre de código interno del pivote actual: **PHENO HUNTER**) es un
sandbox isométrico single-player de cultivo/cruce/trapicheo de genéticas
landrace de cannabis — parodia de coleccionismo estilo Pokémon pero **sin
combates**. Vanilla JS puro, namespace global `PH`, **sin dependencias en
runtime** (todo el arte de plantas se genera/compone por código o se sirve
inline en base64; no hay bundler, `index.html` se abre directo en el navegador).

- Consola: chasis homenaje a una portátil retro con LCD 10:9 (matriz interna
  160×144, píxeles cuadrados), modo DMG de 4 tonos. Ver `assets/style.css` +
  el `<div id="device">` en `index.html`.
- `sharp` en `package.json` es una dependencia **solo de las herramientas
  offline** en `scripts/` (pipeline de generación/postproceso de sprites), no
  la usa el juego en el navegador.

## ⚠️ Estado actual: motor en migración (top-down → isométrico)

El repo contiene **dos motores de juego coexistiendo**, ambos cargados por
`index.html` y ambos registran su propio `DOMContentLoaded`:

| Motor | Archivos clave | Estado según docs |
|---|---|---|
| **Top-down original** (Strainmon clásico: biomas, GBA-like) | `game.js`, `world.js`, `render.js` | Legado; lógica de genética/inventario que reutiliza el pivote |
| **Isométrico** (pivote PHENO HUNTER: ciudad GTA-lite, grow-room, trato callejero) | `iso.js`, `isogame.js` | Activo / en desarrollo — es el que describen `docs/GDD.md` y `docs/GAME_LOGIC.md` |

Antes de tocar el bucle de juego, la cámara, el input o el render de mundo,
confirma **cuál de los dos motores es el objetivo del cambio** — es fácil
editar el archivo equivocado. `docs/GAME_LOGIC.md` trae una tabla de estado
por sistema (`✅`/pendiente) del pivote isométrico.

## Arquitectura de código

Todos los módulos siguen el mismo patrón IIFE que cuelga de `window.PH`:

```js
(function (PH) {
  'use strict';
  const { RNG, clamp, hslToHex, cap } = PH.util; // ejemplo de import interno
  // ...
  PH.miModulo = { ...exports };
})(window.PH = window.PH || {});
```

Orden de carga en `index.html` (importa: los módulos posteriores asumen que
los anteriores ya registraron su parte de `PH`):

```
util → genetics → species → items → world → render → sprites → plantart →
state → quests → events → research → garden → encounter → ui → charart →
furniart → audio → heat → iso → isogame
```

| Archivo | Responsabilidad |
|---|---|
| `src/util.js` | RNG con semilla (mulberry32), matemáticas, helpers de color |
| `src/genetics.js` | **Motor genético** (el corazón): genotipo diploide, dominancia/codominancia, poligenes cuantitativos, poliploidía, mutaciones raras, cruce (`breed`), firma fenotípica, secuencia de ADN, parentesco |
| `src/species.js` | Especies base, perfiles y tablas de aparición por bioma/ambiente |
| `src/items.js` | Herramientas de recolección y equipo |
| `src/world.js` | Mapas por tiles, colisiones, warps, NPCs (motor top-down) |
| `src/render.js` | Render pixel-art top-down: tiles, personajes, sprites de planta |
| `src/sprites.js` | Sprites de cultivo (48×48) inline en base64 y ciclo de vida |
| `src/plantart.js` | Arte de planta generado por código a partir de la genética (archivo grande, ~620 KB) |
| `src/state.js` | Estado global, banco genético, catálogo mundial, ambiente, guardado (`localStorage`, clave `phenohunter_save_v1`) |
| `src/quests.js` | Misiones y diálogos |
| `src/events.js` | Eventos raros temporizados |
| `src/research.js` | Secuenciación de ADN, parentesco, linaje (Strain-dex) |
| `src/garden.js` | Invernadero: plantado, crecimiento por fases (plántula→vegetativo→floración→cosecha), propagación de clones |
| `src/encounter.js` | Resolución de recolección en el mundo |
| `src/ui.js` | HUD y paneles superpuestos (mochila, banco, catálogo, misiones…) |
| `src/charart.js` | Arte de personajes |
| `src/furniart.js` | Arte de mobiliario/decoración |
| `src/audio.js` | Motor de audio (SFX/música) |
| `src/heat.js` | Sistema de "calor"/riesgo (mecánica dealer) |
| `src/iso.js` | Motor isométrico base: proyección, orden de profundidad |
| `src/isogame.js` | Bucle del sandbox isométrico: movimiento, cámara, colisión, salas/warps, IA de NPCs, economía dealer (`updateNPCs`, `dealWith`) — **es el motor activo del pivote** |

El motor genético (`genetics.js`) es compartido/reutilizado por ambos motores
de juego — no dupliques esa lógica al trabajar en `isogame.js`.

## Estructura del repo

```
index.html          entrada única, carga todos los <script> de src/ en orden
src/*.js             módulos del juego (ver tabla arriba)
assets/style.css     todo el CSS (consola, LCD, HUD, paneles) — un solo archivo
assets/{chars,furni,parts,plants,ref,sprites}/  arte fuente (PNG) usado por el pipeline offline
docs/                documentación de diseño (ver abajo)
scripts/*.mjs        pipeline offline de generación/postproceso de sprites (Node + sharp)
prompts/*.json       prompts estructurados para generación de sprites (consumidos por scripts/)
dist/PhenoHunter.html  build bundleado autocontenido (generado, no editar a mano)
package.json         solo declara `sharp` para scripts/; el juego no tiene build step
```

### `docs/` — documentación de diseño (leer antes de cambios de sistemas/arte)

- `docs/GDD.md` — GDD maestro del pivote PHENO HUNTER (pitch, core loop, stack, colisiones). Documento canónico, supersede notas previas.
- `docs/GAME_LOGIC.md` — Lógica de sistemas y estado de implementación (tabla ✅/pendiente) del pivote isométrico.
- `docs/DESIGN_CANON.md` — Canon de diseño de arte **cerrado**: resolución del motor (32 px/tile, 480×320 interno), tamaños de sprite por categoría, encuadre, paleta. Todo sprite nuevo debe cumplirlo.
- `docs/PROMPT_MAESTRO.md` / `docs/PROMPTS_SPRITES.md` — prompts maestros y por-sprite para el pipeline de generación de arte.

### `scripts/` — pipeline offline de arte (Node, no corre en el juego)

- `gen-sprites.mjs` — genera sprites vía API de Gemini. Lee la key **solo**
  desde `.secrets/gemini.key` o `env GEMINI_API_KEY`; nunca la imprime ni la
  versiona. `.secrets/` y `*.key` están en `.gitignore`.
- `post-sprites.mjs` — post-proceso: chroma-key magenta → transparencia,
  recorte, relleno cuadrado, escalado, cuantizado.
- `slice-sheet.mjs` — recorta láminas multi-fase (crecimiento) en frames individuales.
- `assemble-plant.mjs` — ensambla una planta completa por piezas (`assets/parts`) según genética (prueba de concepto con `sharp`).
- `make-sheet-prompts.mjs` — genera prompts de láminas evaluando `src/species.js` con stubs mínimos de `PH` (truco: define un `PH` falso e inyecta `species.js` con `eval` para extraer `SPECIES` sin DOM).
- Salida cruda de generación (`assets/gen/`, `assets/gen_plants/`, `assets/gen_sheets/`) se ignora en git — **curar antes de versionar**.

## Cómo correr / probar

- No hay servidor ni build para desarrollo: abrir `index.html` directo en el navegador.
- `package.json` no define tests reales (`npm test` es un placeholder que falla a propósito).
- No hay linter ni typecheck configurado — no hay comando de verificación automática que correr tras un cambio; probar manualmente en el navegador.
- Autoguardado cada 20 s vía `localStorage` (clave `phenohunter_save_v1`, en `src/state.js`).
- **Build de distribución** (bundle inline autocontenido): `node <scratchpad>/build.js` → `dist/PhenoHunter.html`. El script de build vive fuera del repo (en el scratchpad de la sesión), no está versionado aquí; `dist/PhenoHunter.html` es un artefacto generado, no lo edites a mano.

## Convenciones

- Todo el código y comentarios de dominio están en **español**; identificadores de API/funciones en inglés cuando es genérico (`init`, `update`, `render`), en español cuando es de dominio (`cruzar`, `cosecha`).
- Módulos: patrón IIFE `(function (PH) {...})(window.PH = window.PH || {})`, sin `export`/`import` de ES modules, sin bundler.
- RNG determinista disponible vía `PH.util.RNG`/`mulberry32` para generación reproducible; el mundo vivo usa `Math.random` sin semilla.
- No introducir dependencias de runtime (todo debe seguir funcionando abriendo `index.html` sin servidor). Dependencias npm solo para tooling offline en `scripts/`.
- Respeta el canon cerrado de `docs/DESIGN_CANON.md` para cualquier sprite/arte nuevo (tamaños, encuadre, paleta).
- Nunca commitear `.secrets/`, `*.key`, ni salida cruda de `assets/gen*/` (ya cubiertos por `.gitignore`).

## Rama de trabajo

- Rama de trabajo: `claude/pheno-hunter-game-wzl06e`.
