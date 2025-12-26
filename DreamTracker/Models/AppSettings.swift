import Foundation
import SwiftUI

enum AIProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var keyPlaceholder: String {
        switch self {
        case .openai:
            return "sk-..."
        case .anthropic:
            return "sk-ant-..."
        }
    }
}

class AppSettings: ObservableObject {
    private let openAIKeyKey = "openai_api_key"
    private let anthropicKeyKey = "anthropic_api_key"
    private let defaultProviderKey = "default_ai_provider"

    @Published var openAIKey: String {
        didSet {
            saveToKeychain(key: openAIKeyKey, value: openAIKey)
        }
    }

    @Published var anthropicKey: String {
        didSet {
            saveToKeychain(key: anthropicKeyKey, value: anthropicKey)
        }
    }

    @Published var defaultProvider: AIProvider {
        didSet {
            UserDefaults.standard.set(defaultProvider.rawValue, forKey: defaultProviderKey)
        }
    }

    init() {
        self.openAIKey = Self.loadFromKeychain(key: "openai_api_key") ?? ""
        self.anthropicKey = Self.loadFromKeychain(key: "anthropic_api_key") ?? ""

        let providerRaw = UserDefaults.standard.string(forKey: "default_ai_provider") ?? AIProvider.openai.rawValue
        self.defaultProvider = AIProvider(rawValue: providerRaw) ?? .openai
    }

    var hasValidAPIKey: Bool {
        switch defaultProvider {
        case .openai:
            return !openAIKey.isEmpty
        case .anthropic:
            return !anthropicKey.isEmpty
        }
    }

    var currentAPIKey: String {
        switch defaultProvider {
        case .openai:
            return openAIKey
        case .anthropic:
            return anthropicKey
        }
    }

    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        if !value.isEmpty {
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    private static func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }
}
