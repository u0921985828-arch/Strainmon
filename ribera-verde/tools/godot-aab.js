#!/usr/bin/env node
/*
  Landrace Hunters — AAB para Google Play (y el APK universal sacado de él) con Godot 4.7 y la plantilla Gradle
    0. La música (tools/musica.js) y los iconos del lanzador de art/icono por vecino más próximo (godot/icono, también el monocromo
       de Android 13: la silueta del de delante en blanco).
    1. Godot 4.7 (GODOT=…) exporta el AAB sin firmar con export_presets.cfg (gradle_build, targetSdk 36, minSdk 24, arm64-v8a +
       armeabi-v7a). Necesita el Android SDK de verdad (ANDROID_HOME, por defecto /home/user/android-sdk: platform-tools,
       platforms;android-36 y build-tools;36.1.0) y lo apunta en los ajustes del editor de 4.7. La plantilla Gradle se instala
       en godot/android la primera vez (no va al repo).
    2. Godot reescala los iconos con un filtro suave: se vuelven a escribir en el AAB (webp sin pérdida) por vecino más próximo.
    3. Firma con la upload key: LH_KEYSTORE, LH_KEYSTORE_USER y LH_KEYSTORE_PASS (o LH_ENV=archivo con esas tres líneas). La
       keystore nunca va al repo. Sin ellas, sale el AAB sin firmar y el APK con la clave de depuración de Godot.
    4. bundletool (BUNDLETOOL=…jar) saca el APK universal; se comprueba la alineación de 16 KB (zipalign -c -P 16 y los LOAD de
       cada .so) y targetSdkVersion 36 con aapt2 dump badging.
  Sale: dist/landrace-hunters.aab y dist/landrace-hunters.apk.   Uso: node tools/godot-aab.js
*/
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..'), GD = path.join(ROOT, 'godot'), SAL = path.join(__dirname, 'salida'), DIST = path.join(ROOT, 'dist');
const GODOT = process.env.GODOT || '/home/user/godot-bin/Godot_v4.7-stable_linux.x86_64';
const SDK = process.env.ANDROID_HOME || '/home/user/android-sdk';
const BT = path.join(SDK, 'build-tools', '36.1.0');
const BUNDLETOOL = process.env.BUNDLETOOL || path.join(SDK, 'bundletool', 'bundletool.jar');
const JAVA_HOME = process.env.JAVA_HOME || path.dirname(path.dirname(fs.realpathSync(execFileSync('which', ['java']).toString().trim())));
const run = (cmd, args, opts = {}) => execFileSync(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 256 << 20, ...opts }).toString();
const falta = (f, que) => { if (!fs.existsSync(f)) throw new Error('falta ' + que + ': ' + f); };

falta(GODOT, 'Godot 4.7 (GODOT=…)');
falta(path.join(os.homedir(), '.local/share/godot/export_templates/4.7.stable/android_source.zip'), 'la plantilla Android de Godot 4.7');
falta(path.join(BT, 'zipalign'), 'build-tools 36.1.0 del Android SDK');
falta(path.join(SDK, 'platforms', 'android-36'), 'platforms;android-36 del Android SDK');
falta(BUNDLETOOL, 'bundletool (BUNDLETOOL=…)');

// la firma: variables o un archivo .env fuera del repo
const FIRMA = {};
if (process.env.LH_ENV) for (const l of fs.readFileSync(process.env.LH_ENV, 'utf8').split('\n')) { const m = l.match(/^(\w+)=(.*)$/); if (m) FIRMA[m[1]] = m[2]; }
for (const k of ['LH_KEYSTORE', 'LH_KEYSTORE_USER', 'LH_KEYSTORE_PASS']) if (process.env[k]) FIRMA[k] = process.env[k];
const firmado = !!(FIRMA.LH_KEYSTORE && FIRMA.LH_KEYSTORE_USER && FIRMA.LH_KEYSTORE_PASS);
if (firmado && path.resolve(FIRMA.LH_KEYSTORE).startsWith(path.resolve(ROOT, '..') + path.sep)) throw new Error('la keystore no puede estar dentro del repo');

