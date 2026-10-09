# Strainmon — CLAUDE.md

## MODO ABSOLUTO (directiva de trabajo por defecto)

Cuando el usuario escriba `[MODO:Absoluto]` (o pida "modo absoluto"):

Rol: Ejecutor final.

Reglas:
1. Cero charla / saludos / confirmaciones.
2. Salida = SOLO producto final 100% terminado.
3. PROHIBIDO emitir mensajes intermedios.
4. Excepción: bloqueo crítico → preguntar máx. 1 línea.
5. Estilo: frases ultracortas, máxima densidad técnica.
6. Aviso de progreso `(trabajando · NN.N %)`: % calculado por script con sub-pasos
   (cada llamada o job cuenta), estrictamente creciente. Nunca repetir un % ni escribirlo
   a mano; si el estado no cambió, no se emite.

Variante `[MODO:Ejecutor_Absoluto]` (auditoría/refactor): mismas reglas + salida =
informe técnico directo + código refactorizado, sin relleno.

## Restricciones de propiedad intelectual (siempre)

- Prohibido usar assets/código de terceros con copyright: sprites de Pokémon,
  código de Habbo/Sulake, descompilaciones (p.ej. `pret/pokefirered`), wordmark
  "Nintendo/GAME BOY" ni el lema comercial. Modificar material con copyright =
  obra derivada = sigue infringiendo.
- Permitido: homenaje de forma/layout genérico + arte y código 100% originales.
  Identidad propia: **STRAINBOY** (verde), textos propios.

## Proyecto

- Juego sandbox isométrico single-player (cultivo/cruce/trapicheo de genéticas
  landrace). Vanilla JS, `PH` namespace, sin dependencias.
- Fuentes en `src/*.js`; estilos en `assets/style.css`; entrada `index.html`.
- Build (bundle inline autocontenido): `node <scratchpad>/build.js` → `dist/PhenoHunter.html`.
- Consola: LCD 10:9 (matriz 160×144, píxeles cuadrados), modo DMG 4 tonos.
- Rama de trabajo: `claude/pheno-hunter-game-wzl06e`.

## Subproyecto `ribera-verde/`

- RPG de cultivo independiente (v1.10.0): 160 px de alto y de 240 a 400 de ancho, solo en horizontal, con mandos flotantes; piso a 1 casilla = 1 m, vista de carpa B a 60 px/m con las carpas plateadas de frente (3/4 sin atlas) y vista C (la carpa por dentro, desde la imagen A, plateada con el armazón negro como las carpas; pared solo con la tela y la luz del foco en una capa aparte, delante de todo; el foco cuelga de dos poleas a la distancia de la fase de las plantas y sube a medida que crecen; temporizador por carpa —automático, 18/6 para madres, 12/12— en la pared y en la vista; con el atlas sale siempre: todo el equipo, la muerta y los extras, dibujados a mano en `tools/sprites/a-mano/equipo_c.py`; iconos del equipo y nevera y cajas a escala en `equipo_p5.py`; sombras de los muebles y noche en el piso). Notas propias en `ribera-verde/CLAUDE.md`.
- Tests: `cd ribera-verde && npm install` y, con el Chromium preinstalado
  (`export CHROMIUM_PATH=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux/chrome | head -1)`):
  `npm test` → 84/84, 0 errores JS · `npm run test:arte` → 27/27.
