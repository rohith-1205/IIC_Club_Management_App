import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';

class ExcelExportService {
  static Future<String?> exportAttendanceForEvent({
    required String eventId,
    required String eventName,
  }) async {
    // 1️⃣ Fetch attendance records
    final QuerySnapshot<Map<String, dynamic>> attendanceSnap =
        await FirebaseFirestore.instance
            .collection('attendance')
            .where('eventId', isEqualTo: eventId)
            .get();

    if (attendanceSnap.docs.isEmpty) {
      return null; // nothing to export
    }

    // 2️⃣ Create Excel
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Attendance'];

    // 3️⃣ Header row
    sheet.appendRow([
      'Name',
      'Status',
      'Marked By',
      'Timestamp',
    ]);

    // 4️⃣ Data rows (SAFE + BACKWARD COMPATIBLE)
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in attendanceSnap.docs) {
      final Map<String, dynamic> data = doc.data();

      sheet.appendRow([
        // 👤 Member name
        data['name'] ??
            data['email'] ??
            'Unknown',

        // ✅ Status
        data['status'] ?? '',

        // 👮 Manager name (fallback safe)
        data['markedByName'] ??
            data['markedBy'] ??
            'Unknown',

        // ⏰ Timestamp
        (data['timestamp'] as Timestamp?)?.toDate().toString() ?? '',
      ]);
    }

    // 5️⃣ Save to Downloads (Android)
    final Directory downloadsDir =
        Directory('/storage/emulated/0/Download');

    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    final String safeName =
        eventName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

    final String filePath =
        '${downloadsDir.path}/${safeName}_attendance.xlsx';

    final File file = File(filePath);
    final List<int>? bytes = excel.encode();

    if (bytes == null) return null;

    await file.writeAsBytes(bytes, flush: true);

    return filePath; // ✅ real device path
  }
}