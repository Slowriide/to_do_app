package com.example.to_do_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PinnedNoteHomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    widgetData: SharedPreferences
) {
    val (pinnedNoteId, title, preview) = try {
        Triple(
            parsePinnedId(widgetData),
            (widgetData.all["pinnedNoteTitle"] as? String) ?: "Pinned note",
            (widgetData.all["pinnedNotePreview"] as? String)
                ?: "Tap a note and pin it to this widget."
        )
    } catch (_: Throwable) {
        // Never crash app process because of malformed widget prefs.
        Triple(null, "Pinned note", "Tap a note and pin it to this widget.")
    }

    val views = RemoteViews(context.packageName, R.layout.pinned_note_widget)
    views.setTextViewText(R.id.widget_title, title)
    views.setTextViewText(R.id.widget_preview, preview)

    val intent = if ((pinnedNoteId ?: -1L) > 0L) {
        Intent(
            Intent.ACTION_VIEW,
            Uri.parse("todoapp://note/$pinnedNoteId"),
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

private fun parsePinnedId(widgetData: SharedPreferences): Long? {
    val raw = widgetData.all["pinnedNoteId"] ?: return null
    return when (raw) {
        is Int -> raw.toLong()
        is Long -> raw
        is Float -> raw.toLong()
        is Double -> raw.toLong()
        is String -> raw.toLongOrNull()
        is Number -> raw.toLong()
        else -> raw.toString().toLongOrNull()
    }
}
