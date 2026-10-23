#!/usr/bin/env node
/*
  Ribera Verde — 1.42: el plugin de WordPress «landrace-hunters» con la versión web del juego Godot de hoy (lo pidió el usuario:
  «convierte el juego en un plugin para WordPress como este, actualizado al punto en el que estamos»).
    0. La música grabada (tools/musica.js → godot/musica), como para el APK; en la copia de la web, en mono y a calidad 0 (1.4.3).
    1. Copia godot/ a una carpeta temporal, le añade un preset «Web» (sin hilos, sin extensiones) y exporta solo el paquete:
       index.pck (--export-pack). export_presets.cfg del repo no se toca.
    2. Monta landrace-hunters/: el plugin (wordpress/: PHP, readme, .htaccess, lh-fs.js, index.html, iconos y licencias), el motor
       web de Godot 4.7 sin hilos (index.js, index.wasm y los dos worklets de audio, de --motor <dir>, LH_MOTOR o la plantilla instalada) y el index.pck;
       en index.html, los tamaños de fileSizes.
    3. Lo comprime en descargas/landrace-hunters-<versión del plugin>.zip.
  Uso: node tools/wordpress.js --motor <carpeta con index.js, index.wasm e index.audio.worklet.js> [--sin-zip --salida <dir>]
*/
const { execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

const ROOT = path.join(__dirname, '..'), GD = path.join(ROOT, 'godot'), WP = path.join(ROOT, 'wordpress');
const GODOT = process.env.GODOT || '/home/user/godot-bin/Godot_v4.7-stable_linux.x86_64';
const arg = (k, d) => { const i = process.argv.indexOf(k); return i > 0 && i + 1 < process.argv.length ? process.argv[i + 1] : d; };
const MOTOR_F = ['index.js', 'index.wasm', 'index.audio.worklet.js', 'index.audio.position.worklet.js'];   // 4.7: con el de la posición
// 0.51: sin --motor, el de la plantilla web sin hilos de Godot 4.7 instalada (godot.* → index.*)
const PLANTILLA = path.join(os.homedir(), '.local/share/godot/export_templates/4.7.stable/web_nothreads_release.zip');
let MOTOR = arg('--motor', process.env.LH_MOTOR || '');
if (!MOTOR && fs.existsSync(PLANTILLA)) {
  MOTOR = fs.mkdtempSync(path.join(os.tmpdir(), 'lh-motor-'));
  execFileSync('unzip', ['-q', '-o', PLANTILLA, '-d', MOTOR]);
  for (const f of MOTOR_F) fs.renameSync(path.join(MOTOR, f.replace(/^index/, 'godot')), path.join(MOTOR, f));
}

if (!fs.existsSync(GODOT)) throw new Error('falta Godot 4.7: ' + GODOT + ' (o GODOT=…)');
if (!MOTOR || !MOTOR_F.every((f) => fs.existsSync(path.join(MOTOR, f)))) throw new Error('falta el motor web de Godot 4.7 (sin hilos): --motor <dir> con ' + MOTOR_F.join(', '));
const php = fs.readFileSync(path.join(WP, 'landrace-hunters.php'), 'utf8');
const V = (php.match(/const VERSION\s*=\s*'([^']+)'/) || [])[1];
if (!V) throw new Error('no encuentro la versión en wordpress/landrace-hunters.php');

// 0 · la música
execFileSync(process.execPath, [path.join(__dirname, 'musica.js')], { stdio: 'inherit' });

// 1 · el index.pck, desde una copia del proyecto con el preset Web
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), 'lh-wp-'));
const PROY = path.join(TMP, 'godot');
fs.cpSync(GD, PROY, { recursive: true });
// 1.4.3: la música de la versión web, en mono y a calidad 0 (el zip, por debajo de 30 MB); la del APK no se toca
for (const f of fs.readdirSync(path.join(PROY, 'musica')).filter((x) => x.endsWith('.ogg'))) {
  const o = path.join(PROY, 'musica', f), t = o + '.tmp.ogg';
  execFileSync('ffmpeg', ['-v', 'error', '-y', '-i', o, '-c:a', 'libvorbis', '-q:a', '0', '-ac', '1', t]);
  fs.renameSync(t, o);
}
const pre = fs.readFileSync(path.join(PROY, 'export_presets.cfg'), 'utf8');
const filtro = (k) => (pre.match(new RegExp('^' + k + '="([^"]*)"', 'm')) || [])[1] || '';
fs.writeFileSync(path.join(PROY, 'export_presets.cfg'), `[preset.0]

name="Web"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="${filtro('include_filter')}"
exclude_filter="${filtro('exclude_filter')}"
export_path=""
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
`);
const OUT = arg('--salida', path.join(TMP, 'landrace-hunters'));
const GAME = path.join(OUT, 'game');
fs.rmSync(OUT, { recursive: true, force: true });
fs.mkdirSync(GAME, { recursive: true });
const PCK = path.join(GAME, 'index.pck');
try {
  execFileSync(GODOT, ['--headless', '--path', PROY, '--import'], { stdio: 'ignore', timeout: 600000 });
} catch (e) { /* --import sale con error si no hay nada que importar; el export de abajo dice si falta algo */ }
execFileSync(GODOT, ['--headless', '--path', PROY, '--export-pack', 'Web', PCK], { stdio: 'inherit', timeout: 900000 });
if (!fs.existsSync(PCK) || fs.statSync(PCK).size < 1 << 20) throw new Error('el export no dejó index.pck');
fs.chmodSync(PCK, 0o644);

