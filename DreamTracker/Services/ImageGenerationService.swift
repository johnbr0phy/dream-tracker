import Foundation
import UIKit

enum ImageGenerationError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Invalid response from image generation service."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

class ImageGenerationService: ObservableObject {
    @Published var isGenerating = false
    @Published var errorMessage: String?

    private let appSettings: AppSettings

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }

    func generateImage(from dreamText: String) async throws -> Data {
        guard appSettings.hasValidAPIKey else {
            throw ImageGenerationError.noAPIKey
        }

        isGenerating = true
        defer { isGenerating = false }

        let prompt = createImagePrompt(from: dreamText)

        switch appSettings.defaultProvider {
        case .openai:
            return try await generateWithOpenAI(prompt: prompt)
        case .anthropic:
            return try await generateWithAnthropic(prompt: prompt)
        }
    }

    private func createImagePrompt(from dreamText: String) -> String {
        "A surreal, dreamlike artistic visualization of: \(dreamText). Style: ethereal, soft lighting, fantasy art, mysterious atmosphere"
    }

    private func generateWithOpenAI(prompt: String) async throws -> Data {
        let url = URL(string: "https://api.openai.com/v1/images/generations")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(appSettings.openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
            "response_format": "b64_json"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageGenerationError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw ImageGenerationError.apiError(message)
            }
            throw ImageGenerationError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let firstImage = dataArray.first,
              let b64Json = firstImage["b64_json"] as? String,
              let imageData = Data(base64Encoded: b64Json) else {
            throw ImageGenerationError.invalidResponse
        }

        return imageData
    }

    private func generateWithAnthropic(prompt: String) async throws -> Data {
        // Anthropic doesn't have a direct image generation API
        // This would need to use Claude to generate a detailed prompt
        // then potentially use another service. For now, we'll provide
        // a helpful error message.
        throw ImageGenerationError.apiError(
            "Anthropic doesn't offer direct image generation. Please use OpenAI for image generation, or use Anthropic to enhance your dream description."
        )
    }
}
