/* =========================================================
   MAPAS
   ========================================================= */
const MAPS={};
function newMap(name,w,h,g){const m={name,w,h,g:[],o:[],exits:{},doors:{},music:'town'};for(let y=0;y<h;y++){m.g.push(Array(w).fill(g));m.o.push(Array(w).fill(null));}MAPS[name]=m;return m;}
const gr=(m,x,y,k)=>{if(x>=0&&y>=0&&x<m.w&&y<m.h)m.g[y][x]=k;};
const ob=(m,x,y,k)=>{if(x>=0&&y>=0&&x<m.w&&y<m.h)m.o[y][x]=k;};
const rect=(m,x0,y0,x1,y1,fn)=>{for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++)fn(x,y);};
function building(m,id,x0,y0,w,h,doorX,warp){
  (m.blds=m.blds||[]).push({id,x0,y0,w,h,doorX});
  for(let x=x0;x<x0+w;x++){gr(m,x,y0,'roofT_'+id);gr(m,x,y0+1,'roofB_'+id);for(let y=y0+2;y<y0+h;y++)gr(m,x,y,'wall_'+id);
    if((x-x0)%3===1&&x!==doorX){gr(m,x,y0+3,'win_'+id);}}
  if(doorX!=null){gr(m,doorX,y0+h-1,'door_'+id);m.doors[doorX+','+(y0+h-1)]=warp;}
}
function buildMaps(){
  // ---------- TOWN ----------
  const m=newMap('town',40,30,'grass');m.music='town';
  for(let x=0;x<40;x++){ob(m,x,0,'tree');ob(m,x,1,'tree');ob(m,x,29,'tree');}
  for(let y=0;y<30;y++){ob(m,0,y,'tree');ob(m,39,y,'tree');}
  [[3,2],[10,2],[12,2],[22,2],[31,2],[36,2]].forEach(([x,y])=>gr(m,x,y,'flowers'));
  for(let x=1;x<39;x++){gr(m,x,9,'walk');gr(m,x,10,'roadT');gr(m,x,11,'roadB');gr(m,x,12,'walk');}
  building(m,'home',2,3,7,6,5,{to:'home',x:5,y:6,dir:'up'});
  building(m,'shop',14,3,7,6,17,{to:'shop',x:4,y:6,dir:'up'});
  building(m,'bar',23,3,7,6,26,{to:'bar',x:4,y:6,dir:'up'});
  building(m,'gray',32,3,6,6,null);
  ob(m,9,8,'sign');ob(m,13,8,'sign');ob(m,22,8,'sign');
  [11,21,31].forEach(x=>ob(m,x,9,'lamp'));
  // park
  rect(m,1,13,11,13,(x,y)=>{if(x!==5&&x!==6)ob(m,x,y,'fence');});ob(m,4,13,'sign');
  rect(m,5,13,6,27,(x,y)=>gr(m,x,y,'dirt'));
  rect(m,7,18,10,20,(x,y)=>gr(m,x,y,'tallgrass'));rect(m,1,21,3,23,(x,y)=>gr(m,x,y,'tallgrass'));
  [[1,15],[11,15],[1,20],[11,21],[2,24],[11,26],[8,27]].forEach(([x,y])=>ob(m,x,y,'tree'));
  [[9,16],[2,26],[1,17],[10,24]].forEach(([x,y])=>ob(m,x,y,'bush'));
  ob(m,3,17,'bench');
  [[2,14],[9,14],[8,22],[3,19],[10,27],[4,26],[9,25]].forEach(([x,y])=>gr(m,x,y,'flowers'));
  // plaza
  rect(m,14,14,26,24,(x,y)=>gr(m,x,y,'plaza'));rect(m,18,13,22,13,(x,y)=>gr(m,x,y,'plaza'));
  ob(m,20,19,'fountain');[[16,16],[24,16],[16,22],[24,22]].forEach(([x,y])=>ob(m,x,y,'bench'));
  [[14,14],[26,14],[14,24],[26,24]].forEach(([x,y])=>ob(m,x,y,'lamp'));ob(m,17,13,'sign');
  [14,17,20,23,26].forEach(x=>ob(m,x,26,'tree'));[[13,18],[12,22],[27,16],[18,27],[25,28],[13,27]].forEach(([x,y])=>gr(m,x,y,'flowers'));
  // river + docks
  rect(m,30,13,38,13,(x,y)=>ob(m,x,y,'fence'));
  rect(m,31,14,38,28,(x,y)=>gr(m,x,y,'water'));
  rect(m,34,16,38,25,(x,y)=>gr(m,x,y,'dock'));
  rect(m,31,19,33,19,(x,y)=>gr(m,x,y,'bridgeT'));rect(m,31,20,33,20,(x,y)=>gr(m,x,y,'bridgeB'));
  rect(m,27,19,30,20,(x,y)=>gr(m,x,y,'walk'));ob(m,29,18,'sign');
  [[28,15],[29,24],[28,27]].forEach(([x,y])=>ob(m,x,y,'tree'));
  ob(m,38,17,'crate');ob(m,38,18,'crate');ob(m,34,25,'crate');

  // ---------- HOME ----------
  // 1 casilla = 1 m: 12 × 6 m de suelo (72 m²). Dormitorio a la izquierda, escritorio y mesa de genética al fondo,
  // las carpas (montarCasa) al fondo a la derecha (A en x 8, B en x 10-11), cocina abajo a la izquierda y la puerta en (5,7)
  const h=newMap('home',12,8,'floor');h.music='home';
  rect(h,0,0,11,0,(x,y)=>gr(h,x,y,'iwT_home'));rect(h,0,1,11,1,(x,y)=>gr(h,x,y,'iwB_home'));
  ob(h,2,1,'iwin');ob(h,6,1,'iwin');ob(h,3,1,'poster');
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
const sitioLibre=(x,y)=>SITIOS.some((s,ci)=>!S.carpas[ci]&&x>=s.x&&x<s.x+s.w&&y===s.y);
let CLIENT_TILES=[];
function computeClientTiles(){
  const m=MAPS.town;CLIENT_TILES=[];
  for(let y=12;y<m.h;y++)for(let x=1;x<m.w-1;x++){const g=m.g[y][x];if((g==='plaza'||g==='walk'||g==='dirt')&&!m.o[y][x]&&!(y===13&&x>=18&&x<=22))CLIENT_TILES.push([x,y]);}
}

