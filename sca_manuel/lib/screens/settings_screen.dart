import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isVoiceReadingEnabled = true;
  bool isDarkModeEnabled = false;
  bool isNotificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.85),
              theme.colorScheme.secondaryContainer.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  "Ayarlar",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      _buildSwitchTile(
                        icon: Icons.volume_up,
                        title: "Sesli Okuma",
                        value: isVoiceReadingEnabled,
                        onChanged: (val) {
                          setState(() {
                            isVoiceReadingEnabled = val;
                          });
                        },
                        theme: theme,
                      ),
                      _buildSwitchTile(
                        icon: Icons.dark_mode,
                        title: "Karanlık Mod",
                        value: isDarkModeEnabled,
                        onChanged: (val) {
                          setState(() {
                            isDarkModeEnabled = val;
                          });
                        },
                        theme: theme,
                      ),
                      _buildSwitchTile(
                        icon: Icons.notifications_active,
                        title: "Bildirimler",
                        value: isNotificationsEnabled,
                        onChanged: (val) {
                          setState(() {
                            isNotificationsEnabled = val;
                          });
                        },
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required ThemeData theme,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: SwitchListTile(
        secondary: Icon(icon, color: theme.colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
