/* Arranque: registra escenas y crea el juego. */
SM.config.scene = [SM.BootScene, SM.WorldScene];
new Phaser.Game(SM.config);
