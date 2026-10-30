/*
 * SPDX-FileCopyrightText: The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

package org.lineageos.balmudaparts;

import android.app.AutomaticZenRule;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.SharedPreferences;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.hardware.TriggerEvent;
import android.hardware.TriggerEventListener;
import android.media.AudioManager;
import android.net.Uri;
import android.os.PowerManager;
import android.os.SystemClock;
import android.service.notification.Condition;
import android.service.notification.ZenPolicy;
import android.util.Log;

import androidx.preference.PreferenceManager;

import java.util.Arrays;

/**
 * BALMUDA gestures on the stock Kyocera sensors (vendor sensor types):
 * - Relax mode: face down silences notifications; alarms ring, calls only vibrate.
 * - Shake to wake (flick_detect, one-shot wake-up sensor).
 */
public final class GestureController implements SharedPreferences.OnSharedPreferenceChangeListener {
    private static final String TAG = "BalmudaParts";

    static final String KEY_RELAX = "relax_mode";
    static final String KEY_SHAKE = "shake_to_wake";
    private static final String KEY_RULE_ID = "relax_rule_id";
    private static final String KEY_SAVED_RINGER = "relax_saved_ringer";

    private static final String TYPE_FACEDOWN = "jp.kyocera.hardware.sensors.facedown_detect";
    private static final String TYPE_FLICK = "jp.kyocera.hardware.sensors.flick_detect";
    private static final Uri RELAX_CONDITION =
            Uri.parse("condition://org.lineageos.balmudaparts/relax");

    private static GestureController sInstance;

    private final Context mContext;
    private final SharedPreferences mPrefs;
    private final SensorManager mSensorManager;
    private final PowerManager mPowerManager;
    private final NotificationManager mNotificationManager;
    private final AudioManager mAudioManager;
    private final Sensor mFaceDownSensor;
    private final Sensor mFlickSensor;

    private boolean mFaceDownListening;
    private boolean mFlickArmed;
    private boolean mRelaxActive;

    static synchronized GestureController get(Context context) {
        if (sInstance == null) {
            sInstance = new GestureController(context.getApplicationContext());
        }
        return sInstance;
    }

    private GestureController(Context context) {
        mContext = context;
        mPrefs = PreferenceManager.getDefaultSharedPreferences(context);
        mSensorManager = context.getSystemService(SensorManager.class);
        mPowerManager = context.getSystemService(PowerManager.class);
        mNotificationManager = context.getSystemService(NotificationManager.class);
        mAudioManager = context.getSystemService(AudioManager.class);
        mFaceDownSensor = findSensor(TYPE_FACEDOWN);
        mFlickSensor = findSensor(TYPE_FLICK);
        Log.i(TAG, "facedown=" + mFaceDownSensor + " flick=" + mFlickSensor);
    }

    static boolean hasFaceDownSensor(Context context) {
        return get(context).mFaceDownSensor != null;
    }

    static boolean hasFlickSensor(Context context) {
        return get(context).mFlickSensor != null;
    }

    void start() {
        mPrefs.registerOnSharedPreferenceChangeListener(this);
        update();
    }

    boolean isRelaxEnabled() {
        return mPrefs.getBoolean(KEY_RELAX, false);
    }

    void setRelaxEnabled(boolean enabled) {
        mPrefs.edit().putBoolean(KEY_RELAX, enabled).apply();
    }

    @Override
    public void onSharedPreferenceChanged(SharedPreferences prefs, String key) {
        if (KEY_RELAX.equals(key) || KEY_SHAKE.equals(key)) {
            update();
        }
    }

    private void update() {
        final boolean relax = isRelaxEnabled() && mFaceDownSensor != null;
        if (relax && !mFaceDownListening) {
            mFaceDownListening = mSensorManager.registerListener(mFaceDownListener,
                    mFaceDownSensor, SensorManager.SENSOR_DELAY_NORMAL);
        } else if (!relax && mFaceDownListening) {
            mSensorManager.unregisterListener(mFaceDownListener);
            mFaceDownListening = false;
            setRelaxActive(false);
        }

        final boolean shake = mPrefs.getBoolean(KEY_SHAKE, false) && mFlickSensor != null;
        if (shake && !mFlickArmed) {
            mFlickArmed = mSensorManager.requestTriggerSensor(mFlickListener, mFlickSensor);
        } else if (!shake && mFlickArmed) {
            mSensorManager.cancelTriggerSensor(mFlickListener, mFlickSensor);
            mFlickArmed = false;
        }
    }

