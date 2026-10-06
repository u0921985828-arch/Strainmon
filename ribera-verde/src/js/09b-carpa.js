/* =========================================================
   VISTA DE CARPA (1.8)
   En el piso (1 casilla = 1 m) cada carpa es un mueble de 1-2 casillas. A delante de ella abre su vista de frente:
   una escena compuesta a 240 px, como el combate, a 1 m = 64 px (la carpa de 150 × 200 cm mide 96 × 128 px y una
   planta lista para cosechar, con su maceta, ~1,1 m = 70 px).
   Las plazas van en filas de CARPAS[t].cols macetas: la fila 0 delante y la 1 detrás (más arriba, pintada antes y
   al tresbolillo para que se vea). ◀ ▶ cambian de plaza y ▲ ▼ de fila; desde la fila de atrás, ▲ elige el foco.
   A cuida la planta (potAction) o cambia el foco (carpaAction); B sale. El tiempo no corre mientras se mira.
   Con atlas: fondo 'cuarto-cultivo', 'carpa-<t>-vista', 'maceta-vista-<k>' y 'planta-vista' (cepa × fase); sin él, lo de abajo.
   ========================================================= */
const VC_M=64,VC_SUELO=148,VC_FONDO=13;   // px por metro · fila de la base de la carpa · cuánto más arriba va la fila de atrás
const VC_ALTO=[4,10,26,50,56],VC_MUERTA=30;   // alto de la planta sobre la maceta por fase (6, 16, 40, 78 y 88 cm)
let VC=null;                              // carpa abierta: {ci, sel: plaza (índice de huecos()) o −1 = el foco, ocupado}
const vcCm=t=>CARPAS[t].cm.map(v=>Math.round(v*VC_M/100));
function vcGeo(ci){
  const c=S.carpas[ci],C=CARPAS[c.t],[w,h]=vcCm(c.t),x0=120-(w>>1),top=VC_SUELO-h,cw=w/C.cols;
  const pl=[];huecos().forEach((q,i)=>{if(q.c!==ci)return;const col=q.j%C.cols,fila=Math.floor(q.j/C.cols),off=C.filas>1?(fila?.3:.7):.5;
    pl.push({i,col,fila,x:Math.round(x0+(col+off)*cw),y:VC_SUELO-(fila?VC_FONDO:2)});});
  const n=Math.max(1,Math.round(Math.min(FOCOS[c.foco].cubre,C.plazas)/2)),focos=[];
  for(let k=0;k<n;k++)focos.push(Math.round(x0+(k+.5)*w/n));
  return {c,C,w,h,x0,top,pl,focos,fy:top+(c.t==='p60'?20:26)};   // fy: parte de abajo de los focos (~40 cm por encima de una planta lista)
}
// dónde lanzar un efecto sobre la plaza i (riego, cosecha): en la vista, sobre la planta; si no, sobre el jugador
function posPlaza(i){
  const q=VC&&vcGeo(VC.ci).pl.find(q=>q.i===i);if(!q)return [P.px+8,P.py+2];
  const p=S.pots[i],h=p?(p.dead?VC_MUERTA:VC_ALTO[plantStage(p)]):0;return [q.x,q.y-14-Math.round(h/2)];
}

