# 🌿 STRAINMON — Prompt maestro desglosado

Documento único que describe **todo el juego** por bloques, para entenderlo,
recrearlo o continuarlo. Refleja el estado actual (sandbox isométrico híbrido
"salas + grow") y su hoja de ruta. Juego **100% original** (sin IP de terceros).

---

## 0. PITCH EN UNA LÍNEA
Sandbox isométrico single-player donde eres un **pheno hunter / grower-dealer**:
recorres una ciudad llena de NPCs, consigues **cepas landrace**, las **cultivas**
por fases, las **cruzas** con genética real y las **vendes**, para completar el
mayor **catálogo genético** (Strain-dex) y prosperar. Sin combates.

---

## 1. GÉNERO Y REFERENTES
- Estructura de coleccionismo/criatura (parodia de mecánica, no de marca).
- **Perspectiva isométrica 2:1** (salas y ciudad), roam libre estilo GTA-lite.
- Simulación de cultivo (fases de crecimiento, cuidado) + genética mendeliana.
- **Todo NPC** (single-player), tono relajado y adictivo.

## 2. FANTASÍA DEL JUGADOR
Empiezas como aprendiz con un pequeño grow-room. Exploras la ciudad, tratas con
dealers y clientes, viajas a regiones landrace, y te conviertes en el mayor
cazador/criador de genéticas del mundo.

---

## 3. BUCLE CENTRAL (core loop)
1. **Explorar** la ciudad/regiones (iso).
2. **Conseguir** cepa: parterres silvestres, mercado, NPCs.
3. **Cultivar** en tu grow-room: 5 fases (plántula→vegetativo→floración→cosecha).
4. **Cosechar**: propaga clones (conserva la genética; nunca se pierde).
5. **Cruzar** (laboratorio): genética diploide → fenotipos/colores/mutaciones nuevos.
6. **Vender**: mercado (legal) o **trato callejero** con clientes (premium).
7. **Progresar**: prestigio (Strain-dex) + dinero → desbloquea salas/equipo/regiones.

---

## 4. MOTOR Y PERSPECTIVA
- **Isométrico** 2:1: rombos de suelo 64×32, cubos de pared/mueble, personajes
  billboard anclados a la base. **Painter's algorithm** (orden por profundidad
  `gx+gy`) → oclusión correcta.
- Lienzo interno 480×320, escala entera a ventana. Render por capas.
- **Movimiento** por ejes de rejilla (cada flecha recorre una arista del rombo),
  con interpolación suave (tween) y **cámara que sigue** al jugador.

## 5. COLISIONES (robustas)
- **Lista blanca** de tiles caminables (`.` suelo, `D` puerta, `g` parterre).
  Todo lo demás bloquea (paredes `#`, vacío, fachadas `H`, farolas `P`, etc.).
- Bloquean también **objetos sólidos**, el **jugador** y **otros NPCs**.
- **Auditoría** automática que detecta NPCs/objetos/puertas/spawns mal colocados.

## 6. EL MUNDO (salas y ciudad)
- **Tu Grow-Room** (apt): invernadero, ordenador (banco/dex), cama (guardar).
- **Calle Verde** (street): fachadas, farolas, parterres silvestres, NPCs; puertas
  a las demás salas.
- **Mercado** (shop): mercader + mostrador (tienda).
- **Laboratorio** (lab): botánico + mesa de cruces + terminal de ADN.
- Salas conectadas por **puertas/warps**. Ciclo día/noche + clima tiñen la escena.
- *Roadmap:* ciudad más grande, más edificios, salas decorables, regiones landrace.

## 7. NPCs — ROLES E IA
- **IA de deambular** con colisión total; estados **idle/walk** animados.
- Roles: `player`, `dealer` (mercado negro), `neighbor` (lore), `customer`
  (compra tus cepas), `walker` (peatón), `merchant` (tienda), `botanist` (lab),
  `cop` 🔜 (sube "heat" al trapichear).
- Cada NPC: 4 direcciones iso × fotogramas idle/walk.

## 8. ECONOMÍA
- **Mercado**: compra herramientas/equipo, vende cepas a precio estándar.
- **Trato callejero**: los `customer` compran tu mejor cepa a **precio premium**
  (base del bucle dealer). *Roadmap:* reputación/heat, demanda por tipo, pedidos.
- Moneda: **créditos**. Segundo eje de progreso junto al **prestigio**.

## 9. GENÉTICA (el corazón)
Genotipo **diploide** real:
- **Cualitativos** con dominancia/recesividad y codominancia: color de flor
  (incl. albino recesivo), forma de hoja, terpeno/aroma, patrón de pigmentación.
- **Cuantitativos** (poligénicos): altura, producción, vigor, resistencia,
  velocidad, resina, aroma.
