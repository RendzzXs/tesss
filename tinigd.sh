#!/bin/bash

# -------------------------------
# RENDZZ UNIQUE EDITION v2.0 - DENGAN LOADING ANIMATION!
# -------------------------------
PTERO_DIR="/var/www/pterodactyl"
TARGET_FILE="$PTERO_DIR/resources/views/templates/base/core.blade.php"
FOOTER_FILE="$PTERO_DIR/resources/views/templates/base/footer.blade.php"
SERVER_FILE="$PTERO_DIR/resources/views/templates/base/server.blade.php"
DASHBOARD_FILE="$PTERO_DIR/resources/scripts/components/dashboard/DashboardContainer.tsx"
BACKUP_FILE="$PTERO_DIR/core.backup"
WALLPAPER_DIR="$PTERO_DIR/public/rendzz"
WALLPAPER_FILE="$WALLPAPER_DIR/bg.jpg"
INDEX_FILE="$PTERO_DIR/resources/views/welcome.blade.php"

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# -------------------------------
# FUNCTION: HEADER
# -------------------------------
show_header() {
    clear
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}║${WHITE}          🔥 RENDZZ UNIQUE EDITION v2.0 🔥   ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}           ✨ With Loading Animation ✨      ${CYAN}║${NC}"
    echo -e "${CYAN}║                                                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# -------------------------------
# FUNCTION: CREATE LOADING PAGE
# -------------------------------
create_loading_page() {
    echo -e "${YELLOW}📄 Creating loading page...${NC}"
    
    cat > "$INDEX_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🔥 Rendzz Panel</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            overflow: hidden;
        }

        .loading-container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(20px);
            border-radius: 30px;
            border: 1px solid rgba(255, 255, 255, 0.2);
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.3);
            animation: fadeIn 0.8s ease-out;
            max-width: 500px;
            width: 90%;
        }

        @keyframes fadeIn {
            from {
                opacity: 0;
                transform: scale(0.9) translateY(30px);
            }
            to {
                opacity: 1;
                transform: scale(1) translateY(0);
            }
        }

        .logo-icon {
            font-size: 80px;
            margin-bottom: 20px;
            animation: float 3s ease-in-out infinite;
        }

        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-15px); }
        }

        .welcome-text {
            color: white;
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 10px;
            text-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
        }

        .greeting-text {
            color: rgba(255, 255, 255, 0.9);
            font-size: 18px;
            margin-bottom: 30px;
            font-weight: 300;
        }

        .time-display {
            color: rgba(255, 255, 255, 0.8);
            font-size: 14px;
            margin-bottom: 25px;
            background: rgba(0, 0, 0, 0.2);
            padding: 8px 20px;
            border-radius: 50px;
            display: inline-block;
        }

        /* LOADING SPINNER */
        .spinner-wrapper {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 15px;
            margin: 30px 0 20px 0;
        }

        .spinner {
            width: 50px;
            height: 50px;
            border: 4px solid rgba(255, 255, 255, 0.1);
            border-top: 4px solid #fff;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .spinner-text {
            color: white;
            font-size: 16px;
            font-weight: 500;
        }

        /* VERIFICATION DOTS */
        .dots {
            display: inline-block;
            width: 20px;
            text-align: left;
        }

        .dots::after {
            content: '';
            animation: dots 1.5s steps(4, end) infinite;
        }

        @keyframes dots {
            0% { content: ''; }
            25% { content: '.'; }
            50% { content: '..'; }
            75% { content: '...'; }
            100% { content: ''; }
        }

        /* PROGRESS BAR */
        .progress-wrapper {
            width: 100%;
            height: 4px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            overflow: hidden;
            margin-top: 20px;
        }

        .progress-bar {
            height: 100%;
            width: 0%;
            background: linear-gradient(90deg, #f093fb, #f5576c, #4facfe);
            border-radius: 10px;
            animation: progress 3s ease-in-out forwards;
        }

        @keyframes progress {
            0% { width: 0%; }
            20% { width: 25%; }
            40% { width: 45%; }
            60% { width: 65%; }
            80% { width: 85%; }
            100% { width: 100%; }
        }

        /* VERIFICATION STATUS */
        .status-list {
            text-align: left;
            margin: 25px 0;
            padding: 0 20px;
        }

        .status-item {
            color: rgba(255, 255, 255, 0.8);
            font-size: 14px;
            padding: 8px 0;
            display: flex;
            align-items: center;
            gap: 10px;
            opacity: 0;
            animation: statusAppear 0.5s ease forwards;
        }

        .status-item:nth-child(1) { animation-delay: 0.5s; }
        .status-item:nth-child(2) { animation-delay: 1.2s; }
        .status-item:nth-child(3) { animation-delay: 1.9s; }
        .status-item:nth-child(4) { animation-delay: 2.6s; }

        @keyframes statusAppear {
            from {
                opacity: 0;
                transform: translateX(-20px);
            }
            to {
                opacity: 1;
                transform: translateX(0);
            }
        }

        .status-icon {
            font-size: 18px;
            width: 25px;
            text-align: center;
        }

        .status-check {
            color: #4ade80;
        }

        .status-loading {
            animation: pulse 1s ease-in-out infinite;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.3; }
        }

        /* PARTICLES BACKGROUND */
        .particles {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            z-index: -1;
        }

        .particle {
            position: absolute;
            width: 6px;
            height: 6px;
            background: rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            animation: particleFloat 15s infinite;
        }

        @keyframes particleFloat {
            0% { transform: translateY(100vh) rotate(0deg); opacity: 0; }
            10% { opacity: 1; }
            90% { opacity: 1; }
            100% { transform: translateY(-100vh) rotate(720deg); opacity: 0; }
        }

        /* RESPONSIVE */
        @media (max-width: 480px) {
            .welcome-text { font-size: 22px; }
            .greeting-text { font-size: 15px; }
            .loading-container { padding: 30px 20px; }
            .logo-icon { font-size: 60px; }
        }
    </style>
