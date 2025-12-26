# Dream Tracker

A minimal iOS app for capturing dreams the moment you wake up. One tap from the home screen → speak your dream → it's saved, transcribed, and optionally visualized with AI.

## Features

### Capture
- **Home screen widget** - Single tap to start recording
- **Voice recording** with automatic transcription using Apple Speech framework
- **Dark minimal UI** optimized for half-asleep use

### Storage
- Local dream history with date, transcript, audio, and generated images
- Simple list view to browse past dreams
- SwiftData for persistent storage

### AI Generation
- Generate dreamlike images from transcripts using DALL-E 3
- User provides their own OpenAI API key

### Settings
- API key input for OpenAI
- Secure keychain storage for API keys

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Open `DreamTracker.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on your device
4. Add the Dream Tracker widget to your home screen
5. Configure your OpenAI API key in Settings for image generation

## Usage

1. **Wake from a dream** → tap the home screen widget
2. App opens directly to the recording screen (minimal dark UI)
3. **Speak your dream** → tap stop
4. Audio is transcribed and saved automatically
5. Browse dream history and generate AI images from any entry

## Architecture

```
DreamTracker/
├── DreamTrackerApp.swift      # App entry point
├── ContentView.swift          # Main tab view
├── Models/
│   ├── Dream.swift            # SwiftData model
│   └── AppSettings.swift      # Settings with Keychain storage
├── Views/
│   ├── RecordingView.swift    # Voice recording UI
│   ├── DreamListView.swift    # Dream history list
│   ├── DreamDetailView.swift  # Dream detail with image gen
│   └── SettingsView.swift     # API key configuration
└── Services/
    ├── DreamStore.swift       # Data persistence
    ├── AudioRecorder.swift    # AVAudioRecorder wrapper
    ├── SpeechTranscriber.swift # Speech recognition
    └── ImageGenerationService.swift # OpenAI DALL-E integration

DreamWidgetExtension/
├── DreamWidget.swift          # Widget implementation
└── DreamWidgetBundle.swift    # Widget bundle
```

## Privacy

- All dream data is stored locally on device
- Audio recordings are saved to the app's Documents directory
- API keys are stored securely in the iOS Keychain
- No data is sent to any server except for image generation (using your own API key)

## License

MIT
