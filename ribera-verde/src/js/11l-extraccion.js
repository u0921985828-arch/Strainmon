/* ---------- las extracciones (1.35, lo pidió el usuario) ----------
   En la mesa del piso y sin disolventes: el rosin (la prensa), el dry sift (los tamices de seda), el Ice-o-lator (agua con hielo
   y las bolsas de malla), el charas (a mano), el hachís prensado (del kief del tamiz o del hielo) y el moonrock, lo más difícil
   (un cogollo bañado en rosin y rebozado en kief). Cada una es una tanda de barras (tiroBillar con 'dir': parar en el verde, de
   ancho a; per, lo que tarda la barra en ir y volver): la calidad q es la parte de las que entran, y sale rend × (0,6 + 0,4 q)
   del peso con thc × (0,9 + 0,1 q) veces el THC, hasta tope. Bien hecho, el rosin da lo de siempre (ROSIN). Los lotes van en
   S.rosin: el rosin con la clave del cogollo y los demás con «~tipo» detrás (lotSid lo quita). Los catadores compran de todo, a
   precioRosin × px. Cifras reales: dry sift 5-15 % de la flor y 30-60 % de THC; Ice-o-lator 3-15 % y 40-70 %; charas, poco
   y 25-50 %; el prensado, el kief tal cual; el moonrock, el THC de lo que lleva. */
const EXTR={
  rosin:{n:'Rosin',v:'Prensar rosin',item:'prensa',de:'flor',rend:ROSIN.rend,thc:ROSIN.thc,tope:ROSIN.tope,px:1,min:30,per:1400,
    d:'La prensa: papel de horno, la flor en su bolsa y las planchas calientes.',
    pasos:[['La temperatura: para la barra en el verde.',.12],['Ahora la presión: en el verde, sin pasarte.',.12]]},
  seco:{n:'Dry sift',v:'Tamizar en seco',item:'tamiz',de:'flor',rend:.1,thc:2.2,tope:60,px:.8,min:40,per:1300,kief:1,
    d:'Los tamices de seda, de grueso a fino: la flor muy seca y fría, y se sacude con cuidado.',
    pasos:[['El tamiz grueso: sacude en el verde.',.14],['El de en medio, más fino.',.12],['El fino: solo las cabezas de resina.',.1]]},
  ice:{n:'Ice-o-lator',v:'Ice-o-lator',item:'ice',de:'flor',rend:.12,thc:2.8,tope:70,px:1,min:90,per:1300,kief:1,
    d:'El cubo con agua y hielo y las bolsas de malla: se bate, se deja reposar y se recoge la resina.',
    pasos:[['El hielo: el agua a su punto de frío.',.12],['Batir: en el verde, sin romper la flor.',.1],['Filtrar por las bolsas.',.1],['Secar la resina sin que coja moho.',.1]]},
  charas:{n:'Charas',v:'Frotar charas',de:'flor',rend:.04,thc:2,tope:50,px:.85,min:60,per:1200,
    d:'A mano: frotas los cogollos frescos entre las palmas hasta que la resina se pega, y la amasas.',
    pasos:[['Frotar: en el verde, sin aplastar.',.12],['Rascar la resina de las palmas.',.1],['Amasarla en una bola.',.1]]},
  hash:{n:'Hachís prensado',v:'Prensar hachís',de:'kief',rend:.9,thc:1,tope:75,px:.9,min:20,per:1300,
    d:'El kief en papel de horno, con calor y presión, hasta que se hace una placa.',
    pasos:[['El calor: tibio, en el verde.',.12],['La presión.',.12]]},
  moon:{n:'Moonrock',v:'Hacer moonrock',de:'moon',rend:1.3,thc:1,tope:80,px:1.3,min:45,per:800,
    d:'Lo más difícil: el cogollo bañado en rosin caliente y rebozado en kief, sin que se apelmace.',
    pasos:[['Calentar el rosin hasta que corra.',.06],['Bañar el cogollo.',.06],['Rebozarlo en el kief.',.06],['Secarlo sin que se pegue.',.06]]},
};
const MOON={oil:.1,kief:.2};   // por gramo de cogollo: 0,1 g de rosin y 0,2 g de kief
const extrAlgo=()=>!!(S.items.prensa||S.items.tamiz||S.items.ice);   // algún aparato: catadores en la calle y el extracto en la caja
const tipoExtr=k=>k.split('~')[1]||'rosin',baseExtr=k=>k.split('~')[0];
const kiefLots=min=>rosinLots(min).filter(([k])=>EXTR[tipoExtr(k)].kief);
const mayorLote=l=>l.reduce((a,x)=>!a||x[1].g>a[1].g?x:a,null);
// las que puedes hacer: la de cada aparato, el charas con cualquiera de ellos (ya sabes de esto), el prensado con kief que sacar y
// el moonrock con la prensa y kief
function extrYa(){
  const it=S.items,algo=extrAlgo(),kf=it.tamiz||it.ice;
  return Object.keys(EXTR).filter(t=>({rosin:it.prensa,seco:it.tamiz,ice:it.ice,charas:algo,hash:kf,moon:it.prensa&&kf})[t]);
}
const saleExtr=(E,g,q)=>Math.max(.1,Math.round(g*E.rend*(.6+.4*q)*10)/10);
async function extraer(t){
  const E=EXTR[t],kief=E.de==='kief',N=E.n.toUpperCase();
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
  for(const [tx,a] of E.pasos)if(Math.abs(await tiroBillar(tx,'dir',a,E.per,N)-BILLAR.centro)<=a)ok++;
  const q=ok/E.pasos.length,r=saleExtr(E,g,q);
  let thc=b.thc;
  if(oil){const o=Math.round(g*MOON.oil*10)/10,m=Math.round(g*MOON.kief*10)/10;thc=(b.thc*g+oil[1].thc*o+kf[1].thc*m)/(g+o+m);useRosin(oil[0],o);useRosin(kf[0],m);}
  thc=Math.min(E.tope,thc*E.thc*(.9+.1*q));
  if(kief)useRosin(k,g);else useBuds(k,g);
  addRosin(t==='rosin'?k:baseExtr(k)+'~'+t,r,thc);advanceTime(E.min);sfx('get');
  await say(`${q>=1?'Te sale perfecto':q>=.5?'Te sale bien, con algo de pérdida':'Te sale regular: pierdes bastante'}. ${E.n} de ${lotNombre(baseExtr(k))}: ${coma(r)} g con un ${pct(thc)} % de THC.`);
}
