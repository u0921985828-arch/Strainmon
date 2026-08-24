using System;
using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>
/// Los edificios singulares: el estadio, la catedral, el Ayuntamiento y los demás.
///
/// Hasta que existieron, el Arriaga y el Ayuntamiento eran una chincheta sobre una manzana
/// igual que las demás: el juego te decía dónde estaban pero desde arriba no se veía nada.
/// Estos se dibujan enteros, encima del tejado genérico y a su tamaño de verdad: la
/// estación de Abando ocupa treinta y cinco casillas de largo porque la nave mide ciento
/// ochenta metros y la casilla son 5,16 m. No caben en pantalla de una vez, y así debe
/// ser — se recorren andando, como el resto de la ciudad.
///
/// No son fachadas fotografiadas ni plantas copiadas: son la silueta que tiene cada uno
/// visto desde arriba —el cuenco de un campo de fútbol, la cruz de una catedral, la nave
/// de una estación— dibujada con la paleta del juego. Eso es un hecho de la ciudad, como
/// las calles; el dibujo es nuestro.
/// </summary>
public static class Singulares {

    /// <summary>Un singular ya colocado: dónde cae y en qué trozos se ha partido.</summary>
    public class Puesto {
        public string Id;
        /// Medida final en casillas, que puede ser menor que la de plano si no cabía.
        public int W, H;
        /// Esquina noroeste, en casillas del mapa.
        public int X, Y;
    }

    public static readonly Dictionary<string,Puesto> Colocados = new Dictionary<string,Puesto>();
    /// Un trozo de 32×32 por casilla ocupada, indexado por casilla del mapa.
    static readonly Dictionary<int,Sprite> _trozos = new Dictionary<int,Sprite>();

    /// <summary>Radios de búsqueda, en casillas, del más pegado al rótulo al más lejano.</summary>
    static readonly int[] Radios = { 10, 20 };
    /// Cuánta caja tiene que caer en suelo pintable para dar la colocación por buena.
    const float SecoMin = 0.88f;

    /// <summary>Qué trozo de singular toca en esta casilla, si toca alguno.</summary>
    public static Sprite En(int x, int y) {
        Sprite s;
        return _trozos.TryGetValue(y*Ciudad.MW + x, out s) ? s : null;
    }

    /// <summary>Dónde puede pisar un singular. La calle, la ría y el monte no: por ahí se
    /// anda o se navega, y un edificio encima los borraría.</summary>
    public static bool Pintable(Suelo t) {
        return t != Suelo.Agua && t != Suelo.Muelle && t != Suelo.Puente
            && t != Suelo.Road && t != Suelo.Monte;
    }

    // ═══════════ EL PINCEL ═══════════

    /// <summary>
    /// Pincel que pinta en casillas, no en píxeles. La primera versión iba en píxeles
    /// absolutos y valía mientras un singular medía ocho casillas; a treinta y cinco, un
    /// remate de tres píxeles sobre un lienzo de mil se pierde. Así el mismo dibujo sirve
    /// a cualquier tamaño, que hace falta: abajo se encogen hasta que caben.
    /// </summary>
    public class Pincel {
        readonly Lienzo _l;
        public Pincel(Lienzo l) { _l = l; }

        public void P(float x, float y, float w, float h, Color32 c) {
            _l.P(Mathf.RoundToInt(x*Forja.TS), Mathf.RoundToInt(y*Forja.TS),
                 Mathf.Max(1, Mathf.RoundToInt(w*Forja.TS)),
                 Mathf.Max(1, Mathf.RoundToInt(h*Forja.TS)), c);
        }

        /// <summary>Un aro de grosor constante, para el círculo central y el cuenco.</summary>
        public void Aro(float cx, float cy, float r, float gr, Color32 c) {
            int n = Mathf.Max(32, Mathf.RoundToInt(r*Forja.TS/1.5f));
            for (int i = 0; i < n; i++) {
                float a = i/(float)n * 6.283f;
                P(cx + Mathf.Cos(a)*r - gr/2, cy + Mathf.Sin(a)*r - gr/2, gr, gr, c);
            }
        }
    }

    delegate void Dibujo(Pincel T, int W, int H);

    struct Plano_ { public int W, H; public Dibujo Dib; }