- Plano de escala: `npm run plano` → `docs/plano/` (con `vista-b.png`) + `docs/PLANO.md` (opción A en la 1.8.0; vista de carpa B en P2).
- Genética (1.9.0): landraces e híbridos clásicos de `src/species.js` (solo texto e información), estabilizar F1 → F4 y banco de semillas. En la 1.10, cada variedad lleva su % índica real y su tono de hoja: de ahí salen el porte y la forma de la planta A (vista C, dibujada a mano); un cruce nuevo (sin receta) sale en un 30–70 % de la madre y cada planta varía su % índica hasta la F4.
- Economía (1.10): cifras reales (precios, W, kWh, g/W, tope por maceta y de tierra por carpa), fenotipos estrella según la pureza, esquejes, venta al por mayor, deuda de 30.000 € e imperio tras la deuda con los encargos de Baltasar.
- Guion y mapa (1.10): caja fuerte de la tía (detrás del diploma, combinación en el PC) y empotrada (PC, 380 €); capítulo 4 por 2 variedades de receta cosechadas; plazo desde Toño; robo de Darko (cap. 7); embargo al 3.er plazo vencido; cuota de Molina cada 10 días; barrio alto y astilleros (40 × 30, con `ZONAS`) y 3 interiores (casa de Txaro, comisaría, almacén); la comarca por biomas (Puerto Viejo y Valdehierro, ciudades pequeñas; Mendialde y Errotabarri, pueblos) en autobús (`PARADAS`), y el prólogo en el caserío de Mendialde. Tablas en `docs/ECONOMIA.md` (`npm run docs`).
- Calle (1.10): patrullas de policía visibles (`10b-patrulla.js`: 0-2 agentes por zona, cono de día, sigilo de noche, barra de sospecha, alarma y huida por un portal o por distancia; la policía ya no sale por paso) y rosin (prensa de Kiko, catadores, 10 + 0,6 × THC el gramo).
- Piso y móvil (1.10): clima por sala (`09c-sala.js`: mes, día/noche, calor de focos, termohigrómetro y aparatos termostato que gastan luz; fuera de rango crecen menos, moho con humedad en flor), riego automático en dos niveles (garrafas por maceta, 15 €, media cosecha; goteo por carpa, 1.200 €, unas cinco cosechas con la carpa llena), que se rellenan, mochila con tope (1/3/10 kg) y arcón en casa (el control no lo ve; la redada sí, no la caja), y el móvil en START (`12b-movil.js`: llamar a Kiko/Toño/Iñaki y a la agenda de clientes, pedir a Kiko +15 % con entrega al día siguiente, SMS). Salón (1.10, `12c-salon.js`): piso de 18 × 8 con el salón a la derecha (sofá, tele de 43" y PC gaming, arte a mano en `tools/sprites/a-mano/salon.py`) que se compran en la tienda online (ordenador de la tía, PC gaming o móvil) y llegan al día siguiente; el menú START con iconos y el día, la hora y el dinero arriba; el botón MÓVIL (tecla P) abre el móvil de un toque; los avisos no pisan el HUD, la ficha de la carpa ni SONIDO; los iconos de los menús, centrados en la línea y a un múltiplo entero de sus píxeles (pixel perfect), con el cogollo de la Genoteca redibujado a mano; el techo de las carpas del piso a medio fondo (`tools/sprites/a-mano/carpas_mapa.py`). Siguiente tanda: ropa/pelo; después, local clandestino de setas.
- Análisis (1.10): guion y misiones, probabilidades de ladrones, controles, soborno, calor, redada y Copa en las tres zonas, y la caja fuerte (jugada) en `docs/ANALISIS.md` (`npm run analisis`: modelo exacto, comprobado con las funciones del juego salvo la tabla de la caja; sale con 1 si no cuadra).
- Mundo orgánico (1.10): árboles y monte corridos y en espejo por un hash de casilla (`hashT`, igual en Godot), detalles en la hierba, firmes con variantes (hormigón, pista de tierra, asfalto roto), bordes irregulares (`linde`, `bosque`) y casas de varios tamaños; Mendialde 48 × 34 con partes y afueras, Errotabarri por pista. Arte a mano en `tools/sprites/a-mano/mundo.py`.
- Android: `npm run apk` → `dist/ribera-verde.apk` (WebView + index.html, `sensorLandscape`; sin Android SDK, ver `ribera-verde/CLAUDE.md`).
- Godot (`ribera-verde/godot/`, 0.4.0, la app de Android que se publica): el juego entero portado a Godot 4.3, con icono propio, aviso de edad, OPCIONES, CRÉDITOS (licencias y privacidad), Atrás = pausa y mandos de 48 dp (`docs/NORMAS-MOVIL.md`; ficha de Play en `docs/PLAY.md`), y comparado con el HTML: historia 1 → 8 (`tests/historia.gd`, 84 pasos, 0 diferencias), 29 pantallas píxel a píxel (`tests/pantallas.gd`, con el piso de noche), vista C (`tests/prueba.gd`, C1 y C2), capas (`tests/capas.gd`) y una partida jugada con los mandos desde el título (`tests/ciclo.gd`, con `--fixed-fps 60`); `npm run godot` saca del HTML datos, arte, oráculos y pantallas, y `npm run godot:apk` → `dist/ribera-verde-godot.apk` (`com.riberaverde.godot`, no va al repo). Ver `ribera-verde/CLAUDE.md`.
- Sprites: MCP `pixellab` en `.mcp.json` (raíz; habilitado en `.claude/settings.json`), token en la variable `PIXELLAB_TOKEN`,
  nunca en el repo. En sesiones cloud exige `api.pixellab.ai` en los dominios permitidos.
