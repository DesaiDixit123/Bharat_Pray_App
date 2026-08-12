import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jap_models.dart';
import 'api_service.dart';
import 'jap_offline_repository.dart';

typedef EffectTriggerCallback =
    void Function(Offset tapPosition, double intensity);
typedef CompletionCallback = void Function();

/// Core state machine and session controller for Jap meditation chanting.
/// Governs the complete 108 completion engine, Darshan unlocking gates, and idempotency.
class JapSessionController extends ChangeNotifier {
  final JapConfig config;
  JapLifecycle _lifecycle = JapLifecycle.idle;

  int _currentCount = 0;
  int _completedMalas = 0;
  DateTime? _startedAt;
  DateTime _lastActionAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  EffectTriggerCallback? onEffectTrigger;
  CompletionCallback? onCompletion;

  static const Duration tapDebounceThreshold = Duration(milliseconds: 220);
  bool _isDisposed = false;
  bool _isDarshanUnlocked = false;
  bool _hasFiredCompletion = false;

  // Getters
  JapLifecycle get lifecycle => _lifecycle;
  int get currentCount => _currentCount;
  int get targetCount => config.targetCount;
  int get completedMalas => _completedMalas;
  int get totalLifetimeCount => (_completedMalas * targetCount) + _currentCount;
  double get progressFraction => (_currentCount / targetCount).clamp(0.0, 1.0);
  bool get isCompleted =>
      _currentCount >= targetCount || _lifecycle == JapLifecycle.completed;
  bool get isDarshanUnlocked => _isDarshanUnlocked || isCompleted;
  bool get canChant =>
      (_lifecycle == JapLifecycle.started ||
          _lifecycle == JapLifecycle.inProgress) &&
      !isCompleted;
  DateTime? get startedAt => _startedAt;
  DateTime get lastActionAt => _lastActionAt;

  JapSessionController({
    required this.config,
    int initialCount = 0,
    int initialMalas = 0,
    this.onEffectTrigger,
    this.onCompletion,
  }) : _currentCount = initialCount.clamp(0, config.targetCount),
       _completedMalas = initialMalas {
    if (_currentCount >= config.targetCount) {
      _lifecycle = JapLifecycle.completed;
      _isDarshanUnlocked = true;
      _hasFiredCompletion = true;
    } else if (_currentCount > 0) {
      _lifecycle = JapLifecycle.inProgress;
    } else {
      _lifecycle = JapLifecycle.idle;
    }
  }

  String _sessionId = '';
  String get sessionId => _sessionId;

