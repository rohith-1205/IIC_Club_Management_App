// ONLY ADDITIONS ARE MARKED
// NO EXISTING UI / HERO / LOGIC REMOVED

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberAttendanceScreen extends StatelessWidget {
  const MemberAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
      ),
      body: Column(
        children: [
          /// ✅ HERO (UNCHANGED)
          Hero(
            tag: 'attendanceHero',
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.checklist, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Attendance Records',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// 🔽 DATA LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('userId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final records = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final data =
                        records[index].data() as Map<String, dynamic>;

                    final String eventId = data['eventId'];
                    final String eventName =
                        data['eventName'] ?? 'Event';

                    final String status =
                        data['status'] ?? 'absent';

                    /// ✅ EXISTING FIELD (USED, NOT REMOVED)
                    final Timestamp? ts = data['timestamp'];
                    final String markedOn = ts != null
                        ? ts.toDate().toString()
                        : '—';

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('events')
                          .doc(eventId)
                          .get(),
                      builder: (context, eventSnap) {
                        final eventData = eventSnap.data?.data()
                            as Map<String, dynamic>?;

                        final description =
                            eventData?['description'];
                        final reference =
                            eventData?['reference'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(
                              status == 'present'
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: status == 'present'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(
                              eventName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            /// 🔹 SUBTITLE (ONLY ADDITION BELOW)
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                /// ✅ DATE & TIME RESTORED
                                Text(
                                  'Marked on: $markedOn',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),

                                if (description != null)
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 4),
                                    child: Text(description),
                                  ),

                                if (reference != null)
                                  Text(
                                    'Reference: $reference',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                              ],
                            ),

                            trailing: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: status == 'present'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
