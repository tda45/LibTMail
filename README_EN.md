# LibTMail - Mail Server Configuration Scripts

![License](https://img.shields.io/badge/License-TL%C4%B0%20v1.0-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20Docker-lightgrey.svg)
![Version](https://img.shields.io/badge/Version-2.0-green.svg)

LibTMail is a comprehensive script set for automated mail server installation and configuration on Linux, Windows, and Docker. It installs and configures Postfix, Dovecot, MariaDB, SpamAssassin, ClamAV, OpenDKIM, and Roundcube with a single command.

## 📋 Table of Contents

- [Features](#-features)
- [Supported Platforms](#-supported-platforms)
- [Installation Methods](#-installation-methods)
  - [Linux Installation](#-linux-installation)
  - [Windows Installation](#-windows-installation)
  - [Docker Installation](#-docker-installation)
- [Quick Start](#-quick-start)
- [Management Tools](#-management-tools)
- [Testing and Validation](#-testing-and-validation)
- [Security Features](#-security-features)
- [Webmail Interface](#-webmail-interface)
- [DNS Configuration](#-dns-configuration)
- [Troubleshooting](#-troubleshooting)
- [License](#-license)

## 🚀 Features

### 📧 Mail Server Components
- **Postfix** - SMTP server (Linux) / **hMailServer** (Windows)
- **Dovecot** - IMAP/POP3 server (Linux) / **hMailServer** (Windows)
- **MariaDB/MySQL** - Database management
- **OpenDKIM** - DKIM signing
- **SpamAssassin** - Spam filtering
- **ClamAV** - Virus scanning
- **Roundcube** - Webmail interface

### 🐳 Platform Support
- **Linux** - Ubuntu/Debian/CentOS/RHEL/Fedora
- **Windows** - 7/8.1/10/11
- **Docker** - Container deployment
- **Cross-platform** management tools

### 🛡️ Security
- SSL/TLS encryption
- Spam filtering
- Virus scanning
- DKIM signing
- Firewall configuration
- Automatic security updates

### 🌐 Web Interface
- **Roundcube** webmail
- Modern and user-friendly interface
- Mobile responsive design
- Multi-language support

### 🔧 Management Tools
- `mailadmin/mailadmin.bat` - User management
- `mailbackup/mailbackup.bat` - Automatic backup
- `mailmonitor/mailmonitor.bat` - Service monitoring
- `mailqueue/mailqueue.bat` - Mail queue management

### 🧪 Testing and Validation
- `test.sh/test.bat` - Automated test scripts
- `validate.sh/validate.bat` - Configuration validation
- Detailed reporting and logging
- Error detection and recommendations

### 🚀 Quick Installation
- `install.sh/install.bat` - One-click installation
- Automatic dependency management
- Interactive and quick installation options

## 🖥️ Supported Platforms

### Linux
- **Distributions:** Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+, Fedora 35+
- **Requirements:** Root access, 2GB+ RAM, 20GB+ disk

### Windows
- **Versions:** Windows 7, 8.1, 10, 11
- **Requirements:** Administrator privileges, 2GB+ RAM, 20GB+ disk

### Docker
- **Platforms:** Linux, Windows, macOS (Docker Desktop)
- **Requirements:** Docker and Docker Compose

## 📦 Installation Methods

### 🔥 Quick Installation (All Platforms)

#### Linux
```bash
curl -fsSL https://raw.githubusercontent.com/tda45/LibTMail/master/install.sh | sudo bash
```

#### Windows
```cmd
powershell -Command "iwr -Uri https://raw.githubusercontent.com/tda45/LibTMail/master/install.bat -OutFile install.bat; ./install.bat"
```

### 📋 Manual Installation

#### 1. Clone the repository
```bash
git clone https://github.com/tda45/LibTMail.git
cd LibTMail
```

#### 2. Run the installation for your platform

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

## 🐳 Docker Installation

### Quick Start
```bash
# Create environment file
./docker.sh env

# Start containers
./docker.sh start
```

### Docker Management
```bash
./docker.sh status          # Show status
./docker.sh logs             # Show logs
./docker.sh backup           # Backup
./docker.sh exec mailadmin list  # Execute command
./docker.sh stop             # Stop
./docker.sh update           # Update
```

### Docker Compose
```bash
# Manual start
docker-compose up -d

# View logs
docker-compose logs -f

# Container status
docker-compose ps
```

## ⚙️ Configuration

### Basic Ports
| Port | Service | Description |
|------|--------|----------|
| 25   | SMTP | Incoming/outgoing email |
| 587  | SMTP | Email submission |
| 143  | IMAP | Email reading |
| 993  | IMAPS | Secure email reading |
| 110  | POP3 | Email download |
| 995  | POP3S | Secure email download |
| 80   | HTTP | Webmail interface |
| 443  | HTTPS | Secure webmail |

### Important Files
```
/etc/postfix/main.cf          - Postfix configuration
/etc/dovecot/dovecot.conf     - Dovecot configuration
/etc/opendkim.conf            - OpenDKIM configuration
/etc/spamassassin/local.cf    - SpamAssassin settings
/etc/clamav/clamd.conf         - ClamAV settings
/var/vmail/                   - Email storage
```

## 🔧 Management Tools

### mailadmin/mailadmin.bat - User Management
```bash
# Linux
mailadmin add user@domain.com password123
mailadmin list
mailadmin password user@domain.com newpassword
mailadmin delete user@domain.com

# Windows
mailadmin.bat add user@domain.com password123
mailadmin.bat list
mailadmin.bat password user@domain.com newpassword
mailadmin.bat delete user@domain.com
```

### mailbackup/mailbackup.bat - Backup
```bash
# Linux
mailbackup

# Windows
mailbackup.bat

# Docker
./docker.sh exec mailbackup
```

### mailmonitor/mailmonitor.bat - Monitoring
```bash
# Linux
mailmonitor

# Windows
mailmonitor.bat

# Monitoring logs
tail -f /var/log/mailserver_monitor.log
```

### mailqueue/mailqueue.bat - Mail Queue
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

## 🧪 Testing and Validation

### Automated Testing
```bash
# Linux
./test.sh

# Windows
test.bat

# Docker
./docker.sh exec test.sh
```

### Configuration Validation
```bash
# Linux
./validate.sh

# Windows
validate.bat

# Docker
./docker.sh exec validate.sh
```

### Test Options
```bash
# Quick test
./test.sh --quick

# Test services only
./test.sh --services

# Test network only
./test.sh --network

# Detailed report
./test.sh -v
```

## 🛡️ Security Features

### Spam Filtering
- **SpamAssassin** with intelligent spam detection
- Automatic learning and updates
- Bayesian filtering
- SPF/DKIM verification

### Virus Scanning
- **ClamAV** with real-time virus scanning
- Automatic database updates
- Quarantine system

### Email Signing
- **OpenDKIM** with DKIM signing
- Domain validation
- Improved delivery rates

### SSL/TLS
- Automatic SSL certificate creation
- Secure connection requirement
- Encrypted communication

## 🌐 Webmail Interface

### Roundcube Features
- Modern and responsive interface
- Multi-language support (including English)
- Email folder management
- Address book
- Calendar support
- File attachment management

### Access URLs
- **Linux/Windows:** `http://mail.domain.com/webmail`
- **Docker:** `http://localhost:80` or `http://localhost:443`

### Setup
For webmail setup:
1. Navigate to the webmail address
2. Enter database information
3. Complete the installation
4. Remove the installer folder

## 🌍 DNS Configuration

### Required DNS Records
```
; MX Record
@    IN    MX    10    mail.domain.com.

; A Record
mail IN    A     SERVER_IP_ADDRESS

; SPF Record
@    IN    TXT   "v=spf1 mx -all"

; DKIM Record (copy from script output)
mail._domainkey IN    TXT   "v=DKIM1; k=rsa; p=PUBLIC_KEY"

; DMARC Record
_dmarc IN    TXT   "v=DMARC1; p=quarantine; rua=mailto:dmarc@domain.com"
```

### DKIM Key
The script generates your DKIM key during installation. For DNS record:
```bash
# Linux
cat /etc/opendkim/keys/domain.com/mail.txt

# Docker
./docker.sh exec cat /etc/opendkim/keys/domain.com/mail.txt
```

## 🔧 Troubleshooting

### Automatic Validation
```bash
# Configuration validation
./validate.sh          # Linux
validate.bat           # Windows

# Test execution
./test.sh              # Linux
test.bat               # Windows
```

### Service Status Check
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

### Port Status
```bash
# Linux/Windows
netstat -tlnp | grep -E ':(25|587|143|993|110|995|80|443)\s'

# Docker
./docker.sh exec netstat -tlnp | grep -E ':(25|587|143|993|110|995|80|443)\s'
```

### Log Files
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

### Common Issues

#### Postfix Not Starting
```bash
# Linux
postfix check
journalctl -u postfix

# Docker
./docker.sh exec postfix check
```

#### Dovecot Connection Error
```bash
# Linux
doveconf -n
systemctl restart dovecot

# Docker
./docker.sh exec doveconf -n
./docker.sh restart
```

#### Webmail Access Issues
```bash
# Linux
systemctl status apache2
apache2ctl configtest

# Windows
sc query W3SVC

# Docker
curl -I http://localhost:80
```

#### Database Issues
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

### Docker Specific Issues
```bash
# Restart container
docker-compose restart

# View logs
docker-compose logs -f libtmail

# Execute command in container
docker-compose exec libtmail bash

# Clean start
docker-compose down -v
docker-compose up -d
```

## 📈 Performance Optimization

### Postfix Optimization
```bash
# Add to /etc/postfix/main.cf
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30
smtpd_client_message_rate_limit = 100
```

### Dovecot Optimization
```bash
# Add to /etc/dovecot/dovecot.conf
mail_max_userip_connections = 10
process_limit = 100
```

### Database Optimization
```bash
# MariaDB configuration
mysql -u root -p -e "OPTIMIZE TABLE mailserver.users;"
```

## 🔄 Backup and Restore

### Manual Backup
```bash
# Full backup
mailbackup

# Database backup
mysqldump --single-transaction --routines --triggers mailserver > mailserver_backup.sql

# Email data backup
tar -czf vmail_backup.tar.gz /var/vmail
```

### Restore
```bash
# Database restore
mysql mailserver < mailserver_backup.sql

# Email data restore
tar -xzf vmail_backup.tar.gz -C /
```

## 📊 Monitoring and Reporting

### Service Monitoring
```bash
# Service status
mailmonitor

# Disk usage
df -h /var/vmail

# Mail queue status
mailqueue stats
```

### Log Analysis
```bash
# Spam statistics
grep "Spam detected" /var/log/mail.log | wc -l

# Virus scan results
grep "FOUND" /var/log/clamav/clamd.log

# Incoming/outgoing email count
grep -c "from=" /var/log/mail.log
```

## 🔐 Security Tips

### Strong Passwords
- At least 12 characters
- Uppercase, lowercase, numbers, and special characters
- Regular password changes

### Firewall
```bash
# Open only necessary ports
ufw allow 25/tcp
ufw allow 587/tcp
ufw allow 143/tcp
ufw allow 993/tcp
ufw allow 80/tcp
ufw allow 443/tcp
```

### Fail2Ban Installation
```bash
# Brute force protection
apt install fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban
```

## 🚨 Updates

### System Updates
```bash
# Update packages
apt update && apt upgrade -y

# Update virus database
freshclam

# Update spam rules
sa-update
```

### Script Updates
```bash
# Get latest version
git pull origin master

# Check changes
git log --oneline -5
```

## 🤝 Contributing

### Bug Reports
- Open an issue on GitHub
- Include detailed information and log files
- Specify system information

### Feature Requests
- Use GitHub Discussions
- Describe use cases
- Set priorities

### Development
1. Fork the repository
2. Create a feature branch
3. Make changes
4. Submit a pull request

## 📞 Support

### Official Channels
- **GitHub:** https://github.com/tda45/LibTMail
- **Issues:** https://github.com/tda45/LibTMail/issues
- **Discussions:** https://github.com/tda45/LibTMail/discussions

### Community
- Forum and discussion groups
- Social media accounts
- Technical blog posts

## 📄 License

This project is licensed under **TLİ (Turkish License Signature) v1.0**.

### Important Terms:
- ✅ **Free use:** Cannot be sold under any circumstances
- ✅ **Open source:** Source code can be freely used
- ✅ **Modification:** Development is allowed
- ❌ **Commercial use:** Sales, rental, or IAP are prohibited
- ❌ **Malware:** Malware cannot be added

For detailed information, see the [LICENSE](LICENSE) file.

## 🙏 Thanks

Thanks to all community members who contributed to the development of this script!

### Used Projects
- [Postfix](http://www.postfix.org/) - SMTP server
- [Dovecot](https://www.dovecot.org/) - IMAP/POP3 server
- [MariaDB](https://mariadb.org/) - Database
- [Roundcube](https://roundcube.net/) - Webmail
- [SpamAssassin](https://spamassassin.apache.org/) - Spam filtering
- [ClamAV](https://www.clamav.net/) - Virus scanning
- [OpenDKIM](http://www.opendkim.org/) - DKIM signing

---

**⚡ Quick Installation:** `git clone https://github.com/tda45/LibTMail.git && cd LibTMail && chmod +x install.sh && sudo ./install.sh`

**📧 Email:** tahadikbas45@gmail.com
**🌐 Web:** https://github.com/tda45/LibTMail  
**📜 License:** TLİ v1.0
