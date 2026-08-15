import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/risk_gauge.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String surveyNumber;
  const PropertyDetailScreen({super.key, required this.surveyNumber});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late Future<_DetailBundle> _future;
  bool _generatingReport = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailBundle> _load() async {
    final property = await ApiService.searchBySurveyNumber(widget.surveyNumber);
    final risk = await ApiService.getRiskScore(widget.surveyNumber);
    final fraud = await ApiService.getFraudFlags(widget.surveyNumber);
    return _DetailBundle(property, risk, fraud);
  }

  Future<void> _generateReport() async {
    setState(() => _generatingReport = true);
    try {
      final url = await ApiService.generateReport(widget.surveyNumber);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report ready: $url')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
      }
    } finally {
      if (mounted) setState(() => _generatingReport = false);
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _fmtMoney(double? v) {
    if (v == null) return '—';
    return '₹${NumberFormat('#,##0').format(v)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Survey No. ${widget.surveyNumber}')),
      body: FutureBuilder<_DetailBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const LoadingView(message: 'Running AI risk analysis...');
          if (snap.hasError) {
            return ErrorView(
              message: snap.error.toString().replaceFirst('Exception: ', ''),
              onRetry: () => setState(() => _future = _load()),
            );
          }
          final bundle = snap.data!;
          final p = bundle.property;
          final risk = bundle.risk;
          final fraudFlags = (bundle.fraud['fraud_flags'] as List? ?? []);

          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Risk summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        RiskGauge(score: risk.riskScore, level: risk.riskLevel),
                        const SizedBox(height: 16),
                        Text(risk.recommendation, textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatChip(label: 'Active Cases', value: '${risk.activeCases}'),
                            _StatChip(label: 'Encumbrances', value: '${risk.activeEncumbrances}'),
                            _StatChip(label: 'Fraud Flags', value: '${fraudFlags.length}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _generatingReport ? null : _generateReport,
                            icon: _generatingReport
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: Text(_generatingReport ? 'Generating...' : 'Download Verification Report (PDF)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (fraudFlags.isNotEmpty)
                  SectionCard(
                    title: 'Fraud Detection Flags',
                    icon: Icons.warning_amber_rounded,
                    child: Column(
                      children: fraudFlags.map<Widget>((f) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 6, color: AppColors.riskHigh),
                              const SizedBox(width: 8),
                              Expanded(child: Text(f['detail'], style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                if (fraudFlags.isNotEmpty) const SizedBox(height: 16),

                SectionCard(
                  title: 'AI Risk Factors',
                  icon: Icons.psychology_outlined,
                  child: Column(
                    children: risk.factors
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.circle, size: 6, color: AppColors.gold),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                SectionCard(
                  title: 'Property Details',
                  icon: Icons.map_outlined,
                  child: Column(
                    children: [
                      _Row('Location', '${p.village ?? '—'}, ${p.taluk ?? '—'}, ${p.district ?? '—'}'),
                      _Row('Type', p.propertyType ?? '—'),
                      _Row('Area', p.areaSqft != null ? '${p.areaSqft!.toStringAsFixed(0)} sq.ft' : '—'),
                      _Row('Current Owner', p.currentOwner ?? '—'),
                      _Row('Patta No.', p.pattaNumber ?? '—'),
                      _Row('Chitta No.', p.chittaNumber ?? '—'),
                      _Row('Est. Market Value', _fmtMoney(p.marketValueEst)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SectionCard(
                  title: 'Ownership History',
                  icon: Icons.history_edu_outlined,
                  child: p.owners.isEmpty
                      ? const EmptyState(message: 'No ownership records found.')
                      : Column(
                          children: p.owners
                              .map((o) => Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(o.ownerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text('${o.acquisitionType} • ${o.documentNumber}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        Text('Registered: ${_fmtDate(o.registrationDate)} • ${o.registrarOffice ?? ''}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),

                SectionCard(
                  title: 'Encumbrances',
                  icon: Icons.account_balance_outlined,
                  child: p.encumbrances.isEmpty
                      ? const EmptyState(message: 'No encumbrances found.')
                      : Column(
                          children: p.encumbrances
                              .map((e) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text('${e.type[0].toUpperCase()}${e.type.substring(1)} — ${e.holderName}'),
                                    subtitle: Text(e.amount != null ? _fmtMoney(e.amount) : ''),
                                    trailing: StatusPill(
                                      text: e.status,
                                      color: e.status == 'active' ? AppColors.riskHigh : AppColors.riskLow,
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),

                SectionCard(
                  title: 'Litigation / Court Case Timeline',
                  icon: Icons.gavel_outlined,
                  child: p.courtCases.isEmpty
                      ? const EmptyState(message: 'No litigation records found.')
                      : Column(
                          children: p.courtCases.map((c) {
                            final active = c.status.toLowerCase() == 'pending';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border(left: BorderSide(color: active ? AppColors.riskHigh : AppColors.riskLow, width: 3)),
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text('${c.caseType} — ${c.caseNumber}',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      ),
                                      StatusPill(text: c.status, color: active ? AppColors.riskHigh : AppColors.riskLow),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(c.courtName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  Text(c.summary, style: const TextStyle(fontSize: 12.5)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Filed: ${_fmtDate(c.filedDate)}${c.nextHearingDate != null ? ' • Next hearing: ${_fmtDate(c.nextHearingDate)}' : ''}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailBundle {
  final PropertyModel property;
  final RiskAssessment risk;
  final Map<String, dynamic> fraud;
  _DetailBundle(this.property, this.risk, this.fraud);
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.navy)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}
