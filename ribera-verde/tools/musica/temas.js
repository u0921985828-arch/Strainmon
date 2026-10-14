/*
  Las canciones de la app de Godot (1.30), propias. Las sintetiza tools/musica.js.
  Cada una: bpm, estilo (batería, bajo y acompañamiento de tools/musica.js), inst (lead y lead2), sec (secciones: ch, los acordes,
  un compás cada uno o «:n» negras; mel, la melodía a corcheas: «c5», «f#4», «.» silencio, «-» liga, «!» acento; «|» separa
  compases y se comprueba) y forma (las secciones en orden; «|» marca dónde empieza el bucle; «+» llena —segunda voz por debajo,
  más batería y plato—, «-» sin melodía, «~» sin batería, «>» intro suave). calle: 1 saca también la de noche (más lenta, con el
  lead de noche y la forma `formaN`): `night` la de Ribera y `<clave>_n` las demás. oct sube o baja la melodía.
*/
const TEMAS = {
  /* ---------- la calle, de día (y de noche) ---------- */
  // Ribera Verde, el barrio: la de siempre, con su segunda parte y un puente en la menor
  town: { bpm: 120, estilo: 'pop', calle: 1, inst: { lead: 'pulso', lead2: 'campana' },
    sec: {
      i: { ch: 'C Am F G' },
      A: { ch: 'C C:2 Am:2 C:2 F:2 G:2 C:2 C C:2 Am:2 F:2 G:2 C',
        mel: 'c5 . e5 g5 f5 e5 d5 . | c5 d5 e5 c5 a4 . g4 . | c5 . e5 g5 a5 g5 f5 e5 | d5 e5 f5 d5 c5 - . . | c5 . e5 g5 f5 e5 d5 . | c5 d5 e5 g5 a5 . g5 . | f5 . a5 g5 f5 e5 d5 e5 | c5 - - - . . g4 .' },
      B: { ch: 'F:2 G:2 Em:2 Am:2 Dm:2 G:2 C:2 G:2 F:2 G:2 Em:2 Am:2 Dm:2 G:2 C:2 G:2',
        mel: 'f5 . a5 c6 - . b5 a5 | g5 . e5 . a5 - . . | f5 e5 d5 . f5 . g5 a5 | g5 - e5 . d5 . . . | f5 . a5 c6 - . d6 c6 | b5 . g5 . e5 - . . | d5 e5 f5 a5 g5 . f5 d5 | e5 - - - d5 - - .' },
      C: { ch: 'Am Dm F C C Em:2 Am:2 Dm:2 G7:2 G',
        mel: 'e5 - - - a5 - g5 e5 | d5 - c5 - a4 - - . | f5 - - - a5 - c6 a5 | g5 - - - . . . . | e5 - - - g5 - c6 - | b5 - a5 - g5 - e5 . | d5 - e5 - f5 - g5 - | g5 - - - b4 . d5 .' },
    },
    forma: 'i> | A B A+ C B+', formaN: 'i> | A B C A~' },
  // el barrio alto: lounge en fa, con vibráfono y escobillas
  alto: { bpm: 104, estilo: 'lounge', calle: 1, inst: { lead: 'campana', lead2: 'flauta' },
    sec: {
      i: { ch: 'Fmaj7 Dm7 Gm7 C7' },
      A: { ch: 'Fmaj7 Gm7:2 C7:2 Am7:2 Dm7:2 Gm7:2 C7:2 Fmaj7 Bbmaj7 Am7:2 D7:2 Gm7:2 C7:2',
        mel: 'c6 - a5 - e5 - f5 . | bb5 - a5 g5 e5 - c5 . | a5 - g5 - f5 - d5 . | g5 - - a5 bb5 - g5 . | a5 - c6 - f6 - e6 . | d6 - - c6 a5 - bb5 . | c6 - a5 - f#5 - a5 . | g5 - f5 - e5 - c5 .' },
      B: { ch: 'Bbmaj7 Bbm6 Am7 D7 Gm7 C7 Fmaj7 C7',
        mel: 'd6 - - c6 a5 - f5 . | db6 - - c6 bb5 - g5 . | c6 - - - a5 - e5 . | f#5 - a5 - c6 - d6 . | bb5 - - a5 g5 - d5 . | e5 - g5 - bb5 - a5 g5 | a5 - - - - - c5 . | e5 - g5 - c6 - bb5 .' },
    },
    forma: 'i> | A B A+ B+', formaN: 'i> | A B A~' },
  // los astilleros: industrial en mi menor, chatarra y bajo de sierra
  astilleros: { bpm: 124, estilo: 'industrial', calle: 1, inst: { lead: 'cuadrada', lead2: 'pulso12' },
    sec: {
      i: { ch: 'Em Em C B7' },
      A: { ch: 'Em Em C D Em Em C:2 D:2 B7',
        mel: 'e5 . e5 g5 . e5 d5 . | e5 . b4 . d5 - e5 . | c5 . c5 e5 . c5 b4 . | d5 . a4 . d5 - f#5 . | g5 . g5 f#5 e5 . d5 . | e5 - b4 . e5 . g5 . | a5 - g5 . f#5 - d5 . | d#5 - f#5 - b5 - . .' },
      B: { ch: 'Am Am Em Em C D Em B7',
        mel: 'a5 - - . c6 - b5 a5 | e5 - - - . . a4 b4 | g5 - - . b5 - a5 g5 | e5 - - - . . e5 f#5 | g5 . g5 . a5 . g5 e5 | f#5 - - . a5 - f#5 d5 | e5 . g5 . b5 . e6 . | d#6 - - - b5 - . .' },
    },
    forma: 'i> | A B A+ B+', formaN: 'i> | A B A~' },
  // Puerto Viejo: vals marinero en re, con acordeón
  puerto: { bpm: 150, estilo: 'vals', calle: 1, inst: { lead: 'acordeon', lead2: 'flauta' },
    sec: {
      i: { ch: 'D G A7 D' },
      A: { ch: 'D D G D A A7 D D',
        mel: 'f#5 - - e5 d5 . | a5 - - - f#5 . | g5 - b5 - g5 . | f#5 - - d5 - . | e5 - - c#5 - e5 | a5 - g5 - e5 . | d5 - f#5 - a5 . | d6 - - - - .' },
      B: { ch: 'D D G G D A7 D D',
        mel: 'a5 - - f#5 - a5 | d6 - - a5 - . | b5 - - g5 - b5 | d6 - b5 - g5 . | a5 - - f#5 - d5 | e5 - - a4 - c#5 | d5 - - - - . | . . . a4 - -' },
      C: { ch: 'Bm Bm F#m F#m G G A A7',
        mel: 'f#5 - - d5 - f#5 | b5 - - - a5 . | a5 - - f#5 - c#5 | c#5 - - - . . | b5 - - g5 - b5 | d6 - - b5 - g5 | a5 - - e5 - c#5 | e5 - - - - .' },
    },
    forma: 'i> | A B C A+ B+', formaN: 'i> | A B C' },
  // Valdehierro: la menor dórico, ciudad de mina, guitarras
  valdehierro: { bpm: 116, estilo: 'rock', calle: 1, inst: { lead: 'pulso', lead2: 'campana' },
    sec: {
      i: { ch: 'Am D Am E' },
      A: { ch: 'Am D Am D C G Am E',
        mel: '. a4 c5 d5 e5 . c5 . | f#5 - e5 d5 . a4 . . | . a4 c5 d5 e5 . g5 - | f#5 - d5 . e5 - . . | g5 . g5 e5 c5 . e5 . | d5 . b4 . d5 . g5 - | e5 - c5 . a4 . c5 . | b4 - g#4 . b4 . e5 .' },
      B: { ch: 'F G Am Am F G E E',
        mel: 'a5 - - . f5 . c5 . | d5 - b4 . d5 . g5 . | e5 - - - a5 - - . | g5 . e5 . c5 . a4 . | a5 - - . c6 . a5 . | b5 - - . g5 . d5 . | e5 - - . g#5 . b5 . | e6 - - - . . . .' },
    },
    forma: 'i> | A B A+ B+', formaN: 'i> | A B A~' },
  // Mendialde: 6/8 de caserío, acordeón y pandero
  mendialde: { bpm: 168, estilo: 'trikiti', calle: 1, oct: -1, inst: { lead: 'acordeon', lead2: 'flauta' },
    sec: {
      i: { ch: 'G D G D' },
      A: { ch: 'G G C G D D G G',
        mel: 'd6 - b5 g5 - b5 | d6 - - g6 - . | e6 - c6 e6 - g6 | d6 - b5 g5 - . | a5 - f#5 a5 - d6 | c6 - a5 f#5 - a5 | b5 - g5 d6 - b5 | g5 - - - - .' },
      B: { ch: 'Em Em C G D D G G',
        mel: 'e6 - b5 e6 - g6 | f#6 - e6 b5 - . | c6 - e6 g6 - e6 | d6 - b5 g5 - b5 | a5 - b5 c6 - a5 | f#5 - a5 d6 - c6 | b5 - a5 g5 - f#5 | g5 - - - . .' },
    },
    forma: 'i> | A B A+ B+', formaN: 'i> | A B A~' },
  // Errotabarri: pastoral lenta en fa, flauta, guitarra y cuerdas
  errotabarri: { bpm: 92, estilo: 'pastoral', calle: 1, inst: { lead: 'flauta', lead2: 'campana' },
    sec: {
      i: { ch: 'F Bb F C' },
      A: { ch: 'F C Dm Bb:2 C:2 F Am Bb:2 C:2 F',
        mel: 'c5 - f5 - a5 - - g5 | g5 - e5 - c5 - . . | d5 - f5 - a5 - g5 f5 | f5 - d5 - e5 - - . | a5 - c6 - a5 - f5 - | e5 - a5 - c6 - b5 a5 | d6 - bb5 - g5 - e5 . | f5 - - - . . . .' },
      B: { ch: 'Bb F Gm C Dm Am Bb C',
        mel: 'd5 - f5 - bb5 - - a5 | a5 - - - f5 - c5 . | bb4 - d5 - g5 - - f5 | e5 - - - g5 - - . | f5 - a5 - d6 - c6 a5 | c6 - - - e5 - - . | d5 - f5 - bb5 - a5 g5 | g5 - - - - - . .' },
    },
    forma: 'i> | A B A+ B+', formaN: 'i> | A B A~' },
  // Ibarbide, el Casco Viejo: funk en sol menor
  ibarbide: { bpm: 108, estilo: 'funk', calle: 1, inst: { lead: 'pulso', lead2: 'campana' },
    sec: {
      i: { ch: 'Gm7 C7 Gm7 D7' },
      A: { ch: 'Gm7 C7 Gm7 D7 Ebmaj7 F7 Gm7 D7',
        mel: 'g5 . bb5 . c6 - bb5 . | a5 . g5 . e5 - d5 . | g5 . bb5 . d6 - c6 . | a5 - - . f#5 - d5 . | eb5 . g5 . bb5 - g5 . | f5 . a5 . c6 - a5 . | bb5 - a5 g5 . d5 g5 . | f#5 - - - d5 . . .' },
      B: { ch: 'Cm7 F7 Bbmaj7 Ebmaj7 Am7b5 D7 Gm7 D7',
        mel: 'c6 . . bb5 . g5 eb5 . | f5 - a5 . c6 . eb6 . | d6 - - . bb5 . f5 . | g5 . bb5 . d6 - eb6 . | c6 - - . a5 . eb5 . | f#5 - a5 . c6 . d6 . | bb5 - a5 g5 . f5 g5 . | a5 - - - f#5 - d5 .' },
    },
    forma: 'i> | A B A+ B+', formaN: 'i> | A B A~' },
  // el Ensanche: pop electrónico en do, a cuatro por compás
  ensanche: { bpm: 124, estilo: 'electro', calle: 1, inst: { lead: 'pulso12', lead2: 'supersaw' },
    sec: {
      i: { ch: 'C Am F G' },
      A: { ch: 'C Am Am C F G F:2 G:2 C',
        mel: 'e5 . g5 . c6 . g5 . | e5 - d5 . c5 - . . | a4 . c5 . e5 . a5 . | g5 - e5 . c5 - . . | f5 . a5 . c6 . a5 . | g5 . b5 . d6 - b5 . | c6 . b5 . a5 . g5 . | e5 - d5 - c5 - . .' },
      B: { ch: 'Am F C G Am F G G',
        mel: 'a5 . a5 . c6 . e6 . | d6 . c6 . a5 . f5 . | g5 . c6 . e6 . g6 . | f6 - e6 - d6 - b5 . | c6 . a5 . e5 . a5 . | c6 - - . a5 . f5 . | g5 - b5 - d6 - g5 . | b5 - - - d6 - - .' },
    },
    forma: 'i> | A B A+ B+', formaN: 'i> | A B A~' },
  // la Kale Zaharra: cine negro en la menor, contrabajo, piano y trompeta con sordina
  callejon: { bpm: 84, estilo: 'noir', calle: 1, inst: { lead: 'metales', lead2: 'piano' },
    sec: {
      i: { ch: 'Am E7' },
      A: { ch: 'Am Am F E Am E F:2 E7:2 Am:2 E7:2',
        mel: 'e5 - - . c5 . . . | d5 - - . b4 . . . | f5 - . a5 - . c6 . | b5 - - . g#5 - . . | . . c5 . e5 . a5 - | g#5 - - . e5 - . . | a5 - g5 . f5 . e5 . | d5 - c5 . b4 - - .' },
      B: { ch: 'Dm Dm Am Am Bb E Am E7',
        mel: 'f5 - - . a5 . d6 . | c6 - - . a5 . f5 . | e5 - - . a5 . c6 . | e6 - - . c6 - . . | bb5 - - . f5 . d5 . | g#5 - - . b5 . d6 . | c6 - b5 . a5 . e5 . | g#5 - - - . . . .' },
    },
    forma: 'i> | A B A B~', formaN: 'i> | A B A~' },

  /* ---------- los interiores ---------- */
  // el piso: lo-fi en re con guitarra; de noche (home_n), con el piano eléctrico
  home: { bpm: 84, estilo: 'lofi', calle: 1, bpmN: .9, inst: { lead: 'guitarra', lead2: 'campana' }, noche: { lead: 'epiano' },
    sec: {
      i: { ch: 'Gmaj7 A7' },
      A: { ch: 'Gmaj7 F#m7 Em7 A7 Gmaj7 F#m7 Em7:2 A7:2 Dmaj7',
        mel: 'b4 - d5 - f#5 - e5 d5 | c#5 - - - a4 - - . | b4 - d5 - g5 - f#5 e5 | e5 - - - c#5 - - . | d5 - f#5 - a5 - g5 f#5 | e5 - - - c#5 - a4 . | b4 - d5 - c#5 - e5 - | d5 - - - - - . .' },
      B: { ch: 'Bm7 Bm7 Gmaj7 A7 Bm7 Em7 Gmaj7 A7',
        mel: 'f#5 - - - d5 - b4 . | a5 - - - f#5 - d5 . | g5 - f#5 - d5 - b4 - | c#5 - e5 - g5 - - . | f#5 - - - b5 - a5 f#5 | g5 - - - e5 - d5 . | f#5 - - - d5 - - . | e5 - - - c#5 - a4 .' },
    },
    forma: 'i> | A B A+ B+', formaN: 'i> | A B A B~' },
  // el growshop de Kiko: reggae en sol, con melódica
  shop: { bpm: 78, estilo: 'reggae', inst: { lead: 'acordeon', lead2: 'organo' },
    sec: {
      i: { ch: 'G C G D' },
      A: { ch: 'G C G D G C Em D',
        mel: '. . b4 d5 . . g5 . | e5 - - . c5 . e5 . | d5 . b4 . g4 - - . | . . a4 c5 d5 - . . | . . b5 . a5 . g5 . | e5 - g5 - e5 . c5 . | b4 - - e5 g5 - . . | f#5 - - d5 - . . .' },
      B: { ch: 'C D G Em C D G G',
        mel: 'e5 . g5 . c6 - b5 . | a5 - - . f#5 . d5 . | g5 - - . b5 . d6 . | b5 - - . g5 . e5 . | c6 . . b5 a5 . g5 . | f#5 - - . a5 . d6 . | b5 - - . a5 . g5 . | g5 - - - . . . .' },
    },
    forma: 'i> | A B A+ B+' },
  // GROW IBARBIDE: neo soul en mi bemol
  growcity: { bpm: 90, estilo: 'neosoul', inst: { lead: 'flauta', lead2: 'campana' },
    sec: {
      i: { ch: 'Abmaj7 Bb7' },
      A: { ch: 'Ebmaj7 Cm7 Abmaj7 Bb7 Ebmaj7 Cm7 Fm7:2 Bb7:2 Ebmaj7',
        mel: 'g5 - bb5 - d6 - c6 bb5 | g5 - - - eb5 - - . | c6 - - bb5 ab5 - g5 . | f5 - - - d5 - bb4 . | g5 - bb5 - eb6 - d6 c6 | bb5 - - - g5 - eb5 . | f5 - ab5 - d5 - f5 - | eb5 - - - - - . .' },
      B: { ch: 'Abmaj7 Bb7 Gm7 Cm7 Fm7 Bb7 Ebmaj7 Bb7',
        mel: 'c6 - - - eb6 - c6 . | d6 - - - bb5 - f5 . | bb5 - - - g5 - d5 . | eb5 - g5 - bb5 - c6 . | c6 - - - ab5 - f5 . | d6 - - - bb5 - ab5 . | g5 - - - bb5 - eb6 . | d6 - - - bb5 - - .' },
    },
    forma: 'i> | A B A+ B+' },
  // el bar El Ancla: tango en re menor, bandoneón y piano
  bar: { bpm: 120, estilo: 'tango', inst: { lead: 'acordeon', lead2: 'piano' },
    sec: {
      i: { ch: 'Dm A7 Dm A7' },
      A: { ch: 'Dm Dm A7 A7 Dm Dm Gm A7 Dm Dm Gm Gm Dm A7 A7 A7',
        mel: 'd5 . . d5 | f5 . a5 . | e5 - - c#5 | a4 . . . | d5 . . f5 | a5 . d6 . | bb5 - a5 . | g5 . e5 . | f5 . . a5 | d6 - c6 . | bb5 . . g5 | d5 - . . | f5 - e5 d5 | c#5 - e5 . | a4 - - - | . . . .' },
      B: { ch: 'F F C7 C7 F F Bb A7 Dm Dm Gm Gm A7 A7 Dm Dm',
        mel: 'a5 . . a5 | c6 . a5 . | g5 - - e5 | c5 . . . | a5 . . c6 | f6 . e6 . | d6 - bb5 . | c#6 . a5 . | d6 . . a5 | f5 . d5 . | g5 - bb5 . | d6 - . . | c#6 - e6 . | a5 - g5 . | f5 - e5 . | d5 - - -' },
    },
    forma: 'i> | A B A+ B+' },
  // la casa de la abuela Txaro: bolero en la menor
  txaro: { bpm: 88, estilo: 'bolero', inst: { lead: 'flauta', lead2: 'piano' },
    sec: {
      i: { ch: 'Am E7' },
      A: { ch: 'Am Dm G C F Dm E7 Am',
        mel: 'c6 - - b5 a5 - e5 - | f5 - - e5 d5 - - . | d5 - - c5 b4 - g4 - | c5 - - - e5 - g5 . | a5 - - g5 f5 - c5 - | d5 - - e5 f5 - a5 . | g#5 - - - b5 - d6 - | c6 - - - - - . .' },
      B: { ch: 'C C Am Am Dm G C E7',
        mel: 'e5 - - d5 e5 - g5 - | c6 - - - g5 - e5 . | a5 - - g5 a5 - c6 - | e6 - - - c6 - a5 . | f5 - - e5 f5 - a5 - | b5 - - a5 g5 - f5 . | e5 - - - g5 - c6 - | b5 - - - g#5 - e5 .' },
    },
    forma: 'i> | A B A+ B+' },
  // la comisaría: tensa, en mi menor
  comisaria: { bpm: 96, estilo: 'tension', inst: { lead: 'pulso12', lead2: 'cuerdas' },
    sec: {
      i: { ch: 'Em C' },
      A: { ch: 'Em Em C B7 Em Em C B7',
        mel: 'b4 - - - . . . . | c5 - b4 - . . g4 . | e5 - - - . . . . | d#5 - - - f#5 - . . | b5 - - - a5 - g5 - | f#5 - - - e5 - . . | e5 - g5 - c6 - - . | b5 - - - . . . .' },
      B: { ch: 'Am Am Em Em F#m7b5 B7 Em Em',
        mel: 'c5 - - - e5 - a5 - | e5 - - - c5 - . . | b4 - - - e5 - g5 - | f#5 - - - e5 - . . | a5 - - - c6 - - . | b5 - - - a5 - d#5 . | e5 - - - - - . . | . . . . b4 - - .' },
    },
    forma: 'i> | A B A B~' },
  // el almacén de los astilleros: industrial oscuro en si menor
  almacen: { bpm: 100, estilo: 'industrial', inst: { lead: 'cuadrada', lead2: 'metales' },
    sec: {
      i: { ch: 'Bm F#7' },
      A: { ch: 'Bm Bm G F#7 Bm Bm G:2 A:2 F#7',
        mel: 'f#5 - - . f#5 . d5 . | b4 - - - . . c#5 d5 | e5 - - . d5 . b4 . | c#5 - - - a#4 - - . | f#5 - - . a5 . f#5 . | d5 - - - . . b4 d5 | g5 - - . e5 . a5 . | f#5 - - - . . . .' },
      B: { ch: 'Em Em Bm Bm G G F#7 F#7',
        mel: 'g5 - - . b5 . e5 . | g5 . f#5 . e5 - . . | f#5 - - . d6 . b5 . | a5 . f#5 . d5 - . . | b5 - - . g5 . d5 . | e5 - - . g5 . b5 . | a#5 - - . c#6 . e6 . | f#6 - - - . . . .' },
    },
    forma: 'i> | A B A+ B~' },
  // el caserío de ama, en Mendialde: folk en sol con piano
  casa_ama: { bpm: 96, estilo: 'folk', inst: { lead: 'piano', lead2: 'flauta' },
    sec: {
      i: { ch: 'G C D G' },
      A: { ch: 'G D Em C G D7 C:2 D:2 G',
        mel: 'b4 - d5 - g5 - - f#5 | f#5 - a5 - d5 - - . | e5 - g5 - b5 - a5 g5 | e5 - - - c5 - - . | d5 - g5 - b5 - d6 - | c6 - b5 - a5 - f#5 - | e5 - - - f#5 - - . | g5 - - - - - . .' },
      B: { ch: 'C G Am D C G Am:2 D:2 G',
        mel: 'e5 - g5 - c6 - - b5 | b5 - - - g5 - d5 . | c5 - e5 - a5 - g5 e5 | f#5 - - - a5 - - . | g5 - e5 - c5 - e5 - | d5 - g5 - b5 - - . | c6 - - - a5 - f#5 - | g5 - - - - - . .' },
    },
    forma: 'i> | A B A+ B+' },
  // los clubs: bossa en la menor, flauta y guitarra
  club: { bpm: 112, estilo: 'bossa', inst: { lead: 'flauta', lead2: 'epiano' },
    sec: {
      i: { ch: 'Am7 Dm7 Am7 E7' },
      A: { ch: 'Am7 Dm7 Am7 Em7 Fmaj7 G7 Am7 E7',
        mel: 'a4 - - c5 e5 - - . | d5 - - f5 a5 - - . | c5 - e5 - a5 - g5 . | e5 - - - . . . . | f5 - a5 - c6 - a5 . | g5 - b5 - d6 - b5 . | a5 - g5 - e5 - c5 . | b4 - - - g#4 - . .' },
      B: { ch: 'Dm7 G7 Cmaj7 Fmaj7 Bm7b5 E7 Am7 E7',
        mel: 'f5 - - a5 c6 - - . | b5 - - - g5 - f5 . | e5 - - g5 b5 - - . | a5 - - - f5 - e5 . | d5 - - f5 a5 - - . | g#5 - - - b5 - d6 . | c6 - - - a5 - e5 . | g#5 - - - - - . .' },
    },
    forma: 'i> | A B A+ B+' },
  // la nave de Valdehierro: ambiente con marimba, los ventiladores de fondo
  nave: { bpm: 100, estilo: 'ambiente', inst: { lead: 'campana', lead2: 'pulso12' },
    sec: {
      i: { ch: 'Dm Bb' },
      A: { ch: 'Dm Bb F C Dm Bb Gm A',
        mel: 'a5 - - - - - f5 - | d5 - - - f5 - - . | c6 - - - a5 - - . | g5 - - - e5 - - . | a5 - - - d6 - - - | f6 - - - d6 - - . | bb5 - - - g5 - d5 - | c#5 - - - e5 - - .' },
      B: { ch: 'Gm Gm Dm Dm Bb C Dm A',
        mel: 'd6 - - c6 bb5 - g5 - | a5 - - - - - . . | f5 - - e5 d5 - a4 - | c5 - - - d5 - - . | f5 - - - bb5 - d6 - | e6 - - - c6 - g5 - | a5 - - - f5 - d5 - | e5 - - - c#5 - - .' },
    },
    forma: 'i> | A B A+ B~' },
  // GAUA: house en do menor, con la compresión del bombo
  disco: { bpm: 126, estilo: 'electro', inst: { lead: 'supersaw', lead2: 'pulso12' },
    sec: {
      i: { ch: 'Cm Ab Eb Bb' },
      A: { ch: 'Cm Ab Eb Bb Cm Bb Fm G',
        mel: 'c5 . eb5 . g5 . c6 . | bb5 - g5 . eb5 - . . | ab5 . c6 . eb6 . c6 . | bb5 - ab5 . g5 - . . | g5 . c6 . g5 . eb5 . | f5 - eb5 . d5 - . . | c5 . eb5 . f5 . ab5 . | g5 - - - b4 - d5 .' },
      B: { ch: 'Ab Bb Gm Cm Ab Bb G G',
        mel: 'c6 . c6 . eb6 . c6 . | d6 . d6 . f6 . d6 . | bb5 . g5 . d6 . bb5 . | c6 - - - g5 - - . | ab5 . c6 . eb6 . ab6 . | f6 . d6 . bb5 . f5 . | g5 . b5 . d6 . f6 . | g6 - - - . . . .' },
    },
    forma: 'i> | A B A+ B+ i- B+' },

  /* ---------- los momentos ---------- */
  // el título: el tema de Landrace Hunters, en re
  title: { bpm: 112, estilo: 'pop', inst: { lead: 'pulso', lead2: 'cuerdas' }, comp: [{ i: 'guitarra', t: 'rasgueo', p: 'd . d u . u d u', v: .5 }, { i: 'cuerdas', t: 'pad', v: .5 }],
    sec: {
      i: { ch: 'D A Bm G' },
      A: { ch: 'D A Bm G D A G:2 A:2 D',
        mel: 'f#5 - - e5 d5 - a4 - | e5 - - - c#5 - a4 . | d5 - - e5 f#5 - b5 - | b5 - - a5 g5 - - . | a5 - - f#5 d6 - - a5 | c#6 - - b5 a5 - e5 - | g5 - - - f#5 - e5 - | d5 - - - - - . .' },
      B: { ch: 'G A F#m Bm G A Bm A',
        mel: 'b5 - - - d6 - b5 - | c#6 - - - e6 - c#6 - | a5 - - - c#6 - f#6 - | f#6 - - e6 d6 - - . | d6 - - - b5 - g5 - | e6 - - - c#6 - a5 - | b5 - - - d6 - f#6 - | e6 - - - - - . .' },
    },
    forma: 'i> | A B A+ B+' },
  // los combates: el ladrón (la menor, la de siempre más larga)…
  battle: { bpm: 160, estilo: 'batalla', inst: { lead: 'pulso', lead2: 'cuadrada' },
    sec: {
      A: { ch: 'Am F:2 G:2 Am F:2 E:2 Am F:2 G:2 Am E',
        mel: 'a4 c5 e5 c5 a4 c5 e5 g5 | f5 e5 d5 c5 b4 c5 d5 b4 | a4 c5 e5 c5 a4 c5 e5 a5 | g5 f5 e5 d5 e5 . d#5 . | a4 c5 e5 c5 a4 c5 e5 g5 | f5 e5 d5 c5 b4 c5 d5 b4 | c5 e5 a5 e5 c6 a5 e6 c6 | b5 a5 g#5 f#5 e5 . . .' },
      B: { ch: 'Dm Dm Am Am F G E E',
        mel: 'd5 . f5 . a5 . d6 . | c6 . a5 . f5 . d5 . | e5 . a5 . c6 . e6 . | d6 c6 b5 a5 g5 a5 b5 c6 | a5 . . f5 a5 c6 f6 . | d6 . . b5 d6 . g6 . | e6 - - - g#5 - b5 - | e6 - - - e5 - - .' },
    },
    forma: '| A B A+ B+' },
  // …la policía (re menor, metales y sirena)…
  battle_police: { bpm: 150, estilo: 'batalla', inst: { lead: 'metales', lead2: 'pulso' },
    sec: {
      A: { ch: 'Dm Dm Bb A Dm Dm Bb:2 C:2 A7',
        mel: 'd5 . d5 . f5 . d5 . | a5 - - . g#5 . a5 . | bb5 . a5 . g5 . f5 . | e5 - - . c#5 - - . | d5 . d5 . f5 . a5 . | d6 - - . c6 . a5 . | bb5 . g5 . c6 . e5 . | a5 - - - c#6 - - .' },
      B: { ch: 'Gm Gm Dm Dm Eb Eb A A',
        mel: 'g5 - bb5 - g5 - bb5 - | d6 - - - c6 - bb5 . | a5 - f5 - a5 - f5 - | d6 - - - a5 - - . | g5 - bb5 - eb6 - g6 - | f6 - - - eb6 - d6 . | c#6 - e6 - c#6 - a5 - | e6 - - - - - . .' },
    },
    forma: '| A B A+ B+' },
  // …un rival de la calle (funk rápido en mi menor)…
  battle_rival: { bpm: 132, estilo: 'funk', inst: { lead: 'pulso12', lead2: 'clavi' },
    sec: {
      A: { ch: 'Em7 Em7 A7 A7 Em7 Em7 C7 B7',
        mel: 'e5 . . g5 . e5 b4 . | d5 . e5 . g5 . a5 . | c#6 . . a5 . g5 e5 . | g5 . a5 . c#6 . e6 . | e6 . . d6 . b5 g5 . | a5 . g5 . e5 . d5 . | e5 . g5 . bb5 . g5 . | a5 - - - d#5 - f#5 .' },
      B: { ch: 'Am7 D7 Gmaj7 Cmaj7 F#m7b5 B7 Em7 B7',
        mel: 'c6 . . a5 . e5 g5 . | f#5 . a5 . c6 . d6 . | b5 . . f#5 . d5 g5 . | e5 . g5 . b5 . e6 . | c6 - - . a5 . f#5 . | d#5 - f#5 - a5 - b5 . | g5 . . e5 . b4 d5 . | f#5 - - - d#5 - . .' },
    },
    forma: '| A B A+ B+' },
  // …y Darko (si menor armónica, órgano)
  battle_darko: { bpm: 168, estilo: 'batalla', inst: { lead: 'organo', lead2: 'metales' },
    sec: {
      A: { ch: 'Bm Bm G F#7 Bm Bm Em F#7',
        mel: 'b4 d5 f#5 d5 b4 d5 f#5 b5 | a#5 b5 c#6 b5 a#5 f#5 c#5 f#5 | g5 f#5 e5 d5 e5 f#5 g5 b5 | a#5 - - - c#6 - - . | b5 . f#5 . d5 . b4 . | d6 c#6 b5 a#5 b5 . f#5 . | g5 . b5 . e6 . g6 . | f#6 - e6 - c#6 - a#5 -' },
      B: { ch: 'Em Em C C Am F#7 Bm F#7',
        mel: 'e5 . g5 . b5 . e6 . | d6 c6 b5 a5 g5 . e5 . | e5 . g5 . c6 . e6 . | d6 - c6 - b5 - g5 - | a5 . c6 . e6 . a6 . | g6 - f#6 - e6 - c#6 - | d6 - b5 - f#5 - d5 - | c#5 - - - e5 - a#4 -' },
    },
    forma: '| A B A+ B+' },
  // la alarma: te persigue un agente (fa sostenido menor, sirena)
  alarma: { bpm: 150, estilo: 'tension', inst: { lead: 'cuadrada', lead2: 'metales' },
    sec: {
      A: { ch: 'F#m F#m D E F#m F#m D C#7',
        mel: 'c#6 - - - a5 - - - | c#6 - - - a5 - - - | d6 - - - a5 - f#5 - | e6 - - - b5 - g#5 - | f#6 - - - c#6 - - - | a5 - c#6 - f#6 - e6 - | d6 - - - f#6 - a6 - | g#6 - - - e#6 - c#6 -' },
      B: { ch: 'Bm Bm F#m F#m D E F#m C#7',
        mel: 'd6 . c#6 . b5 . f#5 . | b5 . a5 . f#5 . d5 . | c#6 . b5 . a5 . f#5 . | a5 . g#5 . f#5 . c#5 . | d6 . f#6 . a6 . f#6 . | e6 . g#6 . b6 . g#6 . | a6 - - - f#6 - - . | e#6 - - - g#6 - - .' },
    },
    forma: '| A B A+ B+' },
  // la redada: timbales y cuerdas, en do menor
  redada: { bpm: 80, estilo: 'drama', inst: { lead: 'cuerdas', lead2: 'piano' },
    sec: {
      A: { ch: 'Cm Cm Ab Ab Fm Fm G G',
        mel: 'g5 - - - - - eb5 - | d5 - - - c5 - - . | c6 - - - - - ab5 - | g5 - - - eb5 - - . | f5 - - - ab5 - c6 - | eb6 - - - d6 - c6 - | b5 - - - d6 - - - | g5 - - - - - . .' },
      B: { ch: 'Ab Ab Eb Eb Fm G Cm G',
        mel: 'c6 - - - eb6 - - - | ab5 - - - c6 - - . | bb5 - - - g5 - - - | eb5 - - - - - . . | f5 - - - ab5 - c6 - | b5 - - - d6 - - . | c6 - - - g5 - eb5 - | d5 - - - b4 - - .' },
    },
    forma: '| A B A+ B+' },
  // el final: balada en do, piano y cuerdas
  final: { bpm: 76, estilo: 'balada', inst: { lead: 'piano', lead2: 'cuerdas' },
    sec: {
      i: { ch: 'C G Am F' },
      A: { ch: 'C G Am Em F C Dm:2 G:2 C',
        mel: 'e5 - - - g5 - c6 - | b5 - - - d5 - g5 - | a5 - - - c6 - e6 - | d6 - - - b5 - g5 - | a5 - - - c6 - f6 - | e6 - - - c6 - g5 - | f5 - a5 - g5 - b5 - | c6 - - - - - . .' },
      B: { ch: 'F G Em Am F G C C',
        mel: 'a5 - - - c6 - - b5 | b5 - - - d6 - - . | g5 - - - b5 - e6 - | c6 - - - - - a5 - | f5 - - - a5 - c6 - | d6 - - - b5 - g5 - | e5 - - - g5 - c6 - | c6 - - - - - - .' },
    },
    forma: 'i> | A B A+ B+' },
};
module.exports = { TEMAS };
