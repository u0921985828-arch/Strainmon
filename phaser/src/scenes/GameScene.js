/* Mundo top-down ortogonal grid-based. Movimiento y cámara anclados a enteros
   (pixel-perfect). Lanza UIScene en paralelo. */
import Phaser from 'https://cdn.jsdelivr.net/npm/phaser@3.86.0/dist/phaser.esm.js';
import { BASE_W, BASE_H, PAL } from '../config.js';
import { applyWorldZoom } from '../scale.js';

const TILE = 16, MAP_W = 40, MAP_H = 30, SPEED = 60;

export default class GameScene extends Phaser.Scene {
  constructor() { super('Game'); }

  create() {
    // --- mapa placeholder (sustituir por this.make.tilemap({key:'map'})) ---
    this.add.tileSprite(0, 0, MAP_W * TILE, MAP_H * TILE, 't_grass').setOrigin(0);
    for (let x = 6; x < MAP_W - 6; x++) this.add.image(x * TILE, 14 * TILE, 't_path').setOrigin(0);

    // --- jugador (arcade, coordenadas enteras) ---
    this.player = this.physics.add.image(BASE_W / 2, BASE_H / 2, 'player');
    this.player.setCollideWorldBounds(true);
    this.physics.world.setBounds(0, 0, MAP_W * TILE, MAP_H * TILE);

    // --- cámara pixel-perfect, sigue al jugador, límites de mundo ---
    const cam = this.cameras.main;
    cam.setBounds(0, 0, MAP_W * TILE, MAP_H * TILE);
    cam.startFollow(this.player, true, 1, 1);   // sin lerp -> sin sub-pixel
    cam.roundPixels = true;

    this.keys = this.input.keyboard.addKeys('W,A,S,D,UP,DOWN,LEFT,RIGHT');

    // UI superpuesta como escena independiente.
    this.scene.launch('UI');

    // Escalado responsivo (zoom entero) inicial + en cada resize.
    this.scale.on('resize', () => applyWorldZoom(this));
    applyWorldZoom(this);
  }

  update() {
    const k = this.keys, b = this.player.body;
    let vx = 0, vy = 0;
    if (k.A.isDown || k.LEFT.isDown) vx = -SPEED; else if (k.D.isDown || k.RIGHT.isDown) vx = SPEED;
    if (k.W.isDown || k.UP.isDown) vy = -SPEED; else if (k.S.isDown || k.DOWN.isDown) vy = SPEED;
    b.setVelocity(vx, vy);
  }

  // Ancla el render a enteros: elimina sub-pixel del sprite.
  postUpdate() {
    this.player.x = Math.round(this.player.x);
    this.player.y = Math.round(this.player.y);
  }
}
