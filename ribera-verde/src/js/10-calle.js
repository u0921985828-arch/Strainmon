/* ---------- clientes y venta ----------
   Precios reales (1.10): en la calle, el gramo a 6-10 € según el THC (× el tipo de cliente y lo que pidas); al por mayor,
   3,50-5 € (ventaMayor, 11-historia). */
const precioCalle=thc=>4+thc*.2,precioMayor=thc=>2+thc*.1;
function spawnClients(){
  S.clientsDay=S.day;S.clients=[];
  if(S.ch>=2){
    const n=Math.min(10,4+Math.floor(S.rep/15)+(S.ch>=4?1:0)),used=new Set(NPCDEF.filter(d=>d.map==='town').map(d=>d.x+','+d.y).concat(ITEMS.map(it=>it.x+','+it.y)));
    for(let i=0;i<n;i++){let t;for(let k=0;k<30;k++){t=pick(CLIENT_TILES);if(!used.has(t+''))break;}used.add(t+'');
      const types=['est','est','cur','cur'];if(S.ch>=3)types.push('tur');if(S.ch>=4)types.push('pij','pij');
      const type=pick(types),ct=CTYPES[type],id='c'+S.day+'_'+i;
      S.clients.push({id,x:t[0],y:t[1],type,want:ri(ct.g[0],ct.g[1]),minThc:type==='pij'?Math.min(24,15+S.ch):(type==='tur'&&Math.random()<.4?15:0),look:randLook(id,'client')});}
  }
  if(S.map==='town')buildEnts();
}
function removeClient(id){S.clients=S.clients.filter(c=>c.id!==id);ents=ents.filter(e=>e.id!==id);}
async function talkClient(c){
  const ct=CTYPES[c.type],N=ct.label;
  await say(pick(ct.greet),N);
  await say(`Busco ${c.want} g${c.minThc?` de algo potente, mínimo ${c.minThc}% de THC`:''}.`,N);
  const lots=budLots(c.want,c.minThc);
  if(!lots.length)return say(totalBuds()>0?'Eso no me vale. Vuelve cuando tengas lo que busco.':'¿No llevas nada? Vale.',N);
  const i=await menu(lots.map(lotItem).concat([{label:'Nada'}]),{cls:'right',title:'¿Qué le vendes?'});
  if(i<0||i>=lots.length)return say('Vale, otro día.',N);
  const [sid,b]=lots[i],base=precioCalle(b.thc)*ct.mult*c.want;
  const pr=[Math.round(base*.85),Math.round(base),Math.round(base*1.3)];
  const j=await ask(`${c.want} g de ${lotNombre(sid)}. ¿Cuánto le pides?`,[`Rebaja · ${pr[0]} €`,`Justo · ${pr[1]} €`,`Caro · ${pr[2]} €`,'Cancelar']);
  if(j===3)return say('Entonces me voy.',N);
  const acc=[1,.92,clamp(.3+(b.thc-(c.minThc||14))*.05+(c.type==='pij'?.25:0)+(c.type==='tur'?.15:0),.1,.9)][j];
  if(Math.random()<acc){
    useBuds(sid,c.want);S.money+=pr[j];S.sales+=pr[j];S.heat=Math.min(100,S.heat+3+c.want*.5);S.rep+=[3,2,1][j];sfx('coin');
    await accion('vender',{id:'vfx-monedas',x:P.px+8,y:P.py+2});
    removeClient(c.id);
    await say(pick(['Trato hecho.','Gracias. Nos vemos.','Bien. Se lo diré a mis amigos.']),N);
    toast(`+${eur(pr[j])} · ${c.want} g vendidos`,1600);
    heatWarn();await checkStory();
  }else{S.rep=Math.max(0,S.rep-1);sfx('bad');removeClient(c.id);await say(pick(['¿Tanto? No.','A ese precio, paso.','Eso es demasiado. Adiós.']),N);}
}
function heatWarn(){if(S.heat>=70&&!S.flags.heatW){S.flags.heatW=true;toast('<small>CUIDADO</small>Mucha presión policial. Si llega a 90 habrá registro.',3200);}if(S.heat<60)S.flags.heatW=false;}

