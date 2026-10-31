// Landrace Hunters — mirar la portada de Kuboplay Web: abre el HTML de tools/kubo-portada.php en Chromium
// y guarda la captura entera, en móvil y en ordenador.
//   node tools/kubo-portada.js <portada.html> <salida-sin-extension>
const { chromium } = require('playwright');
(async () => {
  const [html, out] = process.argv.slice(2);
  const exe = process.env.CHROMIUM_PATH || '';
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'], ...(exe ? { executablePath: exe } : {}) });
  for (const [n, v] of [['movil', { width: 390, height: 844 }], ['pc', { width: 1200, height: 900 }]]) {
    const p = await b.newPage({ viewport: v, deviceScaleFactor: 2 });
    await p.goto('file://' + html);
    await p.waitForTimeout(400);
    // acepta las cookies: los anuncios viven en <template> y solo se cargan con permiso
    const ok = await p.$('#kpw-ck .ok');
    if (ok) { await ok.click(); await p.waitForTimeout(500); }
    await p.waitForTimeout(400);
    const mal = await p.evaluate(() => {
      const d = document.documentElement, out = [];
      if (d.scrollWidth > d.clientWidth + 1) out.push(`scroll horizontal: ${d.scrollWidth} > ${d.clientWidth}`);
      document.querySelectorAll('header,main,aside,footer,section,ul,li,p,img,a,div').forEach((e) => {
        const r = e.getBoundingClientRect();
        if (r.width && (r.right > d.clientWidth + 1 || r.left < -1)) {
          out.push(`${e.tagName.toLowerCase()}.${e.className || ''} de ${Math.round(r.left)} a ${Math.round(r.right)}`);
        }
      });
      return out.slice(0, 6);
    });
    if (mal.length) { console.log(`  ${n}: ` + mal.join(' · ')); process.exitCode = 1; }
    await p.screenshot({ path: `${out}-${n}.png`, fullPage: true });
    console.log(`${out}-${n}.png`);
    await p.close();
  }
  await b.close();
})();
