/* [UI] UIScene — overlay independiente. Cámara a resolución de VIEWPORT (texto
   nítido). Elementos anclados dinámicamente a los bordes; paneles complejos en
   DOM híbrido (CSS Grid). Fuente bitmap para conservar la estética pixel. */
/* Phaser global (UMD, cargado antes del módulo). */
import { PAL } from './config.js';

export default class UIScene extends Phaser.Scene {
  constructor() { super({ key: 'UI', active: false }); }

  preload() {
    // Fuente bitmap real: this.load.bitmapFont('px','font.png','font.fnt');
  }

  create() {
    this.anchors = [];

    // HUD nativo anclado (arriba-izq). Con bitmap font: this.add.bitmapText(...).
    const hud = this.add.text(6, 6, 'HP 100  ₡ 300', { fontFamily: 'monospace', fontSize: '10px', color: PAL.ink }).setScrollFactor(0);
    this.anchor(hud, () => hud.setPosition(6, 6));

    // Panel modular DOM híbrido (CSS Grid) anclado abajo-centro, responsivo.
    this.panel = this.add.dom(0, 0).createFromHTML(`
      <div class="ui-panel" data-open="true">
        <header>INVENTARIO</header>
        <div class="ui-grid">${'<div class="cell"></div>'.repeat(12)}</div>
      </div>`).setScrollFactor(0).setOrigin(0.5, 1);
    this.anchor(this.panel, (w, h) => this.panel.setPosition(Math.round(w / 2), h - 4));

    this.scale.on('resize', (gs) => this.reflow(gs.width, gs.height));
    this.reflow(this.scale.width, this.scale.height);
  }

  anchor(obj, fn) { this.anchors.push({ obj, fn }); }
  reflow(w, h) {
    this.cameras.main.setViewport(0, 0, w, h);   // UI a resolución de pantalla
    for (const a of this.anchors) a.fn(w, h);
  }
}
