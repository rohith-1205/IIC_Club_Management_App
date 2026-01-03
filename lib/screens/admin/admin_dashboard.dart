import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../services/excel_export_service.dart';
import '../manager/create_event_screen.dart';
import 'create_user_screen.dart';
import 'view_users_screen.dart';
import '../common/change_password_dialog.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  /// 🗑 DELETE EVENT + RELATED ATTENDANCE (ADMIN ONLY)
  Future<void> _deleteEvent(
    BuildContext context,
    String eventId,
    String eventTitle,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "$eventTitle"?\n\n'
          'All attendance records for this event will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      final eventRef =
          FirebaseFirestore.instance.collection('events').doc(eventId);
      batch.delete(eventRef);

      final attendanceSnap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (final doc in attendanceSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event and attendance deleted successfully'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE6C9),
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/amrita_logo.png', height: 30),
            const Spacer(),
            Image.asset('assets/images/iic_logo.png', height: 30),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await AuthService().logout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1F2A60),
              Color(0xFF3A4BAF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome IIC Admin',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                /// ACTION CARD
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ActionButton(
                          icon: Icons.event,
                          label: 'Create Event',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateEventScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          icon: Icons.person_add,
                          label: 'Create Manager / Member',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateUserScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ViewUsersScreen(
                                        role: 'manager',
                                        title: 'Managers',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('View Managers'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ViewUsersScreen(
                                        role: 'member',
                                        title: 'Members',
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('View Members'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// ✅ RESTORED HEADING
                const Text(
                  'Attendance Analytics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                /// EVENTS LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('events')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final events = snap.data!.docs;

                      if (events.isEmpty) {
                        return const Center(
                          child: Text(
                            'No events found',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (_, i) {
                          final e = events[i];
                          final data = e.data() as Map<String, dynamic>;

                          final present = data['presentCount'] ?? 0;
                          final absent = data['absentCount'] ?? 0;

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              title: Text(
                                data['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Row(
                                children: [
                                  _CountChip(
                                    label: 'Present',
                                    count: present,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  _CountChip(
                                    label: 'Absent',
                                    count: absent,
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  /// ⬇ DOWNLOAD ATTENDANCE (ICON)
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () async {
                                      await ExcelExportService
                                          .exportAttendanceForEvent(
                                        eventId: e.id,
                                        eventName: data['title'],
                                      );
                                    },
                                  ),

                                  /// ❌ DELETE EVENT (RESTORED)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteEvent(
                                      context,
                                      e.id,
                                      data['title'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                /// CHANGE PASSWORD
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text('Change Password'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ChangePasswordDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- HELPERS ----------

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
