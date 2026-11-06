package com.riberaverde.juego;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.webkit.ValueCallback;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/*
  Ribera Verde para Android: una sola pantalla con un WebView que carga el juego de assets/index.html
  (el mismo index.html del build, offline y con el atlas incrustado). Sin permisos: no usa la red.
  La partida se guarda en el localStorage del WebView. Atrás = botón B; si no hay nada que cerrar, la app pasa a segundo plano.
*/
public class MainActivity extends Activity {
    private WebView web;
    // pantalla completa inmersiva: LAYOUT_STABLE | LAYOUT_HIDE_NAVIGATION | LAYOUT_FULLSCREEN | HIDE_NAVIGATION | FULLSCREEN | IMMERSIVE_STICKY
    private static final int INMERSIVA = 0x100 | 0x200 | 0x400 | 0x2 | 0x4 | 0x1000;

    @Override
    protected void onCreate(Bundle estado) {
        super.onCreate(estado);
        getWindow().addFlags(0x80);   // FLAG_KEEP_SCREEN_ON
        web = new WebView(this);
        web.setBackgroundColor(0xff0c130f);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setMediaPlaybackRequiresUserGesture(false);
        s.setAllowFileAccess(true);
        s.setTextZoom(100);
        web.setWebViewClient(new WebViewClient());
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");
    }

    private void inmersiva() {
        getWindow().getDecorView().setSystemUiVisibility(INMERSIVA);
    }

    @Override
    public void onWindowFocusChanged(boolean foco) {
        super.onWindowFocusChanged(foco);
        if (foco) inmersiva();
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("(function(){try{if(typeof handlers!=='undefined'&&handlers.length){press('B');return 'b';}}catch(e){}return 'salir';})()",
            new ValueCallback<String>() {
                @Override
                public void onReceiveValue(String r) {
                    if (r == null || r.indexOf("salir") >= 0) moveTaskToBack(true);
                }
            });
    }

    @Override
    protected void onPause() {
        web.onPause();
        web.pauseTimers();
        super.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        web.resumeTimers();
        web.onResume();
        inmersiva();
    }

    @Override
    protected void onDestroy() {
        web.destroy();
        super.onDestroy();
    }
}
