import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final TextEditingController otpController =
      TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  // =========================================================
  // VERIFY OTP
  // =========================================================

  Future<void> _verifyOtp() async {
    final String otp = otpController.text.trim();

    if (otp.isEmpty) {
      _showError('Please enter the OTP.');
      return;
    }

    if (otp.length != 6) {
      _showError('Please enter the 6-digit OTP.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // =======================================================
      // CREATE PHONE AUTH CREDENTIAL
      // =======================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      // =======================================================
      // SIGN IN WITH PHONE OTP
      // =======================================================

      await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      if (!mounted) return;

      // =======================================================
      // SUCCESS
      // =======================================================

      _showSuccess(
        'Phone number verified successfully.',
      );

      // =======================================================
      // GO TO HOME SCREEN
      // =======================================================

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message =
          'OTP verification failed. Please try again.';

      switch (e.code) {
        case 'invalid-verification-code':
          message =
              'The OTP you entered is incorrect.';
          break;

        case 'session-expired':
          message =
              'The OTP has expired. Please request a new OTP.';
          break;

        case 'invalid-credential':
          message =
              'Invalid OTP or verification session.';
          break;

        case 'network-request-failed':
          message =
              'Network error. Please check your internet connection.';
          break;

        case 'too-many-requests':
          message =
              'Too many attempts. Please try again later.';
          break;

        default:
          message =
              e.message ??
                  'OTP verification failed. Please try again.';
      }

      _showError(message);
    } catch (e) {
      if (!mounted) return;

      _showError(
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // SUCCESS MESSAGE
  // =========================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(message),
      ),
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Verify Phone Number',
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 30),

              // =================================================
              // LOGO
              // =================================================

              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(25),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.35,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(25),

                  child: Image.asset(
                    'assets/images/swat_ride_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // TITLE
              // =================================================

              const Text(
                'Enter Verification Code',
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // =================================================
              // PHONE INFORMATION
              // =================================================

              Text(
                'We sent a 6-digit verification code to',
                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                widget.phoneNumber,
                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD60A),
                ),
              ),

              const SizedBox(height: 35),

              // =================================================
              // OTP INPUT
              // =================================================

              TextFormField(
                controller: otpController,

                keyboardType:
                    TextInputType.number,

                maxLength: 6,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),

                decoration:
                    const InputDecoration(
                  labelText: 'Enter OTP',
                  hintText: '123456',

                  prefixIcon: Icon(
                    Icons.lock_outline,
                  ),

                  border:
                      OutlineInputBorder(),

                  counterText: '',
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // VERIFY BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed:
                      isLoading
                          ? null
                          : _verifyOtp,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFFFD60A,
                    ),

                    foregroundColor:
                        Colors.black,

                    disabledBackgroundColor:
                        Colors.grey.shade700,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,

                          child:
                              CircularProgressIndicator(
                            strokeWidth: 3,
                            color:
                                Colors.black,
                          ),
                        )
                      : const Text(
                          'Verify OTP',

                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // CHANGE NUMBER
              // =================================================

              TextButton(
                onPressed:
                    isLoading
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                            );
                          },

                child: const Text(
                  'Change Phone Number',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}