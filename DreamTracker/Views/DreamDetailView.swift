import SwiftUI
import SwiftData
import AVFoundation

struct DreamDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appSettings: AppSettings
    @Bindable var dream: Dream

    @State private var isPlaying = false
    @State private var isGeneratingImage = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioDelegate: AudioPlayerDelegate?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isEditingTranscript = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Date and time
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(.purple)
                    Text(dream.formattedDate)
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)

                // Transcript section
                transcriptSection

                // Audio playback section
                if dream.audioFileName != nil {
                    audioSection
                }

                // Generated image section
                imageSection
            }
            .padding()
        }
        .navigationTitle("Dream")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            audioPlayer?.stop()
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dream Description")
                    .font(.headline)
                Spacer()
                Button(isEditingTranscript ? "Done" : "Edit") {
                    if isEditingTranscript {
                        try? modelContext.save()
                    }
                    isEditingTranscript.toggle()
                }
                .font(.subheadline)
            }

            if isEditingTranscript {
                TextEditor(text: $dream.transcript)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text(dream.transcript.isEmpty ? "No transcript available" : dream.transcript)
                    .foregroundColor(dream.transcript.isEmpty ? .secondary : .primary)
            }
        }
    }

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio Recording")
                .font(.headline)

            Button(action: togglePlayback) {
                HStack {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading) {
                        Text(isPlaying ? "Playing..." : "Tap to play")
                            .font(.subheadline)
                        Text("Audio recording")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dream Visualization")
                .font(.headline)

            if let imageData = dream.generatedImageData,
               let uiImage = UIImage(data: imageData) {
                // Show generated image
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)

                if let prompt = dream.imagePrompt {
                    Text("Prompt: \(prompt)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 4)
                }

                // Regenerate button
                Button(action: generateImage) {
                    Label("Regenerate Image", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isGeneratingImage || dream.transcript.isEmpty)
            } else {
                // Generate button
                Button(action: generateImage) {
                    if isGeneratingImage {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Generating...")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Label("Generate Dream Image", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(isGeneratingImage || dream.transcript.isEmpty || !appSettings.hasValidAPIKey)

                if !appSettings.hasValidAPIKey {
                    Text("Add an API key in Settings to generate images")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func togglePlayback() {
        guard let audioURL = dream.audioURL else { return }

        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
        } else {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
                audioDelegate = AudioPlayerDelegate { self.isPlaying = false }
                audioPlayer?.delegate = audioDelegate
                audioPlayer?.play()
                isPlaying = true
            } catch {
                errorMessage = "Failed to play audio: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func generateImage() {
        Task {
            isGeneratingImage = true
            defer { isGeneratingImage = false }

            do {
                let imageData = try await generateImageWithOpenAI(prompt: dream.transcript)
                dream.generatedImageData = imageData
                dream.imagePrompt = dream.transcript
                try modelContext.save()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func generateImageWithOpenAI(prompt: String) async throws -> Data {
        guard !appSettings.openAIKey.isEmpty else {
            throw ImageError.noAPIKey
        }

        let url = URL(string: "https://api.openai.com/v1/images/generations")!
        let fullPrompt = "A surreal, dreamlike artistic visualization of: \(prompt). Style: ethereal, soft lighting, fantasy art, mysterious atmosphere"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(appSettings.openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": fullPrompt,
            "n": 1,
            "size": "1024x1024",
            "response_format": "b64_json"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ImageError.apiError(message)
            }
            throw ImageError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstImage = dataArray.first,
              let b64Json = firstImage["b64_json"] as? String,
              let imageData = Data(base64Encoded: b64Json) else {
            throw ImageError.invalidResponse
        }

        return imageData
    }
}

enum ImageError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your OpenAI API key in Settings."
        case .invalidResponse:
            return "Invalid response from image generation service."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// Helper class for audio player delegate
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}

#Preview {
    NavigationStack {
        DreamDetailView(dream: Dream(transcript: "I was flying over a beautiful ocean with purple clouds..."))
    }
    .environmentObject(AppSettings())
    .modelContainer(for: Dream.self, inMemory: true)
}
