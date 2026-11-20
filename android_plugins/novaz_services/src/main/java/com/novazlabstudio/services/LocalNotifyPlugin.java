package com.novazlabstudio.services;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.annotation.NonNull;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Cihazda zamanlanan yerel bildirimler (sunucu / Firebase yok). AlarmManager ile kesin olmayan
 * (inexact) alarm kurulur; özel izin (SCHEDULE_EXACT_ALARM) gerekmez. Android 13+ için
 * POST_NOTIFICATIONS izni oyuncuya sorulur.
 */
public class LocalNotifyPlugin extends GodotPlugin {
    private static final int RC_PERM = 9302;

    public LocalNotifyPlugin(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "LocalNotify";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("permission_result", Boolean.class));
        return signals;
    }

    @UsedByGodot
    public boolean hasPermission() {
        Activity a = getActivity();
        if (a == null) return false;
        if (Build.VERSION.SDK_INT >= 33) {
            return a.checkSelfPermission("android.permission.POST_NOTIFICATIONS") == PackageManager.PERMISSION_GRANTED;
        }
        NotificationManager nm = (NotificationManager) a.getSystemService(Context.NOTIFICATION_SERVICE);
        return nm == null || nm.areNotificationsEnabled();
    }

    @UsedByGodot
    public void requestPermission() {
        Activity a = getActivity();
        if (a == null) return;
        if (Build.VERSION.SDK_INT >= 33 && !hasPermission()) {
            a.requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, RC_PERM);
        } else {
            emitSignal("permission_result", hasPermission());
        }
    }

    @Override
    public void onMainRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == RC_PERM) {
            boolean ok = grantResults != null && grantResults.length > 0
                    && grantResults[0] == PackageManager.PERMISSION_GRANTED;
            emitSignal("permission_result", ok);
        }
    }

    private PendingIntent pending(Context ctx, int id, String title, String body) {
        Intent i = new Intent(ctx, NotifyReceiver.class);
        i.putExtra("id", id);
        i.putExtra("title", title);
        i.putExtra("body", body);
        return PendingIntent.getBroadcast(ctx, id, i,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
    }

    /** delaySeconds sonra bildirim göster. Aynı id tekrar zamanlanırsa eskisinin yerine geçer. */
    @UsedByGodot
    public void schedule(int id, String title, String body, int delaySeconds) {
        Activity a = getActivity();
        if (a == null || delaySeconds <= 0) return;
        Context ctx = a.getApplicationContext();
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am == null) return;
        long at = System.currentTimeMillis() + delaySeconds * 1000L;
        am.set(AlarmManager.RTC, at, pending(ctx, id, title, body));
    }

    @UsedByGodot
    public void cancel(int id) {
        Activity a = getActivity();
        if (a == null) return;
        Context ctx = a.getApplicationContext();
        AlarmManager am = (AlarmManager) ctx.getSystemService(Context.ALARM_SERVICE);
        if (am != null) am.cancel(pending(ctx, id, "", ""));
        NotificationManager nm = (NotificationManager) ctx.getSystemService(Context.NOTIFICATION_SERVICE);
        if (nm != null) nm.cancel(id);
    }
}
