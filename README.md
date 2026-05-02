# LibTMail - Mail Sunucu Yapılandırma Script'i

![License](https://img.shields.io/badge/License-TL%C4%B0%20v1.0-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20Docker-lightgrey.svg)
![Version](https://img.shields.io/badge/Version-2.0-green.svg)

LibTMail, Linux, Windows ve Docker için tam özellikli bir mail sunucusu kurulumunu otomatikleştiren kapsamlı bir script set'idir. Postfix, Dovecot, MariaDB, SpamAssassin, ClamAV, OpenDKIM ve Roundcube gibi bileşenleri tek komutla kurup yapılandırır.

## 📋 İçerik

- [Özellikler](#-özellikler)
- [Desteklenen Platformlar](#-desteklenen-platformlar)
- [Kurulum Yöntemleri](#-kurulum-yöntemleri)
  - [Linux Kurulumu](#-linux-kurulumu)
  - [Windows Kurulumu](#-windows-kurulumu)
  - [Docker Kurulumu](#-docker-kurulumu)
- [Hızlı Kurulum](#-hızlı-kurulum)
- [Yönetim Araçları](#-yönetim-araçları)
- [Test ve Doğrulama](#-test-ve-doğrulama)
- [Güvenlik Özellikleri](#-güvenlik-özellikleri)
- [Webmail Arayüzü](#-webmail-arayüzü)
- [DNS Yapılandırması](#-dns-yapılandırması)
- [Sorun Giderme](#-sorun-giderme)
- [Lisans](#-lisans)

## 🚀 Özellikler

### 📧 Mail Sunucu Bileşenleri
- **Postfix** - SMTP sunucusu (Linux) / **hMailServer** (Windows)
- **Dovecot** - IMAP/POP3 sunucusu (Linux) / **hMailServer** (Windows)
- **MariaDB/MySQL** - Veritabanı yönetimi
- **OpenDKIM** - DKIM imzalama
- **SpamAssassin** - Spam filtreleme
- **ClamAV** - Virüs tarama
- **Roundcube** - Webmail arayüzü

### � Platform Desteği
- **Linux** - Ubuntu/Debian/CentOS/RHEL/Fedora
- **Windows** - 7/8.1/10/11
- **Docker** - Konteyner deployment
- **Cross-platform** yönetim araçları

### �️ Güvenlik
- SSL/TLS şifreleme
- Spam filtreleme
- Virüs tarama
- DKIM imzalama
- Güvenlik duvarı yapılandırması
- Otomatik güvenlik güncellemeleri

### 🌐 Web Arayüzü
- **Roundcube** webmail
- Modern ve kullanıcı dostu arayüz
- Mobil uyumlu tasarım
- Çoklu dil desteği

### 🔧 Yönetim Araçları
- `mailadmin/mailadmin.bat` - Kullanıcı yönetimi
- `mailbackup/mailbackup.bat` - Otomatik yedekleme
- `mailmonitor/mailmonitor.bat` - Servis izleme
- `mailqueue/mailqueue.bat` - Posta kuyruğu yönetimi

### 🧪 Test ve Doğrulama
- `test.sh/test.bat` - Otomatik test script'leri
- `validate.sh/validate.bat` - Konfigürasyon doğrulama
- Detaylı raporlama ve loglama
- Hata tespiti ve öneriler

### 🚀 Hızlı Kurulum
- `install.sh/install.bat` - Tek komutla kurulum
- Otomatik bağımlılık yönetimi
- İnteraktif ve hızlı kurulum seçenekleri

## �️ Desteklenen Platformlar

### Linux
- **Dağıtımlar:** Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora 35+
- **Gereksinimler:** Root erişimi, 2GB+ RAM, 20GB+ disk

### Windows
- **Sürümler:** Windows 7, 8.1, 10, 11
- **Gereksinimler:** Administrator yetkisi, 2GB+ RAM, 20GB+ disk

### Docker
- **Platformlar:** Linux, Windows, macOS (Docker Desktop)
- **Gereksinimler:** Docker ve Docker Compose

## 📦 Kurulum Yöntemleri

### 🔥 Hızlı Kurulum (Tüm Platformlar)

#### Linux
```bash
curl -fsSL https://raw.githubusercontent.com/tda45/LibTMail/master/install.sh | sudo bash
```

#### Windows
```cmd
powershell -Command "iwr -Uri https://raw.githubusercontent.com/tda45/LibTMail/master/install.bat -OutFile install.bat; ./install.bat"
```

### � Manuel Kurulum

#### 1. Repository'yi klonlayın
```bash
git clone https://github.com/tda45/LibTMail.git
cd LibTMail
```

#### 2. Platformunuza göre kurulumu çalıştırın

**Linux:**
```bash
chmod +x install.sh
sudo ./install.sh
```

**Windows:**
```cmd
install.bat
```

**Docker:**
```bash
chmod +x docker.sh
./docker.sh start
```

## 🐳 Docker Kurulumu

### Hızlı Başlatma
```bash
# Environment dosyası oluştur
./docker.sh env

# Konteynerleri başlat
./docker.sh start
```

### Docker Yönetimi
```bash
./docker.sh status          # Durum göster
./docker.sh logs             # Logları göster
./docker.sh backup           # Yedekle
./docker.sh exec mailadmin list  # Komut çalıştır
./docker.sh stop             # Durdur
./docker.sh update           # Güncelle
```

### Docker Compose
```bash
# Manuel başlatma
docker-compose up -d

# Logları görüntüle
docker-compose logs -f

# Konteyner durumu
docker-compose ps
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

### mailadmin/mailadmin.bat - Kullanıcı Yönetimi
```bash
# Linux
mailadmin add kullanici@domain.com sifre123
mailadmin list
mailadmin password kullanici@domain.com yenisifre
mailadmin delete kullanici@domain.com

# Windows
mailadmin.bat add kullanici@domain.com sifre123
mailadmin.bat list
mailadmin.bat password kullanici@domain.com yenisifre
mailadmin.bat delete kullanici@domain.com
```

### mailbackup/mailbackup.bat - Yedekleme
```bash
# Linux
mailbackup

# Windows
mailbackup.bat

# Docker
./docker.sh exec mailbackup
```

### mailmonitor/mailmonitor.bat - İzleme
```bash
# Linux
mailmonitor

# Windows
mailmonitor.bat

# İzleme logları
tail -f /var/log/mailserver_monitor.log
```

### mailqueue/mailqueue.bat - Posta Kuyruğu
```bash
# Linux
mailqueue show
mailqueue flush
mailqueue deferred
mailqueue stats

# Windows
mailqueue.bat show
mailqueue.bat flush
mailqueue.bat deferred
mailqueue.bat stats
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

## 🧪 Test ve Doğrulama

### Otomatik Test
```bash
# Linux
./test.sh

# Windows
test.bat

# Docker
./docker.sh exec test.sh
```

### Konfigürasyon Doğrulama
```bash
# Linux
./validate.sh

# Windows
validate.bat

# Docker
./docker.sh exec validate.sh
```

### Test Seçenekleri
```bash
# Hızlı test
./test.sh --quick

# Sadece servisleri test et
./test.sh --services

# Sadece bağlantıyı test et
./test.sh --network

# Detaylı rapor
./test.sh -v
```

## 🌐 Webmail Arayüzü

### Roundcube Özellikleri
- Modern ve responsive arayüz
- Çoklu dil desteği (Türkçe dahil)
- E-posta klasör yönetimi
- Adres defteri
- Takvim desteği
- Dosya eki yönetimi

### Erişim Adresleri
- **Linux/Windows:** `http://mail.domain.com/webmail`
- **Docker:** `http://localhost:80` veya `http://localhost:443`

### Kurulum
Webmail kurulumu için:
1. Webmail adresine gidin
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
# Linux
cat /etc/opendkim/keys/domain.com/mail.txt

# Docker
./docker.sh exec cat /etc/opendkim/keys/domain.com/mail.txt
```

## 🔧 Sorun Giderme

### Otomatik Doğrulama
```bash
# Konfigürasyon doğrulama
./validate.sh          # Linux
validate.bat           # Windows

# Test çalıştırma
./test.sh              # Linux
test.bat               # Windows
```

### Servis Durumu Kontrolü
```bash
# Linux
systemctl status postfix dovecot mariadb spamassassin clamav-daemon opendkim apache2

# Windows
sc query hmailserver
sc query mysql

# Docker
./docker.sh status
docker-compose ps
```

### Port Durumu
```bash
# Linux/Windows
netstat -tlnp | grep -E ':(25|587|143|993|110|995|80|443)\s'

# Docker
./docker.sh exec netstat -tlnp | grep -E ':(25|587|143|993|110|995|80|443)\s'
```

### Log Dosyaları
```bash
# Linux
tail -f /var/log/mail.log
tail -f /var/log/dovecot.log
tail -f /var/log/spamassassin/spamd.log
tail -f /var/log/clamav/clamd.log
tail -f /var/log/apache2/error.log

# Windows
Get-Content -Wait C:\ProgramData\hMailServer\Logs\hMailServer.log
Get-Content -Wait C:\ProgramData\MySQL\MySQL Server 8.0\Data\*.err

# Docker
./docker.sh logs libtmail
docker-compose logs -f
```

### Yaygın Sorunlar

#### Postfix Başlamıyor
```bash
# Linux
postfix check
journalctl -u postfix

# Docker
./docker.sh exec postfix check
```

#### Dovecot Bağlantı Hatası
```bash
# Linux
doveconf -n
systemctl restart dovecot

# Docker
./docker.sh exec doveconf -n
./docker.sh restart
```

#### Webmail Erişim Sorunu
```bash
# Linux
systemctl status apache2
apache2ctl configtest

# Windows
sc query W3SVC

# Docker
curl -I http://localhost:80
```

#### Veritabanı Sorunları
```bash
# Linux
systemctl status mariadb
mysql -u root -p

# Windows
sc query mysql
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p

# Docker
./docker.sh exec mysql -u root -p mailserver
```

### Docker Özel Sorunları
```bash
# Konteyner yeniden başlatma
docker-compose restart

# Logları görüntüleme
docker-compose logs -f libtmail

# Konteyner içinde komut çalıştırma
docker-compose exec libtmail bash

# Temiz başlatma
docker-compose down -v
docker-compose up -d
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
