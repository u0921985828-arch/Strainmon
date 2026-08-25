#!/usr/bin/env node
/* ============================================================
   Strainmon — servidor de pruebas que imita la API de Pixel Lab.

   Sirve los mismos endpoints con formas de color deterministas en lugar de
   pixel art de verdad. Vale para probar la cadena completa (gen-kit →
   pack-kit → kit-export → kit-lab) sin key y sin gastar créditos.

   Uso:
     node scripts/kit-mock-server.mjs 8787 &
     PIXELLAB_BASE_URL=http://127.0.0.1:8787/v1 PIXELLAB_API_KEY=test \
       node scripts/gen-kit.mjs character --yes
   ============================================================ */
import http from 'node:http';
import crypto from 'node:crypto';
import sharp from 'sharp';

const PORT = parseInt(process.argv[2] || '8787', 10);

function hash(s) { return crypto.createHash('sha1').update(String(s)).digest(); }

/** Silueta plana y determinista a partir del texto del prompt. */
async function fakeSprite(desc, size, seed) {
  const h = hash(desc + '|' + seed);
  const W = Math.max(8, size?.width || 64), H = Math.max(8, size?.height || 64);
  const hue = h[0] * 360 / 255, kind = h[1] % 3;
  const color = `hsl(${hue.toFixed(0)} 55% ${35 + (h[2] % 30)}%)`;
  const line = `hsl(${hue.toFixed(0)} 60% 12%)`;
  const m = Math.max(2, Math.round(Math.min(W, H) * 0.12));
  const shape = kind === 0
    ? `<rect x="${m}" y="${m}" width="${W - m * 2}" height="${H - m * 2}" rx="${m}" fill="${color}" stroke="${line}" stroke-width="1"/>`
    : kind === 1
      ? `<ellipse cx="${W / 2}" cy="${H / 2}" rx="${(W - m * 2) / 2}" ry="${(H - m * 2) / 2}" fill="${color}" stroke="${line}" stroke-width="1"/>`
      : `<polygon points="${W / 2},${m} ${W - m},${H - m} ${m},${H - m}" fill="${color}" stroke="${line}" stroke-width="1"/>`;
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}">${shape}</svg>`;
  return sharp(Buffer.from(svg)).png().toBuffer();
}

const server = http.createServer((req, res) => {
  const send = (code, obj) => { res.writeHead(code, { 'Content-Type': 'application/json' }); res.end(JSON.stringify(obj)); };
  if (!/^Bearer .+/.test(req.headers.authorization || '')) return send(401, { detail: 'missing key' });
  if (req.method === 'GET' && req.url.endsWith('/balance')) return send(200, { type: 'usd', usd: 42 });

  let body = '';
  req.on('data', c => body += c);
  req.on('end', async () => {
    let p = {};
    try { p = JSON.parse(body || '{}'); } catch { return send(422, { detail: 'bad json' }); }
    const known = ['/generate-image-pixflux', '/generate-image-bitforge', '/rotate', '/inpaint'];
    const route = known.find(k => req.url.endsWith(k));
    if (!route) return send(404, { detail: 'unknown endpoint ' + req.url });
    const desc = p.description || (p.from_image ? 'rotate:' + (p.to_direction || '') + (p.from_image.base64 || '').slice(0, 32) : 'x');
    const buf = await fakeSprite(desc, p.image_size, p.seed || 0);
    send(200, { image: { type: 'base64', base64: buf.toString('base64'), format: 'png' }, usage: { type: 'usd', usd: 0.01 } });
  });
});
server.listen(PORT, '127.0.0.1', () => console.log(`🧪 mock Pixel Lab en http://127.0.0.1:${PORT}/v1`));
