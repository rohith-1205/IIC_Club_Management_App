import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> markAttendance({
    required String eventId,
    required String userId,
    required String status,
    required String markedBy,
  }) async {
    await _firestore.collection('attendance').add({
      'eventId': eventId,
      'userId': userId,
      'status': status,
      'markedBy': markedBy,
      'timestamp': DateTime.now(),
    });
  }

  Stream<QuerySnapshot> getAttendanceForUser(String userId) {
    return _firestore
        .collection('attendance')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}