/**
 * ¿Aguanta el juego el callejero entero?
 *
 *   node herramientas/html/escala-calles.js [cuántas]
 *
 * La tabla que hay en el repositorio son 34 ejes puestos a mano, pero la de verdad la
 * escribe el extractor del plano y son del orden de mil calles. Con 34 no se nota nada;
 * con mil, si el trazado estuviera mal planteado, serían minutos de carga y nadie se
 * enteraría hasta tener el PDF delante. Esto lo mide antes, con calles de mentira puestas
 * donde hay calle de verdad.
 */
require('./arnes.js');
const listo=async()=>{for(let t=0;t<90000;t+=25){const A=global.__;if(A&&A.LARGO_CALLE&&A.LARGO_CALLE.length===A.CALLES.length)return;await new Promise(r=>setTimeout(r,25));}throw new Error('no');};
listo().then(()=>{
 const A=global.__,N=Number(process.argv[2]||1000);
 // Calles de mentira, pero puestas donde hay calle de verdad y con la misma pinta que
 // las que saca el extractor: dos o tres rótulos a lo largo de un tramo corto.
 const vias=[];
 for(let y=0;y<A.MH;y++)for(let x=0;x<A.MW;x++)if(A.rodable(x,y))vias.push([x,y]);
 const base=A.CALLES.length;
 for(let i=0;i<N;i++){
  const [x,y]=vias[(i*7919)%vias.length];
  const v=[[x,y]];
  for(let k=1;k<3;k++)v.push([x+k*14,y+((i%3)-1)*8]);
  A.CALLES.push({n:'Calle de prueba '+i,v});}
 const t0=Date.now();
 A.nombrarCalles();
 const ms=Date.now()-t0;
 let con=0;for(let i=0;i<A.calleDe.length;i++)if(A.calleDe[i])con++;
 console.log(`${A.CALLES.length} calles (${base} de verdad + ${N} de prueba) · ${ms} ms · ${con} casillas nombradas`);
 process.exit(0);});
