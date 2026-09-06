import 'package:dafter/core/widgets/action_button.dart';
import 'package:dafter/features/settings/widgets/settings_summary_row.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // =========================================================
          // Action Buttons
          // =========================================================
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  icon: Icons.backup_outlined,
                  label: 'نسخ احتياطي',
                  primary: false,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.restore_outlined,
                  label: 'استعادة',
                  primary: false,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.person_outlined,
                  label: 'المستخدمون',
                  primary: false,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ActionButton(
                  icon: Icons.tune_outlined,
                  label: 'الإعدادات العامة',
                  primary: true,
                  onTap: () {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // =========================================================
          // Summary Cards
          // =========================================================
          const SettingsSummaryRow(),
        ],
      ),
    );
  }
}
