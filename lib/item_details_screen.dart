import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lostandfoundproject/NotificationsScreen.dart';
import 'dart:io';
import 'claim_request_screen.dart';

class ItemDetailsScreen extends StatefulWidget {
  final String collectionName;
  final String docId;
  final Map<String, dynamic> data;

  const ItemDetailsScreen({
    Key? key,
    required this.collectionName,
    required this.docId,
    required this.data,
  }) : super(key: key);

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  bool _isLoading = false;
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  void _goToClaimRequestScreen() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must be logged in to send a claim request."))
      );
      return;
    }

    final postOwnerId = widget.data['ownerId'] ?? '';
    if (postOwnerId == _currentUser!.uid) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Warning"),
          content: const Text("You can't claim your own post!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClaimRequestScreen(
          collectionName: widget.collectionName,
          docId: widget.docId,
          itemData: widget.data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.data['lat'] as double?;
    final lng = widget.data['lng'] as double?;
    final imagePath = widget.data['imagePath'] as String?;
    final claimed = widget.data['claimed'] == true;
    final ownerName = widget.data['ownerName'] ?? 'Owner';
    final ownerEmail = widget.data['ownerEmail'] ?? 'No email';
    final ownerContact = widget.data['ownerContact'] ?? 'No contact';

    Widget mapWidget = const SizedBox.shrink();
    if(lat != null && lng != null) {
      final position = LatLng(lat, lng);
      mapWidget = SizedBox(
        height: 200,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: position, zoom: 14),
            markers: {
              Marker(markerId: const MarkerId("itemLocation"), position: position),
            },
          ),
        ),
      );
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = screenWidth * 0.9;
    double imageHeight = imageWidth * 0.6;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF397ADC),
        title: const Text(
          "Item Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: buildBadgeIcon(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
            tooltip: 'Notifications',
          ),
        ],
        shape: const Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 1.0,
          ),
        ),
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
                const SizedBox(height: 10),
                Card(
                  color: Color(0xFFE8EEF4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        if(imagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: imageWidth,
                              height: imageHeight,
                              child: Image.file(
                                File(imagePath),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          "${widget.data['itemName']}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Description: ${widget.data['description']}",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Date: ${widget.data['date']}",
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        mapWidget,
                        const SizedBox(height: 12),
                        const Text(
                          "Posted By:",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                        const SizedBox(height: 6),
                        Text("Name: $ownerName", style: const TextStyle(fontSize: 15)),
                        Text("Email: $ownerEmail", style: const TextStyle(fontSize: 15)),
                        Text("Contact: $ownerContact", style: const TextStyle(fontSize: 15)),
                        const SizedBox(height: 16),
                        if (!claimed)
                          ElevatedButton(
                            onPressed: _goToClaimRequestScreen,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Send Claim Request"),
                          )
                        else
                          const Text(
                            "This item is already claimed",
                            style: TextStyle(fontSize: 18, color: Colors.orange),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBadgeIcon() {
    return const Icon(Icons.mail_outline);
  }
}
