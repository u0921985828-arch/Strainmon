/* Config Phaser (script clásico; Phaser global desde vendor). Pixel-perfect +
   escalado responsivo. Reutiliza toda la lógica PH.* del juego vanilla. */
window.SM = window.SM || {};
SM.BASE_W = 320; SM.BASE_H = 240; SM.TILE = 16;

// Paleta soft (pastel desaturado) por nombre de tile de PH.world.TILES.
SM.PAL = {
  grass: 0xb9c9a3, tallgrass: 0xa7ba90, tree: 0x7f9a6f, rock: 0xb9b3a8,
  water: 0xa9c7cf, deepwater: 0x8fb2bd, path: 0xd8cdb0, house: 0xc9b79a,
  door: 0x9a6a4a, flowers: 0xcdbad9, bush: 0x93ad84, sand: 0xe2d7b0,
  mud: 0xa89a7a, snow: 0xe6ecec, cavefloor: 0x9a94a0, bridge: 0xc2a878,
  lava: 0xd29a86, ash: 0xb0a49c, ice: 0xcfe0e6, stalag: 0x8a84a0, palm: 0x7fa07a,
  _bg: 0xaeb9a0, _player: 0xc98a86, _npc: 0xb0a0c8, _ink: 0x3b3a4a,
};

SM.config = {
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: SM.PAL._bg,
  pixelArt: true, antialias: false, roundPixels: true,
  render: { pixelArt: true, antialias: false, roundPixels: true, powerPreference: 'low-power' },
  dom: { createContainer: false },
  scale: { mode: Phaser.Scale.RESIZE, autoCenter: Phaser.Scale.CENTER_BOTH, width: SM.BASE_W, height: SM.BASE_H },
  scene: [],   // se añaden en main.js
};
