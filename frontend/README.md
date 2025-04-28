# Frontend - Garden Glossary Mobile App

[![Flutter Version](https://img.shields.io/badge/Flutter-%3E=3.0.0-blue)](https://flutter.dev)

## Overview

This directory contains the Flutter mobile application for Garden Glossary. It provides the user interface for plant identification and accessing cultivation information from the backend API.

## Features

* Upload plant photos from gallery or capture directly with camera.
* View top 3 likely plant identification matches.
* Access cultivation information from RHS or Claude.
* User-friendly mobile interface.
* Supports different build flavors for various environments.

## Getting Started

### Prerequisites

* [Flutter SDK](https://flutter.dev/docs/get-started/install) (version >= 3.0.0 recommended)
* An IDE with Flutter/Dart plugins (e.g., [VS Code](https://code.visualstudio.com/docs/getstarted/extensions))
* Android Studio and/or Xcode (depending on which platforms you want to develop for)

### Installation

1.  Clone the repository and navigate to the `frontend` directory:
    ```bash
    git clone https://github.com/jplimmer/garden-glossary.git
    cd frontend
    ```

2.  Install the necessary Flutter dependencies:
    ```bash
    flutter pub get
    ```

## Running the App

### App Flavors

The app includes four different flavors to support various development scenarios. You can run a specific flavor using the corresponding entry point:

1. **Production (`prod`)**: 
   - Connects to production backend
   - No debugging tools enabled
   - For release builds
    ```bash
    # Production
    flutter run --flavor prod -t lib/main_prod.dart
    ```

2. **Development (`dev`)**: 
   - Connects to production backend
   - Includes debugging tools
   - For development and testing with live data
    ```bash
    # Development
    flutter run --flavor dev -t lib/main_dev.dart
    ```

3. **Local (`local`)**: 
   - Connects to locally running backend (http://localhost:8000 or appropriate address)
   - Includes debugging tools
   - For full-stack local development
    ```bash
    # Local backend
    flutter run --flavor local -t lib/main_local.dart
    ```

4. **Mock (`mock`)**: 
   - Uses mock responses, no backend connection required
   - For UI development and testing without backend dependencies
    ```bash
    # Mock (no backend)
    flutter run --flavor mock -t lib/main_mock.dart
    ```

### Environment variables

The app uses different environment configurations for each flavor - each flavor requires its own environment file.

#### Environment file structure 

Create the following environment files in the `frontend` directory:

* `.env.prod` - Production environment variables
* `.env.dev` - Development environment variables
* `.env.local` - Local testing environment variables
* `.env.mock` - Mock data environment variables

#### Environment file template

Each `.env` file should follow this template:

```
API_URL=https://api.example.com
PAYLOAD_LIMIT_KB=5000
```

## Project Structure

```
frontend/
├── lib/
│   ├── main_prod.dart            # Production entry point
│   ├── main_dev.dart             # Development entry point
│   ├── main_local.dart           # Local backend entry point
│   ├── main_mock.dart            # Mock entry point
│   ├── main.dart                 # App initialisation
│   ├── config/                   # App configuration
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   ├── services/                 # API and backend services
│   ├── utils/                    # Utility functions
│   └── widgets/                  # Reusable UI components
├── assets/                       # Static assets
├── pubspec.yaml                  # Package definition
└── README.md                     # This file
```

## Building for Production

### Android

```bash
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

### iOS

```bash
flutter build ios --flavor prod -t lib/main_prod.dart
```

## Troubleshooting

### Common Issues

1. **Backend Connection Errors**:
   - Check that the API URL in the relevant `.env` file is correct.
   - Verify that the backend is running and accessible.
   - When using the `local` flavor, ensure the device can reach your development machine.

2. **Image Processing Issues**:
   - Ensure the app has camera and storage permissions.
   - Check that payload limit is appropriate and verify image compression.

## License

[MIT License](LICENSE)