- **Poliploidía**: diploide/triploide(estéril)/tetraploide.
- **Mutaciones raras**: variegación, gigantismo, enanismo, quimera, fasciación,
  bioluminiscencia, cristalina, hexaploide.
- **Expresión** genotipo→fenotipo (y su arte). **Cruce**: herencia mendeliana +
  recombinación + mutaciones *de novo*. **Firma fenotípica** identifica variedades
  únicas para el catálogo.

## 10. CULTIVO (invernadero)
- Plantas del banco → **5 fases** con arte real (maceta constante, solo crece la
  planta). Ciclo modulado por velocidad y eventos.
- **Cosecha**: propaga varios **clones idénticos** (según producción/ploidía) +
  créditos + prestigio.
- *Roadmap:* **salud** (sed/riego, moho/enfermedad) con estados visuales; colocar
  macetas en el suelo de la sala; decoración/equipo (luz, CO2, hidro).

## 11. CEPAS (contenido)
18 **cepas landrace** de parodia mapeadas a regiones reales (Hindú Kush, Rif,
Michoacán, Triángulo Dorado, Congo, Oaxaca, Chitral, Jamaica…), cada una con
perfil genético, lore, y **secuencia de 5 fases** de crecimiento en arte propio.
Los **híbridos** (cruces) usan la criatura procedural (reflejan color/mutación).

## 12. CATÁLOGO (Strain-dex)
Registra cada **fenotipo único** (firma), con rareza, primer descubridor y
recuento. Progreso por especies y por fenotipos. Da **prestigio**.

## 13. INVESTIGACIÓN (ADN)
Secuenciación (revela alelos recesivos ocultos), **parentesco** entre genotipos y
**linaje**. Dirige los cruces hacia mutaciones concretas.

## 14. AMBIENTE Y EVENTOS
- **Ciclo día/noche**, **estaciones**, **clima** (lluvia, niebla, tormenta, ola de
  calor…) que alteran apariciones en tiempo real.
- **Eventos raros** temporizados (eclipse, meteoros, floración masiva, tormenta
  eléctrica, bruma astral) que disparan rarezas/mutaciones.

## 15. PROGRESIÓN
- **Prestigio** (no niveles): descubrir/catalogar → desbloquea regiones, licencias
  y equipo. **Dinero**: economía dealer/mercado.

## 16. CONTROLES
- Mover: `WASD`/Flechas (diagonales iso). Interactuar/Confirmar: `Espacio`/`E`.
- `I` Mochila · `B` Banco · `C` Strain-dex · `L` Laboratorio · `G` Invernadero ·
  `Q` Misiones · `M` Guardar. Controles táctiles en móvil. Autoguardado.

## 17. ARTE Y ESTILO
- Pixel-art 16-bit isométrico, contorno 1px `#20161f`, luz cenital, paleta cálida.
- **Personajes**: 8 roles × 4 direcciones (sprites originales, billboard).
- **Plantas**: 18 cepas × 5 fases (arte real, maceta constante) + criatura
  procedural para híbridos. *Roadmap:* mobiliario iso y tiles iso por tema.

## 18. ARQUITECTURA TÉCNICA
HTML5/Canvas, sin dependencias, espacio de nombres global `PH`. Se ejecuta
abriendo `index.html`; se empaqueta en **un único archivo** (`dist/PhenoHunter.html`)
con todo inline (CSS/JS/sprites en base64). Módulos:
`util, genetics, species, items, world, render, sprites, plantart, charart,
state, quests, events, research, garden, encounter, ui, iso, isogame`.
Guardado en `localStorage`.

## 19. PIPELINE DE SPRITES (Gemini)
`scripts/gen-sprites.mjs` (genera con API, fondo magenta/negro) →
`scripts/slice-sheet.mjs` (chroma/flood-fill + recorte por poses, modo `grow`
para fases con maceta constante) → módulo inline base64 → cableado. Clave del
personaje: `<rol>_<dir>` (1=SE 2=SW 3=NW 4=NE).

## 20. HOJA DE RUTA
1. **Mobiliario iso** (grow bench, PC, cama, mesa lab, mostrador, farola) y **tiles
   iso** por tema (parquet/asfalto/parterre).
2. **Salud del cultivo** (sed/riego, moho) con estados del atlas.
3. **Rutinas de NPC** por horario + **reputación/heat** (cop, redadas).
4. **Ciudad grande** y **salas decorables**; colocar macetas en el suelo.
5. Más regiones landrace y misiones (recuperar cepa perdida, pedidos, expos).

---
*Estado vigente: sandbox isométrico jugable con genética, cultivo, economía dealer
y 8 roles de NPC con sprites propios. Todo original.*
