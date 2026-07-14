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
      desc: 'Recolecta tu primera cepa en el Altiplano de Michoacán.',
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
      id: 'q_relic', name: 'La raíz del linaje',
      desc: 'Consigue la landrace ancestral Afghani, raíz de innumerables híbridos.',
      reward: { credits: 3000, prestige: 40 },
      check: (s) => (s.species['afghani'] && s.species['afghani'].obtained > 0),
    },
    q_sequence: {
      id: 'q_sequence', name: 'Lectura del genoma',
      desc: 'Secuencia el ADN de una variedad en el laboratorio.',
      reward: { credits: 500, prestige: 8 },
      check: (s) => s.stats.sequenced >= 1,
    },
    q_regions: {
      id: 'q_regions', name: 'Cartógrafo genético',
      desc: 'Cataloga al menos una variedad en 5 biomas distintos.',
      reward: { credits: 1200, prestige: 20, gear: 'estabilizador' },
      check: (s) => {
        const biomes = new Set();
        for (const sp of s.bank) if (sp.caughtAt && sp.caughtAt.biome) biomes.add(sp.caughtAt.biome);
        return biomes.size >= 5;
      },
    },
    q_poly: {
      id: 'q_poly', name: 'Genoma multiplicado',
      desc: 'Documenta una variedad poliploide (triploide o superior).',
      reward: { credits: 1000, prestige: 18 },
      check: (s) => Object.values(s.catalog).some(e => e.pheno && e.pheno.ploidy > 2),
    },
    q_harvest: {
      id: 'q_harvest', name: 'Primera cosecha',
      desc: 'Cultiva una planta en el invernadero y coséchala.',
      reward: { credits: 400, prestige: 7 },
      check: (s) => (s.stats.harvests || 0) >= 1,
    },
    q_greenthumb: {
      id: 'q_greenthumb', name: 'Mano verde',
      desc: 'Cosecha una planta en perfecto estado (salud ≥ 90%): riégala a tiempo y evita el moho.',
      reward: { credits: 700, prestige: 12, gear: 'medidor' },
      check: (s) => (s.stats.perfectHarvests || 0) >= 1,
    },
    q_hustle: {
      id: 'q_hustle', name: 'Bajo perfil',
      desc: 'Cierra 3 tratos callejeros. Vigila el nivel de búsqueda y piérdete en interiores si aprieta la poli.',
      reward: { credits: 900, prestige: 14 },
      check: (s) => (s.stats.deals || 0) >= 3,
    },
    q_master: {
      id: 'q_master', name: 'Maestro Strainmon',
      desc: 'Registra 25 fenotipos en el Strain-dex mundial.',
      reward: { credits: 5000, prestige: 60 },
      check: (s) => Object.keys(s.catalog).length >= 25,
    },
  };

  // Diálogos: función que devuelve páginas (array de strings) según estado.
  const DIALOGS = {
    mentor: (s) => {
      if (!s.flags.metMentor) {
        s.flags.metMentor = true;
        activate('q_intro');
        return [
          'Dra. Elna: ¡Bienvenido al gremio Strainmon!',
          'Nuestra misión no es luchar, sino encontrar y preservar las cepas landrace ancestrales y sus linajes.',
          'Toma tu Frasco de semillas. Baja al Altiplano de Michoacán, al sur, y recolecta tu primera cepa.',
          'Pulsa I para la mochila y C para el Strain-dex. ¡Suerte, cazador de cepas!',
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
      activate('q_breeder'); activate('q_harvest');
      return [
        'Criador Wex: El verdadero arte está en el cruce.',
        'En el Laboratorio puedes cruzar dos ejemplares del Banco. La descendencia hereda genes de ambos.',
        'Y en el Invernadero (tecla G) puedes cultivar clones: crecen por fases y, al cosechar, propagas la genética en varios clones idénticos.',
        'A veces surgen fenotipos, colores o mutaciones que nadie había visto. Eso es oro para el catálogo.',
      ];
    },
    explorador: (s) => [
      'Explorador Ino: El clima lo cambia todo.',
      'De noche salen las cepas de flor púrpura; el calor despierta las landrace del sur.',
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
    genetista: (s) => {
      activate('q_sequence');
      return [
        'Dr. Vane: Toda planta esconde alelos recesivos invisibles a simple vista.',
        'Secuencia su ADN en el Laboratorio (botón Investigar) para revelar genes ocultos y calcular parentescos.',
        'Con esa información podrás dirigir tus cruces hacia mutaciones concretas.',
      ];
    },
    nomada: (s) => {
      activate('q_regions');
      return [
        'Zahra: El Rif guarda las landrace del hachís. La Rifeña Kif rinde tricomas incluso con sequía.',
        'En verano y con olas de calor, las cepas del Rif se multiplican.',
        'Sigue al norte, hacia los Cráteres de Oaxaca... si tu prestigio lo permite.',
      ];
    },
    vulcanologo: (s) => [
      'Draco: En suelo volcánico germina lo más vigoroso. La Oaxaqueña nace de la ceniza.',
      'Y por el istmo baja la legendaria Rojo de Panamá, veteada de rojo y púrpura.',
      'Cuidado con la lava. Cataloga y márchate.',
    ],
    glaciologa: (s) => [
      'Frey: Estas cumbres son la cuna de las índicas. El Kush Ancestral resiste el hielo.',
      'El frío nocturno pinta de púrpura a la Afgana y fija resina cristalina.',
      'Abrígate, cazador de cepas.',
    ],
    espeleologo: (s) => [
      'Mox: En Chitral se frota el charas a mano. La resina de estas cuevas no tiene igual.',
      'Estas galerías tienen la mayor tasa de mutación conocida.',
      'Dicen que en lo más profundo duerme una reliquia: la Semilla del Edén...',
    ],
    marinera: (s) => [
      'Nira: Bienvenido a la Costa de Jamaica. La brisa salina moldea linajes únicos.',
      'La Jamaicana Costera tolera la sal; su aroma marino no se da tierra adentro.',
      'El muelle te lleva de vuelta al continente cuando quieras.',
    ],
    descampado: (s) => {
      activate('q_greenthumb'); activate('q_hustle');
      return [
        'Rasta Dodo: Este descampado es tierra de nadie... y de cultivo libre. Rebusca entre la maleza (parcelas verdes).',
        'Cuida tus plantas en casa: sin agua se estresan y el exceso de humedad cría moho. Trátalo con poda y ventilación, nada de venenos.',
        'Y ojo en la calle: cada trapicheo levanta la liebre. Si aparece la patrulla, métete en un portal y desaparece.',
      ];
    },
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
