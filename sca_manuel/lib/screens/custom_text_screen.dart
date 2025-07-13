import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // Dosya yolu için
import 'package:flutter_tts/flutter_tts.dart'; // Metni seslendirmek için
import 'package:shared_preferences/shared_preferences.dart'; // Kalıcı depolama için

class CustomTextScreen extends StatefulWidget {
  final String username;

  const CustomTextScreen({Key? key, required this.username}) : super(key: key);

  @override
  _CustomTextScreenState createState() => _CustomTextScreenState();
}

class _CustomTextScreenState extends State<CustomTextScreen> {
  final TextEditingController _controller = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  String _savedFilePath = '';
  final String _prefsKeyPrefix = 'saved_custom_text_';

  @override
  void initState() {
    super.initState();
    _loadSavedText();
  }

  Future<void> _loadSavedText() async {
    final prefs = await SharedPreferences.getInstance();
    final savedText = prefs.getString(_prefsKeyPrefix + widget.username) ?? '';
    _controller.text = savedText;

    final file = await _localFile;
    if (await file.exists()) {
      setState(() {
        _savedFilePath = file.path;
      });
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    // Dosya adı kullanıcı adına göre değişiyor:
    return File('$path/kendi_metnim_${widget.username}.txt');
  }

  Future<void> _saveText() async {
    final file = await _localFile;
    await file.writeAsString(_controller.text);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyPrefix + widget.username, _controller.text);

    setState(() {
      _savedFilePath = file.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Metin kaydedildi!')),
    );
  }

  Future<void> _readText() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen önce metin yazın!')),
      );
      return;
    }

    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Kendi Metnini Yaz, Kendini Test Et"),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "Buraya metnini yaz...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveText,
                    icon: Icon(Icons.save, color: Colors.white),
                    label: Text("Metni Kaydet", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _readText,
                    icon: Icon(Icons.volume_up, color: Colors.white),
                    label: Text("Metni Dinle", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            if (_savedFilePath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  "Kaydedilen dosya: $_savedFilePath",
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
