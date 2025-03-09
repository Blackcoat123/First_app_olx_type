import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert'; // For Base64 encoding/decoding
import 'package:image/image.dart' as img; // Add prefix 'img' to avoid conflict
import 'package:kuchbhi/pages/home_page.dart';
import 'myads_page.dart'; // Import the MyAdsPage

class AddItemPage extends StatefulWidget {
  final String userId; // Pass the current user's ID

  const AddItemPage({required this.userId});

  @override
  _AddItemPageState createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _description1Controller = TextEditingController();
  final TextEditingController _description2Controller = TextEditingController();
  String? _selectedLocation;
  final List<String> _locations = ['North', 'South'];
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

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
    final resizedImage = img.copyResize(decodedImage!, width: 500); // Use 'img' prefix
    final compressedImageBytes = img.encodeJpg(resizedImage, quality: 85); // Use 'img' prefix
    return base64Encode(compressedImageBytes); // Convert to Base64
  }

  // Function to submit data to Firestore
  Future<void> _submitData() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Compress and convert image to Base64
      String base64Image = _compressAndConvertImageToBase64(_image!);
      print('Image compressed and converted to Base64');

      // Save data to Firestore
      await FirebaseFirestore.instance.collection('items').add({
        'userId': widget.userId, // Include the userId
        'price': double.parse(_priceController.text),
        'title': _titleController.text,
        'description1': _description1Controller.text,
        'description2': _description2Controller.text,
        'location': _selectedLocation,
        'imageBase64': base64Image, // Store Base64 string
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item added successfully!')),
      );

      // Clear the form
      _priceController.clear();
      _titleController.clear();
      _description1Controller.clear();
      _description2Controller.clear();
      setState(() {
        _selectedLocation = null;
        _image = null;
      });

      // Navigate to MyAdsPage after successful submission
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(), // Pass the userId
        ),
      );
    } catch (e) {
      print('Error submitting data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade700,
        title: Text(
          "Add Item",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image == null
                      ? Center(
                    child: Text(
                      "Add Images",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )
                      : Image.file(_image!, fit: BoxFit.cover), // Flutter's Image widget
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Price",
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when enabled
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when focused
                  ),
                  prefixIcon: Icon(Icons.currency_rupee, color: Colors.white), // Icon for price
                ),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(
                  labelText: "Location",
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when enabled
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when focused
                  ),
                  prefixIcon: Icon(Icons.location_on, color: Colors.white), // Icon for location
                ),
                dropdownColor: Colors.blueGrey.shade800, // Set dropdown background color
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(
                      location,
                      style: TextStyle(color: Colors.white), // White text for dropdown items
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title of the Item",
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when enabled
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when focused
                  ),
                  prefixIcon: Icon(Icons.title, color: Colors.white), // Icon for title
                ),
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _description1Controller,
                maxLines: 5, // Same size as Description 2
                decoration: InputDecoration(
                  labelText: "Description 1 (Max 50 words)",
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when enabled
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when focused
                  ),
                  prefixIcon: Icon(Icons.description, color: Colors.white), // Icon for description
                ),
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _description2Controller,
                maxLines: 5, // Same size as Description 1
                decoration: InputDecoration(
                  labelText: "Description 2",
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when enabled
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White border when focused
                  ),
                  prefixIcon: Icon(Icons.description, color: Colors.white), // Icon for description
                ),
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Submit",
                    style: TextStyle(fontSize: 16, color: Colors.white), // Set text color to white
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.blueGrey.shade800, // Make the button slightly darker than the background
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}