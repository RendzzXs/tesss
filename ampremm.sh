#!/bin/bash

# ============================================
#   🎬 RENDZZ ALIGHT MOTION FREE PREMIUM
#   Full Auto Installer
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}Harus root!${NC}"; exit 1; }

clear
echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🎬 RENDZZ ALIGHT MOTION FREE PREMIUM     ║${NC}"
echo -e "${CYAN}║  Premium • VIP • QRIS • Live Chat         ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

# ============ INPUT ============
read -p "👉 Subdomain: " SUBDOMAIN
[[ -z "$SUBDOMAIN" ]] && { echo -e "${RED}Kosong!${NC}"; exit 1; }

read -p "👉 Email SSL: " EMAIL
[[ -z "$EMAIL" ]] && EMAIL="admin@$SUBDOMAIN"

read -p "👉 Username admin [admin]: " ADMIN_USER
ADMIN_USER=${ADMIN_USER:-admin}

read -s -p "👉 Password admin [123456]: " ADMIN_PASS
echo ""
ADMIN_PASS=${ADMIN_PASS:-123456}

read -p "👉 Email admin [$ADMIN_USER@$SUBDOMAIN]: " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-$ADMIN_USER@$SUBDOMAIN}

# Path
DB_PASS=$(openssl rand -hex 12)
DB_NAME="rendzz_$(echo $SUBDOMAIN | tr '.' '_' | cut -c1-18)"
WEB_ROOT="/var/www/$SUBDOMAIN"
NGINX_CONF="/etc/nginx/sites-available/$SUBDOMAIN"

# Backend
API_BASE_URL="https://am.rafaelxd.my.id/api/v1"
API_KEY="alight_live_3809350d937f869762f6de5d3a9a60d0"

# QRIS (dari gambar yang kamu kasih)
QRIS_URL="https://files.catbox.moe/jpez3c.jpg"

echo ""
echo -e "${CYAN}📋 Config:${NC}"
echo -e "  Subdomain : $SUBDOMAIN"
echo -e "  Web Root  : $WEB_ROOT"
echo -e "  Admin     : $ADMIN_USER / $ADMIN_PASS"
echo ""
read -p "Lanjut? (y/n): " C
[[ "$C" != "y" && "$C" != "Y" ]] && exit 0

# ============ STEP 1: PACKAGES ============
echo ""
echo -e "${CYAN}[1/9] Install packages & fix MySQL...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update -qq 2>/dev/null
apt install nginx php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-curl php8.3-xml php8.3-zip php8.3-gd mysql-server curl wget unzip -y -qq 2>/dev/null

rm -f /etc/mysql/FROZEN 2>/dev/null
systemctl enable mysql nginx php8.3-fpm >/dev/null 2>&1
systemctl start mysql nginx php8.3-fpm >/dev/null 2>&1

if ! systemctl is-active --quiet mysql; then
    echo -e "${YELLOW}  → MySQL rusak, reinstall...${NC}"
    systemctl stop mysql >/dev/null 2>&1
    apt purge mysql-server mysql-server-8.0 mysql-client mysql-common -y >/dev/null 2>&1
    rm -rf /var/lib/mysql /etc/mysql
    apt install mysql-server -y -qq >/dev/null 2>&1
    systemctl enable mysql >/dev/null 2>&1
    systemctl start mysql >/dev/null 2>&1
    sleep 5
fi

for i in {1..15}; do
    [[ -S /var/run/mysqld/mysqld.sock ]] && break
    sleep 1
done

if systemctl is-active --quiet mysql; then
    echo -e "${GREEN}  ✓ MySQL OK${NC}"
else
    echo -e "${RED}  ✗ MySQL gagal!${NC}"; exit 1
fi

# ============ STEP 2: DATABASE ============
echo -e "${CYAN}[2/9] Setup database...${NC}"
mysql -e "DROP DATABASE IF EXISTS \`$DB_NAME\`;" 2>/dev/null
mysql -e "CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'webuser'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO 'webuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

mysql "$DB_NAME" << 'SQLEOF'
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('admin','user','vip') DEFAULT 'user',
    status ENUM('active','banned') DEFAULT 'active',
    vip_expires DATETIME DEFAULT NULL,
    daily_count INT DEFAULT 0,
    daily_date DATE DEFAULT NULL,
    total_runs INT DEFAULT 0,
    success_runs INT DEFAULT 0,
    profile_pic VARCHAR(255) DEFAULT NULL,
    bio TEXT DEFAULT NULL,
    last_login DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE activity_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT, action VARCHAR(255), ip VARCHAR(45),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    amount INT NOT NULL,
    unique_code INT NOT NULL,
    total INT NOT NULL,
    method VARCHAR(50) DEFAULT 'qris',
    status ENUM('pending','approved','rejected') DEFAULT 'pending',
    proof VARCHAR(255) DEFAULT NULL,
    note TEXT DEFAULT NULL,
    approved_by INT DEFAULT NULL,
    approved_at DATETIME DEFAULT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE live_chat (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    username VARCHAR(50),
    message TEXT NOT NULL,
    is_admin INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE premium_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT, email VARCHAR(100),
    status ENUM('success','failed') DEFAULT 'success',
    message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255), message TEXT,
    target ENUM('all','vip','user','admin') DEFAULT 'all',
    created_by INT, created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
SQLEOF
echo -e "${GREEN}  ✓ Database OK${NC}"

# ============ STEP 3: FOLDER ============
echo -e "${CYAN}[3/9] Setup folder...${NC}"
if [[ -d "$WEB_ROOT" ]]; then
    mv "$WEB_ROOT" "/var/www/backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}  ⚠️  Folder lama di-backup${NC}"
fi
mkdir -p "$WEB_ROOT"/{admin,user,api,includes,assets/{css,js,img},uploads}
echo -e "${GREEN}  ✓ Folder OK${NC}"

# ============ STEP 4: CONFIG ============
echo -e "${CYAN}[4/9] Bikin config...${NC}"
cat > "$WEB_ROOT/includes/config.php" << PHPEOF
<?php
session_start();
date_default_timezone_set('Asia/Jakarta');

define('DB_HOST', 'localhost');
define('DB_NAME', '$DB_NAME');
define('DB_USER', 'webuser');
define('DB_PASS', '$DB_PASS');
define('SITE_URL', 'https://$SUBDOMAIN');
define('SITE_NAME', 'Rendzz Alight Motion Free Premium');
define('API_BASE_URL', '$API_BASE_URL');
define('API_KEY', '$API_KEY');
define('QRIS_URL', '$QRIS_URL');
define('MIN_PAYMENT', 2000);
define('VIP_PRICE', 5000);

try {
    \$pdo = new PDO("mysql:host=".DB_HOST.";dbname=".DB_NAME.";charset=utf8mb4", DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);
} catch (PDOException \$e) { die("DB Error: " . \$e->getMessage()); }

function isLoggedIn() { return isset(\$_SESSION['user_id']); }
function isAdmin() { return isLoggedIn() && \$_SESSION['role'] === 'admin'; }
function isVip() { return isLoggedIn() && in_array(\$_SESSION['role'], ['admin','vip']); }
function requireLogin() { if (!isLoggedIn()) { header('Location: /login.php'); exit; } }
function requireAdmin() { if (!isAdmin()) { header('Location: /user/'); exit; } }
function requireVip() { if (!isVip()) { header('Location: /vip.php'); exit; } }
function csrf() { if (empty(\$_SESSION['csrf'])) \$_SESSION['csrf'] = bin2hex(random_bytes(32)); return \$_SESSION['csrf']; }
function checkCsrf(\$t) { return isset(\$_SESSION['csrf']) && hash_equals(\$_SESSION['csrf'], \$t); }
function logAct(\$pdo, \$uid, \$action) {
    \$s = \$pdo->prepare("INSERT INTO activity_log (user_id, action, ip) VALUES (?,?,?)");
    \$s->execute([\$uid, \$action, \$_SERVER['REMOTE_ADDR'] ?? '']);
}

// ============ ALIGHT API ============
function apiCall(\$endpoint, \$body, \$retry = 2) {
    \$url = API_BASE_URL . '/' . \$endpoint;
    for (\$i = 0; \$i <= \$retry; \$i++) {
        \$ch = curl_init(\$url);
        curl_setopt_array(\$ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 45,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'x-api-key: ' . API_KEY,
            ],
            CURLOPT_POSTFIELDS => json_encode(\$body),
            CURLOPT_SSL_VERIFYPEER => false,
        ]);
        \$res = curl_exec(\$ch);
        \$code = curl_getinfo(\$ch, CURLINFO_HTTP_CODE);
        curl_close(\$ch);

        if (\$res !== false) {
            \$data = json_decode(\$res, true);
            if (\$data && (\$code >= 200 && \$code < 300) && (\$data['success'] ?? true) !== false) {
                return ['ok' => true, 'data' => \$data];
            }
            if (\$i < \$retry) { sleep(2); continue; }
            return ['ok' => false, 'error' => \$data['message'] ?? \$data['error'] ?? "HTTP \$code"];
        }
        if (\$i < \$retry) sleep(2);
    }
    return ['ok' => false, 'error' => 'Network error / timeout'];
}

// ============ TEMP MAIL ============
function generateTempMail() {
    \$providers = [
        ['name' => 'mail.tm', 'base' => 'https://api.mail.tm', 'viewer' => 'https://mail.tm/en/'],
        ['name' => 'mail.gw', 'base' => 'https://api.mail.gw', 'viewer' => 'https://mail.gw/en/'],
    ];
    foreach (\$providers as \$p) {
        try {
            \$ch = curl_init(\$p['base'] . '/domains');
            curl_setopt_array(\$ch, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 15]);
            \$res = curl_exec(\$ch); curl_close(\$ch);
            \$data = json_decode(\$res, true);
            \$domains = \$data['hydra:member'] ?? [];
            \$domain = null;
            foreach (\$domains as \$d) {
                if ((\$d['isActive'] ?? false) && !(\$d['isPrivate'] ?? false)) {
                    \$domain = \$d['domain']; break;
                }
            }
            if (!\$domain) continue;

            \$local = 'rendzz' . substr(md5(uniqid(mt_rand(), true)), 0, 8);
            \$email = \$local . '@' . \$domain;
            \$password = 'Aa1!' . substr(bin2hex(random_bytes(6)), 0, 10);

            // Create account
            \$ch = curl_init(\$p['base'] . '/accounts');
            curl_setopt_array(\$ch, [
                CURLOPT_POST => true, CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 15,
                CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                CURLOPT_POSTFIELDS => json_encode(['address' => \$email, 'password' => \$password]),
            ]);
            curl_exec(\$ch); curl_close(\$ch);

            // Login
            \$ch = curl_init(\$p['base'] . '/token');
            curl_setopt_array(\$ch, [
                CURLOPT_POST => true, CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 15,
                CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                CURLOPT_POSTFIELDS => json_encode(['address' => \$email, 'password' => \$password]),
            ]);
            \$res = curl_exec(\$ch); curl_close(\$ch);
            \$tok = json_decode(\$res, true);
            \$token = \$tok['token'] ?? null;
            if (!\$token) continue;

            return [
                'ok' => true,
                'email' => \$email,
                'password' => \$password,
                'token' => \$token,
                'base' => \$p['base'],
                'provider' => \$p['name'],
                'viewer' => \$p['viewer'],
            ];
        } catch (\Exception \$e) { continue; }
    }
    return ['ok' => false, 'error' => 'Semua provider gagal'];
}

function fetchInbox(\$base, \$token) {
    \$ch = curl_init(\$base . '/messages');
    curl_setopt_array(\$ch, [
        CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 15,
        CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . \$token],
    ]);
    \$res = curl_exec(\$ch); curl_close(\$ch);
    \$data = json_decode(\$res, true);
    return \$data['hydra:member'] ?? [];
}

function fetchMessage(\$base, \$token, \$id) {
    \$ch = curl_init(\$base . '/messages/' . \$id);
    curl_setopt_array(\$ch, [
        CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 15,
        CURLOPT_HTTPHEADER => ['Authorization: Bearer ' . \$token],
    ]);
    \$res = curl_exec(\$ch); curl_close(\$ch);
    return json_decode(\$res, true);
}

// ============ NOTIF ADMIN ============
function notifyAdmin(\$pdo, \$title, \$message) {
    try {
        \$pdo->prepare("INSERT INTO notifications (title, message, target, created_by) VALUES (?,?,?,0)")
            ->execute([\$title, \$message, 'admin']);
    } catch (\Exception \$e) {}
}

// Generate unique code 2008-2999
function generateUniqueCode() {
    return rand(2008, 2999);
}
PHPEOF

# Insert admin
ADMIN_HASH=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_BCRYPT);")
mysql "$DB_NAME" -e "INSERT INTO users (username, email, password, role, status, vip_expires) VALUES ('$ADMIN_USER', '$ADMIN_EMAIL', '$ADMIN_HASH', 'admin', 'active', DATE_ADD(NOW(), INTERVAL 100 YEAR));"
echo -e "${GREEN}  ✓ Config & admin OK${NC}"

# ============ STEP 5: HEADER & NAVBAR ============
echo -e "${CYAN}[5/9] Bikin layout...${NC}"

cat > "$WEB_ROOT/includes/header.php" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="id" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= $pageTitle ?? 'Home' ?> — <?= SITE_NAME ?></title>
<link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>🎬</text></svg>">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=Space+Grotesk:wght@500;700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
<link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
HTMLEOF

cat > "$WEB_ROOT/includes/navbar.php" << 'HTMLEOF'
<nav class="navbar">
    <a href="/" class="logo">
        <span class="logo-icon">🎬</span>
        <span class="logo-text">Rendzz<span class="logo-accent">Premium</span></span>
    </a>
    <div class="nav-menu">
        <a href="/"><i class="fas fa-house"></i> Home</a>
        <?php if (isLoggedIn()): ?>
            <a href="/user/"><i class="fas fa-gauge-high"></i> Dashboard</a>
            <a href="/tools.php"><i class="fas fa-wand-magic-sparkles"></i> Tools</a>
            <?php if (isVip()): ?>
                <a href="/vip/" class="vip-link"><i class="fas fa-crown"></i> VIP</a>
            <?php endif; ?>
            <?php if (isAdmin()): ?>
                <a href="/admin/"><i class="fas fa-shield-halved"></i> Admin</a>
            <?php endif; ?>
            <a href="/profile.php"><i class="fas fa-user-circle"></i> Profile</a>
        <?php endif; ?>
        <button id="themeToggle" class="icon-btn" aria-label="Theme"><i class="fas fa-moon"></i></button>
        <?php if (isLoggedIn()): ?>
            <a href="/logout.php" class="btn btn-outline"><i class="fas fa-arrow-right-from-bracket"></i></a>
        <?php else: ?>
            <a href="/login.php" class="btn btn-primary"><i class="fas fa-arrow-right-to-bracket"></i> Login</a>
        <?php endif; ?>
    </div>
