# Hand Tech Commercial Smart Glasses Companion App

Hand Tech is a state-of-the-art Flutter companion application designed to pair with smart glasses, enabling a seamless blend of telemetry, live translations, and control.

## Tech Stack
*   **Framework**: Flutter
*   **State Management**: Riverpod
*   **Architecture**: Clean Architecture (Repository Pattern)

## Key Modules Implemented
*   **Auth & Profiles**: Secure login and registration flows with accessible design patterns.
*   **BLE Pairing & Telemetry**: Bluetooth hardware connection logic and live battery/status indicators.
*   **Live Translation Stream Engine**: Real-time sign language transcription and text rendering.
*   **30 FPS Camera PiP**: Smooth picture-in-picture floating overlay with lifecycle management.

## Getting Started

To run the application locally on Web/Chrome or Mobile, follow these steps:

1.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

2.  **Run the application**:
    ```bash
    flutter run
    ```
    *Tip: To force the Chrome web target, use `flutter run -d chrome`.*

## Architecture Notes
The application strictly separates presentation (screens, widgets) from business logic (providers) and data contracts (models, repositories). 
*   `lib/data/` contains models and repository implementations (including mock backends for testing).
*   `lib/providers/` holds the Riverpod state notifiers.
*   `lib/screens/` and `lib/widgets/` hold the UI components.
