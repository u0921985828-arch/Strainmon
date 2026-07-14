/* Escalado responsivo por ZOOM ENTERO sobre RESIZE: protege la resolución base
   (pixel-perfect) y adapta el viewport en móvil y escritorio. */
import { BASE_W, BASE_H } from './config.js';

// Zoom entero máximo que cabe; >=1. Llamar en resize.
export function integerZoom(vw, vh) {
  return Math.max(1, Math.floor(Math.min(vw / BASE_W, vh / BASE_H)));
}

// Aplica el zoom a la cámara de una escena de mundo y recorta su viewport al
// área base * zoom, centrada. Devuelve {zoom,w,h,ox,oy}.
export function applyWorldZoom(scene) {
  const { width: vw, height: vh } = scene.scale.gameSize;
  const z = integerZoom(vw, vh);
  const w = BASE_W * z, h = BASE_H * z;
  const ox = Math.round((vw - w) / 2), oy = Math.round((vh - h) / 2);
  const cam = scene.cameras.main;
  cam.setViewport(ox, oy, w, h);
  cam.setZoom(z);
  cam.roundPixels = true;
  return { zoom: z, w, h, ox, oy, vw, vh };
}