</head>
<body>
    <!-- PARTICLES -->
    <div class="particles" id="particles"></div>

    <div class="loading-container">
        <div class="logo-icon">🚀</div>
        <div class="welcome-text">✨ WELCOME ✨</div>
        <div class="greeting-text">
            <span id="greetingMessage">Good Morning ☀️</span>
        </div>
        <div class="time-display" id="timeDisplay">Loading...</div>

        <div class="status-list">
            <div class="status-item">
                <span class="status-icon">🔐</span>
                <span>Verifying credentials...</span>
                <span class="status-loading" style="margin-left:auto;">⏳</span>
            </div>
            <div class="status-item">
                <span class="status-icon">🛡️</span>
                <span>Securing connection...</span>
                <span class="status-loading" style="margin-left:auto;">⏳</span>
            </div>
            <div class="status-item">
                <span class="status-icon">⚡</span>
                <span>Initializing panel...</span>
                <span class="status-loading" style="margin-left:auto;">⏳</span>
            </div>
            <div class="status-item">
                <span class="status-icon">🎨</span>
                <span>Loading unique design...</span>
                <span class="status-loading" style="margin-left:auto;">⏳</span>
            </div>
        </div>

        <div class="spinner-wrapper">
            <div class="spinner"></div>
            <div class="spinner-text">
                Please wait<span class="dots"></span>
            </div>
        </div>

        <div class="progress-wrapper">
            <div class="progress-bar"></div>
        </div>
    </div>

    <script>
        // GREETING BASED ON TIME
        function updateGreeting() {
            const hour = new Date().getHours();
            const greetingMsg = document.getElementById('greetingMessage');
            let greeting = '';
            let emoji = '';
            
            if (hour >= 5 && hour < 12) {
                greeting = 'Good Morning';
                emoji = '☀️';
            } else if (hour >= 12 && hour < 17) {
                greeting = 'Good Afternoon';
                emoji = '🌤️';
            } else if (hour >= 17 && hour < 20) {
                greeting = 'Good Evening';
                emoji = '🌅';
            } else if (hour >= 20 || hour < 5) {
                greeting = 'Good Night';
                emoji = '🌙';
            }
            
            greetingMsg.textContent = greeting + ' ' + emoji;
        }

        // UPDATE TIME
        function updateTime() {
            const now = new Date();
            const options = { 
                weekday: 'long', 
                year: 'numeric', 
                month: 'long', 
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit',
                hour12: false
            };
            document.getElementById('timeDisplay').textContent = 
                '🕐 ' + now.toLocaleDateString('en-US', options);
        }

        // CREATE PARTICLES
        function createParticles() {
            const container = document.getElementById('particles');
            for (let i = 0; i < 30; i++) {
                const particle = document.createElement('div');
                particle.className = 'particle';
                particle.style.left = Math.random() * 100 + '%';
                particle.style.animationDuration = (10 + Math.random() * 20) + 's';
                particle.style.animationDelay = (Math.random() * 10) + 's';
                particle.style.width = (3 + Math.random() * 6) + 'px';
                particle.style.height = particle.style.width;
                container.appendChild(particle);
            }
        }

        // UPDATE STATUS TO CHECK MARK
        function updateStatus() {
            const items = document.querySelectorAll('.status-item');
            const loadingSpans = document.querySelectorAll('.status-loading');
            
            items.forEach((item, index) => {
                setTimeout(() => {
                    const icon = item.querySelector('.status-icon');
                    const loading = item.querySelector('.status-loading');
                    
                    // Change icon to check mark
                    const checkmarks = ['✅', '🛡️', '⚡', '🎨'];
                    icon.textContent = checkmarks[index] || '✅';
                    
                    // Remove loading animation
                    loading.className = '';
                    loading.textContent = '✅';
                    loading.style.color = '#4ade80';
                    
                    // Add success color to text
                    item.style.color = '#4ade80';
                }, (index + 1) * 700 + 500);
            });
        }

        // AUTO REDIRECT TO PANEL
        function redirectToPanel() {
            setTimeout(() => {
                window.location.href = '/';
            }, 4500);
        }

        // INIT
        updateGreeting();
        updateTime();
        createParticles();
        updateStatus();
        redirectToPanel();

        // Update time every second
        setInterval(updateTime, 1000);
    </script>