// 0 · música e iconos
execFileSync(process.execPath, [path.join(__dirname, 'musica.js')], { stdio: 'inherit' });
const ICO = path.join(GD, 'icono');
fs.mkdirSync(ICO, { recursive: true });
fs.writeFileSync(path.join(ICO, 'icono-192.png'), PNG.sync.write(vecino('icono-48.png', 192)));
fs.writeFileSync(path.join(ICO, 'icono-delante-432.png'), PNG.sync.write(vecino('icono-delante-72.png', 432)));
fs.writeFileSync(path.join(ICO, 'icono-fondo-432.png'), PNG.sync.write(vecino('icono-fondo-72.png', 432)));
fs.writeFileSync(path.join(ICO, 'icono-mono-432.png'), PNG.sync.write(vecino('icono-delante-72.png', 432, true)));
// un PNG de art/icono a lado × lado por vecino más próximo; mono: blanco con el alfa del original
function vecino(f, lado, mono) {
  const t = PNG.sync.read(fs.readFileSync(path.join(ROOT, 'art', 'icono', f))), o = new PNG({ width: lado, height: lado });
  for (let y = 0; y < lado; y++) for (let x = 0; x < lado; x++) {
    const i = (Math.floor(y * t.height / lado) * t.width + Math.floor(x * t.width / lado)) * 4, j = (y * lado + x) * 4;
    t.data.copy(o.data, j, i, i + 4);
    if (mono) o.data[j] = o.data[j + 1] = o.data[j + 2] = 255;
  }
  return o;
}

// 1 · exportar el AAB sin firmar
const AJ = path.join(os.homedir(), '.config/godot/editor_settings-4.7.tres');
if (fs.existsSync(AJ)) {
  let s = fs.readFileSync(AJ, 'utf8');
  const pon = (k, v) => { const l = `${k} = "${v}"`; s = new RegExp('^' + k.replace(/\//g, '\\/') + ' = .*$', 'm').test(s) ? s.replace(new RegExp('^' + k.replace(/\//g, '\\/') + ' = .*$', 'm'), l) : s.replace(/\n*$/, '\n' + l + '\n'); };
  pon('export/android/android_sdk_path', SDK);
  pon('export/android/java_sdk_path', JAVA_HOME);
  fs.writeFileSync(AJ, s);
}
const TMP = path.join(SAL, 'godot-aab');
fs.rmSync(TMP, { recursive: true, force: true });fs.mkdirSync(TMP, { recursive: true });
const crudo = path.join(TMP, 'sin-firmar.aab');
const env = { ...process.env, ANDROID_HOME: SDK, JAVA_HOME };
delete env.ANDROID_SDK_ROOT;
const args = ['--headless', '--path', GD];
if (!fs.existsSync(path.join(GD, 'android', 'build', 'build.gradle'))) args.push('--install-android-build-template');
let log = '';
try { log = run(GODOT, [...args, '--export-release', 'Android', crudo], { env }); }
catch (e) { log = (e.stdout || '') + (e.stderr || ''); }
if (!fs.existsSync(crudo)) { console.error(log.slice(-6000)); throw new Error('Godot no ha exportado el AAB'); }

// 2 · iconos nítidos en el AAB (webp sin pérdida, al tamaño que dejó Godot)
{
  const DE = { 'icon': ['icono-48.png'], 'icon_foreground': ['icono-delante-72.png'], 'icon_background': ['icono-fondo-72.png'], 'icon_monochrome': ['icono-delante-72.png', true] };
  const ents = run('unzip', ['-Z1', crudo]).split('\n').filter(e => /^base\/res\/mipmap[^/]*\/icon(_foreground|_background|_monochrome)?\.webp$/.test(e));
  if (ents.length < 20) throw new Error('el AAB no trae los iconos esperados: ' + ents.join(', '));
  const lista = [];
  for (const e of ents) {
    const k = path.basename(e, '.webp'), png = path.join(TMP, e.replace(/\.webp$/, '.png'));
    fs.mkdirSync(path.dirname(png), { recursive: true });
    run('unzip', ['-o', '-q', crudo, e, '-d', TMP]);
    lista.push([png, path.join(TMP, e), DE[k][0], !!DE[k][1]]);
  }
  // el lado de cada webp lo mide Pillow; el PNG nítido lo hace vecino() y Pillow lo pasa a webp sin pérdida
  const lados = JSON.parse(run('python3', ['-I', '-c', 'import sys,json\nfrom PIL import Image\nprint(json.dumps([Image.open(f).size[0] for f in sys.argv[1:]]))', ...lista.map(l => l[1])]));
  lista.forEach((l, i) => fs.writeFileSync(l[0], PNG.sync.write(vecino(l[2], lados[i], l[3]))));
  run('python3', ['-I', '-c', 'import sys\nfrom PIL import Image\na=sys.argv[1:]\nfor p,w in zip(a[::2],a[1::2]):\n  im=Image.open(p)\n  im=im.convert("RGB") if w.endswith("icon_background.webp") else im.convert("RGBA")\n  im.save(w,"WEBP",lossless=True,quality=100)', ...lista.flatMap(l => [l[0], l[1]])]);
  execFileSync('zip', ['-q', '-0', crudo, ...ents], { cwd: TMP });
}

// 3 · firma con la upload key (jarsigner, como Gradle)
fs.mkdirSync(DIST, { recursive: true });
const AAB = path.join(DIST, 'landrace-hunters.aab'), APKS = path.join(TMP, 'universal.apks'), APK = path.join(DIST, 'landrace-hunters.apk');
fs.copyFileSync(crudo, AAB);
// bundletool solo lee la clave de un archivo: uno temporal fuera del repo, solo para el dueño, que se borra al salir
const PASS = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'lh-')), 'p');
if (firmado) { fs.writeFileSync(PASS, FIRMA.LH_KEYSTORE_PASS, { mode: 0o600 });process.on('exit', () => fs.rmSync(path.dirname(PASS), { recursive: true, force: true })); }
const ks = firmado ? ['--ks', FIRMA.LH_KEYSTORE, '--ks-key-alias', FIRMA.LH_KEYSTORE_USER, '--ks-pass', 'file:' + PASS, '--key-pass', 'file:' + PASS] : [];
const envF = { ...env, LH_KEYSTORE_PASS: FIRMA.LH_KEYSTORE_PASS || '' };
if (firmado) {
  run(path.join(JAVA_HOME, 'bin', 'jarsigner'), ['-sigalg', 'SHA256withRSA', '-digestalg', 'SHA-256', '-storepass:env', 'LH_KEYSTORE_PASS', '-keystore', FIRMA.LH_KEYSTORE, AAB, FIRMA.LH_KEYSTORE_USER], { env: envF });
  const v = run(path.join(JAVA_HOME, 'bin', 'jarsigner'), ['-verify', AAB], { env });
  if (!/jar verified/.test(v)) throw new Error('el AAB no verifica: ' + v);
} else console.warn('AVISO: sin LH_KEYSTORE*: el AAB sale sin firmar (Play no lo acepta) y el APK con la clave de depuración');

