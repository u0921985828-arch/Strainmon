/* [ENGINE] GameScene — mundo top-down ortogonal grid-based. Cámara y sprites
   anclados a enteros (Math.round). Lanza la UIScene en paralelo. */
/* Phaser global (UMD, cargado antes del módulo). */
import { BASE_W, BASE_H, TILE, PAL, integerZoom } from './config.js';

const MAP_W = 40, MAP_H = 30, SPEED = 60;

export default class GameScene extends Phaser.Scene {
  constructor() { super('Game'); }

  preload() {
    // Real: this.load.image('tiles',...); this.load.tilemapTiledJSON('map',...)
    this.#solid('t_floor', PAL.floor); this.#solid('t_floorAlt', PAL.floorAlt);
    this.#solid('t_path', PAL.path); this.#solid('t_wall', PAL.wall);
    this.#actor('player', PAL.accent);
  }

  create() {
    // suelo (tileSprite) + detalle
    this.add.tileSprite(0, 0, MAP_W * TILE, MAP_H * TILE, 't_floor').setOrigin(0);
    for (let x = 4; x < MAP_W - 4; x++) this.add.image(x * TILE, 15 * TILE, 't_path').setOrigin(0);

    // jugador (arcade, integer-anclado)
    this.player = this.physics.add.image(BASE_W / 2, BASE_H / 2, 'player').setCollideWorldBounds(true);
    this.physics.world.setBounds(0, 0, MAP_W * TILE, MAP_H * TILE);

    // cámara pixel-perfect (sin lerp = sin sub-pixel)
    const cam = this.cameras.main;
    cam.setBounds(0, 0, MAP_W * TILE, MAP_H * TILE);
    cam.startFollow(this.player, true, 1, 1);
    cam.roundPixels = true;

    this.keys = this.input.keyboard.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT');
    this.scene.launch('UI');                       // UIScene superpuesta

    this.applyIntegerZoom();
    this.scale.on('resize', () => this.applyIntegerZoom());
  }

  applyIntegerZoom() {
    const z = integerZoom(this.scale.width, this.scale.height);
    this.cameras.main.setZoom(z);
  }

  update() {
    const k = this.keys, b = this.player.body; let vx = 0, vy = 0;
    if (k.A.isDown || k.LEFT.isDown) vx = -SPEED; else if (k.D.isDown || k.RIGHT.isDown) vx = SPEED;
    if (k.W.isDown || k.UP.isDown) vy = -SPEED; else if (k.S.isDown || k.DOWN.isDown) vy = SPEED;
    b.setVelocity(vx, vy);
  }

  // ancla a enteros el sprite tras la física
  postUpdate() { this.player.x = Math.round(this.player.x); this.player.y = Math.round(this.player.y); }

  #solid(key, c) {
    const g = this.make.graphics({ add: false });
    g.fillStyle(Phaser.Display.Color.HexStringToColor(c).color).fillRect(0, 0, TILE, TILE);
    g.generateTexture(key, TILE, TILE); g.destroy();
  }
  #actor(key, c) {
    const g = this.make.graphics({ add: false });
    g.fillStyle(Phaser.Display.Color.HexStringToColor(PAL.ink).color).fillRect(3, 3, 10, 12);
    g.fillStyle(Phaser.Display.Color.HexStringToColor(c).color).fillRect(4, 4, 8, 7);
    g.generateTexture(key, TILE, TILE); g.destroy();
  }
}
