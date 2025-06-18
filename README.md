# QR Sipariş Sistemi

Restoran yönetim sistemi için geliştirilmiş QR kod tabanlı sipariş çözümü.

## Proje Hakkında

Bu proje, restoran yönetim sistemine entegre QR kod sipariş sistemini içerir. Müşteriler QR kod ile sipariş verebilir ve siparişler garson onayından sonra mutfağa iletilir.

## Özellikler

* **Garson Onay Mekanizması**  
  Müşteri QR kod ile sipariş verdiğinde, sipariş önce garson onayına gider. Garson siparişi onayladıktan sonra mutfağa iletilir. Masa durumu "QR_waiting" (QR Onay Bekliyor) olarak işaretlenir.

* **Masa Durumları**  
  * QR_waiting: Garson onayı bekleyen QR siparişi  
  * QR_confirmed: Garson onaylı QR siparişi

* **Ek Sipariş Desteği**  
  Müşteri aynı masaya ek sipariş verebilir. Ek siparişler de garson onayına gider. Mutfak sadece yeni eklenen ürünleri görür.

* **Gerçek Zamanlı Bildirimler**  
  * Yeni QR siparişleri için bildirim ve ses uyarısı  
  * Sipariş durumu değişikliklerinde bildirim

## Kurulum

1. `app.js` dosyasını projenize entegre edin
2. Supabase veritabanında orders tablosuna is_confirmed alanı ekleyin:  
```
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

## Veritabanı Yapısı

Sistem aşağıdaki veritabanı tablolarını kullanır:

1. **orders** - Siparişlerin ana tablosu
   - id: UUID (Birincil anahtar)
   - table_number: Integer (Masa numarası)
   - status: String (Sipariş durumu)
   - source: String ('qr' veya 'waiter')
   - total_amount: Decimal (Toplam tutar)
   - is_confirmed: Boolean (Garson onayı)
   - created_at: Timestamp

2. **order_items** - Sipariş kalemleri
   - id: UUID (Birincil anahtar)
   - order_id: UUID (Siparişe referans)
   - menu_item_id: UUID (Menü öğesine referans)
   - name: String (Ürün adı)
   - price: Decimal (Ürün fiyatı)
   - quantity: Integer (Miktar)

3. **masalar** - Masa bilgileri
   - id: Integer (Birincil anahtar)
   - masa_no: Integer (Masa numarası)
   - durum: String (Masa durumu)
   - son_guncelleme: Timestamp

4. **waiter_calls** - Garson çağrıları
   - id: UUID (Birincil anahtar)
   - table_number: Integer (Masa numarası)
   - status: String ('waiting', 'responded', 'completed')
   - created_at: Timestamp

## Hata Giderme

401 hatası alınması durumunda:

* Supabase bağlantısını kontrol edin
* API anahtarının doğru olduğundan emin olun
* Veritabanı izinlerini kontrol edin

## Katkıda Bulunma

1. Bu depoyu fork edin
2. Özellik dalınızı oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add some amazing feature'`)
4. Dalınıza push edin (`git push origin feature/amazing-feature`)
5. Bir Pull Request açın

## Lisans

MIT Lisansı altında dağıtılmaktadır.

## İletişim

Proje Sahibi: [1sthillman](https://github.com/1sthillman)

Proje Linki: [https://github.com/1sthillman/waitermenuorqr](https://github.com/1sthillman/waitermenuorqr) 