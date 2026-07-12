#!/bin/bash
# ptero-custom-dashboard-full.sh

PANEL_DIR="/var/www/pterodactyl"
BACKUP_DIR="/root/backup-ptero-full"
LOGO_URL="https://files.catbox.moe/nig1j1.jpg"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ============================================
# FUNGSI BACKUP OTOMATIS
# ============================================

auto_backup() {
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/backup-$TIMESTAMP"
    mkdir -p $BACKUP_PATH
    
    echo -e "${YELLOW}[*] Auto Backup...${NC}"
    
    # Backup file-file yang akan diubah
    cp -r $PANEL_DIR/resources/views/admin $BACKUP_PATH/ 2>/dev/null
    cp -r $PANEL_DIR/resources/views/layouts $BACKUP_PATH/ 2>/dev/null
    cp $PANEL_DIR/public/css/app.css $BACKUP_PATH/ 2>/dev/null
    cp $PANEL_DIR/routes/web.php $BACKUP_PATH/ 2>/dev/null
    
    echo -e "${GREEN}[✓] Backup di: $BACKUP_PATH${NC}"
    echo "$BACKUP_PATH" > /tmp/last_full_backup.txt
}

# ============================================
# FITUR 1: CARD PESAN DI DASHBOARD
# ============================================

create_message_card() {
    echo -e "${CYAN}[*] Membuat Card Pesan di Dashboard...${NC}"
    
    # Backup dulu
    auto_backup
    
    # File dashboard.blade.php
    DASHBOARD_FILE="$PANEL_DIR/resources/views/admin/dashboard.blade.php"
    
    # Baca file dashboard yang sudah ada
    if [ ! -f "$DASHBOARD_FILE" ]; then
        echo -e "${RED}[✗] File dashboard tidak ditemukan!${NC}"
        return 1
    fi
    
    # Backup file dashboard
    cp $DASHBOARD_FILE $DASHBOARD_FILE.bak
    
    # Tambahkan card pesan di bagian atas dashboard
    cat > $PANEL_DIR/resources/views/admin/dashboard.blade.php << 'EOF'
@extends('layouts.admin')

@section('title', 'Dashboard - Rendzz Panel')

@section('content')
<div class="container-fluid">
    
    <!-- ========== CARD PESAN / NOTICE ========== -->
    <div class="row mb-4">
        <div class="col-md-12">
            <div class="card" style="background: linear-gradient(135deg, rgba(240,147,251,0.15), rgba(245,87,108,0.15)); 
                        border: 1px solid rgba(245,87,108,0.2); border-radius: 20px; 
                        backdrop-filter: blur(10px);">
                <div class="card-body" style="padding: 25px 30px;">
                    <div class="row align-items-center">
                        <div class="col-md-1 text-center">
                            <i class="fas fa-bullhorn" style="font-size: 40px; color: #f5576c;"></i>
                        </div>
                        <div class="col-md-9">
                            <h5 style="color: white; font-weight: 700; margin: 0;">
                                <span style="background: linear-gradient(135deg, #f093fb, #f5576c); 
                                        -webkit-background-clip: text; -webkit-text-fill-color: transparent;">
                                    📢 PENGUMUMAN
                                </span>
                            </h5>
                            <p style="color: rgba(255,255,255,0.7); margin: 5px 0 0;">
                                {!! session('dashboard_message', 'Selamat datang di Rendzz Panel! 🚀') !!}
                            </p>
                        </div>
                        <div class="col-md-2 text-end">
                            <span class="badge" style="background: rgba(245,87,108,0.2); color: #f5576c; padding: 8px 15px; border-radius: 50px; font-size: 12px;">
                                <i class="fas fa-edit"></i> Edit di Settings
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- ========== END CARD PESAN ========== -->

    <!-- STATISTIK -->
    <div class="row mb-4">
        <div class="col-md-3">
            <div class="card" style="background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); border-radius: 15px;">
                <div class="card-body">
                    <h6 style="color: rgba(255,255,255,0.5);">Total Servers</h6>
                    <h2 style="color: white;">{{ $servers->count() }}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card" style="background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); border-radius: 15px;">
                <div class="card-body">
                    <h6 style="color: rgba(255,255,255,0.5);">Online</h6>
                    <h2 style="color: #2ed573;">{{ $servers->where('status', 'online')->count() }}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card" style="background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); border-radius: 15px;">
                <div class="card-body">
                    <h6 style="color: rgba(255,255,255,0.5);">Offline</h6>
                    <h2 style="color: #ff4757;">{{ $servers->where('status', 'offline')->count() }}</h2>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="card" style="background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); border-radius: 15px;">
                <div class="card-body">
                    <h6 style="color: rgba(255,255,255,0.5);">Installing</h6>
                    <h2 style="color: #ffa502;">{{ $servers->where('status', 'installing')->count() }}</h2>
                </div>
            </div>
        </div>
    </div>

    <!-- SERVER LIST -->
    <div class="row">
        @foreach($servers as $server)
        <div class="col-md-4 col-lg-3 mb-4">
            <div class="card h-100" style="background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); border-radius: 20px; transition: all 0.3s;">
                <div class="card-body">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="font-size: 30px;">🖥️</span>
                        @if($server->status == 'online')
                            <span class="badge" style="background: rgba(46,213,115,0.2); color: #2ed573; border: 1px solid #2ed573;">● Online</span>
                        @elseif($server->status == 'offline')
                            <span class="badge" style="background: rgba(255,71,87,0.2); color: #ff4757; border: 1px solid #ff4757;">● Offline</span>
                        @else
                            <span class="badge" style="background: rgba(255,165,0,0.2); color: #ffa502; border: 1px solid #ffa502;">● Installing</span>
                        @endif
                    </div>
                    <h6 style="color: white; margin-top: 10px;">{{ $server->name }}</h6>
                    <small style="color: rgba(255,255,255,0.4);">{{ $server->node->name ?? 'N/A' }}</small>
                    
                    <div style="margin-top: 15px;">
                        <div style="display: flex; justify-content: space-between;">
                            <small style="color: rgba(255,255,255,0.5);">CPU</small>
                            <small style="color: white;">{{ $server->cpu }}%</small>
                        </div>
                        <div class="progress" style="height: 4px; background: rgba(255,255,255,0.1);">
                            <div class="progress-bar bg-success" style="width: {{ $server->cpu }}%;"></div>
                        </div>
                    </div>
                    
                    <div style="margin-top: 10px;">
                        <div style="display: flex; justify-content: space-between;">
                            <small style="color: rgba(255,255,255,0.5);">RAM</small>
                            <small style="color: white;">{{ $server->memory }}%</small>
                        </div>
                        <div class="progress" style="height: 4px; background: rgba(255,255,255,0.1);">
                            <div class="progress-bar bg-info" style="width: {{ $server->memory }}%;"></div>
                        </div>
                    </div>
                    
                    <a href="{{ route('server.show', $server->id) }}" class="btn btn-primary btn-sm w-100 mt-3" style="border-radius: 50px; background: linear-gradient(135deg, #f093fb, #f5576c); border: none;">
                        <i class="fas fa-cog"></i> Manage
                    </a>
                </div>
            </div>
        </div>
        @endforeach
    </div>
