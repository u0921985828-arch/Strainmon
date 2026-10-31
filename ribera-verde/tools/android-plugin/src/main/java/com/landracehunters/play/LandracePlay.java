package com.landracehunters.play;

import android.Manifest;
import android.app.Activity;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;
import com.google.android.gms.games.PlayGames;
import com.google.android.gms.games.PlayGamesSdk;
import com.google.android.gms.games.SnapshotsClient;
import com.google.android.gms.games.snapshot.Snapshot;
import com.google.android.gms.games.snapshot.SnapshotMetadataChange;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import io.sentry.Breadcrumb;
import io.sentry.Sentry;
import io.sentry.android.core.SentryAndroid;

/**
 * Landrace Hunters · fase 6 (U7, U10, U11): la compra única (Play Billing), los logros y la nube (Play Games v2), el aviso local de la
 * cosecha y los informes de errores (Sentry, solo con el opt-in). Lo usa godot/src/plataforma.gd; las señales: compra(estado),
 * comprado(producto), permiso(ok), nube(datos).
 */
public class LandracePlay extends GodotPlugin implements PurchasesUpdatedListener {
    private static final String TAG = "LandracePlay";
    private static final int PIDE_AVISOS = 7301;
    private BillingClient billing;
    private boolean games = false;
    private boolean sentry = false;

    public LandracePlay(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "LandracePlay";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> s = new HashSet<>();
        s.add(new SignalInfo("compra", String.class));
        s.add(new SignalInfo("comprado", String.class));
        s.add(new SignalInfo("permiso", Boolean.class));
        s.add(new SignalInfo("nube", String.class));
        return s;
    }

    private Context ctx() {
        Activity a = getActivity();
        return a != null ? a.getApplicationContext() : null;
    }

    // ---------- arranque: Billing siempre; Play Games solo con el APP_ID puesto ----------
    @UsedByGodot
    public void conectar(boolean conGames) {
        Activity a = getActivity();
        if (a == null) return;
        if (conGames && !games) {
            try {
                PlayGamesSdk.initialize(a);
                games = true;
            } catch (Exception e) {
                Log.w(TAG, "Play Games", e);
            }
        }
        billing = BillingClient.newBuilder(a)
                .setListener(this)
                .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
                .build();
        billing.startConnection(new BillingClientStateListener() {
            @Override
            public void onBillingSetupFinished(@NonNull BillingResult r) {
                if (r.getResponseCode() == BillingClient.BillingResponseCode.OK) consultar();
            }

            @Override
            public void onBillingServiceDisconnected() {
            }
        });
    }

    // ---------- compra única ----------
    @UsedByGodot
    public void comprar(String producto) {
        if (billing == null || !billing.isReady()) {
            emitSignal("compra", "error");
            return;
        }
        QueryProductDetailsParams q = QueryProductDetailsParams.newBuilder()
                .setProductList(Collections.singletonList(QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(producto).setProductType(BillingClient.ProductType.INAPP).build()))
                .build();
        billing.queryProductDetailsAsync(q, (r, lista) -> {
            List<ProductDetails> l = lista;
            if (r.getResponseCode() != BillingClient.BillingResponseCode.OK || l == null || l.isEmpty()) {
                emitSignal("compra", "error");
                return;
            }
            BillingFlowParams p = BillingFlowParams.newBuilder()
                    .setProductDetailsParamsList(Collections.singletonList(
                            BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(l.get(0)).build()))
                    .build();
            Activity a = getActivity();
            if (a == null) {
                emitSignal("compra", "error");
                return;
            }
            a.runOnUiThread(() -> {
                BillingResult br = billing.launchBillingFlow(a, p);
                if (br.getResponseCode() != BillingClient.BillingResponseCode.OK) emitSignal("compra", "error");
            });
        });
    }

    @Override
    public void onPurchasesUpdated(@NonNull BillingResult r, List<Purchase> compras) {
        int c = r.getResponseCode();
        if (c == BillingClient.BillingResponseCode.OK && compras != null) {
            boolean ok = false, pendiente = false;
            for (Purchase p : compras) {
                if (p.getPurchaseState() == Purchase.PurchaseState.PURCHASED) {
                    reconoce(p);
                    ok = true;
                } else if (p.getPurchaseState() == Purchase.PurchaseState.PENDING) {
                    pendiente = true;
                }
            }
            emitSignal("compra", ok ? "ok" : (pendiente ? "pendiente" : "error"));
        } else if (c == BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED) {
            consultar();
            emitSignal("compra", "ok");
        } else if (c == BillingClient.BillingResponseCode.USER_CANCELED) {
            emitSignal("compra", "cancelada");
        } else {
            emitSignal("compra", "error");
        }
    }

