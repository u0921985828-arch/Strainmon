/* =========================================================
   LA SALA DEL PISO (1.10): CLIMA, APARATOS, GOTEO Y ARCÓN
   ========================================================= */
/* ---------- clima ----------
   Una sala para todas las carpas: temperatura y humedad según el mes (un día de juego ≈ 4 semanas, así que 12 días son un año
   y el día 1 es abril), de día o de noche (isNight), el calor de los focos encendidos (de día, en las carpas con plantas: °C
   por vatio según el tipo; el sodio calienta mucho y el LED poco), la humedad que sudan las plantas y los extractores con
   filtro. Los aparatos (S.sala[k] = true) son termostatos: solo trabajan con alguna planta viva y solo hasta su objetivo.
   Fuera de T_OK / HR_OK las plantas crecen más despacio (fClima, en factores) y, con la humedad por encima de HR_OK en
   floración, les sale moho (plantStep: MOHO de salud por hora y punto de más; lo avisa avisoPlaga al despertar) */
const MESES=['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'],MES0=3;
const T_MES=[[18,15],[18,15],[19,17],[20,18],[21,19],[23,21],[26,23],[26,23],[24,21],[21,19],[19,18],[18,15]];   // °C en la sala, sin aparatos: [de día, de noche]
const HR_MES=[45,45,50,50,50,55,55,55,55,50,50,45];   // % de humedad relativa en la sala, de día y sin plantas
const CALOR_W={cfl:.008,sodio:.01,led:.004},MOHO=.1,HR_PLANTA=2,HR_NOCHE=5,HR_FILTRO=6,T_FILTRO=1,T_OK=[18,30],HR_OK=[40,60],H_DIA=15/24;
// t / hr: lo que sube (o baja) como mucho · obj: hasta dónde · w: lo que gasta mientras trabaja (la mitad del tiempo, H_24 horas al día)
const APARATOS={
  termo:{n:'Termohigrómetro',w:0,d:'Temperatura y humedad de la sala, de día y de noche: se ven en PLANTAS (START).'},
  calef:{n:'Calefactor',w:1500,t:6,obj:20,d:'Termostato: si la sala baja de 20 °C, la sube hasta 6 °C. Gasta 1.500 W mientras calienta.'},
  aire:{n:'Aire acondicionado portátil',w:900,t:-12,obj:26,d:'Termostato: si la sala pasa de 26 °C, la baja hasta 12 °C. Gasta 900 W mientras enfría.'},
  humi:{n:'Humidificador',w:30,hr:15,obj:45,d:'Si la humedad baja del 45 %, la sube hasta 15 puntos. Gasta 30 W.'},
  deshu:{n:'Deshumidificador',w:250,hr:-20,obj:55,d:'Si la humedad pasa del 55 %, la baja hasta 20 puntos: contra el moho en floración. Gasta 250 W.'}};
const mesDe=d=>(MES0+d-1)%12;
const fuera=(v,[a,b])=>v<a?a-v:v>b?v-b:0;
// el clima de la sala ahora (o de día / de noche): t (°C, al décimo), hr (%), uso (los aparatos que trabajan) y n (plantas vivas)
function climaSala(noche=isNight()){
  const m=mesDe(S.day),sa=S.sala||{};let n=0,calor=0,filtros=0;
  S.pots.forEach(p=>{if(p&&!p.dead)n++;});
  S.carpas.forEach((c,ci)=>{if(!c||!plantasVivas(ci))return;const F=FOCOS[c.foco];if(!noche)calor+=F.w*CALOR_W[F.tipo];if(c.filtro)filtros++;});
  let t=T_MES[m][noche?1:0]+calor-T_FILTRO*filtros,hr=HR_MES[m]+HR_PLANTA*n+(noche?HR_NOCHE:0)-HR_FILTRO*filtros-calor;
  const uso={};
  if(n)for(const k in APARATOS){const A=APARATOS[k];if(!sa[k]||!(A.t||A.hr))continue;
    if(A.t){if(A.t>0?t<A.obj:t>A.obj){t=A.t>0?Math.min(A.obj,t+A.t):Math.max(A.obj,t+A.t);uso[k]=1;}}
    else if(A.hr>0?hr<A.obj:hr>A.obj){hr=A.hr>0?Math.min(A.obj,hr+A.hr):Math.max(A.obj,hr+A.hr);uso[k]=1;}}
  return {t:Math.round(t*10)/10,hr:Math.round(hr),uso,n};
}
// lo que crece de más o de menos por el clima: −6 % por grado fuera de T_OK (hasta ×0,4) y −1,5 % por punto fuera de HR_OK (hasta ×0,7)
const fClima=cl=>clamp(1-.06*fuera(cl.t,T_OK),.4,1)*clamp(1-.015*fuera(cl.hr,HR_OK),.7,1);
// € al día de los aparatos que trabajan (de día H_DIA del tiempo, de noche el resto; un termostato, la mitad de ese tiempo)
function facturaSala(){
  const d=climaSala(false),n=climaSala(true);if(!d.n)return 0;
  let kwh=0;for(const k in APARATOS)if(d.uso[k]||n.uso[k])kwh+=APARATOS[k].w*H_24*(H_DIA*(d.uso[k]||0)+(1-H_DIA)*(n.uso[k]||0))*.5/1000;
  return Math.round(kwh*KWH);
}
const tClima=cl=>`${coma(cl.t)} °C · ${cl.hr} %`;
function salaDesc(){
  const d=climaSala(false),n=climaSala(true),ap=Object.keys(APARATOS).filter(k=>k!=='termo'&&S.sala[k]).map(k=>APARATOS[k].n);
  const mal=cl=>{const L=[];if(cl.t<T_OK[0])L.push('frío');if(cl.t>T_OK[1])L.push('calor');if(cl.hr<HR_OK[0])L.push('seco');if(cl.hr>HR_OK[1])L.push('húmedo');return L.length?' ('+L.join(', ')+')':'';};
  return `${MESES[mesDe(S.day)][0].toUpperCase()+MESES[mesDe(S.day)].slice(1)} · de día ${tClima(d)}${mal(d)} · de noche ${tClima(n)}${mal(n)}\nBien: ${T_OK[0]}-${T_OK[1]} °C y ${HR_OK[0]}-${HR_OK[1]} %. Aparatos: ${ap.length?ap.join(', '):'ninguno'}${facturaSala()?' · '+eur(facturaSala())+' al día':''}.`;
}
/* ---------- goteo ----------
   El depósito (S.carpas[ci].dep litros; sin el campo, lleno) riega solo: la planta que baja del 50 % de agua vuelve al 100 %
   gastando la mitad de los litros de su maceta por cada 100 % que sube. Si no llega, sube lo que dé y el depósito se vacía */