</div>
@endsection
EOF

    echo -e "${GREEN}[✓] Card Pesan berhasil ditambahkan!${NC}"
}

# ============================================
# FITUR 2: SETTINGS CUSTOM (GANTI PESAN)
# ============================================

create_settings_page() {
    echo -e "${CYAN}[*] Membuat Settings Page...${NC}"
    
    # Backup dulu
    auto_backup
    
    # Buat file settings custom
    mkdir -p $PANEL_DIR/resources/views/admin
    
    cat > $PANEL_DIR/resources/views/admin/settings-custom.blade.php << 'EOF'
@extends('layouts.admin')

@section('title', 'Custom Settings - Rendzz Panel')

@section('content')
<div class="container-fluid">
    <div class="row">
        <div class="col-md-12">
            <h3 style="color: white; font-weight: 700;">
                <i class="fas fa-sliders-h" style="color: #f5576c;"></i> Custom Settings
            </h3>
            <p style="color: rgba(255,255,255,0.5);">Kelola tampilan dan pesan panel</p>
        </div>
    </div>

    <!-- Card Pesan -->
    <div class="row mt-4">
        <div class="col-md-8">
            <div class="card" style="background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); border-radius: 20px;">
                <div class="card-body">
                    <h5 style="color: white; font-weight: 600;">
                        <i class="fas fa-bullhorn" style="color: #f5576c;"></i> Pesan Dashboard
                    </h5>
                    <p style="color: rgba(255,255,255,0.3); font-size: 13px;">Ubah pesan yang tampil di card pengumuman dashboard</p>
                    
                    <form method="POST" action="{{ route('admin.settings.update') }}">
                        @csrf
                        @method('PUT')
                        
                        <div class="form-group">
                            <label style="color: rgba(255,255,255,0.6);">Pesan</label>
                            <input type="text" name="dashboard_message" class="form-control" 
                                   value="{{ session('dashboard_message', 'Selamat datang di Rendzz Panel! 🚀') }}"
                                   style="background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); border-radius: 10px; color: white; padding: 12px 15px;">
                        </div>
                        
                        <div class="form-group mt-3">
                            <button type="submit" class="btn" style="background: linear-gradient(135deg, #f093fb, #f5576c); border: none; color: white; padding: 10px 30px; border-radius: 50px;">
                                <i class="fas fa-save"></i> Simpan Pesan
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
        
        <div class="col-md-4">
            <div class="card" style="background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); border-radius: 20px;">
                <div class="card-body text-center">
                    <i class="fas fa-lightbulb" style="font-size: 40px; color: #f5576c;"></i>
                    <h6 style="color: white; margin-top: 10px;">Tips</h6>
                    <p style="color: rgba(255,255,255,0.3); font-size: 13px;">
                        Gunakan emoji untuk membuat pesan lebih menarik!<br>
                        Contoh: 🚀 ✨ 📢 ⚡
                    </p>
                </div>
            </div>
        </div>
    </div>

    <!-- Clear Cache Tools -->
    <div class="row mt-4">
        <div class="col-md-12">
            <div class="card" style="background: rgba(255,255,255,0.05); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.1); border-radius: 20px;">
                <div class="card-body">
                    <h5 style="color: white; font-weight: 600;">
                        <i class="fas fa-broom" style="color: #4facfe;"></i> Tools Clear Cache
                    </h5>
                    <p style="color: rgba(255,255,255,0.3); font-size: 13px;">Bersihkan cache panel tanpa menghapus file penting</p>
                    
                    <div class="row mt-3">
                        <div class="col-md-3 col-6 mb-2">
                            <button onclick="clearCache('view')" class="btn w-100" style="background: rgba(79,172,254,0.1); border: 1px solid rgba(79,172,254,0.2); color: white; border-radius: 10px; padding: 12px;">
                                <i class="fas fa-eye"></i> View
                            </button>
                        </div>
                        <div class="col-md-3 col-6 mb-2">
                            <button onclick="clearCache('cache')" class="btn w-100" style="background: rgba(46,213,115,0.1); border: 1px solid rgba(46,213,115,0.2); color: white; border-radius: 10px; padding: 12px;">
                                <i class="fas fa-database"></i> Cache
                            </button>
                        </div>
                        <div class="col-md-3 col-6 mb-2">
                            <button onclick="clearCache('config')" class="btn w-100" style="background: rgba(245,87,108,0.1); border: 1px solid rgba(245,87,108,0.2); color: white; border-radius: 10px; padding: 12px;">
                                <i class="fas fa-cog"></i> Config
                            </button>
                        </div>
                        <div class="col-md-3 col-6 mb-2">
                            <button onclick="clearCache('all')" class="btn w-100" style="background: linear-gradient(135deg, rgba(240,147,251,0.2), rgba(245,87,108,0.2)); border: 1px solid rgba(245,87,108,0.3); color: white; border-radius: 10px; padding: 12px;">
                                <i class="fas fa-bolt"></i> All
                            </button>
                        </div>
                    </div>
                    
                    <div id="clear-status" class="mt-3" style="display: none; padding: 12px; border-radius: 10px; background: rgba(46,213,115,0.1); border: 1px solid rgba(46,213,115,0.2); color: #2ed573;">
                        <i class="fas fa-check-circle"></i> <span id="status-message">Cache berhasil dibersihkan!</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
function clearCache(type) {
    const statusDiv = document.getElementById('clear-status');
    const statusMsg = document.getElementById('status-message');
    
    statusDiv.style.display = 'block';
    statusMsg.innerHTML = '⏳ Sedang memproses...';
    statusMsg.style.color = '#ffa502';
    
    fetch('{{ route("admin.clear.cache") }}', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': '{{ csrf_token() }}'
        },
        body: JSON.stringify({ type: type })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            statusMsg.innerHTML = '✅ ' + data.message;
            statusMsg.style.color = '#2ed573';
        } else {
            statusMsg.innerHTML = '❌ ' + data.message;
            statusMsg.style.color = '#ff4757';
        }
    })
    .catch(error => {
        statusMsg.innerHTML = '❌ Error: ' + error;
        statusMsg.style.color = '#ff4757';
    });
}
</script>
@endsection
EOF

    echo -e "${GREEN}[✓] Settings Page berhasil dibuat!${NC}"
}