</nav>
HTMLEOF

cat > "$WEB_ROOT/includes/footer.php" << 'HTMLEOF'
<!-- BOTTOM NAVBAR (MOBILE) -->
<div class="bottom-nav">
    <a href="/" class="bn-item"><i class="fas fa-house"></i><span>Home</span></a>
    <a href="/tools.php" class="bn-item"><i class="fas fa-wand-magic-sparkles"></i><span>Tools</span></a>
    <a href="/live-chat.php" class="bn-item"><i class="fas fa-comments"></i><span>Chat</span></a>
    <a href="/vip.php" class="bn-item"><i class="fas fa-crown"></i><span>VIP</span></a>
    <a href="/profile.php" class="bn-item"><i class="fas fa-user"></i><span>Profile</span></a>
</div>

<footer class="footer">
    <div class="footer-content">
        <div class="footer-brand">
            <span class="logo-icon">🎬</span>
            <span>Rendzz Alight Motion Free Premium</span>
        </div>
        <p>© <?= date('Y') ?> Rendzz Premium. All rights reserved.</p>
        <div class="footer-links">
            <a href="/vip.php">VIP</a>
            <a href="/live-chat.php">Live Chat</a>
            <a href="/tools.php">Tools</a>
        </div>
    </div>
</footer>

<!-- FLOATING CHAT BUTTON -->
<a href="/live-chat.php" class="floating-chat" title="Live Chat">
    <i class="fas fa-comments"></i>
    <span class="chat-badge"></span>
</a>

<script src="/assets/js/main.js"></script>
</body>
</html>
HTMLEOF

# ============ STEP 6: HALAMAN UTAMA ============
cat > "$WEB_ROOT/index.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
$pageTitle = 'Home';
$totalUsers = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE status='active'")->fetchColumn();
$totalPremium = (int)$pdo->query("SELECT COUNT(*) FROM premium_history WHERE status='success'")->fetchColumn();
include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/navbar.php';
?>
<section class="hero">
    <div class="hero-bg"></div>
    <div class="hero-content">
        <div class="hero-badge"><i class="fas fa-bolt"></i> 100% Otomatis & Gratis</div>
        <h1>
            <span class="gradient-text">Alight Motion</span>
            <span class="hero-line">Premium <span class="badge-vip-sm">VIP</span></span>
        </h1>
        <p class="hero-sub">Dapatkan akun premium Alight Motion secara instan. Sistem otomatis, cepat, dan aman. Upgrade VIP untuk fitur tanpa batas!</p>
        <div class="hero-actions">
            <?php if (isLoggedIn()): ?>
                <a href="/tools.php" class="btn btn-primary btn-lg pulse-btn">
                    <i class="fas fa-bolt"></i> Generate Sekarang
                </a>
                <a href="/vip.php" class="btn btn-outline btn-lg">
                    <i class="fas fa-crown"></i> Upgrade VIP
                </a>
            <?php else: ?>
                <a href="/register.php" class="btn btn-primary btn-lg pulse-btn">
                    <i class="fas fa-rocket"></i> Mulai Gratis
                </a>
                <a href="/login.php" class="btn btn-outline btn-lg">
                    <i class="fas fa-arrow-right-to-bracket"></i> Login
                </a>
            <?php endif; ?>
        </div>
        <div class="hero-stats">
            <div class="hs-item"><strong><?= number_format($totalUsers) ?>+</strong><span>User Aktif</span></div>
            <div class="hs-item"><strong><?= number_format($totalPremium) ?>+</strong><span>Premium Sukses</span></div>
            <div class="hs-item"><strong>24/7</strong><span>Auto System</span></div>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-head">
        <h2><i class="fas fa-sparkles"></i> Kenapa Pilih Kami?</h2>
        <p>Fitur terbaik untuk pengalaman premium tanpa ribet</p>
    </div>
    <div class="features">
        <div class="feature-card">
            <div class="fc-icon" style="background:linear-gradient(135deg,#667eea,#764ba2)"><i class="fas fa-bolt"></i></div>
            <h3>Otomatis</h3>
            <p>1 klik langsung premium. Gak perlu ribet input manual.</p>
        </div>
        <div class="feature-card">
            <div class="fc-icon" style="background:linear-gradient(135deg,#f093fb,#f5576c)"><i class="fas fa-shield-halved"></i></div>
            <h3>Aman</h3>
            <p>Sistem enkripsi & data user terjaga dengan baik.</p>
        </div>
        <div class="feature-card">
            <div class="fc-icon" style="background:linear-gradient(135deg,#4facfe,#00f2fe)"><i class="fas fa-rocket"></i></div>
            <h3>Cepat</h3>
            <p>Proses cuma 30 detik sampai 2 menit aja.</p>
        </div>
        <div class="feature-card">
            <div class="fc-icon" style="background:linear-gradient(135deg,#43e97b,#38f9d7)"><i class="fas fa-crown"></i></div>
            <h3>VIP Unlimited</h3>
            <p>Upgrade VIP cuma 2rb, generate tanpa batas!</p>
        </div>
    </div>
</section>

<section class="section section-vip">
    <div class="vip-box">
        <div class="vip-glow"></div>
        <div class="vip-content">
            <div class="vip-crown">👑</div>
            <h2>Upgrade ke <span class="gradient-gold">VIP Member</span></h2>
            <p>Nikmati generate <b>tanpa batas</b>, priority queue, dan akses semua fitur premium.</p>
            <div class="vip-price">
                <span class="vip-price-from">Mulai dari</span>
                <span class="vip-price-now">Rp 2.000</span>
            </div>
            <a href="/vip.php" class="btn btn-gold btn-lg">
                <i class="fas fa-crown"></i> Upgrade Sekarang
            </a>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-head">
        <h2><i class="fas fa-question-circle"></i> Pertanyaan Umum</h2>
    </div>
    <div class="faq">
        <details><summary>Apa ini gratis?</summary><p>Ya! Untuk user biasa gratis dengan limit harian. VIP unlimited mulai Rp 2.000.</p></details>
        <details><summary>Berapa lama prosesnya?</summary><p>Rata-rata 30 detik - 2 menit tergantung server.</p></details>
        <details><summary>Bagaimana cara bayar VIP?</summary><p>Scan QRIS di halaman VIP, lalu upload bukti transfer. Admin akan approve.</p></details>
        <details><summary>Apakah akun saya aman?</summary><p>Kami hanya pakai email sementara. Data kamu gak dijual/dibagikan.</p></details>
    </div>
</section>

<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

echo -e "${GREEN}  ✓ Halaman utama OK${NC}"

# ============ STEP 7: AUTH PAGES ============
cat > "$WEB_ROOT/login.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
if (isLoggedIn()) { header('Location: /user/'); exit; }
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!checkCsrf($_POST['csrf'] ?? '')) $error = 'CSRF error';
    else {
        $u = trim($_POST['username'] ?? ''); $p = $_POST['password'] ?? '';
        $s = $pdo->prepare("SELECT * FROM users WHERE username=? OR email=? LIMIT 1");
        $s->execute([$u, $u]); $user = $s->fetch();
        if ($user && password_verify($p, $user['password'])) {
            if ($user['status'] === 'banned') $error = 'Akun dibanned!';
            else {
                $_SESSION['user_id'] = $user['id'];
                $_SESSION['username'] = $user['username'];
                $_SESSION['role'] = $user['role'];
                $pdo->prepare("UPDATE users SET last_login=NOW() WHERE id=?")->execute([$user['id']]);
                logAct($pdo, $user['id'], 'Login');
                header('Location: /user/'); exit;
            }
        } else $error = 'Username/password salah';
    }
}
$pageTitle = 'Login'; include __DIR__ . '/includes/header.php'; include __DIR__ . '/includes/navbar.php';
?>
<div class="auth-wrap"><div class="auth-card">
    <div class="auth-icon"><i class="fas fa-arrow-right-to-bracket"></i></div>
    <h1>Welcome Back</h1>
    <p class="auth-sub">Login untuk akses dashboard premium</p>
    <?php if ($error): ?><div class="alert alert-error"><i class="fas fa-circle-exclamation"></i> <?= $error ?></div><?php endif; ?>
    <form method="POST">
        <input type="hidden" name="csrf" value="<?= csrf() ?>">
        <div class="form-group"><label><i class="fas fa-user"></i> Username / Email</label><input type="text" name="username" required autofocus placeholder="Masukkan username/email"></div>
        <div class="form-group"><label><i class="fas fa-lock"></i> Password</label><input type="password" name="password" required placeholder="Masukkan password"></div>
        <button class="btn btn-primary btn-block btn-lg"><i class="fas fa-arrow-right-to-bracket"></i> Login Sekarang</button>
    </form>
    <p class="auth-footer">Belum punya akun? <a href="/register.php">Daftar Gratis</a></p>
</div></div>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/register.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
if (isLoggedIn()) { header('Location: /user/'); exit; }
$error = ''; $success = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!checkCsrf($_POST['csrf'] ?? '')) $error = 'CSRF error';
    else {
        $u = trim($_POST['username'] ?? ''); $e = trim($_POST['email'] ?? '');
        $p = $_POST['password'] ?? ''; $c = $_POST['confirm'] ?? '';
        if (strlen($u) < 3) $error = 'Username minimal 3 karakter';
        elseif (!filter_var($e, FILTER_VALIDATE_EMAIL)) $error = 'Email tidak valid';
        elseif (strlen($p) < 6) $error = 'Password minimal 6 karakter';
        elseif ($p !== $c) $error = 'Konfirmasi password tidak sama';
        else {
            $s = $pdo->prepare("SELECT id FROM users WHERE username=? OR email=?");
            $s->execute([$u, $e]);
            if ($s->fetch()) $error = 'Username/email sudah terdaftar';
            else {
                $h = password_hash($p, PASSWORD_BCRYPT);
                $pdo->prepare("INSERT INTO users (username,email,password) VALUES (?,?,?)")->execute([$u, $e, $h]);
                $success = 'Registrasi berhasil! Silakan login.';
                logAct($pdo, (int)$pdo->lastInsertId(), 'Register');
            }
        }
    }
}
$pageTitle = 'Register'; include __DIR__ . '/includes/header.php'; include __DIR__ . '/includes/navbar.php';
?>
<div class="auth-wrap"><div class="auth-card">
    <div class="auth-icon"><i class="fas fa-user-plus"></i></div>
    <h1>Buat Akun Baru</h1>
    <p class="auth-sub">Gratis, cepat, dan langsung bisa pakai</p>
    <?php if ($error): ?><div class="alert alert-error"><i class="fas fa-circle-exclamation"></i> <?= $error ?></div><?php endif; ?>
    <?php if ($success): ?><div class="alert alert-success"><i class="fas fa-circle-check"></i> <?= $success ?> <a href="/login.php">Login →</a></div><?php endif; ?>
    <form method="POST">
        <input type="hidden" name="csrf" value="<?= csrf() ?>">
        <div class="form-group"><label><i class="fas fa-user"></i> Username</label><input type="text" name="username" required placeholder="Min 3 karakter"></div>
        <div class="form-group"><label><i class="fas fa-envelope"></i> Email</label><input type="email" name="email" required placeholder="email@example.com"></div>
        <div class="form-group"><label><i class="fas fa-lock"></i> Password</label><input type="password" name="password" required placeholder="Min 6 karakter"></div>
        <div class="form-group"><label><i class="fas fa-lock"></i> Konfirmasi</label><input type="password" name="confirm" required placeholder="Ulangi password"></div>
        <button class="btn btn-primary btn-block btn-lg"><i class="fas fa-user-plus"></i> Daftar Sekarang</button>
    </form>
    <p class="auth-footer">Sudah punya akun? <a href="/login.php">Login</a></p>
</div></div>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/logout.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
if (isLoggedIn()) logAct($pdo, $_SESSION['user_id'], 'Logout');
session_destroy();
header('Location: /login.php'); exit;
PHPEOF

echo -e "${GREEN}  ✓ Auth pages OK${NC}"

# ============ STEP 8: TOOLS / GENERATOR ============
cat > "$WEB_ROOT/tools.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
requireLogin();

$userId = $_SESSION['user_id'];
$isVipUser = isVip();
$dailyLimit = $isVipUser ? 999 : 4;

// Reset daily
$s = $pdo->prepare("SELECT daily_count, daily_date, role FROM users WHERE id=?");
$s->execute([$userId]);
$me = $s->fetch();
if ($me['daily_date'] !== date('Y-m-d')) {
    $pdo->prepare("UPDATE users SET daily_count=0, daily_date=? WHERE id=?")->execute([date('Y-m-d'), $userId]);
    $me['daily_count'] = 0;
}
$used = (int)$me['daily_count'];
$sisa = max(0, $dailyLimit - $used);

