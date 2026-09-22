import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthNotifier extends Notifier<AuthStatus> {
  StreamSubscription<User?>? _authStateSubscription;

  bool get hasPasswordProvider {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'password');
  }

  @override
  AuthStatus build() {
    _authStateSubscription?.cancel();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      if (user != null) {
        state = AuthStatus.authenticated;
      } else {
        state = AuthStatus.unauthenticated;
      }
    });

    return FirebaseAuth.instance.currentUser != null
        ? AuthStatus.authenticated
        : AuthStatus.initial;
  }

  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred during login.';
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred during signup.';
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> updateProfilePicture(File imageFile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_pictures/${user.uid}.jpg',
      );
      await storageRef.putFile(imageFile);
      final downloadUrl = await storageRef.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      // Force a state update to rebuild the UI
      state = AuthStatus.authenticated;
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  Future<void> updateProfileName(String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';
      await user.updateDisplayName(name);
      state = AuthStatus.authenticated;
    } catch (e) {
      throw 'Failed to update name: $e';
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'For your security, please log out and log back in before changing your password.';
      }
      throw e.message ?? 'An unknown error occurred';
    } catch (e) {
      throw 'Failed to update password: $e';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred';
    } catch (e) {
      throw 'Failed to send password reset email: $e';
    }
  }

  Future<void> changePasswordWithReauth(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      final email = user.email;
      if (email == null) throw 'No email associated with this account';

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: email,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw 'Incorrect old password';
      }
      throw e.message ?? 'An unknown error occurred';
    } catch (e) {
      throw 'Failed to change password: $e';
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      return userCredential.additionalUserInfo?.isNewUser ?? false;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred during Google sign-in.';
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthStatus>(() {
  return AuthNotifier();
});
