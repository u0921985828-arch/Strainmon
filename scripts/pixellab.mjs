#!/usr/bin/env node
/* ============================================================
   Strainmon — cliente Pixel Lab (API v1), sin dependencias.

   Endpoints cubiertos (https://api.pixellab.ai/v1):
     POST /generate-image-pixflux    texto -> pixel art
     POST /generate-image-bitforge   texto + imagen de estilo -> pixel art coherente
     POST /rotate                    gira un sprite a otra dirección/vista
     POST /inpaint                   repinta una zona (máscara)
     GET  /balance                   saldo en USD

   La key se lee SOLO de .secrets/pixellab.key o de PIXELLAB_API_KEY /
   PIXELLAB_SECRET. Nunca se imprime ni se escribe en ningún artefacto.

   Caché en disco: cada petición se indexa por SHA-1 del cuerpo, así repetir
   una tanda no vuelve a gastar créditos. Borra .cache/pixellab para regenerar.

   Uso directo (diagnóstico):  node scripts/pixellab.mjs balance
   ============================================================ */
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

export const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
export const CACHE_DIR = path.join(ROOT, '.cache', 'pixellab');

// ---- vocabulario cerrado de la API (validar antes de gastar créditos) ----
export const VIEWS = ['side', 'low top-down', 'high top-down'];
export const DIRECTIONS = ['south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west'];
export const OUTLINES = ['single color black outline', 'single color outline', 'selective outline', 'lineless'];
export const SHADINGS = ['flat shading', 'basic shading', 'medium shading', 'detailed shading', 'highly detailed shading'];
export const DETAILS = ['low detail', 'medium detail', 'highly detailed'];
// Límite del modelo: el área del lienzo no puede pasar de 400x400.
export const MAX_AREA = 400 * 400;

const BASE_URL = (process.env.PIXELLAB_BASE_URL || 'https://api.pixellab.ai/v1').replace(/\/$/, '');

