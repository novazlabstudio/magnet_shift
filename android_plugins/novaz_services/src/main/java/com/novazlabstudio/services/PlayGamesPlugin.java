package com.novazlabstudio.services;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.games.GamesSignInClient;
import com.google.android.gms.games.PlayGames;
import com.google.android.gms.games.PlayGamesSdk;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Google Play Games Services v2: otomatik giriş, sıralama (leaderboard) ve başarımlar.
 * Sunucu gerektirmez; skorları Google saklar. APP_ID tanımlı değilse hiçbir şey yapmaz
 * (oyun Play Games olmadan da aynen çalışır).
 */
public class PlayGamesPlugin extends GodotPlugin {
    private static final String TAG = "PlayGamesV2";
    private static final int RC_UI = 9301;
    private boolean configured = false;
    private boolean initialized = false;
    private boolean authenticated = false;

    public PlayGamesPlugin(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "PlayGamesV2";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("sign_in_result", Boolean.class));
        return signals;
    }

    @Nullable
    @Override
    public View onMainCreate(Activity activity) {
        try {
            ApplicationInfo ai = activity.getPackageManager().getApplicationInfo(
                    activity.getPackageName(), PackageManager.GET_META_DATA);
            Bundle md = ai.metaData;
            Object id = md != null ? md.get("com.google.android.gms.games.APP_ID") : null;
            String s = id != null ? String.valueOf(id).trim() : "";
            configured = s.length() > 0 && !s.equals("0");
        } catch (Exception e) {
            configured = false;
        }
        if (configured) {
            try {
                PlayGamesSdk.initialize(activity);
                initialized = true;
            } catch (Exception e) {
                Log.w(TAG, "init failed", e);
            }
        }
        return null;
    }

    @UsedByGodot
    public boolean isConfigured() {
        return configured && initialized;
    }

    @UsedByGodot
    public boolean isAuthenticated() {
        return authenticated;
    }

    /** Sessiz kontrol: Play Games v2 oyuna girişte otomatik oturum açmayı dener. */
    @UsedByGodot
    public void checkSignIn() {
        final Activity a = getActivity();
        if (a == null || !isConfigured()) {
            emitSignal("sign_in_result", false);
            return;
        }
        a.runOnUiThread(() -> {
            GamesSignInClient c = PlayGames.getGamesSignInClient(a);
            c.isAuthenticated().addOnCompleteListener(t -> {
                authenticated = t.isSuccessful() && t.getResult().isAuthenticated();
                emitSignal("sign_in_result", authenticated);
            });
        });
    }

    /** Oyuncu bir Play Games düğmesine bastığında: gerekirse giriş penceresini açar. */
    @UsedByGodot
    public void signIn() {
        final Activity a = getActivity();
        if (a == null || !isConfigured()) {
            emitSignal("sign_in_result", false);
            return;
        }
        a.runOnUiThread(() -> PlayGames.getGamesSignInClient(a).signIn().addOnCompleteListener(t -> {
            authenticated = t.isSuccessful() && t.getResult().isAuthenticated();
            emitSignal("sign_in_result", authenticated);
        }));
    }

    @UsedByGodot
    public void submitScore(String leaderboardId, int score) {
        final Activity a = getActivity();
        if (a == null || !authenticated || leaderboardId.isEmpty()) return;
        a.runOnUiThread(() -> {
            try {
                PlayGames.getLeaderboardsClient(a).submitScore(leaderboardId, score);
            } catch (Exception e) {
                Log.w(TAG, "submitScore", e);
            }
        });
    }

    @UsedByGodot
    public void unlockAchievement(String achievementId) {
        final Activity a = getActivity();
        if (a == null || !authenticated || achievementId.isEmpty()) return;
        a.runOnUiThread(() -> {
            try {
                PlayGames.getAchievementsClient(a).unlock(achievementId);
            } catch (Exception e) {
                Log.w(TAG, "unlock", e);
            }
        });
    }

    /** leaderboardId boşsa tüm sıralamaların listesi açılır. */
    @UsedByGodot
    public void showLeaderboard(String leaderboardId) {
        final Activity a = getActivity();
        if (a == null || !authenticated) return;
        a.runOnUiThread(() -> {
            if (leaderboardId.isEmpty()) {
                PlayGames.getLeaderboardsClient(a).getAllLeaderboardsIntent()
                        .addOnSuccessListener(i -> startUi(a, i));
            } else {
                PlayGames.getLeaderboardsClient(a).getLeaderboardIntent(leaderboardId)
                        .addOnSuccessListener(i -> startUi(a, i));
            }
        });
    }

    @UsedByGodot
    public void showAchievements() {
        final Activity a = getActivity();
        if (a == null || !authenticated) return;
        a.runOnUiThread(() -> PlayGames.getAchievementsClient(a).getAchievementsIntent()
                .addOnSuccessListener(i -> startUi(a, i)));
    }

    private void startUi(Activity a, Intent i) {
        try {
            a.startActivityForResult(i, RC_UI);
        } catch (Exception e) {
            Log.w(TAG, "ui", e);
        }
    }
}
