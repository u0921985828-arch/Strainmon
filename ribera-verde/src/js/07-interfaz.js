/* =========================================================
   UI: diálogos, menús, avisos
   ========================================================= */
const dlg=$('dlg'),dlgText=$('dlgText'),dlgName=$('dlgName'),dlgMore=$('dlgMore'),menuEl=$('menu');
function nm(t){return S?t.replace(/\{N\}/g,S.name):t;}
function typeText(text,name){return new Promise(res=>{
  dlg.hidden=false;dlgName.hidden=!name;dlgName.textContent=name||'';dlgMore.hidden=true;
  const full=nm(text);let i=0,done=false;dlgText.textContent='';
  const fin=()=>{clearInterval(iv);dlgText.textContent=full;done=true;pop();res();};
  const iv=setInterval(()=>{i+=1;dlgText.textContent=full.slice(0,i);if(i%3===0)sfx('blip');if(i>=full.length)fin();},20);
  push(b=>{if((b==='A'||b==='B')&&!done)fin();});
});}
async function say(text,name,keep){
  await typeText(text,name);dlgMore.hidden=false;
  await new Promise(res=>push(b=>{if(b==='A'||b==='B'){pop();res();}}));
  dlgMore.hidden=true;if(!keep)dlg.hidden=true;
}
async function talk(name,lines){for(const l of lines)await say(l,name);}
async function ask(text,opts,name){await typeText(text,name);const i=await menu(opts,{cls:'right',cancel:true});dlg.hidden=true;return i<0?opts.length-1:i;}
dlg.addEventListener('click',()=>press('A'));
function menu(items,o={}){return new Promise(res=>{
  items=items.map(it=>typeof it==='string'?{label:it}:it);
  let i=clamp(o.initial||0,0,items.length-1),top=0;const rows=o.rows||(o.cls==='full'?(o.desc?5:8):items.length);
  menuEl.className='box menu '+(o.cls||'right');
  const draw=()=>{
    if(i<top)top=i;if(i>=top+rows)top=i-rows+1;
    let h='';if(o.title)h+=`<div class="ttl"><span>${o.title}</span>${o.title2?`<span>${o.title2}</span>`:''}</div>`;
    if(o.cls==='full')h+=`<div class="arr">${top>0?'▲':''}</div><div class="list">`;
    items.slice(top,top+rows).forEach((it,k)=>{const idx=top+k;h+=`<div class="it ${idx===i?'sel':''} ${it.disabled?'dis':''}" data-i="${idx}"><span>${it.sw?`<i class="sw" style="background:${it.sw}"></i>`:''}${esc(it.label)}</span>${it.right!=null?`<span class="r">${esc(it.right)}</span>`:''}</div>`;});
    if(o.cls==='full')h+=`</div><div class="arr">${top+rows<items.length?'▼':''}</div>`;
    if(o.desc)h+=`<div class="desc">${esc(items[i].desc||'')}</div>`;
    menuEl.innerHTML=h;
  };
  draw();menuEl.hidden=false;
  const done=v=>{pop();menuEl.hidden=true;menuEl.onclick=null;res(v);};
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
function toast(html,ms=2400){const t=$('toast');t.innerHTML=html;t.hidden=false;clearTimeout(toastT);toastT=setTimeout(()=>t.hidden=true,ms);}
const fadeEl=$('fade');
async function fade(to,white){fadeEl.classList.toggle('white',!!white);fadeEl.style.opacity=to;await wait(240);}

