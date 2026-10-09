/* =========================================================
   AUDIO — chiptune propio
   ========================================================= */
let AC=null,master=null,musG=null,musF=null,sfxG=null,soundOn=true,tune=null,seqT=0,seqStep=0,seqIv=null,noiseBuf=null;
function audioInit(){
  if(AC)return;try{AC=new (window.AudioContext||window.webkitAudioContext)();master=AC.createGain();master.gain.value=soundOn?.16:0;master.connect(AC.destination);
  musG=AC.createGain();sfxG=AC.createGain();musG.connect(master);sfxG.connect(master);ajustesSonido();
  noiseBuf=AC.createBuffer(1,AC.sampleRate*.3,AC.sampleRate);const d=noiseBuf.getChannelData(0);for(let i=0;i<d.length;i++)d[i]=Math.random()*2-1;}catch(e){AC=null;}
  if(AC&&!seqIv)seqIv=setInterval(schedule,60);
}
function tone(f,t,dur,type='square',vol=.25,f2,out=sfxG){if(!AC)return;const o=AC.createOscillator(),g=AC.createGain();o.type=type;o.frequency.setValueAtTime(f,t);if(f2)o.frequency.exponentialRampToValueAtTime(f2,t+dur);
  g.gain.setValueAtTime(vol,t);g.gain.exponentialRampToValueAtTime(.001,t+dur);o.connect(g);g.connect(out);o.start(t);o.stop(t+dur+.02);}
function noise(t,dur,vol=.3,out=sfxG){if(!AC)return;const s=AC.createBufferSource(),g=AC.createGain();s.buffer=noiseBuf;g.gain.setValueAtTime(vol,t);g.gain.exponentialRampToValueAtTime(.001,t+dur);s.connect(g);g.connect(out);s.start(t);s.stop(t+dur);}
const mf=n=>440*Math.pow(2,(n-69)/12);
function sfx(k){if(!AC||!soundOn)return;const t=AC.currentTime+.005;
  switch(k){
    case 'blip':tone(1200,t,.025,'square',.06);break;
    case 'tick':tone(900,t,.03,'square',.08);break;
    case 'sel':tone(880,t,.05,'square',.12);tone(1320,t+.05,.07,'square',.12);break;
    case 'back':tone(660,t,.05,'square',.1);tone(440,t+.05,.07,'square',.1);break;
    case 'bump':tone(110,t,.08,'triangle',.3);break;
    case 'door':noise(t,.18,.15);tone(300,t,.15,'triangle',.2,120);break;
    case 'coin':tone(988,t,.07,'square',.14);tone(1319,t+.07,.18,'square',.14);break;
    case 'get':[72,76,79,84].forEach((n,i)=>tone(mf(n),t+i*.09,.12,'square',.13));tone(mf(88),t+.38,.3,'square',.13);break;
    case 'hit':noise(t,.15,.4);tone(200,t,.12,'square',.2,60);break;
    case 'hurt':tone(400,t,.25,'sawtooth',.18,90);noise(t,.1,.2);break;
    case 'enc':for(let i=0;i<8;i++)tone(mf(60+i*3),t+i*.045,.05,'square',.12);break;
    case 'bad':tone(220,t,.18,'square',.15);tone(160,t+.18,.35,'square',.15);break;
  }}
// Las canciones se escriben en notas («c5», «f#4», «bb5»; «.» silencio, «-» alarga la anterior un paso), acordes por compás
// (cs pasos cada uno: bajo con el patrón bp —R raíz, 5 quinta, 8 octava, 3 tercera— y arpegio ap con los índices del acorde) y
// batería (k bombo, s caja, h charles). tema() las convierte en pasos: mel/md (nota y largo en pasos), arm, bas y bat (1 k, 2 s,
// 3 h), con la onda y el volumen de cada voz (mo/ao/bo). Godot recibe TUNES ya convertido (tools/godot.js).
const VOLW={square:.07,pulse25:.07,pulse12:.06,triangle:.12,sawtooth:.05},PC={c:0,d:2,e:4,f:5,g:7,a:9,b:11},
  ACORDE={'':[0,4,7],m:[0,3,7],'7':[0,4,7,10],maj7:[0,4,7,11],m7:[0,3,7,10]},BATERIA={k:1,s:2,h:3},
  toks=s=>s.split(/\s+/).filter(x=>x&&x!=='|'),alt=x=>x==='#'?1:x==='b'?-1:0;
