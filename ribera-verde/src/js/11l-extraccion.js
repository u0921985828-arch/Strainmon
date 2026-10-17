/* ---------- las extracciones (1.35, lo pidió el usuario) ----------
   En la mesa del piso y sin disolventes: el rosin (la prensa), el dry sift (los tamices de seda), el Ice-o-lator (agua con hielo
   y las bolsas de malla), el charas (a mano), el hachís prensado (del kief del tamiz o del hielo) y el moonrock, lo más difícil
   (un cogollo bañado en rosin y rebozado en kief). Cada una es una tanda de barras (tiroBillar con 'dir': parar en el verde, de
   ancho a; per, lo que tarda la barra en ir y volver): la calidad q es la parte de las que entran, y sale rend × (0,6 + 0,4 q)
   del peso con thc × (0,9 + 0,1 q) veces el THC, hasta tope. Bien hecho, el rosin da lo de siempre (ROSIN). Los lotes van en
   S.rosin: el rosin con la clave del cogollo y los demás con «~tipo» detrás (lotSid lo quita). Los catadores compran de todo, a
   precioRosin × px. Cifras reales: dry sift 5-15 % de la flor y 30-60 % de THC; Ice-o-lator 3-15 % y 40-70 %; charas, poco
   y 25-50 %; el prensado, el kief tal cual; el moonrock, el THC de lo que lleva. 1.36 (lo pidió el usuario): los pasos, como se hace de
   verdad (guías de los fabricantes): rosin de flor a 80-100 °C en bolsa de 90-120 micras, apretando despacio; dry sift de flor
   congelada por 220/160/120/73 micras; Ice-o-lator con hielo y agua a partes iguales por debajo de 4 °C, 15-20 min de batido suave,
   reposo y bolsas de grueso a fino (en cubo o en una lavadora de carga superior, que desagua por la manguera); static, la flor
   tamizada en frío y una placa cargada que levanta las cabezas; charas, frotado a mano; prensado, kief con calor suave. */
