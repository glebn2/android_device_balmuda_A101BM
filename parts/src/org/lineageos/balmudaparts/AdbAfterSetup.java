/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.balmudaparts;

import android.content.ContentResolver;
import android.content.Context;
import android.content.SharedPreferences;
import android.database.ContentObserver;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.util.Log;

import androidx.preference.PreferenceManager;

/**
 * USB debugging turns itself on, but only after the setup wizard: otherwise on first boot with a cable
 * the computer authorization prompt covers the wizard. Runs once on a clean install; if the wizard is
 * already done (an update), the user's choice is kept.
 */
final class AdbAfterSetup {
    private static final String TAG = "BalmudaParts";
    private static final String KEY_STATE = "adb_after_setup";
    private static final String STATE_PENDING = "pending";
    private static final String STATE_DONE = "done";

    private AdbAfterSetup() {
    }

    static void start(Context context) {
        final SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(context);
        final String state = prefs.getString(KEY_STATE, null);
        if (STATE_DONE.equals(state)) {
            return;
        }
        final ContentResolver resolver = context.getContentResolver();
        if (isSetupComplete(resolver)) {
            // Wizard finished while the process was not running (pending), or this is an update (null)
            finish(resolver, prefs, STATE_PENDING.equals(state));
            return;
        }
        prefs.edit().putString(KEY_STATE, STATE_PENDING).apply();
        resolver.registerContentObserver(
                Settings.Secure.getUriFor(Settings.Secure.USER_SETUP_COMPLETE), false,
                new ContentObserver(new Handler(Looper.getMainLooper())) {
                    @Override
                    public void onChange(boolean selfChange) {
                        if (isSetupComplete(resolver)) {
                            resolver.unregisterContentObserver(this);
                            finish(resolver, prefs, true);
                        }
                    }
                });
    }

    private static boolean isSetupComplete(ContentResolver resolver) {
        return Settings.Secure.getInt(resolver, Settings.Secure.USER_SETUP_COMPLETE, 0) != 0;
    }

    private static void finish(ContentResolver resolver, SharedPreferences prefs, boolean enable) {
        if (enable) {
            Settings.Global.putInt(resolver, Settings.Global.ADB_ENABLED, 1);
            Log.i(TAG, "setup finished: USB debugging on");
        }
        prefs.edit().putString(KEY_STATE, STATE_DONE).apply();
    }
}
