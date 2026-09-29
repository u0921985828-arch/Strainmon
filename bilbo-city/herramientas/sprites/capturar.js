// Fotografía una tanda de SVG con Chromium y la devuelve en base64 por la salida estándar.
//
// Una sola página y una sola foto: los SVG se colocan en rejilla, pegados y sin margen, y
// quien recorta es Python. Abrir el navegador una vez por celda tardaba medio minuto para
// las 55; así son dos segundos.
//
// `deviceScaleFactor: 1` y los SVG ya dibujados a su tamaño final: si se dejara escalar al
// navegador, el reescalado suavizaría los bordes y la reducción por mayoría dejaría de ser
// una cuenta exacta.
'use strict';
const fs = require('fs');
const { chromium } = require('../html/node_modules/playwright');

// El Chromium del contenedor y el que espera esta versión de Playwright no siempre llevan
// el mismo número de compilación, y entonces `launch()` manda a bajar uno que no hace
// falta. Si hay uno instalado en PLAYWRIGHT_BROWSERS_PATH, se usa ése y en paz.
function chromiumDelSistema() {
  const raiz = process.env.PLAYWRIGHT_BROWSERS_PATH || '/opt/pw-browsers';
  if (!fs.existsSync(raiz)) return undefined;
  for (const dir of fs.readdirSync(raiz).filter(d => d.startsWith('chromium')).sort()) {
    for (const cola of ['chrome-linux/chrome', 'chrome-headless-shell-linux64/chrome-headless-shell']) {
      const ruta = `${raiz}/${dir}/${cola}`;
      if (fs.existsSync(ruta)) return ruta;
    }
  }
  return undefined;
}

let crudo = '';
process.stdin.on('data', t => (crudo += t));
process.stdin.on('end', async () => {
  const { ancho, alto, columnas, svg } = JSON.parse(crudo);
  const filas = Math.ceil(svg.length / columnas);
  const html = `<!doctype html><meta charset="utf-8"><style>
    html,body{margin:0;padding:0;background:#000;image-rendering:pixelated}
    #r{display:grid;grid-template-columns:repeat(${columnas},${ancho}px);
       width:${columnas * ancho}px;line-height:0;font-size:0}
    #r>div{width:${ancho}px;height:${alto}px}
  </style><div id="r">${svg.map(s => `<div>${s}</div>`).join('')}</div>`;

  const nav = await chromium.launch({ executablePath: chromiumDelSistema(),
                                      args: ['--force-color-profile=srgb',
                                             '--disable-lcd-text'] });
  const pag = await nav.newPage({ viewport: { width: columnas * ancho,
                                              height: filas * alto },
                                  deviceScaleFactor: 1 });
  await pag.setContent(html, { waitUntil: 'load' });
  const foto = await pag.locator('#r').screenshot({ type: 'png' });
  await nav.close();
  process.stdout.write(foto.toString('base64'));
});
