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
import java.io.File
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
        var voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0

        // Current in uA (MicroAmps)
        var currentRaw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            batteryManager.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        } else {
            0L
        }

        // Try reading from sysfs for more accuracy on some devices (OPlus specific)
        val sysVoltage = readSysFile("/sys/class/power_supply/battery/voltage_now")
        if (sysVoltage != null) {
            // voltage_now is usually in uV
            voltage = (sysVoltage.toLong() / 1000).toInt()
        }

        val sysCurrent = readSysFile("/sys/class/power_supply/battery/current_now")
        if (sysCurrent != null) {
            currentRaw = sysCurrent.toLong()
        }

        return mapOf(
            "voltage_mv" to voltage,
            "current_raw" to currentRaw,
            "manufacturer" to Build.MANUFACTURER.lowercase(Locale.ROOT)
        )
    }

    private fun readSysFile(path: String): String? {
        return try {
            val file = File(path)
            if (file.exists() && file.canRead()) {
                file.readText().trim()
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getChargingWattage(): Double {
        val data = getBatteryData()
        val voltage = data["voltage_mv"] as Int
        val currentRaw = data["current_raw"] as Long

        // Default: assume current is in uA
        var currentAmps = Math.abs(currentRaw).toDouble() / 1000000.0

        // Heuristic: if current is suspiciously low for charging, maybe it's mA
        if (currentAmps > 0 && currentAmps < 0.05) {
            currentAmps = Math.abs(currentRaw).toDouble() / 1000.0
        }

        return (voltage.toDouble() / 1000.0) * currentAmps
    }
}
