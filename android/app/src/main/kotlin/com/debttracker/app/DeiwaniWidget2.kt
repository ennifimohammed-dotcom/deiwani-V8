package com.debttracker.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class DeiwaniWidget2 : AppWidgetProvider() {

    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            try {
                update(ctx, mgr, id)
            } catch (e: Throwable) {
                android.util.Log.e("DeiwaniWidget2", "update failed", e)
            }
        }
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        super.onReceive(ctx, intent)
        if (intent.action == "com.debttracker.app.REFRESH") {
            val mgr = AppWidgetManager.getInstance(ctx)
            val ids = mgr.getAppWidgetIds(ComponentName(ctx, DeiwaniWidget2::class.java))
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

    private fun relativeTime(tsMs: Long): String {
        val diffMs = System.currentTimeMillis() - tsMs
        val diffMin  = diffMs / 60_000L
        val diffHour = diffMs / 3_600_000L
        val diffDay  = diffMs / 86_400_000L
        return when {
            diffMs   < 60_000L  -> "الآن"
            diffMin  < 60L      -> "منذ ${diffMin}د"
            diffHour < 24L      -> "منذ ${diffHour}س"
            else                -> "منذ ${diffDay}ي"
        }
    }

    private fun update(ctx: Context, mgr: AppWidgetManager, id: Int) {
        val views = RemoteViews(ctx.packageName, R.layout.widget_layout_2)
        val p = ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

        val balance      = p.getString("flutter.widget_net_balance",    "0")   ?: "0"
        val lent         = p.getString("flutter.widget_total_lent",     "0")   ?: "0"
        val borrowed     = p.getString("flutter.widget_total_borrowed", "0")   ?: "0"
        val overdue      = p.getString("flutter.widget_overdue_count",  "0")   ?: "0"
        val cur          = p.getString("flutter.widget_currency_symbol","د.م") ?: "د.م"
        val curCode      = p.getString("flutter.widget_currency_code",  "MAD") ?: "MAD"
        val positive     = p.getBoolean("flutter.widget_net_positive", true)
        val lastActivity = p.getString("flutter.widget_last_activity",  "")   ?: ""
        val lastTs       = p.getLong("flutter.widget_last_activity_ts", 0L)

        // Header badge: show positive or negative
        if (positive) {
            views.setViewVisibility(R.id.badge_pos, View.VISIBLE)
            views.setViewVisibility(R.id.badge_neg, View.GONE)
        } else {
            views.setViewVisibility(R.id.badge_pos, View.GONE)
            views.setViewVisibility(R.id.badge_neg, View.VISIBLE)
        }

        // Net balance with dynamic color
        val balColor = if (positive) 0xFF00C896.toInt() else 0xFFFF4757.toInt()
        views.setTextViewText(R.id.net_balance, fmt(balance, cur, curCode))
        views.setTextColor(R.id.net_balance, balColor)

        // Stats
        views.setTextViewText(R.id.stat_lent,     fmt(lent,     cur, curCode))
        views.setTextViewText(R.id.stat_borrowed, fmt(borrowed, cur, curCode))
        views.setTextViewText(R.id.stat_overdue,  overdue)

        // Highlight overdue section when count > 0
        val overdueCount = overdue.toIntOrNull() ?: 0
        val overdueColor = if (overdueCount > 0) 0x4DFF9F43 else 0x00000000
        views.setInt(R.id.overdue_section, "setBackgroundColor", overdueColor)

        // Last activity row
        if (lastActivity.isNotEmpty() && lastTs > 0L) {
            val timeStr = relativeTime(lastTs)
            views.setTextViewText(R.id.last_activity, "آخر عملية: $lastActivity • $timeStr")
            views.setViewVisibility(R.id.last_activity_row, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.last_activity_row, View.GONE)
        }

        // Click handlers
        views.setOnClickPendingIntent(R.id.header_row,  openIntent(ctx, "home", 20))
        views.setOnClickPendingIntent(R.id.net_balance, openIntent(ctx, "home", 21))
        views.setOnClickPendingIntent(R.id.btn_add,     openIntent(ctx, "add",  22))
        views.setOnClickPendingIntent(R.id.btn_all,     openIntent(ctx, "all",  23))

        mgr.updateAppWidget(id, views)
    }

    private fun fmt(amount: String, symbol: String, code: String): String =
        when (code) {
            "EUR", "USD", "GBP" -> "$amount $symbol"
            else                -> "$symbol $amount"
        }
}
