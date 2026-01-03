import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import 'member_attendance_screen.dart';
import '../common/change_password_dialog.dart';

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

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
              Color(0xFF1C2759),
              Color(0xFF3A4BAF),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<String>(
            future: AuthService().getUserName(userId),
            builder: (context, nameSnap) {
              final name = nameSnap.data ?? 'Member';

              return Card(
                elevation: 14,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 30,
                  ),
                  child: Column(
                    children: [
                      /// 👤 HEADER
                      Column(
                        children: [
                          Text(
                            'Welcome, $name 🎓',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your attendance overview',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),
                      const Divider(thickness: 1),
                      const SizedBox(height: 20),

                      /// 📊 ATTENDANCE SUMMARY CARD (UNCHANGED)
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('attendance')
                            .where('userId', isEqualTo: userId)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const SizedBox();
                          }

                          final total = snap.data!.docs.length;
                          final present = snap.data!.docs
                              .where((d) =>
                                  (d.data() as Map)['status'] == 'present')
                              .length;

                          final percent =
                              total == 0 ? 0 : ((present / total) * 100).round();

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.withOpacity(0.12),
                                  Colors.green.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.pie_chart,
                                  color: Colors.green,
                                  size: 36,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '$percent% Attendance',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$present of $total sessions present',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      /// 🆕 EVENTS DETAILS (ADDED – READ ONLY)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Events',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        height: 220,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('events')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snap) {
                            if (!snap.hasData ||
                                snap.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No events available',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              );
                            }

                            final events = snap.data!.docs;

                            return ListView.builder(
                              itemCount: events.length,
                              itemBuilder: (_, i) {
                                final data = events[i].data()
                                    as Map<String, dynamic>;

                                return Card(
                                  elevation: 3,
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['title'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (data['description'] != null &&
                                            data['description']
                                                .toString()
                                                .isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    top: 6),
                                            child: Text(
                                              data['description'],
                                              style: const TextStyle(
                                                color:
                                                    Colors.black87,
                                              ),
                                            ),
                                          ),
                                        if (data['reference'] != null &&
                                            data['reference']
                                                .toString()
                                                .isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    top: 4),
                                            child: Text(
                                              'Reference: ${data['reference']}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color:
                                                    Colors.black54,
                                              ),
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

                      const SizedBox(height: 30),

                      /// 🎯 PRIMARY ACTION (UNCHANGED)
                      Hero(
                        tag: 'attendanceHero',
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.checklist),
                            label: const Text(
                              'View Detailed Attendance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MemberAttendanceScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      /// 🔐 CHANGE PASSWORD (UNCHANGED)
                      const SizedBox(height: 18),
                      TextButton.icon(
                        icon:
                            const Icon(Icons.lock_outline, size: 18),
                        label: const Text(
                          'Change Password',
                          style:
                              TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                const ChangePasswordDialog(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
