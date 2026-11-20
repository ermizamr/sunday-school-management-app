import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef AppRefreshCallback = Future<void> Function();

class AppRefreshController extends ChangeNotifier {
  AppRefreshController({required AppRefreshCallback defaultOnRefresh})
    : _defaultOnRefresh = defaultOnRefresh;

  final AppRefreshCallback _defaultOnRefresh;
  AppRefreshCallback? _onRefresh;
  bool _disposed = false;
  bool _notifyScheduled = false;

  Future<void> _runRefresh() async {
    await _defaultOnRefresh();

    final callback = _onRefresh;
    if (callback == null) return;

    Session? session;
    try {
      session = Supabase.instance.client.auth.currentSession;
    } catch (_) {
      session = null;
    }

    // If the global refresh logged the user out, skip page refresh.
    if (session == null) return;

    await callback();
  }

  AppRefreshCallback get onRefresh => _runRefresh;

  void setOnRefresh(AppRefreshCallback? callback) {
    if (identical(_onRefresh, callback)) return;
    _onRefresh = callback;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final inBuild =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (inBuild) {
      _scheduleNotify();
      return;
    }

    notifyListeners();
  }

  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (_disposed) return;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
