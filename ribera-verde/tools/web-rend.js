// Landrace Hunters — la fluidez del juego web (lo pidió el usuario: «que no vaya petado… lo más fluido posible»): carga en Chromium
// (SwiftShader, sin tarjeta: el peor caso) el juego de `node tools/wordpress.js --sin-zip --salida <dir>` con "args": ["--", "--rend"]
// en su index.html, servido por `python3 -m http.server`, mide los fotogramas (rAF) y saca la consola: las líneas REND de juego.gd.
//   node tools/web-rend.js http://localhost:8769/game/index.html 40 web.png
const { chromium } = require('playwright');
(async () => {
  const url = process.argv[2], secs = +(process.argv[3] || 40);
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
  const p = await b.newPage({ viewport: { width: 960, height: 540 } });
  const log = [];
  p.on('console', (m) => log.push(m.type() + ': ' + m.text()));
  p.on('pageerror', (e) => log.push('pageerror: ' + e.message));
  await p.addInitScript(() => {
    window.__f = []; let t0 = performance.now();
    const raf = window.requestAnimationFrame.bind(window);
    window.requestAnimationFrame = (cb) => raf((t) => { window.__f.push(t); cb(t); });
  });
  const cdp = await p.context().newCDPSession(p);
  await cdp.send('Performance.enable');
  const met = async () => Object.fromEntries((await cdp.send('Performance.getMetrics')).metrics.map((m) => [m.name, m.value]));
  let m0 = null;
  await p.goto(url);
  const marks = [];
  for (let s = 0; s < secs; s += 5) {
    await p.waitForTimeout(5000);
    const f = await p.evaluate(() => { const a = window.__f; window.__f = []; return a; });
    const d = []; for (let i = 1; i < f.length; i++) d.push(f[i] - f[i - 1]);
    d.sort((a, b) => a - b);
    const m1 = await met();
    const busy = m0 ? `· script ${((m1.ScriptDuration - m0.ScriptDuration) / 5 * 100).toFixed(0)} % · tareas ${((m1.TaskDuration - m0.TaskDuration) / 5 * 100).toFixed(0)} %` : '';
    m0 = m1;
    marks.push(`${busy} ${s + 5}s: ${f.length / 5} fps (${f.length} cb), mediana ${d[d.length >> 1]?.toFixed(1)} ms, p95 ${d[Math.floor(d.length * .95)]?.toFixed(1)} ms`);
  }
  await p.screenshot({ path: process.argv[4] || 'web.png' });
  console.log(marks.join('\n'));
  console.log(log.filter((l) => !/^(log|info): .*(Godot Engine|OpenGL|^$)/.test(l)).slice(0, 40).join('\n'));
  await b.close();
})();
