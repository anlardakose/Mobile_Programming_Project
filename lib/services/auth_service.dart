import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login
  Future<UserModel?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _getUserData(credential.user!.uid);
      }
      return null;
    } catch (e) {
      // Firebase hatası yerine genel hata fırlat
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Register
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String department,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final user = UserModel(
          id: credential.user!.uid,
          name: name,
          email: email,
          department: department,
          role: UserRole.user, // Varsayılan role
          createdAt: DateTime.now(),
        );

        // Firestore'a kullanıcı bilgilerini kaydet
        await _firestore.collection('users').doc(user.id).set(user.toJson());

        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Kullanıcı bilgilerini Firestore'dan al
  Future<UserModel?> _getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson({
          'id': userId,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Password reset
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Mevcut kullanıcıyı al
  User? getCurrentFirebaseUser() {
    return _auth.currentUser;
  }

  // Auth state değişikliklerini dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}


