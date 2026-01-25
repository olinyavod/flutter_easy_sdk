# EasyCamera Module

Ready-to-use camera page for photo capture with customizable appearance and persistent settings.

## Installation

Add `flutter_easy_sdk` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_easy_sdk:
    path: local_packages/flutter_easy_sdk
```

## Quick Start

```dart
import 'package:flutter_easy_sdk/flutter_easy_sdk.dart';

// Navigate to camera page
final result = await context.push<EasyCameraResult>('/camera');
if (result != null) {
  final File photo = result.file;
  // Use the captured photo
}
```

## Components

### EasyCameraPage

Main camera widget with full UI.

```dart
EasyCameraPage(
  config: EasyCameraConfig.fromTheme(Theme.of(context)),
  initialSettings: savedSettings, // Optional: restore previous settings
  onCapture: (result) => context.pop(result),
  onCancel: () => context.pop(),
  onError: (error) => print('Camera error: $error'),
  onSettingsChanged: (settings) {
    // Save settings for next time
    saveSettings(settings);
  },
)
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `config` | `EasyCameraConfig` | Visual and behavior configuration |
| `initialSettings` | `EasyCameraSettings?` | Restore saved settings (flash, zoom, etc.) |
| `onCapture` | `Function(EasyCameraResult)` | Called when photo is captured |
| `onCancel` | `VoidCallback?` | Called when user cancels |
| `onError` | `Function(String)?` | Called on camera error |
| `onSettingsChanged` | `Function(EasyCameraSettings)?` | Called when settings change |

### EasyCameraConfig

Configuration for camera appearance and initial values.

```dart
EasyCameraConfig(
  // Colors
  backgroundColor: Colors.black.withOpacity(0.8),
  iconColor: Colors.white,
  captureButtonColor: Colors.red,

  // UI options
  showSwitchCamera: true,
  showFlashButton: true,
  showZoomSlider: true,

  // Initial values
  initialCamera: SensorPosition.back,
  initialFlashMode: FlashMode.auto,
  initialZoom: 0.0,

  // Image settings
  imageQuality: 0.85,
  maxWidth: 1920,
  maxHeight: 1080,

  // Labels
  title: 'Take Photo',
  backButtonText: 'Cancel',
)
```

**Factory constructors:**

```dart
// Create config from app theme
EasyCameraConfig.fromTheme(Theme.of(context))
```

### EasyCameraSettings

Persistent settings that can be saved and restored.

```dart
EasyCameraSettings(
  flashMode: FlashMode.auto,
  cameraPosition: SensorPosition.back,
  zoomLevel: 0.0,
  imageQuality: 0.85,
)
```

**Serialization:**

```dart
// Save to JSON
final json = settings.toJson();
await prefs.setString('camera_settings', jsonEncode(json));

// Load from JSON
final json = jsonDecode(prefs.getString('camera_settings')!);
final settings = EasyCameraSettings.fromJson(json);
```

### EasyCameraResult

Result returned after successful capture.

```dart
class EasyCameraResult {
  final String filePath;  // Path to captured image
  File get file;          // File object for the image
}
```

## Integration with GoRouter

### 1. Define route

```dart
// app_routes.dart
class AppRoutes {
  static const String camera = '/camera';
}
```

### 2. Add GoRoute

```dart
// app_router.dart
GoRoute(
  path: AppRoutes.camera,
  builder: (context, state) {
    final config = state.extra as EasyCameraConfig? ??
        EasyCameraConfig.fromTheme(Theme.of(context));
    return EasyCameraPage(
      config: config,
      initialSettings: cameraSettingsService.loadSettings(),
      onSettingsChanged: (settings) {
        cameraSettingsService.saveSettings(settings);
      },
      onCapture: (result) => context.pop(result),
      onCancel: () => context.pop(),
    );
  },
),
```

### 3. Navigate to camera

```dart
// Basic usage
final result = await context.push<EasyCameraResult>(AppRoutes.camera);

// With custom config
final result = await context.push<EasyCameraResult>(
  AppRoutes.camera,
  extra: EasyCameraConfig(
    captureButtonColor: Colors.blue,
    showZoomSlider: false,
  ),
);
```

## Settings Persistence Service

Example service for saving camera settings:

```dart
@lazySingleton
class CameraSettingsService {
  static const _key = 'camera_settings';
  final SharedPreferences _prefs;

  CameraSettingsService(this._prefs);

  EasyCameraSettings? loadSettings() {
    final json = _prefs.getString(_key);
    if (json == null) return null;
    try {
      return EasyCameraSettings.fromJson(jsonDecode(json));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSettings(EasyCameraSettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }

  Future<void> clearSettings() async {
    await _prefs.remove(_key);
  }
}
```

## State Management

The camera uses Cubit for internal state management:

### EasyCameraState

| State | Description |
|-------|-------------|
| `EasyCameraInitial` | Camera not yet initialized |
| `EasyCameraReady` | Camera ready for capture |
| `EasyCameraCapturing` | Photo capture in progress |
| `EasyCameraCaptured` | Photo captured successfully |
| `EasyCameraError` | Error occurred |

### Accessing Cubit

```dart
// Inside EasyCameraPage widget tree
final cubit = context.read<EasyCameraCubit>();

// Get current settings
final settings = cubit.getCurrentSettings();

// Check state
cubit.state is EasyCameraReady
```

## Platform Permissions

### Android

Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

Add to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to take photos</string>
```

## Features

- Front/back camera switch
- Flash modes (auto, on, off, always)
- Zoom slider with gesture support
- Settings persistence
- Theme-aware styling
- Error handling with retry
- Permission handling

## Dependencies

- `camerawesome: ^2.1.0` - Camera functionality
- `flutter_bloc: ^8.1.6` - State management
- `equatable: ^2.0.5` - Value equality
- `path_provider: ^2.1.0` - File paths
