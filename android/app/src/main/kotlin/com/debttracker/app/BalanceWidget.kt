package com.debttracker.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

class BalanceWidget : AppWidgetProvider() {

    override fun onUpdate(
        ctx: Context,
        mgr: AppWidgetManager,
        ids: IntArray
    ) {
        for (id in ids) {
            try {
                update(ctx, mgr, id)
            } catch (e: Throwable) {
                android.util.Log.e("BalanceWidget", "update failed", e)
            }
        }
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        super.onReceive(ctx, intent)
        if (intent.action == "com.debttracker.app.REFRESH") {
            val mgr = AppWidgetManager.getInstance(ctx)
            val ids = mgr.getAppWidgetIds(
                ComponentName(ctx, BalanceWidget::class.java)
            )
            onUpdate(ctx, mgr, ids)
        }
    }

    private fun update(ctx: Context, mgr: AppWidgetManager, id: Int) {
        val views = RemoteViews(ctx.packageName, R.layout.widget_balance)
        val p = ctx.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        )

        // Safe reads with fallbacks
        val balance  = p.getString("flutter.w_balance",  "0")    ?: "0"
        val lent     = p.getString("flutter.w_lent",     "0")    ?: "0"
        val borrowed = p.getString("flutter.w_borrowed", "0")    ?: "0"
        val overdue  = p.getString("flutter.w_overdue",  "0")    ?: "0"
        val cur      = p.getString("flutter.w_currency", "د.م")  ?: "د.م"
        val positive = p.getBoolean("flutter.w_positive", true)

        // Format: "د.م 3,500.00" (currency on left for Arabic currencies)
        views.setTextViewText(R.id.w_balance,  "$cur $balance")
        views.setTextViewText(R.id.w_lent,     "$cur $lent")
        views.setTextViewText(R.id.w_borrowed, "$cur $borrowed")
        views.setTextViewText(R.id.w_overdue,  overdue)

        // Show positive or negative badge — safely via visibility only
        if (positive) {
            views.setViewVisibility(R.id.w_badge_pos, View.VISIBLE)
            views.setViewVisibility(R.id.w_badge_neg, View.GONE)
        } else {
            views.setViewVisibility(R.id.w_badge_pos, View.GONE)
            views.setViewVisibility(R.id.w_badge_neg, View.VISIBLE)
        }

        // Click anywhere → open app
        val pi = PendingIntent.getActivity(
            ctx, 0,
            Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        views.setOnClickPendingIntent(R.id.root, pi)

        mgr.updateAppWidget(id, views)
    }
}
