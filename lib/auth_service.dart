import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Sign up failed: $e';
    }
  }

  // Sign in with email and password (UPDATED)
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;
      final userRef = _firestore.collection('users').doc(user.uid);

      // Create or update user doc so we never get "not-found"
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? user.email?.split('@')[0],
        'provider': 'email',
        'lastLogin': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Sign in failed: $e';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw 'Google Sign-In cancelled';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Save or update user data in Firestore
      final userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (!userDoc.exists) {
        // New user - create document
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName,
          'photoUrl': userCredential.user!.photoURL,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Existing user - update last login and profile
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
          'photoUrl': userCredential.user!.photoURL,
          'name': userCredential.user!.displayName,
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google Sign-In failed: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e) {
      throw 'Sign out failed: $e';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Password reset failed: $e';
    }
  }

  // Delete user account and all associated data
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      final batch = _firestore.batch();

      // Delete all user chats
      final chatsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .get();

      for (var doc in chatsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete user document
      batch.delete(_firestore.collection('users').doc(user.uid));

      // Commit batch
      await batch.commit();

      // Delete Firebase Auth account
      await user.delete();

      // Sign out from Google if signed in
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Please sign in again to delete your account';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Account deletion failed: $e';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      // Update Firebase Auth profile
      if (name != null) {
        await user.updateDisplayName(name);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update Firestore
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) updates['name'] = name;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(user.uid).update(updates);

      // Reload user to get fresh data
      await user.reload();
    } catch (e) {
      throw 'Profile update failed: $e';
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) throw 'No user logged in';

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Current password is incorrect';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Password change failed: $e';
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      throw 'Failed to fetch user data: $e';
    }
  }

  // Stream user data from Firestore
  Stream<DocumentSnapshot> streamUserData(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // ==================== CHAT MANAGEMENT ====================

  // Save a chat message
  Future<String> saveChatMessage({
    required String message,
    required String response,
    String? category,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      print('🟢 Saving chat for uid=${user.uid}');
      print('   message: $message');
      print('   response length: ${response.length}');

      DocumentReference chatRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .add({
        'message': message,
        'response': response,
        'category': category ?? 'general',
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Chat saved with id=${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      print('❌ Failed to save chat: $e');
      throw 'Failed to save chat: $e';
    }
  }


  // Get all chats for current user (ordered by timestamp)
  Future<List<Map<String, dynamic>>> getUserChats({int? limit}) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      Query query = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Failed to fetch chats: $e';
    }
  }

  // Stream user chats in real-time
  Stream<QuerySnapshot> streamUserChats({int? limit}) {
    User? user = _auth.currentUser;
    if (user == null) throw 'No user logged in';

    Query query = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .orderBy('timestamp', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // Get recent chats (last N chats)
  Future<List<Map<String, dynamic>>> getRecentChats({int limit = 10}) async {
    return getUserChats(limit: limit);
  }

  // Get a specific chat by ID
  Future<Map<String, dynamic>?> getChatById(String chatId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .get();

      if (!doc.exists) return null;

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      throw 'Failed to fetch chat: $e';
    }
  }

  // Delete a specific chat
  Future<void> deleteChat(String chatId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .delete();
    } catch (e) {
      throw 'Failed to delete chat: $e';
    }
  }

  // Delete all chats for current user
  Future<void> deleteAllChats() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      final chatsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .get();

      final batch = _firestore.batch();
      for (var doc in chatsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw 'Failed to delete chats: $e';
    }
  }

  // Get chat count for current user
  Future<int> getChatCount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      AggregateQuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw 'Failed to get chat count: $e';
    }
  }

  // Search chats by keyword
  Future<List<Map<String, dynamic>>> searchChats(String keyword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> results = snapshot.docs
          .map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      })
          .where((chat) {
        String message = (chat['message'] ?? '').toString().toLowerCase();
        String response = (chat['response'] ?? '').toString().toLowerCase();
        return message.contains(keyword.toLowerCase()) ||
            response.contains(keyword.toLowerCase());
      })
          .toList();

      return results;
    } catch (e) {
      throw 'Failed to search chats: $e';
    }
  }

  // Get chats by category
  Future<List<Map<String, dynamic>>> getChatsByCategory(String category) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .where('category', isEqualTo: category)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw 'Failed to fetch chats by category: $e';
    }
  }

  // Update chat category
  Future<void> updateChatCategory(String chatId, String category) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('chats')
          .doc(chatId)
          .update({
        'category': category,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update chat category: $e';
    }
  }

  // ==================== END CHAT MANAGEMENT ====================

  // Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw 'No user logged in';
      if (user.emailVerified) throw 'Email already verified';

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send verification email: $e';
    }
  }

  // Reload current user
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters)';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      case 'invalid-credential':
        return 'Invalid credentials provided';
      case 'account-exists-with-different-credential':
        return 'Account exists with different sign-in method';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action';
      default:
        return e.message ?? 'Authentication error occurred';
    }
  }
}
