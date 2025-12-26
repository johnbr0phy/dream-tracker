# Dream Tracker

A minimal Flutter app for capturing dreams with voice recording and AI visualization.

## Features

- **Voice Recording** - Record your dreams with one tap
- **Speech-to-Text** - Automatic transcription using on-device speech recognition
- **Dark UI** - Optimized for half-asleep use
- **AI Visualization** - Generate dreamlike images from your transcripts using DALL-E 3
- **Local Storage** - All dreams stored locally on your device
- **Secure** - API keys stored in secure storage

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.2.0 or higher)
- Xcode (for iOS)
- Android Studio (for Android)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/johnbr0phy/dream-tracker.git
   cd dream-tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # iOS
   flutter run -d ios

   # Android
   flutter run -d android
   ```

### iOS Setup

For iOS, you need to:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Set your development team in Signing & Capabilities
3. Run from Xcode or use `flutter run`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── dream.dart           # Dream data model
├── screens/
│   ├── home_screen.dart     # Tab navigation
│   ├── recording_screen.dart # Voice recording UI
│   ├── dream_list_screen.dart # Dream history
│   ├── dream_detail_screen.dart # Dream details + AI image
│   └── settings_screen.dart  # API key configuration
└── services/
    ├── database_service.dart # SQLite persistence
    ├── settings_service.dart # Secure settings storage
    ├── audio_service.dart    # Recording & playback
    ├── speech_service.dart   # Speech recognition
    └── image_generation_service.dart # OpenAI DALL-E
```

## Configuration

1. Open the app and go to Settings
2. Enter your OpenAI API key
3. Start recording your dreams!

## Privacy

- All dream data is stored locally on your device
- Audio recordings are saved to the app's documents directory
- API keys are stored in secure storage (iOS Keychain / Android EncryptedSharedPreferences)
- No data is sent anywhere except for image generation (using your own API key)

## License

MIT
