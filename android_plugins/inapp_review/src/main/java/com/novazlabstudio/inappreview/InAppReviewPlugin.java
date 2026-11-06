package com.novazlabstudio.inappreview;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.google.android.play.core.review.ReviewInfo;
import com.google.android.play.core.review.ReviewManager;
import com.google.android.play.core.review.ReviewManagerFactory;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Google Play'in oyun içi değerlendirme penceresini açar (ücretsiz Play In-App Review API).
 * Pencerenin gösterilip gösterilmeyeceğine Google karar verir (kota); oyuncu puan verdi mi
 * bilgisi uygulamaya verilmez. Bu yüzden sinyal yalnızca "akış bitti" der.
 */
public class InAppReviewPlugin extends GodotPlugin {

    public InAppReviewPlugin(Godot godot) {
        super(godot);
    }

    @NonNull
    @Override
    public String getPluginName() {
        return "InAppReview";
    }

    @NonNull
    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> signals = new HashSet<>();
        signals.add(new SignalInfo("review_flow_finished", Boolean.class));
        return signals;
    }

    @UsedByGodot
    public void requestReview() {
        final Activity activity = getActivity();
        if (activity == null) {
            emitSignal("review_flow_finished", false);
            return;
        }
        activity.runOnUiThread(() -> {
            try {
                final ReviewManager manager = ReviewManagerFactory.create(activity);
                manager.requestReviewFlow().addOnCompleteListener(task -> {
                    if (!task.isSuccessful()) {
                        emitSignal("review_flow_finished", false);
                        return;
                    }
                    ReviewInfo info = task.getResult();
                    manager.launchReviewFlow(activity, info)
                            .addOnCompleteListener(done -> emitSignal("review_flow_finished", true));
                });
            } catch (Exception e) {
                emitSignal("review_flow_finished", false);
            }
        });
    }
}
