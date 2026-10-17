<!-- kit-pro -->
# Sprites y animaciones con PixelLab · guía pro

Esta guía y su kit sirven para que **Claude Code** cambie el arte procedural de Ribera Verde por sprites y animaciones de **PixelLab** sin perder la estética acordada (RPG de portátil de 16 bits, 240 × 160, casillas de 16 px). Está escrita para que la siga Claude Code con el comando `/sprites`, pero también se lee de corrido.

Los nombres de herramientas y los parámetros se comprobaron contra el MCP oficial (`https://api.pixellab.ai/mcp`, 98 herramientas) y la API v2 (`https://api.pixellab.ai/v2/openapi.json`) en octubre de 2026. Si PixelLab cambia algo, `npm run sprites:validar` lo detecta en cuanto el manifiesto use un valor que ya no existe.

## 1. Qué hay en el kit

| Ruta | Para qué sirve |
|---|---|
| `art/manifest.json` | **La biblia.** 50 assets (+14 items) con familia de herramienta, herramienta, parámetros, prompt, entrada, celda, animaciones, ambiente, fase, dependencias, lotes compartidos y pasos previos. Cubre el 100 % de los gráficos actuales del juego. |
| `docs/CATALOGO-SPRITES.md` · `art/catalogo.json` | **El catálogo:** cada sprite del juego con su familia de PixelLab, herramienta, lote, entrada, orden y coste. Lo genera `tools/sprites/catalogo.js` desde el manifiesto. |
| `art/inventario.json` | Lista real de assets del juego: 42 tiles de suelo, 26 objetos, 23 personajes, fases de planta, combate y extras. Sale del propio juego. |
| `art/referencias/` | El arte procedural actual exportado a PNG: personajes en 4 direcciones × 3 fotogramas, tiles, objetos, plantas, fondos y pantalla de título. `mapa/` son recortes del mapa con su máscara para `create_map_object` (si el build lleva atlas, salen con los tiles ya aprobados). `estilo/*_x2.png` son los personajes de frente al doble, para la revisión a ojo. `_hoja-*.png` son hojas de contacto a 4×. Las referencias sirven para revisar y para sacar los colores de identidad; a PixelLab solo se envía lo que el asset pone en `entrada`. |
| `art/paleta/` | Paleta real del juego: `ribera.png` (121 colores, la que se pasa a PixelLab), `.hex`, `.gpl` (GIMP o Aseprite) y `ribera.json` (maestra, existentes, fondos y colores de identidad por personaje). |
| `tools/sprites/referencias.js` | Regenera inventario y referencias desde `index.html`. |
| `tools/sprites/paleta.js` | Regenera la paleta desde las referencias. |
| `tools/sprites/validar.js` | Valida el manifiesto: herramientas, límites, plantillas, referencias, reglas de contenido y cobertura. |
| `tools/sprites/procesar.js` | Pasa la salida cruda de PixelLab a sprites listos (paleta, alfa, tope de colores, encaje en celda e informe) y monta el atlas. |
| `tools/sprites/catalogo.js` | Escribe el catálogo y falla si alguna clave del juego queda sin catalogar. |
| `tools/sprites/calco.js` | Calca el arte procedural al formato de `art/crudo` (sin gastar créditos) para probar el motor de punta a punta. |
| `tools/test-arte.js` | Prueba de la integración: calco → atlas → juego, y 16 comprobaciones (caminar, ambiente de fumadores con humo, menor que nunca fuma, combate, cogollos por variedad…). |
| `src/js/01b-arte.js` | El motor de sprites del juego (F2, ya hecho): carga el atlas, anima y deja el procedural de reserva. |
| `.claude/skills/sprites/SKILL.md` | El comando `/sprites` para Claude Code. |
| `.mcp.json.ejemplo` | Conexión del MCP con el token en una variable de entorno, en vez de escrito en el comando. |

Comandos (todos en `package.json`):

```
npm run sprites:ref        # build + referencias + paleta
npm run sprites:validar    # comprueba el manifiesto (0 errores para empezar)
npm run sprites:procesar -- <grupo> [--atlas]      # o -- --todos --atlas
npm run sprites:catalogo   # catálogo por herramienta (docs/CATALOGO-SPRITES.md)
npm run test:arte          # motor de sprites con un atlas de calco (22 comprobaciones)
```

## 2. Dirección de arte (no negociable)

Es lo que mantiene «la estética que hemos acordado». Todo está también en `manifest.estilo` y `manifest.celdas`.