</body>
</html>
EOF

    # Set permission
    chown www-data:www-data "$INDEX_FILE" 2>/dev/null || chown nginx:nginx "$INDEX_FILE" 2>/dev/null
    chmod 644 "$INDEX_FILE"
    
    echo -e "${GREEN}✅ Loading page created!${NC}"
}

# -------------------------------
# FUNCTION: HAPUS WALLPAPER
# -------------------------------
uninstall_wallpaper() {
    show_header
    echo -e "${YELLOW}🗑️  Menghapus custom design...${NC}\n"
    
    # Hapus loading page
    if [ -f "$INDEX_FILE" ]; then
        rm -f "$INDEX_FILE"
        echo -e "${GREEN}✅ Loading page dihapus${NC}"
    fi
    
    # Hapus folder wallpaper
    if [ -d "$WALLPAPER_DIR" ]; then
        rm -rf "$WALLPAPER_DIR"
        echo -e "${GREEN}✅ Folder wallpaper dihapus${NC}"
    fi
    
    # Kembalikan core.blade.php ke default
    cat > "$TARGET_FILE" << 'EOF'
@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-800'],
])

@section('container')
    <div id="modal-portal"></div>
    <div id="app"></div>
@endsection
EOF
    
    # Kembalikan footer ke default
    if [ -f "$FOOTER_FILE" ]; then
        sed -i 's/Rendzz Official®/Pterodactyl®/g' "$FOOTER_FILE"
        sed -i 's/© 2025 - 2026/© 2015 - 2026/g' "$FOOTER_FILE"
    fi
    
    # Clear cache
    cd "$PTERO_DIR" 2>/dev/null
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    
    echo -e "\n${GREEN}✅ Panel kembali normal!${NC}"
}

