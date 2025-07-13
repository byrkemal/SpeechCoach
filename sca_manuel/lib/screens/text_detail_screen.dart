import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vosk_flutter_2/vosk_flutter_2.dart';
import 'package:sca_manuel/screens/pronunciation_error.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

double calculateLevenshteinSimilarity(String s1, String s2) {
  s1 = s1.toLowerCase().trim();
  s2 = s2.toLowerCase().trim();
  if (s1.isEmpty && s2.isEmpty) return 1.0;
  if (s1.isEmpty || s2.isEmpty) return 0.0;

  final int m = s1.length;
  final int n = s2.length;
  final List<List<int>> dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));

  for (int i = 0; i <= m; i++) dp[i][0] = i;
  for (int j = 0; j <= n; j++) dp[0][j] = j;

  for (int i = 1; i <= m; i++) {
    for (int j = 1; j <= n; j++) {
      int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  final int maxLength = m > n ? m : n;
  return 1.0 - (dp[m][n] / maxLength);
}

List<String> _splitIntoSyllables(String word) {
  if (word.isEmpty) return [];
  List<String> syllables = [];
  final vowels = 'aeıioöuüAEIİOÖUÜ';
  int start = 0;

  for (int i = 0; i < word.length; i++) {
    if (vowels.contains(word[i])) {
      // Eğer bir ünlü bulursak ve bu ünsüzden sonraki ilk ünlü değilse
      // veya kelimenin başından itibaren bir kısım birikmişse
      if (i > start && vowels.contains(word[i - 1]) && i + 1 < word.length && vowels.contains(word[i + 1])) {
        // İki ünlü yan yanaysa ve sonrası da ünlü ise (örneğin "saat" -> sa-at)
        syllables.add(word.substring(start, i)); // Önceki kısmı al
        start = i;
      } else if (i + 1 < word.length && !vowels.contains(word[i + 1])) {
        // Ünlüden sonra sessiz varsa
        if (i + 2 < word.length && !vowels.contains(word[i + 2])) {
          // Ünlü + sessiz + sessiz durumu (örneğin "gel-di")
          syllables.add(word.substring(start, i + 1));
          start = i + 1;
        } else {
          // Ünlü + sessiz durumu (örneğin "a-lı")
          syllables.add(word.substring(start, i + 1));
          start = i + 1;
        }
      } else if (i == word.length - 1) {
        // Son ünlü veya kelime sonu
        syllables.add(word.substring(start, i + 1));
        start = i + 1;
      }
    }
  }
  // Kalan kısmı ekle (eğer varsa, genellikle son hece olur)
  if (start < word.length) {
    syllables.add(word.substring(start));
  }
  return syllables.where((s) => s.isNotEmpty).toList();
}


class TextDetailScreen extends StatefulWidget {
  final String title;
  final String content;

  const TextDetailScreen({required this.title, required this.content, Key? key}) : super(key: key);

  @override
  State<TextDetailScreen> createState() => _TextDetailScreenState();
}

class _TextDetailScreenState extends State<TextDetailScreen> {
  final _vosk = VoskFlutterPlugin.instance();
  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  bool _modelIsLoading = true;
  bool _isListening = false;
  bool _isPlaying = false;
  bool _countdownActive = false;

  StreamSubscription<String>? _partialSubscription;
  StreamSubscription<String>? _resultSubscription;

  Completer<void>? _ttsCompleter;
  Completer<void>? _audioCompleter;

  List<String> _originalWords = [];
  List<String> _finalSpokenWords = [];
  String _currentPartialText = "";
  List<Map<String, dynamic>> _voskResultsWithTimestamps = [];

  List<TextSpan> _displaySpans = [];
  int _score = 0;
  bool _recordingFinished = false;

  final ScrollController _scrollController = ScrollController();

  int _countdownValue = 3;
  Timer? _countdownTimer;
  Timer? _recordingTimer;
  int _elapsedRecordingTime = 0;
  int _totalRecordingDuration = 0;

  @override
  void initState() {
    super.initState();
    // Noktalama işaretlerini kelimelerden ayırarak orijinal kelimeleri al
    // Türkçe karakterleri de koruyarak sadece harf ve rakam olmayanları temizle
    _originalWords = widget.content
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '') // Unicode destekli regex kullanıldı
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    _displaySpans = _buildInitialSpans(_originalWords);
    _initTTS();
    _initAudioPlayer();
    _initializeVosk();

    _totalRecordingDuration = (_originalWords.length * 0.75).ceil();
    if (_totalRecordingDuration < 10) _totalRecordingDuration = 10;
  }

  void _initTTS() {
    _flutterTts.setLanguage("tr-TR");
    _flutterTts.setSpeechRate(0.45);

    _flutterTts.setCompletionHandler(() {
      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        _ttsCompleter!.complete();
      }
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });

    _flutterTts.setCancelHandler(() {
      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        _ttsCompleter!.complete();
      }
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_audioCompleter != null && !_audioCompleter!.isCompleted) {
        _audioCompleter!.complete();
      }
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        if (_audioCompleter != null && !_audioCompleter!.isCompleted) {
          _audioCompleter!.complete();
        }
        if (mounted) {
          setState(() => _isPlaying = false);
        }
      }
    });
  }

  // Vosk modelini yükleme ve başlatma
  Future<void> _initializeVosk() async {
    try {
      final modelPath = await ModelLoader().loadFromAssets('assets/models/vosk-model-small-tr-0.3.zip');
      _model = await _vosk.createModel(modelPath);
      // recognizer için timecodes = true olarak ayarladık!
      _recognizer = await _vosk.createRecognizer(model: _model!, sampleRate: 16000);
      _speechService = await _vosk.initSpeechService(_recognizer!);
      _setupListeners();
    } catch (e) {
      print('Vosk model loading or initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ses tanıma motoru yüklenirken bir hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _modelIsLoading = false);
      }
    }
  }

  void _setupListeners() {
    _partialSubscription = _speechService!.onPartial().listen((result) {
      if (!_isListening || !mounted) return;
      final decoded = jsonDecode(result);
      final partialText = (decoded['partial'] as String?) ?? '';
      setState(() {
        _currentPartialText = partialText;
        _updateLiveTextHighlight();
      });
    }, onError: (error) {
      print('Vosk partial stream error: $error');
    });

    _resultSubscription = _speechService!.onResult().listen((result) {
      if (!_isListening || !mounted) return;
      final decoded = jsonDecode(result);
      final finalResultText = (decoded['text'] as String?) ?? '';
      if (finalResultText.isNotEmpty) {
        // Vosk'tan gelen her kelimenin zaman damgalarını kaydet
        if (decoded['result'] is List) {
          for (var wordInfo in decoded['result']) {
            if (wordInfo is Map<String, dynamic>) { // Type check for safety
              _voskResultsWithTimestamps.add(wordInfo);
              _finalSpokenWords.add(wordInfo['word'].toString());
            }
          }
        } else {
          // Eğer result list değilse, sadece metni ekle
          _finalSpokenWords.addAll(finalResultText.split(RegExp(r'\s+')).where((dynamic w) => w is String && w.isNotEmpty).cast<String>().toList());
        }

        setState(() {
          _currentPartialText = '';
          _updateLiveTextHighlight();
          _updateScrollPosition();
        });
      }
    }, onError: (error) {
      print('Vosk result stream error: $error');
    });
  }

  void _updateLiveTextHighlight() {
    if (_recordingFinished) return;

    List<TextSpan> spans = [];
    List<String> combinedLiveWords = List.from(_finalSpokenWords);

    final partialWords = _currentPartialText.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    combinedLiveWords.addAll(partialWords);

    int originalIdx = 0;
    int spokenIdx = 0;

    while (originalIdx < _originalWords.length && spokenIdx < combinedLiveWords.length) {
      final originalWord = _originalWords[originalIdx].toLowerCase();
      final spokenWord = combinedLiveWords[spokenIdx].toLowerCase();
      final similarity = calculateLevenshteinSimilarity(originalWord, spokenWord);

      if (similarity >= 0.75) { // İyi eşleşme
        spans.add(TextSpan(text: '${_originalWords[originalIdx]} ', style: const TextStyle(color: Colors.green)));
        originalIdx++;
        spokenIdx++;
      } else {
        // Kısmi veya yanlış eşleşme durumları
        spans.add(TextSpan(text: '${_originalWords[originalIdx]} ', style: const TextStyle(color: Colors.orange))); // Canlıda turuncu göster
        originalIdx++;
        spokenIdx++; // Hem orijinal hem de söylenen kelimeyi ilerletiyoruz
      }
    }

    // Kalan orijinal kelimeler (henüz okunmamış)
    while (originalIdx < _originalWords.length) {
      spans.add(TextSpan(text: '${_originalWords[originalIdx]} ', style: const TextStyle(color: Colors.black)));
      originalIdx++;
    }

    _displaySpans = spans;
  }

  List<TextSpan> _buildInitialSpans(List<String> words) {
    return words.map((w) => TextSpan(text: '$w ', style: const TextStyle(color: Colors.black))).toList();
  }

  void _updateScrollPosition() {
    if (!mounted || !_scrollController.hasClients) return;

    int estimatedProgressWords = _finalSpokenWords.length;
    estimatedProgressWords = estimatedProgressWords.clamp(0, _originalWords.length);

    const double wordHeightEstimate = 24.0; // Tahmini kelime yüksekliği
    const double wordsPerRowEstimate = 5.0; // Tahmini satırdaki kelime sayısı

    final int targetLine = (estimatedProgressWords / wordsPerRowEstimate).floor();
    final double targetOffset = targetLine * wordHeightEstimate;

    // Görünüm alanının yaklaşık %70'ini geçtikten sonra kaydır
    if (targetOffset > _scrollController.position.pixels + _scrollController.position.viewportDimension * 0.7) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startListening() async {
    if (_isListening || _isPlaying || _countdownActive) return;

    _finalSpokenWords.clear();
    _voskResultsWithTimestamps.clear(); // Zaman damgalı sonuçları da temizle
    _currentPartialText = '';
    _recordingFinished = false;
    _score = 0;
    _elapsedRecordingTime = 0;

    if (mounted) {
      setState(() {
        _displaySpans = _buildInitialSpans(_originalWords);
        _countdownValue = 3;
        _countdownActive = true;
      });
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_countdownValue > 1) {
        if (mounted) {
          setState(() {
            _countdownValue--;
          });
        }
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 50);
        }
      } else {
        _countdownTimer?.cancel();
        if (mounted) {
          setState(() {
            _countdownActive = false;
            _isListening = true;
          });
        }
        await _speechService?.start();

        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (mounted) {
            setState(() {
              _elapsedRecordingTime++;
            });
          }
          if (_elapsedRecordingTime >= _totalRecordingDuration) {
            await _stopListening();
          }
        });
      }
    });
  }

  Future<void> _stopListening() async {
    if (!_isListening && !_countdownActive) return;

    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _countdownActive = false;

    if (_isListening) {
      await _speechService?.stop();
    }

    if (mounted) {
      setState(() {
        _isListening = false;
        _recordingFinished = true;
        _currentPartialText = '';
      });
    }

    await _calculateFinalScoreAndErrors();
    if (mounted) {
      setState(() {
        _updateFinalDisplaySpans(); // UI'ı güncelleyecek setState'i çağırır
      });
    }
  }

  /// **Yeni ve Gelişmiş Hata Tespit Mantığı**
  /// Bu metot, orijinal ve konuşulan metinler arasındaki farkları analiz ederek
  /// telaffuz hatalarını tespit eder ve kategorize eder.
  Future<void> _calculateFinalScoreAndErrors() async {
    List<Color> finalColors = List.filled(_originalWords.length, Colors.black);
    List<PronunciationError> detectedErrors = [];
    int correctMatches = 0;

    // Vosk'tan gelen tüm kelimeleri (zaman damgalı veya damgasız) tek bir listede topla
    // Zaman damgası olanları tercih et, yoksa sadece metni kullanarak yapay bir yapı oluştur.
    List<Map<String, dynamic>> processedSpokenWords = [];
    if (_voskResultsWithTimestamps.isNotEmpty) {
      processedSpokenWords = _voskResultsWithTimestamps;
    } else {
      // Eğer zaman damgası yoksa, _finalSpokenWords'ü kullanarak yapay bir yapı oluştur
      double syntheticTime = 0.0;
      for (String word in _finalSpokenWords) {
        processedSpokenWords.add({
          'word': word,
          'start': syntheticTime,
          'end': syntheticTime + 0.5, // Varsayılan kelime süresi 0.5 saniye
          'conf': 1.0 // Varsayılan güven
        });
        syntheticTime += 0.5;
      }
    }

    int originalIdx = 0;
    int spokenIdx = 0;

    while (originalIdx < _originalWords.length) {
      final originalWord = _originalWords[originalIdx].toLowerCase();
      String spokenWord = '';
      double similarity = 0.0;

      // Önce doğrudan eşleşme ara
      if (spokenIdx < processedSpokenWords.length) {
        spokenWord = processedSpokenWords[spokenIdx]['word'].toString().toLowerCase();
        similarity = calculateLevenshteinSimilarity(originalWord, spokenWord);
      }

      if (similarity >= 0.75) {
        // Mükemmel/Çok İyi Eşleşme
        finalColors[originalIdx] = Colors.green;
        correctMatches++;
        originalIdx++;
        spokenIdx++;
      } else {
        // Eşleşme yok veya yetersiz: İleriye doğru bak ve en iyi eşleşmeyi bul
        int bestMatchSpokenIdx = -1;
        double maxSimilarity = 0.0;
        bool foundMatchInLookahead = false;
        String bestSpokenWordInLookahead = ''; // En iyi eşleşen söylenen kelimeyi tutmak için

        // İleriye dönük küçük bir pencereye bak (örn: 3-5 kelime)
        for (int i = spokenIdx; i < (spokenIdx + 5).clamp(0, processedSpokenWords.length); i++) {
          final currentSpokenWord = processedSpokenWords[i]['word'].toString().toLowerCase();
          final currentSimilarity = calculateLevenshteinSimilarity(originalWord, currentSpokenWord);
          if (currentSimilarity > maxSimilarity) {
            maxSimilarity = currentSimilarity;
            bestMatchSpokenIdx = i;
            bestSpokenWordInLookahead = currentSpokenWord; // En iyi eşleşen kelimeyi kaydet
          }
          if (currentSimilarity >= 0.75) { // Yüksek benzerlik varsa hemen al
            foundMatchInLookahead = true;
            break;
          }
        }

        if (foundMatchInLookahead) {
          // İleride iyi bir eşleşme bulunduysa, aradaki kelimeler atlanmış veya gereksiz olabilir.
          // Atlanan orijinal metindeki kelimeleri işaretle ve hata olarak kaydet.
          for (int i = originalIdx; i < originalIdx + (bestMatchSpokenIdx - spokenIdx) && i < _originalWords.length; i++) {
            finalColors[i] = Colors.red; // Orijinal kelime atlandı
            detectedErrors.add(
              PronunciationError(
                originalText: _originalWords[i],
                spokenText: '', // Bu kelime için karşılık gelen bir şey söylenmedi
                detectedFragment: '',
                category: ErrorCategory.skipping,
                date: DateTime.now(),
                textTitle: widget.title,
              ),
            );
          }
          originalIdx += (bestMatchSpokenIdx - spokenIdx); // Orijinal dizini zıplat

          if (originalIdx < _originalWords.length) { // Orijinal kelime listesinin sonuna gelmediysek
            // Bulunan iyi eşleşmeyi kaydet
            finalColors[originalIdx] = Colors.green; // Eşleştiği için yeşil
            correctMatches++;
            originalIdx++;
            spokenIdx = bestMatchSpokenIdx + 1; // Spoken index'i zıplat
          } else {
            spokenIdx = bestMatchSpokenIdx + 1; // Orijinal kelime listesi bittiyse sadece spoken index'i ilerlet
          }

        } else if (maxSimilarity >= 0.35) { // Kısmi eşleşme bulundu (ama yeterince iyi değil)
          finalColors[originalIdx] = Colors.orange; // Kısmi eşleşme turuncu
          detectedErrors.add(
            PronunciationError(
              originalText: _originalWords[originalIdx],
              spokenText: bestSpokenWordInLookahead, // Kullanıcının söylediği kelime
              detectedFragment: bestSpokenWordInLookahead,
              category: _analyzeErrorCategory(
                _originalWords[originalIdx],
                bestSpokenWordInLookahead,
                (bestMatchSpokenIdx != -1) ? processedSpokenWords[bestMatchSpokenIdx]['start'] as double? ?? 0.0 : 0.0,
                (bestMatchSpokenIdx != -1) ? processedSpokenWords[bestMatchSpokenIdx]['end'] as double? ?? 0.0 : 0.0,
                (bestMatchSpokenIdx != -1) ? processedSpokenWords[bestMatchSpokenIdx]['conf'] as double? ?? 0.0 : 0.0,
              ),
              date: DateTime.now(),
              textTitle: widget.title,
            ),
          );
          originalIdx++;
          if (bestMatchSpokenIdx != -1) {
            spokenIdx = bestMatchSpokenIdx + 1;
          } else {
            spokenIdx++; // Eğer eşleşme yoksa bile konuşulan kelimeyi ilerlet
          }
        } else {
          // Hiç eşleşme bulunamadı veya çok düşük benzerlik (tamamen atlandı)
          finalColors[originalIdx] = Colors.red;
          detectedErrors.add(
            PronunciationError(
              originalText: _originalWords[originalIdx],
              spokenText: bestSpokenWordInLookahead, // Eğer boşsa boş, eğer denenen bir şey varsa o
              detectedFragment: bestSpokenWordInLookahead,
              category: ErrorCategory.skipping,
              date: DateTime.now(),
              textTitle: widget.title,
            ),
          );
          originalIdx++;
          // spokenIdx ilerlemiyor, çünkü bu orijinal kelimeye karşılık gelen bir konuşulan kelime bulunamadı
        }
      }
    }

    // Konuşulan metinde kalan kelimeler (gereksiz kelimeler veya yanlış kelime olabilir)
    // Bu kısım, originalIdx döngüsü bittikten sonra fazlalık kelimeleri işler.
    while (spokenIdx < processedSpokenWords.length) {
      final extraWord = processedSpokenWords[spokenIdx]['word'].toString();
      detectedErrors.add(
        PronunciationError(
          originalText: '', // Orijinal metinde karşılığı yok
          spokenText: extraWord,
          detectedFragment: extraWord,
          category: _analyzeErrorCategory(
            '', // Orijinal kelime boş olduğu için bu durum özel olarak ele alınır
            extraWord,
            processedSpokenWords[spokenIdx]['start'] as double? ?? 0.0,
            processedSpokenWords[spokenIdx]['end'] as double? ?? 0.0,
            processedSpokenWords[spokenIdx]['conf'] as double? ?? 0.0,
          ),
          date: DateTime.now(),
          textTitle: widget.title,
        ),
      );
      spokenIdx++;
    }

    _score = (_originalWords.isEmpty) ? 0 : (correctMatches / _originalWords.length * 100).round();

    await _saveScore(_score);
    await _savePronunciationErrors(detectedErrors);

    // Final renkleri uygulayarak _displaySpans'ı güncelle
    _displaySpans = List.generate(_originalWords.length, (index) {
      return TextSpan(text: '${_originalWords[index]} ', style: TextStyle(color: finalColors[index]));
    });
  }

  /// **Yeni ve Gelişmiş Hata Kategorisi Analizi**
  /// Bu metod, tek bir kelimenin orijinal ve söylenen versiyonları arasındaki farkı analiz ederek
  /// en uygun hata kategorisini belirler.
  ErrorCategory _analyzeErrorCategory(
      String originalWord,
      String spokenWord,
      double startTime,
      double endTime,
      double confidence,
      ) {
    originalWord = originalWord.toLowerCase().trim();
    spokenWord = spokenWord.toLowerCase().trim();

    // 1. Gereksiz Kelime Kullanımı (Orijinal kelime boşsa veya düşük güvenle anlaşılan kelime)
    final fillerWords = ['eee', 'aaa', 'ııı', 'hımm', 'şey', 'yani', 'evet', 'aslında', 'hı', 'ı', 'bir', 'de', 'ya', 'hani', 'mi', 'mı'];
    if (originalWord.isEmpty) { // Orijinalde karşılığı olmayan kelime
      if (fillerWords.contains(spokenWord) || confidence < 0.5) { // Düşük güvenli kelimeler de gereksiz olabilir
        return ErrorCategory.unnecessaryWords;
      }
      // Orijinalde karşılığı yok ama "filler" değilse ve güven yüksekse, bu bir "kelime değişimi" olabilir
      return ErrorCategory.unnecessaryWords; // Varsayılan olarak gereksiz kelime
    }

    final similarity = calculateLevenshteinSimilarity(originalWord, spokenWord);

    // 2. Mükemmel Eşleşme (Çok yüksek benzerlik)
    if (similarity >= 0.95) {
      return ErrorCategory.perfect;
    }

    // 3. Atlama / Hece Yutma
    // Orijinal kelime daha uzun, konuşulan kelime kısa ve benzerlik düşük.
    // Basit hece analizi ile de desteklenebilir.
    if (originalWord.length > spokenWord.length + 1 && similarity < 0.70) {
      List<String> originalSyllables = _splitIntoSyllables(originalWord);
      List<String> spokenSyllables = _splitIntoSyllables(spokenWord);
      // Eğer hece sayısı önemli ölçüde farklıysa (örneğin 2 veya daha fazla hece atlandıysa)
      if (originalSyllables.length - spokenSyllables.length >= 1 && similarity < 0.75) {
        return ErrorCategory.skipping;
      }
      return ErrorCategory.skipping; // Genel olarak kelimenin atlandığı veya büyük bir kısmının yutulduğu durumlar
    }
    // Eğer konuşulan kelime tamamen boşsa ve orijinal kelime var ise bu da atlama
    if (spokenWord.isEmpty && originalWord.isNotEmpty) {
      return ErrorCategory.skipping;
    }


    // 4. Kekeleme / Tutukluk
    // Konuşulan kelime orijinalin bir kısmını tekrar ediyor mu?
    // Örn: original="koşmak", spoken="ko koşmak" veya "ko-koşmak"
    if (spokenWord.length > originalWord.length && similarity < 0.90) {
      // Eğer konuşulan kelime orijinal kelimeyi birden fazla içeriyorsa veya benzer ön ek tekrarı varsa
      if (spokenWord.contains(originalWord + originalWord) || spokenWord.startsWith('${originalWord.substring(0, (originalWord.length / 2).ceil())}-${originalWord.substring(0, (originalWord.length / 2).ceil())}')) {
        return ErrorCategory.stuttering;
      }
    }

    // 5. Yanlış Telaffuz
    // Benzerlik orta düzeyde ancak yeterince yüksek değil. Kelimenin tanındığı ama yanlış telaffuz edildiği durumlar.
    // Sesletim hataları (s/ş, c/ç, g/ğ vb.) bu kategoriye girer.
    if (similarity >= 0.35 && similarity < 0.75) {
      return ErrorCategory.mispronunciation;
    }

    // 6. Kelime Değişimi / Hatalı Kelime
    // Eğer similarity çok düşükse (0.35 altı) ve orijinal kelime boş değilse,
    // ve yukarıdaki kategorilere girmiyorsa, bu tamamen farklı bir kelime olabilir.
    if (similarity < 0.35 && originalWord.isNotEmpty) {
      return ErrorCategory.wordSwap;
    }


    // 7. Uzun Duraklama (Zaman damgaları gerektirir)
    // Kelimenin konuşma süresi normalden çok uzunsa.
    final wordDuration = endTime - startTime; // saniye cinsinden
    // Ortalama kelime süresi 0.4-0.6 saniye arası kabul edilebilir.
    if (wordDuration > 1.2 && confidence > 0.7) { // 1.2 saniyeden uzunsa ve güven yüksekse
      return ErrorCategory.longPause;
    }


    // 8. Çok Hızlı/Yavaş Konuşma (Zaman damgaları gerektirir)
    // Kelime süresi normalden çok kısa ise hızlı konuşma.
    if (wordDuration < 0.2 && confidence > 0.7) { // Çok kısa ve yüksek güvenliyse
      return ErrorCategory.speedTooFast;
    }
    // Kelime süresi normalden çok uzun ise yavaş konuşma (uzun duraklama değilse).
    if (wordDuration > 0.8 && confidence > 0.7 && wordDuration <= 1.2) { // 0.8 ile 1.2 saniye arası ise
      return ErrorCategory.speedTooSlow;
    }


    return ErrorCategory.unknown; // Hiçbir kategoriye uymuyorsa
  }

  void _updateFinalDisplaySpans() {
    setState(() {});
  }

  Future<void> _saveScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('score_${widget.title.replaceAll(' ', '_')}', score);
  }

  Future<void> _savePronunciationErrors(List<PronunciationError> errors) async {
    if (errors.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> existingErrorsJson = prefs.getStringList('pronunciation_errors') ?? [];
    List<PronunciationError> existingErrors = existingErrorsJson
        .map((e) => PronunciationError.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();

    existingErrors.addAll(errors);

    List<String> updatedErrorsJson = existingErrors.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('pronunciation_errors', updatedErrorsJson);
  }

  /// Ses dosyası adını metin başlığından türetme.
  /// Örneğin "Metin 1" -> "1.mp3"
  String _getAudioFileNameFromTitle() {
    final RegExp regex = RegExp(r'Metin(\d+)');
    final match = regex.firstMatch(widget.title);
    if (match != null && match.groupCount > 0) {
      return '${match.group(1)}.mp3';
    }
    return '';
  }

  Future<bool> _audioFileExists(String audioFileName) async {
    if (audioFileName.isEmpty) {
      return false;
    }
    final String assetPath = 'assets/audio/$audioFileName';
    try {
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (e) {
      print('Audio file not found or inaccessible: $assetPath');
      return false;
    }
  }

  Future<void> _playTTS() async {
    if (!mounted || _isPlaying) return;

    setState(() => _isPlaying = true);

    final String audioFileName = _getAudioFileNameFromTitle();
    final bool fileExists = await _audioFileExists(audioFileName);

    if (fileExists) {
      _audioCompleter = Completer<void>();
      print('Playing audio from asset: assets/audio/$audioFileName');
      try {
        await _audioPlayer.play(AssetSource('audio/$audioFileName'));
        await _audioCompleter!.future;
      } catch (e) {
        print('Error playing audio asset: $e');
        setState(() => _isPlaying = false);
        await _flutterTts.setSpeechRate(0.45);
        await _flutterTts.speak(widget.content);
      }
    } else {
      _ttsCompleter = Completer<void>();
      print('Audio file not found for "$audioFileName". Using TTS.');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.speak(widget.content);
      await _ttsCompleter!.future;
    }

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _stopTTS() async {
    if (!mounted || !_isPlaying) return;

    await _flutterTts.stop();
    await _audioPlayer.stop();

    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      _ttsCompleter!.complete();
    }
    if (_audioCompleter != null && !_audioCompleter!.isCompleted) {
      _audioCompleter!.complete();
    }

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _partialSubscription?.cancel();
    _resultSubscription?.cancel();
    _speechService?.dispose();
    _flutterTts.stop();
    _audioPlayer.dispose();
    _scrollController.dispose();
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _modelIsLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_countdownActive)
              Text(
                '$_countdownValue...',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            SizedBox(height: _countdownActive ? 16 : 0),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: RichText(
                  text: TextSpan(
                    children: _displaySpans,
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_recordingFinished)
              Text('Skor: %$_score', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_isListening && _totalRecordingDuration > 0)
              LinearProgressIndicator(
                value: _elapsedRecordingTime / _totalRecordingDuration,
                backgroundColor: Colors.grey[300],
                color: Colors.blueAccent,
                minHeight: 10,
              ),
            if (_isListening && _totalRecordingDuration > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Kalan Süre: ${(_totalRecordingDuration - _elapsedRecordingTime).clamp(0, _totalRecordingDuration)} sn',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening || _countdownActive
                        ? null
                        : (_isPlaying ? _stopTTS : _playTTS),
                    icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
                    label: Text(_isPlaying ? "Dinlemeyi Durdur" : "Metni Dinle"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isListening || _countdownActive ? _stopListening : _startListening,
                    icon: Icon(_isListening || _countdownActive ? Icons.stop : Icons.mic),
                    label: Text(_isListening || _countdownActive ? "Durdur" : "Kaydet"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}