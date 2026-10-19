# Cambios

## 1.58 · Google Play (en curso, por fases del plan)

### Fase 1 · plataforma
- **Godot 4.7** (antes 4.3): el proyecto, las pruebas y la exportación; `.uid` de los scripts en el repo. Arreglos por el cambio de versión: `prueba.gd` compara los números por su valor (4.4+ escribe `1.0` donde 4.3 escribía `1`) y `paginas()` de `ui.gd` cuenta los saltos de línea y parte las líneas de más de 3.500 letras (una página de las licencias salía de 3.501).
- **AAB con la plantilla Gradle** (`tools/godot-aab.js`, `npm run godot:aab`; sustituye a `godot-apk.js`): paquete `com.landracehunters.game`, targetSdk 36, minSdk 24, arm64-v8a y armeabi-v7a, icono monocromo de Android 13, iconos por vecino más próximo dentro del AAB, firma con la upload key (variables `LH_KEYSTORE*` o `LH_ENV`, la keystore fuera del repo; se niega a usar una dentro) y comprobaciones: páginas de 16 KB (`zipalign -P 16` y `readelf` en las `.so` de 64 bits) y targetSdk 36 en el manifiesto. Saca también el APK universal con bundletool para probar en el móvil.
- **Música e iconos versionados** (`godot/musica/`, `godot/icono/`): ya no hace falta regenerarlos para exportar.
- **Batería entera** en `tools/tests.sh` (`npm run test:godot`), con las banderas de cada prueba (`mandos_geo` a 2600 × 1700 y `--sin-arranque`, `pantallas` con sus referencias, `ciclo` con `--fixed-fps 60`). Línea base en `.modo-absoluto/base.txt`.

### Fase 2 · identidad y cumplimiento
- **`Datos.PLAY`** (por defecto `true`, la versión de la tienda): los cambios de contenido van detrás de esta constante; con `false`, el juego entero de antes (lo usan todas las pruebas contra el HTML y las de la versión entera). `datos/play.json` (lo escribe `tools/play.py`) dice qué cambia: `Datos.carga` lo aplica en su sitio (las mismas listas y diccionarios, solo los textos) y lo deshace al volver a `false`; `Datos.tp()` hace lo mismo con los textos del código en los diálogos, menús y avisos.
- **Sin cifras reales de cultivo** (C1/C2): ni °C, ni micras, ni µm, ni pH en lo que se ve. El pH pasa a «corrector», «riego» o «acidez»; las extracciones, el foro, los consejos de Kiko y la pizarra, con textos de juego; en la ficha de las plantas, «riego a ojo / a medias / bien» en vez de la EC y el pH.
- **Los híbridos con nombre propio** (C5): 54 cruces con nombre de marca o de persona pasan a nombres inventados (Ría Uno, Ondarra, Ipar, Leyenda, Escarcha…), también dentro de los textos; las landraces, igual.
- **Sin el bajo de las setas** (C3): ni Txomin, ni su SMS, ni la línea del mapa, ni el cartel; la puerta gris queda cerrada y el sótano no sale en la tienda online.
- **El billar, sin apuestas** (C4): «Una partida» o «Nada», sin euros.
- **Fuera los restos de otro juego** (C6): `pk-*` → `mo-*`, `exterior-pk` → `exterior-mosaico`, `PK_TILE` → `MOSAICO_TILE` (en el código, el atlas, el arte y los documentos), y con PLAY la cortinilla del combate en persiana de lamas verticales.
- **El aviso de edad nuevo** (C7) y **la copia de seguridad de Android** (U8, `user_data_backup/allow=true`); el texto de PRIVACIDAD del juego lo dice.
- **`store/`**: política de privacidad (es + en), formulario de seguridad de los datos, cuestionario IARC, fichas en español e inglés (`tools/ficha.py` las mide), icono de 512, gráfico destacado de 1024 × 500 y 8 capturas de 1920 × 1080 sacadas del juego con PLAY (`tests/capturas.gd`).
- Prueba nueva `tests/play.gd` (27): ningún texto de los datos ni del código con cifras reales, los nombres nuevos y ninguno viejo, ida y vuelta de PLAY, sin setas, el billar, el aviso y la copia de seguridad.

### Fase 3 · bugs E1–E14
- **Guardado seguro** (E1, E2): `escribe_partida` escribe el `.tmp`, comprueba el error de escritura y lo vuelve a leer antes de cambiarlo por la partida; la de antes pasa a `.bak`. `load_save` prueba la partida y, si está rota, cortada o no pasa `partida_valida`, la `.bak`.
- **La casilla al cargar** (E3): `casilla_libre` busca por BFS la casilla libre más cercana dentro del mapa y que se llegue andando desde una salida (nunca la salida misma); si la guardada está libre, se queda.
- **Sin guardar a medias** (E4–E6): `guarda_al_salir` (al pausar o cerrar la app) no guarda con un guion en marcha (`lock > 0`) ni fuera del mapa o la carpa (el combate); la redada y el plazo vencido (con el embargo, `embargo_aplica`) cambian `S` antes del primer aviso, así que cerrar a mitad no los repite ni los pierde.
- **Los avisos de la cola se guardan** (E7): `queue(k, fn, av)` guarda el texto de cada aviso (`_cola` en la partida, `cola_guardar`/`cola_cargar`); los que se calculan (plazo, calor, historia, misión, logro, itinerario) se vuelven a encolar por su nombre.
- **Importar** (E8–E10): `partida_valida` mira el tipo de cada clave de `new_state()` y los rangos de `day`, `min` y `ch`; la caja de texto es de varias líneas con PEGAR (el portapapeles solo al tocarlo), con tope de 1 MB (`IMPORTA_MAX`); importada en partida, se abre al cerrar los menús (`relanza`, `relanzar`), como CONTINUAR (con `Datos.CAL`; sin él, en caliente como en la 1.22, para la historia contra el HTML).
- **START cierra el móvil** (E11), **los céntimos no se pierden** al pagar la luz (E12), **`pop(fn)` quita su manejador** y no el de arriba (E13, `type_text`) y **fuera «en este navegador»** (E14).
- START (la pausa) guarda antes de abrir el menú.
- Prueba nueva `tests/bugs.gd` (29 comprobaciones: una o más por bug, que fallaban antes del arreglo).

### Fase 4 · rendimiento (R1–R15)
- **Medidas** (`tests/perf.gd`, fuera de la batería; `.modo-absoluto/perf-base.txt` → `perf-final.txt`, 1280 × 720 en Xvfb con GL por software): draw calls en la calle 407 → 112 (−72 %); con el menú START abierto, 446 → 66 y 1,00 → 0,00 redibujos por fotograma; memoria estática tras recorrer las escenas 143 → 110 MB, +0,1 % de la 1.ª a la 4.ª vuelta; escala a 720p 3,933 → 3 (entera); arranque 262 → 259 ms en escritorio.
- **R1 + R8, el atlas en hojas de GPU** (`atlas.gd`): el atlas de 1024 × 4168 sube en dos texturas de ≤ 4096 (`HOJA_MAX`, `hojas`, `hoja_y`) y cada fotograma y su espejo quedan registrados con su recuadro (`reg`, `_registra`); `Atlas.dibuja` pinta con `draw_texture_rect_region` (el espejo, con el ancho de destino negativo) en vez de una textura por fotograma. La imagen de CPU se queda: la usan los recoloreados de ropa y genética.
- **R2, pintar solo si cambia** (`juego.gd`, `lienzo_quieto`): con el fundido en negro o un menú, el lector o la importación encima del mapa o la carpa (sin minijuego, vista ni andar), el lienzo deja de redibujarse a los dos fotogramas y su `SubViewport` pasa a `UPDATE_DISABLED`.
- **R3** el juego a 60 FPS como mucho y, con `Datos.CAL`, OPCIONES → AHORRO a 30 (`aj.ahorro`); solo en la escena del juego, no en las pruebas. **R15** `hud_pon` no rehace el HUD si no ha cambiado nada (`hud_ultimo`).
- **R4** los colores de texto leídos una vez (`_css`). **R7** tope en todas las cachés (`Atlas.tx`, `Arte.cache`/`texs`, `Procedural.cache`, la del pintor): al pasar el tope se vacían y se rehacen al pedirlas.
- **R10, la música** (`sonido.gd`): los OGG se leen cuando tocan, no todos al arrancar (`hilo_vivo`: el hilo vuelve si se pide otra canción después de acabar); en memoria, solo la que suena y la que se apaga.
- **R11** a escala entera (×2 o más) siempre con `Datos.CAL` (720p → ×3, con bandas). **R12** en el móvil, la zona segura se vuelve a mirar al volver a la app y cada segundo (giros, recortes). **R13** al perder el foco en el móvil, el juego se para y se calla, y vuelve como estaba. **R14** mando: cruceta y palanca izquierda, A, B, START, BACK (= B) e Y (el móvil) (`BOTONES_JOY`, `_joy`).
- Sin hacer: **R5** (el balanceo de las plantas por shader: es un recorte por filas del sprite, no una deformación, y el lienzo ya no se redibuja con los menús), **R6** (`vista.gd` no pinta píxel a píxel: las plantas salen de `Procedural.planta34`, en caché por su clave de alto) y **R9** (el arranque entero ya está en ~0,26 s en escritorio, de ellos ~0,14 s el sonido con sus efectos; la música va en su hilo). El arranque en frío en el emulador x86_64 no se ha podido medir aquí (sin KVM).

### Fase 5 · primera hora, economía, texto y accesibilidad (U1–U5)
- **Arranque corto** (`new_game_corto` en `juego.gd`, con `Datos.PLAY` y `Juego.FTUE_CORTO`): sin el prólogo de Mendialde, Kiko pregunta el nombre y apareces en el piso delante del armario, con 3 semillas de Skunk #1, el abono, la carta en dos líneas y el SMS de Kiko; la carga dura 0,5 s (antes 3,6). Una flecha amarilla sobre el objetivo del capítulo 1 (`objetivo_xy`, `pinta.gd`). Prueba nueva `tests/ftue.gd`: de NUEVA PARTIDA a la semilla plantada, 20-29 s para una persona (≤ 90).
- **Economía simulada** (`tests/economia.gd`, `tools/economia.sh` → `docs/ECONOMIA-SIM.md`): tres jugadores (prudente, medio, torpe) con el motor de cultivo de verdad. Con `Datos.PLAY`: días de plazo `PLAZO_DIAS` 12/16/24 (antes 7/10/7), el recargo sobre lo que pedía el plazo (sin interés compuesto) y como mucho `RESCATE.tope` (50 %), el rescate de Toño al primer impago (la mitad de recargo y `RESCATE.dias` más) y el embargo como mucho una vez por capítulo (`S.emb_ch`). Resultado con 4 semillas: el medio paga los tres plazos a tiempo; el torpe, tras el rescate, se recupera y acaba la deuda sin embargos.
- **Texto** (`ui.gd`): −42 % de cajas en los capítulos 1-3 (95 → 55, contando el arranque corto; `RECORTE` en `datos.json` quita 15 líneas de relleno), A mantenida pasa el texto y las cajas solas (`RAPIDO_MS`) y START → REGISTRO enseña las últimas 80 cajas (`registro`).
- **OPCIONES de accesibilidad**: TAMAÑO DE TEXTO S/M/L (nunca por debajo de 14 sp, `fs_txt`), ZURDO (la cruceta a la derecha y A/B a la izquierda), DALTÓNICO (gota y marca de lista junto a las barras de las plantas, `Vista.DALTONICO`) y SIN DESTELLOS (sin parpadeo de las barras, del enemigo golpeado, del temblor ni del relámpago, `Vista.CALMA`).

### Fase 6 · retención y métricas (U7, U10, U11), con `Datos.PLAY`
- **Progreso offline** (`retencion.gd`: `minutos_fuera`, `crece_fuera`, `fuera_desde`): al volver o al CONTINUAR, las plantas crecen el tiempo real que estuviste fuera (`OFFLINE.min_h` minutos de juego por hora, tope `OFFLINE.tope_h` = 8 h) sin sed, plagas ni muertes; el reloj y la deuda no corren. Desde `OFFLINE.aviso` minutos, la pantalla «MIENTRAS ESTABAS FUERA» (cuántas crecieron y cuántas están listas). `S.ts` se guarda con la partida.
- **Aviso de cosecha** opcional (OPCIONES · AVISO DE COSECHA, apagado): al salir, una notificación local para cuando la primera planta esté lista (`seg_cosecha`); `POST_NOTIFICATIONS` se pide solo al activarlo.
- **Objetivos diarios** (`DIARIOS` en `datos.json`; START → OBJETIVO → DIARIOS): tres al día, rotando por la fecha, con un abono por cada uno.
- **Demo + compra única** (`COMPLETO`): los capítulos 1-3 gratis; al pagar el plazo del capítulo 3, «FIN DE LA DEMO» con «Comprar el juego completo» (`juego_completo`, no consumible) o «Más tarde» (START → JUEGO COMPLETO). Sin ventajas de pago.
- **Play Games v2**: los 27 logros (`datos/play_games.json`, 1000 puntos) y CARGAR DE LA NUBE en COPIA DE SEGURIDAD (se sube al salir).
- **Informes de errores** (OPCIONES · INFORMES DE ERRORES, opt-in): Sentry sin PII y eventos del embudo de la primera hora (`evento`: capítulos, primer riego, plantar, cosecha) solo con el consentimiento.
- **Plugin Android** propio (`tools/android-plugin`, `tools/plugin-android.sh` → `godot/addons/landrace_play/bin/landrace-play.aar`; `addons/landrace_play/export_plugin.gd` añade el AAR, Billing 7.1.1, Play Games v2 20.1.2, Sentry 7.22.6 y el APP_ID). `plataforma.gd` lo envuelve y, sin él, no hace nada.
- PRIVACIDAD, `store/privacy-policy.md`, `data-safety.md`, `iarc.md`, las fichas, `store/play-console.md` (lo que hace Eddie) y `store/logros-play-games.csv`. Prueba nueva `tests/retencion.gd` (41 comprobaciones: 0 h, 3 h y 30 h → tope; logros 27/27; compra cancelada, más tarde y hecha).

### APK de la tanda Play · Godot 0.48.0 (código 67)
- `node tools/godot-aab.js` con la upload key: `dist/landrace-hunters.aab` (79 MB, firmado) y el APK universal (176 MB: las `.so` sin comprimir por los 16 KB).
- `descargas/LandraceHunters.apk` (85 MB, para instalar a mano; GitHub no admite más de 100 MB): `tools/apk-instalar.py` pone `extractNativeLibs=true` y comprime las `.so`; después `zipalign -P 16` y `apksigner` con la upload key. Paquete `com.landracehunters.game`: hay que desinstalar antes la de `com.riberaverde.godot`.

### Fase 8 · `trama.gd` y `mundo.gd` en módulos, sin cambiar el comportamiento
- `tools/partir.py` (planes `tools/plan_trama.json` y `tools/plan_mundo.json`) parte cada script en una cadena de herencia: los miembros y las funciones static se quedan en la base; cada función va al módulo de su tramo; lo que una parte anterior llama y vive en una posterior lleva un stub en la base.
- Cadena: ui → mundo → `calle` → granja → trama → `menus` → `policia` → `movil` → `venta` → `nave` → `setas` → `eventos` → retencion → juego. Ningún archivo de `src/` pasa de 2.500 líneas (antes `trama.gd` 9.438 y `mundo.gd` 3.659; ahora el mayor, `mundo.gd`, 2.216).
- Los 89 comentarios con la versión delante (`# 1.47: …`) se quedan sin ella en el código y van, por versión, a «Notas del código por versión (fase 8)», al final de este archivo.
- historia 120 pasos y vista C con 0 diferencias; batería entera en verde.

