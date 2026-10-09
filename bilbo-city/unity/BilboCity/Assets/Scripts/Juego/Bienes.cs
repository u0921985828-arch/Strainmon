using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

public class Propiedad {
    public string Id, Nombre, Desc, Poi, Perk;
    /// "vivienda" o "negocio".
    public string Tipo;
    public int Precio, Nivel, Renta;
}

/// <summary>Nivel de personaje, viviendas, negocios y el alquiler.
///
/// La fama por gremio ya existía y desbloquea curros, pero es local: ser bueno repartiendo
/// pintxos no dice nada de lo que has hecho en la calle. El nivel es el resumen de todo, y
/// es lo que abre las armas grandes, los coches y —sobre todo— lo que te dejan comprar.
///
/// La curva sube deprisa a propósito: el primer piso tiene que costar varios días de curro
/// y la galería, media partida. Si el dinero llega antes que el nivel, comprar deja de ser
/// una meta y pasa a ser un trámite.</summary>
public static class Bienes {

    public static int XpNivel(int n) { return Mathf.RoundToInt(140f * Mathf.Pow(n, 1.5f)); }

    public static void DarXp(int n, string motivo = null) {
        var E = Estado.I;
        E.Xp += n;
        while (E.Xp >= XpNivel(E.NivelPj)) {
            E.Xp -= XpNivel(E.NivelPj);
            E.NivelPj++;
            Hud.I.Grande("NIVEL " + E.NivelPj, 2.4f);
            AudioProc.I.Sfx("dinero", 1f);
        }
        if (motivo != null) Hud.I.Aviso("+" + n + " XP · " + motivo.ToUpperInvariant());
    }

    /// <summary>Lo gordo se desbloquea con el nivel, no solo con el dinero: un recado bien
    /// hecho vale más que un golpe de suerte.</summary>
    public static readonly Dictionary<string,int> NivelArma = new Dictionary<string,int> {
        {"uzi",4},{"escopeta",6}
    };
    public static readonly Dictionary<string,int> NivelVehiculo = new Dictionary<string,int> {
        {"furgo",2},{"deportivo",5}
    };
    public static int NivelDe(Dictionary<string,int> tabla, string id) {
        int n; return tabla.TryGetValue(id, out n) ? n : 0;
    }

    /// <summary>Las viviendas se compran en su puerta y los negocios a su dueño, dentro. No
    /// hay inmobiliaria ni menú de compra: si quieres el taller, vas al taller y se lo dices
    /// a Iker. Es lo que hace que el mapa sirva para algo más que ir a la misión.</summary>
    public static readonly List<Propiedad> Todas = new List<Propiedad> {
        new Propiedad{ Id="pisosantutxu", Nombre="Tu piso de Santutxu", Tipo="vivienda", Precio= 9000, Nivel= 2, Poi="piso",
                       Desc="El que le alquilas a Amaia. Comprarlo te quita la deuda de encima." },
        new Propiedad{ Id="pisodeustu",   Nombre="Piso en Deustu",       Tipo="vivienda", Precio=16000, Nivel= 4, Poi="pisodeustu",
                       Desc="Dos habitaciones y el metro debajo." },
        new Propiedad{ Id="loftabando",   Nombre="Loft en Abandoibarra", Tipo="vivienda", Precio=38000, Nivel= 7, Poi="loftabando",
                       Desc="Suelo de hormigón y vistas a la ría. Caro por las vistas." },
        new Propiedad{ Id="caserio",      Nombre="Caserío en Artxanda",  Tipo="vivienda", Precio=62000, Nivel= 9, Poi="caserio",
                       Desc="Arriba del todo. Nadie sube aquí sin querer subir." },
        new Propiedad{ Id="tascapozas",   Nombre="Tasca Ondarra",        Tipo="negocio",  Precio=13000, Nivel= 3, Renta= 95, Perk="comer",
                       Desc="Cuatro mesas y una barra. Se llena a la salida del turno." },
        new Propiedad{ Id="ropagranvia",  Nombre="Trapos Gran Vía",      Tipo="negocio",  Precio=22000, Nivel= 5, Renta=150, Perk="ropa",
                       Desc="Escaparate a la Gran Vía. El alquiler se lo come casi todo." },
        new Propiedad{ Id="gasodeustu",   Nombre="Gasolinera Deustu",    Tipo="negocio",  Precio=31000, Nivel= 6, Renta=215, Perk="taller",
                       Desc="Tres surtidores y la tienda. No cierra nunca." },
        new Propiedad{ Id="taller",       Nombre="Taller Iker",          Tipo="negocio",  Precio=47000, Nivel= 8, Renta=310, Perk="repintar",
                       Desc="Foso, chapa y pintura. Y lo que no se pregunta." },
        new Propiedad{ Id="galeria",      Nombre="Galería Abandoibarra", Tipo="negocio",  Precio=95000, Nivel=11, Renta=640,
                       Desc="Veinte locales alquilados. Esto ya no es un negocio, es una renta." },
        new Propiedad{ Id="almacenes",    Nombre="Almacenes Ibaizabal", Tipo="negocio", Precio=180000, Nivel=14, Renta=1150,
            Desc="Toda la esquina de la Gran Vía. Lo último que se compra, y el que paga los demás.", Perk="ropa" },
    };

