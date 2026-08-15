import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'property_detail_screen.dart';

class DocumentScanScreen extends StatefulWidget {
  const DocumentScanScreen({super.key});

  @override
  State<DocumentScanScreen> createState() => _DocumentScanScreenState();
}

class _DocumentScanScreenState extends State<DocumentScanScreen> {
  final _ctrl = TextEditingController(
    text: "This sale deed pertains to Survey No. 200/9 situated in Padi village. "
        "Patta No. 77102 was registered on 22/03/2024 at the Ambattur Sub-Registrar Office. "
        "Vendor: J. Anbu. Purchaser: A. Fathima.",
  );
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  Future<void> _extract() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await ApiService.extractDocument(_ctrl.text);
      setState(() => _result = res);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final matched = (_result?['matched_properties'] as List? ?? []);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Document Extraction')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Paste text from a sale deed, patta certificate, or court document. '
            'The NLP engine identifies survey numbers, patta numbers, dates, and named entities, '
            'then automatically links them to matching property records.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'Paste document text here...'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _extract,
              icon: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_loading ? 'Analyzing...' : 'Extract with AI'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.riskHigh)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            SectionCard(
              title: 'Extracted Entities',
              icon: Icons.text_snippet_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tagRow('Survey Numbers', _result!['survey_numbers_found']),
                  _tagRow('Patta Numbers', _result!['patta_numbers_found']),
                  _tagRow('Dates', _result!['dates_found']),
                  _tagRow('Named Entities', _result!['entities']),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Matched Property Records',
              icon: Icons.link,
              child: matched.isEmpty
                  ? const EmptyState(message: 'No matching properties found in system.')
                  : Column(
                      children: matched.map<Widget>((p) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.verified_outlined, color: AppColors.riskLow),
                          title: Text('Survey No. ${p['survey_number']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${p['village'] ?? ''}, ${p['district'] ?? ''}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PropertyDetailScreen(surveyNumber: p['survey_number'])),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tagRow(String label, dynamic items) {
    final list = (items as List? ?? []).cast<String>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          list.isEmpty
              ? const Text('None found', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: list.map((e) => Chip(label: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
                ),
        ],
      ),
    );
  }
}