/* ---------- arte procedural (sin atlas, y huella de lo que se pidió a PixelLab) ---------- */
const VK={pole:'#5a5e68',hi:'#8a8e98',tela:'#26272c',osc:'#1c1d22',techo:'#3e4048',my:'#d4d8e2',my2:'#b2b8c4',my3:'#f2f4f8',my4:'#c8ccd6',som:'#a8aebb'};
// el mueble del piso: frente de tela negra (ancho × alto reales a 16 px/m) y techo visto desde arriba (medio fondo); pies en (cw/2, ch−1)
function carpaMapa(tk){
  const key='cm|'+tk;if(carpaCache[key])return carpaCache[key];
  const C=CARPAS[tk],w=Math.round(C.cm[0]*.16),hf=Math.round(C.cm[1]*.16),ht=tk==='p60'?5:8,[c,x]=mkCanvas(w,hf+ht),t=painter(x,rngSeed(w));
  t.F(0,0,w,ht,VK.techo);t.F(0,0,w,1,VK.hi);t.F(0,ht-1,w,1,VK.hi);t.F(0,0,1,ht,VK.pole);t.F(w-1,0,1,ht,VK.pole);
  if(tk!=='p60'){t.F(w-7,2,4,3,VK.osc);t.F(w-6,2,2,1,VK.som);}                                // salida del extractor
  t.F(0,ht,w,hf,VK.tela);t.F(0,ht,1,hf,VK.pole);t.F(w-1,ht,1,hf,VK.pole);t.F(0,ht+hf-1,w,1,VK.osc);
  const dw=tk==='p60'?6:8,dx=tk==='g150'?3:(w-dw)>>1,dy=ht+3;                                  // puerta de cremallera
  t.F(dx,dy+1,dw,hf-5,'#2e3036');t.F(dx+1,dy,dw-2,1,'#a0a4ac');t.F(dx,dy+1,1,hf-5,'#a0a4ac');t.F(dx+dw-1,dy+1,1,hf-5,'#a0a4ac');t.P(dx+dw-2,dy+3,'#e0e2e8');
  if(tk==='g150'){t.F(w-9,ht+hf-9,6,4,VK.osc);for(let i=0;i<6;i+=2)t.F(w-9+i,ht+hf-9,1,4,'#3a3c44');}   // rejilla de ventilación
  return carpaCache[key]=c;
}
function pintarCarpaMapa(t,cam){
  const xc=(t.x0+t.x1+1)*8-cam.x,yb=t.y*16+15-cam.y;
  if(!arteCarpaMapa(t.t,xc,yb)){const c=carpaMapa(t.t);ctx.drawImage(c,xc-(c.width>>1),yb-c.height+1);}
  if(plantasVivas(t.ci)){ctx.fillStyle=FOCO_LUZ[FOCOS[S.carpas[t.ci].foco].tipo]+'.6)';ctx.fillRect(xc-3,yb+1,6,1);}   // la luz se escapa bajo la puerta
}
// la carpa abierta de frente: la puerta enrollada arriba, el mylar del fondo y de los lados en perspectiva y el suelo;
// lienzo de (ancho + 4) × (alto + 2), pies en el centro de la última fila
function carpaVista(tk){
  const key='cv|'+tk;if(carpaCache[key])return carpaCache[key];
  const [w,h]=vcCm(tk),W=w+4,H=h+2,[c,x]=mkCanvas(W,H),t=painter(x,rngSeed(w*3));
  const d=tk==='p60'?4:6,ix0=2,ix1=W-3,iy0=9,iy1=H-3,bx0=ix0+d,bx1=ix1-d,by0=iy0+d,by1=iy1-VC_FONDO-4;
  t.F(ix0,iy0,ix1-ix0+1,iy1-iy0+1,VK.my2);                                                    // paredes de los lados
  for(let y=iy0;y<by0;y++){const k=y-iy0;t.F(ix0+k,y,ix1-ix0+1-2*k,1,k%2?'#9aa0ac':'#8a909c');}   // techo
  for(let y=by1;y<=iy1;y++){const k=Math.round((y-by1)/(iy1-by1)*d);t.F(bx0-k,y,bx1-bx0+1+2*k,1,(y-by1)%4===3?VK.my:VK.my3);}   // suelo
  t.F(bx0,by0,bx1-bx0+1,by1-by0,VK.my4);                                                      // pared del fondo
  for(let i=bx0;i<=bx1;i++){const r=(i*7+3)%11;if(r<2)t.F(i,by0,1,by1-by0,'#e6e9f0');else if(r===5)t.F(i,by0,1,by1-by0,VK.my2);}
  for(let k=0;k<d;k++){t.P(ix0+k,iy0+k,VK.som);t.P(ix1-k,iy0+k,VK.som);}
  for(let y=by1;y<=iy1;y++){const k=Math.round((y-by1)/(iy1-by1)*d);t.P(bx0-k,y,VK.som);t.P(bx1+k,y,VK.som);}
  t.F(bx0,by0,1,by1-by0,VK.som);t.F(bx1,by0,1,by1-by0,VK.som);t.F(bx0,by1,bx1-bx0+1,1,VK.som);
  t.F(bx0,by0+1,bx1-bx0+1,1,VK.pole);                                                         // barra de colgar los focos
  t.F(0,0,2,H,VK.tela);t.F(W-2,0,2,H,VK.tela);                                                // bordes de la puerta abierta
  t.F(ix0,7,ix1-ix0+1,2,VK.pole);t.F(ix0,7,ix1-ix0+1,1,VK.hi);t.F(ix0,iy0,1,iy1-iy0+1,VK.pole);t.F(ix1,iy0,1,iy1-iy0+1,VK.hi);
  t.F(0,0,W,7,VK.tela);t.F(0,1,W,1,'#34353c');t.F(0,5,W,1,VK.osc);                            // la puerta, enrollada arriba
  for(const sx of [Math.round(W*.25),Math.round(W*.75)-2]){t.F(sx,0,2,8,'#3a3c44');t.F(sx,7,2,1,'#a0a4ac');}
  t.F(0,H-2,W,2,VK.pole);t.F(0,H-2,W,1,VK.hi);                                                 // riel del suelo
  return carpaCache[key]=c;
}
// el cuarto: pared del piso y suelo de tarima, a 64 px/m (240 × 160 = 3,75 × 2,5 m)
let cuartoProc=null;
function fondoCuarto(){
  if(cuartoProc)return cuartoProc;const [c,x]=mkCanvas(240,160),t=painter(x,rngSeed(11)),col='#ead8b4',ys=VC_SUELO-VC_FONDO-10;
  t.F(0,0,240,ys,col);for(let i=3;i<240;i+=8)t.F(i,0,1,ys,shade(col,-10));
  t.F(0,ys-6,240,6,'#f4ecd8');t.F(0,ys-6,240,1,'#c8b896');t.F(0,ys-1,240,1,'#a89470');           // rodapié
  for(let y=ys;y<160;y++){const k=y-ys;t.F(0,y,240,1,k%5===4?'#b48446':'#d8a868');}
  for(let y=ys;y<160;y+=5)for(let i=0;i<6;i++){const xx=Math.floor(t.R()*236)+2;t.F(xx,y,1,4,'#b48446');}
  t.noise(260,['#e6bc80'],0,ys,240,160-ys);
  t.F(186,40,14,9,'#f4f4ee');t.F(186,40,14,1,'#c8c8c0');t.P(190,44,'#3a3a44');t.P(195,44,'#3a3a44');   // enchufe
  t.F(187,49,1,ys-49-6,'#5a5e68');                                                              // cable
  return cuartoProc=c;
}
// maceta de la vista a 64 px/m: ancho, alto, cuerpo, borde y tela/plástico (7 L 14 × 12 · 11 L 16 × 14 · 18 L 19 × 16 · 25 L 22 × 17)
const MACETA_VISTA={plastico7:[14,12,'#2c2c30','#4a4a52',0],tela11:[16,14,'#45474e','#5e6068',1],plastico18:[19,16,'#2c2c30','#4a4a52',0],tela25:[22,17,'#7a6c50','#988a6c',1]};
function macetaVista(k){
  const key='mv|'+k;if(carpaCache[key])return carpaCache[key];
  const [w,h,cu,bo,tela]=MACETA_VISTA[k]||MACETA_VISTA.plastico7,[c,x]=mkCanvas(w,h),t=painter(x,rngSeed(w));
  if(tela){t.F(0,1,w,h-1,cu);t.F(0,0,w,2,bo);t.F(1,3,w-2,1,shade(cu,-18));t.F(2,h-4,w-4,1,shade(cu,-12));t.F(1,0,w-2,1,'#5a3a20');}
  else{t.F(1,1,w-2,h-1,cu);t.F(0,0,w,2,bo);t.F(1,0,w-2,1,'#5a3a20');t.F(2,3,1,h-5,'#6a6a74');t.F(0,1,1,1,bo);t.F(w-1,1,1,1,bo);}
  t.F(1,h-1,w-2,1,'#18181c');
  return carpaCache[key]=c;
}
// planta de la vista: tallo, pares de hojas (las de abajo más grandes) y, en floración, cogollos en las puntas; base en (32, 63)
function plantaVistaProc(st,dry,bud){
  const key='pv|'+st+'|'+dry+'|'+bud;if(plantCache[key])return plantCache[key];
  const [c,x]=mkCanvas(64,64),t=painter(x,rngSeed(st*7+3)),B=63,cx=32;
  const g1=dry?'#b8aa48':'#3c9a3e',g2=dry?'#8a7c30':'#22662a',g3=dry?'#d8cc78':'#74d064',mu=st===9;
  const H=mu?VC_MUERTA:VC_ALTO[st];
  const hoja=(hx,hy,s,o)=>{drawLeafPx(t,hx,hy,s+.6,mu?'#5a4a28':g2);drawLeafPx(t,hx,hy,s,mu?'#8a7040':g1);if(s>2.2&&!mu)drawLeafPx(t,hx,hy-.5,s*.45,g3);};
  const cogollo=(bx,by,rx,ry)=>t.blob(bx,by,rx,ry,bud,shade(bud,-60),shade(bud,50));
  if(st===0){t.F(cx,B-3,1,4,g2);t.blob(cx-2,B-3.5,2,1.2,g1,g2,g3);t.blob(cx+3,B-3.5,2,1.2,g1,g2,g3);return plantCache[key]=c;}
  t.F(cx-(st>=3?1:0),B-H+3,st>=3?2:1,H-3,mu?'#8a7040':g2);
  const nodos=st===1?2:st===2?4:mu?4:6;
  for(let n=0;n<nodos;n++){
    const y=B-Math.round((n+1)*H/(nodos+1.3)),f=1-n/(nodos+1)*.55,len=(st===1?4:st===2?9:15)*f;
    if(st>=3){t.F(cx-Math.round(len*.7),y,Math.round(len*.7),1,g2);t.F(cx,y,Math.round(len*.7),1,g2);}
    hoja(cx-len*.55,y-1,Math.max(1.2,len*.22),-1);hoja(cx+len*.55,y-1,Math.max(1.2,len*.22),1);
    if(st>=3&&n>0){const r=st===4?2.2:1.6;cogollo(cx-len*.72,y-3,r,r*1.4);cogollo(cx+len*.72,y-3,r,r*1.4);}
  }
  if(st>=3){const r=st===4?3.2:2.4;cogollo(cx+.5,B-H+6,r,r*2.2);if(st===4)for(let i=0;i<8;i++)t.P(cx-3+Math.floor(t.R()*7),B-H+2+Math.floor(t.R()*10),'#ffffff');}
  else hoja(cx+.5,B-H+2,st===1?1.4:2.4,0);
  return plantCache[key]=c;
}

