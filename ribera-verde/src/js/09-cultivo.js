/* =========================================================
   TIEMPO Y CULTIVO
   ========================================================= */
function plantStep(p,h){
  if(p.dead)return;const s=getStrain(p.sid);
  p.water=Math.max(0,p.water-3.5*h);
  if(!p.pest&&p.prog<1&&Math.random()<.006*h*(100-s.r)/40)p.pest=true;
  let g=h/(s.d*24);if(p.water<20)g*=.4;if(p.water<=0)g=0;if(p.fert)g*=1.1;if(S.led)g*=1.1;
  if(p.prog<1)p.prog=Math.min(1,p.prog+g);
  if(p.water<=0)p.health-=4*h;if(p.pest)p.health-=2.5*h;if(p.water>30&&!p.pest)p.health+=h;
  p.health=clamp(p.health,0,100);if(p.health<=0)p.dead=true;
}
function plantsAdvance(min){for(const p of S.pots)if(p)plantStep(p,min/60);}
function advanceTime(min){while(min>0){const st=Math.min(60,min);min-=st;S.min+=st;plantsAdvance(st);if(S.min>=1440){S.min-=1440;newDay();}}}
function tickMinute(){
  S.min++;if(S.min%10===0)plantsAdvance(10);
  if(S.min%30===0&&S.hp<S.hpMax)S.hp++;
  if(S.min>=1440){S.min-=1440;newDay();}
  if(S.min%30===0&&S.map==='town')music(mapMusic());
}
function newDay(){
  S.day++;
  if(S.heat>=90)queue('raid',raidEvent); // se comprueba antes de que el calor baje con el nuevo día
  S.heat=Math.max(0,S.heat-(S.protect?20:12));
  spawnClients();
  if(S.due>0&&S.flags.metB&&S.day>S.deadline)queue('penalty',penaltyEvent);
}
function stageName(p){return p.prog<.12?'Germinando':p.prog<.35?'Plántula':p.prog<.65?'Vegetativo':'Floración';}
async function potAction(i){
  const p=S.pots[i];
  if(!p){
    const own=Object.entries(S.seeds).filter(([,v])=>v>0);
    if(!own.length)return say('Maceta vacía. No tienes semillas: cómpralas en el growshop de Kiko.');
    const j=await menu(own.map(([k,v])=>({label:getStrain(k).n,right:'×'+v,sw:getStrain(k).c,desc:strainLine(k)})).concat([{label:'Cancelar',desc:''}]),{cls:'full',title:'¿QUÉ PLANTAS?',desc:true});
    if(j<0||j>=own.length)return;
    const sid=own[j][0];S.seeds[sid]--;if(!S.seeds[sid])delete S.seeds[sid];
    S.pots[i]={sid,prog:0,water:70,health:100,fert:false,pest:false};sfx('sel');
    return say(`Has plantado ${getStrain(sid).n}. ¡A crecer!`);
  }
  const s=getStrain(p.sid);
  if(p.dead){await say(`La ${s.n} se ha secado del todo. Una pena.`);S.pots[i]=null;return say('Retiras la planta muerta.');}
  if(p.prog>=1){const c=await ask(`¡${s.n} lista para cosechar!\nSalud ${Math.round(p.health)}% · Agua ${Math.round(p.water)}%`,['Cosechar','Esperar']);if(c===0)await harvest(i);return;}
  const opts=['Regar'];if(!p.fert)opts.push('Abonar');if(p.pest)opts.push('Tratar plaga');opts.push('Arrancar','Salir');
  const c=await ask(`${s.n} · ${stageName(p)} ${Math.floor(p.prog*100)}%\nAgua ${Math.round(p.water)}% · Salud ${Math.round(p.health)}%${p.pest?' · ¡PLAGA!':''}`,opts);
  const op=opts[c];
  if(op==='Regar'){p.water=100;sfx('sel');await say('Riegas la planta. Agua al 100%.');}
  else if(op==='Abonar'){if(S.items.fert>0){S.items.fert--;p.fert=true;sfx('sel');await say('Echas FERTILIZANTE. Dará más cogollos.');}else await say('No te queda FERTILIZANTE.');}
  else if(op==='Tratar plaga'){if(S.items.insect>0){S.items.insect--;p.pest=false;sfx('sel');await say('Aplicas INSECTICIDA con guantes y mascarilla. Plaga eliminada.');}else await say('No tienes INSECTICIDA. Kiko lo vende.');}
  else if(op==='Arrancar'){if(await ask('¿Seguro que quieres arrancarla?',['Sí','No'])===0){S.pots[i]=null;await say('Arrancas la planta.');}}
}
async function harvest(i){
  const p=S.pots[i],s=getStrain(p.sid);
  const g=Math.max(1,Math.round(s.y*(.4+.6*p.health/100)*(p.fert?1.25:1)*(S.led?1.3:1)));
  const thc=Math.round((s.thc*(.85+.15*p.health/100)+(S.led?.5:0)+(p.fert?.3:0))*10)/10;
  const n=1+ri(0,2);addBuds(p.sid,g,thc);addSeeds(p.sid,n);S.pots[i]=null;sfx('get');
  await say(`¡Cosechas ${g} g de ${s.n} con ${pct(thc)}% de THC!`);
  await say(`También recoges ${n} semilla${n>1?'s':''} de ${s.n}.`);
  S.flags.harvest1=true;await checkStory();
}
async function bedAction(){
  const c=await ask('Tu cama. Todavía huele a la colonia de la tía.',['Dormir hasta las 7','Siesta de 3 h','Nada']);
  if(c>1)return;
  await fade(1);
  const mins=c===1?180:(((7*60-S.min)+1440)%1440||1440);
  advanceTime(mins);S.hp=S.hpMax;buildEnts();updateHUD();await wait(500);await fade(0);
  save();toast('Has descansado · Partida guardada',1800);
}
async function pcAction(){
  const c=await ask('El ordenador de la tía. Tiene una pegatina de un cogollo.',['Genoteca','Guardar partida','Apagar']);
  if(c===0)await genoteca();else if(c===1){await say(save()?'Partida guardada.':'No se ha podido guardar en este navegador.');}
}
async function letterAction(){
  if(S.flags.letter)return say('La carta de la tía Maite. «Cuida el armario. Y perdona lo de Baltasar.»');
  await say('Hay una carta encima de la mesa. Es de la tía Maite.');
  await talk('CARTA',['«{N}: si lees esto, el piso es tuyo. Cuídalo, que la escalera cruje.»','«Al fondo del salón está mi armario de cultivo. Ya sabes de qué hablo.»','«Pásate por el growshop de Kiko, aquí al lado. Él te enseñará.»','«P.D.: Si alguien pregunta por mí en el bar El Ancla... yo no estoy. Lo siento.»']);
  S.flags.letter=true;showObjective();
}
async function labAction(){
  if(!S.flags.lab)return say('Una mesa con un microscopio viejo y frascos. Kiko sabrá qué hacer con esto.');
  const own=()=>Object.entries(S.seeds).filter(([,v])=>v>0);
  if(own().length<2)return say('MESA DE GENÉTICA: necesitas semillas de dos variedades distintas para cruzar.');
  const mk=l=>l.map(([k,v])=>({label:getStrain(k).n,right:'×'+v,sw:getStrain(k).c,desc:strainLine(k)}));
  const l1=own();const a=await menu(mk(l1),{cls:'full',title:'CRUCE · MADRE',desc:true});if(a<0)return;
  const A=l1[a][0];const l2=own().filter(([k])=>k!==A);
  const b=await menu(mk(l2),{cls:'full',title:'CRUCE · PADRE',title2:getStrain(A).n,desc:true});if(b<0)return;
  const Bk=l2[b][0];
  if(await ask(`¿Cruzar ${getStrain(A).n} × ${getStrain(Bk).n}? Gastas 1 semilla de cada.`,['Cruzar','Cancelar'])!==0)return;
  S.seeds[A]--;S.seeds[Bk]--;for(const k of [A,Bk])if(!S.seeds[k])delete S.seeds[k];
  const r=crossResult(A,Bk),isNew=!S.disc[r],s=getStrain(r);
  sfx('enc');await fade(1,true);await wait(450);await fade(0,true);
  addSeeds(r,2);
  if(isNew){sfx('get');await say(`¡NUEVA VARIEDAD! ${s.n}`);await say(`THC ${pct(s.thc)}% · ${s.y} g/planta · ${String(s.d).replace('.',',')} días.\nObtienes 2 semillas.`);
    if(r==='leyenda'){await say('Te tiemblan las manos. Es la LEYENDA DE LA RÍA.');await talk('SMS · KIKO',['¿¿LA LEYENDA DE LA RÍA?? La busco desde hace veinte años.','Tu tía estaría dando saltos. Yo estoy llorando un poco.']);}}
  else await say(`Obtienes 2 semillas de ${s.n}.`);
  await checkStory();
}

