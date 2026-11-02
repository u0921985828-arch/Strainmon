# Landrace Hunters · Declaración de originalidad y procedencia

Documento de respaldo para registrar la obra y acreditar su autoría. Hecho el 2 de noviembre de 2026
sobre la versión de Godot del juego (`ribera-verde/godot/`).

> **Aviso previo, en una línea:** un videojuego **no se patenta**, se **registra como obra** (propiedad
> intelectual / derechos de autor) y, aparte, su **nombre y su logo se registran como marca**. Las
> patentes protegen invenciones técnicas, y las reglas o mecánicas de un juego no son patentables como
> tales. Lo que este documento acredita es lo que de verdad protege a la obra: que **todo lo que se
> publica es original o está licenciado**, y que hay **rastro fechado** de cómo se hizo.

---

## 1. Titular y obra

| Campo | Dato |
| --- | --- |
| Título | **Landrace Hunters · genética de barrio** |
| Tipo | Videojuego (programa de ordenador + obra audiovisual: arte, música y texto) |
| Autor y titular | **WolfCade** (Eddie) |
| Motor | Godot Engine 4.7 (MIT) |
| Plataformas | Android (Google Play y APK) y web (plugin de WordPress) |
| Paquete | `com.landracehunters.game` |
| Idiomas | castellano e inglés |
| Primer commit | 12 de julio de 2026 |
| Último commit de esta declaración | 2 de noviembre de 2026 |
| Commits en el repositorio | 567 |

---

## 2. Qué es original (100 % de la casa)

Todo lo de esta lista está **creado desde cero para este juego**; no procede de ninguna obra ajena y no
es derivado de material con copyright de terceros.

| Parte | Dónde está | Cómo se hizo |
| --- | --- | --- |
| **Código del juego** | `godot/src/*.gd` (GDScript) | Escrito para este proyecto. Sin librerías de terceros dentro del juego: el único `addons/` es `landrace_play`, un plugin de exportación propio. |
| **Herramientas de producción** | `tools/*.js`, `tools/*.py` | Scripts propios (arte, mapas, economía, documentación, empaquetado). |
| **Datos del mundo** | `godot/datos/datos.json`, generado por `tools/*.py` | Mapas, economía, genética, misiones, diálogos: todo inventado. |
| **Arte a mano** | `tools/sprites/a-mano/*.py` | Pixel art dibujado píxel a píxel por código propio: carpas por dentro, plantas, equipo de cultivo, extracciones, planos de cerca de cada acción, calle y firmes, pueblos, zonas de ciudad, interiores, vehículos, iconos, interfaz e icono de la app. El código fuente del dibujo queda en el repositorio: es la prueba de autoría más fuerte que hay. |
| **Tipografía** | `godot/fuentes/RiberaPixel.ttf` y `-Bold.ttf`, de `tools/fuente/` | 138 glifos dibujados píxel a píxel (`glifos_may.py`, `glifos_min.py`, `glifos_sig.py`) y compilados a TTF con FontTools. **Ninguna fuente ajena se ha modificado ni calcado.** Ver §4. |
| **Música y sonido** | `tools/musica/temas.js` → `godot/musica/*.ogg`; chiptune en `godot/src/sonido.gd` | Partituras propias, sintetizadas y grabadas para el juego. Todos los efectos, generados por código propio. |
| **Textos y guion** | `godot/i18n/strings.csv`, `docs/GUION.md` | Historia, diálogos, personajes y nombres de lugares, inventados. |
| **Nombre y marca** | **LANDRACE HUNTERS**, **WOLFCADE**, **STRAINBOY** | Identidad propia. |

---

## 3. Arte generado con PixelLab

Parte de los personajes, los muebles de los locales y algunos escenarios se generaron con **PixelLab**
(`pixellab.ai`) desde este proyecto y después se revisaron y retocaron a mano.

- El uso está sujeto a los términos de servicio de PixelLab (`https://pixellab.ai/termsofservice`), que
  son los que rigen la titularidad de lo generado con una cuenta de pago.
- **Antes de registrar la obra conviene imprimir o guardar en PDF la versión vigente de esos términos**,
  junto con el recibo de la suscripción, como prueba de que el arte se generó con licencia.
- Las especificaciones y los procesados de cada lote están en `tools/sprites/` y `tools/sprites/director/`,
  con sus `spec.yaml`: queda el rastro de qué se pidió y cómo se retocó.
- La parte dibujada a mano (la mayoría del juego) no depende de esto en absoluto.

---

## 4. Terceros: qué se usa, con qué licencia y qué obliga

| Componente | Autor | Licencia | Obligación cumplida |
| --- | --- | --- | --- |
| **Godot Engine 4.7** | Juan Linietsky, Ariel Manzur y colaboradores | MIT | Aviso de copyright en CRÉDITOS → LICENCIAS, dentro del juego. |
| **Press Start 2P** | The Press Start 2P Project Authors, 2012 | SIL OFL 1.1 | Licencia entera en `godot/fuentes/OFL-PressStart2P.txt` y en LICENCIAS. Uso sin modificar. |
| **Atkinson Hyperlegible** | Braille Institute of America, 2020 | SIL OFL 1.1 | Licencia entera en `godot/fuentes/OFL-AtkinsonHyperlegible.txt` y en LICENCIAS. Uso sin modificar. |
| **DejaVu Sans** | Bitstream Vera Fonts © 2003 Bitstream, Inc. | Licencia Bitstream Vera / DejaVu | Licencia entera en `godot/fuentes/LICENCIA-DejaVu.txt` y en LICENCIAS. Uso sin modificar. |
| **Playwright, pngjs** | sus autores | Apache 2.0 / MIT | Solo herramientas de desarrollo (`devDependencies`): **no viajan en el juego publicado**. |
| **Bibliotecas de Android del AAB** | Google (Play Billing, Play Games v2, AndroidX) y Sentry | Apache 2.0 (Sentry: MIT) | Se enlazan en la compilación de Android (`godot/addons/landrace_play`). **Sus avisos todavía no salen en la pantalla de LICENCIAS** (ahora lista Godot y las tres fuentes): ver §8. |

