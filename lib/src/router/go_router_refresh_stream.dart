import 'dart:async';
import 'package:flutter/foundation.dart';

/// Утилита для обновления go_router при изменении стрима.
///
/// Преобразует Stream в ChangeNotifier, который можно передать
/// в GoRouter.refreshListenable для автоматического обновления
/// маршрутов при изменении состояния.
///
/// Пример использования:
/// ```dart
/// GoRouter(
///   refreshListenable: GoRouterRefreshStream(authBloc.stream),
///   // ...
/// );
/// ```
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
