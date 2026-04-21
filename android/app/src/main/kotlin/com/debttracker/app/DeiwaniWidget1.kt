package com.debttracker.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class DeiwaniWidget1 : AppWidgetProvider() {

    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            try {
                update(ctx, mgr, id)
            } catch (e: Throwable) {
                android.util.Log.e("DeiwaniWidget1", "update failed", e)
            }
        }
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        super.onReceive(ctx, intent)
        if (intent.action == "com.debttracker.app.REFRESH") {
            val mgr = AppWidgetManager.getInstance(ctx)
            val ids = mgr.getAppWidgetIds(ComponentName(ctx, DeiwaniWidget1::class.java))
            if (ids.isNotEmpty()) onUpdate(ctx, mgr, ids)
        }
    }

    private fun openIntent(ctx: Context, screen: String, reqCode: Int): PendingIntent {
        val i = Intent(ctx, MainActivity::class.java).apply {
            putExtra("widget_screen", screen)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            ctx, reqCode, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun update(ctx: Context, mgr: AppWidgetManager, id: Int) {
        val views = RemoteViews(ctx.packageName, R.layout.widget_layout_1)
        val p = ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val balance  = p.getString("flutter.widget_net_balance",    "0")   ?: "0"
        val lent     = p.getString("flutter.widget_total_lent",     "0")   ?: "0"
        val borrowed = p.getString("flutter.widget_total_borrowed", "0")   ?: "0"
        val overdue  = p.getString("flutter.widget_overdue_count",  "0")   ?: "0"
        val cur      = p.getString("flutter.widget_currency_symbol","د.م") ?: "د.م"
        val curCode  = p.getString("flutter.widget_currency_code",  "MAD") ?: "MAD"
        val positive = p.getBoolean("flutter.widget_net_positive", true)

        views.setTextViewText(R.id.card1_value, fmt(balance, cur, curCode))
        views.setTextViewText(R.id.card2_value, fmt(lent,    cur, curCode))
        views.setTextViewText(R.id.card3_value, fmt(borrowed,cur, curCode))
        views.setTextViewText(R.id.card4_value, overdue)

        // Color balance card green when positive, red when negative
        val balColor = if (positive) 0xFF00C896.toInt() else 0xFFFF4757.toInt()
        views.setTextColor(R.id.card1_value, balColor)

        views.setOnClickPendingIntent(R.id.card1, openIntent(ctx, "home",     10))
        views.setOnClickPendingIntent(R.id.card2, openIntent(ctx, "lent",     11))
        views.setOnClickPendingIntent(R.id.card3, openIntent(ctx, "borrowed", 12))
        views.setOnClickPendingIntent(R.id.card4, openIntent(ctx, "overdue",  13))

        mgr.updateAppWidget(id, views)
    }

    private fun fmt(amount: String, symbol: String, code: String): String =
        when (code) {
            "EUR", "USD", "GBP" -> "$amount $symbol"
            else                -> "$symbol $amount"
        }
}