# ============================================
# FITUR 3: ROUTES CUSTOM
# ============================================

add_custom_routes() {
    echo -e "${CYAN}[*] Menambahkan routes custom...${NC}"
    
    ROUTES_FILE="$PANEL_DIR/routes/web.php"
    
    # Backup routes
    cp $ROUTES_FILE $ROUTES_FILE.bak
    
    # Cek apakah route sudah ada
    if grep -q "admin.settings.update" $ROUTES_FILE; then
        echo -e "${YELLOW}[!] Routes sudah ada, skip...${NC}"
        return
    fi
    
    # Tambahkan routes di bagian admin
    cat >> $ROUTES_FILE << 'EOF'

// ============================================
// RENDZZ PANEL CUSTOM ROUTES
// ============================================

Route::group(['prefix' => 'admin', 'middleware' => ['auth', 'admin']], function () {
    Route::get('/settings', function () {
        return view('admin.settings-custom');
    })->name('admin.settings');
    
    Route::put('/settings/update', function () {
        $message = request('dashboard_message', 'Selamat datang di Rendzz Panel! 🚀');
        session(['dashboard_message' => $message]);
        return redirect()->route('admin.settings')->with('success', 'Pesan berhasil diupdate!');
    })->name('admin.settings.update');
    
    Route::post('/clear-cache', function () {
        try {
            $type = request('type', 'all');
            
            switch($type) {
                case 'view':
                    \Artisan::call('view:clear');
                    $msg = 'View cache cleared!';
                    break;
                case 'cache':
                    \Artisan::call('cache:clear');
                    $msg = 'Application cache cleared!';
                    break;
                case 'config':
                    \Artisan::call('config:clear');
                    $msg = 'Config cache cleared!';
                    break;
                default:
                    \Artisan::call('view:clear');
                    \Artisan::call('cache:clear');
                    \Artisan::call('config:clear');
                    $msg = 'All caches cleared!';
            }
            
            return response()->json([
                'success' => true,
                'message' => $msg
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error: ' . $e->getMessage()
            ]);
        }
    })->name('admin.clear.cache');
});
EOF

    echo -e "${GREEN}[✓] Routes custom berhasil ditambahkan!${NC}"
}

