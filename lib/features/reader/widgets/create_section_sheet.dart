import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';

class CreateSectionSheet extends StatefulWidget {
  final String selectedText;
  final VoidCallback onCancel;
  final Future<void> Function({
    required String title,
    required List<String> tags,
    required int difficulty,
  }) onSave;

  const CreateSectionSheet({
    super.key,
    required this.selectedText,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<CreateSectionSheet> createState() => _CreateSectionSheetState();
}

class _CreateSectionSheetState extends State<CreateSectionSheet> {
  late TextEditingController _titleController;
  late TextEditingController _tagsController;
  int _difficulty = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    // Generate default title from first line of selected text
    String defaultTitle = _generateDefaultTitle(widget.selectedText);
    _titleController = TextEditingController(text: defaultTitle);
    _tagsController = TextEditingController();
  }

  String _generateDefaultTitle(String text) {
    if (text.isEmpty) return 'New Section';
    
    // Get first line
    final firstLine = text.split('\n').first.trim();
    
    // Limit to 60 characters
    if (firstLine.length > 60) {
      return '${firstLine.substring(0, 57)}...';
    }
    
    return firstLine.isEmpty ? 'New Section' : firstLine;
  }

  String _getPreviewSnippet() {
    if (widget.selectedText.length <= 200) {
      return widget.selectedText;
    }
    return '${widget.selectedText.substring(0, 197)}...';
  }

  List<String> _parseTags() {
    final tagsText = _tagsController.text.trim();
    if (tagsText.isEmpty) return [];
    
    return tagsText
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    
    if (title.isEmpty) {
      _showError('Title cannot be empty');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        title: title,
        tags: _parseTags(),
        difficulty: _difficulty,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showError('Could not save section');
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.tertiaryText,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isSaving ? null : widget.onCancel,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const Text(
                    'Create Section',
                    style: TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const CupertinoActivityIndicator()
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            
            Container(
              height: 0.5,
              color: AppTheme.separator,
            ),
            
            // Form
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: [
                  // Title
                  _buildFieldLabel('Title'),
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: 'Section title',
                    style: const TextStyle(color: AppTheme.primaryText),
                    decoration: BoxDecoration(
                      color: AppTheme.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Tags (optional)
                  _buildFieldLabel('Tags (optional)'),
                  CupertinoTextField(
                    controller: _tagsController,
                    placeholder: 'Comma-separated tags',
                    style: const TextStyle(color: AppTheme.primaryText),
                    decoration: BoxDecoration(
                      color: AppTheme.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Difficulty
                  _buildFieldLabel('Difficulty'),
                  const SizedBox(height: 8),
                  CupertinoSlidingSegmentedControl<int>(
                    backgroundColor: AppTheme.secondarySurface,
                    thumbColor: AppTheme.tertiaryFill,
                    groupValue: _difficulty,
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _difficulty = value;
                        });
                      }
                    },
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Easy', style: TextStyle(fontSize: 13)),
                      ),
                      1: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Medium', style: TextStyle(fontSize: 13)),
                      ),
                      2: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Hard', style: TextStyle(fontSize: 13)),
                      ),
                      3: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('Very Hard', style: TextStyle(fontSize: 13)),
                      ),
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Preview snippet
                  _buildFieldLabel('Preview'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getPreviewSnippet(),
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Character count info
                  if (widget.selectedText.length > 2000)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Note: Text will be trimmed to 2000 characters',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryText,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
