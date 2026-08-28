# El APK

El juego es un `index.html` autónomo —todo el arte y el audio se generan por código, no hay
ni una imagen ni un archivo de sonido— así que la parte nativa **solo lo aloja**: un `WebView`
a pantalla completa y apaisado. No hay puente de JavaScript a Java, ni permisos, ni una sola
dependencia.

## Bajarse el APK sin compilar nada

Lo compila GitHub Actions: **Actions ▸ «APK · Bilbo City» ▸ el run ▸ Artifacts ▸
`BilboCity-apk`**. Se lanza solo cuando cambia el juego o esta carpeta, y a mano con
*Run workflow*.

En el móvil: abrir el `.apk`, activar «instalar apps desconocidas» si lo pide. Por USB con
depuración: `adb install -r BilboCity.apk`.

## Compilarlo en local

Hace falta el SDK de Android (lo pone Android Studio solo). Desde `bilbo-city/android`:

```bash
echo "sdk.dir=$ANDROID_HOME" > local.properties
gradle wrapper          # una vez, si quieres ./gradlew
./gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

O más corto: **Android Studio ▸ abrir `bilbo-city/android` ▸ Run ▶**.

## Tres decisiones que no son obvias

- **El HTML no se versiona dos veces.** `assets/index.html` lo pone una tarea de Gradle
  (`copiarJuego`) desde `referencia/bilbo-city.html` al compilar, y está en `.gitignore`.
  Una copia versionada se queda vieja el primer día y nadie se entera hasta que el APK va
  una semana por detrás del juego. El workflow lo comprueba: compara los bytes del original
  con los de la copia y mira que `assets/index.html` esté dentro del APK. El fallo silencioso
  de esto es una app que instala, abre y se queda en negro.
- **`minSdk` 26, y no menos.** Por debajo de Android 8 el icono necesitaría PNG en cinco
  densidades, y aquí no entra ni una imagen: con 26 el icono es un vector —el meandro de la
  ría— y todo el arte sigue siendo código.
- **Ni un `gradle-wrapper.jar` en el repositorio.** Es un binario. En CI lo pone
  `gradle/actions/setup-gradle`; en local, `gradle wrapper` o Android Studio.

## Lo que hace el WebView y por qué

| | |
|---|---|
| `setDomStorageEnabled(true)` | El juego guarda la partida en `localStorage` cuando no hay `window.storage`. Sin esto la escritura falla en silencio y la partida se pierde al salir. |
| `setMediaPlaybackRequiresUserGesture(false)` | El sonido es Web Audio. Sin esto el contexto nace suspendido y no suena hasta el segundo toque, que se lee como que el juego no tiene audio. |
| `setUseWideViewPort(false)` y sin zoom | Es pixel art: el lienzo va a resolución baja y se escala en entero. Si el WebView reescala la página, esa cuenta se rompe y salen píxeles de tamaños distintos. |
| `FLAG_KEEP_SCREEN_ON` | Un juego que se apaga solo mientras miras el mapa no es un juego. |
| `onPause` → `pauseTimers()` | Sin esto el bucle y el audio siguen corriendo con la app en segundo plano. |

## Para publicar

El APK de depuración va firmado con la clave de depuración: sirve para instalar y probar,
no para la Play Store. Para eso hace falta un keystore propio y un `signingConfigs` en
`app/build.gradle.kts` — **y la clave no entra en el repositorio**, va por secretos del
workflow.
