/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.balmudaparts;

import android.os.Bundle;

import androidx.preference.PreferenceFragmentCompat;
import androidx.preference.SwitchPreferenceCompat;

import com.android.settingslib.collapsingtoolbar.CollapsingToolbarBaseActivity;

/** Settings > System > Gestures > BALMUDA gestures. */
public class GesturesActivity extends CollapsingToolbarBaseActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (savedInstanceState == null) {
            getSupportFragmentManager().beginTransaction()
                    .replace(com.android.settingslib.collapsingtoolbar.R.id.content_frame,
                            new GesturesFragment())
                    .commit();
        }
    }

    public static class GesturesFragment extends PreferenceFragmentCompat {
        @Override
        public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
            setPreferencesFromResource(R.xml.gestures, rootKey);
            final SwitchPreferenceCompat relax = findPreference(GestureController.KEY_RELAX);
            if (relax != null) {
                relax.setVisible(GestureController.hasFaceDownSensor(requireContext()));
            }
            final SwitchPreferenceCompat shake = findPreference(GestureController.KEY_SHAKE);
            if (shake != null) {
                shake.setVisible(GestureController.hasFlickSensor(requireContext()));
            }
        }
    }
}
