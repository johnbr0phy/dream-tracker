import Foundation
import SwiftData

actor DreamStore {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func saveDream(transcript: String, audioFileName: String?) async throws -> Dream {
        let context = modelContainer.mainContext
        let dream = Dream(transcript: transcript, audioFileName: audioFileName)
        context.insert(dream)
        try context.save()
        return dream
    }

    @MainActor
    func deleteDream(_ dream: Dream) throws {
        let context = modelContainer.mainContext

        // Delete associated audio file if exists
        if let audioURL = dream.audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }

        context.delete(dream)
        try context.save()
    }

    @MainActor
    func updateDreamImage(_ dream: Dream, imageData: Data, prompt: String) throws {
        let context = modelContainer.mainContext
        dream.generatedImageData = imageData
        dream.imagePrompt = prompt
        try context.save()
    }

    @MainActor
    func fetchAllDreams() throws -> [Dream] {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<Dream>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }
}
