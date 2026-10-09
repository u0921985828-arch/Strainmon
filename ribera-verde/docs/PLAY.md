# Ribera Verde en Google Play: ficha y lista de publicación

La app que se publica es la de Godot (`dist/ribera-verde-godot.apk`, `npm run godot:apk`). Lo que pide el juego por dentro está
en [NORMAS-MOVIL.md](NORMAS-MOVIL.md); aquí va lo que pide la tienda. Los gráficos están en [`play/`](play/).

## 1. Ficha de la tienda

| Campo | Valor |
|---|---|
| Nombre (máx. 30) | Ribera Verde |
| Paquete | `com.riberaverde.godot` (no se puede cambiar después de la primera subida: si se prefiere otro, cámbialo antes en `godot/export_presets.cfg`) |
| Descripción corta (máx. 80) | Cultiva, cruza y vende genéticas en un barrio obrero. Pixel art para mayores. |
| Categoría | Juegos · Simulación |
| Etiquetas | Simulación, Pixel art, Un jugador, Sin conexión, Historia |
| Precio | Gratis, sin anuncios ni compras |
| Correo de contacto | El tuyo (obligatorio; sale en la ficha) |
| Política de privacidad | La URL pública de [PRIVACIDAD.md](PRIVACIDAD.md) (obligatoria; ver § 5) |
| Icono 512 × 512 | `play/icono-512.png` |
| Gráfico destacado 1024 × 500 | `play/destacado-1024x500.png` |
| Capturas de móvil (2-8, máx. 2:1) | `play/captura-*.png` (1560 × 780, del ciclo jugado en Godot, con banda negra para no pasar de 2:1) |

### Descripción completa

> Tu tía Maite te ha dejado su piso en Ribera Verde, un barrio obrero a orillas de la ría: su armario de cultivo, su libreta de
> genéticas… y una deuda de 30.000 €.
>
> **Cultiva** de verdad: carpas a escala, focos de sodio, CFL o LED de barras, macetas de tela o de plástico, riego, clima de la
> sala, plagas y temporizador 18/6 o 12/12. Cada variedad crece según su % índica, y el foco sube a medida que crecen las plantas.
>
> **Cruza y estabiliza**: landraces de Afganistán, México o la India y los híbridos clásicos. De una F1 a una línea estable en la
> F4, con fenotipos estrella y esquejes de tus mejores madres. Todas van a tu Genoteca.
>
> **Vende y sobrevive**: clientes de barrio, al por mayor, rosin para los catadores… y patrullas de policía, ladrones, el calor
> de la redada y los plazos de la deuda. Recorre la comarca en autobús, del caserío de Mendialde a los astilleros.
>
> · Pixel art original, hecho a mano · Chiptune propio · Mandos táctiles pensados para jugar en horizontal con los pulgares
> · Sin conexión, sin anuncios y sin compras · Guardado automático
>
> Ribera Verde es una obra de ficción para mayores de 18 años. El cultivo y la venta de cannabis son delito en muchos países: el
> juego no anima a consumir ni a vender.

## 2. Clasificación de contenido (cuestionario IARC)

Respuestas para el cuestionario de la consola (categoría «Juego»):

| Pregunta | Respuesta |
|---|---|
| Violencia | Sí: peleas por turnos sin sangre, con personajes en pixel art (ladrones y policía). Sin violencia realista ni sexual |
| Miedo / terror | No |
| Sexualidad / desnudos | No |
| Lenguaje soez | No |
| **Drogas** | **Sí: el juego trata del cultivo y la venta de cannabis (ilegal en muchos países); se ve y se habla de él, y algunos personajes adultos fuman. Ningún menor fuma** |
| Alcohol / tabaco | Referencias (un bar) |
| Apuestas / juegos de azar con dinero | No |
| Compras digitales / cajas de botín | No |
| Interacción entre usuarios, chat, compartir ubicación | No |

Clasificación esperada: PEGI 18 / ESRB M (o Adults Only en algunas regiones) por las drogas. Es lo que corresponde: el juego ya
pide confirmar la edad al abrirlo.

## 3. Público objetivo y contenido

- **Público objetivo**: solo «18 años o más». No marcar ningún grupo de edad menor: con menores, el juego no cumple la política
  de Familias.
- **Anuncios**: no contiene anuncios.
- **Acceso a la app**: toda la app es accesible sin cuenta ni credenciales.
- **App de noticias / gubernamental / salud / préstamos**: no.

### Política de Google Play sobre el cannabis

Google Play no permite apps que **faciliten la venta** de cannabis o de sus productos, sea legal o no donde se use. Un juego de
simulación ficticio no vende nada, pero la revisión es manual, así que la ficha tiene que dejarlo claro:

- Decir que es un juego de ficción y para mayores (ya va en la descripción y en el juego).
- Nada de enlaces, cupones ni nombres de tiendas, bancos de semillas o marcas reales (el juego no los tiene: los nombres de las
  variedades son los de genéticas conocidas, sin marca).
- Las capturas, del juego y no de cannabis real.

Si la revisión lo rechaza, se puede recurrir desde la consola explicando que es una simulación sin venta real.

## 4. Seguridad de los datos (formulario «Data safety»)

| Pregunta | Respuesta |
|---|---|
| ¿Recoge o comparte alguno de los tipos de datos obligatorios? | **No** |
| ¿Los datos se cifran en tránsito? | No aplica (no se envía nada) |
| ¿Se puede pedir que se borren? | No aplica (no se recoge nada; la partida se borra desde el juego o al desinstalar) |
| Permisos | Ninguno |

## 5. Lo que falta para subirla (no se puede hacer desde aquí)

1. **Cuenta de desarrollador** de Google Play (pago único). Las cuentas personales nuevas tienen que hacer antes una **prueba
   cerrada con al menos 12 personas durante 14 días** seguidos.
2. **Android App Bundle (.aab)**: Play no acepta APK en apps nuevas. Godot solo lo exporta con la compilación por Gradle
   (`gradle_build/use_gradle_build=true` y `export_format=1`), que necesita el Android SDK y la plantilla de compilación de
   Godot instalada en `godot/android/build`. El APK de `npm run godot:apk` sirve para instalarlo a mano y para la prueba.
3. **Nivel de API**: Play exige un `targetSdkVersion` reciente (en 2025, API 35 para apps nuevas; mira el que pida la consola).
   La plantilla estándar de Godot 4.3 da 34: con Gradle se sube en `gradle_build/target_sdk`, o pasando a Godot 4.4 o posterior.
4. **Clave de subida**: crea tu propio almacén de claves (`keytool -genkeypair …`) y activa la firma de apps de Google Play. La
   clave y su contraseña **nunca van al repo**: pásalas a Godot por las variables `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`,
   `…_USER` y `…_PASSWORD`. El APK de ahora va firmado con una clave de depuración pública y no vale para la tienda.
5. **Política de privacidad pública**: Play pide una URL. Publica `docs/PRIVACIDAD.md` en una página abierta (GitHub Pages,
   una web propia…) y pon tu correo de contacto.
6. **Versión**: cada subida necesita un `version/code` mayor (`godot/export_presets.cfg`, ahora 6) y el `version/name` a juego
   (0.5.0, también en `application/config/version` de `godot/project.godot`, que sale en los créditos).
