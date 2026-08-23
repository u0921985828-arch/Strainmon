using System;
using System.Collections.Generic;
using UnityEngine;

namespace BilboCity {

public class Paso {
    public string Tipo;            // ir, irCoche, robar, entregarCoche, matar, evento
    public Vector2 Destino;
    public string Texto;
    public float Limite;
    public int Cantidad;
    public string ArqEnemigo = "maton", ArmaEnemigo = "punos";
    public Vector2 Donde;
    public int EstrellasAlEntrar;
    public Vehiculo Coche;
    public Action Evento;
}

public class DefMision {
    public string Nombre, Giver, Donde;
    public int Pago;
    public string[] Intro, Fin;
    public bool RequiereArma, RequiereFurgo;
    public Func<List<Paso>> Pasos;
}

public class MisionActiva {
    public DefMision Def;
    public List<Paso> Pasos;
    public int Idx;
    public float T, Limite;
    public Paso Actual { get { return Idx < Pasos.Count ? Pasos[Idx] : null; } }
}

/// <summary>La campaña: ocho misiones encadenadas entre Txema y el taller de Iker.</summary>
public class Misiones : MonoBehaviour {
    public static Misiones I;
    public MisionActiva Activa;
    public static List<DefMision> Lista;

    void Awake() { I = this; Construir(); }

    static Vector2 S(string id) { return Estado.Sitio_(id).Pos; }

