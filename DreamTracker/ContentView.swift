import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings
    @State private var selectedTab = 0
    @State private var showingRecording = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DreamListView(showRecording: $showingRecording)
            }
            .tabItem {
                Label("Dreams", systemImage: "moon.stars.fill")
            }
            .tag(0)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(1)
        }
        .tint(.purple)
        .fullScreenCover(isPresented: $showingRecording) {
            RecordingView(isPresented: $showingRecording)
        }
        .onOpenURL { url in
            if url.scheme == "dreamtracker" && url.host == "record" {
                showingRecording = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppSettings())
        .modelContainer(for: Dream.self, inMemory: true)
}
