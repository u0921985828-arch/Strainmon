#!/usr/bin/env node
/*
  Ribera Verde — APK del port a Godot (godot/, el juego entero), sin Android SDK ni Gradle
    1. Godot 4.3 (GODOT=… o /home/user/godot-bin/Godot_v4.3-stable_linux.x86_64) con sus plantillas de exportación
       (~/.local/share/godot/export_templates/4.3.stable) exporta la plantilla release sin firmar (godot/export_presets.cfg:
       arm64-v8a, com.riberaverde.godot). La comprobación del SDK solo mira que existan adb y apksigner: se le da una carpeta
       con dos scripts vacíos (tools/salida/godot-sdk), porque la firma la hace el paso 2.
    1b. Godot reescala los iconos a cada densidad con un filtro suave (pixel art borroso en xxhdpi, ×4,5): se vuelven a escribir
       en el APK por vecino más próximo desde art/icono, al tamaño que dejó Godot.
    2. uber-apk-signer (el de tools/build-apk.js, en tools/salida/apk-cache con su huella): zipalign + firma v1/v2/v3 con su
       clave de depuración fija y verificación.
  Sale: dist/ribera-verde-godot.apk.   Uso: node tools/godot.js && node tools/godot-apk.js
*/
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { PNG } = require('pngjs');

const ROOT = path.join(__dirname, '..'), GD = path.join(ROOT, 'godot'), SAL = path.join(__dirname, 'salida');
const GODOT = process.env.GODOT || '/home/user/godot-bin/Godot_v4.3-stable_linux.x86_64';
const SIGNER = { f: path.join(SAL, 'apk-cache', 'signer', 'signer.jar'), url: 'https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar',
  sha256: 'e1299fd6fcf4da527dd53735b56127e8ea922a321128123b9c32d619bba1d835' };
const run = (cmd, args, opts = {}) => execFileSync(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 64 << 20, ...opts }).toString();

if (!fs.existsSync(GODOT)) throw new Error('falta Godot 4.3: ' + GODOT + ' (o GODOT=…)');
const TPL = path.join(process.env.HOME, '.local/share/godot/export_templates/4.3.stable/android_release.apk');
if (!fs.existsSync(TPL)) throw new Error('faltan las plantillas de exportación de Godot 4.3: ' + TPL);
if (!fs.existsSync(path.join(GD, 'datos', 'datos.json'))) throw new Error('falta godot/datos: node tools/godot.js');

// 0 · iconos del lanzador, de art/icono (tools/sprites/a-mano/icono.py), por vecino más próximo: el normal (48 px de arte) a ×4
//     = 192 y, para el adaptativo (Android 8+), sus dos capas (72 px de arte = 108 dp) a ×6 = 432
const ICO = path.join(GD, 'icono');
{
  fs.mkdirSync(ICO, { recursive: true });
  fs.writeFileSync(path.join(ICO, 'icono-192.png'), PNG.sync.write(vecino('icono-48.png', 192)));
  fs.writeFileSync(path.join(ICO, 'icono-delante-432.png'), PNG.sync.write(vecino('icono-delante-72.png', 432)));
  fs.writeFileSync(path.join(ICO, 'icono-fondo-432.png'), PNG.sync.write(vecino('icono-fondo-72.png', 432)));
}
// un PNG de art/icono a lado × lado, por vecino más próximo (a ×1,5 o ×4,5 los píxeles salen desiguales, pero nítidos)
function vecino(f, lado) {
  const t = PNG.sync.read(fs.readFileSync(path.join(ROOT, 'art', 'icono', f))), o = new PNG({ width: lado, height: lado });
  for (let y = 0; y < lado; y++) for (let x = 0; x < lado; x++) {
    const i = (Math.floor(y * t.height / lado) * t.width + Math.floor(x * t.width / lado)) * 4; t.data.copy(o.data, (y * lado + x) * 4, i, i + 4);
  }
  return o;
}