- **Pantalla y rejilla:** 240 × 160, casillas de 16 px. No se escala nada en tiempo real; cada sprite se dibuja a su tamaño nativo.
- **Vista:** 3/4 baja (`low top-down`), como los RPG de portátil de principios de los 2000.
- **Personajes:** celda de **32 × 32 con los pies en (16, 30)**. Es el equivalente a los sprites de 16 × 32 de esa época. Proporciones **chibi**, con la cabeza en torno al 40-45 % de la altura. Sin sombra en el sprite: la sombra la pinta el motor.
- **Contorno** oscuro de 1 px (`#26262e`, contorno selectivo permitido por dentro). **Sombreado** de 3 tonos con luz desde arriba a la izquierda. Sin antialias, sin degradados y sin tramados.
- **Color:**
  - Paleta maestra `art/paleta/ribera.png`.
  - **Como mucho 15 colores + transparencia por sprite**, el mismo límite que una paleta de 16 colores de la época. Única excepción: los fondos de pantalla entera de la vista C (`carpa-c-fondo`, `max_colores: 32` en el manifiesto).
  - Cada personaje conserva sus **colores de identidad** actuales (gorra verde y camiseta roja del protagonista, traje morado de Baltasar…) para que se le reconozca.
- **Celdas:**

| Celda | Tamaño | Ancla | Ajuste | Uso |
|---|---|---|---|---|
| `tile` | 16 × 16 | — | exacto | suelos, paredes, interiores |
| `tile_bloque` | 32 × 32 | — | exacto | tiles animados en bloques de 2 × 2 casillas (agua, flores, hierba alta) |
| `personaje` | 32 × 32 | (16, 30) | pies | jugador, NPC, clientes |
| `planta` | 32 × 32 | (16, 31) | pies | fases de cultivo en maceta |
| `objeto_1x1` / `objeto_alto` | 16 × 16 / 32 × 32 | abajo-centro | pies | props (los altos sobresalen de su casilla) |
| `edificio_7x6` / `edificio_6x6` | 112 × 96 / 96 × 96 | base (56, 95) / (48, 95) | pies | fachadas completas encima de las casillas del edificio |
| `puerta` | 32 × 32 | — | exacto | animación de la puerta, recortada del edificio |
| `carpa_p60` / `carpa_m100` / `carpa_g150` | 64 / 96 / 128 × 80 | — | exacto | carpas del piso (huella entera de 4/6/8 × 5 casillas): por dentro (`carpa-<t>`) y cerrada (`carpa-<t>-fuera`) |
| `foco` | 32 × 32 | (16, 0) | exacto | focos CFL, sodio y LED colgados (el motor los apoya por abajo y corta el cable en el techo de la carpa) |
| `combate` | 64 × 64 | (32, 62) | pies | sprites de combate |
| `icono` / `cogollo` | 16 × 16 / 32 × 32 | centro | centro | mochila, tienda, Genoteca |
| `vfx` / `vfx_grande` | 16 × 16 / 32 × 32 | abajo-centro | pies | humo, golpes, brillos |
| `pantalla` | 240 × 160 | — | exacto | fondos de combate y título |

**Ajuste:** `pies` alinea la fila más baja y el centro del contorno con el ancla; `centro` alinea el centro del contorno; `exacto` exige el tamaño justo de la celda. Un asset puede cambiarlo por sprite con `ajuste_por_sprite` (lo que cuelga de la pared, como botellas, ventana y póster, va `exacto` para no caerse al suelo).

- **Prompt base**, que se antepone a cada `descripcion`:

```
16-bit handheld RPG sprite in the style of early-2000s portable console games, chibi proportions with a big head,
3/4 low top-down view, clean 1px dark outline, 3-tone cel shading with light from the top-left, limited flat palette,
no anti-aliasing, no gradients, no dithering, transparent background
```

- **Prohibido:**
  - antialias, degradados y brillos suaves;
  - proporciones realistas;
  - texto y logos;
  - personajes, nombres o logos de juegos existentes;
  - menores fumando o junto a drogas.

## 3. Preparación (F0)

1. **Conectar el MCP.** Ya lo tienes con:
   ```
   claude mcp add pixellab https://api.pixellab.ai/mcp -t http -H "Authorization: Bearer TU_TOKEN"
   ```
   La forma canónica de la documentación es `claude mcp add --transport http pixellab https://api.pixellab.ai/mcp --header "Authorization: Bearer TU_TOKEN"`. Compruébalo con `claude mcp get pixellab` o con `/mcp` dentro de Claude Code. El nombre **tiene que ser `pixellab`**, porque el comando `/sprites` llama a `mcp__pixellab__*`.

   Alternativa sin el token en el historial de la consola:
   - `setx PIXELLAB_TOKEN "tu-token"` en `cmd`;
   - abre una consola nueva;
   - renombra `.mcp.json.ejemplo` a `.mcp.json`.

   Si usas esta vía, quita el servidor añadido a mano (`claude mcp remove pixellab`) para no tener dos.
