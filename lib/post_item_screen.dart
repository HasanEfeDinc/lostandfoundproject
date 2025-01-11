import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({Key? key}) : super(key: key);

  @override
  State<PostItemScreen> createState() {
    return _PostItemScreenState();
  }
}

class _PostItemScreenState extends State<PostItemScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _selectedStatus = 'Found';
  bool _isLoading = false;
  bool _shareLocation = false;
  double? _lat;
  double? _lng;
  late User? _currentUser;
  String _ownerName = '';
  String _ownerEmail = '';
  String _ownerContact = '';
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    fetchCurrentUserData();
    fetchCurrentDate();
  }

  Future<void> fetchCurrentUserData() async {
    if (_currentUser == null) return;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _ownerName = data['full_name'] ?? '';
          _ownerEmail = data['email'] ?? '';
          _ownerContact = data['contact_number'] ?? '';
        });
      }
    } catch (e) {
      // Hata yönetimi ekleyebilirsiniz
    }
  }

  Future<void> fetchCurrentDate() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://worldtimeapi.org/api/timezone/Etc/UTC'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final datetime = data['datetime'];
        DateTime date = DateTime.parse(datetime);
        String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
        _dateController.text = formattedDate;
      } else {
        DateTime now = DateTime.now();
        String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
        _dateController.text = formattedDate;
      }
    } catch (e) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
      _dateController.text = formattedDate;
    }
    setState(() => _isLoading = false);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _lat = position.latitude;
    _lng = position.longitude;
  }

  Future<void> save() async {
    final itemName = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final date = _dateController.text.trim();
    if (itemName.isEmpty || date.isEmpty || _currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in required fields."))
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_shareLocation) {
        await getLocation();
      }
      final collectionName = _selectedStatus.toLowerCase();
      final docRef = FirebaseFirestore.instance.collection(collectionName).doc();
      await docRef.set({
        'itemName': itemName,
        'description': description,
        'date': date,
        'lat': _shareLocation && _lat != null ? _lat : null,
        'lng': _shareLocation && _lng != null ? _lng : null,
        'ownerId': _currentUser!.uid,
        'ownerName': _ownerName,
        'ownerEmail': _ownerEmail,
        'ownerContact': _ownerContact,
        'claimed': false,
        'claimedById': null,
        'claimedByName': null,
        'claimedByContact': null,
        'claimedAt': null,
        'imagePath': _selectedImage != null ? _selectedImage!.path : null
      });
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving item: $e"))
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget buildStatusSelector() {
    return DropdownButton<String>(
      value: _selectedStatus,
      items: const [
        DropdownMenuItem(value: 'Lost', child: Text('Lost')),
        DropdownMenuItem(value: 'Found', child: Text('Found')),
      ],
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedStatus = val;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resim boyutlarını ekran genişliğine göre dinamik hale getirme
    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = screenWidth * 0.9; // Genişliği artırdım
    double imageHeight = imageWidth * 0.6; // Yüksekliği orantılı olarak ayarladım

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Item"),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
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
                // Resim
                _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.contain, // BoxFit.cover yerine BoxFit.contain
                    ),
                  ),
                )
                    : Container(
                  width: imageWidth,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Pick Image"),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Item Name",
                    prefixIcon: const Icon(Icons.edit),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: "Description (optional)",
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      "Status: ",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    buildStatusSelector(),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Date",
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Checkbox(
                      value: _shareLocation,
                      onChanged: (val) {
                        setState(() {
                          _shareLocation = val ?? false;
                        });
                      },
                    ),
                    const Text("Share my location"),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Save Item", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
