import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/complaint_service.dart';
import 'complaint_detail_screen.dart';
import 'dart:async';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  Timer? _timer;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    context.read<ComplaintService>().loadComplaints();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      context.read<ComplaintService>().loadComplaints();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch ((status).toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in_progress':
      case 'in progress':
        return const Color(0xFF3B82F6);
      case 'resolving verification':
        return const Color(0xFFEA580C);
      case 'solved':
      case 'resolved':
      case 'closed':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  IconData _getStatusIcon(String status) {
    switch ((status).toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'in_progress':
      case 'in progress':
        return Icons.engineering_rounded;
      case 'resolving verification':
        return Icons.verified_outlined;
      case 'solved':
      case 'resolved':
      case 'closed':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getStatusLabel(String status) {
    if (status.isEmpty) return 'Unknown';
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':
        return 'In Progress';
      case 'pending':
        return 'Pending';
      case 'pending citizen verification':
      case 'resolving verification':
        return 'Resolving Verification';
      case 'solved':
        return 'Solved';
      case 'resolved':
        return 'Solved';
      case 'closed':
        return 'Solved';
      default:
        return status;
    }
  }

  List<Map<String, dynamic>> _getFilteredComplaints(List<Map<String, dynamic>> complaints) {
    if (_filterStatus == 'all') return complaints;
    if (_filterStatus == 'resolving verification') {
      return complaints.where((c) {
        final status = (c['status'] ?? '').toString().toLowerCase();
        return status == 'resolving verification' || status == 'pending citizen verification';
      }).toList();
    }
    return complaints.where((c) => (c['status'] ?? '').toLowerCase() == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allComplaints = context.watch<ComplaintService>().complaints;
    final complaints = _getFilteredComplaints(allComplaints);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Complaints'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    count: allComplaints.length,
                    isSelected: _filterStatus == 'all',
                    onTap: () => setState(() => _filterStatus = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pending',
                    count: allComplaints.where((c) => (c['status'] ?? '').toLowerCase() == 'pending').length,
                    color: _getStatusColor('pending'),
                    isSelected: _filterStatus == 'pending',
                    onTap: () => setState(() => _filterStatus = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'In Progress',
                    count: allComplaints.where((c) => (c['status'] ?? '').toLowerCase() == 'in progress').length,
                    color: _getStatusColor('in progress'),
                    isSelected: _filterStatus == 'in progress',
                    onTap: () => setState(() => _filterStatus = 'in progress'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Resolving Verification',
                    count: allComplaints.where((c) {
                      final status = (c['status'] ?? '').toString().toLowerCase();
                      return status == 'resolving verification' || status == 'pending citizen verification';
                    }).length,
                    color: _getStatusColor('resolving verification'),
                    isSelected: _filterStatus == 'resolving verification',
                    onTap: () => setState(() => _filterStatus = 'resolving verification'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Solved',
                    count: allComplaints.where((c) {
                      final status = (c['status'] ?? '').toString().toLowerCase();
                      return status == 'solved' || status == 'resolved' || status == 'closed';
                    }).length,
                    color: _getStatusColor('solved'),
                    isSelected: _filterStatus == 'solved',
                    onTap: () => setState(() => _filterStatus = 'solved'),
                  ),
                ],
              ),
            ),
          ),

          // Complaints List
          Expanded(
            child: complaints.isEmpty
                ? _EmptyState(
                    icon: _filterStatus == 'all' ? Icons.inbox_rounded : Icons.filter_alt_off_rounded,
                    title: _filterStatus == 'all' ? 'No Complaints Yet' : 'No ${_getStatusLabel(_filterStatus)} Complaints',
                    subtitle: _filterStatus == 'all' 
                        ? 'Tap the button below to create your first complaint'
                        : 'Try selecting a different filter',
                  )
                : RefreshIndicator(
                    onRefresh: () => context.read<ComplaintService>().loadComplaints(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: complaints.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = complaints[index];
                        return _ComplaintCard(
                          item: item,
                          statusColor: _getStatusColor(item['status'] ?? ''),
                          statusIcon: _getStatusIcon(item['status'] ?? ''),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ComplaintDetailScreen(id: item['id']),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onTap;

  const _ComplaintCard({
    required this.item,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  String _getStatusLabel(String status) {
    if (status.isEmpty) return 'Unknown';
    switch (status.toLowerCase()) {
      case 'in_progress': 
      case 'in progress': 
        return 'In Progress';
      case 'pending': 
        return 'Pending';
      case 'resolving verification':
        return 'Resolving Verification';
      case 'solved': 
        return 'Solved';
      case 'resolved': 
      case 'closed': 
        return 'Solved';
      default: 
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item['type'] ?? 'Complaint',
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(item['status'] ?? 'Unknown'),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item['description'] ?? 'No description',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item['location'] ?? 'Unknown location',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                size: 64,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9CA3AF),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
