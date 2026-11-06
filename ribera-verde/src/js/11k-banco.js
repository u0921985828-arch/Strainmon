/* =========================================================
   EL BANCO, LOS RECIBOS Y LOS LOCALES (1.35, lo pidió el usuario)
   ========================================================= */
// Dos dineros: el efectivo (S.money, el de la calle: negro) y la cuenta del banco (S.banco, limpio). Con tarjeta, de la cuenta, se
// paga lo que deja rastro: la tienda online (muebles, vehículos y reformas), el banco de semillas del ordenador y los locales; la luz,
// domiciliada (de la cuenta y, si no llega, del efectivo y de la caja). En el cajero (cajero: barrio, Puerto Viejo, Valdehierro e
// Ibarbide) se saca hasta CUENTA.sacar al día y se ingresa efectivo hasta CUENTA.ingreso al día sin que el banco pregunte. Los
// movimientos (S.mov, los CUENTA.mov últimos) y los recibos que vienen, en el móvil → BANCA
const CUENTA={inicial:300,sacar:600,ingreso:400,mov:20,pasos:[20,50,100,200,500]};
function movimiento(t,e){S.mov.unshift({d:S.day,t,e:Math.round(e)});if(S.mov.length>CUENTA.mov)S.mov.length=CUENTA.mov;}
function cobroBanco(e,t){if(S.banco<e)return false;S.banco-=e;movimiento(t,-e);return true;}
function abonoBanco(e,t){S.banco+=e;movimiento(t,e);}
// un recibo domiciliado que no puede fallar (la luz): lo que haya en la cuenta y el resto como pagarCasa; devuelve lo que falta
function pagarRecibo(e,t){const b=Math.min(S.banco,e);if(b>0){S.banco-=b;movimiento(t,-b);}return pagarCasa(e-b);}
// con tarjeta: false (y el aviso) si no hay saldo
async function tarjeta(e,t){if(cobroBanco(e,t))return true;sfx('bad');await say(`La tarjeta no pasa: en la cuenta tienes ${eur(S.banco)}. Ingresa efectivo en un cajero.`);return false;}
const sacado=()=>S.saca&&S.saca.d===S.day?S.saca.e:0,ingresado=()=>S.ingr&&S.ingr.d===S.day?S.ingr.e:0;
// cuánto: las cantidades de CUENTA.pasos por debajo del tope y el tope; 0 si nada
async function cantidad(t,max){
  const v=CUENTA.pasos.filter(x=>x<max).concat(max>=1?[max]:[]),i=await ask(t,v.map(eur).concat(['Nada']));
  return i>=0&&i<v.length?v[i]:0;
}
async function cajero(){
  for(;;){
    const ops=['Sacar','Ingresar','Movimientos','Salir'],op=ops[await ask(`CAJERO · en la cuenta tienes ${eur(S.banco)}.`,ops)];
    if(op==='Sacar'){const max=Math.floor(Math.min(S.banco,CUENTA.sacar-sacado()));
      if(max<1){sfx('bad');await say(S.banco<1?'No hay saldo.':`Hoy ya has sacado ${eur(sacado())}: es el tope del cajero.`);continue;}
      const e=await cantidad(`¿Cuánto sacas? Hoy, hasta ${eur(max)}.`,max);if(!e)continue;
      S.saca={d:S.day,e:sacado()+e};S.banco-=e;S.money+=e;movimiento('Cajero',-e);sfx('coin');updateHUD();}
    else if(op==='Ingresar'){const max=Math.floor(Math.min(S.money,CUENTA.ingreso-ingresado()));
      if(max<1){sfx('bad');await say(S.money<1?'No llevas efectivo.':`Hoy ya has ingresado ${eur(ingresado())}. Más, y el banco pregunta de dónde sale.`);continue;}
      const e=await cantidad(`¿Cuánto ingresas? Sin preguntas, hasta ${eur(CUENTA.ingreso)} al día.`,max);if(!e)continue;
      S.ingr={d:S.day,e:ingresado()+e};S.money-=e;S.banco+=e;movimiento('Ingreso en efectivo',e);sfx('coin');updateHUD();}
    else if(op==='Movimientos')await banca();
    else return;
  }
}
// los recibos que vienen: [quién, día, €, cómo], por día
function recibos(){
  const r=[];
  if(S.nave)r.push(['Nave de Valdehierro',S.nave.r,RECIBO.nave(),'efectivo']);
  if(S.setas)r.push(['Bajo de la Kale Zaharra',S.setas.r,RECIBO.setas(),'efectivo']);
  for(const k in S.loc)r.push([LOCALES[k].n,S.loc[k].r,LOCALES[k].sem,'cuenta']);
  if(S.protect&&S.protHasta)r.push(['Sargento Molina',S.protHasta+1,SOBORNO,'mano']);
  return r.sort((a,b)=>a[1]-b[1]);
}
const COMO={cuenta:'de la cuenta',efectivo:'en efectivo',mano:'en mano, en la comisaría'};
async function banca(){
  const it=recibos().map(([n,d,e,c])=>({label:'Recibo · '+n,right:eur(e),desc:`El día ${d}, ${COMO[c]}.`}))
    .concat(S.mov.map(m=>({label:m.t,right:(m.e<0?'−':'+')+eur(Math.abs(m.e)),desc:`Día ${m.d}.`})));
  it.push({label:'Salir',desc:`Ingresos en efectivo: hasta ${eur(CUENTA.ingreso)} al día sin preguntas (hoy, ${eur(ingresado())}).`});
  await menu(it,{cls:'full',title:'BANCA',title2:'Saldo '+eur(S.banco),desc:true});
}