    private final SensorEventListener mFaceDownListener = new SensorEventListener() {
        @Override
        public void onSensorChanged(SensorEvent event) {
            Log.d(TAG, "facedown " + Arrays.toString(event.values));
            setRelaxActive(event.values.length > 0 && event.values[0] != 0f);
        }

        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) {
        }
    };

    private final TriggerEventListener mFlickListener = new TriggerEventListener() {
        @Override
        public void onTrigger(TriggerEvent event) {
            Log.d(TAG, "flick " + Arrays.toString(event.values));
            // One-shot sensor: re-arm after it fires
            mFlickArmed = mSensorManager.requestTriggerSensor(mFlickListener, mFlickSensor);
            if (!mPowerManager.isInteractive()) {
                mPowerManager.wakeUp(SystemClock.uptimeMillis(),
                        PowerManager.WAKE_REASON_GESTURE, "balmuda:shake");
            }
        }
    };

    private void setRelaxActive(boolean active) {
        if (active == mRelaxActive) {
            return;
        }
        mRelaxActive = active;
        final String ruleId = ensureRelaxRule();
        if (ruleId != null) {
            mNotificationManager.setAutomaticZenRuleState(ruleId, new Condition(RELAX_CONDITION,
                    mContext.getString(R.string.relax_title),
                    active ? Condition.STATE_TRUE : Condition.STATE_FALSE));
        }
        // Calls only vibrate in Relax mode; restore the ringer unless the user changed it
        if (active) {
            final int ringer = mAudioManager.getRingerModeInternal();
            if (ringer == AudioManager.RINGER_MODE_NORMAL) {
                mPrefs.edit().putInt(KEY_SAVED_RINGER, ringer).apply();
                mAudioManager.setRingerModeInternal(AudioManager.RINGER_MODE_VIBRATE);
            }
        } else {
            final int saved = mPrefs.getInt(KEY_SAVED_RINGER, -1);
            if (saved != -1) {
                if (mAudioManager.getRingerModeInternal() == AudioManager.RINGER_MODE_VIBRATE) {
                    mAudioManager.setRingerModeInternal(saved);
                }
                mPrefs.edit().remove(KEY_SAVED_RINGER).apply();
            }
        }
        Log.i(TAG, "relax " + (active ? "on" : "off"));
    }

    /** Own Do Not Disturb rule: alarms, media and calls pass, other notifications do not. */
    private String ensureRelaxRule() {
        String id = mPrefs.getString(KEY_RULE_ID, null);
        if (id != null && mNotificationManager.getAutomaticZenRule(id) != null) {
            return id;
        }
        final ZenPolicy policy = new ZenPolicy.Builder()
                .allowAlarms(true)
                .allowMedia(true)
                .allowCalls(ZenPolicy.PEOPLE_TYPE_ANYONE)
                .allowRepeatCallers(true)
                .allowMessages(ZenPolicy.PEOPLE_TYPE_NONE)
                .allowConversations(ZenPolicy.CONVERSATION_SENDERS_NONE)
                .allowReminders(false)
                .allowEvents(false)
                .allowSystem(false)
                .build();
        final AutomaticZenRule rule = new AutomaticZenRule.Builder(
                mContext.getString(R.string.relax_title), RELAX_CONDITION)
                .setConfigurationActivity(new ComponentName(mContext, GesturesActivity.class))
                .setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                .setZenPolicy(policy)
                .setType(AutomaticZenRule.TYPE_OTHER)
                .setManualInvocationAllowed(false)
                .build();
        try {
            id = mNotificationManager.addAutomaticZenRule(rule);
            mPrefs.edit().putString(KEY_RULE_ID, id).apply();
            return id;
        } catch (RuntimeException e) {
            Log.e(TAG, "addAutomaticZenRule failed", e);
            return null;
        }
    }

    private Sensor findSensor(String type) {
        for (Sensor s : mSensorManager.getSensorList(Sensor.TYPE_ALL)) {
            if (type.equals(s.getStringType())) {
                return s;
            }
        }
        return null;
    }
}