$pageTitle = 'Tools';
include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/navbar.php';
?>
<div class="container">
    <div class="page-head">
        <h1><i class="fas fa-wand-magic-sparkles"></i> Tools Generator</h1>
        <p>Generate akun premium Alight Motion secara otomatis</p>
    </div>

    <div class="quota-bar">
        <div class="quota-info">
            <span><i class="fas fa-gauge-high"></i> Kuota: <b id="quotaText"><?= $sisa ?>/<?= $isVipUser ? '∞' : $dailyLimit ?></b></span>
            <?php if (!$isVipUser): ?>
                <a href="/vip.php" class="btn btn-sm btn-gold"><i class="fas fa-crown"></i> Upgrade VIP</a>
            <?php else: ?>
                <span class="badge badge-vip"><i class="fas fa-crown"></i> VIP Member</span>
            <?php endif; ?>
        </div>
    </div>

    <div class="tool-grid">
        <div class="tool-card">
            <div class="tc-head">
                <i class="fas fa-envelope-circle-check"></i>
                <h3>1. Temp Mail</h3>
            </div>
            <p>Generate email sementara otomatis</p>
            <button class="btn btn-primary btn-block" id="btnGenMail">
                <i class="fas fa-plus"></i> Generate Email
            </button>
        </div>

        <div class="tool-card">
            <div class="tc-head">
                <i class="fas fa-paper-plane"></i>
                <h3>2. Kirim Magic Link</h3>
            </div>
            <p>Kirim link verifikasi ke email</p>
            <button class="btn btn-primary btn-block" id="btnSendMagic" disabled>
                <i class="fas fa-paper-plane"></i> Kirim
            </button>
        </div>

        <div class="tool-card">
            <div class="tc-head">
                <i class="fas fa-inbox"></i>
                <h3>3. Cek Inbox</h3>
            </div>
            <p>Auto-polling inbox real-time</p>
            <button class="btn btn-primary btn-block" id="btnInbox" disabled>
                <i class="fas fa-sync"></i> Refresh
            </button>
        </div>

        <div class="tool-card tc-hero">
            <div class="tc-head">
                <i class="fas fa-bolt"></i>
                <h3>⚡ AUTO MODE</h3>
            </div>
            <p>1 klik = semua step otomatis</p>
            <button class="btn btn-gold btn-block pulse-btn" id="btnAuto">
                <i class="fas fa-bolt"></i> FULL AUTO
            </button>
        </div>
    </div>

    <!-- EMAIL CARD -->
    <div class="email-card" id="emailCard" style="display:none">
        <div class="ec-head">
            <i class="fas fa-envelope"></i>
            <span>Email Aktif</span>
        </div>
        <div class="ec-body">
            <code id="emailText">-</code>
            <button class="btn-copy" onclick="copyText(document.getElementById('emailText').innerText)"><i class="fas fa-copy"></i></button>
        </div>
        <div class="ec-foot">
            <small id="providerText">-</small>
            <a id="inboxViewerLink" href="#" target="_blank" class="btn btn-sm btn-outline">
                <i class="fas fa-external-link-alt"></i> Buka Inbox
            </a>
        </div>
    </div>

    <!-- PROGRESS -->
    <div class="progress-card" id="progressCard" style="display:none">
        <div class="pc-head">
            <span>Progress</span>
            <span id="progressPct">0%</span>
        </div>
        <div class="progress-bar">
            <div class="pb-fill" id="progressFill" style="width:0%"></div>
        </div>
        <div class="pc-log" id="pcLog"></div>
    </div>

    <!-- INBOX -->
    <div class="inbox-card" id="inboxCard" style="display:none">
        <div class="ic-head">
            <i class="fas fa-inbox"></i> Inbox
            <button class="btn btn-sm btn-outline" onclick="loadInbox()"><i class="fas fa-sync"></i></button>
        </div>
        <div class="ic-body" id="inboxBody">
            <p class="empty">Belum ada email</p>
        </div>
    </div>

    <!-- RESULT -->
    <div class="result-card" id="resultCard" style="display:none"></div>
</div>

<script src="/assets/js/tools.js"></script>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# ============ TOOLS.JS ============
cat > "$WEB_ROOT/assets/js/tools.js" << 'JSEOF'
// ===== TOOLS GENERATOR =====
const state = { email: null, provider: null, base: null, token: null, viewer: null, password: null };

function copyText(t) { navigator.clipboard.writeText(t).then(() => toast('Copied!')); }

function toast(msg, type = 'info') {
    const el = document.createElement('div');
    el.className = 'toast toast-' + type;
    el.innerHTML = `<i class="fas fa-circle-info"></i> ${msg}`;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 3000);
}

function setProgress(pct, log) {
    document.getElementById('progressCard').style.display = 'block';
    document.getElementById('progressFill').style.width = pct + '%';
    document.getElementById('progressPct').textContent = Math.round(pct) + '%';
    if (log) {
        const pcLog = document.getElementById('pcLog');
        pcLog.innerHTML += `<div class="pl-line">→ ${log}</div>`;
        pcLog.scrollTop = pcLog.scrollHeight;
    }
}

async function api(action, data = {}) {
    const res = await fetch('/api/generate.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action, ...data })
    });
    return await res.json();
}

// Generate email
document.getElementById('btnGenMail')?.addEventListener('click', async () => {
    const btn = document.getElementById('btnGenMail');
    btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Loading...';
    const r = await api('generate_mail');
    btn.disabled = false; btn.innerHTML = '<i class="fas fa-plus"></i> Generate Email';
    if (!r.ok) return toast(r.error || 'Gagal', 'error');
    state.email = r.email; state.provider = r.provider;
    state.base = r.base; state.token = r.token;
    state.viewer = r.viewer; state.password = r.password;
    document.getElementById('emailCard').style.display = 'block';
    document.getElementById('emailText').innerText = r.email;
    document.getElementById('providerText').innerText = 'Provider: ' + r.provider;
    document.getElementById('inboxViewerLink').href = r.viewer + '?login=' + encodeURIComponent(r.email);
    document.getElementById('btnSendMagic').disabled = false;
    document.getElementById('btnInbox').disabled = false;
    toast('Email generated: ' + r.email, 'success');
});

// Send magic link
document.getElementById('btnSendMagic')?.addEventListener('click', async () => {
    if (!state.email) return toast('Generate email dulu', 'error');
    const btn = document.getElementById('btnSendMagic');
    btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
    setProgress(30, 'Kirim magic link...');
    const r = await api('send_magic', { email: state.email });
    btn.disabled = false; btn.innerHTML = '<i class="fas fa-paper-plane"></i> Kirim';
    if (!r.ok) { setProgress(30, '❌ ' + (r.error || 'Gagal')); return toast(r.error, 'error'); }
    setProgress(50, '✅ Magic link terkirim');
    toast('Magic link terkirim!', 'success');
});

// Refresh inbox
document.getElementById('btnInbox')?.addEventListener('click', loadInbox);

async function loadInbox() {
    if (!state.base || !state.token) return;
    const r = await api('fetch_inbox', { base: state.base, token: state.token });
    if (!r.ok) return toast(r.error, 'error');
    document.getElementById('inboxCard').style.display = 'block';
    const body = document.getElementById('inboxBody');
    if (!r.messages || r.messages.length === 0) {
        body.innerHTML = '<p class="empty">Belum ada email</p>';
        return;
    }
    body.innerHTML = r.messages.map(m => `
        <div class="inbox-item">
            <div class="ii-head">
                <strong>${m.subject || '(no subject)'}</strong>
                <small>${m.from?.address || ''}</small>
            </div>
            <div class="ii-body">${(m.intro || '').slice(0, 150)}</div>
            <button class="btn btn-sm btn-outline" onclick="openMail('${m.id}')">Buka</button>
        </div>
    `).join('');
}

async function openMail(id) {
    const r = await api('read_mail', { base: state.base, token: state.token, id });
    if (!r.ok) return toast(r.error, 'error');
    const html = r.data.html?.[0] || r.data.text?.[0] || '';
    const w = window.open('', '_blank', 'width=600,height=700');
    w.document.write('<pre style="white-space:pre-wrap;font-family:sans-serif;padding:20px">' + (r.data.text?.[0] || html.replace(/<[^>]*>/g,'')) + '</pre>');
}

// AUTO MODE
document.getElementById('btnAuto')?.addEventListener('click', async () => {
    const btn = document.getElementById('btnAuto');
    btn.disabled = true;
    document.getElementById('pcLog').innerHTML = '';
    setProgress(5, 'Memulai...');

    // Step 1: generate mail
    setProgress(10, '1️⃣ Generate email...');
    const g = await api('generate_mail');
    if (!g.ok) { setProgress(10, '❌ ' + g.error); btn.disabled = false; return toast(g.error, 'error'); }
    state.email = g.email; state.base = g.base; state.token = g.token; state.viewer = g.viewer;
    document.getElementById('emailCard').style.display = 'block';
    document.getElementById('emailText').innerText = g.email;
    document.getElementById('providerText').innerText = 'Provider: ' + g.provider;
    document.getElementById('inboxViewerLink').href = g.viewer + '?login=' + encodeURIComponent(g.email);
    setProgress(20, '✅ Email: ' + g.email);

    // Step 2: send magic link
    setProgress(30, '2️⃣ Kirim magic link...');
    const m = await api('send_magic', { email: g.email });
    if (!m.ok) { setProgress(30, '❌ ' + m.error); btn.disabled = false; return toast(m.error, 'error'); }
    setProgress(40, '✅ Magic link terkirim');

    // Step 3: polling inbox (max 3 menit)
    setProgress(45, '3️⃣ Menunggu email verifikasi...');
    let link = null, code = null;
    const startTime = Date.now();
    while (Date.now() - startTime < 180000) {
        const poll = await api('poll_inbox', { base: g.base, token: g.token });
        if (poll.ok && (poll.link || poll.code)) {
            link = poll.link; code = poll.code;
            break;
        }
        const elapsed = Date.now() - startTime;
        const pct = 45 + Math.min(20, (elapsed / 180000) * 20);
        setProgress(pct, 'Polling inbox... (' + Math.round(elapsed/1000) + 's)');
        await new Promise(r => setTimeout(r, 4000));
    }
    if (!link && !code) { setProgress(65, '❌ Timeout'); btn.disabled = false; return toast('Email gak masuk', 'error'); }
    setProgress(70, '✅ Email diterima');

    // Step 4: verify
    setProgress(75, '4️⃣ Verifikasi akun...');
    const v = await api('verify', { email: g.email, link, code });
    if (!v.ok) { setProgress(75, '❌ ' + v.error); btn.disabled = false; return toast(v.error, 'error'); }
    setProgress(85, '✅ Verifikasi OK');

    // Step 5: apply premium
    setProgress(90, '5️⃣ Apply premium...');
    const a = await api('apply', { email: g.email, idToken: v.idToken });
    if (!a.ok) { setProgress(90, '❌ ' + a.error); btn.disabled = false; return toast(a.error, 'error'); }

    setProgress(100, '✅ SELESAI! Premium aktif!');
    document.getElementById('resultCard').style.display = 'block';
    document.getElementById('resultCard').innerHTML = `
        <div class="rc-success">
            <div class="rc-icon">✅</div>
            <h3>Premium Berhasil!</h3>
            <p>Email: <code>${g.email}</code></p>
            <a href="/user/" class="btn btn-primary">Kembali ke Dashboard</a>
        </div>
    `;
    btn.disabled = false;
    toast('Premium berhasil! 🎉', 'success');
});
JSEOF

# ============ API GENERATE ============
cat > "$WEB_ROOT/api/generate.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
header('Content-Type: application/json');

if (!isLoggedIn()) { echo json_encode(['ok'=>false,'error'=>'Login required']); exit; }

$userId = $_SESSION['user_id'];
$input = json_decode(file_get_contents('php://input'), true) ?: [];
$action = $input['action'] ?? '';

// Cek limit
$s = $pdo->prepare("SELECT daily_count, daily_date, role FROM users WHERE id=?");
$s->execute([$userId]);
$me = $s->fetch();
$isVipUser = in_array($me['role'], ['admin','vip']);
$limit = $isVipUser ? 999 : 4;

if ($me['daily_date'] !== date('Y-m-d')) {
    $pdo->prepare("UPDATE users SET daily_count=0, daily_date=? WHERE id=?")->execute([date('Y-m-d'), $userId]);
    $me['daily_count'] = 0;
}
if (!$isVipUser && (int)$me['daily_count'] >= $limit) {
    echo json_encode(['ok'=>false,'error'=>'Limit harian habis ('.$limit.'x). Upgrade VIP!']);
    exit;
}

switch ($action) {
    case 'generate_mail':
        $r = generateTempMail();
        if ($r['ok']) {
            // Simpan history
            $pdo->prepare("INSERT INTO premium_history (user_id, email, status, message) VALUES (?,?,?,?)")
                ->execute([$userId, $r['email'], 'pending', 'Temp mail dibuat']);
        }
        echo json_encode($r);
        break;

    case 'send_magic':
        $email = $input['email'] ?? '';
        if (!$email) { echo json_encode(['ok'=>false,'error'=>'Email kosong']); exit; }
        $r = apiCall('send-magiclink', ['email'=>$email]);
        echo json_encode($r);
        break;

    case 'fetch_inbox':
        $base = $input['base'] ?? ''; $token = $input['token'] ?? '';
        $messages = fetchInbox($base, $token);
        echo json_encode(['ok'=>true, 'messages'=>$messages]);
        break;

    case 'read_mail':
        $base = $input['base'] ?? ''; $token = $input['token'] ?? ''; $id = $input['id'] ?? '';
        $data = fetchMessage($base, $token, $id);
        echo json_encode(['ok'=>true, 'data'=>$data]);
        break;

    case 'poll_inbox':
        $base = $input['base'] ?? ''; $token = $input['token'] ?? '';
        $messages = fetchInbox($base, $token);
        $link = null; $code = null;
        foreach (array_slice($messages, 0, 5) as $m) {
            $full = fetchMessage($base, $token, $m['id']);
            $blob = '';
            if (is_array($full['text'] ?? null)) $blob .= implode("\n", $full['text']);
            elseif (is_string($full['text'] ?? null)) $blob .= $full['text'];
            if (is_array($full['html'] ?? null)) $blob .= "\n" . implode("\n", $full['html']);
            elseif (is_string($full['html'] ?? null)) $blob .= "\n" . $full['html'];

            // Extract link
            $decoded = html_entity_decode($blob);
            if (preg_match_all('#https?://[^\s"\'<>)\]]+#i', $decoded, $mch)) {
                foreach ($mch[0] as $u) {
                    if (preg_match('/(verify|verif|magic|token|confirm|activate|auth|alight)/i', $u)) { $link = $u; break; }
                }
                if (!$link && !empty($mch[0])) $link = $mch[0][0];
            }
            // Extract code
            $textOnly = strip_tags($blob);
            if (preg_match('/(?:code|kode|verification|验证码|码)[\s:：]*(\d{4,8})/i', $textOnly, $cm)) $code = $cm[1];
            elseif (preg_match('/\b(\d{6})\b/', $textOnly, $cm)) $code = $cm[1];

            if ($link || $code) break;
        }
        echo json_encode(['ok'=>true, 'link'=>$link, 'code'=>$code]);
        break;

    case 'verify':
        $email = $input['email'] ?? ''; $link = $input['link'] ?? null; $code = $input['code'] ?? null;
        $body = ['email'=>$email];
        if ($link) $body['rawLink'] = $link;
        elseif ($code) $body['code'] = $code;
        $r = apiCall('verify-account', $body);
        if ($r['ok']) {
            $idToken = $r['data']['idToken'] ?? $r['data']['data']['idToken'] ?? null;
            if ($idToken) {
                echo json_encode(['ok'=>true, 'idToken'=>$idToken]);
                break;
            }
            echo json_encode(['ok'=>false, 'error'=>'No idToken']);
        } else {
            echo json_encode($r);
        }
        break;

    case 'apply':
        $email = $input['email'] ?? ''; $idToken = $input['idToken'] ?? '';
        $r = apiCall('apply-premium', ['email'=>$email, 'idToken'=>$idToken]);
        if ($r['ok']) {
            // Increment daily & stats
            $pdo->prepare("UPDATE users SET daily_count=daily_count+1, daily_date=?, total_runs=total_runs+1, success_runs=success_runs+1 WHERE id=?")
                ->execute([date('Y-m-d'), $userId]);
            $pdo->prepare("UPDATE premium_history SET status='success', message='Premium aktif' WHERE user_id=? AND email=? ORDER BY id DESC LIMIT 1")
                ->execute([$userId, $email]);
            logAct($pdo, $userId, "Premium: $email");
            notifyAdmin($pdo, 'Premium Baru', "User #$userId berhasil premium: $email");
        } else {
            $pdo->prepare("UPDATE users SET failed_runs=failed_runs+1 WHERE id=?")->execute([$userId]);
            $pdo->prepare("UPDATE premium_history SET status='failed', message=? WHERE user_id=? AND email=? ORDER BY id DESC LIMIT 1")
                ->execute([$r['error'] ?? 'Error', $userId, $email]);
        }
        echo json_encode($r);
        break;

    default:
        echo json_encode(['ok'=>false, 'error'=>'Unknown action']);
}
PHPEOF

