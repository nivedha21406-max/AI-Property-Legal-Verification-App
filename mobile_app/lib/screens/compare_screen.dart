import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _ctrl1 = TextEditingController(text: '123/4A');
  final _ctrl2 = TextEditingController(text: '45/2');
  List<PropertyModel>? _results;
  Map<String, RiskAssessment> _risks = {};
  bool _loading = false;
  String? _error;

  Future<void> _compare() async {
    final a = _ctrl1.text.trim();
    final b = _ctrl2.text.trim();
    if (a.isEmpty || b.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });
    try {
      final props = await ApiService.compareProperties([a, b]);
      final risks = <String, RiskAssessment>{};
      for (final p in props) {
        risks[p.surveyNumber] = await ApiService.getRiskScore(p.surveyNumber);
      }
      setState(() {
        _results = props;
        _risks = risks;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Properties')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: TextField(controller: _ctrl1, decoration: const InputDecoration(labelText: 'Survey No. A'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _ctrl2, decoration: const InputDecoration(labelText: 'Survey No. B'))),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _compare,
              child: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Compare'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.riskHigh)),
          ],
          if (_results != null) ...[
            const SizedBox(height: 20),
            Row(
              children: _results!.map((p) {
                final risk = _risks[p.surveyNumber];
                return Expanded(
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.surveyNumber, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${p.village ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 10),
                          if (risk != null) ...[
                            StatusPill(text: risk.riskLevel, color: AppColors.riskColor(risk.riskLevel)),
                            const SizedBox(height: 6),
                            Text('${risk.riskScore.toStringAsFixed(0)} / 100',
                                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.riskColor(risk.riskLevel))),
                          ],
                          const Divider(height: 24),
                          _cmpRow('Type', p.propertyType ?? '—'),
                          _cmpRow('Area', p.areaSqft != null ? '${p.areaSqft!.toStringAsFixed(0)} sqft' : '—'),
                          _cmpRow('Cases', '${risk?.activeCases ?? 0}'),
                          _cmpRow('Liens', '${risk?.activeEncumbrances ?? 0}'),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cmpRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
