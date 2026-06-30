package com.rab1d.debug

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
    private val CHANNEL = "com.rab1d.debug/device_info"

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
            } else if (call.method == "getBatteryData") {
                val data = getBatteryData()
                result.success(data)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getWifiCountry(): String {
        val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        var country = tm.networkCountryIso

        if (country.isNullOrEmpty()) {
            country = tm.simCountryIso
        }

        if (country.isNullOrEmpty()) {
            country = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                resources.configuration.locales.get(0).country
            } else {
                resources.configuration.locale.country
            }
        }

        return country?.uppercase(Locale.ROOT) ?: "Unknown"
    }

    private fun getBatteryData(): Map<String, Any> {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))

        // Voltage in mV
        val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0

        // Current in uA (MicroAmps). Note: some devices report in mA (MilliAmps).
        var currentRaw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            batteryManager.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        } else {
            0L
        }

        return mapOf(
            "voltage_mv" to voltage,
            "current_raw" to currentRaw,
            "manufacturer" to Build.MANUFACTURER.lowercase(Locale.ROOT)
        )
    }

    private fun getChargingWattage(): Double {
        val data = getBatteryData()
        val voltage = data["voltage_mv"] as Int
        val currentRaw = data["current_raw"] as Long
        val manufacturer = data["manufacturer"] as String

        // Standard Android: current in uA
        var currentAmps = Math.abs(currentRaw).toDouble() / 1000000.0

        // OnePlus/Oppo/Realme often use dual-cell batteries where the reported current/voltage
        // might only be for one cell, or current is reported in mA.
        // Heuristic: if currentAmps is very low (< 0.05) and we are charging, assume mA.
        if (currentAmps > 0 && currentAmps < 0.05) {
            currentAmps = Math.abs(currentRaw).toDouble() / 1000.0
        }

        var wattage = (voltage.toDouble() / 1000.0) * currentAmps

        // OnePlus Specific: If manufacturer is OnePlus/Oppo and wattage is around half
        // of expected, it might be dual-cell. We'll provide both raw and "boosted"
        // in the jumble for verification.

        return wattage
    }
}
