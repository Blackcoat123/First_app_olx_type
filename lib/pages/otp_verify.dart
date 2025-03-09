import 'package:flutter/material.dart';
import 'package:kuchbhi/pages/prof_sign_page.dart';
import '../services/firestore_service.dart'; // For OTP verification
import 'profile_page.dart'; // For navigation after OTP verification

class OTPVerifyPage extends StatelessWidget {
  final String email;
  final String userId;
  final TextEditingController otpController = TextEditingController();

  OTPVerifyPage({required this.email, required this.userId});

  void _verifyOTP(BuildContext context) async {
    final userEnteredOTP = otpController.text;
    final isOTPValid = await FirestoreService.verifyOTP(email, userEnteredOTP);

    if (isOTPValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP Verified Successfully!")),
      );
      // Navigate to ProfilePage after OTP verification
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Profile_Page(userId: userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: otpController,
              decoration: InputDecoration(labelText: "Enter OTP"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _verifyOTP(context),
              child: Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}