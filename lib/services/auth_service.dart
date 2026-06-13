import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _db.collection('users').doc(credential.user!.uid).get();
    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{'name': name};
    if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
    await _db.collection('users').doc(uid).update(data);
  }

  Future<String> uploadAvatar(String uid, XFile file) async {
    final storage = FirebaseStorage.instance;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last;
    final fileName = '${const Uuid().v4()}.$ext';
    final ref = storage.ref().child('avatars/$uid/$fileName');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/$ext'));
    return await ref.getDownloadURL();
  }

  Future<void> signOut() => _auth.signOut();

  String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'invalid-credential':
        return 'Incorrect email or password';
      default:
        return 'An error occurred, please try again';
    }
  }
}
