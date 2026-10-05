---
name: sprites
description: Genera, procesa e integra sprites y animaciones de Ribera Verde con el MCP de PixelLab siguiendo art/manifest.json y docs/PIXELLAB.md, sin salirse de la estética acordada. Úsalo cuando se pida mejorar gráficos, sprites, animaciones o arte del juego.
argument-hint: "[F0..F8 | id-de-asset | estado]"
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash(npm run *)
  - Bash(node tools/*)
  - mcp__pixellab__get_balance
  - mcp__pixellab__list_jobs
  - mcp__pixellab__wait_for_jobs
  - mcp__pixellab__create_character
  - mcp__pixellab__animate_character
  - mcp__pixellab__get_character
  - mcp__pixellab__create_tiles_pro
  - mcp__pixellab__get_tiles_pro
  - mcp__pixellab__create_building_kit
  - mcp__pixellab__create_topdown_tileset
  - mcp__pixellab__get_topdown_tileset
  - mcp__pixellab__create_map_object
  - mcp__pixellab__get_map_object
  - mcp__pixellab__create_1_direction_object
  - mcp__pixellab__get_object
  - mcp__pixellab__select_object_frames
  - mcp__pixellab__dismiss_review
  - mcp__pixellab__animate_object
  - mcp__pixellab__create_image_pixflux
  - mcp__pixellab__create_image_pro
  - mcp__pixellab__animate_image
  - mcp__pixellab__get_image
  - mcp__pixellab__reduce_colors
  - mcp__pixellab__correct_pixelart
  - mcp__pixellab__unzoom_image
  - mcp__pixellab__pixelart_workbench
  - mcp__pixellab__save_to_asset
---

# /sprites — arte de Ribera Verde con PixelLab

Argumento: `$ARGUMENTS` (una fase `F0`…`F8`, el id de un asset del manifiesto, o `estado`).

## Antes de nada

1. Lee `docs/PIXELLAB.md` (guía completa), `docs/CATALOGO-SPRITES.md` (qué herramienta, en qué lote y en qué orden) y `art/manifest.json` (parámetros exactos). No improvises parámetros ni herramientas: salen del manifiesto.
2. Comprueba que el MCP responde con `mcp__pixellab__get_balance`. Si no hay herramientas `mcp__pixellab__*`, para y di cómo conectarlo (sección «Preparación» de la guía).
3. Si no existen `art/referencias/` ni `art/paleta/`, ejecuta `npm run sprites:ref`. Ejecuta siempre `npm run sprites:validar`; con errores no se genera nada.

## Qué hacer según el argumento

- **`estado`**: resume por fase cuántos assets están `pendiente`, `generado`, `procesado` y `aprobado`, más el saldo y lo que falta por gastar según `npm run sprites:catalogo`. No generes nada.
- **Una fase**: recorre en orden los assets de esa fase que no estén `aprobado`. En **F1** no pases a F2 sin que la persona apruebe el player a la vista de la captura comparativa.
- **Un id**: haz solo ese asset.

## Bucle por asset

1. **Presupuesto.** Antes de cada llamada de lote (create_1_direction_object, mode pro, estados), mira el saldo. Si el coste puede pasar del saldo, para y avisa.
2. **Generar** con la herramienta y los `parametros` del asset.
   - Prompt: `estilo.prompt_base` + `descripcion` + los hex de `colores_identidad`.
   - Imágenes: **solo las de `entrada`**, con el nombre de parámetro que pone ahí (`style_images`, `init_image_base64` + `color_image_base64`, `reference_image_base64` solo con `mode: "v3"`, `background_image` + `inpainting` = `{"type": "mask", "mask_image": "<base64 de la máscara>"}` en `create_map_object`).
   - `referencias` no se envía: sirve para la revisión visual y para los colores de identidad.
   - **`depende_de`:** si lo que necesita no está `aprobado`, para. Las fachadas y props de exterior van después de `tiles-exterior` y de volver a lanzar `npm run sprites:ref` con el atlas en el build.
   - **`previo`:** primero esa llamada (p. ej. `create_image_pro` con el sprite aprobado como referencia), elige candidato, guárdalo en `previo.guarda` y úsalo como entrada.
   - **`lote`:** junta en una sola llamada las `item_descriptions` de todos los assets de ese lote (`manifest.lotes`) y reparte después los candidatos elegidos a la carpeta de cada asset.
3. **Esperar** con `wait_for_jobs`; nunca con bucles de espera propios. Después, el `get_*` que toque.
4. **Elegir.** En los objetos en revisión, mira los candidatos, quédate con uno por item (`select_object_frames`) y descarta el resto (`dismiss_review`).
5. **Animar** según `animaciones`, con el parámetro de cada herramienta (tabla en la guía, sección 6).
   - `animate_character`: `template_animation_id`, o `action_description` + `frame_count`, y siempre `directions` explícitas.
   - `animate_object`: `animation_description` + `frame_count`, sin `directions` en objetos de 1 dirección.
   - `animate_image`: `action` + `frame_count` + `first_frame_base64`.
6. **Descargar** a `art/crudo/<grupo>/<sprite>/<dir>/<NN>.png`. `sprite` es `base` para las rotaciones, el nombre de la animación, o la clave del tile u objeto. `dir` es `south`, `north`, `east`, `west` o `unica`.
7. **Procesar** con `npm run sprites:procesar -- <grupo>`. Si hay errores, arréglalos y repite.
   - Píxeles sueltos o borde sucio: `pixelart_workbench` (`lint`, `repair`) o `correct_pixelart`, y guarda con `save_to_asset`.
   - Fuera de celda o mal encuadrado: regenera.
8. **Revisión visual.** Abre los PNG procesados (amplíalos) junto a su referencia de `art/referencias/` y aplica la lista de la guía (sección «QA»). Si falla algo, vuelve al paso 2 y regenera.
9. **Atlas y juego.** `npm run sprites:procesar -- --todos --atlas`, después `npm run build`, `npm test` (34/34), `npm run test:arte` (16/16) y `npm run capturas`. Mira las capturas.
10. **Anotar** en el manifiesto:
    - `estado: "aprobado"`;
    - `pixellab` con los ids devueltos (`character_id`, `animation_group_id`, `object_id`…) y la `seed` si la herramienta la acepta;
    - `coste_real` (saldo antes − después).

## Reglas que no se rompen

- La estética acordada manda: 240×160, casillas de 16 px, vista 3/4, chibi, contorno oscuro de 1 px, 3 tonos, paleta de `art/paleta/` y como mucho 15 colores por sprite.
- Ningún menor fuma, vapea ni aparece junto a drogas. El humo siempre es un VFX aparte.
- No se borra nada de PixelLab sin permiso. Tampoco se usa `mode: "pro"`, `create_character_state` ni `confirm_cost: true` sin enseñar antes el coste.
- `art/crudo/` no se edita a mano. Los arreglos se guardan en PixelLab (`save_to_asset`) y se vuelven a descargar.
- El juego tiene que seguir funcionando con arte procedural en lo que todavía no tenga sprite.
