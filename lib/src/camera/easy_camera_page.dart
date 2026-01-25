import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'cubit/easy_camera_cubit.dart';
import 'cubit/easy_camera_state.dart';
import 'easy_camera_config.dart';
import 'easy_camera_result.dart';
import 'easy_camera_settings.dart';

/// Callback type for saving camera settings.
typedef OnSettingsChanged = void Function(EasyCameraSettings settings);

/// Ready-to-use camera page for photo capture.
///
/// Usage:
/// ```dart
/// final result = await Navigator.push<EasyCameraResult>(
///   context,
///   MaterialPageRoute(
///     builder: (_) => EasyCameraPage(
///       config: EasyCameraConfig.fromTheme(Theme.of(context)),
///       onCapture: (result) => Navigator.pop(context, result),
///       initialSettings: savedSettings, // Load saved settings
///       onSettingsChanged: (settings) => saveSettings(settings), // Save on change
///     ),
///   ),
/// );
/// ```
class EasyCameraPage extends StatelessWidget {
  /// Camera configuration.
  final EasyCameraConfig config;

  /// Called when photo is captured successfully.
  final void Function(EasyCameraResult result)? onCapture;

  /// Called when user cancels.
  final VoidCallback? onCancel;

  /// Called when an error occurs.
  final void Function(Object error)? onError;

  /// Called when user wants to open app settings (for permissions).
  final VoidCallback? onOpenSettings;

  /// Initial settings to restore (loaded from storage).
  final EasyCameraSettings? initialSettings;

  /// Called when settings change (flash, camera, zoom).
  /// Use this to persist settings.
  final OnSettingsChanged? onSettingsChanged;

  const EasyCameraPage({
    super.key,
    this.config = const EasyCameraConfig(),
    this.onCapture,
    this.onCancel,
    this.onError,
    this.onOpenSettings,
    this.initialSettings,
    this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EasyCameraCubit(config, initialSettings: initialSettings),
      child: _EasyCameraPageContent(
        config: config,
        onCapture: onCapture,
        onCancel: onCancel,
        onError: onError,
        onOpenSettings: onOpenSettings,
        onSettingsChanged: onSettingsChanged,
      ),
    );
  }
}

class _EasyCameraPageContent extends StatefulWidget {
  final EasyCameraConfig config;
  final void Function(EasyCameraResult result)? onCapture;
  final VoidCallback? onCancel;
  final void Function(Object error)? onError;
  final VoidCallback? onOpenSettings;
  final OnSettingsChanged? onSettingsChanged;

  const _EasyCameraPageContent({
    required this.config,
    this.onCapture,
    this.onCancel,
    this.onError,
    this.onOpenSettings,
    this.onSettingsChanged,
  });

  @override
  State<_EasyCameraPageContent> createState() => _EasyCameraPageContentState();
}

class _EasyCameraPageContentState extends State<_EasyCameraPageContent> {
  StreamSubscription<double>? _zoomSubscription;
  SensorConfig? _currentSensorConfig;

