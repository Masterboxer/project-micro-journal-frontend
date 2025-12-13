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

  final List<String> _templates = [
    'What went well today?',
    'One thing to improve tomorrow:',
    'Grateful for:',
  ];

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
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

    // Validate template selection
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a template first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something for today'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
      appBar: AppBar(title: const Text('My Micro Journal'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _hasPostedToday
                ? _buildPostedView(theme)
                : _buildComposeView(theme),
      ),
    );
  }

  Widget _buildComposeView(ThemeData theme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's micro-post", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Up to 280 characters.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),

          // Template Selection Section
          Text(
            'Choose a template *',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _templates.map((template) {
                  final isSelected = _selectedTemplate == template;
                  return ChoiceChip(
                    label: Text(template),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTemplate = selected ? template : null;
                        // Clear or update text field based on selection
                        if (selected) {
                          _postController.text = '$template ';
                          _postController
                              .selection = TextSelection.fromPosition(
                            TextPosition(offset: _postController.text.length),
                          );
                        }
                      });
                    },
                    selectedColor: theme.colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    showCheckmark: true,
                  );
                }).toList(),
          ),

          const SizedBox(height: 20),

          // Selected Template Indicator
          if (_selectedTemplate != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Template: $_selectedTemplate',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Text Input Field
          TextField(
            controller: _postController,
            maxLength: 280,
            maxLines: 5,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText:
                  _selectedTemplate != null
                      ? 'Continue writing...'
                      : 'Select a template first',
              enabled: _selectedTemplate != null,
            ),
          ),

          const SizedBox(height: 8),

          // Photo Button
          TextButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo_outlined),
            label: Text(
              _todayPhotoPath != null
                  ? 'Photo added ✓'
                  : 'Add photo (optional)',
            ),
          ),

          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitPost,
              child: const Text("Submit today's post"),
            ),
          ),
        ],
      ),
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
                // Show selected template
                if (_selectedTemplate != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _selectedTemplate!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