# ============ USER DASHBOARD ============
cat > "$WEB_ROOT/user/index.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireLogin();
$pageTitle = 'Dashboard';
$uid = $_SESSION['user_id'];
$s = $pdo->prepare("SELECT * FROM users WHERE id=?"); $s->execute([$uid]); $me = $s->fetch();
$logs = $pdo->prepare("SELECT * FROM activity_log WHERE user_id=? ORDER BY id DESC LIMIT 8");
$logs->execute([$uid]); $logs = $logs->fetchAll();
$hist = $pdo->prepare("SELECT * FROM premium_history WHERE user_id=? ORDER BY id DESC LIMIT 5");
$hist->execute([$uid]); $hist = $hist->fetchAll();

$isVipUser = in_array($me['role'], ['admin','vip']);
$limit = $isVipUser ? '∞' : 4;
$usedToday = $me['daily_date'] === date('Y-m-d') ? $me['daily_count'] : 0;

include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>
<div class="container">
    <div class="welcome-card">
        <div class="wc-left">
            <div class="wc-avatar"><?= strtoupper(substr($me['username'], 0, 1)) ?></div>
            <div>
                <h1>Halo, <?= htmlspecialchars($me['username']) ?>! 👋</h1>
                <p>
                    <?php if ($me['role'] === 'admin'): ?>
                        <span class="badge badge-admin"><i class="fas fa-shield-halved"></i> ADMIN</span>
                    <?php elseif ($me['role'] === 'vip'): ?>
                        <span class="badge badge-vip"><i class="fas fa-crown"></i> VIP</span>
                    <?php else: ?>
                        <span class="badge badge-user">MEMBER</span>
                    <?php endif; ?>
                    <span style="margin-left:8px;color:var(--text-muted)"><?= htmlspecialchars($me['email']) ?></span>
                </p>
            </div>
        </div>
        <div class="wc-right">
            <a href="/tools.php" class="btn btn-primary pulse-btn"><i class="fas fa-bolt"></i> Generate</a>
        </div>
    </div>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon" style="background:linear-gradient(135deg,#667eea,#764ba2)"><i class="fas fa-gauge-high"></i></div>
            <div class="stat-info"><h3><?= $usedToday ?>/<?= $limit ?></h3><p>Kuota Hari Ini</p></div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background:linear-gradient(135deg,#43e97b,#38f9d7)"><i class="fas fa-check-circle"></i></div>
            <div class="stat-info"><h3><?= (int)$me['success_runs'] ?></h3><p>Sukses</p></div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background:linear-gradient(135deg,#f093fb,#f5576c)"><i class="fas fa-xmark-circle"></i></div>
            <div class="stat-info"><h3><?= (int)$me['failed_runs'] ?></h3><p>Gagal</p></div>
        </div>
        <div class="stat-card">
            <div class="stat-icon" style="background:linear-gradient(135deg,#4facfe,#00f2fe)"><i class="fas fa-calendar"></i></div>
            <div class="stat-info"><h3><?= date('d M', strtotime($me['created_at'])) ?></h3><p>Join</p></div>
        </div>
    </div>

    <div class="grid-2">
        <div class="card">
            <h2><i class="fas fa-history"></i> Aktivitas Terakhir</h2>
            <?php if (empty($logs)): ?><p class="empty">Belum ada aktivitas</p>
            <?php else: foreach ($logs as $l): ?>
                <div class="log-item">
                    <i class="fas fa-circle-dot"></i>
                    <div><strong><?= htmlspecialchars($l['action']) ?></strong><br><small><?= $l['created_at'] ?></small></div>
                </div>
            <?php endforeach; endif; ?>
        </div>
        <div class="card">
            <h2><i class="fas fa-crown"></i> Riwayat Premium</h2>
            <?php if (empty($hist)): ?><p class="empty">Belum ada premium</p>
            <?php else: foreach ($hist as $h): ?>
                <div class="log-item">
                    <i class="fas fa-<?= $h['status']==='success'?'check-circle':'xmark-circle' ?>" style="color:<?= $h['status']==='success'?'var(--success)':'var(--danger)' ?>"></i>
                    <div><strong><?= htmlspecialchars($h['email']) ?></strong><br><small><?= $h['status'] ?> • <?= $h['created_at'] ?></small></div>
                </div>
            <?php endforeach; endif; ?>
        </div>
    </div>
</div>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

# ============ VIP PAGE ============
cat > "$WEB_ROOT/vip.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
$pageTitle = 'VIP Member';
$msg = ''; $err = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isLoggedIn() && checkCsrf($_POST['csrf'] ?? '')) {
    $amount = (int)($_POST['amount'] ?? 0);
    if ($amount < MIN_PAYMENT) $err = 'Minimal Rp ' . number_format(MIN_PAYMENT, 0, ',', '.');
    else {
        $code = generateUniqueCode();
        $total = $amount + $code;
        $s = $pdo->prepare("INSERT INTO payments (user_id, amount, unique_code, total) VALUES (?,?,?,?)");
        $s->execute([$_SESSION['user_id'], $amount, $code, $total]);
        $msg = "Order dibuat! Transfer Rp " . number_format($total, 0, ',', '.') . " (kode unik: $code). Upload bukti ke admin via live chat.";
        notifyAdmin($pdo, 'Pembayaran Baru', "User {$_SESSION['username']} order Rp " . number_format($total, 0, ',', '.'));
    }
}

include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/navbar.php';
?>
<div class="container">
    <div class="vip-hero">
        <div class="vip-crown-big">👑</div>
        <h1>Upgrade ke <span class="gradient-gold">VIP Member</span></h1>
        <p>Dapatkan akses unlimited dan semua fitur premium</p>
    </div>

    <?php if ($msg): ?><div class="alert alert-success"><i class="fas fa-check-circle"></i> <?= $msg ?></div><?php endif; ?>
    <?php if ($err): ?><div class="alert alert-error"><i class="fas fa-circle-exclamation"></i> <?= $err ?></div><?php endif; ?>

    <div class="vip-grid">
        <div class="vip-benefit">
            <h2><i class="fas fa-gem"></i> Benefit VIP</h2>
            <ul class="vip-list">
                <li><i class="fas fa-check"></i> Generate <b>UNLIMITED</b></li>
                <li><i class="fas fa-check"></i> Priority queue</li>
                <li><i class="fas fa-check"></i> Bebas limit harian</li>
                <li><i class="fas fa-check"></i> Support fast response</li>
                <li><i class="fas fa-check"></i> Badge VIP di profile</li>
                <li><i class="fas fa-check"></i> Akses fitur baru lebih awal</li>
            </ul>
        </div>

        <div class="vip-payment">
            <h2><i class="fas fa-qrcode"></i> Pembayaran QRIS</h2>
            <p>Scan QRIS di bawah, lalu transfer sesuai nominal.</p>
            <div class="qris-box">
                <img src="<?= QRIS_URL ?>" alt="QRIS" class="qris-img">
            </div>
            <div class="payment-info">
                <div class="pi-row"><span>Minimal:</span><strong>Rp <?= number_format(MIN_PAYMENT, 0, ',', '.') ?></strong></div>
                <div class="pi-row"><span>Kode unik:</span><strong>+Rp 2008 - 2999</strong></div>
                <div class="pi-row"><span>Contoh total:</span><strong>Rp 5.008</strong></div>
            </div>

            <?php if (isLoggedIn()): ?>
            <form method="POST" class="vip-form">
                <input type="hidden" name="csrf" value="<?= csrf() ?>">
                <label>Nominal Transfer (min <?= number_format(MIN_PAYMENT, 0, ',', '.') ?>)</label>
                <input type="number" name="amount" min="<?= MIN_PAYMENT ?>" value="<?= MIN_PAYMENT ?>" required>
                <button class="btn btn-gold btn-block btn-lg"><i class="fas fa-crown"></i> Buat Order VIP</button>
            </form>
            <?php else: ?>
                <a href="/login.php" class="btn btn-gold btn-block btn-lg"><i class="fas fa-arrow-right-to-bracket"></i> Login Dulu</a>
            <?php endif; ?>

            <div class="vip-note">
                <i class="fas fa-info-circle"></i>
                Setelah transfer, kirim bukti ke <a href="/live-chat.php">Live Chat</a>. Admin akan approve manual dalam 1-24 jam.
            </div>
        </div>
    </div>
</div>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# ============ PROFILE ============
cat > "$WEB_ROOT/profile.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
requireLogin();
$uid = $_SESSION['user_id'];
$msg = ''; $err = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if (!checkCsrf($_POST['csrf'] ?? '')) $err = 'CSRF error';
    else {
        $act = $_POST['act'] ?? '';
        if ($act === 'profile') {
            $bio = trim($_POST['bio'] ?? '');
            $pdo->prepare("UPDATE users SET bio=? WHERE id=?")->execute([$bio, $uid]);
            $msg = 'Profile diupdate';
            logAct($pdo, $uid, 'Update profile');
        } elseif ($act === 'password') {
            $old = $_POST['old'] ?? ''; $new = $_POST['new'] ?? ''; $c = $_POST['confirm'] ?? '';
            $s = $pdo->prepare("SELECT password FROM users WHERE id=?"); $s->execute([$uid]);
            $p = $s->fetch()['password'];
            if (!password_verify($old, $p)) $err = 'Password lama salah';
            elseif (strlen($new) < 6) $err = 'Password baru min 6';
            elseif ($new !== $c) $err = 'Konfirmasi beda';
            else {
                $pdo->prepare("UPDATE users SET password=? WHERE id=?")->execute([password_hash($new, PASSWORD_BCRYPT), $uid]);
                $msg = 'Password diupdate';
                logAct($pdo, $uid, 'Ganti password');
            }
        }
    }
}

$s = $pdo->prepare("SELECT * FROM users WHERE id=?"); $s->execute([$uid]); $me = $s->fetch();
$pageTitle = 'Profile';
include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/navbar.php';
?>
<div class="container">
    <div class="page-head">
        <h1><i class="fas fa-user-circle"></i> Profile Saya</h1>
    </div>

    <?php if ($msg): ?><div class="alert alert-success"><i class="fas fa-check-circle"></i> <?= $msg ?></div><?php endif; ?>
    <?php if ($err): ?><div class="alert alert-error"><i class="fas fa-circle-exclamation"></i> <?= $err ?></div><?php endif; ?>

    <div class="grid-2">
        <div class="card">
            <div class="profile-head">
                <div class="profile-avatar"><?= strtoupper(substr($me['username'], 0, 1)) ?></div>
                <div>
                    <h2><?= htmlspecialchars($me['username']) ?></h2>
                    <p><?= htmlspecialchars($me['email']) ?></p>
                    <?php if ($me['role']==='admin'): ?><span class="badge badge-admin"><i class="fas fa-shield-halved"></i> ADMIN</span>
                    <?php elseif ($me['role']==='vip'): ?><span class="badge badge-vip"><i class="fas fa-crown"></i> VIP</span>
                    <?php else: ?><span class="badge badge-user">MEMBER</span><?php endif; ?>
                </div>
            </div>
            <div class="profile-info">
                <div class="pi-row"><span>User ID</span><code>#<?= $me['id'] ?></code></div>
                <div class="pi-row"><span>Bergabung</span><strong><?= $me['created_at'] ?></strong></div>
                <div class="pi-row"><span>Total Run</span><strong><?= (int)$me['total_runs'] ?></strong></div>
                <div class="pi-row"><span>Sukses</span><strong style="color:var(--success)"><?= (int)$me['success_runs'] ?></strong></div>
            </div>
        </div>

        <div class="card">
            <h2><i class="fas fa-edit"></i> Edit Profile</h2>
            <form method="POST">
                <input type="hidden" name="csrf" value="<?= csrf() ?>">
                <input type="hidden" name="act" value="profile">
                <div class="form-group"><label>Bio</label><textarea name="bio" rows="3" class="form-input" placeholder="Ceritakan tentang kamu..."><?= htmlspecialchars($me['bio'] ?? '') ?></textarea></div>
                <button class="btn btn-primary"><i class="fas fa-save"></i> Simpan</button>
            </form>

            <hr style="margin:25px 0;border:none;border-top:1px solid var(--border)">

            <h2><i class="fas fa-key"></i> Ganti Password</h2>
            <form method="POST">
                <input type="hidden" name="csrf" value="<?= csrf() ?>">
                <input type="hidden" name="act" value="password">
                <div class="form-group"><label>Password Lama</label><input type="password" name="old" required></div>
                <div class="form-group"><label>Password Baru</label><input type="password" name="new" required></div>
                <div class="form-group"><label>Konfirmasi</label><input type="password" name="confirm" required></div>
                <button class="btn btn-primary"><i class="fas fa-key"></i> Ganti</button>
            </form>
        </div>
    </div>
</div>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

# ============ LIVE CHAT ============
cat > "$WEB_ROOT/live-chat.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/includes/config.php';
$pageTitle = 'Live Chat';
include __DIR__ . '/includes/header.php';
include __DIR__ . '/includes/navbar.php';
?>
<div class="container">
    <div class="page-head">
        <h1><i class="fas fa-comments"></i> Live Chat</h1>
        <p>Chat dengan admin & user lain real-time</p>
    </div>

    <div class="chat-box">
        <div class="chat-messages" id="chatMessages"></div>
        <div class="chat-input">
            <input type="text" id="chatInput" placeholder="Tulis pesan..." maxlength="500">
            <button class="btn btn-primary" id="btnSend"><i class="fas fa-paper-plane"></i></button>
        </div>
    </div>
</div>

<script>
const chatBox = document.getElementById('chatMessages');
const input = document.getElementById('chatInput');

async function loadChat() {
    try {
        const r = await fetch('/api/chat.php?action=list').then(x => x.json());
        if (!r.ok) return;
        const box = document.getElementById('chatMessages');
        const wasBottom = box.scrollTop + box.clientHeight >= box.scrollHeight - 50;
        box.innerHTML = r.messages.map(m => `
            <div class="chat-msg ${m.is_admin==1?'chat-admin':''}">
                <div class="cm-head">
                    <strong>${m.username || 'Guest'}${m.is_admin==1?' 👑':''}</strong>
                    <small>${new Date(m.created_at).toLocaleTimeString('id-ID',{hour:'2-digit',minute:'2-digit'})}</small>
                </div>
                <div class="cm-body">${escapeHtml(m.message)}</div>
            </div>
        `).join('');
        if (wasBottom) box.scrollTop = box.scrollHeight;
    } catch(e) {}
}

function escapeHtml(t) { const d = document.createElement('div'); d.textContent = t; return d.innerHTML; }

async function sendMsg() {
    const t = input.value.trim();
    if (!t) return;
    input.value = '';
    await fetch('/api/chat.php', {
        method: 'POST', headers: {'Content-Type':'application/json'},
        body: JSON.stringify({action:'send', message: t})
    });
    loadChat();
}

document.getElementById('btnSend').addEventListener('click', sendMsg);
input.addEventListener('keypress', e => { if (e.key === 'Enter') sendMsg(); });

loadChat();
setInterval(loadChat, 3000);
</script>
<?php include __DIR__ . '/includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/api/chat.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $s = $pdo->query("SELECT * FROM live_chat ORDER BY id DESC LIMIT 50");
    $msgs = array_reverse($s->fetchAll());
    echo json_encode(['ok'=>true, 'messages'=>$msgs]);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true) ?: [];
