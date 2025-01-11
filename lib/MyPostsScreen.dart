import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({Key? key}) : super(key: key);

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  User? _currentUser;
  bool _isLoading = false;
  List<Map<String, dynamic>> _myPosts = [];

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    if (_currentUser == null) return;
    setState(() => _isLoading = true);

    try {
      final lostSnapshot = await FirebaseFirestore.instance
          .collection('lost')
          .where('ownerId', isEqualTo: _currentUser!.uid)
          .get();

      final foundSnapshot = await FirebaseFirestore.instance
          .collection('found')
          .where('ownerId', isEqualTo: _currentUser!.uid)
          .get();

      final allDocs = [
        ...lostSnapshot.docs.map((e) => {
          "docId": e.id,
          "collectionName": "lost",
          "data": e.data(),
        }),
        ...foundSnapshot.docs.map((e) => {
          "docId": e.id,
          "collectionName": "found",
          "data": e.data(),
        }),
      ];

      setState(() {
        _myPosts = allDocs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error fetching posts: $e")));
    }
  }

  Future<void> _deletePost(String collectionName, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(docId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post deleted successfully!")));

      _fetchMyPosts();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error deleting post: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Posts"),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myPosts.isEmpty
          ? const Center(child: Text("No posts found."))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myPosts.length,
        itemBuilder: (context, index) {
          final post = _myPosts[index];
          final data = post["data"] as Map<String, dynamic>;
          final docId = post["docId"] as String;
          final collectionName = post["collectionName"] as String;

          final itemName = data['itemName'] ?? 'No name';
          final description = data['description'] ?? '';
          final imagePath = data['imagePath'];

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(8.0),
              leading: imagePath != null
                  ? SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  : const SizedBox(
                width: 60,
                height: 60,
                child: Icon(Icons.image, size: 40),
              ),
              title: Text(itemName),
              subtitle: Text(description),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _deletePost(collectionName, docId);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
