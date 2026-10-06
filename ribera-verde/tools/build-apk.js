#!/usr/bin/env node
/*
  Ribera Verde — APK de Android (sin Android SDK)
  Envuelve el index.html del build (offline, con el atlas incrustado) en una app con un WebView a pantalla completa.

  Pasos:
    1. herramientas en tools/salida/apk-cache (se descargan la primera vez y se comprueba su huella):
       apktool 2.9.3 (trae aapt2 y el framework), dalvik-dx 9.0.0_r3 (Maven Central) y uber-apk-signer 1.3.0;
    2. javac de tools/apk/java contra los stubs de tools/apk/stubs (solo las firmas de la API que se usan) y dx → classes.dex;
    3. proyecto de apktool en tools/salida/apk/proyecto: manifiesto, apktool.yml, icono (la hoja del título del atlas),
       nombre y assets/index.html → apktool b;
    4. uber-apk-signer: zipalign + firma v1/v2/v3 con su clave de depuración (la misma en cada build, así que una versión
       nueva se instala encima sin perder la partida) y verificación.
  Sale: dist/ribera-verde.apk

  Requisitos: Java 17+ (javac), node, red a github.com y repo1.maven.org la primera vez. Uso: npm run apk
*/
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..');
const APK = path.join(__dirname, 'apk');
const SAL = path.join(__dirname, 'salida');
const CACHE = path.join(SAL, 'apk-cache');
const TMP = path.join(SAL, 'apk');
const PKG = JSON.parse(fs.readFileSync(path.join(ROOT, 'package.json'), 'utf8'));
const [ma, mi, pa] = PKG.version.split('.').map(Number);
const VERSION_CODE = ma * 10000 + mi * 100 + pa;
const PAQUETE = 'com.riberaverde.juego';

const HERRAMIENTAS = {
  apktool: { url: 'https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar', sha256: '7956eb04194300ce0d0a84ad18771eebc94b89fb8d1ddcce8ea4c056818646f4' },
  dx: { url: 'https://repo1.maven.org/maven2/com/jakewharton/android/repackaged/dalvik-dx/9.0.0_r3/dalvik-dx-9.0.0_r3.jar', sha256: 'b29c1c21e52ed6238cd3fed39d880a17ecf2360118604548cea8821be6801e1c' },   // sha1 de Maven Central: df4b3258ddb4c7d531143405505a9396949bbb51
  signer: { url: 'https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar', sha256: 'e1299fd6fcf4da527dd53735b56127e8ea922a321128123b9c32d619bba1d835' },
};
const run = (cmd, args, opts = {}) => execFileSync(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], ...opts }).toString();
const hash = (f, alg) => crypto.createHash(alg).update(fs.readFileSync(f)).digest('hex');

function herramienta(n) {
  const h = HERRAMIENTAS[n], f = path.join(CACHE, n, n + '.jar');
  if (!fs.existsSync(f)) {
    fs.mkdirSync(path.dirname(f), { recursive: true });
    console.log(`descargando ${n}…`);
    run('curl', ['-sSLf', '--max-time', '300', '-o', f, h.url]);
  }
  if (h.sha256 && hash(f, 'sha256') !== h.sha256) throw new Error(`${n}: la huella sha256 no coincide; borra ${f} y vuelve a intentarlo`);
  return f;
}

// icono: la hoja del título (atlas procesado), 48×48 escalado por vecino más próximo a cada densidad
function iconos(dir) {
  const t = PNG.sync.read(fs.readFileSync(path.join(ROOT, 'art', 'procesado', 'titulo', 'base', 'unica', '00.png')));
  const X0 = 96, Y0 = 64, N = 48;
  for (const [d, k] of [['mdpi', 1], ['xhdpi', 2], ['xxhdpi', 3], ['xxxhdpi', 4]]) {
    const o = new PNG({ width: N * k, height: N * k });
    for (let y = 0; y < N * k; y++) for (let x = 0; x < N * k; x++) {
      const i = ((Y0 + Math.floor(y / k)) * t.width + X0 + Math.floor(x / k)) * 4, j = (y * N * k + x) * 4;
      o.data[j] = t.data[i]; o.data[j + 1] = t.data[i + 1]; o.data[j + 2] = t.data[i + 2]; o.data[j + 3] = 255;
    }
    const f = path.join(dir, 'res', 'mipmap-' + d, 'ic_launcher.png'); fs.mkdirSync(path.dirname(f), { recursive: true }); fs.writeFileSync(f, PNG.sync.write(o));
  }
}

