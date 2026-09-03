import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/help_video_tutorial_model.dart';
import '../services/contextual_video_guide_service.dart';

class ContextualVideoGuideButton extends StatelessWidget {
  ContextualVideoGuideButton({
    super.key,
    required this.module,
    required this.feature,
    this.intents = const <String>[],
    this.label = 'Need Help? Watch Guide',
    ContextualVideoGuideService? service,
  }) : _service = service ?? ContextualVideoGuideService();

  final String module;
  final String feature;
  final List<String> intents;
  final String label;

  final ContextualVideoGuideService _service;

  Future<void> _openGuide(
    BuildContext context,
    HelpVideoTutorialModel tutorial,
  ) async {
    if (!_service.isSafeVideoUrl(tutorial.videoUrl)) {
      _showMessage(context, 'This video guide link is not valid.');
      return;
    }

    final Uri? uri = Uri.tryParse(tutorial.videoUrl.trim());

    if (uri == null) {
      _showMessage(context, 'This video guide link is not valid.');
      return;
    }

    try {
      final bool opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        _showMessage(context, 'The video guide could not be opened.');
      }
    } on Object {
      if (context.mounted) {
        _showMessage(context, 'The video guide could not be opened.');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HelpVideoTutorialModel?>(
      stream: _service.watchBestGuide(
        module: module,
        feature: feature,
        intents: intents,
      ),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<HelpVideoTutorialModel?> snapshot,
          ) {
            final HelpVideoTutorialModel? tutorial = snapshot.data;

            if (snapshot.hasError || tutorial == null) {
              return const SizedBox.shrink();
            }

            return OutlinedButton.icon(
              onPressed: () {
                _openGuide(context, tutorial);
              },
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: Text(label),
            );
          },
    );
  }
}
