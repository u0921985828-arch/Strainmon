using System;
using System.Collections.Generic;

namespace BilboCity {

/// <summary>Una frase del parroquiano: su etiqueta —la condición, que es código— y su
/// texto, que es redacción. `herramientas/plano/reglas.py` carea las etiquetas con las
/// del HTML y jamás los textos: aquí se puede escribir con otras palabras sin que el
/// juego cambie, pero una frase que falte sí lo cambia.</summary>
public class FraseParroquiano {
    public string Etiqueta;
    public Func<bool> Si;      // null = charla de barra, vale siempre
    public string Texto;
}

/// <summary>Lo que cuenta el de la barra. Es la única boca del juego que no vende nada
/// ni manda a ningún sitio, así que es donde cabe contar cómo va la partida. Eran cinco
/// frases al azar: a la tercera tasca te las sabías, y ninguna se enteraba de que
/// entrabas sangrando, con tres estrellas y debiendo dos recibos.
///
/// El reparto tres de cuatro a favor de lo concreto no es un capricho: en el mismo saco
/// que las doce de charla, con dos o tres condiciones ciertas, lo concreto salía una de
/// cada seis y el parroquiano volvía a parecer una máquina de refranes.</summary>
public static class Parroquiano {
    public const float Contexto = .75f;

    static Estado E { get { return Estado.I; } }

    public static readonly FraseParroquiano[] Frases = {
        F("barra", "El puente viejo se cierra cuando la pasma se pone seria."),
        F("barra", "En el hospital te cosen por dinero y sin preguntas."),
        F("barra", "Koldo vende cosas que no salen en el escaparate."),
        F("barra", "Si te escondes y no te ven un rato, se olvidan de ti."),
        F("barra", "Iker repinta coches. Eso quita una estrella."),
        F("barra", "Agachado se ve menos. Mirar una esquina es gratis; doblarla, no."),
        F("barra", "De noche se ve la mitad. Eso vale para ellos y para ti."),
        F("barra", "En el metro no te dejan subir si te buscan."),
        F("barra", "Txema no manda a nadie ahí fuera con las manos vacías."),
        F("barra", "Cambiarte de ropa despista. La descripción deja de valer."),
        F("barra", "Aquí se bebe de pie. El que se sienta es que espera a alguien."),
        F("barra", "La ría separa más que el mapa. Para cruzar, al puente."),
        F("buscado",   () => E.Estrellas > 0, "Baja la voz. Por la puerta no ha pasado una patrulla, han pasado tres."),
        F("buscado",   () => E.Estrellas > 0, "Quédate quieto. Se cansan antes ellos que tú."),
        F("acosado",   () => E.Estrellas >= 3, "Lo tuyo ya no es una multa. Lo tuyo sale por la emisora."),
        F("noche",     () => Sigilo.EsDeNoche(), "A estas horas, el que anda por la calle es que no quiere ir a casa."),
        F("noche",     () => Sigilo.EsDeNoche(), "Cierro cuando se vaya el último. Hoy pareces tú."),
        F("manana",    () => E.Min < 10*60, "Café y a currar. El que empieza el día en la barra lo acaba aquí."),
        F("deuda",     () => E.Deuda > 0, "Amaia pregunta por ti. Sin mala idea, pero pregunta."),
        F("desahucio", () => E.CaseraDesahucio, "Te han cambiado la cerradura. Aquí se sabe antes que en el portal."),
        F("okupa",     () => E.CaseraOkupa, "Dormir en tu propia casa sin llave tiene delito. Literalmente."),
        F("pobre",     () => E.Dinero < 20, "Si no te llega para el zurito, el agua de la barra es gratis."),
        F("rico",      () => E.Dinero >= 3000, "Con lo que llevas encima ya no hace falta que robes nada."),
        F("hambre",    () => E.Hambre < .35f, "Come algo. Luego andas lento, y lento te cogen."),
        F("herido",    () => E.Hp < 45, "Esa pinta no es de resaca. En Basurto no preguntan."),
        F("mision",    () => Misiones.I != null && Misiones.I.Activa != null, "Tienes cara de que te esperan en otro sitio."),
        F("nivel",     () => E.NivelPj >= 4, "Ya no eres el chaval que entró preguntando por Txema."),
        F("casero",    () => E.Props.Count > 0, "Dicen que ahora tienes local. Enhorabuena y que dure."),
        F("hierro",    () => E.TieneArmaFuego(), "Eso de la cazadora se nota. Siéntate de espaldas a la pared."),
        F("silencio",  () => E.TieneSilenciador, "Un hierro que no suena no es más seguro. Es que te confías."),
        F("deportivo", () => E.TieneDeportivo, "Ese coche lo oye medio barrio. Para algo discreto, coge el bus."),
        F("furgo",     () => E.TieneFurgo, "Con furgoneta hay curro de verdad. Lo que pesa paga mejor."),
        F("rutina",    () => E.Dia >= 10, "Llevas aquí lo tuyo ya. Antes ni saludabas."),
        F("fama",      () => E.Rep["calle"] >= 4, "Por la calle te conocen. Eso abre puertas y cierra otras."),
    };

    static FraseParroquiano F(string t, string l) {
        return new FraseParroquiano { Etiqueta = t, Texto = l };
    }
    static FraseParroquiano F(string t, Func<bool> si, string l) {
        return new FraseParroquiano { Etiqueta = t, Si = si, Texto = l };
    }

    static string _ult = "";

    /// <summary>Nunca dos veces seguidas la misma, y por eso se descarta la última de los
    /// dos sacos antes de elegir y no después: con una sola condición cierta, el saco de
    /// lo concreto tiene una frase, y filtrar al final lo dejaba vacío y obligaba a
    /// repetirla. Si eso pasa se dice una de barra, que de esas siempre quedan once.</summary>
    public static string Frase() {
        var con = new List<FraseParroquiano>();
        var barra = new List<FraseParroquiano>();
        foreach (var f in Frases) {
            if (f.Texto == _ult) continue;
            if (f.Si == null) barra.Add(f);
            else if (f.Si()) con.Add(f);
        }
        var b = (con.Count > 0 && Utiles.Rnd(0f, 1f) < Contexto) ? con
              : (barra.Count > 0 ? barra : con);
        _ult = b[Utiles.RndI(0, b.Count - 1)].Texto;
        return _ult;
    }
}

}