const html = path.join(ROOT, 'index.html');
if (!fs.existsSync(html)) { console.error('Falta index.html: ejecuta antes npm run build'); process.exit(1); }
const jar = { apktool: herramienta('apktool'), dx: herramienta('dx'), signer: herramienta('signer') };

fs.rmSync(TMP, { recursive: true, force: true });
const CLS = path.join(TMP, 'clases'), DEXIN = path.join(TMP, 'dex'), PROY = path.join(TMP, 'proyecto');
for (const d of [CLS, DEXIN, PROY]) fs.mkdirSync(d, { recursive: true });

// 2 · Java → dex (solo las clases del juego; los stubs se quedan fuera)
const fuentes = []; const busca = d => { for (const f of fs.readdirSync(d)) { const p = path.join(d, f); if (fs.statSync(p).isDirectory()) busca(p); else if (f.endsWith('.java')) fuentes.push(p); } };
busca(path.join(APK, 'stubs')); busca(path.join(APK, 'java'));
run('javac', ['-nowarn', '--release', '8', '-Xlint:-options', '-encoding', 'UTF-8', '-d', CLS, ...fuentes]);
fs.cpSync(path.join(CLS, 'com'), path.join(DEXIN, 'com'), { recursive: true });
run('java', ['-cp', jar.dx, 'com.android.dx.command.Main', '--dex', '--min-sdk-version=24', '--output=' + path.join(PROY, 'classes.dex'), DEXIN]);

// 3 · proyecto de apktool
fs.writeFileSync(path.join(PROY, 'AndroidManifest.xml'), fs.readFileSync(path.join(APK, 'AndroidManifest.xml'), 'utf8').replace(/__PAQUETE__/g, PAQUETE));
fs.writeFileSync(path.join(PROY, 'apktool.yml'), `!!brut.androlib.apk.ApkInfo
apkFileName: ribera-verde.apk
compressionType: false
doNotCompress:
- resources.arsc
- png
isFrameworkApk: false
packageInfo:
  forcedPackageId: '127'
  renameManifestPackage: null
sdkInfo:
  minSdkVersion: '24'
  targetSdkVersion: '34'
sharedLibrary: false
sparseResources: false
usesFramework:
  ids:
  - 1
  tag: null
version: 2.9.3
versionInfo:
  versionCode: '${VERSION_CODE}'
  versionName: ${PKG.version}
`);
fs.mkdirSync(path.join(PROY, 'res', 'values'), { recursive: true });
fs.writeFileSync(path.join(PROY, 'res', 'values', 'strings.xml'), '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <string name="app_name">Ribera Verde</string>\n</resources>\n');
iconos(PROY);
fs.mkdirSync(path.join(PROY, 'assets'), { recursive: true });
fs.copyFileSync(html, path.join(PROY, 'assets', 'index.html'));
const sinFirmar = path.join(TMP, 'sin-firmar.apk');
run('java', ['-jar', jar.apktool, '--frame-path', path.join(CACHE, 'framework'), 'b', PROY, '-o', sinFirmar], { cwd: TMP });

// 4 · zipalign + firma + verificación
const FIR = path.join(TMP, 'firmado');
const log = run('java', ['-jar', jar.signer, '-a', sinFirmar, '-o', FIR, '--allowResign']);
const firmado = fs.readdirSync(FIR).find(f => f.endsWith('.apk'));
if (!firmado) { console.error(log); throw new Error('uber-apk-signer no ha dejado APK'); }
const ver = run('java', ['-jar', jar.signer, '-a', path.join(FIR, firmado), '-y', '--verbose']);
if (!/VERIFY[\s\S]*SUCCESS|verified/i.test(ver) || /FAIL/i.test(ver)) { console.error(ver); throw new Error('la verificación de la firma ha fallado'); }
const OUT = path.join(ROOT, 'dist', 'ribera-verde.apk');
fs.copyFileSync(path.join(FIR, firmado), OUT);
const esquemas = (ver.match(/v[123]-?signature[^\n]*|Scheme v[123][^\n]*/gi) || []).slice(0, 3).join(' · ');
console.log(`APK OK: dist/ribera-verde.apk · ${PAQUETE} ${PKG.version} (${VERSION_CODE}) · ${(fs.statSync(OUT).size / 1048576).toFixed(2)} MB${esquemas ? ' · ' + esquemas : ''}`);
