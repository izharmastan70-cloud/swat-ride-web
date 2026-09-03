import 'package:flutter/material.dart';

import '../models/help_video_navigation_metadata.dart';
import '../models/help_video_tutorial_model.dart';
import '../services/help_video_navigation_service.dart';
import '../services/help_video_tutorial_service.dart';

class VideoGuideNavigationScreen extends StatelessWidget {
  VideoGuideNavigationScreen({
    super.key,
    HelpVideoTutorialService? tutorialService,
    HelpVideoNavigationService? navigationService,
  }) : tutorialService = tutorialService ?? HelpVideoTutorialService(),
       navigationService = navigationService ?? HelpVideoNavigationService();

  final HelpVideoTutorialService tutorialService;
  final HelpVideoNavigationService navigationService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide Chapters & Timestamps')),
      body: StreamBuilder<List<HelpVideoTutorialModel>>(
        stream: tutorialService.watchEnabledTutorials(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Guide navigation is unavailable right now.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tutorials = snapshot.data!;

          if (tutorials.isEmpty) {
            return const Center(
              child: Text('No approved Video Guides are available.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tutorials.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tutorial = tutorials[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: Text(tutorial.title),
                  subtitle: Text(
                    tutorial.module.trim().isEmpty
                        ? 'View chapters and timestamps'
                        : '${tutorial.module} • '
                              'View chapters and timestamps',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => VideoGuideNavigationDetailsScreen(
                          tutorial: tutorial,
                          navigationService: navigationService,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VideoGuideNavigationDetailsScreen extends StatelessWidget {
  const VideoGuideNavigationDetailsScreen({
    super.key,
    required this.tutorial,
    required this.navigationService,
  });

  final HelpVideoTutorialModel tutorial;
  final HelpVideoNavigationService navigationService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tutorial.title)),
      body: FutureBuilder<HelpVideoNavigationMetadata?>(
        future: navigationService.getMetadata(tutorialId: tutorial.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Chapter information could not be loaded.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final metadata = snapshot.data;

          if (metadata == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No chapter or deep-link metadata '
                  'has been published for this guide yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              if (metadata.deepLinkPath.isNotEmpty) ...<Widget>[
                const Text(
                  'Related app section',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SelectableText(metadata.deepLinkPath),
                const SizedBox(height: 6),
                const Text(
                  'Only approved internal app paths are stored here. '
                  'Unknown routes are not executed automatically.',
                ),
                const SizedBox(height: 18),
              ],
              Text(
                'Chapters (${metadata.chapters.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              if (metadata.chapters.isEmpty)
                const Text('No chapter timestamps are available yet.')
              else
                ...metadata.chapters.map(
                  (chapter) => _ChapterTile(chapter: chapter),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.chapter});

  final HelpVideoChapterMarker chapter;

  @override
  Widget build(BuildContext context) {
    final start = HelpVideoNavigationService.timestampLabel(
      chapter.startSeconds,
    );

    final end = chapter.endSeconds > 0
        ? HelpVideoNavigationService.timestampLabel(chapter.endSeconds)
        : '';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.bookmark_outline),
        title: Text(chapter.title),
        subtitle: Text(end.isEmpty ? start : '$start – $end'),
        trailing: chapter.deepLinkPath.isEmpty
            ? null
            : Tooltip(
                message: chapter.deepLinkPath,
                child: const Icon(Icons.link),
              ),
      ),
    );
  }
}
