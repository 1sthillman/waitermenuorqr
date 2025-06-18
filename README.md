# QR Sipariş Sistemi

Restoran yönetim sistemi için geliştirilmiş QR kod tabanlı sipariş çözümü.

## Proje Hakkında

Bu proje, restoran yönetim sistemine entegre QR kod sipariş sistemini içerir. Müşteriler QR kod ile sipariş verebilir ve siparişler garson onayından sonra mutfağa iletilir.

## Özellikler

* **Garson Onay Mekanizması**  
  Müşteri QR kod ile sipariş verdiğinde, sipariş önce garson onayına gider. Garson siparişi onayladıktan sonra mutfağa iletilir. Masa durumu "QR_waiting" (QR Onay Bekliyor) olarak işaretlenir.

* **Masa Durumları**  
  - QR_waiting: Garson onayı bekleyen QR siparişi 
  - QR_confirmed: Garson onaylı QR siparişi

* **Ek Sipariş Desteği**  
  Müşteri aynı masaya ek sipariş verebilir. Ek siparişler de garson onayına gider. Mutfak sadece yeni eklenen ürünleri görür.

* **Gerçek Zamanlı Bildirimler**  
  - Yeni QR siparişleri için bildirim ve ses uyarısı
  - Sipariş durumu değişikliklerinde bildirim

## Kurulum

1. `app.js` dosyasını projenize entegre edin
2. Supabase veritabanında orders tablosuna is_confirmed alanı ekleyin:
   ```sql
   ALTER TABLE orders ADD COLUMN IF NOT EXISTS is_confirmed BOOLEAN DEFAULT false;
   ```
3. QR kod sistemini test edin

## Kullanım Akışı

1. Müşteri QR kod ile sipariş verir
2. Garson siparişi onaylar
3. Mutfak siparişi hazırlar
4. Garson siparişi teslim alır ve servis eder
5. Kasiyer ödeme alır
6. Masa boşalır

## Teknik Detaylar

QR sipariş sistemi aşağıdaki temel fonksiyonları içerir:

1. **handleQROrderChange** - QR siparişlerindeki değişiklikleri izler
2. **updateQROrderStatus** - QR sipariş durumunu günceller
3. **fetchQROrderDetails** - QR sipariş detaylarını getirir
4. **updateTableStatusFromQROrder** - Masa durumunu QR siparişine göre günceller
5. **confirmQROrder** - Garsonun QR siparişini onaylamasını sağlar

Bu sistem, RestaurantApp projesi için özel olarak geliştirilmiştir.

## Hata Giderme

401 hatası alınması durumunda:
- Supabase bağlantısını kontrol edin
- API anahtarının doğru olduğundan emin olun
- Veritabanı izinlerini kontrol edin

## Lisans

MIT Lisansı altında dağıtılmaktadır.

© 2023 QR Sipariş Sistemi 