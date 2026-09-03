import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  // =========================================================
  // FIREBASE AUTH
  // =========================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =========================================================
  // PHONE
  // =========================================================

  final TextEditingController phoneController =
      TextEditingController();

  String selectedCountryCode = '+92';

  bool isLoading = false;

  static const String _facebookUrl = 'https://www.facebook.com/SwatRide';
  static const String _instagramUrl = 'https://www.instagram.com/swatride';
  static const String _tiktokUrl = 'https://www.tiktok.com/@swatride';
  static const String _tiktokLoginUrl = String.fromEnvironment(
    'TIKTOK_LOGIN_URL',
  );

  // =========================================================
  // TEST PHONE LOGIN
  // =========================================================
  //
  // Firebase Console Test Phone Number:
  //
  // +92 3414188770
  //
  // Test OTP:
  //
  // 414188
  //
  // IMPORTANT:
  // Firebase Console mein Test Phone Number add hone ki wajah
  // se testing ke waqt real SMS ki zaroorat nahi hoti.
  //
  // =========================================================

  static const String testPhoneNumber =
      '+923414188770';

  // =========================================================
  // ORIGINAL REAL PHONE OTP CODE
  // =========================================================
  //
  // REAL PHONE OTP CODE KO ABHI COMMENTED RAKH RAHE HAIN.
  //
  // Billing enable hone ke baad isi flow ko wapas enable
  // kiya ja sakta hai.
  //
  // Future<void> _sendRealOtp() async {
  //   await _auth.verifyPhoneNumber(
  //     phoneNumber: fullPhoneNumber,
  //     verificationCompleted: (credential) async {
  //       await _auth.signInWithCredential(
  //         credential,
  //       );
  //     },
  //     verificationFailed: (e) {
  //       // Error
  //     },
  //     codeSent: (
  //       String verificationId,
  //       int? resendToken,
  //     ) {
  //       // Open OTP Screen
  //     },
  //     codeAutoRetrievalTimeout:
  //         (String verificationId) {},
  //   );
  // }
  //
  // =========================================================

  // =========================================================
  // COUNTRIES
  // =========================================================

  final List<Map<String, String>> countries = [
    {
      'name': 'Pakistan',
      'code': '+92',
      'flag': '🇵🇰',
    },
    {
      'name': 'United Arab Emirates',
      'code': '+971',
      'flag': '🇦🇪',
    },
    {
      'name': 'Saudi Arabia',
      'code': '+966',
      'flag': '🇸🇦',
    },
    {
      'name': 'United Kingdom',
      'code': '+44',
      'flag': '🇬🇧',
    },
    {
      'name': 'United States',
      'code': '+1',
      'flag': '🇺🇸',
    },
    {
      'name': 'Canada',
      'code': '+1',
      'flag': '🇨🇦',
    },
    {
      'name': 'Australia',
      'code': '+61',
      'flag': '🇦🇺',
    },
    {
      'name': 'Qatar',
      'code': '+974',
      'flag': '🇶🇦',
    },
    {
      'name': 'Kuwait',
      'code': '+965',
      'flag': '🇰🇼',
    },
    {
      'name': 'Oman',
      'code': '+968',
      'flag': '🇴🇲',
    },
  ];

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  // =========================================================
  // SEND TEST OTP
  // =========================================================

  Future<void> _sendTestOtp() async {
    String phoneNumber =
        phoneController.text.trim();

    // =======================================================
    // PHONE VALIDATION
    // =======================================================

    if (phoneNumber.isEmpty) {
      _showError(
        'Please enter your phone number.',
      );
      return;
    }

    // Remove spaces, dash and brackets
    phoneNumber =
        phoneNumber.replaceAll(
      RegExp(r'[\s\-\(\)]'),
      '',
    );

    // Remove starting 0
    if (phoneNumber.startsWith('0')) {
      phoneNumber =
          phoneNumber.substring(1);
    }

    if (phoneNumber.length < 7) {
      _showError(
        'Please enter a valid phone number.',
      );
      return;
    }

    // =======================================================
    // CREATE FULL PHONE NUMBER
    // =======================================================

    final String fullPhoneNumber =
        '$selectedCountryCode$phoneNumber';

    // =======================================================
    // TEST NUMBER CHECK
    // =======================================================

    if (fullPhoneNumber !=
        testPhoneNumber) {
      _showError(
        'For testing, please use +92 3414188770.',
      );
      return;
    }

    // =======================================================
    // LOADING
    // =======================================================

    setState(() {
      isLoading = true;
    });

    try {
      // =====================================================
      // FIREBASE TEST PHONE AUTH
      // =====================================================
      //
      // Firebase Console ke Phone Numbers for testing mein
      // add kiya hua number use ho raha hai.
      //
      // Firebase test number par real SMS send nahi hota.
      //
      // =====================================================

      await _auth.verifyPhoneNumber(
        phoneNumber:
            testPhoneNumber,

        // ===================================================
        // ANDROID AUTO VERIFICATION
        // ===================================================

        verificationCompleted:
            (PhoneAuthCredential
                credential) async {
          try {
            await _auth
                .signInWithCredential(
              credential,
            );
          } catch (e) {
            debugPrint(
              'Auto verification error: $e',
            );
          }
        },

        // ===================================================
        // VERIFICATION FAILED
        // ===================================================

        verificationFailed:
            (FirebaseAuthException e) {
          debugPrint(
            '================================',
          );

          debugPrint(
            'TEST PHONE AUTH ERROR',
          );

          debugPrint(
            'Code: ${e.code}',
          );

          debugPrint(
            'Message: ${e.message}',
          );

          debugPrint(
            '================================',
          );

          if (!mounted) {
            return;
          }

          setState(() {
            isLoading = false;
          });

          _showError(
            e.message ??
                'Phone verification failed.',
          );
        },

        // ===================================================
        // CODE SENT
        // ===================================================

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          if (!mounted) {
            return;
          }

          setState(() {
            isLoading = false;
          });

          // =================================================
          // OPEN OTP SCREEN
          // =================================================

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      OtpVerificationScreen(
                verificationId:
                    verificationId,

                phoneNumber:
                    testPhoneNumber,
              ),
            ),
          );
        },

        // ===================================================
        // AUTO RETRIEVAL TIMEOUT
        // ===================================================

        codeAutoRetrievalTimeout:
            (String verificationId) {
          debugPrint(
            'OTP auto retrieval timeout.',
          );

          debugPrint(
            'Verification ID: $verificationId',
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '================================',
      );

      debugPrint(
        'TEST OTP FIREBASE ERROR',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      debugPrint(
        '================================',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      _showError(
        e.message ??
            'Unable to send verification code.',
      );
    } catch (e) {
      debugPrint(
        'TEST OTP ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      _showError(
        'Something went wrong: $e',
      );
    }
  }

  // =========================================================
  // ERROR MESSAGE
  // =========================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor:
            Colors.red,
        content:
            Text(message),
      ),
    );
  }

  Future<void> _openExternalUrl(String value) async {
    final opened = await launchUrl(
      Uri.parse(value),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _showError('Unable to open this link right now.');
    }
  }

  Future<void> _continueWithTikTok() async {
    if (_tiktokLoginUrl.isEmpty) {
      _showError('TikTok login is not configured yet.');
      return;
    }
    await _openExternalUrl(_tiktokLoginUrl);
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body:
          SafeArea(
        child:
            Center(
          child:
              SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  24,
              vertical:
                  30,
            ),
            child:
                Column(
              children: [

                // =====================================================
                // SWAT RIDE LOGO
                // =====================================================

                Container(
                  width:
                      150,
                  height:
                      150,
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(
                          alpha:
                              0.35,
                        ),
                        blurRadius:
                            20,
                        offset:
                            const Offset(
                          0,
                          8,
                        ),
                      ),
                    ],
                  ),
                  child:
                      ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    child:
                        Image.asset(
                      'assets/images/swat_ride_logo.png',
                      fit:
                          BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      25,
                ),

                // =====================================================
                // TITLE
                // =====================================================

                const Text(
                  'Welcome to SWAT RIDE',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize:
                        28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height:
                      10,
                ),

                Text(
                  'Enter your phone number to continue',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade400,
                    fontSize:
                        15,
                  ),
                ),

                const SizedBox(
                  height:
                      35,
                ),

                // =====================================================
                // COUNTRY + PHONE NUMBER
                // =====================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    // =================================================
                    // COUNTRY CODE
                    // =================================================

                    SizedBox(
                      width:
                          125,
                      child:
                          DropdownButtonFormField<String>(
                        initialValue:
                            selectedCountryCode,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Country',
                          border:
                              OutlineInputBorder(),
                        ),
                        items:
                            countries.map(
                          (
                            country,
                          ) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  country['code'],
                              child:
                                  Text(
                                '${country['flag']} ${country['code']}',
                              ),
                            );
                          },
                        ).toList(),
                        onChanged:
                            isLoading
                                ? null
                                : (
                                    value,
                                  ) {
                                    if (value !=
                                        null) {
                                      setState(
                                        () {
                                          selectedCountryCode =
                                              value;
                                        },
                                      );
                                    }
                                  },
                      ),
                    ),

                    const SizedBox(
                      width:
                          12,
                    ),

                    // =================================================
                    // PHONE NUMBER
                    // =================================================

                    Expanded(
                      child:
                          TextFormField(
                        controller:
                            phoneController,
                        enabled:
                            !isLoading,
                        keyboardType:
                            TextInputType.phone,
                        decoration:
                            const InputDecoration(
                          labelText:
                              'Phone Number',
                          hintText:
                              '3414188770',
                          prefixIcon:
                              Icon(
                            Icons.phone,
                          ),
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                      25,
                ),

                // =====================================================
                // CONTINUE BUTTON
                // =====================================================

                SizedBox(
                  width:
                      double.infinity,
                  height:
                      55,
                  child:
                      ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : _sendTestOtp,
                    style:
                        ElevatedButton
                            .styleFrom(
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
                    child:
                        isLoading
                            ? const SizedBox(
                                width:
                                    24,
                                height:
                                    24,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      3,
                                  color:
                                      Colors.black,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style:
                                    TextStyle(
                                  fontSize:
                                      17,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                  ),
                ),

                const SizedBox(
                  height:
                      12,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height:
                      48,
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        isLoading
                            ? null
                            : _continueWithTikTok,
                    icon:
                        const Icon(
                      Icons.play_circle_fill,
                    ),
                    label:
                        const Text(
                      'Continue with TikTok',
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                      20,
                ),

                // =====================================================
                // TEST LOGIN NOTICE
                // =====================================================

                Text(
                  'Testing Mode: Use +92 3414188770 and OTP 414188.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade500,
                    fontSize:
                        12,
                  ),
                ),

                const SizedBox(
                  height:
                      8,
                ),

                Text(
                  'Real Phone OTP code is temporarily kept disabled until Firebase Billing is enabled.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize:
                        11,
                  ),
                ),

                const SizedBox(
                  height:
                      22,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip:
                          'Facebook',
                      onPressed:
                          () => _openExternalUrl(
                        _facebookUrl,
                      ),
                      icon:
                          const Icon(
                        Icons.facebook,
                      ),
                    ),
                    IconButton(
                      tooltip:
                          'Instagram',
                      onPressed:
                          () => _openExternalUrl(
                        _instagramUrl,
                      ),
                      icon:
                          const Icon(
                        Icons.camera_alt_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip:
                          'TikTok',
                      onPressed:
                          () => _openExternalUrl(
                        _tiktokUrl,
                      ),
                      icon:
                          const Icon(
                        Icons.play_circle_outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}