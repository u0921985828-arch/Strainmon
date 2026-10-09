/* =========================================================
   UI: diálogos, menús, avisos
   ========================================================= */
const dlg=$('dlg'),dlgText=$('dlgText'),dlgName=$('dlgName'),dlgMore=$('dlgMore'),menuEl=$('menu');
function nm(t){return S?t.replace(/\{N\}/g,S.name):t;}
function typeText(text,name){return new Promise(res=>{
  dlg.hidden=false;dlgName.hidden=!name;dlgName.textContent=name||'';dlgMore.hidden=true;
  const full=nm(text),paso=[1,3,1e5][AJ.texto];let i=0,n=0,done=false;dlgText.textContent='';   // OPCIONES · TEXTO: normal, rápido o al momento
  const fin=()=>{clearInterval(iv);dlgText.textContent=full;done=true;pop();res();};
  const iv=setInterval(()=>{i=Math.min(i+paso,full.length);dlgText.textContent=full.slice(0,i);if(++n%3===0)sfx('blip');if(i>=full.length)fin();},20);
  push(b=>{if((b==='A'||b==='B')&&!done)fin();});
});}
async function say(text,name,keep){
  await typeText(text,name);dlgMore.hidden=false;
  await new Promise(res=>push(b=>{if(b==='A'||b==='B'){pop();res();}}));
  dlgMore.hidden=true;if(!keep)dlg.hidden=true;
}
// los SMS (1.10) se quedan en el móvil: S.sms, del último al primero, hasta SMS_MAX
async function talk(name,lines){if(S&&S.sms&&/^SMS · /.test(name)){S.sms.unshift({d:S.day,n:name.slice(6),t:lines.map(nm).join('\n')});if(S.sms.length>SMS_MAX)S.sms.length=SMS_MAX;}for(const l of lines)await say(l,name);}
async function ask(text,opts,name){await typeText(text,name);const i=await menu(opts,{cls:'right',cancel:true});dlg.hidden=true;return i<0?opts.length-1:i;}
dlg.addEventListener('click',()=>press('A'));
function menu(items,o={}){return new Promise(res=>{
  items=items.map(it=>typeof it==='string'?{label:it}:it);
  let i=clamp(o.initial||0,0,items.length-1),top=0;const rows=o.rows||(o.cls==='full'?(o.desc?5:8):items.length);
  menuEl.className='box menu '+(o.cls||'right');
  // menú a toda altura: si la descripción ocupa más líneas, caben menos filas (vis) y la lista no se monta sobre ella
  const draw=(vis=rows)=>{
    if(i<top)top=i;if(i>=top+vis)top=i-vis+1;
    let h='';if(o.title)h+=`<div class="ttl"><span>${o.title}</span>${o.title2?`<span>${o.title2}</span>`:''}</div>`;
    if(o.cls==='full')h+=`<div class="arr">${top>0?'▲':''}</div><div class="list">`;
    items.slice(top,top+vis).forEach((it,k)=>{const idx=top+k;h+=`<div class="it ${idx===i?'sel':''} ${it.disabled?'dis':''}" data-i="${idx}"><span>${it.ic?`<i class="ic" style="background-image:url(${it.ic});width:${icPx(ICO_N[it.ic]||16)}px;height:${icPx(ICO_N[it.ic]||16)}px"></i>`:it.sw?`<i class="sw" style="background:${it.sw}"></i>`:''}${esc(it.label)}</span>${it.right!=null?`<span class="r">${esc(it.right)}</span>`:''}</div>`;});
    if(o.cls==='full')h+=`</div><div class="arr">${top+vis<items.length?'▼':''}</div>`;
    if(o.desc)h+=`<div class="desc">${esc(items[i].desc||'')}</div>`;
    menuEl.innerHTML=h;
    const l=o.cls==='full'&&!menuEl.hidden&&menuEl.querySelector('.list');if(l&&vis>1&&l.scrollHeight>l.clientHeight+1)draw(vis-1);
  };
  menuEl.hidden=false;draw();menuRedraw=()=>draw();
  const done=v=>{pop();menuRedraw=null;menuEl.hidden=true;menuEl.onclick=null;res(v);};
  menuEl.onclick=e=>{const it=e.target.closest('.it');if(!it)return;const n=+it.dataset.i;if(n===i)handler('A');else{i=n;draw();}};
  const handler=b=>{const g=o.cls==='battle';const n=items.length;
    if(b==='up'){i=g?(i>=2?i-2:i):(i-1+n)%n;sfx('tick');draw();}
    else if(b==='down'){i=g?(i+2<n?i+2:i):(i+1)%n;sfx('tick');draw();}
    else if(g&&b==='left'){if(i%2)i--;draw();}else if(g&&b==='right'){if(i%2===0&&i+1<n)i++;draw();}
    else if(b==='A'){if(items[i].disabled){sfx('bump');return;}sfx('sel');done(i);}
    else if(b==='B'&&o.cancel!==false){sfx('back');done(-1);}
    else if(b==='START'&&o.startCloses){done(-1);}};
  push(handler);
});}
let toastT=null;
function toast(html,ms=2400){const t=$('toast');t.innerHTML=html;t.hidden=false;clearTimeout(toastT);toastT=setTimeout(()=>t.hidden=true,ms);colocaToast(true);}
// el aviso, sin pisar la ficha de la carpa, el HUD ni SONIDO (como coloca_toast en Godot): de ancho, lo que quepa a la derecha de la ficha;
// si choca con el HUD, a su derecha si cabe y, si no, debajo; con un menú a pantalla completa, encima de él y abajo (sobre la descripción)
// el botón MÓVIL solo sirve andando por el mapa: en el título, la carpa o el combate no se ve (ni tapa la ficha de la carpa)
function verMovil(){const b=$('bMovil'),v=mode==='world'?'':'hidden';if(b&&b.style.visibility!==v)b.style.visibility=v;}
var toastFirma='';   // var: ajustarPantalla (06b) ya llama a colocaToast al cargar
function colocaToast(forzar){
  const t=$('toast');if(t.hidden){toastFirma='';return;}
  const mm=$('menu'),hh=$('hud'),f=[t.innerHTML,mm.hidden,mm.className,$('vcInfo').hidden,hh.hidden,hh.innerHTML,innerWidth,innerHeight].join('|');
  if(!forzar&&f===toastFirma)return;toastFirma=f;
  const ui=$('ui'),U=ui.getBoundingClientRect(),us=parseFloat($('consola').style.getPropertyValue('--us'))||1;
  const ve=e=>e&&!e.hidden&&getComputedStyle(e).visibility!=='hidden',B=e=>e.getBoundingClientRect(),choca=(R,x,y,w,h)=>x<R.right&&x+w>R.left&&y<R.bottom&&y+h>R.top;
  const vc=$('vcInfo'),m=$('menu'),full=ve(m)&&m.classList.contains('full'),hi=U.right;let lo=U.left;
  if(ve(vc))lo=Math.max(lo,B(vc).right+3*us);
  t.style.transform='none';t.style.maxWidth=Math.max(0,Math.min(210*us,hi-lo))+'px';   // .box es border-box: la caja entera, como en Godot
t.classList.toggle('sobre',full);
  const w=t.offsetWidth,h=t.offsetHeight;
  let x=clamp(U.left+U.width/2-w/2,lo,Math.max(lo,hi-w)),y=U.top+24*us;
  if(full)y=B(m).bottom-6*us-h;
  else{
    const hu=$('hud');
    if(ve(hu)){const H=B(hu);if(choca(H,x,y,w,h)){if(H.right+3*us+w<=hi)x=Math.max(x,H.right+3*us);else y=H.bottom+2*us;}}
    const so=B($('bSound'));if(choca(so,x,y,w,h))y=Math.max(y,so.bottom+2*us);
  }
  t.style.left=x-U.left+'px';t.style.top=y-U.top+'px';
}
const fadeEl=$('fade');
async function fade(to,white){fadeEl.classList.toggle('white',!!white);fadeEl.style.opacity=to;await wait(240);}

