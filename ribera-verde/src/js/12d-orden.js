/* ---------- ordenar la casa, la asociación y la nave (1.37, lo pidió el usuario) ----------
   Con A en la mesa redonda del piso, en una mesita de la asociación (de presidente) o en el escritorio de la nave, ORDENAR: eliges
   un mueble y lo llevas con las flechas por el suelo; A lo deja (si cabe) y B lo devuelve a donde estaba. Cada pieza (ORDEN_P) son
   sus objetos [dx, dy, objeto] desde su casilla, la gente que va con ella (el socio de los sofás, el del billar, el navero delante de
   su mesa: [dx, dy, id, dir]) y su sitio de serie (def; alt, el de reserva si llega una carpa encima). Lo que eliges se guarda en
   S.coloca[mapa][pieza] = [x, y] y aplicaOrden monta el mapa con ello (montarCasa, montarNave y, en la asociación, al entrar).
   Cabe (cabePieza) si todo cae en el suelo libre de su filas, no pisa lo de otro, ni a la gente, ni el hueco de la carpa que toca,
   ni a ti, y si después se sigue llegando andando desde la puerta a ti, a la gente, a lo que se usa desde delante (pie) y a cada
   mueble por un lado. En la nave, además, la manguera tiene que llegar del tanque a cada mesa (rutaRiego, 11j-locales). */
const ORDEN_P={
  home:{n:'ORDENAR LA CASA',filas:[2,7],pie:[[7,2]],piezas:[
    {k:'nevera',n:'La nevera',o:[[0,0,'fridge']],def:[2,2],alt:[0,6]},   // 1.37 (lo pidió el usuario): entre la planta y el ordenador de la tía
    {k:'mesa',n:'La mesa redonda',o:[[0,0,'table']],def:[3,5]},
    {k:'planta',n:'La planta del dormitorio',o:[[0,0,'plantDeco']],def:[1,2]},
    {k:'planta2',n:'La planta del salón',o:[[0,0,'plantDeco']],def:[17,7]},
    {k:'trim',n:'La mesa de manicurar',o:[[0,0,'trim']],def:[4,7]},
    {k:'lavadora',n:'La lavadora de extracción',o:[[0,0,'lavadora']],def:[1,7],si:'extr'},
    {k:'mallas',n:'El cubo de mallas',o:[[0,0,'mallas']],def:[2,7],si:'extr'},
    {k:'staticM',n:'La máquina de static',o:[[0,0,'staticM']],def:[3,7],si:'extr'},
    {k:'prensaM',n:'La prensa de rosin',o:[[0,0,'prensaM']],def:[6,7],si:'extr'},
    {k:'tamizM',n:'Los tamices',o:[[0,0,'tamizM']],def:[7,7],si:'extr'},
    {k:'tv',n:'La tele',o:[[0,0,'tv'],[1,0,'tv2']],def:[13,2],si:'mueble'},
    {k:'gpc',n:'El PC gaming',o:[[0,0,'gpc'],[1,0,'gpc2'],[0,1,'sillaG'],[1,1,'sillaG2']],def:[16,2],si:'mueble'},
    {k:'sofa',n:'El sofá',o:[[0,0,'sofa'],[1,0,'sofa2']],def:[13,5],si:'mueble'},
    {k:'sillon',n:'El sillón',o:[[0,0,'sillon'],[1,0,'sillon2']],def:[16,5],si:'mueble'},
    {k:'carro',n:'El carro de esquejes',o:[[0,0,'carro'],[1,0,'carro2']],def:[8,5],si:'mueble'},
    {k:'alfombra',n:'La alfombra',o:[[0,0],[1,0],[0,1],[1,1]],def:[13,3],si:'mueble',suelo:1}]},
  'club-rv':{n:'ORDENAR EL LOCAL',filas:[2,9],pie:[],piezas:[
    {k:'salita',n:'Los sofás de la entrada',o:[[0,0,'sofaF'],[1,0,'sofaF2'],[0,1,'mesita'],[1,1,'mesita'],[0,2,'sofaB'],[1,2,'sofaB2']],gente:[[2,1,'socio','left']],def:[5,3]},
    {k:'salita2',n:'Los sofás del fondo',o:[[0,0,'sofaF'],[1,0,'sofaF2'],[0,1,'mesita'],[1,1,'mesita'],[0,2,'sofaB'],[1,2,'sofaB2']],gente:[[-1,1,'cg1','right']],def:[13,3]},
    {k:'salita3',n:'Los sofás de abajo',o:[[0,0,'sofaF'],[1,0,'sofaF2'],[0,1,'mesita'],[1,1,'mesita'],[0,2,'sofaB'],[1,2,'sofaB2']],gente:[[2,1,'cg2','left']],def:[1,7]},
    {k:'billar',n:'El billar',o:[[0,0,'billar'],[1,0,'billar2']],gente:[[2,0,'billarista','left']],def:[10,7]},
    {k:'libreria',n:'La librería',o:[[0,0,'libreria'],[1,0,'libreria']],def:[10,2]},
    {k:'jukebox',n:'La gramola',o:[[0,0,'jukebox']],def:[15,2]},
    {k:'planta',n:'La planta de la entrada',o:[[0,0,'plantDeco']],def:[3,2]},
    {k:'planta2',n:'La planta del rincón',o:[[0,0,'plantDeco']],def:[15,8]}]},
  nave:{n:'ORDENAR LA NAVE',filas:[3,6],pie:[],piezas:[
    ...MESAS_X.map((x,i)=>({k:'m'+i,n:'La mesa '+(i+1),o:[[0,0,'mesaN'],[1,0,'mesaN2']],gente:[[0,1,'nv'+i,'up']],def:[x,4]})),
    // el riego (rg ≥ 1): el tanque contra la pared, la máquina a su lado y el controlador en la pared, encima (EQUIPO_NAVE)
    {k:'riego',n:'El tanque del riego',o:[[0,0,'tanqueN'],[1,0,'riegoN',3],[2,-1,'ctrlN',2]],def:[1,2],si:'riego',fila:2}]}};   // [.., desde el nivel de riego]
