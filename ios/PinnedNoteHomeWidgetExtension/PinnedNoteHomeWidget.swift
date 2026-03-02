import SwiftUI
import WidgetKit

private let appGroupId = "group.com.example.to_do_app"

struct PinnedNoteEntry: TimelineEntry {
    let date: Date
    let noteId: Int?
    let title: String
    let preview: String
}

struct PinnedNoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinnedNoteEntry {
        PinnedNoteEntry(
            date: Date(),
            noteId: nil,
            title: "Pinned note",
            preview: "Pin a note in the app to show it here."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PinnedNoteEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PinnedNoteEntry>) -> Void) {
        let entry = makeEntry()
        let refreshAt = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }

    private func makeEntry() -> PinnedNoteEntry {
        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        let rawNoteId = sharedDefaults?.string(forKey: "pinnedNoteId")
        let noteId = rawNoteId.flatMap { Int($0) }
        let title = sharedDefaults?.string(forKey: "pinnedNoteTitle") ?? "Pinned note"
        let preview = sharedDefaults?.string(forKey: "pinnedNotePreview") ?? "Pin a note in the app to show it here."

        return PinnedNoteEntry(
            date: Date(),
            noteId: noteId,
            title: title,
            preview: preview
        )
    }
}

struct PinnedNoteHomeWidgetEntryView: View {
    var entry: PinnedNoteProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(.headline)
                .lineLimit(1)

            Text(entry.preview)
                .font(.footnote)
                .lineLimit(5)
                .foregroundColor(.secondary)

            Spacer(minLength: 0)
        }
        .padding(14)
        .widgetURL(deepLinkUrl)
    }

    private var deepLinkUrl: URL? {
        guard let noteId = entry.noteId else { return URL(string: "todoapp://home") }
        return URL(string: "todoapp://note/\(noteId)")
    }
}

struct PinnedNoteHomeWidget: Widget {
    let kind: String = "PinnedNoteHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PinnedNoteProvider()) { entry in
            PinnedNoteHomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pinned Note")
        .description("Shows your pinned note from the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
