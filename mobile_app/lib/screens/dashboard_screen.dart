import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'property_detail_screen.dart';
import 'search_screen.dart';
import 'compare_screen.dart';
import 'document_scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<PropertyModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.listProperties();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LandCheck AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: StatusPill(text: user?.role ?? '', color: AppColors.gold),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          setState(() => _future = ApiService.listProperties());
          return _future;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome, ${user?.fullName.split(' ').first ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            const Text('Verify property legal status before you decide.',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.search,
                    label: 'Search Property',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.compare_arrows,
                    label: 'Compare',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompareScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _QuickAction(
              icon: Icons.document_scanner_outlined,
              label: 'Scan Document (AI/NLP survey no. extraction)',
              wide: true,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DocumentScanScreen())),
            ),
            const SizedBox(height: 24),
            Text('Recently Tracked Properties', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FutureBuilder<List<PropertyModel>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.only(top: 40), child: LoadingView());
                }
                if (snap.hasError) {
                  return ErrorView(
                    message: 'Could not reach backend.\nCheck ApiService.baseUrl and that the server is running.',
                    onRetry: () => setState(() => _future = ApiService.listProperties()),
                  );
                }
                final props = snap.data ?? [];
                if (props.isEmpty) return const EmptyState(message: 'No properties yet.');
                return Column(
                  children: props
                      .map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PropertyTile(property: p),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool wide;

  const _QuickAction({required this.icon, required this.label, required this.onTap, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.gold, size: 22),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyTile extends StatelessWidget {
  final PropertyModel property;
  const _PropertyTile({required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.navy.withOpacity(0.08),
          child: const Icon(Icons.home_work_outlined, color: AppColors.navy),
        ),
        title: Text('Survey No. ${property.surveyNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${property.village ?? ''}, ${property.district ?? ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => PropertyDetailScreen(surveyNumber: property.surveyNumber))),
      ),
    );
  }
}
