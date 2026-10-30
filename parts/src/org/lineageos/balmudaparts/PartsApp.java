/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.balmudaparts;

import android.app.Application;

/** Persistent process: registers the gesture sensors at boot. */
public class PartsApp extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        GestureController.get(this).start();
    }
}
