/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.balmudaparts;

import android.content.Context;
import android.os.PowerManager;
import android.os.SystemClock;
import android.util.Log;
import android.view.KeyEvent;

import com.android.internal.os.DeviceKeyHandler;

/**
 * Double tap to wake. In gesture mode the ILITEK touch firmware reports any touch of the screen-off panel
 * as "Double Click" (KEY_F3), so a single touch woke the phone. Wake only on the second KEY_F3
 * within DOUBLE_TAP_MS. Loaded by system_server (config_deviceKeyHandlerClasses), so it uses
 * framework classes only.
 */
public class KeyHandler implements DeviceKeyHandler {
    private static final String TAG = "BalmudaKeyHandler";
    private static final int SCANCODE_GESTURE = 61; // KEY_F3 from ILITEK_TDDI
    private static final long DOUBLE_TAP_MS = 600;

    private final PowerManager mPowerManager;
    private long mLastTap;

    public KeyHandler(Context context) {
        mPowerManager = context.getSystemService(PowerManager.class);
    }

    @Override
    public KeyEvent handleKeyEvent(KeyEvent event) {
        if (event.getScanCode() != SCANCODE_GESTURE) {
            return event;
        }
        if (event.getAction() != KeyEvent.ACTION_DOWN || mPowerManager.isInteractive()) {
            return null;
        }
        final long now = SystemClock.uptimeMillis();
        if (now - mLastTap <= DOUBLE_TAP_MS) {
            mLastTap = 0;
            Log.d(TAG, "double tap: wake up");
            mPowerManager.wakeUp(now, PowerManager.WAKE_REASON_GESTURE, "balmuda:double_tap");
        } else {
            mLastTap = now;
        }
        return null;
    }
}