    public static void Construir() {
        if (Lista != null) return;
        Lista = new List<DefMision> {
            new DefMision {
                Nombre="Primer recado", Giver="Txema", Donde="el Bar Zurito", Pago=150,
                Intro=new[]{"Aupa. Tú eres el del piso de arriba, ¿no?",
                            "Necesito que lleves esto al muelle. Sin abrirlo. Sin mirarlo.",
                            "Y no te pares a saludar."},
                Fin=new[]{"Puntual. Eso aquí no lo tiene nadie.","Vuelve mañana, que habrá más."},
                Pasos=() => new List<Paso>{
                    new Paso{ Tipo="ir", Destino=S("puerto"), Texto="LLEVA EL PAQUETE AL MUELLE", Limite=170 }}
            },
            new DefMision {
                Nombre="El coche de Iker", Giver="Iker", Donde="el Taller", Pago=260,
                Intro=new[]{"Hay un coche mal aparcado que ya no es de nadie.","Tráemelo entero y te lo pago."},
                Fin=new[]{"Bonito. Le doy una capa de pintura y sale otro.","Tienes mano para esto."},
                Pasos=() => {
                    var c = Juego.I.MarcarCoche(Ciudad.PuntoCalle(46,30,22));
                    return new List<Paso>{
                        new Paso{ Tipo="robar", Coche=c, Texto="ROBA EL COCHE MARCADO" },
                        new Paso{ Tipo="entregarCoche", Destino=S("taller"), Texto="LLÉVALO AL TALLER" }};
                }
            },
            new DefMision {
                Nombre="Cobrar deudas", Giver="Txema", Donde="el Bar Zurito", Pago=340,
                Intro=new[]{"Tres tipos me deben dinero y ninguno coge el teléfono.",
                            "No hace falta que los mates. Solo que se acuerden de mí."},
                Fin=new[]{"Han pagado los tres antes de comer.","Empiezas a caerme bien."},
                Pasos=() => {
                    var l = new List<Paso>();
                    for (int i = 0; i < 3; i++) {
                        var q = Ciudad.PuntoAcera(Mathf.RoundToInt(Juego.I.Jug.Pos.x), Mathf.RoundToInt(Juego.I.Jug.Pos.y), 50);
                        l.Add(new Paso{ Tipo="matar", Cantidad=1, Donde=q, ArqEnemigo="maton2", ArmaEnemigo="punos",
                                        Texto="CONVENCE AL DEUDOR " + (i+1) + " DE 3" });
                    }
                    return l;
                }
            },
            new DefMision {
                Nombre="Fuga en la Ribera", Giver="Txema", Donde="el Bar Zurito", Pago=520,
                Intro=new[]{"Hoy conduces tú.","Recógeme, aguanta lo que caiga y déjame en el piso franco."},
                Fin=new[]{"Nunca había visto conducir así por Miribilla.","Toma. Y cómprate algo que dispare."},
                Pasos=() => {
                    var franco = Ciudad.PuntoAcera(110,110,28);
                    return new List<Paso>{
                        new Paso{ Tipo="irCoche", Destino=Ciudad.PuntoAcera(Mathf.RoundToInt(Juego.I.Jug.Pos.x),
                                  Mathf.RoundToInt(Juego.I.Jug.Pos.y), 25), Texto="RECOGE A TXEMA EN COCHE" },
                        new Paso{ Tipo="evento", Evento=() => {
                            Combate.I.Estrellas(3, Juego.I); Hud.I.Aviso("¡NOS HAN VISTO! ¡CORRE!", 2.6f); } },
                        new Paso{ Tipo="irCoche", Destino=franco, Texto="LLEGA AL PISO FRANCO", Limite=130 }};
                }
            },
            new DefMision {
                Nombre="Emboscada en Zorrotzaurre", Giver="Txema", Donde="el Bar Zurito", Pago=700, RequiereArma=true,
                Intro=new[]{"Los de la otra orilla han montado una nave en Zorrotzaurre.",
                            "Ve, hazte notar y sal por tu propio pie."},
                Fin=new[]{"Media isla hablando de ti.","Esto ya no es hacer recados."},
                Pasos=() => {
                    var z = Ciudad.PuntoAcera(40,76,24);
                    return new List<Paso>{
                        new Paso{ Tipo="ir", Destino=z, Texto="VE A LA NAVE" },
                        new Paso{ Tipo="matar", Cantidad=5, Donde=z, ArqEnemigo="maton", ArmaEnemigo="pistola",
                                  Texto="LIMPIA LA NAVE" }};
                }
            },
            new DefMision {
                Nombre="La entrega grande", Giver="Iker", Donde="el Taller", Pago=900, RequiereFurgo=true,
                Intro=new[]{"Furgoneta cargada, tres paradas y el reloj corriendo.",
                            "Si te paran con eso dentro, no me conoces."},
                Fin=new[]{"Todo entregado y sin una multa.","Eres el mejor sueldo que he pagado nunca."},
                Pasos=() => {
                    var l = new List<Paso>();
                    for (int i = 0; i < 3; i++)
                        l.Add(new Paso{ Tipo="irCoche", Destino=Ciudad.PuntoAcera(),
                                        Texto="PARADA " + (i+1) + " DE 3", Limite = i == 0 ? 120 : 100 });
                    return l;
                }
            },
            new DefMision {
                Nombre="Traición", Giver="Txema", Donde="el Bar Zurito", Pago=1200,
                Intro=new[]{"Uno de los míos se ha ido de la lengua.","Está en el mercado, con dos que le cuidan."},
                Fin=new[]{"Ya está.","No me mires así. Tú también estabas allí."},
                Pasos=() => {
                    var m = S("merca");
                    return new List<Paso>{
                        new Paso{ Tipo="ir", Destino=m, Texto="VE AL MERCADO" },
                        new Paso{ Tipo="matar", Cantidad=3, Donde=m, ArqEnemigo="maton", ArmaEnemigo="pistola",
                                  Texto="ACABA CON EL CHIVATO", EstrellasAlEntrar=3 }};
                }
            },
            new DefMision {
                Nombre="El último puente", Giver="Txema", Donde="el Bar Zurito", Pago=2500,
                Intro=new[]{"Se acabó. O nosotros o ellos.","Nos vemos en el puente. Trae todo lo que tengas."},
                Fin=new[]{"Bilbao entera se ha enterado.","Yo me retiro. Tú quédate con el barrio."},
                Pasos=() => {
                    var pu = Ciudad.Buscar((x,y) => Ciudad.T(x,y) == Suelo.Puente, 64, 66, 32);
                    return new List<Paso>{
                        new Paso{ Tipo="ir", Destino=pu, Texto="SUBE AL PUENTE" },
                        new Paso{ Tipo="matar", Cantidad=7, Donde=pu, ArqEnemigo="maton", ArmaEnemigo="escopeta",
                                  Texto="AGUANTA EL ASALTO", EstrellasAlEntrar=4 },
                        new Paso{ Tipo="ir", Destino=S("bar"), Texto="VUELVE AL ZURITO", Limite=180 }};
                }
            },
        };
    }

