# Landrace Hunters · Declaración de originalidad y procedencia

Documento de respaldo para registrar la obra y acreditar su autoría. Hecho el 2 de noviembre de 2026
sobre la versión de Godot del juego (`ribera-verde/godot/`).

> **Aviso previo, en una línea:** un videojuego **no se patenta**. Se **registra como obra** (derecho de
> autor: guion, arte, música y código), su interfaz puede registrarse como **diseño industrial**, y su
> **nombre y su logo, como marca**. El detalle, en §7. Lo que este documento acredita es lo que de verdad
> sostiene todo eso: que **todo lo que se publica es original o está licenciado**, y que hay **rastro
> fechado** de cómo se hizo.
>
> Esto es una guía de trabajo, no asesoramiento jurídico: antes de presentar nada, que lo mire un
> abogado de propiedad intelectual.

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

## 3. Arte generado con el generador de sprites

Parte de los personajes, los muebles de los locales y algunos escenarios se generaron con **el generador de sprites**
(`el generador de sprites`) desde este proyecto y después se revisaron y retocaron a mano.

- El uso está sujeto a los términos de servicio del generador de sprites (`https://el generador de sprites/termsofservice`), que
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
| **Bibliotecas de Android del AAB** | Google (Play Billing, Play Games v2, AndroidX) y Sentry | Apache 2.0 (Sentry: MIT) | Se enlazan en la compilación de Android (`godot/addons/landrace_play`). Sus avisos, con el texto entero de la Apache 2.0 y de la MIT de Sentry, salen en CRÉDITOS → LICENCIAS (`godot/licencias/`). |

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

- **Nada de assets ni código de terceros con copyright**: ni sprites de franquicias comerciales, ni código de
  Habbo/Sulake, ni descompilaciones de juegos comerciales, ni el los wordmarks de consolas comerciales,
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

## 7. Cómo se protege cada parte (las cuatro vías)

El derecho de autor **nace solo**, en el momento de crear la obra y plasmarla en un soporte: no hay que
registrar nada para tenerlo. Lo que da el registro es **prueba con fecha** ante un plagio. Cada parte
del juego se defiende por una vía distinta:

### 7.1 Argumento, guion y diálogos → derecho de autor

- Protege **la expresión concreta**: cómo se cuenta la historia y los textos exactos. **No protege la
  idea abstracta**: otro puede hacer un juego de cultivo sin copiar nada si su historia y sus diálogos
  son distintos.
- Dónde está lo nuestro, ya escrito y fechado: `docs/GUION.md` (el hilo del cuaderno azul de la tía
  Maite y los cuatro actos), `godot/i18n/strings.csv` (todos los diálogos, línea a línea),
  `godot/datos/datos.json` (misiones, recados, personajes) y `docs/GDD.md`.
- **Qué hacer:** registrarlo en el Registro de la Propiedad Intelectual y/o sellarlo con marca de tiempo
  (Safe Creative, un sello de tiempo cualificado o acta notarial). Aportar el guion y el volcado de
  diálogos como un PDF único, con la fecha y la versión.

### 7.2 Pantallas, estética y arte → derecho de autor + diseño industrial

- **Derecho de autor (obra artística):** sprites, escenarios, personajes, iconos, interfaz y el icono de
  la app. Ventaja nuestra: el arte está en **código fuente** (`tools/sprites/a-mano/*.py`), así que se
  acredita el proceso, no solo el resultado.
- **Diseño industrial:** si la interfaz o el HUD son distintivos, se registran en la **OEPM** (España) o
  en la **EUIPO** (dibujo o modelo comunitario) e impiden copiar la disposición exacta de menús y
  pantallas. Candidatos claros aquí: el HUD con sus filas, los mandos flotantes, la vista C de la carpa,
  el cuadro de diálogo con busto y cinta de nombre, y la ficha de la carpa.
- **Ojo con el plazo:** el dibujo o modelo comunitario exige novedad, con un **periodo de gracia de 12
  meses** desde la primera divulgación pública. Si el juego ya se enseñó, hay que registrar dentro de ese
  año.
- **Qué hacer:** sacar las capturas con `tests/capturas.gd` (`store/`) y presentar las vistas de cada
  pantalla que se quiera registrar.

### 7.3 Código fuente → derecho de autor (como obra literaria)

- El código está protegido **automáticamente**: nadie puede copiarlo, descompilarlo ni reutilizarlo sin
  permiso. Son `godot/src/*.gd`, `tools/*.js`, `tools/*.py` y los generadores de datos.
- **Qué hacer:** registrarlo como **programa de ordenador** (se aporta un listado del código, normalmente
  las primeras y últimas páginas o el fuente entero en soporte), escribir en el repositorio bajo qué
  licencia se publica (en un juego comercial, «todos los derechos reservados») y mantener el repositorio
  privado y con copia.

### 7.4 Nombre y logo → marca

- **LANDRACE HUNTERS** (y, si interesa, **WOLFCADE** y **STRAINBOY**) se registran como **marca** en la
  OEPM o, para toda la UE, en la **EUIPO**. Clases: **9** (programas de videojuego) y **41** (servicios
  de entretenimiento).
- Es lo único que impide de verdad que otro publique un juego con el mismo título. El derecho de autor
  **no protege los títulos**.
- **Qué hacer antes:** comprobar que el nombre está libre en los buscadores de la OEPM y la EUIPO, y
  registrar el logo tal como se usa.

### 7.5 Patente: cuándo sí (y por qué aquí no)

No se patenta ni el juego ni su argumento ni sus reglas. Sí se patentan **innovaciones técnicas**: un
accesorio o hardware propio, o un algoritmo que resuelva un problema técnico concreto (el caso clásico
es la patente de Bandai Namco sobre los minijuegos durante las pantallas de carga). Para un desarrollo
independiente queda descartada por coste y complejidad; además, nada de este juego encaja ahí.

### 7.6 Lo que hay que guardar junto al registro

- Este documento.
- Los **términos del generador de sprites** y el recibo de la suscripción.
- Las licencias de las tres fuentes de terceros (ya en `godot/fuentes/`).
- El historial de git exportado (`git log`) como prueba de fechas, y el ZIP del fuente con su suma de
  verificación.

### 7.7 Resumen de la estrategia

| Qué | Vía | Dónde | Automático | Qué aporta registrarlo |
| --- | --- | --- | --- | --- |
| Argumento, guion y diálogos | Derecho de autor | Registro de la Propiedad Intelectual · Safe Creative · notario | Sí | Prueba de fecha ante un plagio |
| Arte, pantallas y música | Derecho de autor | Igual que arriba | Sí | Igual |
| Interfaz y HUD | Diseño industrial | OEPM · EUIPO | No | Impide copiar la disposición exacta (12 meses de gracia) |
| Código fuente | Derecho de autor (programa de ordenador) | Registro de la Propiedad Intelectual | Sí | Prueba de titularidad del software |
| Nombre y logo | Marca | OEPM · EUIPO (clases 9 y 41) | **No** | Uso exclusivo del nombre en el sector |
| Invención técnica | Patente | OEPM | No | No aplica a este juego |

## 8. Cabos sueltos que conviene atar antes de publicar

- Repasar que ningún sprite procesado conserve el nombre de la referencia de la que se partió.
- Antes del registro, exportar el código fuente en un soporte fijo (PDF o ZIP con suma de verificación)
  y anotar la suma en este documento.

---

*WolfCade · Landrace Hunters · este documento se actualiza cuando entra arte, música o código de fuera.*
