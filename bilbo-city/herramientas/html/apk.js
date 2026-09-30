/* El juego dentro de una app de Android: un WebView y nada más.
 *
 * El puerto a Unity es el objetivo de producción, pero no se ha abierto nunca en el
 * editor y de ahí no sale un APK esta tarde. Esto sí: el prototipo ya está probado y es
 * un archivo suelto, así que la app es un `WebView` a pantalla completa cargándolo desde
 * los assets. No es un puerto ni una copia — el HTML entra tal cual, byte a byte.
 *
 *   node herramientas/html/apk.js            # escribe dist/android/
 *   node herramientas/html/apk.js --compilar # y llama a gradle, si hay SDK
 *
 * Después: Android Studio → abrir `dist/android` → Run. O `gradle assembleDebug` con
 * ANDROID_HOME apuntando a un SDK con la plataforma 34.
 *
 * `dist/` no se versiona: esto es salida, como el APK que produce.
 */
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const { execFileSync } = require('child_process');
const { FUENTE, DIST, paleta, icono32 } = require('./pwa.js');

const PAQ = 'eus.bilbocity.juego';
const RAIZ = path.join(DIST, 'android');
const AGP = '8.5.2', SDK = 34, MIN_SDK = 26;   // 26 = Android 8, el primero con icono adaptativo

/* Del dibujo de 32×32 a un VectorDrawable.
 *
 * Y no a un PNG, que sería lo evidente: Android pide el icono en cinco densidades —48,
 * 72, 96, 144 y 192— y solo dos de ellas son múltiplo entero de 32. Las otras tres
 * saldrían con unos píxeles del doble de alto que otros, que es justo lo que este
 * proyecto no hace. Un vector son rectángulos exactos y el lanzador lo pinta a la
 * resolución que le toque. Se juntan las tiras horizontales del mismo color para no
 * escribir mil veinticuatro rectángulos. */
function vectorDe(c32, esc, desp) {
  const d = c32.getContext('2d').getImageData(0, 0, 32, 32).data;
  const hex = i => '#' + [0,1,2].map(j => d[i+j].toString(16).padStart(2,'0')).join('');
  const porColor = new Map();
  for (let y = 0; y < 32; y++) {
    let x = 0;
    while (x < 32) {
      const i = (y*32 + x)*4;
      if (d[i+3] < 8) { x++; continue; }
      const col = hex(i);
      let an = 1;
      while (x + an < 32 && d[(y*32 + x + an)*4 + 3] >= 8 && hex((y*32 + x + an)*4) === col) an++;
      const X = desp + x*esc, Y = desp + y*esc, W = an*esc, H = esc;
      if (!porColor.has(col)) porColor.set(col, []);
      porColor.get(col).push(`M${X},${Y}h${W}v${H}h${-W}z`);
      x += an;
    }
  }
  const lado = desp*2 + 32*esc;
  return `<?xml version="1.0" encoding="utf-8"?>
<!-- Generado por herramientas/html/apk.js. No se edita a mano. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="${lado}dp" android:height="${lado}dp"
    android:viewportWidth="${lado}" android:viewportHeight="${lado}">
${[...porColor].map(([col, ds]) =>
  `    <path android:fillColor="${col}" android:pathData="${ds.join('')}"/>`).join('\n')}
</vector>
`;
}

