/* ============================================================
   STRAINMON — lineages.js
   Árbol genealógico canónico: 100 híbridas con nombre que salen
   de las 16 landraces (SM-001…SM-016) y, en la cima, de las dos
   reliquias (SM-000, SM-017). Nombres de parodia originales.

   Cada receta es un cruce A × B (el orden no importa). Una línea
   es una landrace (SM-xxx) o una híbrida canónica (SH-xxx); cruzar
   dos líneas que forman receta da la híbrida con su nombre.
   La generación sale de los padres: F1 = dos landraces.
   ============================================================ */
(function (PH) {
  'use strict';

  const HYBRIDS = [
    // ---------- F1 · landrace × landrace ----------
    { id: 'SH-001', name: 'Sol de Altiplano', parents: ['SM-001', 'SM-002'], nota: 'Las dos mexicanas: cítrico dorado de altura.' },
    { id: 'SH-002', name: 'Lima Andina', parents: ['SM-001', 'SM-003'], nota: 'Espigada y ácida, pistilo rojizo.' },
    { id: 'SH-003', name: 'Brasa del Golfo', parents: ['SM-002', 'SM-014'], nota: 'Oro costero con brasas del istmo.' },
    { id: 'SH-004', name: 'Rubí Cafetero', parents: ['SM-003', 'SM-014'], nota: 'Los dos rojos de América juntos.' },
    { id: 'SH-005', name: 'Seda del Mekong', parents: ['SM-004', 'SM-005'], nota: 'Sativa fina de selva, floración eterna.' },
    { id: 'SH-006', name: 'Liana Ecuatorial', parents: ['SM-004', 'SM-009'], nota: 'Trepadora dorada, especias de dos continentes.' },
    { id: 'SH-007', name: 'Resina de Ladera', parents: ['SM-006', 'SM-007'], nota: 'Charas e incienso: se pega a los dedos.' },
    { id: 'SH-008', name: 'Piedra de Chitral', parents: ['SM-006', 'SM-015'], nota: 'Índica compacta, terrosa y pesada.' },
    { id: 'SH-009', name: 'Incienso Púrpura', parents: ['SM-007', 'SM-016'], nota: 'Morada de templo, aroma de altar.' },
    { id: 'SH-010', name: 'Escarcha Afgana', parents: ['SM-015', 'SM-016'], nota: 'Las dos índicas de nieve, escarchada de resina.' },
    { id: 'SH-011', name: 'Aguacero del Congo', parents: ['SM-008', 'SM-009'], nota: 'Africana rápida, fruta ácida y lluvia.' },
    { id: 'SH-012', name: 'Brisa Salina', parents: ['SM-010', 'SM-014'], nota: 'Isleña de costa, aguanta el salitre.' },
    { id: 'SH-013', name: 'Coral Dorado', parents: ['SM-002', 'SM-010'], nota: 'Oro y turquesa, dulce tropical.' },
    { id: 'SH-014', name: 'Polvo de Ketama', parents: ['SM-011', 'SM-012'], nota: 'Las dos del Rif: tamiz fino.' },
    { id: 'SH-015', name: 'Tamiz del Rif', parents: ['SM-006', 'SM-011'], nota: 'Charas frotado y kif tamizado.' },
    { id: 'SH-016', name: 'Ceniza Oaxaqueña', parents: ['SM-013', 'SM-014'], nota: 'Volcánica, crece en ceniza fértil.' },
    { id: 'SH-017', name: 'Obsidiana', parents: ['SM-013', 'SM-016'], nota: 'Hojas casi negras, brillo vítreo.' },
    { id: 'SH-018', name: 'Ruta de las Caravanas', parents: ['SM-012', 'SM-015'], nota: 'Del Rif al Kush por el desierto.' },
    { id: 'SH-019', name: 'Atardecer de Malawi', parents: ['SM-002', 'SM-009'], nota: 'Cogollos enormes, ámbar de tarde.' },
    { id: 'SH-020', name: 'Pantera de Selva', parents: ['SM-005', 'SM-016'], nota: 'Púrpura oscura, vigorosa y sigilosa.' },
    { id: 'SH-021', name: 'Monzón', parents: ['SM-004', 'SM-007'], nota: 'Del llano tailandés a la colina nepalí.' },
    { id: 'SH-022', name: 'Tambor Caribe', parents: ['SM-008', 'SM-010'], nota: 'África y el Caribe al mismo ritmo.' },
    { id: 'SH-023', name: 'Pimienta Roja', parents: ['SM-003', 'SM-004'], nota: 'Picante, especiada, pistilo encendido.' },
    { id: 'SH-024', name: 'Nube de Templo', parents: ['SM-005', 'SM-007'], nota: 'Dulce y ahumada, efecto en calma.' },
    { id: 'SH-025', name: 'Alfombra Persa', parents: ['SM-011', 'SM-016'], nota: 'Hachís tejido a mano, púrpura y terroso.' },
    { id: 'SH-026', name: 'Lava Dulce', parents: ['SM-010', 'SM-013'], nota: 'Isla y volcán: tropical con fondo mineral.' },
    { id: 'SH-027', name: 'Jade Salvaje', parents: ['SM-001', 'SM-004'], nota: 'Verde lima intenso, hoja estrecha.' },
    { id: 'SH-028', name: 'Mezcal de Sierra', parents: ['SM-001', 'SM-013'], nota: 'Mexicana ahumada de sierra.' },
    { id: 'SH-029', name: 'Sabana de Ámbar', parents: ['SM-009', 'SM-012'], nota: 'África de punta a punta, ámbar seco.' },
    { id: 'SH-030', name: 'Té de Selva', parents: ['SM-005', 'SM-008'], nota: 'Dulce terroso con chispa cítrica.' },
    { id: 'SH-031', name: 'Fuego de Istmo', parents: ['SM-008', 'SM-014'], nota: 'Tropical roja, fruta y calor.' },
    { id: 'SH-032', name: 'Cumbre Nevada', parents: ['SM-007', 'SM-015'], nota: 'Índica de altura, resiste heladas.' },
    { id: 'SH-033', name: 'Dunas Rojas', parents: ['SM-003', 'SM-012'], nota: 'Rojo andino tostado al sol del Rif.' },
    { id: 'SH-034', name: 'Cacao Salvaje', parents: ['SM-003', 'SM-005'], nota: 'Dulce y terrosa, aroma de cacao.' },
    { id: 'SH-035', name: 'Marea Púrpura', parents: ['SM-010', 'SM-016'], nota: 'Púrpura con brisa marina.' },
    { id: 'SH-036', name: 'Oro Viejo', parents: ['SM-002', 'SM-011'], nota: 'Oro costero curado como hachís.' },
    { id: 'SH-037', name: 'Bambú Errante', parents: ['SM-004', 'SM-008'], nota: 'Altísima y flexible, cítrico especiado.' },
    { id: 'SH-038', name: 'Kif Dorado', parents: ['SM-009', 'SM-011'], nota: 'Kif del Rif con oro de Malawi.' },
    { id: 'SH-039', name: 'Roca Madre', parents: ['SM-006', 'SM-016'], nota: 'Índica pura de cueva y valle.' },
    { id: 'SH-040', name: 'Niebla de Guerrero', parents: ['SM-002', 'SM-013'], nota: 'Costa y sierra mexicanas.' },

    // ---------- F2 · híbrida × híbrida o retrocruce ----------
    { id: 'SH-041', name: 'Corona de Sol', parents: ['SH-001', 'SH-019'], nota: 'Doble oro: la más dorada de F2.' },
    { id: 'SH-042', name: 'Rubí Imperial', parents: ['SH-004', 'SH-009'], nota: 'Rojo de América y púrpura de templo.' },
    { id: 'SH-043', name: 'Seda Púrpura', parents: ['SH-005', 'SH-020'], nota: 'Sativa fina teñida de púrpura.' },
    { id: 'SH-044', name: 'Bloque de Templo', parents: ['SH-007', 'SH-024'], nota: 'Resina prensada con humo de incienso.' },
    { id: 'SH-045', name: 'Cristal de Hielo', parents: ['SH-010', 'SH-032'], nota: 'Tricomas como escarcha.' },
    { id: 'SH-046', name: 'Huracán', parents: ['SH-011', 'SH-012'], nota: 'Lluvia del Congo y viento de isla.' },
    { id: 'SH-047', name: 'Tamiz Real', parents: ['SH-014', 'SH-015'], nota: 'El mejor polen de todo el Rif.' },
    { id: 'SH-048', name: 'Basalto', parents: ['SH-016', 'SH-017'], nota: 'Volcánica oscura y densa.' },
    { id: 'SH-049', name: 'Caravana Púrpura', parents: ['SH-018', 'SH-025'], nota: 'Desierto, Kush y alfombra persa.' },
    { id: 'SH-050', name: 'Arrecife', parents: ['SH-013', 'SH-022'], nota: 'Turquesa, coral y tambor.' },
    { id: 'SH-051', name: 'Jade Monzón', parents: ['SH-021', 'SH-027'], nota: 'Verde jade que crece con la lluvia.' },
    { id: 'SH-052', name: 'Chile Andino', parents: ['SH-002', 'SH-023'], nota: 'Lima ácida y pimienta roja.' },
    { id: 'SH-053', name: 'Mole Negro', parents: ['SH-028', 'SH-034'], nota: 'Ahumado y cacao: receta de sierra.' },
    { id: 'SH-054', name: 'Leopardo de Arena', parents: ['SH-029', 'SH-033'], nota: 'Hoja moteada, ámbar y rojo seco.' },
    { id: 'SH-055', name: 'Selva Profunda', parents: ['SH-006', 'SH-030'], nota: 'Dos selvas y dos continentes.' },
    { id: 'SH-056', name: 'Fuego Lento', parents: ['SH-003', 'SH-031'], nota: 'Brasa del golfo, fuego del istmo.' },
    { id: 'SH-057', name: 'Ámbar Fósil', parents: ['SH-036', 'SH-038'], nota: 'Hachís dorado de solera.' },
    { id: 'SH-058', name: 'Raíz de Piedra', parents: ['SH-008', 'SH-039'], nota: 'La índica más terrosa del árbol.' },
    { id: 'SH-059', name: 'Medianoche Tropical', parents: ['SH-026', 'SH-035'], nota: 'Púrpura de isla con fondo de lava.' },
    { id: 'SH-060', name: 'Bambú Dorado', parents: ['SH-037', 'SM-009'], nota: 'Retrocruce a Malawi: dorado y alto.' },
    { id: 'SH-061', name: 'Niebla Alta', parents: ['SH-040', 'SM-007'], nota: 'Retrocruce de montaña, más compacta.' },
    { id: 'SH-062', name: 'Rocío Carmesí', parents: ['SH-002', 'SM-014'], nota: 'Retrocruce rojo: pistilo carmesí fijo.' },
    { id: 'SH-063', name: 'Sal de Roca', parents: ['SH-012', 'SM-015'], nota: 'Isleña endurecida en la nieve.' },
    { id: 'SH-064', name: 'Granizo Morado', parents: ['SH-032', 'SM-016'], nota: 'Retrocruce afgano, púrpura con frío.' },
    { id: 'SH-065', name: 'Té Negro', parents: ['SH-024', 'SH-030'], nota: 'Dulce ahumado y oscuro.' },
    { id: 'SH-066', name: 'Sirena', parents: ['SH-019', 'SH-022'], nota: 'Oro de Malawi que canta en la costa.' },
    { id: 'SH-067', name: 'Cobre', parents: ['SH-003', 'SH-036'], nota: 'Del oro al cobre: ámbar rojizo.' },
    { id: 'SH-068', name: 'Espino Errante', parents: ['SH-014', 'SM-001'], nota: 'Kif del Rif en el altiplano.' },
    { id: 'SH-069', name: 'Lava Púrpura', parents: ['SH-017', 'SH-020'], nota: 'Obsidiana y pantera: casi negra.' },
    { id: 'SH-070', name: 'Tueste Andino', parents: ['SH-004', 'SH-034'], nota: 'Rojo cafetero tostado con cacao.' },

    // ---------- F3 ----------
    { id: 'SH-071', name: 'Diadema', parents: ['SH-041', 'SH-042'], nota: 'Oro y rubí en un mismo cogollo.' },
    { id: 'SH-072', name: 'Seda Real', parents: ['SH-043', 'SH-051'], nota: 'Púrpura y jade, la sativa más fina.' },
    { id: 'SH-073', name: 'Monasterio', parents: ['SH-044', 'SH-045'], nota: 'Resina de templo en cristal de hielo.' },
    { id: 'SH-074', name: 'Tormenta Tropical', parents: ['SH-046', 'SH-050'], nota: 'Huracán sobre el arrecife.' },
    { id: 'SH-075', name: 'Sello del Rif', parents: ['SH-047', 'SH-049'], nota: 'Tamiz real con sello de caravana.' },
    { id: 'SH-076', name: 'Magma', parents: ['SH-048', 'SH-069'], nota: 'Basalto y lava púrpura: núcleo ardiente.' },
    { id: 'SH-077', name: 'Salsa Brava', parents: ['SH-052', 'SH-053'], nota: 'Chile andino y mole: pica y endulza.' },
    { id: 'SH-078', name: 'Felino de Sabana', parents: ['SH-054', 'SH-055'], nota: 'Leopardo de arena criado en selva.' },
    { id: 'SH-079', name: 'Brasa Eterna', parents: ['SH-056', 'SH-067'], nota: 'Fuego lento sobre cobre.' },
    { id: 'SH-080', name: 'Ámbar Sagrado', parents: ['SH-057', 'SH-065'], nota: 'Ámbar fósil infusionado en té negro.' },
    { id: 'SH-081', name: 'Roca Helada', parents: ['SH-058', 'SH-064'], nota: 'Raíz de piedra cubierta de granizo.' },
    { id: 'SH-082', name: 'Eclipse Caribe', parents: ['SH-059', 'SH-066'], nota: 'Medianoche tropical y canto de sirena.' },
    { id: 'SH-083', name: 'Oro Verde', parents: ['SH-060', 'SH-062'], nota: 'Bambú dorado y rocío carmesí.' },
    { id: 'SH-084', name: 'Cumbre de Niebla', parents: ['SH-061', 'SH-063'], nota: 'Niebla alta y sal de roca.' },
    { id: 'SH-085', name: 'Café de Altura', parents: ['SH-068', 'SH-070'], nota: 'Espino del Rif y tueste andino.' },
    { id: 'SH-086', name: 'Alba Morada', parents: ['SH-059', 'SH-064'], nota: 'Amanece púrpura tras la tormenta.' },
    { id: 'SH-087', name: 'Tierra Roja', parents: ['SH-054', 'SH-056'], nota: 'Arena, fuego y suelo rojo.' },
    { id: 'SH-088', name: 'Viento de Oración', parents: ['SH-050', 'SH-065'], nota: 'Arrecife y té de templo.' },

    // ---------- F4 ----------
    { id: 'SH-089', name: 'Corona Imperial', parents: ['SH-071', 'SH-083'], nota: 'Diadema coronada de oro verde.' },
    { id: 'SH-090', name: 'Rueda de Plegaria', parents: ['SH-072', 'SH-073'], nota: 'Seda real que gira en el monasterio.' },
    { id: 'SH-091', name: 'Ciclón', parents: ['SH-074', 'SH-082'], nota: 'Tormenta y eclipse: imprevisible.' },
    { id: 'SH-092', name: 'Sello Dorado', parents: ['SH-075', 'SH-080'], nota: 'El hachís más noble del árbol.' },
    { id: 'SH-093', name: 'Núcleo Volcánico', parents: ['SH-076', 'SH-079'], nota: 'Magma y brasa eterna.' },
    { id: 'SH-094', name: 'Fiesta Mayor', parents: ['SH-077', 'SH-085'], nota: 'Salsa brava con café de altura.' },
    { id: 'SH-095', name: 'Rey de la Sabana', parents: ['SH-078', 'SH-087'], nota: 'Felino de sabana sobre tierra roja.' },
    { id: 'SH-096', name: 'Luna de Escarcha', parents: ['SH-081', 'SH-084'], nota: 'Roca helada bajo la cumbre de niebla.' },

    // ---------- F5 ----------
    { id: 'SH-097', name: 'Trono Solar', parents: ['SH-089', 'SH-092'], nota: 'Corona imperial sobre sello dorado.' },
    { id: 'SH-098', name: 'Calma Absoluta', parents: ['SH-090', 'SH-096'], nota: 'Plegaria y escarcha: silencio total.' },

    // ---------- F6 · cima: cruces con las reliquias ----------
    { id: 'SH-099', name: 'Edén Renacido', parents: ['SH-098', 'SM-017'], nota: 'Despierta los linajes que guardaba la Semilla del Edén.' },
    { id: 'SH-100', name: 'Origen', parents: ['SH-097', 'SM-000'], nota: 'Vuelve a la Cepa Primigenia: la cima del árbol.' },
  ];

  const HYBRIDS_BY_ID = {};
  const RECIPES = {};
  const pairKey = (a, b) => [a, b].sort().join('×');
  for (const h of HYBRIDS) {
    HYBRIDS_BY_ID[h.id] = h;
    RECIPES[pairKey(h.parents[0], h.parents[1])] = h;
  }

  // Generación: landrace = 0, F1 = 1… (los padres siempre van antes en la lista).
  function genOf(id) {
    const h = HYBRIDS_BY_ID[id];
    return h ? 1 + Math.max(genOf(h.parents[0]), genOf(h.parents[1])) : 0;
  }
  for (const h of HYBRIDS) h.gen = genOf(h.id);

  // Línea de un espécimen: su híbrida canónica o, si no tiene, su cepa.
  const lineOf = spec => spec.canonId || spec.speciesId;
  // Receta que forman dos especímenes (o dos ids de línea), si existe.
  function recipe(a, b) {
    const la = typeof a === 'string' ? a : lineOf(a);
    const lb = typeof b === 'string' ? b : lineOf(b);
    return RECIPES[pairKey(la, lb)] || null;
  }
  // Nombre legible de una línea (SM-xxx o SH-xxx).
  function lineName(id) {
    const h = HYBRIDS_BY_ID[id];
    if (h) return h.name;
    const sp = PH.species && PH.species.SPECIES_BY_ID[id];
    return sp ? sp.name : id;
  }

  PH.lineages = { HYBRIDS, HYBRIDS_BY_ID, recipe, lineOf, lineName, genOf };
})(window.PH = window.PH || {});
