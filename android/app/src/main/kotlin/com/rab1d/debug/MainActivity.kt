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
    private val OPLUS_PATH = "/sys/class/oplus_chg/battery/"

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

        var voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
        var currentRaw = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            batteryManager.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        } else {
            0L
        }

        var isDual = false
        var v0: Int? = null
        var v1: Int? = null
        var oplusCurrent: Long? = null

        // Try OPlus specific nodes
        val bccParms = readSysFile("${OPLUS_PATH}bcc_parms")
        if (bccParms != null) {
            val parts = bccParms.split(",")
            // indices 6, 8, 11 (V0, I, V1)
            if (parts.size > 11) {
                v0 = parts[6].trim().toIntOrNull()
                oplusCurrent = parts[8].trim().toLongOrNull()
                v1 = parts[11].trim().toIntOrNull()
            }
        }

        val agingFfc = readSysFile("${OPLUS_PATH}aging_ffc_data")
        if (agingFfc != null) {
            val parts = agingFfc.split(",")
            if (parts.size > 1) {
                isDual = parts[1].trim() == "2"
            }
        }

        // Fallback for standard voltage/current if OPlus nodes fail
        if (v0 == null) {
             val sysVoltage = readSysFile("/sys/class/power_supply/battery/voltage_now")
             if (sysVoltage != null) {
                 val v = sysVoltage.toLong()
                 v0 = when {
                     v > 1000000 -> (v / 1000).toInt()
                     v > 10000 -> v.toInt()
                     else -> (v * 1000).toInt()
                 }
             }
        }

        if (oplusCurrent == null) {
            val sysCurrent = readSysFile("/sys/class/power_supply/battery/current_now")
            if (sysCurrent != null) {
                oplusCurrent = sysCurrent.toLong()
            }
        }

        return mapOf(
            "voltage_mv" to (v0 ?: voltage),
            "voltage_v1_mv" to (v1 ?: 0),
            "current_raw" to (oplusCurrent ?: currentRaw),
            "is_dual" to isDual,
            "manufacturer" to Build.MANUFACTURER.lowercase(Locale.ROOT),
            "brand" to Build.BRAND.lowercase(Locale.ROOT)
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
