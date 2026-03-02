import SwiftUI
import WidgetKit

private let appGroupId = "group.com.example.to_do_app"

struct PinnedItemEntry: TimelineEntry {
    let date: Date
    let itemId: Int?
    let itemType: String
    let title: String
    let preview: String
}

struct PinnedNoteProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinnedItemEntry {
        PinnedItemEntry(
            date: Date(),
            itemId: nil,
            itemType: "note",
            title: "Pinned note",
            preview: "Pin a note in the app to show it here."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PinnedItemEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PinnedItemEntry>) -> Void) {
        let entry = makeEntry()
        let refreshAt = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }

    private func makeEntry() -> PinnedItemEntry {
        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        let itemId = sharedDefaults?.string(forKey: "pinnedNoteId").flatMap { Int($0) }
        let title = sharedDefaults?.string(forKey: "pinnedNoteTitle") ?? "Pinned note"
        let preview = sharedDefaults?.string(forKey: "pinnedNotePreview")
            ?? "Pin a note in the app to show it here."

        return PinnedItemEntry(
            date: Date(),
            itemId: itemId,
            itemType: "note",
            title: title,
            preview: preview
        )
    }
}

struct PinnedTodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinnedItemEntry {
        PinnedItemEntry(
            date: Date(),
            itemId: nil,
            itemType: "todo",
            title: "Pinned todo",
            preview: "Pin a todo in the app to show it here."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PinnedItemEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PinnedItemEntry>) -> Void) {
        let entry = makeEntry()
        let refreshAt = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refreshAt)))
    }

    private func makeEntry() -> PinnedItemEntry {
        let sharedDefaults = UserDefaults(suiteName: appGroupId)
        let itemId = sharedDefaults?.string(forKey: "pinnedTodoId").flatMap { Int($0) }
        let title = sharedDefaults?.string(forKey: "pinnedTodoTitle") ?? "Pinned todo"
        let preview = sharedDefaults?.string(forKey: "pinnedTodoPreview")
            ?? "Pin a todo in the app to show it here."

        return PinnedItemEntry(
            date: Date(),
            itemId: itemId,
            itemType: "todo",
            title: title,
            preview: preview
        )
    }
}

struct PinnedItemWidgetEntryView: View {
    var entry: PinnedItemEntry

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
        guard let itemId = entry.itemId else { return URL(string: "todoapp://home") }
        return URL(string: "todoapp://\(entry.itemType)/\(itemId)")
    }
}

struct PinnedNoteHomeWidget: Widget {
    let kind: String = "PinnedNoteHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PinnedNoteProvider()) { entry in
            PinnedItemWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pinned Note")
        .description("Shows your pinned note from the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct PinnedTodoHomeWidget: Widget {
    let kind: String = "PinnedTodoHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PinnedTodoProvider()) { entry in
            PinnedItemWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pinned Todo")
        .description("Shows your pinned todo from the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
