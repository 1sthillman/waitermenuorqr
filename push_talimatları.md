# GitHub'a QR Sipariş Sistemini Push Etme Talimatları

GitHub'a QR sipariş sistemini push etmek için önce GitHub'da yeni bir repository oluşturmanız gerekiyor. Aşağıdaki adımları takip edin:

1. GitHub hesabınıza giriş yapın
2. Sağ üst köşede "+" işaretine tıklayın ve "New repository" seçin
3. Repository adını "RestaurantApp-QR" olarak girin
4. Açıklama ekleyin: "QR kod ile sipariş sistemi"
5. "Public" seçeneğini işaretleyin
6. "Create repository" butonuna tıklayın

Daha sonra, bu klasördeki dosyaları oluşturduğunuz repository'ye push etmek için aşağıdaki komutları kullanın:

```
git remote add origin https://github.com/KULLANICI_ADINIZ/RestaurantApp-QR.git
git push -u origin master
```

Not: "KULLANICI_ADINIZ" kısmını kendi GitHub kullanıcı adınızla değiştirin.

## Dosya İçerikleri

Bu pakette iki önemli dosya bulunmaktadır:

1. **app.js**: QR sipariş sisteminin tüm kodu
2. **README.md**: Sistemin özellikleri ve kullanımı hakkında bilgiler

Bu dosyaları ana projenize entegre etmek için app.js dosyasındaki QR sipariş ile ilgili fonksiyonları kendi app.js dosyanıza eklemeniz yeterlidir. 