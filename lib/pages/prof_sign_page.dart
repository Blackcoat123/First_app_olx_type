import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // For Base64 encoding/decoding
import 'package:image/image.dart' as img; // Add prefix 'img' to avoid conflict

import 'home_page.dart';

class Profile_Page extends StatefulWidget {
  final String userId; // Add userId parameter
  Profile_Page({required this.userId}); // Update constructor

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<Profile_Page> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  String? gender;
  String? location;
  File? _image; // To store the selected image
  final ImagePicker _picker = ImagePicker(); // For picking images

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to compress and convert image to Base64
  String _compressAndConvertImageToBase64(File image) {
    final imageBytes = image.readAsBytesSync();
    final decodedImage = img.decodeImage(imageBytes); // Use 'img' prefix
    final resizedImage = img.copyResize(decodedImage!, width: 500); // Resize image
    final compressedImageBytes = img.encodeJpg(resizedImage, quality: 85); // Compress image
    return base64Encode(compressedImageBytes); // Convert to Base64
  }

  void _saveProfile() async {
    String? base64Image;
    if (_image != null) {
      // Compress and convert image to Base64 if an image is selected
      base64Image = _compressAndConvertImageToBase64(_image!);
    }

    // Save profile data to Firestore
    await _firestore.collection('users').doc(widget.userId).set({
      'firstName': firstNameController.text,
      'lastName': lastNameController.text,
      'contact': contactController.text,
      'age': ageController.text,
      'gender': gender,
      'location': location,
      'email': FirebaseAuth.instance.currentUser!.email, // Save user email
      'profileImage': base64Image, // Save Base64 image (if available)
    });

    // Navigate to the main app screen (e.g., HomePage)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700, // AppBar color
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueGrey.shade900,
              Colors.blueGrey.shade700,
              Colors.blueGrey.shade500,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.15, // Dynamic size
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _image != null
                                ? FileImage(_image!) // Display selected image
                                : null,
                            child: _image == null
                                ? Icon(Icons.person, size: screenWidth * 0.15, color: Colors.white)
                                : null,
                          ),
                          FloatingActionButton(
                            mini: true,
                            child: Icon(Icons.add_a_photo),
                            onPressed: _pickImage, // Call _pickImage on button press
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02), // Dynamic spacing
                    TextFormField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.02), // Dynamic spacing
                    TextFormField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.02), // Dynamic spacing
                    TextFormField(
                      controller: contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.02), // Dynamic spacing
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: screenHeight * 0.02), // Dynamic spacing
                    DropdownButtonFormField<String>(
                      value: gender,
                      items: ['Male', 'Female', 'Other']
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: TextStyle(color: Colors.white)),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => gender = val),
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      dropdownColor: Colors.blueGrey.shade800, // Dropdown background
                    ),
                    SizedBox(height: screenHeight * 0.02), // Dynamic spacing
                    DropdownButtonFormField<String>(
                      value: location,
                      items: ['North', 'South']
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: TextStyle(color: Colors.white)),
                      ))
                          .toList(),
                      onChanged: (val) => setState(() => location = val),
                      decoration: InputDecoration(
                        labelText: 'Location',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      dropdownColor: Colors.blueGrey.shade800, // Dropdown background
                    ),
                    SizedBox(height: screenHeight * 0.03), // Dynamic spacing
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: Text(
                          'Submit',
                          style: TextStyle(fontSize: screenWidth * 0.035,color: Colors.white), // Dynamic font size
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.02, // Dynamic padding
                            horizontal: screenWidth * 0.1, // Dynamic padding
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.black54, // Button color
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02), // Dynamic spacing
                    Center(
                      child: TextButton(
                        onPressed: _saveProfile,
                        child: Text(
                          'Use Without Pic',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.04, // Dynamic font size
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}