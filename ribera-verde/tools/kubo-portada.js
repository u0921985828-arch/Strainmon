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
    await p.waitForTimeout(800);
    await p.screenshot({ path: `${out}-${n}.png`, fullPage: true });
    console.log(`${out}-${n}.png`);
    await p.close();
  }
  await b.close();
})();
