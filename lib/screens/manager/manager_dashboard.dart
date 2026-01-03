import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../services/excel_export_service.dart';
import '../admin/view_users_screen.dart';
import 'create_event_screen.dart';
import 'mark_attendance_screen.dart';
import '../common/change_password_dialog.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final managerId = FirebaseAuth.instance.currentUser!.uid;

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
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (_) => false);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F2A60), Color(0xFF3A4BAF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manager Dashboard',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              /// ACTION CARD (UNCHANGED + VIEW MEMBERS RESTORED)
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _PrimaryButton(
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
                      _SecondaryButton(
                        icon: Icons.group,
                        label: 'View Members',
                        onTap: () {
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
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// ATTENDANCE ANALYTICS (RESTORED)
              const Text(
                'Attendance Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              /// EVENTS LIST WITH DESCRIPTION + REFERENCE
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
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// TITLE
                                Text(
                                  data['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                /// DESCRIPTION
                                if (data['description'] != null &&
                                    data['description'].toString().isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6),
                                    child: Text(
                                      data['description'],
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),

                                /// REFERENCE
                                if (data['reference'] != null &&
                                    data['reference'].toString().isNotEmpty)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Reference: ${data['reference']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),

                                const SizedBox(height: 8),

                                /// STATS
                                Row(
                                  children: [
                                    _StatChip(
                                      label: 'Present',
                                      count: present,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    _StatChip(
                                      label: 'Absent',
                                      count: absent,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                /// ACTIONS
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon:
                                            const Icon(Icons.download),
                                        label:
                                            const Text('Download'),
                                        onPressed: () async {
                                          await ExcelExportService
                                              .exportAttendanceForEvent(
                                            eventId: e.id,
                                            eventName: data['title'],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        child: const Text(
                                            'Mark Attendance'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  MarkAttendanceScreen(
                                                eventId: e.id,
                                                eventTitle:
                                                    data['title'],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
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

              /// CHANGE PASSWORD (UNCHANGED)
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Change Password'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          const ChangePasswordDialog(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// HELPERS (UNCHANGED)

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PrimaryButton({
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

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
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