const JAVA = `package ${PAQ};

import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import androidx.webkit.WebViewAssetLoader;

/** El juego entero. Un WebView a pantalla completa y nada más. */
public class Principal extends Activity {

    private WebView vista;

    @Override
    protected void onCreate(Bundle guardado) {
        super.onCreate(guardado);

        /* Los assets se sirven por https y no por file://, que es lo que parecería más
           directo. Un origen file:// tiene el almacenamiento capado según el fabricante y
           el juego guarda la partida en localStorage: se perdía sin decir nada. */
        final WebViewAssetLoader cargador = new WebViewAssetLoader.Builder()
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();

        vista = new WebView(this);
        vista.setBackgroundColor(Color.parseColor("#07090c"));
        vista.setOverScrollMode(View.OVER_SCROLL_NEVER);
        vista.setKeepScreenOn(true);            // nadie quiere que se apague conduciendo

        WebSettings s = vista.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);           // la partida
        s.setMediaPlaybackRequiresUserGesture(false);   // el audio se genera por código
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        s.setTextZoom(100);                     // el tamaño de letra del sistema no manda aquí

        vista.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView v, WebResourceRequest p) {
                return cargador.shouldInterceptRequest(p.getUrl());
            }
            /* El juego no navega a ningún lado. Cualquier intento de salir del origen de
               los assets se queda donde está: la app no pide permiso de red y una
               pantalla de error de conexión dentro del juego no tiene sentido. */
            @Override
            public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest p) {
                return true;
            }
        });

        setContentView(vista);
        Pantalla();
        vista.loadUrl("https://appassets.androidplatform.net/assets/index.html");
    }

    /** Sin barras: el juego ya dibuja su propio marco de consola de lado a lado. */
    private void Pantalla() {
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        WindowCompat.setDecorFitsSystemWindows(getWindow(), false);
        WindowInsetsControllerCompat c =
                WindowCompat.getInsetsController(getWindow(), vista);
        c.hide(WindowInsetsCompat.Type.systemBars());
        c.setSystemBarsBehavior(
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
    }

    @Override
    public void onWindowFocusChanged(boolean tieneFoco) {
        super.onWindowFocusChanged(tieneFoco);
        if (tieneFoco) Pantalla();              // vuelven al bajar la persiana de avisos
    }

    /* Atrás no mata la partida: manda la app al fondo, como el botón de inicio. El juego
       no tiene pantallas apiladas de las que volver, así que cerrar sería lo único que
       podría hacer, y sería una forma tonta de perder lo que no se haya guardado. */
    @Override
    public void onBackPressed() {
        moveTaskToBack(true);
    }

    @Override protected void onPause()  { super.onPause();  vista.onPause();  }
    @Override protected void onResume() { super.onResume(); vista.onResume(); }
    @Override protected void onDestroy() { vista.destroy(); super.onDestroy(); }
}
`;

const MANIFIESTO = `<?xml version="1.0" encoding="utf-8"?>
<!-- Generado por herramientas/html/apk.js. No se edita a mano. -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Ni un permiso. El juego no sale a la red, no mira los contactos y no sabe dónde
         estás: todo lo que necesita va dentro del APK. -->

    <application
        android:label="@string/app_name"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:theme="@style/TemaJuego"
        android:hardwareAccelerated="true"
        android:usesCleartextTraffic="false"
        android:allowBackup="true">

        <activity
            android:name=".Principal"
            android:exported="true"
            android:screenOrientation="sensorLandscape"
            android:resizeableActivity="false"
            android:configChanges="orientation|screenSize|screenLayout|keyboardHidden|density|uiMode"
            android:launchMode="singleTask">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
`;

function escribir(rel, txt) {
  const f = path.join(RAIZ, rel);
  fs.mkdirSync(path.dirname(f), { recursive: true });
  fs.writeFileSync(f, txt);
  return rel;
}

