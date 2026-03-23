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

  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  String get identityLabel {
    final user = currentUser;
    if (user == null) {
      return 'Guest';
    }

    final displayName = (user.displayName ?? '').trim();
    if (displayName.isNotEmpty) {
      return 'Hello $displayName';
    }

    final email = (user.email ?? '').trim();
    if (email.isNotEmpty) {
      return 'Hello ${email.split('@').first}';
    }

    return user.isAnonymous ? 'Anonymous' : 'Hello there';
  }

  Future<User?> signInAsGuest() async {
    if (_auth.currentUser != null) {
      return _auth.currentUser;
    }

    final credential = await _auth.signInAnonymously();
    return credential.user;
  }

  Future<User?> ensureSignedIn() => signInAsGuest();

  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final current = _auth.currentUser;
    final credential = EmailAuthProvider.credential(
      email: trimmedEmail,
      password: password,
    );

    UserCredential result;
    if (current != null && current.isAnonymous) {
      result = await current.linkWithCredential(credential);
    } else {
      result = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
    }

    final user = result.user;
    if (user != null && trimmedName.isNotEmpty) {
      await user.updateDisplayName(trimmedName);
      await user.reload();
    }

    return _auth.currentUser;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    final current = _auth.currentUser;
    if (current != null && current.isAnonymous) {
      await _auth.signOut();
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );

    return credential.user;
  }

  Future<void> signOut() => _auth.signOut();
}