// Los recibos (RECIBO): cada RECIBO.dias, el día o.r. Arrieta (la nave) y Txomin (el bajo) cobran en efectivo, de lo que llevas y de
// la caja, y avisan por SMS (RECIBO.aviso días antes); si no está, vuelven al día siguiente (RECIBO.gracia) y después cambian la
// cerradura. Los locales, domiciliados: el banco avisa y, si no hay saldo, lo devuelve; a los RECIBO.graciaB días, el local se pierde
// con la fianza. Molina avisa RECIBO.aviso días antes de que se acabe lo pagado
const RECIBO={dias:7,aviso:2,gracia:1,graciaB:3,nave:()=>RECIBO.dias*NAVE.dia,setas:()=>RECIBO.dias*SETAS.dia};
// o.r: el día del cobro; e; quien: el del SMS; banco: domiciliado (t, el concepto); devuelve false si se ha perdido
function cobra(o,e,quien,banco,t){
  const N='SMS · '+quien;
  if(S.day===o.r-RECIBO.aviso)queue('av'+t,()=>talk(N,[banco?`El día ${o.r} se carga el recibo de ${t}: ${eur(e)}. Saldo: ${eur(S.banco)}.`:`El día ${o.r} paso a cobrar: ${eur(e)}, en efectivo. Tenlo preparado.`]));
  if(S.day<o.r)return true;
  if(banco?cobroBanco(e,'Recibo · '+t):S.money+cajaE()>=e&&pagarCasa(e)===0){o.r+=RECIBO.dias;return true;}
  if(S.day<o.r+(banco?RECIBO.graciaB:RECIBO.gracia)){queue('dv'+t,()=>talk(N,[banco?`Recibo de ${t} devuelto: ${eur(e)}. Si el día ${o.r+RECIBO.graciaB} no hay saldo, se rescinde el contrato.`:'He pasado a cobrar y no había nada. Vuelvo mañana; como no esté, cambio la cerradura.']));return true;}
  return false;
}
function recibosDia(){
  for(const k of Object.keys(S.loc)){const L=LOCALES[k],o=S.loc[k];
    if(o.caja>0){const n=Math.round(o.caja*(1-L.com));abonoBanco(n,'Ingresos · '+L.n);o.tot+=n;o.caja=0;}   // lo de ayer, ya limpio
    if(!cobra(o,L.sem,'BANCO',true,L.n)){delete S.loc[k];queue('loc'+k,()=>talk('SMS · BANCO',[`Contrato de ${L.n} rescindido por impago. La fianza no se devuelve.`]));}}
  if(S.protect&&S.protHasta-S.day===RECIBO.aviso)queue('avMolina',()=>talk('SMS · MOLINA',[`Lo nuestro se acaba el día ${S.protHasta}. Si quieres seguir, ya sabes dónde está la comisaría.`]));
}

// Los locales (LOCALES, lo pidió el usuario): uno por pueblo, con su negocio, para lavar el efectivo. Los alquila quien conoce a Don
// Baltasar, a medida que le pagas (L.pago: lo pagado de la deuda). Fianza y el primer recibo con tarjeta; después, L.sem cada
// RECIBO.dias, domiciliado. Cada día metes en la caja del negocio hasta L.tope de efectivo y a la mañana siguiente está en tu cuenta
// como ingresos del negocio, menos L.com (gastos e impuestos). El rótulo (rotuloL, delante del local): «se alquila» o el del negocio
const LOCALES={
  rv:{n:'Lavadero Distira',neg:'el lavadero de coches',map:'astilleros',x:6,y:10,pago:3000,fianza:1200,sem:150,tope:300,com:.15},
  puerto:{n:'Taberna Itsasargi',neg:'la taberna',map:'puerto',x:31,y:8,pago:15000,fianza:2000,sem:250,tope:600,com:.12},
  valde:{n:'Taller Burdina',neg:'el taller',map:'valdehierro',x:22,y:8,pago:15000,fianza:2000,sem:220,tope:600,com:.12},
  mendi:{n:'Quesería Gaztandegi',neg:'la quesería',map:'mendialde',x:19,y:11,pago:30000,fianza:2500,sem:180,tope:800,com:.1},
  erro:{n:'Panadería Errota',neg:'la panadería',map:'errotabarri',x:8,y:9,pago:30000,fianza:2500,sem:180,tope:800,com:.1},
  ibar:{n:'Lavandería Garbi',neg:'la lavandería',map:'ibarbide',x:30,y:8,pago:30000,fianza:4000,sem:400,tope:1500,com:.1}};
