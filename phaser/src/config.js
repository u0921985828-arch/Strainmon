/* Config Phaser — pixel-perfect + escalado responsivo. */
import Phaser from 'https://cdn.jsdelivr.net/npm/phaser@3.86.0/dist/phaser.esm.js';
import BootScene from './scenes/BootScene.js';
import GameScene from './scenes/GameScene.js';
import UIScene from './scenes/UIScene.js';

// Resolución base protegida (escalada por enteros).
export const BASE_W = 320;
export const BASE_H = 240;

// Paleta soft (pastel desaturado). Sin primarios puros.
export const PAL = {
  bg: '#aeb9a0', grass: '#b9c9a3', grassAlt: '#a7ba90', path: '#d8cdb0',
  water: '#a9c7cf', ink: '#3b3a4a', ui: '#efeadd', uiEdge: '#8f8a7a', accent: '#c98a86',
};

export const config = {
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: PAL.bg,
  pixelArt: true,
  antialias: false,
  roundPixels: true,
  render: { pixelArt: true, antialias: false, roundPixels: true, powerPreference: 'low-power' },
  dom: { createContainer: true },      // maquetado DOM híbrido (CSS Grid sobre canvas)
  scale: {
    mode: Phaser.Scale.RESIZE,         // canvas = viewport; el zoom entero lo fija scale.js
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: BASE_W, height: BASE_H,
  },
  physics: { default: 'arcade', arcade: { debug: false, tileBias: 8 } },
  scene: [BootScene, GameScene, UIScene],
};
