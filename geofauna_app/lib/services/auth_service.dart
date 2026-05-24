import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Perfil en Firestore ───────────────────────────────────────────────────

  /// Stream del documento del usuario; lo usa AuthWrapper para decidir si el
  /// perfil está completo y enrutar al shell o a "completar perfil".
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDoc(String uid) =>
      _firestore.collection('users').doc(uid).snapshots();

  /// Un perfil se considera completo cuando se han llenado los datos
  /// obligatorios (marcado explícitamente al enviar el formulario).
  bool isProfileComplete(Map<String, dynamic>? data) =>
      data != null && data['profileCompleted'] == true;

  /// Guarda los datos obligatorios del perfil (cualquier método de ingreso) y
  /// marca el perfil como completo.
  Future<void> completeProfile({
    required String uid,
    required String name,
    required String rangerId,
    required String userType,
    required String specialty,
  }) {
    final user = _auth.currentUser;
    return _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      if (user?.email != null) 'email': user!.email,
      'rangerId': rangerId,
      'userType': userType,
      'specialty': specialty,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Actualiza los datos editables del perfil del usuario autenticado en
  /// Firebase Auth y Firestore.
  Future<void> updateAccountProfile({
    required String name,
    required String rangerId,
    required String userType,
    required String specialty,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay una sesión activa.',
      );
    }

    await user.updateDisplayName(name);
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      if (user.email != null) 'email': user.email,
      'rangerId': rangerId,
      'userType': userType,
      'specialty': specialty,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await user.reload();
  }

  // ── Email / Contraseña ──────────────────────────────────────────────────────

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    File? photoFile,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String? photoUrl;
    if (photoFile != null) {
      photoUrl = await _uploadProfilePhoto(credential.user!.uid, photoFile);
    }

    await credential.user!.updateDisplayName(name);
    if (photoUrl != null) await credential.user!.updatePhotoURL(photoUrl);

    await _saveUserToFirestore(
      uid: credential.user!.uid,
      name: name,
      email: email,
      photoUrl: photoUrl,
    );

    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay una cuenta con correo activa.',
      );
    }

    final usesPassword = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (!usesPassword) {
      throw FirebaseAuthException(
        code: 'provider-not-password',
        message:
            'Esta cuenta no usa contraseña local. Gestiona el acceso desde tu proveedor de inicio de sesión.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // ── Google Sign-In ──────────────────────────────────────────────────────────

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // usuario canceló

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _saveUserToFirestore(
        uid: userCredential.user!.uid,
        name: userCredential.user!.displayName ?? '',
        email: userCredential.user!.email ?? '',
        photoUrl: userCredential.user!.photoURL,
      );
    }

    return userCredential;
  }

  // ── Cerrar sesión ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await NotificationService.instance.unregisterCurrentDevice();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Helpers privados ────────────────────────────────────────────────────────

  Future<String> _uploadProfilePhoto(String uid, File photoFile) async {
    final ref = _storage.ref().child('profile_photos/$uid.jpg');
    await ref.putFile(photoFile);
    return ref.getDownloadURL();
  }

  Future<void> _saveUserToFirestore({
    required String uid,
    required String name,
    required String email,
    String? photoUrl,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
