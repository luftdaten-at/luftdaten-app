# Luftdaten App

The **Luftdaten App** is a mobile application that allows users to visualize real-time air quality data based on measurements from air quality sensors. The app is developed using **Flutter**, an open-source framework by Google that enables cross-platform mobile applications (iOS, Android) to be built from a single codebase.

## Table of Contents

1. [Installation](#installation)
2. [Project Setup](#project-setup)
3. [Using the App](#using-the-app)
4. [Flutter Commands](#flutter-commands)
5. [Contributing](#contributing)
6. [License](#license)

## Installation

### Prerequisites

- **Flutter SDK**: You need Flutter to build and run the project.
  Download Flutter [here](https://flutter.dev/docs/get-started/install).
- **Android Studio or Xcode**: Install one of these development environments to develop for Android or iOS.
- **Git**: You need Git to clone the repository.

### Installing Flutter

```bash
# On macOS/Linux:
export PATH="$PATH:/path/to/flutter/bin"

# On Windows:
# Add the path to Flutter `C:\path\to\flutter\bin` to your environment variables.
```

### Cloning the Project

```bash
git clone https://github.com/luftdaten-at/luftdaten-app.git
cd luftdaten-app
```

## Project Setup

### Installing Dependencies

Make sure to install all the required packages:

```bash
flutter pub get
```

### Android Configuration

If you are developing for Android, make sure the Android emulator or a physical Android device is set up properly. Check that the Android SDK tools are available:

```bash
flutter doctor --android-licenses
```

### iOS Configuration

If you are developing for iOS, ensure that Xcode and its related tools are correctly installed. You can verify everything is set up by running:

```bash
flutter doctor
```

If you see LLDB warnings when debugging on a physical device, see [docs/DEBUGGING_IOS.md](docs/DEBUGGING_IOS.md).

## Using the App

### Running the App on an Emulator or Device

To run the app on an Android or iOS device/emulator, use the following command:

```bash
flutter run
```

This command will start the app in a debug environment. Ensure a device (either physical or virtual) is connected.

### Building a Release

Create a release build of the app:

- **Android**:

  ```bash
  flutter build apk
  ```

  For an App Bundle (recommended for Google Play Store):

  ```bash
  flutter build appbundle
  ```

- **iOS**:

  ```bash
  flutter build ipa
  ```

  Note that building for iOS only works on macOS.

## Flutter Commands

Here are some useful Flutter commands:

- **Managing dependencies**:

  ```bash
  flutter pub get
  ```

- **Analyzing the Flutter project**:

  ```bash
  flutter analyze
  ```

- **Automatically format code**:

  ```bash
  flutter format .
  ```

- **Running tests**:

  ```bash
  flutter test
  ```

- **Clean the project (remove old build files)**:

  ```bash
  flutter clean
  ```

## Contributing

Contributions to this project are always welcome! To contribute:

1. Fork this repository.
2. Create a branch for your feature: `git checkout -b feature/YourFeature`.
3. Make your changes and commit them: `git commit -m 'Add some feature'`.
4. Push to your branch: `git push origin feature/YourFeature`.
5. Open a Pull Request.

## License

This project is licensed under the [AGPL-3.0 license](LICENSE).
