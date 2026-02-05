import 'package:flutter/cupertino.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/services/card_generation_service.dart';
import '../../../data/database/database.dart';
import '../../../data/models/card_type.dart';
import '../../../data/models/card_status.dart';
import '../../../data/repositories/card_repository.dart';

class GeneratedCardsReviewScreen extends StatefulWidget {
  final List<GeneratedCard> generatedCards;

  const GeneratedCardsReviewScreen({
    super.key,
    required this.generatedCards,
  });

  @override
  State<GeneratedCardsReviewScreen> createState() => _GeneratedCardsReviewScreenState();
}

class _GeneratedCardsReviewScreenState extends State<GeneratedCardsReviewScreen> {
  late List<GeneratedCard> _cards;
  late List<bool> _selectedForActivation;
  final CardRepository _cardRepository = CardRepository(AppDatabase());
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cards = List.from(widget.generatedCards);
    _selectedForActivation = List.generate(_cards.length, (_) => false);
  }

  void _deleteCard(int index) {
    setState(() {
      _cards.removeAt(index);
      _selectedForActivation.removeAt(index);
    });
  }

  void _editCard(int index) {
    // For MVP, show a simple dialog instead of complex editor
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Edit Card'),
        content: const Text('Card editing will be available in a future update. For now, you can delete cards you don\'t want.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCards() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert GeneratedCards to CardsCompanion
      final cardsToSave = <CardsCompanion>[];
      
      for (int i = 0; i < _cards.length; i++) {
        final card = _cards[i];
        final status = _selectedForActivation[i] ? CardStatus.active : CardStatus.draft;
        
        final now = DateTime.now();
        cardsToSave.add(
          CardsCompanion.insert(
            id: card.id,
            documentId: card.documentId,
            sectionId: drift.Value(card.sectionId),
            type: card.type,
            front: card.front,
            back: card.back,
            tags: '[]',
            status: status,
            sourceSnippet: drift.Value(card.sourceSnippet),
            sourceAnchor: drift.Value(card.sourceAnchor?.toJsonString()),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      // Batch insert all cards
      await _cardRepository.createCards(cardsToSave);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate cards were saved
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: const Text('Failed to save generated cards. Please try again.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancel() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Discard Generated Cards?'),
        content: const Text('All generated cards will be lost.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Discard'),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Close screen
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.surfaceColor,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _cancel,
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppTheme.accentRed),
          ),
        ),
        middle: const Text('Generated Cards', style: AppTheme.title2),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _cards.isEmpty ? null : _saveCards,
          child: _isSaving
              ? const CupertinoActivityIndicator()
              : Text(
                  'Save All',
                  style: TextStyle(
                    color: _cards.isEmpty ? AppTheme.tertiaryText : AppTheme.accentBlue,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacing16),
              color: AppTheme.secondarySurface,
              child: Column(
                children: [
                  Text(
                    '${_cards.length} cards generated',
                    style: AppTheme.subheadline.copyWith(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  const Text(
                    'Review, edit, and mark cards for activation',
                    style: AppTheme.caption1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Cards list
            Expanded(
              child: _cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_circle,
                            size: 64,
                            color: AppTheme.tertiaryText,
                          ),
                          const SizedBox(height: AppTheme.spacing16),
                          Text(
                            'All cards removed',
                            style: AppTheme.subheadline.copyWith(
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      itemCount: _cards.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing12),
                      itemBuilder: (context, index) {
                        return _buildCardItem(index);
                      },
                    ),
            ),

            // Bottom action bar
            if (_cards.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceColor,
                  border: Border(
                    top: BorderSide(color: AppTheme.secondarySurface),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_selectedForActivation.where((s) => s).length} cards will be activated',
                      style: AppTheme.caption1,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        onPressed: _isSaving ? null : _saveCards,
                        child: _isSaving
                            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                            : const Text('Save Selected'),
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

  Widget _buildCardItem(int index) {
    final card = _cards[index];
    final isSelected = _selectedForActivation[index];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isSelected ? AppTheme.accentBlue : CupertinoColors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Type badge and actions
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing8,
                    vertical: AppTheme.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(card.type).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    _getTypeLabel(card.type),
                    style: AppTheme.caption1.copyWith(
                      color: _getTypeColor(card.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                
                // Edit button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _editCard(index),
                  child: const Icon(
                    CupertinoIcons.pencil,
                    size: 20,
                    color: AppTheme.accentBlue,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                
                // Delete button
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => _deleteCard(index),
                  child: const Icon(
                    CupertinoIcons.trash,
                    size: 20,
                    color: AppTheme.accentRed,
                  ),
                ),
              ],
            ),
          ),

          // Card content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Front
                const Text(
                  'Front:',
                  style: AppTheme.caption1,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  card.front,
                  style: AppTheme.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing12),
                
                // Back
                const Text(
                  'Back:',
                  style: AppTheme.caption1,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  card.back,
                  style: AppTheme.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Activation toggle
          Container(
            margin: const EdgeInsets.all(AppTheme.spacing12),
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.secondarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                const Text(
                  'Status:',
                  style: AppTheme.callout,
                ),
                const Spacer(),
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: isSelected,
                  backgroundColor: AppTheme.backgroundColor,
                  thumbColor: AppTheme.surfaceColor,
                  children: const {
                    false: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Draft', style: AppTheme.caption1),
                    ),
                    true: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Active', style: AppTheme.caption1),
                    ),
                  },
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedForActivation[index] = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(CardType type) {
    switch (type) {
      case CardType.qa:
        return 'Q&A';
      case CardType.cloze:
        return 'Cloze';
      case CardType.trueFalse:
        return 'T/F';
    }
  }

  Color _getTypeColor(CardType type) {
    switch (type) {
      case CardType.qa:
        return AppTheme.accentBlue;
      case CardType.cloze:
        return AppTheme.accentOrange;
      case CardType.trueFalse:
        return AppTheme.accentGreen;
    }
  }
}
