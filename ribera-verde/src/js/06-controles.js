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
  z:'A',Z:'A',' ':'A',Enter:'A',j:'A',x:'B',X:'B',Escape:'B',Backspace:'B',k:'B',Shift:'B',m:'START',M:'START',Tab:'START'};
document.addEventListener('keydown',e=>{
  if(document.activeElement===$('nameInput'))return;
  const b=KEYMAP[e.key];if(!b)return;e.preventDefault();
  setHeld(b,true);if(e.repeat&&!['up','down','left','right'].includes(b))return;press(b);});
document.addEventListener('keyup',e=>{const b=KEYMAP[e.key];if(b)setHeld(b,false);});
window.addEventListener('blur',()=>{for(const k in held)held[k]=false;dirOrder.length=0;});
document.querySelectorAll('[data-b]').forEach(el=>{
  const b=el.dataset.b;let rep=null,rep2=null;
  const stop=()=>{setHeld(b,false);clearTimeout(rep);clearInterval(rep2);el.classList.remove('on');};
  el.addEventListener('pointerdown',e=>{e.preventDefault();try{el.setPointerCapture(e.pointerId);}catch(_){}el.classList.add('on');setHeld(b,true);press(b);
    if(['up','down','left','right'].includes(b)){rep=setTimeout(()=>{rep2=setInterval(()=>{if(handlers.length)press(b);},110);},320);}});
  ['pointerup','pointercancel','lostpointercapture'].forEach(ev=>el.addEventListener(ev,stop));
  el.addEventListener('contextmenu',e=>e.preventDefault());
});
$('bSound').addEventListener('click',()=>{audioInit();setSound(!soundOn);});