export function loadKey({ required = true } = {}) {
  const env = process.env.PIXELLAB_API_KEY || process.env.PIXELLAB_SECRET;
  if (env && env.trim()) return env.trim();
  const f = path.join(ROOT, '.secrets', 'pixellab.key');
  if (fs.existsSync(f)) {
    const k = fs.readFileSync(f, 'utf8').trim();
    if (k) return k;
  }
  if (!required) return null;
  console.error('❌ No hay key de Pixel Lab. Crea .secrets/pixellab.key o exporta PIXELLAB_API_KEY.');
  process.exit(1);
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const enumCheck = (name, value, list) => {
  if (value == null) return undefined;
  if (!list.includes(value)) throw new Error(`${name} inválido: "${value}". Válidos: ${list.join(' | ')}`);
  return value;
};
const num = (v, lo, hi, def) => {
  if (v == null) return def;
  const n = Number(v);
  if (!Number.isFinite(n) || n < lo || n > hi) throw new Error(`valor fuera de rango [${lo}, ${hi}]: ${v}`);
  return n;
};
/** Buffer PNG -> objeto imagen del protocolo ({type,base64,format}). */
export const toImage = (buf, format = 'png') =>
  (buf == null ? null : (Buffer.isBuffer(buf) ? { type: 'base64', base64: buf.toString('base64'), format } : buf));

function checkSize(size) {
  const w = Math.round(size?.width), h = Math.round(size?.height);
  if (!w || !h || w < 8 || h < 8) throw new Error('image_size inválido: ' + JSON.stringify(size));
  if (w * h > MAX_AREA) throw new Error(`lienzo demasiado grande (${w}x${h}); el máximo es un área de 400x400`);
  return { width: w, height: h };
}

export class PixelLab {
  /**
   * @param {object} [opt]
   * @param {string} [opt.key]      key explícita (por defecto, .secrets/pixellab.key o env)
   * @param {string} [opt.baseUrl]  URL base (por defecto https://api.pixellab.ai/v1)
   * @param {boolean} [opt.cache]   usar caché en disco (por defecto true)
   * @param {boolean} [opt.force]   ignorar la caché y volver a pedir
   * @param {boolean} [opt.dry]     no llamar a la red; lanza si algo intenta salir
   */
  constructor(opt = {}) {
    this.key = opt.key || loadKey({ required: !opt.dry });
    this.baseUrl = (opt.baseUrl || BASE_URL).replace(/\/$/, '');
    this.useCache = opt.cache !== false;
    this.force = !!opt.force;
    this.dry = !!opt.dry;
    this.retries = opt.retries ?? 4;
    this.usd = 0;          // coste acumulado de esta sesión
    this.calls = 0;        // peticiones que sí salieron a la red
    this.cached = 0;       // peticiones servidas desde caché
  }

  headers() { return { Authorization: `Bearer ${this.key}`, 'Content-Type': 'application/json' }; }

  cachePath(endpoint, body) {
    const h = crypto.createHash('sha1').update(endpoint + '\n' + JSON.stringify(body)).digest('hex');
    return path.join(CACHE_DIR, `${endpoint.replace(/[^a-z0-9-]/gi, '')}-${h}.json`);
  }

  /** POST con reintentos exponenciales (2s, 4s, 8s, 16s) en 429/5xx y errores de red. */
  async post(endpoint, body) {
    const cacheFile = this.cachePath(endpoint, body);
    if (this.useCache && !this.force && fs.existsSync(cacheFile)) {
      this.cached++;
      return JSON.parse(fs.readFileSync(cacheFile, 'utf8'));
    }
    if (this.dry) throw new Error(`[dry] se habría llamado a ${endpoint}`);

    let wait = 2000, lastErr = null;
    for (let attempt = 0; attempt <= this.retries; attempt++) {
      try {
        const r = await fetch(`${this.baseUrl}${endpoint}`, {
          method: 'POST', headers: this.headers(), body: JSON.stringify(body),
        });
        if (r.status === 401) throw Object.assign(new Error('key rechazada (401)'), { fatal: true });
        if (r.status === 422) {
          const t = await r.text();
          throw Object.assign(new Error('petición inválida (422): ' + t.slice(0, 300)), { fatal: true });
        }
        if (r.status === 429 || r.status >= 500) throw new Error(`HTTP ${r.status}`);
        if (!r.ok) {
          const t = await r.text();
          throw Object.assign(new Error(`HTTP ${r.status}: ${t.slice(0, 200)}`), { fatal: true });
        }
        const json = await r.json();
        this.calls++;
        if (typeof json?.usage?.usd === 'number') this.usd += json.usage.usd;
        if (this.useCache) {
          fs.mkdirSync(CACHE_DIR, { recursive: true });
          fs.writeFileSync(cacheFile, JSON.stringify(json));
        }
        return json;
      } catch (e) {
        lastErr = e;
        if (e.fatal || attempt === this.retries) break;
        await sleep(wait); wait *= 2;
      }
    }
    throw lastErr;
  }

  async balance() {
    if (this.dry) return { type: 'usd', usd: 0 };
    const r = await fetch(`${this.baseUrl}/balance`, { headers: { Authorization: `Bearer ${this.key}` } });
    if (!r.ok) throw new Error('balance HTTP ' + r.status);
    return r.json();
  }

  /** Campos comunes de estilo (los comparten pixflux, bitforge e inpaint). */
  styleFields(p) {
    return {
      outline: enumCheck('outline', p.outline, OUTLINES),
      shading: enumCheck('shading', p.shading, SHADINGS),
      detail: enumCheck('detail', p.detail, DETAILS),
      view: enumCheck('view', p.view, VIEWS),
      direction: enumCheck('direction', p.direction, DIRECTIONS),
      isometric: !!p.isometric,
      no_background: p.noBackground !== false,
      coverage_percentage: p.coveragePercentage == null ? undefined : num(p.coveragePercentage, 0, 100),
    };
  }

  /** POST /generate-image-pixflux — generación desde texto puro. */
  async pixflux(p) {
    const body = {
      description: p.description,
      image_size: checkSize(p.imageSize),
      negative_description: p.negativeDescription || '',
      text_guidance_scale: num(p.textGuidanceScale, 1, 20, 8),
      ...this.styleFields(p),
      init_image: toImage(p.initImage),
      init_image_strength: num(p.initImageStrength, 0, 1000, 300),
      color_image: toImage(p.colorImage),
      seed: p.seed ?? 0,
    };
    const j = await this.post('/generate-image-pixflux', body);
    return { buf: Buffer.from(j.image.base64, 'base64'), usd: j.usage?.usd ?? 0 };
  }

  /** POST /generate-image-bitforge — texto + imagen de estilo (coherencia de set). */
  async bitforge(p) {
    const body = {
      description: p.description,
      image_size: checkSize(p.imageSize),
      negative_description: p.negativeDescription || '',
      text_guidance_scale: num(p.textGuidanceScale, 1, 20, 3),
      extra_guidance_scale: num(p.extraGuidanceScale, 0, 20, 3),
      style_strength: num(p.styleStrength, 0, 100, 0),
      ...this.styleFields(p),
      oblique_projection: !!p.obliqueProjection,
      init_image: toImage(p.initImage),
      init_image_strength: num(p.initImageStrength, 0, 1000, 300),
      style_image: toImage(p.styleImage),
      inpainting_image: toImage(p.inpaintingImage),
      mask_image: toImage(p.maskImage),
      color_image: toImage(p.colorImage),
      skeleton_keypoints: p.skeletonKeypoints || null,
      skeleton_guidance_scale: num(p.skeletonGuidanceScale, 0, 20, 1),
      seed: p.seed ?? 0,
    };
    const j = await this.post('/generate-image-bitforge', body);
    return { buf: Buffer.from(j.image.base64, 'base64'), usd: j.usage?.usd ?? 0 };
  }

  /** POST /rotate — misma pieza vista desde otra dirección/altura de cámara. */
  async rotate(p) {
    const body = {
      image_size: checkSize(p.imageSize),
      image_guidance_scale: num(p.imageGuidanceScale, 1, 20, 3),
      from_view: enumCheck('from_view', p.fromView, VIEWS),
      to_view: enumCheck('to_view', p.toView, VIEWS),
      from_direction: enumCheck('from_direction', p.fromDirection, DIRECTIONS),
      to_direction: enumCheck('to_direction', p.toDirection, DIRECTIONS),
      view_change: p.viewChange,
      direction_change: p.directionChange,
      isometric: !!p.isometric,
      oblique_projection: !!p.obliqueProjection,
      init_image: toImage(p.initImage),
      init_image_strength: num(p.initImageStrength, 0, 1000, 300),
      mask_image: toImage(p.maskImage),
      from_image: toImage(p.fromImage),
      color_image: toImage(p.colorImage),
      seed: p.seed ?? 0,
    };
    const j = await this.post('/rotate', body);
    return { buf: Buffer.from(j.image.base64, 'base64'), usd: j.usage?.usd ?? 0 };
  }

  /** POST /inpaint — repinta la zona blanca de la máscara (variantes de una pieza). */
  async inpaint(p) {
    const body = {
      description: p.description,
      image_size: checkSize(p.imageSize),
      negative_description: p.negativeDescription || '',
      text_guidance_scale: num(p.textGuidanceScale, 1, 20, 3),
      extra_guidance_scale: num(p.extraGuidanceScale, 0, 20, 3),
      ...this.styleFields(p),
      oblique_projection: !!p.obliqueProjection,
      init_image: toImage(p.initImage),
      init_image_strength: num(p.initImageStrength, 0, 1000, 300),
      inpainting_image: toImage(p.inpaintingImage),
      mask_image: toImage(p.maskImage),
      color_image: toImage(p.colorImage),
      seed: p.seed ?? 0,
    };
    const j = await this.post('/inpaint', body);
    return { buf: Buffer.from(j.image.base64, 'base64'), usd: j.usage?.usd ?? 0 };
  }
}

// ---- CLI de diagnóstico ----
if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname)) {
  const cmd = process.argv[2] || 'balance';
  const cli = new PixelLab();
  if (cmd === 'balance') {
    try {
      const b = await cli.balance();
      console.log(`✅ Key válida. Saldo: $${b.usd.toFixed(3)}`);
    } catch (e) { console.error('❌', e.message); process.exit(1); }
  } else {
    console.log('Uso: node scripts/pixellab.mjs balance');
  }
}