    // una compra sin reconocer en 3 días se devuelve sola
    private void reconoce(Purchase p) {
        for (String id : p.getProducts()) emitSignal("comprado", id);
        if (p.isAcknowledged()) return;
        billing.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(p.getPurchaseToken()).build(), r -> {
        });
    }

    @UsedByGodot
    public void consultar() {
        if (billing == null || !billing.isReady()) return;
        billing.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build(), (r, l) -> {
            if (r.getResponseCode() != BillingClient.BillingResponseCode.OK) return;
            for (Purchase p : l)
                if (p.getPurchaseState() == Purchase.PurchaseState.PURCHASED) reconoce(p);
        });
    }

    // ---------- Play Games ----------
    @UsedByGodot
    public void logro(String id) {
        Activity a = getActivity();
        if (!games || a == null || id.isEmpty()) return;
        try {
            PlayGames.getAchievementsClient(a).unlock(id);
        } catch (Exception e) {
            Log.w(TAG, "logro", e);
        }
    }

    @UsedByGodot
    public void nube_guarda(String nombre, String datos) {
        Activity a = getActivity();
        if (!games || a == null) return;
        SnapshotsClient sc = PlayGames.getSnapshotsClient(a);
        sc.open(nombre, true, SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED).addOnSuccessListener(dc -> {
            Snapshot s = dc.getData();
            if (s == null) return;
            s.getSnapshotContents().writeBytes(datos.getBytes(StandardCharsets.UTF_8));
            sc.commitAndClose(s, new SnapshotMetadataChange.Builder().setDescription("Landrace Hunters").build());
        }).addOnFailureListener(e -> Log.w(TAG, "nube_guarda", e));
    }

    @UsedByGodot
    public void nube_carga(String nombre) {
        Activity a = getActivity();
        if (!games || a == null) {
            emitSignal("nube", "");
            return;
        }
        SnapshotsClient sc = PlayGames.getSnapshotsClient(a);
        sc.open(nombre, false, SnapshotsClient.RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED).addOnSuccessListener(dc -> {
            Snapshot s = dc.getData();
            String t = "";
            try {
                if (s != null) t = new String(s.getSnapshotContents().readFully(), StandardCharsets.UTF_8);
            } catch (Exception e) {
                Log.w(TAG, "nube_carga", e);
            }
            if (s != null) sc.discardAndClose(s);
            emitSignal("nube", t);
        }).addOnFailureListener(e -> emitSignal("nube", ""));
    }

    // ---------- aviso local de la cosecha ----------
    @UsedByGodot
    public void permiso_avisos() {
        Activity a = getActivity();
        if (a == null) {
            emitSignal("permiso", false);
            return;
        }
        if (Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(a, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            emitSignal("permiso", true);
            return;
        }
        ActivityCompat.requestPermissions(a, new String[]{Manifest.permission.POST_NOTIFICATIONS}, PIDE_AVISOS);
    }

    @Override
    public void onMainRequestPermissionsResult(int code, String[] permisos, int[] res) {
        if (code == PIDE_AVISOS)
            emitSignal("permiso", res.length > 0 && res[0] == PackageManager.PERMISSION_GRANTED);
    }

    private PendingIntent pi(Context c, String titulo, String texto) {
        Intent i = new Intent(c, Aviso.class).putExtra("t", titulo).putExtra("x", texto);
        return PendingIntent.getBroadcast(c, 1, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    @UsedByGodot
    public void aviso(int segundos, String titulo, String texto) {
        Context c = ctx();
        if (c == null) return;
        AlarmManager am = (AlarmManager) c.getSystemService(Context.ALARM_SERVICE);
        // inexacta (sin SCHEDULE_EXACT_ALARM): unos minutos arriba o abajo da igual para una cosecha
        am.set(AlarmManager.RTC, System.currentTimeMillis() + segundos * 1000L, pi(c, titulo, texto));
    }

    @UsedByGodot
    public void sin_aviso() {
        Context c = ctx();
        if (c == null) return;
        ((AlarmManager) c.getSystemService(Context.ALARM_SERVICE)).cancel(pi(c, "", ""));
    }

    // ---------- informes de errores (opt-in) ----------
    @UsedByGodot
    public void errores(boolean on, String dsn) {
        Context c = ctx();
        if (on && !sentry && c != null && !dsn.isEmpty()) {
            SentryAndroid.init(c, o -> {
                o.setDsn(dsn);
                o.setSendDefaultPii(false);
                o.setAttachScreenshot(false);
                o.setAttachViewHierarchy(false);
                o.setEnableUserInteractionBreadcrumbs(false);
            });
            sentry = true;
        } else if (!on && sentry) {
            Sentry.close();
            sentry = false;
        }
    }

    @UsedByGodot
    public void evento(String k) {
        if (!sentry) return;
        Breadcrumb b = new Breadcrumb();
        b.setCategory("embudo");
        b.setMessage(k);
        Sentry.addBreadcrumb(b);
    }
}