// lo que no se puede tapar, aparte de la gente: en la nave, la pared de la extracción (los extractores y filtros de cualquier nivel)
const ORDEN_RESERVA={nave:EQUIPO_NAVE.filter(e=>e[3]==='ex').map(e=>[e[0],e[1]])};
// lo que no hace falta alcanzar por su lado: la otra mitad de un mueble ancho, la cabecera de la cama y los ordenadores (se usan
// desde su silla, SILLAS)
const ORDEN_SIN_LADO=/^(bedT|pc|gpc|.*2)$/;
const ORDEN_MOTIVO={fuera:'Ahí no cabe.',ocupado:'Ahí ya hay algo.',carpa:'Ese hueco es para la carpa.',tu:'Ahí estás tú.',paso:'Así no se podría pasar.',riego:'La manguera no llegaría a todas las mesas.'};
let ORDEN=null;   // mientras mueves una pieza: {mapa, k, x, y, x0, y0, ok (el motivo, '' si cabe), vo: los objetos con la pieza encima, vg: el suelo}
const piezaDe=(mapa,k)=>ORDEN_P[mapa].piezas.find(P=>P.k===k);
function piezaYa(mapa,P){
  if(P.si==='extr')return muebleYa(MUEBLE_EXTR[P.k]);
  if(P.si==='mueble')return mueblesYa().includes(P.k);
  if(P.si==='riego')return !!(S.nave&&S.nave.rg>=1);
  return true;
}
const piezasYa=mapa=>ORDEN_P[mapa].piezas.filter(P=>piezaYa(mapa,P));
// dónde está: la que mueves, en el cursor; si no, la que eligió el jugador o la de serie
function posPieza(mapa,k){
  if(ORDEN&&ORDEN.mapa===mapa&&ORDEN.k===k)return [ORDEN.x,ORDEN.y];
  const o=S&&S.coloca&&S.coloca[mapa];return o&&o[k]?o[k]:piezaDe(mapa,k).def;
}
const celdasP=(P,x,y)=>P.o.map(([dx,dy,o,n])=>[x+dx,y+dy,n&&!(S.nave&&S.nave.rg>=n)?null:o]);   // lo de un nivel de riego que aún no hay, vacío
const genteP=(P,x,y)=>(P.gente||[]).map(([dx,dy,id,dir])=>[x+dx,y+dy,id,dir]);
// la gente que no va con ninguna pieza y no se mueve (en su casilla de NPCDEF)
function genteFija(mapa){
  const con=new Set(ORDEN_P[mapa].piezas.flatMap(P=>(P.gente||[]).map(g=>g[2])));
  return NPCDEF.filter(d=>d.map===mapa&&!con.has(d.id)).map(d=>[d.x,d.y]);
}
// el hueco de la carpa que toca comprar (el que se ve marcado en el suelo del piso)
const huecoCarpa=mapa=>mapa!=='home'?[]:SITIOS.flatMap((s,ci)=>sitioVisible(ci)?Array.from({length:s.w},(_,j)=>[s.x+j,s.y]):[]);
const pisable=(m,x,y)=>x>=0&&y>=0&&x<m.w&&y<m.h&&!SOLID_G.test(m.g[y][x])&&m.g[y][x]!=='mat'&&!m.exits[x+','+y]&&!m.doors[x+','+y];
// casillas a las que se llega andando desde las puertas con los objetos O; B: las casillas de la gente (no se pasa por encima)
function andable(m,O,B=new Set()){
  const v=new Set(),q=[],libre=(x,y)=>pisable(m,x,y)&&!O[y][x]&&!B.has(x+','+y);
  for(const k of Object.keys(m.exits)){const [x,y]=k.split(',').map(Number);
    for(const [dx,dy] of [[0,-1],[-1,0],[1,0],[0,1]]){const nx=x+dx,ny=y+dy,kk=nx+','+ny;if(!v.has(kk)&&libre(nx,ny)){v.add(kk);q.push([nx,ny]);}}}
  while(q.length){const [x,y]=q.shift();for(const [dx,dy] of [[0,1],[-1,0],[1,0],[0,-1]]){const nx=x+dx,ny=y+dy,k=nx+','+ny;if(!v.has(k)&&libre(nx,ny)){v.add(k);q.push([nx,ny]);}}}
  return v;
}
// los objetos del mapa sin la pieza k (donde esté ahora: m.opos)
function sinPieza(mapa,k){
  const m=MAPS[mapa],O=m.o.map(r=>r.slice()),p=m.opos&&m.opos[k],P=piezaDe(mapa,k);
  if(p&&!P.suelo)for(const [x,y] of celdasP(P,p[0],p[1]))if(O[y]&&O[y][x]!==undefined)O[y][x]=null;
  return O;
}
// '' si la pieza k cabe en (x, y); si no, el motivo (ORDEN_MOTIVO). O: los objetos sin ella (sinPieza); jug: comprobar al jugador
function cabePieza(mapa,k,x,y,O=sinPieza(mapa,k),jug=true){
  const m=MAPS[mapa],D=ORDEN_P[mapa],P=piezaDe(mapa,k),F=celdasP(P,x,y),G=genteP(P,x,y);
  const fila=(cx,cy,dy)=>dy<0?cy===1:(P.fila?cy===P.fila:cy>=D.filas[0]&&cy<=D.filas[1]);
  for(const [cx,cy] of F.concat(G))if(cx<0||cy<0||cx>=m.w||cy>=m.h)return 'fuera';
  if(P.suelo){for(const [cx,cy] of F)if(!fila(cx,cy,0)||!pisable(m,cx,cy))return 'fuera';return '';}
  for(const [i,[cx,cy]] of F.entries()){const dy=P.o[i][1];if(!fila(cx,cy,dy)||(dy>=0&&!pisable(m,cx,cy)))return 'fuera';}
  for(const [cx,cy] of G)if(!pisable(m,cx,cy))return 'fuera';
  const res=new Set(genteFija(mapa).concat(D.pie,ORDEN_RESERVA[mapa]||[]).map(c=>c.join()));
  const otras=piezasYa(mapa).filter(Q=>Q.k!==k);
  for(const Q of otras){const [qx,qy]=posPieza(mapa,Q.k);for(const [gx,gy] of genteP(Q,qx,qy))res.add(gx+','+gy);}
  const hueco=new Set(huecoCarpa(mapa).map(c=>c.join()));
  for(const [cx,cy] of F.concat(G)){if(hueco.has(cx+','+cy))return 'carpa';if(O[cy][cx]||res.has(cx+','+cy))return 'ocupado';}
  if(jug&&S.map===mapa&&F.concat(G).some(([cx,cy])=>cx===P_x()&&cy===P_y()))return 'tu';
  const O2=O.map(r=>r.slice());for(const [cx,cy,o] of F)O2[cy][cx]=o;
  // la gente no se mueve y no se pasa por ella: a cada uno se le habla desde al lado o por encima de un mostrador (la vitrina)
  const gente=genteFija(mapa).concat(G,...otras.map(Q=>{const [qx,qy]=posPieza(mapa,Q.k);return genteP(Q,qx,qy);}));
  const B=new Set(gente.map(([gx,gy])=>gx+','+gy)),v=andable(m,O2,B),llega=([cx,cy])=>v.has(cx+','+cy);
  const habla=([gx,gy])=>[[0,1],[-1,0],[1,0],[0,-1]].some(([dx,dy])=>v.has((gx+dx)+','+(gy+dy))||(O2[gy+dy]&&O2[gy+dy][gx+dx]&&v.has((gx+2*dx)+','+(gy+2*dy))));
  const deben=D.pie.concat(huecoCarpa(mapa));
  if(jug&&S.map===mapa)deben.push([P_x(),P_y()]);
  if(!deben.every(llega)||!gente.every(habla))return 'paso';
  for(let cy=2;cy<m.h;cy++)for(let cx=0;cx<m.w;cx++){const o=O2[cy][cx];if(!o||ORDEN_SIN_LADO.test(o))continue;
    if(![[0,1],[-1,0],[1,0],[0,-1]].some(([dx,dy])=>v.has((cx+dx)+','+(cy+dy))||B.has((cx+dx)+','+(cy+dy))))return 'paso';}   // o al lado de quien lo usa
  if(mapa==='nave'&&S.nave&&S.nave.rg>=1){const pos={};pos[k]=[x,y];if(MESAS_X.some((_,i)=>!rutaRiego(i,O2,pos)))return 'riego';}
  return '';
}
// la casilla del jugador (en las pruebas y al montar sin jugador, fuera del mapa)
const P_x=()=>typeof P!=='undefined'&&P?P.x:-9,P_y=()=>typeof P!=='undefined'&&P?P.y:-9;
// monta las piezas del mapa: quita las de antes y pone cada una donde se eligió; si ya no cabe (una carpa nueva, un mueble que
// acaba de llegar), en su sitio de reserva o en el libre más cercano, y se apunta. Lo llaman montarCasa, montarNave y montarClub
function aplicaOrden(mapa){
  const m=MAPS[mapa];if(!m||!S)return;
  quitaOrden(mapa);
  for(const P of piezasYa(mapa)){
    let p=posPieza(mapa,P.k);
    if(cabePieza(mapa,P.k,p[0],p[1],m.o.map(r=>r.slice()),false)){
      const c=[P.alt].concat(cercanas(m,p)).filter(Boolean).find(([x,y])=>!cabePieza(mapa,P.k,x,y,m.o.map(r=>r.slice()),false));
      if(!c)continue;p=c;(S.coloca[mapa]||(S.coloca[mapa]={}))[P.k]=c.slice();}
    m.opos[P.k]=p.slice();if(!P.suelo)for(const [cx,cy,o] of celdasP(P,p[0],p[1]))ob(m,cx,cy,o);
  }
}
// quita las piezas del mapa (las de serie del plano la primera vez: las que están enteras en su sitio de serie)
function quitaOrden(mapa){
  const m=MAPS[mapa];
  if(!m.opos){m.opos={};for(const P of ORDEN_P[mapa].piezas)if(!P.suelo&&P.o.every(([dx,dy,o])=>m.o[P.def[1]+dy]&&m.o[P.def[1]+dy][P.def[0]+dx]===o))m.opos[P.k]=P.def.slice();}
  for(const k in m.opos){const P=piezaDe(mapa,k),[x,y]=m.opos[k];if(!P.suelo)for(const [cx,cy] of P.o.map(([dx,dy])=>[x+dx,y+dy]))ob(m,cx,cy,null);}
  m.opos={};
}
// las casillas del mapa de la más cercana a p a la más lejana (por filas y columnas, sin azar)
function cercanas(m,[x0,y0]){const c=[];for(let y=0;y<m.h;y++)for(let x=0;x<m.w;x++)c.push([x,y]);
  return c.sort((a,b)=>Math.abs(a[0]-x0)+Math.abs(a[1]-y0)-Math.abs(b[0]-x0)-Math.abs(b[1]-y0)||a[1]-b[1]||a[0]-b[0]);}
