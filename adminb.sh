#!/usr/bin/env bash
#
# ██████╗  █████╗  ██████╗ ██████╗ ██████╗
# ██╔══██╗██╔══██╗██╔════╝██╔═══██╗██╔══██╗
# ██║  ██║███████║██║     ██║   ██║██████╔╝
# ██║  ██║██╔══██║██║     ██║   ██║██╔══██╗
# ██████╔╝██║  ██║╚██████╗╚██████╔╝██║  ██║
# ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝
#
# gacor.sh - All-in-One Web Recon Tool
# Untuk testing legal (bug bounty / pentest resmi)
#

set -o pipefail

# ============ WARNA ============
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
GRAY='\033[0;90m'; WHITE='\033[1;37m'; BOLD='\033[1m'; NC='\033[0m'

# ============ KONFIG ============
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
TIMEOUT=8
MAX_CRAWL=10
MAX_SQLI=8
MAX_XSS=8
MAX_PORTS=20
THREADS=10

# ============ KEYWORD ============
KW_LOGIN="login|signin|sign-in|log-in|masuk|auth|session|sso|oauth"
KW_ADMIN="admin|administrator|dashboard|panel|cpanel|manage|backend|wp-admin|phpmyadmin"
KW_REGISTER="register|signup|sign-up|daftar|create-account"
KW_CONFIG="config|configuration|\.env|settings|setup|install|\.git|backup|database|\.sql|\.bak"
KW_API="api|graphql|rest|swagger|docs|openapi|/v1|/v2|/v3"
KW_SENSITIVE="upload|download|private|secret|token|key|password|passwd|\.zip|\.tar|\.gz"
KW_USER="profile|account|user|users|member|customer"

# ============ SENSITIVE PATHS ============
SENSITIVE_PATHS=(
  ".env" ".env.local" ".env.production" ".env.backup"
  ".git/config" ".git/HEAD" ".gitignore"
  "wp-config.php.bak" "wp-config.php~" "config.php.bak" "config.old"
  "backup.sql" "database.sql" "db.sql" "dump.sql" "backup.zip"
  "adminer.php" "phpinfo.php" "info.php" "test.php" "debug.php"
  "debug.log" "error.log" "access.log" "composer.json" "package.json"
  ".htaccess" "web.config" "robots.txt" "sitemap.xml" ".DS_Store"
  "server-status" "swagger.json" "openapi.json" "graphql" "api-docs"
  "actuator" "actuator/env" "actuator/health" ".well-known/security.txt"
)

# ============ COMMON PORTS ============
COMMON_PORTS=(21 22 23 25 53 80 110 143 443 445 3306 3389 5432 5900 6379 8080 8443 9000 9200 27017)

# ============ COMMON SUBDOMAINS ============
SUBDOMAINS=(
  "www" "mail" "ftp" "admin" "api" "dev" "test" "staging" "beta" "demo"
  "app" "portal" "dashboard" "panel" "cpanel" "webmail" "smtp" "ns1" "ns2"
  "blog" "shop" "store" "cdn" "static" "assets" "img" "docs" "help" "support"
  "vpn" "remote" "git" "gitlab" "jenkins" "jira" "confluence" "wiki" "monitor"
  "status" "internal" "intranet" "backup" "old" "new" "m" "mobile" "secure"
)

# ============ CEK DEPENDENSI ============
check_deps() {
  local missing=()
  for cmd in curl grep sed awk sort cut tr; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  # opsional
  HAVE_DIG=0; command -v dig >/dev/null 2>&1 && HAVE_DIG=1
  HAVE_NC=0;  command -v nc >/dev/null 2>&1  && HAVE_NC=1
  HAVE_HOST=0; command -v host >/dev/null 2>&1 && HAVE_HOST=1
  HAVE_WHOIS=0; command -v whois >/dev/null 2>&1 && HAVE_WHOIS=1

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}✗ Tool wajib tidak ada: ${missing[*]}${NC}"
    exit 1
  fi
}

# ============ BANNER ============
banner() {
  clear
  echo -e "${MAGENTA}${BOLD}"
  cat << "EOF"
   ██████╗  █████╗  ██████╗ ██████╗ ██████╗
  ██╔════╝ ██╔══██╗██╔════╝██╔═══██╗██╔══██╗
  ██║  ███╗███████║██║     ██║   ██║██████╔╝
  ██║   ██║██╔══██║██║     ██║   ██║██╔══██╗
  ╚██████╔╝██║  ██║╚██████╗╚██████╔╝██║  ██║
   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝
EOF
  echo -e "${CYAN}       All-in-One Web Recon Tool v2.0${NC}"
  echo -e "${GRAY}       For LEGAL testing only!${NC}"
  echo
}

