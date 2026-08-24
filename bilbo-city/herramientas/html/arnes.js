const {createCanvas}=require('canvas');const fs=require('fs');
const path=require('path');
const RUTA=process.env.BILBO_HTML||path.join(__dirname,'..','..','referencia','bilbo-city.html');
const html=fs.readFileSync(RUTA,'utf8');
let js=html.match(/<script>([\s\S]*)<\/script>/)[1];
const H={};const cache={};
function el(id){const o={id,style:{},dataset:{},className:'',textContent:'',value:'',children:[],
 classList:{add(){},remove(){},toggle(){}},addEventListener(n,f){if(id)H[id+':'+n]=f;},
 appendChild(){},querySelector:()=>el(),querySelectorAll:()=>[],clientWidth:840,clientHeight:400,
 getContext:()=>createCanvas(1,1).getContext('2d'),width:0,height:0,toDataURL:()=>'d',select(){}};return o;}
global.document={createElement:t=>{if(t==='canvas'){const c=createCanvas(1,1);c.style={};c.className='';
 c.classList={add(){},remove(){},toggle(){}};c.addEventListener=()=>{};c.appendChild=()=>{};
 c.querySelector=()=>el();c.querySelectorAll=()=>[];return c;}return el();},
 getElementById:i=>cache[i]||(cache[i]=el(i)),querySelectorAll:()=>[],addEventListener(){}};
// canvas principal real
// El juego es apaisado: el arnés tiene que serlo también o el mando no cae donde cae.
const real=createCanvas(840,400);
cache.c=Object.assign(real,{style:{},className:'',classList:{add(){},remove(){},toggle(){}},
 addEventListener:()=>{},appendChild:()=>{},querySelector:()=>el(),querySelectorAll:()=>[],
 clientWidth:840,clientHeight:400});
global.addEventListener=()=>{};global.devicePixelRatio=1;
let store={};global.localStorage={getItem:k=>store[k]??null,setItem:(k,v)=>store[k]=v,removeItem:k=>delete store[k]};
let now=0;global.performance={now:()=>now};
let raf=null;global.requestAnimationFrame=f=>{raf=f;};
global.location={reload(){}};global.innerWidth=840;global.innerHeight=400;global.window=global;
/* Se siembra el generador antes de arrancar para que dos pasadas de la batería den
   exactamente lo mismo. BILBO_SEMILLA cambia la semilla cuando quieras probar otra
   tirada — un fallo que solo sale con una semilla concreta sigue siendo un fallo. */
const SEMILLA=Number(process.env.BILBO_SEMILLA)||20250823;
const i=js.lastIndexOf('arrancar();');
js=js.slice(0,i)+`global.__={S,player,MISIONES,empezarMision,avanzarPaso,objetivo,cerrarDlg,enemigos,
 policia,coches,peatones,balas,estrellas,danarJugador,entrar,salir,atacarJugador,teclas,map,MW,MH,
 EDIF,ROAD,ACERA,AGUA,PARQUE,PLAZA,MUELLE,PATIO,PUENTE,POI,puntoAcera,puntoCalle,arma,HOJAS,hoja,
 real:cv,dib,BARRIOS,barrioDe,distDe,Tc,rodable,sembrar,azar,MONTE,SPR,HOJAS,ICO,CURROS,ARMAS,TILE,PROP,VEH,PALETA,ORDEN_POSES,ARQ,TILE_MUEBLE,hoja,
 INT,TILE_INT,solidoInt,PARADAS,PRENDAS,REDES,vestir,tiendaRopa,abrirRed,viajarA,nodos,estacion,
 paradaCerca,minutosViaje,comer,repostar,ACERA,PLAZA,salir,
 teVe,testigos,delito,ruido,ojos,alcanceVista,esDeNoche,porDetras,desprevenido,CONO,
 AGACHA,CORRE,lineaVista,dirAng,estrellas,atacarJugador,dir8De,generarEnemigos,danar};
 sembrar(SEMILLA);`+js.slice(i);
eval(js);
module.exports={H,step:n=>{for(let k=0;k<n;k++){now+=16.7;const f=raf;raf=null;if(!f)throw new Error('sin frame');f(now);}},
 raf:()=>raf,setNow:v=>now=v,store};
global.__H=H;
global.__step=n=>{for(let k=0;k<n;k++){now+=16.7;const f=raf;raf=null;if(!f)throw new Error('el bucle paro');f(now);}};
global.__now=()=>now;
global.__adv=ms=>{now+=ms;};
global.__store=()=>store;
