package com.example.app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app/device_info"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getWifiCountry") {
                val country = getWifiCountry()
                result.success(country)
            } else if (call.method == "getChargingWattage") {
                val wattage = getChargingWattage()
                result.success(wattage)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getWifiCountry(): String {
        // Try to get country from TelephonyManager first (SIM country)
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        var country = tm.networkCountryIso

        if (country.isNullOrEmpty()) {
            country = tm.simCountryIso
        }

        if (country.isNullOrEmpty()) {
            // Fallback to Locale
            country = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                resources.configuration.locales.get(0).country
            } else {
                resources.configuration.locale.country
            }
        }

        return country?.uppercase(Locale.ROOT) ?: "Unknown"
    }

    private fun getChargingWattage(): Double {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager

        // Voltage in mV
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0

        // Current in uA
        val currentMicroAmps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            batteryManager.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        } else {
            0L
        }

        // Wattage = (Voltage (mV) / 1000) * (Current (uA) / 1000000)
        val wattage = (voltage.toDouble() / 1000.0) * (Math.abs(currentMicroAmps).toDouble() / 1000000.0)
        return wattage
    }
}