// la gente que va con las piezas, en su sitio (al entrar y al acabar de ordenar)
function colocaGente(mapa){
  if(mapa==='nave')return colocaNaveros();
  for(const P of piezasYa(mapa)){const [x,y]=posPieza(mapa,P.k);
    for(const [gx,gy,id,dir] of genteP(P,x,y)){const e=ents.find(e=>e.id===id);if(e)Object.assign(e,{x:gx,y:gy,px:gx*16,py:gy*16,hx:gx,hy:gy,fx:gx,fy:gy,dir,moving:false});}}
}
const montarClub=mapa=>{if(mapa.startsWith('club-')&&ORDEN_P[mapa])aplicaOrden(mapa);};
// mientras mueves, la pieza se ve en el mapa en el cursor (aunque no quepa, encima de lo que haya): pon(P, x, y) en los objetos o, la
// alfombra, en el suelo; O y G, los objetos y el suelo sin ella, para volver a dejarlos como estaban
function vistaOrden(m,P,O,G){
  for(let y=0;y<m.h;y++){m.o[y]=O[y].slice();m.g[y]=G[y].slice();}
  if(P.suelo){const fs=decoV('suelo')?'-'+decoV('suelo'):'';
    for(let y=0;y<m.h;y++)for(let x=0;x<m.w;x++)if(/^alf/.test(m.g[y][x]))m.g[y][x]='floor'+fs;
    celdasP(P,ORDEN.x,ORDEN.y).forEach(([x,y],j)=>{if(m.g[y]&&m.g[y][x]!==undefined&&m.g[y][x]!=='mat')m.g[y][x]='alf'+decoV('alfombra')+'abcd'[j]+fs;});return;}
  for(const [x,y,o] of celdasP(P,ORDEN.x,ORDEN.y))if(o&&m.o[y]&&m.o[y][x]!==undefined)m.o[y][x]=o;
}
// el marco de la pieza en el cursor: verde si cabe, rojo si no ([x, y, w, h, color] en el mapa); y la casilla de su gente, en azul
function rectsOrden(){
  if(!ORDEN)return [];const P=piezaDe(ORDEN.mapa,ORDEN.k),F=celdasP(P,ORDEN.x,ORDEN.y).filter((c,j)=>P.suelo||P.o[j][1]>=0),c=ORDEN.no?'#e04040':'#58d080',o=[];
  const x0=Math.min(...F.map(f=>f[0]))*16,y0=Math.min(...F.map(f=>f[1]))*16,x1=(Math.max(...F.map(f=>f[0]))+1)*16,y1=(Math.max(...F.map(f=>f[1]))+1)*16;
  o.push([x0,y0,x1-x0,1,c],[x0,y1-1,x1-x0,1,c],[x0,y0,1,y1-y0,c],[x1-1,y0,1,y1-y0,c]);
  for(const [x,y] of genteP(P,ORDEN.x,ORDEN.y))o.push([x*16+6,y*16+6,4,4,'#80b0f0']);
  return o;
}
// mover una pieza: las flechas la llevan (sin salirse del mapa), A la deja si cabe y B la devuelve
async function moverPieza(mapa,k){
  const m=MAPS[mapa],P=piezaDe(mapa,k);if(!m.opos||!m.opos[k])return false;const [x0,y0]=m.opos[k];
  if(!P.suelo)for(const [cx,cy] of celdasP(P,x0,y0))ob(m,cx,cy,null);
  const O=m.o.map(r=>r.slice()),G=m.g.map(r=>r.slice());
  ORDEN={mapa,k,x:x0,y:y0,no:''};
  const xs=P.o.map(o=>o[0]).concat((P.gente||[]).map(g=>g[0])),ys=P.o.map(o=>o[1]).concat((P.gente||[]).map(g=>g[1]));
  const mx=[-Math.min(...xs),m.w-1-Math.max(...xs)],my=[-Math.min(...ys),m.h-1-Math.max(...ys)];
  const muestra=()=>{ORDEN.no=cabePieza(mapa,k,ORDEN.x,ORDEN.y,O);vistaOrden(m,P,O,G);
    dlgFijo(`${P.n} · ${ORDEN.no?ORDEN_MOTIVO[ORDEN.no]:'Aquí cabe.'}\nFlechas: mover · A: dejar aquí · B: como estaba`,ORDEN_P[mapa].n);};
  muestra();
  const r=await new Promise(res=>push(b=>{
    if(b==='B'){pop();res(false);return;}
    if(b==='A'){if(ORDEN.no){sfx('no');return;}pop();res(true);return;}
    const d={left:[-1,0],right:[1,0],up:[0,-1],down:[0,1]}[b];if(!d)return;
    const nx=clamp(ORDEN.x+d[0],mx[0],mx[1]),ny=clamp(ORDEN.y+d[1],my[0],my[1]);if(nx===ORDEN.x&&ny===ORDEN.y)return;
    ORDEN.x=nx;ORDEN.y=ny;sfx('sel');muestra();}));
  const x=ORDEN.x,y=ORDEN.y;ORDEN=null;dlg.hidden=true;
  for(let j=0;j<m.h;j++){m.o[j]=O[j].slice();m.g[j]=G[j].slice();}
  if(!P.suelo)for(const [cx,cy,o] of celdasP(P,x0,y0))ob(m,cx,cy,o);
  if(r)(S.coloca[mapa]||(S.coloca[mapa]={}))[k]=[x,y];
  rehaceOrden(mapa);if(r)sfx('get');return r;
}
// después de mover: el mapa con lo elegido y la gente en su sitio
function rehaceOrden(mapa){
  if(mapa==='home'){MAPS.home.carpasK=null;montarCasa();}else if(mapa==='nave')montarNave();else montarClub(mapa);
  if(S.map===mapa)colocaGente(mapa);
}
// ORDENAR: la lista de lo que se puede mover, hasta Terminar
async function ordenar(mapa){
  let i=0;
  for(;;){const L=piezasYa(mapa);
    i=await menu(L.map(P=>({label:P.n})).concat([{label:'Terminar'}]),{title:ORDEN_P[mapa].n,initial:i,cancel:true});
    if(i<0||i>=L.length)return;await moverPieza(mapa,L[i].k);}
}
// dónde están las mesas de la nave (la casilla de la izquierda) y de quién es la casilla x, y: el número de mesa o −1
const posMesa=i=>posPieza('nave','m'+i);
const mesaIdx=(x,y)=>MESAS_X.findIndex((_,i)=>{const [X,Y]=posMesa(i);return Y===y&&(X===x||X+1===x);});
// la lámpara del billar de la asociación, sobre el billar, donde esté (LUZ_CLUB)
function luzClub(k){
  const L=LUZ_CLUB[k];if(k!=='rv')return L;const [x,y]=posPieza('club-rv','billar');
  return {fondo:L.fondo,l:[[x*16+16,y*16+6].concat(L.l[0].slice(2)),L.l[1]]};
}
/* ---------- la manguera de la nave, guiada (1.37, lo pidió el usuario: «guiar desde cualquier punto desde el depósito hasta las mesas») ----------
   La tubería sale del tanque por el pie de la pared (RIEGO_Y) y, para cada mesa, baja por una columna de la fila del fondo (2, detrás
   de los muebles) hasta el suelo y sigue por las casillas libres (fila 3 en adelante, sin objetos ni salidas) hasta la mesa: por
   arriba o por un lado. La columna, la primera que llega en este orden: la de la mesa, la de su derecha y las demás de la más cercana
   a la más lejana, la del tanque al final; el camino, el más corto (abajo, izquierda, derecha, arriba). O: los objetos; pos: las piezas
   que cambian ({k: [x, y]}). Da {c: la columna, t: las casillas del suelo, lado: 'up' | 'left' | 'right'} o null */