2. **Dependencias:** `npm install` y `npx playwright install chromium`.
3. **Referencias y paleta:** `npm run sprites:ref`. Vuelve a ejecutarlo si cambias el arte procedural o el manifiesto.
4. **Validar:** `npm run sprites:validar` → `ERRORES: 0`, con cobertura del 100 % en personajes y resto.
5. **Saldo:** `get_balance`. El manifiesto completo cuesta unas 410 generaciones en las herramientas con coste documentado, más las que no lo tienen (ver sección 9 y el catálogo).

## 4. El bucle de cada asset

Es lo que hace `/sprites` con cada entrada del manifiesto:

1. **Generar** con la `herramienta` y los `parametros` exactos.
   - Prompt: `prompt_base` + `descripcion` + los hex de `colores_identidad`.
   - **Imágenes: solo las de `entrada`**, con el nombre de parámetro que pone ahí:
     - `style_images` en `create_tiles_pro` (`[{base64, width, height}]`) y en `create_1_direction_object` (`[{base64, format: "png"}]`, hasta 256 px; sin `size`, porque el tamaño lo fija la imagen más grande);
     - `init_image_base64` (la pantalla actual, img2img con `init_image_strength`) y `color_image_base64` (paleta) en `create_image_pixflux`;
     - `reference_image_base64` en `create_character` **solo con `mode: "v3"`**;
     - `background_image` (recorte de `art/referencias/mapa/`) e `inpainting` = `{"type": "mask", "mask_image": "<base64 de *_mascara.png>"}` en `create_map_object`: PixelLab pinta el edificio o el prop **encima del suelo real** (blanco = genera, negro = se conserva) y casa luz, paleta y perspectiva. Sin `width`/`height`: salen del recorte.
   - **`previo`:** algunos assets tienen un paso antes (los de combate: `create_image_pro` con el sprite aprobado como referencia, eliges uno de los 16 candidatos, lo guardas donde dice `guarda` y ese PNG es la entrada de `create_character` v3).
   - **`lote`:** los assets con el mismo `lote` van en **una sola llamada** de `create_1_direction_object` (se juntan sus `item_descriptions`); cada candidato elegido va después a la carpeta de su asset.
   - **`depende_de`:** no generes un asset antes de que esté aprobado aquello de lo que depende (las fachadas y los props de exterior, tras `tiles-exterior`; vuelve a lanzar `npm run sprites:ref` con el atlas puesto para que los recortes ya lleven los tiles nuevos).
   - Las herramientas sin entrada de imagen (`create_character` estándar, `create_building_kit`, `create_topdown_tileset`) no reciben ninguna: su coherencia sale de los parámetros, el prompt y la paleta.
   - Los PNG de 16-32 px van bien en base64. Con imágenes grandes, usa el parámetro `_url` (https) si la herramienta lo tiene: los clientes MCP recortan a veces el base64 largo.
2. **Esperar** con `wait_for_jobs`, que es gratis y devuelve en cuanto termina algo. Después, el `get_*` correspondiente.
3. **Elegir.** Con `create_1_direction_object` y `size ≤ 42`, PixelLab devuelve **64 candidatos** en estado de revisión (también en los lotes compartidos). Elige uno por item con `select_object_frames` y descarta el resto con `dismiss_review`.
4. **Animar** según `animaciones` (sección 6).
5. **Descargar** a `art/crudo/<grupo>/<sprite>/<dir>/<NN>.png`:
   - `grupo` es el id del asset o del item;
   - `sprite` es `base` para las rotaciones, el nombre de la animación, o la clave del tile u objeto (`grass`, `jukebox`…);
   - `dir` es `south`, `north`, `east`, `west` o `unica`.
6. **Procesar** con `npm run sprites:procesar -- <grupo>`. El informe queda en `art/procesado/<grupo>/informe.json`.
7. **Revisión visual** con la lista de la sección 8.
8. **Atlas y juego:** `npm run sprites:procesar -- --todos --atlas`, después `npm run build`, `npm test` y `npm run capturas`.
9. **Anotar** en el asset:
   - `estado: "aprobado"`;
   - `pixellab` con los ids devueltos (`character_id`, `animation_group_id`, `object_id`…) y, si la herramienta la acepta, la `seed`;
   - `coste_real` (saldo antes − después).

**Qué hace `procesar.js`** (probado con crudos sintéticos: devuelve el arte original exacto):
- **Alfa binario:** opaco a partir de 128.
- **Bloqueo de paleta:**
  - primero, los colores de identidad del asset (los declarados y los de sus PNG de referencia);
  - si ninguno está cerca, el color más cercano de los 320 que ya usa el juego (`existentes` en `ribera.json`; la maestra de 121 es la que se pasa a PixelLab);
  - los cogollos van a su rampa clave.