const GOTEO_L=100;
function regarGoteo(p,i){
  const c=S.carpas[huecos()[i].c];if(!c.goteo||p.dead||p.water>=50)return;
  const l=(MACETAS[S.macetas[i]]||MACETAS.plastico7).l*.5*(100-p.water)/100,d=c.dep??GOTEO_L;if(d<=0)return;
  if(d>=l){p.water=100;c.dep=Math.round((d-l)*100)/100;}else{p.water+=d/l*(100-p.water);c.dep=0;}
}
/* ---------- arcón y mochila ----------
   Lo que llevas encima (cogollos y rosin, en gramos) tiene el tope de la mochila (S.items.bolsa: la de serie, la bolsa de
   deporte o la maleta, del growshop). Lo que no cabe al cosechar va al arcón de casa (S.arcon), que no tiene tope: un control
   en la calle solo se lleva lo que llevas encima; una redada, todo lo del piso, arcón incluido (no la caja fuerte) */
const MOCHILAS=[{n:'Mochila',g:1000},{n:'Bolsa de deporte',g:3000},{n:'Maleta con ruedas',g:10000}];
// la mejor bolsa que tienes o que ya has pedido a Kiko (no se vende otra igual o peor)
const bolsaYa=()=>Math.max(S.items.bolsa||0,...S.envio.map(l=>(SHOP.find(x=>x.lbl===l)||{}).bolsa||0));
const pesoEncima=()=>totalBuds()+totalRosin(),capMochila=()=>MOCHILAS[S.items.bolsa||0].g,libreMochila=()=>Math.max(0,capMochila()-pesoEncima());
const arconG=()=>Object.values(S.arcon.buds).reduce((a,b)=>a+b.g,0),arconR=()=>Object.values(S.arcon.rosin).reduce((a,b)=>a+b.g,0);
const arconTxt=()=>arconR()>=.1?`${gTxt(arconG())} y ${rosinTxt(arconR())}`:gTxt(arconG());
async function arconAction(){
  for(;;){
    const ops=['Guardar todo','Guardar un lote','Sacar un lote','Cerrar'];
    const op=ops[await ask(`El arcón: ${arconTxt()}.\nEncima: ${gTxt(pesoEncima())} de ${kgTxt(capMochila())}.`,ops)];
    if(!op||op==='Cerrar')return;
    if(op==='Guardar todo'){
      const g=totalBuds(),r=totalRosin();
      if(g<.5&&r<.1){await say('No llevas nada que guardar.');continue;}
      for(const k of Object.keys(S.buds))moverLote(S.buds,S.arcon.buds,k,S.buds[k].g);
      for(const k of Object.keys(S.rosin))moverRosin(S.rosin,S.arcon.rosin,k,S.rosin[k].g);
      sfx('sel');await say(`Guardas ${r>=.1?`${gTxt(g)} y ${rosinTxt(r)}`:gTxt(g)} en el arcón.`);continue;
    }
    const mete=op==='Guardar un lote',B=mete?S.buds:S.arcon.buds,Ro=mete?S.rosin:S.arcon.rosin;
    const lots=Object.entries(B).map(l=>[l,0]).concat(Object.entries(Ro).map(l=>[l,1]));
    if(!lots.length){await say(mete?'No llevas nada encima.':'El arcón está vacío.');continue;}
    if(!mete&&libreMochila()<.1){await say('No te cabe nada más encima.');continue;}
    const i=await menu(lots.map(([l,r])=>r?rosinItem(l):lotItem(l)).concat([{label:'Nada'}]),{cls:'right',title:mete?'¿Qué guardas?':'¿Qué sacas?'});
    if(i<0||i>=lots.length)continue;
    const [[k,b],r]=lots[i],tope=mete?b.g:Math.min(b.g,libreMochila()),max=r?Math.floor(tope*10+1e-9)/10:Math.floor(tope);
    if(max<(r?.1:1)){await say('No te cabe encima.');continue;}
    const g=await cuanto(`${r?'Rosin · ':''}${lotNombre(k)}: ¿cuánto?`,max,r?[1,5,10,50]:[10,50,100,500,1000],r?q=>coma(q)+' g':gTxt);if(!g)continue;
    if(r)moverRosin(Ro,mete?S.arcon.rosin:S.rosin,k,g);else moverLote(B,mete?S.arcon.buds:S.buds,k,g);sfx('sel');
  }
}
