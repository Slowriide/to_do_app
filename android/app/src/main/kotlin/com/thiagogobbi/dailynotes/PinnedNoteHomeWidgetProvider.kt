package com.thiagogobbi.dailynotes

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
            updateNoteWidget(context, appWidgetManager, appWidgetId, widgetData)
        }
    }
}

internal fun updateNoteWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    widgetData: SharedPreferences
) {
    val data = try {
        WidgetSnapshot(
            itemId = parsePinnedId(widgetData.all["pinnedNoteId"]),
            title = (widgetData.all["pinnedNoteTitle"] as? String) ?: "Pinned note",
            preview = (widgetData.all["pinnedNotePreview"] as? String)
                ?: "Tap a note and pin it to this widget."
        )
    } catch (_: Throwable) {
        WidgetSnapshot(null, "Pinned note", "Tap a note and pin it to this widget.")
    }

    val views = RemoteViews(context.packageName, R.layout.pinned_note_widget)
    views.setTextViewText(R.id.widget_title, data.title)
    views.setTextViewText(R.id.widget_preview, data.preview)

    val intent = if ((data.itemId ?: -1L) > 0L) {
        Intent(
            Intent.ACTION_VIEW,
            Uri.parse("todoapp://note/${data.itemId}"),
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

internal fun parsePinnedId(raw: Any?): Long? {
    if (raw == null) return null
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

internal data class WidgetSnapshot(
    val itemId: Long?,
    val title: String,
    val preview: String
)