// 2 · el plugin
fs.copyFileSync(path.join(WP, 'landrace-hunters.php'), path.join(OUT, 'landrace-hunters.php'));
fs.copyFileSync(path.join(WP, 'readme.txt'), path.join(OUT, 'readme.txt'));
for (const f of fs.readdirSync(path.join(WP, 'game'))) fs.copyFileSync(path.join(WP, 'game', f), path.join(GAME, f));
for (const f of MOTOR_F) fs.copyFileSync(path.join(MOTOR, f), path.join(GAME, f));
const tam = (f) => fs.statSync(path.join(GAME, f)).size;
const html = fs.readFileSync(path.join(GAME, 'index.html'), 'utf8')
  .replace(/"fileSizes": \{[^}]*\}/, `"fileSizes": {"index.pck": ${tam('index.pck')}, "index.wasm": ${tam('index.wasm')}}`);
if (!html.includes(`"index.pck": ${tam('index.pck')}`)) throw new Error('index.html sin fileSizes');
fs.writeFileSync(path.join(GAME, 'index.html'), html);

// 3 · el zip
if (!process.argv.includes('--sin-zip')) {
  const ZIP = path.join(ROOT, 'descargas', `landrace-hunters-${V}.zip`);
  fs.mkdirSync(path.dirname(ZIP), { recursive: true });
  fs.rmSync(ZIP, { force: true });
  execFileSync('zip', ['-q', '-r', '-9', ZIP, path.basename(OUT)], { cwd: path.dirname(OUT) });
  console.log(`${path.relative(ROOT, ZIP)}: ${(fs.statSync(ZIP).size / 1048576).toFixed(1)} MB (index.pck ${(tam('index.pck') / 1048576).toFixed(1)} MB)`);
  // 1.6.0: el ligero, sin el motor ni el index.pck; el plugin los baja de GitHub en el servidor (Landrace_Hunters::fetch_game, el zip de arriba)
  const LIG = path.join(ROOT, 'descargas', `landrace-hunters-${V}-ligero.zip`);
  fs.rmSync(LIG, { force: true });
  execFileSync('zip', ['-q', '-r', '-9', LIG, path.basename(OUT), ...MOTOR_F.concat('index.pck').flatMap((f) => ['-x', `${path.basename(OUT)}/game/${f}`])], { cwd: path.dirname(OUT) });
  console.log(`${path.relative(ROOT, LIG)}: ${(fs.statSync(LIG).size / 1024).toFixed(0)} KB`);
}
fs.rmSync(PROY, { recursive: true, force: true });   // la copia del proyecto, 1,5 GB por exportación: sin borrarla, el disco se llena
console.log('plugin en ' + OUT);
