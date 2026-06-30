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
        // Standard Android API says it's in microAmperes.
        var currentMicroAmps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            batteryManager.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        } else {
            0L
        }

        // Heuristic: If current is very small (e.g. < 5000) and we are charging,
        // it might be reported in mA instead of uA.
        // But 5000mA is 5A which is plausible for fast charging.
        // Let's just provide the raw values to Dart and let it handle or display them.

        return mapOf(
            "voltage_mv" to voltage,
            "current_ua" to currentMicroAmps
        )
    }

    private fun getChargingWattage(): Double {
        val data = getBatteryData()
        val voltage = data["voltage_mv"] as Int
        val currentMicroAmps = data["current_ua"] as Long

        // Wattage = (Voltage (V)) * (Current (A))
        // (voltage / 1000.0) * (abs(currentMicroAmps) / 1000000.0)

        var currentAmps = Math.abs(currentMicroAmps).toDouble() / 1000000.0

        // Check if value is ridiculously small (like it was actually mA)
        if (currentAmps > 0 && currentAmps < 0.01) {
             // Maybe it was reported in mA
             currentAmps = Math.abs(currentMicroAmps).toDouble() / 1000.0
        }

        val wattage = (voltage.toDouble() / 1000.0) * currentAmps
        return wattage
    }
}
