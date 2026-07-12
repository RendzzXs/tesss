#!/bin/bash
# ptero-custom-login-html.sh

PANEL_DIR="/var/www/pterodactyl"
LOGO_URL="https://files.catbox.moe/nig1j1.jpg"
BACKUP_DIR="/root/backup-ptero-login"

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

backup_login() {
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/login-$TIMESTAMP"
    mkdir -p $BACKUP_PATH
    
    echo -e "${YELLOW}[*] Backup login page...${NC}"
    cp -r $PANEL_DIR/resources/views/auth $BACKUP_PATH/ 2>/dev/null
    
    echo -e "${GREEN}[✓] Backup di: $BACKUP_PATH${NC}"
    echo "$BACKUP_PATH" > /tmp/last_login_backup.txt
}

# ============================================
# DOWNLOAD LOGO
# ============================================

download_logo() {
    echo -e "${YELLOW}[*] Download logo...${NC}"
    cd /tmp
    wget -q --show-progress -O logo.jpg $LOGO_URL
    if [ -f "logo.jpg" ]; then
        if command -v convert &> /dev/null; then
            convert logo.jpg logo.png
        else
            cp logo.jpg logo.png
        fi
        cp logo.png $PANEL_DIR/public/images/logo-custom.png
        echo -e "${GREEN}[✓] Logo siap!${NC}"
    else
        echo -e "${RED}[✗] Gagal download logo${NC}"
        return 1
    fi
}

# ============================================
# CUSTOM LOGIN PAGE - HTML FULL
# ============================================

