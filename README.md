# Debian 11/12 to Debian 13 Upgrade Script

Skrip shell otomatis untuk upgrade Debian 11 (Bullseye) atau Debian 12 (Bookworm) ke Debian 13 (Trixie) pada server Linux.

## Fitur

✓ Mendukung upgrade dari Debian 11 ke 13  
✓ Mendukung upgrade dari Debian 12 ke 13  
✓ Backup otomatis konfigurasi APT sebelum upgrade  
✓ Update repositori ke Debian 13  
✓ Menjalankan apt-get upgrade, dist-upgrade, dan cleanup  
✓ Verifikasi hasil upgrade  
✓ Logging detail ke `/var/log/debian-upgrade-*.log`  
✓ Tidak menginstall software baru  

## Persyaratan

- Sistem Debian 11 atau Debian 12
- Akses root/sudo
- Koneksi internet stabil
- Backup data penting sebelum menjalankan

## Instalasi dan Cara Pakai

### Metode 1: Clone Repository

```bash
git clone https://github.com/musthari/debian-upgrade-script.git
cd debian-upgrade-script
chmod +x upgrade-debian.sh
sudo ./upgrade-debian.sh
```

### Metode 2: Download dengan curl

```bash
curl -fsSL https://raw.githubusercontent.com/musthari/debian-upgrade-script/main/upgrade-debian.sh -o upgrade-debian.sh
chmod +x upgrade-debian.sh
sudo ./upgrade-debian.sh
```

### Metode 3: Download dengan wget

```bash
wget https://raw.githubusercontent.com/musthari/debian-upgrade-script/main/upgrade-debian.sh
chmod +x upgrade-debian.sh
sudo ./upgrade-debian.sh
```

### Metode 4: Langsung jalankan dengan curl (one-liner)

```bash
curl -fsSL https://raw.githubusercontent.com/musthari/debian-upgrade-script/main/upgrade-debian.sh | sudo bash
```

### Metode 5: Langsung jalankan dengan wget (one-liner)

```bash
wget -qO- https://raw.githubusercontent.com/musthari/debian-upgrade-script/main/upgrade-debian.sh | sudo bash
```

## Tahapan Upgrade

Skrip akan melakukan langkah-langkah berikut secara otomatis:

1. ✓ Verifikasi script dijalankan sebagai root
2. ✓ Deteksi versi Debian saat ini
3. ✓ Backup konfigurasi APT ke `/root/debian-upgrade-backup-YYYYMMDD-HHMMSS/`
4. ✓ Update `/etc/apt/sources.list` ke Debian 13
5. ✓ Menjalankan `apt-get update`
6. ✓ Menjalankan `apt-get upgrade`
7. ✓ Menjalankan `apt-get dist-upgrade`
8. ✓ Menjalankan `apt-get autoremove` dan `apt-get autoclean`
9. ✓ Verifikasi hasil upgrade

## Log File

Setiap jalannya skrip akan membuat log file di:
```
/var/log/debian-upgrade-YYYYMMDD-HHMMSS.log
```

Untuk melihat log:
```bash
cat /var/log/debian-upgrade-*.log
```

## Backup dan Recovery

Backup konfigurasi APT disimpan di:
```
/root/debian-upgrade-backup-YYYYMMDD-HHMMSS/
```

Jika ingin mengembalikan ke backup:
```bash
cp /root/debian-upgrade-backup-YYYYMMDD-HHMMSS/sources.list /etc/apt/sources.list
```

## Versi yang Didukung

| Dari | Ke | Status |
|------|-----|--------|
| Debian 11 (Bullseye) | Debian 13 (Trixie) | ✓ Didukung |
| Debian 12 (Bookworm) | Debian 13 (Trixie) | ✓ Didukung |
| Debian 10 (Buster) | Debian 13 (Trixie) | ✗ Tidak didukung |
| Debian 9 (Stretch) | Debian 13 (Trixie) | ✗ Tidak didukung |

## Catatan Penting

⚠️ **Backup data penting sebelum menjalankan skrip**

- Upgrade bisa memerlukan beberapa menit tergantung kecepatan internet dan spesifikasi server
- Disarankan untuk reboot sistem setelah upgrade selesai
- Jalankan skrip pada waktu maintenance untuk menghindari downtime yang tidak terduga
- Tidak disarankan menjalankan pada server production tanpa testing sebelumnya

## Troubleshooting

### Error: "Ini bukan sistem Debian"
- Pastikan Anda menggunakan sistem Debian, bukan distro lain

### Error: "Versi Debian yang didukung hanya 11 dan 12"
- Skrip hanya mendukung upgrade dari Debian 11 atau 12. Jika Anda menggunakan versi lain, lakukan upgrade bertahap

### Error: "apt-get update gagal"
- Periksa koneksi internet
- Periksa firewall yang mungkin memblokir akses ke repository
- Coba ganti mirror repository jika yang default lambat

### Upgrade tertunda atau timeout
- Jalankan skrip kembali, proses upgrade akan melanjutkan dari tahap terakhir
- Pastikan Anda tidak menghentikan skrip di tengah jalan

### Error: `/dev/fd/63: No such file or directory`
- Gunakan Metode 2, 3 atau jalankan skrip secara terpisah
- Shell Anda mungkin tidak mendukung process substitution
- Gunakan Metode 4 atau 5 yang menggunakan pipe standar

## Lihat Log Detail

Untuk melihat proses upgrade secara real-time:
```bash
tail -f /var/log/debian-upgrade-*.log
```

## Reboot Sistem (Opsional)

Setelah upgrade selesai, reboot sistem:
```bash
sudo reboot
```

## Kontribusi

Silakan buat issue atau pull request untuk perbaikan atau saran fitur baru.

## Lisensi

MIT License - Bebas digunakan untuk keperluan apapun

## Disclaimer

Skrip ini diberikan apa adanya tanpa jaminan. Pengguna bertanggung jawab penuh atas penggunaan dan konsekuensi yang timbul. Selalu lakukan backup sebelum menjalankan skrip upgrade pada sistem production.
