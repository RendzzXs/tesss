#!/bin/bash
# ptero-manager.sh

PANEL_DIR="/var/www/pterodactyl"
LOGO_URL="https://files.catbox.moe/nig1j1.jpg"
COPYRIGHT_TEXT="Rendzz Panel"
BACKUP_DIR="/root/backup-ptero"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Fungsi: Backup
do_backup() {
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"
    
    echo -e "${YELLOW}[*] Membuat backup...${NC}"
    mkdir -p $BACKUP_PATH
    
    # Backup file-file penting
    cp -r $PANEL_DIR/public/images $BACKUP_PATH/ 2>/dev/null
    cp -r $PANEL_DIR/resources/views $BACKUP_PATH/ 2>/dev/null
    cp -r $PANEL_DIR/public/css $BACKUP_PATH/ 2>/dev/null
    
    # Simpan info
    echo "Backup created: $TIMESTAMP" > $BACKUP_PATH/info.txt
    echo "Original copyright: Pterodactyl Panel" >> $BACKUP_PATH/info.txt
    
    echo -e "${GREEN}[✓] Backup tersimpan di: $BACKUP_PATH${NC}"
    echo "$BACKUP_PATH" > /tmp/last_backup.txt
}

# Fungsi: Install Custom
do_install() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     INSTALL RENDZZ PANEL CUSTOM      ${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    # Cek apakah sudah diinstall sebelumnya
    if [ -f "/tmp/rendzz_installed" ]; then
        echo -e "${YELLOW}[!] Deteksi: Panel sudah di-custom sebelumnya${NC}"
        read -p "Lanjutkan? (y/n): " confirm
        if [[ $confirm != "y" && $confirm != "Y" ]]; then
            echo -e "${RED}[✗] Dibatalkan${NC}"
            return
        fi
    fi
    
    # Backup dulu
    do_backup
    
    # Download dan ganti logo
    echo -e "${YELLOW}[*] Download logo...${NC}"
    cd /tmp
    wget -q --show-progress -O logo.jpg $LOGO_URL
    if [ -f "logo.jpg" ]; then
        # Convert ke PNG
        if command -v convert &> /dev/null; then
            convert logo.jpg logo.png
        else
            cp logo.jpg logo.png
        fi
        cp logo.png $PANEL_DIR/public/images/logo.png
        cp logo.png $PANEL_DIR/public/images/logo-dark.png 2>/dev/null || true
        echo -e "${GREEN}[✓] Logo berhasil diganti${NC}"
    else
        echo -e "${RED}[✗] Gagal download logo${NC}"
        return 1
    fi
    
    # Ganti copyright
    echo -e "${YELLOW}[*] Mengganti copyright ke \"$COPYRIGHT_TEXT\"...${NC}"
    cd $PANEL_DIR
    
    # Backup asli dulu sebelum di-sed (biar restore gampang)
    find resources/views -name "*.blade.php" -exec sed -i.bak "s/Pterodactyl Panel/$COPYRIGHT_TEXT/g" {} \;
    find resources/views -name "*.blade.php" -exec sed -i.bak "s/Pterodactyl®/$COPYRIGHT_TEXT/g" {} \;
    find resources/views -name "*.blade.php" -exec sed -i.bak "s/Pterodactyl Inc./$COPYRIGHT_TEXT/g" {} \;
    find resources/views -name "*.blade.php" -exec sed -i.bak "s/<title>Pterodactyl/<title>$COPYRIGHT_TEXT/g" {} \;
    find resources/lang -name "*.php" -exec sed -i.bak "s/Pterodactyl Panel/$COPYRIGHT_TEXT/g" {} \; 2>/dev/null
    
    # Hapus file backup .bak (biar ga numpuk)
    find resources/views -name "*.bak" -delete 2>/dev/null
    find resources/lang -name "*.bak" -delete 2>/dev/null
    
    echo -e "${GREEN}[✓] Copyright diubah${NC}"
    
    # Clear cache
    echo -e "${YELLOW}[*] Clear cache...${NC}"
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    
    # Tandai sudah diinstall
    touch /tmp/rendzz_installed
    echo "$COPYRIGHT_TEXT" > /tmp/rendzz_custom_name
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}[✓] INSTALLASI SELESAI!${NC}"
    echo -e "${GREEN}[✓] Panel sekarang: $COPYRIGHT_TEXT${NC}"
    echo -e "${YELLOW}[!] Refresh browser (Ctrl+F5)${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Fungsi: Uninstall (Restore dari backup)