- **Tope de colores:** funde los colores menos usados hasta dejar 15. Personajes, combate y VFX comparten paleta en todo el grupo (como un sprite de la época); tiles, objetos, plantas, edificios y fondos cuentan por sprite.
- **Limpieza:** quita los píxeles sueltos.
- **Encaje en la celda:** cada secuencia se alinea por los pies de su primer fotograma y el mismo desplazamiento se aplica a toda la secuencia, para que los saltos y agacharse sigan moviéndose. Si así algo se saldría (efectos que crecen al disiparse), usa la caja de todos los fotogramas y avisa. Las carpetas de `art/crudo` que empiezan por `_` (como `_ref`) no son grupos.
- **Informe:**
  - % de píxeles ya en paleta antes del bloqueo;
  - colores finales;
  - píxeles semitransparentes y huérfanos;
  - deriva de los pies entre fotogramas;
  - aviso si dos colores de identidad son casi iguales.
- **Ajuste a la celda** según su modo (`pies`, `centro` o `exacto`). Con `exacto`, si el PNG llega ampliado a un múltiplo limpio (×2, ×4…) lo reduce por vecino más próximo y avisa.
- **Errores:** si algo se sale de la celda, si el tamaño no cuadra o si quedan más de 15 colores.

## 4b. Catálogo: qué herramienta para cada sprite

El detalle sprite a sprite está en **[CATALOGO-SPRITES.md](CATALOGO-SPRITES.md)** (`npm run sprites:catalogo`). En resumen, cada cosa va a la familia de PixelLab que mejor la resuelve:

| Familia | Qué | Herramientas | Por qué |
|---|---|---|---|
| **Personajes** | protagonista, 13 NPC, 6 clientes, combate | `create_character` estándar (1 gen) + plantillas; combate: `create_image_pro` con referencia → `create_character` v3 | rig humanoide: rotaciones coherentes y animaciones a 1 gen por dirección; el paso previo conserva la identidad a 64 px |
| **Mapa · terreno** | suelos del barrio, interiores, agua y flores animadas, orillas | `create_tiles_pro` (tiles numerados en 1 llamada; también paredes y suelos de interior, porque `create_building_kit` no casa con la rejilla), `create_topdown_tileset` (3 Wang encadenados por la hierba), `animate_image` | lo que se repite en casillas |
| **Mapa · objetos con el estilo del mapa** | árbol, farola, fuente; 4 fachadas y carpa | árbol, farola y fuente: `create_map_object` con `background_image` + máscara; fachadas y carpa: `create_image_pixflux` img2img sobre su huella (strength 30 y 60) | se pintan sobre el suelo real o sobre la huella: casan luz, paleta, perspectiva y columna de la puerta |
| **Objetos sueltos en lote** | props pequeños, plantas, iconos, cogollos, VFX, gaviota y paloma | `create_1_direction_object` con `item_descriptions` y **lotes compartidos** | 64 candidatos por llamada: dos lotes (16 y 32 px) ahorran ~120 generaciones |
| **Imágenes simples** | fondos de combate y título | `create_image_pixflux` img2img + paleta | 1 generación por pantalla, sin mover la composición |

Descartadas, con su motivo en el catálogo: `create_path_tiles` (solo 32 px), `create_ui_asset` (≥ 192 px), estados de personaje u objeto (nadie cambia de ropa; la planta seca la hace el motor), retratos con boca animada (opcional, F9) y el Map Workshop (`create_map`, `edit_map`, `view_map`), que sirve como maqueta opcional en F4b pero no en el juego.

## 5. Fases

| Fase | Qué | Puerta para pasar |
|---|---|---|
| **F0** Preparación | MCP, saldo, referencias, paleta, validación | `ERRORES: 0` |
| **F1** Ancla de estilo | protagonista: base + `idle` + `walk`, e integración mínima | **la apruebas tú** viendo la captura antes y después |
| **F2** Motor | atlas, animaciones, ambiente, VFX, arte procedural de reserva (sección 7). **Hecho en la 1.3** | `npm test` 34/34 con y sin atlas y `npm run test:arte` 16/16 |
| **F3** Personajes | 13 NPC, 6 clientes, acciones de ambiente, humos y efectos (`vfx-16`, `vfx-32`), gaviotas y palomas | revisión visual y capturas. **Personajes hechos en la 1.4; humos, efectos, gaviotas y palomas en la 1.5** |
| **F4** Entorno | primero tiles e interiores; después, con los recortes regenerados, las 4 fachadas, árbol, farola, fuente y carpa sobre el mapa; props pequeños y tiles animados | mosaico 3×3 sin costuras. **Hecho en la 1.5** (fachadas y carpa con pixflux img2img, ver sección 10) |
| **F4b** Transiciones *(opcional)* | tilesets Wang + autotiling en el motor | — **Hecho en la 1.5**: agua, tierra y plaza como superposiciones sobre el tile de siempre (`arteOrilla`) |
| **F5** Plantas | 6 fases, balanceo, cogollo por variedad, seca, plaga | las 23 variedades se distinguen. **Hecho en la 1.5** |
| **F6** Combate | jugador de espaldas y policía (paso previo con el sprite aprobado), 3 ladrones, 2 fondos img2img | combates de prueba enteros. **Hecho en la 1.5** |
| **F7** Iconos y título | iconos de objetos, cogollos de la Genoteca, pantalla de título | — **Hecho en la 1.5** (el motor dibuja el título del atlas) |
| **F8** Pulido | QA global, capturas, test, build, CHANGELOG | todo en verde |

