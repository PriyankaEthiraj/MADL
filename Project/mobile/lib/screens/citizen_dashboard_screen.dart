import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/complaint_service.dart';
import 'complaint_category_screen.dart';
import 'complaint_detail_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComplaintService>().loadComplaints();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _CitizenHomeTab(),
      const _CitizenComplaintsTab(),
      const _CitizenProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Complaints'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComplaintCategoryScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Report Issue'),
            )
          : null,
    );
  }
}

class _CitizenHomeTab extends StatelessWidget {
  const _CitizenHomeTab();

  bool _isVerificationStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'pending citizen verification' || normalized == 'resolving verification';
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthService>().user?['name'] ?? 'Citizen';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart City', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Welcome, $userName', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    title: 'Pending',
                    color: Colors.red,
                    countSelector: (items) => items.where((e) => '${e['status']}'.toLowerCase() == 'pending').length,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    title: 'In Progress',
                    color: Colors.amber.shade700,
                    countSelector: (items) {
                      final status = items.map((e) => '${e['status']}'.toLowerCase());
                      return status.where((s) => s == 'in progress' || s == 'in_progress').length;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    title: 'Resolving Verification',
                    color: Colors.orange,
                    countSelector: (items) {
                      final status = items.map((e) => '${e['status']}'.toLowerCase());
                      return status.where(_isVerificationStatus).length;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    title: 'Solved',
                    color: Colors.green,
                    countSelector: (items) {
                      final status = items.map((e) => '${e['status']}'.toLowerCase());
                      return status.where((s) => s == 'resolved' || s == 'solved' || s == 'closed').length;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.add_location_alt),
                title: const Text('Create New Complaint'),
                subtitle: const Text('Capture geo-tagged photo/video and submit issue'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ComplaintCategoryScreen()),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.color,
    required this.countSelector,
  });

  final String title;
  final Color color;
  final int Function(List<Map<String, dynamic>>) countSelector;

  @override
  Widget build(BuildContext context) {
    final complaints = context.watch<ComplaintService>().complaints;
    final count = countSelector(complaints);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: 8),
          Text('$count', style: Theme.of(context).textTheme.headlineSmall),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _CitizenComplaintsTab extends StatelessWidget {
  const _CitizenComplaintsTab();

  bool _isVerificationStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'pending citizen verification' || normalized == 'resolving verification';
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending citizen verification':
      case 'resolving verification':
        return 'Resolving Verification';
      case 'resolved':
      case 'solved':
      case 'closed':
        return 'Solved';
      case 'in progress':
      case 'in_progress':
        return 'In Progress';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'pending') return Colors.red;
    if (s == 'in progress' || s == 'in_progress') return Colors.amber.shade700;
    if (s == 'pending citizen verification' || s == 'resolving verification') return Colors.orange;
    if (s == 'reopened') return Colors.redAccent;
    if (s == 'resolved' || s == 'solved' || s == 'closed') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ComplaintService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: RefreshIndicator(
        onRefresh: service.loadComplaints,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: service.complaints.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final c = service.complaints[index];
            final status = '${c['status'] ?? 'Pending'}';
            final displayStatus = _getStatusLabel(status);
            return Card(
              child: ListTile(
                title: Text('${c['type'] ?? 'General'}'),
                subtitle: Text(
                  '${c['description'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Chip(
                  backgroundColor: _statusColor(status).withValues(alpha: 0.12),
                  label: Text(displayStatus, style: TextStyle(color: _statusColor(status))),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ComplaintDetailScreen(id: c['id'] as int)),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CitizenProfileTab extends StatelessWidget {
  const _CitizenProfileTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user['name'] ?? 'Citizen'}', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('${user['email'] ?? '-'}'),
                  const SizedBox(height: 6),
                  Text('${user['phone'] ?? '-'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
