/* [BOOTSTRAP] Registra GameScene + UIScene y crea el juego. */
import { config } from './config.js';
import GameScene from './GameScene.js';
import UIScene from './UIScene.js';

config.scene = [GameScene, UIScene];
// eslint-disable-next-line no-new
new Phaser.Game(config);
