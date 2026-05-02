# LibTMail - Linux Mail Sunucu Yapılandırma Script'i

![License](https://img.shields.io/badge/License-TL%C4%B0%20v1.0-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey.svg)
![Version](https://img.shields.io/badge/Version-1.0-green.svg)

LibTMail, Linux sistemler için tam özellikli bir mail sunucusu kurulumunu otomatikleştiren kapsamlı bir shell script'idir. Postfix, Dovecot, MariaDB ve daha birçok bileşeni tek komutla kurup yapılandırır.

## 📋 İçerik

- [Özellikler](#-özellikler)
- [Sistem Gereksinimleri](#-sistem-gereksinimleri)
- [Desteklenen Dağıtımlar](#-desteklenen-dağıtımlar)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Yapılandırma](#-yapılandırma)
- [Yönetim Araçları](#-yönetim-araçları)
- [Güvenlik Özellikleri](#-güvenlik-özellikleri)
- [Webmail Arayüzü](#-webmail-arayüzü)
- [DNS Yapılandırması](#-dns-yapılandırması)
- [Sorun Giderme](#-sorun-giderme)
- [Lisans](#-lisans)

## 🚀 Özellikler

### 📧 Mail Sunucu Bileşenleri
- **Postfix** - SMTP sunucusu
- **Dovecot** - IMAP/POP3 sunucusu
- **MariaDB** - Veritabanı yönetimi
- **OpenDKIM** - DKIM imzalama
- **SpamAssassin** - Spam filtreleme
- **ClamAV** - Virüs tarama

### 🛡️ Güvenlik
- SSL/TLS şifreleme
- Spam filtreleme
- Virüs tarama
- DKIM imzalama
- Güvenlik duvarı yapılandırması

### 🌐 Web Arayüzü
- **Roundcube** webmail
- Modern ve kullanıcı dostu arayüz
- Mobil uyumlu tasarım

### 🔧 Yönetim Araçları
- `mailadmin` - Kullanıcı yönetimi
- `mailbackup` - Otomatik yedekleme
- `mailmonitor` - Servis izleme
- `mailqueue` - Posta kuyruğu yönetimi

## 💻 Sistem Gereksinimleri

- **İşletim Sistemi:** Linux (Ubuntu/Debian/CentOS/RHEL/Fedora)
- **RAM:** Minimum 2GB, tavsiye edilen 4GB+
- **Disk Alanı:** Minimum 20GB boş alan
- **Ağ:** Statik IP adresi
- **Root Erişimi:** Administrator yetkileri

## 🐧 Desteklenen Dağıtımlar

- **Ubuntu** 18.04, 20.04, 22.04+
- **Debian** 9, 10, 11+
- **CentOS** 7, 8, 9
- **RHEL** 7, 8, 9
- **Fedora** 35, 36, 37+

## 📦 Kurulum

### 1. Script'i İndirin
```bash
git clone https://github.com/tda45/LibTMail.git
cd LibTMail
```

### 2. Script'i Çalıştırın
```bash
chmod +x config.sh
sudo ./config.sh
```

### 3. Kurulum Parametreleri
Script size aşağıdaki bilgileri soracaktır:
- **Domain Adı:** example.com
- **Hostname:** mail (varsayılan)
- **Admin E-posta:** admin@example.com

## 🎯 Kullanım

### Kurulum Sonrası
Kurulum tamamlandığında script size aşağıdaki bilgileri verecektir:
- Admin kullanıcı şifresi
- MySQL veritabanı şifreleri
- DKIM DNS kayıtları
- Servis durumları

### Webmail Erişimi
```
http://mail.domain.com/webmail
```

## ⚙️ Yapılandırma

### Temel Portlar
| Port | Servis | Açıklama |
|------|--------|----------|
| 25   | SMTP | Gelen/giden e-posta |
| 587  | SMTP | E-posta gönderimi |
| 143  | IMAP | E-posta okuma |
| 993  | IMAPS | Güvenli e-posta okuma |
| 110  | POP3 | E-posta indirme |
| 995  | POP3S | Güvenli e-posta indirme |
| 80   | HTTP | Webmail arayüzü |
| 443  | HTTPS | Güvenli webmail |

### Önemli Dosyalar
```
/etc/postfix/main.cf          - Postfix yapılandırması
/etc/dovecot/dovecot.conf     - Dovecot yapılandırması
/etc/opendkim.conf            - OpenDKIM yapılandırması
/etc/spamassassin/local.cf    - SpamAssassin ayarları
/etc/clamav/clamd.conf         - ClamAV ayarları
/var/vmail/                   - E-posta depolama alanı
```

## 🔧 Yönetim Araçları

### mailadmin - Kullanıcı Yönetimi
```bash
# Kullanıcı ekle
mailadmin add kullanici@domain.com sifre123

# Kullanıcıları listele
mailadmin list

# Şifre değiştir
mailadmin password kullanici@domain.com yenisifre

# Kullanıcı sil
mailadmin delete kullanici@domain.com
```

### mailbackup - Yedekleme
```bash
# Manuel yedekleme
mailbackup

# Otomatik yedekleme (her gün 02:00)
# Cron job otomatik olarak ayarlanır
```

### mailmonitor - İzleme
```bash
# Servis durumunu kontrol et
mailmonitor

# İzleme logları
tail -f /var/log/mailserver_monitor.log
```

### mailqueue - Posta Kuyruğu
```bash
# Kuyruğu göster
mailqueue show

# Kuyruğu temizle
mailqueue flush

# Bekleyen mesajları sil
mailqueue deferred

# İstatistikler
mailqueue stats
```

## 🛡️ Güvenlik Özellikleri

### Spam Filtreleme
- **SpamAssassin** ile akıllı spam tespiti
- Otomatik öğrenme ve güncelleme
- Bayes filtreleme
- SPF/DKIM doğrulama

### Virüs Tarama
- **ClamAV** ile gerçek zamanlı virüs tarama
- Otomatik veritabanı güncellemeleri
- Karantina sistemi

### E-posta İmzalama
- **OpenDKIM** ile DKIM imzalama
- Alan adı doğrulaması
- Teslimat oranı artışı

### SSL/TLS
- Otomatik SSL sertifikası oluşturma
- Güvenli bağlantı zorunluluğu
- Şifreli iletişim

## 🌐 Webmail Arayüzü

### Roundcube Özellikleri
- Modern ve responsive arayüz
- Çoklu dil desteği (Türkçe dahil)
- E-posta klasör yönetimi
- Adres defteri
- Takvim desteği
- Dosya eki yönetimi

### Kurulum
Webmail kurulumu için:
1. `http://mail.domain.com/webmail/installer` adresine gidin
2. Veritabanı bilgilerini girin
3. Kurulumu tamamlayın
4. Installer klasörünü silin

## 🌍 DNS Yapılandırması

### Gerekli DNS Kayıtları
```
; MX Kaydı
@    IN    MX    10    mail.domain.com.

; A Kaydı
mail IN    A     SUNUCU_IP_ADRESI

; SPF Kaydı
@    IN    TXT   "v=spf1 mx -all"

; DKIM Kaydı (script çıktısından kopyalayın)
mail._domainkey IN    TXT   "v=DKIM1; k=rsa; p=PUBLIC_KEY"

; DMARC Kaydı
_dmarc IN    TXT   "v=DMARC1; p=quarantine; rua=mailto:dmarc@domain.com"
```

### DKIM Anahtarı
Script kurulumu sırasında DKIM anahtarınızı oluşturur. DNS kaydı için:
```bash
cat /etc/opendkim/keys/domain.com/mail.txt
```

## 🔧 Sorun Giderme

### Servis Durumu Kontrolü
```bash
# Tüm servislerin durumu
systemctl status postfix dovecot mariadb spamassassin clamav-daemon opendkim apache2

# Port durumu
netstat -tlnp | grep -E ':(25|587|143|993|110|995|80|443)\s'
```

### Log Dosyaları
```bash
# Postfix logları
tail -f /var/log/mail.log

# Dovecot logları
tail -f /var/log/dovecot.log

# SpamAssassin logları
tail -f /var/log/spamassassin/spamd.log

# ClamAV logları
tail -f /var/log/clamav/clamd.log

# Apache logları
tail -f /var/log/apache2/error.log
```

### Yaygın Sorunlar

#### Postfix Başlamıyor
```bash
# Yapılandırma kontrolü
postfix check

# Hataları göster
journalctl -u postfix
```

#### Dovecot Bağlantı Hatası
```bash
# Yapılandırma kontrolü
doveconf -n

# Servis yeniden başlat
systemctl restart dovecot
```

#### Webmail Erişim Sorunu
```bash
# Apache durumunu kontrol et
systemctl status apache2

# Apache yapılandırmasını kontrol et
apache2ctl configtest
```

### Veritabanı Sorunları
```bash
# MariaDB durumunu kontrol et
systemctl status mariadb

# Veritabanına bağlan
mysql -u mailuser -p mailserver
```

## 📈 Performans Optimizasyonu

### Postfix Optimizasyonu
```bash
# /etc/postfix/main.cf dosyasına ekleyin
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 100
```

### Dovecot Optimizasyonu
```bash
# /etc/dovecot/dovecot.conf dosyasına ekleyin
mail_max_userip_connections = 10
process_limit = 100
```

### Veritabanı Optimizasyonu
```bash
# MariaDB yapılandırması
mysql -u root -p -e "OPTIMIZE TABLE mailserver.users;"
```

## 🔄 Yedekleme ve Geri Yükleme

### Manuel Yedekleme
```bash
# Tam yedekleme
mailbackup

# Veritabanı yedekleme
mysqldump --single-transaction mailserver > mailserver_backup.sql

# E-posta verilerini yedekleme
tar -czf vmail_backup.tar.gz /var/vmail
```

### Geri Yükleme
```bash
# Veritabanı geri yükleme
mysql mailserver < mailserver_backup.sql

# E-posta verilerini geri yükleme
tar -xzf vmail_backup.tar.gz -C /
```

## 📊 İzleme ve Raporlama

### Servis İzleme
```bash
# Servis durumu
mailmonitor

# Disk kullanımı
df -h /var/vmail

# Posta kuyruğu durumu
mailqueue stats
```

### Log Analizi
```bash
# Spam istatistikleri
grep "Spam detected" /var/log/mail.log | wc -l

# Virüs tarama sonuçları
grep "FOUND" /var/log/clamav/clamd.log

# Giden/gelen e-posta sayısı
grep -c "from=" /var/log/mail.log
```

## 🔐 Güvenlik İpuçları

### Güçlü Şifreler
- En az 12 karakter
- Büyük/küçük harf, sayı ve özel karakter
- Düzenli şifre değişimi

### Güvenlik Duvarı
```bash
# Sadece gerekli portları açık tutun
ufw allow 25/tcp
ufw allow 587/tcp
ufw allow 143/tcp
ufw allow 993/tcp
ufw allow 80/tcp
ufw allow 443/tcp
```

### Fail2Ban Kurulumu
```bash
# Brute force koruması
apt install fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban
```

## 🚨 Güncellemeler

### Sistem Güncellemeleri
```bash
# Paketleri güncelle
apt update && apt upgrade -y

# Virüs veritabanını güncelle
freshclam

# Spam kurallarını güncelle
sa-update
```

### Script Güncellemeleri
```bash
# En son sürümü çek
git pull origin master

# Değişiklikleri kontrol et
git log --oneline -5
```

## 🤝 Katkıda Bulunma

### Hata Bildirimi
- GitHub Issues üzerinden bildirin
- Detaylı bilgi ve log dosyaları ekleyin
- Sistem bilgilerini belirtin

### Özellik İstekleri
- GitHub Discussions kullanın
- Kullanım senaryolarını açıklayın
- Öncelik belirleyin

### Geliştirme
1. Fork yapın
2. Feature branch oluşturun
3. Değişiklikleri yapın
4. Pull request gönderin

## 📞 Destek

### Resmi Kanallar
- **GitHub:** https://github.com/tda45/LibTMail
- **Issues:** https://github.com/tda45/LibTMail/issues
- **Discussions:** https://github.com/tda45/LibTMail/discussions

### Topluluk
- Forum ve tartışma grupları
- Sosyal medya hesapları
- Teknik blog yazıları

## 📄 Lisans

Bu proje **TLİ (Türk Lisans İmzası) v1.0** ile lisanslanmıştır.

### Önemli Maddeler:
- ✅ **Ücretsiz kullanım:** Hiçbir koşulda ücretli satılamaz
- ✅ **Açık kaynak:** Kaynak kodu serbestçe kullanılabilir
- ✅ **Modifikasyon:** Geliştirme yapılabilir
- ❌ **Ticari kullanım:** Satış, kiralama veya IAP yasak
- ❌ **Zararlı yazılım:** Malware eklenemez

Detaylı bilgi için [LICENSE](LICENSE) dosyasını inceleyin.

## 🙏 Teşekkürler

Bu script'in geliştirilmesine katkı sağlayan tüm topluluk üyelerine teşekkür ederiz.

### Kullanılan Projeler
- [Postfix](http://www.postfix.org/) - SMTP sunucusu
- [Dovecot](https://www.dovecot.org/) - IMAP/POP3 sunucusu
- [MariaDB](https://mariadb.org/) - Veritabanı
- [Roundcube](https://roundcube.net/) - Webmail
- [SpamAssassin](https://spamassassin.apache.org/) - Spam filtreleme
- [ClamAV](https://www.clamav.net/) - Virüs tarama
- [OpenDKIM](http://www.opendkim.org/) - DKIM imzalama

---

**⚡ Hızlı Kurulum:** `git clone https://github.com/tda45/LibTMail.git && cd LibTMail && chmod +x config.sh && sudo ./config.sh`

**📧 E-posta:** tahadikbas45@gmail.com
**🌐 Web:** https://github.com/tda45/LibTMail  
**📜 Lisans:** TLİ v1.0
