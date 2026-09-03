import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/super_admin_access_result.dart';
import '../services/super_admin_access_service.dart';
import 'super_admin_dashboard_screen.dart';

// =========================================================
// SWAT RIDE — SUPER ADMIN ACCESS GUARD
// =========================================================
//
// Strict global Super Admin gate.
//
// Allowed:
//   role == super_admin
//
// Denied:
//   normal admin
//   hotel owner/admin
//   food admin
//   ride admin
//   tourism admin
//   unauthenticated user
//
// Existing module admin access remains separate.

class SuperAdminAccessGuardScreen extends StatefulWidget {
  const SuperAdminAccessGuardScreen({super.key});

  @override
  State<SuperAdminAccessGuardScreen> createState() =>
      _SuperAdminAccessGuardScreenState();
}

class _SuperAdminAccessGuardScreenState
    extends State<SuperAdminAccessGuardScreen> {
  static const Color _yellow = Color(0xFFFFD400);
  static const Color _background = Color(0xFF090909);
  static const Color _card = Color(0xFF191919);

  final SuperAdminAccessService _accessService =
      SuperAdminAccessService();

  Future<SuperAdminAccessResult>? _accessCheck;
  String? _checkedUserId;

  Future<SuperAdminAccessResult> _checkFor(User user) {
    if (_accessCheck == null || _checkedUserId != user.uid) {
      _checkedUserId = user.uid;

      _accessCheck =
          _accessService.checkCurrentAccess();
    }

    return _accessCheck!;
  }

  void _retry({
    bool refreshToken = false,
  }) {
    setState(() {
      final User? user = _accessService.currentUser;

      _checkedUserId = user?.uid;

      _accessCheck =
          _accessService.checkCurrentAccess(
        forceRefreshToken: refreshToken,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _accessService.authStateChanges(),
      initialData: _accessService.currentUser,
      builder: (
        BuildContext context,
        AsyncSnapshot<User?> authSnapshot,
      ) {
        if (authSnapshot.connectionState ==
                ConnectionState.waiting &&
            authSnapshot.data == null) {
          return const _SuperAdminCheckingScreen();
        }

        final User? user = authSnapshot.data;

        if (user == null) {
          _checkedUserId = null;
          _accessCheck = null;

          return _SuperAdminMessageScreen(
            icon: Icons.lock_outline_rounded,
            iconColor: _yellow,
            title: 'Super Admin sign-in required',
            message:
                'Please sign in with an authorized SWAT RIDE Super Admin account.',
            primaryLabel: 'Go to Login',
            onPrimaryPressed: () =>
                _goToRoute('/login'),
            secondaryLabel: 'Back',
            onSecondaryPressed: _goBack,
          );
        }

        return FutureBuilder<SuperAdminAccessResult>(
          future: _checkFor(user),
          builder: (
            BuildContext context,
            AsyncSnapshot<SuperAdminAccessResult>
                accessSnapshot,
          ) {
            if (accessSnapshot.connectionState !=
                ConnectionState.done) {
              return const _SuperAdminCheckingScreen();
            }

            if (accessSnapshot.hasError) {
              return _SuperAdminMessageScreen(
                icon: Icons.cloud_off_rounded,
                iconColor: Colors.redAccent,
                title: 'Super Admin verification failed',
                message:
                    _cleanError(accessSnapshot.error),
                primaryLabel: 'Try Again',
                onPrimaryPressed: () =>
                    _retry(refreshToken: true),
                secondaryLabel: 'Back',
                onSecondaryPressed: _goBack,
              );
            }

            final SuperAdminAccessResult result =
                accessSnapshot.data ??
                    const SuperAdminAccessResult.error(
                      reason:
                          'No Super Admin verification result was returned.',
                    );

            if (result.isAllowed &&
                result.isSuperAdmin) {
              return _AuthorizedSuperAdminShell(
                result: result,
              );
            }

            return _SuperAdminMessageScreen(
              icon: result.hasError
                  ? Icons.warning_amber_rounded
                  : Icons.gpp_bad_outlined,
              iconColor: result.hasError
                  ? Colors.orangeAccent
                  : Colors.redAccent,
              title: result.hasError
                  ? 'Unable to verify Super Admin access'
                  : 'Super Admin access denied',
              message: result.reason,
              accountText:
                  user.phoneNumber ??
                  user.email ??
                  user.uid,
              primaryLabel: 'Check Again',
              onPrimaryPressed: () =>
                  _retry(refreshToken: true),
              secondaryLabel: 'Sign Out',
              onSecondaryPressed: _signOut,
            );
          },
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await _accessService.signOut();

      if (!mounted) return;

      _goToRoute('/login');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            _cleanError(error),
          ),
        ),
      );
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    _goToRoute('/home');
  }

  void _goToRoute(String route) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil(
      route,
      (_) => false,
    );
  }

  static String _cleanError(Object? error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }
}

// =========================================================
// AUTHORIZED SUPER ADMIN SHELL
// =========================================================

class _AuthorizedSuperAdminShell
    extends StatelessWidget {
  final SuperAdminAccessResult result;

  const _AuthorizedSuperAdminShell({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SuperAdminDashboardScreen(
          adminId: result.adminId,
          adminName: result.adminName,
        ),
        if (result.isTestingBypass)
          SafeArea(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin:
                      const EdgeInsets.only(top: 58),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _SuperAdminAccessGuardScreenState._yellow,
                    borderRadius:
                        BorderRadius.circular(30),
                    boxShadow:
                        const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.science_outlined,
                        color: Colors.black,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SUPER ADMIN TESTING BYPASS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                          decoration:
                              TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =========================================================
// CHECKING SCREEN
// =========================================================

class _SuperAdminCheckingScreen
    extends StatelessWidget {
  const _SuperAdminCheckingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _SuperAdminAccessGuardScreenState._background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 48,
                  height: 48,
                  child:
                      CircularProgressIndicator(
                    color: _SuperAdminAccessGuardScreenState._yellow,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 22),
                Text(
                  'Verifying Super Admin access...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Checking your SWAT RIDE global Super Admin role.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// MESSAGE SCREEN
// =========================================================

class _SuperAdminMessageScreen
    extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback onSecondaryPressed;
  final String? accountText;

  const _SuperAdminMessageScreen({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.secondaryLabel,
    required this.onSecondaryPressed,
    this.accountText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SuperAdminAccessGuardScreenState._background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints:
                  const BoxConstraints(
                maxWidth: 460,
              ),
              padding:
                  const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _SuperAdminAccessGuardScreenState._card,
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white10,
                ),
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 76,
                    height: 76,
                    decoration:
                        BoxDecoration(
                      color:
                          iconColor.withValues(
                        alpha: 0.12,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                  if ((accountText ?? '')
                      .trim()
                      .isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(
                        12,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withValues(
                          alpha: 0.045,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Text(
                        'Signed in as: $accountText',
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child:
                        FilledButton(
                      onPressed:
                          onPrimaryPressed,
                      style:
                          FilledButton.styleFrom(
                        backgroundColor:
                            _SuperAdminAccessGuardScreenState._yellow,
                        foregroundColor:
                            Colors.black,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                        textStyle:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      child:
                          Text(primaryLabel),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed:
                        onSecondaryPressed,
                    child:
                        Text(secondaryLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

