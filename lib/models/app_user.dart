import 'package:cloud_firestore/cloud_firestore.dart';


class AppUser {
  final String uid;
  final String name;
  final String email;
  final bool isOnline;
  final Timestamp? lastSeen;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.isOnline,
    this.lastSeen,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'isOnline': isOnline,
      'lastSeen': lastSeen ?? FieldValue.serverTimestamp(),
    };
  }
}
