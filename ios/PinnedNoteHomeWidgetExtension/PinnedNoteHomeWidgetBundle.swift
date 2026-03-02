import SwiftUI
import WidgetKit

@main
struct PinnedNoteHomeWidgetBundle: WidgetBundle {
    var body: some Widget {
        PinnedNoteHomeWidget()
        PinnedTodoHomeWidget()
    }
}