function empaquetar() {
  const C = paleta();
  const html = fs.readFileSync(FUENTE, 'utf8');
  const v = crypto.createHash('sha256').update(html).digest('hex').slice(0, 12);
  fs.rmSync(RAIZ, { recursive: true, force: true });

  const hechos = [];
  const A = (rel, txt) => hechos.push(escribir(rel, txt));

  A('settings.gradle', `pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
rootProject.name = 'BilboCity'
include ':app'
`);
  A('build.gradle', `plugins { id 'com.android.application' version '${AGP}' apply false }
`);
  A('gradle.properties', `android.useAndroidX=true
org.gradle.jvmargs=-Xmx2g
`);
  /* versionCode a mano y a 1: no hay tienda detrás que exija que suba, y sacarlo del
     hash daría un número que baja tan a menudo como sube. El nombre sí es el hash, que
     es lo que sirve para saber qué build tienes en el móvil. */
  A('app/build.gradle', `plugins { id 'com.android.application' }

android {
    namespace '${PAQ}'
    compileSdk ${SDK}

    defaultConfig {
        applicationId '${PAQ}'
        minSdk ${MIN_SDK}
        targetSdk ${SDK}
        versionCode 1
        versionName '${v}'
    }
    buildTypes {
        release { minifyEnabled false }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation 'androidx.core:core:1.13.1'
    implementation 'androidx.webkit:webkit:1.11.0'
}
`);
  A('app/src/main/AndroidManifest.xml', MANIFIESTO);
  A('app/src/main/java/' + PAQ.replace(/\./g, '/') + '/Principal.java', JAVA);
  A('app/src/main/assets/index.html', html);       // el juego, sin tocar

  A('app/src/main/res/values/strings.xml', `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Bilbo City</string>
</resources>
`);
  A('app/src/main/res/values/colors.xml', `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="fondo">#07090c</color>
</resources>
`);
  A('app/src/main/res/values/themes.xml', `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Material sin barra y con el fondo del juego: cualquier otro color asoma un
         instante al abrir y se ve un fogonazo blanco antes de la portada. -->
    <style name="TemaJuego" parent="@android:style/Theme.Material.NoActionBar">
        <item name="android:windowBackground">@color/fondo</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
</resources>
`);
  /* El fondo del icono adaptativo lleva el dibujo a sangre y el primer plano va vacío: el
     lanzador recorta la máscara sobre el fondo, y con el dibujo en el primer plano se
     queda encogido dentro de la zona segura y no llena el círculo. */
  const adaptativo = `<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/icono_fondo"/>
    <foreground android:drawable="@drawable/icono_frente"/>
</adaptive-icon>
`;
  A('app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml', adaptativo);
  A('app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml', adaptativo);
  A('app/src/main/res/drawable/icono_fondo.xml', vectorDe(icono32(C, 0), 3.375, 0));
  A('app/src/main/res/drawable/icono_frente.xml', `<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108"/>
`);

  A('LEEME.md', `# Bilbo City · envoltorio de Android

**Generado.** No se edita a mano: se rehace con \`node herramientas/html/apk.js\` desde
la raíz de \`bilbo-city/\`. Lo que hay aquí es una sola pantalla con un \`WebView\` que
carga \`app/src/main/assets/index.html\`, que es \`referencia/bilbo-city.html\` sin tocar.

Versión empaquetada: \`${v}\` (hash del HTML).

## Compilar

Con Android Studio: abrir esta carpeta y darle a Run.

Con gradle a mano, hace falta un SDK con la plataforma ${SDK}:

\`\`\`bash
export ANDROID_HOME=/ruta/al/sdk
gradle assembleDebug          # app/build/outputs/apk/debug/app-debug.apk
\`\`\`

No hay \`gradlew\`: el wrapper es un \`.jar\` y en este repositorio no entran binarios.
Android Studio lo pone solo, o \`gradle wrapper\` una vez.

## Lo que hace la app

- Pantalla completa, apaisada, sin barras y sin apagarse.
- Los assets se sirven por \`https://appassets.androidplatform.net/\`, no por \`file://\`:
  con \`file://\` el almacenamiento va según el fabricante y la partida se perdía.
- **Ningún permiso**, ni el de red. El juego no sale fuera.
- Atrás manda la app al fondo en vez de cerrarla.
`);

  const peso = hechos.reduce((n, f) => n + fs.statSync(path.join(RAIZ, f)).size, 0);
  console.log('-> ' + path.relative(process.cwd(), RAIZ) + '/  ' + hechos.length +
              ' ficheros · ' + (peso/1024/1024).toFixed(2) + ' MB · v' + v);
  return hechos;
}

/* Lo que se puede comprobar sin SDK de Android, que resulta ser casi todo lo que se
   rompe al tocar esto: que el XML esté bien formado, que el paquete diga lo mismo en los
   cuatro sitios donde se escribe, que cada `R.algo` del Java exista de verdad y que el
   HTML de los assets sea el del juego y no una copia vieja. */