**F1 es la que manda.** El protagonista se genera con `create_character`:

```
mode "standard", n_directions 4, size 32, view "low top-down",
proportions '{"type": "preset", "name": "chibi"}',
outline "single color black outline", shading "basic shading", detail "medium detail"
```

`create_character` no tiene `seed`: genéralo 2 o 3 veces y quédate con el mejor. Después vienen `animate_character` con `template_animation_id: "breathing-idle"` y `"walking-4-frames"` en las 4 direcciones. Los parámetros que apruebes son los de todos los demás personajes; así se mantiene la coherencia, porque `style_character_id` solo existe en el modo `pro`, que cuesta 20-40 generaciones.

Si un personaje cambia de cara entre direcciones, **regenera con `mode: "v3"`, `reference_image_base64` = su rotación sur aprobada de PixelLab (32 × 32) y `size: 32`**. Ese modo rota tu sprite exacto a 8 direcciones. No uses los `_x2` procedurales como referencia: v3 los copiaría tal cual, a 32 × 40.

## 6. Animaciones

### Qué parámetro lleva cada campo del manifiesto

| Manifiesto | `animate_character` | `animate_object` | `animate_image` |
|---|---|---|---|
| `plantilla` | `template_animation_id` | — | — |
| `accion` | `action_description` | `animation_description` | `action` |
| `frames` | `frame_count` (v3: par 4-16) | `frame_count` (par 4-16) | `frame_count` (par 4-16) |
| `direcciones` | `directions` (pásalas siempre) | **no** en objetos de 1 dirección (da error) | — |
| imagen de partida | — | — | `first_frame_base64` o `first_frame_url` (recorte del sprite procesado, al tamaño de `lienzo`) |

### Plantillas (1 generación por dirección)
Las de humanoide que hay hoy, con `template_animation_id`:
- **Caminar y correr:** `walking-4-frames`, `walking-6-frames`, `walking-8-frames`, `running-4-frames`, `running-6-frames`, `running-8-frames`, `sad-walk`, `scary-walk`, `crouched-walking`.
- **Quieto y acciones:** `breathing-idle`, `crouching`, `picking-up`, `drinking`, `getting-up`, `pushing`, `pull-heavy-object`, `throw-object`.
- **Combate:** `fight-stance-idle-8-frames`, `cross-punch`, `lead-jab`, `high-kick`, `roundhouse-kick`, `taking-punch`, `falling-back-death`.
- **Otras:** `backflip`, `fireball`, `flying-kick`, `front-flip`, `hurricane-kick`, `jumping-1`, `jumping-2`, `leg-sweep`, `running-jump`, `running-slide`, `surprise-uppercut`, `two-footed-jump`, `walk`, `walk-1`, `walk-2`, `walking`, `walking-2` a `walking-10`.

### Acciones a medida (`mode: "v3"`)
- Van con `action_description` y `frame_count` par entre 4 y 16.
- Cuestan unas 1 generación por dirección a 32-64 px.
- **Por defecto solo animan la dirección sur:** pasa siempre `directions`.
- Con `keep_first_frame: true` (por defecto) se guarda `frame_count + 1` fotogramas; el 0 es la rotación. Para bucles limpios usa `false`.

### Tiempos en el motor

| Animación | Fotogramas | Ritmo |
|---|---|---|
| `walk` | 4 | **sincronizada con el paso**: un ciclo cada 2 casillas, no por reloj |
| `run` | 6 | un ciclo cada 2 casillas |
| `idle` | los de la plantilla | 3-4 fps, con fase aleatoria por NPC para que no respiren a la vez |
| acciones del jugador | 6-8 | 8 fps, una vez, y vuelve a `idle` |
| ambiente | 6-12 | 8 fps, cada `cada_s` segundos (aleatorio entre el mínimo y el máximo) |
| VFX | 4-8 | 10 fps, una vez |
| tiles animados (agua, flores) | 4 | 3-4 fps en bucle |

### Comportamiento de ambiente (`ambiente` en el manifiesto)
Solo se dispara si el NPC está **quieto, en pantalla y fuera de un diálogo**. Al hablarle, mira al jugador y corta la acción.

