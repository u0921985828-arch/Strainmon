package android.webkit;
public class WebView extends android.view.View {
    public WebView(android.content.Context c) { super(c); }
    public WebSettings getSettings() { return null; }
    public void setWebViewClient(WebViewClient c) {}
    public void loadUrl(String url) {}
    public void evaluateJavascript(String script, ValueCallback<String> cb) {}
    public void onPause() {}
    public void onResume() {}
    public void pauseTimers() {}
    public void resumeTimers() {}
    public void destroy() {}
}
