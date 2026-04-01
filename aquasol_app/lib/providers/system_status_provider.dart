import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SystemStatus { stable, warning, aiActive, success, offline }

class SystemStatusState {
  final SystemStatus status;
  final String message;

  const SystemStatusState({
    this.status = SystemStatus.stable,
    this.message = "System Stable",
  });

  SystemStatusState copyWith({SystemStatus? status, String? message}) =>
      SystemStatusState(
        status: status ?? this.status,
        message: message ?? this.message,
      );
}

class SystemStatusNotifier extends StateNotifier<SystemStatusState> {
  WebSocketChannel? _aiDecisionChannel;
  WebSocketChannel? _systemStatusChannel;

  static const String _wsBase = "ws://localhost:8000/ws";

  SystemStatusNotifier() : super(const SystemStatusState()) {
    _connect();
  }

  void _connect() {
    try {
      _aiDecisionChannel = WebSocketChannel.connect(
          Uri.parse("$_wsBase/ai-decisions"));
      _aiDecisionChannel!.stream.listen(_onAiDecision, onError: _onError);

      _systemStatusChannel = WebSocketChannel.connect(
          Uri.parse("$_wsBase/system-status"));
      _systemStatusChannel!.stream.listen(_onSystemStatus, onError: _onError);
    } catch (e) {
      state = const SystemStatusState(
          status: SystemStatus.offline, message: "Connecting to system...");
    }
  }

  void _onAiDecision(dynamic raw) {
    try {
      final data = jsonDecode(raw.toString());
      if (data['event'] == 'ai_command_queued') {
        state = SystemStatusState(
          status: SystemStatus.aiActive,
          message: "⚡ AI Optimization Active: Irrigation queued",
        );
      } else if (data['event'] == 'irrigation_feedback') {
        state = SystemStatusState(
          status: SystemStatus.success,
          message: data['message'] ?? "Optimization Complete",
        );
      }

      // Auto-revert to stable after 10 seconds for any temporary status
      if (state.status != SystemStatus.stable && state.status != SystemStatus.offline) {
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            state = const SystemStatusState(
                status: SystemStatus.stable, message: "System Stable");
          }
        });
      }
    } catch (_) {}
  }

  void _onSystemStatus(dynamic raw) {
    try {
      final data = jsonDecode(raw.toString());
      final msg = data['message']?.toString() ?? "System Stable";
      state = SystemStatusState(status: SystemStatus.stable, message: msg);
    } catch (_) {}
  }

  void _onError(dynamic error) {
    state = const SystemStatusState(
        status: SystemStatus.offline, message: "📡 Reconnecting...");
  }

  @override
  void dispose() {
    _aiDecisionChannel?.sink.close();
    _systemStatusChannel?.sink.close();
    super.dispose();
  }
}

final systemStatusProvider =
    StateNotifierProvider<SystemStatusNotifier, SystemStatusState>(
        (ref) => SystemStatusNotifier());
