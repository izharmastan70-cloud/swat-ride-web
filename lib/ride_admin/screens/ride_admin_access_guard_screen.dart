import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ride_admin_access_service.dart';
import 'ride_admin_dashboard_screen.dart';

class RideAdminAccessGuardScreen extends StatefulWidget {
  const RideAdminAccessGuardScreen({super.key});

  @override
  State<RideAdminAccessGuardScreen> createState() =>
      _RideAdminAccessGuardScreenState();
}

class _RideAdminAccessGuardScreenState
    extends State<RideAdminAccessGuardScreen> {
  static const Color _yellow = Color(0xFFFFD400);
  static const Color _background = Color(0xFF090909);
  static const Color _card = Color(0xFF191919);

  final RideAdminAccessService _accessService = RideAdminAccessService();
  Future<RideAdminAccessResult>? _accessCheck;
  String? _checkedUserId;

  Future<RideAdminAccessResult> _checkFor(User user) {
    if (_accessCheck == null || _checkedUserId != user.uid) {
      _checkedUserId = user.uid;
      _accessCheck = _accessService.checkCurrentAccess();
    }
    return _accessCheck!;
  }

  void _retry({bool refreshToken = false}) {
    setState(() {
      final User? user = _accessService.currentUser;
      _checkedUserId = user?.uid;
      _accessCheck = _accessService.checkCurrentAccess(
        forceRefreshToken: refreshToken,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _accessService.authStateChanges(),
      initialData: _accessService.currentUser,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting &&
            authSnapshot.data == null) {
          return const _AdminCheckingScreen();
        }

        final User? user = authSnapshot.data;
        if (user == null) {
          _checkedUserId = null;
          _accessCheck = null;
          return _AdminAccessMessageScreen(
            icon: Icons.lock_outline_rounded,
            iconColor: _yellow,
            title: 'Admin sign-in required',
            message:
                'Please sign in with an authorized SWAT RIDE Admin account before opening this dashboard.',
            primaryLabel: 'Go to Login',
            onPrimaryPressed: () => _goToRoute('/login'),
            secondaryLabel: 'Back',
            onSecondaryPressed: _goBack,
          );
        }

        return FutureBuilder<RideAdminAccessResult>(
          future: _checkFor(user),
          builder: (context, accessSnapshot) {
            if (accessSnapshot.connectionState != ConnectionState.done) {
              return const _AdminCheckingScreen();
            }

            if (accessSnapshot.hasError) {
              return _AdminAccessMessageScreen(
                icon: Icons.cloud_off_rounded,
                iconColor: Colors.redAccent,
                title: 'Admin verification failed',
                message: _cleanError(accessSnapshot.error),
                primaryLabel: 'Try Again',
                onPrimaryPressed: () => _retry(refreshToken: true),
                secondaryLabel: 'Back',
                onSecondaryPressed: _goBack,
              );
            }

            final RideAdminAccessResult result =
                accessSnapshot.data ??
                    const RideAdminAccessResult.error(
                      reason: 'No Admin verification result was returned.',
                    );

            if (result.isAllowed) {
              return _AuthorizedAdminShell(result: result);
            }

            return _AdminAccessMessageScreen(
              icon: result.hasError
                  ? Icons.warning_amber_rounded
                  : Icons.gpp_bad_outlined,
              iconColor:
                  result.hasError ? Colors.orangeAccent : Colors.redAccent,
              title: result.hasError
                  ? 'Unable to verify Admin access'
                  : 'Access denied',
              message: result.reason,
              accountText: user.phoneNumber ?? user.email ?? user.uid,
              primaryLabel: 'Check Again',
              onPrimaryPressed: () => _retry(refreshToken: true),
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
          content: Text(_cleanError(error)),
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
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  static String _cleanError(Object? error) =>
      error.toString().replaceFirst('Exception: ', '').trim();
}

class _AuthorizedAdminShell extends StatelessWidget {
  const _AuthorizedAdminShell({required this.result});

  final RideAdminAccessResult result;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        RideAdminDashboardScreen(
          adminId: result.adminId,
          adminName: result.adminName,
        ),
        if (result.isTestingBypass)
          SafeArea(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 58),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD400),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.science_outlined, color: Colors.black, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ADMIN TESTING BYPASS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.none,
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

class _AdminCheckingScreen extends StatelessWidget {
  const _AdminCheckingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF090909),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD400),
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 22),
                Text(
                  'Verifying Admin access...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Checking your secure SWAT RIDE Admin role.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAccessMessageScreen extends StatelessWidget {
  const _AdminAccessMessageScreen({
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

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback onSecondaryPressed;
  final String? accountText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RideAdminAccessGuardScreenState._background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _RideAdminAccessGuardScreenState._card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 38),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.45),
                  ),
                  if ((accountText ?? '').trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.045),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Signed in as: $accountText',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: onPrimaryPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _RideAdminAccessGuardScreenState._yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      child: Text(primaryLabel),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onSecondaryPressed,
                    child: Text(secondaryLabel),
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
