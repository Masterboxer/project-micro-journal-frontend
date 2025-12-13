import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _postController = TextEditingController();
  String? _todayPostText;
  String? _todayPhotoPath;
  bool _hasPostedToday = false;
  String? _selectedTemplate;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _openTemplateSelector() async {
    final template = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Choose a micro-template',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 0),
              ListTile(
                title: const Text('What went well today?'),
                onTap: () => Navigator.of(context).pop('What went well today?'),
              ),
              ListTile(
                title: const Text('One thing to improve tomorrow:'),
                onTap: () =>
                    Navigator.of(context).pop('One thing to improve tomorrow:'),
              ),
              ListTile(
                title: const Text('Grateful for:'),
                onTap: () => Navigator.of(context).pop('Grateful for:'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (template != null) {
      setState(() {
        _selectedTemplate = template;
        // If the field is empty, prefill with the template
        if (_postController.text.trim().isEmpty) {
          _postController.text = template + ' ';
          _postController.selection = TextSelection.fromPosition(
            TextPosition(offset: _postController.text.length),
          );
        }
      });
    }
  }

  Future<void> _pickPhoto() async {
    // TODO: integrate image picker
    // For now, just mock a value
    setState(() {
      _todayPhotoPath = 'mock_photo_path.jpg';
    });
  }

  void _submitPost() {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    // TODO: send to backend / local DB
    setState(() {
      _todayPostText = text;
      _hasPostedToday = true;
    });
  }

  void _viewFriendsFeed() {
    // TODO: navigate to Friends Feed page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Friends Feed coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Today'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _hasPostedToday
            ? _buildPostedView(theme)
            : _buildComposeView(theme),
      ),
    );
  }

  Widget _buildComposeView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's micro-post", style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Up to 280 characters.', style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        TextField(
          controller: _postController,
          maxLength: 280,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Capture today in a sentence or two…',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Add photo (optional)'),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _openTemplateSelector,
              icon: const Icon(Icons.article_outlined),
              label: const Text('Templates'),
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitPost,
            child: const Text('Submit today’s post'),
          ),
        ),
      ],
    );
  }

  Widget _buildPostedView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's post", style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          "You cannot edit after posting.",
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_todayPostText != null) ...[
                  Text(_todayPostText!, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 8),
                ],
                if (_todayPhotoPath != null)
                  Row(
                    children: [
                      const Icon(Icons.photo, size: 18),
                      const SizedBox(width: 4),
                      Text('Photo attached', style: theme.textTheme.bodySmall),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _viewFriendsFeed,
            child: const Text('View Friends Feed'),
          ),
        ),
      ],
    );
  }
}
