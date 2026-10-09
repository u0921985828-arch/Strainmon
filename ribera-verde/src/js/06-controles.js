/* =========================================================
   INPUT
   ========================================================= */
const held={up:false,down:false,left:false,right:false,A:false,B:false};
const dirOrder=[];
const handlers=[];
const push=fn=>handlers.push(fn),pop=()=>handlers.pop();
function press(b){audioInit();if(handlers.length){handlers[handlers.length-1](b);return;}worldPress(b);}
function setHeld(b,v){if(b in held){held[b]=v;if(['up','down','left','right'].includes(b)){const i=dirOrder.indexOf(b);if(i>=0)dirOrder.splice(i,1);if(v)dirOrder.push(b);}}}
const KEYMAP={ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right',w:'up',s:'down',a:'left',d:'right',W:'up',S:'down',A:'left',D:'right',
  z:'A',Z:'A',' ':'A',Enter:'A',j:'A',x:'B',X:'B',Escape:'B',Backspace:'B',k:'B',Shift:'B',m:'START',M:'START',Tab:'START',p:'MOVIL',P:'MOVIL'};
document.addEventListener('keydown',e=>{
  if(document.activeElement===$('nameInput'))return;
  const b=KEYMAP[e.key];if(!b)return;e.preventDefault();
  setHeld(b,true);if(e.repeat&&!['up','down','left','right'].includes(b))return;press(b);});
document.addEventListener('keyup',e=>{const b=KEYMAP[e.key];if(b)setHeld(b,false);});
document.querySelectorAll('[data-b]').forEach(el=>{   // START
  const b=el.dataset.b;
  el.addEventListener('pointerdown',e=>{e.preventDefault();try{el.setPointerCapture(e.pointerId);}catch(_){}dedoEn(b,true,el);});
  ['pointerup','pointercancel','lostpointercapture'].forEach(ev=>el.addEventListener(ev,()=>dedoEn(b,false,el)));
  el.addEventListener('contextmenu',e=>e.preventDefault());
});
// un mando apretado con el dedo: las flechas se repiten (320 ms y luego cada 110) mientras haya algo abierto
function dedoEn(b,on,el){
  if(el)el.classList.toggle('on',on);setHeld(b,on);clearTimeout(dedoEn.rep[b]);clearInterval(dedoEn.rep2[b]);if(!on)return;press(b);
  if(['up','down','left','right'].includes(b))dedoEn.rep[b]=setTimeout(()=>{dedoEn.rep2[b]=setInterval(()=>{if(handlers.length)press(b);},110);},320);
}
dedoEn.rep={};dedoEn.rep2={};
// al perder el foco (otra app, otra pestaña, la pantalla apagada) puede no llegar el pointerup: se suelta todo, paran las
// repeticiones y la cruceta y A/B olvidan sus dedos (soltarMandos.f)
function soltarMandos(){
  for(const k in held)held[k]=false;dirOrder.length=0;
  for(const b in dedoEn.rep)clearTimeout(dedoEn.rep[b]);for(const b in dedoEn.rep2)clearInterval(dedoEn.rep2[b]);
  soltarMandos.f.forEach(f=>f());document.querySelectorAll('#mando .on').forEach(e=>e.classList.remove('on'));
}
soltarMandos.f=[];
addEventListener('blur',soltarMandos);addEventListener('pagehide',soltarMandos);
document.addEventListener('visibilitychange',()=>{if(document.hidden)soltarMandos();});
// cruceta: un dedo para las cuatro flechas. Manda la del ángulo desde el centro de la cruz (fuera de una zona muerta de 0,42 brazos)
// y, al deslizar sin levantar el dedo, pasa a la otra; la zona de toque (#dpad) es más grande que la cruz
(()=>{const el=$('dpad');if(!el)return;const cruz=el.querySelector('.cruz'),brazo={up:'.u',down:'.d',left:'.l',right:'.r'};let id=null,dir=null;
  const dirDe=e=>{const r=cruz.getBoundingClientRect(),x=e.clientX-(r.left+r.width/2),y=e.clientY-(r.top+r.height/2);
    if(Math.hypot(x,y)<r.width/3*.42)return dir;return Math.abs(x)>Math.abs(y)?(x<0?'left':'right'):(y<0?'up':'down');};
  const pon=d=>{if(d===dir)return;if(dir)dedoEn(dir,false,cruz.querySelector(brazo[dir]));dir=d;if(d)dedoEn(d,true,cruz.querySelector(brazo[d]));};
  soltarMandos.f.push(()=>{id=null;dir=null;});
  el.addEventListener('pointerdown',e=>{e.preventDefault();if(id!==null)return;id=e.pointerId;try{el.setPointerCapture(id);}catch(_){}pon(dirDe(e));});
  el.addEventListener('pointermove',e=>{if(e.pointerId===id)pon(dirDe(e));});
  ['pointerup','pointercancel','lostpointercapture'].forEach(ev=>el.addEventListener(ev,e=>{if(e.pointerId===id){id=null;pon(null);}}));
  el.addEventListener('contextmenu',e=>e.preventDefault());
})();
// A y B: la zona de toque (#ab) es más grande que los botones; cada dedo aprieta el más cercano hasta que se levanta
(()=>{const el=$('ab');if(!el)return;const bs=[...el.querySelectorAll('[data-k]')],dedos=new Map();
  const cerca=e=>{let m=null,dm=1e9;for(const b of bs){const r=b.getBoundingClientRect(),d=Math.hypot(e.clientX-r.left-r.width/2,e.clientY-r.top-r.height/2);if(d<dm){dm=d;m=b;}}return m;};
  soltarMandos.f.push(()=>dedos.clear());
  el.addEventListener('pointerdown',e=>{e.preventDefault();const b=cerca(e);dedos.set(e.pointerId,b);try{el.setPointerCapture(e.pointerId);}catch(_){}dedoEn(b.dataset.k,true,b);});
  ['pointerup','pointercancel','lostpointercapture'].forEach(ev=>el.addEventListener(ev,e=>{const b=dedos.get(e.pointerId);if(!b)return;dedos.delete(e.pointerId);
    if(![...dedos.values()].includes(b))dedoEn(b.dataset.k,false,b);}));
  el.addEventListener('contextmenu',e=>e.preventDefault());
})();
$('bSound').addEventListener('click',()=>{audioInit();setSound(!soundOn);});

