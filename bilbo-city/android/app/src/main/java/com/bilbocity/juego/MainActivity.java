package com.bilbocity.juego;

import android.app.Activity;
import android.os.Build;
import android.os.Bundle;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.webkit.WebSettings;
import android.webkit.WebView;

/**
 * El juego entero vive en el HTML. Esto solo lo aloja: un WebView a pantalla completa,
 * apaisado, sin barras y sin que la pantalla se apague mientras se juega.
 *
 * No hay puente de JavaScript a Java a propósito. La parte nativa no le da nada al juego
 * que el juego no tuviera ya en un navegador, así que no hay superficie que asegurar.
 */
public class MainActivity extends Activity {

    private WebView web;

    @Override
    protected void onCreate(Bundle estado) {
        super.onCreate(estado);

        // Un juego que se apaga solo a los treinta segundos de mirar el mapa no es un juego.
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        aPantallaCompleta();

        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        // El juego guarda la partida en localStorage cuando no hay window.storage. Sin esto
        // la escritura falla en silencio y se pierde la partida al salir.
        s.setDomStorageEnabled(true);
        // El sonido se sintetiza con Web Audio. Sin esto el AudioContext nace suspendido y
        // no suena nada hasta el segundo toque, que se lee como que el juego no tiene audio.
        s.setMediaPlaybackRequiresUserGesture(false);
        // Es pixel art: el lienzo va a resolución baja y se escala en entero. Dejar que el
        // WebView reescale la página rompe esa cuenta y salen píxeles de tamaños distintos.
        s.setUseWideViewPort(false);
        s.setLoadWithOverviewMode(false);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);

        web.setBackgroundColor(0xFF0B0E11);
        web.setLongClickable(false);
        web.setHapticFeedbackEnabled(false);
        // Sin scroll ni efecto de rebote: el mundo lo mueve el juego, no el dedo sobre la página.
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setVerticalScrollBarEnabled(false);
        web.setHorizontalScrollBarEnabled(false);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            WebView.setWebContentsDebuggingEnabled(true);
        }

        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
    }

    /** Sin barra de estado ni de navegación: la pantalla del móvil es pequeña y el mando ocupa. */
    private void aPantallaCompleta() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            getWindow().setDecorFitsSystemWindows(false);
            WindowInsetsController c = getWindow().getInsetsController();
            if (c != null) {
                c.hide(WindowInsets.Type.systemBars());
                c.setSystemBarsBehavior(
                        WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
            }
        } else {
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }

    @Override
    public void onWindowFocusChanged(boolean tieneFoco) {
        super.onWindowFocusChanged(tieneFoco);
        // Al volver de la barra de notificaciones las barras reaparecen: hay que esconderlas otra vez.
        if (tieneFoco) aPantallaCompleta();
    }

    @Override
    protected void onPause() {
        super.onPause();
        // Sin esto el bucle y el audio siguen corriendo con la app en segundo plano.
        if (web != null) { web.onPause(); web.pauseTimers(); }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (web != null) { web.resumeTimers(); web.onResume(); }
    }

    @Override
    protected void onDestroy() {
        if (web != null) { web.destroy(); web = null; }
        super.onDestroy();
    }
}
