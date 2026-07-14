/* Carga mínima + genera un tileset/atlas soft procedural (placeholder) para no
   depender de assets externos. Sustituir make* por load.image/load.tilemap. */
import Phaser from 'https://cdn.jsdelivr.net/npm/phaser@3.86.0/dist/phaser.esm.js';
import { PAL } from '../config.js';

export default class BootScene extends Phaser.Scene {
  constructor() { super('Boot'); }

  preload() {
    // Fuente bitmap y assets reales irían aquí:
    // this.load.bitmapFont('px', 'assets/font.png', 'assets/font.fnt');
    // this.load.image('tiles', 'assets/tiles.png');
    // this.load.tilemapTiledJSON('map', 'assets/map.json');
    this.#tile('t_grass', PAL.grass, PAL.grassAlt);
    this.#tile('t_path', PAL.path, PAL.grassAlt);
    this.#tile('t_water', PAL.water, PAL.grass);
    this.#actor('player', PAL.accent, PAL.ink);
  }

  create() { this.scene.start('Game'); }

  // --- placeholders 16×16 pixel-perfect ---
  #tile(key, a, b) {
    const g = this.make.graphics({ x: 0, y: 0, add: false });
    g.fillStyle(Phaser.Display.Color.HexStringToColor(a).color).fillRect(0, 0, 16, 16);
    g.fillStyle(Phaser.Display.Color.HexStringToColor(b).color);
    g.fillRect(0, 0, 1, 1).fillRect(8, 8, 1, 1).fillRect(4, 12, 1, 1);
    g.generateTexture(key, 16, 16); g.destroy();
  }
  #actor(key, a, b) {
    const g = this.make.graphics({ x: 0, y: 0, add: false });
    g.fillStyle(Phaser.Display.Color.HexStringToColor(b).color).fillRect(3, 2, 10, 12);
    g.fillStyle(Phaser.Display.Color.HexStringToColor(a).color).fillRect(4, 3, 8, 6);
    g.generateTexture(key, 16, 16); g.destroy();
  }
}
