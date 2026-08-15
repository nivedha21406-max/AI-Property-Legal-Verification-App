import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.navy,
                  child: Text(
                    (user?.fullName.isNotEmpty == true ? user!.fullName[0] : '?').toUpperCase(),
                    style: const TextStyle(color: AppColors.gold, fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.fullName ?? 'User', style: Theme.of(context).textTheme.titleLarge),
                Text(user?.email ?? 'No email', style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                if (user != null) Chip(label: Text((user.role).toUpperCase())),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend Connection', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(ApiService.baseUrl, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  const Text(
                    'Change ApiService.baseUrl in lib/services/api_service.dart to point at your server.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.riskHigh),
            label: const Text('Log Out', style: TextStyle(color: AppColors.riskHigh)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.riskHigh)),
          ),
        ],
      ),
    );
  }
}
