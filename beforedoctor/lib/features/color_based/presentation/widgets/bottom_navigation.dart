import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/app_models.dart';

/// TikTok-style bottom navigation widget
class BottomNavigation extends StatelessWidget {
  final int currentPageIndex;
  final AppStatus currentStatus;
  final Function(int) onTabTapped;

  const BottomNavigation({
    super.key,
    required this.currentPageIndex,
    required this.currentStatus,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClinicColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ClinicColors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.chat, 'Chat'),
          _buildNavItem(1, Icons.insights, 'Insights'),
          _buildNavItem(2, Icons.history, 'Log'),
          _buildNavItem(3, Icons.settings, 'Settings'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = currentPageIndex == index;
    
    return GestureDetector(
      onTap: () => onTabTapped(index),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive 
                  ? statusColor(currentStatus).withOpacity(0.2)
                  : ClinicColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isActive 
                    ? statusColor(currentStatus).withOpacity(0.4)
                    : ClinicColors.white.withOpacity(0.3),
                width: isActive ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? statusColor(currentStatus) : ClinicColors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? statusColor(currentStatus) : ClinicColors.white.withOpacity(0.9),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
