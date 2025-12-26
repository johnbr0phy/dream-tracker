import SwiftUI
import SwiftData

@main
struct DreamTrackerApp: App {
    let modelContainer: ModelContainer
    @StateObject private var appSettings = AppSettings()

    init() {
        do {
            modelContainer = try ModelContainer(for: Dream.self)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appSettings)
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
