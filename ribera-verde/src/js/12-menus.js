/* =========================================================
   MENÚ START
   ========================================================= */
async function startMenu(){
  let i=0;
  for(;;){
    i=await menu(['GENOTECA','MOCHILA','MÓVIL','PLANTAS','OBJETIVO','GUARDAR',soundOn?'SONIDO: SÍ':'SONIDO: NO','SALIR'],{cls:'start',initial:i,startCloses:true});
    if(i<0||i===7)return;
    if(i===0)await genoteca();else if(i===1)await mochila();else if(i===2)await movilMenu();else if(i===3)await plantas();
    else if(i===4){await say(`CAPÍTULO ${S.ch}: ${CH_TITLES[S.ch]||''}\n${objectiveText()}`);await say(`Deuda: ${eur(S.debt)} · Ventas: ${eur(S.sales)}\nReputación ${S.rep} · Calor ${Math.round(S.heat)}%`);}
    else if(i===5)await say(save()?'Partida guardada.':'No se ha podido guardar en este navegador.');
    else if(i===6)setSound(!soundOn);
  }
}
async function genoteca(){
  const items=DEX.map((k,n)=>{const s=STRAINS[k],nn=String(n+1).padStart(2,'0');return S.disc[k]?{label:`${nn} ${s.n}`,right:pct(s.thc)+'%',sw:s.c,ic:iconoCogollo(k),desc:strainLine(k)+(s.h?'\n'+s.h:'')}:{label:`${nn} ??????`,desc:'Sin descubrir.'};});
  const cust=Object.keys(S.custom).filter(k=>S.disc[k]);
  cust.forEach(k=>{const s=S.custom[k];items.push({label:'★ '+s.n,right:pct(s.thc)+'%',sw:s.c,ic:iconoCogollo(k),desc:strainLine(k)});});
  let i=0;
  do{i=await menu(items,{cls:'full',title:'GENOTECA',title2:`${DEX.filter(k=>S.disc[k]).length}/${DEX.length} · ${cust.length} propias`,desc:true,initial:i});}while(i>=0);
}
async function mochila(){
  let i=0;
  for(;;){
    const M=MOCHILAS[S.items.bolsa||0];
    const rows=[{label:'Dinero',right:eur(S.money),ic:icono('billetes'),desc:'Lo que llevas encima. Don Baltasar también lo cuenta.'},
      {label:M.n,right:`${Math.floor(pesoEncima())} de ${kgTxt(M.g)}`,ic:icono('bolsa'),desc:'Cogollos y rosin que llevas encima. Lo que no cabe al cosechar va al arcón de casa.'}].concat(arconG()>=1||arconR()>=.1?[{label:'Arcón',right:arconTxt(),ic:icono('cogollo'),
      desc:'En casa, entre la cama y la nevera. Un control en la calle no lo ve; una redada se lo lleva.'}]:[],S.caja?[{label:'Caja fuerte',right:`${eur(cajaE())} · ${Math.floor(cajaG())} g${cajaR()>=.1?' · '+coma(Math.round(cajaR()*10)/10)+' g rosin':''}`,ic:icono('billetes'),
      desc:`${CAJA[S.caja.nivel].n}, detrás del diploma. Caben ${eur(CAJA[S.caja.nivel].money)} y ${kgTxt(CAJA[S.caja.nivel].g)}.\nLo que está dentro no lo llevas encima.`}]:[],[{label:'Vida',right:`${S.hp}/${S.hpMax}`,desc:'Se recupera durmiendo, comiendo o con el tiempo.'},
      {label:'Abono (dosis)',right:'×'+S.items.fert,ic:icono('abono'),desc:'Una por planta: +25% de cosecha.'},{label:'Insecticida (tratamientos)',right:'×'+S.items.insect,ic:icono('insecticida'),desc:'Úsalo en una maceta con plaga.'},
      {label:'Spray de pimienta',right:'×'+S.items.spray,ic:icono('spray'),desc:'Solo en combate.'},{label:'Bocata',right:'×'+S.items.bocata,ic:icono('bocadillo'),desc:'Pulsa A para comerlo: +15 de vida.',k:'bocata'}]);
    for(const k in MACETAS)if(S.items['m_'+k]>0)rows.push({label:'Maceta '+MACETAS[k].n,right:'×'+S.items['m_'+k],ic:icono('maceta'),desc:descMaceta(k)+'\nSe cambia en una plaza vacía de la carpa.'});
    for(const k in FOCOS)if(S.items['f_'+k]>0)rows.push({label:'Foco '+FOCOS[k].n,right:'×'+S.items['f_'+k],ic:icono('lampara'),desc:descFoco(k)+'\nSe cuelga desde la vista de carpa: ▲ hasta el foco y A.'});
    for(const k in EXTRAS)if(S.items['x_'+k]>0)rows.push({label:EXTRAS[k].n,right:'×'+S.items['x_'+k],desc:EXTRAS[k].d+`\nSe pone${EXTRAS[k].pl?'n':''} desde la vista de carpa: ▲ hasta el foco y A.`});
    for(const [k,v] of Object.entries(S.seeds))rows.push({label:'Semilla '+getStrain(k).n,right:'×'+v,sw:getStrain(k).c,ic:icono('semillas'),desc:strainLine(k)});
    for(const e of S.esquejes)rows.push({label:'Esqueje '+getStrain(e.sid).n+marcaFeno(e.f),right:'día '+(e.dia+ESQUEJE_DIAS),sw:getStrain(e.sid).c,ic:iconoCogollo(e.sid),desc:`Enraizando en el propagador. Plántalo en una plaza vacía antes de que acabe el día ${e.dia+ESQUEJE_DIAS}.`});
    for(const [k,b] of Object.entries(S.buds))rows.push({label:lotNombre(k),right:`${Math.floor(b.g)} g · ${pct(b.thc)}%`,sw:getStrain(lotSid(k)).c,ic:iconoCogollo(lotSid(k)),desc:(k.endsWith('*')?'Cogollos de un fenotipo estrella, en lote aparte.\n':'Cogollos listos para vender.\n')+getStrain(lotSid(k)).o});
    for(const [k,b] of Object.entries(S.rosin))rows.push({label:'Rosin · '+lotNombre(k),right:`${coma(b.g)} g · ${pct(b.thc)}%`,sw:'#d89a18',ic:iconoCogollo(lotSid(k)),desc:'Rosin: extracción prensada sin disolventes. Lo compran los catadores.\n'+getStrain(lotSid(k)).o});
    if(S.items.prensa)rows.push({label:'Prensa de rosin',right:'en la mesa',desc:'De 5 g de cogollo, 1 g de rosin con el triple de THC. Se usa en la mesa del piso.'});
    i=await menu(rows,{cls:'full',title:'MOCHILA',title2:`${Math.floor(totalBuds())} g encima`+(S.caja?` · ${Math.floor(cajaG())} g en la caja`:''),desc:true,initial:i});
    if(i<0)return;
    if(rows[i].k==='bocata'){if(S.items.bocata>0&&S.hp<S.hpMax){S.items.bocata--;S.hp=Math.min(S.hpMax,S.hp+15);sfx('get');toast('Te comes el bocata. +15 de vida',1200);}else sfx('bump');}
  }
}
async function plantas(){
  const rows=[],H=huecos(),cl=climaSala();
  rows.push({label:'Sala',right:S.sala.termo?tClima(cl):'¿?',desc:S.sala.termo?salaDesc():'Sin termohigrómetro no sabes la temperatura ni la humedad de la sala. Kiko lo vende.'});
  S.carpas.forEach((c,ci)=>{
    if(!c)return;const C=CARPAS[c.t],F=FOCOS[c.foco],wm2=Math.round(F.w/(C.cm[0]*C.cm[2]/1e4));
    rows.push({label:C.n,right:F.n,ic:icono('lampara'),desc:`${C.plazas} plantas · foco ${F.n}, ${wm2} W/m²${wm2<W_M2?' (poca luz: crecen más despacio y con menos THC)':''}\nLuz: ${eur(luzCarpa(ci))} al día con plantas · hasta ${C.wmax} W, macetas de ${C.lmax} L y ${litrosMax(ci)} L de tierra (${litrosCarpa(ci)} puestos).`});
    H.forEach((h,i)=>{if(h.c!==ci)return;const p=S.pots[i],M=MACETAS[S.macetas[i]];
      if(!p){rows.push({label:`  ${h.j+1} · vacía`,right:M.l+' L',ic:icono('maceta'),desc:`Maceta de ${M.n}. Planta algo desde la carpa de tu piso.`});return;}
      const s=getStrain(p.sid);
      rows.push({label:`  ${h.j+1} · ${s.n}${marcaFeno(p.f)}`,sw:s.c,ic:iconoCogollo(p.sid),right:p.dead?'muerta':p.prog>=1?'LISTA':`${Math.floor(p.prog*100)}%`,desc:p.dead?'Se ha secado. Retírala.':`${p.prog>=1?'Lista para cosechar':stageName(p)} · Agua ${Math.round(p.water)}% · Salud ${Math.round(p.health)}%\n${p.pest?'PLAGA: trátala con insecticida. ':''}${p.fert?'Abonada':'Sin abonar'} · maceta de ${M.n}.`});});
  });
  const luz=facturaLuz();
  let i=0;do{i=await menu(rows,{cls:'full',title:'CULTIVO',title2:luz?'Luz '+eur(luz)+'/día':'Luz apagada',desc:true,initial:i});}while(i>=0);
}
