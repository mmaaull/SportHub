import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          child: Icon(
            Icons.person,
            size: 54,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            user?.name ?? '-',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            user?.email ?? '-',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ProfileItem(
          icon: Icons.badge_outlined,
          label: 'NIM',
          value: user?.nim ?? '-',
        ),
        _ProfileItem(
          icon: Icons.school_outlined,
          label: 'Fakultas',
          value: user?.faculty ?? '-',
        ),
        _ProfileItem(
          icon: Icons.verified_user_outlined,
          label: 'Role',
          value: user?.role ?? '-',
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppColors.primary,
        ),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}