| Quién | Acciones | Fuma | Humo |
|---|---|---|---|
| Kiko | liar y fumar un porro · ordenar semillas | porro | `vfx-humo-porro` |
| Don Baltasar | fumar un puro · contar billetes | puro | `vfx-humo-puro` |
| Toño | crujirse los nudillos · fumar | cigarro | `vfx-humo-cigarro` |
| Sargento Molina | fumar apoyado, chulesco | cigarro | `vfx-humo-cigarro` |
| Iñaki | fumar en pipa · recoger un cabo | pipa | `vfx-humo-pipa` |
| Darko | vapear con nube grande | vaper | `vfx-nube-vaper` |
| Clientes 2 y 5 | fumar | cigarro | `vfx-humo-cigarro` |
| Josune | secar un vaso · servir | — | — |
| Abuela Txaro | hacer punto | — | — |
| Patxi | echar migas (con `paloma` al lado) | — | — |
| Begoña | cotillear gesticulando | — | — |
| Unai *(menor)* | dar toques a una pelota | **nunca** | — |
| Agente | hablar por la radio | — | — |
| Jurado | apuntar en la carpeta | — | — |
| Clientes 1, 3, 4 y 6 | mirar el móvil | — | — |

**El humo es un VFX aparte**, no está pintado en el sprite:
- sale en el fotograma `frame_humo` desde `offset_boca` (respecto a los pies);
- sube 1 px cada 3 fotogramas mientras corre su propia animación de disiparse;
- con viento, se desplaza 1 px a la derecha cada 6 fotogramas.

Así sirve el mismo humo para todos y no se rompe al girar.

### Acciones del jugador
- `regar` con `vfx-gotas`.
- `plantar` (`crouching`).
- `cosechar` (`picking-up`) seguida de `oler` y `vfx-brillo`.
- `cruzar` (mirando por el microscopio, dirección norte) con `vfx-polen`.
- `vender` con `vfx-monedas`.

### Combate
- **Jugador de espaldas:** `idle` (`fight-stance-idle-8-frames`), `golpe` (`cross-punch`), `patada` (`high-kick`), `spray` (v3) con `vfx-spray`, `comer`, `herido` (`taking-punch`) y `desmayo` (`falling-back-death`).
- **Ladrones:** `idle`, `ataque` (`lead-jab`), `herido` con `vfx-golpe`, y `huir` al perder.
- **Policía:** `alto`, `multa` (al requisar), `soborno` (cuando SOBORNAR sale bien) y `perseguir`.

## 7. Integración en el motor (F2) — hecha

Desde la 1.3 el juego ya sabe usar sprites: en cuanto exista `assets/sprites/atlas.png` + `atlas.json`, `npm run build` los mete dentro del HTML y el juego los usa. Lo que no esté en el atlas se sigue dibujando por código, así que se puede ir fase a fase.

**Build** (`tools/build.js`): con atlas genera `const ATLAS = { png: 'data:image/png;base64,…', def: {…} }` en el hueco `//@@ATLAS@@` de `src/shell.html`; sin atlas, `const ATLAS = null`. Acepta `--atlas-dir` y `--salida` para compilar pruebas sin tocar el `index.html` de la raíz.

**`atlas.json` (versión 2)** lo escribe `procesar.js --atlas` con todo lo que el motor necesita: `frames`, `celdas`, `anims` (fps, bucle, celda propia y `sobre`), `rampas`, `rampas_cambio`, `cubre` (clave del juego → grupo), `ambiente`, `fumador` y `menores`.

**`src/js/01b-arte.js`**
- `arteListo()` carga la imagen una vez y recorta cada fotograma a un canvas en caché.
- `frameDe(grupo, sprite, dir, t, {i | ph | fps, bucle})`: el fotograma por índice, por fase del ciclo o por reloj. Si falta una dirección, usa la más cercana; este y oeste se sacan en espejo.
- `dibujar(…)` y `pinta(…)` aplican el ancla de la celda; `conRampa(canvas, mapa, id)` cambia colores exactos con caché.
- **Personajes** (`dibujarPJ`): celda 32 × 32 en (px − 8, py − 15), sombra del motor, `walk`/`run` sincronizados con el paso (un ciclo cada 2 casillas), `idle` con fase propia por NPC. Clientes y ladrones aleatorios se reparten en las 6 y 3 familias del atlas.
- **Ambiente** (`ambiente`): solo con el NPC quieto, en pantalla y sin diálogo; al hablarle se corta. Los fumadores sueltan su VFX de humo en `frame_humo` desde `offset_boca`; sube 1 px cada 3 fotogramas y en la calle el viento lo lleva. Un grupo de `menores` nunca hace acciones de fumar aunque el atlas las traiga.
- **Jugador** (`accion(nombre, vfx)`): regar, plantar, cosechar + oler, cruzar y vender, con su VFX. Devuelve una promesa que acaba con la animación (inmediata sin atlas), así que los guiones esperan.
- **Mundo:** tiles por clave, tiles animados por reloj en bloques de 2 × 2 casillas, hierba pisada al entrar, orillas Wang sobre el agua, la tierra y la plaza que tocan hierba (`arteOrilla`), objetos de 1 casilla en el suelo y los altos ordenados por Y (tapan al jugador si está detrás), edificios como una pieza encima de sus casillas con la puerta abierta al pasar, carpa, bolsa de los objetos, paloma junto a Patxi y gaviotas en el muelle.
- **Plantas** (`artePlanta`): fase desde el atlas, balanceo en vegetativo, floración y lista, cogollos del color de la variedad (rampa magenta → `STRAINS[k].c`), rampa seca sin agua y ácaros con plaga.
- **Combate:** fondos, jugador de espaldas y rival desde el atlas; `bAnim(quién, nombre)` dispara golpe, patada, spray, comer, herido, desmayo, ataque, huida, alto, multa, soborno y persecución desde `13-combate.js`, con `vfx-golpe` y `vfx-spray`.
- **Reserva:** si una clave no está en el atlas, se usa el dibujo procedural. `?arte=procedural` en la URL ignora el atlas para comparar.

