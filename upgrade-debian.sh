#!/bin/bash

# Pastikan script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Harap jalankan skrip ini sebagai root (gunakan sudo -i atau login sebagai root)."
  exit 1
fi

# Hindari prompt interaktif selama proses upgrade (menjawab Yes secara otomatis)
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# Ambil informasi codename Debian saat ini
source /etc/os-release
CURRENT_CODENAME=$VERSION_CODENAME

echo "Sistem saat ini terdeteksi sebagai Debian: $CURRENT_CODENAME"

# Fungsi untuk mengeksekusi proses upgrade
do_upgrade() {
    TARGET_CODENAME=$1
    echo "=========================================================="
    echo "Memulai proses upgrade dari $CURRENT_CODENAME ke $TARGET_CODENAME..."
    echo "=========================================================="

    # Backup konfigurasi repositori
    cp /etc/apt/sources.list "/etc/apt/sources.list.bak.$CURRENT_CODENAME"

    # Ubah codename repositori lama ke codename target
    sed -i "s/$CURRENT_CODENAME/$TARGET_CODENAME/g" /etc/apt/sources.list
    sed -i "s/$CURRENT_CODENAME/$TARGET_CODENAME/g" /etc/apt/sources.list.d/*.list 2>/dev/null || true

    # Debian 12 ke atas memisahkan komponen firmware non-free
    # Menambahkan non-free-firmware secara otomatis jika menggunakan komponen non-free
    if grep -q "non-free" /etc/apt/sources.list && ! grep -q "non-free-firmware" /etc/apt/sources.list; then
        sed -i 's/non-free/non-free non-free-firmware/g' /etc/apt/sources.list
    fi

    # 1. Update daftar paket
    echo "[1/4] Memperbarui repositori..."
    apt-get update -y

    # 2. Upgrade paket utama tanpa menghapus dependensi yang ada (Minimal Upgrade)
    echo "[2/4] Melakukan upgrade minimal..."
    apt-get upgrade --without-new-pkgs -y

    # 3. Upgrade penuh termasuk instalasi kernel baru dan dependensi usang
    echo "[3/4] Melakukan full upgrade sistem..."
    apt-get full-upgrade -y

    # 4. Pembersihan sisa paket usang
    echo "[4/4] Membersihkan paket yang sudah tidak digunakan..."
    apt-get autoremove -y
    apt-get clean

    echo "Upgrade ke $TARGET_CODENAME selesai!"
    CURRENT_CODENAME=$TARGET_CODENAME
}

# Logika rute upgrade
if [ "$CURRENT_CODENAME" == "bullseye" ]; then
    echo "Debian 11 (Bullseye) terdeteksi."
    echo "Mengikuti jalur resmi: Upgrade ke Debian 12 (Bookworm) terlebih dahulu, lalu ke Debian 13 (Trixie)."
    
    do_upgrade "bookworm"
    do_upgrade "trixie"

elif [ "$CURRENT_CODENAME" == "bookworm" ]; then
    echo "Debian 12 (Bookworm) terdeteksi. Melakukan upgrade langsung ke Debian 13 (Trixie)."
    
    do_upgrade "trixie"

elif [ "$CURRENT_CODENAME" == "trixie" ]; then
    echo "Sistem Anda sudah berada di Debian 13 (Trixie). Tidak ada operasi yang dijalankan."
    exit 0
else
    echo "GAGAL: Skrip ini hanya mendukung upgrade dari Debian 11 (Bullseye) atau Debian 12 (Bookworm)."
    exit 1
fi

echo "=========================================================="
echo "SELURUH PROSES UPGRADE TELAH SELESAI!"
echo "Semua file sources.list lama telah di-backup di /etc/apt/"
echo "Sangat disarankan untuk me-restart sistem Anda sekarang."
echo "Jalankan: reboot"
echo "=========================================================="
