/* =========================================================
   MAPAS
   ========================================================= */
const MAPS={};
function newMap(name,w,h,g){const m={name,w,h,g:[],o:[],exits:{},doors:{},music:'town'};for(let y=0;y<h;y++){m.g.push(Array(w).fill(g));m.o.push(Array(w).fill(null));}MAPS[name]=m;return m;}
const gr=(m,x,y,k)=>{if(x>=0&&y>=0&&x<m.w&&y<m.h)m.g[y][x]=k;};
const ob=(m,x,y,k)=>{if(x>=0&&y>=0&&x<m.w&&y<m.h)m.o[y][x]=k;};
const rect=(m,x0,y0,x1,y1,fn)=>{for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++)fn(x,y);};
// linde de los mapas (1.10): monte espeso de 3 m, dos copas alternas, por arriba y por los lados; seto de 1 m por abajo (el árbol
// alto, de 5,8 m, en fila de 1 en 1 era un peine de troncos y tapaba 5 filas). monte(m, x, y) pone el que toca en esa casilla
const monte=(m,x,y)=>ob(m,x,y,(x+y)&1?'monte2':'monte');
// op (1.10, edificios grises con puerta): ancha, la puerta ocupa doorX y doorX + 1 (se pinta centrada entre las dos: dx 8);
// fachada, el arte de la fachada si no es el de id ('gray-puerta': la gris con las ventanas de abajo separadas para la puerta);
// puerta, la fachada de la que sale la animación de la puerta ('home'); mascara, sin el trozo de pared de esa fachada
const GRIS_PUERTA={ancha:1,fachada:'gray-puerta',puerta:'home',mascara:1,dx:8};   // la casa de Txaro (la comisaría y el almacén, con la suya)
function building(m,id,x0,y0,w,h,doorX,warp,op){
  (m.blds=m.blds||[]).push(Object.assign({id,x0,y0,w,h,doorX},op));
  for(let x=x0;x<x0+w;x++){gr(m,x,y0,'roofT_'+id);gr(m,x,y0+1,'roofB_'+id);for(let y=y0+2;y<y0+h;y++)gr(m,x,y,'wall_'+id);
    if((x-x0)%3===1&&x!==doorX){gr(m,x,y0+3,'win_'+id);}}
  if(doorX!=null)for(let x=doorX;x<=doorX+(op&&op.ancha?1:0);x++){gr(m,x,y0+h-1,'door_'+id);m.doors[x+','+(y0+h-1)]=Object.assign({},warp,{x:warp.x+x-doorX});}
}
// las tres zonas de fuera (1.10): policía y ladrones por paso (× pol y × lad), precio de la calle (× precio) y música de calle
// y la comarca (1.10): dos ciudades pequeñas y dos pueblos, a los que se va en autobús (PARADAS)
const ZONAS={town:{n:'Ribera Verde',pol:1,lad:1,precio:1},alto:{n:'Barrio alto',pol:1.5,lad:.5,precio:1},astilleros:{n:'Astilleros',pol:.5,lad:2,precio:1.2},
  puerto:{n:'Puerto Viejo',pol:.8,lad:.6,precio:1.15},valdehierro:{n:'Valdehierro',pol:.6,lad:1.4,precio:.9},
  mendialde:{n:'Mendialde',pol:.2,lad:.1,precio:1},errotabarri:{n:'Errotabarri',pol:.2,lad:.1,precio:1}};
// paradas del autobús (1.10): el poste (x, y), dónde te deja el autobús (a: x, y, hacia dónde miras) y lo que hay hasta la estación
// de Ribera Verde (min, €): todas las líneas pasan por ella, así que un viaje entre dos pueblos suma los dos tramos. De 7:00 a 21:00
const PARADAS={town:{n:'Ribera Verde',x:8,y:12,a:[7,12,'down'],min:0,eur:0},
  puerto:{n:'Puerto Viejo',x:19,y:9,a:[20,9,'down'],min:25,eur:2},valdehierro:{n:'Valdehierro',x:14,y:11,a:[15,11,'down'],min:20,eur:2},
  mendialde:{n:'Mendialde',x:10,y:13,a:[11,13,'down'],min:40,eur:3},errotabarri:{n:'Errotabarri',x:8,y:11,a:[9,11,'down'],min:30,eur:3}};
