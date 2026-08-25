using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

/// <summary>El botón de acción, el de atacar y todo lo que dicen los NPC.</summary>
public static class Acciones {

    public static Sitio SitioCerca(Vector2 p) {
        Sitio mejor = null;
        float md = 1.8f;
        foreach (var s in Estado.Sitios) {
            float d = Vector2.Distance(s.Pos, p);
            if (d < md) { md = d; mejor = s; }
        }
        return mejor;
    }

    public static Vehiculo CocheCerca(Juego J) {
        Vehiculo mejor = null;
        float md = 1.7f;
        foreach (var c in J.Coches) {
            if (!c.Vivo) continue;
            float d = Vector2.Distance(c.Pos, J.Jug.Pos);
            if (d < md) { md = d; mejor = c; }
        }
        return mejor;
    }

    public static void Ejecutar(Juego J) {
        if (Dialogo.I.Abierto) return;
        var E = Estado.I;

        if (E.EnInterior) {
            var n = Interiores.NpcCerca(J.Jug.Pos);
            if (n != null) { Hablar(n); return; }
            char arriba = Interiores.Casilla(J.Jug.Pos.x, J.Jug.Pos.y - 0.9f);
            if (arriba == 'C') { Dormir(); return; }
            if (arriba == 'L') { Curar(); return; }
            if (Interiores.Casilla(J.Jug.Pos.x, J.Jug.Pos.y + 0.7f) == 'D' ||
                Interiores.Casilla(J.Jug.Pos.x, J.Jug.Pos.y) == 'D') { Interiores.Salir(); return; }
            Hud.I.Aviso("AQUÍ NO HAY NADA");
            return;
        }

        if (J.Jug.EnCoche != null) {
            var c = J.Jug.EnCoche;
            J.Jug.Pos = c.Pos + new Vector2(Mathf.Cos(c.Ang + Mathf.PI/2f), Mathf.Sin(c.Ang + Mathf.PI/2f)) * 1.3f;
            J.Jug.EnCoche = null;
            AudioProc.I.MotorApagado();
            return;
        }

        var s = SitioCerca(J.Jug.Pos);
        if (s != null) {
            if (s.Red != null) { Transporte.Estacion(s); return; }
            // Tu piso, cuando ya no es tuyo.
            if (s.Id == "piso" && E.CaseraDesahucio && !Bienes.EsMio("pisosantutxu")) {
                if (E.CaseraOkupa) { Interiores.Entrar("piso", s.Pos, "Tu piso · de okupa", s.Id); return; }
                var sitio = s;
                Dialogo.I.Abrir("Cerradura nueva", new[]{"La llave no entra. Amaia la ha cambiado."}, new[]{
                    new Opcion{ Texto="Forzar la puerta", Accion = () => {
                        Bienes.Ocupar();
                        Interiores.Entrar("piso", sitio.Pos, "Tu piso · de okupa", sitio.Id); }},
                    new Opcion{ Texto="Dejarlo estar" }});
                return;
            }
            // En la puerta de una casa en venta: o la compras o te quedas mirando el cartel.
            if (s.Vende != null && !Bienes.EsMio(s.Vende)) {
                var q = Bienes.PropDe(s.Vende);
                string pega = Bienes.PegaPara(q);
                Dialogo.I.Abrir("SE VENDE",
                    new[]{ q.Desc, pega != "" ? pega : "Piden " + q.Precio + " €." },
                    pega != "" ? null : new[]{
                        new Opcion{ Texto="Comprarla", Coste = q.Precio + " €", Accion = () => Bienes.ComprarProp(q.Id) },
                        new Opcion{ Texto="Otro día" }});
                return;
            }
            if (s.Interior != null) { Interiores.Entrar(s.Interior, s.Pos, s.Nombre, s.Id); return; }
            if (s.Id == "poli") { Hud.I.Aviso("COMISARÍA. MEJOR NO ENTRES"); return; }
            if (s.Mirador) { Hud.I.Aviso(s.Nombre); return; }
            Hud.I.Aviso("ACEPTA UN CURRO AQUÍ DESDE EL MÓVIL");
            return;
        }

        var parada = Transporte.ParadaCerca(J.Jug.Pos);
        if (parada != null) {
            if (Estado.I.Estrellas > 0) { Hud.I.Aviso("CON LA PASMA DETRÁS NO SUBES A NINGÚN SITIO"); return; }
            Transporte.AbrirRed("bus", "Parada · " + parada.Nombre, parada.Pos);
            return;
        }

        var v = CocheCerca(J);
        if (v != null) {
            J.Jug.EnCoche = v;
            if (!v.Propio && !v.Marcado) {
                // Reventar una ventanilla se oye, aunque no haya nadie mirando.
                Sigilo.Ruido(v.Pos, 7f);
                Hud.I.Aviso(Sigilo.Delito(1) ? "COCHE ROBADO" : "COCHE ROBADO. SIN TESTIGOS");
            }
            else Hud.I.Aviso("A RODAR");
            return;
        }
        Hud.I.Aviso("AQUÍ NO HAY NADA QUE HACER");
    }

