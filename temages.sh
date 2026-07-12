#!/bin/bash
# ptero-ultimate-customizer.sh

PANEL_DIR="/var/www/pterodactyl"
LOGO_URL="https://files.catbox.moe/nig1j1.jpg"
COPYRIGHT_TEXT="Rendzz Panel"
BACKUP_DIR="/root/backup-ptero-ultimate"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ============================================
# FUNGSI BACKUP
# ============================================

backup_all() {
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/backup-$TIMESTAMP"
    mkdir -p $BACKUP_PATH
    
    echo -e "${YELLOW}[*] Backup semua file...${NC}"
    cp -r $PANEL_DIR/public/images $BACKUP_PATH/ 2>/dev/null
    cp -r $PANEL_DIR/resources/views $BACKUP_PATH/ 2>/dev/null
    cp -r $PANEL_DIR/public/css $BACKUP_PATH/ 2>/dev/null
    cp $PANEL_DIR/public/favicon.ico $BACKUP_PATH/ 2>/dev/null
    
    echo -e "${GREEN}[✓] Backup di: $BACKUP_PATH${NC}"
    echo "$BACKUP_PATH" > /tmp/last_backup_ultimate.txt
}

# ============================================
# 1. CUSTOM CSS (TANPA BACKGROUND)
# ============================================