// 4 · APK universal, 16 KB y targetSdk
run('java', ['-jar', BUNDLETOOL, 'build-apks', '--bundle=' + AAB, '--output=' + APKS, '--mode=universal', '--overwrite', ...ks], { env: envF });
run('unzip', ['-o', '-q', APKS, 'universal.apk', '-d', TMP]);
fs.copyFileSync(path.join(TMP, 'universal.apk'), APK);
const za = run(path.join(BT, 'zipalign'), ['-c', '-P', '16', '-v', '4', APK]);
if (!/Verification succesful|Verification successful/.test(za)) throw new Error('zipalign -P 16 falla:\n' + za.slice(-3000));
// las páginas de 16 KB solo se exigen en 64 bits (arm64-v8a, x86_64); armeabi-v7a puede ir a 4 KB
const sos = run('unzip', ['-Z1', APK]).split('\n').filter(e => /^lib\/(arm64-v8a|x86_64)\/.*\.so$/.test(e));
const LIBS = path.join(TMP, 'libs');
for (const so of sos) {
  run('unzip', ['-o', '-q', APK, so, '-d', LIBS]);
  const loads = run('readelf', ['-lW', path.join(LIBS, so)]).split('\n').filter(l => /^\s*LOAD/.test(l));
  for (const l of loads) if (parseInt(l.trim().split(/\s+/).pop(), 16) < 0x4000) throw new Error(so + ': LOAD alineado a menos de 16 KB: ' + l);
}
const badge = run(path.join(BT, 'aapt2'), ['dump', 'badging', APK]);
const tgt = (badge.match(/targetSdkVersion:'(\d+)'/) || [])[1], pkg = (badge.match(/package: name='([^']+)'/) || [])[1];
if (tgt !== '36') throw new Error('targetSdkVersion ' + tgt + ' (se espera 36)');
const mb = f => (fs.statSync(f).size / 1048576).toFixed(2) + ' MB';
console.log(`AAB ${firmado ? 'firmado' : 'SIN FIRMAR'}: ${AAB} (${mb(AAB)})\nAPK universal: ${APK} (${mb(APK)})\n${pkg} · targetSdk ${tgt} · 16 KB OK en ${sos.length} .so`);
