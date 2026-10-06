# Cambios

## 1.5.0 · 6 de octubre de 2026

- **Nuevo: el resto del mundo sale de PixelLab (F3-resto, F4, F5, F6 y F7).** El atlas pasa de 569 a 1086 fotogramas; lo procedural queda de reserva.
  - **Humos y efectos:** cigarro, puro, porro, pipa, nube de vaper, golpe, gotas, brillo, polen, ácaros, monedas y spray, cada uno animado con `animate_object`. **Gaviotas y palomas** animadas (aleteo y picoteo).
  - **Tiles:** 12 del barrio con `create_tiles_pro` (dos llamadas: tierra y puentes se repitieron con la barandilla en su borde), agua, flores y hierba pisada animadas con `animate_image`; paredes y suelos de los tres interiores, felpudo y suelo de la carpa, también con `create_tiles_pro`.
  - **Fachadas:** piso, growshop, bar y casa gris con `create_image_pixflux` img2img sobre la huella del edificio (strength 30); las puertas se abren con `animate_image`. La casa gris no tiene puerta (se tapó la que pintó PixelLab con una ventana).
  - **Objetos:** árbol, farola y fuente (con agua animada) con `create_map_object` sobre el mapa; carpa de cultivo con pixflux sobre una huella; 20 props pequeños (con las luces de la gramola), nevera y cama.
  - **Plantas:** 6 fases, maceta vacía (sale de la germinación sin el brote) y balanceo en vegetativo, floración y lista. Los cogollos siguen en la rampa magenta y salen del color de cada variedad.
  - **Combate:** jugador de espaldas, policía y 3 ladrones con `create_image_pro` → `create_character` v3 → animaciones v3 a medida (golpe, patada, spray, comer, herido, desmayo; ataque, herido, huida; alto, multa, soborno, persecución). Fondos del callejón y de la calle con img2img.
  - **Iconos y título:** la bolsa y 12 iconos más, 4 cogollos de la Genoteca y la pantalla de título.
  - **Protagonista:** las 8 acciones que faltaban (correr, regar, plantar, cosechar, cruzar, oler, vender y móvil), con los 13 colores del sprite aprobado.
- **Nuevo: orillas (F4b).** Tres Wang de `create_topdown_tileset` encadenados por la misma hierba (agua, tierra y plaza). El motor (`arteOrilla`) pinta la transición sobre el agua, la tierra o la plaza que toca hierba, con máscara de esquinas; debajo sigue el tile de siempre (el agua, animada). La hierba de las orillas es la del tile aprobado, así que no hay costuras.
- **Nuevo:** el título sale del atlas cuando está (`arteTitulo`); sin atlas, el procedural. El calco incluye el título y las orillas, y `npm run test:arte` los comprueba (19/19).
- **Descartado:** `create_building_kit` (piezas en perspectiva de 24×42 que no casan con la rejilla de 16 px) y, para fachadas y carpa, `create_map_object` y `create_image_pro` (casas estrechas, carpa rara). Están en el manifiesto con su motivo.
- **Corregido: la carpa de cultivo.** La primera versión era una carpa vista de frente, con la pared trasera ocupando dos tercios del alto, y las macetas de arriba parecían colgadas de la pared. Ahora se ve desde arriba: del arte de PixelLab quedan el panel LED, el marco, una franja corta de pared trasera y las paredes laterales, y dentro se ve el suelo de mylar donde apoyan las macetas. Además mide 72 px de ancho (4 más por cada lado) para que las macetas de la izquierda no pisen el marco.
- **Nuevo: APK de Android** (`npm run apk` → `dist/ribera-verde.apk`, 0,8 MB). Una actividad con un WebView a pantalla completa e inmersiva que carga el `index.html` del build; sin permisos ni red; Atrás = B (si no hay nada que cerrar, la app pasa a segundo plano). Se construye sin Android SDK: stubs de la API + dalvik-dx + apktool + uber-apk-signer. Mínimo Android 7 (API 24), objetivo API 34, firma v2/v3.
- **Coste:** 425 generaciones en esta fase (de 1534 a 1109), 9 de ellas en las orillas.

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
