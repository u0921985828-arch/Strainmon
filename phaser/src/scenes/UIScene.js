/* UI superpuesta. Cámara a resolución de VIEWPORT (no del mundo) para nitidez
   del texto/bitmap. Elementos anclados dinámicamente a los bordes. Paneles
   complejos vía DOM híbrido (HTML/CSS Grid) sobre el canvas. */
import Phaser from 'https://cdn.jsdelivr.net/npm/phaser@3.86.0/dist/phaser.esm.js';
import { PAL } from '../config.js';

export default class UIScene extends Phaser.Scene {
  constructor() { super({ key: 'UI', active: false }); }

  create() {
    this.anchors = [];

    // HUD nativo (barra superior) anclado arriba-izquierda.
    this.hud = this.add.text(4, 4, 'STRAINMON', {
      fontFamily: 'monospace', fontSize: '10px', color: PAL.ink,
    }).setScrollFactor(0);
    this.anchor(this.hud, (w, h, o) => o.setPosition(6, 6));

    // Panel modular DOM híbrido (CSS Grid), anclado abajo, responsivo.
    this.panel = this.add.dom(0, 0).createFromHTML(`
      <div class="ui-panel" data-open="false">
        <header>BANCO DE CEPAS</header>
        <div class="ui-grid" id="ui-grid"></div>
      </div>`).setScrollFactor(0).setOrigin(0.5, 1);
    this.anchor(this.panel, (w, h) => this.panel.setPosition(Math.round(w / 2), h - 4));

    // Reposiciona todo en cada resize (móvil/escritorio).
    this.scale.on('resize', (gs) => this.reflow(gs.width, gs.height));
    this.reflow(this.scale.width, this.scale.height);
  }

  anchor(obj, fn) { this.anchors.push({ obj, fn }); }
  reflow(w, h) {
    this.cameras.main.setViewport(0, 0, w, h);   // UI a resolución de pantalla
    for (const a of this.anchors) a.fn(w, h, a.obj);
  }

  togglePanel() { const el = this.panel.node.firstElementChild; el.dataset.open = el.dataset.open !== 'true'; }
}