// 1 · SDK de mentira y exportación sin firmar
const SDK = path.join(SAL, 'godot-sdk'), TMP = path.join(SAL, 'godot-apk');
for (const f of ['platform-tools/adb', 'build-tools/34.0.0/apksigner']) {
  fs.mkdirSync(path.dirname(path.join(SDK, f)), { recursive: true });
  fs.writeFileSync(path.join(SDK, f), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
}
fs.rmSync(TMP, { recursive: true, force: true });fs.mkdirSync(TMP, { recursive: true });
const sinFirmar = path.join(TMP, 'sin-firmar.apk');
const env = { ...process.env, ANDROID_HOME: SDK, ANDROID_SDK_ROOT: SDK, JAVA_HOME: process.env.JAVA_HOME || path.dirname(path.dirname(fs.realpathSync(run('which', ['java']).trim()))) };
let log = '';
try { log = run(GODOT, ['--headless', '--path', GD, '--export-release', 'Android', sinFirmar], { env }); }
catch (e) { log = (e.stdout || '') + (e.stderr || ''); }
if (!fs.existsSync(sinFirmar)) { console.error(log); throw new Error('Godot no ha exportado el APK'); }

// 1b · los iconos de cada densidad, nítidos (zip -0 los cambia en su sitio; la firma del paso 2 rehace el APK)
{
  const DE = { 'icon.png': 'icono-48.png', 'icon_foreground.png': 'icono-delante-72.png', 'icon_background.png': 'icono-fondo-72.png' };
  const ents = run('unzip', ['-Z1', sinFirmar]).split('\n').filter(e => /^res\/mipmap[^/]*\/icon(_foreground|_background)?\.png$/.test(e));
  if (ents.length < 15) throw new Error('el APK de Godot no trae los iconos esperados: ' + ents.join(', '));
  for (const e of ents) {
    const lado = PNG.sync.read(execFileSync('unzip', ['-p', sinFirmar, e], { maxBuffer: 1 << 26 })).width;
    fs.mkdirSync(path.join(TMP, path.dirname(e)), { recursive: true });
    fs.writeFileSync(path.join(TMP, e), PNG.sync.write(vecino(DE[path.basename(e)], lado)));
  }
  execFileSync('zip', ['-q', '-0', sinFirmar, ...ents], { cwd: TMP });
}

// 2 · zipalign + firma + verificación
if (!fs.existsSync(SIGNER.f)) { fs.mkdirSync(path.dirname(SIGNER.f), { recursive: true });run('curl', ['-sSLf', '--max-time', '300', '-o', SIGNER.f, SIGNER.url]); }
if (crypto.createHash('sha256').update(fs.readFileSync(SIGNER.f)).digest('hex') !== SIGNER.sha256) throw new Error('uber-apk-signer: la huella no coincide');
const FIR = path.join(TMP, 'firmado');
const flog = run('java', ['-jar', SIGNER.f, '-a', sinFirmar, '-o', FIR, '--allowResign']);
const firmado = fs.existsSync(FIR) && fs.readdirSync(FIR).find(f => f.endsWith('.apk'));
if (!firmado) { console.error(flog); throw new Error('uber-apk-signer no ha dejado APK'); }
const ver = run('java', ['-jar', SIGNER.f, '-a', path.join(FIR, firmado), '-y', '--verbose']);
if (!/VERIFY[\s\S]*SUCCESS|verified/i.test(ver) || /FAIL/i.test(ver)) { console.error(ver); throw new Error('la verificación de la firma ha fallado'); }
fs.mkdirSync(path.join(ROOT, 'dist'), { recursive: true });
const OUT = path.join(ROOT, 'dist', 'ribera-verde-godot.apk');
fs.copyFileSync(path.join(FIR, firmado), OUT);
const esquemas = (ver.match(/v[123]-?signature[^\n]*|Scheme v[123][^\n]*/gi) || []).slice(0, 3).join(' · ');
console.log(`APK OK: dist/ribera-verde-godot.apk · ${(fs.statSync(OUT).size / 1048576).toFixed(2)} MB${esquemas ? ' · ' + esquemas : ''}`);
