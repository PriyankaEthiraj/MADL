import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'complaint_detail_screen.dart';
import 'login_screen.dart';
import 'resolution_verification_screen.dart';

class DepartmentDashboardScreen extends StatefulWidget {
  const DepartmentDashboardScreen({super.key});

  @override
  State<DepartmentDashboardScreen> createState() => _DepartmentDashboardScreenState();
}

class _DepartmentDashboardScreenState extends State<DepartmentDashboardScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _complaints = [];
  String _pageSize = 'all';

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  int _countByStatus(String status) {
    final normalized = status.toLowerCase();
    return _complaints.where((complaint) {
      final current = '${complaint['status'] ?? ''}'.toLowerCase();
      return current == normalized;
    }).length;
  }

  Future<void> _loadComplaints() async {
    final auth = context.read<AuthService>();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final query = Uri(queryParameters: {'limit': _pageSize}).query;
      final res = await auth.api.get('/complaints?$query');
      final data = res['data'];
      final items = List<Map<String, dynamic>>.from(data['items'] ?? data ?? []);

      setState(() => _complaints = items);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'pending') return Colors.red;
    if (normalized == 'in progress' || normalized == 'in_progress') return Colors.amber.shade700;
    if (normalized == 'pending citizen verification' || normalized == 'resolving verification') return Colors.orange;
    if (normalized == 'resolved' || normalized == 'solved' || normalized == 'closed') return Colors.green;
    if (normalized == 'reopened') return Colors.deepOrange;
    return Colors.grey;
  }

  String _statusLabel(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'resolved' || normalized == 'solved' || normalized == 'closed') return 'Solved';
    if (normalized == 'in progress' || normalized == 'in_progress') return 'In Progress';
    if (normalized == 'pending citizen verification' || normalized == 'resolving verification') return 'Resolving Verification';
    if (normalized == 'pending') return 'Pending';
    return status;
  }

  Future<void> _resolveComplaintWithProof(Map<String, dynamic> complaint) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ResolutionVerificationScreen(complaint: complaint)),
    );

    if (!mounted) return;
    if (result == true) {
      await _loadComplaints();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Dashboard'),
        actions: [
          IconButton(
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadComplaints,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _buildHeaderCard(user),
                      const SizedBox(height: 16),
                      _buildStatusSummary(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Assigned Complaints',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 132,
                            child: DropdownButtonFormField<String>(
                              initialValue: _pageSize,
                              isDense: true,
                              borderRadius: BorderRadius.circular(14),
                              decoration: const InputDecoration(
                                labelText: 'Show',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: const [
                                DropdownMenuItem(value: '10', child: Text('10')),
                                DropdownMenuItem(value: '20', child: Text('20')),
                                DropdownMenuItem(value: '30', child: Text('30')),
                                DropdownMenuItem(value: 'all', child: Text('All')),
                              ],
                              onChanged: (value) {
                                setState(() => _pageSize = value ?? 'all');
                                _loadComplaints();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_complaints.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.inbox_outlined, color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No complaints assigned to your department yet',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._complaints.map((complaint) {
                          final status = '${complaint['status'] ?? 'Pending'}';
                          final statusLower = status.toLowerCase();
                          final canResolve = statusLower != 'solved' &&
                              statusLower != 'closed' &&
                              statusLower != 'resolved' &&
                              statusLower != 'pending citizen verification';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: _statusColor(status).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(Icons.assignment_outlined, color: _statusColor(status)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '#${complaint['id']} ${complaint['type'] ?? 'General'}',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w700,
                                                      height: 1.2,
                                                    ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Department complaint',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 165),
                                          child: Chip(
                                            visualDensity: VisualDensity.compact,
                                            side: BorderSide(color: _statusColor(status).withValues(alpha: 0.22)),
                                            backgroundColor: _statusColor(status).withValues(alpha: 0.10),
                                            label: Text(
                                              _statusLabel(status),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${complaint['description'] ?? ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.place_outlined, size: 18, color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${complaint['location'] ?? ''}',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Colors.grey[700],
                                                  height: 1.35,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ComplaintDetailScreen(id: complaint['id'] as int),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.open_in_new, size: 18),
                                            label: const Text('Open details'),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                          ),
                                        ),
                                        if (canResolve) ...[
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _resolveComplaintWithProof(complaint),
                                              icon: const Icon(Icons.verified_outlined, size: 18),
                                              label: const Text('Resolve'),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (!canResolve) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        'Resolution is locked for this status.',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic>? user) {
    final liveQueue = _countByStatus('pending') + _countByStatus('in progress') + _countByStatus('in_progress');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user?['name'] ?? '-'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Department ID: ${user?['department_id'] ?? '-'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryPill(label: 'Assigned', value: '${_complaints.length}'),
              const SizedBox(width: 10),
              _SummaryPill(label: 'Live Queue', value: '$liveQueue'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    final pending = _countByStatus('pending');
    final inProgress = _countByStatus('in progress') + _countByStatus('in_progress');
    final pendingCitizenVerification = _countByStatus('pending citizen verification');
    final resolved = _countByStatus('resolved') + _countByStatus('solved') + _countByStatus('closed');

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 8) / 2;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(width: tileWidth, child: _StatusMiniCard(label: 'Pending', value: '$pending', color: Colors.red)),
            SizedBox(width: tileWidth, child: _StatusMiniCard(label: 'In Progress', value: '$inProgress', color: Colors.amber.shade700)),
            SizedBox(width: tileWidth, child: _StatusMiniCard(label: 'Citizen Verification', value: '$pendingCitizenVerification', color: Colors.orange)),
            SizedBox(width: tileWidth, child: _StatusMiniCard(label: 'Solved', value: '$resolved', color: Colors.green)),
          ],
        );
      },
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusMiniCard extends StatelessWidget {
  const _StatusMiniCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
