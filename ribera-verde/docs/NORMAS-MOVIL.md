# Ribera Verde para móvil: normas básicas de un juego de Android

Repaso de la app de Godot (`com.riberaverde.godot`, 0.4.0) contra lo que se espera de un juego para móvil: las guías de calidad
de Android (Core app quality, Material: zonas táctiles, botón Atrás, ciclo de vida) y lo que pide Google Play. Lo de la tienda
(ficha, clasificación, privacidad, AAB y clave) está en [PLAY.md](PLAY.md). Cada punto dice dónde está y qué lo comprueba
(`godot/tests/ciclo.gd` es la partida jugada con los mandos: `ciclo: 0 fallos`).

✅ cumple · ➖ cumple con una salvedad · ⏳ no se puede hacer desde aquí (ver PLAY.md § 5)

## 1. La app

| Norma | Estado | Dónde / cómo se comprueba |
|---|---|---|
| Icono propio, clásico y adaptativo (Android 8+), sin recortes con ninguna máscara | ✅ | `tools/sprites/a-mano/icono.py` → `art/icono`; la hoja va entera dentro del círculo seguro de 66 dp (a 18,6 de 22 px de radio); `art/icono/vista.png` lo enseña con máscara redonda, de ardilla y cuadrada |
| Pantalla de arranque propia, sin el logo del motor | ✅ | `godot/arranque.png` sobre el fondo del juego (`boot_splash` en `project.godot`) |
| Nombre y versión visibles y coherentes | ✅ | «Ribera Verde», 0.4.0 (código 6) en `project.godot`, `export_presets.cfg` y los créditos |
| Sin permisos que no use | ✅ | ninguno (`permissions/*` vacíos; lo comprueba el APK desempaquetado) |
| 64 bits | ✅ | arm64-v8a |
| Horizontal con el sensor, pantalla completa inmersiva, muescas | ✅ | `sensorLandscape`, `immersive_mode`; los mandos y la pantalla dejan los márgenes seguros (`_zona_segura`) |
| Sin conexión, sin anuncios ni compras | ✅ | no usa la red |
| AAB, `targetSdk` actual y clave de subida | ⏳ | PLAY.md § 5 |

## 2. Ciclo de vida y guardado

| Norma | Estado | Dónde / cómo se comprueba |
|---|---|---|
| Guardado automático, sin perder nada al salir | ✅ | al cambiar de capítulo, al dormir, desde START y al pasar a segundo plano o cerrar (`APPLICATION_PAUSED`, `WM_CLOSE_REQUEST`); a un archivo aparte y luego se cambia de nombre (no se corrompe si se corta) |
| Al volver a la app, en pausa | ✅ | `APPLICATION_RESUMED` andando por el mapa abre el menú START, con el reloj del juego parado (ciclo: «al volver a la app, en pausa») |
| Nada se queda apretado al perder el foco | ✅ | `suelta_todo` (ciclo) |
| Continuar la partida desde el título | ✅ | CONTINUAR (ciclo) |
| Borrar la partida desde el juego | ✅ | título · OPCIONES · BORRAR PARTIDA, con confirmación |

## 3. Botón Atrás

| Situación | Qué hace |
|---|---|
| Diálogo, menú, carpa o texto largo abiertos | Es B: cierra o vuelve (ciclo) |
| Andando por el mapa | La pausa: abre el menú START; Atrás otra vez la cierra (ciclo). Antes guardaba y cerraba la app de golpe |
| En el título | Sale de la app |

## 4. Mandos y lectura

| Norma | Estado | Dónde / cómo se comprueba |
|---|---|---|
| Zonas táctiles ≥ 48 × 48 dp (7,6 mm) | ✅ | cruceta de 24 mm con 3 mm de margen; A y B de 10,5 mm; START, MÓVIL y SONIDO se ven de 15 × 7 mm pero se tocan en 48 dp como poco, sin comerse el menú o el diálogo que tengan debajo (`mando_en`; ciclo: «START se toca en 48 dp») |
| Donde descansan los pulgares, sin tapar el juego | ✅ | `geo_mandos` (en mm); ciclo con 6 tamaños de ventana |
| Varios dedos a la vez, deslizar por la cruceta | ✅ | ciclo |
| Texto legible | ✅ | Atkinson Hyperlegible (hecha para baja visión); el texto de los diálogos nunca baja de 13 dp (10 px de juego a 1,3 px como poco) |
| Velocidad del texto | ✅ | OPCIONES · TEXTO: normal, rápido o al momento; tocar la caja acaba el texto |
| Filas de los menús | ➖ | se eligen con la cruceta y A; tocarlas también vale, pero miden menos de 48 dp en móviles pequeños (es un juego de píxeles con cruceta: no se cambia el diseño) |

## 5. Sonido

| Norma | Estado | Dónde / cómo se comprueba |
|---|---|---|
| Silenciar en un toque | ✅ | el mando SONIDO (ciclo) |
| Volumen de la música y de los efectos por separado | ✅ | OPCIONES · MÚSICA / EFECTOS, de 25 en 25 % (ciclo) |
| Se recuerda al volver a abrir | ✅ | `user://ajustes.json` |
| Se calla en segundo plano | ✅ | Android pausa la app y su audio |

## 6. Contenido, créditos y licencias

| Norma | Estado | Dónde / cómo se comprueba |
|---|---|---|
| Aviso de edad (+18) la primera vez | ✅ | `aviso_edad` (juego.gd): ficción, mayores de 18, cannabis delito en muchos países; «SALIR» cierra la app (ciclo) |
| Créditos | ✅ | título · CRÉDITOS: autor (Eddie), versión, herramientas, arte, música, fuentes y el aviso de ficción (ciclo) |
| Licencias de terceros enteras | ✅ | título · CRÉDITOS · LICENCIAS: la MIT de Godot, las OFL de las dos fuentes y las licencias de las bibliotecas que lleva Godot (`Engine.get_license_text`, `get_copyright_info`, `get_license_info`), con scroll y por páginas para que abran al momento (ciclo) |
| Privacidad | ✅ | título · CRÉDITOS · PRIVACIDAD y `docs/PRIVACIDAD.md` |
| Sin marcas ni personas reales; arte y código propios | ✅ | normas del repo (CLAUDE.md) |
| Ningún menor fuma | ✅ | `sprites:validar`, `procesar.js` y el motor |

## 7. Lo que queda fuera

- La versión web (`index.html`, el Artifact) no es la app: tiene OPCIONES en START como la de Godot (para que las pruebas
  comparen lo mismo), pero no el aviso de edad, los créditos ni las licencias.
- Publicar en Google Play: PLAY.md § 5.
