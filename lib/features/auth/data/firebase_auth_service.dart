import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  FirebaseAuthService._(this._auth);

  static final FirebaseAuthService instance =
      FirebaseAuthService._(FirebaseAuth.instance);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUserId => currentUser?.uid;

  bool get isSignedIn => currentUser != null;

  Future<User?> ensureSignedIn() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser;
    }

    final credential = await _auth.signInAnonymously();
    return credential.user;
  }
}
