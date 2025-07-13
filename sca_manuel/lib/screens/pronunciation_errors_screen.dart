import 'package:flutter/material.dart';
import 'package:sca_manuel/screens/pronunciation_error.dart'; // Doğru yolu kontrol edin
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class PronunciationErrorsScreen extends StatefulWidget {
  const PronunciationErrorsScreen({Key? key}) : super(key: key);

  @override
  State<PronunciationErrorsScreen> createState() =>
      _PronunciationErrorsScreenState();
}

class _PronunciationErrorsScreenState extends State<PronunciationErrorsScreen> {
  List<PronunciationError> _allErrors = [];
  List<PronunciationError> _filteredErrors = [];
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _showAllTime = false; // Yeni durum değişkeni

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  Future<void> _loadErrors() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> errorsJson = prefs.getStringList('pronunciation_errors') ?? [];
    setState(() {
      _allErrors = errorsJson
          .map(
            (e) => PronunciationError.fromJson(
          jsonDecode(e) as Map<String, dynamic>,
        ),
      )
          .toList()
        ..sort(
              (a, b) => b.date.compareTo(a.date),
        ); // Hataları tarihe göre azalan sırada sırala
      _filterErrors(); // Hataları başlangıçta filtrele
    });
  }

  void _filterErrors() {
    setState(() {
      if (_showAllTime) {
        _filteredErrors = _allErrors;
      } else {
        _filteredErrors = _allErrors.where((error) {
          return error.date.year == _selectedDay.year &&
              error.date.month == _selectedDay.month &&
              error.date.day == _selectedDay.day;
        }).toList();
      }
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _showAllTime = false; // Bir gün seçildiğinde "Tüm Zamanlar"ı kapat
      });
      _filterErrors();
    }
  }

  void _showRecommendationDialog(
      BuildContext context,
      PronunciationError error,
      ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(error.category.toTitle()),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(error.category.getRecommendation()),
                const SizedBox(height: 16),
                Text(
                  'Hatanın Görüldüğü Metin: ${error.textTitle}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Söylenen Kısım: "${error.detectedFragment}"'),
                Text(
                  'Orijinal Cümle: "${error.originalText}"',
                ), // Orijinal metni de göster
                Text(
                  'Söylenen Cümle: "${error.spokenText}"',
                ), // Söylenen metni de göster
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Kapat'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Hataları temizleme işlemini onaylayan ve gerçekleştiren metod.
  Future<void> _confirmAndDeleteErrors() async {
    final bool deleteAll = _showAllTime;
    final String dialogTitle = deleteAll
        ? "Tüm Hataları Temizle"
        : "Seçili Günün Hatalarını Temizle";
    final String dialogContent = deleteAll
        ? "Tüm telaffuz hatalarını silmek istediğinizden emin misiniz? Bu işlem geri alınamaz."
        : "${DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDay)} tarihli hataları silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.";

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      List<PronunciationError> errorsToKeep = [];

      if (deleteAll) {
        // Tüm hataları silmek için SharedPreferences'tan anahtarı kaldır
        await prefs.remove('pronunciation_errors');
        _allErrors.clear();
      } else {
        // Sadece seçili günün hatalarını sil
        errorsToKeep = _allErrors.where((error) {
          return !(error.date.year == _selectedDay.year &&
              error.date.month == _selectedDay.month &&
              error.date.day == _selectedDay.day);
        }).toList();

        // Geri kalan hataları SharedPreferences'a kaydet
        List<String> errorsJson =
        errorsToKeep.map((e) => jsonEncode(e.toJson())).toList();
        await prefs.setStringList('pronunciation_errors', errorsJson);
        _allErrors = errorsToKeep;
      }
      _filterErrors(); // UI'ı güncelle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deleteAll
              ? 'Tüm hatalar temizlendi.'
              : 'Seçili günün hataları temizlendi.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telaffuz Hatalarım'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Temizle butonu
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _filteredErrors.isEmpty
                ? null
                : _confirmAndDeleteErrors, // Hata yoksa pasif olsun
            tooltip: _showAllTime
                ? 'Tüm Hataları Temizle'
                : 'Seçili Günün Hatalarını Temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          // "Tüm Zamanlar" ve "Tarih Seç" seçenekleri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showAllTime = true;
                      });
                      _filterErrors();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showAllTime ? Colors.teal : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tüm Zamanlar'),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showAllTime = false;
                        _filterErrors();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      !_showAllTime ? Colors.teal : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tarih Seç'),
                  ),
                ),
              ),
            ],
          ),
          if (!_showAllTime) // "Tüm Zamanlar" seçili değilse takvimi göster
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color:
                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _showAllTime
                  ? 'Tüm Zamanlardaki Hatalar:'
                  : '${DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDay)} Tarihli Hatalar:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _filteredErrors.isEmpty
                ? const Center(child: Text('Tespit edilmiş bir hata yok.'))
                : ListView.builder(
              itemCount: _filteredErrors.length,
              itemBuilder: (context, index) {
                final error = _filteredErrors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 4,
                  child: InkWell(
                    onTap: () =>
                        _showRecommendationDialog(context, error),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            error.category.toTitle(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: error.category.toColor(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Metin: ${error.textTitle}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            'Hatalı Kısım: "${error.detectedFragment}"',
                            style: const TextStyle(fontSize: 15),
                          ),
                          Text(
                            'Tarih: ${DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(error.date)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}