    public static void Atacar(Juego J) {
        var E = Estado.I;
        if (E.EnInterior || J.Jug.EnCoche != null) return;
        var a = Armas.De(E.ArmaAct);
        if (J.Jug.Cadencia > 0) return;
        if (!a.Infinita && E.Mun(a.Id) <= 0) { Hud.I.Aviso("SIN MUNICIÓN"); return; }
        J.Jug.Cadencia = a.Cad;

        // auto-apuntado solo a enemigos; a los viandantes solo con las manos
        Enemigo obj = null;
        float md = a.Alc + 0.6f;
        foreach (var e in J.Enemigos) {
            float d = Vector2.Distance(e.Pos, J.Jug.Pos);
            if (d > md) continue;
            float ang = Mathf.Atan2(e.Pos.y - J.Jug.Pos.y, e.Pos.x - J.Jug.Pos.x);
            float df = Mathf.Abs(Mathf.DeltaAngle(ang * Mathf.Rad2Deg, DirAng(J.Jug.Dir8) * Mathf.Rad2Deg)) * Mathf.Deg2Rad;
            if (df < 1.05f && Combate.LineaVista(J.Jug.Pos, e.Pos)) { md = d; obj = e; }
        }
        Peaton victima = null;
        if (a.Cuerpo && obj == null) {
            foreach (var p in J.Peatones) {
                float d = Vector2.Distance(p.Pos, J.Jug.Pos);
                if (d > a.Alc + 0.4f) continue;
                float ang = Mathf.Atan2(p.Pos.y - J.Jug.Pos.y, p.Pos.x - J.Jug.Pos.x);
                float df = Mathf.Abs(Mathf.DeltaAngle(ang * Mathf.Rad2Deg, DirAng(J.Jug.Dir8) * Mathf.Rad2Deg)) * Mathf.Deg2Rad;
                if (df < 1.05f) { victima = p; break; }
            }
        }

        Vector2 hacia = obj != null ? obj.Pos : (victima != null ? victima.Pos : Vector2.zero);
        float angulo = (obj != null || victima != null)
            ? Mathf.Atan2(hacia.y - J.Jug.Pos.y, hacia.x - J.Jug.Pos.x)
            : DirAng(J.Jug.Dir8);
        if (obj != null || victima != null) J.Jug.Dir8 = ForjaChar.Dir8(Mathf.Cos(angulo), Mathf.Sin(angulo));

        if (a.Cuerpo) {
            J.Jug.PoseAct = Pose.Pega2;
            J.Jug.GolpeT = 0.22f;
            // Por detrás y a alguien que no sabe que estás ahí: cae de un golpe y sin
            // ruido. Es el premio de haber ido despacio; sin esto, el sigilo solo sirve
            // para tardar más en llegar al mismo tiroteo.
            if (obj != null && Sigilo.Desprevenido(obj) && Sigilo.PorDetras(obj)
                && Vector2.Distance(obj.Pos, J.Jug.Pos) < 1.4f) {
                AudioProc.I.Sfx("golpe", 0.35f);
                Combate.I.Danar(obj, 999, J);
                Particulas.I.Emitir(obj.Pos, "sangre", 6);
                Sigilo.Ruido(obj.Pos, 2.5f);
                Bienes.DarXp(25);
                Hud.I.Aviso("POR LA ESPALDA");
                return;
            }
            AudioProc.I.Sfx("golpe", 0.7f);
            if (obj != null && Vector2.Distance(obj.Pos, J.Jug.Pos) <= a.Alc + 0.4f) Combate.I.Danar(obj, a.Dmg, J);
            else if (victima != null) Combate.I.DanarPeaton(victima, a.Dmg, J);
        } else {
            E.Municion[a.Id] = E.Mun(a.Id) - 1;
            Combate.I.Disparar(J.Jug.Pos, angulo, a, true);
            J.Jug.PoseAct = Pose.Dispara;
            J.Jug.GolpeT = 0.16f;
            if (a.Fog != null) J.Jug.Fogonazo(a.Fog, J.Jug.Dir8);
            // Un disparo se oye a media calle. Con silenciador, a la acera de enfrente y
            // poco más: el arma sigue haciendo el mismo daño, lo que compras es no
            // despertar al barrio.
            bool sil = E.TieneSilenciador && a.Id == "pistola";
            Sigilo.Ruido(J.Jug.Pos, sil ? 5f : 18f);
            if (E.Estrellas < 1) Sigilo.Delito(1);
        }
    }

