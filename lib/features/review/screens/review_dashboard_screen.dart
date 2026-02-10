import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/database/database.dart';
import '../../../data/models/study_scope.dart';
import '../../../data/repositories/srs_repository.dart';
import '../../../data/repositories/card_repository.dart';
// import '../../../core/services/demo_seeder.dart'; // File not found
import 'study_session_screen.dart';

class ReviewDashboardScreen extends StatefulWidget {
  const ReviewDashboardScreen({super.key});

  @override
  State<ReviewDashboardScreen> createState() => _ReviewDashboardScreenState();
}

class _ReviewDashboardScreenState extends State<ReviewDashboardScreen> {
  final SRSRepository _srsRepository = SRSRepository(AppDatabase());
  final CardRepository _cardRepository = CardRepository(AppDatabase());

  int _dueCount = 0;
  int _totalActiveCards = 0;
  bool _isLoading = true;
  
  // Settings
  int _dailyMaxReviews = 200;
  int _newCardsPerDay = 20;

  @override
  void initState() {
    super.initState();
    _loadDueCount();
  }

  Future<void> _loadDueCount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final count = await _srsRepository.getDueCardsCount();
      final totalCards = await _cardRepository.getActiveCardsCount();
      setState(() {
        _dueCount = count;
        _totalActiveCards = totalCards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _dueCount = 0;
        _totalActiveCards = 0;
        _isLoading = false;
      });
    }
  }

  void _startReview() {
    if (_dueCount == 0) return;

    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const StudySessionScreen(
          scope: StudyScope.all,
        ),
      ),
    ).then((_) {
      // Reload due count after returning from session
      _loadDueCount();
    });
  }

  Widget _buildReviewContent() {
    // Case 1: No active cards at all
    if (_totalActiveCards == 0) {
      return Column(
        children: [
          Icon(
            CupertinoIcons.square_stack_3d_up,
            size: 64,
            color: AppTheme.tertiaryText,
          ),
          const SizedBox(height: AppTheme.spacing16),
          const Text(
            'No cards to review yet',
            style: AppTheme.title2,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Create flashcards from your documents to start reviewing',
            style: AppTheme.body.copyWith(
              color: AppTheme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.accentBlue,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onPressed: _tryDemoSession,
              child: const Text(
                'Try Demo Session',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.secondarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onPressed: () {
                // Note: In CupertinoTabScaffold, tab switching is handled by tapping tabs
                // This button provides context to user
              },
              child: Text(
                'Import PDF',
                style: TextStyle(
                  color: CupertinoTheme.of(context).brightness == Brightness.dark
                      ? AppTheme.primaryText
                      : CupertinoColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Case 2: Cards exist but none are due
    if (_dueCount == 0) {
      return Column(
        children: [
          Icon(
            CupertinoIcons.checkmark_seal_fill,
            size: 64,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(height: AppTheme.spacing16),
          const Text(
            'You\'re all caught up!',
            style: AppTheme.title2,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'No cards due right now. Come back later.',
            style: AppTheme.body.copyWith(
              color: AppTheme.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppTheme.secondarySurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              onPressed: () {
                // Note: In CupertinoTabScaffold, tab switching is handled by tapping tabs
                // This button provides context to user
              },
              child: Text(
                'Browse Documents',
                style: TextStyle(
                  color: CupertinoTheme.of(context).brightness == Brightness.dark
                      ? AppTheme.primaryText
                      : CupertinoColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Case 3: Normal case - cards are due
    return Column(
      children: [
        const Text(
          'Cards due today',
          style: AppTheme.subheadline,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          _dueCount.toString(),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppTheme.accentBlue,
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: AppTheme.accentBlue,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            onPressed: _startReview,
            child: const Text(
              'Start Review',
              style: TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _tryDemoSession() async {
    try {
      // Show loading
      if (mounted) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CupertinoActivityIndicator(radius: 20),
          ),
        );
      }

      // Create/get demo
      // final demoSeeder = DemoSeeder(AppDatabase()); // DemoSeeder not available
      // await demoSeeder.ensureDemoExists();

      if (mounted) {
        // Close loading
        Navigator.of(context).pop();

        // Reload due count to show the new cards
        await _loadDueCount();

        // If we have due cards now, start review
        if (_dueCount > 0) {
          _startReview();
        }
      }
    } catch (e) {
      if (mounted) {
        // Close loading if showing
        Navigator.of(context).popUntil((route) => route.isFirst);

        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load demo: ${e.toString()}'),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppTheme.backgroundColor : CupertinoColors.systemGroupedBackground;
    final surfaceColor = isDark ? AppTheme.surfaceColor : CupertinoColors.systemBackground;
    final textColor = isDark ? AppTheme.primaryText : CupertinoColors.black;
    
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: surfaceColor,
        border: null,
        middle: Text('Review', style: AppTheme.title2.copyWith(color: textColor)),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showReviewSettings,
          child: const Icon(
            CupertinoIcons.ellipsis_circle,
            color: AppTheme.accentBlue,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
            // Due cards count
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: _isLoading 
                  ? const Center(
                      child: CupertinoActivityIndicator(),
                    )
                  : _buildReviewContent(),
            ),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Settings
            const Text('Study Settings', style: AppTheme.headline),
            const SizedBox(height: AppTheme.spacing12),
            
            _buildSettingRow(
              'Daily max reviews',
              _dailyMaxReviews.toString(),
              _showDailyMaxReviewsPicker,
            ),
            
            const SizedBox(height: AppTheme.spacing8),
            
            _buildSettingRow(
              'New cards per day',
              _newCardsPerDay.toString(),
              _showNewCardsPerDayPicker,
            ),
            
            const SizedBox(height: AppTheme.spacing24),
            
            // Breakdown by document
            const Text('By Document', style: AppTheme.headline),
            const SizedBox(height: AppTheme.spacing12),
            
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing32),
                child: Text(
                  'No documents yet',
                  style: AppTheme.subheadline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.body),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTheme.body.copyWith(color: AppTheme.secondaryText),
                ),
                const SizedBox(width: AppTheme.spacing8),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: AppTheme.iconSmall,
                  color: AppTheme.secondaryText,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewSettings() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Review Settings'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showDailyMaxReviewsPicker();
            },
            child: const Text('Daily max reviews'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showNewCardsPerDayPicker();
            },
            child: const Text('New cards per day'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showNotificationSettings();
            },
            child: const Text('Notification settings'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDailyMaxReviewsPicker() {
    int selectedValue = _dailyMaxReviews;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: AppTheme.surfaceColor,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text('Daily Max Reviews', style: AppTheme.headline),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _dailyMaxReviews = selectedValue;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: [50, 100, 150, 200, 250, 300, 500, 1000]
                      .indexOf(_dailyMaxReviews)
                      .clamp(0, 7),
                ),
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  selectedValue = [50, 100, 150, 200, 250, 300, 500, 1000][index];
                },
                children: [50, 100, 150, 200, 250, 300, 500, 1000]
                    .map((value) => Center(child: Text('$value cards')))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewCardsPerDayPicker() {
    int selectedValue = _newCardsPerDay;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: AppTheme.surfaceColor,
        child: Column(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Text('New Cards Per Day', style: AppTheme.headline),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _newCardsPerDay = selectedValue;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(
                  initialItem: [5, 10, 15, 20, 25, 30, 40, 50]
                      .indexOf(_newCardsPerDay)
                      .clamp(0, 7),
                ),
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  selectedValue = [5, 10, 15, 20, 25, 30, 40, 50][index];
                },
                children: [5, 10, 15, 20, 25, 30, 40, 50]
                    .map((value) => Center(child: Text('$value cards')))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Notification Settings'),
        content: const Text('Daily reminder notifications will be available in a future update.'),
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
