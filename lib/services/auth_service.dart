import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------- LOGIN ----------------
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  // ---------------- REGISTER (ADMIN USE) ----------------
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    final FirebaseAuth secondaryAuth =
        FirebaseAuth.instanceFor(app: secondaryApp);

    final UserCredential result =
        await secondaryAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final String uid = result.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await secondaryAuth.signOut();
    await secondaryApp.delete();
  }

  // ---------------- CHANGE PASSWORD (ALL ROLES) ----------------
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User not authenticated');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    // 🔐 Re-authenticate
    await user.reauthenticateWithCredential(credential);

    // 🔄 Update password
    await user.updatePassword(newPassword);
  }

  // ---------------- DELETE USER (FIRESTORE ONLY) ----------------
  Future<void> deleteUser({required String uid}) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // ---------------- PASSWORD RESET (EMAIL) ----------------
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ---------------- ROLE ----------------
  Future<String> getUserRole(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'member';
  }

  // ---------------- USER NAME ----------------
  Future<String> getUserName(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['name'] ??
        doc.data()?['email'] ??
        'Unknown';
  }

  // ---------------- LOGOUT ----------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ---------------- AUTH STATE ----------------
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}