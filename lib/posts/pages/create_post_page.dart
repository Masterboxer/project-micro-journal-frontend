import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_micro_journal/authentication/services/authentication_token_storage_service.dart';
import 'package:project_micro_journal/environment/development.dart';
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
  final ScrollController _scrollController = ScrollController();
  final AuthenticationTokenStorageService _authStorage =
      AuthenticationTokenStorageService();

  String? _todayPhotoPath;
  PostTemplate? _selectedTemplate;
  bool _isLoadingTemplates = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _postController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      await _templateService.fetchTemplatesFromBackend();
      if (mounted) {
        setState(() => _isLoadingTemplates = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTemplates = false;
          _error = 'Failed to load templates: $e';
        });
      }
    }
  }

  Future<void> _pickPhoto() async {
    // TODO: Add image_picker package and implement
    setState(() {
      _todayPhotoPath = 'mock_photo_path.jpg';
    });
  }

  Future<void> _submitPost() async {
    final text = _postController.text.trim();

    if (_selectedTemplate == null) {
      _showSnackBar('Please select a template first', Colors.red);
      return;
    }

    if (text.isEmpty) {
      _showSnackBar('Please write something for today', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userId = await _authStorage.getUserId();

      if (userId == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      final postData = {
        'user_id': int.parse(userId),
        'template_id': _selectedTemplate!.id,
        'text': text,
        'photoPath': _todayPhotoPath ?? '',
      };

      final response = await http.post(
        Uri.parse('${Environment.baseUrl}posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(postData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final resultData = {
          'id': responseData['id'],
          'template_id': _selectedTemplate!.id,
          'text': text,
          'photoPath': _todayPhotoPath,
          'timestamp': DateTime.now(),
          'should_reload_streak': true,
        };

        if (mounted) {
          Navigator.pop(context, resultData);
        }
      } else {
        String errorMessage = 'Failed to create post';

        try {
          final errorBody = json.decode(response.body);

          if (errorBody is Map) {
            errorMessage =
                errorBody['message'] ??
                errorBody['error'] ??
                errorBody['detail'] ??
                'Server error: ${response.statusCode}';
          } else if (errorBody is String) {
            errorMessage = errorBody;
          }
        } catch (e) {
          if (response.body.isNotEmpty) {
            errorMessage = response.body;
          } else {
            errorMessage = 'Server error: ${response.statusCode}';
          }
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      String displayMessage;

      if (e.toString().contains('Exception:')) {
        displayMessage = e.toString().replaceFirst('Exception: ', '');
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        displayMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('TimeoutException')) {
        displayMessage = 'Request timeout. Please try again.';
      } else {
        displayMessage = e.toString();
      }

      _showSnackBar(displayMessage, Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, Color? backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = _templateService.getAllTemplates();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post'), centerTitle: false),
      body:
          _isLoadingTemplates
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorView(theme)
              : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: _buildComposeView(theme, templates),
              ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load templates',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadTemplates, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildComposeView(ThemeData theme, List<PostTemplate> templates) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's Micro Journal", style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Up to 280 characters.', style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),

          Text(
            'Choose a template *',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          if (templates.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.temple_hindu_sharp,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No templates available',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    constraints.maxWidth > 600
                        ? 3
                        : constraints.maxWidth > 400
                        ? 2
                        : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    final isSelected = _selectedTemplate?.id == template.id;

                    return _buildTemplateCard(theme, template, isSelected);
                  },
                );
              },
            ),

            const SizedBox(height: 8),
            Text(
              'Tap to select a template',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: 24),

          if (_selectedTemplate != null) ...[
            _buildSelectedTemplateIndicator(theme),
            const SizedBox(height: 20),
          ],

          _buildTextInputSection(theme),
          _buildPhotoSection(theme),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    ThemeData theme,
    PostTemplate template,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: _isSubmitting ? null : () => _selectTemplate(template),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.primaryContainer.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: isSelected ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  template.iconData,
                  size: 28,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    template.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTemplateIndicator(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.primaryContainer.withOpacity(0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _selectedTemplate!.iconData,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedTemplate!.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (_selectedTemplate!.description.isNotEmpty)
                  Text(
                    _selectedTemplate!.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.edit,
            color: theme.colorScheme.primary.withOpacity(0.6),
            size: 20,
          ),
        ],
      ),
    );
  }

  void _selectTemplate(PostTemplate template) {
    setState(() {
      final wasSelected = _selectedTemplate?.id == template.id;
      _selectedTemplate = wasSelected ? null : template;
      if (wasSelected) {
        _postController.clear();
      }
    });

    if (_selectedTemplate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Widget _buildTextInputSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _postController,
          maxLength: 280,
          maxLines: 5,
          enabled: !_isSubmitting && _selectedTemplate != null,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            hintText:
                _selectedTemplate != null
                    ? 'Continue writing your reflection...'
                    : 'Select a template first to start writing',
            counterText: null,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${_postController.text.length}/280',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    _postController.text.length > 260
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed:
              (!_isSubmitting && _selectedTemplate != null) ? _pickPhoto : null,
          icon: Icon(
            _todayPhotoPath != null ? Icons.check_circle : Icons.photo_outlined,
          ),
          label: Text(
            _todayPhotoPath != null ? 'Photo added ✓' : 'Add photo (optional)',
            style: TextStyle(
              color:
                  _selectedTemplate != null && !_isSubmitting
                      ? null
                      : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPost,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSubmitting
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 20),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Submit today\'s post (${_postController.text.length}/280)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
