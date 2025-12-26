import Foundation
import SwiftData

@Model
final class Dream {
    var id: UUID
    var createdAt: Date
    var transcript: String
    var audioFileName: String?
    var generatedImageData: Data?
    var imagePrompt: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        transcript: String = "",
        audioFileName: String? = nil,
        generatedImageData: Data? = nil,
        imagePrompt: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.generatedImageData = generatedImageData
        self.imagePrompt = imagePrompt
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var audioURL: URL? {
        guard let fileName = audioFileName else { return nil }
        return Dream.audioDirectory.appendingPathComponent(fileName)
    }

    static var audioDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioDir = documentsPath.appendingPathComponent("DreamAudio")

        if !FileManager.default.fileExists(atPath: audioDir.path) {
            try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
        }

        return audioDir
    }
}