$action = $input['action'] ?? '';

if ($action === 'send') {
    if (!isLoggedIn()) { echo json_encode(['ok'=>false,'error'=>'Login required']); exit; }
    $msg = trim($input['message'] ?? '');
    if (!$msg) { echo json_encode(['ok'=>false,'error'=>'Kosong']); exit; }
    $s = $pdo->prepare("INSERT INTO live_chat (user_id, username, message, is_admin) VALUES (?,?,?,?)");
    $s->execute([$_SESSION['user_id'], $_SESSION['username'], $msg, isAdmin() ? 1 : 0]);
    echo json_encode(['ok'=>true]);
    exit;
}
echo json_encode(['ok'=>false]);
PHPEOF

echo -e "${GREEN}  ✓ Tools + Live Chat + VIP + Profile OK${NC}"

# ============ STEP 9: ADMIN PANEL ============
cat > "$WEB_ROOT/admin/index.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$pageTitle = 'Admin Dashboard';
$totalUsers = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='user'")->fetchColumn();
$totalVip = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='vip'")->fetchColumn();
$totalAdmin = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role='admin'")->fetchColumn();
$totalBanned = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE status='banned'")->fetchColumn();
$totalPremium = (int)$pdo->query("SELECT COUNT(*) FROM premium_history WHERE status='success'")->fetchColumn();
$pendingPay = (int)$pdo->query("SELECT COUNT(*) FROM payments WHERE status='pending'")->fetchColumn();
$recentPay = $pdo->query("SELECT p.*, u.username FROM payments p LEFT JOIN users u ON p.user_id=u.id WHERE p.status='pending' ORDER BY p.id DESC LIMIT 5")->fetchAll();
$recentUsers = $pdo->query("SELECT * FROM users ORDER BY id DESC LIMIT 5")->fetchAll();
include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>
<div class="container">
    <div class="page-head">
        <h1><i class="fas fa-shield-halved"></i> Admin Control Center</h1>
        <p>Panel lengkap untuk kelola website</p>
    </div>

    <?php if ($pendingPay > 0): ?>
    <div class="alert alert-warning pulse-warn">
        <i class="fas fa-bell"></i> <b><?= $pendingPay ?></b> pembayaran pending menunggu approval!
        <a href="/admin/payments.php" class="btn btn-sm btn-gold">Lihat</a>
    </div>
    <?php endif; ?>

    <div class="stats-grid">
        <div class="stat-card"><div class="stat-icon" style="background:linear-gradient(135deg,#667eea,#764ba2)"><i class="fas fa-users"></i></div><div class="stat-info"><h3><?= $totalUsers ?></h3><p>Total User</p></div></div>
        <div class="stat-card"><div class="stat-icon" style="background:linear-gradient(135deg,#f6d365,#fda085)"><i class="fas fa-crown"></i></div><div class="stat-info"><h3><?= $totalVip ?></h3><p>VIP</p></div></div>
        <div class="stat-card"><div class="stat-icon" style="background:linear-gradient(135deg,#43e97b,#38f9d7)"><i class="fas fa-check-circle"></i></div><div class="stat-info"><h3><?= $totalPremium ?></h3><p>Premium Sukses</p></div></div>
        <div class="stat-card"><div class="stat-icon" style="background:linear-gradient(135deg,#fa709a,#fee140)"><i class="fas fa-credit-card"></i></div><div class="stat-info"><h3><?= $pendingPay ?></h3><p>Payment Pending</p></div></div>
    </div>

    <div class="admin-grid">
        <a href="/admin/users.php" class="admin-card">
            <i class="fas fa-users-cog"></i>
            <h3>Kelola User</h3>
            <p>Ban, unban, jadikan VIP, hapus</p>
        </a>
        <a href="/admin/payments.php" class="admin-card <?= $pendingPay > 0 ? 'admin-card-alert' : '' ?>">
            <i class="fas fa-credit-card"></i>
            <h3>Pembayaran <?= $pendingPay > 0 ? "($pendingPay)" : '' ?></h3>
            <p>Approve / reject pembayaran VIP</p>
        </a>
        <a href="/admin/logs.php" class="admin-card">
            <i class="fas fa-list-alt"></i>
            <h3>Activity Logs</h3>
            <p>Semua aktivitas user</p>
        </a>
        <a href="/admin/broadcast.php" class="admin-card">
            <i class="fas fa-bullhorn"></i>
            <h3>Broadcast</h3>
            <p>Kirim notif ke semua user</p>
        </a>
        <a href="/admin/notifications.php" class="admin-card">
            <i class="fas fa-bell"></i>
            <h3>Notifikasi</h3>
            <p>Log notifikasi sistem</p>
        </a>
        <a href="/admin/settings.php" class="admin-card">
            <i class="fas fa-cog"></i>
            <h3>Pengaturan</h3>
            <p>Config website</p>
        </a>
    </div>

    <?php if (!empty($recentPay)): ?>
    <div class="card">
        <h2><i class="fas fa-hourglass-half"></i> Pembayaran Menunggu</h2>
        <table class="table">
            <thead><tr><th>User</th><th>Nominal</th><th>Status</th><th>Waktu</th><th>Aksi</th></tr></thead>
            <tbody>
                <?php foreach ($recentPay as $p): ?>
                <tr>
                    <td><?= htmlspecialchars($p['username'] ?? '-') ?></td>
                    <td><strong>Rp <?= number_format($p['total'], 0, ',', '.') ?></strong></td>
                    <td><span class="badge badge-<?= $p['status'] ?>"><?= $p['status'] ?></span></td>
                    <td><small><?= $p['created_at'] ?></small></td>
                    <td><a href="/admin/payments.php" class="btn btn-sm btn-primary">Review</a></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
    <?php endif; ?>

    <div class="card">
        <h2><i class="fas fa-user-plus"></i> User Terbaru</h2>
        <table class="table">
            <thead><tr><th>ID</th><th>Username</th><th>Email</th><th>Role</th><th>Status</th></tr></thead>
            <tbody>
                <?php foreach ($recentUsers as $u): ?>
                <tr>
                    <td>#<?= $u['id'] ?></td>
                    <td><?= htmlspecialchars($u['username']) ?></td>
                    <td><small><?= htmlspecialchars($u['email']) ?></small></td>
                    <td><span class="badge badge-<?= $u['role'] ?>"><?= $u['role'] ?></span></td>
                    <td><span class="badge badge-<?= $u['status'] ?>"><?= $u['status'] ?></span></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/admin/users.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && checkCsrf($_POST['csrf'] ?? '')) {
    $a = $_POST['action'] ?? ''; $uid = (int)($_POST['uid'] ?? 0);
    if ($uid && $uid != $_SESSION['user_id']) {
        if ($a === 'ban') { $pdo->prepare("UPDATE users SET status='banned' WHERE id=?")->execute([$uid]); $msg='User dibanned'; }
        elseif ($a === 'unban') { $pdo->prepare("UPDATE users SET status='active' WHERE id=?")->execute([$uid]); $msg='User diaktifkan'; }
        elseif ($a === 'vip') { $pdo->prepare("UPDATE users SET role='vip', vip_expires=DATE_ADD(NOW(), INTERVAL 30 DAY) WHERE id=?")->execute([$uid]); $msg='User jadi VIP (30 hari)'; }
        elseif ($a === 'user') { $pdo->prepare("UPDATE users SET role='user' WHERE id=?")->execute([$uid]); $msg='User downgrade'; }
        elseif ($a === 'admin') { $pdo->prepare("UPDATE users SET role='admin' WHERE id=?")->execute([$uid]); $msg='User jadi admin'; }
        elseif ($a === 'delete') { $pdo->prepare("DELETE FROM users WHERE id=?")->execute([$uid]); $msg='User dihapus'; }
        logAct($pdo, $_SESSION['user_id'], "Admin: $a user #$uid");
        notifyAdmin($pdo, 'Admin Action', "$a → user #$uid");
    }
}
$users = $pdo->query("SELECT * FROM users ORDER BY id DESC")->fetchAll();
$pageTitle = 'Kelola User';
include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>
<div class="container">
    <div class="page-head"><h1><i class="fas fa-users-cog"></i> Kelola User</h1></div>
    <?php if ($msg): ?><div class="alert alert-success"><i class="fas fa-check-circle"></i> <?= $msg ?></div><?php endif; ?>
    <div class="card">
        <table class="table">
            <thead><tr><th>ID</th><th>Username</th><th>Email</th><th>Role</th><th>Status</th><th>Run</th><th>Aksi</th></tr></thead>
            <tbody>
                <?php foreach ($users as $u): ?>
                <tr>
                    <td>#<?= $u['id'] ?></td>
                    <td><strong><?= htmlspecialchars($u['username']) ?></strong></td>
                    <td><small><?= htmlspecialchars($u['email']) ?></small></td>
                    <td><span class="badge badge-<?= $u['role'] ?>"><?= $u['role'] ?></span></td>
                    <td><span class="badge badge-<?= $u['status'] ?>"><?= $u['status'] ?></span></td>
                    <td>✅<?= (int)$u['success_runs'] ?> ❌<?= (int)$u['failed_runs'] ?></td>
                    <td class="actions">
                        <?php if ($u['id'] != $_SESSION['user_id']): ?>
                        <form method="POST" style="display:inline-flex;gap:4px" onsubmit="return confirm('Yakin?')">
                            <input type="hidden" name="csrf" value="<?= csrf() ?>">
                            <input type="hidden" name="uid" value="<?= $u['id'] ?>">
                            <?php if ($u['status']=='active'): ?>
                                <button name="action" value="ban" class="btn-icon btn-warn" title="Ban"><i class="fas fa-ban"></i></button>
                            <?php else: ?>
                                <button name="action" value="unban" class="btn-icon btn-ok" title="Unban"><i class="fas fa-check"></i></button>
                            <?php endif; ?>
                            <?php if ($u['role']=='user'): ?>
                                <button name="action" value="vip" class="btn-icon btn-gold" title="Jadikan VIP"><i class="fas fa-crown"></i></button>
                            <?php elseif ($u['role']=='vip'): ?>
                                <button name="action" value="user" class="btn-icon btn-info" title="Downgrade"><i class="fas fa-user"></i></button>
                            <?php endif; ?>
                            <button name="action" value="delete" class="btn-icon btn-danger" title="Hapus"><i class="fas fa-trash"></i></button>
                        </form>
                        <?php else: ?><span class="badge badge-info">Kamu</span><?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/admin/payments.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && checkCsrf($_POST['csrf'] ?? '')) {
    $pid = (int)($_POST['pid'] ?? 0); $act = $_POST['act'] ?? '';
    $p = $pdo->prepare("SELECT * FROM payments WHERE id=?"); $p->execute([$pid]); $pay = $p->fetch();
    if ($pay && $pay['status'] === 'pending') {
        if ($act === 'approve') {
            $pdo->prepare("UPDATE payments SET status='approved', approved_by=?, approved_at=NOW() WHERE id=?")->execute([$_SESSION['user_id'], $pid]);
            $pdo->prepare("UPDATE users SET role='vip', vip_expires=DATE_ADD(NOW(), INTERVAL 30 DAY) WHERE id=?")->execute([$pay['user_id']]);
            $msg = 'Pembayaran di-approve, user jadi VIP 30 hari!';
            notifyAdmin($pdo, 'Payment Approved', "Payment #$pid user #{$pay['user_id']}");
        } elseif ($act === 'reject') {
            $pdo->prepare("UPDATE payments SET status='rejected', approved_by=?, approved_at=NOW() WHERE id=?")->execute([$_SESSION['user_id'], $pid]);
            $msg = 'Pembayaran di-reject';
        }
    }
}
$pays = $pdo->query("SELECT p.*, u.username, u.email FROM payments p LEFT JOIN users u ON p.user_id=u.id ORDER BY p.id DESC LIMIT 100")->fetchAll();
$pageTitle = 'Pembayaran';
include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>
<div class="container">
    <div class="page-head">
        <h1><i class="fas fa-credit-card"></i> Kelola Pembayaran</h1>
        <p>Approve / reject pembayaran VIP</p>
    </div>
    <?php if ($msg): ?><div class="alert alert-success"><i class="fas fa-check-circle"></i> <?= $msg ?></div><?php endif; ?>
    <div class="card">
        <table class="table">
            <thead><tr><th>ID</th><th>User</th><th>Nominal</th><th>Kode</th><th>Total</th><th>Status</th><th>Waktu</th><th>Aksi</th></tr></thead>
            <tbody>
                <?php foreach ($pays as $p): ?>
                <tr>
                    <td>#<?= $p['id'] ?></td>
                    <td><strong><?= htmlspecialchars($p['username'] ?? '-') ?></strong><br><small><?= htmlspecialchars($p['email'] ?? '') ?></small></td>
                    <td>Rp <?= number_format($p['amount'], 0, ',', '.') ?></td>
                    <td><code><?= $p['unique_code'] ?></code></td>
                    <td><strong>Rp <?= number_format($p['total'], 0, ',', '.') ?></strong></td>
                    <td><span class="badge badge-<?= $p['status'] ?>"><?= $p['status'] ?></span></td>
                    <td><small><?= $p['created_at'] ?></small></td>
                    <td>
                        <?php if ($p['status']=='pending'): ?>
                        <form method="POST" style="display:inline-flex;gap:4px">
                            <input type="hidden" name="csrf" value="<?= csrf() ?>">
                            <input type="hidden" name="pid" value="<?= $p['id'] ?>">
                            <button name="act" value="approve" class="btn-icon btn-ok" title="Approve" onclick="return confirm('Approve?')"><i class="fas fa-check"></i></button>
                            <button name="act" value="reject" class="btn-icon btn-danger" title="Reject" onclick="return confirm('Reject?')"><i class="fas fa-xmark"></i></button>
                        </form>
                        <?php else: ?><small>—</small><?php endif; ?>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/admin/logs.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$logs = $pdo->query("SELECT l.*, u.username FROM activity_log l LEFT JOIN users u ON l.user_id=u.id ORDER BY l.id DESC LIMIT 200")->fetchAll();
