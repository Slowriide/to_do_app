package com.example.to_do_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PinnedTodoHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateTodoWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }
}

internal fun updateTodoWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    widgetData: SharedPreferences
) {
    val data = try {
        WidgetSnapshot(
            itemId = parsePinnedId(widgetData.all["pinnedTodoId"]),
            title = (widgetData.all["pinnedTodoTitle"] as? String) ?: "Pinned todo",
            preview = (widgetData.all["pinnedTodoPreview"] as? String)
                ?: "Tap a todo and pin it to this widget."
        )
    } catch (_: Throwable) {
        WidgetSnapshot(null, "Pinned todo", "Tap a todo and pin it to this widget.")
    }

    val views = RemoteViews(context.packageName, R.layout.pinned_note_widget)
    views.setTextViewText(R.id.widget_title, data.title)
    views.setTextViewText(R.id.widget_preview, data.preview)

    val intent = if ((data.itemId ?: -1L) > 0L) {
        Intent(
            Intent.ACTION_VIEW,
            Uri.parse("todoapp://todo/${data.itemId}"),
            context,
            MainActivity::class.java
        )
    } else {
        Intent(context, MainActivity::class.java)
    }.apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }

    val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    val pendingIntent = PendingIntent.getActivity(context, appWidgetId, intent, flags)
    views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

    appWidgetManager.updateAppWidget(appWidgetId, views)
}
