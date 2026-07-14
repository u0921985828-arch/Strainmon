/* BootScene: genera texturas pixel 16×16 (soft) por tipo de tile + actores.
   Placeholder procedural; sustituibles por load.image de un tileset real. */
SM.BootScene = class BootScene extends Phaser.Scene {
  constructor() { super('Boot'); }
  create() {
    const T = SM.TILE, PAL = SM.PAL;
    for (const name of Object.keys(PAL)) {
      if (name[0] === '_') continue;
      this.#tile('t_' + name, PAL[name]);
    }
    this.#actor('a_player', PAL._player);
    this.#actor('a_npc', PAL._npc);
    this.scene.start('World');
  }
  #shade(c, d) { const col = Phaser.Display.Color.IntegerToColor(c); return Phaser.Display.Color.GetColor(Phaser.Math.Clamp(col.red + d, 0, 255), Phaser.Math.Clamp(col.green + d, 0, 255), Phaser.Math.Clamp(col.blue + d, 0, 255)); }
  #tile(key, c) {
    const T = SM.TILE, g = this.make.graphics({ add: false });
    g.fillStyle(c).fillRect(0, 0, T, T);
    g.fillStyle(this.#shade(c, -12));
    g.fillRect(1, 1, 1, 1).fillRect(9, 5, 1, 1).fillRect(5, 11, 1, 1).fillRect(12, 9, 1, 1);
    g.fillStyle(this.#shade(c, 10)).fillRect(6, 3, 1, 1).fillRect(3, 8, 1, 1);
    g.generateTexture(key, T, T); g.destroy();
  }
  #actor(key, c) {
    const T = SM.TILE, g = this.make.graphics({ add: false });
    g.fillStyle(SM.PAL._ink).fillRect(3, 3, 10, 12);
    g.fillStyle(c).fillRect(4, 4, 8, 7);
    g.fillStyle(this.#shade(c, 18)).fillRect(5, 5, 3, 2);
    g.generateTexture(key, T, T); g.destroy();
  }
};
