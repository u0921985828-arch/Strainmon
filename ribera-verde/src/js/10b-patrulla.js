/* =========================================================
   PATRULLAS (1.10): los policías se ven por la calle
   ========================================================= */
// cuántos agentes andan por cada mapa de fuera, [de día, de noche], desde el capítulo 2: el barrio 1–2 y el barrio alto 2, las
// ciudades pequeñas y los astilleros 1, los pueblos ninguno. No se guardan: salen al entrar en el mapa
const PATRULLAS={town:[1,2],alto:[2,2],astilleros:[1,1],puerto:[1,1],valdehierro:[1,1],mendialde:[0,0],errotabarri:[0,0]};
// la ronda: un paso cada paso[día, noche] ms; sigue recto 3 de cada 4 veces y cada 5–10 pasos se para 0,9–1,8 s a mirar (y a falta
// de 0,6 s gira; fuera de la calle, vuelve a ella). Ve vista casillas hacia delante (cono: de lado, como mucho lo que tiene delante) y la de al lado, si nada alto
// tapa (edificios, árboles, monte, setos, cajas). De noche no se ve por dónde mira (sigilo), pero la sospecha sube sube[1] veces
// más deprisa. Sospecha (0–100, no se guarda): por segundo, mientras un agente te ve y llevas algo, (8 + 0,12 × gramos, hasta
// 100 g) × sube × (1 + calor/100) × protección de Molina (0,4); sin verte baja baja por segundo. Llena: alarma («¡alto!»: alto ms
// quieto, para que dé tiempo a reaccionar) y el agente corre (corre ms por paso) a por ti; te pierde si pasan olvida ms sin verte (ve vista[0] × 2 casillas a la redonda) y estás a más de
// pierde casillas, o si cruzas una puerta o una salida. Vender a vista[0] casillas o menos de uno (aunque no mire): +vende. Tras un control, tregua ms sin sospecha
const PAT={paso:[420,360],corre:[210,180],alto:600,vista:[5,5],sube:[1,2.5],baja:10,vende:60,pierde:10,olvida:4000,tregua:30000};
const CALLE=/^(walk|roadT|roadB|rotoT|rotoB|hormigon|pista|plaza|dirt|dock|bridgeT|bridgeB)$/,TAPA_VISTA=/^(tree|tree2|manzano|monte|monte2|seto|crate)$/;
let SOSP={v:0,alarma:null,sinVer:0,aviso:0,tregua:0};
const nPatrullas=()=>{const p=PATRULLAS[S.map];return p&&S.ch>=2?p[isNight()?1:0]:0;};
const cargaSosp=()=>totalBuds()+totalRosin();
const llegadaBus=(x,y)=>!!PARADAS[S.map]&&PARADAS[S.map].a[0]===x&&PARADAS[S.map].a[1]===y;
// casillas de ronda de un mapa: de calle, a las que se llega a pie, sin la llegada del autobús
const RONDA={};
function casillasRonda(k){
  if(RONDA[k])return RONDA[k];const m=MAPS[k],va=aPie(m,entrada(k)),pa=PARADAS[k],l=[];
  for(const s of va){const [x,y]=s.split(',').map(Number);if(CALLE.test(m.g[y][x])&&!m.doors[s]&&!m.exits[s]&&!(pa&&pa.a[0]===x&&pa.a[1]===y))l.push([x,y]);}
  l.sort((a,b)=>a[1]-b[1]||a[0]-b[0]);return RONDA[k]=l;
}
// dónde sale el agente i: por hash del día, el mapa y su número, a 6 casillas o más del jugador y sin nadie encima
function sitioPatrulla(i){
  const l=casillasRonda(S.map),h0=hashT(S.day*7+i*131,S.map.length*17+i);
  for(let k=0;k<l.length;k++){const [x,y]=l[(h0+k*61)%l.length];if(Math.abs(x-P.x)+Math.abs(y-P.y)>=6&&!entAt(x,y))return [x,y];}
  return l[h0%l.length];
}
function mkPatrulla(i){const [x,y]=sitioPatrulla(i),d={id:'pat'+i,map:S.map,x,y,look:'cop',talk:()=>say(pick(['«Circule.»','«Buenas. Nada que ver aquí.»','«¿Todo bien? Siga.»']),'AGENTE')};
  return {id:d.id,x,y,px:x*16,py:y*16,hx:x,hy:y,dir:['down','left','up','right'][hashT(x,y)%4],look:LOOKS.cop,def:d,wander:0,wt:0,moving:false,t:0,fx:x,fy:y,
    pat:true,mapa:S.map,pasos:6+hashT(y,x)%6,espera:0,giro:0,caza:false,dur:PAT.paso[0]};}
