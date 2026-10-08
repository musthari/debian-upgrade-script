#!/bin/bash

################################################################################
# Debian 11/12 to Debian 13 Upgrade Script
# Mendukung upgrade dari Debian 11 (Bullseye) ke 13 (Trixie)
# Mendukung upgrade dari Debian 12 (Bookworm) ke 13 (Trixie)
################################################################################

set -e

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/var/log/debian-upgrade-$(date +%Y%m%d-%H%M%S).log"

# Flags
AUTO_CONFIRM=0

################################################################################
# Function: Print dengan warna
################################################################################
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
    echo "=== $1 ===" >> "$LOG_FILE"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    echo "✓ $1" >> "$LOG_FILE"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    echo "✗ $1" >> "$LOG_FILE"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    echo "⚠ $1" >> "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
    echo "ℹ $1" >> "$LOG_FILE"
}

################################################################################
# Function: parse args
################################################################################
detect_arguments() {
    for arg in "$@"; do
        case "$arg" in
            -y|--yes)
                AUTO_CONFIRM=1
                ;;
            -n|--no)
                print_warning "Upgrade dibatalkan melalui argumen CLI."
                exit 0
                ;;
            -h|--help)
                echo "Penggunaan: $0 [--yes|-y] [--no|-n]"
                echo ""
                echo "Contoh:"
                echo "  sudo $0 --yes"
                echo "  AUTO_CONFIRM=1 sudo $0"
                exit 0
                ;;
        esac
    done
}

################################################################################
# Function: Check if running as root
################################################################################
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Script ini harus dijalankan dengan user root"
        exit 1
    fi
    print_success "Running sebagai root"
}

################################################################################
# Function: Detect Debian version
################################################################################
detect_debian_version() {
    print_header "Mendeteksi Versi Debian"

    if [ ! -f /etc/debian_version ]; then
        print_error "Ini bukan sistem Debian. Script dihentikan."
        exit 1
    fi

    DEBIAN_VERSION=$(cat /etc/os-release | grep VERSION_ID | cut -d= -f2 | tr -d '"')
    DEBIAN_NAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2 | tr -d '"')

    print_info "Versi Debian: $DEBIAN_VERSION ($DEBIAN_NAME)"
    echo "Versi Debian: $DEBIAN_VERSION ($DEBIAN_NAME)" >> "$LOG_FILE"

    case "$DEBIAN_VERSION" in
        11)
            print_success "Debian 11 (Bullseye) terdeteksi - Upgrade ke Debian 13 tersedia"
            SOURCE_VERSION="11"
            SOURCE_NAME="bullseye"
            ;;
        12)
            print_success "Debian 12 (Bookworm) terdeteksi - Upgrade ke Debian 13 tersedia"
            SOURCE_VERSION="12"
            SOURCE_NAME="bookworm"
            ;;
        *)
            print_error "Versi Debian tidak didukung. Hanya Debian 11 dan 12 yang didukung."
            exit 1
            ;;
    esac

    TARGET_VERSION="13"
    TARGET_NAME="trixie"
}

################################################################################
# Function: Backup sources.list
################################################################################
backup_sources_list() {
    print_header "Backup Konfigurasi APT"

    BACKUP_DIR="/root/debian-upgrade-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    cp /etc/apt/sources.list "$BACKUP_DIR/sources.list.bak"
    [ -d /etc/apt/sources.list.d ] && cp -r /etc/apt/sources.list.d "$BACKUP_DIR/sources.list.d.bak"

    print_success "Backup disimpan di: $BACKUP_DIR"
    echo "Backup disimpan di: $BACKUP_DIR" >> "$LOG_FILE"
}

################################################################################
# Function: Memperbarui sources.list ke Debian 13
################################################################################
update_sources_list() {
    print_header "Memperbarui Sources List ke Debian 13"

    # Hapus repo pihak ketiga
    print_info "Menghapus third-party repositories..."
    [ -d /etc/apt/sources.list.d ] && rm -f /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null || true

    # Update sources.list ke Debian 13
    cat > /etc/apt/sources.list << 'EOF'
# Debian 13 (Trixie) - Main Repository
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie main contrib non-free non-free-firmware

# Debian 13 (Trixie) - Updates
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware

# Debian 13 (Trixie) - Security Updates
deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF

    print_success "Sources list diperbarui ke Debian 13 (Trixie)"
}

################################################################################
# Function: Clean APT cache
################################################################################
clean_apt_cache() {
    print_header "Membersihkan APT Cache"

    apt-get clean
    apt-get autoclean

    print_success "APT cache dibersihkan"
}

################################################################################
# Function: Update package list
################################################################################
update_package_list() {
    print_header "Memperbarui Daftar Package"

    if ! apt-get update >> "$LOG_FILE" 2>&1; then
        print_error "Gagal update package list"
        exit 1
    fi

    print_success "Daftar package diperbarui"
}

################################################################################
# Function: Minimal upgrade
################################################################################
minimal_upgrade() {
    print_header "Menjalankan Minimal Upgrade (apt-get upgrade)"

    if ! DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG_FILE" 2>&1; then
        print_error "Gagal menjalankan upgrade"
        exit 1
    fi

    print_success "Minimal upgrade selesai"
}

################################################################################
# Function: Full dist-upgrade
################################################################################
full_dist_upgrade() {
    print_header "Menjalankan Full Distribution Upgrade (dist-upgrade)"

    if ! DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y >> "$LOG_FILE" 2>&1; then
        print_error "Gagal menjalankan dist-upgrade"
        exit 1
    fi

    print_success "Distribution upgrade selesai"
}

