# Cambios

## 1.4.0 · 6 de octubre de 2026

- **Nuevo: F1, protagonista generado con PixelLab** (aprobado). `base` + `idle` + `walk` en 4 direcciones (36 fotogramas, 14 colores), en el atlas `assets/sprites/atlas.{png,json}` e incrustado en el build. El resto del juego sigue procedural.
  - `create_image_pro` (64 candidatos de 32×32, prompt de RPG de portátil pulido) → el candidato 17 → `create_character` v3 con esa referencia → `idle` y `walk` con animación v3 a medida (las plantillas lo ponían de espaldas mirando al sur).
  - 27-28 px de alto y 16 de ancho, cabeza grande, ojos legibles, contorno limpio, 13 colores (`reduce_colors` con los 36 fotogramas juntos).
  - Coste real: unas 195 generaciones, incluidas tres versiones descartadas (estándar de 24-27 px, editada de 22-23 px y de 16 px).
- **Nuevo: F3, los 19 personajes con la misma receta** (13 NPC y 6 clientes, 510 fotogramas en el atlas).
  - Cada uno: `create_image_pro` 32×32 con el player como imagen de estilo (64 candidatos) → `create_character` v3 con el elegido → animaciones v3 a medida → `reduce_colors` a 15 colores.
  - `idle` al sur (y sur, norte y este en Kiko, Josune, Baltasar y Toño); `walk` sur/norte/este en los que caminan (el oeste es espejo del este); las acciones de ambiente de siempre (fumar, puro, pipa, vapear, semillas, servir, punto, radio, móvil…).
  - El caminar al sur se pide «de frente toda la animación»: la descripción normal lo giraba de lado (a Begoña se le repitió).
  - Coste: unas 480 generaciones (20 del Pro, 1 del v3 y 1 por dirección animada en cada personaje).
- **Cambiado:** el motor solo pone el `idle` en las direcciones que lo tienen (o su espejo este/oeste); en las demás, la base. `npm run test:arte` lo comprueba (17/17) y compara el atlas de calco con el número de PNG calcados en vez de con un mínimo fijo.

## 1.3.0 · 5 de octubre de 2026

- **Nuevo: el motor ya usa sprites (F2).** `src/js/01b-arte.js` carga el atlas que incrusta el build y dibuja con él personajes, tiles, objetos, edificios, plantas, combate y efectos; lo que falte sigue saliendo procedural. Incluye:
  - caminar y correr sincronizados con el paso, `idle` con fase propia por NPC;
  - acciones de ambiente (los fumadores fuman con su humo aparte; Unai nunca);
  - acciones del jugador (regar, plantar, cosechar, oler, cruzar, vender) y animaciones de combate;
  - cogollos del color de cada variedad, planta seca y plaga;
  - `?arte=procedural` para comparar.
- **Nuevo:** catálogo de sprites por familia de PixelLab (`docs/CATALOGO-SPRITES.md`, `npm run sprites:catalogo`).
  - Cada sprite va a la herramienta que mejor lo resuelve.
  - Fachadas, carpa, árbol, farola y fuente se pintan con `create_map_object` sobre recortes del mapa con máscara.
  - Personajes de combate con paso previo `create_image_pro` + `create_character` v3 para no perder la identidad.
  - Fondos y título con img2img.
  - Dos lotes compartidos de `create_1_direction_object`.
  - Coste documentado: ~410 generaciones (antes ~460) y herramientas descartadas con su motivo.
- **Nuevo:** `tools/sprites/calco.js` y `npm run test:arte`: atlas de calco sin gastar créditos y 16 comprobaciones del motor. Con ese atlas la historia completa también da 34/34.
- **Cambiado:**
  - `procesar.js` cuenta el tope de colores por sprite en tiles y objetos, encaja los efectos que crecen y admite `ajuste_por_sprite`.
  - `atlas.json` pasa a la versión 2, con `cubre`, `ambiente`, `fumador` y `menores`.
  - `validar.js` comprueba familias, lotes, pasos previos, máscaras y dependencias.
  - Las animaciones de balanceo de la planta tienen nombre propio.
  - Los scripts de Playwright aceptan `CHROMIUM_PATH`, `RV_HTML` y `RV_SALIDA`.

## 1.2.0 · 5 de octubre de 2026

- **Nuevo:** kit pro de sprites y animaciones con PixelLab para Claude Code. El juego no cambia.
  - `docs/PIXELLAB.md` (guía): dirección de arte, fases, animaciones, comportamientos de ambiente (fumadores con humo aparte), integración en el motor, QA, presupuesto y problemas típicos.
  - `art/manifest.json` (47 assets + 14 items, cobertura del 100 %).
  - `art/inventario.json`, `art/referencias/` y `art/paleta/`.
  - `tools/sprites/` (`referencias`, `paleta`, `validar`, `procesar`).
  - Comando `/sprites` y `.mcp.json.ejemplo`.

## 1.1.0 · 5 de octubre de 2026

- **Arreglado:** los cruces sin receta fallaban. Se gastaban las semillas y no salía el híbrido propio.
- **Arreglado:** las redadas no podían ocurrir porque el calor bajaba antes de comprobarse. Ahora saltan con calor ≥ 90 al empezar el día.
- **Arreglado:** el capítulo 5 no empezaba si la 8.ª variedad llegaba por un regalo (abuela Txaro) o por un arbusto, hasta la siguiente cosecha, venta o cruce.
- **Arreglado:** no se podía hablar con Josune, la camarera, porque quedaba detrás de dos taburetes. Ahora está en (2,2).
- **Ajuste:** los ladrones de capítulos altos ganaban casi siempre. Ahora tienen vida `12 + 2 × cap. + 0…4` y daño `2 + cap./4` a `4 + cap./2`, y cada ladrón vencido sube +2 la VIDA máxima (tope 60).
- **Nuevo:** código separado en 16 módulos (`src/js`) con build reproducible, `index.html` jugable sin conexión con las fuentes incrustadas, test automático de la historia completa (34 pasos), generador de documentación, capturas y documentación de diseño, guion, genética, mapa y sprites.

## 1.0.0 · 5 de octubre de 2026

- Primera versión, publicada como Artifact de Claude.
