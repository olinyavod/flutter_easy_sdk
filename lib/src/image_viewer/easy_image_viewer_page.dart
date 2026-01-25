import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/easy_image_viewer_cubit.dart';
import 'cubit/easy_image_viewer_state.dart';
import 'easy_image_source.dart';
import 'easy_image_viewer_config.dart';

/// Ready-to-use image viewer page with zoom and pan support.
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => EasyImageViewerPage(
///       source: EasyImageSource.file('/path/to/image.jpg'),
///       config: EasyImageViewerConfig.fromTheme(Theme.of(context)),
///       onClose: () => Navigator.pop(context),
///     ),
///   ),
/// );
/// ```
class EasyImageViewerPage extends StatelessWidget {
  /// Image source to display.
  final EasyImageSource source;

  /// Viewer configuration.
  final EasyImageViewerConfig config;

  /// Called when user closes the viewer.
  final VoidCallback? onClose;

  /// Called when user taps share button.
  final VoidCallback? onShare;

  /// Called when user taps delete button.
  final VoidCallback? onDelete;

  /// Called when an error occurs.
  final void Function(Object error)? onError;

  const EasyImageViewerPage({
    super.key,
    required this.source,
    this.config = const EasyImageViewerConfig(),
    this.onClose,
    this.onShare,
    this.onDelete,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EasyImageViewerCubit(config),
      child: _EasyImageViewerContent(
        source: source,
        config: config,
        onClose: onClose,
        onShare: onShare,
        onDelete: onDelete,
        onError: onError,
      ),
    );
  }
}

class _EasyImageViewerContent extends StatefulWidget {
  final EasyImageSource source;
  final EasyImageViewerConfig config;
  final VoidCallback? onClose;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final void Function(Object error)? onError;

  const _EasyImageViewerContent({
    required this.source,
    required this.config,
    this.onClose,
    this.onShare,
    this.onDelete,
    this.onError,
  });

  @override
  State<_EasyImageViewerContent> createState() =>
      _EasyImageViewerContentState();
}

class _EasyImageViewerContentState extends State<_EasyImageViewerContent>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  /// Key to force Image widget rebuild on retry.
  Key _imageKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.config.animationDuration,
    );
  }

  void _onRetry() {
    setState(() {
      _imageKey = UniqueKey();
    });
    context.read<EasyImageViewerCubit>().retry();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onDoubleTap(TapDownDetails details) {
    final cubit = context.read<EasyImageViewerCubit>();
    final state = cubit.state;

    if (state is! EasyImageViewerReady) return;

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    final targetScale = currentScale > widget.config.initialScale
        ? widget.config.initialScale
        : (widget.config.initialScale * 2)
            .clamp(widget.config.minScale, widget.config.maxScale);

    // Animate to target scale
    final position = details.localPosition;
    final endMatrix = Matrix4.identity()
      ..setEntry(0, 3, position.dx * (1 - targetScale))
      ..setEntry(1, 3, position.dy * (1 - targetScale))
      ..setEntry(0, 0, targetScale)
      ..setEntry(1, 1, targetScale);

    if (targetScale == widget.config.initialScale) {
      // Reset to center
      _animateToMatrix(Matrix4.identity());
    } else {
      _animateToMatrix(endMatrix);
    }

    cubit.onDoubleTap();
  }

  void _animateToMatrix(Matrix4 targetMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });

    _animationController.forward(from: 0);
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    final cubit = context.read<EasyImageViewerCubit>();
    final scale = _transformationController.value.getMaxScaleOnAxis();
    cubit.onScaleChanged(scale);
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.config.backgroundColor ?? Colors.black;
    final iconColor = widget.config.iconColor ?? Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: BlocConsumer<EasyImageViewerCubit, EasyImageViewerState>(
        listener: (context, state) {
          if (state is EasyImageViewerError) {
            widget.onError?.call(state.error ?? state.message);
          }
        },
        builder: (context, state) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Image viewer
              GestureDetector(
                onTap: () =>
                    context.read<EasyImageViewerCubit>().toggleControls(),
                onDoubleTapDown: widget.config.doubleTapToZoom &&
                        state is! EasyImageViewerError
                    ? _onDoubleTap
                    : null,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: widget.config.minScale,
                  maxScale: widget.config.maxScale,
                  onInteractionUpdate: _onInteractionUpdate,
                  // Disable gestures when image failed to load
                  panEnabled: state is! EasyImageViewerError,
                  scaleEnabled: state is! EasyImageViewerError,
                  child: Center(
                    child: _buildImage(context, state),
                  ),
                ),
              ),

              // Close button (always visible)
              if (widget.config.showCloseButton)
                _buildCloseButton(context, iconColor),

              // Top actions (visible when controls are shown)
              if (state is EasyImageViewerReady && state.controlsVisible)
                _buildTopActions(context, iconColor),

              // Bottom info
              if (state is EasyImageViewerReady &&
                  state.controlsVisible &&
                  widget.config.showImageInfo &&
                  state.imageWidth != null)
                _buildImageInfo(context, state, iconColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImage(BuildContext context, EasyImageViewerState state) {
    // Show error state with retry button
    if (state is EasyImageViewerError) {
      return _buildErrorWidget(context);
    }

    // Show loading state
    if (state is EasyImageViewerLoading) {
      return Semantics(
        label: 'Loading image',
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    // Show image
    return Semantics(
      label: 'Image viewer',
      child: Image(
        key: _imageKey,
        image: widget.source.toImageProvider(),
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            // Image loaded synchronously (from cache)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<EasyImageViewerCubit>().onImageLoadSuccess();
              }
            });
            return child;
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: frame != null
                ? Builder(builder: (context) {
                    // Image frame loaded
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        context.read<EasyImageViewerCubit>().onImageLoadSuccess();
                      }
                    });
                    return child;
                  })
                : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<EasyImageViewerCubit>().setError(
                'Failed to load image',
                error,
              );
            }
          });
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final iconColor = widget.config.iconColor ?? Colors.white;

    return Semantics(
      label: 'Failed to load image. Tap retry to try again.',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить изображение',
              style: TextStyle(color: Colors.white.withAlpha(179)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _onRetry,
              icon: Icon(Icons.refresh, color: iconColor),
              label: Text(
                'Повторить',
                style: TextStyle(color: iconColor),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: iconColor.withAlpha(128)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, Color iconColor) {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Semantics(
            button: true,
            label: widget.config.closeTooltip ?? 'Close',
            child: IconButton(
              icon: Icon(Icons.close, color: iconColor),
              tooltip: widget.config.closeTooltip ?? 'Close',
              onPressed: () {
                widget.onClose?.call();
                if (widget.onClose == null) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopActions(BuildContext context, Color iconColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withAlpha(128),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Spacer for close button (close button is always visible separately)
                const SizedBox(width: 48),

                // Title
                if (widget.config.title != null)
                  Expanded(
                    child: Text(
                      widget.config.title!,
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.config.showShareButton && widget.onShare != null)
                      IconButton(
                        icon: Icon(Icons.share, color: iconColor),
                        tooltip: widget.config.shareTooltip ?? 'Share',
                        onPressed: widget.onShare,
                      ),
                    if (widget.config.showDeleteButton &&
                        widget.onDelete != null)
                      IconButton(
                        icon: Icon(Icons.delete, color: iconColor),
                        tooltip: widget.config.deleteTooltip ?? 'Delete',
                        onPressed: widget.onDelete,
                      ),
                    if (!widget.config.showShareButton &&
                        !widget.config.showDeleteButton)
                      const SizedBox(width: 48),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageInfo(
    BuildContext context,
    EasyImageViewerReady state,
    Color iconColor,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withAlpha(128),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${state.imageWidth} × ${state.imageHeight}',
              style: TextStyle(
                color: iconColor.withAlpha(179),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
