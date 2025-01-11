import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimRequestScreen extends StatefulWidget {
  final String collectionName;
  final String docId;
  final Map<String, dynamic> itemData;

  const ClaimRequestScreen({
    Key? key,
    required this.collectionName,
    required this.docId,
    required this.itemData,
  }) : super(key: key);

  @override
  State<ClaimRequestScreen> createState() => _ClaimRequestScreenState();
}

class _ClaimRequestScreenState extends State<ClaimRequestScreen> {
  final TextEditingController _messageController = TextEditingController();
  String _requesterName = '';
  String _requesterContact = '';
  User? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchCurrentUserInfo();
  }

  Future<void> _fetchCurrentUserInfo() async {
    if (_currentUser == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _requesterName = data['full_name'] ?? '';
          _requesterContact = data['contact_number'] ?? '';
        });
      }
    } catch (e) {}
  }

  Future<void> _sendClaimRequest() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Message field cannot be empty.")));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final postOwnerId = widget.itemData['ownerId'] ?? '';
      final itemName = widget.itemData['itemName'] ?? 'Item';

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUserId': postOwnerId,
        'message': "Claim request for '$itemName' from $_requesterName. Message: $message",
        'timestamp': DateTime.now(),
        'isRead': false,
        'type': 'claimRequest',
        'collectionName': widget.collectionName,
        'itemDocId': widget.docId,
        'requesterUserId': _currentUser!.uid,
        'requesterName': _requesterName,
        'requesterContact': _requesterContact,
        'isAccepted': false,
        'isDenied': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Claim request sent!")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending request: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Claim Request"),
        backgroundColor: Colors.orange,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF90CAF9), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Your Name",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                  controller: TextEditingController(text: _requesterName),
                ),
                const SizedBox(height: 16),
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Contact",
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                  controller: TextEditingController(text: _requesterContact),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Message (Required)",
                    prefixIcon: const Icon(Icons.message),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _sendClaimRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Send Request", style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
