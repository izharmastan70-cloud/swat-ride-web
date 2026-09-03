/// SWAT RIDE Help Video low-bandwidth playback policy.
class HelpVideoPlaybackPolicy {
  const HelpVideoPlaybackPolicy({this.lowBandwidthMode = true});

  final bool lowBandwidthMode;

  bool get manualPlayOnly => true;
  bool get autoplayAllowed => false;
  bool get automaticVideoPrefetchAllowed => false;
  bool get preferLowerQuality => lowBandwidthMode;
  bool get preferCaptions => true;
  bool get textFallbackRequired => true;
  bool get bundleTutorialVideosInApk => false;

  String get userHint => lowBandwidthMode
      ? 'Low-bandwidth mode: videos open only when you tap. '
            'Lower quality should be preferred when supported.'
      : 'Videos open only when you tap. Autoplay remains disabled.';

  String textFallback({required String title, required String description}) {
    if (description.trim().isNotEmpty) {
      return description.trim();
    }

    if (title.trim().isNotEmpty) {
      return 'Video guide "" is temporarily unavailable. '
          'Please use Help & Support text guidance.';
    }

    return 'Video guide is temporarily unavailable. '
        'Please use Help & Support text guidance.';
  }
}
