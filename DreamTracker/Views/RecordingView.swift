import SwiftUI
import SwiftData

struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool

    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var transcriber = SpeechTranscriber()

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Live transcript preview
                if !transcriber.transcript.isEmpty {
                    ScrollView {
                        Text(transcriber.transcript)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: 200)
                } else if audioRecorder.isRecording {
                    Text("Speak your dream...")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Recording time
                if audioRecorder.isRecording {
                    Text(audioRecorder.formattedTime)
                        .font(.system(size: 48, weight: .light, design: .monospaced))
                        .foregroundColor(.white)
                }

                // Record button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(audioRecorder.isRecording ? Color.red : Color.purple)
                            .frame(width: 80, height: 80)

                        if audioRecorder.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 28, height: 28)
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .disabled(isSaving)
                .scaleEffect(audioRecorder.isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: audioRecorder.isRecording)

                Text(audioRecorder.isRecording ? "Tap to stop" : "Tap to record")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))

                Spacer()
                    .frame(height: 60)

                // Cancel button
                Button("Cancel") {
                    cancelRecording()
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, 40)
            }

            // Saving overlay
            if isSaving {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Saving dream...")
                        .foregroundColor(.white)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func toggleRecording() {
        if audioRecorder.isRecording {
            stopAndSave()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            await audioRecorder.startRecording()
            await transcriber.startLiveTranscription()
        }
    }

    private func stopAndSave() {
        isSaving = true

        let audioFileName = audioRecorder.stopRecording()
        transcriber.stopLiveTranscription()

        // Use the live transcript
        let finalTranscript = transcriber.transcript

        if finalTranscript.isEmpty && audioFileName == nil {
            errorMessage = "No audio or transcript to save"
            showError = true
            isSaving = false
            return
        }

        // Save the dream
        let dream = Dream(
            transcript: finalTranscript,
            audioFileName: audioFileName
        )
        modelContext.insert(dream)

        do {
            try modelContext.save()
            isPresented = false
        } catch {
            errorMessage = "Failed to save dream: \(error.localizedDescription)"
            showError = true
        }

        isSaving = false
    }

    private func cancelRecording() {
        if audioRecorder.isRecording {
            audioRecorder.cancelRecording()
            transcriber.stopLiveTranscription()
        }
        isPresented = false
    }
}

#Preview {
    RecordingView(isPresented: .constant(true))
        .modelContainer(for: Dream.self, inMemory: true)
}
