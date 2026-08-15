import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<AlertModel>> _future;
  WebSocketChannel? _channel;
  final List<Map<String, dynamic>> _liveAlerts = [];
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getAlerts();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiService.wsUrl));
      if (mounted) setState(() => _connected = true);
      _channel!.stream.listen(
        (event) {
          if (!mounted) return;
          final data = jsonDecode(event);
          setState(() => _liveAlerts.insert(0, data));
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
        },
        onError: (_) {
          if (mounted) setState(() => _connected = false);
        },
      );
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Litigation Alerts'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _connected ? Colors.greenAccent : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(_connected ? 'Live' : 'Offline', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _future = ApiService.getAlerts()),
        child: FutureBuilder<List<AlertModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
            if (snap.hasError) {
              return ErrorView(message: 'Could not load alerts.', onRetry: () => setState(() => _future = ApiService.getAlerts()));
            }
            final stored = snap.data ?? [];
            if (_liveAlerts.isEmpty && stored.isEmpty) {
              return const EmptyState(message: 'No litigation alerts yet.', icon: Icons.notifications_none);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_liveAlerts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Live updates', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.gold)),
                  ),
                  ..._liveAlerts.map((a) => _AlertCard(
                        message: a['message'] ?? '',
                        severity: a['severity'] ?? 'info',
                        time: 'Just now',
                        isLive: true,
                      )),
                  const SizedBox(height: 12),
                ],
                ...stored.map((a) => _AlertCard(message: a.message, severity: a.severity, time: a.createdAt)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String message;
  final String severity;
  final String time;
  final bool isLive;

  const _AlertCard({required this.message, required this.severity, required this.time, this.isLive = false});

  Color get _color {
    switch (severity) {
      case 'critical':
        return AppColors.riskHigh;
      case 'warning':
        return AppColors.riskMedium;
      default:
        return AppColors.navy;
    }
  }

  IconData get _icon {
    switch (severity) {
      case 'critical':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: _color.withOpacity(0.12), child: Icon(_icon, color: _color, size: 20)),
        title: Text(message, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        subtitle: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: isLive ? const StatusPillDot() : null,
      ),
    );
  }
}

class StatusPillDot extends StatelessWidget {
  const StatusPillDot({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
    );
  }
}
