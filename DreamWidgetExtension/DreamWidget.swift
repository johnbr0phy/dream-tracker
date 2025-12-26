import WidgetKit
import SwiftUI

struct DreamWidgetEntry: TimelineEntry {
    let date: Date
}

struct DreamWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamWidgetEntry {
        DreamWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (DreamWidgetEntry) -> Void) {
        let entry = DreamWidgetEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamWidgetEntry>) -> Void) {
        let entry = DreamWidgetEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct DreamWidgetEntryView: View {
    var entry: DreamWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .fill(Color.black.gradient)

            VStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: family == .systemSmall ? 32 : 44))
                    .foregroundStyle(.purple.gradient)

                if family != .systemSmall {
                    Text("Record Dream")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .widgetURL(URL(string: "dreamtracker://record"))
    }
}

struct DreamWidget: Widget {
    let kind: String = "DreamWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamWidgetProvider()) { entry in
            DreamWidgetEntryView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Record Dream")
        .description("Tap to instantly start recording your dream.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    DreamWidget()
} timeline: {
    DreamWidgetEntry(date: .now)
}

#Preview(as: .systemMedium) {
    DreamWidget()
} timeline: {
    DreamWidgetEntry(date: .now)
}