# ============================================
# FITUR 4: TAMBAH MENU SETTINGS DI SIDEBAR
# ============================================

add_sidebar_menu() {
    echo -e "${CYAN}[*] Menambahkan menu Settings di sidebar...${NC}"
    
    LAYOUT_FILE="$PANEL_DIR/resources/views/layouts/admin.blade.php"
    
    if [ ! -f "$LAYOUT_FILE" ]; then
        echo -e "${RED}[✗] Layout admin tidak ditemukan!${NC}"
        return
    fi
    
    # Backup layout
    cp $LAYOUT_FILE $LAYOUT_FILE.bak
    
    # Cek apakah menu sudah ada
    if grep -q "admin.settings" $LAYOUT_FILE; then
        echo -e "${YELLOW}[!] Menu Settings sudah ada, skip...${NC}"
        return
    fi
    
    # Tambah menu di sidebar (cari navigation section)
    sed -i '/<ul class="navbar-nav/i <!-- RENDZZ PANEL CUSTOM MENU -->\n<li class="nav-item">\n    <a class="nav-link" href="{{ route(\"admin.settings\") }}">\n        <i class="fas fa-sliders-h"></i> <span>Custom Settings</span>\n    </a>\n</li>' $LAYOUT_FILE
    
    echo -e "${GREEN}[✓] Menu Settings ditambahkan di sidebar!${NC}"
}