# ============ INPUT ============
get_target() {
  echo -ne "${BLUE}→ Masukkan URL target: ${NC}"
  read -r TARGET

  [ -z "$TARGET" ] && { echo -e "${RED}✗ Kosong!${NC}"; exit 1; }
  [[ "$TARGET" =~ ^https?:// ]] || TARGET="https://$TARGET"
  TARGET="${TARGET%/}"

  if ! [[ "$TARGET" =~ ^https?://[a-zA-Z0-9.-]+ ]]; then
    echo -e "${RED}✗ URL tidak valid.${NC}"; exit 1
  fi

  HOST=$(echo "$TARGET" | sed -E 's|https?://([^/]+).*|\1|')
  DOMAIN=$(echo "$HOST" | sed -E 's|^www\.||')
  SCHEME=$(echo "$TARGET" | sed -E 's|(https?)://.*|\1|')

  echo
  echo -e "${GRAY}╔═════════════════════════════════════════════╗${NC}"
  echo -e "${GRAY}║${NC} Target : ${WHITE}$TARGET${NC}"
  echo -e "${GRAY}║${NC} Host   : ${WHITE}$HOST${NC}"
  echo -e "${GRAY}║${NC} Domain : ${WHITE}$DOMAIN${NC}"
  echo -e "${GRAY}╚═════════════════════════════════════════════╝${NC}"
  echo
}

# ============ FETCH ============
fetch_html() {
  curl -sL --max-time "$TIMEOUT" -A "$UA" "$1" 2>/dev/null
}
fetch_headers() {
  curl -sIL --max-time "$TIMEOUT" -A "$UA" "$1" 2>/dev/null
}
check_status() {
  curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 -A "$UA" "$1" 2>/dev/null
}

# ============ SECTION SEPARATOR ============
section() {
  echo
  echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
  printf "${MAGENTA}${BOLD}║${NC}  %-52s ${MAGENTA}${BOLD}║${NC}\n" "$1"
  echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
  echo
}

# ============ 1. DNS / WHOIS ============
run_dns() {
  section "🌐 DNS / WHOIS INFO"

  if [ "$HAVE_DIG" -eq 1 ]; then
    echo -e "${BLUE}A Records:${NC}"
    dig +short A "$DOMAIN" 2>/dev/null | head -5 | while read -r ip; do
      echo -e "  ${GREEN}•${NC} $ip"
    done

    echo -e "${BLUE}MX Records:${NC}"
    dig +short MX "$DOMAIN" 2>/dev/null | head -5 | while read -r mx; do
      echo -e "  ${GREEN}•${NC} $mx"
    done

    echo -e "${BLUE}NS Records:${NC}"
    dig +short NS "$DOMAIN" 2>/dev/null | head -5 | while read -r ns; do
      echo -e "  ${GREEN}•${NC} $ns"
    done

    echo -e "${BLUE}TXT Records:${NC}"
    dig +short TXT "$DOMAIN" 2>/dev/null | head -5 | while read -r txt; do
      echo -e "  ${GREEN}•${NC} $txt"
    done
  else
    echo -e "${GRAY}  dig tidak tersedia${NC}"
  fi

  echo
}

# ============ 2. PORT SCAN ============
run_portscan() {
  section "🔌 PORT SCAN (common ports)"

  if [ "$HAVE_NC" -eq 0 ]; then
    echo -e "${YELLOW}  nc tidak tersedia, skip.${NC}"
    echo -e "${GRAY}  Install: apt install netcat${NC}"
    return
  fi

  local ip
  ip=$(dig +short A "$DOMAIN" 2>/dev/null | head -1)
  [ -z "$ip" ] && ip="$HOST"

  echo -e "${GRAY}  Target IP: $ip${NC}"
  echo

  local found=0
  for port in "${COMMON_PORTS[@]}"; do
    if nc -z -w2 "$ip" "$port" 2>/dev/null; then
      local svc=""
      case "$port" in
        21) svc="FTP" ;; 22) svc="SSH" ;; 23) svc="Telnet" ;;
        25) svc="SMTP" ;; 53) svc="DNS" ;; 80) svc="HTTP" ;;
        110) svc="POP3" ;; 143) svc="IMAP" ;; 443) svc="HTTPS" ;;
        445) svc="SMB" ;; 3306) svc="MySQL" ;; 3389) svc="RDP" ;;
        5432) svc="PostgreSQL" ;; 5900) svc="VNC" ;; 6379) svc="Redis" ;;
        8080) svc="HTTP-Alt" ;; 8443) svc="HTTPS-Alt" ;;
        9000) svc="PHP-FPM" ;; 9200) svc="Elasticsearch" ;;
        27017) svc="MongoDB" ;;
      esac
      echo -e "  ${GREEN}[OPEN]${NC} $port/tcp  ${WHITE}$svc${NC}"
      found=$((found+1))
    fi
  done

  [ "$found" -eq 0 ] && echo -e "${GRAY}  Tidak ada port common yang terbuka.${NC}"
  echo
}

