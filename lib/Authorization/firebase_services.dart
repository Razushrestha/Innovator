import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Debug helper to check authentication status
  static void debugAuthStatus() {
    final user = _auth.currentUser;
    developer.log('=== DEBUG AUTH STATUS ===');
    developer.log('User: ${user?.email}');
    developer.log('UID: ${user?.uid}');
    developer.log('Is Anonymous: ${user?.isAnonymous}');
    developer.log('Email Verified: ${user?.emailVerified}');
    developer.log('Provider Data: ${user?.providerData.map((p) => p.providerId).toList()}');
    developer.log('========================');
  }

  // Save user data to Firestore with enhanced debugging
  static Future<void> saveUserToFirestore({
    required String userId,
    required String name,
    required String email,
    String? phone,
    String? dob,
    String? photoURL,
    String provider = 'email',
  }) async {
    try {
      debugAuthStatus();
      
      developer.log('Attempting to save user to Firestore...');
      developer.log('User ID: $userId');
      developer.log('Name: $name');
      developer.log('Email: $email');
      
      final userDoc = _firestore.collection('users').doc(userId);
      
      final userData = {
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'dob': dob ?? '',
        'photoURL': photoURL ?? '',
        'provider': provider,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      developer.log('User data to save: $userData');
      
      await userDoc.set(userData, SetOptions(merge: true));
      developer.log('User saved to Firestore successfully: $userId');
    } catch (e) {
      developer.log('Error saving user to Firestore: $e');
      developer.log('Error details: ${e.runtimeType}');
      if (e is FirebaseException) {
        developer.log('Firebase error code: ${e.code}');
        developer.log('Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // Update user online status with enhanced debugging
  static Future<void> updateUserStatus(String userId, bool isOnline) async {
    try {
      debugAuthStatus();
      
      developer.log('Attempting to update user status...');
      developer.log('User ID: $userId');
      developer.log('Is Online: $isOnline');
      developer.log('Current user UID: ${_auth.currentUser?.uid}');
      developer.log('UIDs match: ${_auth.currentUser?.uid == userId}');
      
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      developer.log('User status updated successfully');
    } catch (e) {
      developer.log('Error updating user status: $e');
      developer.log('Error details: ${e.runtimeType}');
      if (e is FirebaseException) {
        developer.log('Firebase error code: ${e.code}');
        developer.log('Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // Test Firestore connection and permissions
  static Future<void> testFirestoreConnection() async {
    try {
      debugAuthStatus();
      
      developer.log('Testing Firestore connection...');
      
      // Try to read a simple document
      final testDoc = await _firestore.collection('test').doc('connection').get();
      developer.log('Test read successful: ${testDoc.exists}');
      
      // Try to write a simple document
      await _firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
        'test': true,
      });
      developer.log('Test write successful');
      
      // Clean up test document
      await _firestore.collection('test').doc('connection').delete();
      developer.log('Test cleanup successful');
      
    } catch (e) {
      developer.log('Firestore connection test failed: $e');
      if (e is FirebaseException) {
        developer.log('Firebase error code: ${e.code}');
        developer.log('Firebase error message: ${e.message}');
      }
      rethrow;
    }
  }

  // Update user profile with debugging
  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? dob,
    String? photoURL,
  }) async {
    try {
      debugAuthStatus();
      
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (dob != null) updateData['dob'] = dob;
      if (photoURL != null) updateData['photoURL'] = photoURL;

      developer.log('Updating user profile with data: $updateData');

      await _firestore.collection('users').doc(userId).update(updateData);
      developer.log('User profile updated successfully: $userId');
    } catch (e) {
      developer.log('Error updating user profile: $e');
      rethrow;
    }
  }

  // Get all users for chat list
  static Stream<QuerySnapshot> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('name')
        .snapshots();
  }

  // Get user by ID
  static Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }

  // Send message with debugging
  static Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    required String senderName,
  }) async {
    try {
      debugAuthStatus();
      
      developer.log('Sending message...');
      developer.log('Chat ID: $chatId');
      developer.log('Sender ID: $senderId');
      developer.log('Receiver ID: $receiverId');
      developer.log('Current user UID: ${_auth.currentUser?.uid}');
      
      final messageData = {
        'chatId': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'message': message,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'messageType': 'text',
      };

      // Add message to messages collection
      await _firestore.collection('messages').add(messageData);

      // Update or create chat document
      final chatData = {
        'chatId': chatId,
        'participants': [senderId, receiverId],
        'lastMessage': message,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
        'lastMessageType': 'text',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('chats').doc(chatId).set(chatData, SetOptions(merge: true));
      
      developer.log('Message sent successfully');
    } catch (e) {
      developer.log('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a specific chat
  static Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get user's chats
  static Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final unreadMessages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      developer.log('Error marking messages as read: $e');
    }
  }

  // Generate chat ID from two user IDs
  static String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Get unread message count for a chat
  static Stream<QuerySnapshot> getUnreadMessageCount(String chatId, String userId) {
    return _firestore
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  // Search users by name or email
  static Future<QuerySnapshot> searchUsers(String query) {
    return _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();
  }
}