################################################################################
# Function: Autoremove unused packages
################################################################################
autoremove_packages() {
    print_header "Membersihkan Package yang Tidak Digunakan"

    if ! apt-get autoremove -y >> "$LOG_FILE" 2>&1; then
        print_warning "Autoremove selesai dengan warning"
    else
        print_success "Autoremove selesai"
    fi

    if ! apt-get autoclean -y >> "$LOG_FILE" 2>&1; then
        print_warning "Autoclean selesai dengan warning"
    else
        print_success "Autoclean selesai"
    fi
}

################################################################################
# Function: Verify upgrade
################################################################################
verify_upgrade() {
    print_header "Verifikasi Upgrade"

    NEW_VERSION=$(cat /etc/os-release | grep VERSION_ID | cut -d= -f2 | tr -d '"')
    NEW_NAME=$(cat /etc/os-release | grep VERSION_CODENAME | cut -d= -f2 | tr -d '"')

    print_info "Versi sistem setelah upgrade: $NEW_VERSION ($NEW_NAME)"
    echo "Versi sistem setelah upgrade: $NEW_VERSION ($NEW_NAME)" >> "$LOG_FILE"

    if [ "$NEW_VERSION" = "13" ]; then
        print_success "Upgrade ke Debian 13 BERHASIL!"
        return 0
    else
        print_warning "Versi masih $NEW_VERSION, mungkin perlu restart sistem"
        return 1
    fi
}

################################################################################
# Function: Show summary
################################################################################
show_summary() {
    print_header "RINGKASAN UPGRADE"

    echo ""
    echo "Upgrade Path: Debian $SOURCE_VERSION ($SOURCE_NAME) -> Debian $TARGET_VERSION ($TARGET_NAME)"
    echo ""
    echo "Langkah yang dilakukan:"
    echo "  1. ✓ Verifikasi sistem sebagai root"
    echo "  2. ✓ Deteksi versi Debian"
    echo "  3. ✓ Backup konfigurasi APT"
    echo "  4. ✓ Update sources.list ke Debian 13"
    echo "  5. ✓ Update package list"
    echo "  6. ✓ Minimal upgrade"
    echo "  7. ✓ Full distribution upgrade"
    echo "  8. ✓ Autoremove unused packages"
    echo ""
    echo "Log file: $LOG_FILE"
    echo ""

    if [ "$NEW_VERSION" = "13" ]; then
        echo -e "${GREEN}Status: UPGRADE BERHASIL${NC}"
    else
        echo -e "${YELLOW}Status: Upgrade selesai, versi masih $NEW_VERSION${NC}"
        echo -e "${YELLOW}Restart sistem mungkin diperlukan${NC}"
    fi

    echo ""
}

################################################################################
# Function: Confirmation prompt
################################################################################
test_tty() {
    if [ -t 0 ]; then
        return 0
    fi
    return 1
}

confirm_upgrade() {
    print_header "KONFIRMASI UPGRADE"

    echo ""
    echo "WARNING: Script ini akan upgrade sistem dari Debian $DEBIAN_VERSION ke Debian 13"
    echo ""
    echo "Informasi sistem:"
    echo "  - Hostname: $(hostname)"
    echo "  - Kernel: $(uname -r)"
    echo "  - Versi saat ini: Debian $DEBIAN_VERSION ($DEBIAN_NAME)"
    echo "  - Versi target: Debian 13 (Trixie)"
    echo ""
    echo "Backup akan dibuat di: $BACKUP_DIR"
    echo ""
    echo "PASTIKAN ANDA:"
    echo "  1. Sudah membuat backup sistem"
    echo "  2. Tidak ada proses penting yang sedang berjalan"
    echo "  3. Koneksi internet stabil"
    echo "  4. Memiliki akses root/sudo"
    echo ""

    if [ "$AUTO_CONFIRM" -eq 1 ]; then
        print_info "Mode non-interaktif aktif: upgrade otomatis dilanjutkan."
        return 0
    fi

    if ! test_tty; then
        print_warning "STDIN bukan TTY. Untuk melanjutkan, jalankan dengan --yes atau set AUTO_CONFIRM=1."
        exit 1
    fi

    read -r -p "Lanjutkan upgrade? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        print_warning "Upgrade dibatalkan oleh user"
        exit 0
    fi
}

################################################################################
# MAIN EXECUTION
################################################################################
main() {
    detect_arguments "$@"

    echo "Debian Upgrade Script - Memulai" | tee -a "$LOG_FILE"
    echo "Start Time: $(date)" >> "$LOG_FILE"
    echo ""

    # Check root
    check_root
    echo ""

    # Detect version
    detect_debian_version
    echo ""

    # Backup sources
    backup_sources_list
    echo ""

    # Confirmation
    confirm_upgrade
    echo ""

    # Update sources list
    update_sources_list
    echo ""

    # Clean cache
    clean_apt_cache
    echo ""

    # Update package list
    update_package_list
    echo ""

    # Minimal upgrade
    minimal_upgrade
    echo ""

    # Full dist-upgrade
    full_dist_upgrade
    echo ""

    # Autoremove
    autoremove_packages
    echo ""

    # Verify
    verify_upgrade
    echo ""

    # Summary
    show_summary

    echo "End Time: $(date)" >> "$LOG_FILE"
}

# Run main function
main "$@"