Las tres fuentes de terceros se incluyen **sin modificar** y con su licencia completa, que es justo lo
que esas licencias exigen. El texto de la interfaz va con la fuente propia.

### Las siete fuentes que se descartaron

`tools/fuente/LICENCIAS-ORIGEN.md` deja por escrito el análisis de las siete tipografías que se
barajaron como referencia: seis prohíben el uso comercial, las obras derivadas o no traen licencia
comprobable, así que **ninguna se usó ni se derivó**; se dibujó Ribera Pixel desde cero. Ese documento
es, por sí solo, una prueba de diligencia.

---

## 5. Lo que se ha evitado a propósito

Regla permanente del proyecto (`CLAUDE.md`), aplicada desde el primer día:

- **Nada de assets ni código de terceros con copyright**: ni sprites de Pokémon, ni código de
  Habbo/Sulake, ni descompilaciones (por ejemplo `pret/pokefirered`), ni el wordmark «Nintendo/GAME BOY»,
  ni su lema comercial. **Modificar material con copyright crea una obra derivada, que sigue
  infringiendo**: por eso no se hizo en ningún caso.
- Lo que sí hay es un **homenaje de forma**: el formato de consola portátil y el aire del pixel art de
  los 16 bits, con arte y código 100 % propios e identidad propia (**STRAINBOY**, verde, textos propios).
  La estética de una época no es de nadie; lo que está protegido son los dibujos, el código y las marcas
  concretas, y de eso no se ha tocado nada.
- **Las zonas de ciudad** (Bilbao y su comarca) son un homenaje de trazado, **sin rótulos, escudos ni
  marcas**. Los edificios se dibujaron a mano. Los nombres de barrio son topónimos reales de uso común,
  que no son propiedad de nadie; los negocios y personajes son inventados.
- **Los nombres de variedades** (Haze, Northern Lights…) se usan como información botánica y cultural.
  No son marcas de este juego ni se presentan como productos de nadie.
- **Las marcas de abono** del juego (MEATZA, ORTUA BIO) son **inventadas**, precisamente para no usar
  marcas reales.
- El aviso de ficción y el de legalidad van dentro del juego, en CRÉDITOS.

---

## 6. Rastro de autoría (lo que vale como prueba)

1. **Repositorio git** con 567 commits fechados y firmados por cuenta desde el 12 de julio de 2026:
   muestra la obra creciendo paso a paso, que es lo contrario de una copia.
2. **El arte está en forma de código fuente** (`tools/sprites/a-mano/*.py`): cualquiera puede volver a
   generar cada sprite desde el script. Un copista no tiene eso.
3. **Las pruebas automáticas** (`tools/tests.sh`, 60 y pico suites) documentan el comportamiento del
   juego versión a versión.
4. **La documentación de diseño** (`docs/GDD.md`, `GUION.md`, `ECONOMIA.md`, `GENETICA.md`, `MAESTRO.md`,
   `ANALISIS.md`) recoge las decisiones antes de implementarlas.
5. **Los créditos y las licencias dentro del juego** acreditan lo ajeno y lo propio ante el usuario final.

---

## 7. Qué hacer para proteger la obra (pasos reales)

1. **Registro de la Propiedad Intelectual** (en España, el Registro territorial de tu comunidad). Se
   registra como **programa de ordenador** y, si se quiere, por separado como obra audiovisual y las
   composiciones musicales. Se aporta: el código fuente (listado o soporte), una memoria descriptiva,
   capturas y los datos del titular. Sirve de prueba de autoría con fecha.
2. **Marca**, para el nombre: **LANDRACE HUNTERS** (y, si interesa, **WOLFCADE**) en la OEPM, clase 9
   (programas de videojuego) y clase 41 (servicios de entretenimiento); si el mercado es europeo, marca
   de la UE en la EUIPO. El nombre comercial es lo único que de verdad impide que otro publique un juego
   llamado igual.
3. **Depósito fechado alternativo o complementario**: un notario, un sello de tiempo o el propio
   historial de git publicado en GitHub con fechas.
4. **Licencia de distribución**: decidir y escribir en el repositorio bajo qué condiciones se publica
   (todos los derechos reservados es lo normal en un juego comercial).
5. Guardar junto al registro: **los términos de PixelLab y el recibo de la suscripción**, las licencias
   de las tres fuentes y este documento.

---

## 8. Cabos sueltos que conviene atar antes de publicar

- `package.json` describe el proyecto como «inspirado en las mecánicas de Weed Firm». **Las mecánicas de
  un juego no están protegidas** y ahí no hay infracción, pero citar otro título en la descripción de un
  paquete que se publica no aporta nada y puede confundir: conviene reescribir esa línea con una
  descripción propia antes de publicar.
- **Añadir a CRÉDITOS → LICENCIAS los avisos de las bibliotecas de Android** que entran en el AAB (Play Billing, Play Games v2, AndroidX y Sentry): la Apache 2.0 obliga a incluir su aviso de copyright, y hoy esa pantalla solo trae Godot y las tres fuentes.
- Repasar que ningún sprite procesado conserve el nombre de la referencia de la que se partió.
- Antes del registro, exportar el código fuente en un soporte fijo (PDF o ZIP con suma de verificación)
  y anotar la suma en este documento.

---

*WolfCade · Landrace Hunters · este documento se actualiza cuando entra arte, música o código de fuera.*
