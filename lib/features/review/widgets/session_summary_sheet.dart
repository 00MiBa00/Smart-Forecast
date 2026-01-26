import 'package:flutter/cupertino.dart';
import '../../../core/theme/app_theme.dart';

class SessionSummarySheet extends StatelessWidget {
  final int totalReviewed;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final VoidCallback onDone;

  const SessionSummarySheet({
    super.key,
    required this.totalReviewed,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryText,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Success icon
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 64,
                color: AppTheme.accentGreen,
              ),
              
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Session Complete!',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Total reviewed
              Text(
                'Reviewed $totalReviewed ${totalReviewed == 1 ? 'card' : 'cards'}',
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Statistics
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Again',
                      againCount,
                      AppTheme.accentRed,
                    ),
                    if (againCount > 0 || hardCount > 0 || goodCount > 0 || easyCount > 0)
                      const SizedBox(height: 12),
                    _buildStatRow(
                      'Hard',
                      hardCount,
                      AppTheme.accentOrange,
                    ),
                    if (hardCount > 0 || goodCount > 0 || easyCount > 0)
                      const SizedBox(height: 12),
                    _buildStatRow(
                      'Good',
                      goodCount,
                      AppTheme.accentBlue,
                    ),
                    if (goodCount > 0 || easyCount > 0)
                      const SizedBox(height: 12),
                    _buildStatRow(
                      'Easy',
                      easyCount,
                      AppTheme.accentGreen,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Done button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: onDone,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: const TextStyle(
            color: AppTheme.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