**Pruebas:** `npm test` (38/38 sin atlas) y `npm run test:arte`, que calca el arte procedural a `art/crudo`, lo procesa, compila el juego con ese atlas en `tools/salida/arte/` y comprueba 19 cosas (el título del atlas y las orillas entre ellas) y un atlas parcial (solo el player y sin «east»). Con el atlas de calco la historia completa también da 34/34, y las capturas salen casi idénticas a las procedurales: así se sabe que las anclas cuadran antes de gastar un crédito.

## 8. QA y criterio de aprobado

**Automático** (`procesar.js`):
- 0 errores;
- ≤ 15 colores (o los `max_colores` del asset);
- todo dentro de la celda;
- pies estables (≤ 2 px de deriva en `base`, `idle`, `walk` y `run`);
- sin semitransparencias ni píxeles sueltos;
- después del bloqueo, 100 % en paleta.

**Visual** (Claude Code abre el PNG ampliado junto a su referencia):
1. La silueta se lee a tamaño real (1×).
2. El contorno es continuo y sin huecos; la luz viene de arriba a la izquierda.
3. La proporción cabeza/cuerpo es la del protagonista aprobado.
4. Los colores de identidad se reconocen: a Baltasar se le identifica por el traje morado.
5. La escala es igual que la de sus vecinos: ningún NPC más alto que una puerta.
6. Los tiles en mosaico 3 × 3 no tienen costuras.
7. No hay texto, marcas ni nada que recuerde a un personaje de otro juego.
8. Las animaciones hacen bucle limpio, sin saltos del primer al último fotograma.
9. Ningún menor fuma, vapea ni sale junto a drogas.

**Herramientas de PixelLab para arreglar en vez de regenerar**:
- `pixelart_workbench`: `lint <id>` para defectos, `score <id>` para la puntuación de disciplina 0-100 y `repair <id>` para limpiar. Gratis con suscripción.
- `correct_pixelart` (0,1 generaciones) para bordes y píxeles sueltos, con todos los fotogramas en una sola llamada.
- `reduce_colors` con `palette_image_base64` (o `palette_image_url`) = `art/paleta/ribera.png` (0,1 generaciones) para unificar la paleta de una animación entera.
- `inpaint_image` para rehacer una zona.
- `save_to_asset` para guardar el arreglo en el personaje u objeto de PixelLab.

**Global**: capturas antes/después de cada fase, `npm test` 38/38, `npm run build` y peso del HTML final.

## 9. Presupuesto

**Costes documentados por PixelLab**
- `create_character` estándar: 1 generación.
- Animación con plantilla: 1 por dirección.
- Animación `v3`: unas 1 por dirección a ≤ 64 px y 8 fotogramas.
- `create_1_direction_object`: 20-40 (pero da 64 candidatos a ≤ 42 px).
- `create_image_pixflux`: 1.
- `create_topdown_tileset`: 1-4 (media ≈ 3).
- `reduce_colors` y `correct_pixelart`: 0,1.

**Sin coste publicado:** `create_tiles_pro`, `create_building_kit`, `create_map_object` y `animate_object`. Mide el saldo antes y después de la primera llamada y apúntalo en `coste_real`.

**Total con coste conocido:** unas **410 generaciones**; `npm run sprites:validar` y `npm run sprites:catalogo` lo recalculan.

**Ahorro**
- **Lotes compartidos** (`manifest.lotes`): iconos + VFX de 16 px en una llamada y plantas + nevera/cama + cogollos + VFX de 32 px en otra. Ahorran ~120 generaciones frente a una llamada por asset.
- `create_tiles_pro` con los tiles numerados en la descripción: todo el exterior en una llamada.
- Usa plantillas antes que `v3`.
- No regeneres lo aprobado.
- Guarda la `seed` en las herramientas que la aceptan (`create_tiles_pro`, `create_building_kit`, `create_image_pixflux`, `animate_image`). Las demás no tienen semilla: guarda sus ids para no regenerar.
- Evita `mode: "pro"` y `create_character_state` (20-40 cada uno): el «fumar» es una animación, no un estado nuevo del personaje.

