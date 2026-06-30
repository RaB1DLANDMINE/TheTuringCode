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

        // Android standard voltage in mV
        var voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0

        // Android standard current in uA (MicroAmps)
        var currentRaw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            batteryManager.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        } else {
            0L
        }

        // Try reading from various sysfs paths for better accuracy on OPlus/OnePlus devices
        val voltagePaths = listOf(
            "/sys/class/power_supply/battery/voltage_now",
            "/sys/class/power_supply/battery/batt_vol",
            "/sys/class/power_supply/battery/voltage_avg"
        )

        for (path in voltagePaths) {
            val sysVal = readSysFile(path)
            if (sysVal != null) {
                val v = sysVal.toLong()
                // If it's > 1,000,000 it's likely uV, if > 1000 it's mV, else V
                voltage = when {
                    v > 1000000 -> (v / 1000).toInt()
                    v > 10000 -> v.toInt() // Likely mV already
                    v > 0 -> (v * 1000).toInt() // Likely V
                    else -> voltage
                }
                break
            }
        }

        val currentPaths = listOf(
            "/sys/class/power_supply/battery/current_now",
            "/sys/class/power_supply/battery/batt_chg_current",
            "/sys/class/power_supply/battery/current_avg"
        )

        for (path in currentPaths) {
            val sysVal = readSysFile(path)
            if (sysVal != null) {
                currentRaw = sysVal.toLong()
                break
            }
        }

        return mapOf(
            "voltage_mv" to voltage,
            "current_raw" to currentRaw,
            "manufacturer" to Build.MANUFACTURER.lowercase(Locale.ROOT),
            "brand" to Build.BRAND.lowercase(Locale.ROOT),
            "model" to Build.MODEL
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
}
