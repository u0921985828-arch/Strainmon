const {createCanvas}=require('canvas');const fs=require('fs');
const [LIENZO_W,LIENZO_H]=(process.env.BILBO_LIENZO||'840x400').split('x').map(Number);
const path=require('path');
const RUTA=process.env.BILBO_HTML||path.join(__dirname,'..','..','referencia','bilbo-city.html');
const html=fs.readFileSync(RUTA,'utf8');
let js=html.match(/<script>([\s\S]*)<\/script>/)[1];
const H={};const cache={};
/* appendChild era un hueco vacío, así que ningún panel del juego contaba nunca sus filas
   y una pestaña que no pintara nada habría pasado por buena. Ahora los hijos se guardan
   de verdad, e `innerHTML=''` los tira, que es como los vacía el juego. */
function el(id){const o={id,style:{},dataset:{},className:'',textContent:'',value:'',
 classList:{add(){},remove(){},toggle(){}},addEventListener(n,f){if(id)H[id+':'+n]=f;},
 appendChild(h){o.children.push(h);},querySelector:()=>el(),querySelectorAll:()=>[],
/* El lienzo, configurable con BILBO_LIENZO=anchoxalto. Hace falta para juzgar el campo de
   visión: la cámara enseña 13,5 casillas de alto y el zoom es entero, así que con la
   casilla a 64 px una pantalla de 400 enseña la mitad de ciudad que una de 800. Comparar
   dos resoluciones de casilla en el mismo lienzo compara dos cosas distintas. */
 clientWidth:LIENZO_W,clientHeight:LIENZO_H,
 getContext:()=>createCanvas(1,1).getContext('2d'),width:0,height:0,toDataURL:()=>'d',select(){}};
 let hijos=[],html='';
 Object.defineProperty(o,'children',{get:()=>hijos});
 Object.defineProperty(o,'innerHTML',{get:()=>html,set(v){html=v;if(v==='')hijos=[];}});
 return o;}
global.document={createElement:t=>{if(t==='canvas'){const c=createCanvas(1,1);c.style={};c.className='';
 c.classList={add(){},remove(){},toggle(){}};c.addEventListener=()=>{};c.appendChild=()=>{};
 c.querySelector=()=>el();c.querySelectorAll=()=>[];return c;}return el();},
 getElementById:i=>cache[i]||(cache[i]=el(i)),querySelectorAll:()=>[],addEventListener(){},
 /* El juego escribe variables CSS en la raíz para el tamaño del mando. Sin esto el
    arranque revienta en el arnés y no en el navegador, que es la peor combinación. */
 documentElement:{style:{setProperty(){},getPropertyValue:()=>''}},
 body:el('body')};
// canvas principal real
// El juego es apaisado: el arnés tiene que serlo también o el mando no cae donde cae.
const real=createCanvas(LIENZO_W,LIENZO_H);
cache.c=Object.assign(real,{style:{},className:'',classList:{add(){},remove(){},toggle(){}},
 addEventListener:()=>{},appendChild:()=>{},querySelector:()=>el(),querySelectorAll:()=>[],
 clientWidth:LIENZO_W,clientHeight:LIENZO_H});
global.addEventListener=()=>{};global.devicePixelRatio=1;
let store={};global.localStorage={getItem:k=>store[k]??null,setItem:(k,v)=>store[k]=v,removeItem:k=>delete store[k]};
let now=0;global.performance={now:()=>now};
let raf=null;global.requestAnimationFrame=f=>{raf=f;};
global.location={reload(){}};global.innerWidth=LIENZO_W;global.innerHeight=LIENZO_H;global.window=global;
/* Se siembra el generador antes de arrancar para que dos pasadas de la batería den
   exactamente lo mismo. BILBO_SEMILLA cambia la semilla cuando quieras probar otra
   tirada — un fallo que solo sale con una semilla concreta sigue siendo un fallo. */
const SEMILLA=Number(process.env.BILBO_SEMILLA)||20250823;
const i=js.lastIndexOf('arrancar();');
js=js.slice(0,i)+`global.__={S,player,MISIONES,empezarMision,avanzarPaso,objetivo,cerrarDlg,enemigos,
 policia,coches,peatones,balas,estrellas,danarJugador,entrar,salir,atacarJugador,teclas,map,MW,MH,
 EDIF,ROAD,ACERA,AGUA,PARQUE,PLAZA,MUELLE,PATIO,PUENTE,POI,puntoAcera,puntoCalle,arma,HOJAS,hoja,
 real:cv,dib,MOB,colocarCalle,BARRIOS,barrioDe,distDe,Tc,rodable,sembrar,azar,MONTE,SPR,HOJAS,ICO,CURROS,ARMAS,TILE,PROP,VEH,PALETA,ORDEN_POSES,ARQ,hoja,SUELO_I,PARED_I,PUERTA_I,PASO_I,MUEBLES,sprMueble,piezasDe,TS_INT,M_INT,BLANDO_I,UNITARIO_I,
 INT,solidoInt,PARADAS,PRENDAS,REDES,vestir,tiendaRopa,abrirRed,viajarA,nodos,estacion,
 paradaCerca,minutosViaje,comer,repostar,ACERA,PLAZA,salir,
 teVe,testigos,delito,ruido,ojos,alcanceVista,esDeNoche,porDetras,desprevenido,CONO,
 AGACHA,CORRE,lineaVista,dirAng,estrellas,atacarJugador,dir8De,generarEnemigos,danar,
 XP_NIVEL,darXp,PROPIEDADES,propDe,esMio,pegaPara,comprarProp,rentaDiaria,cobrarRentas,
 estadoCasera,deudaTotal,correrAlquiler,pagarCasera,dejarPiso,ocupar,dormir,
 NIVEL_ARMA,NIVEL_VEHICULO,comer,verTab,telC,roof,famDe,familiaTejado,TEJADO_DE,PROP,SINGULARES,PLANO_SINGULAR,TS,CALLES,calleEn,calleDe,LARGO_CALLE,nombrarCalles,
 BASES,cargarSprites,setDe,lutDe,hojaDeSet,TORSOS,PIERNAS,CALZADO,C,COMPLEX,ARMA_MANO,FOG,contorno,sc,ANCHO_FACH,REVOCO,PISO_BARRIO,poseAndar,MS,ZANCADA,
 poi,pasoActual,npcCerca,empezarPrologo,PROLOGO,PRIMO};
 sembrar(SEMILLA);`+js.slice(i);
eval(js);
module.exports={H,step:n=>{for(let k=0;k<n;k++){now+=16.7;const f=raf;raf=null;if(!f)throw new Error('sin frame');f(now);}},
 raf:()=>raf,setNow:v=>now=v,store};
global.__H=H;
global.__step=n=>{for(let k=0;k<n;k++){now+=16.7;const f=raf;raf=null;if(!f)throw new Error('el bucle paro');f(now);}};
global.__now=()=>now;
global.__adv=ms=>{now+=ms;};
global.__store=()=>store;
