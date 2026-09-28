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
        // 175×145 m: el estadio viejo, La Catedral. El cuenco de 2013 mide 227×203 y
        // todavía no existe; en el 96 lo que hay es la caja del trece con el arco de acero
        // de los cincuenta sobre la tribuna. Sigue siendo lo que más se reconoce de Bilbao
        // desde el aire después de la ría —no hay otro rectángulo verde en la ciudad— y
        // ahora además lleva encima lo único curvo del mapa.
        {"sanmames", new Plano_ { W = 34, H = 28, Dib = (T,W,H) => {
            // Abajo se encogen hasta que caben, y este cabe al 50 %: nada de medidas
            // absolutas, que a la mitad se salen de la caja. Todo va por `k`, que vale 1
            // a tamaño de plano.
            float k = H/28f;
            T.P(0,0,W,H,Paleta.HormigonO);                     // la explanada de alrededor
            T.P(k,k,W-2*k,H-2*k,Paleta.GrisL);                 // el muro y el anillo de fuera
            T.P(2.4f*k,2.4f*k,W-4.8f*k,H-4.8f*k,Paleta.Gris);  // la grada
            // Los dos fondos son lo único descubierto, así que son lo único donde se ven
            // las filas: rayas paralelas a la portería. Sin ellas la grada es un gris.
            for (int i = 0; i < 3; i++) {
                T.P(3.2f*k+i*.8f*k,3.6f*k,.3f*k,H-7.2f*k,Paleta.GrisO);
                T.P(W-3.5f*k-i*.8f*k,3.6f*k,.3f*k,H-7.2f*k,Paleta.GrisO);
            }
            // 105×70 m, la medida reglamentaria.
            float pw = 20.3f*k, ph = 13.6f*k, px = (W-pw)/2, py = 7.4f*k;
            // La boca ciñe el césped: entre la última fila y la banda hay metro y medio,
            // no treinta. Con la boca a la caja entera el estadio salía siendo un agujero
            // negro con un sello verde al fondo, que es justo lo que no es un campo.
            T.P(px-1.4f*k,py-1.4f*k,pw+2.8f*k,ph+2.8f*k,Paleta.Carbon);
            // Las cubiertas. Tribuna y preferencia van techadas de lado a lado; los dos
            // fondos no, y las esquinas siguen abiertas, que es como estaba en el 96.
            T.P(3.2f*k,2.6f*k,W-6.4f*k,2.6f*k,Paleta.Hormigon);
            T.P(3.2f*k,H-5.2f*k,W-6.4f*k,2.6f*k,Paleta.Hormigon);
            for (float x = 4.4f*k; x < W-4*k; x += 2.6f*k) {   // las correas de las cubiertas
                T.P(x,2.6f*k,.3f*k,2.6f*k,Paleta.GrisL);
                T.P(x,H-5.2f*k,.3f*k,2.6f*k,Paleta.GrisL);
            }
            T.P(3.2f*k,4.9f*k,W-6.4f*k,.3f*k,Paleta.GrisL);    // el alero, donde acaba el techo
            T.P(3.2f*k,H-5.5f*k,W-6.4f*k,.3f*k,Paleta.GrisL);
            T.P(px,py,pw,ph,Paleta.CespedO);
            for (float i = 0; i < pw; i += 2*k)
                T.P(px+i,py,k,ph,Paleta.Cesped);               // las franjas de siega
            float l = .22f*k;
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
            // El arco. Cuarenta y cinco metros de acero de punta a punta de la tribuna, y
            // lo que le da el apodo al campo. Desde arriba no se vería —un arco visto en
            // planta es una recta— pero esta vista es la de 45°, así que el alto sube por
            // la pantalla: la curva arranca del borde interior del tejado y su clave se
            // asoma por encima del estadio.
            float ax0 = 3.6f*k, ax1 = W-3.6f*k, ay = 4.8f*k, flecha = 4*k;
            Action<float,float,Color32> arco = (dy, gr, col) => {
                int n = Mathf.Max(64, Mathf.RoundToInt((ax1-ax0)*Forja.TS/1.5f));
                for (int i = 0; i <= n; i++) {
                    float t = i/(float)n;
                    T.P(ax0+(ax1-ax0)*t-gr/2,
                        ay - Mathf.Sin(Mathf.PI*t)*flecha + dy - gr/2, gr, gr, col);
                }
            };
            arco(.34f*k,.9f*k,Paleta.AceroO);                  // el canto, en sombra
            arco(0,.9f*k,Paleta.Acero);
            arco(-.28f*k,.5f*k,Paleta.Hueso);                  // el brillo de arriba
            T.P(ax0-.8f*k,ay-.4f*k,1.6f*k,2.4f*k,Paleta.AceroO);   // los dos arranques
            T.P(ax1-.8f*k,ay-.4f*k,1.6f*k,2.4f*k,Paleta.AceroO);
            float[,] focos = {{1.4f*k,1.4f*k},{W-3.4f*k,1.4f*k},
                              {1.4f*k,H-3.4f*k},{W-3.4f*k,H-3.4f*k}};
            for (int i = 0; i < 4; i++) {
                T.P(focos[i,0],focos[i,1],2*k,2*k,Paleta.Acero);
                T.P(focos[i,0]+.45f*k,focos[i,1]+.45f*k,1.1f*k,1.1f*k,Paleta.Hueso);
            }
        }}},
        // 1996: aquí no hay museo todavía, hay un solar con grúas. Abre en octubre del 97,
        // así que en el último trimestre del 96 lo que se ve desde la ría son las
        // torres-grúa, las placas de titanio apiladas esperando y el vallado. Sigue siendo
        // el hito de la ría — CONTEXT.md §18.4 le da el único foco frío del mapa— pero es
        // un hito de obra.
        {"obraGuggen", new Plano_ { W = 29, H = 21, Dib = (T,W,H) => {
            T.P(0,0,W,H,Paleta.HormigonO);                     // el solar, tierra removida
            T.P(.6f,.6f,W-1.2f,H-1.2f,Paleta.Ladrillo1);
            for (float x = 1.4f; x < W-1.4f; x += 2.2f)
                T.P(x,1.2f,.35f,H-2.4f,Paleta.Ladrillo0);      // rodadas de camión
            // Las placas de titanio, apiladas por lotes. Lo único frío del solar.
            float[,] lotes = {{2,3,5,2.2f},{8.5f,2.4f,4.5f,2},{3.5f,7.5f,6,2.4f},{13,8,4,2}};
            for (int i = 0; i < 4; i++) {
                float x = lotes[i,0], y = lotes[i,1], an = lotes[i,2], al = lotes[i,3];
                T.P(x,y,an,al,Paleta.Titanio0);
                T.P(x,y,an,.4f,Paleta.Titanio1);
                T.P(x+an-.4f,y,.4f,al,Paleta.Hormigon);
            }
            // Dos torres-grúa. La pluma es lo que se ve desde arriba, no el mástil.
            float[,] gruas = {{7,13,11},{19,6,9}};
            for (int i = 0; i < 2; i++) {
                float cx = gruas[i,0], cy = gruas[i,1], largo = gruas[i,2];
                T.P(cx-.6f,cy-.6f,1.2f,1.2f,Paleta.Aviso0);    // el mástil
                T.P(cx,cy-.25f,largo,.5f,Paleta.Aviso1);       // la pluma
                T.P(cx+largo-.8f,cy-.6f,.8f,1.2f,Paleta.Aviso0); // el carro
                T.P(cx-2.4f,cy-.25f,2.4f,.5f,Paleta.HormigonL);  // el contrapeso
            }
            T.P(.6f,.6f,W-1.2f,.3f,Paleta.HormigonL);          // el vallado
            T.P(.6f,H-.9f,W-1.2f,.3f,Paleta.HormigonL);
            T.P(.6f,.6f,.3f,H-1.2f,Paleta.HormigonL);
            T.P(W-.9f,.6f,.3f,H-1.2f,Paleta.HormigonL);
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
