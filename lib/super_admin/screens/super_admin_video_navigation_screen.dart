import 'package:flutter/material.dart';

import '../services/super_admin_video_navigation_service.dart';

class SuperAdminVideoNavigationScreen extends StatefulWidget {
  const SuperAdminVideoNavigationScreen({super.key, required this.adminId});

  final String adminId;

  @override
  State<SuperAdminVideoNavigationScreen> createState() =>
      _SuperAdminVideoNavigationScreenState();
}

class _SuperAdminVideoNavigationScreenState
    extends State<SuperAdminVideoNavigationScreen> {
  final SuperAdminVideoNavigationService _service =
      SuperAdminVideoNavigationService();

  final TextEditingController _tutorialIdController = TextEditingController();

  final TextEditingController _deepLinkController = TextEditingController();

  final TextEditingController _chaptersController = TextEditingController();

  bool _isEnabled = true;
  bool _busy = false;

  @override
  void dispose() {
    _tutorialIdController.dispose();
    _deepLinkController.dispose();
    _chaptersController.dispose();

    super.dispose();
  }

  Future<void> _load() async {
    final id = _tutorialIdController.text.trim();

    if (id.isEmpty) {
      _message('Enter tutorial ID.');
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final metadata = await _service.loadMetadata(id);

      if (!mounted) {
        return;
      }

      if (metadata == null) {
        _deepLinkController.clear();
        _chaptersController.clear();

        setState(() {
          _isEnabled = true;
        });

        _message('No navigation metadata exists for this tutorial yet.');

        return;
      }

      _deepLinkController.text = metadata.deepLinkPath;

      _chaptersController.text = _service.serializeChapterLines(
        metadata.chapters,
      );

      setState(() {
        _isEnabled = metadata.isEnabled;
      });

      _message('Tutorial navigation metadata loaded.');
    } catch (error) {
      if (mounted) {
        _message('Could not load metadata: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final id = _tutorialIdController.text.trim();

    if (id.isEmpty) {
      _message('Enter tutorial ID.');
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final chapters = _service.parseChapterLines(_chaptersController.text);

      await _service.saveMetadata(
        tutorialId: id,
        deepLinkPath: _deepLinkController.text,
        chapters: chapters,
        isEnabled: _isEnabled,
        adminId: widget.adminId,
      );

      if (mounted) {
        _message('Deep links, chapters and timestamps saved.');
      }
    } catch (error) {
      if (mounted) {
        _message('Could not save navigation metadata: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
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
      appBar: AppBar(title: const Text('Tutorial Chapters & Deep Links')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const Text(
            '37M navigation metadata',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'This metadata is separate from the production video URL. '
            'Unknown internal routes are never auto-executed.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tutorialIdController,
            decoration: const InputDecoration(
              labelText: 'Tutorial ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.search),
            label: const Text('Load navigation metadata'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _deepLinkController,
            decoration: const InputDecoration(
              labelText: 'Tutorial internal deep link',
              hintText: '/ride/booking',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chapter format',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const SelectableText(
            'startSeconds|endSeconds|Title|/optional/path\n'
            '0|35|Introduction|\n'
            '35|90|Choose pickup location|/ride/location',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chaptersController,
            minLines: 8,
            maxLines: 18,
            decoration: const InputDecoration(
              labelText: 'Chapter markers',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Navigation metadata enabled'),
            subtitle: const Text(
              'Turning this off hides chapters/deep links '
              'without deleting history.',
            ),
            value: _isEnabled,
            onChanged: _busy
                ? null
                : (value) {
                    setState(() {
                      _isEnabled = value;
                    });
                  },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_busy ? 'Saving...' : 'Save chapters & deep links'),
          ),
        ],
      ),
    );
  }
}
