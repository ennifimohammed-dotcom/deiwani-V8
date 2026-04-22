package com.debttracker.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.appwidget.AppWidgetManager

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        handleWidgetNavigation(intent)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleWidgetNavigation(intent)
    }

    private fun handleWidgetNavigation(intent: Intent?) {
        val screen = intent?.getStringExtra("widget_screen") ?: return
        getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .edit()
            .putString("flutter.widget_pending_route", screen)
            .commit()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.debttracker.app/widgets"
        ).setMethodCallHandler { call, result ->
            if (call.method == "refresh") {
                try {
                    // Direct call — bypasses implicit-broadcast restriction on API 33+.
                    // Implicit sendBroadcast() never reaches manifest receivers on Android 8+;
                    // calling onUpdate() directly is synchronous and always works.
                    val manager = AppWidgetManager.getInstance(this)
                    val ids = manager.getAppWidgetIds(
                        ComponentName(this, DeiwaniWidget1::class.java)
                    )
                    if (ids.isNotEmpty()) {
                        DeiwaniWidget1().onUpdate(this, manager, ids)
                    }
                } catch (_: Throwable) {}
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
