import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/card_type.dart';
import '../../../data/models/card_status.dart';

class CardEditorSheet extends StatefulWidget {
  final String selectedText;
  final VoidCallback onCancel;
  final Future<void> Function({
    required CardType type,
    required String front,
    required String back,
    required List<String> tags,
    required CardStatus status,
  }) onSave;

  const CardEditorSheet({
    super.key,
    required this.selectedText,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<CardEditorSheet> createState() => _CardEditorSheetState();
}

class _CardEditorSheetState extends State<CardEditorSheet> {
  late TextEditingController _frontController;
  late TextEditingController _backController;
  late TextEditingController _tagsController;
  
  CardType _cardType = CardType.qa;
  CardStatus _status = CardStatus.active;
  bool _trueFalseAnswer = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController();
    _backController = TextEditingController();
    _tagsController = TextEditingController();
    _prefillFields();
  }

  void _prefillFields() {
    // Prefill based on card type
    switch (_cardType) {
      case CardType.qa:
        // Keep empty or use default
        if (_frontController.text.isEmpty) {
          _frontController.text = '';
        }
        break;
      case CardType.cloze:
        // Could suggest a cloze from first line
        if (_frontController.text.isEmpty) {
          _frontController.text = '';
        }
        break;
      case CardType.trueFalse:
        // Use first line of selected text
        if (_frontController.text.isEmpty) {
          final firstLine = widget.selectedText.split('\n').first.trim();
          _frontController.text = firstLine.length > 120 
              ? '${firstLine.substring(0, 117)}...' 
              : firstLine;
        }
        break;
    }
  }

  String _getSourcePreview() {
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

  bool _canSave() {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();

    if (front.isEmpty) return false;

    switch (_cardType) {
      case CardType.qa:
      case CardType.cloze:
        return back.isNotEmpty;
      case CardType.trueFalse:
        return true; // back is set by toggle
    }
  }

  Future<void> _handleSave() async {
    if (!_canSave()) {
      _showError('Please fill all required fields');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final back = _cardType == CardType.trueFalse 
          ? (_trueFalseAnswer ? 'true' : 'false')
          : _backController.text.trim();

      await widget.onSave(
        type: _cardType,
        front: _frontController.text.trim(),
        back: back,
        tags: _parseTags(),
        status: _status,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        _showError('Could not save card');
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

  void _onTypeChanged(CardType? newType) {
    if (newType != null && newType != _cardType) {
      setState(() {
        _cardType = newType;
        // Preserve front text when possible
        // For True/False, prefill from selection if front is empty
        if (newType == CardType.trueFalse && _frontController.text.isEmpty) {
          final firstLine = widget.selectedText.split('\n').first.trim();
          _frontController.text = firstLine.length > 120 
              ? '${firstLine.substring(0, 117)}...' 
              : firstLine;
        }
      });
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
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
                    'New Card',
                    style: TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: (_isSaving || !_canSave()) ? null : _handleSave,
                    child: _isSaving
                        ? const CupertinoActivityIndicator()
                        : Text(
                            'Save',
                            style: TextStyle(
                              color: _canSave() ? AppTheme.accentBlue : AppTheme.tertiaryText,
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
                  // Type selector
                  _buildFieldLabel('Type'),
                  const SizedBox(height: 8),
                  CupertinoSlidingSegmentedControl<CardType>(
                    backgroundColor: AppTheme.secondarySurface,
                    thumbColor: AppTheme.tertiaryFill,
                    groupValue: _cardType,
                    onValueChanged: _onTypeChanged,
                    children: {
                      CardType.qa: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text(CardType.qa.displayName, style: const TextStyle(fontSize: 13)),
                      ),
                      CardType.cloze: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text(CardType.cloze.displayName, style: const TextStyle(fontSize: 13)),
                      ),
                      CardType.trueFalse: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        child: Text(CardType.trueFalse.displayName, style: const TextStyle(fontSize: 13)),
                      ),
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Front
                  _buildFieldLabel(_getFrontLabel()),
                  CupertinoTextField(
                    controller: _frontController,
                    placeholder: _getFrontPlaceholder(),
                    style: const TextStyle(color: AppTheme.primaryText),
                    decoration: BoxDecoration(
                      color: AppTheme.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    maxLines: 3,
                    minLines: 2,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Back
                  if (_cardType != CardType.trueFalse) ...[
                    _buildFieldLabel(_getBackLabel()),
                    CupertinoTextField(
                      controller: _backController,
                      placeholder: _getBackPlaceholder(),
                      style: const TextStyle(color: AppTheme.primaryText),
                      decoration: BoxDecoration(
                        color: AppTheme.secondarySurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      maxLines: 3,
                      minLines: 2,
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    _buildFieldLabel('Answer'),
                    const SizedBox(height: 8),
                    CupertinoSlidingSegmentedControl<bool>(
                      backgroundColor: AppTheme.secondarySurface,
                      thumbColor: AppTheme.tertiaryFill,
                      groupValue: _trueFalseAnswer,
                      onValueChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _trueFalseAnswer = value;
                          });
                        }
                      },
                      children: const {
                        true: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                          child: Text('True', style: TextStyle(fontSize: 15)),
                        ),
                        false: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                          child: Text('False', style: TextStyle(fontSize: 15)),
                        ),
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  
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
                  
                  // Status
                  _buildFieldLabel('Status'),
                  const SizedBox(height: 8),
                  CupertinoSlidingSegmentedControl<CardStatus>(
                    backgroundColor: AppTheme.secondarySurface,
                    thumbColor: AppTheme.tertiaryFill,
                    groupValue: _status,
                    onValueChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                    children: {
                      CardStatus.draft: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: Text('Draft', style: TextStyle(fontSize: 13)),
                      ),
                      CardStatus.active: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: Text('Active', style: TextStyle(fontSize: 13)),
                      ),
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Source preview
                  _buildFieldLabel('Source'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.secondarySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getSourcePreview(),
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Snippet truncation warning
                  if (widget.selectedText.length > 500)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Note: Source snippet will be trimmed to 500 characters',
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

  String _getFrontLabel() {
    switch (_cardType) {
      case CardType.qa:
        return 'Question';
      case CardType.cloze:
        return 'Sentence';
      case CardType.trueFalse:
        return 'Statement';
    }
  }

  String _getFrontPlaceholder() {
    switch (_cardType) {
      case CardType.qa:
        return 'What is the question?';
      case CardType.cloze:
        return 'Sentence with {{blank}}';
      case CardType.trueFalse:
        return 'True or false statement';
    }
  }

  String _getBackLabel() {
    switch (_cardType) {
      case CardType.qa:
        return 'Answer';
      case CardType.cloze:
        return 'Answer';
      case CardType.trueFalse:
        return 'Answer';
    }
  }

  String _getBackPlaceholder() {
    switch (_cardType) {
      case CardType.qa:
        return 'The answer is...';
      case CardType.cloze:
        return 'Expected answer for the blank';
      case CardType.trueFalse:
        return '';
    }
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