$pageTitle = 'Logs';
include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>
<div class="container">
    <div class="page-head"><h1><i class="fas fa-list-alt"></i> Activity Logs</h1><p>200 log terakhir</p></div>
    <div class="card">
        <table class="table">
            <thead><tr><th>ID</th><th>User</th><th>Action</th><th>IP</th><th>Waktu</th></tr></thead>
            <tbody>
                <?php foreach ($logs as $l): ?>
                <tr><td>#<?= $l['id'] ?></td><td><?= htmlspecialchars($l['username'] ?? 'Guest') ?></td><td><?= htmlspecialchars($l['action']) ?></td><td><code><?= $l['ip'] ?></code></td><td><small><?= $l['created_at'] ?></small></td></tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
</div>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/admin/broadcast.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$msg = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST' && checkCsrf($_POST['csrf'] ?? '')) {
    $title = trim($_POST['title'] ?? ''); $message = trim($_POST['message'] ?? '');
    $target = $_POST['target'] ?? 'all';
    if ($title && $message) {
        $pdo->prepare("INSERT INTO notifications (title, message, target, created_by) VALUES (?,?,?,?)")
            ->execute([$title, $message, $target, $_SESSION['user_id']]);
        $msg = 'Broadcast terkirim!';
    }
}
$notifs = $pdo->query("SELECT n.*, u.username FROM notifications n LEFT JOIN users u ON n.created_by=u.id ORDER BY n.id DESC LIMIT 20")->fetchAll();
$pageTitle = 'Broadcast';
include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>
<div class="container">
    <div class="page-head"><h1><i class="fas fa-bullhorn"></i> Broadcast Notifikasi</h1></div>
    <?php if ($msg): ?><div class="alert alert-success"><i class="fas fa-check-circle"></i> <?= $msg ?></div><?php endif; ?>

    <div class="card">
        <h2><i class="fas fa-paper-plane"></i> Kirim Broadcast</h2>
        <form method="POST">
            <input type="hidden" name="csrf" value="<?= csrf() ?>">
            <div class="form-group"><label>Judul</label><input type="text" name="title" required placeholder="Judul notifikasi"></div>
            <div class="form-group"><label>Pesan</label><textarea name="message" rows="4" class="form-input" required placeholder="Isi notifikasi..."></textarea></div>
            <div class="form-group"><label>Target</label>
                <select name="target" class="form-input">
                    <option value="all">Semua User</option>
                    <option value="user">User Biasa</option>
                    <option value="vip">VIP Only</option>
                    <option value="admin">Admin Only</option>
                </select>
            </div>
            <button class="btn btn-primary"><i class="fas fa-bullhorn"></i> Kirim</button>
        </form>
    </div>

    <div class="card">
        <h2><i class="fas fa-history"></i> Riwayat Broadcast</h2>
        <?php foreach ($notifs as $n): ?>
            <div class="log-item">
                <i class="fas fa-bell"></i>
                <div><strong><?= htmlspecialchars($n['title']) ?></strong> <span class="badge badge-info"><?= $n['target'] ?></span><br><small><?= htmlspecialchars(substr($n['message'], 0, 120)) ?>... • <?= $n['created_at'] ?></small></div>
            </div>
        <?php endforeach; ?>
    </div>
</div>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/admin/notifications.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$notifs = $pdo->query("SELECT * FROM notifications ORDER BY id DESC LIMIT 100")->fetchAll();
$pageTitle = 'Notifikasi';
include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>
<div class="container">
    <div class="page-head"><h1><i class="fas fa-bell"></i> Semua Notifikasi</h1></div>
    <div class="card">
        <?php if (empty($notifs)): ?><p class="empty">Belum ada notifikasi</p>
        <?php else: foreach ($notifs as $n): ?>
            <div class="log-item">
                <i class="fas fa-bell" style="color:var(--warning)"></i>
                <div><strong><?= htmlspecialchars($n['title']) ?></strong><br><?= htmlspecialchars($n['message']) ?><br><small><?= $n['created_at'] ?></small></div>
            </div>
        <?php endforeach; endif; ?>
    </div>
</div>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

cat > "$WEB_ROOT/admin/settings.php" << 'PHPEOF'
<?php
require_once __DIR__ . '/../includes/config.php';
requireAdmin();
$pageTitle = 'Settings';
include __DIR__ . '/../includes/header.php';
include __DIR__ . '/../includes/navbar.php';
?>
<div class="container">
    <div class="page-head"><h1><i class="fas fa-cog"></i> Pengaturan Website</h1></div>
    <div class="card">
        <h2><i class="fas fa-info-circle"></i> Info Sistem</h2>
        <table class="table">
            <tr><th>Site Name</th><td><?= SITE_NAME ?></td></tr>
            <tr><th>Site URL</th><td><a href="<?= SITE_URL ?>" target="_blank"><?= SITE_URL ?></a></td></tr>
            <tr><th>API Backend</th><td><code><?= API_BASE_URL ?></code></td></tr>
            <tr><th>Min Payment</th><td>Rp <?= number_format(MIN_PAYMENT, 0, ',', '.') ?></td></tr>
            <tr><th>PHP Version</th><td><?= phpversion() ?></td></tr>
            <tr><th>Server Time</th><td><?= date('Y-m-d H:i:s') ?></td></tr>
        </table>
    </div>
</div>
<?php include __DIR__ . '/../includes/footer.php'; ?>
PHPEOF

echo -e "${GREEN}  ✓ Admin panel OK${NC}"

# ============ STEP 10: CSS ============
echo -e "${CYAN}[10/10] Bikin CSS mewah...${NC}"

cat > "$WEB_ROOT/assets/css/style.css" << 'CSSEOF'
:root {
    --bg: #0a0a1a; --bg-2: #12122a; --bg-card: rgba(30,30,60,.6);
    --bg-nav: rgba(15,15,35,.85); --text: #e8e8ff; --text-muted: #8888aa;
    --border: rgba(120,120,200,.15);
    --primary: #7c5cff; --primary-2: #b066ff;
    --gold: #ffb700; --gold-2: #ff8c00;
    --success: #00e676; --danger: #ff4757; --warning: #ffa726; --info: #29b6f6;
    --shadow: 0 8px 40px rgba(0,0,0,.4);
    --glow: 0 0 40px rgba(124,92,255,.4);
}
[data-theme="light"] {
    --bg: #f0f2ff; --bg-2: #e8ebff; --bg-card: rgba(255,255,255,.8);
    --bg-nav: rgba(255,255,255,.9); --text: #1a1a2e; --text-muted: #666688;
    --border: rgba(100,100,180,.15);
    --shadow: 0 8px 40px rgba(80,80,180,.12);
}
* { margin:0; padding:0; box-sizing:border-box; }
html { scroll-behavior:smooth; }
body {
    font-family: 'Plus Jakarta Sans', system-ui, sans-serif;
    background: var(--bg); color: var(--text); line-height:1.6;
    min-height:100vh; overflow-x:hidden; padding-bottom:70px;
    background-image:
        radial-gradient(circle at 20% 0%, rgba(124,92,255,.15), transparent 40%),
        radial-gradient(circle at 80% 100%, rgba(176,102,255,.1), transparent 40%);
}
a { color: var(--primary); text-decoration: none; transition:.2s; }
a:hover { color: var(--primary-2); }
img { max-width:100%; display:block; }

/* NAVBAR */
.navbar {
    display:flex; justify-content:space-between; align-items:center;
    padding:14px 30px; background: var(--bg-nav);
    backdrop-filter: blur(20px); border-bottom:1px solid var(--border);
    position: sticky; top:0; z-index:100;
    box-shadow: 0 4px 30px rgba(0,0,0,.2);
}
.logo { display:flex; align-items:center; gap:10px; font-family:'Space Grotesk',sans-serif; font-weight:700; font-size:1.15em; }
.logo-icon { font-size:1.5em; }
.logo-text { color: var(--text); }
.logo-accent { background: linear-gradient(135deg, var(--primary), var(--primary-2)); -webkit-background-clip:text; -webkit-text-fill-color:transparent; background-clip:text; }
.nav-menu { display:flex; align-items:center; gap:8px; flex-wrap:wrap; }
.nav-menu a {
    color: var(--text-muted); font-weight:600; padding:8px 14px; border-radius:10px;
    display:flex; align-items:center; gap:6px; font-size:.9em; transition:.2s;
}
.nav-menu a:hover { color: var(--text); background: rgba(124,92,255,.1); }
.nav-menu a.vip-link { color: var(--gold); }
.icon-btn {
    background: transparent; border:1px solid var(--border); color:var(--text);
    padding:8px 12px; border-radius:10px; cursor:pointer; transition:.2s;
}
.icon-btn:hover { border-color: var(--primary); background: rgba(124,92,255,.1); }

