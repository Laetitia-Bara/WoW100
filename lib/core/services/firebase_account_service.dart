import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../data/models/app_user_profile.dart';
import '../../data/models/app_wallpaper_preference.dart';

class FirebaseAccountService {
  FirebaseAccountService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleInitialization;

  static const _iosGoogleClientId =
      '536516621931-kbpmmor4o24rupb1te678iimie5t32af.apps.googleusercontent.com';

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<AppWallpaperPreference> get wallpaperPreferenceChanges {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<AppWallpaperPreference>.value(
          AppWallpaperPreference.factions,
        );
      }

      return _userRef(user.uid).snapshots().map((snapshot) {
        return AppWallpaperPreference.fromFirestoreValue(
          snapshot.data()?['wallpaperPreference'],
        );
      });
    });
  }

  Stream<AppUserProfile?> get profileChanges {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream<AppUserProfile?>.value(null);
      }

      unawaited(
        ensureUserProfile(user).catchError((Object error, StackTrace stack) {}),
      );
      return _userRef(user.uid).snapshots().map((snapshot) {
        if (!snapshot.exists) {
          return AppUserProfile(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoURL,
            isPremium: false,
            wallpaperPreference: AppWallpaperPreference.factions,
          );
        }

        return AppUserProfile.fromFirestore(snapshot);
      });
    });
  }

  Future<bool> isPremium() async {
    final user = _auth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final snapshot = await _userRef(user.uid).get();
      if (!snapshot.exists) {
        await ensureUserProfile(user);
        return false;
      }

      return AppUserProfile.fromFirestore(snapshot).isPremium;
    } on FirebaseException {
      return false;
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await ensureUserProfile(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await ensureUserProfile(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithGoogle() async {
    UserCredential credential;
    if (kIsWeb) {
      credential = await _auth.signInWithPopup(GoogleAuthProvider());
    } else {
      await _ensureGoogleInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      credential = await _auth.signInWithCredential(authCredential);
    }

    await ensureUserProfile(credential.user);
    return credential;
  }

  Future<UserCredential> signInWithApple() async {
    UserCredential credential;
    if (kIsWeb) {
      credential = await _auth.signInWithPopup(AppleAuthProvider());
    } else {
      final rawNonce = _generateNonce();
      final nonce = _sha256(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      credential = await _auth.signInWithCredential(oauthCredential);

      final nameParts = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().where((part) => part.trim().isNotEmpty);
      final displayName = nameParts.join(' ').trim();
      if (displayName.isNotEmpty && credential.user?.displayName == null) {
        await credential.user?.updateDisplayName(displayName);
      }
    }

    await ensureUserProfile(credential.user);
    return credential;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } on Object {
        // FirebaseAuth remains the source of truth for the app session.
      }
    }

    await _auth.signOut();
  }

  Future<void> updateWallpaperPreference(
    AppWallpaperPreference preference,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'No Firebase account is signed in.',
      );
    }

    await ensureUserProfile(user);
    await _userRef(user.uid).set({
      'wallpaperPreference': preference.firestoreValue,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureUserProfile(User? user) async {
    if (user == null) {
      return;
    }

    final ref = _userRef(user.uid);
    final snapshot = await ref.get();
    final baseData = <String, Object?>{
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'providerIds': user.providerData.map((info) => info.providerId).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (snapshot.exists) {
      await ref.set(baseData, SetOptions(merge: true));
      return;
    }

    await ref.set({
      ...baseData,
      'isPremium': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<void> _ensureGoogleInitialized() {
    final clientId =
        defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS
        ? _iosGoogleClientId
        : null;

    return _googleInitialization ??= _googleSignIn.initialize(
      clientId: clientId,
    );
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();

    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