// los que tocan en este mapa a esta hora (buildEnts y, al pasar de día a noche, updatePatrullas)
function ponPatrullas(){
  const n=nPatrullas(),hay=ents.filter(e=>e.pat).length;
  for(let i=hay;i<n;i++)ents.push(mkPatrulla(i));
  if(hay>n)ents=ents.filter(e=>!e.pat||+e.id.slice(3)<n);
}
// ¿ve el agente e la casilla (x, y)? En su cono (o, con lejos, a lejos casillas a la redonda) o pegada a él, con la línea limpia
function veCasilla(e,x,y,lejos){
  const dx=x-e.x,dy=y-e.y,ad=Math.abs(dx)+Math.abs(dy);if(ad===0)return true;
  const m=MAPS[S.map];
  if(ad>1){if(lejos){if(ad>lejos)return false;}
    else{const [fx,fy]=DV[e.dir],fr=dx*fx+dy*fy,la=Math.abs(dx*fy)+Math.abs(dy*fx);if(fr<=0||la>fr||fr>PAT.vista[isNight()?1:0])return false;}}
  const n=Math.max(Math.abs(dx),Math.abs(dy));
  for(let s=1;s<n;s++){const cx=e.x+Math.round(dx*s/n),cy=e.y+Math.round(dy*s/n),g=m.g[cy][cx],o=m.o[cy][cx];
    if(/^(roof|wall|win|door)/.test(g)||(o&&TAPA_VISTA.test(o)))return false;}
  return true;
}
const tePilla=e=>veCasilla(e,P.x,P.y,e.caza?PAT.vista[0]*2:0);
// un paso de ronda: recto si puede (3 de cada 4), si no, a un lado; media vuelta solo en un callejón
function pasoRonda(e,m){
  if(!CALLE.test(m.g[e.y][e.x])){pasoVuelta(e,m);return;}
  const libre=d=>{const [dx,dy]=DV[d],nx=e.x+dx,ny=e.y+dy,k=nx+','+ny;return CALLE.test((m.g[ny]||[])[nx]||'')&&!tileSolid(m,nx,ny)&&!entAt(nx,ny)&&!(nx===P.x&&ny===P.y)&&
    !(P.moving&&nx===P.fx&&ny===P.fy)&&!m.doors[k]&&!m.exits[k]&&!llegadaBus(nx,ny);};
  const ops=['up','down','left','right'].filter(d=>d!==OPP[e.dir]&&libre(d)),otras=ops.filter(d=>d!==e.dir);
  const d=ops.includes(e.dir)&&Math.random()<.75?e.dir:otras.length?pick(otras):ops.length?ops[0]:libre(OPP[e.dir])?OPP[e.dir]:null;
  if(!d)return;e.dir=d;const [dx,dy]=DV[d];e.fx=e.x;e.fy=e.y;e.x+=dx;e.y+=dy;e.t=0;e.moving=true;e.dur=PAT.paso[isNight()?1:0];
}
// fuera de la calle (tras una caza, por la hierba o el parque): un paso por el camino más corto a la calle más cercana
function pasoVuelta(e,m){
  const k0=e.x+','+e.y,prev=new Map([[k0,null]]),q=[[e.x,e.y]];let fin=null;
  for(let qi=0;qi<q.length&&!fin;qi++){const [x,y]=q[qi];for(const d of ['up','down','left','right']){const [dx,dy]=DV[d],nx=x+dx,ny=y+dy,k=nx+','+ny;
    if(prev.has(k)||tileSolid(m,nx,ny)||m.doors[k]||m.exits[k]||(nx===P.x&&ny===P.y)||(P.moving&&nx===P.fx&&ny===P.fy)||ents.some(o=>o!==e&&o.x===nx&&o.y===ny))continue;
    prev.set(k,[x,y,d]);if(CALLE.test(m.g[ny][nx])){fin=k;break;}q.push([nx,ny]);}}
  if(!fin)return;let k=fin,p=prev.get(k);while(p[0]+','+p[1]!==k0){k=p[0]+','+p[1];p=prev.get(k);}
  const [nx,ny]=k.split(',').map(Number);e.dir=p[2];e.fx=e.x;e.fy=e.y;e.x=nx;e.y=ny;e.t=0;e.moving=true;e.dur=PAT.paso[isNight()?1:0];
}
// un paso de caza: el primero del camino más corto hasta el jugador (por lo que no es sólido, sin puertas ni salidas ni gente)
function pasoCaza(e,m){
  const k0=e.x+','+e.y,prev=new Map([[k0,null]]),q=[[e.x,e.y]];let fin=null;
  for(let qi=0;qi<q.length&&!fin;qi++){const [x,y]=q[qi];for(const d of ['up','down','left','right']){const [dx,dy]=DV[d],nx=x+dx,ny=y+dy,k=nx+','+ny;
    if(prev.has(k))continue;if(nx===P.x&&ny===P.y){prev.set(k,[x,y,d]);fin=k;break;}
    if(tileSolid(m,nx,ny)||m.doors[k]||m.exits[k]||ents.some(o=>o!==e&&o.x===nx&&o.y===ny))continue;prev.set(k,[x,y,d]);q.push([nx,ny]);}}
  if(!fin)return;let k=fin,p=prev.get(k);while(p[0]+','+p[1]!==k0){k=p[0]+','+p[1];p=prev.get(k);}
  e.dir=p[2];const [nx,ny]=k.split(',').map(Number);if(nx===P.x&&ny===P.y)return;
  e.fx=e.x;e.fy=e.y;e.x=nx;e.y=ny;e.t=0;e.moving=true;e.dur=PAT.corre[isNight()?1:0];
}
// en el mundo y libre (update): mueve a los agentes, sube o baja la sospecha y lleva la alarma
function updatePatrullas(dt){
  if(!ZONAS[S.map])return;
  if(ents.filter(e=>e.pat).length!==nPatrullas())ponPatrullas();
  const pats=ents.filter(e=>e.pat),m=MAPS[S.map];if(!pats.length){SOSP.v=0;return;}
  for(const e of pats){
    if(e.moving){e.t+=dt;const k=Math.min(1,e.t/e.dur);e.px=(e.fx+(e.x-e.fx)*k)*16;e.py=(e.fy+(e.y-e.fy)*k)*16;if(k>=1){e.moving=false;e.fx=e.x;e.fy=e.y;}continue;}
    if(e.caza){if(e.espera>0){e.espera-=dt;continue;}if(Math.abs(e.x-P.x)+Math.abs(e.y-P.y)===1&&!P.moving){pillado(e);return;}pasoCaza(e,m);continue;}
    if(e.espera>0){e.espera-=dt;if(e.espera<=600&&!e.giro){e.giro=1;e.dir=pick(['up','down','left','right']);}continue;}
    if(--e.pasos<=0){e.pasos=6+Math.floor(Math.random()*6);e.espera=900+Math.random()*900;e.giro=0;continue;}
    pasoRonda(e,m);
  }
  const ve=pats.find(tePilla),seg=dt/1000;
  if(SOSP.alarma){const e=pats.find(p=>p.id===SOSP.alarma);
    if(!e){SOSP.alarma=null;SOSP.v=50;toast('Lo has despistado.',1600);return;}   // al cambiar el turno se va el que te seguía
    if(ve)SOSP.sinVer=0;else SOSP.sinVer+=dt;
    if(SOSP.sinVer>=PAT.olvida&&Math.abs(e.x-P.x)+Math.abs(e.y-P.y)>PAT.pierde){e.caza=false;e.espera=1200;SOSP.alarma=null;SOSP.v=50;toast('Lo has despistado.',1600);}
    return;
  }
  if(SOSP.tregua>0)SOSP.tregua-=dt;
  const g=SOSP.tregua>0?0:cargaSosp();
  if(ve&&g>0){SOSP.v=Math.min(100,SOSP.v+(8+Math.min(g,100)*.12)*PAT.sube[isNight()?1:0]*(1+S.heat/100)*(S.protect?.4:1)*seg);
    if(!SOSP.aviso&&(!isNight()||SOSP.v>=40)){SOSP.aviso=1;toast(isNight()?'Oyes pasos detrás de ti.':'Un agente te está mirando.',1800);}}
  else SOSP.v=Math.max(0,SOSP.v-PAT.baja*seg);
  if(SOSP.v>=100)alarma(ve||pats[0]);
}
function alarma(e){SOSP.alarma=e.id;SOSP.sinVer=0;e.caza=true;e.espera=PAT.alto;sfx('enc');toast('<small>¡ALTO, POLICÍA!</small>Corre (B): métete en un portal o aléjate.',2200);}
// vender cerca de un agente (talkClient), aunque no mire: la sospecha sube de golpe
function vistoVender(){if(!SOSP.alarma&&ents.some(e=>e.pat&&veCasilla(e,P.x,P.y,PAT.vista[0]))){SOSP.v=Math.min(100,SOSP.v+PAT.vende);SOSP.aviso=1;toast('Un agente te ha visto vender.',1600);}}
// te alcanza: el control de siempre (battle, 13-combate); después, una tregua
function pillado(e){e.caza=false;e.espera=1500;e.dir=OPP[P.dir];SOSP={v:0,alarma:null,sinVer:0,aviso:1,tregua:PAT.tregua};run(()=>battle('police'));}
// al cambiar de mapa (enterMap): la sospecha y la alarma se quedan en la calle
function resetSosp(){SOSP={v:0,alarma:null,sinVer:0,aviso:0,tregua:0};}
// de día, por dónde mira cada agente (de noche, no: sigilo); con la alarma, ninguno
function pintarVistas(cam){
  if(isNight()||SOSP.alarma)return;
  ctx.fillStyle='rgba(255,230,60,.34)';
  const m=MAPS[S.map];
  for(const e of ents){if(!e.pat)continue;const R=PAT.vista[0];   // desde la casilla a la que va
    for(let y=e.y-R;y<=e.y+R;y++)for(let x=e.x-R;x<=e.x+R;x++){if((x===e.x&&y===e.y)||tileSolid(m,x,y)||!veCasilla(e,x,y,0))continue;
      ctx.fillRect(x*16-cam.x,y*16-cam.y,16,16);}}
}