const BUS_HORAS=[7*60,21*60];
const viaje=(a,b)=>({min:PARADAS[a].min+PARADAS[b].min,eur:PARADAS[a].eur+PARADAS[b].eur});
function buildMaps(){
  // ---------- TOWN ----------
  const m=newMap('town',40,30,'grass');m.music='town';
  for(let x=0;x<40;x++){monte(m,x,0);monte(m,x,1);ob(m,x,29,'seto');}
  for(let y=0;y<30;y++){monte(m,0,y);monte(m,39,y);}
  [[3,2],[10,2],[12,2],[22,2],[31,2],[36,2]].forEach(([x,y])=>gr(m,x,y,'flowers'));
  for(let x=1;x<39;x++){gr(m,x,9,'walk');gr(m,x,10,'roadT');gr(m,x,11,'roadB');gr(m,x,12,'walk');}
  building(m,'home',2,3,7,6,5,{to:'home',x:5,y:6,dir:'up'});
  building(m,'shop',14,3,7,6,17,{to:'shop',x:4,y:6,dir:'up'});
  building(m,'bar',23,3,7,6,26,{to:'bar',x:4,y:6,dir:'up'});
  building(m,'gray',32,3,6,6,34,{to:'txaro',x:4,y:6,dir:'up'},GRIS_PUERTA);   // casa de Txaro (1.10)
  ob(m,9,8,'sign');ob(m,13,8,'sign');ob(m,22,8,'sign');
  [11,21,31].forEach(x=>ob(m,x,9,'lamp'));
  // park
  rect(m,1,13,11,13,(x,y)=>{if(x!==5&&x!==6)ob(m,x,y,'fence');});ob(m,4,13,'sign');
  rect(m,5,13,6,27,(x,y)=>gr(m,x,y,'dirt'));
  rect(m,7,18,10,20,(x,y)=>gr(m,x,y,'tallgrass'));rect(m,1,21,3,23,(x,y)=>gr(m,x,y,'tallgrass'));
  // árboles altos (1.10): la copa ocupa 3 casillas de ancho y las 5 de encima del tronco; ninguna tapa un objeto, un arbusto
  // con premio ni la zona por la que pasea un personaje
  [[1,15],[1,20],[11,21],[2,24],[4,28],[12,28]].forEach(([x,y])=>ob(m,x,y,'tree'));
  [[9,16],[2,26],[10,24]].forEach(([x,y])=>ob(m,x,y,'bush'));
  ob(m,3,17,'bench');
  [[2,14],[9,14],[8,22],[3,19],[10,27],[4,26],[9,25]].forEach(([x,y])=>gr(m,x,y,'flowers'));
  // plaza
  rect(m,14,14,26,24,(x,y)=>gr(m,x,y,'plaza'));rect(m,18,13,22,13,(x,y)=>gr(m,x,y,'plaza'));
  ob(m,20,19,'fountain');[[16,16],[24,16],[16,22],[24,22]].forEach(([x,y])=>ob(m,x,y,'bench'));
  [[14,14],[26,14],[14,24],[26,24]].forEach(([x,y])=>ob(m,x,y,'lamp'));ob(m,17,13,'sign');
  [17,20,23,26].forEach(x=>ob(m,x,28,'tree'));[[13,18],[12,22],[27,16],[18,27],[25,28],[13,27]].forEach(([x,y])=>gr(m,x,y,'flowers'));
  // river + docks
  rect(m,30,13,38,13,(x,y)=>ob(m,x,y,'fence'));
  rect(m,31,14,38,28,(x,y)=>gr(m,x,y,'water'));
  rect(m,34,16,38,25,(x,y)=>gr(m,x,y,'dock'));
  rect(m,31,19,33,19,(x,y)=>gr(m,x,y,'bridgeT'));rect(m,31,20,33,20,(x,y)=>gr(m,x,y,'bridgeB'));
  rect(m,27,19,30,20,(x,y)=>gr(m,x,y,'walk'));ob(m,29,18,'sign');
  [[28,15],[29,24],[28,27]].forEach(([x,y])=>ob(m,x,y,'tree'));
  ob(m,38,17,'crate');ob(m,38,18,'crate');ob(m,34,25,'crate');
  // salidas (1.10): al norte, la cuesta al barrio alto; al este, por el muelle, los astilleros
  rect(m,11,0,12,8,(x,y)=>{gr(m,x,y,'walk');ob(m,x,y,null);});
  [11,12].forEach(x=>m.doors[x+',0']={to:'alto',x,y:28,dir:'up'});
  [20,21].forEach(y=>{ob(m,39,y,null);gr(m,39,y,'dock');m.doors['39,'+y]={to:'astilleros',x:1,y,dir:'right'};});
  ob(m,10,4,'sign');ob(m,38,19,'sign');
  ob(m,8,12,'parada');   // el autobús de la comarca, delante del piso (1.10)

  // ---------- BARRIO ALTO (1.10) ----------
  // al norte del barrio, cuesta arriba: la plaza del Ensanche, los jardines y la comisaría del sargento Molina.
  // Más policía y menos ladrones; clientes con dinero (pijos y turistas) desde el capítulo 3
  const a=newMap('alto',40,30,'grass');a.music='town';
  for(let x=0;x<40;x++){monte(a,x,0);monte(a,x,1);if(x!==11&&x!==12)ob(a,x,29,'seto');}
  for(let y=0;y<30;y++){monte(a,0,y);monte(a,39,y);}
  for(let x=1;x<39;x++){gr(a,x,20,'walk');gr(a,x,21,'roadT');gr(a,x,22,'roadB');gr(a,x,23,'walk');}
  rect(a,11,24,12,29,(x,y)=>gr(a,x,y,'walk'));[11,12].forEach(x=>a.doors[x+',29']={to:'town',x,y:1,dir:'down'});
  rect(a,3,4,19,4,(x,y)=>gr(a,x,y,'flowers'));rect(a,3,5,19,17,(x,y)=>gr(a,x,y,'plaza'));rect(a,11,18,12,19,(x,y)=>gr(a,x,y,'walk'));
  ob(a,11,11,'fountain');[[7,8],[15,8],[7,14],[15,14]].forEach(([x,y])=>ob(a,x,y,'bench'));
  [[3,5],[19,5],[3,17],[19,17]].forEach(([x,y])=>ob(a,x,y,'lamp'));[[4,3],[8,3],[14,3],[18,3]].forEach(([x,y])=>ob(a,x,y,'tree'));
  [[2,6],[2,10],[2,14],[20,7],[20,12]].forEach(([x,y])=>ob(a,x,y,'bush'));ob(a,10,18,'sign');
  building(a,'comisaria',24,13,6,6,26,{to:'comisaria',x:4,y:6,dir:'up'},{ancha:1,dx:8});   // de piedra (1.10)
  rect(a,23,19,30,19,(x,y)=>gr(a,x,y,'walk'));ob(a,23,19,'sign');
  rect(a,31,14,37,18,(x,y)=>gr(a,x,y,'flowers'));rect(a,31,12,37,12,(x,y)=>ob(a,x,y,'fence'));[[32,15],[35,17],[36,14]].forEach(([x,y])=>ob(a,x,y,'bush'));
  [[24,4],[28,3],[33,4],[37,6],[26,8],[31,7],[35,9],[29,10]].forEach(([x,y])=>ob(a,x,y,'tree'));
  [[25,6],[30,5],[34,7],[27,10],[32,9]].forEach(([x,y])=>gr(a,x,y,'flowers'));ob(a,22,7,'sign');ob(a,30,8,'bench');
  [6,17,32].forEach(x=>ob(a,x,20,'lamp'));
  [[3,25],[7,27],[2,28],[16,25],[20,27],[28,25],[32,27],[36,25]].forEach(([x,y])=>ob(a,x,y,'tree'));   // x múltiplo de 4: entre los arbustos
  rect(a,14,24,37,24,(x,y)=>{if(x%4===2)ob(a,x,y,'bush');});[[5,26],[19,26],[30,26],[24,28]].forEach(([x,y])=>gr(a,x,y,'flowers'));

  // ---------- ASTILLEROS (1.10) ----------
  // al este del muelle: los astilleros cerrados, el muelle de carga y el almacén donde Toño recoge los encargos de Baltasar.
  // Pocos controles y muchos ladrones; las esquinas de Darko: los clientes pagan más, pero sus chicos vigilan
  const t=newMap('astilleros',40,30,'dirt');t.music='town';
  for(let x=0;x<40;x++){monte(t,x,0);monte(t,x,1);}
  for(let y=0;y<23;y++){if(y!==20&&y!==21)monte(t,0,y);monte(t,39,y);}
  rect(t,0,23,39,29,(x,y)=>gr(t,x,y,'water'));rect(t,0,19,39,22,(x,y)=>gr(t,x,y,'dock'));
  rect(t,6,23,8,27,(x,y)=>gr(t,x,y,'dock'));rect(t,26,23,28,27,(x,y)=>gr(t,x,y,'dock'));
  [20,21].forEach(y=>t.doors['0,'+y]={to:'town',x:38,y,dir:'left'});
  building(t,'nave',16,8,6,6,18,{to:'almacen',x:4,y:6,dir:'up'},{ancha:1,dx:8});ob(t,15,13,'sign');ob(t,2,18,'sign');   // nave de chapa (1.10)
  rect(t,2,3,6,7,(x,y)=>gr(t,x,y,'tallgrass'));rect(t,30,13,35,15,(x,y)=>gr(t,x,y,'tallgrass'));rect(t,9,3,13,4,(x,y)=>gr(t,x,y,'grass'));
  rect(t,24,4,37,4,(x,y)=>ob(t,x,y,'fence'));rect(t,24,10,37,10,(x,y)=>{if(x!==30&&x!==31)ob(t,x,y,'fence');});rect(t,24,5,24,9,(x,y)=>ob(t,x,y,'fence'));rect(t,37,5,37,9,(x,y)=>ob(t,x,y,'fence'));
  [[25,5],[26,5],[25,6],[36,5],[36,6],[35,5],[28,8],[33,8],[3,17],[4,17],[10,16],[11,16],[10,15],[33,18],[34,18],[35,18],[7,27],[27,27],[22,17]].forEach(([x,y])=>ob(t,x,y,'crate'));
  [[9,19],[20,19],[31,19],[14,8]].forEach(([x,y])=>ob(t,x,y,'lamp'));[[10,3],[12,4],[2,10],[37,14]].forEach(([x,y])=>ob(t,x,y,'tree'));

  // ---------- MENDIALDE (1.10): el pueblo de caseríos del que viene el protagonista ----------
  // la carretera de la comarca cruza el pueblo; al norte, el caserío de la familia (se entra: casa-ama) y el de los vecinos;
  // al sur, la plaza con su fuente y la parada, otro caserío y la huerta de maíz
  const v=newMap('mendialde',32,24,'grass');v.music='town';
  for(let x=0;x<32;x++){monte(v,x,0);monte(v,x,1);ob(v,x,23,'seto');}
  for(let y=0;y<24;y++){monte(v,0,y);monte(v,31,y);}
  for(let x=1;x<31;x++){gr(v,x,10,'walk');gr(v,x,11,'roadT');gr(v,x,12,'roadB');gr(v,x,13,'walk');}
  building(v,'caserio',3,4,8,6,6,{to:'casa-ama',x:4,y:6,dir:'up'},{ancha:1,dx:8});
  building(v,'caserio2',19,3,8,6,null);rect(v,19,9,26,9,(x,y)=>gr(v,x,y,'dirt'));
  rect(v,12,14,19,18,(x,y)=>gr(v,x,y,'plaza'));ob(v,15,16,'fountain');ob(v,13,17,'bench');ob(v,18,17,'bench');
  [[12,14],[19,14]].forEach(([x,y])=>ob(v,x,y,'lamp'));ob(v,10,13,'parada');ob(v,2,13,'sign');
  building(v,'caserio2',2,16,8,6,null);rect(v,2,22,9,22,(x,y)=>gr(v,x,y,'dirt'));
  rect(v,21,15,29,15,(x,y)=>{if(x!==25)ob(v,x,y,'fence');});rect(v,21,21,29,21,(x,y)=>ob(v,x,y,'fence'));
  rect(v,21,16,21,20,(x,y)=>ob(v,x,y,'fence'));rect(v,29,16,29,20,(x,y)=>ob(v,x,y,'fence'));rect(v,22,16,28,20,(x,y)=>gr(v,x,y,'tallgrass'));
  [[13,8],[29,8],[11,21],[20,21]].forEach(([x,y])=>ob(v,x,y,'tree'));[[2,3],[17,9],[28,13]].forEach(([x,y])=>ob(v,x,y,'bush'));
  [[12,3],[15,5],[4,14],[8,14],[24,14],[27,22],[14,20],[17,21]].forEach(([x,y])=>gr(v,x,y,'flowers'));
  // ---------- CASA DE AMA (1.10): dentro del caserío de la familia ----------
  const ca=newMap('casa-ama',10,8,'floor');ca.music='home';
  rect(ca,0,0,9,0,(x,y)=>gr(ca,x,y,'iwT_home'));rect(ca,0,1,9,1,(x,y)=>gr(ca,x,y,'iwB_home'));
  ob(ca,2,1,'iwin');ob(ca,7,1,'iwin');ob(ca,0,2,'bedT');ob(ca,0,3,'bedB');ob(ca,9,6,'fridge');ob(ca,5,4,'table');
  ob(ca,9,2,'plantDeco');ob(ca,0,7,'plantDeco');
  gr(ca,4,7,'mat');ca.exits['4,7']={to:'mendialde',x:6,y:10,dir:'down'};
  // ---------- PUERTO VIEJO (1.10): el pueblo pesquero, ciudad pequeña ----------
  // casas marineras de colores en fila frente al paseo, el muelle con sus pantalanes y el mar abajo
  const pv=newMap('puerto',40,24,'plaza');pv.music='town';
  for(let x=0;x<40;x++){monte(pv,x,0);monte(pv,x,1);}
  for(let y=0;y<16;y++){monte(pv,0,y);monte(pv,39,y);}
  ['marinera','marinera3','marinera2','marinera4','marinera','marinera2','marinera3','marinera4','marinera2'].forEach((k,i)=>building(pv,k,1+i*4,2,4,6,null));
  rect(pv,37,2,38,7,(x,y)=>gr(pv,x,y,'grass'));ob(pv,37,6,'bush');
  for(let x=1;x<39;x++)gr(pv,x,8,'walk');
  rect(pv,0,16,39,23,(x,y)=>{gr(pv,x,y,'water');ob(pv,x,y,null);});
  [[6,8],[22,24],[32,34]].forEach(([x0,x1],i)=>rect(pv,x0,16,x1,i===2?19:21,(x,y)=>gr(pv,x,y,'dock')));
  rect(pv,1,15,38,15,(x,y)=>{if(!(x>=6&&x<=8||x>=22&&x<=24||x>=32&&x<=34))ob(pv,x,y,'fence');});
  [5,15,27,35].forEach(x=>ob(pv,x,9,'lamp'));[[11,14],[18,14],[29,14]].forEach(([x,y])=>ob(pv,x,y,'bench'));
  [[8,20],[23,21],[24,20],[34,18]].forEach(([x,y])=>ob(pv,x,y,'crate'));ob(pv,19,9,'parada');ob(pv,2,9,'sign');
  [[4,14],[37,14]].forEach(([x,y])=>ob(pv,x,y,'tree'));
  // ---------- VALDEHIERRO (1.10): la ciudad pequeña de la industria ----------
  // bloques de ladrillo y la fundición a los dos lados de la carretera; al sureste, un solar vallado con cajas
  const vh=newMap('valdehierro',40,24,'walk');vh.music='town';
  for(let x=0;x<40;x++){monte(vh,x,0);monte(vh,x,1);ob(vh,x,23,'seto');}
  for(let y=0;y<24;y++){monte(vh,0,y);monte(vh,39,y);}
  building(vh,'ladrillo',2,2,7,6,null);building(vh,'ladrillo',10,2,7,6,null);building(vh,'ladrillo',19,2,7,6,null);building(vh,'fabrica',29,2,8,6,null);
  for(let x=1;x<39;x++){gr(vh,x,9,'roadT');gr(vh,x,10,'roadB');}
  building(vh,'ladrillo',2,13,7,6,null);building(vh,'ladrillo',10,13,7,6,null);
  rect(vh,21,13,37,21,(x,y)=>gr(vh,x,y,'dirt'));rect(vh,20,12,38,12,(x,y)=>{if(x!==28&&x!==29)ob(vh,x,y,'fence');});
  rect(vh,20,13,20,22,(x,y)=>ob(vh,x,y,'fence'));rect(vh,38,13,38,22,(x,y)=>ob(vh,x,y,'fence'));rect(vh,21,22,37,22,(x,y)=>ob(vh,x,y,'fence'));
  [[23,14],[24,14],[23,15],[33,15],[34,15],[34,16],[26,19],[31,20],[36,18]].forEach(([x,y])=>ob(vh,x,y,'crate'));rect(vh,30,17,33,19,(x,y)=>gr(vh,x,y,'tallgrass'));
  [[9,8],[18,8],[28,8],[6,11],[24,11]].forEach(([x,y])=>ob(vh,x,y,'lamp'));ob(vh,14,11,'parada');ob(vh,2,8,'sign');ob(vh,27,12,'sign');
  rect(vh,2,20,17,22,(x,y)=>gr(vh,x,y,'grass'));[[5,22],[14,22]].forEach(([x,y])=>ob(vh,x,y,'tree'));ob(vh,9,21,'bench');
  // ---------- ERROTABARRI (1.10): el pueblo del río, con su molino ----------
  const e=newMap('errotabarri',32,20,'grass');e.music='town';
  for(let x=0;x<32;x++){if(x<15||x>17){monte(e,x,0);monte(e,x,1);ob(e,x,19,'seto');}}
  for(let y=0;y<20;y++){monte(e,0,y);monte(e,31,y);}
  rect(e,15,0,17,19,(x,y)=>gr(e,x,y,'water'));rect(e,15,9,17,9,(x,y)=>gr(e,x,y,'bridgeT'));rect(e,15,10,17,10,(x,y)=>gr(e,x,y,'bridgeB'));
  for(let x=1;x<31;x++)if(x<15||x>17){gr(e,x,9,'dirt');gr(e,x,10,'dirt');}
  building(e,'caserio2',3,2,8,6,null);building(e,'caserio',20,2,8,6,null);rect(e,6,8,7,8,(x,y)=>gr(e,x,y,'dirt'));rect(e,23,8,24,8,(x,y)=>gr(e,x,y,'dirt'));
  ob(e,19,8,'sign');ob(e,8,11,'parada');ob(e,2,11,'sign');
  rect(e,2,13,10,13,(x,y)=>ob(e,x,y,'fence'));rect(e,2,17,10,17,(x,y)=>ob(e,x,y,'fence'));rect(e,3,14,9,16,(x,y)=>gr(e,x,y,'tallgrass'));
  [[13,17],[28,16],[25,16]].forEach(([x,y])=>ob(e,x,y,'tree'));[[11,12],[19,13],[23,12],[29,10]].forEach(([x,y])=>ob(e,x,y,'bush'));
  [[4,12],[11,14],[20,17],[25,17],[13,4],[29,6]].forEach(([x,y])=>gr(e,x,y,'flowers'));

  // ---------- HOME ----------
  // 1 casilla = 1 m: 12 × 6 m de suelo (72 m²). Dormitorio a la izquierda, escritorio y mesa de genética al fondo,
  // las carpas (montarCasa) al fondo (A en x 8, B en x 10-11 y C en x 2-3, junto a la cama), cocina abajo a la izquierda y la puerta en (5,7).
  // En la pared, solo encima de casillas que no puede tapar una carpa: ventanas en x 6 y x 9, diploma en x 7
  const h=newMap('home',12,8,'floor');h.music='home';
  rect(h,0,0,11,0,(x,y)=>gr(h,x,y,'iwT_home'));rect(h,0,1,11,1,(x,y)=>gr(h,x,y,'iwB_home'));
  ob(h,6,1,'iwin');ob(h,9,1,'iwin');ob(h,7,1,'poster');
  ob(h,0,2,'bedT');ob(h,0,3,'bedB');ob(h,1,2,'plantDeco');ob(h,4,2,'pc');ob(h,5,2,'lab');ob(h,6,2,'lab2');
  ob(h,0,6,'fridge');ob(h,3,5,'table');ob(h,11,7,'plantDeco');
  gr(h,5,7,'mat');h.exits['5,7']={to:'town',x:5,y:9,dir:'down'};
  // ---------- SHOP ----------
  const s=newMap('shop',10,8,'floorS');s.music='home';
  rect(s,0,0,9,0,(x,y)=>gr(s,x,y,'iwT_shop'));rect(s,0,1,9,1,(x,y)=>gr(s,x,y,'iwB_shop'));
  [0,1,8,9].forEach(x=>ob(s,x,1,'shelfW'));ob(s,4,1,'poster');
  rect(s,2,3,7,3,(x,y)=>ob(s,x,y,'counter'));
  ob(s,0,5,'display');ob(s,9,5,'display');ob(s,0,7,'plantDeco');ob(s,9,7,'plantDeco');
  gr(s,4,7,'mat');s.exits['4,7']={to:'town',x:17,y:9,dir:'down'};
  // ---------- BAR ----------
  const b=newMap('bar',10,8,'floorB');b.music='home';
  rect(b,0,0,9,0,(x,y)=>gr(b,x,y,'iwT_bar'));rect(b,0,1,9,1,(x,y)=>gr(b,x,y,'iwB_bar'));
  rect(b,0,1,3,1,(x,y)=>ob(b,x,y,'bottles'));ob(b,6,1,'iwin');
  rect(b,0,3,3,3,(x,y)=>ob(b,x,y,'barcounter'));ob(b,1,4,'stool');ob(b,3,4,'stool');
  ob(b,7,5,'btable');ob(b,9,2,'jukebox');ob(b,8,2,'btable');
  gr(b,4,7,'mat');b.exits['4,7']={to:'town',x:26,y:9,dir:'down'};
  // ---------- CASA DE TXARO (1.10) ----------
  const tx=newMap('txaro',10,8,'floor');tx.music='home';
  rect(tx,0,0,9,0,(x,y)=>gr(tx,x,y,'iwT_home'));rect(tx,0,1,9,1,(x,y)=>gr(tx,x,y,'iwB_home'));
  ob(tx,2,1,'iwin');ob(tx,7,1,'iwin');ob(tx,0,2,'bedT');ob(tx,0,3,'bedB');ob(tx,9,6,'fridge');
  ob(tx,5,4,'table');ob(tx,1,2,'plantDeco');ob(tx,9,2,'plantDeco');ob(tx,0,7,'plantDeco');
  gr(tx,4,7,'mat');tx.exits['4,7']={to:'town',x:34,y:9,dir:'down'};
  // ---------- COMISARÍA (1.10) ----------
  const c=newMap('comisaria',10,8,'floorS');c.music='home';
  rect(c,0,0,9,0,(x,y)=>gr(c,x,y,'iwT_shop'));rect(c,0,1,9,1,(x,y)=>gr(c,x,y,'iwB_shop'));
  [0,1,8,9].forEach(x=>ob(c,x,1,'shelfW'));ob(c,4,1,'iwin');rect(c,2,3,7,3,(x,y)=>ob(c,x,y,'counter'));
  ob(c,0,5,'bench');ob(c,9,5,'bench');ob(c,0,7,'plantDeco');ob(c,9,7,'plantDeco');
  gr(c,4,7,'mat');c.exits['4,7']={to:'alto',x:26,y:19,dir:'down'};
  // ---------- ALMACÉN DE LOS ASTILLEROS (1.10) ----------
  const w=newMap('almacen',10,8,'floorB');w.music='home';
  rect(w,0,0,9,0,(x,y)=>gr(w,x,y,'iwT_bar'));rect(w,0,1,9,1,(x,y)=>gr(w,x,y,'iwB_bar'));ob(w,6,1,'iwin');
  [[0,2],[1,2],[0,3],[8,2],[9,2],[9,3],[8,6],[9,6],[0,6]].forEach(([x,y])=>ob(w,x,y,'crate'));ob(w,5,4,'btable');ob(w,4,4,'stool');
  gr(w,4,7,'mat');w.exits['4,7']={to:'astilleros',x:18,y:14,dir:'down'};
}
// carpas del piso según S.carpas: un mueble sólido ('carpa') en las casillas de su sitio; se pinta entero desde su base
// (14-render) y por dentro se ve en la vista de carpa (09b-carpa)
function montarCasa(){
  const h=MAPS.home;if(!h||!S)return;
  const key=S.carpas.map(c=>c?c.t:'-').join();if(h.carpasK===key)return;h.carpasK=key;
  SITIOS.forEach(s=>{for(let x=s.x;x<s.x+s.w;x++)ob(h,x,s.y,null);});
  h.carpas=[];
  S.carpas.forEach((c,ci)=>{
    if(!c)return;const s=SITIOS[ci],x0=s.x,x1=x0+CARPAS[c.t].w-1;
    for(let x=x0;x<=x1;x++)ob(h,x,s.y,'carpa');
    h.carpas.push({ci,t:c.t,x0,x1,y:s.y});
  });
}
const sitioVisible=ci=>!S.carpas[ci]&&(ci<2||!!S.carpas[1]);   // C, junto a la cama, después de B
const sitioLibre=(x,y)=>SITIOS.findIndex((s,ci)=>sitioVisible(ci)&&x>=s.x&&x<s.x+s.w&&y===s.y);
// casillas donde puede salir un cliente, por zona (1.10): en el barrio, de la calle para abajo y fuera de la entrada de la plaza
// (Darko y Molina); en el barrio alto, la plaza del Ensanche y la avenida; en los astilleros, el patio y el muelle de carga
// copas (1.10): lo que tapa un objeto alto por encima de su casilla, [casillas a cada lado, filas hacia arriba]; ahí no sale un cliente
const COPA={tree:[1,5],monte:[1,2],monte2:[1,2]};
function tapadas(m){const t=new Set();for(let y=0;y<m.h;y++)for(let x=0;x<m.w;x++){const c=COPA[m.o[y][x]];if(c)for(let j=y-c[1];j<y;j++)for(let i=x-c[0];i<=x+c[0];i++)t.add(i+','+j);}return t;}
let CLIENT_TILES={};
function computeClientTiles(){
  CLIENT_TILES={};
  const zona={town:(x,y,g)=>y>=12&&(g==='plaza'||g==='walk'||g==='dirt')&&!(y===13&&x>=18&&x<=22),
    alto:(x,y,g)=>y<=23&&y!==21&&y!==22&&(g==='plaza'||g==='walk')&&!(y===19&&x>=23)&&!(x>=10&&x<=13&&y>=18),
    astilleros:(x,y,g)=>y>=12&&y<=21&&x>=2&&(g==='dirt'||g==='dock')&&!(x>=15&&x<=22&&y<=14),
    puerto:(x,y,g)=>y>=9&&(g==='plaza'||g==='dock'),valdehierro:(x,y,g)=>(y===8||y===11||y>=20)&&(g==='walk'||g==='grass'),
    mendialde:(x,y,g)=>g==='plaza',errotabarri:(x,y,g)=>g==='dirt'&&y>=9};
  for(const k in zona){const m=MAPS[k],l=CLIENT_TILES[k]=[],tp=tapadas(m),va=aPie(m,entrada(k));
    for(let y=1;y<m.h-1;y++)for(let x=1;x<m.w-1;x++){const g=m.g[y][x];if(zona[k](x,y,g)&&va.has(x+','+y)&&!tp.has(x+','+y)&&!(PARADAS[k]&&PARADAS[k].a[0]===x&&PARADAS[k].a[1]===y))l.push([x,y]);}}   // ni en la casilla donde deja el autobús (1.10)
}
// casillas a las que se llega andando desde (x, y) (1.10): ni sólidas ni puertas ni salidas (te llevan a otro mapa); un cliente
// encajonado entre cajas y agua no se podía visitar
// por dónde se entra a un mapa de fuera: la llegada del autobús o, si no tiene parada, la primera puerta que lleva a él
function entrada(k){if(PARADAS[k])return PARADAS[k].a;for(const n in MAPS)for(const d of Object.values(MAPS[n].doors))if(d.to===k)return [d.x,d.y];}
function aPie(m,[x0,y0]){
  const v=new Set([x0+','+y0]),q=[[x0,y0]];
  while(q.length){const [x,y]=q.shift();for(const [dx,dy] of [[1,0],[-1,0],[0,1],[0,-1]]){const nx=x+dx,ny=y+dy,k=nx+','+ny;
    if(v.has(k)||nx<0||ny<0||nx>=m.w||ny>=m.h||SOLID_G.test(m.g[ny][nx])||m.o[ny][nx]||m.doors[k]||m.exits[k])continue;v.add(k);q.push([nx,ny]);}}
  return v;
}

