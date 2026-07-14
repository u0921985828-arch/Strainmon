/* [ENGINE] Config base Phaser — pixel-perfect + escalado responsivo.
   Resolución base protegida por zoom entero (ver GameScene.applyIntegerZoom). */
export const BASE_W = 320, BASE_H = 240, TILE = 16;
export const PAL = {           // paleta soft (pastel desaturado, sin primarios puros)
  bg: '#aeb9a0', floor: '#b9c9a3', floorAlt: '#a7ba90', path: '#d8cdb0',
  water: '#a9c7cf', wall: '#8f9a80', ink: '#3b3a4a', ui: '#efeadd', edge: '#8f8a7a', accent: '#c98a86',
};

export const config = {
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: PAL.bg,
  pixelArt: true,            // nearest-neighbor
  antialias: false,
  roundPixels: true,         // sin sub-pixel
  render: { pixelArt: true, antialias: false, roundPixels: true, powerPreference: 'low-power' },
  dom: { createContainer: true },   // DOM híbrido: paneles HTML/CSS Grid sobre el canvas
  scale: {
    mode: Phaser.Scale.RESIZE,      // canvas = viewport; el zoom entero fija la base
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: BASE_W, height: BASE_H,
  },
  physics: { default: 'arcade', arcade: { debug: false, tileBias: 8 } },
  // GameScene (mundo) + UIScene (overlay). Se inyectan en el bootstrap.
  scene: [],
};

// Zoom entero máximo que cabe (>=1). Protege el pixel-perfect en cualquier aspecto.
export const integerZoom = (vw, vh) => Math.max(1, Math.floor(Math.min(vw / BASE_W, vh / BASE_H)));
