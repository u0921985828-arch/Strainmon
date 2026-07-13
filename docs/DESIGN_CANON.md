# 📐 Strainmon — Canon de diseño (CERRADO)

Decisiones bloqueadas para el arte y el motor. Todo sprite nuevo debe cumplir esto.

## 1. Resolución del motor — **32 px**

- Tile **32×32 px**. Resolución interna **480×320** (×2 del GBA original), **15×10 tiles** visibles.
- Los mapas siguen definidos en **unidades de tile** (no cambian).
- **Arquitectura de render en dos capas:**
  1. **Mundo (tiles)**: se dibuja en un búfer 240×160 y se escala ×2 al lienzo 480×320 → look retro nítido.
  2. **Personajes y criaturas (alta resolución)**: se dibujan encima a **resolución nativa 32 px** (sprites/imagenes), con todo su detalle.
- Sombra de contacto y overlays de ambiente (día/noche, clima) se aplican en la capa superior.

## 2. Actores overworld (jugador / NPCs) — **32×32 px**

- Rejilla **32×32**, fondo transparente, contorno 1px `#20161f`, luz cenital.
- **4 direcciones** (abajo, arriba, izquierda, derecha) × **3 fotogramas** (quieto, paso A, paso B).
- Encuadre: pies en la fila inferior, ~2 px de margen; cabeza con 2 px de aire.
- Proporción chibi (cabeza grande). Paleta cálida limitada.
- Entrega: hoja `player.png` (3 col × 4 fila = 96×128) o sueltos `player_<dir>_<n>.png`.
  NPCs: `npc_<rol>_<dir>_<n>.png` (mínimo dirección `down`).

## 3. Criatura-cepa — arte de Strain-dex — **128×128 px**

- Lienzo **128×128**, fondo **transparente**, **un solo sujeto centrado**.
- **Encuadre fijo:** maceta de terracota apoyada abajo (~8 px margen inferior); cuerpo
  centrado; **≥16 px de aire arriba** para cogollos altos / gigantismo.
- **Estilo:** contorno 1px `#20161f`, luz cenital, paleta media; **maceta terracota**
  de color constante, **cuerpo verde**, **cabeza-cogollo = color base del fenotipo**.
- Cara amable (ojos con brillo, sonrisa, mejillas), 2 brazos-hoja según tipo de hoja.
- **Generación:** rejilla lógica 128 → salida 1024 (×8 exacto) → recorte a contenido →
  quitar fondo si lo trae → cuantizar → guardar 128² transparente.
- Se muestra en: encuentro, Bóveda, Strain-dex, invernadero.

## 4. Criatura overworld (roaming) — **32×32 px** — ✅ decidido: pululan por el mapa

- Cada cepa aparece **suelta en la hierba alta** antes del encuentro.
- Sprite overworld = **derivado del arte 128²** (recorte + downscale a ~28–32 px, encajado
  en tile 32). Sin fondo. 1–2 fotogramas de balanceo.
- **Lógica:** en zonas de flora, se instancian cepas errantes que vagan lento; acercarse /
  pisar su tile abre el encuentro con esa cepa (respetando clima/estación/bioma).
- Naming: `roam_<SM-id>.png` (o se genera automático desde `strain_<SM-id>.png`).

## 5. Fenotipos e híbridos — ✅ decidido: híbridos = procedural

- **Cepas base (landrace pura):** usan el **arte IA** (`strain_<id>`).
- **Híbridos y mutantes (cruces):** usan la **criatura procedural** actual (que ya refleja
  color de cogollo, patrón, ploidía y mutaciones). Así cada cruce se ve único sin generar
  arte nuevo, y las landrace tienen su retrato "oficial".
- El motor elige: `form === 'cruce'` → procedural; si no → arte IA de la especie
  (fallback a procedural si falta el sprite).

## 6. Paleta y contorno (referencia)

- Contorno: `#20161f`. Terracota maceta: base `#c07048`, sombra `#9a5636`, luz `#d98a5f`.
- Cuerpo verde: base `#3f8f3a` (luz `#5ab04f`, sombra `#2f6b2a`).
- Cabeza-cogollo por color de fenotipo (hue del gen de color): verde, lima, ámbar, oro,
  púrpura, violeta, carmesí, rosa, magenta, azur, turquesa, obsidiana (negro), blanco (albino).

## 7. Pipeline de integración

1. Generar (Gemini, `scripts/gen-sprites.mjs`) a alta resolución.
2. Post: recorte a bbox → relleno cuadrado → downscale entero → quitar fondo → cuantizar.
3. Empaquetar: PNGs optimizados; para el archivo único, **inline base64** (128² cuantizado
   pesa pocos KB; ~20 sprites es asumible).
4. Cablear en render/UI; `drawPlant` procedural queda como fallback e híbridos.

## 8. Orden de trabajo

1. **Motor a 32 px** (refactor de render en dos capas) — *base, primero*.
2. Jugador + NPCs 32 px.
3. Criaturas-cepa 128² (18) + derivar roaming 32².
4. Spawn de cepas errantes en la hierba + encuentro.
5. (Después) tiles 32 px por bioma, edificios, iconos.

---
*Estado: canon cerrado con el usuario el 2026-07-13. Cambios requieren re-acuerdo.*