  /// Initializes or restores session state from local offline repository
  Future<void> initializeFromStorage({String? userId}) async {
    final session = await JapOfflineRepository.getSession(
      config.id,
      defaultTarget: config.targetCount,
      userId: userId,
    );

    _sessionId = session.sessionId;
    _currentCount = session.currentCount;
    _completedMalas = session.completedMalas;
    _startedAt = session.startedAt;
    _lastActionAt = session.lastJapAt;

    if (_currentCount >= config.targetCount || session.isCompleted) {
      _lifecycle = JapLifecycle.completed;
      _isDarshanUnlocked = true;
      _hasFiredCompletion = true;
    } else if (session.status == JapLifecycle.paused) {
      _lifecycle = JapLifecycle.paused;
    } else if (_currentCount > 0) {
      _lifecycle = JapLifecycle.inProgress;
    } else {
      _lifecycle = JapLifecycle.idle;
    }

    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Starts or resumes chanting session
  void start() {
    if (_isDisposed) return;
    _startedAt ??= DateTime.now();

    if (_currentCount >= config.targetCount) {
      _lifecycle = JapLifecycle.completed;
      _isDarshanUnlocked = true;
    } else if (_currentCount > 0) {
      _lifecycle = JapLifecycle.inProgress;
    } else {
      _lifecycle = JapLifecycle.started;
    }
    notifyListeners();
  }

  /// Pauses the active chanting session
  void pause() {
    if (_isDisposed) return;
    if (_lifecycle == JapLifecycle.started ||
        _lifecycle == JapLifecycle.inProgress) {
      _lifecycle = JapLifecycle.paused;
      notifyListeners();
    }
  }

  /// Resumes a paused session
  void resume() {
    if (_isDisposed) return;
    if (_lifecycle == JapLifecycle.paused) {
      _lifecycle = _currentCount > 0
          ? JapLifecycle.inProgress
          : JapLifecycle.started;
      notifyListeners();
    }
  }

  /// Increments Jap count by 1 with hardware debouncing and boundary protection
  bool performChant({Offset tapPosition = const Offset(200, 400)}) {
    if (_isDisposed) return false;

    // 1. Session State Validation
    if (_lifecycle == JapLifecycle.idle) {
      start();
    }
    if (_lifecycle == JapLifecycle.paused ||
        _lifecycle == JapLifecycle.completed ||
        _lifecycle == JapLifecycle.darshanReveal ||
        _lifecycle == JapLifecycle.darshanActive) {
      return false;
    }

    // 2. Double-Tap Hardware Debounce Protection (220ms)
    final now = DateTime.now();
    if (now.difference(_lastTapTime) < tapDebounceThreshold) {
      return false; // Accidental double tap prevented
    }
    _lastTapTime = now;
    _lastActionAt = now;

    // 3. Count Boundary Enforcement (Strictly <= targetCount, e.g. 108 -> 109 is blocked)
    if (_currentCount >= config.targetCount) {
      _lifecycle = JapLifecycle.completed;
      _isDarshanUnlocked = true;
      notifyListeners();
      return false;
    }

    // 4. Atomic Increment
    _currentCount++;

    // 5. State Transition & Completion Detection
    final reachedTarget = (_currentCount >= config.targetCount);
    if (reachedTarget) {
      _lifecycle = JapLifecycle.completed;
      _isDarshanUnlocked = true;
    } else {
      _lifecycle = JapLifecycle.inProgress;
    }

    // 6. Local Offline-First Persistence
    unawaited(persistState());

    // 7. Safe Effect Engine Trigger (Animation failure must NOT lose count)
    try {
      if (onEffectTrigger != null) {
        onEffectTrigger!(tapPosition, 1.0);
      }
    } catch (e) {
      debugPrint(
        '[JapSessionController] Effect trigger caught exception: $e. Count preserved.',
      );
    }

    // 8. Exactly-Once Completion Callback Execution
    if (reachedTarget && !_hasFiredCompletion) {
      _hasFiredCompletion = true;
      try {
        if (onCompletion != null) {
          onCompletion!();
        }
      } catch (e) {
        debugPrint(
          '[JapSessionController] Completion callback caught exception: $e',
        );
      }
    }

    // 9. Queue Asynchronous Background Sync at Milestones (Non-blocking)
    _queueBackgroundSyncIfMilestone();

    // 10. Reactive UI Update
    notifyListeners();
    return true;
  }

  /// Advances completed Malas count and resets current round to 0
  void advanceMala() {
    if (_isDisposed) return;
    _completedMalas++;
    _currentCount = 0;
    _hasFiredCompletion = false;
    _lifecycle = JapLifecycle.started;

    unawaited(persistState());
    notifyListeners();
  }

  /// Resets the current round session to 0
  void resetCurrentRound() {
    if (_isDisposed) return;
    _currentCount = 0;
    _hasFiredCompletion = false;
    _lifecycle = JapLifecycle.idle;

    unawaited(persistState());
    notifyListeners();
  }

  /// Transitions state to Darshan Reveal ONLY after valid completion
  bool transitionToDarshanReveal() {
    if (_isDisposed) return false;
    if (!isDarshanUnlocked && !isCompleted) {
      debugPrint(
        '[JapSessionController] Cannot reveal Darshan before completing target count.',
      );
      return false;
    }
    _lifecycle = JapLifecycle.darshanReveal;
    notifyListeners();
    return true;
  }

  /// Transitions state to Darshan Active
  bool transitionToDarshanActive() {
    if (_isDisposed) return false;
    if (!isDarshanUnlocked && !isCompleted) {
      return false;
    }
    _lifecycle = JapLifecycle.darshanActive;
    notifyListeners();
    return true;
  }

  /// Explicitly flushes current session state to disk cache
  Future<void> persistState({String? userId}) async {
    if (_sessionId.isEmpty) {
      _sessionId =
          'session_${config.id}_${DateTime.now().millisecondsSinceEpoch}';
    }
    final record = JapOfflineSessionRecord(
      sessionId: _sessionId,
      userId: userId,
      japId: config.id,
      currentCount: _currentCount,
      targetCount: config.targetCount,
      completedMalas: _completedMalas,
      status: _lifecycle,
      startedAt: _startedAt ?? DateTime.now(),
      lastJapAt: _lastActionAt,
      isCompleted: isCompleted,
      isDirty: true,
    );
    await JapOfflineRepository.saveSession(record);
  }

  void _queueBackgroundSyncIfMilestone() {
    final isQuarter = _currentCount == (config.targetCount * 0.25).round();
    final isHalf = _currentCount == (config.targetCount * 0.50).round();
    final isThreeQuarter = _currentCount == (config.targetCount * 0.75).round();
    final isComplete = _currentCount >= config.targetCount;
    final isStepOfTen = (_currentCount % 10 == 0);

    if (isQuarter || isHalf || isThreeQuarter || isComplete || isStepOfTen) {
      // Fire-and-forget background cloud sync
      unawaited(() async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final token =
              prefs.getString('token') ?? prefs.getString('auth_token') ?? '';
          if (token.isNotEmpty) {
            await ApiService.syncJapProgress(
              token,
              config.id,
              _currentCount,
              completedMalas: _completedMalas,
              sessionId: _sessionId,
              lastJapAt: _lastActionAt,
            );
          }
        } catch (e) {
          debugPrint(
            '[JapSessionController] Background sync queued for retry: $e',
          );
        }
      }());
    }
  }

  /// Creates a snapshot representation of current session state
  JapSessionState toSnapshot() {
    return JapSessionState(
      japId: config.id,
      currentCount: _currentCount,
      targetCount: config.targetCount,
      completedMalas: _completedMalas,
      lifecycle: _lifecycle,
      startedAt: _startedAt ?? DateTime.now(),
      lastActionAt: _lastActionAt,
      isMaskRevealed:
          _lifecycle == JapLifecycle.darshanReveal ||
          _lifecycle == JapLifecycle.darshanActive,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
