# Türkçe Telaffuz Eğitimi Mobil Uygulaması

Bu proje, Türkçe telaffuz becerilerini geliştirmek amacıyla geliştirilen bir mobil uygulamadır. Uygulama, doğal dil işleme (NLP) teknolojileri ve gerçek zamanlı ses analizi ile kullanıcıların konuşma hatalarını tespit ederek görsel geri bildirim sunar.

## Özellikler

- **Gerçek Zamanlı Ses Tanıma:** Vosk açık kaynak motoru ile offline çalışabilme.
- **Telaffuz Analizi:** Levenshtein mesafesi algoritması ile kelime benzerlik skoru hesaplama.
- **Hata Kategorizasyonu:** 9 farklı hata türüne göre detaylı analiz.
- **Kullanıcı Dostu Arayüz:** Flutter ile geliştirilen cross-platform mobil uygulama.
- **Görsel Geri Bildirim:** Renk kodlu (yeşil/turuncu/kırmızı) performans değerlendirmesi.

## Teknolojiler

- **Ses Tanıma:** Vosk (Türkçe küçük model)
- **NLP Algoritmaları:** Levenshtein mesafesi, özel hece analizi
- **Mobil Geliştirme:** Flutter, Dart
- **Ses İşleme:** Flutter TTS, Audio Players

## Kurulum

1. Projeyi klonlayın:
     git clone https://github.com/byrkemal/SpeechCoach.git
   
2. Gerekli bağımlılıkları yükleyin:
     flutter pub get
   
3. Vosk modelini indirip assets klasörüne ekleyin.
     Modeli resmi siteden indirin: [Vosk Modelleri](https://alphacephei.com/vosk/models)
   
5. Uygulamayı çalıştırın:
     flutter run

Ekran Görüntüleri   
![Uploading WhatsApp Image 2025-08-14 at 14.09.47 (3).jpeg…]()
