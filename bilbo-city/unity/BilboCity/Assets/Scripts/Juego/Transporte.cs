using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

public class RedTransporte {
    public string Id, Nombre, Icono;
    /// Precio del billete, en euros.
    public int Tarifa;
    /// Casillas por minuto de reloj de juego, y minutos de espera en el andén.
    public float Vel;
    public int Espera;
}

public class Parada {
    public string Nombre;
    public Vector2 Pos;
}

/// <summary>Transporte público: tres redes con la misma mecánica y tres coberturas
/// distintas, que es lo que las diferencia. El bus para en los treinta y cuatro barrios
/// pero tarda; el metro solo pasa por donde pasa, y vuela; el cercanías llega al fondo
/// del valle —Zorrotza, Olabeaga— que es justo donde el metro no baja.
///
/// Cuesta dinero y cuesta reloj. Y con la pasma detrás no te dejan subir: si no, el
/// billete de dos euros sería la mejor huida del juego.</summary>
public static class Transporte {

    public static readonly Dictionary<string, RedTransporte> Redes = new Dictionary<string, RedTransporte> {
        {"bus",   new RedTransporte{ Id="bus",   Nombre="Bilbobus",  Icono="bus",   Tarifa=2, Vel= 48f, Espera= 7 }},
        {"metro", new RedTransporte{ Id="metro", Nombre="Metro",     Icono="metro", Tarifa=3, Vel=115f, Espera= 4 }},
        {"tren",  new RedTransporte{ Id="tren",  Nombre="Cercanías", Icono="tren",  Tarifa=3, Vel=135f, Espera=10 }},
    };

    /// <summary>Una parada de bus por barrio. No hay que escribir ninguna coordenada: los
    /// barrios ya están donde el ayuntamiento los rotula en el plano, así que el bus llega
    /// a todos sin una lista que mantener.</summary>
    public static readonly List<Parada> Paradas = new List<Parada>();

    public static void ColocarParadas() {
        Paradas.Clear();
        foreach (var b in Plano.Barrios)
            Paradas.Add(new Parada{ Nombre = b.Nombre, Pos = Ciudad.CercaDe(
                (x,y) => { var t = Ciudad.T(x,y); return t == Suelo.Acera || t == Suelo.Plaza; },
                b.X, b.Y, 34) });
    }

    public static List<Parada> Nodos(string red) {
        if (red == "bus") return Paradas;
        var l = new List<Parada>();
        foreach (var s in Estado.Sitios)
            if (s.EsDeRed(red)) l.Add(new Parada{ Nombre = s.Nombre, Pos = s.Pos });
        return l;
    }

    public static int Minutos(string red, float casillas) {
        var R = Redes[red];
        return Mathf.Max(2, Mathf.RoundToInt(R.Espera + casillas / R.Vel));
    }

    /// <summary>Una parada de bus no es un sitio: no sale en el radar ni en el mapa de
    /// pausa, porque treinta y cuatro chinchetas más taparían la ciudad. Se encuentra
    /// estando encima.</summary>
    public static Parada ParadaCerca(Vector2 p) {
        Parada mej = null; float md = 1.8f;
        foreach (var q in Paradas) {
            float d = Vector2.Distance(q.Pos, p);
            if (d < md) { md = d; mej = q; }
        }
        return mej;
    }

    public static void Viajar(string red, Parada destino) {
        var E = Estado.I;
        var J = Juego.I;
        int min = Minutos(red, Vector2.Distance(destino.Pos, J.Jug.Pos));
        J.Jug.Pos = destino.Pos;
        J.Jug.EnCoche = null;
        E.Min += min;
        while (E.Min >= 1440) { E.Min -= 1440; E.Dia++; }
        E.Energia = Mathf.Max(0f, E.Energia - min * 0.004f);
        Hud.I.Aviso(Redes[red].Nombre.ToUpperInvariant() + " · " + min + " MIN");
        Guardado.Guardar();
    }

    public static void AbrirRed(string red, string titulo, Vector2 aqui) {
        var R = Redes[red];
        var destinos = new List<Parada>();
        foreach (var q in Nodos(red))
            if (Vector2.Distance(q.Pos, aqui) > 3f) destinos.Add(q);
        if (destinos.Count == 0) { Hud.I.Aviso("NO HAY MÁS PARADAS EN ESTA RED"); return; }
        destinos.Sort((a,b) => Vector2.Distance(a.Pos, aqui).CompareTo(Vector2.Distance(b.Pos, aqui)));

        var arts = new List<Articulo>();
        foreach (var q in destinos) {
            var dest = q;
            float d = Vector2.Distance(q.Pos, aqui);
            arts.Add(new Articulo{
                Icono = R.Icono, Titulo = q.Nombre,
                Desc = Minutos(red, d) + " min · " + (Mathf.Round(d * 5.16f / 100f) / 10f) + " km",
                Precio = R.Tarifa,
                YaLoTiene = () => false,
                Comprar = () => Viajar(red, dest) });
        }
        MenuMovil.I.AbrirTienda(titulo + " · " + R.Nombre, arts);
    }

    /// <summary>Abando es las dos cosas, que es lo que pasa de verdad: allí se cambia de red.</summary>
    public static void Estacion(Sitio s) {
        if (Estado.I.Estrellas > 0) { Hud.I.Aviso("CON LA PASMA DETRÁS NO SUBES A NINGÚN SITIO"); return; }
        var redes = new List<string>();
        foreach (var r in new[]{"metro","tren","bus"}) if (s.EsDeRed(r)) redes.Add(r);
        if (redes.Count == 1) { AbrirRed(redes[0], s.Nombre, s.Pos); return; }
        var ops = new List<Opcion>();
        foreach (var r in redes) {
            var red = r;
            ops.Add(new Opcion{ Texto = Redes[red].Nombre, Accion = () => AbrirRed(red, s.Nombre, s.Pos) });
        }
        Dialogo.I.Abrir(s.Nombre, new[]{"Metro abajo, cercanías arriba. ¿Qué coges?"}, ops.ToArray());
    }
}

}
