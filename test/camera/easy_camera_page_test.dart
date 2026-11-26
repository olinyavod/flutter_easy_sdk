import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart' show CameraInterface, PreviewSize;
// The SDK intentionally uses native Flutter Material, not material_ui types.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easy_sdk/flutter_easy_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CameraTestTransport transport;
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sdk-camera-test-');
    transport = CameraTestTransport()..install();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => directory.path,
    );
  });

  tearDown(() async {
    transport.uninstall();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await directory.delete(recursive: true);
  });

  for (final title in ['Фото профиля', 'Profile photo']) {
    for (final brightness in Brightness.values) {
      testWidgets(
          '$title $brightness applies each top inset once at 320px scale 2',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semantics = tester.ensureSemantics();
        Rect? initialPreview;
        Rect? initialShutter;
        for (final topInset in [0.0, 24.0, 48.0]) {
          final insets = EdgeInsets.only(top: topInset, bottom: 24);
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: insets,
                viewPadding: insets,
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: EasyCameraPage(config: EasyCameraConfig(title: title)),
          ));
          await pumpCameraReady(tester);
          expect(find.bySemanticsLabel(title), findsOneWidget);
          final titleFinder = find.text(title);
          expect(titleFinder.hitTestable(), findsOneWidget);
          final text = tester.widget<Text>(titleFinder);
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
          final row = find
              .ancestor(
                of: find.byIcon(Icons.arrow_back),
                matching: find.byType(Row),
              )
              .first;
          final rowBounds = tester.getRect(row);
          expect(rowBounds.top, closeTo(topInset + 8, 0.01));
          final titleBounds = tester.getRect(titleFinder);
          expect(titleBounds.center.dx, closeTo(160, 0.01));
          expect(titleBounds.center.dy, closeTo(rowBounds.center.dy, 0.01));
          for (final icon in [Icons.arrow_back, Icons.flash_auto]) {
            final control = find.byIcon(icon);
            expect(control.hitTestable(), findsOneWidget);
            final target = find
                .ancestor(of: control, matching: find.byType(SizedBox))
                .first;
            final bounds = tester.getRect(target);
            expect(bounds.size, const Size(48, 48));
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(320));
            expect(bounds.center.dx,
                closeTo(icon == Icons.arrow_back ? 40 : 280, 0.01));
            expect(bounds.center.dy, closeTo(rowBounds.center.dy, 0.01));
          }
          final shutter = find.byType(AwesomeCaptureButton);
          expect(shutter, findsOneWidget);
          expect(shutter.hitTestable(), findsOneWidget);
          final previewBounds = tester.getRect(find.byType(Texture));
          final shutterBounds = tester.getRect(shutter);
          initialPreview ??= previewBounds;
          initialShutter ??= shutterBounds;
          expect(previewBounds, initialPreview);
          expect(shutterBounds, initialShutter);
          expect(transport.physicalButtonEnabled, isFalse);
          expect(tester.takeException(), isNull);
        }
        semantics.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets(
      'null hooks preserve the default shutter, temporary destination and stream callback',
      (tester) async {
    EasyCameraResult? captured;
    await tester.pumpWidget(MaterialApp(
        home: EasyCameraPage(onCapture: (value) => captured = value)));
    await pumpCameraReady(tester);
    await tester.tap(find.byType(AwesomeCaptureButton));
    await pumpCameraUntil(tester, () => captured != null);
    expect(File(captured!.filePath).parent.path, directory.path);
    expect(
        File(captured!.filePath).uri.pathSegments.last, startsWith('photo_'));
    expect(transport.photos, 1);
    expect(
        await tester.runAsync(() => File(captured!.filePath).exists()), isTrue);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'optional hooks await the real native Future and onPhoto after SDK stream disposal',
      (tester) async {
    final gate = Completer<void>();
    final raw = File('${directory.path}/owned.jpg');
    var onPhoto = 0;
    var streamCapture = 0;
    Future<CaptureRequest>? capture;
    transport.writePhoto = (file) async {
      await gate.future;
      await file.writeAsBytes([1, 2, 3]);
      return true;
    };
    await tester.pumpWidget(MaterialApp(
        home: EasyCameraPage(
      photoPathBuilder: (sensors) async =>
          SingleCaptureRequest(raw.path, sensors.single),
      captureButtonBuilder: (context, state) => SizedBox(
        width: 80,
        height: 80,
        child: IconButton(
          tooltip: 'Managed shutter',
          onPressed: () => capture =
              (state as PhotoCameraState).takePhoto(onPhoto: (_) => onPhoto++),
          icon: const Icon(Icons.camera_alt),
        ),
      ),
      onCapture: (_) => streamCapture++,
    )));
    await pumpCameraReady(tester);
    expect(find.byType(AwesomeCaptureButton), findsNothing);
    await tester.tap(find.byTooltip('Managed shutter'));
    await pumpCameraUntil(tester, () => transport.photos == 1);
    expect(onPhoto, 0);
    expect(await tester.runAsync(raw.exists), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(transport.stops, 1);
    gate.complete();
    var done = false;
    unawaited(capture!.then((_) => done = true));
    await pumpCameraUntil(tester, () => done);
    expect(onPhoto, 1);
    expect(streamCapture, 0);
    expect(await tester.runAsync(raw.readAsBytes), [1, 2, 3]);
    expect(tester.takeException(), isNull);
  });
}

/// Mocks only the platform transport; CameraAwesomeBuilder and takePhoto are real.
class CameraTestTransport {
  final _channels = <BasicMessageChannel<Object?>>[];
  Future<bool> Function(File) writePhoto = (file) async {
    await file.writeAsBytes([1, 2, 3]);
    return true;
  };
  int photos = 0;
  int stops = 0;
  bool? physicalButtonEnabled;
  String? lastPath;

  void install() {
    CamerawesomePlugin.currentState = CameraRunningState.stopped;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    void register(String method, Future<Object?> Function(Object?) handler) {
      final channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.CameraInterface.$method',
        CameraInterface.codec,
      );
      _channels.add(channel);
      messenger.setMockDecodedMessageHandler(channel, handler);
    }

    for (final method in [
      'setFilter',
      'setCaptureMode',
      'setZoom',
      'setFlashMode',
      'setSensor'
    ]) {
      register(method, (_) async => [null]);
    }
    register('setupCamera', (arguments) async {
      physicalButtonEnabled = (arguments! as List<Object?>)[4] as bool;
      return [true];
    });
    register('start', (_) async => [true]);
    register('stop', (_) async {
      stops++;
      return [true];
    });
    register('getPreviewTextureId', (_) async => [1]);
    register('getEffectivPreviewSize',
        (_) async => [PreviewSize(width: 640, height: 480)]);
    register('takePhoto', (arguments) async {
      final paths = (arguments! as List<Object?>)[1]! as List<Object?>;
      lastPath = paths.single! as String;
      photos++;
      try {
        return [await writePhoto(File(lastPath!))];
      } catch (_) {
        return ['capture_failed', 'Synthetic native failure', null];
      }
    });
    messenger.setMockMethodCallHandler(
        const MethodChannel('camerawesome/orientation'), (_) async => null);
  }

  void uninstall() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in _channels) {
      messenger.setMockDecodedMessageHandler(channel, null);
    }
    messenger.setMockMethodCallHandler(
        const MethodChannel('camerawesome/orientation'), null);
  }
}

Future<void> pumpCameraReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

Future<void> pumpCameraUntil(WidgetTester tester, bool Function() done) async {
  for (var frame = 0; frame < 250 && !done(); frame++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(done(), isTrue,
      reason: 'Native camera fixture did not finish within its bounded wait.');
}
