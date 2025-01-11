import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ChatScreen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  Future<void> acceptClaimRequest(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final collectionName = data['collectionName'] as String?;
    final itemDocId = data['itemDocId'] as String?;
    if (collectionName == null || itemDocId == null) return;

    try {
      final claimerId = data['requesterUserId'] ?? '';
      final claimerName = data['requesterName'] ?? 'Unknown';
      final claimerContact = data['requesterContact'] ?? 'Unknown';

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(itemDocId)
          .update({
        'claimed': true,
        'claimedById': claimerId,
        'claimedByName': claimerName,
        'claimedByContact': claimerContact,
        'claimedAt': DateTime.now().toIso8601String(),
      });

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(doc.id)
          .update({'isAccepted': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Claim accepted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error accepting claim: $e")),
      );
    }
  }

  Future<void> denyClaimRequest(DocumentSnapshot doc) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(doc.id)
          .update({'isDenied': true});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Claim request denied.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error denying claim: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF90CAF9), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const Center(
            child: Text("You must be logged in to see notifications."),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF90CAF9), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('toUserId', isEqualTo: _currentUser!.uid)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No notifications"));
            }

            final docs = snapshot.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final message = data['message'] ?? 'No message';
                final timestamp = data['timestamp'];
                final isRead = data['isRead'] == true;
                final type = data['type'] ?? 'normal';

                String dateString = '';
                if (timestamp is Timestamp) {
                  dateString = timestamp.toDate().toString();
                }

                final isAccepted = data['isAccepted'] == true;
                final isDenied = data['isDenied'] == true;

                Widget listTile = ListTile(
                  tileColor: isRead ? Colors.white : Colors.blue[50],
                  title: Text(
                    message,
                    style: TextStyle(
                        fontWeight:
                        isRead ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text(dateString),
                );

                Widget? actionButtons;
                if (type == 'claimRequest') {
                  if (!isAccepted && !isDenied) {
                    actionButtons = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () => acceptClaimRequest(doc),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Accept"),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => denyClaimRequest(doc),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Deny"),
                        ),
                      ],
                    );
                  } else if (isAccepted) {
                    actionButtons = Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isRead)
                          ElevatedButton(
                            onPressed: () {
                              markAsRead(docId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Mark as Read"),
                          ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline,
                              color: Colors.blue),
                          onPressed: () {
                            final requesterId = data['requesterUserId'];
                            final ownerId = data['toUserId'];
                            final itemDocId = data['itemDocId'];
                            final collectionName = data['collectionName'];
                            final String chatId =
                                "${ownerId}_$requesterId\_$itemDocId";

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chatId,
                                  ownerId: ownerId,
                                  requesterId: requesterId,
                                  collectionName: collectionName,
                                  itemDocId: itemDocId,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                } else if (type == 'message') {
                  actionButtons = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isRead)
                        ElevatedButton(
                          onPressed: () {
                            markAsRead(docId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Mark as Read"),
                        ),
                      const SizedBox(height: 8),
                      if (data['chatId'] != null &&
                          data['ownerId'] != null &&
                          data['requesterId'] != null &&
                          data['collectionName'] != null &&
                          data['itemDocId'] != null)
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline,
                              color: Colors.blue),
                          onPressed: () {
                            final chatId = data['chatId'];
                            final ownerId = data['ownerId'];
                            final requesterId = data['requesterId'];
                            final collectionName = data['collectionName'];
                            final itemDocId = data['itemDocId'];

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chatId,
                                  ownerId: ownerId,
                                  requesterId: requesterId,
                                  collectionName: collectionName,
                                  itemDocId: itemDocId,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                } else if (!isRead) {
                  actionButtons = ElevatedButton(
                    onPressed: () {
                      markAsRead(docId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Mark as Read"),
                  );
                }

                return Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        listTile,
                        if (actionButtons != null) ...[
                          const Divider(),
                          actionButtons,
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