## 10. Problemas típicos

| Síntoma | Causa y solución |
|---|---|
| Imagen rota o a medias | El cliente MCP recortó el base64. Usa imágenes pequeñas, `data:` URL o https. |
| La animación solo tiene la dirección sur | En `v3` es lo que pasa por defecto. Pasa `directions` y, para completar después, `animation_group_id` + el mismo `animation_name`. |
| Un fotograma de más | `keep_first_frame: true` añade la rotación como fotograma 0. Quítalo o usa `false`. |
| El lienzo de la animación es más grande que el del personaje | Normal en `v3`, porque la silueta agranda el lienzo. `procesar.js` lo encaja por los pies. |
| Colores distintos entre fotogramas | `reduce_colors` con todos los fotogramas en una llamada y `palette_image_base64` del juego. Después, `procesar.js`. |
| Llega ampliado (píxeles de 2×2 o 4×4) | En celdas `exacto`, `procesar.js` lo reduce solo si el múltiplo es limpio. Si no, redúcelo en local por vecino más próximo o regenera al tamaño de la celda. `unzoom_image` no sirve para sprites: pide como mínimo 256 px y devuelve fondo opaco. |
| Cara distinta en cada dirección | `create_character` con `mode: "v3"`, `reference_image_base64` de la rotación sur aprobada y `size: 32`. |
| `select_object_frames` pendiente | Los objetos con `size ≤ 170` quedan en revisión hasta que eliges. |
| Trabajo atascado | `list_jobs` y `cancel_job`. Según PixelLab, los tilesets fallidos no se cobran; en lo demás, mira el saldo antes y después. |
| Fuera de celda en `procesar.js` | El sprite es demasiado grande para su celda. Regenera con un `size` menor o pide «fits in a 32x32 tile». En combate, si solo un fotograma sube 1-2 px por encima (un bote del `idle`), bájalo lo justo en el crudo. |
| `keyframe image is incomplete` / `did not decode` | El base64 se copió mal (no siempre es el cliente). Cuantiza el PNG en paleta (`convert in.png -colors 24 -define png:color-type=3 -strip out.png`, 300-1200 bytes), imprímelo en líneas de 80 caracteres y cópialo línea a línea. `-strip` quita el alfa: el fondo vuelve negro y hay que vaciarlo después. |
| Casa estrecha con `create_map_object` o `create_image_pro` | Salen de ~76 px y no cubren una huella de 112. Usa `create_image_pixflux` img2img con la huella procedural (el edificio del calco) como `init_image` e `init_image_strength` 30: redibuja todo a lo ancho y deja la puerta en su columna (150/100 apenas cambia nada). |
| `create_building_kit` no encaja | Da piezas de 24×42 en perspectiva con suelo de 16×12: no casan con la rejilla cenital de 16 px. Paredes y suelos de interior con `create_tiles_pro` y referencias. |
| Caja opaca en un fotograma de VFX | `animate_object` a veces devuelve un fotograma con fondo: vacía por relleno lo que toca el borde (si hay ≥ 8 píxeles opacos en el borde). |
| Descarga de un objeto sin animación no es un zip | `objects/<id>/download` devuelve el PNG directamente cuando el objeto no tiene animaciones. |
| Un objeto trae lo que no es (gancho, bola de fuego) | La acción se lee literal: «hook punch» le dio un gancho en la mano. Quita la palabra y añade «empty hands, no effects». |

## 11. Comando de Claude Code

`/sprites F1`, `/sprites kiko`, `/sprites estado`… El comando (`.claude/skills/sprites/SKILL.md`) lee esta guía y el manifiesto, comprueba el saldo, recorre los assets pendientes de la fase con el bucle de la sección 4 y se para en las puertas (F1 la apruebas tú). Funciona igual en **modo absoluto**: trabaja en silencio y cierra con el bloque ✅ COMPLETADO.

## 12. Lista de cierre

- [ ] `npm run sprites:validar` → 0 errores y `npm run sprites:catalogo` → todas las claves
- [ ] Todos los assets de la fase en `aprobado`, con `pixellab` (y `seed` si la herramienta la acepta) y `coste_real`
- [ ] `npm run sprites:procesar -- --todos --atlas` → `ATLAS OK`
- [ ] `npm run build`, `npm test` 38/38 (con y sin atlas), `npm run test:arte` 22/22 y `npm run capturas` revisadas
- [ ] `CHANGELOG.md` actualizado y capturas nuevas en `screenshots/`
