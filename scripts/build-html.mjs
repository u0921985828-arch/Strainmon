/* Bundle autocontenido: inyecta assets/style.css y todos los src/*.js inline
   en un único HTML jugable sin servidor (abrir con doble clic). Sin SW. */
import fs from 'node:fs';
const html = fs.readFileSync('index.html','utf8');
const css = fs.readFileSync('assets/style.css','utf8');
// scripts en orden de index.html
const scripts = [...html.matchAll(/<script src="([^"]+)"><\/script>/g)].map(m=>m[1]);
let body = html
  .replace(/<link rel="stylesheet" href="assets\/style.css" \/>/, `<style>\n${css}\n</style>`)
  .replace(/<link rel="manifest"[^>]*>/,'')
  .replace(/<script src="[^"]+"><\/script>\n?/g,'');
// inserta todos los JS inline justo antes del <script> del service worker
const bundle = scripts.map(s=>{
  const code = fs.readFileSync(s,'utf8');
  return `<script>\n/* ${s} */\n${code}\n</script>`;
}).join('\n');
// quita el bloque del service worker (no aplica en fichero local)
body = body.replace(/<script>\s*\/\/ Service worker[\s\S]*?<\/script>/, '');
body = body.replace('</body>', bundle + '\n</body>');
fs.mkdirSync('dist',{recursive:true});
fs.writeFileSync('dist/Strainmon.html', body);
console.log('dist/Strainmon.html', (fs.statSync('dist/Strainmon.html').size/1048576).toFixed(2)+'MB', '·', scripts.length,'módulos');
