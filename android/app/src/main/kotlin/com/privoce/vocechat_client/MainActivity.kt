package com.privoce.vocechatclient
import android.content.Context   
import android.app.NotificationManager

//import io.flutter.embedding.android.FlutterActivity
//
//class MainActivity: FlutterActivity() {
//}
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterFragmentActivity() {
    override fun onResume() {
        super.onResume()
        closeAllNotifications();
    }

    private fun closeAllNotifications() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancelAll()
    }

    private val CHANNEL = "clipboard/image"


    override fun configureFlutterEngdine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
        //     if (call.method == "getBatteryLevel") {
        //         val batteryLevel = getBatteryLevel()

        //         if (batteryLevel != -1) {
        //             result.success(batteryLevel)
        //         } else {
        //             result.error("UNAVAILABLE", "Battery level not available.", null)
        //         }
        //     } else {
        //         result.notImplemented()
        //     }
        // }
    }

    // private fun getBatteryLevel(): Int {
    //     val batteryLevel: Int
    //     if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
    //         val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    //         batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    //     } else {
    //         val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    //         batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
    //     }

    //     return batteryLevel
    // }

    // private fun getClipboardImage():

}