import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'complaint_detail_screen.dart';
import 'login_screen.dart';
import 'package:path_provider/path_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _feedback = [];
  Map<String, dynamic> _stats = {};

  String _typeFilter = '';
  String _areaFilter = '';
  String _statusFilter = '';
  String _fromDate = '';
  String _toDate = '';
  String _pageSize = 'all';

  final TextEditingController _assignComplaintIdController = TextEditingController();
  String _selectedDepartmentName = '';
  int _selectedMenuIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _assignComplaintIdController.dispose();
    super.dispose();
  }

  String _queryString() {
    final params = <String, String>{
      'limit': _pageSize,
      if (_typeFilter.isNotEmpty) 'type': _typeFilter,
      if (_areaFilter.isNotEmpty) 'area': _areaFilter,
      if (_statusFilter.isNotEmpty) 'status': _statusFilter,
      if (_fromDate.isNotEmpty) 'fromDate': _fromDate,
      if (_toDate.isNotEmpty) 'toDate': _toDate,
    };
    return params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthService>();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final query = _queryString();
      final responses = await Future.wait([
        auth.api.get('/complaints${query.isNotEmpty ? '?$query' : ''}'),
        auth.api.get('/stats'),
        auth.api.get('/departments'),
        auth.api.get('/feedback'),
      ]);

      final complaintsData = responses[0]['data'];
      final statsData = responses[1]['data'];
      final departmentsData = responses[2]['data'];
      final feedbackData = responses[3]['data'];

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(complaintsData['items'] ?? complaintsData ?? []);
        _stats = Map<String, dynamic>.from(statsData ?? {});
        _departments = List<Map<String, dynamic>>.from(departmentsData ?? []);
        _feedback = List<Map<String, dynamic>>.from(feedbackData ?? []);
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _assignComplaint() async {
    final auth = context.read<AuthService>();
    final idText = _assignComplaintIdController.text.trim();
    if (idText.isEmpty || _selectedDepartmentName.isEmpty) return;

    final complaintId = int.tryParse(idText);
    if (complaintId == null) return;

    final dept = _departments.firstWhere(
      (d) => d['name'] == _selectedDepartmentName,
      orElse: () => {},
    );
    if (dept.isEmpty) return;

    await auth.api.post('/complaints/$complaintId/assign', {
      'departmentId': dept['id'],
    });

    _assignComplaintIdController.clear();
    setState(() => _selectedDepartmentName = '');
    await _loadData();
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'pending') return Colors.red;
    if (s == 'in progress' || s == 'in_progress') return Colors.amber.shade700;
    if (s == 'resolved' || s == 'solved' || s == 'closed') return Colors.green;
    return Colors.grey;
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'resolved' || s == 'solved' || s == 'closed') return 'Solved';
    if (s == 'in progress' || s == 'in_progress') return 'In Progress';
    if (s == 'pending citizen verification' || s == 'resolving verification') return 'Resolving Verification';
    if (s == 'pending') return 'Pending';
    return status;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (selected == null) return;
    final iso = selected.toIso8601String().split('T').first;
    setState(() {
      if (isFrom) {
        _fromDate = iso;
      } else {
        _toDate = iso;
      }
    });
  }

  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  Future<bool> _saveExportFile({required File sourceFile, required String fileName}) async {
    try {
      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: sourceFile.path,
          fileName: fileName,
        ),
      );

      if (!mounted) return true;
      if (savedPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export cancelled')),
        );
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: $savedPath')),
      );
      return true;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _shareExportFile(File file, String label) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '$label Export',
      text: 'Exported $label file',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save dialog unavailable. Shared file instead.')),
    );
  }

  Future<void> _exportComplaintsCsv() async {
    try {
      if (_complaints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No complaints to export')),
        );
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('ID,Type,Description,Location,Status');
      for (final c in _complaints) {
        buffer.writeln(
          [
            _csvEscape('${c['id'] ?? ''}'),
            _csvEscape('${c['type'] ?? ''}'),
            _csvEscape('${c['description'] ?? ''}'),
            _csvEscape('${c['location'] ?? ''}'),
            _csvEscape('${c['status'] ?? ''}'),
          ].join(','),
        );
      }

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'complaints_$timestamp.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(buffer.toString());
      final saved = await _saveExportFile(sourceFile: file, fileName: fileName);
      if (!saved) {
        await _shareExportFile(file, 'CSV');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV export failed: $e')),
      );
    }
  }

  Future<void> _exportComplaintsPdf() async {
    try {
      if (_complaints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No complaints to export')),
        );
        return;
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Header(level: 0, child: pw.Text('Complaints Report')),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['ID', 'Type', 'Description', 'Location', 'Status'],
              data: _complaints
                  .map(
                    (c) => [
                      '${c['id'] ?? ''}',
                      '${c['type'] ?? ''}',
                      '${c['description'] ?? ''}',
                      '${c['location'] ?? ''}',
                      '${c['status'] ?? ''}',
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'complaints_$timestamp.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      final saved = await _saveExportFile(sourceFile: file, fileName: fileName);
      if (!saved) {
        await _shareExportFile(file, 'PDF');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      _buildDashboardPage(),
      _buildAllComplaintsPage(),
      _buildFeedbackPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedMenuIndex == 0
              ? 'Admin Dashboard'
              : _selectedMenuIndex == 1
                  ? 'All Complaints'
                  : 'Feedback',
        ),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
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
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: sections[_selectedMenuIndex],
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedMenuIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedMenuIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Feedback',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverview(),
        const SizedBox(height: 14),
        _buildAssignCard(),
      ],
    );
  }

  Widget _buildAllComplaintsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFilterCard(),
        const SizedBox(height: 14),
        _buildComplaintsList(),
      ],
    );
  }

  Widget _buildFeedbackPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFeedbackCard(),
      ],
    );
  }

  Widget _buildOverview() {
    final byStatus = List<Map<String, dynamic>>.from(_stats['byStatus'] ?? []);
    int pending = 0;
    int inProgress = 0;
    int solved = 0;

    for (final row in byStatus) {
      final status = '${row['status']}'.toLowerCase();
      final count = row['count'] as int? ?? 0;
      if (status == 'pending') pending += count;
      if (status == 'in progress' || status == 'in_progress') inProgress += count;
      if (status == 'solved' || status == 'resolved' || status == 'closed') solved += count;
    }

    final total = pending + inProgress + solved;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Analytics', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _AnalyticsRow(title: 'Total', count: total, color: Colors.blue),
                const Divider(height: 18),
                _AnalyticsRow(title: 'Pending', count: pending, color: Colors.red),
                const Divider(height: 18),
                _AnalyticsRow(title: 'In Progress', count: inProgress, color: Colors.amber.shade700),
                const Divider(height: 18),
                _AnalyticsRow(title: 'Solved', count: solved, color: Colors.green),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(labelText: 'Type'),
              onChanged: (value) => _typeFilter = value.trim(),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Area/Location'),
              onChanged: (value) => _areaFilter = value.trim(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _statusFilter.isEmpty ? null : _statusFilter,
              items: const [
                DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'Solved', child: Text('Solved')),
              ],
              onChanged: (value) => _statusFilter = value ?? '',
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _pageSize,
              items: const [
                DropdownMenuItem(value: '10', child: Text('Show 10')),
                DropdownMenuItem(value: '20', child: Text('Show 20')),
                DropdownMenuItem(value: '30', child: Text('Show 30')),
                DropdownMenuItem(value: 'all', child: Text('Show All')),
              ],
              onChanged: (value) => setState(() => _pageSize = value ?? 'all'),
              decoration: const InputDecoration(labelText: 'Complaints Count'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isFrom: true),
                    child: Text(_fromDate.isEmpty ? 'From Date' : _fromDate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isFrom: false),
                    child: Text(_toDate.isEmpty ? 'To Date' : _toDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.search),
                    label: const Text('Apply Filters'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _typeFilter = '';
                      _areaFilter = '';
                      _statusFilter = '';
                      _fromDate = '';
                      _toDate = '';
                      _pageSize = 'all';
                    });
                    _loadData();
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign Complaint', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _assignComplaintIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Complaint ID'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedDepartmentName.isEmpty ? null : _selectedDepartmentName,
              items: _departments
                  .map((d) => DropdownMenuItem<String>(
                        value: d['name'].toString(),
                        child: Text(d['name'].toString()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedDepartmentName = value ?? ''),
              decoration: const InputDecoration(labelText: 'Department'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _assignComplaint,
                icon: const Icon(Icons.assignment_turned_in),
                label: const Text('Assign'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('All Complaints', style: Theme.of(context).textTheme.titleLarge),
            Text('${_complaints.length}', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportComplaintsCsv,
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Export CSV'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _exportComplaintsPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Export PDF'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._complaints.map((c) {
          final status = '${c['status'] ?? 'Pending'}';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ComplaintDetailScreen(id: c['id'] as int)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '#${c['id']}  ${c['type'] ?? 'General'}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                          label: Text(
                            _statusLabel(status),
                            style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${c['description'] ?? ''}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${c['location'] ?? ''}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Citizen Feedback', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_feedback.isEmpty)
              const Text('No feedback available yet')
            else
              ..._feedback.map((f) {
                final rating = (f['rating'] as num?)?.toInt() ?? 0;
                final stars = List.generate(
                  5,
                  (idx) => Icon(
                    idx < rating ? Icons.star : Icons.star_border,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${f['citizen_name'] ?? 'Citizen'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Row(children: stars),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Complaint #${f['complaint_id'] ?? '-'}: ${f['comment'] ?? ''}'),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({required this.title, required this.count, required this.color});

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

