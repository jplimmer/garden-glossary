import 'package:flutter/material.dart';
import 'dart:async';
import 'package:garden_glossary/services/health_check_service.dart';

enum HealthStatus { initial, loading, healthy, unhealthy }

class HealthCheckButton extends StatefulWidget {
  final HealthCheckService healthCheckService;

  const HealthCheckButton({
    super.key,
    required this.healthCheckService,
  });

  @override
  HealthCheckButtonState createState() => HealthCheckButtonState();
}

class HealthCheckButtonState extends State<HealthCheckButton> {

  HealthStatus _status = HealthStatus.initial;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _startResetTimer();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(minutes: 10), () {
      if (mounted) {
        setState(() {
          _status = HealthStatus.initial;
        });
      }
    });
  }

  Future<void> _checkHealth() async {
    setState(() {
      _status = HealthStatus.loading;
    });

    final isHealthy = await widget.healthCheckService.checkHealth();

    if (mounted) {
      setState(() {
        _status = isHealthy ? HealthStatus.healthy : HealthStatus.unhealthy;
      });

      _startResetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color iconColor;
    Widget icon;

    switch (_status) {
      case HealthStatus.initial:
        backgroundColor = theme.colorScheme.onPrimary;
        iconColor = theme.colorScheme.primary;
        icon = const Icon(Icons.favorite_border);
        break;
      case HealthStatus.loading:
        backgroundColor = theme.colorScheme.onPrimary;
        iconColor = theme.colorScheme.primary;
        icon = const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
        break;
      case HealthStatus.healthy:
        backgroundColor = Colors.green;
        iconColor = theme.colorScheme.onPrimary;
        icon = const Icon(Icons.check);
        break;
      case HealthStatus.unhealthy:
        backgroundColor = Colors.red;
        iconColor = theme.colorScheme.onPrimary;
        icon = const Icon(Icons.cancel);
        break;
    }

    return FloatingActionButton(
      onPressed: _status == HealthStatus.loading ? null : _checkHealth,
      mini: true,
      backgroundColor: backgroundColor,
      foregroundColor: iconColor,
      child: icon,
    );
  }

}