function comprobar() {
  const mal = [];
  const ok = (c, t) => { if (c) console.log('  ok    ' + t); else { mal.push(t); console.log('  FALLO ' + t); } };
  const leer = f => fs.readFileSync(path.join(RAIZ, f), 'utf8');

  const xmls = [];
  (function andar(d) {
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      const f = path.join(d, e.name);
      if (e.isDirectory()) andar(f); else if (e.name.endsWith('.xml')) xmls.push(f);
    }
  })(RAIZ);
  try {
    execFileSync('python3', ['-c',
      'import sys,xml.etree.ElementTree as E\n' +
      'for f in sys.argv[1:]: E.parse(f)'].concat(xmls), { stdio: 'pipe' });
    ok(true, xmls.length + ' XML bien formados');
  } catch (e) { ok(false, 'XML mal formado: ' + String(e.stderr || e).trim().split('\n').pop()); }

  const java = leer('app/src/main/java/' + PAQ.replace(/\./g, '/') + '/Principal.java');
  ok(java.startsWith('package ' + PAQ + ';') &&
     leer('app/build.gradle').includes("namespace '" + PAQ + "'") &&
     leer('app/build.gradle').includes("applicationId '" + PAQ + "'"),
     'el paquete ' + PAQ + ' cuadra en el Java y en el gradle');

  /* Un `R.mipmap.loQueSea` que no existe no lo ve nadie hasta que compila Android
     Studio, y compilar Android Studio es lo que no se puede hacer aquí. */
  const recursos = new Set();
  (function andar(d, tipo) {
    if (!fs.existsSync(d)) return;
    for (const e of fs.readdirSync(d, { withFileTypes: true })) {
      if (e.isDirectory()) { andar(path.join(d, e.name), e.name.split('-')[0]); continue; }
      if (tipo === 'values') for (const m of fs.readFileSync(path.join(d, e.name), 'utf8')
          .matchAll(/<(string|color|style)\s+name="([^"]+)"/g))
        recursos.add((m[1] === 'style' ? 'style' : m[1]) + '/' + m[2]);
      else recursos.add(tipo + '/' + e.name.replace(/\.[^.]+$/, ''));
    }
  })(path.join(RAIZ, 'app/src/main/res'), null);
  const pedidos = [...MANIFIESTO.matchAll(/"@(\w+)\/(\w+)"/g)].map(m => m[1] + '/' + m[2])
    .concat([...leer('app/src/main/res/values/themes.xml').matchAll(/"@(\w+)\/(\w+)"/g)]
      .map(m => m[1] + '/' + m[2]))
    .concat([...leer('app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')
      .matchAll(/"@(\w+)\/(\w+)"/g)].map(m => m[1] + '/' + m[2]));
  const faltan = pedidos.filter(r => !recursos.has(r));
  ok(!faltan.length, 'los ' + new Set(pedidos).size + ' recursos que se piden existen' +
     (faltan.length ? ': falta ' + faltan.join(', ') : ''));

  ok(leer('app/src/main/assets/index.html') === fs.readFileSync(FUENTE, 'utf8'),
     'el HTML de los assets es el del juego, byte a byte');
  ok(!MANIFIESTO.includes('uses-permission'), 'la app no pide ni un permiso');
  ok(/screenOrientation="sensorLandscape"/.test(MANIFIESTO), 'la actividad va apaisada');

  /* El Java no se puede compilar sin el SDK, pero sí se puede LEER con javac: se le pasa
     y se mira qué se queja. Si todo lo que dice es que no encuentra `android.webkit` o un
     símbolo suyo, la sintaxis está bien; cualquier otra cosa —una llave de menos, un
     punto y coma— sale aquí y no tres días después al abrir Android Studio. */
  try {
    const salida = path.join(require('os').tmpdir(), 'bilbo-javac');
    fs.mkdirSync(salida, { recursive: true });
    let quejas = '';
    try {
      execFileSync('javac', ['-nowarn', '-proc:none', '-d', salida,
        path.join(RAIZ, 'app/src/main/java/' + PAQ.replace(/\./g, '/') + '/Principal.java')],
        { stdio: ['pipe', 'pipe', 'pipe'] });
    } catch (e) { quejas = String(e.stderr || ''); }
    const raras = quejas.split('\n')
      .filter(l => / error: /.test(l))
      .filter(l => !/(does not exist|cannot find symbol|method does not override)/.test(l));
    ok(!raras.length, 'el Java no tiene fallos de sintaxis' +
       (raras.length ? ': ' + raras[0].trim() : ''));
  } catch (e) { console.log('  --    sin javac: no puedo leer el Java'); }

  /* Un vector con un color fuera de la paleta sería el primero del proyecto. */
  const C = paleta(), hay = new Set(Object.values(C).map(h => h.toLowerCase()));
  const cols = [...leer('app/src/main/res/drawable/icono_fondo.xml')
    .matchAll(/fillColor="(#[0-9a-f]{6})"/g)].map(m => m[1]);
  ok(cols.length > 0 && cols.every(c => hay.has(c)),
     'los ' + cols.length + ' colores del icono están en la paleta');
  return mal;
}

function compilar() {
  if (!process.env.ANDROID_HOME && !process.env.ANDROID_SDK_ROOT) {
    console.log('  --    sin ANDROID_HOME: no hay SDK de Android que valga, no compilo');
    return [];
  }
  try {
    execFileSync('gradle', ['assembleDebug', '--console=plain'],
                 { cwd: RAIZ, stdio: 'inherit' });
    const apk = path.join(RAIZ, 'app/build/outputs/apk/debug/app-debug.apk');
    console.log('  ok    ' + apk + ' · ' + (fs.statSync(apk).size/1024/1024).toFixed(1) + ' MB');
    return [];
  } catch (e) { console.log('  FALLO gradle no pudo con ello'); return ['gradle']; }
}

if (require.main === module) {
  empaquetar();
  let mal = comprobar();
  if (process.argv.includes('--compilar')) mal = mal.concat(compilar());
  if (mal.length) { console.log('\n' + mal.length + ' fallos'); process.exit(1); }
  console.log('\nel proyecto de Android está listo para compilar');
}
