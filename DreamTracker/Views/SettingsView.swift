import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings
    @State private var showOpenAIKey = false
    @State private var showAnthropicKey = false

    var body: some View {
        Form {
            Section {
                Picker("Default Provider", selection: $appSettings.defaultProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
            } header: {
                Text("AI Provider")
            } footer: {
                Text("Choose which AI provider to use for image generation")
            }

            Section {
                HStack {
                    if showOpenAIKey {
                        TextField("OpenAI API Key", text: $appSettings.openAIKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("OpenAI API Key", text: $appSettings.openAIKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }

                    Button(action: { showOpenAIKey.toggle() }) {
                        Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if !appSettings.openAIKey.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Key configured")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            } header: {
                Text("OpenAI")
            } footer: {
                Text("Enter your OpenAI API key for DALL-E image generation. Get one at platform.openai.com")
            }

            Section {
                HStack {
                    if showAnthropicKey {
                        TextField("Anthropic API Key", text: $appSettings.anthropicKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Anthropic API Key", text: $appSettings.anthropicKey)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }

                    Button(action: { showAnthropicKey.toggle() }) {
                        Image(systemName: showAnthropicKey ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if !appSettings.anthropicKey.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Key configured")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            } header: {
                Text("Anthropic")
            } footer: {
                Text("Enter your Anthropic API key. Note: Anthropic doesn't offer direct image generation, but can be used for dream analysis.")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dream Tracker v1.0")
                        .font(.headline)
                    Text("Capture your dreams with voice recording and AI visualization.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                    Label("Get OpenAI API Key", systemImage: "link")
                }

                Link(destination: URL(string: "https://console.anthropic.com/")!) {
                    Label("Get Anthropic API Key", systemImage: "link")
                }
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AppSettings())
}