# ============ 3. SUBDOMAIN ENUM ============
run_subdomains() {
  section "🔎 SUBDOMAIN ENUM (common names)"

  if [ "$HAVE_HOST" -eq 0 ] && [ "$HAVE_DIG" -eq 0 ]; then
    echo -e "${YELLOW}  dig/host tidak tersedia, skip.${NC}"
    return
  fi

  local found=0
  for sub in "${SUBDOMAINS[@]}"; do
    local full="$sub.$DOMAIN"
    local ip
    if [ "$HAVE_DIG" -eq 1 ]; then
      ip=$(dig +short A "$full" 2>/dev/null | head -1)
    else
      ip=$(host "$full" 2>/dev/null | grep -oE '[0-9.]+' | head -1)
    fi

    if [ -n "$ip" ]; then
      echo -e "  ${GREEN}[+]${NC} $full ${GRAY}→ $ip${NC}"
      found=$((found+1))
    fi
  done

  [ "$found" -eq 0 ] && echo -e "${GRAY}  Tidak ada subdomain umum yang ditemukan.${NC}"
  echo
}

# ============ 4. WAF DETECT ============
run_waf() {
  section "🛡️ WAF / CDN DETECT"

  local headers
  headers=$(fetch_headers "$TARGET")

  local waf=""
  echo "$headers" | grep -qi "cf-ray\|cloudflare" && waf="$waf Cloudflare"
  echo "$headers" | grep -qi "x-sucuri" && waf="$waf Sucuri"
  echo "$headers" | grep -qi "x-akamai" && waf="$waf Akamai"
  echo "$headers" | grep -qi "x-amz-cf\|cloudfront" && waf="$waf CloudFront"
  echo "$headers" | grep -qi "x-fw\|firewall" && waf="$waf Generic-FW"
  echo "$headers" | grep -qi "incap_ses\|visid_incap" && waf="$waf Incapsula"
  echo "$headers" | grep -qi "x-iinfo" && waf="$waf Imperva"
  echo "$headers" | grep -qi "server:.*cloudflare" && waf="$waf Cloudflare"

  waf=$(echo "$waf" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

  if [ -n "$waf" ]; then
    echo -e "  ${GREEN}WAF/CDN:${NC} ${WHITE}$waf${NC}"
  else
    echo -e "  ${GRAY}Tidak terdeteksi WAF${NC}"
  fi
  echo
}

# ============ 5. SECURITY HEADERS ============
run_sec_headers() {
  section "🔒 SECURITY HEADERS"

  local headers
  headers=$(fetch_headers "$TARGET")

  local checks=(
    "Strict-Transport-Security:HSTS"
    "Content-Security-Policy:CSP"
    "X-Frame-Options:X-Frame-Options"
    "X-Content-Type-Options:X-Content-Type-Options"
    "Referrer-Policy:Referrer-Policy"
    "Permissions-Policy:Permissions-Policy"
    "X-XSS-Protection:X-XSS-Protection"
  )

  for check in "${checks[@]}"; do
    local header="${check%%:*}"
    local label="${check##*:}"
    if echo "$headers" | grep -qi "^$header:"; then
      echo -e "  ${GREEN}[✓]${NC} $label"
    else
      echo -e "  ${RED}[✗]${NC} $label ${GRAY}(missing)${NC}"
    fi
  done
  echo
}

# ============ 6. CMS DETECT ============
run_cms() {
  section "🎯 CMS / TECH DETECT"

  local headers html
  headers=$(fetch_headers "$TARGET")
  html=$(fetch_html "$TARGET")

  local found=""
  echo "$headers" | grep -qi "x-powered-by:.*php" && found="$found PHP"
  echo "$headers" | grep -qi "x-powered-by:.*asp" && found="$found ASP.NET"
  echo "$headers" | grep -qi "x-powered-by:.*express" && found="$found Express"
  echo "$headers" | grep -qi "server:.*nginx" && found="$found Nginx"
  echo "$headers" | grep -qi "server:.*apache" && found="$found Apache"
  echo "$headers" | grep -qi "server:.*iis" && found="$found IIS"
  echo "$headers" | grep -qi "x-drupal" && found="$found Drupal"
  echo "$headers" | grep -qi "x-generator:.*wordpress" && found="$found WordPress"
  echo "$html" | grep -qi "wp-content\|wp-includes" && found="$found WordPress"
  echo "$html" | grep -qi "joomla" && found="$found Joomla"
  echo "$html" | grep -qi "drupal" && found="$found Drupal"
  echo "$html" | grep -qi "csrf-token.*content" && found="$found Laravel"
  echo "$html" | grep -qi "__next_data__\|_next/static" && found="$found Next.js"
  echo "$html" | grep -qi "data-reactroot" && found="$found React"
  echo "$html" | grep -qi "ng-app\|angular" && found="$found Angular"
  echo "$html" | grep -qi "vue.js\|vue.min" && found="$found Vue"
  echo "$html" | grep -qi "jquery" && found="$found jQuery"
  echo "$html" | grep -qi "bootstrap" && found="$found Bootstrap"
  echo "$html" | grep -qi "tailwind" && found="$found Tailwind"

  found=$(echo "$found" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

  echo -e "  ${BLUE}Server Header:${NC}"
  echo "$headers" | grep -iE "^(server|x-powered-by|x-generator|x-aspnet)" | while read -r line; do
    echo -e "    ${GRAY}$line${NC}"
  done
  echo

  if [ -n "$found" ]; then
    echo -e "  ${GREEN}Terdeteksi:${NC} ${WHITE}$found${NC}"
  else
    echo -e "  ${GRAY}Tech: tidak terdeteksi${NC}"
  fi
  echo
}

# ============ 7. CRAWL ============
run_crawl() {
  section "🕷️ CRAWLING SITUS"

  ALL_LINKS=""
  PAGES_VISITED=0
  QUEUE="$TARGET"

  while [ -n "$QUEUE" ] && [ "$PAGES_VISITED" -lt "$MAX_CRAWL" ]; do
    local current
    current=$(echo "$QUEUE" | head -n1)
    QUEUE=$(echo "$QUEUE" | tail -n +2)
    [ -z "$current" ] && continue

    PAGES_VISITED=$((PAGES_VISITED + 1))
    echo -e "${GRAY}  [$PAGES_VISITED/$MAX_CRAWL] $current${NC}"

    local html
    html=$(fetch_html "$current")
    [ -z "$html" ] && continue

    local new_links
    new_links=$(echo "$html" \
      | grep -oEi '(href|src|action)=["'"'"'][^"'"'"' >]+' \
      | sed -E 's/^[a-zA-Z]+=["'"'"']//' \
      | sort -u \
      | while read -r link; do
          [ -z "$link" ] && continue
          case "$link" in
            \#*|javascript:*|mailto:*|tel:*|data:*) continue ;;
          esac
          if [[ "$link" =~ ^https?:// ]]; then
            [[ "$link" == *"$HOST"* ]] && echo "$link"
          elif [[ "$link" =~ ^// ]]; then
            echo "${SCHEME}:$link"
          elif [[ "$link" =~ ^/ ]]; then
            echo "$TARGET$link"
          else
            echo "$TARGET/$link"
          fi
        done | sort -u)

    ALL_LINKS=$(printf "%s\n%s" "$ALL_LINKS" "$new_links")

    local pending
    pending=$(echo "$new_links" | grep -Ei "$KW_LOGIN|$KW_ADMIN|$KW_REGISTER")
    QUEUE=$(printf "%s\n%s" "$QUEUE" "$pending" | sort -u)
  done

  ALL_LINKS=$(echo "$ALL_LINKS" | grep -v '^$' | sort -u)
  echo
  echo -e "  ${GREEN}Total link ditemukan: $(echo "$ALL_LINKS" | grep -c .)${NC}"
  echo
}

# ============ 8. SENSITIVE FILES ============
run_sensitive() {
  section "📁 SENSITIVE FILE SCAN"

  local found=0
  for path in "${SENSITIVE_PATHS[@]}"; do
    local url="$TARGET/$path"
    local code
    code=$(check_status "$url")

    case "$code" in
      200)
        echo -e "  ${GREEN}[200]${NC} $url"
        found=$((found+1))
        ;;
      301|302|307|308)
        echo -e "  ${CYAN}[$code]${NC} $url"
        found=$((found+1))
        ;;
      401|403)
        echo -e "  ${YELLOW}[$code]${NC} $url ${GRAY}(exists, forbidden)${NC}"
        found=$((found+1))
        ;;
    esac
  done

  [ "$found" -eq 0 ] && echo -e "${GRAY}  Tidak ada file sensitif terdeteksi.${NC}"
  echo
}

# ============ 9. FILTER LINK PENTING ============
run_filter() {
  section "🔍 LINK PENTING"

  LOGIN=$(echo "$ALL_LINKS" | grep -Ei "$KW_LOGIN" | sort -u)
  ADMIN=$(echo "$ALL_LINKS" | grep -Ei "$KW_ADMIN" | sort -u)
  REGISTER=$(echo "$ALL_LINKS" | grep -Ei "$KW_REGISTER" | sort -u)
  CONFIG=$(echo "$ALL_LINKS" | grep -Ei "$KW_CONFIG" | sort -u)
  API=$(echo "$ALL_LINKS" | grep -Ei "$KW_API" | sort -u)
  SENSITIVE=$(echo "$ALL_LINKS" | grep -Ei "$KW_SENSITIVE" | sort -u)
  USER=$(echo "$ALL_LINKS" | grep -Ei "$KW_USER" | sort -u)

  print_cat() {
    local title="$1" icon="$2" color="$3" items="$4"
    [ -z "$items" ] && return
    local count
    count=$(echo "$items" | grep -c .)
    echo -e "${color}${BOLD}┌──────────────────────────────────────────────────────┐${NC}"
    printf "${color}${BOLD}│${NC}  %s  %-45s ${color}${BOLD}[%d]${NC}\n" "$icon" "$title" "$count"
    echo -e "${color}${BOLD}├──────────────────────────────────────────────────────┤${NC}"
    local i=1
    echo "$items" | while read -r u; do
      [ -z "$u" ] && continue
      printf "${color}│${NC}  ${WHITE}[%d]${NC} %s\n" "$i" "$u"
      i=$((i+1))
    done
    echo -e "${color}${BOLD}└──────────────────────────────────────────────────────┘${NC}"
    echo
  }

  print_cat "LOGIN"      "🔐" "$MAGENTA" "$LOGIN"
  print_cat "ADMIN"      "🛠️ " "$RED"     "$ADMIN"
  print_cat "REGISTER"   "📝" "$CYAN"    "$REGISTER"
  print_cat "CONFIG"     "⚙️ " "$YELLOW"  "$CONFIG"
  print_cat "API"        "🔌" "$BLUE"    "$API"
  print_cat "SENSITIVE"  "⚠️ " "$RED"     "$SENSITIVE"
  print_cat "USER"       "👤" "$GREEN"   "$USER"
}

# ============ 10. PARAMETER EXTRACT ============
run_params() {
  section "🔗 PARAMETER URL"

  local params
  params=$(echo "$ALL_LINKS" | grep -oE '\?[^#]*' | grep -oE '[a-zA-Z_][a-zA-Z0-9_]*=' | sed 's/=$//' | sort -u)

  if [ -z "$params" ]; then
    echo -e "${GRAY}  Tidak ada parameter.${NC}"
  else
    echo -e "  ${WHITE}Parameter unik:${NC}"
    echo "$params" | while read -r p; do
      echo -e "    ${GREEN}•${NC} $p"
    done
  fi
  echo
}

# ============ 11. FORM EXTRACT ============
run_forms() {
  section "📋 FORM LOGIN / ADMIN"

  local shown=0
  for url in $(echo "$LOGIN" | head -3) $(echo "$ADMIN" | head -2); do
    [ -z "$url" ] && continue

    local html
    html=$(fetch_html "$url")
    [ -z "$html" ] && continue

    local action method
    action=$(echo "$html" | tr '\n' ' ' | grep -oEi '<form[^>]*action=["'"'"'][^"'"'"']*' | head -1 | sed -E 's/.*=["'"'"']//')
    method=$(echo "$html" | tr '\n' ' ' | grep -oEi '<form[^>]*method=["'"'"'][^"'"'"']*' | head -1 | sed -E 's/.*=["'"'"']//')
    [ -z "$method" ] && method="GET"
    [ -z "$action" ] && action="$url"

    echo -e "${MAGENTA}${BOLD}┌─ FORM ──────────────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│${NC} URL    : $url"
    echo -e "${MAGENTA}│${NC} Action : $action"
    echo -e "${MAGENTA}│${NC} Method : $method"
    echo -e "${MAGENTA}│${NC} ${GRAY}─────────────────────────────────────────${NC}"
    echo -e "${MAGENTA}│${NC} Fields :"

    echo "$html" | tr '\n' ' ' | grep -oEi '<input[^>]*>' | while read -r inputtag; do
      local name type placeholder
      name=$(echo "$inputtag" | grep -oEi 'name=["'"'"'][^"'"'"']*' | sed -E 's/.*=["'"'"']//')
      type=$(echo "$inputtag" | grep -oEi 'type=["'"'"'][^"'"'"']*' | sed -E 's/.*=["'"'"']//')
      placeholder=$(echo "$inputtag" | grep -oEi 'placeholder=["'"'"'][^"'"'"']*' | sed -E 's/.*=["'"'"']//')
      [ -z "$name" ] && continue
      [ -z "$type" ] && type="text"
      case "$type" in hidden|submit|button|image|reset) continue ;; esac
      printf "${MAGENTA}│${NC}   ${GREEN}•${NC} ${WHITE}%-20s${NC} ${GRAY}[%s]${NC}" "$name" "$type"
      [ -n "$placeholder" ] && printf " ${GRAY}(%s)${NC}" "$placeholder"
      echo
    done
    echo -e "${MAGENTA}${BOLD}└─────────────────────────────────────────────────────┘${NC}"
    echo
    shown=1
  done

  [ "$shown" -eq 0 ] && echo -e "${GRAY}  Tidak ada form login/admin.${NC}\n"
}

# ============ 12. SQLi TEST ============
run_sqli() {
  section "💉 SQL INJECTION TEST"
  echo -e "${YELLOW}  ⚠ Only for legal testing!${NC}"
  echo

  local candidates
  candidates=$(echo "$ALL_LINKS" | grep -E '\?.*=' | head -n "$MAX_SQLI")
  [ -z "$candidates" ] && { echo -e "${GRAY}  Tidak ada URL berparam.${NC}"; return; }

  local payloads=("'" "\"" "' OR '1'='1" "1' AND '1'='1" "1 AND 1=2" "1' UNION SELECT NULL--")
  local hits=0

  for url in $candidates; do
    echo -e "${GRAY}  Testing: $url${NC}"
    local base_html
    base_html=$(fetch_html "$url")
    local base_size
    base_size=$(echo "$base_html" | wc -c)

    for payload in "${payloads[@]}"; do
      local enc
      enc=$(printf '%s' "$payload" | sed "s/ /%20/g;s/'/%27/g;s/\"/%22/g")
      local testurl
      testurl=$(echo "$url" | sed -E "s/(=)[^&]*$/\1$enc/")

      local thtml
      thtml=$(fetch_html "$testurl")
      local tsize
      tsize=$(echo "$thtml" | wc -c)

      if echo "$thtml" | grep -qiE "SQL syntax|MySQL server|mysql_fetch|ORA-[0-9]|PostgreSQL.*ERROR|SQLite.*error|Unclosed quotation|you have an error in your sql"; then
        echo -e "    ${RED}[SQLi-ERR]${NC} Payload: $payload"
        echo -e "    ${GRAY}URL: $testurl${NC}"
        hits=$((hits+1))
      fi

      local diff=$((base_size - tsize)); [ "$diff" -lt 0 ] && diff=$((-diff))
      if [ "$base_size" -gt 100 ] && [ "$diff" -gt $((base_size / 2)) ]; then
        echo -e "    ${YELLOW}[SQLi-DIFF]${NC} ${diff} bytes diff, payload: $payload"
        echo -e "    ${GRAY}URL: $testurl${NC}"
        hits=$((hits+1))
      fi
    done
  done

  [ "$hits" -eq 0 ] && echo -e "  ${GRAY}Tidak ada indikasi SQLi.${NC}"
  echo
}

# ============ 13. XSS TEST ============
run_xss() {
  section "🎯 XSS TEST (reflected)"

  local candidates
  candidates=$(echo "$ALL_LINKS" | grep -E '\?.*=' | head -n "$MAX_XSS")
  [ -z "$candidates" ] && { echo -e "${GRAY}  Tidak ada URL berparam.${NC}"; return; }

  local payload='<script>alert(1)</script>'
  local hits=0

  for url in $candidates; do
    echo -e "${GRAY}  Testing: $url${NC}"
    local enc='%3Cscript%3Ealert(1)%3C%2Fscript%3E'
    local testurl
    testurl=$(echo "$url" | sed -E "s/(=)[^&]*$/\1$enc/")

    local thtml
    thtml=$(fetch_html "$testurl")

    if echo "$thtml" | grep -qF "$payload"; then
      echo -e "    ${RED}[XSS]${NC} Payload reflected unencoded!"
      echo -e "    ${GRAY}URL: $testurl${NC}"
      hits=$((hits+1))
    elif echo "$thtml" | grep -qi "script>alert(1)"; then
      echo -e "    ${YELLOW}[XSS?]${NC} Payload reflected (partially encoded)"
      echo -e "    ${GRAY}URL: $testurl${NC}"
      hits=$((hits+1))
    fi
  done

  [ "$hits" -eq 0 ] && echo -e "  ${GRAY}Tidak ada indikasi XSS.${NC}"
  echo
}

# ============ 14. LFI TEST ============
run_lfi() {
  section "📂 LFI TEST"

  local candidates
  candidates=$(echo "$ALL_LINKS" | grep -E '\?.*=|file=|path=|page=' | head -n 5)
  [ -z "$candidates" ] && { echo -e "${GRAY}  Tidak ada URL cocok.${NC}"; return; }

  local payloads=(
    "../../../../etc/passwd"
    "....//....//....//etc/passwd"
    "/etc/passwd"
  )
  local hits=0

  for url in $candidates; do
    echo -e "${GRAY}  Testing: $url${NC}"
    for payload in "${payloads[@]}"; do
      local enc
      enc=$(printf '%s' "$payload" | sed 's/\//%2F/g')
      local testurl
      testurl=$(echo "$url" | sed -E "s/(=)[^&]*$/\1$enc/")

      local thtml
      thtml=$(fetch_html "$testurl")

      if echo "$thtml" | grep -qE "root:x:0:0|root:.*:0:0:"; then
        echo -e "    ${RED}[LFI!]${NC} /etc/passwd readable!"
        echo -e "    ${GRAY}URL: $testurl${NC}"
        hits=$((hits+1))
      fi
    done
  done

  [ "$hits" -eq 0 ] && echo -e "  ${GRAY}Tidak ada indikasi LFI.${NC}"
  echo
}

# ============ 15. OPEN REDIRECT TEST ============
run_openredirect() {
  section "↗️  OPEN REDIRECT TEST"

  local candidates
  candidates=$(echo "$ALL_LINKS" | grep -Ei 'redirect|url=|next=|return=|goto=|dest=' | head -n 5)
  [ -z "$candidates" ] && { echo -e "${GRAY}  Tidak ada URL cocok.${NC}"; return; }

  local payload="https://evil.example.com"
  local hits=0

  for url in $candidates; do
    echo -e "${GRAY}  Testing: $url${NC}"
    local enc
    enc=$(printf '%s' "$payload" | sed 's/:/%3A/g;s/\//%2F/g')
    local testurl
    testurl=$(echo "$url" | sed -E "s/(=)[^&]*$/\1$enc/")

    local headers
    headers=$(curl -sIL --max-time 5 -A "$UA" "$testurl" 2>/dev/null)

    if echo "$headers" | grep -qiE "^location:.*evil\.example\.com"; then
      echo -e "    ${RED}[OPEN REDIRECT]${NC} Redirect ke external domain!"
      echo -e "    ${GRAY}URL: $testurl${NC}"
      hits=$((hits+1))
    fi
  done

  [ "$hits" -eq 0 ] && echo -e "  ${GRAY}Tidak ada indikasi open redirect.${NC}"
  echo
}

# ============ 16. CORS MISCONFIG ============
run_cors() {
  section "🌍 CORS MISCONFIG"

  local headers
  headers=$(curl -sIL --max-time 5 -A "$UA" -H "Origin: https://evil.example.com" "$TARGET" 2>/dev/null)

  local acao
  acao=$(echo "$headers" | grep -i "^access-control-allow-origin:" | head -1)
  local acac
  acac=$(echo "$headers" | grep -i "^access-control-allow-credentials:" | head -1)

  if [ -n "$acao" ]; then
    echo -e "  ${WHITE}ACAO:${NC} $acao"
    [ -n "$acac" ] && echo -e "  ${WHITE}ACAC:${NC} $acac"

    if echo "$acao" | grep -qE "evil\.example\.com|\*"; then
      if echo "$acao" | grep -q "\*" && [ -n "$acac" ]; then
        echo -e "  ${RED}[!] Wildcard + credentials → high risk${NC}"
      elif echo "$acao" | grep -q "evil.example.com"; then
        echo -e "  ${RED}[!] Reflects arbitrary origin → high risk${NC}"
      else
        echo -e "  ${YELLOW}[?] Wildcard ACAO${NC}"
      fi
    fi
  else
    echo -e "  ${GRAY}Tidak ada CORS header.${NC}"
  fi
  echo
}

# ============ 17. HTTP METHODS ============
run_methods() {
  section "🔧 ALLOWED HTTP METHODS"

  local allow
  allow=$(curl -sI -X OPTIONS --max-time 5 -A "$UA" "$TARGET" 2>/dev/null | grep -i "^allow:" | head -1)

  if [ -n "$allow" ]; then
    echo -e "  ${WHITE}$allow${NC}"
    if echo "$allow" | grep -qiE "PUT|DELETE|TRACE|CONNECT"; then
      echo -e "  ${YELLOW}[?] Method berbahaya aktif (PUT/DELETE/TRACE)${NC}"
    fi
  else
    echo -e "  ${GRAY}Server tidak mengirim header Allow.${NC}"
  fi
  echo
}

# ============ 18. GOOGLE DORK HINTS ============
run_dorks() {
  section "🔎 GOOGLE DORK HINTS"

  echo -e "${GRAY}  Copy-paste ke Google buat cari exposure:${NC}"
  echo
  echo -e "  ${WHITE}1.${NC} site:$DOMAIN ext:sql OR ext:bak OR ext:log"
  echo -e "  ${WHITE}2.${NC} site:$DOMAIN inurl:admin OR inurl:login"
  echo -e "  ${WHITE}3.${NC} site:$DOMAIN intitle:index.of"
  echo -e "  ${WHITE}4.${NC} site:$DOMAIN ext:env OR ext:config"
  echo -e "  ${WHITE}5.${NC} site:$DOMAIN inurl:api OR inurl:graphql"
  echo -e "  ${WHITE}6.${NC} site:$DOMAIN \"password\" OR \"api_key\""
  echo -e "  ${WHITE}7.${NC} site:pastebin.com \"$DOMAIN\""
  echo -e "  ${WHITE}8.${NC} site:github.com \"$DOMAIN\" \"password\""
  echo
}

# ============ 19. ROBOTS / SITEMAP ============
run_robots() {
  section "🤖 ROBOTS.TXT & SITEMAP"

  local robots
  robots=$(fetch_html "$TARGET/robots.txt")
  if echo "$robots" | grep -qi "user-agent\|disallow"; then
    echo -e "  ${GREEN}[✓]${NC} robots.txt ditemukan"
    echo -e "${GRAY}──────────────────────────────${NC}"
    echo "$robots" | head -20 | while read -r line; do
      echo -e "    $line"
    done
    echo -e "${GRAY}──────────────────────────────${NC}"
  else
    echo -e "  ${GRAY}robots.txt tidak ditemukan${NC}"
  fi
  echo

  local sitemap
  sitemap=$(fetch_html "$TARGET/sitemap.xml")
  if echo "$sitemap" | grep -qi "<urlset\|<sitemapindex"; then
    local count
    count=$(echo "$sitemap" | grep -c "<loc>")
    echo -e "  ${GREEN}[✓]${NC} sitemap.xml ditemukan ($count URL)"
  else
    echo -e "  ${GRAY}sitemap.xml tidak ditemukan${NC}"
  fi
  echo
}

# ============ 20. SECURITY.TXT ============
run_securitytxt() {
  section "📜 SECURITY.TXT"

  local sec
  sec=$(fetch_html "$TARGET/.well-known/security.txt")
  if echo "$sec" | grep -qi "contact:\|policy:"; then
    echo -e "  ${GREEN}[✓]${NC} security.txt ditemukan"
    echo "$sec" | head -10 | while read -r line; do
      echo -e "    ${GRAY}$line${NC}"
    done
  else
    echo -e "  ${GRAY}security.txt tidak ada${NC}"
  fi
  echo
}

# ============ FINAL SUMMARY ============
final_summary() {
  section "📊 FINAL SUMMARY"

  local t_login t_admin t_reg t_cfg t_api t_sens t_user t_total
  t_login=$(echo "$LOGIN" | grep -c . 2>/dev/null || echo 0)
  t_admin=$(echo "$ADMIN" | grep -c . 2>/dev/null || echo 0)
  t_reg=$(echo "$REGISTER" | grep -c . 2>/dev/null || echo 0)
  t_cfg=$(echo "$CONFIG" | grep -c . 2>/dev/null || echo 0)
  t_api=$(echo "$dAPI" |${ grep -c . 2>/dev/nullNC || echo 0)
  t_sens=$(}\echo "$SENSITIVEn" | grep -c ." 2>/dev/null || echo 0)
  t_user=$(echo "$USER" | grep -c . 2>/dev/null || echo 0)
  t_total=$((t_login + t_admin + t_reg + t_cfg + t_api + t_sens + t_user))

  printf "  ${WHITE}%-22s${NC} : ${MAGENTA}%d${NC}\n" "Login"     "$t_login"
  printf "  ${WHITE}%-22s${NC} : ${RED}%d${NC}\n"     "Admin"     "$t_admin"
  printf "  ${WHITE}%-22s${NC} : ${CYAN}%    "Register"  "$t_reg"
  printf "  ${WHITE}%-22s${NC} : ${YELLOW}%d${NC}\n"  "Config"    "$t_cfg"
  printf "  ${WHITE}%-22s${NC} : ${BLUE}%d${NC}\n"    "API"       "$t_api"
  printf "  ${WHITE}%-22s${NC} : ${RED}%d${NC}\n"     "Sensitive" "$t_sens"
  printf "  ${WHITE}%-22s${NC} : ${GREEN}%d${NC}\n"   "User"      "$t_user"
  echo -e "  ${GRAY}─────────────────────────${NC}"
  printf "  ${WHITE}${BOLD}%-22s${NC} : ${GREEN}${BOLD}%d${NC}\n" "TOTAL LINK" "$t_total"
  echo
}

# ============ MAIN ============
main() {
  check_deps
  banner
  get_target

  echo -ne "${YELLOW}→ Mode: [1] Quick  [2] Full  [3] Custom : ${NC}"
  read -r mode
  echo

  case "$mode" in
    1)
      echo -e "${GREEN}Mode QUICK (crawl + filter + sensitive)${NC}\n"
      run_cms
      run_crawl
      run_filter
      run_sensitive
      final_summary
      ;;
    2)
      echo -e "${GREEN}Mode FULL (semua fitur)${NC}\n"
      run_dns
      run_waf
      run_sec_headers
      run_methods
      run_cors
      run_robots
      run_securitytxt
      run_cms
      run_crawl
      run_sensitive
      run_filter
      run_params
      run_forms
      run_sqli
      run_xss
      run_lfi
      run_openredirect
      run_dorks
      final_summary
      ;;
    3)
      echo -e "${YELLOW}Custom mode belum diimplementasi.${NC}"
      echo -e "${GRAY}Pilih 1 atau 2.${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}Mode tidak valid.${NC}"
      exit 1
      ;;
  esac

  echo
  echo -e "${GREEN}${BOLD}✓ Selesai. Selamat hunting!${NC}"
  echo -e "${GRAY}  Ingat: legal testing only.${NC}"
  echo
}

main
