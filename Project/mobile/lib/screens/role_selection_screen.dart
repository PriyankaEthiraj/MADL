import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Role Access')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Role',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 32),
                _RoleActionButton(
                  icon: Icons.admin_panel_settings,
                  title: 'Admin',
                  color: const Color(0xFF4F46E5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(
                          expectedRole: 'admin',
                          title: 'Admin Login',
                          showRoleAccessButton: false,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _RoleActionButton(
                  icon: Icons.business,
                  title: 'Department',
                  color: const Color(0xFF0EA5E9),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(
                          expectedRole: 'department',
                          title: 'Department Login',
                          showRoleAccessButton: false,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class _RoleActionButton extends StatelessWidget {
  const _RoleActionButton({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