/* BUTTONS */
.btn {
    padding:10px 20px; border-radius:12px; border:none; cursor:pointer;
    font-weight:700; font-family:inherit; display:inline-flex; align-items:center;
    gap:8px; transition:.25s; font-size:.9em; text-decoration:none;
}
.btn-primary {
    background: linear-gradient(135deg, var(--primary), var(--primary-2));
    color:#fff; box-shadow: 0 4px 20px rgba(124,92,255,.4);
}
.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(124,92,255,.6); }
.btn-outline { background: transparent; border:2px solid var(--primary); color: var(--primary); }
.btn-outline:hover { background: var(--primary); color:#fff; }
.btn-gold {
    background: linear-gradient(135deg, var(--gold), var(--gold-2));
    color:#000; box-shadow: 0 4px 20px rgba(255,183,0,.4);
}
.btn-gold:hover { transform: translateY(-2px); box-shadow: 0 8px 30px rgba(255,183,0,.6); }
.btn-block { width:100%; justify-content:center; }
.btn-lg { padding:14px 32px; font-size:1.05em; }
.btn-sm { padding:6px 12px; font-size:.8em; }
.btn-icon {
    background: rgba(255,255,255,.05); border:1px solid var(--border);
    padding:8px 12px; border-radius:8px; cursor:pointer; color:var(--text); transition:.2s;
}
.btn-icon:hover { color:#fff; transform:scale(1.05); }
.btn-warn:hover { background: var(--warning); border-color:var(--warning); }
.btn-ok:hover { background: var(--success); border-color:var(--success); }
.btn-info:hover { background: var(--info); border-color:var(--info); }
.btn-danger:hover { background: var(--danger); border-color:var(--danger); }
.btn-gold:hover { background: var(--gold); border-color:var(--gold); }

/* PULSE */
.pulse-btn { position:relative; overflow:hidden; }
.pulse-btn::before {
    content:''; position:absolute; inset:0;
    background: radial-gradient(circle, rgba(255,255,255,.3), transparent 70%);
    animation: pulse 2s infinite;
}
@keyframes pulse {
    0% { transform: scale(.8); opacity:1; }
    100% { transform: scale(1.5); opacity:0; }
}

/* HERO */
.hero {
    min-height:85vh; display:flex; align-items:center; justify-content:center;
    text-align:center; padding:60px 20px; position:relative; overflow:hidden;
}
.hero-bg {
    position:absolute; inset:0; z-index:-1;
    background:
        radial-gradient(circle at 30% 20%, rgba(124,92,255,.3), transparent 45%),
        radial-gradient(circle at 70% 80%, rgba(255,183,0,.15), transparent 45%);
    animation: heroFloat 20s ease-in-out infinite;
}
@keyframes heroFloat { 0%,100%{transform:scale(1)} 50%{transform:scale(1.05)} }
.hero-content { max-width:850px; z-index:1; }
.hero-badge {
    display:inline-flex; align-items:center; gap:6px;
    background: rgba(124,92,255,.15); border:1px solid rgba(124,92,255,.3);
    padding:8px 18px; border-radius:30px; font-size:.85em;
    color: var(--primary-2); margin-bottom:25px; font-weight:600;
}
.hero h1 {
    font-family:'Space Grotesk',sans-serif; font-size:4em; line-height:1.1;
    font-weight:800; margin-bottom:20px;
}
.gradient-text {
    background: linear-gradient(135deg, #7c5cff, #b066ff, #ff6b9d);
    -webkit-background-clip:text; -webkit-text-fill-color:transparent;
    background-clip:text; display:block;
}
.hero-line { display:block; color: var(--text); }
.badge-vip-sm {
    background: linear-gradient(135deg, var(--gold), var(--gold-2));
    color:#000; font-size:.4em; padding:6px 14px; border-radius:8px;
    vertical-align:middle; font-weight:800; letter-spacing:1px;
}
.hero-sub { font-size:1.15em; color:var(--text-muted); margin-bottom:35px; max-width:600px; margin-left:auto; margin-right:auto; }
.hero-actions { display:flex; gap:15px; justify-content:center; flex-wrap:wrap; margin-bottom:50px; }
.hero-stats { display:flex; gap:40px; justify-content:center; flex-wrap:wrap; }
.hs-item { text-align:center; }
.hs-item strong { display:block; font-size:1.8em; font-family:'Space Grotesk',sans-serif; color:var(--primary-2); }
.hs-item span { font-size:.85em; color:var(--text-muted); }

/* SECTIONS */
.section { max-width:1200px; margin:0 auto; padding:70px 20px; }
.section-head { text-align:center; margin-bottom:50px; }
.section-head h2 { font-family:'Space Grotesk',sans-serif; font-size:2.2em; margin-bottom:10px; }
.section-head h2 i { color: var(--primary); }
.section-head p { color:var(--text-muted); }

.features { display:grid; grid-template-columns:repeat(auto-fit,minmax(240px,1fr)); gap:20px; }
.feature-card {
    background: var(--bg-card); backdrop-filter:blur(20px);
    padding:30px; border-radius:20px; border:1px solid var(--border);
    text-align:center; transition:.3s;
}
.feature-card:hover { transform: translateY(-5px); border-color: var(--primary); box-shadow: var(--glow); }
.fc-icon {
    width:70px; height:70px; border-radius:20px; margin:0 auto 20px;
    display:flex; align-items:center; justify-content:center;
    color:#fff; font-size:1.8em;
}
.feature-card h3 { margin-bottom:10px; font-family:'Space Grotesk',sans-serif; }
.feature-card p { color:var(--text-muted); font-size:.92em; }

/* VIP BOX */
.section-vip { padding:40px 20px; }
.vip-box {
    max-width:900px; margin:0 auto; padding:60px 40px; border-radius:30px;
    background: linear-gradient(135deg, rgba(255,183,0,.15), rgba(255,140,0,.08));
    border:2px solid rgba(255,183,0,.3); position:relative; overflow:hidden;
    text-align:center;
}
.vip-glow {
    position:absolute; inset:0;
    background: radial-gradient(circle at 50% 0%, rgba(255,183,0,.4), transparent 60%);
    animation: heroFloat 5s ease-in-out infinite; pointer-events:none;
}
.vip-content { position:relative; z-index:1; }
.vip-crown { font-size:4em; margin-bottom:15px; animation: bounce 2s infinite; }
@keyframes bounce { 0%,100%{transform:translateY(0)} 50%{transform:translateY(-10px)} }
.vip-box h2 { font-family:'Space Grotesk',sans-serif; font-size:2.2em; margin-bottom:15px; }
.gradient-gold {
    background: linear-gradient(135deg, var(--gold), var(--gold-2));
    -webkit-background-clip:text; -webkit-text-fill-color:transparent; background-clip:text;
}
.vip-box p { color:var(--text-muted); margin-bottom:25px; font-size:1.05em; }
.vip-price { margin-bottom:25px; }
.vip-price-from { display:block; color:var(--text-muted); font-size:.9em; }
.vip-price-now { display:block; font-size:2.5em; font-family:'Space Grotesk',sans-serif; color:var(--gold); font-weight:800; }

/* FAQ */
.faq { max-width:800px; margin:0 auto; }
.faq details {
    background: var(--bg-card); border:1px solid var(--border);
    border-radius:14px; padding:20px; margin-bottom:12px; transition:.2s;
}
.faq details:hover { border-color: var(--primary); }
.faq summary { cursor:pointer; font-weight:700; display:flex; justify-content:space-between; align-items:center; list-style:none; }
.faq summary::-webkit-details-marker { display:none; }
.faq summary::after { content:'+'; font-size:1.5em; color:var(--primary); }
.faq details[open] summary::after { content:'−'; }
.faq p { margin-top:15px; color:var(--text-muted); padding-top:15px; border-top:1px solid var(--border); }

/* AUTH */
.auth-wrap { min-height:80vh; display:flex; align-items:center; justify-content:center; padding:40px 20px; }
.auth-card {
    background: var(--bg-card); backdrop-filter:blur(20px);
    padding:45px 40px; border-radius:25px; border:1px solid var(--border);
    width:100%; max-width:440px; box-shadow: var(--shadow);
}
.auth-icon {
    width:70px; height:70px; border-radius:20px; margin:0 auto 20px;
    background: linear-gradient(135deg, var(--primary), var(--primary-2));
    display:flex; align-items:center; justify-content:center;
    color:#fff; font-size:1.7em; box-shadow: 0 8px 30px rgba(124,92,255,.4);
}
.auth-card h1 { text-align:center; font-family:'Space Grotesk',sans-serif; margin-bottom:8px; }
.auth-sub { text-align:center; color:var(--text-muted); margin-bottom:30px; font-size:.9em; }
.auth-footer { text-align:center; color:var(--text-muted); margin-top:25px; font-size:.9em; }

/* FORMS */
.form-group { margin-bottom:18px; }
.form-group label { display:block; margin-bottom:8px; font-weight:600; font-size:.9em; color:var(--text); }
.form-group label i { color:var(--primary); margin-right:5px; }
.form-group input, .form-input, .form-group textarea, .form-group select {
    width:100%; padding:13px 16px; border:1px solid var(--border);
    border-radius:12px; background: rgba(0,0,0,.2); color:var(--text);
    font-size:.95em; font-family:inherit; transition:.2s;
}
[data-theme="light"] .form-group input, [data-theme="light"] .form-input {
    background: rgba(255,255,255,.7);
}
.form-group input:focus, .form-input:focus {
    outline:none; border-color: var(--primary);
    box-shadow: 0 0 0 4px rgba(124,92,255,.15);
}

/* ALERTS */
.alert {
    padding:14px 18px; border-radius:12px; margin-bottom:20px;
    font-size:.9em; display:flex; align-items:center; gap:10px;
}
.alert-success { background: rgba(0,230,118,.1); color: var(--success); border-left:4px solid var(--success); }
.alert-error { background: rgba(255,71,87,.1); color: var(--danger); border-left:4px solid var(--danger); }
.alert-warning { background: rgba(255,167,38,.15); color: var(--warning); border-left:4px solid var(--warning); }
.pulse-warn { animation: pulseWarn 2s infinite; }
@keyframes pulseWarn { 0%,100%{box-shadow:0 0 0 0 rgba(255,167,38,.4)} 50%{box-shadow:0 0 0 10px rgba(255,167,38,0)} }

/* CONTAINER */
.container { max-width:1200px; margin:0 auto; padding:30px 20px; }
.page-head { margin-bottom:30px; }
.page-head h1 { font-family:'Space Grotesk',sans-serif; font-size:2em; display:flex; align-items:center; gap:12px; }
.page-head h1 i { color:var(--primary); }
.page-head p { color:var(--text-muted); margin-top:5px; }

/* CARDS */
.card {
    background: var(--bg-card); backdrop-filter:blur(20px);
    padding:28px; border-radius:20px; border:1px solid var(--border);
    margin-bottom:25px; box-shadow: var(--shadow);
}
.card h2 { font-family:'Space Grotesk',sans-serif; margin-bottom:20px; font-size:1.3em; display:flex; align-items:center; gap:10px; }
.card h2 i { color:var(--primary); }

/* STATS */
.stats-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:18px; margin-bottom:25px; }
.stat-card {
    background: var(--bg-card); backdrop-filter:blur(20px);
    padding:22px; border-radius:18px; border:1px solid var(--border);
    display:flex; align-items:center; gap:16px; transition:.25s;
}
.stat-card:hover { transform: translateY(-3px); border-color: var(--primary); }
.stat-icon {
    width:55px; height:55px; border-radius:14px; display:flex;
    align-items:center; justify-content:center; color:#fff; font-size:1.5em;
    flex-shrink:0; box-shadow: 0 4px 15px rgba(0,0,0,.2);
}
.stat-info h3 { font-size:1.5em; font-family:'Space Grotesk',sans-serif; margin:0; }
.stat-info p { color:var(--text-muted); font-size:.85em; margin:0; }

/* WELCOME CARD */
.welcome-card {
    background: linear-gradient(135deg, rgba(124,92,255,.2), rgba(176,102,255,.1));
    border:1px solid rgba(124,92,255,.3); border-radius:22px;
    padding:28px; display:flex; justify-content:space-between;
    align-items:center; margin-bottom:25px; gap:20px; flex-wrap:wrap;
}
.wc-left { display:flex; align-items:center; gap:18px; }
.wc-avatar {
    width:70px; height:70px; border-radius:20px;
    background: linear-gradient(135deg, var(--primary), var(--primary-2));
    display:flex; align-items:center; justify-content:center;
    font-size:1.8em; font-weight:800; color:#fff;
    box-shadow: 0 8px 30px rgba(124,92,255,.5);
}
.welcome-card h1 { font-family:'Space Grotesk',sans-serif; font-size:1.6em; margin-bottom:5px; }

/* TABLE */
.table { width:100%; border-collapse:collapse; }
.table th {
    text-align:left; padding:13px 12px; font-size:.78em; letter-spacing:.5px;
    text-transform:uppercase; color:var(--text-muted);
    border-bottom:2px solid var(--border); background: rgba(0,0,0,.2);
}
.table td { padding:13px 12px; border-bottom:1px solid var(--border); font-size:.9em; }
.table tr:hover td { background: rgba(124,92,255,.05); }
.table code { background: rgba(124,92,255,.15); padding:3px 8px; border-radius:6px; font-size:.85em; color:var(--primary-2); }

/* BADGES */
.badge {
    padding:4px 12px; border-radius:20px; font-size:.72em; font-weight:800;
    text-transform:uppercase; display:inline-flex; align-items:center; gap:5px;
    letter-spacing:.3px;
}
.badge-admin { background: rgba(255,71,87,.15); color: var(--danger); }
.badge-vip { background: linear-gradient(135deg, var(--gold), var(--gold-2)); color:#000; }
.badge-user { background: rgba(41,182,246,.15); color: var(--info); }
.badge-active { background: rgba(0,230,118,.15); color: var(--success); }
.badge-banned { background: rgba(255,71,87,.15); color: var(--danger); }
.badge-pending { background: rgba(255,167,38,.15); color: var(--warning); }
.badge-approved { background: rgba(0,230,118,.15); color: var(--success); }
.badge-rejected { background: rgba(255,71,87,.15); color: var(--danger); }
.badge-info { background: rgba(124,92,255,.15); color: var(--primary-2); }

/* TOOLS GRID */
.tool-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:18px; margin-bottom:25px; }
.tool-card {
    background: var(--bg-card); backdrop-filter:blur(20px);
    padding:24px; border-radius:18px; border:1px solid var(--border);
    transition:.25s;
}
.tool-card:hover { transform: translateY(-3px); border-color: var(--primary); }
.tool-card.tc-hero {
    background: linear-gradient(135deg, rgba(255,183,0,.15), rgba(255,140,0,.08));
    border-color: rgba(255,183,0,.4);
}
.tc-head { display:flex; align-items:center; gap:12px; margin-bottom:12px; }
.tc-head i { font-size:1.5em; color:var(--primary); }
.tc-hero .tc-head i { color:var(--gold); }
.tc-head h3 { font-family:'Space Grotesk',sans-serif; font-size:1.05em; }
.tool-card p { color:var(--text-muted); font-size:.88em; margin-bottom:15px; }

.quota-bar {
    background: var(--bg-card); padding:18px; border-radius:15px;
    border:1px solid var(--border); margin-bottom:25px;
}
.quota-info { display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:12px; }
.quota-info span { font-size:1em; }
.quota-info b { color:var(--primary-2); }

/* EMAIL CARD */
.email-card {
    background: linear-gradient(135deg, rgba(0,230,118,.1), rgba(0,230,118,.05));
    border:1px solid rgba(0,230,118,.3); border-radius:18px;
    padding:20px; margin-bottom:20px;
}
.ec-head { display:flex; align-items:center; gap:10px; margin-bottom:12px; font-weight:700; color: var(--success); }
.ec-body {
    background: rgba(0,0,0,.3); padding:15px; border-radius:12px;
    display:flex; justify-content:space-between; align-items:center; gap:10px;
    margin-bottom:12px;
}
.ec-body code { color: var(--success); font-size:1.05em; word-break:break-all; font-family:'Space Grotesk',monospace; }
.btn-copy { background: rgba(255,255,255,.1); border:none; color:#fff; padding:8px 12px; border-radius:8px; cursor:pointer; }
.btn-copy:hover { background: var(--success); }
.ec-foot { display:flex; justify-content:space-between; align-items:center; gap:10px; flex-wrap:wrap; }
.ec-foot small { color:var(--text-muted); }

/* PROGRESS */
.progress-card {
    background: var(--bg-card); padding:20px; border-radius:18px;
    border:1px solid var(--border); margin-bottom:20px;
}
.pc-head { display:flex; justify-content:space-between; margin-bottom:12px; font-weight:700; font-family:'Space Grotesk',sans-serif; }
.progress-bar { height:12px; background: rgba(0,0,0,.3); border-radius:10px; overflow:hidden; margin-bottom:15px; }
.pb-fill {
    height:100%; background: linear-gradient(90deg, var(--primary), var(--primary-2), var(--gold));
    border-radius:10px; transition:width .5s;
    box-shadow: 0 0 20px rgba(124,92,255,.5);
}
.pc-log {
    max-height:200px; overflow-y:auto; background: rgba(0,0,0,.3);
    padding:12px; border-radius:10px; font-family:'Space Grotesk',monospace; font-size:.85em;
}
.pl-line { padding:4px 0; color: var(--text-muted); border-bottom:1px dashed rgba(255,255,255,.05); }
.pl-line:last-child { color: var(--primary-2); }

/* INBOX */
.inbox-card {
    background: var(--bg-card); padding:20px; border-radius:18px;
    border:1px solid var(--border); margin-bottom:20px;
}
.ic-head {
    display:flex; justify-content:space-between; align-items:center;
    margin-bottom:15px; font-weight:700; font-family:'Space Grotesk',sans-serif;
}
.inbox-item {
    background: rgba(0,0,0,.2); padding:14px; border-radius:12px;
    margin-bottom:10px; border:1px solid var(--border);
}
.ii-head { display:flex; justify-content:space-between; margin-bottom:8px; flex-wrap:wrap; gap:8px; }
.ii-head strong { font-size:.95em; }
.ii-head small { color: var(--text-muted); font-size:.8em; }
.ii-body { color: var(--text-muted); font-size:.85em; margin-bottom:10px; }
.empty { text-align:center; color:var(--text-muted); padding:20px; }

/* RESULT */
.result-card {
    background: linear-gradient(135deg, rgba(0,230,118,.15), rgba(0,230,118,.05));
    border:2px solid var(--success); border-radius:22px;
    padding:40px; text-align:center; animation: resultPop .5s;
}
@keyframes resultPop { 0%{transform:scale(.9); opacity:0} 100%{transform:scale(1); opacity:1} }
.rc-icon { font-size:4em; margin-bottom:15px; }
.rc-success h3 { font-family:'Space Grotesk',sans-serif; font-size:1.6em; color:var(--success); margin-bottom:10px; }
.rc-success p { margin-bottom:20px; }
.rc-success code { background: rgba(0,0,0,.3); padding:6px 12px; border-radius:8px; }

/* VIP PAGE */
.vip-hero { text-align:center; padding:40px 20px; }
.vip-crown-big { font-size:5em; margin-bottom:15px; animation: bounce 2s infinite; }
.vip-hero h1 { font-family:'Space Grotesk',sans-serif; font-size:2.5em; margin-bottom:10px; }
.vip-hero p { color:var(--text-muted); font-size:1.05em; }
.vip-grid { display:grid; grid-template-columns:1fr 1fr; gap:25px; margin-top:30px; }
@media (max-width:900px) { .vip-grid { grid-template-columns:1fr; } }
.vip-benefit, .vip-payment {
    background: var(--bg-card); backdrop-filter:blur(20px);
    padding:30px; border-radius:22px; border:1px solid var(--border);
}
.vip-benefit h2, .vip-payment h2 {
    font-family:'Space Grotesk',sans-serif; margin-bottom:20px; font-size:1.4em;
    display:flex; align-items:center; gap:10px;
}
.vip-list { list-style:none; }
.vip-list li { padding:12px 0; border-bottom:1px solid var(--border); display:flex; align-items:center; gap:12px; }
.vip-list li:last-child { border-bottom:none; }
.vip-list i { color: var(--success); font-size:1.2em; }
.qris-box {
    background: #fff; padding:15px; border-radius:15px; margin-bottom:20px;
    text-align:center;
}
.qris-img { max-width:280px; margin:0 auto; }
.payment-info { background: rgba(0,0,0,.2); padding:15px; border-radius:12px; margin-bottom:20px; }
.pi-row { display:flex; justify-content:space-between; padding:8px 0; }
.pi-row span { color: var(--text-muted); }
.pi-row strong { color: var(--gold); }
.vip-form label { display:block; margin-bottom:8px; font-weight:600; font-size:.9em; }
.vip-form input {
    width:100%; padding:13px 16px; border:1px solid var(--border); border-radius:12px;
    background: rgba(0,0,0,.2); color:var(--text); margin-bottom:15px; font-family:inherit;
}
.vip-note {
    background: rgba(41,182,246,.1); border-left:4px solid var(--info);
    padding:12px 15px; border-radius:10px; font-size:.88em; margin-top:20px;
    color: var(--text-muted);
}
.vip-note i { color: var(--info); }

/* PROFILE */
.profile-head { display:flex; gap:20px; align-items:center; margin-bottom:25px; }
.profile-avatar {
    width:80px; height:80px; border-radius:24px;
    background: linear-gradient(135deg, var(--primary), var(--primary-2));
    display:flex; align-items:center; justify-content:center;
    font-size:2em; font-weight:800; color:#fff;
    box-shadow: 0 8px 30px rgba(124,92,255,.5); flex-shrink:0;
}
.profile-head h2 { font-family:'Space Grotesk',sans-serif; font-size:1.4em; margin-bottom:3px; }
.profile-head p { color: var(--text-muted); font-size:.9em; margin-bottom:8px; }
.profile-info { display:flex; flex-direction:column; gap:12px; }
.pi-row { display:flex; justify-content:space-between; padding:10px 0; border-bottom:1px solid var(--border); font-size:.9em; }
.pi-row:last-child { border-bottom:none; }
.pi-row span { color: var(--text-muted); }

/* CHAT */
.chat-box {
    background: var(--bg-card); backdrop-filter:blur(20px);
    border:1px solid var(--border); border-radius:22px; overflow:hidden;
    display:flex; flex-direction:column; height:65vh;
}
.chat-messages { flex:1; overflow-y:auto; padding:20px; }
.chat-msg {
    background: rgba(0,0,0,.2); padding:12px 15px; border-radius:14px;
    margin-bottom:12px; max-width:80%;
}
.chat-msg.chat-admin {
    background: linear-gradient(135deg, rgba(255,183,0,.15), rgba(255,140,0,.08));
    border:1px solid rgba(255,183,0,.3); margin-left:auto;
}
.cm-head { display:flex; justify-content:space-between; margin-bottom:5px; font-size:.85em; }
.cm-head strong { color: var(--primary-2); }
.cm-head small { color: var(--text-muted); }
.cm-body { font-size:.92em; word-wrap:break-word; }
.chat-input { display:flex; gap:10px; padding:15px; border-top:1px solid var(--border); }
.chat-input input {
    flex:1; padding:12px 16px; border:1px solid var(--border); border-radius:12px;
    background: rgba(0,0,0,.2); color:var(--text); font-family:inherit;
}
.chat-input input:focus { outline:none; border-color:var(--primary); }

/* ADMIN */
.admin-grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(220px,1fr)); gap:18px; margin-bottom:25px; }
.admin-card {
    background: var(--bg-card); backdrop-filter:blur(20px);
    padding:25px; border-radius:20px; border:1px solid var(--border);
    text-align:center; transition:.25s; color:var(--text);
}
.admin-card:hover { transform: translateY(-4px); border-color: var(--primary); box-shadow: var(--glow); }
.admin-card i { font-size:2.3em; color: var(--primary); margin-bottom:12px; display:block; }
.admin-card h3 { font-family:'Space Grotesk',sans-serif; margin-bottom:5px; }
.admin-card p { color: var(--text-muted); font-size:.85em; }
.admin-card-alert { border-color: var(--warning); background: linear-gradient(135deg, rgba(255,167,38,.15), rgba(255,167,38,.05)); }
.admin-card-alert i { color: var(--warning); }

/* GRID 2 */
.grid-2 { display:grid; grid-template-columns:1fr 1fr; gap:20px; }
@media (max-width:800px) { .grid-2 { grid-template-columns:1fr; } }

/* LOG ITEM */
.log-item {
    display:flex; gap:12px; padding:12px 0; border-bottom:1px solid var(--border);
    font-size:.9em; align-items:flex-start;
}
.log-item:last-child { border-bottom:none; }
.log-item i { color: var(--primary); margin-top:4px; flex-shrink:0; }
.log-item small { color: var(--text-muted); font-size:.8em; }

/* BOTTOM NAV */
.bottom-nav {
    position:fixed; bottom:0; left:0; right:0;
    display:flex; justify-content:space-around; align-items:center;
    background: var(--bg-nav); backdrop-filter:blur(20px);
    border-top:1px solid var(--border); padding:8px 0;
    z-index:99; box-shadow: 0 -4px 30px rgba(0,0,0,.3);
}
.bn-item {
    display:flex; flex-direction:column; align-items:center; gap:3px;
    padding:6px 12px; color:var(--text-muted); font-size:.7em; font-weight:600;
    border-radius:10px; transition:.2s; min-width:55px;
}
.bn-item i { font-size:1.3em; }
.bn-item:hover, .bn-item.active { color: var(--primary); }
@media (min-width:768px) { .bottom-nav { display:none; } body { padding-bottom:0; } }

/* FLOATING CHAT */
.floating-chat {
    position:fixed; bottom:80px; right:20px;
    width:60px; height:60px; border-radius:50%;
    background: linear-gradient(135deg, var(--primary), var(--primary-2));
    display:flex; align-items:center; justify-content:center;
    color:#fff; font-size:1.5em; box-shadow: 0 8px 30px rgba(124,92,255,.6);
    z-index:98; transition:.25s;
}
.floating-chat:hover { transform: scale(1.1); }
.chat-badge {
    position:absolute; top:5px; right:5px; width:12px; height:12px;
    background: var(--success); border-radius:50%; border:2px solid var(--bg);
}
@media (min-width:768px) { .floating-chat { bottom:20px; } }

/* TOAST */
.toast {
    position:fixed; top:20px; right:20px; background: var(--bg-card);
    backdrop-filter:blur(20px); padding:14px 20px; border-radius:12px;
    border:1px solid var(--border); z-index:9999;
    box-shadow: var(--shadow); animation: slideIn .3s;
    display:flex; align-items:center; gap:10px; font-weight:600;
}
.toast-success { border-color: var(--success); color: var(--success); }
.toast-error { border-color: var(--danger); color: var(--danger); }
.toast-info { border-color: var(--info); color: var(--info); }
@keyframes slideIn { from { transform:translateX(400px); opacity:0; } to { transform:translateX(0); opacity:1; } }

/* FOOTER */
.footer {
    margin-top:60px; padding:40px 20px; border-top:1px solid var(--border);
    background: rgba(0,0,0,.2); text-align:center;
}
.footer-content { max-width:1200px; margin:0 auto; }
.footer-brand {
    display:flex; align-items:center; justify-content:center; gap:10px;
    font-family:'Space Grotesk',sans-serif; font-weight:700; font-size:1.1em;
    margin-bottom:15px;
}
.footer p { color: var(--text-muted); font-size:.9em; margin-bottom:15px; }
.footer-links { display:flex; gap:20px; justify-content:center; flex-wrap:wrap; }
.footer-links a { color:var(--text-muted); font-size:.9em; }
.footer-links a:hover { color: var(--primary); }

/* RESPONSIVE */
@media (max-width:768px) {
    .hero h1 { font-size:2.5em; }
    .navbar { padding:12px 16px; }
    .nav-menu { gap:4px; }
    .nav-menu a { padding:6px 10px; font-size:.85em; }
    .logo-text { display:none; }
    .container { padding:20px 15px; }
    .section { padding:50px 15px; }
    .auth-card { padding:30px 25px; }
    .welcome-card { padding:20px; }
    .welcome-card h1 { font-size:1.3em; }
    .stat-card { padding:16px; }
    .stat-info h3 { font-size:1.2em; }
    .table { font-size:.82em; }
    .table th, .table td { padding:8px 6px; }
    .card { padding:20px; }
    .vip-hero h1 { font-size:1.8em; }
    .vip-crown-big { font-size:3.5em; }
    .toast { left:15px; right:15px; }
}
CSSEOF

cat > "$WEB_ROOT/assets/js/main.js" << 'JSEOF'
// Theme toggle
const tt = document.getElementById('themeToggle');
const saved = localStorage.getItem('theme') || 'dark';
document.documentElement.setAttribute('data-theme', saved);
if (tt) {
    const icon = tt.querySelector('i');
    if (icon) icon.className = saved === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
    tt.addEventListener('click', () => {
        const c = document.documentElement.getAttribute('data-theme');
        const n = c === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', n);
        localStorage.setItem('theme', n);
        if (icon) icon.className = n === 'dark' ? 'fas fa-sun' : 'fas fa-moon';
    });
}

// Mark active bottom nav
const path = location.pathname;
document.querySelectorAll('.bn-item').forEach(el => {
    if (el.getAttribute('href') === path || (path.startsWith(el.getAttribute('href')) && el.getAttribute('href') !== '/')) {
        el.classList.add('active');
    }
});
JSEOF

echo -e "${GREEN}  ✓ CSS & JS mewah OK${NC}"

# ============ STEP 11: NGINX ============
echo -e "${CYAN}[11/11] Konfigurasi Nginx...${NC}"

cat > "$NGINX_CONF" << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name $SUBDOMAIN;
    root $WEB_ROOT;
    index index.php index.html;
    client_max_body_size 10M;

    location / { try_files \$uri \$uri/ =404; }
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }
    location ~ /\.(?!well-known).* { deny all; }
    location ~* \.(env|log|sql|md)\$ { deny all; }
    location = /includes/config.php { deny all; }

    access_log /var/log/nginx/$SUBDOMAIN.access.log;
    error_log /var/log/nginx/$SUBDOMAIN.error.log;
}
NGINXEOF

ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/ 2>/dev/null
[[ -f /etc/nginx/sites-enabled/default ]] && rm -f /etc/nginx/sites-enabled/default

