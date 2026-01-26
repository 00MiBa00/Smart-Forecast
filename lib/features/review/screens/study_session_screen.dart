import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/sm2_algorithm.dart';
import '../../../data/database/database.dart';
import '../../../data/models/srs_grade.dart';
import '../../../data/models/study_scope.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../data/repositories/srs_repository.dart';
import '../widgets/session_summary_sheet.dart';

class StudySessionScreen extends StatefulWidget {
  final StudyScope scope;
  final String? scopeId; // documentId for document scope

  const StudySessionScreen({
    super.key,
    required this.scope,
    this.scopeId,
  });

  @override
  State<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends State<StudySessionScreen> {
  final CardRepository _cardRepository = CardRepository(AppDatabase());
  final SRSRepository _srsRepository = SRSRepository(AppDatabase());

  List<Card> _queue = [];
  int _currentIndex = 0;
  bool _showingAnswer = false;
  bool _isLoading = true;

  // Session statistics
  int _againCount = 0;
  int _hardCount = 0;
  int _goodCount = 0;
  int _easyCount = 0;

  @override
  void initState() {
    super.initState();
    _buildQueue();
  }

  Future<void> _buildQueue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get active cards based on scope
      List<Card> activeCards;
      switch (widget.scope) {
        case StudyScope.all:
          activeCards = await _cardRepository.getActiveCards();
          break;
        case StudyScope.document:
          if (widget.scopeId != null) {
            activeCards = await _cardRepository.getActiveCardsByDocumentId(widget.scopeId!);
          } else {
            activeCards = [];
          }
          break;
        case StudyScope.section:
          // TODO: Implement section scope
          activeCards = [];
          break;
      }

      if (activeCards.isEmpty) {
        setState(() {
          _queue = [];
          _isLoading = false;
        });
        return;
      }

      // Separate due cards and new cards
      final now = DateTime.now();
      final List<Card> dueCards = [];
      final List<Card> newCards = [];

      for (final card in activeCards) {
        final srsRecord = await _srsRepository.getSrsRecordByCardId(card.id);
        
        if (srsRecord == null) {
          // New card (no SRS record yet)
          newCards.add(card);
        } else if (srsRecord.dueAt.isBefore(now) || srsRecord.dueAt.isAtSameMomentAs(now)) {
          // Due card
          dueCards.add(card);
        }
      }

      // Build queue: due cards first, then new cards
      setState(() {
        _queue = [...dueCards, ...newCards];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _queue = [];
        _isLoading = false;
      });
    }
  }

  void _showAnswer() {
    setState(() {
      _showingAnswer = true;
    });
  }

  Future<void> _gradeCard(SRSGrade grade) async {
    if (_currentIndex >= _queue.length) return;

    final card = _queue[_currentIndex];

    try {
      // Get or create SRS record
      final currentRecord = await _srsRepository.getOrCreateSrsRecord(card.id);

      // Calculate next record using SM-2
      final nextRecord = SM2Algorithm.calculateNext(currentRecord, grade);

      // Update in database
      await _srsRepository.updateSrsRecord(nextRecord);

      // Update statistics
      setState(() {
        switch (grade) {
          case SRSGrade.again:
            _againCount++;
            break;
          case SRSGrade.hard:
            _hardCount++;
            break;
          case SRSGrade.good:
            _goodCount++;
            break;
          case SRSGrade.easy:
            _easyCount++;
            break;
        }
      });

      // Haptic feedback
      HapticFeedback.lightImpact();

      // Move to next card
      _nextCard();
    } catch (e) {
      // Show error but continue
      _showError('Failed to save progress');
    }
  }

  void _nextCard() {
    if (_currentIndex + 1 >= _queue.length) {
      // Session complete
      _showSummary();
    } else {
      setState(() {
        _currentIndex++;
        _showingAnswer = false;
      });
    }
  }

  void _showSummary() {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionSummarySheet(
        totalReviewed: _currentIndex + 1,
        againCount: _againCount,
        hardCount: _hardCount,
        goodCount: _goodCount,
        easyCount: _easyCount,
        onDone: () {
          Navigator.of(context).pop(); // Close summary
          Navigator.of(context).pop(); // Close study session
        },
      ),
    );
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

  void _handleExit() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Exit Study Session?'),
        content: const Text('Your progress will not be saved.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close study session
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.surfaceColor,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _handleExit,
          child: const Icon(
            CupertinoIcons.xmark,
            color: AppTheme.primaryText,
          ),
        ),
        middle: _queue.isEmpty
            ? const Text('Study Session')
            : Text(
                '${_currentIndex + 1} / ${_queue.length}',
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showSessionOptions,
          child: const Icon(
            CupertinoIcons.ellipsis,
            color: AppTheme.accentBlue,
          ),
        ),
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (_queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle,
              size: 64,
              color: AppTheme.accentGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              'No cards to review',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'All cards are up to date!',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }

    final currentCard = _queue[_currentIndex];

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card front
                  const Text(
                    'Question',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentCard.front,
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  
                  if (_showingAnswer) ...[
                    const SizedBox(height: 32),
                    Container(
                      height: 1,
                      color: AppTheme.separator,
                    ),
                    const SizedBox(height: 32),
                    
                    // Card back
                    const Text(
                      'Answer',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentCard.back,
                      style: const TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 20,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom actions
          _showingAnswer ? _buildGradingBar() : _buildShowAnswerButton(),
        ],
      ),
    );
  }

  Widget _buildShowAnswerButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.separator,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: _showAnswer,
          child: const Text(
            'Show Answer',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradingBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.separator,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildGradeButton(
              label: 'Again',
              grade: SRSGrade.again,
              color: AppTheme.accentRed,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGradeButton(
              label: 'Hard',
              grade: SRSGrade.hard,
              color: AppTheme.accentOrange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGradeButton(
              label: 'Good',
              grade: SRSGrade.good,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildGradeButton(
              label: 'Easy',
              grade: SRSGrade.easy,
              color: AppTheme.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeButton({
    required String label,
    required SRSGrade grade,
    required Color color,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: color,
      borderRadius: BorderRadius.circular(8),
      onPressed: () => _gradeCard(grade),
      child: Text(
        label,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showSessionOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Study Session Options'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showSessionStats();
            },
            child: const Text('Session statistics'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _handleExit();
            },
            child: const Text('End session'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showSessionStats() {
    final totalReviewed = _queue.length - (_queue.length - _currentIndex);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Session Statistics'),
        content: Text(
          'Cards reviewed: $totalReviewed\\n'
          'Cards remaining: ${_queue.length - _currentIndex}\\n'
          'Total cards: ${_queue.length}',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
