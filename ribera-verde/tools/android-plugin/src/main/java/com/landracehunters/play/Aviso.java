package com.landracehunters.play;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;

/** El aviso de la cosecha (LandracePlay.aviso): una notificación que abre el juego. Sin el permiso, no sale nada. */
public class Aviso extends BroadcastReceiver {
    private static final String CANAL = "cosecha";

    @Override
    public void onReceive(Context c, Intent in) {
        NotificationManagerCompat nm = NotificationManagerCompat.from(c);
        if (!nm.areNotificationsEnabled()) return;
        if (Build.VERSION.SDK_INT >= 26)
            c.getSystemService(NotificationManager.class).createNotificationChannel(
                    new NotificationChannel(CANAL, "Cosecha lista", NotificationManager.IMPORTANCE_DEFAULT));
        Intent abre = c.getPackageManager().getLaunchIntentForPackage(c.getPackageName());
        PendingIntent pi = abre == null ? null : PendingIntent.getActivity(c, 0, abre, PendingIntent.FLAG_IMMUTABLE);
        NotificationCompat.Builder b = new NotificationCompat.Builder(c, CANAL)
                .setSmallIcon(c.getApplicationInfo().icon)
                .setContentTitle(in.getStringExtra("t"))
                .setContentText(in.getStringExtra("x"))
                .setAutoCancel(true)
                .setContentIntent(pi);
        try {
            nm.notify(1, b.build());
        } catch (SecurityException e) {
            // sin POST_NOTIFICATIONS
        }
    }
}
