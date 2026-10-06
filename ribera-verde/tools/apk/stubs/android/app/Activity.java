package android.app;
public class Activity extends android.content.Context {
    protected void onCreate(android.os.Bundle b) {}
    protected void onPause() {}
    protected void onResume() {}
    protected void onDestroy() {}
    public void onWindowFocusChanged(boolean f) {}
    public void onBackPressed() {}
    public void setContentView(android.view.View v) {}
    public android.view.Window getWindow() { return null; }
    public boolean moveTaskToBack(boolean nonRoot) { return false; }
}