# -------------------------------
# FUNCTION: INSTALL WALLPAPER + UNIQUE DESIGN
# -------------------------------
install_wallpaper() {
    show_header
    
    # Input URL
    echo -e "${YELLOW}📸 Masukkan URL wallpaper:${NC}"
    echo -n "➤ "
    read WALLPAPER_URL
    
    # Validasi URL
    if [ -z "$WALLPAPER_URL" ]; then
        echo -e "\n${RED}❌ URL tidak boleh kosong!${NC}"
        return 1
    fi
    
    # Backup
    cp "$TARGET_FILE" "$BACKUP_FILE" 2>/dev/null
    
    # Download wallpaper
    echo -e "\n${YELLOW}📥 Downloading wallpaper...${NC}"
    mkdir -p "$WALLPAPER_DIR"
    curl -L "$WALLPAPER_URL" -o "$WALLPAPER_FILE" --progress-bar
    
    if [ ! -f "$WALLPAPER_FILE" ]; then
        echo -e "\n${RED}❌ Gagal download wallpaper!${NC}"
        return 1
    fi
    
    chmod 644 "$WALLPAPER_FILE"
    chown -R www-data:www-data "$WALLPAPER_DIR" 2>/dev/null || \
    chown -R nginx:nginx "$WALLPAPER_DIR" 2>/dev/null
    
    echo -e "${GREEN}✅ Wallpaper tersimpan${NC}\n"
    
    # -------------------------------
    # CREATE LOADING PAGE
    # -------------------------------
    create_loading_page
    
    # -------------------------------
    # GANTI COPYRIGHT FOOTER
    # -------------------------------
    echo -e "${YELLOW}©️  Mengganti copyright footer...${NC}"
    
    cp "$FOOTER_FILE" "$FOOTER_FILE.bak" 2>/dev/null
    
    sed -i 's/Pterodactyl®/Rendzz Official®/g' "$FOOTER_FILE"
    sed -i 's/Pterodactyl/Rendzz Official/g' "$FOOTER_FILE"
    sed -i 's/© 2015 - 2026/© 2025 - 2026/g' "$FOOTER_FILE"
    sed -i 's/© [0-9]\{4\} - [0-9]\{4\}/© 2025 - 2026/g' "$FOOTER_FILE"
    
    echo -e "${GREEN}✅ Footer: Rendzz Official® © 2025 - 2026${NC}\n"
    
    # -------------------------------
    # INJECT CORE BLADE - UNIQUE DESIGN
    # -------------------------------
    echo -e "${YELLOW}🎨 Menginjeksi unique design...${NC}"
    
    cat > "$TARGET_FILE" << 'EOF'
@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-800'],
])

