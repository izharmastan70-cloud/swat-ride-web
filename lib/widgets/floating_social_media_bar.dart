import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FloatingSocialMediaShell extends StatelessWidget {
  const FloatingSocialMediaShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: compact ? 0 : 76,
                bottom: compact ? 76 : 0,
              ),
              child: child,
            ),
            SafeArea(
              child: Align(
                alignment: compact
                    ? Alignment.bottomCenter
                    : Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.all(compact ? 12 : 12),
                  child: _SocialMediaBar(compact: compact),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SocialMediaBar extends StatelessWidget {
  const _SocialMediaBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final links = [
      _SocialLink('Facebook', 'https://www.facebook.com/SwatRide', Icons.facebook),
      _SocialLink('Instagram', 'https://www.instagram.com/swatride', Icons.camera_alt_outlined),
      _SocialLink('TikTok', 'https://www.tiktok.com/@swatride', Icons.play_circle_outline),
    ];
    return Material(
      color: const Color(0xFF171717),
      elevation: 12,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(8),
      child: Flex(
        direction: compact ? Axis.horizontal : Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        children: links,
      ),
    );
  }
}

class _SocialLink extends StatefulWidget {
  const _SocialLink(this.label, this.url, this.icon);

  final String label;
  final String url;
  final IconData icon;

  @override
  State<_SocialLink> createState() => _SocialLinkState();
}

class _SocialLinkState extends State<_SocialLink> {
  bool _hovered = false;

  Future<void> _openLink() async {
    await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 52,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFFD60A) : const Color(0xFF252525),
          boxShadow: _hovered
              ? const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4))]
              : null,
        ),
        child: IconButton(
          tooltip: widget.label,
          onPressed: _openLink,
          icon: Icon(widget.icon, color: _hovered ? Colors.black : Colors.white),
        ),
      ),
    );
  }
}