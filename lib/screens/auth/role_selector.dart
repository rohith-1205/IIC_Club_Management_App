import 'package:flutter/material.dart';
import '../admin/admin_dashboard.dart';
import '../manager/manager_dashboard.dart';
import '../member/member_dashboard.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            child: const Text('Admin'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            ),
          ),
          ElevatedButton(
            child: const Text('Manager'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManagerDashboard()),
            ),
          ),
          ElevatedButton(
            child: const Text('Member'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberDashboard()),
            ),
          ),
        ],
      ),
    );
  }
}
