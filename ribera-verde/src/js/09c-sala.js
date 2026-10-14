/* =========================================================
   LA SALA DEL PISO (1.10): CLIMA, APARATOS, RIEGO AUTOMÁTICO Y ARCÓN
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
  S.carpas.forEach((c,ci)=>{if(!c||!plantasVivas(ci))return;const F=FOCOS[c.foco];if(!noche)calor+=F.w*CALOR_W[F.tipo];if(kitDe(c))filtros++;});
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
/* ---------- riego automático: garrafas y goteo ----------
   Dos niveles. Las garrafas (barato): una por maceta, de GARRAFA_X litros por litro de su tierra (media cosecha), en
   S.carpas[ci].gar[j] por plaza (sin el valor, llena). El goteo (una inversión): un depósito por carpa de GOTEO_X litros por
   litro de tierra que admite (litrosMax: unas cinco cosechas con la carpa llena), en S.carpas[ci].dep (sin el campo, lleno);
   si la carpa lo tiene, las garrafas no se usan. Los dos riegan igual: la planta que baja del 50 % de agua vuelve al 100 %
   gastando la mitad de los litros de su maceta por cada 100 % que sube. Si no llega, sube lo que dé y se vacía */
const GARRAFA_X=.65,GOTEO_X=6.5;   // una cosecha gasta ~1,3 L de agua por litro de tierra (1-1,7 según foco, maceta y variedad)
const goteoL=ci=>Math.round(GOTEO_X*litrosMax(ci));
const garrafaL=i=>Math.round(GARRAFA_X*(MACETAS[S.macetas[i]]||MACETAS.plastico7).l);
const garrafa=i=>{const h=huecos()[i],c=S.carpas[h.c],cap=garrafaL(i);return Math.min(cap,(c.gar||[])[h.j]??cap);};
// litros que quedan y que caben en las garrafas de la carpa (una por plaza)
const garrafasCarpa=ci=>huecos().reduce((a,h,i)=>h.c===ci?[a[0]+garrafa(i),a[1]+garrafaL(i)]:a,[0,0]);
function regarGoteo(p,i){
  const h=huecos()[i],c=S.carpas[h.c];if(!(c.goteo||c.garrafas)||p.dead||p.water>=50)return;
  const l=(MACETAS[S.macetas[i]]||MACETAS.plastico7).l*.5*(100-p.water)/100,d=c.goteo?c.dep??goteoL(h.c):garrafa(i);if(d<=0)return;
  let q=0;if(d>=l){p.water=100;q=Math.round((d-l)*100)/100;}else p.water+=d/l*(100-p.water);
  if(c.goteo)c.dep=q;else(c.gar||(c.gar=[]))[h.j]=q;
}
/* ---------- la mochila ----------
   Lo que llevas encima (cogollos y extractos, en gramos) tiene el tope de la mochila (S.items.bolsa: la de serie, la bolsa de
   deporte o la maleta, del growshop). Lo que no cabe al cosechar va a la caja fuerte (1.36: sin el arcón de la 1.10); un control
   en la calle solo se lleva lo que llevas encima; una redada, todo lo del piso, la nevera incluida (no la caja fuerte) */
const MOCHILAS=[{n:'Mochila',g:1000},{n:'Bolsa de deporte',g:3000},{n:'Maleta con ruedas',g:10000}];
// la mejor bolsa que tienes o que ya has pedido a Kiko (no se vende otra igual o peor)
const bolsaYa=()=>Math.max(S.items.bolsa||0,...S.envio.map(l=>(SHOP.find(x=>x.lbl===l)||{}).bolsa||0));
const pesoEncima=()=>totalBuds()+totalRosin(),capMochila=()=>MOCHILAS[S.items.bolsa||0].g,libreMochila=()=>Math.max(0,capMochila()-pesoEncima());
/* ---------- el curado (1.29) ----------
   Cada lote de cogollos lleva el día de la cosecha (b.dia) y lo curado (b.cu, de 0 a 1; sin él, nada). Con los tarros de Kiko
   (S.items.tarros), en la caja fuerte (1.36: sin arcón) se cura 1/CURADO.dias al día; curado se vende CURADO.precio más caro
   (calidad) y, desde la 1.36 (lo pidió el usuario), el THC sube CURADO.thc (1 %: el cogollo pierde algo de agua y el % por peso sube; no se crea THC), repartido por lo que se cura; sin curar ya no pierde THC; los extractos se curan en frío en la
   nevera (S.nevera.rosin), también en los tarros, y el manicurado (la mesa de las tijeras, junto a la de genética) pela los cogollos: b.mc, de 0
   a 1, MANICURA.precio más caro. Al juntar dos lotes, el THC, lo curado, lo manicurado y el día van por gramos */
