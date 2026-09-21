import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthNotifier extends Notifier<AuthStatus> {
  StreamSubscription<User?>? _authStateSubscription;

  @override
  AuthStatus build() {
    _authStateSubscription?.cancel();
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
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
        password: password
      );
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'An unknown error occurred during login.';
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
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
      
      final storageRef = FirebaseStorage.instance.ref().child('profile_pictures/${user.uid}.jpg');
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
    } catch (e) {
      throw 'Failed to update password: $e';
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
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