    static float DirAng(int d8) { return (2 - d8) * Mathf.PI / 4f; }

    public static void Pista(Juego J) {
        if (J.Jug.EnCoche != null) { Hud.I.Pista("ACCIÓN: BAJAR"); return; }
        var s = SitioCerca(J.Jug.Pos);
        if (s != null) { Hud.I.Pista(s.Interior != null ? "ACCIÓN: ENTRAR EN " + s.Nombre : s.Nombre); return; }
        var c = CocheCerca(J);
        if (c != null) { Hud.I.Pista(c.Propio || c.Marcado ? "ACCIÓN: SUBIR" : "ACCIÓN: ROBAR COCHE"); return; }
        Hud.I.Pista(null);
    }

    public static void PistaInterior(Juego J) {
        var n = Interiores.NpcCerca(J.Jug.Pos);
        if (n != null) { Hud.I.Pista("ACCIÓN: HABLAR CON " + n.Nombre); return; }
        char arriba = Interiores.Casilla(J.Jug.Pos.x, J.Jug.Pos.y - 0.9f);
        if (arriba == 'C') { Hud.I.Pista("ACCIÓN: DORMIR"); return; }
        if (arriba == 'L') { Hud.I.Pista("ACCIÓN: QUE TE CUREN"); return; }
        Hud.I.Pista(null);
    }

    // ═══════════ SERVICIOS ═══════════
    // ═══════════ ROPA, MESA Y SURTIDOR ═══════════
    /// <summary>Una prenda: qué ranura ocupa y por qué valor la cambia.</summary>
    public class ArticuloRopa {
        public string Ranura, Valor, Icono, Titulo, Desc;
        public int Precio;
    }
    static ArticuloRopa Pr(string r, string v, string ico, string tt, string dd, int precio) {
        return new ArticuloRopa{ Ranura=r, Valor=v, Icono=ico, Titulo=tt, Desc=dd, Precio=precio };
    }
    public static readonly ArticuloRopa[] Prendas = {
        Pr("torso","chaqueta", "camisa","Chaqueta de traje","Para pisar moqueta.",190),
        Pr("torso","sudadera", "camisa","Sudadera con capucha","La cara medio tapada.",70),
        Pr("torso","chandal",  "camisa","Chándal","Verde, con la raya blanca.",90),
        Pr("torso","abrigo",   "camisa","Abrigo largo","Aquí llueve nueve meses.",240),
        Pr("torso","gabardina","camisa","Gabardina","De las de esperar bajo un soportal.",210),
        Pr("torso","polo",     "camisa","Polo","Discreto y de verano.",45),
        Pr("torso","cazadora", "camisa","Cazadora negra","La de siempre.",80),
        Pr("piernas","vestir",  "pantalon","Pantalón de vestir","Raya y todo.",95),
        Pr("piernas","vaquero", "pantalon","Vaquero","No falla.",55),
        Pr("piernas","chandalP","pantalon","Pantalón de chándal","Juego con la parte de arriba.",40),
        Pr("piernas","cargo",   "pantalon","Pantalón de faena","Bolsillos en las perneras.",60),
        Pr("calzado","deportivas","zapato","Deportivas","Blancas, para correr de verdad.",75),
        Pr("calzado","zapatos",   "zapato","Zapatos","Negros, de suela dura.",110),
        Pr("calzado","botas",     "zapato","Botas","De obra, sirven para todo.",85),
        Pr("gorro","txapela","gorra","Txapela","De aquí de toda la vida.",35),
        Pr("gorro","gorra",  "gorra","Gorra","Visera y sombra en la cara.",25),
        Pr("gorro","lana",   "gorra","Gorro de lana","Para el sirimiri.",20),
        Pr("gorro","ninguno","gorra","A cabeza descubierta","Se te va a mojar.",10),
    };
    static string Puesta(string ranura) {
        var E = Estado.I;
        return ranura == "torso" ? E.Torso : ranura == "piernas" ? E.Piernas
             : ranura == "calzado" ? E.Calzado : E.Gorro;
    }
    public static void Vestir(string ranura, string valor) {
        var E = Estado.I;
        if (ranura == "torso") E.Torso = valor;
        else if (ranura == "piernas") E.Piernas = valor;
        else if (ranura == "calzado") E.Calzado = valor;
        else E.Gorro = valor;
        ForjaChar.Vestir(E.Torso, E.Piernas, E.Calzado, E.Gorro);
        // Cambiarse de arriba abajo quita una estrella: la descripción que la pasma va
        // pasando por la emisora deja de valer. Es lo que hace el repintado con el coche.
        if (E.Estrellas > 0) {
            E.Estrellas--;
            if (E.Estrellas == 0) Juego.I.Patrullas.Clear();
            Hud.I.Aviso("ROPA NUEVA. UNA ESTRELLA MENOS");
        }
        Guardado.Guardar();
    }
    public static void TiendaRopa(string titulo) {
        bool mio = Bienes.EnLoMio();
        var arts = new List<Articulo>();
        foreach (var q in Prendas) {
            var pr = q;
            arts.Add(new Articulo{
                Icono = pr.Icono, Titulo = pr.Titulo, Desc = pr.Desc, Precio = mio ? 0 : pr.Precio,
                YaLoTiene = () => Puesta(pr.Ranura) == pr.Valor,
                Comprar = () => { Vestir(pr.Ranura, pr.Valor);
                                  Hud.I.Aviso(pr.Titulo.ToUpperInvariant() + " PUESTA"); }});
        }
        MenuMovil.I.AbrirTienda(titulo + (mio ? " · Ropa · tuya" : " · Ropa"), arts);
    }