do_uninstall() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}     UNINSTALL / RESTORE PANEL         ${NC}"
    echo -e "${RED}========================================${NC}"
    
    # Cek apakah ada backup
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}[✗] Tidak ada backup ditemukan!${NC}"
        echo -e "${YELLOW}[!] Backup biasanya di: $BACKUP_DIR${NC}"
        return 1
    fi
    
    # List backup yang tersedia
    echo -e "${YELLOW}Backup yang tersedia:${NC}"
    ls -lt $BACKUP_DIR | grep "^d" | head -10 | nl
    
    echo ""
    read -p "Pilih nomor backup (atau 'latest' untuk terbaru): " choice
    
    if [[ $choice == "latest" ]]; then
        BACKUP_PATH=$(ls -td $BACKUP_DIR/*/ | head -1)
    elif [[ $choice =~ ^[0-9]+$ ]]; then
        BACKUP_PATH=$(ls -td $BACKUP_DIR/*/ | sed -n "${choice}p")
    else
        echo -e "${RED}[✗] Pilihan tidak valid${NC}"
        return 1
    fi
    
    if [ -z "$BACKUP_PATH" ]; then
        echo -e "${RED}[✗] Backup tidak ditemukan${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}[*] Restore dari: $BACKUP_PATH${NC}"
    read -p "Yakin ingin restore? (y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${RED}[✗] Dibatalkan${NC}"
        return
    fi
    
    # Restore file
    echo -e "${YELLOW}[*] Merestore file...${NC}"
    
    # Restore images
    if [ -d "$BACKUP_PATH/images" ]; then
        cp -r $BACKUP_PATH/images/* $PANEL_DIR/public/images/ 2>/dev/null
        echo -e "${GREEN}[✓] Logo/Images direstore${NC}"
    fi
    
    # Restore views (kembalikan ke default)
    if [ -d "$BACKUP_PATH/views" ]; then
        cp -r $BACKUP_PATH/views/* $PANEL_DIR/resources/views/ 2>/dev/null
        echo -e "${GREEN}[✓] Views direstore${NC}"
    fi
    
    # Restore CSS
    if [ -d "$BACKUP_PATH/css" ]; then
        cp -r $BACKUP_PATH/css/* $PANEL_DIR/public/css/ 2>/dev/null
        echo -e "${GREEN}[✓] CSS direstore${NC}"
    fi
    
    # Clear cache
    echo -e "${YELLOW}[*] Clear cache...${NC}"
    cd $PANEL_DIR
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    
    # Hapus tanda installed
    rm -f /tmp/rendzz_installed
    rm -f /tmp/rendzz_custom_name
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}[✓] RESTORE SELESAI!${NC}"
    echo -e "${GREEN}[✓] Panel kembali ke default${NC}"
    echo -e "${YELLOW}[!] Refresh browser (Ctrl+F5)${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# Fungsi: Lihat status
show_status() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}        STATUS PANEL CUSTOM            ${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ -f "/tmp/rendzz_installed" ]; then
        CUSTOM_NAME=$(cat /tmp/rendzz_custom_name 2>/dev/null || echo "Rendzz Panel")
        echo -e "${GREEN}[✓] Status: CUSTOM TERPASANG${NC}"
        echo -e "${GREEN}[✓] Nama: $CUSTOM_NAME${NC}"
        echo -e "${YELLOW}[!] Backup terakhir: $(cat /tmp/last_backup.txt 2>/dev/null || echo 'Tidak ada')${NC}"
    else
        echo -e "${RED}[✗] Status: DEFAULT (belum di-custom)${NC}"
    fi
    
    # Tampilkan daftar backup
    if [ -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}\nBackup tersedia:${NC}"
        ls -lt $BACKUP_DIR | grep "^d" | head -5 | awk '{print "  - " $9 " (" $6 " " $7 " " $8 ")"}'
    fi
}

# Menu Utama
while true; do
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}     PTERODACTYL PANEL MANAGER         ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "1. ${GREEN}Install${NC} - Pasang custom (Rendzz Panel)"
    echo -e "2. ${RED}Uninstall${NC} - Restore dari backup"
    echo -e "3. ${YELLOW}Status${NC} - Cek status panel"
    echo -e "4. ${BLUE}Exit${NC}"
    echo -e "========================================"
    read -p "Pilih menu [1-4]: " menu
    
    case $menu in
        1)
            do_install
            ;;
        2)
            do_uninstall
            ;;
        3)
            show_status
            ;;
        4)
            echo -e "${GREEN}Bye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[✗] Pilihan tidak valid${NC}"
            ;;
    esac
    
    echo ""
    read -p "Tekan Enter untuk kembali ke menu..."
done
