/* ============================================================
   PHENO HUNTER — quests.js
   Misiones, diálogos de NPC y lógica de progreso.
   ============================================================ */
(function (PH) {
  'use strict';

  // Definición de misiones. check(state) -> bool completada.
  const QUESTS = {
    q_intro: {
      id: 'q_intro', name: 'Primeros brotes',
      desc: 'Recolecta tu primera variedad en la Pradera de Auralia.',
      reward: { credits: 150, prestige: 5, tool: 'tijeras' },
      check: (s) => s.stats.discoveries >= 1,
    },
    q_collector: {
      id: 'q_collector', name: 'El ojo del coleccionista',
      desc: 'Registra 5 variedades distintas en el catálogo mundial.',
      reward: { credits: 400, prestige: 8, gear: 'lupa' },
      check: (s) => Object.keys(s.catalog).length >= 5,
    },
    q_breeder: {
      id: 'q_breeder', name: 'La chispa del criador',
      desc: 'Realiza tu primer cruce genético en el laboratorio.',
      reward: { credits: 300, prestige: 6, tool: 'kitclon' },
      check: (s) => s.stats.crosses >= 1,
    },
    q_mutation: {
      id: 'q_mutation', name: 'Anomalía prometedora',
      desc: 'Documenta una variedad con al menos una mutación.',
      reward: { credits: 800, prestige: 15, gear: 'medidor' },
      check: (s) => s.stats.mutationsFound >= 1,
    },
    q_relic: {
      id: 'q_relic', name: 'La reliquia dorada',
      desc: 'Encuentra la mítica Aurífera (PH-007).',
      reward: { credits: 3000, prestige: 40 },
      check: (s) => (s.species['PH-007'] && s.species['PH-007'].obtained > 0),
    },
  };

  // Diálogos: función que devuelve páginas (array de strings) según estado.
  const DIALOGS = {
    mentor: (s) => {
      if (!s.flags.metMentor) {
        s.flags.metMentor = true;
        activate('q_intro');
        return [
          'Dra. Elna: ¡Bienvenido al gremio de los PHENO HUNTERS!',
          'Nuestra misión no es luchar, sino encontrar y preservar la diversidad genética del planeta.',
          'Toma tu Frasco de semillas. Ve a la Pradera, al sur, y recolecta tu primera variedad.',
          'Pulsa I para abrir tu mochila, y C para ver tu Catálogo. ¡Suerte, cazador!',
        ];
      }
      return [
        'Dra. Elna: Cada fenotipo que catalogas queda registrado para siempre.',
        `Llevas ${Object.keys(s.catalog).length} variedades y ${s.player.prestige} de prestigio.`,
        'El prestigio abre nuevas regiones y licencias. Sigue explorando.',
      ];
    },
    coleccionista: (s) => [
      'Coleccionista Bru: Compro genéticas raras a buen precio.',
      'Cuanto más rara la variedad, más pago. Vende clones que te sobren en el Banco (B) con el botón Vender.',
      'Los fenotipos míticos... por esos pagaría una fortuna.',
    ],
    criador: (s) => {
      activate('q_breeder');
      return [
        'Criador Wex: El verdadero arte está en el cruce.',
        'En el Laboratorio puedes cruzar dos ejemplares del Banco. La descendencia hereda genes de ambos.',
        'A veces surgen fenotipos, colores o mutaciones que nadie había visto. Eso es oro para el catálogo.',
      ];
    },
    explorador: (s) => [
      'Explorador Ino: El clima lo cambia todo.',
      'Con niebla aparece la esquiva Brumaria; de noche salen las variedades de sombra.',
      'Consigue un Medidor ambiental para leer las condiciones. Yo nunca salgo sin él.',
    ],
    botanica: (s) => {
      activate('q_mutation');
      return [
        'Botánica Sella: ¿Has visto una planta con variegación? ¿Con gigantismo?',
        'Esas mutaciones son rarísimas en la naturaleza, pero puedes fijarlas cruzando portadores.',
        'Documenta una y el gremio te recompensará generosamente.',
      ];
    },
    contrabandista: (s) => [
      'Contrabandista Kez: Psst... yo consigo lo que otros no pueden.',
      'Herramientas de alta gama, feromonas florales para atraer rarezas...',
      'Pásate por el Mercado. Y no preguntes de dónde saco la mercancía.',
    ],
  };

  function activate(id) {
    const s = PH.state.get();
    if (!s.quests[id]) s.quests[id] = { state: 'active' };
  }

  // Revisa todas las misiones activas; devuelve las recién completadas.
  function checkAll() {
    const s = PH.state.get();
    const completed = [];
    for (const id of Object.keys(s.quests)) {
      const q = s.quests[id];
      if (q.state === 'active' && QUESTS[id] && QUESTS[id].check(s)) {
        q.state = 'done';
        grantReward(QUESTS[id].reward);
        completed.push(QUESTS[id]);
      }
    }
    return completed;
  }

  function grantReward(r) {
    if (!r) return;
    const s = PH.state.get();
    if (r.credits) PH.state.addCredits(r.credits);
    if (r.prestige) PH.state.addPrestige(r.prestige);
    if (r.tool && !s.player.tools.includes(r.tool)) s.player.tools.push(r.tool);
    if (r.gear && !s.player.gear.includes(r.gear)) s.player.gear.push(r.gear);
  }

  function activeList() {
    const s = PH.state.get();
    return Object.keys(s.quests)
      .filter(id => QUESTS[id])
      .map(id => ({ ...QUESTS[id], state: s.quests[id].state }));
  }

  PH.quests = { QUESTS, DIALOGS, activate, checkAll, grantReward, activeList };
})(window.PH = window.PH || {});