create_login_html() {
    echo -e "${CYAN}[*] Membuat custom login page...${NC}"
    
    mkdir -p $PANEL_DIR/resources/views/auth
    
    cat > $PANEL_DIR/resources/views/auth/login.blade.php << 'EOF'
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>Rendzz Panel - Login</title>
    
    <!-- Font Awesome 6 (Icons) -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
    
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    
    <style>
        /* ========================================
           RENDZZ PANEL - CUSTOM LOGIN PAGE
           SEMUA HTML CUSTOM, ICON FONT AWESOME
           ======================================== */
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Inter', sans-serif;
            background: url('/images/bg-login.jpg') no-repeat center center fixed;
            background-size: cover;
            position: relative;
            padding: 20px;
        }
        
        /* Overlay */
        body::before {
            content: '';
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.65);
            z-index: 0;
        }
        
        /* Particles (dekorasi) */
        .particles {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            z-index: 0;
            overflow: hidden;
            pointer-events: none;
        }
        
        .particle {
            position: absolute;
            width: 4px;
            height: 4px;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 50%;
            animation: float 15s infinite;
        }
        
        .particle:nth-child(1) { left: 10%; animation-delay: 0s; }
        .particle:nth-child(2) { left: 20%; animation-delay: 2s; }
        .particle:nth-child(3) { left: 30%; animation-delay: 4s; }
        .particle:nth-child(4) { left: 40%; animation-delay: 1s; }
        .particle:nth-child(5) { left: 50%; animation-delay: 3s; }
        .particle:nth-child(6) { left: 60%; animation-delay: 5s; }
        .particle:nth-child(7) { left: 70%; animation-delay: 2s; }
        .particle:nth-child(8) { left: 80%; animation-delay: 4s; }
        .particle:nth-child(9) { left: 90%; animation-delay: 1s; }
        
        @keyframes float {
            0%, 100% {
                transform: translateY(100vh) scale(0);
                opacity: 0;
            }
            10% {
                opacity: 1;
            }
            90% {
                opacity: 1;
            }
            100% {
                transform: translateY(-100vh) scale(1);
                opacity: 0;
            }
        }
        
        /* Container */
        .login-wrapper {
            position: relative;
            z-index: 1;
            width: 100%;
            max-width: 440px;
        }
        
        /* Login Box */
        .login-box {
            background: rgba(0, 0, 0, 0.75);
            backdrop-filter: blur(25px);
            -webkit-backdrop-filter: blur(25px);
            border-radius: 30px;
            padding: 50px 40px 40px;
            border: 1px solid rgba(255, 255, 255, 0.08);
            box-shadow: 0 40px 100px rgba(0, 0, 0, 0.6);
            position: relative;
            overflow: hidden;
        }
        
        /* Border Glow */
        .login-box::before {
            content: '';
            position: absolute;
            top: -2px;
            left: -2px;
            right: -2px;
            bottom: -2px;
            background: conic-gradient(from 0deg, #f093fb, #f5576c, #4facfe, #43e97b, #f093fb);
            background-size: 400% 400%;
            border-radius: 30px;
            z-index: -1;
            animation: rotateBorder 6s linear infinite;
            opacity: 0.5;
        }
        
        @keyframes rotateBorder {
            0% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
            100% { background-position: 0% 50%; }
        }
        
        /* Logo */
        .login-logo {
            text-align: center;
            margin-bottom: 35px;
        }
        
        .login-logo .logo-img {
            width: 90px;
            height: 90px;
            border-radius: 25px;
            object-fit: cover;
            box-shadow: 0 15px 40px rgba(245, 87, 108, 0.3);
            border: 2px solid rgba(255, 255, 255, 0.1);
            transition: transform 0.3s;
        }
        
        .login-logo .logo-img:hover {
            transform: scale(1.05);
        }
        
        .login-logo h1 {
            color: white;
            font-size: 28px;
            font-weight: 800;
            margin-top: 18px;
            background: linear-gradient(135deg, #f093fb, #f5576c);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .login-logo .subtitle {
            color: rgba(255, 255, 255, 0.4);
            font-size: 13px;
            font-weight: 400;
            margin-top: 4px;
            letter-spacing: 2px;
        }
        
        /* Form */
        .form-group {
            margin-bottom: 22px;
            position: relative;
        }
        
        .form-group label {
            color: rgba(255, 255, 255, 0.6);
            font-size: 13px;
            font-weight: 600;
            display: block;
            margin-bottom: 8px;
            letter-spacing: 0.3px;
        }
        
        .form-group .input-icon {
            position: absolute;
            left: 16px;
            bottom: 15px;
            color: rgba(255, 255, 255, 0.25);
            font-size: 18px;
            transition: color 0.3s;
        }
        
        .form-group:focus-within .input-icon {
            color: #f5576c;
        }
        
        .form-control {
            width: 100%;
            padding: 15px 15px 15px 52px;
            background: rgba(255, 255, 255, 0.06);
            border: 1px solid rgba(255, 255, 255, 0.08);
            border-radius: 16px;
            color: white;
            font-size: 15px;
            font-family: 'Inter', sans-serif;
            transition: all 0.3s;
            outline: none;
        }
        
        .form-control::placeholder {
            color: rgba(255, 255, 255, 0.2);
            font-weight: 300;
        }
        
        .form-control:focus {
            background: rgba(255, 255, 255, 0.08);
            border-color: rgba(245, 87, 108, 0.4);
            box-shadow: 0 0 30px rgba(245, 87, 108, 0.05);
        }
        
        /* Password toggle */
        .password-toggle {
            position: absolute;
            right: 16px;
            bottom: 15px;
            color: rgba(255, 255, 255, 0.25);
            cursor: pointer;
            font-size: 18px;
            transition: color 0.3s;
        }
        
        .password-toggle:hover {
            color: rgba(255, 255, 255, 0.5);
        }
        
        /* Options */
        .login-options {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin: 20px 0 28px;
        }
        
        .login-options .remember {
            display: flex;
            align-items: center;
            gap: 8px;
            color: rgba(255, 255, 255, 0.4);
            font-size: 13px;
            cursor: pointer;
        }
        
        .login-options .remember input[type="checkbox"] {
            width: 16px;
            height: 16px;
            accent-color: #f5576c;
            cursor: pointer;
        }
        
        .login-options .forgot {
            color: rgba(255, 255, 255, 0.3);
            font-size: 13px;
            text-decoration: none;
            transition: color 0.3s;
        }
        
        .login-options .forgot:hover {
            color: #f5576c;
        }
        
        /* Button */
        .btn-login {
            width: 100%;
            padding: 16px;
            background: linear-gradient(135deg, #f093fb, #f5576c);
            border: none;
            border-radius: 16px;
            color: white;
            font-size: 16px;
            font-weight: 700;
            font-family: 'Inter', sans-serif;
            cursor: pointer;
            transition: all 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            position: relative;
            overflow: hidden;
        }
        
        .btn-login:hover {
            transform: translateY(-2px);
            box-shadow: 0 15px 40px rgba(245, 87, 108, 0.4);
        }
        
        .btn-login:active {
            transform: scale(0.98);
        }
        
        .btn-login .btn-icon {
            font-size: 18px;
        }
        
        /* Footer */
        .login-footer {
            text-align: center;
            margin-top: 25px;
            color: rgba(255, 255, 255, 0.2);
            font-size: 12px;
            letter-spacing: 0.5px;
        }
        
        .login-footer .heart {
            color: #f5576c;
            display: inline-block;
            animation: heartbeat 1.5s ease-in-out infinite;
        }
        
        @keyframes heartbeat {
            0%, 100% { transform: scale(1); }
            50% { transform: scale(1.2); }
        }
        
        .login-footer a {
            color: rgba(255, 255, 255, 0.3);
            text-decoration: none;
            transition: color 0.3s;
        }
        
        .login-footer a:hover {
            color: #f5576c;
        }
        
        /* Alert Error */
        .alert-danger {
            background: rgba(255, 71, 87, 0.15);
            border: 1px solid rgba(255, 71, 87, 0.2);
            border-radius: 12px;
            padding: 12px 16px;
            color: #ff6b81;
            font-size: 14px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .alert-danger i {
            font-size: 18px;
        }
        
        /* Responsive */
        @media (max-width: 480px) {
            .login-box {
                padding: 30px 20px 30px;
            }
            
            .login-logo .logo-img {
                width: 70px;
                height: 70px;
            }
            
            .login-logo h1 {
                font-size: 22px;
            }
            
            .login-options {
                flex-direction: column;
                gap: 10px;
                align-items: flex-start;
            }
        }
    </style>
</head>
<body>
    
    <!-- Particles -->
    <div class="particles">
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
        <div class="particle"></div>
    </div>
    
    <!-- Login Wrapper -->
    <div class="login-wrapper">
        <div class="login-box">
            
            <!-- Logo -->
            <div class="login-logo">
                <img src="{{ asset('images/logo-custom.png') }}" alt="Rendzz Panel" class="logo-img">
                <h1>Rendzz Panel</h1>
                <p class="subtitle">✦ MANAGE YOUR SERVERS ✦</p>
            </div>
            
            <!-- Error Message -->
            @if($errors->any())
            <div class="alert-danger">
                <i class="fas fa-exclamation-circle"></i>
                {{ $errors->first() }}
            </div>
            @endif
            
            <!-- Form Login -->
            <form method="POST" action="{{ route('login') }}">
                @csrf
                
                <!-- Email -->
                <div class="form-group">
                    <label for="email">
                        <i class="fas fa-envelope"></i> Email Address
                    </label>
                    <i class="fas fa-user input-icon"></i>
                    <input type="email" name="email" id="email" class="form-control" 
                           placeholder="Masukkan email kamu" value="{{ old('email') }}" required autofocus>
                </div>
                
                <!-- Password -->
                <div class="form-group">
                    <label for="password">
                        <i class="fas fa-lock"></i> Password
                    </label>
                    <i class="fas fa-key input-icon"></i>
                    <input type="password" name="password" id="password" class="form-control" 
                           placeholder="Masukkan password" required>
                    <i class="fas fa-eye password-toggle" id="togglePassword" 
                       onclick="togglePassword()"></i>
                </div>
                
                <!-- Options -->
                <div class="login-options">
                    <label class="remember">
                        <input type="checkbox" name="remember" {{ old('remember') ? 'checked' : '' }}>
                        <i class="fas fa-check-circle"></i> Remember Me
                    </label>
                    @if(Route::has('password.request'))
                    <a href="{{ route('password.request') }}" class="forgot">
                        <i class="fas fa-question-circle"></i> Forgot Password?
                    </a>
                    @endif
                </div>
                
                <!-- Button -->
                <button type="submit" class="btn-login">
                    <i class="fas fa-rocket btn-icon"></i>
                    Login to Panel
                    <i class="fas fa-arrow-right btn-icon"></i>
                </button>
                
            </form>
            
            <!-- Footer -->
            <div class="login-footer">
                <span>© 2026 <span class="heart">❤</span> Made by <a href="#">Rendzz</a></span>
                <br>
                <span style="font-size: 11px; opacity: 0.6;">Powered by Pterodactyl</span>
            </div>
            
        </div>
    </div>
    
    <!-- Script Toggle Password -->
    <script>
        function togglePassword() {
            const password = document.getElementById('password');
            const toggle = document.getElementById('togglePassword');
            
            if (password.type === 'password') {
                password.type = 'text';
                toggle.classList.remove('fa-eye');
                toggle.classList.add('fa-eye-slash');
            } else {
                password.type = 'password';
                toggle.classList.remove('fa-eye-slash');
                toggle.classList.add('fa-eye');
            }
        }
    </script>
    
</body>
</html>
EOF

    echo -e "${GREEN}[✓] Custom login page created!${NC}"
}

# ============================================
# INSTALL LOGIN CUSTOM
# ============================================

install_login() {
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}   INSTALL CUSTOM LOGIN PAGE         ${NC}"
    echo -e "${MAGENTA}========================================${NC}"
    
    # Backup dulu
    backup_login
    
    # Download logo
    download_logo
    
    # Buat login page
    create_login_html
    
    # Clear cache
    cd $PANEL_DIR
    php artisan view:clear
    php artisan cache:clear
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}[✓] CUSTOM LOGIN PAGE SELESAI!${NC}"
    echo -e "${GREEN}[✓] Logo: /public/images/logo-custom.png${NC}"
    echo -e "${YELLOW}[!] Akses: /login${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# ============================================
# UNINSTALL LOGIN (RESTORE DEFAULT)
# ============================================

uninstall_login() {
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}        UNINSTALL CUSTOM LOGIN         ${NC}"
    echo -e "${RED}========================================${NC}"
    
    LAST_BACKUP=$(cat /tmp/last_login_backup.txt 2>/dev/null)
    
    if [ -z "$LAST_BACKUP" ] || [ ! -d "$LAST_BACKUP" ]; then
        echo -e "${YELLOW}[!] Backup tidak ditemukan${NC}"
        echo -e "${YELLOW}[!] Restore dari package default...${NC}"
        cd $PANEL_DIR
        php artisan vendor:publish --force --tag=views
        echo -e "${GREEN}[✓] Restore default selesai${NC}"
        return
    fi
    
    echo -e "${YELLOW}[*] Restore dari: $LAST_BACKUP${NC}"
    cp -r $LAST_BACKUP/auth/* $PANEL_DIR/resources/views/auth/ 2>/dev/null
    
    cd $PANEL_DIR
    php artisan view:clear
    php artisan cache:clear
    
    echo -e "${GREEN}[✓] UNINSTALL SELESAI!${NC}"
}

# ============================================
# MENU UTAMA
# ============================================

while true; do
    clear
    echo -e "${MAGENTA}╔════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║    RENDZZ CUSTOM LOGIN PAGE          ║${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}┌─────────────── MENU ──────────────────┐${NC}"
    echo -e "${CYAN}│${NC} 1. ${GREEN}Install Login Custom${NC}   - Pasang HTML login"
    echo -e "${CYAN}│${NC} 2. ${RED}Uninstall Login${NC}        - Kembali ke default"
    echo -e "${CYAN}│${NC} 3. ${YELLOW}Backup Login${NC}          - Backup login page"
    echo -e "${CYAN}│${NC} 4. ${BLUE}Status${NC}                 - Cek status"
    echo -e "${CYAN}│${NC} 5. ${MAGENTA}Exit${NC}                 - Keluar"
    echo -e "${CYAN}└──────────────────────────────────────┘${NC}"
    echo ""
    read -p "Pilih menu [1-5]: " menu
    
    case $menu in
        1)
            install_login
            ;;
        2)
            uninstall_login
            ;;
        3)
            backup_login
            ;;
        4)
            echo -e "${BLUE}========================================${NC}"
            if [ -f "$PANEL_DIR/resources/views/auth/login.blade.php" ]; then
                if grep -q "Rendzz Panel" "$PANEL_DIR/resources/views/auth/login.blade.php"; then
                    echo -e "${GREEN}[✓] Status: CUSTOM LOGIN TERPASANG${NC}"
                else
                    echo -e "${YELLOW}[!] Status: DEFAULT${NC}"
                fi
            else
                echo -e "${RED}[✗] Status: DEFAULT${NC}"
            fi
            echo -e "${YELLOW}Backup: $(cat /tmp/last_login_backup.txt 2>/dev/null || echo 'Tidak ada')${NC}"
            ;;
        5)
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