# ============================================
# FITUR 5: CLEAR CACHE TOOLS (SAFE)
# ============================================

create_clear_cache_tool() {
    echo -e "${CYAN}[*] Membuat Clear Cache Tools...${NC}"
    
    # Buat script clear cache terpisah (ga ngaruh ke file)
    cat > $PANEL_DIR/clear-cache.sh << 'EOF'
#!/bin/bash
# RENDZZ PANEL - SAFE CLEAR CACHE
# GA HAPUS FILE PENTING, CUMA CLEAR CACHE

PANEL_DIR="/var/www/pterodactyl"

echo "========================================="
echo "   RENDZZ PANEL - CLEAR CACHE TOOLS     "
echo "========================================="
echo ""

echo "[*] View Cache..."
cd $PANEL_DIR && php artisan view:clear

echo "[*] Application Cache..."
php artisan cache:clear

echo "[*] Config Cache..."
php artisan config:clear

echo "[*] Route Cache..."
php artisan route:clear

echo ""
echo "✅ ALL CACHES CLEARED! (File panel aman)"
echo "========================================="
EOF

    chmod +x $PANEL_DIR/clear-cache.sh
    
    echo -e "${GREEN}[✓] Clear Cache Tools siap!${NC}"
    echo -e "${YELLOW}[!] Jalankan: bash $PANEL_DIR/clear-cache.sh${NC}"
}

# ============================================
# INSTALL SEMUA FITUR
# ============================================