    public static void Comer(int coste, float hambre, float energia, int hp) {
        var E = Estado.I;
        if (Bienes.EnLoMio()) coste = 0;
        if (E.Dinero < coste) { Hud.I.Aviso("NO TE LLEGA"); return; }
        E.Dinero -= coste;
        E.Hambre = Mathf.Min(1f, E.Hambre + hambre);
        E.Energia = Mathf.Min(1f, E.Energia + energia);
        E.Hp = Mathf.Min(100f, E.Hp + hp);
        AudioProc.I.Sfx("dinero", 1f);
        Hud.I.Aviso(coste > 0 ? "−" + coste + " €" : "INVITA LA CASA");
    }

    /// <summary>El coche que se repara es el que has dejado en la puerta, no el que
    /// llevas: al entrar te bajas. Se busca alrededor del sitio por el que entraste.</summary>
    public static void Repostar() {
        var E = Estado.I;
        var donde = Interiores.Volver;
        Vehiculo mej = null; float md = 9f;
        foreach (var c in Juego.I.Coches) {
            if (!c.Vivo) continue;
            float d = Vector2.Distance(c.Pos, donde);
            if (d < md) { md = d; mej = c; }
        }
        if (mej == null) { Hud.I.Aviso("ACERCA EL COCHE A LOS SURTIDORES"); return; }
        if (mej.Dano <= 0.02f) { Hud.I.Aviso("EL COCHE ESTÁ ENTERO"); return; }
        int cst = Bienes.EnLoMio() ? 0 : Mathf.Max(15, Mathf.RoundToInt(mej.Dano * 260f));
        if (E.Dinero < cst) { Hud.I.Aviso("TE PIDEN " + cst + " € Y NO LOS TIENES"); return; }
        E.Dinero -= cst; mej.Dano = 0f;
        AudioProc.I.Sfx("dinero", 1f);
        Hud.I.Aviso(cst > 0 ? "REPOSTADO Y ARREGLADO. −" + cst + " €" : "REPOSTADO Y ARREGLADO. ES TUYA");
    }

    public static void Curar() {
        var E = Estado.I;
        if (E.Hp >= 100) { Hud.I.Aviso("ESTÁS ENTERO"); return; }
        int c = Mathf.RoundToInt((100 - E.Hp) * 1.2f);
        if (E.Dinero < c) { Hud.I.Aviso("TE COBRAN " + c + " € Y NO LOS TIENES"); return; }
        E.Dinero -= c; E.Hp = 100;
        AudioProc.I.Sfx("dinero", 1f);
        Hud.I.Aviso("CURADO. −" + c + " €");
    }

    public static void Dormir() {
        var E = Estado.I;
        E.Dia++; E.Min = 8*60; E.Energia = 1;
        E.Hp = Mathf.Min(100, E.Hp + 45);
        E.Estrellas = 0;
        while (Juego.I.Patrullas.Count > 0) Juego.I.QuitarUnaPatrulla();
        bool okupa = E.CaseraOkupa && Interiores.Actual != null
                     && Interiores.PoiActual == "piso" && !Bienes.EsMio("pisosantutxu");
        int renta = Bienes.CobrarRentas();
        Bienes.CorrerAlquiler();
        if (okupa) Bienes.DormirOkupa();
        else if (renta == 0 && E.Deuda == 0) Hud.I.Aviso("HAS DORMIDO. DÍA " + E.Dia);
        if (E.Alquiler > 0 && E.Deuda >= E.Alquiler * 2) {
            E.Energia = Mathf.Min(E.Energia, 0.55f);
            Hud.I.Aviso("DEBES " + E.Deuda + " €. DUERMES FATAL", 3f);
        }
        Guardado.Guardar();
    }