    // ═══════════ LOS TRECE ═══════════

    static readonly Dictionary<string,Plano_> DePlano = new Dictionary<string,Plano_> {
        // 227×203 m: el estadio, y lo que más se reconoce de Bilbao desde el aire después
        // de la ría. No hay otro rectángulo verde en toda la ciudad.
        {"sanmames", new Plano_ { W = 44, H = 39, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            T.P(1,1,W-2,H-2,Paleta.GrisL);                     // el anillo de fuera
            T.P(2.6f,2.6f,W-5.2f,H-5.2f,Paleta.Gris);          // la grada
            T.P(4.4f,3.8f,W-8.8f,H-7.6f,Paleta.Carbon);        // la boca, en sombra
            float px = 6, py = 5, pw = W-12, ph = H-10;
            T.P(px,py,pw,ph,Paleta.CespedO);
            for (float i = 0; i < pw; i += 2) T.P(px+i,py,1,ph,Paleta.Cesped);  // la siega
            const float l = .22f;
            T.P(px,py,pw,l,Paleta.Hueso); T.P(px,py+ph-l,pw,l,Paleta.Hueso);
            T.P(px,py,l,ph,Paleta.Hueso); T.P(px+pw-l,py,l,ph,Paleta.Hueso);
            T.P(px+pw/2-l/2,py,l,ph,Paleta.Hueso);             // el medio campo
            T.Aro(px+pw/2,py+ph/2,ph/5.5f,l,Paleta.Hueso);
            for (int s = 0; s < 2; s++) {                      // las dos áreas
                float bx = s == 1 ? px+pw-pw/6 : px+pw/6;
                float hx = s == 1 ? bx : px;
                T.P(hx,py+ph/2-ph/3,pw/6,l,Paleta.Hueso);
                T.P(hx,py+ph/2+ph/3,pw/6,l,Paleta.Hueso);
                T.P(bx,py+ph/2-ph/3,l,ph*2/3,Paleta.Hueso);
            }
            float[,] focos = {{1.4f,1.4f},{W-3.4f,1.4f},{1.4f,H-3.4f},{W-3.4f,H-3.4f}};
            for (int i = 0; i < 4; i++) {
                T.P(focos[i,0],focos[i,1],2,2,Paleta.Acero);
                T.P(focos[i,0]+.45f,focos[i,1]+.45f,1.1f,1.1f,Paleta.Hueso);
            }
        }}},
        // 150×110 m. Placas de titanio: velas que se solapan, cada una con su brillo por
        // el canto de arriba y su sombra por el de la derecha. Ninguna alineada con la de
        // al lado — eso es lo único que separa al museo de un tejado de chapa cualquiera,
        // y la primera versión, con las bandas a paso regular, salió persiana.
        {"guggen", new Plano_ { W = 29, H = 21, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            float[,] velas = {{.7f,1,W-8.5f,3.4f},{3.6f,3.4f,W-5.8f,3},{1,5.9f,W-9.5f,4},
                              {5.2f,9.3f,W-7.2f,3.2f},{.7f,12,W-10.5f,3.6f},
                              {4.4f,14.9f,W-6.6f,3.4f},{1.8f,17.6f,W-8.5f,2.4f}};
            for (int i = 0; i < 7; i++) {
                float x = velas[i,0], y = velas[i,1], an = velas[i,2], al = velas[i,3];
                T.P(x,y,an,al, i%2 == 1 ? Paleta.Acero : Paleta.AceroO);
                T.P(x,y,an,.45f,Paleta.Hueso);
                T.P(x+an-.45f,y,.45f,al,Paleta.GrisO);
            }
            T.P(W-3.4f,.7f,2.7f,H-2.2f,Paleta.GrisL); T.P(W-3.4f,.7f,2.7f,.4f,Paleta.Hueso);
            T.P(.6f,H-1.1f,W-1.2f,.8f,Paleta.Hormigon);        // la lámina de agua
        }}},
        // 42×42 m. Desde arriba una torre es un cuadrado; lo que la delata es el cristal.
        {"iberdrola", new Plano_ { W = 8, H = 8, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.GrisO);
            T.P(.5f,.5f,W-1,H-1,Paleta.AceroO);
            T.P(1,1,W-2,H-2,Paleta.Acero);
            for (float i = 1.5f; i < W-1.5f; i += .9f) T.P(i,1,.3f,H-2,Paleta.Hueso);
            T.P(1,1,W-2,.4f,Paleta.Hueso);
            T.P(W/2f-1,H/2f-1,2,2,Paleta.AceroO);              // el casquete de arriba
        }}},
        // 130×85 m. Casco de barco en acero oxidado, en el sitio del astillero: las
        // cuadernas se ven desde arriba como costillas.
        {"euskalduna", new Plano_ { W = 25, H = 16, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            T.P(1,1.6f,W-2,H-4,Paleta.TejaO);
            T.P(1,1.6f,W-2,.45f,Paleta.MaderaL);
            for (float x = 2; x < W-2; x += 1.6f) T.P(x,2.2f,.5f,H-5.4f,Paleta.MaderaO);
            T.P(W-4.6f,1,3.6f,H-2,Paleta.Gris);                // la caja de escena
            T.P(2.6f,H-2.6f,W-5.2f,1.8f,Paleta.GrisL);         // la plaza de delante
            T.P(2.6f,H-2.6f,W-5.2f,.35f,Paleta.Hueso);
        }}},
        // 180×80 m. La nave de la estación, con los andenes y las vías debajo.
        {"abando", new Plano_ { W = 35, H = 16, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            T.P(.6f,.6f,W-1.2f,H-1.2f,Paleta.AceroO);
            for (float y = 1.3f; y < H-2.2f; y += 2.6f) {
                T.P(1.2f,y,W-2.4f,1.9f,Paleta.Acero);          // la bóveda
                T.P(1.2f,y,W-2.4f,.3f,Paleta.Hueso);
                T.P(1.2f,y+1.9f,W-2.4f,.5f,Paleta.AsfaltoO);   // la vía por debajo
                T.P(1.2f,y+2.05f,W-2.4f,.15f,Paleta.GrisL);
            }
            T.P(.6f,.6f,W-1.2f,.4f,Paleta.Hueso);
            T.P(W/2f-3,H-1.5f,6,1,Paleta.MostazaO);            // el vestíbulo, a la calle
        }}},
        // 60×45 m. Mansarda de pizarra, frontón al medio y marquesina a la calle.
        {"arriaga", new Plano_ { W = 12, H = 9, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.GrisL);
            T.P(.45f,.45f,W-.9f,H-.9f,Paleta.Gris);
            for (float x = 1; x < W-1; x += 1.4f) T.P(x,1,.45f,H-3,Paleta.GrisO);  // limatesas
            T.P(W/2f-2.6f,.2f,5.2f,2.4f,Paleta.MostazaO);      // el frontón
            T.P(W/2f-2.2f,.6f,4.4f,1.6f,Paleta.Mostaza);
            T.P(.6f,H-2.2f,W-1.2f,1.4f,Paleta.MaderaO);        // la marquesina
            T.P(.6f,H-2.2f,W-1.2f,.4f,Paleta.MostazaO);
            T.P(1.6f,H-1,W-3.2f,.7f,Paleta.Carbon);
        }}},
        // 78×45 m. Planta simétrica y la torre del reloj en el eje.
        {"ayto", new Plano_ { W = 15, H = 9, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.Hormigon);
            T.P(.5f,.5f,W-1,H-1,Paleta.HormigonL);
            T.P(1.2f,1.6f,W-2.4f,H-3.2f,Paleta.GrisL);         // el cuerpo y sus dos alas
            for (float x = 2; x < W-2; x += 1.7f) T.P(x,2,.6f,H-4,Paleta.Gris);
            T.P(W/2f-2.2f,.2f,4.4f,4.6f,Paleta.HormigonL);     // la torre del reloj
            T.P(W/2f-1.8f,.6f,3.6f,3.8f,Paleta.Hormigon);
            // El reloj. Con dos agujas y nada más se leía como una ele mayúscula: hacen
            // falta las marcas del cuadrante y el eje para que la cabeza vea una esfera.
            float rx = W/2f, ry = 2.4f, rr = 1.1f;
            T.P(rx-rr,ry-rr,rr*2,rr*2,Paleta.Crema);
            int[,] marcas = {{0,-1},{1,0},{0,1},{-1,0}};
            for (int i = 0; i < 4; i++)
                T.P(rx+marcas[i,0]*(rr-.3f)-.09f, ry+marcas[i,1]*(rr-.3f)-.09f, .18f,.18f, Paleta.Carbon);
            T.P(rx-.09f,ry-.72f,.18f,.75f,Paleta.Carbon);      // la aguja larga, a las doce
            T.P(rx,ry-.09f,.58f,.18f,Paleta.Carbon);           // la corta, a las tres
            T.P(rx-.15f,ry-.15f,.3f,.3f,Paleta.Carbon);        // el eje
            T.P(.8f,H-1.4f,W-1.6f,.9f,Paleta.HormigonO);       // la escalinata
        }}},
        // 62×32 m. Cruz latina: la nave a lo largo, el crucero cruzándola cerca de la
        // cabecera y el cimborrio en el cruce. A doce por seis el crucero no llegaba a
        // leerse como brazo y la catedral salía siendo una nave más.
        {"catedral", new Plano_ { W = 13, H = 8, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            float nv = 2.9f, cx = W*.62f;
            T.P(.6f,H/2f-nv/2,W-1.2f,nv,Paleta.Gris);
            T.P(cx-1.7f,.7f,3.4f,H-1.4f,Paleta.Gris);
            T.P(.6f,H/2f-nv/2,W-1.2f,.4f,Paleta.GrisL);
            T.P(cx-1.7f,.7f,3.4f,.4f,Paleta.GrisL);
            for (float x = 1; x < W-1.4f; x += 1.2f) T.P(x,H/2f-nv/2,.26f,nv,Paleta.GrisO);
            for (float y = 1.3f; y < H-1.2f; y += 1.2f) T.P(cx-1.7f,y,3.4f,.26f,Paleta.GrisO);
            T.P(cx-1.05f,H/2f-1.45f,2.1f,2.9f,Paleta.HormigonL);  // el cimborrio
            T.P(cx-.5f,H/2f-.95f,1,1.9f,Paleta.MostazaO);         // la aguja
            T.P(W-2,H/2f-1.9f,1.4f,3.8f,Paleta.Hormigon);         // el ábside
        }}},
        // 60×28 m. Nave larga y su torre, que se ve desde media villa.
        {"begonia", new Plano_ { W = 12, H = 5, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            T.P(1,.8f,W-2,H-1.6f,Paleta.Teja);
            T.P(1,.8f,W-2,.35f,Paleta.TejaO);
            for (float y = 1.4f; y < H-1; y += .7f) T.P(1,y,W-2,.18f,Paleta.MaderaO);
            T.P(.4f,.4f,2.8f,H-.8f,Paleta.HormigonL);          // la torre
            T.P(.7f,.7f,2.2f,H-1.4f,Paleta.Hormigon);
            T.P(1.2f,1.4f,1.2f,1.6f,Paleta.Crema);
            T.P(1.5f,.05f,.5f,.8f,Paleta.MostazaO);
        }}},
        // 130×40 m. Nave junto al agua, con sus lucernarios en diente de sierra.
        {"merca", new Plano_ { W = 25, H = 8, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            T.P(.6f,.6f,W-1.2f,H-1.2f,Paleta.GrisL);
            for (float x = 1.6f; x < W-2; x += 2.3f) {
                T.P(x,1.2f,1.6f,H-2.4f,Paleta.Gris);
                T.P(x+.3f,1.5f,1,H-3,Paleta.Acero);
                T.P(x+.3f,1.5f,1,.3f,Paleta.Hueso);
            }
            T.P(.6f,.6f,W-1.2f,.4f,Paleta.Hueso);
        }}},
        // 76×76 m. El almacén de vinos: ladrillo, y los tres patios que le abrieron dentro.
        {"alhondiga", new Plano_ { W = 15, H = 15, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.MaderaL);
            T.P(.45f,.45f,W-.9f,H-.9f,Paleta.Teja);
            for (float y = 1.2f; y < H-1; y += .9f) T.P(.9f,y,W-1.8f,.2f,Paleta.TejaO);
            float an = (W-3.2f)/3;
            for (int i = 0; i < 3; i++) {
                T.P(1.6f+i*an,H/2f-2.4f,an-1.1f,4.8f,Paleta.AceroO);
                T.P(1.9f+i*an,H/2f-2.1f,an-1.7f,4.2f,Paleta.Acero);
            }
            T.P(.45f,.45f,W-.9f,.4f,Paleta.MaderaL);
        }}},
        // 100×62 m. Los almacenes de la Gran Vía: un bloque macizo con la cubierta llena
        // de máquinas y el rótulo corrido por el canto de la calle. Nombre inventado,
        // sitio real — aquí no entra ninguna marca de nadie.
        {"almacenes", new Plano_ { W = 19, H = 12, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            T.P(.5f,.5f,W-1,H-1,Paleta.HormigonL);
            T.P(1.2f,1.2f,W-2.4f,H-3.4f,Paleta.Hormigon);
            for (float y = 2.2f; y < H-3.4f; y += 2.4f)       // los climatizadores
                for (float x = 2.2f; x < W-3; x += 2.6f) {
                    T.P(x,y,1.8f,1.4f,Paleta.AceroO);
                    T.P(x+.25f,y+.25f,1.3f,.9f,Paleta.Acero);
                    T.P(x+.25f,y+.25f,1.3f,.25f,Paleta.Hueso);
                }
            T.P(1.2f,H-4.2f,W-2.4f,.35f,Paleta.GrisO);        // la junta de la cubierta
            T.P(.8f,H-2.4f,W-1.6f,1.5f,Paleta.MostazaO);      // el rótulo, a la Gran Vía
            T.P(1.2f,H-2.1f,W-2.4f,.9f,Paleta.Mostaza);
            for (float x = 2; x < W-2; x += 1.5f) T.P(x,H-1.85f,.55f,.4f,Paleta.Carbon);
            T.P(.8f,H-.9f,W-1.6f,.5f,Paleta.Carbon);          // la marquesina
        }}},
        // 105×90 m. Cuenco pequeño y tejado de madera.
        {"arena", new Plano_ { W = 20, H = 17, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);
            T.P(1,1,W-2,H-2,Paleta.MaderaO);
            for (float x = 1.6f; x < W-1.6f; x += 1.2f) T.P(x,1.4f,.45f,H-2.8f,Paleta.Madera);
            T.P(1,1,W-2,.4f,Paleta.MaderaL);
            T.Aro(W/2f,H/2f,Mathf.Min(W,H)/3.2f,.5f,Paleta.GrisL);
            T.P(W/2f-3.2f,H/2f-2.6f,6.4f,5.2f,Paleta.Gris);
            T.P(W/2f-2.8f,H/2f-2.2f,5.6f,4.4f,Paleta.Acero);
        }}},
    };

    // ═══════════ COLOCACIÓN ═══════════

    /// <summary>
    /// Dónde se planta cada uno, y de qué tamaño.
    ///
    /// El rótulo del plano marca el sitio con un error de unas cuantas casillas, y en dos
    /// casos el error es gordo: los de San Mamés y el Bilbao Arena caen en mitad de la ría.
    /// Plantarlos ahí sin mirar dejaba medio estadio flotando. Así que no se planta: se
    /// desliza la caja alrededor del rótulo y se elige donde más manzana pisa y menos agua
    /// toca; si a diez casillas no hay sitio seco, se busca a veinte; y si aun así no cabe,
    /// el edificio se encoge de diez en diez por ciento hasta que cabe. Lo que se pierde es
    /// escala; lo que se gana es que está donde el plano dice y pisando tierra.
    ///
    /// Veinte casillas es el tope a propósito: la batería exige que ningún sitio se aleje
    /// más de treinta del plano, y así la colocación no puede ser nunca la que rompa eso.
    ///
    /// Dos tablas de sumas acumuladas hacen que cada posición candidata se resuelva con
    /// cuatro restas, así que probar dos mil sitios por edificio no cuesta nada.
    /// </summary>
    public static void Colocar() {
        if (_trozos.Count > 0) return;
        int MW = Ciudad.MW, MH = Ciudad.MH;

        Func<Func<Suelo,bool>,int[]> Acumula = cond => {
            var t = new int[(MW+1)*(MH+1)];
            for (int y = 0; y < MH; y++) {
                int f = 0;
                for (int x = 0; x < MW; x++) {
                    if (cond((Suelo)Ciudad.Map[y*MW+x])) f++;
                    t[(y+1)*(MW+1)+x+1] = t[y*(MW+1)+x+1] + f;
                }
            }
            return t;
        };
        Func<int[],int,int,int,int,int> Caja = (t,x,y,w,h) =>
            t[(y+h)*(MW+1)+x+w] - t[y*(MW+1)+x+w] - t[(y+h)*(MW+1)+x] + t[y*(MW+1)+x];

        var manzana   = Acumula(t => t == Suelo.Edif || t == Suelo.Patio);
        var seco      = Acumula(Pintable);
        var prohibido = Acumula(t => !Pintable(t));

        foreach (var par in DePlano) {
            var sitio = Estado.Sitio_(par.Key);
            if (sitio == null) continue;
            var pl = par.Value;

            int mejX = 0, mejY = 0, mejW = 0, mejH = 0;
            float mejSeco = -1;
            bool hecho = false;
            foreach (int R in Radios) {
                for (int k = 10; k >= 5 && !hecho; k--) {
                    int w = Mathf.Max(4, Mathf.RoundToInt(pl.W*k/10f));
                    int h = Mathf.Max(4, Mathf.RoundToInt(pl.H*k/10f));
                    int bx = 0, by = 0; float mejor = float.NegativeInfinity;
                    for (int dy = -R; dy <= R; dy++)
                        for (int dx = -R; dx <= R; dx++) {
                            int x = Mathf.Clamp(sitio.Cx - (w>>1) + dx, 1, MW-w-1);
                            int y = Mathf.Clamp(sitio.Cy - (h>>1) + dy, 1, MH-h-1);
                            // Manda la manzana, pero un paso de más desde el rótulo se
                            // paga: entre dos sitios parecidos gana el que está donde lo
                            // pone el plano.
                            float v = Caja(seco,x,y,w,h) + Caja(manzana,x,y,w,h)
                                    - 6*Caja(prohibido,x,y,w,h)
                                    - Mathf.Sqrt(dx*dx + dy*dy)*1.2f;
                            if (v > mejor) { mejor = v; bx = x; by = y; }
                        }
                    float s = Caja(seco,bx,by,w,h) / (float)(w*h);
                    if (s > mejSeco + .001f) { mejSeco = s; mejX = bx; mejY = by; mejW = w; mejH = h; }
                    if (s >= SecoMin) { mejX = bx; mejY = by; mejW = w; mejH = h; hecho = true; }
                }
                if (hecho) break;
            }

            Forjar(par.Key, mejX, mejY, mejW, mejH, pl.Dib);
        }
    }

    /// <summary>Dibuja el singular a su medida final y lo parte en trozos de casilla.</summary>
    /// Se parte porque la ciudad se pinta con un Tilemap: no hay dónde colgar un sprite de
    /// mil píxeles de ancho sin salirse de la rejilla, y partido se resuelve solo el
    /// recorte de lo que no se ve.
    static void Forjar(string id, int x, int y, int w, int h, Dibujo dib) {
        var L = new Lienzo(w*Forja.TS, h*Forja.TS);
        dib(new Pincel(L), w, h);
        Paleta.Cuantizar(L.Px);
        var px = new Color32[L.W*L.H];
        L.VolcarEn(px, L.W, L.H, 0, 0);
        var tex = Utiles.Textura(L.W, L.H, px);

        Colocados[id] = new Puesto { Id = id, W = w, H = h, X = x, Y = y };
        for (int j = 0; j < h; j++)
            for (int i = 0; i < w; i++) {
                int mx = x+i, my = y+j;
                if (!Pintable(Ciudad.T(mx,my))) continue;
                // La textura va del revés (Unity cuenta las filas de abajo arriba), así
                // que la fila j del dibujo es la fila h-1-j de la textura.
                _trozos[my*Ciudad.MW + mx] =
                    Utiles.Rebanada(tex, i*Forja.TS, (h-1-j)*Forja.TS, Forja.TS, Forja.TS, 0f, 0f);
            }
    }
}

}