function midi(s){const m=/^([a-g])([#b]?)(\d)$/.exec(s);if(!m)throw Error('nota '+s);return 12*(+m[3]+1)+PC[m[1]]+alt(m[2]);}
function tema(d){const T={bpm:d.bpm,mo:d.mo||'square',ao:d.ao||'square',bo:d.bo||'triangle'};T.mv=VOLW[T.mo];T.av=VOLW[T.ao]*.6*(d.af||1);T.bv=T.bo==='triangle'?.16:.07;
  let mel=[],md=[],u=-1;
  if(Array.isArray(d.mel)){mel=d.mel.slice();md=mel.map(n=>n?1:0);}
  else for(const t of toks(d.mel)){if(t==='-'){mel.push(0);md.push(0);if(u>=0)md[u]++;continue;}const n=t==='.'?0:midi(t);u=n?mel.length:-1;mel.push(n);md.push(n?1:0);}
  const L=mel.length,arm=Array(L).fill(0),bas=d.bas?d.bas.slice():Array(L).fill(0);
  if(d.ch){const cs=d.cs||4,ch=toks(d.ch),bp=toks(d.bp||'R . 5 .'),ap=d.ap?toks(d.ap):null;
    if(ch.length*cs!==L)throw Error(`acordes ${ch.length}×${cs} ≠ ${L} pasos`);
    ch.forEach((c,j)=>{const m=/^([A-G])([#b]?)(maj7|m7|m|7)?$/.exec(c);if(!m)throw Error('acorde '+c);
      const pc=(PC[m[1].toLowerCase()]+alt(m[2])+12)%12,iv=ACORDE[m[3]||''],r=pc<=7?48+pc:36+pc;
      for(let k=0;k<cs;k++){const i=j*cs+k,b=bp[k%bp.length],a=ap?ap[k%ap.length]:'.';
        if(b!=='.'){if(!(b in {R:1,5:1,8:1,3:1}))throw Error('bajo '+b);bas[i]=r+({R:0,5:7,8:12,3:iv[1]})[b];}
        if(a!=='.'){const x=+a;if(!(x>=0))throw Error('arpegio '+a);arm[i]=60+pc+iv[x%iv.length]+12*Math.floor(x/iv.length);}}});}
  const bt=d.bat?toks(d.bat):null;if(bt&&bt.some(x=>x!=='.'&&!BATERIA[x]))throw Error('batería '+d.bat);
  if(bas.length!==L)throw Error('bajo ≠ melodía');
  return Object.assign(T,{mel,md,arm,bas,bat:mel.map((_,i)=>bt&&BATERIA[bt[i%bt.length]]||0)});}
// de noche, la misma canción más lenta, con flauta (triangular), el arpegio más suave y sin bombo ni caja
const nocturno=d=>({...d,bpm:Math.round(d.bpm*.8),mo:'triangle',ao:'pulse12',af:.7,bat:d.bat&&toks(d.bat).map(x=>x==='h'?'h':'.').join(' ')});
const TOWN_A='c5 . e5 g5 f5 e5 d5 . | c5 d5 e5 c5 a4 . g4 . | c5 . e5 g5 a5 g5 f5 e5 | d5 e5 f5 d5 c5 - . .',
  TOWN_B='f5 . a5 c6 - . b5 a5 | g5 . e5 . a5 - . . | f5 e5 d5 . f5 . g5 a5 | g5 - e5 . d5 . . .';
const CANCIONES={
  // Ribera (centro): la de siempre con una segunda parte, A B A
  town:{bpm:132,mel:[TOWN_A,TOWN_B,TOWN_A].join(' '),ch:'C C C Am C F G C  F G Em Am Dm G C G  C C C Am C F G C',bat:'k . h . s . h . k . h k s . h h'},
  night:{bpm:100,mel:[69,0,72,0,76,0,74,72,71,0,67,0,69,0,0,0,69,0,72,0,77,0,76,74,72,0,71,0,69,0,0,0],
        bas:[45,0,0,0,52,0,0,0,43,0,0,0,50,0,0,0,41,0,0,0,48,0,0,0,40,0,0,0,45,0,0,0]},
  home:{bpm:96,mel:[76,0,79,0,81,0,79,76,74,0,72,0,74,76,0,0,76,0,79,0,84,0,83,81,79,0,76,0,74,0,0,0],
        bas:[48,0,0,0,52,0,0,0,53,0,0,0,55,0,0,0,48,0,0,0,52,0,0,0,50,0,0,0,55,0,0,0]},
  battle:{bpm:168,mel:[69,72,76,72,69,72,76,79,77,76,74,72,71,72,74,71,69,72,76,72,69,72,76,81,79,77,76,74,76,0,75,0],
        bas:[45,45,57,45,45,57,45,45,41,41,53,41,43,43,55,43,45,45,57,45,45,57,45,45,41,41,53,41,40,40,52,40],bat:'k h s h k k s h'},
  title:{bpm:120,mel:[76,0,79,0,84,0,83,0,81,0,79,0,76,0,72,0,74,0,77,0,81,0,79,77,76,0,0,0,79,0,0,0],
        bas:[48,0,55,0,48,0,55,0,45,0,52,0,45,0,52,0,50,0,57,0,50,0,57,0,43,0,50,0,43,0,47,0]},
  // barrio alto: lounge en fa, acordes de séptima
  alto:{bpm:108,mo:'pulse25',ao:'pulse12',ap:'0 1 2 3',
    ch:'F F Gm7 C7 Am7 Dm7 Gm7 C7 F F Bbmaj7 Bbmaj7 Am7 D7 Gm7 C7',
    mel:'c6 - a5 - e5 - f5 . | bb5 - a5 g5 e5 - c5 . | a5 - g5 - f5 - d5 . | g5 - - a5 bb5 - g5 . | a5 - c6 - f6 - e6 . | d6 - - c6 a5 - bb5 . | c6 - a5 - f#5 - a5 . | g5 - f5 - e5 - c5 .',bat:'k . h . s . h h'},
  // astilleros: industrial en mi menor, bajo de sierra
  astilleros:{bpm:124,bo:'sawtooth',bp:'R . 8 R',ch:'Em Em Em Em C C D D Em Em Em Em C D B B',
    mel:'e5 . e5 g5 . e5 d5 . | e5 . b4 . d5 - e5 . | c5 . c5 e5 . c5 b4 . | d5 . a4 . d5 - f#5 . | g5 . g5 f#5 e5 . d5 . | e5 - b4 . e5 . g5 . | a5 - g5 . f#5 - d5 . | d#5 - f#5 - b5 - . .',bat:'k . h k s . h . k k h . s . h s'},
  // Puerto Viejo: vals marinero en re
  puerto:{bpm:150,cs:6,mo:'pulse25',ao:'pulse12',bp:'R . . . 5 .',ap:'. . 1 . 2 .',ch:'D D G D A A D D D D G G D A D D',
    mel:'f#5 - - e5 d5 . | a5 - - - f#5 . | g5 - b5 - g5 . | f#5 - - d5 - . | e5 - - c#5 - e5 | a5 - g5 - e5 . | d5 - f#5 - a5 . | d6 - - - - . | a5 - - f#5 - a5 | d6 - - a5 - . | b5 - - g5 - b5 | d6 - b5 - g5 . | a5 - - f#5 - d5 | e5 - - a4 - c#5 | d5 - - - - . | . . . a4 - -',bat:'k . h . h .'},
  // Valdehierro: la menor dórico, ciudad de mina
  valdehierro:{bpm:116,bp:'R . 8 5',ch:'Am Am D D Am Am D D C C G G Am Am E E',
    mel:'. a4 c5 d5 e5 . c5 . | f#5 - e5 d5 . a4 . . | . a4 c5 d5 e5 . g5 - | f#5 - d5 . e5 - . . | g5 . g5 e5 c5 . e5 . | d5 . b4 . d5 . g5 - | e5 - c5 . a4 . c5 . | b4 - g#4 . b4 . e5 .',bat:'k . h . s . h k . k h . s . h h'},
  // Mendialde: 6/8 de caserío, flauta y arpegio
  mendialde:{bpm:168,cs:6,mo:'triangle',ao:'pulse12',bp:'R . . 5 . .',ap:'. 1 2 . 1 2',ch:'G G C G D D G G Em Em C G D D G G',
    mel:'d6 - b5 g5 - b5 | d6 - - g6 - . | e6 - c6 e6 - g6 | d6 - b5 g5 - . | a5 - f#5 a5 - d6 | c6 - a5 f#5 - a5 | b5 - g5 d6 - b5 | g5 - - - - . | e6 - b5 e6 - g6 | f#6 - e6 b5 - . | c6 - e6 g6 - e6 | d6 - b5 g5 - b5 | a5 - b5 c6 - a5 | f#5 - a5 d6 - c6 | b5 - a5 g5 - f#5 | g5 - - - . .',bat:'k . h s . h'},
  // Errotabarri: pastoral lenta en fa
  errotabarri:{bpm:92,mo:'pulse25',ao:'triangle',ap:'0 1 2 1',bp:'R . 5 .',ch:'F F C C Dm Dm Bb C F F Am Am Bb C F F',
    mel:'c5 - f5 - a5 - - g5 | g5 - e5 - c5 - . . | d5 - f5 - a5 - g5 f5 | f5 - d5 - e5 - - . | a5 - c6 - a5 - f5 - | e5 - a5 - c6 - b5 a5 | d6 - bb5 - g5 - e5 . | f5 - - - . . . .',bat:'. . h . . . h .'},
  // interiores: la tienda (reggae), el bar (tango) y la comisaría (tensa)
  shop:{bpm:150,ap:'. . 1 .',ao:'pulse12',ch:'G G C C G G D D G G C C Em Em D D',
    mel:'. . b4 d5 . . g5 . | e5 - - . c5 . e5 . | d5 . b4 . g4 - - . | . . a4 c5 d5 - . . | . . b5 . a5 . g5 . | e5 - g5 - e5 . c5 . | b4 - - e5 g5 - . . | f#5 - - d5 - . . .',bat:'. h . h s h . h'},
  bar:{bpm:120,bp:'R . . 5',ap:'0 . 1 .',ch:'Dm Dm A A Dm Dm Gm A Dm Dm Gm Gm Dm A A A',
    mel:'d5 . . d5 f5 . a5 . | e5 - - c#5 a4 . . . | d5 . . f5 a5 . d6 . | bb5 - a5 . g5 . e5 . | f5 . . a5 d6 - c6 . | bb5 . . g5 d5 - . . | f5 - e5 d5 c#5 - e5 . | a4 - - - . . . .',bat:'k . . h s . h .'},
  comisaria:{bpm:96,bp:'R . R .',ch:'Em Em Em Em C C B B Em Em Em Em C C B B',
    mel:'b4 - - - . . . . | c5 - b4 - . . g4 . | e5 - - - . . . . | d#5 - - - f#5 - . . | b5 - - - a5 - g5 - | f#5 - - - e5 - . . | e5 - g5 - c6 - - . | b5 - - - . . . .',bat:'h . . . h . . .'},
};
// las zonas de la calle llevan su canción de día y otra de noche (k_n); Ribera, la de siempre (night)
const ZONA_MUSICA=Object.keys(ZONAS).filter(k=>k!=='town');
for(const k of ZONA_MUSICA)CANCIONES[k+'_n']=nocturno(CANCIONES[k]);
const TUNES=Object.fromEntries(Object.entries(CANCIONES).map(([k,d])=>[k,tema(d)]));
// las ondas de pulso (25 y 12,5 %) son formas propias de WebAudio (serie de Fourier del pulso)
const ONDAS={};
function onda(w){if(!ONDAS[w]){const d=w==='pulse25'?.25:.125,N=32,re=new Float32Array(N),im=new Float32Array(N);
  for(let n=1;n<N;n++){re[n]=Math.sin(2*Math.PI*n*d)/(n*Math.PI);im[n]=(1-Math.cos(2*Math.PI*n*d))/(n*Math.PI);}ONDAS[w]=AC.createPeriodicWave(re,im);}return ONDAS[w];}
// una nota de la música: de vol a la mitad en dur (lineal) y suelta en 30 ms, a musF (el fundido de la canción)
function voz(f,t,dur,w,vol){const o=AC.createOscillator(),g=AC.createGain();if(w==='pulse25'||w==='pulse12')o.setPeriodicWave(onda(w));else o.type=w;o.frequency.setValueAtTime(f,t);
  g.gain.setValueAtTime(vol,t);g.gain.linearRampToValueAtTime(vol*.5,t+dur);g.gain.linearRampToValueAtTime(0,t+dur+.03);o.connect(g);g.connect(musF);o.start(t);o.stop(t+dur+.05);}
// al cambiar de canción, la que suena se apaga en ~0,3 s y la nueva entra a los 0,4 s
function music(name){const nt=TUNES[name]||null;if(tune===nt)return;const habia=!!tune;tune=nt;seqStep=0;if(!AC)return;const t=AC.currentTime;
  if(musF){const o=musF;o.gain.cancelScheduledValues(t);o.gain.setTargetAtTime(0,t,.08);setTimeout(()=>o.disconnect(),4000);}
  musF=AC.createGain();musF.connect(musG);seqT=t+(habia?.4:.05);musF.gain.setValueAtTime(0,t);musF.gain.setTargetAtTime(1,seqT,.03);}
function schedule(){if(!AC||!tune)return;if(!musF){musF=AC.createGain();musF.connect(musG);}if(seqT<AC.currentTime)seqT=AC.currentTime+.02;const T=tune,st=60/T.bpm/2;
  while(seqT<AC.currentTime+.25){const i=seqStep%T.mel.length;if(soundOn){const n=T.mel[i],a=T.arm[i],b=T.bas[i],d=T.bat[i];
    if(n)voz(mf(n),seqT,T.md[i]*st-st*.1,T.mo,T.mv);if(a)voz(mf(a),seqT,st*.9,T.ao,T.av);if(b)voz(mf(b),seqT,st*.95,T.bo,T.bv);
    if(d===1)tone(150,seqT,.12,'triangle',.3,45,musF);else if(d===2)noise(seqT,.12,.12,musF);else if(d===3)noise(seqT,.03,.05,musF);}
    seqT+=st;seqStep++;}}
// OPCIONES (12-menus): el volumen de la música y de los efectos (de 0 a 4, de 25 en 25 %) y la velocidad del texto, en rv_ajustes
const AJ={musica:4,efectos:4,texto:0};
try{const j=JSON.parse(localStorage.getItem('rv_ajustes')||'{}');for(const k in AJ)if(typeof j[k]==='number')AJ[k]=clamp(Math.round(j[k]),0,k==='texto'?2:4);}catch(e){}
function ajustesSonido(){if(musG){musG.gain.value=AJ.musica/4;sfxG.gain.value=AJ.efectos/4;}}
function guardaAjustes(){ajustesSonido();try{localStorage.setItem('rv_ajustes',JSON.stringify(AJ));}catch(e){}}
function setSound(on){soundOn=on;if(master)master.gain.value=on?.16:0;$('bSound').classList.toggle('on',!on);$('bSound').textContent=on?'SONIDO':'SILENCIO';try{localStorage.setItem('rv_sound',on?'1':'0');}catch(e){}}

