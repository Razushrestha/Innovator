import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:innovator/models/chat_user.dart';
import 'package:innovator/models/message.dart';
import 'notification_access_token.dart';


class APIs {
  //For authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  //for accessing cloiud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  //for accessing firestore storage
  static FirebaseStorage storage = FirebaseStorage.instance;

//for getting current User info
  static ChatUser me = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey, I am Using ",
      image: user.photoURL.toString(),
      createdAt: '',
      isOnline: false,
      lastActive: '',
      pushToken: '');

  //to return current user
  static get user => auth.currentUser!;

//for accessing firebase messaging (push notification)
  static FirebaseMessaging Fmessaging = FirebaseMessaging.instance;

//for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await Fmessaging.requestPermission();
    await Fmessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push Token:$t');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }

// for checking if user exists or not ?
  static Future<bool> userExists() async {
    return (await firestore.collection('Users').doc(user.uid).get()).exists;
  }

  // for adding chat user if user exists or not ?
  static Future<bool> addchatuser(String email) async {
    final data = await firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .get();

    log('data: ${data.docs}');
    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      log('User Exists : ${data.docs.first.data()}');

      //user exists
      firestore
          .collection('Users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      return false;
    }
  }

// for getting user info
  static Future<void> getselfInfo() async {
    await firestore.collection('Users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        //for setting user status to active
        APIs.updateActiveStatus(true);
        //log('My Data: ${user.data}');
      } else {
        await createUser().then((value) => getselfInfo());
      }
    });
  }

  // for sending push notification

  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "message": {
          "token": chatUser.pushToken,
          "notification": {
            "title": me.name,
            "body": msg,
          },
          "data": {
            "some_data": "User  ID : ${me.id}",
          },
        },
      };

      const projectID = 'message-ea92f';

      final bearerToken = await NotificationAccessToken.getToken;

      log('bearerToken: $bearerToken');

      if (bearerToken == null) return;

      var res = await post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/$projectID/messages:send'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $bearerToken'
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE: $e');
    }
  }

  static Future<void> createUser() async {
    final time = DateTime.now().microsecondsSinceEpoch.toString();
    final chatUser = ChatUser(
        id: user.uid,
        name: user.displayName.toString(),
        email: user.email.toString(),
        about: "Hey I'm using Innovator Chatroom",
        image: user.photoURL.toString(),
        createdAt: time,
        isOnline: false,
        lastActive: time,
        pushToken: '');
    return await firestore
        .collection('Users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userIds) {
    log('\n UserIds: $userIds');
    return firestore
        .collection('Users')
        .where('id', whereIn: userIds.isEmpty ? [''] : userIds)
        .snapshots();
  }

  // for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('Users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }

// for getting knows user fromn firebase
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyuserId() {
    return firestore
        .collection('Users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  // for Updating user info ?
  static Future<void> updateUserInfo() async {
    await firestore.collection('Users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  static Future<void> updateProfilePicture(File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('profilepicture/${user.uid}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000}kb');
    });

    //ronit its updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore.collection('Users').doc(user.uid).update({
      'image': me.image,
    });
  }
// Chat Screen Related APIs

//useful for getting conservation ID

  static String getconservationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // for getting all messages of a specific person from firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> getallmessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getconservationID(user.id)}/message/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  //for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
//message sending time (also used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

//message to send

    final Message message = Message(
        msg: msg,
        read: '',
        told: chatUser.id,
        type: type,
        fromid: user.uid,
        sent: time);

    final ref = firestore
        .collection('chats/${getconservationID(chatUser.id)}/message/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chatUser, type == Type.text ? msg : 'image'));
  }

  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getconservationID(message.fromid)}/message/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return firestore
        .collection('chats/${getconservationID(user.id)}/message/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static String getFormattedTime(
      {required BuildContext context, required String time}) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    return TimeOfDay.fromDateTime(date).format(context);
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;
    final ref = storage.ref().child(
        'images/${getconservationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000}kb');
    });

    //ronit its updating image in firestore database
    final imageurl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageurl, Type.image);
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('Users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('Users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getconservationID(message.told)}/message/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  static Future<void> updatemessage(Message message, String UpdateMsg) async {
    await firestore
        .collection('chats/${getconservationID(message.told)}/message/')
        .doc(message.sent)
        .update({'msg': UpdateMsg});
  }


  static Future<List<String>> getMyUserIdsAsList() async {
  final snapshot = await firestore
      .collection('Users')
      .doc(user.uid)
      .collection('my_users')
      .get();
  
  return snapshot.docs.map((e) => e.id).toList();
}
}
