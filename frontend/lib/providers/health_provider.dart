import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_glossary/services/health_check_service.dart';

enum HealthStatus { initial, loading, healthy, unhealthy }

/// Provider for the HealthCheckService
final healthCheckServiceProvider = Provider<HealthCheckService>((ref) {
  return HealthCheckService();
});

/// StateNotifier to manage the health status
class HealthStateNotifier extends StateNotifier<HealthStatus> {
  final HealthCheckService _healthCheckService;
  Timer? _resetTimer;

  HealthStateNotifier(this._healthCheckService): super(HealthStatus.initial) {
    _startResetTimer();
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(minutes: 10), () {
      state = HealthStatus.initial;
    });
  }

  Future<void> checkHealth() async {
    state = HealthStatus.loading;

    final isHealthy = await _healthCheckService.checkHealth();
    state = isHealthy ? HealthStatus.healthy : HealthStatus.unhealthy;

    _startResetTimer();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}

/// Provider for the health state notifier
final healthStateProvider = StateNotifierProvider<HealthStateNotifier, HealthStatus> ((ref) {
  final service = ref.watch(healthCheckServiceProvider);
  return HealthStateNotifier(service);
});

