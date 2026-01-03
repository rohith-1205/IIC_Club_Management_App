import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;

  const MarkAttendanceScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final String managerId = FirebaseAuth.instance.currentUser!.uid;

  String? managerName;

  @override
  void initState() {
    super.initState();
    _loadManagerName();
  }

  /// 🔹 Fetch manager name once
  Future<void> _loadManagerName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(managerId)
        .get();

    setState(() {
      managerName =
          doc.data()?['name'] ?? doc.data()?['email'] ?? 'Unknown';
    });
  }

  Future<void> _setAttendance({
    required String memberId,
    required String memberName,
    required String status,
  }) async {
    if (managerName == null) return;

    final attendanceDocId = '${widget.eventId}_$memberId';

    final attendanceRef =
        FirebaseFirestore.instance.collection('attendance').doc(attendanceDocId);

    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final attendanceSnap = await transaction.get(attendanceRef);
      final eventSnap = await transaction.get(eventRef);

      if (!eventSnap.exists) {
        throw Exception('Event not found');
      }

      int presentCount = (eventSnap.data()?['presentCount'] ?? 0) as int;
      int absentCount = (eventSnap.data()?['absentCount'] ?? 0) as int;

      final previousStatus =
          attendanceSnap.exists ? attendanceSnap['status'] : null;

      // ⛔ No change → no update
      if (previousStatus == status) return;

      if (previousStatus == 'present') presentCount--;
      if (previousStatus == 'absent') absentCount--;

      if (status == 'present') presentCount++;
      if (status == 'absent') absentCount++;

      // 🛡️ Prevent negatives
      if (presentCount < 0) presentCount = 0;
      if (absentCount < 0) absentCount = 0;

      /// ✅ Attendance document
      transaction.set(attendanceRef, {
        'eventId': widget.eventId,
        'eventName': widget.eventTitle,
        'userId': memberId,
        'name': memberName,
        'status': status,
        'markedById': managerId,
        'markedByName': managerName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      /// ✅ Update counters
      transaction.update(eventRef, {
        'presentCount': presentCount,
        'absentCount': absentCount,
      });
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$memberName marked $status'),
        backgroundColor:
            status == 'present' ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - ${widget.eventTitle}'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'member')
            .snapshots(),
        builder: (context, memberSnap) {
          if (!memberSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = memberSnap.data!.docs;

          if (members.isEmpty) {
            return const Center(child: Text('No members found'));
          }

          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final data = member.data() as Map<String, dynamic>;

              final memberId = member.id;
              final memberName =
                  data['name'] ?? data['email'] ?? 'Unknown';

              final attendanceDocId =
                  '${widget.eventId}_$memberId';

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('attendance')
                    .doc(attendanceDocId)
                    .snapshots(),
                builder: (context, attendanceSnap) {
                  String? status;
                  if (attendanceSnap.hasData &&
                      attendanceSnap.data!.exists) {
                    status = attendanceSnap.data!['status'];
                  }

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        status == 'present'
                                            ? Colors.green
                                            : Colors.grey.shade300,
                                    foregroundColor:
                                        status == 'present'
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  onPressed: () => _setAttendance(
                                    memberId: memberId,
                                    memberName: memberName,
                                    status: 'present',
                                  ),
                                  child: const Text('Present'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        status == 'absent'
                                            ? Colors.red
                                            : Colors.grey.shade300,
                                    foregroundColor:
                                        status == 'absent'
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                  onPressed: () => _setAttendance(
                                    memberId: memberId,
                                    memberName: memberName,
                                    status: 'absent',
                                  ),
                                  child: const Text('Absent'),
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
          );
        },
      ),
    );
  }
}