/* ---------- la escena ---------- */
function renderCarpa(now){
  const g=vcGeo(VC.ci),{c}=g,F=FOCOS[c.foco],on=plantasVivas(VC.ci);
  if(!arteFondoCuarto())fondoAncho(fondoCuarto());
  ctx.save();ctx.translate(OX(),0);
  if(!arteCarpaVista(c.t,120,VC_SUELO+1)){const cv=carpaVista(c.t);ctx.drawImage(cv,120-(cv.width>>1),VC_SUELO+2-cv.height);}
  if(on){ctx.globalCompositeOperation='lighter';const a=.1+.16*Math.min(1,F.w/600),hw=g.w/g.focos.length/2;
    for(const fx of g.focos){const gr=ctx.createLinearGradient(0,g.fy,0,VC_SUELO);gr.addColorStop(0,FOCO_LUZ[F.tipo]+a+')');gr.addColorStop(1,FOCO_LUZ[F.tipo]+'0)');
      ctx.fillStyle=gr;ctx.beginPath();ctx.moveTo(fx-10,g.fy);ctx.lineTo(fx+10,g.fy);ctx.lineTo(fx+hw,VC_SUELO);ctx.lineTo(fx-hw,VC_SUELO);ctx.fill();}
    ctx.globalCompositeOperation='source-over';}
  ctx.save();ctx.beginPath();ctx.rect(g.x0,0,g.w,SH);ctx.clip();   // las copas no salen de la carpa (a 64 px/m una planta lista es más ancha que su plaza)
  for(const q of [...g.pl].sort((a,b)=>a.y-b.y||a.x-b.x))vcPlanta(q,now);
  ctx.restore();
  for(const fx of g.focos)if(!arteFoco(F.tipo,fx,g.fy,g.top+9)){const f=focoProc(F.tipo);ctx.fillStyle='#2a2b30';ctx.fillRect(fx-7,g.top+9,1,g.fy-g.top-19);ctx.fillRect(fx+6,g.top+9,1,g.fy-g.top-19);ctx.drawImage(f,fx-16,g.fy-11);}
  vcCursor(g,now);
  if(ARTE.ok)pintarVfx(now,{x:0,y:0},'home');
  ctx.restore();
}
// maceta y planta de una plaza; devuelve la fila de arriba de lo que se ve (para la flecha)
function vcPlanta(q,now){
  const p=S.pots[q.i],k=S.macetas[q.i];
  let rim=arteMacetaVista(k,q.x,q.y);
  if(rim==null){const m=macetaVista(k);ctx.drawImage(m,q.x-(m.width>>1),q.y-m.height+1);rim=q.y-m.height+1;}
  q.alto=q.y-rim;
  if(!p)return;
  const yb=rim+2,h=artePlantaVista(p,q.x,yb,now);
  q.alto+=h===false?(p.dead?VC_MUERTA:VC_ALTO[plantStage(p)]):h-2;
  if(h===false){const s=getStrain(p.sid),pv=plantaVistaProc(p.dead?9:plantStage(p),!p.dead&&p.water<=0,s?s.c:'#9bd35a');
    balanceo(pv,q.x-32,yb-63,63,!p.dead&&p.water>0&&plantStage(p)>=2?1:0,now+q.x*37);
    if(p.pest&&!p.dead){ctx.fillStyle='#e02828';for(let n=0;n<6;n++)ctx.fillRect(q.x-6+((n*5+Math.floor(now/300))%12),yb-8-((n*7)%14),1,1);}}
}
function vcCursor(g,now){
  const b=Math.floor(now/300)%2;let x,y;
  if(VC.sel<0){x=g.focos[0]-24;y=g.fy-6;ctx.fillStyle='#26262e';ctx.fillRect(x-1,y-4,6,9);ctx.fillStyle='#f8f8f0';for(let k=0;k<4;k++)ctx.fillRect(x+b+k,y-3+k,1,7-2*k);return;}
  const q=g.pl.find(q=>q.i===VC.sel);if(!q)return;
  ctx.fillStyle='rgba(255,255,240,.35)';ctx.fillRect(q.x-9,q.y,18,2);
  x=q.x;y=q.y-(q.alto||14)-9+b;
  ctx.fillStyle='#26262e';ctx.fillRect(x-4,y-1,9,6);ctx.fillStyle='#f8f8f0';for(let k=0;k<4;k++)ctx.fillRect(x-3+k,y+k,7-2*k,1);
}
function vcInfo(){
  const el=$('vcInfo');if(!VC||VC.ocupado){el.hidden=true;return;}
  const c=S.carpas[VC.ci],L=[];
  if(VC.sel<0)L.push(esc(FOCOS[c.foco].n),plantasVivas(VC.ci)?'Luz '+eur(luzCarpa(VC.ci))+' al día':'Apagado');
  else{const i=VC.sel,p=S.pots[i];L.push(`Plaza ${huecos()[i].j+1} · ${MACETAS[S.macetas[i]].l} L`);
    if(!p)L.push('Vacía');
    else{L.push(esc(getStrain(p.sid).n));
      if(p.dead)L.push('Seca');else L.push(p.prog>=1?'Cosecha lista':stageName(p)+' '+Math.floor(p.prog*100)+' %','Agua '+Math.round(p.water)+' %','Salud '+Math.round(p.health)+' %');
      if(p.pest&&!p.dead)L.push('<em>PLAGA</em>');}}
  el.innerHTML=`<b>${esc(CARPAS[c.t].n)}</b>`+L.map(l=>`<div>${l}</div>`).join('');el.hidden=false;
}
function vcMover(b){
  const pl=vcGeo(VC.ci).pl,cur=pl.find(q=>q.i===VC.sel),cerca=(l,x)=>l.reduce((m,q)=>Math.abs(q.x-x)<Math.abs(m.x-x)?q:m);
  if(!cur){if(b==='down'){const fm=Math.max(...pl.map(q=>q.fila));VC.sel=cerca(pl.filter(q=>q.fila===fm),120).i;}return;}
  if(b==='left'||b==='right'){const f=pl.filter(q=>q.fila===cur.fila).sort((a,c)=>a.x-c.x),k=f.indexOf(cur)+(b==='left'?-1:1);if(k>=0&&k<f.length)VC.sel=f[k].i;}
  else if(b==='up'){const f=pl.filter(q=>q.fila===cur.fila+1);VC.sel=f.length?cerca(f,cur.x).i:-1;}
  else if(b==='down'){const f=pl.filter(q=>q.fila===cur.fila-1);if(f.length)VC.sel=cerca(f,cur.x).i;}
}
async function abrirCarpa(ci){
  sfx('door');await fade(1);
  const pl=vcGeo(ci).pl;VC={ci,sel:pl.length?pl[0].i:-1,ocupado:false};mode='carpa';updateHUD();vcInfo();
  await fade(0);
  if(!S.flags.vista){S.flags.vista=true;toast('◀ ▶ ▲ ▼ eliges planta o foco · A la cuidas · B sales',2800);}
  await new Promise(res=>push(b=>{
    if(VC.ocupado)return;
    if(b==='B'){pop();res();return;}
    if(b==='A'){VC.ocupado=true;vcInfo();(VC.sel<0?carpaAction(VC.ci):potAction(VC.sel)).then(()=>{VC.ocupado=false;vcInfo();});return;}
    if(DV[b]){const s=VC.sel;vcMover(b);if(s!==VC.sel){sfx('tick');vcInfo();}}
  }));
  VC.ocupado=true;vcInfo();await fade(1);mode='world';VC=null;updateHUD();await fade(0);
}