    public DefMision Siguiente() {
        return Estado.I.MisionIdx < Lista.Count ? Lista[Estado.I.MisionIdx] : null;
    }

    public void Empezar(DefMision def) {
        Curros.I.Cancelar();
        Activa = new MisionActiva { Def = def, Pasos = def.Pasos(), Idx = 0 };
        var p = Activa.Actual;
        Activa.Limite = p.Limite;
        if (p.Tipo == "matar") GenerarEnemigos(p);
        Hud.I.Grande(def.Nombre, 2.4f);
    }

    void GenerarEnemigos(Paso p) {
        for (int i = 0; i < p.Cantidad; i++) {
            var q = Ciudad.PuntoAcera(Mathf.RoundToInt(p.Donde.x), Mathf.RoundToInt(p.Donde.y), 8);
            Juego.I.NuevoEnemigo(q, p.ArqEnemigo, p.ArmaEnemigo, true, false);
        }
        if (p.EstrellasAlEntrar > 0) Combate.I.Estrellas(p.EstrellasAlEntrar, Juego.I);
    }

    public void EnemigoAbatido() {
        var p = Activa != null ? Activa.Actual : null;
        if (p == null || p.Tipo != "matar") return;
        p.Cantidad--;
        if (p.Cantidad <= 0) Avanzar();
        else Hud.I.Aviso("QUEDAN " + p.Cantidad);
    }

    public void Avanzar() {
        if (Activa == null) return;
        Activa.Idx++;
        if (Activa.Idx >= Activa.Pasos.Count) { Terminar(true); return; }
        var p = Activa.Actual;
        Activa.Limite = p.Limite;
        Activa.T = 0;
        if (p.Tipo == "evento") { if (p.Evento != null) p.Evento(); Avanzar(); return; }
        if (p.Tipo == "matar") GenerarEnemigos(p);
        Hud.I.Aviso(p.Texto, 2.4f);
    }

    public void Terminar(bool ok) {
        if (Activa == null) return;
        var def = Activa.Def;
        if (ok) {
            Estado.I.Dinero += def.Pago;
            Estado.I.Rep["calle"] += 2;
            Estado.I.MisionIdx++;
            Hud.I.Grande("MISIÓN CUMPLIDA", 2.6f);
            AudioProc.I.Sfx("dinero", 1f);
            var lineas = new List<string>(def.Fin) { "+" + def.Pago + " €" };
            Dialogo.I.Abrir(def.Giver, lineas.ToArray(), null);
        } else Hud.I.Grande("MISIÓN FALLIDA", 2.4f);
        Juego.I.QuitarEnemigosDeMision();
        Activa = null;
        Guardado.Guardar();
    }

    public Vector2? Objetivo() {
        if (Activa == null) return null;
        var p = Activa.Actual;
        if (p == null) return null;
        if (p.Tipo == "robar") return p.Coche != null ? p.Coche.Pos : (Vector2?)null;
        return p.Destino;
    }

    public void Tic(float dt) {
        if (Activa == null) return;
        Activa.T += dt;
        if (Activa.Limite > 0 && Activa.T > Activa.Limite) {
            Hud.I.Aviso("SE TE HA ACABADO EL TIEMPO");
            Terminar(false);
            return;
        }
        var p = Activa.Actual;
        var J = Juego.I;
        float d = Vector2.Distance(p.Destino, J.Jug.Pos);
        switch (p.Tipo) {
            case "ir":            if (d < 1.7f) Avanzar(); break;
            case "irCoche":       if (d < 2.2f && J.Jug.EnCoche != null) Avanzar(); break;
            case "entregarCoche": if (d < 2.4f && J.Jug.EnCoche != null) Avanzar(); break;
            case "robar":
                if (p.Coche != null && J.Jug.EnCoche == p.Coche) {
                    p.Coche.Marcado = false; p.Coche.Propio = true; Avanzar();
                }
                break;
        }
    }
}

/// <summary>Los curros de la bolsa de trabajo del móvil.</summary>
public class Curros : MonoBehaviour {
    public static Curros I;
    public Curro Activo;
    public Vector2 Origen, Destino;
    public int Fase, Pago;
    public bool TieneDestino;