const CURADO={dias:2,precio:.15,thc:.01};   // thc (1.36): curado del todo, un 1 % más de THC por el agua que pierde (no se crea THC)
const MANICURA={precio:.1,min:.5,max:240};   // por gramo, medio minuto de tijera; la tanda, como mucho 4 h
const calidad=b=>1+CURADO.precio*(b.cu||0)+MANICURA.precio*(b.mc||0);
const curaDe=b=>Object.assign({},b.dia!=null?{dia:b.dia}:{},b.cu?{cu:b.cu}:{},b.mc?{mc:b.mc}:{});
function juntaLote(t,g,thc,cu,dia,mc){
  const n=t.g+g,c=((t.cu||0)*t.g+(cu||0)*g)/n,m=((t.mc||0)*t.g+(mc||0)*g)/n;t.thc=(t.thc*t.g+thc*g)/n;
  if(c)t.cu=c;else delete t.cu;if(m)t.mc=m;else delete t.mc;if(dia!=null)t.dia=Math.round(((t.dia??dia)*t.g+dia*g)/n);t.g=n;
}
const nevera=()=>S.nevera||(S.nevera={rosin:{}}),neveraR=()=>S.nevera?Object.values(S.nevera.rosin).reduce((a,b)=>a+b.g,0):0;
const extrNombre=(k,min)=>(min?EXTR[tipoExtr(k)].n.toLowerCase():EXTR[tipoExtr(k)].n)+' de '+lotNombre(baseExtr(k));   // min: «rosin de Skunk #1», en medio de una frase
// al amanecer (newDay): lo que se cura; av, los avisos del día
function curadoDia(av){
  const cura=L=>{const o=[];for(const [k,b] of Object.entries(L))if((b.cu||0)<1){const c0=b.cu||0;b.cu=Math.min(1,c0+1/CURADO.dias);b.thc=b.thc*(1+CURADO.thc*(b.cu-c0));if(b.cu>=1)o.push(k);}return o;};
  const c=S.items.tarros&&S.caja?cura(S.caja.buds):[],n=S.items.tarros&&S.nevera?cura(S.nevera.rosin):[];   // 1.36: los dos, con los tarros
  if(c.length)av.push('Curada en la caja fuerte: '+yLista(c.map(lotNombre)));
  if(n.length)av.push('Curado en la nevera: '+yLista(n.map(extrNombre)));
}
// cómo está un lote, para la mochila: curado, curándose o sin curar ('' en los de antes de la 1.29), y manicurado
const manTxt=b=>b.mc>=1?` Manicurada: un ${pct0(MANICURA.precio)} % más cara.`:b.mc?' Manicurada en parte.':'';
const curaTxt=b=>((b.cu>=1?`Curada: un ${pct0(CURADO.thc)} % más de THC y se vende un ${pct0(CURADO.precio)} % más cara.`:b.cu?`Curándose (${pct0(b.cu)} %): termina de curarla con los tarros, en la caja fuerte.`
  :b.dia==null?'':`Sin curar: con tarros, en la caja fuerte, se cura en ${CURADO.dias} días: sube un ${pct0(CURADO.thc)} % de THC y se vende un ${pct0(CURADO.precio)} % más cara.`)+manTxt(b)).trim();
const curaCorto=b=>(b.cu>=1?' · curada':b.cu?' · curándose':b.dia!=null?' · sin curar':'')+(b.mc>=1?' · manicurada':'');
