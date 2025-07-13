// pronunciation_error.dart
import 'package:flutter/material.dart';

enum ErrorCategory {
  // Mevcut kategoriler
  unnecessaryWords, // Gereksiz kelime kullanma (örn: eee, şey, yani)
  skipping, // Kelime atlama / Hece atlama
  stuttering, // Kekeleme / Tutukluk
  mispronunciation, // Yanlış Telaffuz (Yeni Kategori)
  wordSwap, // Kelime Değişimi (Yeni Kategori)
  longPause, // Uzun Duraklama (Yeni Kategori)
  speedTooFast, // Çok Hızlı Konuşma (Mevcut 'fastSpeech' yerine daha spesifik)
  speedTooSlow, // Çok Yavaş Konuşma (Yeni Kategori)
  perfect, // Mükemmel eşleşme (hata değil, durum)
  unknown, // Bilinmeyen hata
}

extension ErrorCategoryExtension on ErrorCategory {
  String toTitle() {
    switch (this) {
      case ErrorCategory.unnecessaryWords:
        return 'Gereksiz Kelime Kullanımı';
      case ErrorCategory.skipping:
        return 'Atlama / Hece Yutma';
      case ErrorCategory.stuttering:
        return 'Kekeleme / Tutukluk';
      case ErrorCategory.mispronunciation: // Yeni
        return 'Yanlış Telaffuz';
      case ErrorCategory.wordSwap: // Yeni
        return 'Kelime Değişimi / Hatalı Kelime';
      case ErrorCategory.longPause: // Yeni
        return 'Uzun Duraklama';
      case ErrorCategory.speedTooFast: // Güncellendi
        return 'Çok Hızlı Konuşma';
      case ErrorCategory.speedTooSlow: // Yeni
        return 'Çok Yavaş Konuşma';
      case ErrorCategory.perfect: // Yeni
        return 'Mükemmel Eşleşme';
      case ErrorCategory.unknown:
        return 'Bilinmeyen Hata';
    }
  }

  String getRecommendation() {
    switch (this) {
      case ErrorCategory.unnecessaryWords:
        return 'Konuşurken gereksiz "eee", "şey" gibi kelimeleri kullanmaktan kaçının. Daha akıcı ve öz bir ifade için düşüncelerinizi netleştirin.';
      case ErrorCategory.skipping:
        return 'Kelime veya hece atlamamak için her kelimeyi tam olarak telaffuz etmeye özen gösterin. Özellikle hızlı konuşurken kelimelerin sonlarını yutmamaya dikkat edin.';
      case ErrorCategory.stuttering:
        return 'Kekeleme veya tutukluluğu azaltmak için yavaş ve kontrollü konuşmayı deneyin. Konuşmaya başlamadan önce derin bir nefes almak yardımcı olabilir.';
      case ErrorCategory.mispronunciation: // Yeni
        return 'Yanlış telaffuz ettiğiniz kelimelerin doğru okunuşunu dinleyin ve bolca tekrar edin. Özellikle benzeşen seslere dikkat edin.';
      case ErrorCategory.wordSwap: // Yeni
        return 'Kelime değişimi hatalarını önlemek için cümlenin anlamına daha iyi odaklanın. Konuşmadan önce cümle yapısını zihninizde oluşturun.';
      case ErrorCategory.longPause: // Yeni
        return 'Cümleler arasında gereksiz uzun duraklamalardan kaçının. Akıcı bir konuşma için duraklamaları doğal nefes alma noktalarında kullanın.';
      case ErrorCategory.speedTooFast: // Güncellendi
        return 'Çok hızlı konuşmak anlaşılırlığı azaltabilir. Konuşma hızınızı yavaşlatın, her kelimeye yeterli zaman tanıyın ve dinleyicinin sizi takip etmesine izin verin.';
      case ErrorCategory.speedTooSlow: // Yeni
        return 'Çok yavaş konuşmak dinleyiciyi sıkabilir. Konuşma hızınızı artırmaya çalışın, ancak yine de her kelimenin anlaşılır olduğundan emin olun.';
      case ErrorCategory.perfect: // Yeni
        return 'Tebrikler! Mükemmel bir telaffuz. Pratiğe devam edin.';
      case ErrorCategory.unknown:
        return 'Bu hata türü belirlenemedi. Daha fazla pratik yaparak veya farklı metinler deneyerek telaffuzunuzu geliştirebilirsiniz.';
    }
  }

  Color toColor() {
    switch (this) {
      case ErrorCategory.unnecessaryWords:
        return Colors.purple;
      case ErrorCategory.skipping:
        return Colors.deepOrange;
      case ErrorCategory.stuttering:
        return Colors.brown;
      case ErrorCategory.mispronunciation: // Yeni
        return Colors.red;
      case ErrorCategory.wordSwap: // Yeni
        return Colors.pink;
      case ErrorCategory.longPause: // Yeni
        return Colors.blueGrey;
      case ErrorCategory.speedTooFast: // Güncellendi
        return Colors.indigo;
      case ErrorCategory.speedTooSlow: // Yeni
        return Colors.cyan;
      case ErrorCategory.perfect: // Yeni
        return Colors.green;
      case ErrorCategory.unknown:
        return Colors.grey;
    }
  }
}

class PronunciationError {
  final String originalText;
  final String spokenText;
  final String
  detectedFragment; // Hatanın tespit edildiği orijinal veya söylenen kısım
  final ErrorCategory category;
  final DateTime date;
  final String textTitle; // Hatanın hangi metinde yapıldığı

  PronunciationError({
    required this.originalText,
    required this.spokenText,
    required this.detectedFragment,
    required this.category,
    required this.date,
    required this.textTitle,
  });

  // JSON'a dönüştürme (kaydetmek için)
  Map<String, dynamic> toJson() => {
    'originalText': originalText,
    'spokenText': spokenText,
    'detectedFragment': detectedFragment,
    'category': category.toString(), // Enum'ı string olarak kaydet
    'date': date.toIso8601String(),
    'textTitle': textTitle,
  };

  // JSON'dan oluşturma (yüklemek için)
  factory PronunciationError.fromJson(Map<String, dynamic> json) {
    return PronunciationError(
      originalText: json['originalText'] as String,
      spokenText: json['spokenText'] as String,
      detectedFragment: json['detectedFragment'] as String,
      category: ErrorCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
        orElse: () => ErrorCategory.unknown,
      ),
      date: DateTime.parse(json['date'] as String),
      textTitle: json['textTitle'] as String,
    );
  }
}