    public static Propiedad PropDe(string id) { return Todas.Find(p => p.Id == id); }
    public static bool EsMio(string id) { return id != null && Estado.I.Props.Contains(id); }

    public static int RentaDiaria() {
        int t = 0;
        foreach (var p in Todas) if (EsMio(p.Id)) t += p.Renta;
        return t;
    }

    /// <summary>Falta nivel, falta dinero, o nada. El mismo texto sirve para el móvil y para
    /// el diálogo, y así no se explican de dos maneras distintas. Devuelve null si ya es
    /// tuyo y "" si se puede comprar.</summary>
    public static string PegaPara(Propiedad p) {
        var E = Estado.I;
        if (EsMio(p.Id)) return null;
        if (E.NivelPj < p.Nivel) return "Necesitas nivel " + p.Nivel;
        if (E.Dinero < p.Precio) return "Te faltan " + (p.Precio - Mathf.RoundToInt(E.Dinero)) + " €";
        return "";
    }

    public static void ComprarProp(string id) {
        var E = Estado.I;
        var p = PropDe(id);
        if (p == null) return;
        string pega = PegaPara(p);
        if (pega == null) { Hud.I.Aviso("YA ES TUYO"); return; }
        if (pega != "") { Hud.I.Aviso(pega.ToUpperInvariant()); return; }
        E.Dinero -= p.Precio;
        E.Props.Add(id);
        AudioProc.I.Sfx("dinero", 1f);
        // Comprar el piso de Santutxu es dejar de ser inquilino: se salda lo que se deba y
        // no vuelve a correr el alquiler.
        if (id == "pisosantutxu") { E.Deuda = 0; E.Alquiler = 0; }
        DarXp(Mathf.RoundToInt(p.Precio / 220f));
        Hud.I.Grande(p.Tipo == "vivienda" ? "CASA NUEVA" : "NEGOCIO COMPRADO", 2.6f);
        Hud.I.Aviso(p.Nombre.ToUpperInvariant() + " · −" + p.Precio + " €");
        Guardado.Guardar();
    }

    /// <summary>Lo que renta un negocio se cobra al dormir, como el alquiler pero al revés.</summary>
    public static int CobrarRentas() {
        int r = RentaDiaria();
        if (r > 0) { Estado.I.Dinero += r; Hud.I.Aviso("CUENTAS DEL DÍA: +" + r + " €"); }
        return r;
    }

    /// <summary>En un local tuyo no se paga: es la gracia de haberlo comprado, y se nota más
    /// que un número en una pantalla de estadísticas.</summary>
    public static bool EnLoMio() {
        return Interiores.Actual != null && EsMio(Interiores.PoiActual);
    }

    /// <summary>Una opción de compra para el diálogo del dueño. Si ya es tuyo, la casa invita.</summary>
    public static Opcion OpcionComprar(string id, string textoDentro = null) {
        var p = PropDe(id);
        if (EsMio(id))
            return new Opcion{ Texto = textoDentro ?? "Ver las cuentas",
                               Accion = () => Hud.I.Aviso(p.Nombre.ToUpperInvariant() + " ES TUYO · +" + p.Renta + " €/DÍA") };
        return new Opcion{ Texto = "¿Y si te lo compro?", Coste = p.Precio + " €", Accion = () => {
            string pega = PegaPara(p);
            if (pega != "") { Hud.I.Aviso(pega.ToUpperInvariant()); return; }
            Dialogo.I.Abrir("Trato", new[]{ p.Desc, "Son " + p.Precio + " €. ¿Cerramos?" }, new[]{
                new Opcion{ Texto="Trato hecho", Accion = () => ComprarProp(id) },
                new Opcion{ Texto="Me lo pienso" }});
        }};
    }

    // ═══════════ EL ALQUILER Y LA CASERA ═══════════
    // El alquiler era un número que subía y una frase al dormir. Ahora hay alguien al otro
    // lado: Amaia lleva la cuenta, avisa, y si no pagas te cambia la cerradura. Se puede
    // seguir durmiendo allí a la fuerza, pero eso ya es otra cosa —y se paga de otra manera.
    //
    // Estados, en orden: aldia → debiendo → avisado → desahuciado → okupa. No hay más, y
    // ninguno es un callejón sin salida: pagando se vuelve, aunque el precio de volver sube.
    public const int Semana = 7;

    public static int SemanasDebe() {
        var E = Estado.I;
        return E.Alquiler > 0 ? E.Deuda / E.Alquiler : 0;
    }

