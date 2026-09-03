import 'package:flutter/material.dart';

import '../services/driver_auth_service.dart';
import 'driver_home_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  static const Color yellow = Color(0xFFFFD60A);
  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color darkCard = Color(0xFF1A1A1A);

  final DriverAuthService _authService = DriverAuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isLoading) return;

    final String phone = _phoneController.text.trim();
    if (phone.length < 7) {
      _showError('Please enter a valid phone number.');
      return;
    }

    if (DriverAuthService.testingOtpBypassEnabled) {
      await _completeApprovedDriverLogin(phone);
      return;
    }

    if (!_otpSent) {
      await _sendRealOtp(phone);
    } else {
      await _verifyRealOtp(phone);
    }
  }

  Future<void> _sendRealOtp(String phone) async {
    _setLoading(true);

    try {
      await _authService.sendPhoneOtp(
        phoneNumber: _firebasePhoneNumber(phone),
        onCodeSent: (String verificationId, int? _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _isLoading = false;
          });
          _showMessage('OTP sent to your phone.');
        },
        onAutoVerified: (_) {
          _completeApprovedDriverLogin(phone);
        },
        onError: (String message) {
          if (!mounted) return;
          _setLoading(false);
          _showError(message);
        },
      );
    } catch (error) {
      _showError(_cleanError(error));
      _setLoading(false);
    }
  }

  Future<void> _verifyRealOtp(String phone) async {
    final String code = _otpController.text.trim();
    final String verificationId = _verificationId ?? '';

    if (code.length < 6 || verificationId.isEmpty) {
      _showError('Please enter the valid 6 digit OTP.');
      return;
    }

    _setLoading(true);
    try {
      await _authService.verifyPhoneOtp(
        verificationId: verificationId,
        smsCode: code,
      );
      await _completeApprovedDriverLogin(phone, manageLoading: false);
    } catch (error) {
      _showError(_cleanError(error));
      _setLoading(false);
    }
  }

  Future<void> _completeApprovedDriverLogin(
    String phone, {
    bool manageLoading = true,
  }) async {
    if (manageLoading) _setLoading(true);

    try {
      final DriverLoginResult driver = await _authService.loginDriver(
        phoneNumber: phone,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DriverHomeScreen(
            driverId: driver.driverId,
            driverName: driver.driverName,
            vehicleType: driver.vehicleType,
            vehicleNumber: driver.vehicleNumber,
          ),
        ),
      );
    } catch (error) {
      _showError(_cleanError(error));
      _setLoading(false);
    }
  }

  String _firebasePhoneNumber(String phone) {
    final String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('+')) return clean;
    if (clean.startsWith('0')) return '+92${clean.substring(1)}';
    if (clean.startsWith('92')) return '+$clean';
    return clean;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  void _showError(String message) {
    _showSnackBar(message, Colors.red);
  }

  void _showMessage(String message) {
    _showSnackBar(message, Colors.green);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(backgroundColor: color, content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool testing = DriverAuthService.testingOtpBypassEnabled;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        title: const Text(
          'Driver Login',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 30),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: yellow.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_taxi, color: yellow, size: 55),
              ),
              const SizedBox(height: 25),
              const Text(
                'Welcome, Driver',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Login to manage your SWAT RIDE driver account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 35),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: darkCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Phone Number',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      enabled: !_isLoading && !_otpSent,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '03XXXXXXXXX',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_otpSent && !testing) ...<Widget>[
                      const SizedBox(height: 18),
                      const Text(
                        'OTP Code',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otpController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          hintText: 'Enter 6 digit OTP',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _otpSent && !testing ? 'Verify OTP' : 'Continue',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (testing ? Colors.orange : Colors.green)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (testing ? Colors.orange : Colors.green)
                        .withValues(alpha: 0.30),
                  ),
                ),
                child: Text(
                  testing
                      ? 'Testing mode: OTP is bypassed, but only an approved Firestore driver can login.'
                      : 'Production mode: Firebase Phone OTP verification is active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: testing ? Colors.orange : Colors.green,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pending, rejected or suspended driver accounts cannot go online.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