function rutaRiego(i,O=MAPS.nave.o,pos={}){
  const m=MAPS.nave,[X,Y]=pos['m'+i]||posMesa(i),T=(pos.riego||posPieza('nave','riego'))[0];
  const libre=(x,y)=>y>=3&&pisable(m,x,y)&&!O[y][x];
  const fin=(x,y)=>y===Y-1&&(x===X||x===X+1)?'up':y===Y&&x===X-1?'right':y===Y&&x===X+2?'left':'';
  const cols=Array.from({length:m.w},(_,c)=>c).sort((a,b)=>peso(a)-peso(b)||a-b);
  function peso(c){return (c===T?100:0)+(c===X?0:c===X+1?.5:1+Math.abs(c-X));}
  for(const c of cols){
    if(Y===3){if(c===X||c===X+1)return {c,t:[],lado:'up',Y};continue;}
    if(!libre(c,3))continue;
    const pa=new Map([[c+',3',null]]),q=[[c,3]];let hit=null;
    while(q.length){const [x,y]=q.shift();if(fin(x,y)){hit=[x,y];break;}
      for(const [dx,dy] of [[0,1],[-1,0],[1,0],[0,-1]]){const nx=x+dx,ny=y+dy,k=nx+','+ny;if(!pa.has(k)&&libre(nx,ny)){pa.set(k,[x,y]);q.push([nx,ny]);}}}
    if(!hit)continue;
    const t=[];for(let p=hit;p;p=pa.get(p.join()))t.unshift(p);
    return {c,t,lado:fin(...hit),Y};
  }
  return null;
}
