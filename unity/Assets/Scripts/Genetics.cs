// Genética / cruces. Si el conjunto de parentales coincide con un nodo del árbol
// filogenético -> nace esa cepa NOMBRADA (cruce canónico). Si no, híbrido
// procedural: stats media + varianza, tipo/color heredados, tier+1.
using UnityEngine;

public static class Genetics
{
    public static Strain Cross(Strain a, Strain b, StrainDatabase db)
    {
        if (a == null || b == null) return null;
        var canon = db != null ? db.CanonicalCross(a.id, b.id) : null;
        if (canon != null) return canon;

        var child = new Strain
        {
            id = "hybrid_" + a.id + "_" + b.id,
            name = a.name + " × " + b.name,
            type = (a.type == b.type) ? a.type : "hybrid",
            color = a.color,
            tier = Mathf.Max(a.tier, b.tier) + 1,
            altura = Avg(a.altura, b.altura),
            produccion = Avg(a.produccion, b.produccion),
            resina = Avg(a.resina, b.resina),
            vigor = Avg(a.vigor, b.vigor),
            parents = new string[] { a.id, b.id },
            biomes = new string[0],
        };
        return child;
    }

    static int Avg(int x, int y) => Mathf.Clamp(Mathf.RoundToInt((x + y) / 2f) + Random.Range(-4, 5), 0, 100);
}