const pagadoDeuda=()=>DEUDA-S.debt;
const localDe=(m,x,y)=>Object.keys(LOCALES).find(k=>LOCALES[k].map===m&&LOCALES[k].x===x&&LOCALES[k].y===y);
const metido=o=>o.dia===S.day?o.caja:0;
const delNeg=L=>L.neg.replace(/^el /,'del ').replace(/^la /,'de la ');   // «las llaves del lavadero», «de la taberna»
async function rotuloLocal(k){
  const L=LOCALES[k],o=S.loc[k],N=L.n.toUpperCase();
  if(!o){
    if(pagadoDeuda()<L.pago)return say(`SE ALQUILA. Debajo, a boli: «Preguntar en el bar El Ancla». El dueño es amigo de Don Baltasar: hasta que no le hayas pagado ${eur(L.pago)}, para ti no está.`);
    if(await ask(`SE TRASPASA: ${L.neg}, con el local. ${eur(L.fianza)} de fianza y ${eur(L.sem)} cada ${RECIBO.dias} días, domiciliados. Por su caja pasa el efectivo que metas, hasta ${eur(L.tope)} al día: al día siguiente, en tu cuenta, menos un ${Math.round(L.com*100)} % de gastos e impuestos.`,['Alquilarlo','No'])!==0)return;
    if(!await tarjeta(L.fianza+L.sem,'Fianza · '+L.n))return;
    S.loc[k]={r:S.day+RECIBO.dias,caja:0,dia:0,tot:0};sfx('coin');updateHUD();await got('las llaves '+delNeg(L));
    return say(`${L.n}: el negocio sigue con su gente. Tú metes el efectivo en la caja y, a la mañana siguiente, sale en el banco como lo que ha hecho.`);
  }
  for(;;){
    const hoy=metido(o),ops=['Meter efectivo','Dejar el local','Nada'];
    const op=ops[await ask(`Hoy, ${eur(hoy)} de ${eur(L.tope)} en caja · lavado en total, ${eur(o.tot)} · próximo recibo, el día ${o.r}.`,ops,N)];
    if(op==='Meter efectivo'){const max=Math.floor(Math.min(S.money,L.tope-hoy));
      if(max<1){sfx('bad');await say(S.money<1?'No llevas efectivo.':`Hoy ya hay ${eur(L.tope)} en la caja: más, y Hacienda se fija.`);continue;}
      const e=await cantidad(`¿Cuánto metes en la caja? Hoy, hasta ${eur(max)}.`,max);if(!e)continue;
      o.caja=hoy+e;o.dia=S.day;S.money-=e;sfx('coin');updateHUD();await say(`Mañana entran en la cuenta ${eur(Math.round(o.caja*(1-L.com)))} como ingresos ${delNeg(L)}.`);}
    else if(op==='Dejar el local'){
      if(await ask(`¿Dejas ${L.neg}? Te devuelven la fianza a la cuenta${o.caja>0?'; lo de la caja de hoy se queda en el negocio':''}.`,['Dejarlo','No'])!==0)continue;
      delete S.loc[k];abonoBanco(L.fianza,'Fianza · '+L.n);sfx('coin');updateHUD();return say(`Has dejado ${L.neg}.`);}
    else return;
  }
}
const spriteRotulo=()=>{const k=Object.keys(LOCALES).find(k=>LOCALES[k].map===S.map);return 'rotuloL-'+(k&&S.loc[k]?1:0);};
// los cajeros (en las ciudades; en los pueblos no hay) y, de cada local, su rótulo delante; el del barrio, en los astilleros, en un
// edificio de ladrillo que estaba vacío
const CAJEROS=[['town',31,8],['puerto',13,8],['valdehierro',9,11],['ibarbide',6,8],['ensanche',19,9]];
function mapasBanco(){
  building(MAPS.astilleros,'ladrillo',3,4,7,6,null);
  CAJEROS.forEach(([m,x,y])=>ob(MAPS[m],x,y,'cajero'));
  for(const k in LOCALES){const L=LOCALES[k];ob(MAPS[L.map],L.x,L.y,'rotuloL');}
}
