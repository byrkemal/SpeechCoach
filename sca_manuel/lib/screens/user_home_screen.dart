import 'package:flutter/material.dart';
import 'texts_screen.dart';
import 'pronunciation_errors_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class UserHomeScreen extends StatelessWidget {
  final String username;

  const UserHomeScreen({required this.username, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Konuşma Koçu'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              accountName: Text(username),
              accountEmail: Text(''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  username[0].toUpperCase(),
                  style: TextStyle(fontSize: 32, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.record_voice_over),
              title: Text('Telaffuz Hatalarım'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PronunciationErrorsScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Hakkında'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen()));
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoş Geldin, $username 👋',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.menu_book),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Text(
                    'Metinler',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => TextsScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
