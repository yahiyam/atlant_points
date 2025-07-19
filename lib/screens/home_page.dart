import 'package:atlant_points/model/employee_model.dart';
import 'package:atlant_points/screens/admin/admin_dashboard.dart';
import 'package:atlant_points/screens/customer/customer_search_page.dart';
import 'package:atlant_points/screens/pointsAdding/customer_mobile_entry_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _logsPerPage = 10;
  DocumentSnapshot? _lastLog;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  List<DocumentSnapshot> _logs = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<Employee?> getCurrentEmployee() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('employees')
        .doc(user.uid)
        .get();
    if (doc.exists && doc.data() != null) {
      return Employee.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> _fetchLogs({bool loadMore = false}) async {
    if (_isLoadingMore || (!_hasMore && loadMore)) return;
    setState(() => _isLoadingMore = true);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    Query logsQuery = FirebaseFirestore.instance
        .collection('logs')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .limit(_logsPerPage);

    if (loadMore && _lastLog != null) {
      logsQuery = logsQuery.startAfterDocument(_lastLog!);
    }

    final snap = await logsQuery.get();
    if (snap.docs.isNotEmpty) {
      setState(() {
        if (loadMore) {
          _logs.addAll(snap.docs);
        } else {
          _logs = snap.docs;
        }
        _lastLog = snap.docs.last;
        _hasMore = snap.docs.length == _logsPerPage;
      });
    } else {
      setState(() {
        _hasMore = false;
      });
    }
    setState(() => _isLoadingMore = false);
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Employee?>(
          future: getCurrentEmployee(),
          builder: (context, snapshot) {
            final name = snapshot.data?.name ?? '';
            return Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(
                  name.isNotEmpty ? 'Welcome, $name' : 'Atlant Points',
                  style: Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ],
            );
          },
        ),
        actions: [
          FutureBuilder<Employee?>(
            future: getCurrentEmployee(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final employee = snapshot.data;
              if (employee != null && employee.isAdmin) {
                return IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'Analytics',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminDashboard()),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // --- Real-time Summary Cards ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PointsTodayCard(startOfDay: startOfDay, endOfDay: endOfDay),
                  _CustomersTodayCard(startOfDay: startOfDay, endOfDay: endOfDay),
                  _TopEmployeeCard(startOfDay: startOfDay, endOfDay: endOfDay),
                  _TopCustomerCard(startOfDay: startOfDay, endOfDay: endOfDay),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Action Buttons Row ---
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add AtlantPoints'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerMobileEntryPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('View Customers'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CustomerSearchPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Point Logs Title
            Row(
              children: [
                Text(
                  "Today's Point Logs",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_isLoadingMore)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Search bar ---
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, mobile, category',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 16),

            // Logs List
            Expanded(
              child: _logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text(
                            'No logs yet.\nStart by adding points!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        _lastLog = null;
                        _hasMore = true;
                        await _fetchLogs();
                      },
                      child: ListView.builder(
                        itemCount: _logs.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _logs.length) {
                            // Load more button
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: FilledButton(
                                  onPressed: _isLoadingMore
                                      ? null
                                      : () => _fetchLogs(loadMore: true),
                                  child: _isLoadingMore
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Load More'),
                                ),
                              ),
                            );
                          }

                          final data =
                              _logs[index].data() as Map<String, dynamic>;
                          final adminAction = data['adminAction'] as String?;

                          // Do not show logs with adminAction == 'redeem'
                          if (adminAction == 'redeem') {
                            return const SizedBox.shrink();
                          }

                          final name = data['customerName'] ?? 'Unknown';
                          final points = data['pointsAdded'] ?? 0;
                          final timestamp = (data['timestamp'] as Timestamp?)
                              ?.toDate();
                          final timeStr = timestamp != null
                              ? TimeOfDay.fromDateTime(
                                  timestamp,
                                ).format(context)
                              : 'Unknown time';
                          final categories =
                              (data['categories'] as List<dynamic>?)
                                  ?.map(
                                    (c) => "${c['title']} (+${c['points']})",
                                  )
                                  .join(', ') ??
                              'None';
                          final employeeId =
                              data['employeeId'] as String? ?? '';
                          final mobile = data['customerId'] ?? '';

                          // Search filter (name, mobile, categories)
                          final catsString =
                              (data['categories'] as List<dynamic>?)
                                  ?.map(
                                    (c) => c['title'].toString().toLowerCase(),
                                  )
                                  .join(', ') ??
                              '';
                          if (_searchQuery.isNotEmpty &&
                              !(name.toString().toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  mobile.toString().toLowerCase().contains(
                                    _searchQuery,
                                  ) ||
                                  catsString.contains(_searchQuery))) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ExpansionTile(
                              title: Text('$name earned $points pts'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Time: $timeStr'),
                                  if (adminAction != null &&
                                      adminAction.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        adminAction.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.deepPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              children: [
                                ListTile(
                                  title: Text('Categories: $categories'),
                                  subtitle: employeeId.isEmpty
                                      ? const Text('Employee: -')
                                      : FutureBuilder<DocumentSnapshot>(
                                          future: FirebaseFirestore.instance
                                              .collection('employees')
                                              .doc(employeeId)
                                              .get(),
                                          builder: (context, empSnap) {
                                            final empName =
                                                empSnap.hasData &&
                                                    empSnap.data!.exists
                                                ? (empSnap.data!.data()
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >)['name'] ??
                                                      'Unknown'
                                                : 'Unknown';
                                            return Text('Employee: $empName');
                                          },
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Summary Card Widget ---
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // No shadow
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Real-time Points Today Card ---
class _PointsTodayCard extends StatelessWidget {
  final DateTime startOfDay;
  final DateTime endOfDay;

  const _PointsTodayCard({required this.startOfDay, required this.endOfDay});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snap) {
        int totalPoints = 0;
        if (snap.hasData) {
          for (var doc in snap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final points = data['pointsAdded'] ?? 0;
            totalPoints += (points as num).toInt();
          }
        }
        return _SummaryCard(
          title: "Points Today",
          value: totalPoints.toString(),
          icon: Icons.stars,
          color: const Color(0xFF009FFD),
        );
      },
    );
  }
}

// --- Real-time Customers Today Card ---
class _CustomersTodayCard extends StatelessWidget {
  final DateTime startOfDay;
  final DateTime endOfDay;

  const _CustomersTodayCard({required this.startOfDay, required this.endOfDay});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return _SummaryCard(
          title: "Customers Today",
          value: count.toString(),
          icon: Icons.people,
          color: const Color(0xFFFFD700),
        );
      },
    );
  }
}

// --- Real-time Top Employee Today Card ---
class _TopEmployeeCard extends StatelessWidget {
  final DateTime startOfDay;
  final DateTime endOfDay;

  const _TopEmployeeCard({required this.startOfDay, required this.endOfDay});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const _SummaryCard(
            title: "Top Employee Today",
            value: "-",
            icon: Icons.emoji_events,
            color: Color(0xFF009FFD),
          );
        }
        final logs = snap.data!.docs;
        Map<String, int> employeePoints = {};
        for (var doc in logs) {
          final data = doc.data() as Map<String, dynamic>;
          final points = data['pointsAdded'] ?? 0;
          final employeeId = data['employeeId'] ?? '';
          if (employeeId.isNotEmpty) {
            employeePoints[employeeId] =
                (employeePoints[employeeId] ?? 0) + (points as num).toInt();
          }
        }
        String topEmpId = '-';
        int topPoints = 0;
        for (var entry in employeePoints.entries) {
          if (entry.value > topPoints) {
            topPoints = entry.value;
            topEmpId = entry.key;
          }
        }
        return FutureBuilder<DocumentSnapshot>(
          future: topEmpId != '-' && topEmpId.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('employees')
                  .doc(topEmpId)
                  .get()
              : null,
          builder: (context, empSnap) {
            String empName = '-';
            if (empSnap.hasData &&
                empSnap.data != null &&
                empSnap.data!.exists) {
              empName =
                  (empSnap.data!.data() as Map<String, dynamic>)['name'] ?? '-';
            }
            return _SummaryCard(
              title: "Top Employee Today",
              value: empName,
              icon: Icons.emoji_events,
              color: const Color(0xFF009FFD),
            );
          },
        );
      },
    );
  }
}

// --- Real-time Top Customer Today Card ---
class _TopCustomerCard extends StatelessWidget {
  final DateTime startOfDay;
  final DateTime endOfDay;

  const _TopCustomerCard({required this.startOfDay, required this.endOfDay});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const _SummaryCard(
            title: "Top Customer Today",
            value: "-",
            icon: Icons.person,
            color: Color(0xFFFFD700),
          );
        }
        final logs = snap.data!.docs;
        Map<String, int> customerPoints = {};
        for (var doc in logs) {
          final data = doc.data() as Map<String, dynamic>;
          final points = data['pointsAdded'] ?? 0;
          final customerName = data['customerName'] ?? '';
          if (customerName.isNotEmpty) {
            customerPoints[customerName] =
                (customerPoints[customerName] ?? 0) + (points as num).toInt();
          }
        }
        String topCust = '-';
        int topPoints = 0;
        for (var entry in customerPoints.entries) {
          if (entry.value > topPoints) {
            topPoints = entry.value;
            topCust = entry.key;
          }
        }
        return _SummaryCard(
          title: "Top Customer Today",
          value: topCust,
          icon: Icons.person,
          color: const Color(0xFFFFD700),
        );
      },
    );
  }
}