if nginx -t >/dev/null 2>&1; then
    systemctl reload nginx
    echo -e "${GREEN}  ✓ Nginx OK${NC}"
else
    echo -e "${RED}  ✗ Nginx error!${NC}"; nginx -t; exit 1
fi

chown -R www-data:www-data "$WEB_ROOT"
chmod -R 755 "$WEB_ROOT"
chmod 640 "$WEB_ROOT/includes/config.php"
chmod -R 775 "$WEB_ROOT/uploads"
systemctl restart php8.3-fpm
echo -e "${GREEN}  ✓ Permission OK${NC}"

# SSL
echo -e "${CYAN}Setup SSL...${NC}"
SERVER_IP=$(curl -4 -s --max-time 5 ifconfig.me 2>/dev/null)
DOMAIN_IP=$(dig +short A "$SUBDOMAIN" @8.8.8.8 2>/dev/null | head -1)
[[ -z "$DOMAIN_IP" ]] && DOMAIN_IP=$(getent ahostsv4 "$SUBDOMAIN" 2>/dev/null | awk '{print $1}' | head -1)

SSL_STATUS="dilewati"
if [[ "$SERVER_IP" == "$DOMAIN_IP" ]] || [[ -f "/etc/letsencrypt/live/$SUBDOMAIN/fullchain.pem" ]]; then
    apt install certbot python3-certbot-nginx -y -qq 2>/dev/null
    if certbot --nginx -d "$SUBDOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect >/dev/null 2>&1; then
        SSL_STATUS="aktif ✅"
    fi
fi

command -v ufw >/dev/null 2>&1 && { ufw allow 80/tcp >/dev/null 2>&1; ufw allow 443/tcp >/dev/null 2>&1; }

PROTO="https"; [[ "$SSL_STATUS" == "dilewati" ]] && PROTO="http"

clear
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ INSTALLASI BERHASIL!                    ║${NC}"
echo -e "${GREEN}║  🎬 Rendzz Alight Motion Free Premium       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}🔗 URL:${NC}"
echo -e "  🏠 Home       : $PROTO://$SUBDOMAIN"
echo -e "  🔐 Login      : $PROTO://$SUBDOMAIN/login.php"
echo -e "  📝 Register   : $PROTO://$SUBDOMAIN/register.php"
echo -e "  🛠️  Tools      : $PROTO://$SUBDOMAIN/tools.php"
echo -e "  👑 VIP        : $PROTO://$SUBDOMAIN/vip.php"
echo -e "  💬 Live Chat  : $PROTO://$SUBDOMAIN/live-chat.php"
echo -e "  👤 Profile    : $PROTO://$SUBDOMAIN/profile.php"
echo -e "  🛡️  Admin      : $PROTO://$SUBDOMAIN/admin/"
echo ""
echo -e "${MAGENTA}🔑 Admin Login:${NC}"
echo -e "  👤 User : $ADMIN_USER"
echo -e "  🔑 Pass : $ADMIN_PASS"
echo ""
echo -e "${CYAN}💳 QRIS:${NC} $QRIS_URL"
echo -e "${CYAN}💰 Min Payment:${NC} Rp 2.000 (+ kode unik 2008-2999)"
echo ""
echo -e "${YELLOW}📌 Next Steps:${NC}"
echo -e "  1. Login sebagai admin"
echo -e "  2. Test generate premium di /tools.php"
echo -e "  3. Approve payment user di /admin/payments.php"
echo -e "  4. Share link ke user!"
echo ""
echo -e "${GREEN}🎉 Done bro! Website mewah siap pakai! 🤩${NC}"
