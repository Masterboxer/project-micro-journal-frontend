import 'package:flutter/material.dart';
import 'package:project_micro_journal/templates/template_model.dart';
import 'package:project_micro_journal/templates/template_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _postController = TextEditingController();
  final TemplateService _templateService = TemplateService.instance;

  String? _todayPhotoPath;
  PostTemplate? _selectedTemplate;

  late List<PostTemplate> _templates;

  @override
  void initState() {
    super.initState();
    _templates = _templateService.getAllTemplates();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    // TODO: integrate image picker
    setState(() {
      _todayPhotoPath = 'mock_photo_path.jpg';
    });
  }

  void _submitPost() {
    final text = _postController.text.trim();

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

    // Create post data object with template ID
    final postData = {
      'templateId': _selectedTemplate!.id,
      'template': _selectedTemplate!.name,
      'text': text,
      'photoPath': _todayPhotoPath,
      'timestamp': DateTime.now(),
    };

    // TODO: Send to backend / local DB before popping
    Navigator.pop(context, postData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildComposeView(theme),
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
                  final isSelected = _selectedTemplate?.id == template.id;
                  return ChoiceChip(
                    label: Text(template.name),
                    selected: isSelected,
                    avatar: isSelected ? null : Icon(template.icon, size: 18),
                    onSelected: (selected) {
                      setState(() {
                        _selectedTemplate = selected ? template : null;
                        if (selected) {
                          _postController.text = '${template.name} ';
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
                    _selectedTemplate!.icon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Template: ${_selectedTemplate!.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_selectedTemplate!.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _selectedTemplate!.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
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
}
