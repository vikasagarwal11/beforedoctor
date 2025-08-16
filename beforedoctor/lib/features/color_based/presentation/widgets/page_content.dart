import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Insights page content widget
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Symptom trend
          _buildSymptomTrend(),
          
          const SizedBox(height: 30),
          
          // Summary and export
          _buildSummaryAndExport(),
        ],
      ),
    );
  }

  Widget _buildSymptomTrend() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ClinicColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ClinicColors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Symptom Trend',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ClinicColors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '3x tummy aches this week',
            style: TextStyle(
              fontSize: 18,
              color: ClinicColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Possible triggers: diet changes, stress',
            style: TextStyle(
              fontSize: 16,
              color: ClinicColors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryAndExport() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard('Summary', 'Mild issue, monitor'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard('Export', 'Share with doctor'),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClinicColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ClinicColors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ClinicColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: ClinicColors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Log page content widget
class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Health log entries
          Expanded(
            child: _buildLogEntries(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntries() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        final dates = [
          'Aug 15, 02:30 AM',
          'Aug 14, 01:30 AM',
          'Aug 13, 23:45 PM',
          'Aug 12, 22:15 PM',
          'Aug 11, 21:00 PM',
        ];
        final symptoms = [
          'Symptom noted',
          'Fever',
          'Cough',
          'Headache',
          'Stomach ache',
        ];
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ClinicColors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ClinicColors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dates[index % dates.length],
                    style: TextStyle(
                      fontSize: 14,
                      color: ClinicColors.white.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    symptoms[index % symptoms.length],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ClinicColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Transcript: "Ouch, my tummy hurts..."',
                style: TextStyle(
                  fontSize: 14,
                  color: ClinicColors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Replay',
                    style: TextStyle(
                      fontSize: 14,
                      color: ClinicColors.speak,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Summary: Mild issue',
                    style: TextStyle(
                      fontSize: 14,
                      color: ClinicColors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Settings page content widget
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Settings options
          Expanded(
            child: _buildSettingsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return ListView(
      children: [
        _buildSettingItem('Profile: Child', 'Edit'),
        _buildSettingItem('Voice: US Kid', 'Change'),
        _buildSettingItem('Theme: Kid Mode', 'Preview'),
        _buildSettingItem('Data: Delete', 'Export All'),
        _buildSettingItem('Upgrade', '', isUpgrade: true),
      ],
    );
  }

  Widget _buildSettingItem(String title, String action, {bool isUpgrade = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClinicColors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUpgrade 
              ? ClinicColors.secondary.withOpacity(0.4)
              : ClinicColors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: ClinicColors.white,
            ),
          ),
          if (action.isNotEmpty)
            Text(
              action,
              style: TextStyle(
                fontSize: 14,
                color: isUpgrade 
                    ? ClinicColors.secondary
                    : ClinicColors.speak,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
