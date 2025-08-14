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
![WhatsApp Image 2025-08-14 at 14 09 47 (3)](https://github.com/user-attachments/assets/0165216c-aa33-4f54-9c6a-ca2158f2e1cc),![WhatsApp Image 2025-08-14 at 14 09 47 (2)](https://github.com/user-attachments/assets/8c7e5079-0c05-4215-b4a1-280df1fc0b6c),![WhatsApp Image 2025-08-14 at 14 09 47 (1)](https://github.com/user-attachments/assets/dfd0a78a-0352-4aa6-bf6e-30e483b9b245),
Ana Ekran: Metin seçimi ve temel bilgiler,![WhatsApp Image 2025-08-14 at 14 09 47](https://github.com/user-attachments/assets/7c7bcd41-fd97-4466-8510-b6b6a1c0c8ee),Telaffuz Analizi: Gerçek zamanlı hata tespiti ve renk kodlu geri bildirim,![WhatsApp Image 2025-06-01 at 16 25 52 (2)](https://github.com/user-attachments/assets/34f9db4e-2069-4f33-87bb-401d6b8a4f85),Hata Raporu: Detaylı hata kategorizasyonu istatistikleri
,![WhatsApp Image 2025-08-14 at 14 16 56](https://github.com/user-attachments/assets/b01c1638-cbd8-4c97-8767-406adab73838)






