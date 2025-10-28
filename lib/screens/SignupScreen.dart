import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  String otpCode = '';
  String verificationId = '';
  bool otpSent = false;
  bool loading = false;
  DateTime? selectedDOB;

  void _pickDOB() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      selectedDOB = date;
      _dobController.text = "${date.day}/${date.month}/${date.year}";
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    final result = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isNotEmpty;
  }

  void sendOtp(String phone) async {
    setState(() => loading = true);
    await _auth.verifyPhoneNumber(
      phoneNumber: "+91$phone",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${e.message}")));
        setState(() => loading = false);
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          loading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
        setState(() => loading = false);
      },
    );
  }

  void verifyOtpAndCreateUser(String otp) async {
    try {
      setState(() => loading = true);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      final user = _auth.currentUser;

      await _firestore.collection('users').doc(user!.uid).set({
        'username': _usernameController.text.trim(),
        'dob': selectedDOB,
        'phone': user.phoneNumber,
        'profilePhotoUrl': '', // Default empty, can be updated later
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User Created & Logged In")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error verifying OTP: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  void handleSignup() async {
    final username = _usernameController.text.trim();
    final dob = _dobController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty || dob.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final taken = await isUsernameTaken(username);
    if (taken) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Username already taken")));
      return;
    }

    sendOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!otpSent) ...[
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: "Username"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _dobController,
                      readOnly: true,
                      onTap: _pickDOB,
                      decoration: const InputDecoration(
                        labelText: "Date of Birth",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        prefixText: "+91 ",
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: handleSignup,
                      child: const Text("Send OTP"),
                    ),
                  ] else ...[
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      onChanged: (value) => otpCode = value,
                      keyboardType: TextInputType.number,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(5),
                        fieldHeight: 50,
                        fieldWidth: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => verifyOtpAndCreateUser(otpCode),
                      child: const Text("Verify & Sign Up"),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
