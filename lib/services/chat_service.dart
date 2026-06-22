import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); 
    return ids.join('_');
  }


  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatId = getChatId(currentUserId, receiverId);
    final Timestamp timestamp = Timestamp.now();

    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
    });
  }

  Stream<QuerySnapshot> streamMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

 
  Stream<QuerySnapshot> getUserStream() {
    return _firestore.collection('users').snapshots();
  }

  
  Stream<DocumentSnapshot> getUserStreamById(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