const EXTR={
  rosin:{n:'Rosin',v:'Prensar rosin',item:'prensa',de:'flor',rend:ROSIN.rend,thc:ROSIN.thc,tope:ROSIN.tope,px:1,min:30,per:1400,
    d:'La prensa: las planchas a 80-100 °C y la flor sin moler en una bolsa de 90-120 micras, entre papel de horno.',
    pasos:[['Precalentar las planchas: para la barra en el verde.',.12],['Apretar despacio: la presión sube poco a poco, sin reventar la bolsa.',.12],['Soltar a tiempo y sacar el papel del calor.',.14]]},
  seco:{n:'Dry sift',v:'Tamizar en seco',item:'tamiz',de:'flor',rend:.1,thc:2.2,tope:60,px:.8,min:40,per:1300,kief:1,
    d:'Los tamices, de grueso a fino (220, 160, 120 y 73 micras): la flor seca, congelada desde el día antes, y se sacude con suavidad.',
    pasos:[['220 micras: fuera el polvo verde y los trozos.',.14],['160: sacude en el verde, sin frotar.',.12],['120 y 73: aquí se quedan las cabezas de resina.',.1]]},
  ice:{n:'Ice-o-lator',v:'Ice-o-lator',item:'ice',de:'flor',rend:.12,thc:2.8,tope:70,px:1,min:90,per:1300,kief:1,
    d:'El cubo de 20 L con las bolsas de malla: hielo y agua a partes iguales, por debajo de 4 °C, y la flor congelada.',
    pasos:[['El agua con hielo, entre 1 y 3 °C: para la barra en el verde.',.12],['Remover suave unos 15 minutos, sin romper la hoja.',.1],['Reposar y colar por las bolsas, de la gruesa a la fina.',.1],['Secar la resina en frío, desmenuzada, sin que coja moho.',.1]]},
  charas:{n:'Charas',v:'Frotar charas',de:'flor',rend:.04,thc:2,tope:50,px:.85,min:60,per:1200,
    d:'A mano, como en el Himalaya: frotas las flores frescas entre las palmas hasta que la resina se pega, la rascas y la amasas.',
    pasos:[['Frotar: en el verde, sin aplastar.',.12],['Rascar la resina de las palmas.',.1],['Amasarla en una bola.',.1]]},
  hash:{n:'Hachís prensado',v:'Prensar hachís',de:'kief',rend:.9,thc:1,tope:75,px:.9,min:20,per:1300,
    d:'El kief entre papel de horno, con calor suave y presión, hasta que se hace una placa: poco calor no la liga y mucho la estropea.',
    pasos:[['El calor: tibio, en el verde.',.12],['La presión.',.12]]},
  moon:{n:'Moonrock',v:'Hacer moonrock',de:'moon',rend:1.3,thc:1,tope:80,px:1.3,min:45,per:800,
    d:'Lo más difícil: el cogollo bañado en rosin caliente y rebozado en kief, sin que se apelmace.',
    pasos:[['Calentar el rosin hasta que corra.',.06],['Bañar el cogollo.',.06],['Rebozarlo en el kief.',.06],['Secarlo sin que se pegue.',.06]]},
  // 1.36 (lo pidió el usuario): la lavadora de extracción, el Ice-o-lator en grande (sale ice); su minijuego, la barra que cambia de
  // ritmo (ritmo, de 0 a 1)
  lava:{n:'Ice-o-lator',v:'Ice-o-lator en la lavadora',item:'lavadora',sale:'ice',de:'flor',rend:.14,thc:2.9,tope:72,px:1,min:60,per:1200,ritmo:.6,kief:1,
    d:'La lavadora de extracción, de carga superior y cuba de plástico: hielo y agua a partes iguales y la flor congelada, a baja velocidad.',
    pasos:[['Cargarla: el agua con hielo por debajo de 4 °C.',.12],['El lavado, 15 minutos a baja velocidad: la barra cambia de ritmo.',.1],['Reposo de unos minutos y desaguar por la manguera a las bolsas.',.1],['Recoger cada bolsa aparte: 120, 90 y 73 micras.',.1]]},
  // la máquina de static, la inversión fuerte; su minijuego, el verde que se mueve (mov, ms de ida y vuelta)
  stat:{n:'Static',v:'Hacer static',item:'estatica',de:'flor',rend:.06,thc:3.4,tope:85,px:1.4,min:60,per:1100,mov:2600,kief:1,
    d:'La máquina electrostática: la flor congelada se tamiza a la bandeja y la placa cargada, encima, levanta las cabezas de resina; la hoja se queda.',
    pasos:[['Tamizar la flor fría a la bandeja: el verde se mueve.',.1],['Cargar la placa.',.08],['La altura: que suban las cabezas y no la hoja.',.08],['Rascar la placa con la tarjeta.',.08]]},
};
const SECO00={thc:2.6,tope:70,paso:['La 00, la más fina: solo las cabezas más limpias.',.08]};   // 1.36: con las mallas 00, el dry sift «doble cero»
const MOON={oil:.1,kief:.2};   // por gramo de cogollo: 0,1 g de rosin y 0,2 g de kief
const extrAlgo=()=>!!(S.items.prensa||S.items.tamiz||S.items.mallas00||S.items.ice||S.items.lavadora||S.items.estatica);   // algún aparato: catadores en la calle y el extracto en la caja
const TIPOS_EXTR=()=>Object.keys(EXTR).filter(t=>!EXTR[t].sale);   // los pisos de la nevera (lo que tiene «sale», como la lavadora, que da ice, no)
const tipoExtr=k=>k.split('~')[1]||'rosin',baseExtr=k=>k.split('~')[0];
const kiefLots=min=>rosinLots(min).filter(([k])=>EXTR[tipoExtr(k)].kief);
const mayorLote=l=>l.reduce((a,x)=>!a||x[1].g>a[1].g?x:a,null);
// las que puedes hacer: la de cada aparato, el charas con cualquiera de ellos (ya sabes de esto), el prensado con kief que sacar y
// el moonrock con la prensa y kief
function extrYa(){
  const it=S.items,algo=extrAlgo(),kf=it.tamiz||it.mallas00||it.ice||it.lavadora||it.estatica;
  return Object.keys(EXTR).filter(t=>({rosin:it.prensa,seco:it.tamiz||it.mallas00,ice:it.ice,charas:algo,hash:kf,moon:it.prensa&&kf,lava:it.lavadora,stat:it.estatica})[t]);
}
const saleExtr=(E,g,q)=>Math.max(.1,Math.round(g*E.rend*(.6+.4*q)*10)/10);
async function extraer(t){
  const E=t==='seco'&&S.items.mallas00?Object.assign({},EXTR.seco,SECO00,{pasos:EXTR.seco.pasos.concat([SECO00.paso])}):EXTR[t],kief=E.de==='kief',N=E.n.toUpperCase();
  const lots=kief?kiefLots(1):budLots(5);
  if(!lots.length)return say(`${N}: necesitas ${kief?'1 g de kief, del tamiz o del Ice-o-lator,':'5 g de cogollos'} como mínimo.`);
  let oil=null,kf=null;
  if(t==='moon'){oil=mayorLote(rosinLots(MOON.oil).filter(([k])=>tipoExtr(k)==='rosin'));kf=mayorLote(kiefLots(MOON.kief));
    if(!oil||!kf)return say('MOONROCK: necesitas rosin para bañar el cogollo y kief para rebozarlo.');}
  const i=await menu(lots.map(kief?rosinItem:lotItem).concat([{label:'Nada'}]),{cls:'right',title:`${E.n}: ¿de qué?`});
  if(i<0||i>=lots.length)return;
  const [k,b]=lots[i];
  let tope=kief?Math.floor(b.g):Math.floor(b.g);
  if(oil)tope=Math.min(tope,Math.floor(oil[1].g/MOON.oil+1e-9),Math.floor(kf[1].g/MOON.kief+1e-9));
  if(tope<1)return say('MOONROCK: no te llega el rosin o el kief para un gramo.');
  const ops=(kief?[1,5,25]:oil?[1,3,10]:[5,25,100]).filter(g=>g<tope).concat([tope]);
  const j=await ask(`${kief?E.n+' · '+lotNombre(k):lotNombre(k)}: ${tope} g. ¿Cuánto usas?`,ops.map(g=>`${g} g → ${coma(saleExtr(E,g,1))} g de ${E.n.toLowerCase()}`).concat(['Nada']));
  if(j<0||j>=ops.length)return;
  const g=ops[j];
  await say(E.d,N);
  let ok=0;
  for(const [tx,a] of E.pasos)if(Math.abs(await tiroBillar(tx,'dir',a,E.per,N,E)-BILLAR.centro)<=a)ok++;
  const q=ok/E.pasos.length,r=saleExtr(E,g,q);
  let thc=b.thc;
  if(oil){const o=Math.round(g*MOON.oil*10)/10,m=Math.round(g*MOON.kief*10)/10;thc=(b.thc*g+oil[1].thc*o+kf[1].thc*m)/(g+o+m);useRosin(oil[0],o);useRosin(kf[0],m);}
  thc=Math.min(E.tope,thc*E.thc*(.9+.1*q));
  if(kief)useRosin(k,g);else useBuds(k,g);
  addRosin(t==='rosin'?k:baseExtr(k)+'~'+(E.sale||t),r,thc);advanceTime(E.min);sfx('get');
  await say(`${q>=1?'Te sale perfecto':q>=.5?'Te sale bien, con algo de pérdida':'Te sale regular: pierdes bastante'}. ${E.n} de ${lotNombre(baseExtr(k))}: ${coma(r)} g con un ${pct(thc)} % de THC.`);
}