@section('container')
    <div id="modal-portal"></div>
    <div id="app"></div>

    <style>
        /* ======================================= */
        /*   RENDZZ UNIQUE EDITION v2.0            */
        /*   With Loading Animation!              */
        /* ======================================= */

        /* BACKGROUND */
        body {
            background: url('/rendzz/bg.jpg') no-repeat center center fixed !important;
            background-size: cover !important;
        }

        /* OVERLAY TIPIS */
        body::after {
            content: "";
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.2);
            pointer-events: none;
            z-index: 1;
        }

        #app, .content-wrapper {
            position: relative;
            z-index: 2;
        }

        /* ANIMASI MASUK */
        @keyframes slideInLeft {
            0% {
                opacity: 0;
                transform: translateX(-50px);
            }
            100% {
                opacity: 1;
                transform: translateX(0);
            }
        }

        @keyframes fadeInUp {
            from {
                opacity: 0;
                transform: translateY(30px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        /* SERVER CARD - HEXAGON STYLE */
        .card {
            background: rgba(255, 255, 255, 0.92) !important;
            border: none !important;
            border-radius: 20px 8px 20px 8px !important;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15) !important;
            transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) !important;
            animation: slideInLeft 0.6s ease-out !important;
            position: relative;
            overflow: hidden;
            backdrop-filter: blur(5px);
        }

        /* GARIS DEKORATIF */
        .card::before {
            content: "";
            position: absolute;
            top: 0;
            left: 0;
            width: 5px;
            height: 100%;
            background: linear-gradient(180deg, #f093fb, #f5576c, #4facfe);
            border-radius: 20px 0 0 8px;
        }

        /* HOVER EFEK */
        .card:hover {
            transform: translateY(-10px) scale(1.02) !important;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.25) !important;
            background: white !important;
        }

        /* SIDEBAR MODERN */
        .main-sidebar {
            background: rgba(26, 32, 44, 0.88) !important;
            border-right: none !important;
            box-shadow: 5px 0 30px rgba(0, 0, 0, 0.2) !important;
            backdrop-filter: blur(10px);
        }

        .nav-link {
            border-radius: 12px !important;
            margin: 5px 15px !important;
            transition: all 0.3s ease !important;
            position: relative;
        }

        .nav-link::after {
            content: '';
            position: absolute;
            left: 0;
            bottom: 0;
            width: 0;
            height: 2px;
            background: linear-gradient(90deg, #f093fb, #f5576c);
            transition: width 0.3s ease;
        }

        .nav-link:hover::after {
            width: 100%;
        }

        .nav-link:hover {
            background: rgba(255, 255, 255, 0.1) !important;
            transform: translateX(5px);
        }

        /* NAVBAR CLEAN */
        .main-header {
            background: rgba(255, 255, 255, 0.88) !important;
            backdrop-filter: blur(10px);
            box-shadow: 0 2px 20px rgba(0, 0, 0, 0.08) !important;
            border-bottom: none !important;
        }

        .dark-mode .main-header {
            background: rgba(26, 32, 44, 0.88) !important;
        }

        /* BUTTON BULAT */
        .btn {
            border-radius: 50px !important;
            padding: 8px 25px !important;
            font-weight: 600 !important;
            transition: all 0.3s ease !important;
            position: relative;
            overflow: hidden;
        }

        .btn::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.2);
            transition: all 0.5s ease;
            transform: translate(-50%, -50%);
        }

        .btn:hover::before {
            width: 300px;
            height: 300px;
        }

        .btn-primary {
            background: linear-gradient(145deg, #4facfe, #00f2fe) !important;
            border: none !important;
            box-shadow: 0 4px 20px rgba(79, 172, 254, 0.3) !important;
        }

        .btn-primary:hover {
            transform: scale(1.05) !important;
            box-shadow: 0 8px 30px rgba(79, 172, 254, 0.4) !important;
        }

        /* MODAL UNIK */
        .modal-content {
            border-radius: 30px 10px 30px 10px !important;
            border: none !important;
            box-shadow: 0 30px 60px rgba(0, 0, 0, 0.3) !important;
            backdrop-filter: blur(10px);
        }

        .modal-header {
            border-bottom: 2px dashed #4facfe !important;
            border-radius: 30px 10px 0 0 !important;
        }

        /* DARK MODE */
        .dark-mode .card {
            background: rgba(26, 32, 44, 0.88) !important;
            color: white !important;
        }

        .dark-mode .card-title {
            color: white !important;
            border-bottom: 2px dashed #4facfe;
        }

        /* WATERMARK MINIMAL */
        body::before {
            content: "✦ RENDZZ ✦";
            position: fixed;
            bottom: 20px;
            right: 30px;
            color: rgba(255, 255, 255, 0.15);
            font-size: 18px;
            font-weight: 800;
            letter-spacing: 8px;
            z-index: 999;
            pointer-events: none;
            text-shadow: 0 0 20px rgba(0,0,0,0.3);
        }

        /* LOADING ANIMATION FOR ELEMENTS */
        .content-wrapper > * {
            animation: fadeInUp 0.6s ease forwards;
        }

        .content-wrapper > *:nth-child(1) { animation-delay: 0.1s; }
        .content-wrapper > *:nth-child(2) { animation-delay: 0.2s; }
        .content-wrapper > *:nth-child(3) { animation-delay: 0.3s; }
        .content-wrapper > *:nth-child(4) { animation-delay: 0.4s; }
        .content-wrapper > *:nth-child(5) { animation-delay: 0.5s; }
    </style>
@endsection
EOF

    # -------------------------------
    # GANTI TITLE PANEL
    # -------------------------------
    sed -i 's/<title>.*<\/title>/<title>🔥 Rendzz Unique Edition 🔥<\/title>/g' "$PTERO_DIR/resources/views/layouts/admin.blade.php" 2>/dev/null
    sed -i 's/<title>.*<\/title>/<title>🔥 Rendzz Unique Edition 🔥<\/title>/g' "$PTERO_DIR/resources/views/layouts/auth.blade.php" 2>/dev/null
    
    # -------------------------------
    # CLEAR CACHE
    # -------------------------------
    cd "$PTERO_DIR" 2>/dev/null
    php artisan view:clear
    php artisan cache:clear
    php artisan config:clear
    
    # -------------------------------
    # SUCCESS MESSAGE
    # -------------------------------
    echo -e "\n${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           ✅ INSTALLASI UNIQUE BERHASIL! ✅          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🖼️  Wallpaper    : ${NC}CUSTOM"
    echo -e "${PURPLE}🃏 Server Card   : ${NC}Hexagon style (20px 8px 20px 8px)"
    echo -e "${BLUE}🎬 Animasi       : ${NC}Slide In Left + Hover naik"
    echo -e "${YELLOW}⚪ Button        : ${NC}Bulat (50px radius)"
    echo -e "${GREEN}©️  Footer        : ${NC}Rendzz Official® © 2025-2026"
    echo -e "${CYAN}🔄 Loading Page  : ${NC}Auto verifikasi + Welcome Greeting"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}🚀 Akses panel: ${NC}http://your-domain.com"
    echo -e "${GREEN}🔗 Loading page akan muncul otomatis!${NC}"
}

