import 'package:chating_app/screens/chat_screen.dart';
import 'package:chating_app/screens/login_screen.dart';
import 'package:chating_app/services/auth_services.dart';
import 'package:chating_app/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthServices _auth = AuthServices();
  final ChatService _chatService = ChatService();

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserStream(),
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong. Please try again.'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        final users = snapshot.data!.docs
            .where((doc) => doc['uid'] != currentUserId)
            .toList();

        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No other users yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Invite friends to start chatting!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            return _buildUserTile(userData);
          },
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> userData) {
    final bool isOnline = userData['isOnline'] ?? false;
    final String name = userData['name'] ?? 'Unknown';
    final String email = userData['email'] ?? '';
    final String uid = userData['uid'] ?? '';

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        email,
        style: const TextStyle(fontSize: 13),
      ),
      trailing: Text(
        isOnline ? 'Online' : 'Offline',
        style: TextStyle(
          color: isOnline ? Colors.green : Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              receiverId: uid,
              receiverName: name,
              receiverEmail: email,
            ),
          ),
        );
      },
    );
  }
}