    static void Firmar(string gremio, int meta, int bonus) {
        var E = Estado.I;
        var abierto = E.ContratoDe(gremio);
        if (abierto != null) {
            Hud.I.Aviso("YA TIENES UNO: " + abierto.Hechos + " DE " + abierto.Meta);
            return;
        }
        E.Firmar(gremio, meta, bonus);
        E.Rep[gremio] += 1;
        Hud.I.Aviso(meta + " CURROS DE " + gremio.ToUpperInvariant() + " Y COBRAS " + bonus + " €", 3f);
        Guardado.Guardar();
    }

    // ═══════════ CONVERSACIONES ═══════════
    public static void Hablar(NpcInterior n) {
        var E = Estado.I;
        switch (n.Tipo) {
            case "jefe": {
                if (E.Prologo) {
                    Dialogo.I.Abrir("Txema", new[]{"Tú eres el primo de Yeray, el de las islas.",
                        "Deja la bolsa en el piso y luego hablamos de trabajar."}, null);
                    return;
                }
                var m = Misiones.I.Siguiente();
                if (Misiones.I.Activa != null) {
                    Dialogo.I.Abrir("Txema", new[]{"Estás en mitad de un marrón. Termínalo."}, new[]{
                        new Opcion{ Texto="Abandonar la misión", Accion=() => Misiones.I.Terminar(false) },
                        new Opcion{ Texto="Voy a ello" }});
                    return;
                }
                if (m == null) { Dialogo.I.Abrir("Txema", new[]{"Ya no queda nada que pedirte. El barrio es tuyo."}, null); return; }
                if (m.Giver != "Txema") { Dialogo.I.Abrir("Txema", new[]{"Ahora mismo quien tiene curro es " + m.Giver + "."}, null); return; }
                if (m.RequiereArma && !E.TieneArmaFuego()) {
                    Dialogo.I.Abrir("Txema", new[]{"Sin un hierro no te mando ahí. Pásate por el Bazar."}, null); return;
                }
                var def = m;
                Dialogo.I.Abrir("Txema", m.Intro, new[]{
                    new Opcion{ Texto="Acepto", Accion=() => Misiones.I.Empezar(def) },
                    new Opcion{ Texto="Ahora no" }});
                return;
            }
            case "barman": {
                var ops = new List<Opcion>{
                    new Opcion{ Texto="Zurito y pintxo", Coste="5 €", Accion=() => Comer(5, .5f, .2f, 8) },
                    new Opcion{ Texto="Menú del día", Coste="12 €", Accion=() => Comer(12, 1f, .45f, 22) }};
                if (Interiores.PoiActual == "tascapozas") ops.Add(Bienes.OpcionComprar("tascapozas"));
                ops.Add(new Opcion{ Texto="Firmar contrato de hostelería", Accion=() => Firmar("hosteleria", 3, 140) });
                Dialogo.I.Abrir(n.Nombre, new[]{"Aupa. ¿Qué te pongo?"}, ops.ToArray());
                return;
            }
            case "ropa": {
                var ops = new List<Opcion>{
                    new Opcion{ Texto="Ver la ropa", Accion=() => TiendaRopa(Interiores.Actual.Nombre) }};
                if (Interiores.PoiActual == "ropagranvia") ops.Add(Bienes.OpcionComprar("ropagranvia"));
                ops.Add(new Opcion{ Texto="¿Qué se lleva?", Accion=() =>
                    Hud.I.Aviso("AQUÍ LO QUE SE LLEVA ES QUE NO SE TE NOTE DE DÓNDE VIENES") });
                Dialogo.I.Abrir("Nerea", new[]{ Bienes.EsMio("ropagranvia") && Interiores.PoiActual == "ropagranvia"
                    ? "Buenos días, jefe. Todo en orden." : "Pasa, pasa. ¿Te vistes o miras?" }, ops.ToArray());
                return;
            }
            case "encargada": {
                var ops = new List<Opcion>{
                    new Opcion{ Texto="Ver la ropa", Accion=() => TiendaRopa(Interiores.Actual.Nombre) },
                    new Opcion{ Texto="Llenar la despensa", Coste="25 €", Accion=() => Comer(25, 1f, .35f, 12) },
                    Bienes.OpcionComprar("almacenes"),
                    new Opcion{ Texto="¿Se vende bien?", Accion=() =>
                        Hud.I.Aviso("EN DICIEMBRE NO CABE UN ALMA. EN AGOSTO ESTO ES UN MUSEO") }};
                Dialogo.I.Abrir("Maite", new[]{ Bienes.EsMio("almacenes")
                    ? "Buenos días, jefe. La caja de ayer ya está cuadrada."
                    : "Tres plantas: ropa arriba, alimentación abajo y lo demás en medio." }, ops.ToArray());
                return;
            }
            case "cocinero":
                Dialogo.I.Abrir("Patxi", new[]{"Hay menú y hay carta. Tú dirás."}, new[]{
                    new Opcion{ Texto="Menú del día", Coste="18 €", Accion=() => Comer(18, 1f, .6f, 30) },
                    new Opcion{ Texto="Chuletón y postre", Coste="45 €", Accion=() => Comer(45, 1f, 1f, 55) },
                    new Opcion{ Texto="Café solo", Coste="2 €", Accion=() => Comer(2, .05f, .25f, 0) },
                    new Opcion{ Texto="Firmar contrato de hostelería", Accion=() => Firmar("hosteleria", 3, 140) }});
                return;
            case "gasolinero": {
                var ops = new List<Opcion>{
                    new Opcion{ Texto="Repostar y revisar el coche", Accion=Repostar },
                    new Opcion{ Texto="Café de máquina", Coste="2 €", Accion=() => Comer(2, .05f, .3f, 0) },
                    new Opcion{ Texto="Bocadillo de la vitrina", Coste="6 €", Accion=() => Comer(6, .6f, .1f, 6) }};
                if (Interiores.PoiActual == "gasodeustu") ops.Add(Bienes.OpcionComprar("gasodeustu"));
                ops.Add(new Opcion{ Texto="Firmar contrato de transporte", Accion=() => Firmar("transporte", 3, 170) });
                Dialogo.I.Abrir("Gorka", new[]{"Surtidor libre el tres. ¿Lleno?"}, ops.ToArray());
                return;
            }
            case "parroquiano": {
                var frases = new[]{
                    "El puente viejo se cierra cuando la pasma se pone seria.",
                    "En el hospital te cosen por dinero y sin preguntas.",
                    "Koldo vende cosas que no salen en el escaparate.",
                    "Si te escondes y no te ven un rato, se olvidan de ti.",
                    "Iker repinta coches. Eso quita una estrella."
                };
                Dialogo.I.Abrir("Mikel", new[]{ frases[Utiles.RndI(0, frases.Length-1)] }, null);
                return;
            }
            case "mecanico": {
                var m = Misiones.I.Siguiente();
                var opsBase = new List<Opcion>{
                    new Opcion{ Texto="Ver vehículos", Accion=() => MenuMovil.I.AbrirTienda("Taller Iker", new List<Articulo>{
                        new Articulo{ Icono="furgo", Titulo="Furgoneta",
                            Desc = E.NivelPj < Bienes.NivelDe(Bienes.NivelVehiculo, "furgo")
                                 ? "Necesitas nivel " + Bienes.NivelDe(Bienes.NivelVehiculo, "furgo")
                                 : "Abre mudanzas y entregas grandes.", Precio=700,
                            YaLoTiene=() => E.TieneFurgo || E.NivelPj < Bienes.NivelDe(Bienes.NivelVehiculo, "furgo"),
                            Comprar=() => { E.TieneFurgo = true; Hud.I.Aviso("FURGONETA COMPRADA"); }},
                        new Articulo{ Icono="deportivo", Titulo="Deportivo",
                            Desc = E.NivelPj < Bienes.NivelDe(Bienes.NivelVehiculo, "deportivo")
                                 ? "Necesitas nivel " + Bienes.NivelDe(Bienes.NivelVehiculo, "deportivo")
                                 : "Más velocidad y mejor agarre.", Precio=1600,
                            YaLoTiene=() => E.TieneDeportivo || E.NivelPj < Bienes.NivelDe(Bienes.NivelVehiculo, "deportivo"),
                            Comprar=() => { E.TieneDeportivo = true; Hud.I.Aviso("DEPORTIVO COMPRADO"); }}
                    })},
                    new Opcion{ Texto="Repintar el coche", Coste=(Bienes.EsMio("taller") ? 0 : 100) + " €", Accion=() => {
                        int c = Bienes.EsMio("taller") ? 0 : 100;
                        if (E.Dinero < c) { Hud.I.Aviso("NO TE LLEGA"); return; }
                        if (E.Estrellas == 0) { Hud.I.Aviso("NO TE BUSCA NADIE"); return; }
                        E.Dinero -= c; E.Estrellas--;
                        if (E.Estrellas == 0) while (Juego.I.Patrullas.Count > 0) Juego.I.QuitarUnaPatrulla();
                        Hud.I.Aviso("UNA ESTRELLA MENOS"); }},
                    Bienes.OpcionComprar("taller"),
                    new Opcion{ Texto="Firmar contrato de transporte", Accion=() => Firmar("transporte", 3, 170) }
                };
                if (m != null && m.Giver == "Iker" && Misiones.I.Activa == null) {
                    if (m.RequiereFurgo && !E.TieneFurgo) {
                        Dialogo.I.Abrir("Iker", new[]{"Tengo curro pero necesitas furgoneta."}, opsBase.ToArray());
                        return;
                    }
                    var def = m;
                    var ops = new List<Opcion>{ new Opcion{ Texto="Acepto", Accion=() => Misiones.I.Empezar(def) }};
                    ops.AddRange(opsBase);
                    Dialogo.I.Abrir("Iker", m.Intro, ops.ToArray());
                    return;
                }
                Dialogo.I.Abrir("Iker", new[]{"Aupa. ¿Vienes a mirar o a comprar?"}, opsBase.ToArray());
                return;
            }
            case "pescatera":
                Dialogo.I.Abrir("Bego", new[]{"Buenos días. Aquí se empieza pronto."}, new[]{
                    new Opcion{ Texto="Firmar contrato de hostelería", Accion=() => Firmar("hosteleria", 3, 140) },
                    new Opcion{ Texto="Comprar bocata", Coste="7 €", Accion=() => {
                        if (E.Dinero < 7) { Hud.I.Aviso("NO TE LLEGA"); return; }
                        E.Dinero -= 7; E.Hambre = Mathf.Min(1, E.Hambre + 0.7f);
                        Hud.I.Aviso("BOCATA. −7 €"); }}});
                return;
            case "enfermera":
                Dialogo.I.Abrir("Nekane", new[]{"Si sangras, siéntate en la camilla."}, new[]{
                    new Opcion{ Texto="Que me curen", Accion=Curar },
                    new Opcion{ Texto="Comprar chaleco", Coste="250 €", Accion=() => {
                        if (E.Dinero < 250) { Hud.I.Aviso("NO TE LLEGA"); return; }
                        E.Dinero -= 250; E.Hp = Mathf.Min(100, E.Hp + 60);
                        Hud.I.Aviso("CHALECO PUESTO"); }}});
                return;
            case "primo": {
                if (E.Prologo) { Dialogo.I.Abrir("Yeray", new[]{"Suelta la bolsa, anda."}, null); return; }
                string estP = Bienes.EstadoCasera();
                string linP =
                    estP == "desahuciado" ? "Amaia ha cambiado la cerradura. A mí no me mires: yo pago lo mío." :
                    E.Deuda > 0 ? "Debes " + E.Deuda + " € y Amaia lleva mejor la cuenta que tú." :
                                  "Aupa. La cocina está como la dejaste.";
                Dialogo.I.Abrir("Yeray", new[]{linP}, new[]{
                    new Opcion{ Texto="Cenar lo que haya", Coste="4 €", Accion=() => {
                        if (E.Dinero < 4) { Hud.I.Aviso("NO TE LLEGA NI PARA ESO"); return; }
                        E.Dinero -= 4;
                        E.Hambre = Mathf.Min(1f, E.Hambre + 0.55f);
                        E.Energia = Mathf.Min(1f, E.Energia + 0.15f);
                        AudioProc.I.Sfx("dinero", 1f);
                        Hud.I.Aviso("CENA DE PISO · −4 €"); }},
                    new Opcion{ Texto="Nada" }});
                return;
            }
            case "casera": {
                var ops = new List<Opcion>();
                if (Bienes.EsMio("pisosantutxu")) {
                    Dialogo.I.Abrir("Amaia", new[]{"Ahora el piso es tuyo. Yo solo bajo la basura."}, new[]{
                        new Opcion{ Texto="Preguntar por el barrio",
                            Accion=() => Hud.I.Aviso("AQUÍ SIEMPRE HA LLOVIDO Y SIEMPRE SE HA CURRADO") }});
                    return;
                }
                string est = Bienes.EstadoCasera();
                int total = Bienes.DeudaTotal();
                string linea =
                    est == "aldia"       ? "Estás al día. Así da gusto." :
                    est == "debiendo"    ? "Me debes " + E.Deuda + " € de alquiler." :
                    est == "avisado"     ? "Van dos meses, " + E.Deuda + " €. No me obligues." :
                    est == "desahuciado" ? "La cerradura ya está cambiada. Son " + total + " € y hablamos."
                                         : "Sé que estás durmiendo ahí dentro. " + total + " € o llamo a quien tenga que llamar.";
                ops.Add(new Opcion{
                    Texto = total > 0 ? (E.CaseraDesahucio ? "Pagar todo y recuperar la llave" : "Pagar el alquiler")
                                      : "Adelantar un mes",
                    Coste = (total > 0 ? total : E.Alquiler) + " €",
                    Accion = Bienes.PagarCasera });
                // Solo se le compra el piso a quien está al día. Es lo que ata las dos cosas:
                // la compra deja de ser una lista de precios y pasa a depender de cómo te has
                // portado.
                if (est == "aldia" && E.CaseraPaciencia >= 3) ops.Add(Bienes.OpcionComprar("pisosantutxu"));
                else ops.Add(new Opcion{ Texto="¿Me lo venderías?",
                    Accion=() => Hud.I.Aviso("«¿VENDÉRTELO? PÁGAME LO QUE DEBES Y HABLAMOS»") });
                if (E.Alquiler > 0 && E.Deuda == 0 && !E.CaseraDesahucio)
                    ops.Add(new Opcion{ Texto="Dejar el piso", Accion=() =>
                        Dialogo.I.Abrir("Amaia", new[]{"¿Te vas? Pues las llaves."}, new[]{
                            new Opcion{ Texto="Me voy", Accion = Bienes.DejarPiso },
                            new Opcion{ Texto="Me quedo" }}) });
                ops.Add(new Opcion{ Texto="Preguntar por el barrio",
                    Accion=() => Hud.I.Aviso("AQUÍ SIEMPRE HA LLOVIDO Y SIEMPRE SE HA CURRADO") });
                Dialogo.I.Abrir("Amaia", new[]{ linea }, ops.ToArray());
                return;
            }
            case "armero": {
                Dialogo.I.Abrir("Koldo", new[]{"Aquí no se pregunta y no se fía."}, new[]{
                    new Opcion{ Texto="Ver género", Accion=() => {
                        var arts = new List<Articulo>();
                        foreach (var a in Armas.Todas) {
                            if (a.Precio <= 0) continue;
                            var arma = a;
                            arts.Add(new Articulo{
                                Icono = a.Id, Titulo = a.Nombre,
                                Desc = E.NivelPj < Bienes.NivelDe(Bienes.NivelArma, a.Id)
                                     ? "Necesitas nivel " + Bienes.NivelDe(Bienes.NivelArma, a.Id)
                                     : a.Cuerpo ? "Cuerpo a cuerpo" : "Daño " + a.Dmg + " · " + a.Balas + " balas",
                                Precio = a.Precio,
                                YaLoTiene = () => E.Municion.ContainsKey(arma.Id)
                                              || E.NivelPj < Bienes.NivelDe(Bienes.NivelArma, arma.Id),
                                Comprar = () => { E.Municion[arma.Id] = arma.Infinita ? 999 : arma.Balas;
                                                  E.ArmaAct = arma.Id; Hud.I.Aviso(arma.Nombre.ToUpperInvariant() + " COMPRADA"); }});
                        }
                        arts.Add(new Articulo{
                            Icono = "pistola", Titulo = "Silenciador",
                            Desc = "Para la pistola. El disparo deja de oírse en media calle.",
                            Precio = 520,
                            YaLoTiene = () => E.TieneSilenciador,
                            Comprar = () => { E.TieneSilenciador = true; Hud.I.Aviso("SILENCIADOR MONTADO"); }});
                        foreach (var a in Armas.Todas) {
                            if (a.Pack <= 0 || !E.Municion.ContainsKey(a.Id)) continue;
                            var arma = a;
                            arts.Add(new Articulo{
                                Icono = "📦", Titulo = "Munición " + a.Nombre, Desc = "+" + a.Pack + " balas",
                                Precio = Mathf.RoundToInt(a.Precio * 0.18f),
                                YaLoTiene = () => false,
                                Comprar = () => { E.Municion[arma.Id] = E.Mun(arma.Id) + arma.Pack;
                                                  Hud.I.Aviso("+" + arma.Pack + " BALAS"); }});
                        }
                        MenuMovil.I.AbrirTienda("Bazar Nervión", arts);
                    }}});
                return;
            }
        }
    }
}

}
