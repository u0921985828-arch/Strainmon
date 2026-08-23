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
            if (s.Interior != null) { Interiores.Entrar(s.Interior, s.Pos); return; }
            if (s.Id == "poli") { Hud.I.Aviso("COMISARÍA. MEJOR NO ENTRES"); return; }
            if (s.Mirador) { Hud.I.Aviso(s.Nombre); return; }
            Hud.I.Aviso("ACEPTA UN CURRO AQUÍ DESDE EL MÓVIL");
            return;
        }

        var v = CocheCerca(J);
        if (v != null) {
            J.Jug.EnCoche = v;
            if (!v.Propio && !v.Marcado) { Combate.I.Estrellas(1, J); Hud.I.Aviso("COCHE ROBADO"); }
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
            AudioProc.I.Sfx("golpe", 0.7f);
            J.Jug.PoseAct = Pose.Pega2;
            J.Jug.GolpeT = 0.22f;
            if (obj != null && Vector2.Distance(obj.Pos, J.Jug.Pos) <= a.Alc + 0.4f) Combate.I.Danar(obj, a.Dmg, J);
            else if (victima != null) Combate.I.DanarPeaton(victima, a.Dmg, J);
        } else {
            E.Municion[a.Id] = E.Mun(a.Id) - 1;
            Combate.I.Disparar(J.Jug.Pos, angulo, a, true);
            J.Jug.PoseAct = Pose.Dispara;
            J.Jug.GolpeT = 0.16f;
            if (a.Fog != null) J.Jug.Fogonazo(a.Fog, J.Jug.Dir8);
            if (E.Estrellas < 1) Combate.I.Estrellas(1, J);
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
        if (E.Dia - E.UltCobro >= 7) {
            E.Deuda += E.Alquiler;
            E.UltCobro = E.Dia;
            Hud.I.Aviso("ALQUILER: +" + E.Alquiler + " € DE DEUDA", 3f);
        } else Hud.I.Aviso("HAS DORMIDO. DÍA " + E.Dia);
        if (E.Deuda >= E.Alquiler * 2) { E.Energia = 0.55f; Hud.I.Aviso("DEBES " + E.Deuda + " €. DUERMES FATAL", 3f); }
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
            case "barman":
                Dialogo.I.Abrir("Josu", new[]{"Aupa. ¿Qué te pongo?"}, new[]{
                    new Opcion{ Texto="Zurito y pintxo", Coste="5 €", Accion=() => {
                        if (E.Dinero < 5) { Hud.I.Aviso("NO TE LLEGA"); return; }
                        E.Dinero -= 5; E.Hambre = Mathf.Min(1, E.Hambre + 0.5f);
                        E.Energia = Mathf.Min(1, E.Energia + 0.2f); E.Hp = Mathf.Min(100, E.Hp + 8);
                        Hud.I.Aviso("−5 €"); }},
                    new Opcion{ Texto="Menú del día", Coste="12 €", Accion=() => {
                        if (E.Dinero < 12) { Hud.I.Aviso("NO TE LLEGA"); return; }
                        E.Dinero -= 12; E.Hambre = 1;
                        E.Energia = Mathf.Min(1, E.Energia + 0.45f); E.Hp = Mathf.Min(100, E.Hp + 22);
                        Hud.I.Aviso("−12 €"); }},
                    new Opcion{ Texto="Firmar contrato de hostelería", Accion=() => Firmar("hosteleria", 3, 140) }});
                return;
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
                        new Articulo{ Icono="🚐", Titulo="Furgoneta", Desc="Abre mudanzas y entregas grandes.", Precio=700,
                            YaLoTiene=() => E.TieneFurgo, Comprar=() => { E.TieneFurgo = true; Hud.I.Aviso("FURGONETA COMPRADA"); }},
                        new Articulo{ Icono="🏎", Titulo="Deportivo", Desc="Más velocidad y mejor agarre.", Precio=1600,
                            YaLoTiene=() => E.TieneDeportivo, Comprar=() => { E.TieneDeportivo = true; Hud.I.Aviso("DEPORTIVO COMPRADO"); }}
                    })},
                    new Opcion{ Texto="Repintar el coche", Coste="100 €", Accion=() => {
                        if (E.Dinero < 100) { Hud.I.Aviso("NO TE LLEGA"); return; }
                        if (E.Estrellas == 0) { Hud.I.Aviso("NO TE BUSCA NADIE"); return; }
                        E.Dinero -= 100; E.Estrellas--;
                        if (E.Estrellas == 0) while (Juego.I.Patrullas.Count > 0) Juego.I.QuitarUnaPatrulla();
                        Hud.I.Aviso("UNA ESTRELLA MENOS"); }},
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
            case "casera": {
                var ops = new List<Opcion>();
                if (E.Deuda > 0)
                    ops.Add(new Opcion{ Texto="Pagar alquiler", Coste=E.Deuda + " €", Accion=() => {
                        if (E.Dinero < E.Deuda) { Hud.I.Aviso("NO TIENES SUFICIENTE"); return; }
                        E.Dinero -= E.Deuda; E.Deuda = 0;
                        AudioProc.I.Sfx("dinero", 1f);
                        Hud.I.Aviso("ALQUILER AL DÍA"); Guardado.Guardar(); }});
                ops.Add(new Opcion{ Texto="Preguntar por el barrio",
                    Accion=() => Hud.I.Aviso("AQUÍ SIEMPRE HA LLOVIDO Y SIEMPRE SE HA CURRADO") });
                Dialogo.I.Abrir("Amaia",
                    new[]{ E.Deuda > 0 ? "Me debes " + E.Deuda + " € de alquiler." : "Estás al día. Así da gusto." },
                    ops.ToArray());
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
                                Icono = a.Cuerpo ? "🏏" : "🔫", Titulo = a.Nombre,
                                Desc = a.Cuerpo ? "Cuerpo a cuerpo" : "Daño " + a.Dmg + " · " + a.Balas + " balas",
                                Precio = a.Precio,
                                YaLoTiene = () => E.Municion.ContainsKey(arma.Id),
                                Comprar = () => { E.Municion[arma.Id] = arma.Infinita ? 999 : arma.Balas;
                                                  E.ArmaAct = arma.Id; Hud.I.Aviso(arma.Nombre.ToUpperInvariant() + " COMPRADA"); }});
                        }
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