    public static string EstadoCasera() {
        var E = Estado.I;
        if (E.CaseraOkupa) return "okupa";
        if (E.CaseraDesahucio) return "desahuciado";
        if (E.CaseraAvisada) return "avisado";
        return E.Deuda > 0 ? "debiendo" : "aldia";
    }

    /// <summary>Lo que hay que soltar para volver a tener llave. La mudanza y la cerradura
    /// las paga quien las provoca.</summary>
    public static int DeudaTotal() {
        var E = Estado.I;
        return E.Deuda + (E.CaseraDesahucio ? Mathf.RoundToInt(E.Alquiler * 1.5f) : 0);
    }

    /// <summary>Se llama al dormir, una vez por día. El recibo cae cada siete.</summary>
    public static void CorrerAlquiler() {
        var E = Estado.I;
        if (E.Alquiler <= 0) return;               // piso comprado o dejado: no hay recibo
        while (E.Dia - E.UltCobro >= Semana) {
            E.UltCobro += Semana;
            E.Deuda += E.Alquiler;
            Hud.I.Aviso("RECIBO DEL ALQUILER: +" + E.Alquiler + " € DE DEUDA");
        }
        int sem = SemanasDebe();
        if (sem >= 2 && !E.CaseraAvisada && !E.CaseraDesahucio) {
            E.CaseraAvisada = true;
            E.CaseraPaciencia = Mathf.Max(0, E.CaseraPaciencia - 1);
            Hud.I.Grande("AVISO DE AMAIA", 2.4f);
            Hud.I.Aviso("«DOS MESES. EL QUE VIENE TE CAMBIO LA CERRADURA»");
        }
        if (sem >= 3 && !E.CaseraDesahucio) {
            E.CaseraDesahucio = true;
            Hud.I.Grande("TE HAN DESAHUCIADO", 2.8f);
            Hud.I.Aviso("AMAIA HA CAMBIADO LA CERRADURA DE TU PISO");
        }
    }

    /// <summary>Dormir de okupa es dormir mal, y a veces con visita.</summary>
    public static void DormirOkupa() {
        var E = Estado.I;
        E.Hp = Mathf.Min(100f, E.Hp + 18f);
        E.Energia = 0.55f;
        if (Utiles.Rnd(0f, 1f) < 0.3f) {
            Combate.I.Estrellas(1, Juego.I);
            Hud.I.Aviso("ALGUIEN HA LLAMADO A LA PASMA");
        } else Hud.I.Aviso("HAS DORMIDO EN EL SUELO. DÍA " + E.Dia);
    }

    public static void PagarCasera() {
        var E = Estado.I;
        int t = DeudaTotal();
        if (t <= 0) {
            // Pagar por adelantado no es tirar el dinero: la casera se ablanda, y con ella
            // al día es cuando se puede hablar de comprarle el piso.
            if (E.Dinero < E.Alquiler) { Hud.I.Aviso("NO TE LLEGA NI PARA ADELANTAR UN MES"); return; }
            E.Dinero -= E.Alquiler;
            E.UltCobro += Semana;
            E.CaseraPaciencia = Mathf.Min(5, E.CaseraPaciencia + 1);
            AudioProc.I.Sfx("dinero", 1f);
            Hud.I.Aviso("UN MES POR ADELANTADO. −" + E.Alquiler + " €");
            Guardado.Guardar();
            return;
        }
        if (E.Dinero < t) { Hud.I.Aviso("SON " + t + " € Y NO LOS TIENES"); return; }
        E.Dinero -= t; E.Deuda = 0;
        bool volvia = E.CaseraDesahucio;
        E.CaseraDesahucio = false; E.CaseraOkupa = false; E.CaseraAvisada = false;
        AudioProc.I.Sfx("dinero", 1f);
        Hud.I.Aviso(volvia ? "LLAVE NUEVA. −" + t + " €" : "ALQUILER AL DÍA. −" + t + " €");
        Guardado.Guardar();
    }

    /// <summary>Dejar el piso: se acaba el recibo y se acaba la cama. Es la salida limpia
    /// para quien ya se ha comprado otra cosa.</summary>
    public static void DejarPiso() {
        var E = Estado.I;
        if (E.Deuda > 0) { Hud.I.Aviso("PRIMERO PAGA LO QUE DEBES"); return; }
        E.Alquiler = 0; E.CaseraDesahucio = true; E.CaseraOkupa = false;
        Hud.I.Aviso("LE HAS DEJADO LAS LLAVES A AMAIA");
        Guardado.Guardar();
    }

    /// <summary>Forzar la puerta de tu antiguo piso. Es un delito y se oye.</summary>
    public static void Ocupar() {
        var J = Juego.I;
        Sigilo.Ruido(J.Jug.Pos, 8f);
        Estado.I.CaseraOkupa = true;
        Sigilo.Delito(1, true);
        Hud.I.Aviso("HAS FORZADO LA PUERTA. AHORA ERES EL OKUPA");
        Guardado.Guardar();
    }
}

}
