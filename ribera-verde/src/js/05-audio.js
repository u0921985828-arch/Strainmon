/* =========================================================
   AUDIO — chiptune propio
   ========================================================= */
let AC=null,master=null,soundOn=true,tune=null,seqT=0,seqStep=0,seqIv=null,noiseBuf=null;
function audioInit(){
  if(AC)return;try{AC=new (window.AudioContext||window.webkitAudioContext)();master=AC.createGain();master.gain.value=soundOn?.16:0;master.connect(AC.destination);
  noiseBuf=AC.createBuffer(1,AC.sampleRate*.3,AC.sampleRate);const d=noiseBuf.getChannelData(0);for(let i=0;i<d.length;i++)d[i]=Math.random()*2-1;}catch(e){AC=null;}
  if(AC&&!seqIv)seqIv=setInterval(schedule,60);
}
function tone(f,t,dur,type='square',vol=.25,f2){if(!AC)return;const o=AC.createOscillator(),g=AC.createGain();o.type=type;o.frequency.setValueAtTime(f,t);if(f2)o.frequency.exponentialRampToValueAtTime(f2,t+dur);
  g.gain.setValueAtTime(vol,t);g.gain.exponentialRampToValueAtTime(.001,t+dur);o.connect(g);g.connect(master);o.start(t);o.stop(t+dur+.02);}
function noise(t,dur,vol=.3){if(!AC)return;const s=AC.createBufferSource(),g=AC.createGain();s.buffer=noiseBuf;g.gain.setValueAtTime(vol,t);g.gain.exponentialRampToValueAtTime(.001,t+dur);s.connect(g);g.connect(master);s.start(t);s.stop(t+dur);}
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
const TUNES={
  town:{bpm:132,mel:[72,0,76,79,77,76,74,0,72,74,76,72,69,0,67,0,72,0,76,79,81,79,77,76,74,76,77,74,72,0,0,0],
        bas:[48,0,55,0,53,0,55,0,48,0,55,0,45,0,43,0,48,0,55,0,53,0,52,0,50,0,55,0,48,0,43,0]},
  night:{bpm:100,mel:[69,0,72,0,76,0,74,72,71,0,67,0,69,0,0,0,69,0,72,0,77,0,76,74,72,0,71,0,69,0,0,0],
        bas:[45,0,0,0,52,0,0,0,43,0,0,0,50,0,0,0,41,0,0,0,48,0,0,0,40,0,0,0,45,0,0,0]},
  home:{bpm:96,mel:[76,0,79,0,81,0,79,76,74,0,72,0,74,76,0,0,76,0,79,0,84,0,83,81,79,0,76,0,74,0,0,0],
        bas:[48,0,0,0,52,0,0,0,53,0,0,0,55,0,0,0,48,0,0,0,52,0,0,0,50,0,0,0,55,0,0,0]},
  battle:{bpm:168,mel:[69,72,76,72,69,72,76,79,77,76,74,72,71,72,74,71,69,72,76,72,69,72,76,81,79,77,76,74,76,0,75,0],
        bas:[45,45,57,45,45,57,45,45,41,41,53,41,43,43,55,43,45,45,57,45,45,57,45,45,41,41,53,41,40,40,52,40]},
  title:{bpm:120,mel:[76,0,79,0,84,0,83,0,81,0,79,0,76,0,72,0,74,0,77,0,81,0,79,77,76,0,0,0,79,0,0,0],
        bas:[48,0,55,0,48,0,55,0,45,0,52,0,45,0,52,0,50,0,57,0,50,0,57,0,43,0,50,0,43,0,47,0]},
};
function music(name){if(tune===TUNES[name])return;tune=TUNES[name]||null;seqStep=0;if(AC)seqT=AC.currentTime+.05;}
function schedule(){if(!AC||!tune)return;if(seqT<AC.currentTime)seqT=AC.currentTime+.02;const st=60/tune.bpm/2;
  while(seqT<AC.currentTime+.25){const i=seqStep%tune.mel.length;if(soundOn){const n=tune.mel[i],b=tune.bas[i];if(n)tone(mf(n),seqT,st*.9,'square',.07);if(b)tone(mf(b),seqT,st*.95,'triangle',.16);}
    seqT+=st;seqStep++;}}
function setSound(on){soundOn=on;if(master)master.gain.value=on?.16:0;$('bSound').classList.toggle('on',!on);$('bSound').textContent=on?'SONIDO':'SILENCIO';try{localStorage.setItem('rv_sound',on?'1':'0');}catch(e){}}

