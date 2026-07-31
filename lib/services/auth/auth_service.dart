import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  late final Stream<GoogleSignInAccount?> user = _googleSignIn.onCurrentUserChanged.asBroadcastStream();

  Future<bool> validateCurrentUser(GoogleSignInAccount account) async {
    try {
      final bool hasScopes = await _googleSignIn.canAccessScopes([
        'email',
        'profile',
        'https://www.googleapis.com/auth/drive.file',
      ]);
      if (!hasScopes) {
        debugPrint('[AuthService] validateCurrentUser: Required scopes are not granted');
        return false;
      }
      await account.authHeaders;
      return true;
    } catch (e) {
      debugPrint('[AuthService] validateCurrentUser: Token validation failed: $e');
      return false;
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Error during silent sign in: $e');
      return null;
    }
  }

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
