import 'package:flutter/material.dart';
import 'package:sca_manuel/screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/texts_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('tr', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Coach',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.secondaryContainer.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SpeechCoach',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 40),
                _buildMainButton(
                  context,
                  label: 'Oturum Aç',
                  icon: Icons.login,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMainButton(
                  context,
                  label: 'Metinler',
                  icon: Icons.article_outlined,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TextsScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMainButton(
                  context,
                  label: 'Ayarlar',
                  icon: Icons.settings,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMainButton(
                  context,
                  label: 'Hakkında',
                  icon: Icons.info_outline,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton(BuildContext context,
      {required String label,
        required IconData icon,
        required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}