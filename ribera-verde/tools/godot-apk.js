#!/usr/bin/env node
/*
  Ribera Verde — APK del corte de prueba en Godot (godot/), sin Android SDK ni Gradle
    1. Godot 4.3 (GODOT=… o /home/user/godot-bin/Godot_v4.3-stable_linux.x86_64) con sus plantillas de exportación
       (~/.local/share/godot/export_templates/4.3.stable) exporta la plantilla release sin firmar (godot/export_presets.cfg:
       arm64-v8a, com.riberaverde.godot). La comprobación del SDK solo mira que existan adb y apksigner: se le da una carpeta
       con dos scripts vacíos (tools/salida/godot-sdk), porque la firma la hace el paso 2.
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

// 0 · iconos del lanzador, de godot/icono.svg (rectángulos de 16 × 16): el normal a 192 px y, para el adaptativo (Android 8+),
//     la planta sola centrada en 432 px, dentro del círculo que no recorta ninguna máscara (264 px), sobre fondo #121519
const ICO = path.join(GD, 'icono');
{
  const rects = [...fs.readFileSync(path.join(GD, 'icono.svg'), 'utf8').matchAll(/<rect([^>]*)\/>/g)].map(m => {
    const at = k => { const v = m[1].match(new RegExp('\\b' + k + '="([^"]*)"')); return v ? v[1] : null; };
    return { x: +(at('x') || 0), y: +(at('y') || 0), w: +at('width'), h: +at('height'), rx: +(at('rx') || 0), c: at('fill') };
  });
  const png = (f, n, pinta) => {
    const im = new PNG({ width: n, height: n });
    for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
      const c = pinta(x, y), o = (y * n + x) * 4;
      if (c) { for (let k = 0; k < 3; k++) im.data[o + k] = parseInt(c.slice(1 + 2 * k, 3 + 2 * k), 16); im.data[o + 3] = 255; }
    }
    fs.writeFileSync(path.join(ICO, f), PNG.sync.write(im));
  };
  const dentro = (r, u, v) => {
    if (u < r.x || v < r.y || u >= r.x + r.w || v >= r.y + r.h) return false;
    if (!r.rx) return true;
    const cx = Math.min(Math.max(u, r.x + r.rx), r.x + r.w - r.rx), cy = Math.min(Math.max(v, r.y + r.rx), r.y + r.h - r.rx);
    return (u - cx) ** 2 + (v - cy) ** 2 <= r.rx ** 2;
  };
  const color = (l, u, v) => { let c = null; for (const r of l) if (dentro(r, u, v)) c = r.c; return c; };
  const planta = rects.filter(r => !r.rx);
  const x0 = Math.min(...planta.map(r => r.x)), x1 = Math.max(...planta.map(r => r.x + r.w));
  const y0 = Math.min(...planta.map(r => r.y)), y1 = Math.max(...planta.map(r => r.y + r.h));
  const k = 15, ox = (432 - (x1 - x0) * k) / 2, oy = (432 - (y1 - y0) * k) / 2;
  fs.mkdirSync(ICO, { recursive: true });
  png('icono-192.png', 192, (x, y) => color(rects, (x + .5) / 12, (y + .5) / 12));
  png('icono-delante-432.png', 432, (x, y) => x < ox || y < oy ? null : color(planta, x0 + Math.floor((x - ox) / k), y0 + Math.floor((y - oy) / k)));
  png('icono-fondo-432.png', 432, () => rects.find(r => r.rx).c);
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
