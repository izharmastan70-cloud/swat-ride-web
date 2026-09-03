import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/help_video_tutorial_model.dart';
import '../services/help_video_private_training_service.dart';

class PrivateVideoTrainingScreen extends StatefulWidget {
  PrivateVideoTrainingScreen({
    super.key,
    HelpVideoPrivateTrainingService? service,
  }) : service = service ?? HelpVideoPrivateTrainingService();

  final HelpVideoPrivateTrainingService service;

  @override
  State<PrivateVideoTrainingScreen> createState() =>
      _PrivateVideoTrainingScreenState();
}

class _PrivateVideoTrainingScreenState
    extends State<PrivateVideoTrainingScreen> {
  late Future<List<HelpVideoTutorialModel>> _future;

  @override
  void initState() {
    super.initState();

    _future = widget.service.loadMyPrivateTutorials();
  }

  Future<void> _refresh() async {
    final future = widget.service.loadMyPrivateTutorials();

    setState(() {
      _future = future;
    });

    await future;
  }

  String _audienceLabel(String value) {
    switch (value.trim().toLowerCase()) {
      case 'driver':
        return 'Driver';

      case 'food_rider':
        return 'Food Rider';

      case 'restaurant_partner':
        return 'Restaurant Partner';

      case 'hotel_partner':
        return 'Hotel Partner';

      case 'tourism_driver':
        return 'Tourism Driver';

      case 'tour_guide':
        return 'Tour Guide';

      case 'admin':
        return 'Admin';

      case 'super_admin':
        return 'Super Admin';

      default:
        return value;
    }
  }

  Future<void> _open(HelpVideoTutorialModel tutorial) async {
    final uri = Uri.tryParse(tutorial.videoUrl.trim());

    if (uri == null || uri.scheme.toLowerCase() != 'https') {
      _message('Invalid private training video link.');
      return;
    }

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened && mounted) {
        _message('Private training video could not be opened.');
      }
    } on Object {
      if (mounted) {
        _message('Private training video could not be opened.');
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Private Role Training')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HelpVideoTutorialModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  const SizedBox(height: 120),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Private training could not be loaded.\n\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final tutorials = snapshot.data!;

            if (tutorials.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(height: 120),
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: <Widget>[
                        Icon(Icons.lock_outline, size: 46),
                        SizedBox(height: 12),
                        Text(
                          'No private training access is currently assigned '
                          'to this account.',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Private Driver, Partner and Admin training '
                          'requires authorized access.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: tutorials.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tutorial = tutorials[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(tutorial.title),
                    subtitle: Text(
                      '${_audienceLabel(tutorial.audience)}'
                      '${tutorial.description.trim().isEmpty ? '' : '\n${tutorial.description.trim()}'}',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _open(tutorial),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
