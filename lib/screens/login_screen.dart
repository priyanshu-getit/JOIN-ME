import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  String otpCode = '';
  String verificationId = '';
  bool otpSent = false;
  bool loading = false;

  FirebaseAuth auth = FirebaseAuth.instance;

  void sendOtp(String phone) async {
    setState(() => loading = true);
    await auth.verifyPhoneNumber(
      phoneNumber: "+91$phone",
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification Failed: ${e.message}")),
        );
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

  void verifyOtp(String otp) async {
    try {
      setState(() => loading = true);
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await auth.signInWithCredential(credential);
      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Logged In Successfully")));

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid OTP: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  if (!otpSent)
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Enter Phone Number",
                        prefixText: "+91 ",
                      ),
                    )
                  else
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
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (!otpSent) {
                        final phone = phoneController.text.trim();
                        if (phone.isEmpty || phone.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Enter a valid number"),
                            ),
                          );
                          return;
                        }
                        sendOtp(phone);
                      } else {
                        verifyOtp(otpCode);
                      }
                    },
                    child: Text(otpSent ? "Verify OTP" : "Send OTP"),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text("Don't have an account? Sign up here"),
                  ),
                ],
              ),
      ),
    );
  }
}