install_all() {
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}   INSTALL RENDZZ PANEL FULL         ${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    
    # Backup otomatis
    auto_backup
    
    # Install fitur
    create_message_card
    create_settings_page
    add_custom_routes
    add_sidebar_menu
    create_clear_cache_tool
    
    # Clear cache
    cd $PANEL_DIR
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}[✓] INSTALL SELESAI!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}Fitur:${NC}"
    echo -e "  📢 Card Pesan di Dashboard"
    echo -e "  ⚙️ Custom Settings (ganti pesan)"
    echo -e "  🧹 Clear Cache Tools (aman)"
    echo -e "  📍 Menu Settings di Sidebar"
    echo -e "  🔧 Script clear-cache.sh"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}[!] Akses Settings: /admin/settings${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# ============================================
# UNINSTALL
# ============================================

uninstall_all() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}        UNINSTALL CUSTOM               ${NC}"
    echo -e "${RED}========================================${NC}"
    
    LAST_BACKUP=$(cat /tmp/last_full_backup.txt 2>/dev/null)
    
    if [ -z "$LAST_BACKUP" ] || [ ! -d "$LAST_BACKUP" ]; then
        echo -e "${YELLOW}[!] Backup tidak ditemukan!${NC}"
        echo -e "${YELLOW}[!] Hapus manual:${NC}"
        echo -e "  - Hapus routes custom dari web.php"
        echo -e "  - Hapus menu dari layout admin.blade.php"
        echo -e "  - Hapus file settings-custom.blade.php"
        return 1
    fi
    
    echo -e "${YELLOW}[*] Restore dari: $LAST_BACKUP${NC}"
    read -p "Yakin? (y/n): " confirm
    
    if [[ $confirm != "y" ]]; then
        echo -e "${RED}[✗] Dibatalkan${NC}"
        return
    fi
    
    # Restore semua file
    cp -r $LAST_BACKUP/admin/* $PANEL_DIR/resources/views/admin/ 2>/dev/null
    cp -r $LAST_BACKUP/layouts/* $PANEL_DIR/resources/views/layouts/ 2>/dev/null
    cp $LAST_BACKUP/app.css $PANEL_DIR/public/css/ 2>/dev/null
    
    # Restore routes (hapus custom routes)
    if [ -f "$PANEL_DIR/routes/web.php.bak" ]; then
        cp $PANEL_DIR/routes/web.php.bak $PANEL_DIR/routes/web.php
    fi
    
    # Hapus file custom
    rm -f $PANEL_DIR/resources/views/admin/settings-custom.blade.php
    rm -f $PANEL_DIR/clear-cache.sh
    
    cd $PANEL_DIR
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    
    echo -e "${GREEN}[✓] UNINSTALL SELESAI!${NC}"
}

# ============================================
# MENU UTAMA
# ============================================

while true; do
    clear
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║    RENDZZ PANEL FULL CUSTOMIZER      ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}┌─────────────── MENU ──────────────────┐${NC}"
    echo -e "${CYAN}│${NC} 1. ${GREEN}Install ALL${NC}       - Pasang semua fitur"
    echo -e "${CYAN}│${NC} 2. ${RED}Uninstall${NC}       - Hapus semua custom"
    echo -e "${CYAN}│${NC} 3. ${YELLOW}Backup${NC}          - Backup manual"
    echo -e "${CYAN}│${NC} 4. ${BLUE}Clear Cache${NC}      - Bersihkan cache (aman)"
    echo -e "${CYAN}│${NC} 5. ${BLUE}Status${NC}           - Cek status"
    echo -e "${CYAN}│${NC} 6. ${MAGENTA}Exit${NC}           - Keluar"
    echo -e "${CYAN}└──────────────────────────────────────┘${NC}"
    echo ""
    read -p "Pilih menu [1-6]: " menu
    
    case $menu in
        1)
            install_all
            ;;
        2)
            uninstall_all
            ;;
        3)
            auto_backup
            ;;
        4)
            echo -e "${YELLOW}[*] Clear cache...${NC}"
            cd $PANEL_DIR
            php artisan view:clear
            php artisan cache:clear
            php artisan config:clear
            php artisan route:clear
            echo -e "${GREEN}[✓] Cache bersih!${NC}"
            ;;
        5)
            echo -e "${BLUE}========================================${NC}"
            if [ -f "$PANEL_DIR/resources/views/admin/settings-custom.blade.php" ]; then
                echo -e "${GREEN}[✓] Status: CUSTOM TERPASANG${NC}"
                echo -e "${GREEN}[✓] Settings: /admin/settings${NC}"
            else
                echo -e "${RED}[✗] Status: DEFAULT${NC}"
            fi
            echo -e "${YELLOW}Backup: $(cat /tmp/last_full_backup.txt 2>/dev/null || echo 'Tidak ada')${NC}"
            ;;
        6)
            echo -e "${GREEN}Bye bye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[✗] Pilihan tidak valid${NC}"
            ;;
    esac
    
    echo ""
    read -p "Tekan Enter untuk kembali..."
done
