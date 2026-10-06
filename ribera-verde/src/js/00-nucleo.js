'use strict';
/* =========================================================
   RIBERA VERDE — motor gráfico estilo 16-bit portátil (160 px de alto; 240-400 de ancho)
   Todo el arte es procedural y original.
   ========================================================= */
const TS=16, SH=160;
let SW=240;   // ancho del juego: 06b-pantalla.js lo ajusta al móvil (240-400)
const $=id=>document.getElementById(id);
const cv=$('c'), ctx=cv.getContext('2d'); ctx.imageSmoothingEnabled=false;
const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const ri=(a,b)=>a+Math.floor(Math.random()*(b-a+1));
const pick=a=>a[Math.floor(Math.random()*a.length)];
const wait=ms=>new Promise(r=>setTimeout(r,ms));
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const pct=n=>n.toFixed(1).replace('.',',');
const eur=n=>Math.round(n).toLocaleString('es-ES')+' €';
function mkCanvas(w,h){const c=document.createElement('canvas');c.width=w;c.height=h;const x=c.getContext('2d');x.imageSmoothingEnabled=false;return [c,x];}
function rngSeed(s){let t=s>>>0;return()=>{t=(t+0x6D2B79F5)>>>0;let r=Math.imul(t^(t>>>15),1|t);r^=r+Math.imul(r^(r>>>7),61|r);return((r^(r>>>14))>>>0)/4294967296;};}
function hashStr(s){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619);}return h>>>0;}
function shade(hex,amt){const n=parseInt(hex.slice(1),16);let r=(n>>16)+amt,g=((n>>8)&255)+amt,b=(n&255)+amt;r=clamp(r,0,255);g=clamp(g,0,255);b=clamp(b,0,255);return '#'+((1<<24)|(r<<16)|(g<<8)|b).toString(16).slice(1);}
function mix(a,b,t=.5){const A=parseInt(a.slice(1),16),B=parseInt(b.slice(1),16);const f=(s)=>Math.round(((A>>s)&255)*(1-t)+((B>>s)&255)*t);return '#'+((1<<24)|(f(16)<<16)|(f(8)<<8)|f(0)).toString(16).slice(1);}