    void Awake() { I = this; }

    public void Cancelar() { Activo = null; }

    public void Aceptar(Curro c, int pago) {
        Activo = c; Pago = pago; Fase = 0; TieneDestino = true;
        var J = Juego.I;
        int px = Mathf.RoundToInt(J.Jug.Pos.x), py = Mathf.RoundToInt(J.Jug.Pos.y);
        switch (c.Id) {
            case "reparto": Origen = Estado.Sitio_("bar").Pos;  Destino = Ciudad.PuntoAcera(px,py,45); break;
            case "taxi":
            case "mudanza": Origen = Ciudad.PuntoAcera(px,py,35); Destino = Ciudad.PuntoAcera(); break;
            case "obra":    Origen = Estado.Sitio_("obra").Pos;   TieneDestino = false; break;
            case "puerto":  Origen = Estado.Sitio_("puerto").Pos; TieneDestino = false; break;
            case "lonja":   Origen = Estado.Sitio_("merca").Pos;  TieneDestino = false; break;
            case "fuga":    Origen = Ciudad.PuntoAcera(px,py,30); Destino = Ciudad.PuntoAcera(); break;
            default:        Origen = Estado.Sitio_("taller").Pos; Destino = Ciudad.PuntoAcera(); break;
        }
        Hud.I.Aviso("CURRO ACEPTADO: " + c.Titulo.ToUpperInvariant());
    }

    public Vector2? Objetivo() {
        if (Activo == null) return null;
        return Fase == 0 ? Origen : Destino;
    }

    public void Cobrar() {
        var E = Estado.I;
        string gremio = Activo.Gremio;
        E.Dinero += Pago;
        E.Rep[gremio]++;
        AudioProc.I.Sfx("dinero", 1f);
        int bonus = E.ApuntarCurro(gremio);
        if (bonus > 0) {
            Hud.I.Grande("CONTRATO CUMPLIDO", 2.6f);
            Hud.I.Aviso("+" + Pago + " €  Y BONUS DE " + bonus + " €", 3.4f);
        } else {
            var c = E.ContratoDe(gremio);
            Hud.I.Aviso(c != null ? "+" + Pago + " €  ·  " + c.Hechos + " DE " + c.Meta : "+" + Pago + " €");
        }
        Activo = null;
        Guardado.Guardar();
    }

    public void Tic(float dt) {
        if (Activo == null) return;
        var J = Juego.I;
        Vector2 o = Fase == 0 ? Origen : Destino;
        if (Vector2.Distance(o, J.Jug.Pos) > 1.6f) return;
        if (Fase == 0) {
            switch (Activo.Id) {
                case "obra":   Minijuego.I.Abrir("EN LA OBRA", 26, 22, 0.35f); Fase = 2; break;
                case "puerto": Minijuego.I.Abrir("DESCARGANDO", 34, 24, 0.42f); Fase = 2; break;
                case "lonja":  Minijuego.I.Abrir("CAJAS DE PESCADO", 20, 16, 0.22f); Fase = 2; break;
                case "taxi": case "mudanza": case "fuga":
                    if (J.Jug.EnCoche == null) Hud.I.Aviso("NECESITAS EL COCHE AQUÍ");
                    else {
                        Fase = 1;
                        Hud.I.Aviso(Activo.Id == "fuga" ? "¡ARRANCA!" : "CARGADO");
                        if (Activo.Id == "fuga") Combate.I.Estrellas(2, J);
                    }
                    break;
                default: Fase = 1; Hud.I.Aviso("RECOGIDO"); break;
            }
        } else if (Fase == 1) {
            bool necesitaCoche = Activo.Id == "taxi" || Activo.Id == "mudanza" || Activo.Id == "fuga";
            if (necesitaCoche && J.Jug.EnCoche == null) Hud.I.Aviso("LLEGA EN COCHE");
            else {
                string id = Activo.Id;
                Cobrar();
                if (id == "recado" && UnityEngine.Random.value < 0.4f) {
                    Combate.I.Estrellas(1, J);
                    Hud.I.Aviso("TE HAN FICHADO");
                }
            }
        }
    }
}

}