### Fase 7 · el juego en inglés
- Los textos que se ven pasan por `T()` (frase con huecos con nombre: `{n}`, `{g}`), `K()` (literal que se traduce al enseñarlo y que el código también compara) o `I18n.v()` (lo que se pinta a mano); el castellano es la clave y sale letra a letra igual que antes (las pruebas contra el HTML no cambian). Género y plural, con una plantilla por variante; nada de frases pegadas a trozos.
- `godot/i18n/strings.csv` (clave, es, en; 4.878 filas) lo hace `python3 -I tools/i18n.py extrae` desde `godot/i18n/partes/*.csv` (es,en, por script y los datos), con las variantes de PLAY (`Datos.tp`). `tools/i18n.py cuenta` cuenta los literales visibles fuera de `T`/`K`/`v`: 0 (`# i18n-no` marca lo que no se enseña).
- OPCIONES → IDIOMA (sistema, español, inglés; por defecto el del móvil: es, eu, ca y gl en castellano, lo demás en inglés). En inglés no se pasa `Datos.tp` por el texto traducido (cambiaría «Ice» o «Critical»): `I18n.vt`. Un nombre en minúscula («la skunk #1») se busca con mayúscula.
- Prueba nueva `tests/capturas_ui.gd` (combate, START, OPCIONES, diálogo, tienda, Genoteca, mochila y móvil, en castellano y en inglés, a los ppp de un móvil): 8 pantallas, 0 textos cortados. En la batería.

### Repaso de la APK de Play (lo pidió el usuario: «hay errores… faltan iconos… los nombres de las genéticas son de risa»)
- La caja de vida del jugador en el combate ya no tapa al jugador: si A, B o START la echan a la izquierda, va debajo de la del enemigo (`capturas_ui`, con los ppp de un móvil, falla sin el arreglo).
- Los nombres de las variedades en la versión de Play, parodias de los reales (una letra o el orden): Skonk #1, Limon Haize, Supra Skonk, Bluberri, Big Bod, Norzen Lights, Jak Herrer, Whyte Widou, Saur Disel, Amnesya Haize… y en mayúsculas en los avisos (JAK HERRER, SKONK #1). `tools/play.py` → `datos/play.json`; las traducciones migradas de los nombres de antes.
- La fila Vida de la MOCHILA, con su icono (un corazón a mano en `salon.py`, `iconos-menu`). Prueba nueva `tests/iconos.gd`: cada icono que piden los menús, la tienda y el equipo está en el atlas (131, 0 fallos).
- Los botones SONIDO/MÓVIL, CALOR y VIDA del HUD y del combate, en el idioma elegido.

### APK de Play con el inglés · Godot 0.49.0 (código 68)
- `node tools/godot-aab.js` con la upload key: `dist/landrace-hunters.aab` (79 MB, firmado, targetSdk 36, 16 KB en las 4 `.so`) y el APK universal.
- `descargas/LandraceHunters.apk` (82 MB, `apk-instalar.py` + `zipalign -P 16` + `apksigner`): fases 7 y 8, el repaso de la APK de Play (combate, nombres parodia, icono de la vida) y el idioma.
- En inglés tampoco sale un nombre real: las filas de PLAY sin inglés caían en la del nombre real (Northern Lights × Haze, Durban Poison); ahora Norzen Lights × Haize, Durvan Poizon y la marca Ice-o-lator como Ais-o-lator (`play.gd` recorre `strings.csv` en inglés: 12 → 0).
- Menús a toda pantalla sin aire (lo vio el usuario en la tienda): las 5 filas eran las de la pantalla de 160 px; ahora todas las que caben, y si caben todas, la caja a su alto (`capturas_ui`: 6 huecos → 0).

### Documento maestro (`docs/MAESTRO.md`), por tandas, con `Datos.CAL`
- **[10] La letra:** reserva propia para flechas, ▲▼◀▶, ★, ≈ y −.
- **[1] El personaje:** chico o chica y el cumpleaños al empezar (`S.sexo`, `S.cumple`), sin ventajas por sexo (solo cambia el aspecto); el regalo del cumpleaños una vez al año (el 29 de febrero, también); la protagonista con su sprite de PixelLab en el mapa y en el combate (`player-f`, `player-f-combate`), con boca, y la ropa cambia las mismas piezas. Prueba `tests/personaje.gd`.
- **[3] Los vehículos:** el garaje dibujado junto al piso; se viaja desde el garaje y el coche se queda en el aparcamiento dibujado junto a la parada de cada pueblo (plaza de 2 × 1), no se conduce por el mapa; el maletero por kg (con la envasadora al vacío), cura en botes con los tarros y lleva el abono a los tanques de la nave; la grúa al depósito. Fuera del garaje no hay otro sitio que el aparcamiento; con el coche más de 3 días en el mismo pueblo, cada día te pueden multar (un 35 %, 90 €, SMS del Ayuntamiento; `CONCE.multa`, `multa_aparcado`, por hash, sin el azar). Pruebas `tests/vehiculos.gd` y `tests/concesionario.gd`.
- **[5] La genética:**
  - **Los valores ocultos:** cada línea lleva 4 (`IVS`: potencia, producción, floración y resistencia, de 1 a 31; `S.iv[sid]`) y cada planta, los suyos (`f.iv`, los de su línea ± 3). Salen por hash, sin tirar del azar. Cambian el THC y los gramos (±15 %), la floración (±15 %) y el moho (±50 %).
  - **Herencia y lectura:** las semillas suben la línea a lo mejor de la planta; el cruce, a lo mejor de los dos padres y hasta 2 más (tope 31). Solo se ven con el analizador, en la ficha de la semilla.
  - **La planta rara** (`SHINY`, 1 de cada 500): cogollos morados, albinos o dorados, a su lote `sid!` (`b.sh`), que se paga ×5. Sus semillas no salen así; sus esquejes sí.
  - **La saturación** (`SATURA`): lo vendido en la calle de cada pueblo (`S.sat`) baja el precio de esa variedad hasta la mitad con 100 g; cada día se olvida un 15 %.
  - **La hierba verde** (`VERDE`, `verde`): recién cortada vale un 35 % y está seca del todo a los 4 días; curada en tarros, un 8 % más por semana, hasta 8 semanas. `calidad(b, flor)`: lo verde y la rara, solo en los cogollos.
  - Prueba `tests/genetica.gd`.
- **[2] Borrachera y colocón** (`FISIO`, `S.borr`, `S.colo`, `S.efe`): de 0 a 100, bajan con las horas.
  - **Beber** (`BEBIDAS`, 4.º número): la caña, el vino, la cerveza y la copa suben; el café, el refresco y el zumo, no.
  - **Borracho:** de 31 a 70 el paso se tuerce y al soltar sigues una casilla (`vaiven`, `deriva`); de 70 para arriba, la pantalla en triple con los colores separados (`src/vision.gdshader`); a 100 en la calle, el desmayo: 8 horas después en la parada del pueblo, sin el 30 % del efectivo ni la mitad de los cogollos y extractos que llevabas (`desmayo`).
  - **Fumar y catar** (`colocar`): sube por los mg de THC; la sativa o la índica, por el % índica de la variedad. Sativa: andas un 15 % más rápido y la policía te ve una casilla antes. Índica: andas más despacio, levantas un 30 % menos de sospecha, las extracciones tardan un 20 % menos y el curado de la mañana cunde un 25 % más.
  - En el HUD, ALCOHOL y COLOCÓN cuando los hay (`hud_fisio`). Prueba `tests/estados.gd`.
- **[4] El mundo abierto:**
  - **El puerto al raso:** el muelle (y la comarcal) con el tiempo, el atardecer, la noche y las farolas de la calle (`_al_raso` en `pinta.gd`).
  - **La botritis** (`BOTRITIS`): en flor (del 65 %), cada día la puede coger una planta de las carpas de casa: un 8 % si llueve fuera y la carpa no está sellada, un 12 % con la humedad por encima del 80 % (un 75 % menos sellada) y menos con la resistencia de su línea. Por hash, sin el azar (`prob_botritis`, `botritis_dia`). Pierde 8 de salud al día hasta morir y, cosechada, un 40 % de los gramos (`botritis_merma`). En el growshop, el fungicida (la para), el preventivo (una semana sin ella) y el kit de sellado de la carpa, al final de la tienda. La nave, no.
  - **La carretera comarcal** (`MAPS.comarcal`, 44 × 16, desde el cap. 2): de Mendialde a Errotabarri por las salidas de lado (`montar_campo`), con un claro de landraces salvajes (`CAMPO`): en verano, para esquejes; en otoño, con semillas; en invierno, nada; con tormenta o nieve no se ven; lo recogido no vuelve en una semana. Por hash semanal.
  - **El refugio** (`MAPS.refugio`): el caserío abandonado de la comarcal, con camastro para dormir y un arcón donde esconder los cogollos (`escondite`), donde no llegan ni la redada ni los ladrones.
  - **El control de carretera** (`CONTROL`): yendo en tu vehículo, lo que pesa el maletero sube la probabilidad; al pararte, huir (40 %, 55 % en moto, 75 % en el deportivo; si te pillan, te lo quitan, 600 € de multa y calor), sobornar (200 € + 1,5 €/g; menos probable con calor; si no cuela, se queda el sobre y registran), entregar la carga (sin multa) o dejar que registren, como antes (`resolver_control`).
  - `src/campo.gd` entra en la cadena entre `eventos` y `retencion`. Prueba `tests/campo.gd` (53).

## 1.57.2 · Godot 0.47.1 (código 66; plugin de WordPress 1.5.4)

Lo que pidió el usuario tras la 1.57.1 («Ha desaparecido la puerta del taller, y aún así está muy vacío, molaría meterle otro tipo de suelo en diferentes zonas… el atrezzo deja que desear o por lo menos como está usado» y «en la carretera de la pantalla de carga, que se vea alguna planta en vegetativo, alguna floración, dependiendo del punto del año… cómo sería el cultivo en exterior»). Solo Godot, con `Datos.CAL`.

- **La puerta del cuartucho del taller ya no desaparece**: al comprar una mejora estando dentro, `montar_locales` rehacía el local desde su copia y se llevaba la puerta (`PUERTAS_INT`); ahora vuelve a ponerla (`montar_puertas`) y el atrezo.
- **El suelo del taller por zonas** (`TALLER_SUELO`, `montar_taller` en `mundo.gd`; arte a mano en `tools/sprites/a-mano/taller.py`, `interior-taller`): el hormigón gris de los puestos del elevador y del foso (y del segundo elevador), con manchas de aceite y rodadas por el hash de casilla, la línea amarilla que los separa del paso, el sumidero de rejilla entre el elevador y el foso, la goma antifatiga delante del banco y del lavabo y el gres beige de la espera junto a la caja; el resto, la resina azul de antes.
- **El atrezo del taller, cada cosa en su sitio** (`ATREZO["loc-valde"]`, `taller-alto`, de frente a 16 px/m): el enrollador de la manguera del aire colgado sobre el elevador, el calendario de pared, el lavabo de acero con el papel y el jabón entre el banco y el compresor, la estantería de ruedas nuevas, el extintor con su placa, dos bidones de 200 L, el gato de carretilla y la grúa de motores junto a los puestos, el armario de herramientas grande, la silla de la espera y la máquina de café. Cada cosa con su texto (`ATREZO_TXT`); nada corta el paso.
- **El bancal de exterior en la calle de la carga y del título** (`HUERTO`, `fase_huerto`, `_huerto` en `escena_viaje.gd`): en la hierba de detrás, tres plantas en su bancal según la fecha del sistema y el calendario del norte, con las plantas de cada variedad que ya había (`plantas-vista`, `HUERTO_SM`; sin sprites nuevos, lo pidió el usuario): nada de noviembre a mediados de abril, plántulas hasta mediados de mayo, vegetativo hasta julio, floración en agosto y septiembre, cosecha hasta el 20 de octubre (la del medio, una fase por detrás) y después el bancal vacío.
- **La taberna de Puerto Viejo, toda en muebles a mano** (lo pidió el usuario: «los sprites… en el bar este del Puerto Viejo… no están para nada acorde con el estilo… Una silla tiene que ser de verdad un mueble… crea todo como muebles… que parezca que la haya creado la misma persona»; `tools/sprites/a-mano/taberna.py`, `taberna-alto` y `taberna-ancho`, a 16 px/m con la madera y el contorno del salón): la barra de pintxos con la vitrina (`barraTb`), el botellero (`botTb`), la cafetera de dos grupos (`cafeTb`), las barricas de pie (`barrilTb`), los taburetes (`taburTb`) y, en vez de la mesa con las sillas pegadas (`mesaT`), mesas de pino (`mesaTb`) con sus sillas sueltas, de cara (`sillaTs`) y de espaldas (`sillaTn`, la silla de la tía), en las que te sientas (`ASIENTOS`, `SENT_GEO`; el taburete con las piernas de la barra, `TABURETES`). Las mejoras, con su mesa y sus sillas, sin cortar el paso. La espera del taller (`sillaT`) también es asiento.
- **El atrezo del taller, a la escala del coche** (lo pidió el usuario: «si tú ves el coche, eso tendría que ser como referencia de dimensiones… No pueden ser unos neumáticos igual de grandes que el capó»): todo medido a 16 px/m contra la rueda del coche del elevador (63 cm, 10 px). La pila de ruedas (`neumT`, `negocios.py`), tres ruedas tumbadas de 63 × 20 cm con el hueco de la llanta arriba, y una sola pila por sitio (`montar_taller` quita la segunda, que de fondo hacía una torre); la estantería de ruedas (`rackT`), 1 × 1,8 m con cuatro ruedas de canto por balda; el bidón de 200 L, 58 × 88 cm; el extintor de 6 kg, 50 cm, a 1 m del suelo; el armario de herramientas, 68 cm × 1 m; el lavabo, 60 cm; el calendario, 40 × 60 cm; la máquina de café, 80 cm × 1,8 m; el gato, 90 cm; las sillas de la espera con el asiento a 45 cm (`SENT_GEO.sillaT`). Prueba en `tests/negocios.gd` (las medidas en el atlas).
- **Las plantas del bancal, con contorno y en el estilo de la calle** (lo pidió el usuario: «no tienen el contorno para cerrar el diseño. No son del mismo estilo que los sprites… de la carretera como la acera»): las de `plantas-vista` eran las antiguas de la vista de carpa B (pintadas, sin contorno), no las de la nave ni las de casa. Ahora, dibujadas a mano (`tools/sprites/a-mano/huerto.py`, grupo `huerto-pl`, `hp<variedad>-<fase>`) con la hoja de abanico de las plantas de casa (`prim.hoja`) y su paleta, en pequeño y con el contorno verde casi negro como el árbol y el seto: índica, sativa e híbrida en cinco fases, de la plántula de 20 cm a la madura de 1,4–1,9 m con los pistilos naranjas y las hojas de abajo amarillas. Prueba en `tests/viaje.gd` (las quince, a 16 px/m y creciendo).
- **Al sembrar, la semilla** (lo pidió el usuario: «sería mejor echar una semilla al plantar y al sembrar»): el gesto `sembrar` (`GESTOS`, `GESTO_DE`; `gs-semilla`, `gs-pinza-0/1` en `gestos.py`): los dedos bajan con la semilla, la sueltan en la tierra y la mano la tapa. Al plantar un esqueje, el gesto de antes, pero con el brote dentro de la maceta, delante del canto de atrás (antes se quedaba detrás).
- **La escalera del sótano baja hacia la derecha** (lo pidió el usuario: «girada… que el final se vea a la derecha del todo, no abajo»): el hueco del pasillo, de 2 × 2 casillas (`bajS1`..`bajS4` en `sotano.py`), con los peldaños en bandas del claro al oscuro y la barandilla delante.
- **La franja de la pantalla de carga**: el cielo (`_cielo`) solo llegaba a la fila 120 y entre el monte y la carretera quedaban 2 filas sin pintar, por las que se veía lo de detrás; ahora llega hasta abajo (también en el viaje).
- Pruebas: `tests/negocios.gd` (la puerta y el atrezo tras la mejora, el suelo por zonas, el arte y que se llegue a todo, también en la taberna), `tests/escala.gd` (85: las mesas, sillas y taburetes sueltos de la taberna, que te sientes, su arte; con `--pintar`, sentado en la taberna y en la espera), `tests/sotano.gd` (el hueco de 2 × 2), `tests/acceso.gd` (el gesto de sembrar) y `tests/viaje.gd` (106: las fases del bancal por fecha, que no vayan hacia atrás y las plantas de cada variedad; con `--pintar`, `huerto-<mes>-<día>`).

## 1.57.1 · Godot 0.47.1

Lo que pidió el usuario tras la 1.57 («que aparezcan en la pantalla de carga los sprites reales de césped, árboles, setos, también molaría que pasasen algún transeúnte… los botones de la UI principal más pequeños, que así le da el toque más limpio… mejor que se quede de fondo la carretera andando coches y por la acera transeúntes andando, en bici, patinete»). Solo Godot, con `Datos.CAL`.

- **La calle de la carga, con el arte del juego** (`pinta_calle`, `CALLE_FIL`, `PEATONES` en `escena_viaje.gd`): la calle vista de lado y quieta, de abajo arriba: hierba, la acera de delante, la calzada de dos carriles, la acera de detrás y dos filas de hierba con setos y árboles sueltos (los mismos firmes en mosaico, el canto de la hierba, el seto en matas y los dos árboles del mapa, corridos y en espejo por el hash de casilla), y el monte y el cielo detrás. Por la calzada, los vehículos de perfil de antes; por las aceras, ocho personas: andando, en bici (pedaleando) y en patinete, en los dos sentidos. La barra, en la hierba de abajo.
- **El título, sobre la misma calle** (modo `calle` en `pinta.gd`): sigue donde la dejó la carga (el mismo reloj, `carga_t0`), en vez de la partida de fondo, con un velo azul arriba más suave para que se lean el título y el lema. Sin CAL, la partida de fondo de antes.
- **Los botones del título, más pequeños** (`TIT_WV`, `TIT_HV` en `ui.gd`): la pastilla de 84 × 12 u con la letra de 7 u (antes 132 × 17 y 9,5), en el centro de su botón, que se sigue tocando en 48 dp de alto.
- **El extracto, en el porro con tabaco** (lo pidió el usuario: «las extracciones se deberían de poder fumar también con tabaco, sin tabaco no, porque sería con la pipa»; `FUMAR.porro.grt` en `mundo.gd`): sentado, al liarte uno «Con tabaco», también salen los extractos (0,1 g con 0,7 g de tabaco); «Solo hierba», solo los cogollos, y si no llevas cogollos te dice que el extracto solo se lía con tabaco o va en la pipa, el bong o el vaporizador.
- Pruebas: `tests/viaje.gd` (92; con `--pintar`, `calle-carga-*` y `calle-title-*`), `tests/ocio.gd` (67: el extracto con y sin tabaco) y `tests/ciclo.gd` (el título con la calle de fondo).

## 1.57 · Godot 0.47.0

Lo que pidió el usuario tras la 1.56 («estos recursos se podrían usar antes de la pantalla de inicio, usarlo como de carga del juego, en una carretera sin texto, los vehículos andando y la barra cargándose. Luego aparece la pantalla de inicio START con más atrezo»). Solo Godot, con `Datos.CAL`.

- **La carga del juego** (`arranque` en `juego.gd`, `pinta_carga` en `escena_viaje.gd`, modo `carga` en `pinta.gd`): al abrir, la carretera del viaje de día, sin letras ni botones, con el utilitario, el scooter y el superdeportivo por este carril y el autobús y la berlina por el de enfrente (al revés y un poco más oscuros), cada carril a su marcha y sin montarse (`CARGA_V`, `MARCHA`, `HUECO`), las ruedas girando y, abajo, la barra que se llena en 3,6 s (`CARGA`); A, B o START la pasan; después, fundido al título. `--sin-carga` va directo al título; las pruebas que ponen `oraculo`, al título de antes (`_arranca`).
- **El título con más atrezo** (`DEMO_CAL`, `demo_coche` en `mundo.gd`): el protagonista y el poli por las aceras, dos personas más andando y el utilitario, la berlina, el scooter y el superdeportivo con su conductor por la calzada, cada uno en su carril, que entran por un lado y salen por el otro (`e.veh` en `_pj`).
- **Los tubos llegan a las carpas** (lo pidió el usuario: «los tubos no llegan a las carpas, falta 1 o 2 píxeles»): la boca se calcula con el ancla del dibujo de la carpa, como la pinta `_carpa_mapa`, y el tubo entra un píxel en el techo (`_tubos_casa`).
- **Los codos del tubo** (lo pidió el usuario: «en las curvas o giros del tubo no se deben cortar»): en cada giro, un codo curvo (un cuarto de toro de 5 px, hasta 3 px de radio por dentro, redondo por fuera) y los tramos rectos abiertos que empalman con él, sin el canto de la bajada cruzando el del techo (`_tubo_codos`, `_codo`, `_tubo(…, abierto)`).
- **Los mandos, para jugar horas** (lo pidió el usuario: «los controles tienen que ser perfectos, para poder jugar horas»):
  - un dedo que se queda colgado (Android no manda el soltar: una notificación, un gesto del sistema) ya no bloquea la cruceta ni deja A o B apretados: el toque nuevo manda y el viejo se suelta;
  - la cruceta con histéresis (`CRUZ_HISTERESIS`): al deslizar el pulgar, la flecha de al lado tiene que ganar por unos 11° pasada la diagonal, sin zigzag;
  - andando seguido, cada paso arranca con lo que sobró del anterior (`paso_sobra`): 240 ms por casilla exactos, sin tirones entre casillas (antes, 250 a 60 fps);
  - un toque de vibración al apretar cada mando (`vibra`), con OPCIONES → VIBRACIÓN (sí por defecto; permiso `vibrate` en el APK).
- **Los mandos donde caen los pulgares** (lo pidió el usuario: «que sean lo mejor para jugar con el móvil en horizontal, estudiando en qué zonas caen los dedos, por proporciones, para Android, iOS y demás»; `geo_pulgar` y `PUL` en `ui.gd`):
  - en milímetros de verdad: en el móvil y la tableta, los ppp de la pantalla (`screen_get_dpi`) en vez de estimarlos por el alto;
  - más grandes (lo pidió el usuario: «la idea es hacerlos más grandes, no más pequeños»): la cruceta de 30 mm (flechas de 10 mm) donde descansa el pulgar izquierdo, a unos 25 mm del canto y 24 del borde de abajo; A y B de 14 mm (el doble de los 48 dp de Android y los 44 pt de iOS) en diagonal por el arco del pulgar derecho, A más arriba y fuera, B más abajo y dentro, a unos 19 mm; nunca más pequeños que los de antes (`fmin`, por `geo_mandos`): en los móviles, de un 20 a un 35 % más; en la tableta, como antes o algo más;
  - nada a menos de 9 mm de los cantos de los lados (el gesto de Atrás de Android) ni de 8 del de abajo (la barra de inicio de iOS), y dentro de la zona segura (muesca, isla, esquinas redondas), midiendo el pulgar desde el canto de verdad;
  - START y MÓVIL juntos encima de A y B (MÓVIL al lado de START o, si no cabe, encima), fuera del arco de descanso y sin pisar el recuadro del HUD; la zona de toque de A y B, mayor que el dibujo pero por debajo de ellos y sin entrar en el escenario de diálogos;
  - en los táctiles (Android, iOS, tabletas y la web en el móvil, `es_movil`); en el escritorio, los de antes;
  - si no caben al lado del texto (un móvil pequeño), primero se arriman al canto y después encogen, hasta el 80 % (y nunca por debajo de los de antes).
- Pruebas: `tests/mandos_geo.gd` (242, con las ventanas de escritorio de 4:3 a 21:9 y los tamaños de antes y de ahora en mm: seis pantallas —Android 20:9, Android barato, iPhone con isla, iPhone SE, iPad y tableta Android— con sus ppp y su zona segura), `tests/viaje.gd` (91) y `tests/ciclo.gd` (arranca con la carga y acaba sola en el título; los dedos colgados, la histéresis y los 240 ms por casilla).

## 1.56 · Godot 0.47.0

Lo que pidió el usuario tras la 1.55.3 («en el autobús no hay animación como tampoco en los demás vehículos, como una pantalla de carga, pero que sea el vehículo andando recto desde una vista de perfil»). Solo Godot, con `Datos.CAL`.

- **El viaje, de perfil** (`escena_viaje.gd`, `anim_viaje` y `VIAJE_V` en `granja.gd`): al coger el autobús en una parada o salir en tu vehículo del concesionario, una pantalla de carga con el autobús (los pasajeros, el conductor y tú en la ventanilla), el scooter, el utilitario, la berlina o el superdeportivo de perfil, que entra por la izquierda, rueda por la carretera con las ruedas girando y sale por la derecha, mientras el monte, los caseríos con los postes de la luz y el guardarraíl pasan por detrás a distinta velocidad. El cielo, por la hora (día con sol, atardecer, noche con estrellas, luna y los faros encendidos); arriba, de dónde a dónde y los minutos; abajo, la barra. Unos 3 s; A o B lo pasan.
- Arte a mano en `tools/sprites/a-mano/viaje.py` (`godot/arte/viaje.png` + `viaje.json`: recortes, ruedas, suelo y faro de cada vehículo).
- Prueba: `tests/viaje.gd` (77).

## 1.55.3 · Godot 0.46.2

Lo que pidió el usuario tras la 1.55.2 («fallos de arquitectura notables y todavía no has configurado bien en todos los muebles donde se puede sentar, la altura correcta»). Solo Godot, con `Datos.CAL`.

- **Sentarse a la altura de cada asiento** (`SENT_GEO` en `mundo.gd`, `_pj_sentado` en `pinta.gd`): la cadera en el cojín medido en cada sprite (silla, silla gaming, sillón, sofá, sofás del club y del reservado, banco y taburete). La silla gaming, centrada en sus dos casillas y no a un lado; de espaldas, solo el torso, con la cabeza asomando por encima del respaldo (en la silla, 3 px más arriba que antes); de frente, las piernas dobladas de la cadera al suelo, tantas espinillas como haga falta (`piernas_sentado`); el humo sale de la boca en cada asiento (`boca_sentado`).
- **El tubo de extracción**: pegado al techo, por encima de puertas y cuadros, y entra en la ventana por una placa de chapa en la hoja de arriba (la de abajo sigue siendo cristal), en vez de tapar la ventana entera con una rejilla; cada carpa a su ventana, sin tramos de techo uno encima de otro (`ventanas_tubos`, `_asigna_ventanas`).
- Pruebas: `tests/escala.gd` (66) y `tests/carpas_casa.gd` (88).

## 1.55.2 · Godot 0.46.1

- El de las madres de la nave ya no tapa la puerta de la habitación (lo pidió el usuario): con CAL y las puertas de dentro, se pone en (16, 3), delante de su carpa y mirando a ella (`build_ents` en `mundo.gd`); `tests/sotano.gd` comprueba que nadie de la nave está delante de una puerta (93 comprobaciones).

## 1.55.1 · Godot 0.46.0

Lo que pidió el usuario tras la 1.55 («no parece el personaje tumbado en la cama», «la pipa no parece de una sola pieza» y «que se pueda ordenar cualquier mueble de la casa; delante de la puerta y donde la escalera del camarote, libre siempre»). Solo Godot, con `Datos.CAL`.

- **Dormir**: el protagonista entero, de lado, con la mejilla en la almohada, el pelo, la oreja, los ojos cerrados y la nariz; tapado hasta la barbilla con el edredón marcando el hombro, la cadera y los pies, el embozo de la sábana y el brazo por encima; respira (`gs-dormido-0/1`, 128 × 66).
- **La pipa**: de madera y de una pieza (cazoleta, caña y boquilla con un solo contorno), cogida por debajo de la caña.
- **Ordenar cualquier mueble de la casa**: también la cama, el ordenador de la tía con su silla y la mesa de cruces (`si: "cal"`).
- **Siempre libres**: la casilla de delante de la puerta del pasillo y la de la escalera del camarote y la de delante, aunque el camarote no esté hecho; ningún mueble ni carpa se puede dejar ahí.

## 1.55.0 · Godot 0.46.0

Lo que pidió el usuario («la puerta del sótano está inaccesible porque hay una carpa delante», «debería salir un tubo de extracción de cada carpa hacia una de las ventanas» y «poder ordenar las carpas al gusto»). Solo Godot, con `Datos.CAL`.

- **La puerta del sótano, libre**: la carpa C, de serie junto a la cama (casillas 1-2), ya no tapa la puerta del pasillo; la planta del dormitorio pasa a (12, 2) si no cabe y la nevera, a su sitio de reserva.
- **Ordenar las carpas**: ORDENAR LA CASA trae las tres carpas que tengas (A, B y C), en la fila de la pared, como cualquier mueble: ocupan lo que mide la suya (1 o 2 casillas), no se dejan delante de una puerta ni cortando el paso.
- **El tubo de extracción**: con el extractor puesto, el tubo flexible de aluminio sale por arriba de la carpa, corre por lo alto de la pared (por encima de las puertas) y baja a una rejilla en la ventana más cercana que no tape la propia carpa; se mueve con la carpa.
- Prueba nueva `tests/carpas_casa.gd`.

## 1.54.1 · Godot 0.46.0

Lo que pidió el usuario al ver la 1.54 («eso no son sprites en condiciones en el mismo estilo que los muebles del juego»). Solo Godot, con `Datos.CAL`.

- **Los planos de cerca, de sprites**: cada acción se compone con sprites dibujados a mano en el estilo de los muebles (contorno `#2a2a34`, luz de arriba a la izquierda, 3–4 tonos por material) en un panel de 144 × 96 a la escala de la vista C:
  - la planta (vegetativa y en flor), la plántula, la maceta de tela (seca y mojada) y la pared plateada de la carpa salen de la vista C;
  - regadera, pulverizador, botella de abono, tijeras, esqueje y vaso, pincel, cola (con hojas y pelada), bichos, bruma y gotas;
  - porro, pipa, bong con burbujas, vaporizador con piloto, mechero con llama y humo;
  - bolsita, billete, fajo y manos (la tuya y la del cliente), el que duerme y las zetas;
  - fondos: la carpa, la mesa de madera, el salón de noche con el sofá, la calle de ladrillo y la cama de noche y de día.
- Las cerraduras (llave, candado, teclado, PIN y rueda) siguen como en la 1.53.

## 1.54.0 · Godot 0.46.0

Lo que pidió el usuario tras la 1.53 («que todas las acciones del juego sean más realistas, acompañadas de algo gráfico»). Solo Godot, con `Datos.CAL`.

- **Cada acción, de cerca**: como la llave de la 1.53, al hacerla sale un plano de detalle en el centro de la pantalla, con su sonido (A o B lo pasan):
  - **regar**: la regadera se inclina, cae el agua y la tierra se oscurece;
  - **tratar la plaga**: el pulverizador echa dos nubes y los bichos caen de la hoja;
  - **abonar**: la botella llena el vaso medidor;
  - **plantar**: la mano hace el hoyo con el dedo, cae la semilla y se tapa;
  - **sacar un esqueje**: las tijeras cortan la punta y cae en su taco;
  - **cosechar**: las tijeras cortan la cola y cae en la bandeja, con los tricomas brillando;
  - **manicurar**: cuatro tijeretazos y las hojitas caen a la rejilla;
  - **polinizar**: el pincel con polen sobre los pelos de la flor;
  - **fumar y catar**: con papel, el mechero, la brasa y el humo; la pipa; el bong, con sus burbujas; el vaporizador, con su piloto y el vapor;
  - **vender**: la bolsita va hacia el cliente y los billetes hacia ti;
  - **pagar a Toño**: los billetes caen uno a uno sobre la mesa;
  - **dormir**: la ventana con la luna (o el sol en la siesta), la almohada y las zetas.
- Las extracciones ya tenían su escena desde la 1.38. Tres sonidos nuevos: el agua, la tijera y el mechero. Dibujado en código, en píxeles (`gesto`, `GESTOS`, `_gesto_rects`, `_gesto_fumar` en `trama.gd`); `accion()` de `mundo.gd` lo lanza para regar, plantar, cosechar, cruzar y vender. Prueba `tests/acceso.gd`.

## 1.53.0 · Godot 0.46.0

Lo que pidió el usuario tras la 1.52.1 («que funcionen con una clave o simulando teclear una clave o meter una llave, como animación… que ese toque a la A sea más realista o acompañado de algo gráfico»). Solo Godot, con `Datos.CAL`.

- **Abrir lo tuyo se ve**: al pulsar A en lo que se abre con llave o con clave, un momento en el centro de la pantalla con su sonido (A o B lo pasan):
  - el portal del piso, los locales alquilados, el piso franco y el club KAIA: la puerta de madera con su escudo de latón, la llave que entra, gira y hace clic;
  - la nave: el candado de la persiana (la llave sube, gira y salta el arco) y el teclado de la alarma, con sus 4 cifras;
  - el bajo de Txomin: su candado;
  - el cajero: la tarjeta entra por la ranura y se teclea el PIN, con el piloto rojo y luego verde;
  - la caja fuerte de la tía: las cuatro ruedas que giran y se paran en su cifra, el piloto y la manilla que gira (con una combinación mala, el piloto parpadea en rojo y la manilla no se mueve); la empotrada, con su teclado.
- Dibujado en código, en píxeles (`rects_acceso`, `_teclado`, `_llave_h`, `_llave_v` y una letra de 3 × 5 para las cifras, `ACC_GLIFO`), y tres sonidos nuevos: la tecla, la llave y el «clac» (`sonido.gd`). Las cifras de cada teclado son siempre las mismas en cada partida (`cifras_acceso`). Prueba `tests/acceso.gd`.

## 1.52.1 · Godot 0.46.0

Lo que pidió el usuario tras probar la 1.52 («cómo va a estar el mueble de ordenar una sala en otra»). Solo Godot, con `Datos.CAL`.

- **Cada sala se ordena desde dentro de ella**: desde la 1.51 el escritorio está en el despacho y desde allí se movían las mesas y el tanque de la nave, que está al otro lado de la pared. Ahora ORDENAR LA NAVE sale en la nave: en la estantería de los abonos y en el riego (tanque, bomba y controlador); el escritorio del despacho ya no lo ofrece (sin CAL, con el escritorio en la nave, como antes). Y `ordenar(mapa)` no abre nada si no estás en ese mapa.
- Repaso de todos los sitios: la casa (la mesa redonda, en el piso; el pasillo y el sótano no ordenan nada), el local de la asociación (las mesitas, dentro) y las salas de al lado (el cuartucho del taller, el despacho y la habitación de la nave). Prueba `tests/orden_sala.gd`: en cada mapa ordenable y en sus salas de al lado, A en cada mueble; el menú de ordenar un mapa solo sale dentro de ese mapa y cada mapa ordenable tiene dentro un mueble que lo ordena.

## 1.52.0 · Godot 0.45.0

Lo que pidió el usuario tras la 1.51 (el tiempo en el móvil, las autoflorecientes, la skill de sprites, las proporciones de las puertas y el muelle por obras). Solo Godot, con `Datos.CAL`.

- **El tiempo de fuera** (lo pidió el usuario: «en vez de la hora en grande… los grados, el clima y su dibujo, por estaciones»): en la pantalla del móvil, el dibujo del tiempo (sol, nubes, lluvia, niebla, tormenta o nieve) y los °C en grande; en la descripción, máxima, mínima y la estación. El tiempo sale del mes del calendario (`TIEMPO`: máximas y mínimas de la costa cantábrica por mes, probabilidad de cada tiempo por mes, estaciones por equinoccios y solsticios) con la temperatura por hora (la mínima a las 6, la máxima a las 15; `Datos.tiempo`, `Datos.estacion`, `ICONO_TIEMPO`). En la calle se ve: lluvia en diagonal, copos, niebla y relámpagos (`_tiempo` en `pinta.gd`); con lluvia, tormenta o nieve la calle calienta menos al vender (`calle_tiempo`). Prueba `tests/tiempo.gd`.
- **Ruderalis y las autoflorecientes** (lo pidió el usuario: «se nos ha olvidado meter Ruderalis y toda la gran variedad de genéticas que hay AUTO»): la Ruderalis en el banco de semillas (landrace de 4 % de THC) y 16 autoflorecientes con su linaje («X × Ruderalis»): la Lowryder y las versiones auto de Northern Lights, White Widow, Amnesia, Blueberry, AK-47, Jack Herer, Skunk, Big Bud, Super Skunk, Cheese, Blue Dream, Sour Diesel, Super Silver Haze, Purple Kush y Durban Poison, cada una con su nota en el diario. Florecen solas por su edad, sin 12/12 (con 12/12 rinden un 15 % menos), más bajas y con menos rendimiento; no sirven de madre ni se sacan esquejes; auto × auto da auto (`AUTO` en `datos.json`, que solo entra con CAL; `cross_result`, `plant_step`). Prueba `tests/autos.gd`.
- **La skill del director de sprites en el repo** (lo pidió el usuario): `.claude/skills/director-sprites/SKILL.md`, `tools/sprite_qa.py`, el MCP `pixellab-mcp` en `.mcp.json` (con `PIXELLAB_SECRET` del entorno) y Pillow en `requirements.txt`; prueba de humo: un slime de 32 × 32 con su idle de 4 fotogramas (`sprites/slime/`, QA 4/4).
- **Las puertas de dentro, más bajas que la pared** (lo pidió el usuario: «el alto de la pared no puede ser igual que el de la puerta»): las del sótano y del pasillo con su dintel y la pared encima (`TOP` en `tools/sprites/a-mano/sotano.py`).
- **El muelle, destartalado y por obras** (lo pidió el usuario: «comenzar destartalado… ir reformándolo poco a poco, edificio por edificio… para meter un barco más grande se tiene que reformar el espacio… montar otro club ahí»): las casas de la cofradía en ruina (cristales tapiados, pintura desvaída, desconchones, óxido y grietas) y el pantalán con tablones podridos, hasta su obra. Koldo → Las obras del muelle, por transferencia y en sus días: el pantalán (12.000 €, el pesquero ya puede atracar), el dique (45.000 €, el atunero), la caseta de la cofradía (8.000 €, un 30 % menos de patrulleras), las casas de los pescadores (20.000 €, 600 € de alquiler cada semana) y la casa blanca, que es **el club KAIA**: el tuyo, sin carné, con su encargada y el dispensario que llenas tú (40 g al día a los socios). Arte a mano en `tools/sprites/a-mano/muelle_obras.py` (`MAR.obras`, `S.mar.ob`, `obra_ya`, `obras_muelle`, `obras_dia`, `talk_kaia`).
- **La ley** (lo pidió el usuario: «una legalización del cannabis en España que abriría un mercado mucho mayor, ya es otra peli»): 30 días después de abrir KAIA, el Congreso aprueba la ley; con la licencia (25.000 €), la Distribuidora Kaia te compra hasta 5 kg al día con factura, por el banco y sin calor, y KAIA despacha el triple (`MAR.legal`, `licencia_mar`, `vender_legal`). Prueba `tests/obras.gd`.

## 1.51.0 · Godot 0.45.0

Lo que pidió el usuario tras la 1.50 (el final de partida, el atrezo, misiones secundarias, el móvil con iconos, el sótano, las puertas de dentro y las hojas por variedad). Solo Godot, con `Datos.CAL`.

- **El muelle de Puerto Viejo** (lo pidió el usuario: «un mapa lateral en Puerto Viejo, un mini puerto para hacer envíos, invertir en un barco, empezando por uno pequeño»): desde el capítulo 8, al final de la plaza, a la derecha, el paso al muelle de la cofradía (`MAPS.muelle`, 34 × 16; salidas de lado con `lado` en `exits`, `montar_muelle` en `mundo.gd`), con las casas marineras, la acera, el pantalán con sus norays, redes, nasas y cajas, y el agua. Koldo, el amigo de la tía Maite, te manda un SMS y te da su txalupa *Maite* (6 m); el pesquero *Itsaso* (10 m, 65.000 €) y el atunero *Maite Bi* (14 m, 180.000 €) se compran por transferencia y se amarran cada uno en su noray (arte a mano en `tools/sprites/a-mano/puerto.py`).
- **Los envíos por mar**: en el noray de cada barco, la ruta (Burdeos, Brest, Cork y Róterdam, que abre la reputación), la carga por lotes hasta lo que cabe en la bodega (desde 500 g) y zarpar; a los días de viaje, la conservera paga por transferencia (limpio, a la cuenta) al por mayor por la ruta; la patrullera puede parar un barco (según el barco, la ruta y el calor) y quedarse la carga. Rango por kilos exportados (de Txalupero a Almirante del Cantábrico), un pedido cada semana con prima y, con reputación, **el último trabajo** de Koldo: 10 kg a Róterdam en un viaje, con prima de 50.000 € y el final de su historia (`MAR`, `S.mar`, `talk_koldo`, `cargar_envio`, `mar_dia`).
- **El piso franco de Gorka** (lo pidió el usuario: «distribución a gran escala por un piso franco o una persona»): tras el primer envío, la puerta de la casa amarilla del muelle; se alquila (1.500 € al mes en efectivo), lo que dejas en el alijo lo reparte él al por mayor cada mañana (300 g al día; con la furgoneta, 700 g, y con la red de pisos, 1,5 kg) y se queda un 12 %; la caja se recoge en mano; si la calle se calienta, redada en el piso (`FRANCO`, `S.franco`, `talk_gorka`, `alijo_franco`, `franco_dia`).
- **El sótano** (lo pidió el usuario): una puerta en el dormitorio del piso al pasillo de abajo y, con la obra de la tienda online, la escalera al sótano de la tía, con estanterías para bandejas de setas (`SOTANO`, `PUERTAS_INT`).
- **El bajo de Txomin, más grande** (lo pidió el usuario: «que se cultive como la nave»): nueve estanterías en tres páginas y Ekaitz, el sobrino de Txomin, de ayudante: cada mañana pulveriza, recoge lo listo y lo tiende a secar (`SETAS_AY`).
- **Puertas de dentro**: en el taller, al cuartucho con la cama; en la nave, al despacho (con el escritorio) y a la habitación (con la cama) (`PUERTAS_INT`, `puertas_int`).
- **Las hojas por variedad** (lo pidió el usuario: «dependiendo de la variedad o linaje, las hojas son diferentes»): la hoja de abanico de cada una dibujada en código según su % índica (foliolos, ancho, abertura) y, en las landraces que se distinguen, su ficha propia (`HOJA`: las tailandesas de puntas caídas, la hawaiana ancha y clara…), en la ficha de la Genoteca (`src/hoja.gd`).
- **Recados por la comarca**: diez misiones secundarias que aparecen según el capítulo (el jubilado de la rodilla, el bocata para la mar, el camión de Valdehierro…), con su premio en dinero y reputación (`SECUNDARIAS`, `recados_menu`).
- **El atrezo** de la casa de Txaro, el caserío de ama, la comisaría y el almacén (`ATREZO`, `ATREZO_TXT`).
- **El móvil con su pantalla**: la hora en grande y las aplicaciones en una rejilla con sus iconos, a mano (`tools/sprites/a-mano/movil.py`, `MOVIL_V`, `rects_movil`).
- Pruebas: `tests/muelle.gd`, `sotano.gd`, `hojas.gd`, `recados.gd`, `atrezo.gd` y `movil.gd`.

## 1.50.0 · Godot 0.44.0

Lo que pidió el usuario tras probar la 1.49. Solo Godot, con `Datos.CAL`.

- **El recuadro del HUD**: debajo de la fecha y la hora, una tabla ordenada con EFECTIVO, BANCO (la cuenta), FLORES y ROSIN que llevas encima, la etiqueta a la izquierda y la cifra a la derecha, entre dos rayas (`hud_filas`, `_pinta_hud_tab` en `ui.gd`; `update_hud` en `juego.gd`). Encima de CALOR y SOSPECHA.
- **Los nombres enteros en los mercados**: «Hoy tenemos» de los clubs, Iñaki y la lonja salía en la columna de la derecha y cortaba las variedades («Beldi», «Zam», «Dry s»); ahora es un menú a lo ancho con la ficha de cada lote debajo (`comprar_mercado`).
- **Sin hueco al final de los menús largos**: al pasar a una fila con la descripción más corta caben más filas y la lista se quedaba corrida, con el ▲ arriba y un hueco debajo (la tienda de Kiko); ahora se ajusta (`m_top` en `menu`).
- **Menos de 10 g con su décima** en la caja fuerte y el camarote: un lote de 0,4 g ya no sale como «0 g» (`g_lote`).
- **Los estancos con estanquero**: en Valdehierro, Errotabarri e Ibarbide no salía nadie detrás del mostrador porque su muñeco (`cliente4`, `cliente6`, `cliente2`) no estaba en `LOOKS`; ya están (`datos.json`). Repasados todos los `look` de `NPCDEF`: no falta ninguno más (la gente de los negocios sale cuando el local está alquilado).
- **Los menús de comprar y vender enseñan todo**: el de la derecha se ensancha hasta casi toda la pantalla antes de cortar; a toda pantalla, una fila larga ya no estira la ventana fuera de la pantalla; y si el nombre de lo elegido aún no cabe, sale entero debajo, encima de su ficha (`_desc_sel`, `maxw` en `_pinta_menu`).
- **Las mesitas de los clubs, desde arriba**: el tablero ocupa toda la casilla (30 × 11 px, de una casilla a la otra) visto de frente y desde bastante arriba, con el canto y las patas apenas asomando, y lo de encima visto desde arriba (cenicero, grinder, librillo, mechero; la vela, el baúl con la botella, el tablón sobre los bidones, el cristal con la revista). Sentado en el sofá de abajo, de espaldas, solo te asoma la cabeza por encima del respaldo y la mesa se sigue viendo (`mesa_ancha`, `w-mesita-*` en `tools/sprites/a-mano/ocio.py`).
- **Los bancos donde sentarse**: el banco de la calle, la comisaría y los locales, nuevo y a escala (1,6 m de largo, asiento a 45 cm, respaldo a 80 cm, listones de madera y costados de hierro); sentado se ve a los dos lados de quien se sienta, y pegado al borde del mapa se mete hacia dentro (`banco` en `tools/sprites/a-mano/escala.py`, `e-bench`). La altura en el sofá ya era la real: sentado, la cabeza queda a ≈ 1,37 m y por detrás asoma por encima del respaldo de 85 cm.
- **Sentado de frente, en el asiento y no en el suelo**: de frente (bancos y sofás de cara), el culo va en el asiento y se ven las piernas dobladas: los muslos encima del asiento, las rodillas, las espinillas colgando delante del canto (entre ellas, el banco) y las zapatillas en el suelo, con los colores de la ropa que lleves (`SENT_PIERNAS` en `pinta.gd`, `SENT_CORTA_SUR`).
- **En el taburete de la barra, sentado de verdad**: de espaldas, el culo encima del asiento (a 72 cm), el taburete delante de la espalda ya no la tapa, y las piernas cuelgan a los lados del pie con las zapatillas en el reposapiés (`SENT_TABURETE`, `TABURETE_SUBE` en `pinta.gd`). En los sofás, sillones y sillas de espaldas el respaldo tapa las piernas, como en la realidad, y se queda como estaba.
- **La carta de la tía Maite, encima de la mesa**: se pintaba a la altura del pie de la mesa redonda; ahora va sobre el tablero (de 3 px por encima de la casilla a 2 px dentro), después de la mesa, con su sello rojo.
- La prueba de los créditos de `ciclo.gd` lee la versión de `project.godot`, no una fija.

## 1.49.0 · Godot 0.43.0

Los muebles del taller, la panadería, el bar y la lavandería, de frente (lo pidió el usuario: «recuerda cómo deben ser los sprites», con la skill del director de sprites y fotos de la lavandería y de una cafetera de dos grupos). Solo Godot, con `Datos.CAL`.

- **Rehechos en PixelLab de frente**, nunca girados ni isométricos: los de una casilla en alzado recto (vista sidescroller) y los de dos en 3/4 de frente; solo con texto, sin subir las fotos ni poner marcas. La spec está en `tools/sprites/director/negocios-frente/spec.yaml` y el QA en `tools/sprite_qa.py` (0 semitransparencias, 0 huérfanos, ≤ 32 colores).
- **A escala por su alto real** (`PIEZAS` en `pixellab_negocios.py`, en px a 16 px/m): la lavadora de 14 kg (1,4 m), la secadora de 18 kg (1,6 m), el cambiador de monedas colgado en la pared, la mesa alta de patas negras con el cesto y la papelera al lado, el horno de pisos y el botellero (1,8–1,9 m), los taburetes (75 cm)…
- **La bancada metálica de tres asientos** de la foto en la lavandería, en lugar del banco (`d-bench-loc-ibar`, por mapa con `_detalle_obj`; se sigue pudiendo sentar).
- **Segunda vuelta, todas de frente** (lo dijo el usuario: «la vista NO DEBE SER ISOMÉTRICA… hay algunas que están bien, otras que no»): rehechas en PixelLab en alzado de frente con la tapa a la vista y con las piezas buenas (mostrador y botellero) como referencia de estilo las nueve que salían giradas: el horno y la mesa de acero de la panadería, el carro de bandejas, la barra con vitrina del bar, el carro de herramientas, las cajas, la mesa con sillas y la estantería de recambios del taller y la mesa de doblar de la lavandería. Las demás, como estaban.
- **Sentarse de verdad** (lo pidió el usuario: «que te puedas sentar de verdad… y poder hacer cosas sentado»): en los bancos de la calle, los sofás de los clubs y del reservado de GAUA, los taburetes del bar y las sillas de casa, sentarte ya no es un menú que te tiene parado: te quedas sentado mientras el mundo sigue (la gente anda, el reloj corre, START y el móvil funcionan) y te levantas con B o con una flecha, que te deja mirando hacia ella sin dar el paso. Con A, lo de sentado (`menu_sentado`): fumarte uno (donde se puede), pedir algo en el bar, los clubs y GAUA (`BEBIDAS`, a precio de barra), hablar con quien tengas al lado (`al_lado`, `hablar_con`), mirar el móvil, quedarte un rato (media hora; en un banco de la calle, de día, la sospecha baja 1) o levantarte. Al cambiar de sitio, de pie (`SENT`, `levantarte`, en `mundo.gd`); prueba en `tests/escala.gd`.
- **La cafetera de dos grupos** encima de su mueble bajo (`CAFE`), en el bar y en el taller.

## 1.48.0 · 16 de octubre de 2026

La calle más como un RPG clásico y los muebles con lo que traen (lo pidió el usuario: «el mapa lo quiero más realista, no estilo Minecraft sino más de RPG clásico» y «la calidad de los otros sprites también, que se note que es el sprite y lo que trae»). Solo Godot (0.42.0), con `Datos.CAL`: sin CAL, las pantallas del oráculo no cambian. Todo a mano y de frente a 3/4, sin marcas (`tools/sprites/a-mano/detalle.py`).

- **Los firmes, sin la rejilla de 16 en 16** (`exterior-mosaico`, celda `tile_mosaico`): cada firme es un mosaico de 64 × 64 cortado en 16 casillas, y el juego coge la que le toca por su posición (`MOSAICO_TILE` en `pinta.gd`).
  - La hierba, con sus matitas repartidas; las flores, en ramilletes de cuatro pétalos; la hierba alta, en matas redondas.
  - La acera, de losas grandes de 2 × 1 m a matajuntas, con su luz y su sombra; la plaza, de losas de piedra de varios tamaños.
  - La calzada, con el bordillo de piedra (juntas cada metro y la sombra en el asfalto) y la raya discontinua.
  - El camino de tierra, liso, con alguna piedrecita.
  - La hierba, la plaza y la tierra conservan el color de fondo, así que las orillas de siempre siguen casando.
- **El canto de la hierba** (`_canto_hierba`): donde la hierba toca acera, calzada u hormigón, dos píxeles más oscuros hacen de borde, en vez del corte seco de casilla a casilla.
- **El seto, en matas redondas** (`d-seto`), con el borde oscuro, la luz arriba y la sombra del pie.
- **Los muebles, con lo que traen** (`_detalle_obj`: `d-<mueble>-<mapa>-<tramo>`, por mapa y alternando tres tramos por casilla):
  - El mostrador del grow de Kiko y el de GROW IBARBIDE: la caja registradora, los botes de abono y el expositor de los sobres de semillas.
  - El de la comisaría: los papeles con el sello, el monitor y la bandeja de documentos.
  - La barra del bar: los grifos de cerveza, las cañas con el servilletero y una fuente de pintxos; la de GAUA, con el neón del canto, la cubitera con la botella, los cócteles y la coctelera.
  - La vitrina del grow, iluminada, con los sobres, un grinder, los botes, el medidor de pH y los tamices dentro.
  - Las cajas: en el puerto y los astilleros, las de pescado (con hielo y el pescado); en los demás sitios, de madera, abiertas, con una pieza y una bolsa sobre la paja.
  - Las baldas del grow, con los botes de abono; las de la comisaría, con los archivadores; los sacos de sustrato con la hoja en la etiqueta; las botellas del bar, de cada clase.
- Prueba `tests/detalle.gd`.

## 1.47.0 · 16 de octubre de 2026

Muebles a escala, sentarse a fumar, catar lo que quieras, estancos, la vitrina del grow, GAUA con el reservado arriba y cuatro locales como en las fotos (lo pidió el usuario: «el mobiliario debe de ser a escala realista para con el personaje, también en los clubs, casas y demás»; «que se pueda sentarse a fumarse uno, y opción de levantarse, lo mismo en los asientos de casa»; las fotos del taller, la panadería, el bar y la lavandería, y «¿por qué no estás usando la API de PixelLab?»). Solo Godot (0.41.0), con `Datos.CAL`: sin CAL, las pantallas del oráculo no cambian.

- **Los muebles a escala con el protagonista** (27 px = 1,70 m, 16 px/m) en casas, clubs, grows, la nave, el bajo, la discoteca y los locales.
  - Los que se quedaban cortos salen otra vez a su alto real (`tools/sprites/a-mano/escala.py`): `e-<sprite>` en `escala-alto` (32 × 48) y `escala-ancho` (48 × 48).
  - Así salen mesas, mostradores, barras, vitrinas, el banco, la gramola, las lavadoras, la caja de los locales y los sofás.
  - Con CAL, `_arte_obj` los cambia por los de siempre.
  - El box del lavadero mide 5 m, como los coches (`boxL`, `NEG_LARGO`).
- **Sentarse** en sofás, sillones, sillas, bancos y taburetes, en casa, en los clubs y en la calle (A delante del asiento: `ASIENTOS`, `asiento`, `sentado`).
  - El protagonista se sienta de frente o de espaldas según el asiento (`_pj_sentado`).
  - Desde el asiento puedes fumarte uno o levantarte. En las sillas de los ordenadores, también usar el ordenador.
  - **Fumarte uno** (`fumar_sentado`): gasta lo que pida la forma de fumar (ver más abajo) del lote que elijas y pasa un cuarto de hora, con el humo.
  - En la calle, el calor sube 3. En comisaría no; en el bar, la discoteca y los locales tampoco: «Aquí dentro no se puede fumar».
- **El taller, la panadería, el bar y la lavandería, como en las fotos del usuario:**
  - Los muebles salen de PixelLab (`create_1_direction_object`, solo con texto: las fotos llevan marcas y no se subieron). Están en `tools/sprites/pixellab-negocios/` y se ajustan a 16 px/m con `tools/sprites/a-mano/pixellab_negocios.py`, en los grupos `negocios-pl-alto`, `negocios-pl-ancho` y `negocios-pl-coche`.
  - Los suelos y las paredes están hechos a mano (`tools/sprites/a-mano/negocios2.py`, `interior-negocios`).
  - **El taller:** suelo de resina azul y pared blanca con la franja azul, blanca y roja. El elevador tiene las columnas azules (`e-elevT`). Hay un carro de herramientas rojo, la recogedora de aceite, una estantería de recambios de 2 m y cajas azules.
  - **La panadería:** baldosa gris clara y azulejo de metro. Tiene el horno de pisos, el carro de bandejas, el estante del pan con los cestos, la mesa de acero con la masa y el mostrador con las campanas y la cafetera.
  - **El bar:** suelo de pizarra, pared gris azulada y el machihembrado de pino. Tiene la barra de pintxos de mármol con la vitrina, el botellero con los vasos, la cafetera, taburetes de hierro negro (`e-stool`) y mesas de pino con sus sillas.
  - **La lavandería:** laminado gris y pared azul con burbujas. Tiene lavadoras y secadoras industriales de acero, la caja de pago (el género), la mesa de doblar y el carro de la ropa.
  - Las barras y los mostradores dejan hablar por encima (`COUNTERS`). Los de dos casillas están en `NEG_ANCHO`.
- **Catar lo que sea** (lo pidió el usuario: «que se pueda probar todo tipo de cogollos y extracción (catar 0.5, o la cantidad que sea hasta un límite lógico claro)»):
  - Desde la MOCHILA, cualquier lote de cogollos o de extracto: «Catar…» y la cantidad (`cata_cuanto`, `CATA_MAX`, `CATA_PASOS`).
  - Cogollos: 0,1, 0,25, 0,5 o 1 g de una vez. Extracto: 0,1, 0,2, 0,3 o 0,5 g. Nunca más de lo que queda.
  - Queda la nota de cata en el lote (`marca_cata`). Según los mg de THC, te deja tocado o mirando a la pared (`cata_efecto`).
  - Fumar también es catar.
- **Con qué se fuma** (`FUMAR`):
  - El porro necesita papel y mechero. Con tabaco lleva 0,3 g de hierba y 0,7 de tabaco; con el grinder, 0,4 g en vez de 0,5.
  - La pipa (0,2 g de cogollo o 0,1 de extracto) y el bong (0,3 g o 0,1) necesitan mechero.
  - El vaporizador (0,2 g o 0,1) no necesita mechero y en la calle sube el calor 1 en vez de 3.
  - Si tienes más de una forma, te pregunta «¿Cómo?»; si llevas más de un lote, «¿DE CUÁL?».
- **Un estanco en cada pueblo** (lo pidió el usuario: «uno en cada pueblo, para comprar, tabaco, papel y eso»; `ESTANCO`, `montar_estancos`, `est-<pueblo>`):
  - Están en una casa libre de cada pueblo, con la puerta de su fachada y el rótulo de la T colgado encima (`rotulo` en `blds`).
  - En el barrio alto es una casa nueva del Casco, en (21, 5).
  - Por dentro: terrazo, friso de madera, la estantería de las cajetillas (colores lisos, sin marcas), el mostrador con la vitrina de los mecheros, el humidificador de puros y el expositor del papel.
  - Atiende un estanquero o una estanquera (`est_<pueblo>`, `talk_estanco`) que vende el librillo de papel (50 hojas), los filtros, el tabaco de liar y el mechero.
- **Las pipas y demás, en el grow, en su vitrina** (`PARAFERNALIA`, una de cada):
  - Se venden el grinder, la pipa de cristal, el bong y el vaporizador.
  - Están en la vitrina iluminada de Kiko y en la de GROW IBARBIDE (`vitrinaP`).
  - Aparecen en la MOCHILA y tienen sus iconos (`iconos-fumar`).
- **Las mesas de los sofás de los clubs, de frente a 3/4 como los sofás y el billar** (lo pidió el usuario):
  - Cada par de mesitas es ahora una mesa baja de dos casillas (`w-mesita` y `w-mesita-<estilo>`).
  - Por estilo: la de siempre, el nogal con la vela (Kalea), el baúl de marinero (Itsaso), los dos bidones con el tablón (Fundición) y el cristal con las patas de acero (Ensanche).
- **El cajero del pueblo, fuera de detrás de la farola** (lo pidió el usuario: «está detrás de la farola… muévelo una baldosa a la izquierda y asegúrate de que no haya pasado en otros pueblos»): a (30, 8) (`CAJERO_CAL`). `tests/ocio.gd` repasa todos los mapas de calle: ningún cajero ni puerta tiene una farola delante.
- **GAUA, grande y con el reservado arriba** (lo pidió el usuario: «la discoteca tiene que ser más grande, el piso de arriba reservado, desde el que se ve el piso de abajo, en la cristalera del suelo, transparente»; `DISCO_CAL`, `montar_disco`):
  - **La planta baja**, de 22 × 12: la barra larga, la cabina del DJ entre dos altavoces, la pista de 8 × 5, dos rincones con sofá y la escalera al reservado con su cordón.
  - **El reservado, arriba** (`disco-vip`): moqueta, su barra con camarera, tres mesas con sofá, gente VIP y la escalera de bajada.
  - **La cristalera**, en el suelo, de 14 × 7 casillas: tapa la pista entera y lo de alrededor (lo pidió el usuario: «se tiene que ver algo más que la pista de baile solamente»). A través del cristal se ve la planta baja en su sitio, recortada al cristal: la pista con sus luces, el final de la barra, los altavoces, la gente que baila y la de alrededor (`gentD1`–`gentD3`, con sus frases en `DISCO_CAL.gente`; `_cristalera`).
  - Para subir hace falta la mesa del reservado de esa noche: la vende la RRPP y, al pagarla, te sube.
  - A las 6, el portero también echa a la gente del reservado.
  - Las escaleras están dibujadas a mano de frente (`escaleraD`, `escaleraDB`).
- El arte nuevo está dibujado a mano y siempre de frente a 3/4, nunca en isométrica (`tools/sprites/a-mano/ocio.py`). Los grupos son `iconos-fumar`, `interior-estanco`, `ocio-ancho`, `ocio-alto` y `ocio-16`.
- Prueba nueva `tests/ocio.gd` (61 comprobaciones; con `--pintar`, los estancos por dentro y por fuera, GAUA, el reservado, los clubs y los grows).
- Prueba nueva `tests/escala.gd` (32 comprobaciones; con `--pintar`, cada sitio y la gente sentada). `tests/negocios.gd` pasa a 299.

## 1.46.0 · 16 de octubre de 2026

Las cepas de setas y el taller a escala (lo pidió el usuario: «que se puedan comprar diferentes panes… diferentes micelios… como razas… juntar esos micelios y crear nuevas variedades… preestablecidas en un libro de recetas… que no se permita hacer ciertos cruces… son diferentes formas de las setas»; y «ya hay sprites de coches del concesionario, usa esas medidas para crear los fosos con las máquinas de levantar… a escala»). Solo Godot (0.40.0), con `Datos.CAL`. Las cepas son inventadas y genéricas: nada de método ni de dosis.

- **Doce cepas en cuatro formas** (`CEPAS` en `datos.json`): cúpula, campana, plato y racimo, cada una con sus colores, su rendimiento (×0,85 a ×1,35) y su precio (×0,9 a ×2,4).
  - Cinco panes de micelio que vende Txomin en la puerta (Txuria, Urrezko, Iluna, Adartxo y Gaztain; 20–40 €, `panes_txomin`).
  - Cinco de 2.ª generación (Ilargi, Ekaitz, Errota, Orri y Gautxori) y dos de 3.ª (Izar, la última del cuaderno, y Basoa).
- **La bandeja de tu cepa:** al comprar una bandeja, Txomin pone la Txuria o uno de tus panes (`S.setas.panes`). La bandeja dice su cepa y sus setas salen con su forma y su color.
- **Juntar micelios** en la mesa de trabajo (`juntar_micelios`, 2 h): dos panes dan dos de la cepa nueva, pero solo si la pareja está en el cuaderno (`CEPAS.r`).
  - El racimo no se junta con la cúpula ni con la campana: se repelen (`CEPAS.veta`).
  - Lo que no está en el cuaderno no prende. En los dos casos no se gasta nada.
- **El cuaderno de las cepas** en la mesa (`cuaderno_setas`): todas, con ✓ las que has tenido, su forma, de qué sale cada una y lo que no se junta.
- **Por cepa hasta la venta:** lo recogido se seca por cepa (`fr[].v`), el armario dice cuánto hay de cada una (`S.setas.gv`) y Txomin paga cada cepa a su precio. Los lotes de la mesa salen de la cepa de la que más hay.
- **El taller, a escala con los coches del concesionario** (16 px/m, 5 casillas como la exposición; grupo `negocios-coche`):
  - el elevador es de cuatro columnas, de 5 m, con las rampas a 1,2 m y el utilitario de 4 m subido;
  - el foso mide 5 m de largo, con la berlina de 4,8 m encima, la escalera y la lámpara;
  - el local pasa a 20 × 10. La segunda mejora pone la cabina de diagnosis y la equilibradora (`diagT`, `equiT`).
- Prueba nueva `tests/cepas.gd` (68 comprobaciones; con `--pintar`, las doce cepas en las baldas). `tests/negocios.gd` (287) comprueba el taller a escala.

## 1.45.0 · 15 de octubre de 2026

Los negocios por dentro y los mercados que compran y venden (lo pidió el usuario: «que tú puedas acceder a ese sitio y controlarlo desde ahí… tanto el taller como los demás negocios»; «un cuartucho donde haya una cama pequeña…»; «en el club se tiene que poder tanto comprar como vender extracciones y diferentes tipos de hierba… a todos los mercados»). Solo Godot (0.39.0), con `Datos.CAL`.

- **Cada local alquilado se entra por su puerta** (gate `neg:<k>`, `montar_locales`): el taller de Valdehierro, el lavadero de los astilleros, la taberna del puerto, la quesería de Mendialde, la panadería de Errotabarri y la lavandería de Ibarbide (`MAPS.loc-<k>`). La puerta es la que ya está dibujada en la fachada, con su estilo, su tamaño y en su sitio (lo pidió el usuario): la animación se recorta de la propia base (`edificio-ladrillo-pu`, `edificio-marinera-pu` y `edificio-casco-pu`, en `puertas_neg` de `mundo.py`; los caseríos, con la suya), y la prueba comprueba que, cerrada, calca la fachada píxel a píxel. Sin alquilar, «Cerrado: SE TRASPASA». El rótulo de la calle sigue para alquilarlo y, ya tuyo, manda dentro.
- **Por dentro, con su atrezo** (arte a mano en `tools/sprites/a-mano/negocios.py`): el taller con el elevador y el coche subido, el foso con la escalera, el banco de trabajo, el compresor, los recambios y los neumáticos; los boxes de lavado, los aspiradores y la máquina de fichas; la barra, los barriles y las mesas de la taberna; la cuba, la prensa, la cámara de curación y el mostrador de la quesería; el horno de leña, la amasadora y los estantes del pan; las lavadoras, las secadoras y la mesa de doblar. En cada uno, su empleado (Iker, Unai, Pello, Antxon, Itziar e Idoia).
- **Se lleva desde dentro:** la caja (meter efectivo, las cuentas, reponer género, las mejoras y dejar el local), el género en su estante y la fregona.
- **Un negocio que funciona** (`NEGOCIO`, `neg_venta`, cada mañana en `recibos_dia`): vende su base × la limpieza (baja 5 al día; la fregona, una hora, la deja en 100) × las mejoras (+30 % cada una) × el género (sin género, al 30 %) ± 15 %, y entra en la cuenta como ventas, además de lo que laves por la caja. Dos mejoras por local (se ven dentro), que suben también el tope de la caja un 50 % cada una.
- **Dormir fuera de casa:** el cuartucho del taller, detrás de un tabique, con cama, mesilla, escritorio y armario (cambiarte de ropa); y el camastro de la nave, al fondo.
- **El almacén del club** (asociación, de presidente; `almC`): guardas cogollos y extracciones hasta 2 kg y los socios retiran 40 g al día a precio de dispensario.
- **Mercados que compran y venden** (`MERCADO`, `comprar_mercado`, `mercado_lista`): los clubs, Iñaki y la lonja tienen cada día tres variedades y dos extracciones (rosin, dry sift, ice, charas o static) con sus gramos; y compran varios lotes al día hasta su tope (los clubs, 200 g; Iñaki, su carga; la lonja, sus 500 g el día que carga).
- Prueba nueva `tests/negocios.gd` (284 comprobaciones; con `--pintar`, cada local por dentro y su puerta en la calle).

## 1.44.0 · 15 de octubre de 2026

El bajo de las setas entero (lo pidió el usuario: «los sprites y todo para crear el piso bajo, donde se cultivan, se secan, almacenan y se crean microdosis y comestibles»). Solo Godot (0.38.0), con `Datos.CAL`. Nada de método ni de dosis: lotes y cajas, como el resto del bajo.

- **Muebles nuevos** (`montar_setas`, `SETAS_PRO.x`), dibujados a mano en `tools/sprites/a-mano/bajo.py`:
  - el armario de almacén (3, 2), con sus tres baldas a la vista según lo lleno (`armS-<b>-<m>-<c>`);
  - la mesa de trabajo (7, 5), con la báscula y, si las tienes, la encapsuladora y los moldes (`mesaS-<e>-<m>`);
  - el deshidratador (8, 2), con setas y el piloto cuando está secando (`deshidS-<0|1>`).
- **Secar:** lo que recoges se tiende a secar (`S.setas.fr`).
  - En la malla del secadero tarda 3 días; con el deshidratador (90 €, de Txomin), 1.
  - Seco, pasa al armario al amanecer (`secar_setas`). El secadero y el deshidratador dicen cuánto se seca y qué día pasa.
- **Almacenar:** A en el armario lo abre por dentro (`vista_armario`, `rects_armario`): los botes de setas secas (uno por cada 50 g), las cajitas de microdosis y las cajas de comestibles.
- **La mesa de trabajo:**
  - con la encapsuladora (120 €), un lote de 10 g secos hace una caja de microdosis (1 h);
  - con los moldes (45 €), el lote más 6 € de chocolate hace una caja de comestibles (1 h 30).
- **Vender:** Txomin, en la puerta, compra las cajas: 140 € la de microdosis y 150 € la de comestibles. Sube el calor 2 por caja, y la redada se lo lleva todo.
- Prueba nueva `tests/bajo.gd` (45 comprobaciones; con `--pintar`, el bajo amueblado y el armario por dentro).

## 1.43.9 · 15 de octubre de 2026

El bajo de las setas a la vista (lo pidió el usuario: «que puedas entrar al bajo y veas las setas crecer»). Como el carro de esquejes, ya no es un menú. Solo Godot (0.37.9), con `Datos.CAL`.

- **Las baldas por dentro:** A en una de las tres estanterías del bajo abre la vista de las seis bandejas, dos por estantería, arriba y abajo (`vista_bajo`, `elegir_bajo`, `rects_bajo`). Se mueve con las flechas. A abre lo de las bandejas (pulverizar, recoger o tirar) y después vuelve a las baldas; B cierra.
- **Se ven crecer:** cada bandeja está dibujada a mano por rectángulos (`_bandeja_seta`).
  - El micelio blanco cubre el sustrato día a día y hora a hora (`t_seta`).
  - Después salen los primordios, los tallos y los sombreros, que se abren; cada seta va a su ritmo.
  - Las gotas de la tapa dependen de la humedad, y se ve lo contaminado (verde) y lo seco.
  - Las setas son genéricas, sin especie ni método.
- **La elegida, en grande:** a la derecha, con la barra de humedad y la del ciclo (colonizar → fructificar). El texto dice la fase, el % de micelio o de setas, el día de 10 y la humedad.
- Prueba nueva `tests/setas_vista.gd` (26 comprobaciones; con `--pintar`, las capturas día a día).

## 1.43.8 · 15 de octubre de 2026

Dónde está el bajo de las setas (lo pidió el usuario: «no existe mapa y sitio del bajo de las setas»). El bajo ya estaba (Ibarbide → el callejón junto a GROW IBARBIDE → la Kale Zaharra → la puerta gris de Txomin), pero nada en el juego decía dónde. Solo Godot (0.37.8), con `Datos.CAL`.

- **SMS de Julen:** con Ibarbide abierta (cap. 4, `SETAS.ch`) y el bajo sin alquilar, una vez (`S.flags.setasSms`), el sitio y cómo se llega (`SETAS_SITIO.sms`; se guarda en los SMS del móvil).
- **MÓVIL → Mapa:** al elegir Ibarbide, la línea del bajo de las setas (`SETAS_SITIO.mapa`, `desc_mapa` en `croquis.gd`).
- **El cartel de la Kale Zaharra** (8, 10) añade dónde está la puerta del bajo (`SETAS_SITIO.cartel`).
- Prueba nueva `tests/setas_sitio.gd` (23 comprobaciones: mapas, puertas, que se llega andando de la parada a Txomin y a la puerta, el SMS, el mapa y el cartel, y nada sin `Datos.CAL`).

## 1.43.7 · 15 de octubre de 2026

Las extracciones se venden donde los cogollos (lo pidió el usuario: «las extracciones se deberían de poder vender al por mayor, en clubes y donde se pueda vender cogollos»). Solo Godot (0.37.7), con `Datos.CAL`.

- **Al por mayor:** Iñaki y la lonja de Puerto Viejo te compran también las extracciones que llevas encima, desde 10 g (`VENTA_EXTR.min`), a la mitad de lo que pagan los catadores en la calle (`precio_rosin` × el `px` de cada extracción × `VENTA_EXTR.mayor`; la lonja, con su 15 % más). La carga del día cuenta en gramos de flor (1 g de extracción = 5 g de flor, `ROSIN.rend`), y el calor también.
- **En los clubs:** el lote del día puede ser una extracción, de 10, 25 o 50 g (`VENTA_EXTR.club_g`), a tres cuartos del precio de la calle (`VENTA_EXTR.club`).
- **El dispensario de la asociación:** se le puede dejar una extracción; los socios retiran 5 g al día en vez de 20 (`VENTA_EXTR.dia`).
- En la calle siguen comprándolas los catadores, como antes. El curado cuenta en todos los precios (`calidad`).
- Prueba nueva `tests/extr_venta.gd` (27 comprobaciones).

## 1.43.6 · 15 de octubre de 2026

El camarote de arriba, de almacén (lo pidió el usuario: «habilitar el camarote de arriba, el piso de arriba, como almacén», con «botes más grandes de cristal con bóvedas de humedad»). Solo Godot (0.37.6), con `Datos.CAL`.

- **La obra** (tienda online → El camarote: almacén, con tarjeta, llega al día siguiente): habilitar el camarote, 3.500 €; la escalera escamoteable baja en el piso entre la carpa A y la B, debajo de la ventana (`escaleraC` en (9, 2), se usa desde (9, 3); ORDENAR no deja nada ahí, `reserva_orden`, y lo que estaba se recoloca).
- **Arriba** (`MAPS.camarote`, 10 × 6): tarima de pino, techo abuhardillado con dos ventanas de tejado, murete de pladur, deshumidificador y la trampilla para bajar.
- **Estanterías de tarros de 10 L** (180 €, hasta 4): 6 tarros de cristal de 290 g cada una (`CAMAROTE.est`, `cam_cap`). Curan los lotes como los tarros de Kiko, sin necesitarlos.
- **Sobres de humedad al 62 %** (36 € la caja de 12 sobres de 67 g): un sobre por tarro dura 60 días (`CAMAROTE.dura`); con sobres, lo curado se afina en 14 días (`af`): +10 % en todas las ventas (`calidad`). Se gastan por tarros ocupados al día, con aviso al acabarse.
- **La vista por dentro** (CAMAROTE, como la caja y la nevera): los tarros de 10 L por estante, GUARDAR, la ficha con curado y afinado (`items_almacen("cam")`, `rects_almacen`, `_guardar_cam`).
- **La redada** se lleva lo del camarote: el desván no está escondido como la caja.
- Arte a mano en `tools/sprites/a-mano/camarote.py` (casillas, estantería, escalera, deshumidificador) y `almacen.py` (el fondo del camarote, el tarro de 10 L y lo de dentro). Prueba nueva `tests/camarote.gd` (70 comprobaciones).

## 1.43.5 · 15 de octubre de 2026

El APK también para móviles de 32 bits (lo pidió el usuario, tras la revisión de Gemini). Solo Godot (0.37.5).

- `export_presets.cfg`: `armeabi-v7a` además de `arm64-v8a`; el APK pasa de 52 a 75 MB. Firma v1/v2/v3 verificada.
- De la revisión de Gemini, lo demás ya estaba bien: el atlas y la vista C se leen con `load_png_from_buffer` (por eso `importer="keep"`), las fuentes `.woff2` las carga `FontFile.data`, `icono/` y `musica/` los genera `godot:apk`, los `.json` van por `include_filter`, los tests se excluyen, las licencias OFL tienen que ir y `libc++_shared.so` es de la plantilla oficial.

## 1.43.4 · 15 de octubre de 2026

Exportar e importar la partida, más escondidos (lo pidió el usuario). Solo Godot (0.37.4), con `Datos.CAL`.

- En OPCIONES ya no salen EXPORTAR PARTIDA ni IMPORTAR PARTIDA: van en COPIA DE SEGURIDAD, la última fila antes de VOLVER (`copia_seguridad` en `juego.gd`); en el título, solo importar. Siguen ahí para pasar la partida a otro móvil.
- Prueba nueva `tests/copia.gd`.

## 1.43.3 · 15 de octubre de 2026

Cada nombre con su muñeco (lo pidió el usuario: «los nombres de chica tienen que ir con personajes chica, y los chicos lo mismo»). Solo Godot (0.37.3), con `Datos.CAL` (las pruebas contra el HTML, como antes).

- **Los presidentes de los clubs:** Xabier (Itsaso) y Eneko (Kalea) salían con muñeco de chica y Rosario (La Fundición) y Nagore (Ensanche) con muñeco de chico; ahora Xabier de traje, Eneko de chico, Rosario la señora del moño gris y Nagore la de la melena (`GENERO.look`).
- **Bixente** (Mendialde), con muñeco de chico.
- **La agenda:** el nombre que le pones a un cliente de la calle es del sexo de su muñeco (`nombre_fijo`); y la chica que compra caro es la PIJA, y la del rosin, la CATADORA (`etiqueta_ct`).
- **La nave:** cada navero y quien cuida las madres sale con un muñeco de su sexo (Jaione, Edurne, Amaia… de chica; Mikel, Koldo… de chico; `look_genero`).
- **Yolanda**, la rival del Ensanche, ya no sale con barba (`look_rival`).
- **Los clubs:** en La Fundición y en el Ensanche quien está en la puerta es una mujer: «la encargada» en los textos (`con_encargada`, `GENERO.enc`), y las socias que hablan en el club salen como SOCIA.
- Prueba nueva `tests/generos.gd` (417 comprobaciones).

## 1.43.2 · 15 de octubre de 2026

Lo que cuesta tener un vehículo (lo pidió el usuario: «los coches y la moto sirven para no pagar el autobús para ir de pueblo a pueblo; el gasto es la gasolina, eso sí. Gasto al año de seguro y más cosas, igual al mes o por cierto uso de distancia»). Solo Godot (0.37.2).

- **Sin billete:** con tu vehículo, de parada en parada no pagas autobús, solo la gasolina del tramo (como en la 1.43.0).
- **El seguro, al año** (`seguro_anio`, `CONCE.anio`): se paga el año entero al firmar y se renueva domiciliado cada 365 días. Sin saldo, devuelto y, pasada la gracia, anulado, como antes.
- **El impuesto de circulación** (`CONCE.v[k].ivtm`, `S.coches[k].iv`): un recibo al año, domiciliado, desde el día de la entrega, según la potencia fiscal y con cuotas de ayuntamiento de hoy: 9 € la moto, 62 € el utilitario, 128 € la berlina y 232 € el superdeportivo. Sin pagar, devuelto y, pasada la gracia, por apremio con un 20 % de recargo (`CONCE.recargo`), cobrado de la cuenta, de lo que llevas y de la caja.
- **El taller, por km** (`kilometros`, `S.coches[k].km`): cada viaje suma sus km y, al pasar cada tramo, el taller cobra con su SMS:
  - la revisión (aceite y filtros): la moto cada 6.000 km (120 €), el utilitario y la berlina cada 15.000 (220 € y 320 €) y el superdeportivo cada 10.000 (1.600 €);
  - los neumáticos: la moto cada 12.000 km (160 €), el utilitario cada 40.000 (300 €), la berlina cada 35.000 (480 €) y el superdeportivo cada 15.000 (2.200 €).
- La ficha de cada vehículo dice lo que cuesta al año y por km; el seguro y el impuesto salen en la banca y en el calendario; al venderlo, sus km.
- `cobra` admite el campo de la fecha (`f`, «r» por defecto), para llevar dos recibos en el mismo vehículo.
- **Pruebas:** `tests/concesionario.gd`, 94 comprobaciones (el seguro al año, el impuesto y su apremio, los km y el taller a los 15.000 y a los 40.000).

## 1.43.1 · 14 de octubre de 2026

Vehículos de juguete y ruedas con llanta (lo pidió el usuario: «cuando está montando en la moto parece una bici», «no haría los coches tan realistas porque son demasiado grandes; debe ser un estilo y una escala lógica para con el personaje», «muy finas las ruedas de la moto; en sí son finas todas las ruedas, sin llanta casi»). Solo Godot (0.37.1).

- **La moto, un scooter:** gordito, con el culo redondo, el escudo azul curvo, el piso tapado, el guardabarros, los espejos y las ruedas pequeñas y gordas. Vas sentado: se te ve de la cadera para arriba (`VEHICULOS.moto`: `sube` 3, `corta` 25).
- **Los coches, de juguete:** más cortos y redondos, con la burbuja de la cabina, el techo redondo, los faros redondos y los pasos de rueda. Del tamaño del protagonista sentado, no de un coche de verdad.
  - El utilitario y la berlina con techo: se te ve la cara por el parabrisas. La visera de la gorra ya no se sale del cristal: con `cabina`, `_en_cabina` en `pinta.gd` solo pinta al protagonista por dentro de la cabina.
  - El superdeportivo, descapotable, con el parabrisas más bajo para que se te vea la cara de frente.
- **Ruedas gordas y con llanta** en todos los vehículos (`rueda_lado`, `rueda_frente` en `vehiculos.py`): contorno, goma y llanta clara con el buje y los radios que giran. De frente, la banda de goma más ancha con su dibujo. También en la bici y el patinete.
- **Pruebas:** en `tests/pantallas.gd`, la calle con la bici y con el patinete ya no son las del HTML congelado: lo que cambia tiene que quedarse dentro de la celda del vehículo (32 × 32) y todo lo demás, igual (`RUEDAS`).

## 1.43.0 · 14 de octubre de 2026

Ventanas centradas, el concesionario del barrio y las bandejas de clones de la nave (lo pidió el usuario: «esos pop-up o pestañas tienen que estar centradas como la nevera y la caja fuerte», «abren un concesionario en el barrio y puedes comprar una moto, un coche sin más, uno de gama media y un superdeportivo ya cuando tengas mucho dinero, precios realistas y todas las mecánicas realistas, espacio y lugar del concesionario con el atrezo, los coches y vehículos en venta», «en la nave debería haber bandejas de clones también, ¿no?»). Solo Godot (0.37.0).

- **Ventanas centradas** (`croquis.gd`: `LIBRE`, `centro_y`, `origen_mapa`/`origen_cal` con el alto libre; `alto_libre` en `ui.gd`):
  - El calendario y el mapa del móvil van centrados como la nevera y la caja: a lo ancho y, a lo alto, en lo que deja el cuadro del texto, sin que lo pise.
  - El mapa ya no lleva pestaña con el nombre encima del croquis, y sus textos son más cortos (como mucho tres marcas en el calendario: «y N más»).
  - El cuadro del texto ya no sale gigante la primera vez (se recoloca en el fotograma siguiente).
- **AUTOS RIBERA, el concesionario** (`D.CONCE`; `montar_alto` en `mundo.gd`; `talk_conce`, `comprar_coche`, `vender_coche`, `asegurar_coche`, `conce_dia`, `conducir`, `tramo`, `control_trafico` en `trama.gd`):
  - Abre en el barrio alto, al lado de la asociación, desde el capítulo 5 y con 20.000 € entre efectivo y cuenta. Avisa por SMS. Antes, el barrio alto está como siempre.
  - Por fuera: fachada con dos escaparates, el rótulo, la puerta de cristal de dos hojas, la acera y dos banderolas. Por dentro (18 × 10): suelo de baldosa, la pared con la franja azul, el rótulo, los precios, la cafetera, el expositor de catálogos, los neumáticos, plantas, la mesa de Arantxa (la comercial) con su ordenador y un cliente mirando.
  - A la venta, a precios de hoy con IVA: scooter de 125 cc (3.490 €), utilitario (15.900 €), berlina de gama media (34.500 €) y un superdeportivo de motor central (245.000 €). Todo el arte es propio y sin marcas.
  - Aparte, el impuesto de matriculación por emisiones (0 % hasta 120 g de CO2/km, 4,75 %, 9,75 % y 14,75 % desde 200 g, sobre el precio sin IVA; la moto, exenta) y 300 € de gestoría y placas.
  - En efectivo, como mucho 1.000 € (Ley 11/2021); el resto, por transferencia desde la cuenta.
  - Se entrega a los días de matricularlo (la moto en 2, el utilitario en 5, la berlina en 7) y el superdeportivo, bajo pedido, en 30. El superdeportivo, además, sube el calor: en el barrio se habla.
  - El seguro (de 190 € al año la moto a 4.900 € el superdeportivo) va domiciliado cada mes y sale en la banca y en el calendario. Sin saldo, el recibo se devuelve y, pasada la gracia, la póliza se anula.
  - Con un vehículo, en cualquier parada de autobús eliges «¿Cómo vas?»: vas a cualquier hora, sin esperar, en menos tiempo que el autobús, y pagas la gasolina por los km de cada tramo y el consumo del vehículo (1,60 €/l).
  - A veces hay control de tráfico (el superdeportivo, el triple). Sin seguro: 1.500 € de multa y el vehículo a la grúa hasta que lo asegures. Con algo encima, si te registran, te lo requisan con su multa.
  - Se puede revender: pierde un 20 % al salir del concesionario y un 1,2 % cada mes, hasta el 30 % de lo que valía. Lo pagan por transferencia.
  - La moto, además, se lleva en la calle: vas montado, más rápido que en bici. No se vende en la tienda online.
- **Los coches por la calle, a escala de juguete** (lo pidió el usuario: «este rollo de que el coche sea más bajo que el personaje mola, aunque no van a ser todos descapotables, con lo que habría un conflicto con el personaje y el techo del vehículo»; `VEHICULOS.utilitario`/`berlina`/`deportivo` con `sube` negativo y `corta`, `_pj` en `pinta.gd`):
  - El utilitario, la berlina y el superdeportivo también se llevan por la calle, más bajos que el protagonista de pie, y con el mejor que tengas (el superdeportivo, la berlina, el utilitario y la moto, por ese orden). El que está en la grúa, no.
  - El utilitario (blanco) y la berlina (gris) llevan techo: el protagonista va sentado dentro, de la cintura para arriba, y se le ve la cara por el parabrisas, con dos reflejos en el cristal; de espaldas, la nuca por la luna de atrás.
  - El superdeportivo (rojo) es descapotable: la cabeza y los hombros asoman por encima del parabrisas bajo, con el respaldo detrás y el alerón.
  - Cuanto más caro, más rápido (y con B, aún más).
- **Las bandejas de clones de la nave** (`S.nave.bc`; `corta_bandeja`, `bandejas_listas`, `bandejas_nave` en `trama.gd`):
  - Un carro con dos baldas, sus tubos T5 y sus bandejas con tapa, contra la pared, entre el secadero y el escritorio.
  - Antes de pasar cada mesa a 12/12, quien la cuida le corta 24 esquejes y los pincha en una bandeja. Echan raíces en un día (al ritmo del juego, como las mesas) y, al cosechar, la mesa vuelve a empezar con ellos.
  - Con A, el carro te enseña cada bandeja: de qué mesa es, la variedad y si ya tiene raíces. Las enraizadas también se pueden plantar a mano en una mesa vacía.
  - El carro se ve más o menos lleno según las bandejas.
- **Arte** (todo a mano y propio): `tools/sprites/a-mano/concesionario.py` (la fachada, el suelo y la pared, el rótulo, los precios, los neumáticos, los catálogos, la cafetera, las banderolas, la mesa, los cuatro vehículos de exposición y el carro de bandejas) y la moto y los tres coches (atrás y delante, en tres direcciones) en `vehiculos.py`.
- **Pruebas:** `tests/concesionario.gd`, 78 comprobaciones: los precios, el impuesto, la apertura, el edificio y su vuelta atrás, que se llega a todo, la compra con el tope de efectivo, la entrega, el seguro (cobrado, devuelto y anulado), el viaje, el control, la grúa, la reventa, el superdeportivo, la moto y los coches en la calle, las bandejas de clones y los renders. `tests/calendario.gd` comprueba el centrado (44 con los renders).

## 1.42.0 · 14 de octubre de 2026

El calendario de verdad, el mapa de la comarca y el juego en WordPress (lo pidió el usuario: «que empiece el juego el 20 de abril de 2026, y de ahí se van sumando días; 7 días son 1 semana; haz todos los días del mes y del año», «un mapa donde se vean todos los pueblos, no detalladamente pero modo croquis texturizado» y «convierte el juego en un plugin para WordPress como este, actualizado»). Solo Godot, 0.36.0.

- **El calendario** (`datos.gd`: `CAL`, `CAL0`, `fecha`, `dia_de`, `fd`, `fd_corto`, `fd_hud`, `fd_larga`):
  - El día 1 de la partida es el lunes 20 de abril de 2026. Cada día suma uno: semanas de lunes a domingo, meses con sus días (30, 31, 28 y 29 en los bisiestos) y años.
  - El HUD, el menú START y el móvil dicen el día de la semana y la fecha («LUN 20 ABR · 08:00»).
  - Los plazos, los recibos, los encargos, las primas, la asamblea, los esquejes, los logros y la banca dicen la fecha («antes de que acabe el 1 de mayo»). Si cae en otro año, lo dicen también.
  - El mes del clima de la sala es el del calendario (`Cultivo.mes_de`).
- **El calendario en el móvil** (MÓVIL → Calendario; `elegir_cal`, `marcas_cal` en `trama.gd`; `rects_cal`, `desc_cal`, `mueve_cal` en `croquis.gd`):
  - Muestra la hoja del mes, de lunes a domingo, con hoy en amarillo, los días pasados apagados y los domingos en rojo.
  - Marca los días señalados: el plazo de Don Baltasar en rojo, los recibos en azul, los encargos en verde y la asamblea en morado. Debajo salen con su texto.
  - Con las flechas cambias de mes.
- **El mapa de la comarca** (MÓVIL → Mapa; `elegir_mapa` en `trama.gd`; `croquis.gd`):
  - Es un croquis en papel con su grano: el mar con olas, la costa, la ría de Ribera Verde con las grúas de los astilleros, los montes de Mendialde, bosques, los campos y el molino de Errotabarri, las chimeneas de Valdehierro, el muelle de Puerto Viejo y la cuadrícula del Ensanche de Ibarbide.
  - Lleva las líneas de autobús a trazos desde Ribera Verde, con sus minutos. Los pueblos sin línea todavía salen en gris.
  - Marca dónde estás con una chincheta.
  - Con las flechas eliges un pueblo y te dice qué hay y cuánto cuesta el autobús.
  - La fuente de letras de 3 × 5 y todo el dibujo son propios.
- **Pruebas:**
  - `tests/calendario.gd`, 35 comprobaciones: el 20-4-2026 lunes, semanas de 7 durante 800 días, el 1 de mayo, el año nuevo, el 29 de febrero de 2028, el mes del clima, los textos, el calendario y el mapa dentro de la pantalla, los pueblos cerrados en gris y los renders.
  - Las pruebas contra el HTML congelado (historia, C1, capas y pantallas) ponen `Datos.CAL = false` y siguen como antes: «día N» y un mes por día.
  - `historia.gd` quita las dos filas nuevas del móvil (`NUEVO_MOVIL`).
- **La nave con opción a compra** (lo pidió el usuario: «cuando seas presidente de la asociación del barrio, alquilas con opción a compra la nave, por la tranquilidad; cada mes te da la opción de comprarla a tocateja, a un precio realista»). Está en `opcion_nave`, `comprar_nave`, `resto_nave`, `gastos_nave` y `nave_alquiler` (`trama.gd`), con los datos en `NAVE.compra`.
  - Siendo presidente, Arrieta te ofrece la opción. El día 1 de mes manda un SMS y, en la nave, sale «Opción a compra».
  - El precio es de 220.000 € por 320 m² en el polígono, unos 690 €/m². El alquiler de siempre, 60 € al día, son unos 1.800 € al mes (5,6 €/m²).
  - La prima es de 10.000 €, por transferencia, y se descuenta. La mitad de cada alquiler va a cuenta. El precio no se mueve.
  - Los 7 primeros días de cada mes puedes comprarla a tocateja con lo que falte más un 5 % de gastos (transmisiones, notario y registro), por transferencia desde la cuenta. Te devuelven la fianza.
  - El primero de mes, Arrieta manda un SMS con lo que queda. El calendario marca cuándo se puede comprar.
  - Comprada, no hay alquiler, ni recibo, ni cerradura que cambiar. Si dejas la nave antes, pierdes la opción.
  - Prueba: `tests/compra.gd`, 26 comprobaciones.
- **WordPress:** el plugin `landrace-hunters` 1.3.0 (`wordpress/`, `tools/wordpress.js` → `descargas/landrace-hunters-1.3.0.zip`).
  - Sirve la versión web del juego Godot de hoy (motor 4.3 sin hilos y el `index.pck` de esta versión, con la música).
  - Sigue igual que el plugin 1.2.0: dirección propia a pantalla completa, el atajo `[landrace_hunters]`, instalable como app y el panel de ajustes.

## 1.41.0 · 14 de octubre de 2026

La nave, por ciclos de cultivo, y la caja fuerte con los tarros que se llenarían de verdad (lo pidió el usuario: «el cultivo en la nave no funciona por ciclos; es muy importante que sea realista, también en el visor de la caja»). Solo Godot, 0.35.0.

- **Cada mesa, un ciclo entero** (`nave_dia`, `prog_mesa`, `cosecha_mesa`, `dias_mesa` en `trama.gd`):
  - Los clones de la madre entran en la mesa enraizando (`NAVE.clon`, 0,12, como los esquejes del piso). Crecen a 18/6 y florecen a 12/12 al ritmo de su variedad: 1/d por mañana, como las plantas del piso. La Skunk #1 tarda 3 días (unas 10 semanas reales); una sativa como la Kali Mist, 4.
  - Las fases salen del ciclo (`fase_mesa`): esquejes enraizando, vegetativo (18/6), floración (12/12) y cogollos engordando.
  - Al acabar, el navero corta la mesa entera y la cuelga en el secadero. Luego vuelve a empezar con los esquejes que sacó antes de pasarla a 12/12 (`Me.n`, el ciclo).
  - Sin navero, la mesa no avanza.
- **La cosecha, con cifras reales:**
  - El cálculo: los vatios de los focos × los g/W de cada luz (`FOCO_NAVE.w`, `gpw`), por la variedad y el fenotipo, el cuidado del navero, el riego y el calor.
  - Los focos: LED de barras 2 × 720 W a 0,85 g/W, como el LED 720 del piso; sodio 2 × 600 W a 0,55; cerámica 4 × 315 W a 0,7.
  - Una mesa de LED con la Skunk #1 da unos 1,4 kg por ciclo.
  - El abono cuenta por los días del ciclo que lo tuvo (`Me.am`, `Me.ao` de `Me.dn`).
  - Antes, cada mesa daba 20 g al día para siempre.
- **El secadero:** lo cortado cuelga `NAVE.seca` (1) día secándose (`Me.h`). A la mañana siguiente pasa a lo que se descuelga, con el día de la cosecha para el curado.
  - Mientras se seca, no se puede descolgar ni replantar la mesa.
  - La redada también se lo lleva.
- **Textos:**
  - Cada mesa y el escritorio dicen la fase, cuántos días faltan para la cosecha, el ciclo y lo que cuelga.
  - El navero explica cómo trabaja, y su ficha, cuánto da la cosecha con su cuidado.
  - El sodio ya no dice «más gramos»: da menos por vatio que los LED.
- **La caja fuerte, por tarros de verdad** (`items_almacen`):
  - Cada lote ocupa los tarros que llenaría: de 4 L, `ALM.tarro` = 115 g sin aplastar. 300 g son tres tarros (115 + 115 + 70), y cada uno se ve lleno a su nivel.
  - El texto dice en cuántos tarros va y cuánto lleva el elegido. Sacar sigue sacando el lote.
- **Las mesas de antes** (por días, sin ciclo) siguen igual hasta la primera mañana: entran en el ciclo casi al final y se cosechan.
- **Pruebas:**
  - `tests/nave.gd` (32 comprobaciones, en la batería): plantar, las fases día a día, la cosecha contada aparte, el secado, descolgar, el abono entero y a medias, sin navero, sodio < cerámica < LED, la sativa más larga, la mesa de antes, la redada con lo colgado y los tarros de la caja. Con `--pintar`, la caja llena.
  - La historia compara con el HTML congelado sin la parte de la nave de antes (`NAVE_DESDE`, `NAVE_R`, `PLANTA_NUEVA`, `SODIO_ANTES`). Esa parte la comprueba ahora con las cifras nuevas.
  - Las PNG de `caja-dentro` y `caja-guardar` de `tools/ref/pantallas/` son ya de Godot.

## 1.40.1 · 14 de octubre de 2026

Los esquejes de las bandejas, esquejes de verdad (lo pidió el usuario: «así es solamente una hoja; eso no es un esqueje»). Solo Godot, 0.34.1.

- **`CLON`, de 13 × 12 a 15 × 15:** el tallo largo, dos hojas de cannabis abiertas a los lados con sus peciolos, el brote de arriba y dos brotes en el tallo, como la referencia.
- **Las bandejas, sin el hueco de antes:** la tapa, encima de los esquejes, y las filas de tacos a 22 px para que quepa el esqueje entero; el carro mide lo mismo.

## 1.40.0 · 14 de octubre de 2026

El carro de esquejes, a la vista (lo pidió el usuario: «que no sea un menú; que se vea la bandeja, una arriba y una abajo»). Solo Godot, 0.34.0.

- **El carro por dentro** (`rects_carro`, `elegir_carro` en `trama.gd`; `pinta.gd` lo dibuja con `CARRO_V`): el carro con sus patas y ruedas y dos bandejas, la de arriba y la de abajo, cada una con su tubo T5, su tapa transparente y 12 alvéolos negros (6 × 2) con su taco de turba. Los 24 tacos se llenan por orden y cada esqueje sale en el suyo, dibujado a mano a 1 px: el tallo y una hoja de cannabis de 7 dedos con su nervio (`CLON`, `_esqueje`, `_taco`; en el propagador, `CLON_MINI`), del color de hoja de su variedad; el que está en su último día, amarillento (lo pidió el usuario al verlos: «eso no parecen clones de cannabis»).
  - Flechas para elegir el taco (`mueve_carro`), A para usarlo y B para cerrar; abajo, el texto del elegido (`desc_carro`).
  - A la derecha, el elegido en grande (`CLON_G`, 48 × 40, de `tools/sprites/a-mano/esqueje.py`; con la imagen de referencia del usuario): el tallo largo, cuatro hojas de cannabis de 7 dedos —las de atrás en sombra— y dos brotes, en su taco de turba suelto, con las raíces asomando por debajo según los días que lleva (`RAICES`); debajo, una barra con los días que le quedan y el propagador con los esquejes que esperan.
- **A en un taco vacío pincha** los del propagador (los mismos textos de antes: los que caben y los que se quedan); **A en un esqueje**, nombrarlo o tirarlo, como antes. Sin menú.
- **La cruceta, más ergonómica** (lo pidió el usuario: «más espaciadas las flechas del cuadrado del medio»): cada flecha es una tecla suelta con sus cuatro esquinas redondas, separada del cuadrado del medio por un hueco (`CRUZ_HUECO`, 0,16 del brazo, en `ui.gd`); el cuadrado del medio, redondeado y con su borde. La zona de toque no cambia: la flecha sale del ángulo desde el centro.
- **Pruebas:** `tests/carro.gd`, sin el HTML (24 comprobaciones: la rejilla y sus bordes, el dibujo de los 24 tacos, el marco del elegido, el del último día, todo dentro de la pantalla, pinchar, el carro casi lleno, tirar un esqueje, el taco vacío sin propagador; con `--pintar`, cuatro capturas).
  - La historia compara con el HTML congelado sin el texto ni el menú del carro de antes (`CARRO_FUERA`; el taco se elige con `gancho_carro`).

## 1.39.0 · 14 de octubre de 2026

La nevera, a tamaño de nevera (lo pidió el usuario: «cómo se van a poder meter solo 200 g en una nevera»; eligió la opción B). Solo Godot, 0.33.0.

- **La nevera de serie, 1 kg** (`NEVERA.g` en `datos.json`; antes, 200 g).
- **Arcón congelador en la tienda online:** 320 €, con tarjeta. Llega al día siguiente y lo dejan enchufado al lado de la nevera: caben 5 kg más (6 kg en frío).
  - Como la caja empotrada, no es un mueble aparte: se abre desde la nevera, que lo cuenta todo (`nevera_cap`, `S.nevera.arcon`: el día de llegada en negativo mientras está pedido, 1 en casa).
  - La redada vacía la nevera, pero el arcón se queda.
- **Botes de 40 g** (`NEVERA.bote`): lo que se ve dentro de cada bote ya no depende del tamaño de la nevera.
- **Pruebas:** `tests/nevera.gd`, sin el HTML (23 comprobaciones: 1 kg de serie, la fila de la tienda, sin dinero no se pide, cobro, llegada al día siguiente, 6 kg y el aviso, en casa, redada y partida guardada).
  - La historia compara con el HTML congelado sin la fila nueva de la tienda (`NUEVO_TIENDA`).
  - Las referencias de `nevera-dentro` y `nevera-guardar` pasan a ser las de Godot, con la nevera de 1 kg y los botes de 40 g.

## 1.38.0 · 14 de octubre de 2026

Cada extracción se ve mientras se hace (lo pidió el usuario: «que sea visual»). Solo Godot, 0.32.0.

- **Encima de la barra, la escena del paso** (`escena_extr.gd`, 160 × 76). Las máquinas son las del piso (`extraccion.py`), con sus colores y sus piezas, a 3 o 4 veces su tamaño, y se mueven como en el proceso de verdad. Abajo, a la derecha, un punto por paso: el de ahora, en verde.
- **Ice-o-lator en lavadora:** la lavadora de carga superior, con la cuba azul translúcida.
  - Al cargar, entra el agua con hielo y el termómetro marca la barra (por debajo de 4 °C).
  - En el lavado, a baja velocidad, los cogollos y los cubitos dan vueltas dentro, a un lado y al otro, con espuma; la lavadora tiembla y su luz verde parpadea.
  - En el reposo, la manguera desagua al cubo de las bolsas.
  - Al recoger, cada bolsa (120, 90 y 73) sube, escurre y deja la resina en el fondo, y pasa al tamiz de secar.
- **Ice-o-lator a mano:** el cubo de 20 L con las bolsas colgadas del borde, abierto por delante.
  - El hielo flota y el termómetro está a 1–3 °C.
  - La pala de madera remueve 15 minutos, con su reloj de cocina.
  - Se saca cada bolsa, de la de trabajo (220) a la fina; escurre y la resina va con la cuchara al cartón.
  - Al final, se desmenuza con el colador y se seca al aire del ventilador.
- **Dry sift:** el bastidor de madera con la seda (el de los tamices del piso).
  - Los cogollos desmenuzados saltan encima mientras las manos lo menean.
  - El polen cae al papel de cocina de la mesa: verdoso en el de 220, dorado en los finos.
  - El montón crece, la malla se cierra en cada paso y los tamices que quedan esperan apilados.
  - En el último paso, la tarjeta lo junta.
- **Rosin:** la prensa de palanca roja con sus planchas.
  - Al precalentar, la luz parpadea y el brillo es la barra.
  - Al apretar, la palanca baja despacio, la bolsa se aplasta y el rosin sale por los lados del papel.
  - Al soltar, el papel sale con el charco y se recoge con la herramienta.
- **Charas:** las palmas frotan la cola de la planta viva, en el monte, y se van oscureciendo. Después se rasca la resina y se amasa la bola.
- **Hachís prensado:** el kief envuelto en papel, tibio en la misma prensa. Al apretar se vuelve una placa marrón.
- **Moonrock:** el rosin se funde en su bote sobre la placa. El cogollo se baña con las pinzas, se reboza en el kief del cristal y se seca en la rejilla.
- **Static:** la máquina negra con su bandeja, las guías y la pantallita.
  - La flor congelada se tamiza a la bandeja.
  - La placa se carga con el paño y saltan chispas.
  - La altura de la placa es la barra: lejos, no sube nada; a su altura, suben las cabezas; demasiado cerca, sube también la hoja.
  - Al final, la tarjeta rasca la placa.
- El proceso se ha mirado en guías de extracción sin disolventes (agua con hielo a 1:1 y por debajo de 4 °C, 15–20 minutos suaves, reposo y bolsas de la gruesa a la fina; tamices de seda y flor congelada; papel de horno y presión poco a poco; carga estática; charas de la planta viva; moonrock bañado y rebozado).
- `extraer` pasa a `tiro_billar` la extracción y el paso (`TIRO.esc`, `paso`, `n`). El billar y las pantallas de antes no los llevan y no cambian.
- Prueba nueva, `tests/extracciones.gd`: en cada tipo y paso (28 escenas) comprueba que la escena se pinta y se mueve.

## 1.37.0 · 14 de octubre de 2026

Ordenar la casa, la asociación y la nave (lo pidió el usuario). Godot, 0.31.0.

- **La nevera, en su sitio.** De serie va entre la planta y el ordenador de la tía (2, 2), y abajo queda sitio para la esquina de los procesados. Con la tercera carpa montada, a su sitio de reserva (0, 6).
- **ORDENAR LA CASA** desde la mesa redonda, en cuanto se ha leído la carta: la nevera, la mesa redonda, las dos plantas, la mesa de manicurar, cada máquina de extracción, la tele, el PC gaming (con su silla), el sofá, el sillón, el carro de esquejes y la alfombra. Con las flechas se lleva, A la deja si cabe y B la devuelve a donde estaba. No cabe encima de otra cosa, en el hueco de una carpa ni cortando el paso (desde la puerta, a la cama y a todo lo que se usa); el motivo sale en el cuadro. La cama, la caja fuerte, el ordenador de la tía y lo de las paredes no se mueven.
- **ORDENAR EL LOCAL** en la asociación, siendo su presidente, desde una mesita: los sofás con sus socios, el billar con su jugador y la lámpara encima, la librería, la gramola y las plantas. El dispensario no se mueve.
- **ORDENAR LA NAVE** desde el escritorio: las cuatro mesas (con su foco, sus poleas y su trabajador) y el tanque del riego con el controlador y la máquina. La manguera sale del tanque por el pie de la pared y baja a cada mesa por el suelo libre, por el camino más corto. Una mesa o un tanque que la dejen sin camino no caben.
- La gente no se pisa: nadie se queda sin poder hablarle (desde al lado o por encima de un mostrador) y no se cuenta como paso libre; la planta de la entrada de la asociación se queda en su sitio de serie.
- Lo elegido se guarda en `S.coloca` (`12d-orden.js`: `ORDEN_P`, `posPieza`, `cabePieza`, `moverPieza`, `rutaRiego`, `mangueraNave`). Godot: `mundo.gd` (`pos_pieza`, `cabe_pieza`, `aplica_orden`, `ruta_riego`, `manguera_nave`) y `trama.gd` (`mover_pieza`, `ordenar`).
- Pruebas: un paso más en la historia (120) y tres pantallas (casa-orden, nave-orden y club-orden, 62).

## 1.36.2 · 14 de octubre de 2026

El taller de extracciones, contra la pared, y lo de dentro de los tarros y botes, como es de verdad (lo pidió el usuario). Godot, 0.30.2.

- **El paso, libre.** La lavadora, el cubo de mallas, la máquina de static y la mesa de manicurar (ahora en (4, 7)) van en fila contra la pared de abajo, a la izquierda de la puerta, y la prensa y los tamices, a la derecha (`MUEBLE_EXTR`): del salón y las carpas a la nevera y la cama se pasa por el medio sin rodeos.
- **Los cogollos, pelados o sin pelar.** Lo que se ve dentro de cada tarro depende del lote: manicurado (`alm-cog-p`: cogollos limpios, redondos y con más escarcha) o sin pelar (`alm-cog-s`: con las hojitas de azúcar asomando), siempre en el color de la variedad, con los pelos naranjas, y a cuatro niveles según lo lleno que está.
- **Cada extracción, la suya** (`alm-x-<tipo>`, cuatro niveles): el rosin fresco, ámbar y translúcido como savia, con su brillo; el rosin curado en frío, opaco y cremoso (badder); el tamizado en seco, un montón de arena rubia; el ice (bubble hash), arena rubia en grumos; el charas, bolas oscuras amasadas a mano, con el brillo de la grasa; el hash prensado, en placas marrones apiladas; el moonrock, cogollos bañados en aceite y rebozados en kief; y la static, un polvo finísimo, casi blanco.
- `tarro(…, den, k, v)` y `dentroLote` en `11m-almacen.js` (Godot, `_tarro` y `_dentro_lote` en `trama.gd`); arte a mano en `tools/sprites/a-mano/almacen.py`.
- Fuentes del aspecto: trimleaf.com (hash 101, tipos de hash), weedmaps.com (fresh press, cold-cure badder y jam), floraflex.com (cogollos manicurados o no), thebluntness.com (moon rocks) y la Junta de Control de la Marihuana de Alaska (dry sift); el charas y la static, por su descripción habitual.

## 1.36.1 · 14 de octubre de 2026

Los tarros y la nevera, más realistas (lo pidió el usuario). Godot, 0.30.1.

- Los tarros de cogollos (`alm-tarro`, `alm-tarro-s`): de cristal, con la tapa de rosca estriada más ancha que el cuello, los hombros y el culo redondos, el culo grueso y sus brillos. Por dentro, los cogollos apilados (`alm-cogos`: cada uno con su sombra, la escarcha arriba y algún pelo naranja, sobre el color de la variedad), la cima irregular (`alm-copa`) y la etiqueta de papel escrita a mano (`alm-etiqueta`), con el sello verde del curado.
- Los botes de los extractos (`alm-bote`): bajos, de boca ancha y culo grueso, con la tapa negra de rosca; en la nevera, lo vacío se ve blanco a través del cristal (`tarro(…, v)`).
- La nevera por dentro (`alm-nevera`): la junta de goma, el plástico blanco con las paredes en sombra y el fondo más frío abajo, el plafón con su luz, la rejilla del aire, las baldas de cristal con su canto, el perfil blanco, las guías y su sombra, los portaetiquetas y el visor de lo lleno que está como una pantalla.
- Todo a mano en `tools/sprites/a-mano/almacen.py`; Godot, `_tarro` en `trama.gd`.

## 1.36.0 · 14 de octubre de 2026

El curado sin pérdidas y con un 1 % más de THC, en la caja fuerte y en la nevera (adiós al arcón); tirar cogollos y extractos; los visores de la caja y la nevera dibujados, con GUARDAR y la ficha de lo que eliges; los minijuegos centrados; la mesa de manicurar; un mueble por cada extracción, con la lavadora y la máquina de static; las mallas 00; y las extracciones contadas como se hacen de verdad. Godot, 0.30.0.

- **Curar ya no corre prisa.** Lo que no está curado ya no pierde THC (tampoco lo que llevan tu plantilla o los vendedores). Con los tarros de Kiko, los cogollos se curan en la **caja fuerte** y los extractos, en frío, en la **nevera** (caben 200 g), en 2 días: pierden algo de agua, así que el THC sube un 1 % (no se crea THC: es el mismo en menos peso), y se venden un 15 % más caros.
- **Sin arcón.** Las cajas de al lado de la nevera ya no están: lo seguro es la caja de detrás del diploma (cogollos y dinero) y la nevera (extractos). Lo que no cabe al cosechar va a la caja fuerte y, si tampoco cabe, se queda encima. La redada se lleva la nevera y lo de encima (la caja, nunca); Darko, la mitad de lo de fuera y de la nevera; el gerente de la plantilla cosecha a la caja. En las partidas de antes, lo del arcón pasa a la caja (o encima, sin ella) y a la nevera, y el rosin que había en la caja, a la nevera.
- **Tirar productos.** Como las semillas: desde la MOCHILA, un lote de cogollos (con catar y analizar) o un extracto, la cantidad que quieras. El dinero, no.
- **Minijuegos centrados.** Las barras del billar y de las extracciones salen en el centro de la pantalla.
- **La mesa de manicurar.** Junto a las mesas de la tía, con las tijeras de punta fina, los guantes y la bandeja de rejilla: pela un lote de cogollos (medio minuto por gramo, como mucho 4 h) y se vende un 10 % más caro. El charas se frota aquí.
- **La caja fuerte, por dentro.** Dibujada a mano como el resto del juego: los fajos de billetes, el tarro de **GUARDAR** y los tarros de cogollos según lo llena que está, de más a menos THC; con las flechas eliges y con A sacas un tarro, guardas (todos los cogollos o un lote) o vas al menú del dinero.
- **La nevera, por dentro.** Abierta, con la fila de **GUARDAR** arriba (todos los extractos o uno) y un piso por tipo de extracción con sus botes, del de más THC al de menos; las filas corren en carrusel con las flechas, y con A sacas.
- **La ficha de lo que eliges.** Al lado de la caja y de la nevera, el tarro elegido en grande con su nombre, sus gramos, su THC, cuánto lleva curado y si está manicurado, en barras con iconos.
- **Un mueble por máquina.** Cada aparato se compra y, al tenerlo, se monta en el piso: la prensa de rosin en su mesita, los tamices de seda en su bastidor, el cubo con las bolsas de malla, la **lavadora de extracción** (900 €, desde el capítulo 4: una pequeña de carga superior, con la cuba de plástico azul; Ice-o-lator más limpio, con su barra al ritmo del motor) y la **máquina de static** (4.500 €, desde el capítulo 5: la placa cargada levanta las cabezas de la flor fría; su barra tiene la zona buena moviéndose). Cada una, con su minijuego.
- **Las mallas 00.** Escondidas en un arbusto de Mendialde: con ellas el dry sift lleva un paso más, la malla más fina, y sale menos pero más puro.
- **Las extracciones, como se hacen.** Los textos y los pasos de cada barra siguen el proceso real: el rosin con las planchas a 80-100 °C, la bolsa de 90-120 micras y la presión poco a poco; el dry sift con flor congelada de malla en malla (220, 160, 120 y 73 micras); el Ice-o-lator con hielo y agua a partes iguales por debajo de 4 °C, 15 minutos removiendo, reposo, bolsas de 220 a 73 micras y secado en frío; el charas frotado a mano de la planta viva; el hachís prensado del kief con calor suave; y la static, de la flor tamizada a la bandeja y la placa cargada a la altura justa.
- Arte a mano, sin PixelLab: la caja, la nevera, la ficha, los tarros, los botes, los fajos y los iconos de los visores en `tools/sprites/a-mano/almacen.py`; la mesa de manicurar, la prensa, los tamices, el cubo con las mallas, la lavadora (redibujada de carga superior, sin marcas) y la máquina de static en `tools/sprites/a-mano/extraccion.py`. Las partidas de antes: lo que había perdido no vuelve; desde hoy, nada se pierde.
- Igual en Godot. Tests: `npm test` 119/119 (paso nuevo: la caja y la nevera por dentro con GUARDAR, el curado en las dos, la manicura, la lavadora, la static y las mallas 00; la mochila y los extractos a salvo, sin arcón; el arcón de una partida vieja) y accesos 0 fallos; `test:arte` 29/29; Godot, historia 119 pasos, 59 pantallas (el piso con todas las máquinas, la caja y la nevera por dentro, las dos con GUARDAR elegido, y las barras de la static y la lavadora) y el ciclo.

## 1.35.0 · 14 de octubre de 2026

El dinero negro y el limpio; un local por pueblo para lavarlo; los recibos con su aviso; el billar a la bola 8; seis extracciones sin disolventes; la nave más real; y la pantalla de inicio nueva. Godot, 0.29.0.

- **El banco y el efectivo.** Ahora hay dos dineros: el efectivo de la calle (lo de siempre) y la cuenta del banco (empieza con 300 €). Con tarjeta, de la cuenta, se paga lo que deja rastro: la tienda online (muebles, vehículos y reformas), el banco de semillas del ordenador y los locales. En los cajeros (el barrio, Puerto Viejo, Valdehierro, el Casco Viejo y el Ensanche) sacas hasta 600 € al día e ingresas hasta 400 € de efectivo al día sin que el banco pregunte. En el móvil, BANCA: el saldo, los recibos que vienen y los últimos movimientos.
- **Un local por pueblo, para lavar.** El lavadero de los astilleros, la taberna de Puerto Viejo, el taller de Valdehierro, la quesería de Mendialde, la panadería de Errotabarri y la lavandería de Ibarbide: delante de cada uno, su cartel de «se traspasa». Los alquila un amigo de Don Baltasar, y solo cuando le has pagado lo bastante de la deuda (desde 3.000 € el primero hasta 30.000 € los de los pueblos y la ciudad). Fianza y recibo semanal, domiciliados; cada día metes en su caja hasta su tope de efectivo y a la mañana siguiente lo tienes en la cuenta como ingresos del negocio, menos los gastos e impuestos (del 10 al 15 %).
- **Los recibos, con su SMS.** La nave de Arrieta y el bajo de Txomin se pagan cada 7 días en efectivo (de lo que llevas y de la caja): te avisan dos días antes, y si no hay, vuelven al día siguiente; después cambian la cerradura. Los locales, domiciliados: el banco avisa, lo devuelve sin saldo y a los 3 días rescinde el contrato. Molina también avisa antes de que se acabe lo vuestro.
- **El billar, a la bola 8.** Una partida corta con la mesa a la vista (el tapete, las troneras y las bolas que quedan): en tu turno eliges el tiro (al hueco; al rincón, más difícil pero deja la blanca bien; o jugar seguro) y lo das en dos barras, la dirección y la fuerza. Si te pasas, la blanca se cuela y el otro juega con bola en mano. Cada rival juega distinto. Quien mete la negra con las suyas dentro, gana.
- **Seis extracciones, sin disolventes.** En la mesa del piso, además del rosin: el dry sift con los tamices de seda (60 €), el Ice-o-lator con agua y hielo (140 €), el charas a mano, el hachís prensado (del kief de los tamices o del hielo) y el moonrock, lo más difícil (un cogollo bañado en rosin y rebozado en kief). Cada una es una tanda de barras: cuantas más en el verde, más rendimiento y más THC, con cifras reales (el dry sift saca un 10 % de la flor, el hielo un 12 %, el charas un 4 %). Los catadores de la calle compran de todo, cada uno a su precio.
- **La nave, más real.** El agua entra por un grifo encima del tanque; de la bomba sale la tubería por el pie de la pared, con abrazaderas, y en cada mesa una T con su llave (o su electroválvula, con el cable al controlador) y la bajada a la bandeja. Tu gente ya no está siempre plantada delante de su mesa: a lo largo del día se mueve alrededor de ella, sin tapar nada.
- **Cada cosa en su sitio.** GROW IBARBIDE, con la carpa de exposición al fondo, fuera del paso, y las baldas detrás del mostrador.
- **La pantalla de inicio, nueva.** Detrás del azul, el barrio de verdad, como un vídeo: tú paseando, un cliente esperando y una patrulla pasando. El lema, «Caza genéticas. Salda la deuda. Que no te pillen.», y los botones grandes, en pastilla, con el elegido marcado; se abren solos, sin «pulsa START».
- Las partidas de antes: la cuenta con 300 € y los recibos a 7 días desde hoy.
- Arte a mano, sin PixelLab: los cajeros, los carteles de los locales y el edificio de ladrillo de los astilleros, la mesa del billar y la tubería de la nave. Igual en Godot. Tests: `npm test` 118/118 (pasos nuevos: las extracciones y el banco con los locales) y accesos 0 fallos; `test:arte` 29/29; Godot, historia 118 pasos, pantallas y el ciclo.

## 1.34.0 · 14 de octubre de 2026

Cada local, el suyo; el bajo de las setas por dentro; las madres de la nave y más mando sobre tu gente; los clubs de fuera, con su presidente. Godot, 0.28.0.

- **El bajo de Txomin, por dentro.** En la Kale Zaharra, la casa de Txomin tiene ahora su puerta de chapa al bajo: cerrada con candado si no lo alquilas y, si lo alquilas, se entra (10 × 7, a oscuras con una bombilla). Tres baldas con las bandejas a la vista en su fase (recién sembrada, colonizando, con setas, contaminada o seca), el pulverizador de mochila, el secadero (vacío o con setas), la tubería que suda, las cajas de Txomin y el cubo. En las baldas se pulveriza, se recoge y se tiran las malas; comprar bandejas, venderle las setas y dejar el bajo, con él en la puerta.
- **Cada club, distinto.** Ya no son el mismo local con otro nombre: Kalea (Casco Viejo), el pequeño, de piedra y vigas con terciopelo granate; Itsaso (Puerto Viejo), marinero, con tablas de cubierta, cuero azul, ojo de buey, timón y red; La Fundición (Valdehierro), grande, de hormigón y ladrillo, con cuero marrón, barriles de mesa, diana y un engranaje; Ensanche, el más grande, blanco y moderno, con sofás de diseño, mesas de cristal y un neón con una hoja; y la asociación de la tía Maite, con sus libros y las copas de sus premios. Cada uno con su suelo, su pared, sus sofás, mesas, vitrina y billar, de 15 × 8 a 20 × 10, con más sofás (de 2 a 5 grupos), el billar con sitio alrededor para jugar, la lámpara encima y más socios sentados que hablan contigo.
- **Los clubs de fuera se ganan.** En la asociación del barrio los socios ya te conocen por la tía, pero en Itsaso, La Fundición, Kalea y Ensanche no compran a cualquiera: para venderles un lote o aceptar un encargo de semillas tienes que ganarte al encargado y a su presidente o presidenta (Xabier, Rosario, Eneko y Nagore, sentados en el club), 15 de confianza con cada uno. Suma hablar con ellos cada día, invitarles a probar 2 g de lo tuyo (una vez al día cada uno), comprar en el dispensario y, ya dentro, vender y cumplir. Cuando se fían los dos, te lo dicen. En el móvil, GENTE, salen los presidentes y lo que falta. Las partidas de antes: donde ya vendías, se fían de ti.
- **Los grows, distintos.** El de Kiko, con su pizarra de consejos (cambia cada día), sacos de sustrato y macetas de tela. GROW IBARBIDE, más grande (12 × 9): baldosa gris, ladrillo blanco, neón verde, botes de abono en la pared, el propagador de esquejes y una carpa de exposición montada con su LED.
- **La carpa de las madres, en la nave.** A la derecha, una carpa de 150 × 150 a 18/6 con hasta 4 madres: mete una con una semilla o un esqueje de lo que quieras guardar. Pon a alguien de tu plantilla **a las madres** (30 € al día): cada mañana las riega y les saca un esqueje (dos, con cuidado 4 o más), hasta 4 por madre, que recoges en la carpa al propagador. Las mesas se plantan con el clon de una madre sin gastar nada. Sin nadie que las cuide, pierden vigor y se mueren.
- **Más mando sobre tu gente.** En el escritorio de la nave, LA GENTE: quién cuida cada mesa y las madres, cambiarlos de mesa (si está ocupada, se cambian) y, a cualquiera de la plantilla (también desde el móvil), una **prima** (100 €: lealtad +1; con lealtad 5, no hace falta) o un **curso** (250 €: cuidado +1; a los de la calle, labia +1), hasta 5 y una vez por semana cada uno.
- **Todo se puede andar.** Prueba nueva, `node tools/test-accesos.js` (va en `npm test`): en los 26 mapas con todo montado, desde cada entrada, se llega a cada puerta y salida, se puede hablar con cada persona quieta y mirar cada mueble; arregló una mesita encerrada entre sofás, una caja tapada y gente parada delante de la estantería.
- Arte a mano, sin PixelLab: suelos, paredes, sofás, mesas, vitrinas, billares y lo de las paredes de cada club, el bajo y sus bandejas, la fachada de la casa de Txomin, los grows y la carpa de las madres en `tools/sprites/a-mano/locales.py`. Las partidas de antes: la nave, con la carpa vacía.
- Igual en Godot. Tests: `npm test` 116/116 (paso nuevo: los locales y las madres) y accesos 0 fallos; `test:arte` 29/29; Godot, historia 116 pasos, 52 pantallas (los cuatro clubs nuevos, el bajo con sus bandejas y la nave con las madres) y el ciclo.

## 1.33.0 · 14 de octubre de 2026

La nave, equipada de verdad: focos a elegir, extracción con filtros y riego que crece contigo. Delroy, con rastas. Godot, 0.27.0.

- **Focos por mesa: LED, sodio o cerámica (CMH).** En cada mesa de la nave, FOCOS: LED de barras (dos de 720 W, 1.800 €: gastan poco y apenas calientan), sodio (dos campanas de 600 W con balastro, 600 €: un 10 % más de gramos, pero el doble de calor) o cerámica (cuatro de halogenuro metálico cerámico de 315 W, 1.400 €: luz de día con algo de ultravioleta, un punto más de THC). Los de antes se los queda Arrieta. Cada uno con su dibujo y su luz: rosada, naranja o blanca.
- **Los focos cuelgan de poleas** y nunca tocan las puntas: dos cuerdas por foco bajan del techo (se desvanecen hacia arriba) a dos poleas con su tirador, y el foco queda a unos centímetros de la planta más alta de la mesa; a medida que crecen, sube, como en las carpas de casa.
- **Extracción con filtros de carbón**, en el escritorio → MEJORAS: un extractor de 250 mm con su filtro (450 €), uno de 315 mm con dos filtros (1.200 €) o dos de 315 mm con cuatro filtros (2.600 €). Cada nivel saca más calor y deja salir menos olor: la redada en la nave baja al 70 %, al 45 % y al 25 %. Si los focos calientan más de lo que saca la extracción (CLIMA, en el escritorio), las plantas crecen menos: un 8 % por cada punto de más, hasta un 40 %.
- **La estantería cuenta los decimales**: con el controlador o la máquina, cada mesa gasta 0,8 o 0,7 dosis, y lo que queda se ve con su decimal (antes, «×0» con abono todavía dentro).
- **Riego escalable**, también en MEJORAS: el tanque de 1.000 L con su bomba y una manguera a cada mesa (650 €: el abono ya mezclado, +5 % de gramos), el controlador de riego con electroválvulas y un gotero por maceta (1.600 €: +10 % y un 20 % menos de abono) y la máquina de fertirrigación que mide el pH y la EC y dosifica sola (4.500 €: +18 %, medio punto más de THC y un 30 % menos de abono). Todo se ve montado en la nave: los extractores y los filtros en la pared, el controlador, el tanque con su palé y su bomba, la máquina y la manguera por la pared del fondo bajando a cada mesa. La nave sube de nivel: pelada, apañada, en marcha, seria, profesional, de concurso e industrial.
- **Delroy, con rastas**: las rastas canas, en cordones con su vuelta y las puntas sueltas por encima de los hombros; de frente, dos le caen sobre el pecho.
- **La foto de la tía Maite, más grande y mejor**: ocupa dos casillas, con marco de madera tallada, paspartú, la tía Maite y Delroy de jóvenes en un campo junto a una mata en flor, y la placa de latón.
- **La APK, por GitHub**: va en `descargas/LandraceHunters.apk` de la rama, para descargarla entera desde el enlace.
- Arte a mano, sin PixelLab: los focos, extractores, filtros, controlador, tanque y máquina y la foto en `tools/sprites/a-mano/locales.py`; las rastas, en `tools/sprites/a-mano/delroy.py`. Las partidas de antes llevan LED en todas las mesas y la nave sin mejoras.
- Igual en Godot. Tests: `npm test` 115/115 (paso nuevo: la nave equipada); `test:arte` 29/29; Godot, historia 115 pasos, 47 pantallas (la nave equipada a tope, con sodio y cerámica) y el ciclo.

## 1.32.0 · 14 de octubre de 2026

Mesas de la nave que parecen mesas, la asociación de la tía Maite y Delroy. Godot, 0.26.0.

- **Las mesas de la nave, de nuevo.** Ahora se ven a medio fondo, como el billar: la bandeja blanca con su borde, las acanaladuras y el desagüe, el bastidor y las patas, con el suelo por debajo, y los dos LED de barras colgados encima. En cada mesa, **cinco macetas de 11 L a tresbolillo**: tres en la fila de delante (la de los trabajadores) y dos en la del fondo, en los huecos. Las plantas son más grandes y se ven desde arriba, con su **corona y las puntas**, nada de pinos: matas con hojas de cinco y siete dedos y, en flor, las colas con sus pistilos; el porte y los colores siguen saliendo de la variedad (índica, ancha y baja, con cogollos gordos; sativa, alta y fina, con colas largas).
- **La Asociación Cannábica Ribera Verde**, en el barrio alto, junto a la comisaría (desde el capítulo 3): la casa alta de almagre con la placa de latón, la ventana esmerilada y el portal verde. Por dentro es un club (el carné en la puerta, el dispensario, los sofás con Imanol, el billar con Koldo), y en la pared, **la foto de la tía Maite**.
- **Delroy, el «tío» que nunca lo fue de papeles.** La segunda vez que vas (otro día) está junto a la foto: el compañero jamaicano de la tía Maite durante treinta años, mayor, con las rastas y la barba canas, camisa crema con una cadena fina, pantalón de pinzas y botas de ante color camel. Te cuenta que ella fundó la asociación y la presidió muchos años, y que desde que se fue la lleva una gestora y la presidencia está vacía. Entra en MÓVIL → GENTE.
- **Presidir la asociación**, de dos maneras: **presentarte** a la asamblea (a los 3 días, al amanecer; hacen falta 21 votos de 40: votan por ti 8 de los de siempre de la tía, Delroy 4, cada uno del barrio que se fía de ti —Kiko, Julen, Josune, Begoña, Patxi, Txaro e Iñaki, con 20 de confianza— otros 4, y uno por cada 10 de confianza con la asociación; si gana la gestora, a los 7 días puedes volver a presentarte) o **refundarla**, pagando 3.000 € de deudas y registro (también con la asamblea pendiente). De presidente, **el dispensario**: le dejas a Delroy un lote (50, 100 o 200 g) y cada mañana los socios retiran 20 g a precio de club con un 15 % más; el dinero, a tu buzón. Logro nuevo: «Como la tía Maite».
- Arte a mano, sin PixelLab: la mesa, las macetas y las plantas y la fachada de la asociación y la foto en `tools/sprites/a-mano/locales.py` (con la Ó con su tilde en la placa); Delroy, del dibujo de Kiko, por zonas, en `tools/sprites/a-mano/delroy.py`, con sus ojos, su respiración y su porro.
- Igual en Godot. Tests: `npm test` 114/114 (paso nuevo: la asociación); `test:arte` 29/29; Godot, historia 114 pasos, 46 pantallas (la asociación por fuera y por dentro, con Delroy, y la nave con las mesas nuevas) y el ciclo.

## 1.31.0 · 14 de octubre de 2026

Menús largos con flechas, garrafas de abono, pH− por litros y las plantas de la nave según la variedad. Godot, 0.25.0.

- **Los menús largos ya no se salen de la pantalla.** Los de la derecha (el arcón y la caja fuerte con muchos lotes, ¿QUÉ LOTE?, las preguntas con muchas respuestas, START) enseñan las filas que caben entre el borde de arriba y el diálogo, con ▲ y ▼ cuando hay más arriba o más abajo; la cruceta llega hasta el último, y ▲ y ▼ también se tocan. La misma cuenta en el HTML y en Godot, a cualquier tamaño de pantalla.
- **Garrafas de abono** de 5, 10 y 25 L (desde los capítulos 2, 3 y 4) de los cuatro abonos, MEATZA y ORTUA BIO, además de la botella de 1 L: 4 dosis el litro, y cuanto más grande, más barata la dosis (la floración MEATZA: 14 € el litro, 55 € la de 5 L, 99 € la de 10 L, 215 € la de 25 L).
- **pH− por litros**: la botella de 250 ml pasa a ser de 1 L (capítulo 1), 2 L (capítulo 2) y 5 L (capítulo 3), 40 dosis el litro (MEATZA 10, 17 y 35 €; ORTUA BIO 12, 20 y 42 €).
- **Las plantas de la nave, según su variedad.** Como en las carpas de casa: el porte sale del % índica (índica baja y ancha, sativa alta y fina, híbrida entre las dos) y el color de las hojas y los cogollos, de la variedad. Las mesas pasan de verde a la flor con sus pistilos y a los cogollos maduros; dibujadas a mano y nuevas (`tools/sprites/a-mano/locales.py`, encima de la mesa). Y encima de cada mesa, dos **LED de barras como los de las carpas** (de 100 cm y 8 barras, colgados de sus cuerdas con trinquete y la fuente encima): encendidos con la mesa plantada, con su luz rosada sobre las plantas, y apagados con la mesa vacía.
- **Arreglos de los locales.** El billar no empieza siempre la barra en el mismo sitio (contar ya no vale). La RRPP de GAUA mira antes de cobrar si cabe alguien más en la agenda. Cada trabajador de la nave tiene su mesa fija (despedir o mover a uno ya no cambia la mesa de los demás; las partidas de antes conservan la que tenían). Lo que se recoge en el secadero lleva el día de la cosecha (y empieza a contar el curado desde ahí). La barra, el DJ y el reservado de GAUA, cerrados a partir de las seis. En Godot, una canción grabada que no se puede leer suena con la de reserva en lugar de quedarse en silencio.
- Igual en Godot. Tests: `npm test` 113/113 (paso nuevo: garrafas y botellas de pH−; el de la plantilla, con la mesa fija y el día del secadero; el de los locales, con la agenda llena, GAUA cerrada y la partida vieja); `test:arte` 29/29; Godot, historia 113 pasos, 44 pantallas (la nave con cuatro variedades en sus fases) y el ciclo.

## 1.30.0 · 13 de octubre de 2026

Los locales se entran como una casa y la música es nueva. Godot, 0.24.0.

- **Los clubs por dentro.** Cada club (Itsaso en Puerto Viejo, La Fundición en Valdehierro, Kalea en el Casco Viejo y el del Ensanche) tiene su fachada propia con su puerta, y dentro una sala de 12 × 8: el dispensario con la vitrina y el encargado detrás (comprar, vender, encargos, como antes), los tarros, la pizarra con la variedad del día, las normas, los sofás chester con la mesa baja, el billar bajo su lámpara de techo, el taquero, la gramola y las plantas, en penumbra cálida. El carné se pide en la puerta la primera vez.
- **Billar con apuesta.** El del billar juega a 10, 20 o 50 €: 3 tiros cada uno con una barra de fuerza que va y viene (A en el verde, la bola dentro, 3 puntos; en el amarillo, la rozas, 1). Quien sume más se lleva la apuesta; 3 partidas al día con cada uno, y ganar suma confianza con el club.
- **Un socio en los sofás.** Se charla o se comparte un gramo de lo tuyo (una vez al día, media hora): +3 de confianza con el club.
- **La nave por dentro.** Cuatro mesas de cultivo en fila, una por trabajador (cada uno junto a la suya). Plantas tú, con semilla o esqueje (el THC sale de la variedad y del fenotipo, y la estrella va a su lote), y eliges el abono de cada mesa: MEATZA u ORTUA BIO, que se dejan en la estantería y se gastan una dosis por mesa y día (más gramos y algo más de THC). Cada mesa pasa por recién plantada, creciendo, en flor y dando cogollos, que se ve en la mesa; desde el quinto día cuelga cada mañana lo suyo en el secadero, que se recoge allí. El escritorio enseña las cuatro mesas. Sin alquilar, la persiana está echada. Las naves de antes pasan su variedad y lo que había en el secadero a las cuatro mesas.
- **GAUA, la discoteca del Ensanche** (desde el capítulo 4, de 23:00 a 6:00). El portero cobra la entrada (15 €, una vez por noche). Dentro: la barra (copa 10 €, hasta 3; invitar a una ronda 40 €, +1 de reputación), la pista con luces de colores, la cabina del DJ (bailar media hora; a veces alguien te pide el número y entra en la agenda) y el reservado (300 €, una hora): la RRPP te presenta a un **cliente VIP** que va a la agenda. El VIP pide de lo bueno, como un pijo, y paga un 60 % más. A las seis se encienden las luces y el portero echa a todo el mundo. La gente de GAUA cuenta como una sola confianza en MÓVIL → GENTE.
- **Música nueva** (solo en la app de Godot): 40 canciones grabadas en lugar del chiptune, con instrumentos de verdad sintetizados (piano eléctrico, guitarra, bajo, acordeón, órgano, cuerdas, metales, marimba…), batería, reverb y eco, cada una con su intro y su bucle sin cortes. Una por sitio y momento: cada zona de la calle de día y otra de noche, el piso de día y de noche, el growshop, el bar, el club, la nave, GAUA, la comisaría, el almacén, el caserío, el título, el final, la alarma de la patrulla, la redada y cuatro combates (ladrón, policía, rival y Darko).
- Igual en Godot (los locales, la luz de cada uno y la barra del billar). Arte a mano, sin PixelLab: `tools/sprites/a-mano/locales.py` (fachadas, suelos y paredes, la pista y los muebles, con la mesa de cultivo en sus cinco fases); la gente de los locales sale de los personajes que ya había.
- Tests: `npm test` 112/112 (paso nuevo: los locales; el de los clubs, dentro del club; el de la plantilla, con las mesas, la estantería y el secadero de la nave); `test:arte` 29/29; Godot, historia 112 pasos, 44 pantallas (el club con la barra del billar, la nave con sus mesas y GAUA de noche) y el ciclo, con la música grabada.

## 1.29.2 · 13 de octubre de 2026

Precio real del analizador. Godot, 0.23.2.

- El analizador de cannabinoides y terpenos cuesta 3.000 € en el growshop (antes, 180 €), como un aparato de verdad que mide THC, CBD y terpenos; pedido a Kiko por el móvil, 3.450 € (su 15 %). Lo demás de lo añadido últimamente ya tenía precios de tienda reales (tarros 30 €, medidor de pH y EC 35 €, prensa de rosin 250 €, carro de esquejes 165 €, deshumidificador 190 €, aire acondicionado 320 €, PC gaming 1.490 €) y no cambia.
- Igual en Godot. Tests: `npm test` 111/111; Godot, historia 111 pasos.

## 1.29.1 · 13 de octubre de 2026

Lo que quedaba del curado. Godot, 0.23.1.

- El lote que le dejas a un vendedor de la agenda también pierde THC si no está curado, como el de la plantilla: cuenta desde el día de la cosecha, no desde el día en que se lo das, y vende al THC que le queda. Curado, no pierde.
- Las partidas de antes: el día que guardaban los vendedores era el de la entrega; se borra al cargar, así que lo que ya llevan no pierde nada (como los lotes de antes de la 1.29).
- Igual en Godot. Tests: `npm test` 111/111 (el paso del curado añade el vendedor: el día de la cosecha, lo que pierde, uno de antes que no pierde y la partida vieja); Godot, historia 111 pasos.

## 1.29.0 · 13 de octubre de 2026

La hierba se cura y, sin curar, se estropea. Godot, 0.23.0.

- **Nuevo: el curado.** Cada lote de cogollos lleva el día de la cosecha y sale **sin curar**. En el arcón de casa, con los **tarros de curado** de Kiko (30 €, en el growshop o por el móvil, desde el capítulo 1), se cura en 2 días. Curado, el THC no sube (como en la realidad), pero se vende un 15 % más caro en la calle, a Iñaki (los 10 g y al por mayor), en la lonja, en los clubs y con los vendedores y la plantilla, la cata lo nota («Bien curada: suave y con todo el aroma») y ya no pierde nada.
- **Nuevo: perecedera.** Sin curar, a los 3 días de la cosecha empieza a perder un 2 % de su THC cada día, esté en la mochila, en el arcón o en la caja fuerte (a medio curar, la mitad). Al amanecer avisa el primer día que pierde («Sin curar, pierde THC: …») y el día que queda curada en el arcón.
- La primera cosecha lo cuenta, una vez. En la MOCHILA, cada lote dice si está curado, curándose o desde qué día pierde, y al catarlo sale en la línea («· curada», «· sin curar»). El arcón dice que con los tarros se cura lo de dentro.
- Al juntar dos lotes (cosechar otra de la misma variedad, guardar o sacar del arcón), el THC, lo curado y el día van por gramos. Lo que compras en un club ya viene curado. Lo que lleva alguien de la plantilla en la calle también pierde si no está curado, y lo que le queda vuelve al arcón con su curado y su día (los lotes de antes, sin día).
- Las partidas de antes: los lotes que ya tenías no pierden nada (no tienen día); lo que coseches desde ahora, sí.
- La misión «Llegar al 27 %» avisa: sin curar, a los 3 días empieza a perder THC; preséntala antes o cúrala en el arcón.
- Igual en Godot. Desde esta versión solo se construye y se entrega la app de Godot: el HTML queda como fuente de datos, arte y pruebas de Godot (`npm run godot`), sin APK propia.
- Tests: `npm test` 111/111 (paso nuevo: los tarros, 2 días de curado en el arcón, lo que pierde un lote sin curar desde el 4.º día, los avisos, el precio al por mayor un 15 % más alto, la cata, cómo se juntan los lotes y la plantilla); Godot, historia 111 pasos, 41 pantallas y el ciclo.

## 1.28.0 · 13 de octubre de 2026

Misiones para la Copa: cómo llegar al 27 %. Godot, 0.22.0.

- **Nuevo: tres misiones en el capítulo 6**, en START → OBJETIVO, con su SMS de Kiko y su regalo, como las de antes:
  - **Una genética potente:** la marca de Darko es una Amnesia Haze del 26,8 % y, sin un fenotipo estrella, solo pasan de ahí, con buena luz y abono, las de receta del 26 % o más (Amnesia Haze, Jack Herer y Sour Diesel). La más a mano, la Sour Diesel: Chemdawg × Super Skunk en la mesa, con sus precios. Se cumple al sacar una en la mesa. Regalo: 4 dosis de MEATZA FLORACIÓN y 4 de pH−.
  - **Floración a tope:** el LED de 720 W (+1,4 de THC; en la carpa de 120 o la de 150) y el abono de floración con pH− y el medidor (+0,3 si lo aprovecha entero; el orgánico, +0,4). Se cumple con una planta abonada así bajo el LED de 720 W. Regalo: 2 dosis de ORTUA BIO FLORACIÓN y 2 de su pH−.
  - **Llegar al 27 %:** 20 g de un solo lote en la mochila con más del 26,8 %, redondeado como lo mide el jurado; recuerda que el lote se queda con la media (cosecha la mejor y preséntala antes que otra de la misma variedad; las de fenotipo estrella van aparte). Se cumple al tenerlo y Kiko te manda al jurado.
- Al ganar la Copa, las que falten se dan por hechas, sin aviso ni regalo, igual que en las partidas que ya la ganaron. Nada cambia en el equilibrio: la marca sigue en 26,8 %.
- Igual en Godot.
- Tests: `npm test` 110/110 (paso nuevo: las tres misiones, con 26,8 % que no llega y 26,9 % que sí, sus SMS y regalos; al ganar la Copa, la que falta, cerrada, también en `migrate`); Godot, historia 110 pasos, 41 pantallas y el ciclo.

## 1.27.1 · 13 de octubre de 2026

Una silla delante de cada ordenador. Godot, 0.21.1.

- **Nuevo: la silla de madera de la tía**, delante de su ordenador del dormitorio, y **la silla gaming** (negra con franjas magenta, pistón y base de cinco radios), que llega con el PC gaming (ahora «PC gaming con mesa y silla», al mismo precio) delante de su mesa, en sus dos casillas. Las dos se ven por detrás, mirando a la pantalla, y no se pisan: con A sobre la silla, desde cualquier lado, se usa el ordenador que tiene delante. Arte a mano en `tools/sprites/a-mano/salon.py` (`silla`, `sillaG`).
- Igual en Godot. En `docs/MAPA.md`, las sillas son `r`.
- Tests: `npm test` 109/109 (el paso de la 1.27 mira las sillas: sólidas, A hacia el ordenador y la gaming con el PC); `test:arte` 29/29 (las sillas, también sin atlas); Godot, historia 109 pasos, 41 pantallas (el piso, con las dos sillas) y el ciclo.

## 1.27.0 · 13 de octubre de 2026

La casa a tu gusto y los logros. Godot, 0.21.0.

- **Nuevo: reformas del piso**, en la tienda online (REFORMAS: SUELO Y PAREDES). El suelo, en tarima de roble (la de serie), de nogal, vinílico gris o baldosa hidráulica, y las paredes, en papel crema de rayas (el de serie), pintura verde salvia o azul grisáceo, o ladrillo visto, con precios reales por los 108 m² de suelo y unos 120 m² de pared, colocación incluida. Se paga al pedir y el instalador o el pintor viene al día siguiente; lo que ya tienes sale como «en casa». Arte a mano: `tools/sprites/a-mano/casa.py` (asset `casa-reforma`).
- **Nuevo en la tienda online: un póster enmarcado** (39 €; el faro, la ola, la planta en flor o el mapa de la costa), en la pared del dormitorio, encima del ordenador, y **una alfombra de 180 × 140** (129 €; bereber crema, persa granate o lisa gris) para el salón, entre la tele y el sofá: se pisa y va sobre el suelo que tengas.
- **DECORAR LA CASA en la cama**: el tapizado del sofá y del sillón, la lámina del cuadro, el dibujo del póster y el estampado de la alfombra, todo en un sitio.
- **Nuevo: LOGROS**, en START → OBJETIVO → LOGROS: 26, de la primera venta y la primera cosecha a la Jack Herer, la Genoteca completa, las landraces de la tía, el rosin, la cata, el club, el goteo, los plazos, la deuda saldada, las ventas, los rivales, Darko, la plantilla, la nave, las ruedas y la casa reformada, cada uno con el día en que se consiguió. Al conseguir uno sale su aviso; si a la vez llega el de la misión o el del itinerario, va debajo, en el mismo aviso, para que no se pisen. En las partidas de antes, lo ya conseguido se apunta sin aviso.
- Igual en Godot.
- **Arreglado (pruebas de Godot):** el paso de la 1.25 de `historia.gd` leía `REGALO` del juego en vez de los datos (7 errores de script, sin cambiar el resultado).
- Tests: `npm test` 109/109 (paso nuevo: reformas, póster y alfombra en la tienda online, al día siguiente; DECORAR LA CASA; los logros, su aviso detrás del de la misión y en una partida de antes); `test:arte` 29/29; Godot, historia 109 pasos, 41 pantallas (`casa-reforma`, `casa-reforma2`) y el ciclo, con LOGROS en OBJETIVO.

## 1.26.0 · 13 de octubre de 2026

Más genéticas, todas reales: 87 variedades y 50 de receta. Ninguna landrace ni ningún linaje inventado. Godot, 0.20.0.

- **Seis landraces más en el banco del PC** (19 en total), de regiones donde se cultivan de siempre: **Kashmiri** (valle de Cachemira, cap. 3), **Swazi Gold** (Esuatini), **Malana** (valle de Parvati, la del charas) y **Vietnamese Black** (cap. 4), y **Zamal** (isla de la Reunión) y **Ethiopian Highland** (cap. 5). No entran en ninguna receta: son para tus cruces.
- **Trece cruces clásicos más**, con el linaje que se publicó (≈ donde no está claro): **Chronic** (Skunk #1 × Northern Lights × AK-47) y **White Rhino** (White Widow × una índica norteamericana sin documentar, ≈; en la mesa, con Afghani), de 2.ª generación; **White Shark** (Super Skunk × brasileña × India del Sur: con White Widow o con Manga Rosa y Kerala), **Hawaiian Snow** (Hawaiian Haze × Neville's Haze × Haze), **Ice** (Afghani × Northern Lights × Shiva Skunk), **Northern Light Blue** (Northern Lights × Blueberry), **Critical 47** y **Critical Cheese** (una Critical con AK-47 o con Cheese, ≈: no está claro qué Critical; en la mesa, la Critical Mass), de 3.ª; y **Jack Flash** (Jack Herer × Super Skunk × Haze), **Jack 47** (Jack Herer × AK-47), **Sour Tangie** (Sour Diesel × Tangie), **NL × Big Bud** y **Critical Jack** (≈), de 4.ª. Cada una con su nota en el diario de la tía.
- **El trueque del molino** (Andoni) ya no deja perder las landraces que no se venden: una vez descubiertas, entran en lo que ofrece y, si te quedas sin semillas de alguna, te la ofrece antes que las demás (las del banco, no: esas se compran).
- Los escondites de Lamb's Bread y de Kerala, bien descritos: al fondo del callejón del este de Puerto Viejo y junto a una borda, al este de Mendialde.
- El diario cuenta las variedades que haya (no un 68 escrito a mano) y `REGALO` pasa a Godot por `datos.json`. `docs/MAPA.md` dice qué dan los arbustos de la tía.
- Igual en Godot.
- Tests: `npm test` 108/108 (el árbol, con las 53 de la tabla; el recetario, con las 50); Godot, historia 108 pasos.

## 1.25.0 · 13 de octubre de 2026

Cazar genéticas: el diario de la tía, bajo la almohada, y las landraces que no se venden. Godot, 0.19.0.

- **Nuevo: el diario de la tía Maite se encuentra.** La primera vez que duermes o te echas la siesta en el piso, das vueltas, ahuecas la almohada y dentro de la funda está su cuaderno. Hasta entonces no sale ni en la Genoteca ni en el sillón; en las partidas de antes ya lo tienes (`S.flags.diario`, `almohada` en 09-cultivo).
- **El diario trae las 68 variedades**, en el orden de la Genoteca, cada una con una nota de la tía (antes, solo las 37 de receta). A la derecha, «receta», «N recetas», «tienda» o «landrace»; en las de receta, A abre lo que entra; en las demás, la nota y dónde están sus semillas. El contador va sobre las 68.
- **Nuevo: siete landraces que no están en ningún banco**, para que algunos cruces cuesten más. El banco del PC se queda con 13; las otras 7, donde las dejó la tía (y su nota del diario da la pista): **Chocolate Thai** en la nevera del piso (3 semillas, en un bote de cristal), **Highland Oaxacan Gold** al fondo de la caja fuerte (3; en las partidas con la caja ya abierta, la próxima vez que la abres), **Lamb's Bread** en un arbusto de Puerto Viejo, **Kerala** en el monte de Mendialde, **Manga Rosa** en Errotabarri y **Hawaiian** en un seto del Ensanche de Ibarbide (2 cada una), y **Luang Prabang** con Miren, junto con la última página (3; si ya tenías la página, al volver a hablarle). Así, la Purple Thai pide la nevera y la caja; la Amnesia Haze, la Purple Thai para Miren; la White Widow, dos pueblos.
- **La Genoteca cuenta cada nueva**: «NUEVA EN LA GENOTECA · n/68».
- **Ojos de la opción C en las acciones de los NPC** (fumar, el móvil, la pipa, contar, servir…): `tools/sprites/a-mano/npc_ojos_acc.py`, después de `npc_ojos.py`/`npc_cara.py`, pega la cara nueva donde casa la cabeza de antes y dibuja a mano las que giran la cara; los ojos cerrados (al dar una calada, al mirar abajo) y los perfiles se quedan como estaban.
- Igual en Godot.
- Tests: `npm test` 108/108 (paso nuevo: el diario bajo la almohada, el banco con 13 y las 7 de la tía; Miren da la de Laos; el diario, con nota en las 68); Godot, historia 108 pasos; el ciclo, la Genoteca sin el diario hasta la primera noche.

## 1.24.0 · 13 de octubre de 2026

Más genéticas y los ojos que faltaban. Godot, 0.18.0.

- **Nuevo: cuatro landraces más**, de las regiones clásicas que faltaban, con la forma de su planta en la historia de la Genoteca: **Kerala** (India del Sur, sativa: tronco recio, hasta 3 m, ramas como un helecho, flor pequeña y muy resinosa, aroma especiado), **Lebanese** (valle de la Bekaa: baja, tallos finos, hoja ancha, cogollo resinoso con hoja; la del hachís), **Manga Rosa** (Brasil) y **Durban Poison** (Sudáfrica). Se piden al banco de semillas del PC: Lebanese desde el capítulo 3, Kerala y Manga Rosa desde el 4 y Durban Poison desde el 5.
- **Nuevo: cinco híbridos clásicos de receta**, con su linaje real: **White Widow** (Manga Rosa × Kerala; su padre real fue una índica del sur de la India sin documentar; ≈), **Purple Haze** (Purple Thai × Haze; ≈), **White Russian** (White Widow × AK-47), **Blue Widow** (Blueberry × White Widow) y **Super Lemon Haze** (Lemon Skunk × Super Silver Haze, la primera de 4.ª generación). La Haze tiene otra receta con la India del Sur (Punto Rojo + Michoacán + Thai + Kerala). El diario de la tía Maite pasa de 32 a 37 variedades, cada una con su nota; la Genoteca, de 59 a 68 (las nuevas, al final, para no cambiar el número de las demás).
- **Ojos de la opción C en Josune, Iñaki, Patxi y Molina** (de frente y de lado) y en los lados de Baltasar y Darko: los ojos que PixelLab les dibujó no se podían buscar por su blanco (sin blanco, o con brillos y cejas blancas), así que van a mano (`A_MANO` en `tools/sprites/a-mano/npc_ojos.py`), donde estaban los viejos.
- Patxi y Kiko dan pistas de las recetas nuevas. En las partidas de antes, un cruce propio que se llamaba como una variedad nueva (Purple Thai × Haze era «Purple Haze») cambia de nombre.
- **Arreglado:** contra la carga de Darko, la guardia o la esquiva de la ronda en que coge la barra se gastan; ya no protegían del golpe doble de la ronda siguiente.
- Igual en Godot.
- Tests: `npm test` 107/107 (el árbol, con las 40 de la tabla hasta la 4.ª generación; el recetario, con las 37; la carga de Darko gasta la guardia y la esquiva); Godot, historia 107 pasos.

## 1.23.0 · 13 de octubre de 2026

Marcas de abono, Julen y el itinerario. Godot, 0.17.0.

- **Nuevo: marcas de abono y pH−** (inventadas). **MEATZA**, mineral: crecimiento, floración y pH− de ácido fosfórico, como el abono de antes (+25 % de cosecha, +0,3 de THC y florece un 10 % antes; sin pH−, la mitad). **ORTUA BIO**, orgánico, de liberación lenta: +20 % de cosecha y +0,4 de THC sin acelerar la floración, el de crecimiento da un 8 % (el mineral, un 15 %) y la tierra amortigua el pH (sin pH−, ×0,85; a ojo, ×0,95). Con algo orgánico y nada mineral (tampoco el pH− fosfórico), el **sustrato vivo** frena las plagas (×0,75). El pH− que se gasta es el de la marca del abono y, si no hay, el otro; con las dos marcas, al abonar eliges cuál (`PRODUCTOS`, `ABONO_BIO`, `abonar`, 09-cultivo). En la tienda, 6 productos; en la mochila, uno por fila con lo que hace; en PLANTAS, «bio» y «sustrato vivo».
- **Nuevo: Julen, el hijo de Kiko** (estudia Agrónomas; sprite de Kiko con otro pelo y otra ropa, `tools/sprites/a-mano/julen.py`). Desde que conoces a Kiko hasta la primera cosecha está en el piso, delante del armario: te regala 2 dosis de ORTUA BIO CRECIMIENTO y 4 de pH− ORTUA BIO, te explica el pH y la diferencia entre mineral y orgánico, te dice qué toca ahora y comenta cada paso. Con la primera cosecha se despide y vuelve al growshop, donde da consejos (`11h-guia.js`; en GENTE).
- **Nuevo: el itinerario** (START → OBJETIVO → ITINERARIO, hasta el capítulo 4): 14 pasos desde el autobús hasta el primer plazo pagado (plantar, regar, los dos abonos, cosechar, vender, los 300 €, Baltasar, juntar el plazo y pagarlo). Al cumplir uno sale «ITINERARIO · n/14» con el siguiente; el objetivo del capítulo 1 es el paso de ahora. Las partidas viejas apuntan lo que ya tienen, sin aviso (`ITINERARIO`, `S.itin`).
- Kiko habla de las dos marcas en sus consejos y te manda a ver a Julen.
- Detalles: con riego automático (garrafas o goteo), «Regar» se cumple al plantar; las partidas de antes con la planta ya abonada no se atascan en los abonos; Julen lleva su «!» hasta que hablas con él y, si lo conoces después de cosechar, te saluda sin ofrecerse a ayudar; se despide antes del capítulo 2; el pH del medidor sale con la marca de cada dosis, y si gastas el pH− de la otra marca, te lo dice.
- Igual en Godot.
- Tests: `npm test` 107/107 (paso nuevo: las marcas, Julen y el itinerario; las partidas viejas apuntan el itinerario); Godot, historia 107 pasos.

## 1.22.0 · 13 de octubre de 2026

Repaso: HUD más pequeño, importar la partida y errores. Godot, 0.16.0.

- **HUD más pequeño:** letra de 6,5 px de juego en vez de 7,5, barras de 28 × 2,5 en vez de 34 × 3 y menos margen: tapa menos del mapa. Igual en Godot (`HUD_*` en `ui.gd`, los mismos números que `.hud` en el CSS).
- **Nuevo: IMPORTAR PARTIDA** (START → OPCIONES, junto a EXPORTAR PARTIDA; en Godot, también en las OPCIONES del título). Se pega la partida exportada en la caja de texto (lo que haya en el portapapeles sale ya escrito; sin `<`, `>`, `"` ni `` ` ``, que no salen en el juego); si es una partida, pregunta («¿Cargar la partida de …, día …? La de ahora se pierde.»), la carga como CONTINUAR (`migrate`) y la guarda. Lo que no es una partida, no se carga. Desde el título de Godot se guarda y sale CONTINUAR. Si no se puede guardar, lo dice.
- Arreglos de la ropa (1.21): la gorra, la camiseta, el pantalón y el pelo de combate tienen colores propios (`player_ropa.py`), así que las zapatillas, la regadera y la planta ya no cambian con ellos; la caché de cada combinación lleva todas las piezas (antes, pantalón y pelo se pisaban). PULVERIZAR pasada la medianoche dice la humedad que queda.
- Errores: un vendedor que se larga a medianoche mientras viene a la llamada ya no aparece a comprar; lo que venden los vendedores, la plantilla de calle y el bajo de las setas cuenta para la historia (`checkStory`); el CBD del analizador sale del 0,2 al 1 % (salía diez veces más); el olor de la noche también da el aviso de calor (`heatWarn` al cambiar el día), y hablar con Darko en los astilleros sube su confianza (antes, la de otra ficha).
- Sprites: `validar.js` da 0 errores (los tapizados y láminas `k-N` cuentan como su mueble; el inventario lleva los muebles que se compran y el combate de Darko; los personajes nuevos de la 1.15 a la 1.21, cubiertos en el manifiesto) y el catálogo, al día.
- Tests: `npm test` 106/106 (paso nuevo: importar algo que no es una partida y la exportada); Godot, historia 106 pasos; el ciclo, con IMPORTAR en las OPCIONES del título.

## 1.21.0 · 13 de octubre de 2026

Arte: ropa y pelo, Darko y Miren con sprite propio y los ojos de los personajes. Godot, 0.15.0.

- **Nuevo: ropa y pelo** (la cama del piso → CAMBIARTE DE ROPA; `ROPA`, `S.ropa`, `vestirte`, 12c-salon). Camiseta (7 colores), pantalón (5), gorra (6) y pelo (5): cambian los colores del protagonista andando, montado y de espaldas en el combate (`ropaC`, por colores exactos con `conRampa`). Fuera del piso, la cama no lo ofrece.
- **Darko pelea con su sprite** (`darko-combate`: sudadera negra y pañuelo rojo; antes, el del ladrón) y **Miren lleva el suyo** (`miren`: pelo canoso y top verde; antes, el de una clienta).
- **Ojos de los personajes** como los del protagonista (opción C, `tools/sprites/a-mano/npc_ojos.py`): párpado, blanco e iris de frente y de lado, en la cabeza de cada dirección, que `npc_cara.py` pega en cada paso. Iñaki, Josune, Molina y Patxi se quedan como estaban (sus ojos no se dejan medir) y Baltasar y Darko, solo de frente; con gafas, Jurado y Txaro, sin tocar.
- Pelo del protagonista: sus dos tonos ya no son los de la cara (`player_pelo.py`), para poder cambiarlos sin tocar cejas ni sombras.
- Arreglos de la 1.19 y la 1.20: el alquiler de la nave se cobra antes que los sueldos (sin él, Arrieta cambia la cerradura antes de que nadie trabaje); PULVERIZAR pasada la medianoche ya no deja el menú del bajo abierto si el bajo se ha cerrado al cambiar de día.
- Igual en Godot. Pantallas: 39 (con el piso con ropa y el combate de Darko).
- Tests: `npm test` 105/105 (paso nuevo: la ropa en la cama del piso y fuera de él, los colores del protagonista, el combate y el sprite de Darko y el de Miren); Godot, historia 105 pasos.

## 1.20.0 · 13 de octubre de 2026

El bajo de las setas: un local clandestino en la Kale Zaharra. Godot, 0.14.0.

- **Nuevo: el bajo de las setas** (Txomin, en la Kale Zaharra, desde el capítulo 4; `SETAS`, `S.setas`, 11g-setas). Txomin, el setero viejo del callejón, alquila el bajo de su casa: 1.500 € de fianza y 20 € al día, que cobra cada mañana. Él prepara las bandejas (45 € cada una, hasta 6); tú las tienes húmedas (PULVERIZAR, 10 minutos, las deja al 100 %; cada día pierden 34 puntos) y esperas: 6 días colonizando, 4 fructificando y listas.
- Cada mañana, una bandeja que no está lista puede contaminarse (2 %; un 15 % más por debajo de la mitad de humedad) y, a 0, se seca: las dos se tiran (TIRAR LAS MALAS). RECOGER da de 25 a 40 g por bandeja lista, que se secan en el bajo, y Txomin te los compra a 9 € el gramo (calor +3).
- Una redada en el bajo (1 % al día con bandejas vivas) se lo lleva todo, el local incluido (calor +15). Sin el alquiler, Txomin cambia la cerradura y se queda la fianza y lo de dentro; si lo dejas, te la devuelve.
- Igual en Godot.
- Tests: `npm test` 104/104 (paso nuevo: alquilar, las bandejas, la humedad, las fases, contaminar y secar, recoger, vender, la redada, impagar y dejarlo); Godot, historia 104 pasos.

## 1.19.0 · 13 de octubre de 2026

La plantilla: poner al barrio a trabajar. Godot, 0.13.0.

- **Nuevo: la plantilla** (MÓVIL → PLANTILLA, desde el capítulo 3; `PLANTILLA`, `S.plantilla`, 11f-plantilla). Patxi te manda a alguien del barrio por un sobre de 150 €: no sabes a quién hasta que llega, y le contratas o no (el sobre ya está pagado). Cada uno trae tres números del 1 al 5: **labia** (vende más y le timan menos), **cuidado** (le para la policía y le atracan menos; en la nave, saca más) y **lealtad** (se larga menos con lo tuyo y, de gerente, sisa menos). Hasta 6 a la vez; se les cambia de trabajo, se les deja libres o se les despide desde el móvil.
- **A la calle** con un lote de 25, 50 o 100 g: cada mañana vende de 2 a 4 g por punto de labia a precio de calle del barrio y se queda el 30 %; o le para la policía (5 % con cuidado 1, 1 % con 5: pierde el lote y el calor sube 10), le atracan (8 % → 2 %: la mitad del lote), se larga con todo (6 % con lealtad 1, nunca con 5; la mitad con gerente) o le pagan con billetes falsos (6 % → 2 %: los gramos, sin dinero). Lo que le quede al dejarlo vuelve al arcón.
- **De gerente** (uno, 40 € al día): cada mañana riega, trata las plagas con tu insecticida y rellena garrafas y depósitos, como Begoña, y cosecha lo que esté listo al arcón (las semillas y la estrella, como tú), quitando su sisa: un 3 % por cada punto de lealtad por debajo de 5.
- **La nave de Valdehierro** (Arrieta, al lado de la nave, desde el capítulo 5; `NAVE`, `S.nave`): 3.000 € de fianza y 60 € al día. Pones a trabajar hasta 4 (30 € al día cada uno) y eliges la variedad con una semilla: cada uno saca 16-24 g al día según su cuidado, al 90 % del THC de la variedad, que se recogen allí. Una redada (del 1,7 % al 0,5 % al día, según el más cuidadoso) se lo lleva todo, nave y gente incluidos (calor +20). Sin el alquiler, Arrieta cambia la cerradura y se queda la fianza; si la dejas, te la devuelve.
- Sin dinero para el sueldo, el gerente y los de la nave lo dejan.
- Igual en Godot. Begoña y el gerente comparten `cuidarPlantas`; la cosecha, `thcCosecha` y `semillasCosecha`.
- Tests: `npm test` 103/103 (paso nuevo: los sobres, la calle con sus cinco salidas, el gerente con su sisa, la nave con el alquiler, lo que crece, la redada, dejarla e impagarla); Godot, historia 103 pasos.

## 1.18.0 · 13 de octubre de 2026

Combates con más fondo: esquivar, amenazar y experiencia. Godot, 0.12.0.

- **Nuevo: ESQUIVAR** (LUCHAR → ESQUIVAR). Te quedas atento para apartarte del golpe siguiente: si lo consigues (45 %, +6 % por cada punto de REFLEJOS), no te toca y tu golpe siguiente no falla y hace 3 más («Le pillas abierto.»); si no, te da entero. Contra la barra de Darko, si te apartas, la barra se queda en nada. CUBRIRSE sigue siendo lo seguro: la mitad del golpe y tu golpe siguiente asegurado. Una postura quita la otra.
- **Nuevo: AMENAZAR** (HABLAR → CALMAR o AMENAZAR). CALMAR es el HABLAR de antes (mejor con reputación). AMENAZAR funciona mejor cuanto más tocado está el otro (10 % de base y hasta un 60 % más según la vida que ha perdido, +3 % por punto de FUERZA, con un tope del 80 %): se lo piensa mejor y se va. Si falla, su golpe siguiente hace 2 más. A Darko no se le amenaza. Con la policía, nada cambia.
- **Nuevo: experiencia de pelea** (`PELEA`, `S.pelea`, `experiencia`). Cada pelea ganada da experiencia (un ladrón 1, un rival 2, Darko 3); con 2, 5, 9, 14, 20, 27, 35, 44, 54 y 65 subes un nivel y eliges qué entrenas: **FUERZA** (+1 de daño en cada golpe) o **REFLEJOS** (+2 % de puntería, hasta el 98 %; +6 % de esquivar, y +4 % de escapar de ladrones y rivales, hasta el 70 %), hasta 5 cada una. Al subir hay que elegir: B no la salta. Sigues ganando VIDA máxima como antes. En la MOCHILA, la fila **Pelea** (desde la primera victoria) dice el nivel, la fuerza, los reflejos y lo que falta para el siguiente.
- Igual en Godot. `docs/ANALISIS.md` sigue sin experiencia de pelea (HABLAR es CALMAR).
- Tests: `npm test` 102/102 (paso nuevo con esquivar, la contra, amenazar, la rabia, Darko, subir de nivel, los topes y la fila de la MOCHILA); Godot, historia 102 pasos.

## 1.17.0 · 13 de octubre de 2026

Más fondo: el ajuste de cuentas con Darko y la amiga de la tía Maite. Godot, 0.11.0.

- **Nuevo: el ajuste de cuentas con Darko** (capítulo 8, astilleros; `ajusteDarko`, `DARKO`, 13-combate). Al hablarle, te reta: «Esto lo arreglamos tú y yo». Pelea como un rival con 4 de vida más y, a veces (30 %), coge una barra de hierro: el golpe siguiente vale el doble, y CUBRIRSE lo deja en la mitad. Con él no vale HABLAR, y lleva la «!» mientras te espera. Si le ganas («Darko cae al suelo, sin aire.»; +10 de reputación y +2 de VIDA máxima), se va de los astilleros (`S.flags.darkoFin`): ni él ni sus chicos vuelven a salirte al vender, y Don Baltasar te escribe. Si te vence o huyes, te espera allí.
- **Nuevo: Miren** (Errotabarri, desde el capítulo 4; `talkMiren`, `MIREN`, 11d-comarca), la amiga con la que la tía Maite cultivaba hace treinta años. Te pide 20 g de Purple Thai, la que hacían las dos (de uno o varios lotes; primero los que no son estrella), y te da la página que faltaba del diario (`PAGINA`, al final del DIARIO DE LA TÍA MAITE: de dónde salió la deuda con Baltasar) y 5 semillas de Haze.
- CUBRIRSE asegura también tu siguiente golpe (1.16, tras la revisión).
- En el combate, Darko lleva el sprite del ladrón (su personaje del atlas es de 32 px) y Miren, el de un cliente: el arte propio de los dos queda pendiente.

## 1.16.0 · 12 de octubre de 2026

El diario de la tía Maite, los rivales de cada zona y la casa a tu gusto. Godot, 0.10.0.

- **Nuevo: el diario de la tía Maite.** El recetario de la Genoteca es ahora su cuaderno (DIARIO DE LA TÍA MAITE): cada una de las 32 variedades de receta lleva su nota escrita por ella (`DIARIO`, 12-menus), encima de sus recetas y de dónde sale cada semilla.
- **Nuevo: los rivales** (`RIVALES`, 13-combate): en el barrio alto, Puerto Viejo, Valdehierro, el Casco Viejo, el Ensanche y la Kale Zaharra, desde el capítulo 3, un camello que no quiere competencia (los astilleros siguen siendo de Darko). Cada venta en la calle de su zona le suma una; a la 8.ª sale a buscarte: pelear (más duro que un ladrón: +6 de vida y +1 a cada golpe), pagarle su cuota (200 € por el precio de la zona) o apartarte (vuelve 2 ventas después). Si le ganas, se va 7 días, sus clientes te pagan un 5 % más y ganas reputación.
- **Nuevo en los combates: CUBRIRSE** (LUCHAR → CUBRIRSE): el siguiente golpe duele la mitad.
- **Nuevo: personalizar la casa.** En la tienda online, el sillón orejero con lámpara de pie (229 €; desde él se lee el diario de la tía Maite, 30 min) y un cuadro para la pared del salón (59 €). El sofá y el sillón cambian de tapizado (tres cada uno) y el cuadro, de lámina (la ría, el caserío o la hoja), desde el propio mueble (`DECO`, `S.deco`; arte a mano en `tools/sprites/a-mano/salon.py`).

## 1.15.0 · 12 de octubre de 2026

La gente: confianza con cada persona, trabajadores, clubs cannábicos y la cata. Godot, 0.9.0.

- **Nuevo: la confianza** (`S.rel`, de 0 a 100; MÓVIL → GENTE) con cada persona con nombre. Sube hablando (1 al día), vendiendo a buen precio a los de la agenda (rebaja 3, justo 2, caro 1), con regalos (2 g: +5, una vez al día) y favores (Txaro, +10; cada compra a Kiko y cada venta a Iñaki, +1); baja pidiendo caro (−2) o fallando. Con 20 (amigo): Kiko hace un 5 %, Iñaki paga un 5 % más al por mayor, Begoña se deja contratar y los de la agenda aceptan mejor el precio (+confianza/250). Con 50 (socio): uno de la agenda vende para ti.
- **Nuevo: trabajadores.** Begoña, de jardinera (desde el cap. 3, con 20 de confianza): cada mañana riega todas las plantas, rellena garrafas y depósito y trata las plagas con tu insecticida, por 20 € (sin dinero, se va; calor +0,5 al día). Vendedores a comisión (hasta 2, desde el móvil): un cliente de la agenda con 50 al que le dejas 25, 50 o 100 g; cada día vende de 5 a 15 g a precio de calle del barrio y te deja el 70 % en el buzón (SMS). Riesgo diario: un 4 % de que lo pare la policía (pierde lo que lleva, calor +10) y hasta un 10 % de que se largue con todo (menos cuanta más confianza; sale de la agenda).
- **Nuevo: clubs cannábicos** (`CLUBS`): CLUB ITSASO (Puerto Viejo) y CLUB LA FUNDICIÓN (Valdehierro) desde el cap. 3, CLUB KALEA (Casco Viejo) y CLUB ENSANCHE desde el 4, con el encargado en la puerta. Con el carné (30 o 50 €, una vez): vender un lote al día (50, 100 o 200 g, a 3 + 0,15 × THC € el gramo —entre Iñaki y la calle—, calor +1; un 5 % más si va analizado), comprar 10 g de la variedad del día (entra en la Genoteca) y encargos de semillas (10 de una variedad, en 7 días: las de tienda pagan un 20 % más de lo que cuestan y las de receta que ya tienes, 800 €; uno a la vez; si vence, reputación −3 y confianza −10).
- **Nuevo: la cata y el analizador de cannabinoides y terpenos.** En la MOCHILA, A sobre un lote: catar medio gramo (30 min) deja su nota (aroma por variedad, efecto por el % índica y la potencia) en la Genoteca, y el lote catado se vende algo mejor. El analizador de cannabinoides y terpenos (Kiko, 180 €, desde el cap. 3): analiza un lote —THC, CBD y su terpeno principal— (se vende mejor en la calle y un 5 % más en los clubs) y la cata dice el THC exacto y el terpeno de cada aroma.
- `docs/IDEAS.md`: lo pendiente, por tandas.

## 1.14.0 · 12 de octubre de 2026

La comarca crece con la historia: una ciudad grande, líneas de autobús que se abren por capítulos y un sitio con algo que hacer en cada pueblo. Godot, 0.8.0.

- **Nuevo: Ibarbide, la ciudad grande** (desde el capítulo 4; 4 € y 35 min en autobús). Dos barrios: el **Casco Viejo** (44 × 30: casas estrechas de piedra y madera con miradores, la Plaza Nueva con su fuente, la avenida y un parque) y, por la avenida, el **Ensanche** (46 × 22: bloques de pisos, la carretera y un parque con plaza y fuente). Cada uno con su música de día y de noche, 2 agentes de día (2 y 3 de noche), más ladrones en el Ensanche y el gramo un 30 y un 25 % más caro; clientes desde el capítulo 4 (3 en cada barrio, 4 desde el 5) y catadores de rosin. Fachadas dibujadas a mano (`tools/sprites/a-mano/mundo.py`: `casco`, `growcity`, `bloque`).
- **Nuevo: las líneas de autobús se abren por capítulos** (`PARADAS.cap`): Mendialde desde el principio, Puerto Viejo y Valdehierro en el 2, Errotabarri en el 3 e Ibarbide en el 4. Al abrirse, un SMS de la compañía.
- **Nuevo: GROW IBARBIDE** (Ane, en el Casco Viejo): el equipo de Kiko un 10 % más barato y un capítulo antes; sin semillas, carro ni aparatos de la sala.
- **Nuevo: la lonja de Puerto Viejo** (Nerea, desde el capítulo 3): carga para los barcos de fuera, de 100 a 500 g, un 15 % por encima de lo que paga Iñaki, cada 3 días.
- **Nuevo: la chatarrería del solar de Valdehierro** (Bixente, desde el capítulo 2): 3 piezas de equipo al día (focos, extractores, intractor, ventilador, calefactor, humidificador), de segunda mano, a mitad de precio.
- **Nuevo: el molino de Errotabarri** (Andoni, desde el capítulo 3): 3 semillas de una landrace del banco que aún no tengas por 20 g de lo tuyo, una vez por semana.
- **Nuevo: la Kale Zaharra** (Ibarbide, desde el capítulo 4): por un callejón entre GROW IBARBIDE y las casas del casco, una plazuela de piedra sin patrullas, con más ladrones y el gramo a ×1,3. Se vuelve por el mismo callejón. Algo hay escondido en el arbusto.
- **Cambiado: los mapas ya no son todo cuadrícula** (`senda`): los caminos de tierra de los parques del barrio, del Casco Viejo y del Ensanche van en curva; la Plaza Nueva lleva una fuente con parterre y jardineras con tres entradas, la plaza del Ensanche es ovalada y se entra por los huecos del seto, y la plaza del barrio tiene entradas por los lados.

## 1.13.0 · 12 de octubre de 2026

Patinete y bici, y un repaso de errores. Godot, 0.7.0.

- **Nuevo: el patinete y la bici** (`VEHICULOS`, 12c-salon). Se compran en la tienda online (Muebles y transporte: patinete 119 €, bici de segunda mano 239 €) y el mensajero los deja en el portal al día siguiente. En la calle (cualquier zona exterior) vas montado: el patinete, 150 ms por casilla (110 con B); la bici, 110 (80 con B), la más rápida para dejar atrás a una patrulla (los agentes corren a 180-210). En casa y en los interiores, a pie. La bici, corta (17 px de rueda a rueda, casi una casilla), para no invadir las casillas de al lado. Dibujados a mano (`tools/sprites/a-mano/vehiculos.py`) en dos capas, detrás y delante del protagonista, con las ruedas que giran y el pedal de la bici.
- **Arreglado: Darko ya no entra a robar durante una siesta**; solo al dormir hasta el día siguiente.
- **Arreglado: la redada solo se lleva lo de encima si estás en casa** (el arcón, siempre). El texto dice lo que encuentran, esquejes incluidos (o «No encuentran nada que llevarse») y la multa entera; si no te llega, cuánto pagas.
- **Arreglado: el aviso de la orden** solo menciona a Molina desde el capítulo 5 (antes no lo conoces).
- **Arreglado: la factura de la luz** dice lo que pagas y lo que te falta si no llega.
- **Arreglado: al cargar la partida** salen el aviso de la orden, la redada o el plazo vencido que quedaron pendientes al guardar en la cama.
- **Arreglado: los encargos de Baltasar** piden una bolsa en la que quepan (2 kg, bolsa de deporte; 5 y 10 kg, maleta).
- **Cambiado: los plazos dicen «antes de que acabe el día X»** (el día X todavía vale).
- **Cambiado: la ficha de la planta en la vista C** lleva su número o su nombre y la ★.

## 1.12.0 · 12 de octubre de 2026

Pantalla más alta, nombre nuevo y personajes sin caras que cambian. Godot, 0.6.0.

- **Cambiado: el juego se llama Landrace Hunters** (título, pestaña, aviso de edad, créditos, privacidad y las dos apps). Ribera Verde sigue siendo el barrio; los paquetes de Android (`com.riberaverde.*`) no cambian, así que la app se actualiza encima y las partidas guardadas se cargan igual. En el título, LANDRACE / HUNTERS en dos líneas, arriba, sin tapar la hoja.
- **Cambiado: la pantalla, de 160 a 180 px de alto** (`SH`), píxel a píxel, y de 240 a 450 de ancho (`SW_MAX`, hasta 21:9). En la calle y el piso se ven más casillas; el título, la intro, el combate y la carpa (escenas de 240 × 160) van abajo y la franja de arriba es el reflejo de su fondo (en la vista C, negra).
- **Cambiado: los personajes, por partes** (`tools/sprites/a-mano/npc_cara.py`): la cabeza de cada uno sale de una sola pieza por dirección (la de su postura de base) en el idle y al andar, así la cara ya no cambia en cada fotograma; el idle es la postura de base respirando, sin el «ictus».

## 1.11.0 · 9 de octubre de 2026

Genética por generaciones, policía por niveles con aviso, accesorios de carpa que cuentan y misiones guiadas para pagar la deuda. Godot, 0.5.0.

- **Cambiado: el árbol de la genética** (`docs/GENETICA.md`). 59 variedades: los landraces y, por generaciones, los híbridos clásicos (1.ª: Skunk #1, Haze, Northern Lights, Purple Thai, AK-47, Master Kush…; 2.ª: Blueberry, Super Skunk, Shiva Skunk, Critical Mass, Cheese, Amnesia Haze…; 3.ª: Jack Herer, Super Silver Haze, Blue Dream, Blue Cheese, Sour Diesel, Kali 47…). Los de linaje dudoso llevan «≈ origen incierto». Nuevas: Kali Mist, Cheese, California Orange, Chemdawg, Colombian Gold, Chocolate Thai, Highland Thai, Hawaiian, AK-47, Laughing Buddha, Cannalope Haze, Congo × Panama, Malawi × Panama, Malawi × PCK, NL5 × Haze, Neville's Haze, Chocolope y Kali 47; renombradas a su nombre real las que no lo eran. Sin criadores, bancos ni personas en el juego.
  - **Recetas por conjunto de variedades:** un híbrido propio recuerda de qué variedades sale, así que las de 3 o 4 padres (Skunk #1, Amnesia Haze, Jack Herer…) se sacan cruzando en cualquier orden; las que dependen de quién es la madre (Super Skunk, Critical Mass, NL5 × Haze, Silver Haze) siguen dependiendo.
  - La meta del final es la **Jack Herer** (Haze × (Northern Lights × Shiva Skunk)); la Copa se gana con Amnesia Haze o Sour Diesel.
- **Cambiado: la policía, por niveles y con aviso.** El calor marca el nivel: tranquilo (0-29) y vigilancia (30-59) bajan 12 al día; investigación (60-89), 8 y una patrulla más por zona; con 90 al cambiar de día, **orden de registro**: el calor no baja, Kiko te avisa por SMS y la redada llega al día siguiente. El HUD dice ORDEN mientras dura. Con la protección de Molina, la bajada es × 1,5 y no hay orden.
  - **La redada es justa:** se lleva las plantas, el equipo montado en sus carpas y lo que está a la vista (lo de encima y el arcón). **La caja fuerte no la tocan**: solo sale de ella la multa que no llegue con lo de fuera. La multa es por lo que encuentran: 601 € + 300 € por planta + 3 € por gramo, hasta 30.000 €; el calor queda en 40. Con el día de aviso, guardar en la caja es la jugada.
- **Nuevo: accesorios de la carpa que cuentan.**
  - **Extractores con filtro de carbón** de 100, 125 y 150 mm (250, 400 y 750 m³/h; 75, 110 y 190 €). Cada carpa pide un caudal (su volumen renovado cada minuto, × 1,3 por el filtro, más lo que calienta su foco). Sin extractor, la floración suma 2 de calor al día; con uno corto de caudal, 1; a su medida, nada. Montar uno nuevo devuelve el anterior a la mochila.
  - **Intractor** de 100 mm (45 €): sin él, el extractor rinde un 85 %.
  - **Clima por carpa:** de día, el foco calienta la carpa (el sodio más que el CFL, el LED lo que menos) y cada planta suma humedad; el extractor se lleva casi todo. PLANTAS enseña el caudal y, con termohigrómetro, el clima de dentro. Fuera de rango, crecen menos; con humedad de noche en flor, moho (el aviso de la mañana lo dice por carpa).
  - **Ventilador:** crecen un 3 % más, la mitad de moho y plagas × 0,7.
  - **Abono por fases y pH/EC:** abono de crecimiento (12 €, crecen hasta un 15 % más en vegetativo) además del de floración; **pH−** (6 €, 10 dosis): sin él, el abono rinde la mitad, y con él, tres cuartos; con el **medidor de pH/EC** (35 €), entero, y PLANTAS enseña la EC y el pH de cada maceta.
- **Nuevo: música por zona.** Cada zona de la calle suena distinta, de día y de noche: Ribera (la de siempre, ahora con una segunda parte y batería), el barrio alto (lounge en fa, con séptimas), los astilleros (industrial en mi menor, bajo de sierra), Puerto Viejo (vals marinero), Valdehierro (mina, la menor dórico), Mendialde (6/8 de caserío con flauta) y Errotabarri (pastoral lenta). De noche, la misma canción más lenta, con flauta y sin bombo. Los interiores llevan la suya: la tienda (reggae), el bar (tango), la comisaría (tensa), el almacén (la de los astilleros de noche), la casa de Txaro y el piso (la de casa) y el caserío (la de Mendialde de noche). Al cambiar de canción, la que suena se apaga y entra la nueva. Todo original, en chiptune: ondas de pulso de 25 y 12,5 %, ligaduras, arpegios y batería de ruido (05-audio: las canciones se escriben en notas y acordes y `tema()` las convierte; Godot las sintetiza en un hilo aparte, primero la que toca).
- **Nuevo: misiones guiadas** (`11c-misiones.js`): lo que hay que montar para pagar la deuda a tiempo, en START → OBJETIVO, que ahora es una lista con el objetivo del capítulo, las misiones (con lo que cuesta cada cosa y dónde) y la deuda (el plazo, lo que llevas entre el bolsillo y la caja, ventas, reputación y calor). Salen desde que conoces a Kiko: la caja de la tía y luz de verdad (un LED de 100 W y macetas de tela) en el capítulo 1; una carpa, un extractor e Iñaki en el 2; el por mayor y un sodio de 400 W en el 3; un LED de 480 W y una carpa de seis plazas en el 4. Al cumplir una, Kiko manda un SMS y deja un regalo (abono, pH−, insecticida o semillas; nunca dinero). Siguiéndolas, el primer plazo se paga hacia el día 10 (vence el 12), el segundo hacia el 18 (vence el 22) y el último hacia el 20 (vence el 24). Las partidas guardadas dan por hechas las de los capítulos pasados, sin regalo.
- **Nuevo: el carro de esquejes** (165 €, en el growshop desde el capítulo 2). Kiko lo sube al piso al día siguiente y lo monta delante de las carpas: un carro con ruedas, dos bandejas de propagación de 12 tacos tapadas bajo tubos T5 y una mesita con la tabla de corte, el bisturí y la hormona de enraizamiento (dibujado a mano, `salon.py`). En la tabla de corte se pinchan los esquejes del propagador: en las bandejas aguantan 3 días (sueltos, 1) hasta que haya hueco en una carpa, y se plantan desde la plaza vacía como los demás («bandeja»). Con alguno pinchado, los tubos gastan 4 € de luz al día; la redada se los lleva.
- **Nuevo: avisos del plazo.** Toño manda un SMS cuando quedan 3 días y el último día, con lo que llevas y lo que te falta; el objetivo de los capítulos 3, 5 y 7 dice lo que llevas.
- **Cambiado: el calor de la calle.** Cada venta en la calle sube 2 + 0,3 por gramo (antes, 3 + 0,5; el rosin, 2 + 2,5 por gramo, `CALOR_CALLE`), y con 50 de calor sale un aviso que dice por dónde vender sin tanto calor (Iñaki). Con 200 partidas simuladas, el jugador que vendía en la calle a todo el que pedía pagaba el primer plazo a tiempo un 2 % de las veces (casi siempre llegaba antes la redada); con la calle nueva, unas tres de cada cuatro.
- Las cifras de los textos salen de las constantes del juego (`NIVEL_POLI`, `INTRA`, `VENT`, `ABONO`, `RENUEVA`, `FILTRO_X`), también en Godot: si cambia una, cambia el texto.
- **Arreglado: la luz al dormir.** El aviso de la cama enseñaba la factura del día cada vez que te acostabas, aunque fuera una siesta de 3 h que no pasa de las 12 y no cobra nada. Ahora dice solo lo que se ha pagado durmiendo (la factura sigue siendo de un día entero, a medianoche).
- **Arreglado: la cara del protagonista.** Cada fotograma de estar quieto, andar y correr traía su cara (en unos los ojos se juntaban y se quedaba bizco, en otros se abría la boca o cambiaba la gorra). Ahora la cabeza es la misma en todos, por dirección, con la cara de frente dibujada a mano (`tools/sprites/a-mano/player_cara.py`: ojos finos, sin brillo ni sombra de la visera en la frente), va pegada al cuerpo (sube y baja con él, sin bailar de lado) y de lado el cuello ya no parece barba. También en las acciones (cosechar, regar, plantar, oler, el móvil y vender) donde la cara se ve entera; donde se tapa con la mano, mira al móvil o pasa la regadera por encima, se queda como estaba. Quieto, respira en las cuatro direcciones: la postura de pie con la cabeza 1 px más abajo a la mitad, en vez de cambiar de cuerpo en cada fotograma (mirando a la derecha, el muñeco crecía 3 px al pararse). **Los ojos, más reales e iguales en todos los fotogramas:** de lado seguían con el blanco al lado de la pupila (saltones) y en las acciones cada uno era distinto. Ahora, de frente, párpado y debajo blanco, iris marrón y blanco; de lado, párpado y el blanco detrás del iris; los mismos al estar quieto, andar, correr y en las acciones (donde la cara se ve).
- **Nuevo: cada planta con su número y su nombre.** Cada planta lleva el número de su fenotipo («Skunk #1 nº 12») en la maceta, en PLANTAS, en la mochila y en las bandejas del carro, y sus esquejes, el mismo. En la maceta (también cuando está lista para cosechar), **Nombrar** le pone un nombre (hasta 12 letras, números, espacio y # ' . -) que heredan sus esquejes: «Skunk #1 «Madre Lima» ★». Con B no cambia nada; en blanco vuelve a su número. Para seleccionar madres sin perderse.
- **Nuevo: tirar semillas y esquejes.** En la MOCHILA, una semilla se tira de una en una o todas; un esqueje (también en las bandejas del carro) se nombra o se tira.
- **Cambiado: los nombres de los cruces, cortos.** Un cruce propio se llama con dos palabras de sus padres (hasta 20 letras, sin repetir otra variedad; si no queda ninguna, con «#2», «#3»…), nunca «A × B»: al cruzar cruces salían nombres de 50 letras. Las partidas viejas pasan a nombres cortos al cargar (la variedad es la misma). En la GENOTECA, A sobre una variedad propia le cambia el nombre (sin repetir el de otra, ni cambiando mayúsculas).
- **Nuevo: el recetario**, lo primero de la GENOTECA: las 32 variedades de receta con sus maneras de sacarlas (en cualquier orden o madre × padre) y, de cada variedad que entra, dónde se consiguen las semillas: el regalo de Kiko, Txaro o Iñaki, el growshop o el banco del PC (desde qué capítulo), una misión o su receta; la Acapulco Gold, escondida en el parque.
- **Nuevo: exportar la partida.** START → OPCIONES → EXPORTAR PARTIDA copia la partida (JSON) al portapapeles para guardarla en una nota o pasarla a otro aparato.
- **Nuevo: la caja de texto** (`pedirTexto`) para el nombre del jugador, el de una planta y el de una variedad: A (o Intro) acepta y B (o Esc) cancela, salvo en el nombre del jugador.
- Tests: `npm test` 91/91 (pasos nuevos de las plantas con nombre, los cruces cortos y el recetario, exportar la partida, la cama, del carro de esquejes, de la genética, la orden de registro, la redada con la caja y los accesorios; el menú OBJETIVO con las misiones, el SMS de Toño a 3 días del plazo y las misiones de las partidas viejas); `npm run analisis` con los niveles, la orden y la redada nueva jugados (`docs/ANALISIS.md` § 2.7).

## App de Android 0.4.0 (Godot) · 9 de octubre de 2026

La app de Godot es la de Android y pasa las normas básicas de un juego para móvil (`docs/NORMAS-MOVIL.md`); la ficha de Google Play, en `docs/PLAY.md`.

- **Nuevo: icono de la app**, dibujado a mano (`tools/sprites/a-mano/icono.py`): una hoja de 7 foliolos verde fresco con el halo del foco detrás, sobre la ribera de noche (la orilla y el río). Clásico y adaptativo (Android 8+, entero dentro de cualquier máscara), nítido en cada densidad, en las dos APK; el de la ficha de Play, a 512. Antes, la app de WebView recortaba la hoja del título y la de Godot llevaba un dibujo de prueba.
- **Nuevo: pantalla de arranque** con el icono sobre el fondo del juego (sin el logo del motor), y la app se llama «Ribera Verde».
- **Nuevo: aviso de edad** la primera vez: juego de ficción para mayores de 18 años; «SALIR» cierra la app.
- **Nuevo: el título** con CONTINUAR, NUEVA PARTIDA, **OPCIONES** y **CRÉDITOS** (créditos, licencias enteras de Godot y de las fuentes, y privacidad, en un texto con scroll; las licencias, unas 80.000 letras, por páginas para que abran al momento).
- **Nuevo: OPCIONES** (en el título y en el menú START, en lugar de SONIDO): volumen de la música y de los efectos por separado (de 25 en 25 %), velocidad del texto (normal, rápido o al momento), sonido y, en el título, borrar la partida. Se guardan aparte de la partida y se recuerdan. En el HTML, las mismas OPCIONES en START (sin borrar partida).
- **Cambiado: el botón Atrás** andando por el mapa abre la pausa (el menú START) en vez de cerrar la app; en el título sale. Al volver a la app, el juego espera en pausa.
- **Cambiado: START, MÓVIL y SONIDO se tocan en 48 × 48 dp** como poco (el mínimo de Android), aunque se vean igual.
- `docs/PRIVACIDAD.md` (no recoge ningún dato) y `docs/play/` (icono 512, gráfico destacado y capturas).

## 1.10.0 · 8 de octubre de 2026

Sale con el arte del plan de producción (`docs/PLAN-PRODUCCION.md`, P3–P6 cerrados). Godot, 0.3.0.

- **Nuevo: la carpa por dentro con todo el equipo (lámina B de la vista C).** Con el arte, la carpa se ve siempre por dentro (vista C); la vista B queda para cuando falta el arte. Dibujado a mano (`tools/sprites/a-mano/equipo_c.py`, sin PixelLab), con la paleta de la campana aprobada:
  - **Focos LED de barras** (como los de 720 W de 8 barras: barras delgadas con aire entre ellas): 3 barras el de 100 W, 4 el de 200, 6 el de 480 y 8 el de 720, cada uno a su ancho real en cada carpa, con la cara de diodos encendida (apagados, en gris). Su luz es la suya: blanca de espectro completo, algo rosada, un haz por barra que baja hasta el suelo y se abre hasta las paredes de la carpa (según el ancho de la carpa, el del foco y cuántas barras lleva), con un charco más ancho en el suelo; el **CFL** también en las carpas de 200 cm (la campana aprobada, más pequeña).
  - **Macetas** de tela de 11 y 25 L y de plástico de 18 L, cada una a su tamaño, con la tierra a su altura.
  - **La planta muerta:** la de su porte, seca y marrón, más baja y quieta.
  - **Extras:** el filtro de carbón colgado arriba (el extractor tiembla), el ventilador de pinza con las aspas girando (con él, las plantas se mecen el doble de rápido), el depósito del goteo con el agua que le queda en la mirilla y, en el suelo, un ramal por fila con la llave y el microtubo de cada maceta; con garrafas, cada maceta lleva la suya a su tamaño, con el agua que le queda y las rayas en la curva del cilindro.
  - Cada maceta deja su sombra en el suelo, y el suelo de la carpa se oscurece hacia los bordes.
  - **La luz del foco, lisa:** el cono ya no lleva la textura de la imagen A, que era la sombra de las cortinas; queda un resplandor bajo la boca del foco y un haz central, en los mismos tonos y con el color de cada foco.
  - **El foco sube a medida que crecen:** cuelga a la distancia que pide la fase de las plantas (germinando y plántula, 1,5 veces la distancia de seguridad del foco; vegetativo, 1,4; floración y lista, la de seguridad: el LED de 720 W a 60, 56 y 40 cm) de la planta que lo tiene más cerca (de una muerta, a la distancia de seguridad), y sube con ellas: mientras crecen, nunca baja. Bajado, cuelga de dos poleas del techo, cada una con su tirador, y su luz baja con él.
- **Nuevo: temporizador en cada carpa:** en la pared, a su izquierda (en el piso y en la vista de carpa), con la rueda de pinzas del color del modo: **automático** (18 h de luz mientras crecen y 12 en floración, como hasta ahora), **18/6** (las que no florecen aún, no florecen: madres para sacar esquejes; gasta más luz) y **12/12** (florecen ya: el vegetativo dura la mitad y la cosecha baja hasta un 40 %; gasta menos). Se elige en la vista de carpa con ◀ desde el foco o desde la planta de la izquierda, y A; la factura de la luz va con las horas del modo.
- **Nuevo: el salón del piso.** El piso crece a 18 × 8 m: a la derecha, el salón, vacío al llegar (es la casa de la tía). Los muebles se compran en la **tienda online** (en el ordenador de la tía, en el PC gaming o en el móvil), se pagan con lo que llevas y, si no llega, con la caja fuerte, y llegan al día siguiente, montados (`12c-salon.js`; arte a mano, `tools/sprites/a-mano/salon.py`):
  - **Sofá de 2 plazas** (399 €, 180 cm): una cabezada de 1 h (+5 de vida) o ver la tele desde él.
  - **Tele de 43" con mueble** (449 €): las noticias (según tu calor: el tiempo, una detención en el puerto o la policía buscando un cultivo en el barrio) o un documental (landraces, hachís, bancos de semillas), 1 h.
  - **PC gaming con mesa** (1.490 €): jugar 2 h, el **foro de cultivo** (consejos de verdad: pH, humedad en floración, madres a 18/6, fugas de luz y hermafroditas, tricomas, secado y curado, abono y riego, distancia del foco) y la tienda.
- **Cambiado: el menú START**, con un icono por opción y lo que importa a la derecha (variedades de la Genoteca, kilos encima, SMS sin leer, plantas vivas, capítulo, sonido SÍ/NO); arriba, el día, la hora y el dinero.
- **Nuevo: botón MÓVIL** encima de la cruceta (y la tecla P): abre el móvil de un toque, sin pasar por START. Solo se ve andando por el mapa.
- **Cambiado: nada se pisa en pantalla.** Los avisos se apartan del HUD (a su derecha si caben y, si no, debajo), de la ficha de la carpa y de SONIDO; con un menú a pantalla completa salen encima de él, abajo, y no detrás. En el combate, el texto no pasa por debajo del menú. El rótulo del título baja si SONIDO le pisa la esquina. Auditado en 11 tamaños de pantalla (de 568 × 320 a 1920 × 1080) y 11 estados: 0 solapes (antes, 40 de 121).
- **Cambiado: los iconos, alineados con el texto y pixel perfect.** Cada icono se centra en su celda por lo que pinta y en la línea del texto, y sale a un múltiplo entero de sus píxeles en la pantalla (16, 32, 48… píxeles del dispositivo; los de 32, también a la mitad): todos los píxeles, iguales.
- **Cambiado: el cogollo de la Genoteca**, redibujado a mano: verde fresco, con los cálices apilados, pistilos naranjas y la escarcha de los tricomas (el de antes parecía seco y marrón).
- **Cambiado: las carpas del piso, a su medida también de fondo.** El frente ya iba a su ancho y alto reales a 16 px/m; ahora el techo va a medio fondo como la nevera y los muebles: +1 px la de 100 y la de 150 y +2 la de 120 × 120 (`tools/sprites/a-mano/carpas_mapa.py`).
- **Nuevo: iconos del equipo** (lámina 12, a mano): armario, carpa, LED, ventilador, filtro, garrafa y goteo, en la tienda, la mochila, la lista de plantas y el menú de focos (los LED, de barras; el resto de focos, la lámpara).
- **Nuevo: la nevera y las cajas a escala** (lámina 13, a mano): la nevera de 60 × 180 cm y las cajas de 40 cm a 1 casilla = 1 m, en el piso y en el almacén.
- **Nuevo: sombras y noche en el piso.** Los muebles (mesas, taburetes, nevera, cajas, mostradores, la gramola, la cama…) dejan su sombra en el suelo sin pisar la del vecino. De noche el piso se oscurece como la calle y cada carpa con plantas vivas deja delante una mancha de luz del color de su foco.
- Igual en Godot (0.3.0): 9 escenas de la vista C (LED y extras, garrafas, muertas) y 29 pantallas (con el piso de noche) comparadas con el HTML, 0 diferencias; la partida jugada con los mandos ve siempre la vista C.

- **Nuevo: el móvil.** En el menú START, estés donde estés (`12b-movil.js`):
  - **Llamar** a Kiko (un consejo), a Toño (lo que debes y hasta cuándo) y a Iñaki (la carga al por mayor del día).
  - **Agenda de clientes:** quien te compra en la calle te da su número (hasta 8, con nombre propio). Llamado, viene a buscarte a la calle en 20 minutos (+1 de calor), una vez al día y nunca con la policía detrás; desde casa, «Quedamos en la calle».
  - **Pedir a Kiko** lo del growshop (no semillas, carpas ni la prensa): un 15 % más caro y llega a casa al día siguiente por la mañana, con su SMS.
  - **Mensajes:** los SMS de Kiko, Toño, Iñaki, Molina y Darko se guardan (los 30 últimos).
- **Nuevo: el arcón y la mochila con tope.** Lo que llevas encima (cogollos y rosin) tiene tope: la mochila 1 kg, la bolsa de deporte 3 kg (35 €, capítulo 3) y la maleta con ruedas 10 kg (90 €, capítulo 5). Al cosechar, lo que no cabe va al arcón de casa, entre la cama y la nevera: guardar todo, guardar o sacar un lote (hasta el tope; de la caja fuerte, igual). Un control en la calle no lo ve; una redada se lo lleva (no la caja fuerte) y Darko, la mitad (y cuenta para que entre a robar). La mochila del menú enseña las dos cosas.
- **Nuevo: el clima de la sala** (`09c-sala.js`). Temperatura y humedad según el mes (12 días son un año; el día 1 es abril), de día o de noche, el calor de los focos encendidos (el sodio calienta 2,5 veces más que el LED), la humedad de las plantas y los extractores con filtro. Fuera de 18-30 °C o 40-60 % las plantas crecen más despacio (−6 % por grado y −1,5 % por punto) y, con la humedad por encima del 60 % en floración, les sale moho (−0,1 de salud por hora y punto de más; lo avisa al despertar). Kiko vende el termohigrómetro (12 €; sin él, PLANTAS enseña «¿?»), el calefactor, el humidificador, el deshumidificador y el aire acondicionado: son termostatos (el calefactor sube hasta 6 °C, el aire baja hasta 12, el humidificador sube 15 puntos y el deshumidificador baja 20), solo trabajan con plantas y se pagan en la factura de la luz. Lo pedido por el móvil no se vuelve a vender en la tienda.
- **Cambiado: el riego automático, en dos niveles.** Antes el goteo regaba la mitad para siempre. Ahora:
  - **Garrafas de riego** (15 €, capítulo 1, una tanda por carpa): una garrafa con gotero junto a cada maceta, de 0,65 L por litro de su tierra (16 L la de 25 L): le dura media cosecha. «Rellenar garrafas» en la vista de carpa, que enseña los litros que quedan.
  - **Riego por goteo** (1.200 €, capítulo 4; antes 55 €): un depósito grande con bomba para toda la carpa de 6,5 L por litro de tierra que admite (650 L la de 100): unas cinco cosechas con la carpa llena. Se rellena con «Rellenar depósito». Al ponerlo, las garrafas de esa carpa vuelven a la mochila. Un goteo de una partida vieja sigue puesto y se rellena hasta su nuevo tamaño.
  - Los dos riegan igual: la planta que baja del 50 % vuelve al 100 % gastando la mitad de los litros de su maceta por cada 100 %; vacío, no riega. En la vista B, cada maceta lleva su garrafa detrás a la derecha (de 5 a 16 L, a su tamaño real, con el agua que le queda y el tubo del gotero) y el depósito del goteo va al lado de la carpa a su tamaño real (de 234 a 975 L: un cilindro de 0,6 a 1 m de ancho, con los aros curvados como el cilindro y un tubo de nivel con el agua que le queda); su manguera entra por la pared derecha y baja al suelo, de ahí sale un ramal por detrás de cada fila y cada maceta tiene su llave y su microtubo, que sube por su lado hasta el borde, a la altura de su maceta, y entra en la tierra; la vista C también las dibuja (ver arriba); al cambiar la maceta, su garrafa queda llena. Una cosecha gasta ~1,3 L de agua por litro de tierra (1-1,7 según foco, maceta y variedad: medido con el juego).
- **Arreglado: los restos de las cortinas en la vista C.** La luz del foco aún tenía 40 píxeles de los brillos de las cortinas junto al suelo (x 32-35 y 203-207), fuera de la bandeja; borrados.
- Igual en Godot: los cuatro cambios, con sus 5 pasos en la historia (82, 0 diferencias con el HTML).

- **Cambiado: la carpa por dentro (vista C), plateada.** La pared verdeazulada con cortinas de la imagen A da paso a la tela plateada (mylar) y el armazón negro de las carpas del piso y de la vista B: vetas verticales, laterales más oscuros hacia delante, la bandeja blanca con su rejilla, los postes y la cremallera de la puerta abierta. Misma pared del fondo y laterales, así que plantas, macetas, focos y luz van donde iban; la luz del foco pierde los brillos que tenía pintados en las cortinas. Dibujada a mano (`tools/sprites/a-mano/carpa_c.py`). Igual en Godot.
- **Nuevo: tope de tierra por carpa.** Además de la maceta más grande que cabe en cada plaza, la tierra de todas las macetas de una carpa no pasa de 100 L por m² de suelo (`LITROS_M2`; 36 L el armario de 60, 64 el de 80, 100 la carpa de 100, 144 la de 120 y 150 la de 150). «Cambiar maceta» solo ofrece las que caben y, si no cabe ninguna por la tierra, lo dice («No cabe más tierra en la carpa (tierra 132 de 144 L)»); la ficha de la carpa en PLANTAS enseña el tope y lo puesto. Igual en Godot.
- **Cambiado: la carpa abierta, con las plateadas.** La vista B (desde la lámina B de esta versión, solo cuando falta el arte de la vista C) ya no pinta la carpa en 3/4 por código: pinta de frente la carpa plateada aprobada de su tamaño (`carpa-<t>-vista`, las 5, también las de 80 y 120) y las macetas, plantas, focos y extras se colocan sobre su suelo, que se cierra hacia el fondo. La escala pasa de 48 a 60 px/m de ancho y alto, la del sprite: el foco, a 28 cm del techo, cuelga justo bajo el techo de dentro del dibujo, y nada de lo que cuelga sube de ahí; el depósito del goteo va al lado de la carpa, con el tubo por la puerta. Sin atlas sigue la de 3/4. Igual en Godot.
- **Cambiado: el rosin, como la flor.** La caja fuerte lo guarda y lo saca («Guardar rosin» / «Sacar rosin», y también «Guardar todo» y «Sacar todo»), en el mismo hueco que los cogollos; lo de dentro no lo toca Darko, que se lleva la mitad del de fuera, y la redada que encuentra la caja se lo lleva también. Los ladrones y el robo de Darko cuentan el rosin como la flor de la que sale (1 g = 5 g). La mochila enseña el rosin de la caja. Igual en Godot.
- **Nuevo: perder el último autobús.** Fuera de hora, el poste de la parada ofrece «Esperar al de las 7:00» (el reloj corre hasta las siete y sigue el viaje); en Mendialde, la cama de casa de ama: «Dormir hasta las 7», sin robo de Darko ni avisos de las plantas del piso.
- **Arreglado: la barra de sospecha, al momento.** El HUD la repinta en el fotograma en que cambia (antes, hasta 250 ms tarde). Igual en Godot.
- **Nuevo: el armario de 80 y la carpa de 120 con arte** (`tools/sprites/a-mano/carpas.py`), alargando por dentro el arte aprobado de sus vecinas (de 60 y de 100): solo columnas y filas que ya estaban, misma paleta. Aprobados los de la vista B; los del piso, pendientes de aprobación.
- **Mandos a la medida del pulgar.** Se miden en milímetros (1 px CSS = 1/160 de pulgada) y van donde descansan los pulgares con el móvil en horizontal: cruceta de 24 mm (brazos de 8; antes 19 y 6,5 en un móvil de 360 de alto) con el centro a 16 mm del lado y 18 de abajo (antes 12 y 12), A y B de 10,5 mm (antes 8,6) inclinados 28°, A a 12 mm del lado y 19 de abajo, START encima de A, al alcance del pulgar (antes arriba del todo), y SONIDO arriba a la derecha, de 7 mm de alto (antes 4). La cruceta es de un dedo: se desliza de una flecha a otra sin levantarlo y responde 3 mm por fuera de la cruz; A y B, 2,5 mm por fuera de cada botón. En un móvil estrecho encogen hasta que el escenario de diálogos cabe entre ellos (en 568 × 320, del tamaño de antes); el escenario se estrecha para dejarles sitio (740 × 360: 1,46 px por píxel en vez de 1,9; nunca menos de 1,3), también con la muesca a un solo lado. En el combate, la caja de vida se aparta de A, B y START. Si el juego pierde el foco con un dedo puesto (otra app, la pantalla apagada), los mandos se sueltan. Igual en Godot.
- **Nuevo: la comarca, por biomas, y el autobús.** Además de Ribera Verde (la ciudad grande: el barrio, el barrio alto y los astilleros), dos ciudades pequeñas y dos pueblos, cada uno con sus casas, sus clientes y su riesgo (`ZONAS`): **Puerto Viejo** (40 × 24; casas marineras de colores, paseo y pantalanes; un agente de patrulla, ladrones ×0,6, el gramo ×1,15; turistas), **Valdehierro** (40 × 24; bloques de ladrillo, la fundición y un solar vallado; un agente, ladrones ×1,4, el gramo ×0,9), **Mendialde** (48 × 34; caseríos, plaza, maizal y manzanal) y **Errotabarri** (36 × 24; el río, el puente y el molino), los dos pueblos con sin policía, ladrones ×0,1 y un solo cliente al día. Se va en **autobús**: en el poste de cada parada (de 7:00 a 21:00), a dónde, cuánto (2–3 € desde Ribera Verde; entre dos de fuera, la suma) y cuánto tarda (20–40 min, que corren en el reloj). Un vecino en cada sitio (vecina, excursionista, turista y obrero) y sus carteles.
- **Nuevo: el prólogo en el pueblo.** La partida empieza en el caserío de la familia, en Mendialde: Kiko llama por teléfono, ama deja una nota y un táper de alubias en la nevera (un bocata) y el primer autobús, que paga ama, te deja en la parada de enfrente del piso. Las partidas guardadas de antes siguen en el piso.
- **Arreglado: los árboles, a escala, y el arte de cada sitio.** El árbol medía 1,5 m: ahora 5,8 m (6 m reales), con su sombra y tapando lo de detrás; los lindes de los mapas son monte (bosque espeso) y seto, y ya no hay nada escondido bajo una copa (los clientes no salen tapados). La comisaría (sillar, puerta doble) y el almacén (nave de chapa, puerta corredera) tienen su fachada en vez de la gris de Txaro; caseríos con su puerta, casas marineras, bloques de ladrillo, la fundición y la parada, todo dibujado a mano (`tools/sprites/a-mano/mundo.py`, sin PixelLab). Los objetos altos ya no aparecen de golpe al entrar en pantalla.
- **Cambiado: el mundo, menos cuadriculado.** Los árboles y el monte ya no van a compás de la rejilla: cada uno se corre unos píxeles (hasta 6 a los lados y 3 arriba o abajo) y la mitad va en espejo, siempre igual para la misma casilla; hay dos árboles nuevos (un árbol alto de copa estrecha y el manzano). La hierba lleva detalles sueltos (flores, matas, piedras y hojas) en 1 de cada 4 casillas y los firmes nuevos, variantes (juntas, musgo, manchas, charcos, baches y grietas). Los bordes de los mapas de la comarca entran y salen y hay bosquetes. **Mendialde** crece a 48 × 34 y tiene partes: arriba, el barrio viejo por pistas de hormigón; en medio, la carretera y la plaza; abajo, las afueras por una pista de tierra (el maizal, el manzanal y una borda). **Errotabarri** (36 × 24) no tiene asfalto: una pista de tierra cruza el río, que ahora serpentea, por un puente de madera. **Valdehierro** tiene la carretera rota (baches, parches y la raya borrada) y una nave entre los bloques. Casas de varios tamaños, parecidas entre sí: el caserío pequeño (6 × 5), la borda (4 × 4) y las casas marineras de 3 × 5 y de 5 × 7 (dos pisos) de Puerto Viejo. La vecina, el excursionista, el turista y el obrero salen ya con su sprite del atlas (el manifiesto los tenía y el atlas no se había rehecho). Todo dibujado a mano (`tools/sprites/a-mano/mundo.py`), igual en Godot; el barrio, el barrio alto y los astilleros conservan su trazado (solo se mueven sus árboles).
- **Nuevo: la caja fuerte de la tía.** Detrás del diploma de la Copa de 1998 hay una caja con rueda de cuatro cifras; la pista está en las notas del ordenador («la combinación, el año en que lo gané») y dentro hay 300 €. Caben 20.000 € y 2 kg, y lo que está dentro no va encima: no cuenta para los encuentros ni para el soborno, y no te lo quitan un control, un ladrón ni Darko. En una redada la encuentran 1 de cada 4 veces. Desde el capítulo 4, por el ordenador, la **caja empotrada** (380 €, la instala Kiko al día siguiente): 50.000 € y 2,5 kg. La luz, el ordenador y la multa de la redada se pagan de fuera y, si no llega, de la caja; la mochila enseña las dos cosas.
- **Nuevo: el mapa crece.** Dos zonas de 40 × 30 con su riesgo: el **barrio alto**, al norte (plaza del Ensanche y la comisaría; 2 agentes de patrulla también de día y la mitad de ladrones; pijos y turistas desde el capítulo 3), y los **astilleros**, al este del muelle (el almacén; un solo agente, también de noche, el doble de ladrones y el gramo un 20 % más caro, pero son las esquinas de Darko: 1 de cada 3 ventas acaba en pelea). Y tres interiores: la casa de Txaro, la comisaría y el almacén. Cada zona tiene sus farolas y su secreto (80 € en un arbusto del barrio alto, 2 sprays en los astilleros).
- **Nuevo: patrullas de policía que se ven.** La policía ya no sale al azar al dar un paso: los agentes andan por la calle (desde el capítulo 2; 1 de día y 2 de noche en el barrio, 2 en el barrio alto, 1 en los astilleros, Puerto Viejo y Valdehierro, ninguno en los pueblos), siguen recto, se paran a mirar y giran (`10b-patrulla.js`). Ven 5 casillas hacia delante en cono, si no tapa un edificio, un árbol, un seto o unas cajas; de día se ve el cono, de noche no.
  - **Sospecha:** si un agente te ve con algo encima, se llena la barra SOSPECHA del HUD: de día, despacio y con aviso («Un agente te está mirando»); de noche, 2,5 veces más deprisa y el aviso («Oyes pasos detrás de ti») llega tarde. Sube más con más gramos (hasta 100) y con calor, y la protección de Molina la divide por 2,5. Sin verte, baja. Vender con un agente a 5 casillas o menos (aunque no mire) la sube 60 de golpe. Si una persecución deja a un agente fuera de la calle, vuelve a ella; si al amanecer se va el que te seguía, lo has despistado. Al caer KO, el ladrón también se lleva la mitad del rosin, y ahora lo dice.
  - **Alarma:** llena, suena la alarma («¡ALTO, POLICÍA! Corre (B): métete en un portal o aléjate.») y, tras 0,6 s quieto para dar tiempo a reaccionar, el agente corre a por ti. Corriendo le sacas distancia; andando, no. Si se pone a tu lado cuando estás parado, control (el de siempre: sobornar, hablar, huir o entregar). Te pierde si entras por una puerta, sales del mapa o subes al autobús, o a más de 10 casillas y 4 s sin verte. Tras un control, 30 s de tregua.
  - Lo de la caja fuerte no cuenta: sin nada encima, ni sospecha. Los ladrones siguen saliendo al azar, pero no mientras te persigue un agente.
- **Nuevo: rosin.** Kiko vende una prensa (250 €, capítulo 3). En la mesa del piso, «Prensar rosin»: de 5 g de cogollo sale 1 g con el triple de THC (hasta el 75 %), en media hora. Lo compran los catadores, clientes nuevos con su propio bocadillo (una gota ámbar): 1-3 g, a 10 + 0,6 × THC el gramo (unos 42 € al 54 %); 2 al día en el barrio y 1 en los astilleros, Puerto Viejo y Valdehierro. Prensar compensa desde el 12,5 % de THC de la flor, y cada gramo vendido sube el calor 2,5. La mochila y el HUD enseñan el rosin aparte; en Godot, lo mismo.
- **Cambiado: el guion, completo** (los 8 problemas de `docs/ANALISIS.md`):
  - el **capítulo 4** pide sacar en la mesa 2 variedades de receta y cosechar una planta de cada (antes se pasaba solo comprando semillas);
  - el **primer plazo** corre desde que aparece Toño («tienes siete días para el primer pago»); si tardas más de 2 días en ir al bar, Baltasar te recibe con «Llegas tarde»;
  - **Darko** roba el piso en el capítulo 7 (la primera vez que duermes con más de 1.000 € o 100 g fuera de la caja se lleva la mitad) y desde entonces vigila los astilleros;
  - **Baltasar** da encargos en el imperio: 2 kg (5 y 10 kg en los rangos altos) a 6 €/g, entregados de noche a Toño en el almacén en 2 días; si fallas, reputación −10 y 5 días sin encargos;
  - al **tercer plazo vencido**, Toño se lleva la carpa más grande del piso con sus plantas (sin carpas, la mitad del dinero);
  - la Copa ya no es «el sábado»: se juega «estos días»;
  - **Molina** cobra 1.500 € cada 10 días, en la comisaría del barrio alto, y avisa por SMS cuando se acaba;
  - el objetivo del capítulo 2 dice «vendiendo»;
  - y la abuela Txaro, en su casa desde el capítulo 4, pide 10 g de una índica y da 3 semillas de Chitral Kush.
- **Cambiado: el equilibrio de la calle.** Al por mayor sube el calor 2 + 1 por cada 100 g (antes, por cada 250 g); el soborno suma el 5 % del dinero que llevas encima; los ladrones, desde el capítulo 5, tienen 4 de vida más y pegan 1 más.
- **Arreglado: las puertas de los edificios grises y las alturas.** En la casa de Txaro, la comisaría y el almacén la puerta ya cabe: las dos ventanas de abajo se apartan 9 px hacia fuera (`fachada_puerta.py`, fachada `gray-puerta`) y la puerta es una sola, la de casa, sin pisar la pared. La farola mide 3,5 m (antes 1,69), el mostrador y la barra 1 m (antes 0,69; la barra ya es más alta que los taburetes) y la gramola 1,5 m (`alturas.py`, retoque a mano, sin créditos); las ventanas y los carteles de pared (el diploma) se cuelgan a 0,9 m, las baldas de las plantas a 1 m y el botellero a 1,05 m (`ALZA`).
- **Arreglado (revisión):** Toño ya no pide el encargo en el almacén cuando el plazo se acabó («El plazo se acabó. Don Baltasar ya te escribirá.»); Darko y el aviso de la plaza no vuelven a salir en el pueblo desde el capítulo 7.
- **Nuevo: análisis del guion y de los riesgos de la calle** (`docs/ANALISIS.md`, `npm run analisis`): la historia y las misiones, probabilidades de ladrones por paso, por zona y por trayecto, la sospecha y la huida de las patrullas, cada estrategia de combate, el soborno, el calor, la redada, la Copa y la caja fuerte. Las tablas salen de un modelo exacto y se comprueban jugando cada caso con las funciones del juego, también los viajes y la redada con la caja llena.
- **Nuevo: el juego entero en Godot 4 (`godot/`, 0.2.0).** Lo que empezó como corte de prueba (la vista C y un ciclo de cultivo) es ya el juego completo portado a Godot 4.3: el barrio, el piso, la tienda y el bar con sus personajes y clientes, la historia de los 8 capítulos con la deuda, el imperio y el final, el cultivo entero (esquejes, cambio de maceta y de foco, extras, Genoteca, banco de semillas y mesa de genética), la carpa en vista B y en vista C, los combates, el título y la intro, los menús, el sonido y el guardado. Sale como APK aparte (`npm run godot:apk` → `dist/ribera-verde-godot.apk`, paquete `com.riberaverde.godot`), que se instala al lado del de siempre.
  - **Igual que el HTML, comprobado:** la historia 1 → 8 con el mismo piloto y el mismo azar que `npm test` (77 pasos, con la caja, las zonas, el guion nuevo, el prólogo, el autobús, el rosin y las patrullas; 0 diferencias en diálogos, estado y dónde está cada cosa); 27 pantallas pintadas por los dos y comparadas píxel a píxel (el piso, la calle de día y de tarde, la tienda, el bar, el barrio alto, los astilleros de noche, la casa de Txaro, la comisaría, el almacén, Mendialde, Errotabarri, Valdehierro, Puerto Viejo al atardecer, una patrulla de día con su cono y otra de noche persiguiéndote, la vista B y la C, los combates, los títulos y la intro: lo opaco, idéntico; lo que se mezcla, como mucho a 4 de 255 por canal); la vista C, los ciclos de cultivo, la cama y la cosecha como en el corte.
  - **Jugado con los mandos:** una partida nueva desde el título (con el nombre escrito a mano), el menú START entero, un paseo por la calle y un ciclo de cultivo de punta a punta, andando hasta la carpa y hasta la cama, con el dedo, el teclado y el ratón, y CONTINUAR desde el título (`tests/ciclo.gd`).
  - Los mandos, menús, diálogos, avisos y el HUD van como en el HTML; en el ordenador, los mandos salen del tamaño de un móvil.
- **Nuevo en el HTML: barras, avisos y daños de plaga** (los tenía solo el port de Godot). Encima de cada planta, una barra de agua (roja y parpadeando por debajo del 30 %: toca regar) y otra de cosecha (dorada y parpadeando cuando está lista), con una «!» roja si tiene plaga; las de delante de la planta elegida, en transparencia como su planta, y ninguna pisa a otra ni al cursor. Al despertar, un aviso dice qué plantas han cogido plaga (y cuánto insecticida queda), cuáles la siguen teniendo y cuáles se han secado del todo esa noche. En la vista C, la plaga se ve en la planta: manchas amarillas y pardas y punteado en las hojas, telilla y podrido en los cogollos, sacados de los píxeles de cada sprite y más fuertes cuanta menos salud le queda; tratada, vuelve a ser la de siempre.
- **Nuevo: cifras reales** (`docs/ECONOMIA.md`, generado con `npm run docs`). Lo único comprimido es el tiempo: un día de juego son unas 4 semanas de cultivo.
  - **Cosecha por gramos por vatio:** cada foco da `W × g/W` por cosecha (CFL 0,25, sodio 0,45–0,55, LED 0,65–0,85; abonando, ×1,25), repartidos entre las plazas de la carpa (una plaza vacía es luz perdida), con el rinde de la variedad y un tope por maceta de unos 8 g por litro (56 g en 7 L, 210 g en 25 L). La carpa enseña sus W/m² y la ficha de cada variedad, sus g/m².
  - **Luz:** 392 h de foco y 672 h de extras por día de juego a 0,16 €/kWh: CFL 8 €, sodio 400 W 25 €, LED 720 W 45 €. El ventilador (25 W) y el extractor (75 W) también gastan.
  - **Precios de growshop:** focos de 85 a 950 €, carpas de 90 a 150 €, macetas de 2 a 4 €, abono de 1 L (4 dosis) 14 €, insecticida de neem (3 tratamientos) 12 €.
  - **Calle:** 6,4–10 €/g según el THC. **Multas:** 601 € en la calle (la mínima de la Ley de Seguridad Ciudadana) y hasta 3.000 € en una redada.
- **Nuevo: semillas como en un growshop.** Feminizadas, a precio por semilla (5–10 €), en sobres de 1, 3, 5 y 10 con descuento y, desde el capítulo 3, bolsas de 50 a granel. El banco del PC vende sobres de 10 (20–45 €). Al cosechar, una feminizada casi nunca da semilla (12 % hermafroditas, 1–3); las regulares (las landraces, como el Afghani que te da Kiko, y tus líneas fijadas) dan 1–3, y una línea sin fijar se poliniza entre ella y da 2–5. Así nunca te quedas sin Afghani ni Hindu Kush para las recetas.
- **Nuevo: fenotipos.** Cada semilla es una planta distinta (THC y gramos, cada uno por su lado). La ficha de cada variedad dice su tipo (landrace, línea estable, cruce F1 con sus padres, polihíbrido o F1–F3 propia) y cada cuántas plantas sale un **fenotipo estrella** según su pureza: 1 de cada ~16.000 en una línea estable, ~2.000 en un F1 de tienda, ~100 en una landrace, ~60 en un polihíbrido y ~40 en una F2. La estrella va a un lote aparte (★), que se vende y se presenta a la Copa por separado. Sustituye al ×0,8–1,1 de las F1 de la 1.9.
- **Nuevo: esquejes.** A una planta en crecimiento se le saca un esqueje: es la misma planta, con su fenotipo. Se planta desde el menú de semillas (empieza de plántula) y se seca si no se planta antes de que acabe el día siguiente. Así se guarda una estrella.
- **Nuevo: venta al por mayor.** Desde el capítulo 3, Iñaki carga lotes de 100 g para arriba a 3,2–5 €/g, una vez al día y hasta 1 kg.
- **Cambiado: la deuda, a escala.** 30.000 € en plazos de 3.000, 12.000 y 15.000 €; intereses del 20 % del plazo, Copa de 5.000 € y protección de Molina por 1.500 €. Con las cifras nuevas, los plazos se pagan en unas 4, 8 y 9 cosechas, lo mismo que antes (simulación en `docs/ECONOMIA.md`).
- **Nuevo: tu imperio.** Saldada la deuda («DEUDA SALDADA» en vez de «FIN»), el capítulo 8 sigue con rangos por lo facturado desde el último pago: Cultivador, Proveedor del barrio (25.000 €), Distribuidor de la ría (100.000 €) y Mayorista del norte (250.000 €). Cada uno sube lo que Iñaki carga al día (1, 2, 5 y 10 kg) y llega con un SMS.
- **P3 del plan de producción: vista C (corte de prueba aprobado).** La carpa se ve por dentro a toda la altura de la pantalla, como la imagen A del tablero de estilos, y su arte sale de esa imagen: pared, luz, campana del foco de sodio, maceta de 7 L e índica en floración.
  - La pared solo lleva la tela, con sus brillos y sombras, sin la forma del cono de luz. Macetas y plantas tampoco llevan la luz pintada.
  - La luz del foco es una capa aparte que se pinta delante de todo (pared, macetas y plantas) y se apaga con el foco.
  - Cada carpa va a su escala, con la boca del foco a su altura real. Las copas no pasan de la distancia segura, tampoco en el armario 80 con dos filas.
  - A los lados de la carpa, el cuarto queda a oscuras.
  - Mientras falte arte para algo de la carpa (otros focos, macetas, extras, fases o portes), se ve la vista B.
  - Se descarta la lámina 1 (fondo del cuarto para la vista B), porque no se parecía a la imagen A.
- **P3, lámina A (el CFL, pendiente; la híbrida, sustituida por la planta A, abajo): el CFL y la híbrida en el armario 60.** La vista C ya sale con el foco CFL y con la Skunk #1 (híbrida) en sus 5 fases: germinando, plántula, vegetativo, floración y lista.
  - La luz del CFL es la misma capa de luz con su color frío y más suave. Apagado, el tubo se ve gris.
  - Cada fase tiene su sprite a su tamaño (entre ×0,75 y ×1,33 del real, como en la vista B), y más alta quiere decir más nudos: más pisos de ramas y más cogollos, no los mismos estirados (lista de 99 px, 11 nudos; de 40, 3). Floración y lista comparten sprite. Con el CFL la planta sube hasta 10 cm del foco; con el sodio de 250 W, hasta 30.
  - La híbrida está dibujada a cada alto (floración y lista, de 40 a 99 px; vegetativo, de 18 a 52): más baja, en floración o por la distancia al foco, es otro dibujo con menos nudos, no el grande con trozos de menos.
  - La índica, más baja que su sprite, pierde pisos de ramas enteros del medio (el más bajo que quepa; el de arriba y el de abajo se quedan, para que no asome el corte de un piso como un estante) y filas de tallo pelado, sin aplastar los píxeles; la de 36 (carpas de 100 y 150), por ahora solo filas de tallo pelado.
  - La híbrida está dibujada a mano, sin PixelLab: hojas de abanico grandes abajo, ramas con colas a los dos lados, cogollos pegados al tallo, la cola arriba y pistilos naranjas, en verde frío (paleta A). La de antes, montada con trozos de la índica, no se leía como cannabis.
  - Todas las híbridas comparten ese arte (cada una con el color de sus cogollos). Las índicas siguen en la vista B hasta la floración y las sativas, siempre. En las carpas de 200 cm, el CFL y la híbrida en floración y lista de la 100 y la 150 también, hasta que llegue su arte.
- **P3, planta A (aprobada; el vegetativo y los cogollos sin pera, pendientes de visto bueno): la forma sale de la genética.** Una sola planta, dibujada a mano, para índicas, híbridas y sativas en las 5 fases: baja, despuntada y en mainline, con una corona de 6 ramas y sus colas en zigzag (3 detrás, más altas, y 3 delante), con aire entre las puntas; cada rama pelada abajo (lollipop), yemas en pares cruzados con sus hojas y cogollos de cálices con pistilos y tricomas. En vegetativo, la misma corona con hojas de abanico en cada nudo y un brote en cada punta.
  - **Cogollos sin forma de pera:** cada cogollito de la cola es ancho arriba y estrecho abajo, con las puntas de los cálices hacia arriba y afuera, y las yemas de los nudos son dos cálices con una hoja de azúcar. Con una sola punta arriba y la base redonda, parecían peras.
  - **% índica de cada variedad** (dato real de las 41) y su **tono de hoja**. El porte sale de ahí: índica desde el 70 %, sativa por debajo del 30 % e híbrida entre medias. La índica tiene foliolos anchos, colas gordas y hoja oscura; la sativa sube más, con internudos más largos, colas largas y finas, 9 foliolos estrechos y hoja clara. Con esto, la Mango Kush pasa a híbrida y la Fire OG, a índica.
  - **Tamaños de lista:** índica 60 cm de ancho y 65 de alto, sativa 55 × 90 e híbrida 58 × 70 (despuntadas).
  - **Cruces nuevos** (los que no son de receta): el F1 sale en un X % de la madre (al azar, del 30 al 70 %) y el resto del padre: su % índica, su tono de hoja y el color de sus cogollos se mezclan en esa proporción. La Genoteca lo dice en la ficha: «Índica 62 % · sativa 38 % · 60 % madre · 40 % padre».
  - **Cada planta, la suya hasta la F4:** el fenotipo tira también el % índica de la planta alrededor del de su variedad (σ 0 en una línea estable, 3 en un F1 de tienda, 8 en tu F1, 15 en la F2, 10 en la F3 y en una landrace, 12 en un polihíbrido). Su porte y su tono de hoja salen de ese %: dos plantas de la misma F2 pueden salir una índica y otra sativa.
  - En la carpa, cada planta usa el dibujo más ancho (38 o 32 px) que deja aire con las de su fila y con las paredes, y el fotograma de su alto (hay uno cada 2 px), así que ya no pierde pisos de ramas.
  - Sustituye a la híbrida de la lámina A y a la índica de la imagen A (retiradas en el manifiesto). El atlas pesa 220 KB más.
- **P2 del plan de producción: vista de carpa B.** La carpa se abre recortada en 3/4, como en la 1.6–1.7, pero a escala real (48 px/m de ancho y alto, 24 px/m de fondo), con un foco centrado y la luz recortada a la carpa. Plantas en 3 portes (índica, sativa e híbrida). Todo procedural hasta P3–P4: `npm run sprites:huellas` saca las huellas de las láminas. `npm run plano` mide la vista B (29 de 35 piezas entre ×0,94 y ×1,06; germinando y plántula, ×2) y saca `docs/plano/vista-b.png`.
- **P1 del plan de producción** (decisiones D1–D6 aprobadas): datos y reglas del equipo nuevo.
  - **Armario 80×80** (90 €, capítulo 3): sustituye al de 60 en el sitio A. 3 plazas (la de atrás centrada), focos de hasta 400 W y macetas de hasta 18 L.
  - **Carpa 120×120** (150 €, capítulo 5): tercera carpa, en el sitio C nuevo, junto a la cama, cuando ya hay carpa en B. 6 plazas, hasta 720 W y 25 L. El máximo pasa de 8 plantas a 15.
  - **LED 100 W** (110 €, capítulo 1): el primer paso por encima del CFL.
  - **Extras**, uno de cada por carpa: ventilador de pinza (20 €, cap. 1, plagas ×0,7), extractor con filtro de carbón (110 €, cap. 2) y riego por goteo (55 €, cap. 3, el agua baja a la mitad). Al comprarlos, «¿Te lo pongo ya?»; si no, desde la vista de carpa (▲ hasta el foco y A). La ficha del foco enseña los que tiene la carpa.
  - **Regla nueva, el olor:** cada carpa sin filtro con alguna planta en floración suma +2 de calor al día (sale también en el aviso de la cama).
  - **Piso:** la ventana y el diploma de la pared pasan a (9,1) y (7,1), donde no los tapa ninguna carpa. El hueco de C se marca en el suelo cuando ya tienes carpa en B.
  - **Tienda:** un extra solo se ofrece si alguna carpa lo necesita y no lo llevas ya en la mochila.
  - **Cambiar de carpa:** cada planta y cada maceta se quedan en su carpa y su plaza (antes las plazas nuevas iban al final de la lista, lo que con el armario 80 habría movido las plantas de la carpa del fondo).
- **Nuevo: distancia segura en la vista de carpa.** Cada maceta va en el centro de su parte de la carpa, lo más separada posible (30 cm entre centros en el armario 60, 40 en el 80 y la carpa 120, 50 en las de 100 y 150). Una planta en floración ya no invade a sus vecinas ni las paredes: su copa se dibuja como mucho del hueco que le toca, menos 4 cm de aire, y su cima se queda a la distancia de seguridad del foco (CFL 10 cm, LED 25–40, sodio 30–50), como si la podaras y la doblaras. Con una plaza de atrás elegida, la fila de delante se ve en transparencia. Tabla en `docs/PLANO.md` §6.
- **Corregido:** el menú se redibuja al girar o cambiar el tamaño de la pantalla. El abono se llama igual en la tienda, la mochila, el suelo y los diálogos (antes, «fertilizante» en unos sitios). Al empezar los capítulos 5 y 7, la partida se guardaba antes de poner el plazo nuevo: si cerrabas sin dormir, al volver debías 0 € y podías saltarte 12.000 o 15.000 €; ahora el plazo va antes y una partida guardada así lo recupera al cargar. Al saldar la deuda sale el rótulo «CAPÍTULO 8 · Tu imperio», y el objetivo de cada capítulo espera a que acabe su rótulo en vez de taparlo. Las cifras de 4 cifras llevan punto de miles, como las demás (3.000 €, no 3000 €).
- **Partidas viejas:** una partida de la 1.9 carga igual (mismas plazas, plantas y macetas; extras a 0). La deuda pasa a la escala nueva del capítulo en que estás (los intereses ya cobrados se pierden) y el plazo abierto vuelve a contar desde que cargas, con sus 7 o 10 días; una partida acabada empieza el imperio desde cero.
- **Tests:** `npm test` 52/52 (de 50): semillas regulares y feminizadas al cosechar; una partida de la 1.9 con un plazo abierto y una guardada sin plazo; el plazo de los capítulos 5 y 7 ya está en lo guardado; armario 80, extras y carpa 120; Iñaki al por mayor; el imperio a 25.000 €; fenotipos (200.000 plantas por tipo: la frecuencia de estrellas cuadra con la de la ficha y va de la línea estable a la F2); esquejes (el clon guarda el fenotipo y su cosecha va al lote ★; sin plantar se seca); cifras reales (CFL ≈ 0,3 g/W, LED 720 W ≈ 1–1,35 g/W y 45 € de luz, tope de la maceta). `npm run test:arte` 24/24, con la vista B y su distancia segura (las 5 carpas con cada foco y maceta) y la vista C (las 5 carpas con sodio y la de 60 con el CFL y la híbrida en sus 5 fases).

## 1.9.0 · 6 de octubre de 2026

- **Nuevo: las genéticas de Strainmon.** La Genoteca pasa de 23 a 41 variedades con la información de `../src/species.js`, todas con nombre real y su historia (se lee en la Genoteca y en el banco).
  - 12 landraces: Michoacán, Punto Rojo, Thai, Luang Prabang, Chitral Kush, Nepalese, Congolese, Lamb's Bread, Kif, Beldia, Oaxaca y Panama Red.
  - 6 híbridos clásicos que salen de cruzarlas: Haze (Punto Rojo × Thai o Michoacán × Thai), Northern Lights (Afghani × Thai), Afghan Kush (Afghani × Hindu Kush), Shiva Skunk (Northern Lights × Skunk #1), Silver Haze (Haze × Northern Lights) y Super Silver Haze (Silver Haze × Skunk #1). 20 recetas en total.
  - Fuera las dos reliquias inventadas de Strainmon y las variedades con nombre de persona.
- **Nuevo: estabilizar.** Lo que sale de un cruce nuevo es una F1: sus cosechas dan gramos desiguales (×0,8–1,1; el THC no cambia, para no poner en riesgo la Copa). En la mesa de genética, «estabilizar» cruza la variedad consigo misma: gasta 2 semillas y guarda 1 de la generación siguiente, así que entre generación y generación hay que cultivarla. En la F4 la línea queda fija; también se puede estabilizar sin tener semillas de otra variedad. La Genoteca dice en qué generación va cada una.
- **Nuevo: banco de semillas.** Desde el capítulo 2, el ordenador de la tía vende sobres de 3 semillas de landraces (35–90 €; 5 en el capítulo 2, 10 en el 3 y las 12 en el 4) que llegan al día siguiente.
- **Corregido:** en los menús a toda altura, una descripción de 4 líneas tapaba la lista; ahora se ven las filas que caben.
- **Banco:** si pides dos veces la misma variedad llegan 6 semillas en un solo aviso, y cada landrace nueva sale en la Genoteca con su aviso.
- **Partidas viejas:** una partida de la 1.8 carga igual; las variedades que ya tenías cuentan como estables.
- **Tests:**
  - `npm test` 42/42: estabilizar Critical Mass (F1 → F2 → F3 → estable), el banco (Punto Rojo y Thai, llegan al día siguiente) y el cruce Punto Rojo × Thai → Haze con cosechas desiguales.
  - `npm run test:arte` 22/22: plantas de la vista para las 41 variedades.
- **Docs:** `docs/GENETICA.md` con la historia de cada variedad y la regla de estabilizar; `docs/GDD.md` al día.

## 1.8.0 · 6 de octubre de 2026

- **Cambiado: una sola escala (opción A de `docs/PLANO.md`).**
  - El piso pasa a 12 × 8 casillas a 1 casilla = 1 m (72 m²; antes 20 × 12, 240 m²). Dormitorio a la izquierda, escritorio y mesa de genética al fondo, carpas al fondo a la derecha y la salida en (5,7).
  - Las carpas son muebles sólidos: el armario 60 y la carpa 100 ocupan 1 casilla, la carpa 150 ocupa 2 (sprites nuevos `carpa-<t>-mapa`, a ×1 de su tamaño real).
  - Fuera la bandeja de cultivo, las mesitas y las plazas como casillas del mapa.
- **Nuevo: vista de carpa.** Con A delante de una carpa se abre de frente, a 64 px por metro, sobre el fondo de un cuarto de cultivo.
  - La cruceta elige la plaza (las filas de atrás, al tresbolillo) o el foco; A riega, abona, cosecha o cambia maceta y foco como antes; B sale. El tiempo no corre mientras miras.
  - Ficha a la izquierda con la variedad, la fase, el agua, la salud y la plaga; con el foco, su potencia y la luz que gasta al día.
  - Luz de cada foco sobre las plantas, plantas recortadas al interior de la carpa y la luz que se escapa bajo la puerta en el piso.
- **Nuevo: plantas por variedad.** Las plantas de la vista son el arte de cepas del repositorio (`../assets/plants`, 18 cepas × 5 fases) sin su tiesto y a escala: cada variedad con la cepa más parecida en porte y color de cogollo (los híbridos propios, por hash). Secas, amarillean; muertas, se quedan pardas.
- **Arte:** 4 generaciones de PixelLab (carpas del piso, carpas de la vista, macetas y el cuarto), frente a las 120–180 previstas. Retirados los sprites de carpas, mesa, macetas y plantas de la 1.6–1.7.
- **Partidas viejas:** una partida de la 1.7 carga con sus carpas y sus plantas intactas; si el jugador estaba fuera del piso nuevo, aparece en una casilla libre.
- **Plano** (`docs/PLANO.md`, `npm run plano`) rehecho: decisión A aplicada, carpas a ×1,0 en el piso y la vista medida a 64 px/m (carpas, macetas y focos ×0,76–×1,09; plantas ×0,85–×2,3, estilizadas).
- **Tests:**
  - `npm test` 39/39: paso nuevo de la vista de carpa (A abre, ▶ plaza 2, A riega, B sale).
  - `npm run test:arte` 22/22: carpas como muebles en el piso de 12 × 8, plantas de la vista (23 variedades × 5 fases, seca y muerta sin verdes) y la vista con el arte del atlas.
- **Capturas:** nueva `03b-vista-carpa.png`.

## 1.7.0 · 6 de octubre de 2026

- **Nuevo: plano del juego** (`npm run plano`, `docs/PLANO.md`).
  - Cada mapa sale entero con rejilla, coordenadas y rótulos de edificios, puertas, salidas, NPC, objetos, carpas y plazas (`docs/plano/*.png`).
  - Una hoja de escala pone todos los sprites junto al jugador y los mide contra su tamaño real (`docs/plano/escala.png`, `medidas.json`).
  - Conclusión: con 1 casilla = 1 m, personajes y muebles cuadran (×0,8–×1,3), la zona de cultivo va a ×2,5–×5 y el exterior a ×0,25–×0,5.
  - El documento propone tres maneras de dejar una sola escala (A: vista de carpa a escala de detalle; B: interiores a ×2; C: ajuste dentro del estilo actual), con su coste en PixelLab, **para decidir**.
- **Cambiado: pantalla completa, solo en horizontal.**
  - Fuera el chasis de la consola: la pantalla ocupa el móvil entero, con un reborde fino.
  - Los mandos flotan encima, fijos: cruceta abajo a la izquierda, A/B abajo a la derecha, SONIDO y START arriba a la derecha.
  - El ancho del juego se adapta al móvil (de 240 a 400 px, siempre 160 de alto y píxeles cuadrados): en un móvil de 844 × 390 se ven 358 px de mundo.
  - Diálogos y menús van en un escenario de 240 centrado que encoge lo justo para caber entre la cruceta y A/B (letra de 13 px como mínimo) y empieza debajo de SONIDO/START. Con un menú a toda altura abierto, el HUD se aparta.
  - Título y combate siguen compuestos a 240 y su fondo se alarga a los lados. En el combate, sin repetir trozos de las tarimas.
  - En vertical sale «Gira el móvil».
  - Al primer toque se pide pantalla completa y se bloquea el giro. El APK va en `sensorLandscape`.
- **Cambiado: variedades con nombres reales y guion serio.**
  - Las 23 variedades son reales, con su linaje: Skunk #1, Lemon Haze, OG Kush, Blueberry, Mango y Purple Afghani en la tienda; Afghani, Hindu Kush, Acapulco Gold y Malawi Gold como landraces; y cruces como Lemon Skunk, Critical Mass, Blue Dream, Super Lemon Haze, Amnesia Haze y Fire OG, hasta la legendaria Ghost Train Haze (29 %).
  - Cogollos en tonos verdes realistas.
  - Los híbridos propios se nombran con las variedades de los padres (Skunk #1 × Hindu Kush → «Skunk Kush»).
  - Todo el guion, reescrito en serio:
    - intro de Kiko sin presentador;
    - carta de Maite con la deuda;
    - uso medicinal de Txaro durante la quimio;
    - Copa de la asociación cannábica con análisis de laboratorio;
    - Darko, Molina y Baltasar sin chistes;
    - ladrones sin apodos (encapuchado, atracador, carterista…);
    - combate sin coletillas («Fallas.», «¿Qué haces?», «Consigues…»).
  - Subtítulo: «genética de barrio».
- **Cambiado: fuente más legible.** Atkinson Hyperlegible (400 y 700) en diálogos, menús y HUD; Press Start 2P solo en rótulos. Sale Pixelify Sans.
- **Cambiado: bandeja de cultivo.** Las «mesitas» de madera por plaza (otra escala y otra calidad que la carpa) se cambian por una bandeja continua por carpa: cubeta de plástico sobre bastidor metálico con desagüe, con la paleta de la carpa.
- **Tests:**
  - `npm test` 38/38, con los nombres nuevos.
  - `npm run test:arte` 22/22: pantalla completa en 7 tamaños horizontales (pantalla ≥ 90 % del móvil, píxeles cuadrados, mandos dentro y sin tapar diálogos ni menús en ningún tamaño) y «Gira el móvil» en 2 verticales; bandeja continua.
- **Capturas** de 720 × 480 (×3 exacto) y la del móvil en horizontal (844 × 390).

## 1.6.1 · 6 de octubre de 2026

- **Corregido: el marco en el móvil.** La pantalla del juego quedaba pequeña y los mandos se comían el resto; en horizontal la pantalla se quedaba en 90 × 60 px. Ahora la consola es la app entera, sin scroll, y `ajustarPantalla()` reparte el hueco real (`visualViewport`, con barras del sistema y muescas) con límites fijos para cada parte:
  - **vertical:** pantalla arriba a todo el ancho (332 × 221 en un móvil de 360 × 740; antes 288 × 192) y cruceta, A/B, SONIDO y START debajo, con al menos un tercio del alto para ellos;
  - **horizontal:** cruceta | pantalla a toda la altura | A/B (449 × 299 en 740 × 360; antes 90 × 60), con SONIDO y START debajo de cada lado;
  - los mandos se escalan con el hueco (cruceta de 96 a 210 px) y la pantalla se ajusta a un múltiplo entero de 240 píxeles físicos cuando está a menos de un 8 % (píxeles nítidos).
- **Quitado:** la línea de ayuda del teclado bajo la consola (es una app de móvil; el teclado sigue funcionando en el PC). Sin zoom con dos dedos ni doble toque.
- **Corregido: sprites antiguos.** En la intro, Kiko salía con el muñeco procedural ampliado; ahora es el de PixelLab (×2, con su animación). Los menús usan por fin los iconos y los cogollos que ya estaban en el atlas: mochila, tienda, cultivo, combate, venta y Genoteca (el cogollo de cada variedad con su forma y su color).
- **Corregido (herramientas):** `npm run capturas` podía quedarse colgado tras el combate (el cambio de capítulo encolado acababa con `lock` en −1).
- **Tests:** `npm run test:arte` 22/22 (intro y menús con el arte del atlas; marco en 7 tamaños, vertical y horizontal).

## 1.6.0 · 6 de octubre de 2026

- **Nuevo: carpas de cultivo de verdad en el piso.** El armario de la tía (60×60, 2 plantas) es el de serie; en el growshop se compra una **carpa de 100×100** (450 €, capítulo 2, 4 plantas) y después se cambia por una **de 150×100** (900 €, capítulo 4, 6 plantas: se quedan plantas, foco y macetas). El piso pasa a 20 × 12 casillas, con las dos carpas al fondo.
  - **Desde fuera** la carpa está cerrada: techo con la salida del extractor, frente negro con puerta de cremallera y rejilla. Si hay plantas vivas, se escapa una línea de luz bajo la puerta.
  - **Al entrar** (por la puerta) desaparecen el techo y las paredes de delante y de la derecha: se ven la pared del fondo y la izquierda, de mylar, el suelo, **una mesa por plaza con su maceta encima** y los **focos colgando, medio transparentes**, con su cono de luz detrás de las plantas.
- **Nuevo: macetas de 4 tipos** (plástico 7 L de serie; tela 11 L, plástico 18 L y tela 25 L en la tienda). La de tela airea las raíces: más cosecha y menos plagas, pero bebe más; la grande da más y crece algo más lenta. Se cambian en una plaza vacía; la vieja va a la mochila. Cada carpa admite una maceta máxima (11 L en el armario).
- **Nuevo: 7 focos** (CFL 125 W de serie; sodio 250/400/600 W y LED 200/480/720 W). Cada uno cubre 2, 4 o 6 plantas: un foco pequeño en una carpa grande no llega a todas y rinden menos. El sodio es barato pero calienta y seca las macetas; el LED cuesta más, rinde más, sube más el THC y casi no seca. Cada carpa aguanta unos vatios como mucho. Al comprarlos, Kiko pregunta si los cuelga ya; también se cambian desde la pared de la carpa.
- **Nuevo: factura de la luz.** Cada día, 0,02 € por vatio de cada carpa con alguna planta viva.
- **Cambiado:** fuera «Maceta extra» y «Lámpara LED». Las partidas guardadas se convierten solas: con macetas extra tienes la carpa de 100, la LED pasa a un LED en cada carpa y las plantas siguen donde estaban. Lo de serie da exactamente el cultivo de antes.
- **Menús:** PLANTAS enseña cada carpa con su foco, su factura y sus plazas con la maceta; la mochila enseña las macetas y los focos de repuesto; consejos nuevos de Kiko.
- **Arte (F8):** carpa por dentro y cerrada con `create_image_pixflux` img2img sobre su huella procedural (una generación de cada vista para la de 150; la de 100 y la de 60 se recortan de ella), macetas con `create_1_direction_object` usando la maceta de tela recortada a 16 px como estilo, focos y mesa en otros dos lotes. El motor quita la maceta de tela de cada fotograma de la planta y pinta la nueva debajo. Atlas: 1099 fotogramas. La carpa de la 1.5 queda en `descartadas`.
- **Tests:** `npm test` 38/38 (carpa, focos, macetas y factura) y `npm run test:arte` 20/20 (carpas, focos, macetas y mesa del atlas).
- **Coste:** 64 generaciones (4 pixflux y 3 lotes; uno descartado porque las macetas salían demasiado grandes).

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

## Notas del código por versión (fase 8)

Los comentarios del código que empezaban por su versión («# 1.51: …») la pierden aquí; esta es la lista, por versión, con el archivo y lo que comentan.

### 1.57.2
- `escena_viaje.gd` · `HUERTO`: (lo pidió el usuario: «que se vea alguna planta en vegetativo, alguna floración, dependiendo del punto del año… cómo sería el
- `mundo.gd` · `montar_taller`: (lo pidió el usuario): el taller por zonas, con CAL; montar_locales lo vuelve a poner cada vez que rehace el local
- `mundo.gd`: (lo pidió el usuario: «está muy vacío… el atrezo deja que desear o por lo menos cómo está usado»): el taller, cada cosa en
- `mundo.gd` · `TALLER_SUELO`: el suelo del taller por zonas (x0, y0, x1, y1, casilla): el hormigón de los puestos (con manchas de aceite por hash_t), la

### 1.57.1
- `calle.gd` · `gx`: (lo pidió el usuario: «las extracciones se deberían de poder fumar también con tabaco, sin tabaco no, porque sería con la
- `escena_viaje.gd` · `CALLE_FIL`: (lo pidió el usuario: «que aparezcan en la pantalla de carga los sprites reales de césped, árboles, setos, también molaría que

### 1.57
- `escena_viaje.gd` · `CARGA`: (lo pidió el usuario: «estos recursos se podrían usar antes de la pantalla de inicio, como de carga del juego, en una carretera
- `juego.gd` · `carga_t0`: (lo pidió el usuario: «estos recursos se podrían usar antes de la pantalla de inicio, como de carga del juego, en una carretera
- `mundo.gd` · `DEMO_CAL`: (lo pidió el usuario: «luego aparece la pantalla de inicio START con más atrezo»): en el título, con CAL, el protagonista y el
- `pinta.gd` · `arriba`: (lo pidió el usuario: «los tubos no llegan a las carpas, falta 1 o 2 píxeles»): la boca, en la primera fila opaca del
- `pinta.gd` · `_tubo_codos`: (lo pidió el usuario: «en las curvas o giros del tubo no se deben cortar»): de la carpa (xa, hasta ya) al techo (yc), por el
- `ui.gd` · `DPI_PRUEBA`: para las pruebas de los mandos por móvil (tests/mandos_geo.gd): los ppp y la zona segura de un móvil de verdad
- `ui.gd`: (lo pidió el usuario: «que sean lo mejor para jugar con el móvil en horizontal, estudiando en qué zonas caen los dedos»): los
- `ui.gd` · `CRUZ_HISTERESIS`: al deslizar de una flecha a la de al lado, la nueva tiene que ganar por CRUZ_HISTERESIS (unos 11° pasada la diagonal):
- `ui.gd` · `vibra`: un toque corto del vibrador al apretar un mando (OPCIONES → VIBRACIÓN), en el móvil

### 1.56
- `granja.gd` · `VIAJE_V`: el viaje, de perfil, como pantalla de carga (escena_viaje.gd): el autobús o tu vehículo por la carretera; A o B lo pasan

### 1.55.3
- `mundo.gd` · `SENT_GEO`: (lo pidió el usuario: «la altura correcta en todos los muebles donde se puede sentar»): por asiento, [dx, cadera]: dx,
- `pinta.gd` · `f`: (lo pidió el usuario): sube de la boca del techo de la carpa al techo de la habitación, corre pegado al techo (por
- `pinta.gd` · `cs`: a cada carpa con extractor, su ventana (que no quede detrás de ella), con los tramos de techo sin pisarse y lo más

### 1.55
- `mundo.gd` · `sitio`: (lo pidió el usuario: «la puerta del sótano está inaccesible porque hay una carpa delante» y «poder ordenar las carpas al
- `pinta.gd` · `_tubos_casa`: (lo pidió el usuario: «debería salir un tubo de extracción de cada carpa hacia una de las ventanas»): con el extractor puesto,

### 1.54.1
- `trama.gd` · `GS_W`: (lo pidió el usuario: «eso no son sprites en condiciones en el mismo estilo que los muebles del juego»): el plano de

### 1.52
- `calle.gd` · `calle_tiempo`: con lluvia, tormenta o nieve hay menos gente en la calle: el calor de cada venta, por esto
- `datos.gd` · `_cal_d`: las autoflorecientes (AUTO) entran en la Genoteca, las recetas y el banco solo con CAL (las pruebas contra el HTML, sin ellas)
- `datos.gd` · `K`: el club KAIA del muelle, el tuyo (solo con CAL: las pruebas contra el HTML recorren D.CLUBS)
- `eventos.gd`: las obras del muelle, el club KAIA y la ley
- `mundo.gd`: (lo pidió el usuario: «comenzar destartalado… ir reformándolo poco a poco, edificio por edificio»): cada casa, en ruina hasta
- `mundo.gd` · `obra_ya`: una obra del muelle, terminada (S.mar.ob: el día en que se acaba cada una)
- `trama.gd` · `ICONO_TIEMPO`: el dibujo del tiempo, 13 × 9 (. vacío, s sol, n nube, m sombra de la nube, g gota, r rayo, b nieve, f niebla)

### 1.51
- `eventos.gd`: el muelle de Puerto Viejo, los envíos por mar y el piso franco
- `mundo.gd` · `puertas_int`: (lo pidió el usuario: «una puerta en la casa, luego un mapa pequeño como un mini pasillito»; y en el taller y en la nave): las
- `mundo.gd` · `_muelle0`: (lo pidió el usuario: «un mapa lateral en Puerto Viejo, un mini puerto para los envíos»): desde el capítulo de MAR.ch, el paso
- `mundo.gd` · `ATREZO`: (lo pidió el usuario: «la casa de Txaro es la casa con menos atrezo que hay en el mundo… que en casi todos los lugares donde
- `setas.gd` · `ayudante_setas`: (lo pidió el usuario: «que se cultive como la nave»): Ekaitz, el ayudante del bajo grande, cada mañana: todo húmedo y lo listo, a secar
- `trama.gd` · `_SOT`: (lo pidió el usuario: «antes de… alquilar el bajo… habilitar el sótano de la casa»): las setas, en el bajo de Txomin

### 1.50
- `nave.gd` · `i`: a lo ancho, con el nombre entero (en la columna de la derecha se cortaba: «Beldi», «Zam»…)
- `pinta.gd` · `SENT_PIERNAS`: de frente, sentado: los muslos encima del asiento (vistos desde arriba), las rodillas, las espinillas colgando
- `pinta.gd` · `SENT_TABURETE`: de espaldas en el taburete de la barra (asiento a 72 cm, 11 px): el culo encima del asiento y, a los lados del pie,
- `policia.gd` · `g_lote`: un lote de menos de 10 g, con su décima (0,4 g no es «0 g»); sin CAL, como g_txt
- `ui.gd` · `HUD_TAB_SEP`: el recuadro, etiqueta a la izquierda y cifra a la derecha, con una raya arriba y abajo

### 1.49
- `calle.gd` · `levantarte`: (lo pidió el usuario: «que te puedas sentar de verdad»): sentado es un estado, no un menú; el mundo sigue (la gente

### 1.48
- `pinta.gd` · `MOSAICO_TILE`: los firmes en mosaico (exterior-mosaico) y el canto de la hierba donde toca acera, calzada u hormigón: dos píxeles más oscuros,
- `pinta.gd` · `_det_c`: (lo pidió el usuario: «que se note que es el sprite y lo que trae»): d-<objeto>-<mapa>-<tramo>, d-<objeto>-<mapa>,

### 1.47
- `mundo.gd` · `_disco_cal`: (lo pidió el usuario: «la discoteca tiene que ser más grande, el piso de arriba reservado»), solo con Datos.CAL: GAUA, la planta
- `mundo.gd` · `montar_estancos`: (lo pidió el usuario: «un estanco en cada pueblo»), solo con Datos.CAL: la puerta en una casa libre de cada pueblo (en el barrio
- `mundo.gd` · `FUMAR`: (lo pidió el usuario): con qué se fuma. El papel, el tabaco, las boquillas y el mechero, del estanco (ESTANCO); la pipa,
- `nave.gd` · `subir_vip`: (lo pidió el usuario): el reservado, arriba; desde la cristalera del suelo se ve la pista de abajo
- `pinta.gd` · `_bailan`: (lo pidió el usuario: «desde el que se ve el piso de abajo, en la cristalera del suelo, transparente»): en el reservado, la gente
- `pinta.gd` · `g0`: (lo pidió el usuario: «que se vea algo más que la pista»): por el cristal, lo de abajo entero en su sitio, recortado al
- `pinta.gd` · `_rotulo_x`: el rótulo del estanco, centrado encima de su puerta
- `trama.gd` · `talk_estanco`: (lo pidió el usuario): el estanco de cada pueblo, papel, filtros, tabaco y mecheros (D.ESTANCO)
- `trama.gd` · `CATA_MAX`: (lo pidió el usuario: «que se pueda probar todo tipo de cogollos y extracción… hasta un límite lógico claro»): catar cualquier

### 1.46
- `mundo.gd` · `NEG_LARGO`: el elevador y el foso, a escala con los coches del concesionario (5 casillas, como la exposición); 1.47, el box de lavado
- `setas.gd` · `cp`: cada cepa con su forma y sus colores (CEPAS.v): cúpula (la de siempre), campana, plato o racimo

### 1.45
- `mundo.gd`: (lo pidió el usuario: «en la nave en la que cultivas, lo mismo»): el camastro del rincón, para dormir allí

### 1.43.8
- `trama.gd`: (lo pidió el usuario: «no existe mapa y sitio del bajo de las setas»; con Datos.CAL): nada te decía dónde estaba. Con

### 1.43.7
- `mundo.gd` · `lotes_venta`: (lo pidió el usuario: «las extracciones se deberían poder vender al por mayor, en clubs y donde se pueda vender cogollos»;

### 1.43.6
- `mundo.gd` · `CM`: la escalera escamoteable del camarote, entre las carpas A y B, bajo la ventana; se sube desde la casilla de delante

### 1.43.4
- `juego.gd` · `copia_seguridad`: (lo pidió el usuario: exportar e importar, más escondidos): al final de OPCIONES, en su submenú y con su aviso

### 1.43.3
- `movil.gd` · `look_rival`: el muñeco del rival, del sexo de su nombre (GENERO.rival)
- `mundo.gd` · `sprite_look`: (GENERO): el muñeco de un look (como Atlas.grupo_look: los de la calle, por su hash) y si es de chica
- `venta.gd` · `con_encargada`: donde lleva el club una mujer (GENERO.enc), «la encargada»

### 1.43.2
- `eventos.gd` · `kilometros`: los km de cada vehículo; al pasar cada CONCE.v[k].revKm, la revisión (aceite y filtros), y cada neuKm, los neumáticos

### 1.43
- `calle.gd` · `coche_ya`: un vehículo del concesionario (S.coches: {k: {dia: cuándo llega, p: lo pagado, r: el próximo recibo del seguro o null}}), ya entregado
- `croquis.gd` · `LIBRE`: (lo pidió el usuario): centrados como la nevera y la caja fuerte, a lo ancho y en el alto que deja libre el cuadro del texto
- `mundo.gd`: el carro de las bandejas de clones (S.nave.bc), contra la pared, entre el secadero y el escritorio
- `ui.gd` · `alto_libre`: lo que queda libre del lienzo (en píxeles del juego) por encima del cuadro del texto, para centrar ahí el calendario y el mapa
- `ui.gd`: la primera vez, el texto aún no sabe su ancho y el cuadro sale de toda la pantalla; se recoloca al fotograma siguiente

### 1.41
- `setas.gd` · `tg`: (lo pidió el usuario: realista): cada lote, en los tarros de ALM.tarro g que llenaría de verdad (de 4 L, sin aplastar)

### 1.40
- `granja.gd` · `cap`: (lo pidió el usuario): el carro se ve tal cual, dos bandejas de tacos (arriba y abajo) en vez de un menú; A en un taco
- `ui.gd` · `g`: (lo pidió el usuario: «más ergonómicos, más espaciadas las flechas del cuadrado del medio»): cada flecha, una tecla suelta

### 1.37
- `calle.gd` · `j`: (lo pidió el usuario): con la carta leída, la mesa redonda ordena la casa (12d-orden)

### 1.36
- `policia.gd` · `caja_action`: (lo pidió el usuario): al abrirla, la caja por dentro (rects_almacen): los billetes abren el menú de siempre y un tarro, sacarlo

### 1.35
- `juego.gd` · `_titulo_entra`: el aviso de edad (la primera vez) y, sin PULSA START, los botones del título; con B se cierran y A o START los abren
- `ui.gd` · `LEMA`: (lo pidió el usuario): el rótulo, el lema y, debajo, los botones (el menú «titulo»); detrás, la partida de fondo (pinta.gd)
- `venta.gd` · `nave_alquiler`: cada RECIBO.dias, en efectivo, con su aviso (cobra, granja.gd)

### 1.34
- `movil.gd` · `club_te_compra`: (PRESI): fuera del barrio, un club solo te compra (lotes y encargos) si se fían de ti el encargado y su presidente
- `venta.gd` · `de_la_nave`: con el de las madres (cuida_madres)
- `venta.gd` · `talk_gente_club`: los demás socios de cada club (GENTE_CLUB)

### 1.30
- `sonido.gd`: la música grabada (tools/musica.js → musica/<clave>.ogg, con indice.json: dónde empieza el bucle) va antes que el

### 1.27
- `mundo.gd` · `vs`: el suelo y las paredes de la reforma (REFORMA) y la alfombra (suelo: 1, sus 4 trozos sobre el suelo que haya)

### 1.25
- `menus.gd` · `tipo_diario`: todas las de la Genoteca, en su orden; las de receta abren lo que entra; las demás dicen dónde están sus semillas
- `trama.gd` · `lao_miren`: y MIREN.n2 de la de Laos (MIREN.s2, que no está en el banco; S.flags.lao: las partidas de antes, al volver a hablarle)

### 1.23
- `granja.gd` · `ph_item`: por marca (D.PRODUCTOS): el pH− que se gasta es el de su marca y, si no hay, el otro
- `granja.gd` · `abonar`: (09-cultivo: abonar): el de crecimiento (veg_k: los que hay, en vegetativo y sin él) o el de floración; con dos marcas, eliges

### 1.13
- `juego.gd`: lo que se quedó en la cola al guardar (la cama guarda antes de que salgan los avisos de la noche)

### 1.11
- `calle.gd` · `heat_warn`: un aviso antes, con 50 (con 60 investigan), que dice por dónde se vende sin tanto calor
- `trama.gd` · `llevas`: en los plazos, lo que llevas entre el bolsillo y la caja

### 1.10
- `juego.gd`: el plazo del capítulo 3 corre desde Toño (las partidas sin él, desde hoy) y la protección de Molina dura 10 días desde hoy
