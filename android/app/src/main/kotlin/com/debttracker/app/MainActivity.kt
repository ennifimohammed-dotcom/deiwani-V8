package com.debttracker.app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Write pending route BEFORE Flutter engine starts to avoid race condition
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
            try {
                if (call.method == "refresh") {
                    sendBroadcast(Intent("com.debttracker.app.REFRESH"))
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            } catch (e: Throwable) {
                result.success(null)
            }
        }
    }
}