custom_css() {
    echo -e "${CYAN}[*] Membuat custom CSS (tanpa background)...${NC}"
    
    cat > $PANEL_DIR/public/css/custom-ultimate.css << 'EOF'
/* ========================================
   RENDZZ PANEL ULTIMATE CUSTOM CSS
   BACKGROUND TETEP PAKE FOTO SENDIRI
   ======================================== */

/* ----- NAVBAR ----- */
.navbar {
    background: rgba(0, 0, 0, 0.7) !important;
    backdrop-filter: blur(20px) !important;
    -webkit-backdrop-filter: blur(20px) !important;
    border-bottom: 2px solid rgba(255, 255, 255, 0.1) !important;
    box-shadow: 0 10px 40px rgba(0,0,0,0.5) !important;
}

.navbar-brand {
    font-weight: 800 !important;
    font-size: 1.5rem !important;
    background: linear-gradient(135deg, #f093fb, #f5576c, #4facfe) !important;
    -webkit-background-clip: text !important;
    -webkit-text-fill-color: transparent !important;
    background-clip: text !important;
}

/* ----- CARDS (LIST SERVER) SUPER KEREN ----- */
.card {
    background: rgba(0, 0, 0, 0.6) !important;
    backdrop-filter: blur(15px) !important;
    -webkit-backdrop-filter: blur(15px) !important;
    border: 1px solid rgba(255, 255, 255, 0.15) !important;
    border-radius: 25px !important;
    transition: all 0.5s cubic-bezier(0.175, 0.885, 0.32, 1.275) !important;
    color: white !important;
    overflow: hidden;
    position: relative;
    box-shadow: 0 10px 40px rgba(0,0,0,0.3) !important;
}

.card:hover {
    transform: translateY(-15px) scale(1.03) !important;
    box-shadow: 0 20px 60px rgba(245, 87, 108, 0.4) !important;
    border-color: rgba(245, 87, 108, 0.4) !important;
}

/* Border glow animasi di card */
.card::before {
    content: '';
    position: absolute;
    top: -2px;
    left: -2px;
    right: -2px;
    bottom: -2px;
    background: linear-gradient(45deg, #f093fb, #f5576c, #4facfe, #43e97b);
    background-size: 400% 400%;
    border-radius: 25px;
    z-index: -1;
    animation: borderGlow 4s ease-in-out infinite;
    opacity: 0;
    transition: opacity 0.5s;
}

.card:hover::before {
    opacity: 1;
}

@keyframes borderGlow {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
}

/* Server icon di card */
.server-icon {
    font-size: 60px;
    margin: 15px 0;
    display: block;
    text-align: center;
    filter: drop-shadow(0 0 20px rgba(245, 87, 108, 0.3));
}

/* Status badge */
.badge-status {
    position: absolute;
    top: 15px;
    right: 15px;
    padding: 5px 15px;
    border-radius: 50px;
    font-size: 12px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
}

.badge-online {
    background: rgba(46, 213, 115, 0.3) !important;
    border: 1px solid #2ed573;
    color: #2ed573 !important;
    animation: pulseGreen 2s infinite;
}

.badge-offline {
    background: rgba(255, 71, 87, 0.3) !important;
    border: 1px solid #ff4757;
    color: #ff4757 !important;
}

.badge-installing {
    background: rgba(255, 165, 0, 0.3) !important;
    border: 1px solid #ffa502;
    color: #ffa502 !important;
    animation: pulseOrange 1.5s infinite;
}

@keyframes pulseGreen {
    0%, 100% { box-shadow: 0 0 20px rgba(46, 213, 115, 0.2); }
    50% { box-shadow: 0 0 40px rgba(46, 213, 115, 0.4); }
}

@keyframes pulseOrange {
    0%, 100% { box-shadow: 0 0 20px rgba(255, 165, 0, 0.2); }
    50% { box-shadow: 0 0 40px rgba(255, 165, 0, 0.4); }
}

/* Progress bar keren */
.progress-custom {
    height: 6px;
    border-radius: 10px;
    background: rgba(255, 255, 255, 0.1) !important;
    overflow: hidden;
    margin-top: 8px;
}

.progress-custom .progress-bar {
    border-radius: 10px;
    transition: width 1s ease-in-out;
}

/* Server name */
.server-name {
    font-size: 18px;
    font-weight: 700;
    text-align: center;
    margin: 10px 0 5px;
    background: linear-gradient(135deg, #fff, #a8a8a8);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
}

/* Tombol manage */
.btn-manage {
    background: linear-gradient(135deg, #f093fb, #f5576c) !important;
    border: none !important;
    border-radius: 50px !important;
    padding: 8px 25px !important;
    font-weight: 700 !important;
    color: white !important;
    transition: all 0.3s !important;
    width: 100%;
}

.btn-manage:hover {
    transform: scale(1.05) !important;
    box-shadow: 0 10px 30px rgba(245, 87, 108, 0.4) !important;
}

/* ----- FOOTER ----- */
.footer {
    background: rgba(0, 0, 0, 0.7) !important;
    backdrop-filter: blur(10px) !important;
    border-top: 1px solid rgba(255, 255, 255, 0.1) !important;
    padding: 20px 0 !important;
    color: rgba(255,255,255,0.7) !important;
}

.footer a {
    color: #f5576c !important;
    text-decoration: none !important;
    transition: color 0.3s;
}

.footer a:hover {
    color: #f093fb !important;
}

/* ----- SIDEBAR ----- */
.sidebar {
    background: rgba(0, 0, 0, 0.7) !important;
    backdrop-filter: blur(10px) !important;
    border-right: 1px solid rgba(255, 255, 255, 0.1) !important;
}

.sidebar .nav-link {
    color: rgba(255,255,255,0.6) !important;
    transition: all 0.3s !important;
    border-radius: 10px !important;
    margin: 5px 10px !important;
}

.sidebar .nav-link:hover {
    background: rgba(245, 87, 108, 0.2) !important;
    color: white !important;
    transform: translateX(5px);
}

.sidebar .nav-link.active {
    background: linear-gradient(135deg, rgba(240, 147, 251, 0.3), rgba(245, 87, 108, 0.3)) !important;
    color: white !important;
    border: 1px solid rgba(245, 87, 108, 0.3);
}

/* ----- BUTTONS ----- */
.btn-primary {
    background: linear-gradient(135deg, #f093fb, #f5576c) !important;
    border: none !important;
    border-radius: 50px !important;
    transition: all 0.3s !important;
}

.btn-primary:hover {
    transform: scale(1.05) !important;
    box-shadow: 0 10px 30px rgba(245, 87, 108, 0.4) !important;
}

/* ----- TABLE (kalo pake style list) ----- */
.table {
    color: white !important;
}

.table thead {
    background: rgba(245, 87, 108, 0.2) !important;
    border-radius: 15px !important;
}

.table tbody tr {
    transition: all 0.3s !important;
    border-bottom: 1px solid rgba(255, 255, 255, 0.05) !important;
}

.table tbody tr:hover {
    background: rgba(245, 87, 108, 0.1) !important;
    transform: scale(1.01);
}

/* ----- TITLE PAGE ----- */
.page-title {
    font-weight: 800 !important;
    background: linear-gradient(135deg, #f093fb, #f5576c, #4facfe) !important;
    -webkit-background-clip: text !important;
    -webkit-text-fill-color: transparent !important;
    background-clip: text !important;
    text-shadow: none !important;
}

/* ----- SCROLLBAR KEREN ----- */
::-webkit-scrollbar {
    width: 8px;
}

::-webkit-scrollbar-track {
    background: rgba(0, 0, 0, 0.3);
    border-radius: 10px;
}

::-webkit-scrollbar-thumb {
    background: linear-gradient(135deg, #f093fb, #f5576c);
    border-radius: 10px;
}

::-webkit-scrollbar-thumb:hover {
    background: linear-gradient(135deg, #f5576c, #f093fb);
}
EOF

    # Inject CSS ke layout
    echo -e "${YELLOW}[*] Inject CSS ke layout...${NC}"
    LAYOUT_FILE="$PANEL_DIR/resources/views/layouts/admin.blade.php"
    
    if [ -f "$LAYOUT_FILE" ]; then
        # Cek apakah sudah ada custom css
        if ! grep -q "custom-ultimate.css" "$LAYOUT_FILE"; then
            sed -i '/<\/head>/i <link rel="stylesheet" href="{{ asset("css/custom-ultimate.css") }}">' "$LAYOUT_FILE"
        fi
    fi
    
    echo -e "${GREEN}[✓] Custom CSS selesai!${NC}"
}

# ============================================
# 2. STYLE LIST SERVER - CARDS (MODERN)
# ============================================

style_cards_modern() {
    echo -e "${CYAN}[*] Menerapkan Style: Modern Cards${NC}"
    
    cat > $PANEL_DIR/resources/views/admin/servers.blade.php << 'EOF'
@extends('layouts.admin')

@section('title', 'Servers')

@section('content')
<div class="container-fluid">
    <!-- Header -->
    <div class="row mb-4">
        <div class="col-md-12">
            <h3 class="page-title">🚀 My Servers</h3>
            <p class="text-muted">Total: {{ $servers->count() }} servers</p>
        </div>
    </div>

    <!-- Stats -->
    <div class="row mb-4">
        <div class="col-md-3 col-6">
            <div class="card p-3 text-center">
                <h5>🟢 Online</h5>
                <h3 class="text-success">{{ $servers->where('status', 'online')->count() }}</h3>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card p-3 text-center">
                <h5>🔴 Offline</h5>
                <h3 class="text-danger">{{ $servers->where('status', 'offline')->count() }}</h3>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card p-3 text-center">
                <h5>🟡 Installing</h5>
                <h3 class="text-warning">{{ $servers->where('status', 'installing')->count() }}</h3>
            </div>
        </div>
        <div class="col-md-3 col-6">
            <div class="card p-3 text-center">
                <h5>💾 Total</h5>
                <h3 class="text-info">{{ $servers->count() }}</h3>
            </div>
        </div>
    </div>

    <!-- Server Cards -->
    <div class="row">
        @foreach($servers as $server)
        <div class="col-lg-3 col-md-4 col-sm-6 mb-4">
            <div class="card h-100">
                <div class="card-body">
                    <!-- Status Badge -->
                    @if($server->status == 'online')
                        <span class="badge-status badge-online">● Online</span>
                    @elseif($server->status == 'offline')
                        <span class="badge-status badge-offline">● Offline</span>
                    @else
                        <span class="badge-status badge-installing">● Installing</span>
                    @endif

                    <!-- Icon -->
                    <span class="server-icon">
                        @if($server->status == 'online')
                            🖥️
                        @elseif($server->status == 'offline')
                            💤
                        @else
                            ⚙️
                        @endif
                    </span>

                    <!-- Name -->
                    <div class="server-name">{{ $server->name }}</div>
                    <p class="text-center text-muted" style="font-size: 12px;">
                        {{ $server->node->name ?? 'N/A' }}
                    </p>

                    <!-- CPU -->
                    <div style="margin-top: 15px;">
                        <div style="display: flex; justify-content: space-between;">
                            <small>CPU</small>
                            <small>{{ $server->cpu }}%</small>
                        </div>
                        <div class="progress-custom">
                            <div class="progress-bar bg-success" style="width: {{ $server->cpu }}%;"></div>
                        </div>
                    </div>

                    <!-- RAM -->
                    <div style="margin-top: 10px;">
                        <div style="display: flex; justify-content: space-between;">
                            <small>RAM</small>
                            <small>{{ $server->memory }}%</small>
                        </div>
                        <div class="progress-custom">
                            <div class="progress-bar bg-info" style="width: {{ $server->memory }}%;"></div>
                        </div>
                    </div>

                    <!-- Disk -->
                    <div style="margin-top: 10px; margin-bottom: 15px;">
                        <div style="display: flex; justify-content: space-between;">
                            <small>Disk</small>
                            <small>{{ $server->disk }}%</small>
                        </div>
                        <div class="progress-custom">
                            <div class="progress-bar bg-warning" style="width: {{ $server->disk }}%;"></div>
                        </div>
                    </div>

                    <!-- Manage Button -->
                    <a href="{{ route('server.show', $server->id) }}" class="btn-manage">
                        ⚡ Manage
                    </a>
                </div>
            </div>
        </div>
        @endforeach
    </div>
</div>
@endsection
EOF

    php artisan view:clear
    echo -e "${GREEN}[✓] Style Modern Cards applied!${NC}"
}

# ============================================
# 3. STYLE LIST SERVER - DARK TABLE
# ============================================

style_table_dark() {
    echo -e "${CYAN}[*] Menerapkan Style: Dark Table${NC}"
    
    cat > $PANEL_DIR/resources/views/admin/servers.blade.php << 'EOF'
@extends('layouts.admin')

@section('title', 'Servers')

@section('content')
<div class="container-fluid">
    <div class="row mb-4">
        <div class="col-md-12">
            <h3 class="page-title">📊 Server Management</h3>
            <p class="text-muted">Total: {{ $servers->count() }} servers</p>
        </div>
    </div>

    <div class="card p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead>
                    <tr>
                        <th>Status</th>
                        <th>Server</th>
                        <th>Node</th>
                        <th>CPU</th>
                        <th>RAM</th>
                        <th>Disk</th>
                        <th>Uptime</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    @foreach($servers as $server)
                    <tr>
                        <td>
                            @if($server->status == 'online')
                                <span class="badge-status badge-online" style="padding: 3px 12px;">🟢</span>
                            @elseif($server->status == 'offline')
                                <span class="badge-status badge-offline" style="padding: 3px 12px;">🔴</span>
                            @else
                                <span class="badge-status badge-installing" style="padding: 3px 12px;">🟡</span>
                            @endif
                        </td>
                        <td>
                            <strong>{{ $server->name }}</strong>
                            <br>
                            <small class="text-muted">{{ $server->description ?? 'No description' }}</small>
                        </td>
                        <td>{{ $server->node->name ?? 'N/A' }}</td>
                        <td style="min-width: 120px;">
                            <div class="progress-custom" style="width: 100px;">
                                <div class="progress-bar bg-success" style="width: {{ $server->cpu }}%;">{{ $server->cpu }}%</div>
                            </div>
                        </td>
                        <td style="min-width: 120px;">
                            <div class="progress-custom" style="width: 100px;">
                                <div class="progress-bar bg-info" style="width: {{ $server->memory }}%;">{{ $server->memory }}%</div>
                            </div>
                        </td>
                        <td style="min-width: 120px;">
                            <div class="progress-custom" style="width: 100px;">
                                <div class="progress-bar bg-warning" style="width: {{ $server->disk }}%;">{{ $server->disk }}%</div>
                            </div>
                        </td>
                        <td>
                            <small>{{ rand(1, 30) }} days</small>
                        </td>
                        <td>
                            <a href="{{ route('server.show', $server->id) }}" class="btn btn-primary btn-sm">Manage</a>
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
EOF

    php artisan view:clear
    echo -e "${GREEN}[✓] Style Dark Table applied!${NC}"
}

# ============================================
# 4. STYLE LIST SERVER - ANIMATED
# ============================================

style_animated() {
    echo -e "${CYAN}[*] Menerapkan Style: Animated Cards${NC}"
    
    cat > $PANEL_DIR/resources/views/admin/servers.blade.php << 'EOF'
@extends('layouts.admin')

@section('title', 'Servers')

@section('content')
<style>
.server-card-animated {
    animation: fadeInUp 0.6s ease forwards;
    opacity: 0;
}
.server-card-animated:nth-child(1) { animation-delay: 0.1s; }
.server-card-animated:nth-child(2) { animation-delay: 0.2s; }
.server-card-animated:nth-child(3) { animation-delay: 0.3s; }
.server-card-animated:nth-child(4) { animation-delay: 0.4s; }
.server-card-animated:nth-child(5) { animation-delay: 0.5s; }
.server-card-animated:nth-child(6) { animation-delay: 0.6s; }
.server-card-animated:nth-child(7) { animation-delay: 0.7s; }
.server-card-animated:nth-child(8) { animation-delay: 0.8s; }
.server-card-animated:nth-child(9) { animation-delay: 0.9s; }
.server-card-animated:nth-child(10) { animation-delay: 1.0s; }

@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translateY(50px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.status-indicator {
    display: inline-block;
    width: 12px;
    height: 12px;
    border-radius: 50%;
    margin-right: 5px;
    animation: blink 1.5s infinite;
}

@keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
}
</style>

<div class="container-fluid">
    <div class="row mb-4">
        <div class="col-md-12">
            <h3 class="page-title">✨ Server Dashboard</h3>
            <p class="text-muted">Total: {{ $servers->count() }} servers</p>
        </div>
    </div>

    <div class="row">
        @foreach($servers as $server)
        <div class="col-lg-3 col-md-4 col-sm-6 mb-4 server-card-animated">
            <div class="card h-100">
                <div class="card-body text-center">
                    <!-- Status -->
                    <div class="mb-2">
                        <span class="status-indicator" style="background: {{ $server->status == 'online' ? '#2ed573' : ($server->status == 'offline' ? '#ff4757' : '#ffa502') }};"></span>
                        <span style="text-transform: uppercase; font-size: 11px; font-weight: 700;">
                            {{ $server->status }}
                        </span>
                    </div>

                    <!-- Icon -->
                    <div style="font-size: 55px; margin: 10px 0;">
                        @if($server->status == 'online')
                            🎮
                        @elseif($server->status == 'offline')
                            💀
                        @else
                            🔧
                        @endif
                    </div>

                    <!-- Name -->
                    <h5 class="server-name">{{ $server->name }}</h5>
                    <small class="text-muted">{{ $server->node->name ?? 'N/A' }}</small>

                    <!-- Specs -->
                    <div class="mt-3" style="display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 5px;">
                        <div>
                            <small>CPU</small>
                            <div><strong>{{ $server->cpu }}%</strong></div>
                        </div>
                        <div>
                            <small>RAM</small>
                            <div><strong>{{ $server->memory }}%</strong></div>
                        </div>
                        <div>
                            <small>DISK</small>
                            <div><strong>{{ $server->disk }}%</strong></div>
                        </div>
                    </div>

                    <!-- Progress Bars -->
                    <div class="mt-2">
                        <div class="progress-custom">
                            <div class="progress-bar bg-success" style="width: {{ $server->cpu }}%;"></div>
                        </div>
                        <div class="progress-custom" style="margin-top: 3px;">
                            <div class="progress-bar bg-info" style="width: {{ $server->memory }}%;"></div>
                        </div>
                        <div class="progress-custom" style="margin-top: 3px;">
                            <div class="progress-bar bg-warning" style="width: {{ $server->disk }}%;"></div>
                        </div>
                    </div>

                    <!-- Button -->
                    <a href="{{ route('server.show', $server->id) }}" class="btn-manage mt-3" style="display: block;">
                        🚀 Manage
                    </a>
                </div>
            </div>
        </div>
        @endforeach
    </div>
</div>
@endsection
EOF

    php artisan view:clear
    echo -e "${GREEN}[✓] Style Animated Cards applied!${NC}"
}

# ============================================
# 5. CUSTOM FAVICON
# ============================================

custom_favicon() {
    echo -e "${CYAN}[*] Mengganti favicon...${NC}"
    
    # Download favicon dari logo
    cd /tmp
    wget -q -O favicon.png $LOGO_URL
    if command -v convert &> /dev/null; then
        convert favicon.png -resize 32x32 favicon.ico
        cp favicon.ico $PANEL_DIR/public/favicon.ico
        echo -e "${GREEN}[✓] Favicon diganti!${NC}"
    else
        echo -e "${YELLOW}[!] ImageMagick tidak terinstall, skip favicon${NC}"
    fi
}

# ============================================
# 6. CUSTOM FOOTER
# ============================================

custom_footer() {
    echo -e "${CYAN}[*] Mengganti footer...${NC}"
    
    FOOTER_FILE="$PANEL_DIR/resources/views/layouts/admin.blade.php"
    if [ -f "$FOOTER_FILE" ]; then
        sed -i "s/Pterodactyl®.*<\/div>/Rendzz Panel © 2026 - Made with ❤️ by Rendzz<\/div>/g" "$FOOTER_FILE"
        echo -e "${GREEN}[✓] Footer diubah!${NC}"
    fi
}

# ============================================
# 7. INSTALL SEMUA
# ============================================

install_all() {
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}   INSTALL ULTIMATE CUSTOMIZATION    ${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    
    # Backup dulu
    backup_all
    
    # Download logo
    echo -e "${YELLOW}[*] Download logo...${NC}"
    cd /tmp
    wget -q --show-progress -O logo.jpg $LOGO_URL
    if [ -f "logo.jpg" ]; then
        if command -v convert &> /dev/null; then
            convert logo.jpg logo.png
        else
            cp logo.jpg logo.png
        fi
        cp logo.png $PANEL_DIR/public/images/logo.png
        cp logo.png $PANEL_DIR/public/images/logo-dark.png 2>/dev/null || true
        echo -e "${GREEN}[✓] Logo diganti${NC}"
    fi
    
    # Ganti copyright
    echo -e "${YELLOW}[*] Ganti copyright...${NC}"
    cd $PANEL_DIR
    find resources/views -name "*.blade.php" -exec sed -i "s/Pterodactyl Panel/$COPYRIGHT_TEXT/g" {} \;
    find resources/views -name "*.blade.php" -exec sed -i "s/Pterodactyl®/$COPYRIGHT_TEXT/g" {} \;
    find resources/views -name "*.blade.php" -exec sed -i "s/Pterodactyl Inc./$COPYRIGHT_TEXT/g" {} \;
    find resources/views -name "*.blade.php" -exec sed -i "s/<title>Pterodactyl/<title>$COPYRIGHT_TEXT/g" {} \;
    
    # Custom CSS
    custom_css
    
    # Custom favicon
    custom_favicon
    
    # Custom footer
    custom_footer
    
    # Style default (cards modern)
    style_cards_modern
    
    # Clear cache
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    
    touch /tmp/rendzz_ultimate_installed
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}[✓] INSTALL ULTIMATE SELESAI!${NC}"
    echo -e "${GREEN}[✓] Panel sekarang: $COPYRIGHT_TEXT${NC}"
    echo -e "${GREEN}[✓] Tampilan server: Modern Cards${NC}"
    echo -e "${YELLOW}[!] Ganti style lewat menu${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# ============================================
# 8. UNINSTALL
# ============================================

uninstall_all() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}        UNINSTALL ULTIMATE             ${NC}"
    echo -e "${RED}========================================${NC}"
    
    LAST_BACKUP=$(cat /tmp/last_backup_ultimate.txt 2>/dev/null)
    
    if [ -z "$LAST_BACKUP" ] || [ ! -d "$LAST_BACKUP" ]; then
        echo -e "${YELLOW}[!] Backup tidak ditemukan, restore manual?${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}[*] Restore dari: $LAST_BACKUP${NC}"
    read -p "Yakin? (y/n): " confirm
    if [[ $confirm != "y" ]]; then
        echo -e "${RED}[✗] Dibatalkan${NC}"
        return
    fi
    
    # Restore
    cp -r $LAST_BACKUP/images/* $PANEL_DIR/public/images/ 2>/dev/null
    cp -r $LAST_BACKUP/views/* $PANEL_DIR/resources/views/ 2>/dev/null
    cp -r $LAST_BACKUP/css/* $PANEL_DIR/public/css/ 2>/dev/null
    cp $LAST_BACKUP/favicon.ico $PANEL_DIR/public/ 2>/dev/null
    
    # Hapus custom css dari layout
    sed -i '/custom-ultimate.css/d' $PANEL_DIR/resources/views/layouts/admin.blade.php
    
    cd $PANEL_DIR
    php artisan view:clear
    php artisan cache:clear
    
    rm -f /tmp/rendzz_ultimate_installed
    
    echo -e "${GREEN}[✓] UNINSTALL SELESAI! Panel kembali default${NC}"
}

# ============================================
# 9. MENU STYLE
# ============================================

menu_style() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   PILIH TAMPILAN LIST SERVER         ${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "1. ${CYAN}Modern Cards${NC} - Card dengan efek glow & blur"
    echo -e "2. ${GREEN}Dark Table${NC} - Tabel dark mode"
    echo -e "3. ${MAGENTA}Animated Cards${NC} - Card dengan animasi fade in"
    echo -e "4. ${RED}Default${NC} - Kembali ke default"
    echo -e "5. ${BLUE}Back${NC}"
    echo -e "========================================"
    read -p "Pilih [1-5]: " choice
    
    case $choice in
        1)
            backup_all
            style_cards_modern
            echo -e "${GREEN}[✓] Style diubah ke Modern Cards${NC}"
            ;;
        2)
            backup_all
            style_table_dark
            echo -e "${GREEN}[✓] Style diubah ke Dark Table${NC}"
            ;;
        3)
            backup_all
            style_animated
            echo -e "${GREEN}[✓] Style diubah ke Animated Cards${NC}"
            ;;
        4)
            # Restore default dari backup terakhir
            LAST_BACKUP=$(cat /tmp/last_backup_ultimate.txt 2>/dev/null)
            if [ -d "$LAST_BACKUP/views" ]; then
                cp $LAST_BACKUP/views/admin/servers.blade.php $PANEL_DIR/resources/views/admin/ 2>/dev/null
                echo -e "${GREEN}[✓] Kembali ke default${NC}"
            else
                echo -e "${YELLOW}[!] Backup tidak ditemukan${NC}"
            fi
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}[✗] Pilihan tidak valid${NC}"
            ;;
    esac
    
    cd $PANEL_DIR && php artisan view:clear
}

# ============================================
# 10. MENU UTAMA
# ============================================

while true; do
    clear
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║   RENDZZ PANEL ULTIMATE CUSTOMIZER   ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}┌─────────────── MENU ──────────────────┐${NC}"
    echo -e "${CYAN}│${NC} 1. ${GREEN}Install ALL${NC}     - Pasang semua custom"
    echo -e "${CYAN}│${NC} 2. ${RED}Uninstall${NC}       - Hapus semua custom"
    echo -e "${CYAN}│${NC} 3. ${YELLOW}Backup${NC}          - Backup panel"
    echo -e "${CYAN}│${NC} 4. ${BLUE}Style Server${NC}     - Ganti tampilan list server"
    echo -e "${CYAN}│${NC} 5. ${BLUE}Status${NC}          - Cek status"
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
            backup_all
            ;;
        4)
            menu_style
            ;;
        5)
            echo -e "${BLUE}========================================${NC}"
            if [ -f "/tmp/rendzz_ultimate_installed" ]; then
                echo -e "${GREEN}[✓] Status: ULTIMATE CUSTOM TERPASANG${NC}"
            else
                echo -e "${RED}[✗] Status: DEFAULT${NC}"
            fi
            echo -e "${YELLOW}Backup: $(cat /tmp/last_backup_ultimate.txt 2>/dev/null || echo 'Tidak ada')${NC}"
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
