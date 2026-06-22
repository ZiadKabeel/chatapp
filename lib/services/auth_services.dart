import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  
  Future<UserCredential> signUp(
    String email,
    String password,
    String name,
  ) async {
   
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'name': name,
      'email': email,
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<UserCredential> signIn(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(credential.user!.uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return credential;
  }

 
  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;


    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }

    await _auth.signOut();
  }
}