  @override
  void dispose() {
    _zoomSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToZoom(SensorConfig sensorConfig, EasyCameraCubit cubit) {
    // Only subscribe if sensor config changed (avoid multiple subscriptions)
    if (_currentSensorConfig == sensorConfig) return;
    _currentSensorConfig = sensorConfig;

    _zoomSubscription?.cancel();
    _zoomSubscription = sensorConfig.zoom$.listen((zoom) {
      if (mounted) {
        cubit.onZoomChanged(zoom);
      }
    });
  }

  void _notifySettingsChanged(EasyCameraCubit cubit) {
    final settings = cubit.getCurrentSettings();
    if (settings != null && widget.onSettingsChanged != null) {
      widget.onSettingsChanged!(settings);
    }
  }

  /// Checks if zoom is supported for the current camera sensor.
  Future<void> _checkZoomSupport(SensorConfig sensorConfig, EasyCameraCubit cubit) async {
    // Use a small delay to allow camera to fully switch
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    try {
      // Try to get current zoom
      final currentZoom = await sensorConfig.zoom$.first;
      if (!mounted) return;

      // Try setting a different zoom value
      final testZoom = currentZoom < 0.5 ? 0.5 : 0.0;
      sensorConfig.setZoom(testZoom);

      // Check if zoom actually changed
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final newZoom = await sensorConfig.zoom$.first;
      if (!mounted) return;

      // Restore original zoom
      sensorConfig.setZoom(currentZoom);

      // Zoom is supported if the value changed
      final zoomSupported = (newZoom - testZoom).abs() < 0.1;
      cubit.setZoomSupported(zoomSupported);
    } catch (_) {
      // If we can't get zoom, it's not supported
      if (mounted) {
        cubit.setZoomSupported(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<EasyCameraCubit, EasyCameraState>(
        listener: (context, state) {
          if (state is EasyCameraCaptured) {
            // Save settings before closing
            _notifySettingsChanged(context.read<EasyCameraCubit>());
            widget.onCapture?.call(state.result);
          } else if (state is EasyCameraError) {
            widget.onError?.call(state.error ?? state.message);
          } else if (state is EasyCameraPermissionDenied) {
            _showPermissionDialog(context);
          } else if (state is EasyCameraReady) {
            // Notify settings changed when state updates
            _notifySettingsChanged(context.read<EasyCameraCubit>());
          }
        },
        builder: (context, state) {
          if (state is EasyCameraPermissionDenied) {
            return _buildPermissionDenied(context);
          }

          return _buildCamera(context);
        },
      ),
    );
  }

  Widget _buildCamera(BuildContext context) {
    final cubit = context.read<EasyCameraCubit>();
    final theme = Theme.of(context);
    final iconColor = widget.config.iconColor ?? theme.colorScheme.onSurface;

    // Get initial settings
    final initialSettings = cubit.initialSettings;
    final initialZoom = initialSettings?.zoomLevel ?? widget.config.initialZoom;
    final initialFlash = initialSettings?.flashMode ?? widget.config.initialFlashMode;
    final initialCamera = initialSettings?.cameraPosition ?? widget.config.initialCamera;

    return CameraAwesomeBuilder.awesome(
      previewFit: CameraPreviewFit.fitWidth,
      theme: AwesomeTheme(
        bottomActionsBackgroundColor: Colors.transparent,
      ),
      saveConfig: SaveConfig.photo(
        pathBuilder: (sensors) async {
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          return SingleCaptureRequest(
            '${tempDir.path}/photo_$timestamp.jpg',
            sensors.first,
          );
        },
      ),
      sensorConfig: SensorConfig.single(
        sensor: Sensor.position(initialCamera),
        flashMode: initialFlash,
        zoom: initialZoom,
      ),
      onMediaCaptureEvent: (event) {
        switch (event.status) {
          case MediaCaptureStatus.capturing:
            cubit.onCaptureStart();
            break;
          case MediaCaptureStatus.success:
            final filePath =
                event.captureRequest.when(single: (single) => single.file?.path);
            if (filePath != null) {
              cubit.onCaptureSuccess(filePath);
            } else {
              cubit.onCaptureError('Failed to get file path');
            }
            break;
          case MediaCaptureStatus.failure:
            cubit.onCaptureError(event.exception ?? 'Unknown error');
            break;
        }
      },
      topActionsBuilder: (state) => _buildTopActions(context, state, iconColor),
      bottomActionsBuilder: (state) {
        // Subscribe to zoom changes from camera (pinch gestures)
        _subscribeToZoom(state.sensorConfig, cubit);
        return _buildBottomActions(context, state, iconColor);
      },
      middleContentBuilder: (state) => const SizedBox.shrink(),
    );
  }

  Widget _buildZoomSlider(
    BuildContext context,
    CameraState cameraState,
    Color iconColor,
    double zoomLevel,
  ) {
    return Row(
      children: [
        Icon(
          Icons.zoom_out,
          color: iconColor,
          size: 20,
        ),
        Expanded(
          child: Slider(
            value: zoomLevel.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            activeColor: iconColor,
            inactiveColor: iconColor.withAlpha(77),
            onChanged: (value) {
              cameraState.sensorConfig.setZoom(value);
              context.read<EasyCameraCubit>().onZoomChanged(value);
            },
          ),
        ),
        Icon(
          Icons.zoom_in,
          color: iconColor,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildTopActions(
    BuildContext context,
    CameraState state,
    Color iconColor,
  ) {
    final cubit = context.read<EasyCameraCubit>();

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          _CircleButton(
            icon: Icons.arrow_back,
            iconColor: iconColor,
            onTap: () {
              // Save settings before closing
              _notifySettingsChanged(cubit);
              widget.onCancel?.call();
              if (widget.onCancel == null) {
                Navigator.of(context).pop();
              }
            },
          ),

          // Title
          if (widget.config.title != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(100),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.config.title!,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Flash button
          if (widget.config.showFlashButton)
            AwesomeFlashButton(
              state: state,
              onFlashTap: (sensorConfig, flashMode) {
                sensorConfig.setFlashMode(flashMode);
                cubit.onFlashModeChanged(flashMode);
              },
              iconBuilder: (flashMode) => _CircleButton(
                icon: _getFlashIcon(flashMode),
                iconColor: iconColor,
                onTap: null,
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    CameraState state,
    Color iconColor,
  ) {
    final cubit = context.read<EasyCameraCubit>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        top: 8,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom slider - show only if configured and zoom is supported
              if (widget.config.showZoomSlider)
                BlocBuilder<EasyCameraCubit, EasyCameraState>(
                  buildWhen: (prev, curr) {
                    if (prev is! EasyCameraReady || curr is! EasyCameraReady) return true;
                    return prev.zoomSupported != curr.zoomSupported ||
                        prev.zoomLevel != curr.zoomLevel;
                  },
                  builder: (context, cubitState) {
                    if (cubitState is! EasyCameraReady || !cubitState.zoomSupported) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildZoomSlider(
                        context,
                        state,
                        iconColor,
                        cubitState.zoomLevel,
                      ),
                    );
                  },
                ),

              // Bottom controls row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Placeholder for symmetry
                  const SizedBox(width: 48),

                  // Capture button
                  _CaptureButton(
                    state: state,
                  ),

                  // Switch camera button
                  if (widget.config.showSwitchCamera)
                    AwesomeCameraSwitchButton(
                      state: state,
                      onSwitchTap: (sensorConfig) {
                        sensorConfig.switchCameraSensor();
                        // Toggle camera position in cubit
                        final currentState = cubit.state;
                        if (currentState is EasyCameraReady) {
                          final newPosition = currentState.currentCamera == SensorPosition.back
                              ? SensorPosition.front
                              : SensorPosition.back;
                          cubit.onCameraSwitched(newPosition);
                          // Check zoom support for the new camera after a delay
                          _checkZoomSupport(state.sensorConfig, cubit);
                        }
                      },
                      iconBuilder: () => _CircleButton(
                        icon: Icons.cameraswitch,
                        iconColor: iconColor,
                        onTap: null,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withAlpha(128),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Access Required',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please grant camera permission to take photos.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => _openAppSettings(),
              child: const Text('Open Settings'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                widget.onCancel?.call();
                if (widget.onCancel == null) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(widget.config.backButtonText ?? 'Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission'),
        content: const Text(
          'Camera permission is required to take photos. '
          'Please grant access in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _openAppSettings() {
    if (widget.onOpenSettings != null) {
      widget.onOpenSettings!();
    } else {
      const channel = MethodChannel('flutter_easy_sdk/settings');
      channel.invokeMethod('openAppSettings').catchError((_) {});
    }
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.on:
        return Icons.flash_on;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.none:
        return Icons.flash_off;
    }
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _CircleButton({
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          icon,
          color: iconColor,
          size: 28,
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final CameraState state;

  const _CaptureButton({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return AwesomeCaptureButton(
      state: state,
    );
  }
}