# -------------------------------
# MAIN MENU
# -------------------------------
while true; do
    show_header
    echo -e "${WHITE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║           🔥 PILIH MENU 🔥               ║${NC}"
    echo -e "${WHITE}╠════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║                                          ║${NC}"
    echo -e "${WHITE}║  ${RED}[1]${NC} 🗑️  HAPUS - Balik Normal         ${WHITE}║${NC}"
    echo -e "${WHITE}║  ${GREEN}[2]${NC} ✨ INSTALL - Unique Edition     ${WHITE}║${NC}"
    echo -e "${WHITE}║  ${BLUE}[x]${NC} ❌ KELUAR                       ${WHITE}║${NC}"
    echo -e "${WHITE}║                                          ║${NC}"
    echo -e "${WHITE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${YELLOW}➤ Pilih menu [1/2/x]: ${NC}"
    read MENU
    
    case $MENU in
        1)
            uninstall_wallpaper
            echo ""
            echo -ne "${CYAN}Tekan Enter untuk kembali...${NC}"
            read
            ;;
        2)
            install_wallpaper
            echo ""
            echo -ne "${CYAN}Tekan Enter untuk kembali...${NC}"
            read
            ;;
        x)
            echo -e "\n${GREEN}✨ Thanks for using Rendzz Unique Edition!${NC}"
            echo -e "${CYAN}📱 Telegram: @lynnn046${NC}\n"
            exit 0
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1
            ;;
    esac
done
