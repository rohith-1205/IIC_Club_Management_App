class AttendanceModel {
  final String eventId;
  final String userId;
  final String status; // present / absent
  final String markedBy;
  final DateTime timestamp;

  AttendanceModel({
    required this.eventId,
    required this.userId,
    required this.status,
    required this.markedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'status': status,
      'markedBy': markedBy,
      'timestamp': timestamp,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      eventId: map['eventId'],
      userId: map['userId'],
      status: map['status'],
      markedBy: map['markedBy'],
      timestamp: map['timestamp'].toDate(),
    );
  }
}