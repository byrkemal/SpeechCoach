// Kullanıcı metni yönetimi, başlık ve içerik kaydı içeren versiyon
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'text_detail_screen.dart'; // TextDetailScreen dosyasını import ediyoruz

class TextsScreen extends StatefulWidget {
  const TextsScreen({Key? key}) : super(key: key);

  @override
  State<TextsScreen> createState() => _TextsScreenState();
}

class _TextsScreenState extends State<TextsScreen> {
  List<Map<String, String>> _texts = []; // Hem kullanıcı hem de varsayılan metinleri içerecek
  List<String> _defaultTextFileNames = ['metin1.txt', 'metin2.txt', 'metin3.txt', 'metin4.txt', 'metin5.txt', 'metin6.txt', 'metin7.txt']; // Varsayılan metin dosyaları
  Map<String, int> _scores = {}; // Her metnin skorunu tutmak için

  @override
  void initState() {
    super.initState();
    _loadTextsAndScores(); // Hem metinleri hem de skorları yükle
  }

  Future<void> _loadTextsAndScores() async {
    await _loadDefaultTexts(); // Varsayılan metinleri yükle
    await _loadUserTexts(); // Kullanıcı metinlerini yükle
    await _loadScores(); // Skorları yükle
  }

  Future<void> _loadDefaultTexts() async {
    List<Map<String, String>> defaultTexts = [];
    for (String fileName in _defaultTextFileNames) {
      try {
        final content = await DefaultAssetBundle.of(context).loadString('assets/$fileName');
        // Dosya adından başlık oluştur, uzantıyı kaldır
        String title = fileName.replaceAll('.txt', '');
        // İlk harfi büyüt
        title = title.substring(0, 1).toUpperCase() + title.substring(1);
        defaultTexts.add({'title': title, 'content': content});
      } catch (e) {
        print('Error loading default text $fileName: $e');
      }
    }
    setState(() {
      _texts.insertAll(0, defaultTexts);
    });
  }

  Future<void> _loadUserTexts() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('user_texts') ?? [];
    setState(() {
      _texts.addAll(stored.map((e) => Map<String, String>.from(jsonDecode(e))).toList());
    });
  }

  Future<void> _loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, int> loadedScores = {};
    for (var text in _texts) {
      final titleKey = text['title']!.replaceAll(' ', '_');
      final score = prefs.getInt('score_$titleKey');
      if (score != null) {
        loadedScores[text['title']!] = score;
      }
    }
    setState(() {
      _scores = loadedScores;
    });
  }

  Future<void> _saveUserTexts() async {
    final prefs = await SharedPreferences.getInstance();
    final userOnlyTexts = _texts.where((text) => !_isDefaultText(text)).toList();
    await prefs.setStringList(
      'user_texts',
      userOnlyTexts.map((e) => jsonEncode(e)).toList(),
    );
  }

  bool _isDefaultText(Map<String, String> text) {
    final titleLowerCase = text['title']?.toLowerCase();
    for (String fileName in _defaultTextFileNames) {
      if (titleLowerCase == fileName.replaceAll('.txt', '').toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  Future<void> _addOrEditText({Map<String, String>? existing, int? index}) async {
    final titleController = TextEditingController(text: existing?['title']);
    final contentController = TextEditingController(text: existing?['content']);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(index == null ? "Yeni Metin Ekle" : "Metni Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Başlık')),
            SizedBox(height: 8),
            TextField(controller: contentController, maxLines: 5, decoration: InputDecoration(labelText: 'İçerik')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'title': titleController.text.trim(),
                'content': contentController.text.trim(),
              });
            },
            child: Text("Kaydet"),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (index == null) {
          _texts.add(result);
        } else {
          _texts[index] = result;
        }
      });
      await _saveUserTexts();
      await _loadScores(); // Yeni/güncellenen metin için skorları tekrar yükle
    }
  }

  Future<void> _deleteText(int index) async {
    final deletedTextTitle = _texts[index]['title'];
    setState(() {
      _texts.removeAt(index);
      if (deletedTextTitle != null) {
        _scores.remove(deletedTextTitle); // Skorunu da sil
      }
    });
    await _saveUserTexts();
    // Silinen metnin skorunu SharedPreferences'tan da temizle
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('score_${deletedTextTitle!.replaceAll(' ', '_')}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Metinlerim")),
      body: ListView.builder(
        itemCount: _texts.length,
        itemBuilder: (context, index) {
          final item = _texts[index];
          final bool isDefault = _isDefaultText(item);
          final int? score = _scores[item['title']]; // Skorları al
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(item['title'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['content']?.substring(0, item['content']!.length.clamp(0, 50)) ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (score != null) // Skor varsa göster
                    Text('Son Skor: %$score', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _addOrEditText(existing: item, index: index);
                  } else if (value == 'delete') {
                    await _deleteText(index);
                  }
                },
                itemBuilder: (_) => [
                  if (!isDefault)
                    PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
              onTap: () async {
                // TextDetailScreen'e geçildiğinde, geri dönüldüğünde skorların güncellenmesi için
                // pop()'tan sonra yeniden skorları yükle
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TextDetailScreen(title: item['title']!, content: item['content']!),
                  ),
                );
                await _loadScores(); // Geri dönüldüğünde skorları yenile
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditText(),
        child: Icon(Icons.add),
      ),
    );
  }
}