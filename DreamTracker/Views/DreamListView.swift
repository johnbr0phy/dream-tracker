import SwiftUI
import SwiftData

struct DreamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Dream.createdAt, order: .reverse) private var dreams: [Dream]
    @Binding var showRecording: Bool

    var body: some View {
        ZStack {
            if dreams.isEmpty {
                emptyStateView
            } else {
                dreamList
            }

            // Floating record button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    recordButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .navigationTitle("Dreams")
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.6))

            Text("No dreams yet")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Tap the record button to capture your first dream")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var dreamList: some View {
        List {
            ForEach(groupedDreams.keys.sorted().reversed(), id: \.self) { date in
                Section(header: Text(formatSectionDate(date))) {
                    ForEach(groupedDreams[date] ?? []) { dream in
                        NavigationLink(destination: DreamDetailView(dream: dream)) {
                            DreamRowView(dream: dream)
                        }
                    }
                    .onDelete { indexSet in
                        deleteDreams(at: indexSet, from: date)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var recordButton: some View {
        Button(action: { showRecording = true }) {
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 60, height: 60)
                    .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "mic.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
    }

    private var groupedDreams: [Date: [Dream]] {
        Dictionary(grouping: dreams) { dream in
            Calendar.current.startOfDay(for: dream.createdAt)
        }
    }

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func deleteDreams(at offsets: IndexSet, from date: Date) {
        guard let dreamsForDate = groupedDreams[date] else { return }

        for index in offsets {
            let dream = dreamsForDate[index]

            // Delete audio file if exists
            if let audioURL = dream.audioURL {
                try? FileManager.default.removeItem(at: audioURL)
            }

            modelContext.delete(dream)
        }

        try? modelContext.save()
    }
}

struct DreamRowView: View {
    let dream: Dream

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatTime(dream.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if dream.generatedImageData != nil {
                    Image(systemName: "photo.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }

                if dream.audioFileName != nil {
                    Image(systemName: "waveform")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }

            Text(dream.transcript.isEmpty ? "No transcript" : dream.transcript)
                .font(.body)
                .foregroundColor(dream.transcript.isEmpty ? .secondary : .primary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        DreamListView(showRecording: .constant(false))
    }
    .modelContainer(for: Dream.self, inMemory: true)
}
