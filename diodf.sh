#!/usr/bin/env bash
#
#  ██████╗  █████╗  ██████╗ ██████╗ ██████╗
# ██╔════╝ ██╔══██╗██╔════╝██╔═══██╗██╔══██╗
# ██║  ███╗███████║██║     ██║   ██║██████╔╝
# ██║   ██║██╔══██║██║     ██║   ██║██╔══██╗
# ╚██████╔╝██║  ██║╚██████╗╚██████╔╝██║  ██║
#  ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝
#
# gacor.sh - All-in-One Web Recon Tool
# For LEGAL testing only (bug bounty / pentest resmi)
#

set -o pipefail

# ============ WARNA ============
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'
GRAY=$'\033[0;90m'
WHITE=$'\033[1;37m'
BOLD=$'\033[1m'
NC=$'\033[0m'

# ============ KONFIG ============
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
TIMEOUT=8
MAX_CRAWL=10
MAX_SQLI=8
MAX_XSS=8

# ============ KEYWORD ============
KW_LOGIN="login|signin|sign-in|log-in|masuk|auth|session|sso|oauth"
KW_ADMIN="admin|administrator|dashboard|panel|cpanel|manage|backend|wp-admin|phpmyadmin"
KW_REGISTER="register|signup|sign-up|daftar|create-account"
KW_CONFIG="config|configuration|\\.env|settings|setup|install|\\.git|backup|database|\\.sql|\\.bak"
KW_API="api|graphql|rest|swagger|docs|openapi|/v1|/v2|/v3"
KW_SENSITIVE="upload|download|private|secret|token|key|password|passwd|\\.zip|\\.tar|\\.gz"
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

# ============ SUBDOMAINS ============
SUBDOMAINS=(
  "www" "mail" "ftp" "admin" "api" "dev" "test" "staging" "beta" "demo"
  "app" "portal" "dashboard" "panel" "cpanel" "webmail" "smtp" "ns1" "ns2"
  "blog" "shop" "store" "cdn" "static" "assets" "img" "docs" "help" "support"
  "vpn" "remote" "git" "gitlab" "jenkins" "jira" "confluence" "wiki" "monitor"
  "status" "internal" "intranet" "backup" "old" "new" "m" "mobile" "secure"
)

# ============ PORT COMMON ============
COMMON_PORTS=(21 22 23 25 53 80 110 143 443 445 3306 3389 5432 5900 6379 8080 8443 9000 9200 27017)

# ============ GLOBAL VAR ============
TARGET=""
HOST=""
DOMAIN=""
SCHEME=""
ALL_LINKS=""
LOGIN=""
ADMIN=""
REGISTER=""
CONFIG=""
API=""
SENSITIVE=""
USER=""
HAVE_DIG=0
HAVE_NC=0
HAVE_HOST=0

# ============ CEK DEPENDENSI ============
check_deps() {
  local missing=()
  local cmd
  for cmd in curl grep sed awk sort cut tr head tail; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}Tool wajib tidak ada: ${missing[*]}${NC}"
    echo -e "${YELLOW}Install: apt install ${missing[*]}${NC}"
    exit 1
  fi

  command -v dig >/dev/null 2>&1 && HAVE_DIG=1
  command -v nc >/dev/null 2>&1 && HAVE_NC=1
  command -v host >/dev/null 2>&1 && HAVE_HOST=1
}

# ============ BANNER ============
banner() {
  clear
  echo -e "${MAGENTA}${BOLD}"
  cat << 'BANNER_EOF'
   ██████╗  █████╗  ██████╗ ██████╗ ██████╗
  ██╔════╝ ██╔══██╗██╔════╝██╔═══██╗██╔══██╗
  ██║  ███╗███████║██║     ██║   ██║██████╔╝
  ██║   ██║██╔══██║██║     ██║   ██║██╔══██╗
  ╚██████╔╝██║  ██║╚██████╗╚██████╔╝██║  ██║
   ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝
BANNER_EOF
  echo -e "${CYAN}       All-in-One Web Recon Tool v2.1${NC}"
  echo -e "${GRAY}       For LEGAL testing only${NC}"
  echo
}

# ============ INPUT ============
get_target() {
  echo -ne "${BLUE}Masukkan URL target: ${NC}"
  read -r TARGET

  if [ -z "$TARGET" ]; then
    echo -e "${RED}URL kosong!${NC}"
    exit 1
  fi

  case "$TARGET" in
    http://*|https://*) ;;
    *) TARGET="https://$TARGET" ;;
  esac

  # hapus trailing slash
  TARGET="${TARGET%/}"

  HOST=$(echo "$TARGET" | sed -E 's|https?://([^/]+).*|\1|')
  DOMAIN=$(echo "$HOST" | sed -E 's|^www\.||')
  SCHEME=$(echo "$TARGET" | sed -E 's|(https?)://.*|\1|')

  echo
  echo -e "${GRAY}┌─────────────────────────────────────────┐${NC}"
  echo -e "${GRAY}│${NC} Target : ${WHITE}$TARGET${NC}"
  echo -e "${GRAY}│${NC} Host   : ${WHITE}$HOST${NC}"
  echo -e "${GRAY}│${NC} Domain : ${WHITE}$DOMAIN${NC}"
  echo -e "${GRAY}└─────────────────────────────────────────┘${NC}"
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

# ============ SECTION ============
section() {
  echo
  echo -e "${MAGENTA}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
  printf "${MAGENTA}${BOLD}║${NC}  %-52s ${MAGENTA}${BOLD}║${NC}\n" "$1"
  echo -e "${MAGENTA}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
  echo
}

# ============ 1. DNS ============
run_dns() {
  section "DNS INFO"

  if [ "$HAVE_DIG" -eq 0 ]; then
    echo -e "  ${GRAY}dig tidak tersedia (apt install dnsutils)${NC}"
    return
  fi

  echo -e "${BLUE}  A Records:${NC}"
  dig +short A "$DOMAIN" 2>/dev/null | head -5 | while read -r ip; do
    [ -n "$ip" ] && echo -e "    ${GREEN}*${NC} $ip"
  done

  echo -e "${BLUE}  MX Records:${NC}"
  dig +short MX "$DOMAIN" 2>/dev/null | head -5 | while read -r mx; do
    [ -n "$mx" ] && echo -e "    ${GREEN}*${NC} $mx"
  done

  echo -e "${BLUE}  NS Records:${NC}"
  dig +short NS "$DOMAIN" 2>/dev/null | head -5 | while read -r ns; do
    [ -n "$ns" ] && echo -e "    ${GREEN}*${NC} $ns"
  done

  echo -e "${BLUE}  TXT Records:${NC}"
  dig +short TXT "$DOMAIN" 2>/dev/null | head -3 | while read -r txt; do
    [ -n "$txt" ] && echo -e "    ${GREEN}*${NC} $txt"
  done
  echo
}

# ============ 2. PORT SCAN ============
run_portscan() {
  section "PORT SCAN"

  if [ "$HAVE_NC" -eq 0 ]; then
    echo -e "  ${YELLOW}nc tidak tersedia (apt install netcat-openbsd)${NC}"
    return
  fi

  local ip
  ip=""
  if [ "$HAVE_DIG" -eq 1 ]; then
    ip=$(dig +short A "$DOMAIN" 2>/dev/null | head -1)
  fi
  [ -z "$ip" ] && ip="$HOST"

  echo -e "  ${GRAY}Target IP: $ip${NC}"
  echo

  local found=0
  local port svc
  for port in "${COMMON_PORTS[@]}"; do
    if nc -z -w2 "$ip" "$port" >/dev/null 2>&1; then
      svc=""
      case "$port" in
        21) svc="FTP" ;;
        22) svc="SSH" ;;
        23) svc="Telnet" ;;
        25) svc="SMTP" ;;
        53) svc="DNS" ;;
        80) svc="HTTP" ;;
        110) svc="POP3" ;;
        143) svc="IMAP" ;;
        443) svc="HTTPS" ;;
        445) svc="SMB" ;;
        3306) svc="MySQL" ;;
        3389) svc="RDP" ;;
        5432) svc="PostgreSQL" ;;
        5900) svc="VNC" ;;
        6379) svc="Redis" ;;
        8080) svc="HTTP-Alt" ;;
        8443) svc="HTTPS-Alt" ;;
        9000) svc="PHP-FPM" ;;
        9200) svc="Elasticsearch" ;;
        27017) svc="MongoDB" ;;
      esac
      echo -e "    ${GREEN}[OPEN]${NC} $port/tcp  ${WHITE}$svc${NC}"
      found=$((found + 1))
    fi
  done

  [ "$found" -eq 0 ] && echo -e "  ${GRAY}Tidak ada port terbuka.${NC}"
  echo
}

# ============ 3. SUBDOMAIN ============
run_subdomains() {
  section "SUBDOMAIN ENUM"

  if [ "$HAVE_DIG" -eq 0 ] && [ "$HAVE_HOST" -eq 0 ]; then
    echo -e "  ${YELLOW}dig/host tidak tersedia${NC}"
    return
  fi

  local found=0
  local sub full ip
  for sub in "${SUBDOMAINS[@]}"; do
    full="$sub.$DOMAIN"
    ip=""
    if [ "$HAVE_DIG" -eq 1 ]; then
      ip=$(dig +short A "$full" 2>/dev/null | head -1)
    else
      ip=$(host "$full" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    if [ -n "$ip" ]; then
      echo -e "    ${GREEN}[+]${NC} $full ${GRAY}-> $ip${NC}"
      found=$((found + 1))
    fi
  done

  [ "$found" -eq 0 ] && echo -e "  ${GRAY}Tidak ada subdomain umum.${NC}"
  echo
}

# ============ 4. WAF ============
run_waf() {
  section "WAF / CDN DETECT"

  local headers
  headers=$(fetch_headers "$TARGET")

  local waf=""
  echo "$headers" | grep -qi "cf-ray" && waf="$waf Cloudflare"
  echo "$headers" | grep -qi "cloudflare" && waf="$waf Cloudflare"
  echo "$headers" | grep -qi "x-sucuri" && waf="$waf Sucuri"
  echo "$headers" | grep -qi "x-akamai" && waf="$waf Akamai"
  echo "$headers" | grep -qi "x-amz-cf" && waf="$waf CloudFront"
  echo "$headers" | grep -qi "incap_ses" && waf="$waf Incapsula"
  echo "$headers" | grep -qi "x-iinfo" && waf="$waf Imperva"

  waf=$(echo "$waf" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

  if [ -n "$waf" ]; then
    echo -e "  ${GREEN}WAF/CDN:${NC} ${WHITE}$waf${NC}"
  else
    echo -e "  ${GRAY}Tidak terdeteksi WAF.${NC}"
  fi
  echo
}

# ============ 5. SECURITY HEADERS ============
run_sec_headers() {
  section "SECURITY HEADERS"

  local headers
  headers=$(fetch_headers "$TARGET")

  check_one() {
    local hdr="$1"
    local label="$2"
    if echo "$headers" | grep -qi "^$hdr:"; then
      echo -e "    ${GREEN}[OK]${NC}   $label"
    else
      echo -e "    ${RED}[MISS]${NC} $label"
    fi
  }

  check_one "Strict-Transport-Security" "HSTS"
  check_one "Content-Security-Policy"   "CSP"
  check_one "X-Frame-Options"           "X-Frame-Options"
  check_one "X-Content-Type-Options"    "X-Content-Type-Options"
  check_one "Referrer-Policy"           "Referrer-Policy"
  check_one "Permissions-Policy"        "Permissions-Policy"
  check_one "X-XSS-Protection"          "X-XSS-Protection"
  echo
}

# ============ 6. CMS DETECT ============
run_cms() {
  section "CMS / TECH DETECT"

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
  echo "$html" | grep -qi "wp-content" && found="$found WordPress"
  echo "$html" | grep -qi "wp-includes" && found="$found WordPress"
  echo "$html" | grep -qi "joomla" && found="$found Joomla"
  echo "$html" | grep -qi "drupal" && found="$found Drupal"
  echo "$html" | grep -qi "csrf-token" && found="$found Laravel"
  echo "$html" | grep -qi "__next_data__" && found="$found Next.js"
  echo "$html" | grep -qi "data-reactroot" && found="$found React"
  echo "$html" | grep -qi "ng-app" && found="$found Angular"
  echo "$html" | grep -qi "vue.js" && found="$found Vue"
  echo "$html" | grep -qi "jquery" && found="$found jQuery"
  echo "$html" | grep -qi "bootstrap" && found="$found Bootstrap"
  echo "$html" | grep -qi "tailwind" && found="$found Tailwind"

  found=$(echo "$found" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ')

  echo -e "  ${BLUE}Server Header:${NC}"
  echo "$headers" | grep -iE "^(server|x-powered-by|x-generator):" | while read -r line; do
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
  section "CRAWLING SITUS"

  ALL_LINKS=""
  local pages_visited=0
  local queue="$TARGET"

  while [ -n "$queue" ] && [ "$pages_visited" -lt "$MAX_CRAWL" ]; do
    local current
    current=$(echo "$queue" | head -n1)
    queue=$(echo "$queue" | tail -n +2)
    [ -z "$current" ] && continue

    pages_visited=$((pages_visited + 1))
    echo -e "    ${GRAY}[$pages_visited/$MAX_CRAWL] $current${NC}"

    local html
    html=$(fetch_html "$current")
    [ -z "$html" ] && continue

    # ekstrak link
    local raw_links
    raw_links=$(echo "$html" | grep -oEi '(href|src|action)=["'"'"'][^"'"'"' >]+' | sed -E 's/^[a-zA-Z]+=["'"'"']//' | sort -u)

    local new_links=""
    while IFS= read -r link; do
      [ -z "$link" ] && continue
      case "$link" in
        '#'*|javascript:*|mailto:*|tel:*|data:*) continue ;;
      esac

      case "$link" in
        http://*|https://*)
          case "$link" in
            *"$HOST"*) new_links="$new_links"$'\n'"$link" ;;
          esac
          ;;
        //*)
          new_links="$new_links"$'\n'"${SCHEME}:$link"
          ;;
        /*)
          new_links="$new_links"$'\n'"${TARGET}${link}"
          ;;
        *)
          new_links="$new_links"$'\n'"${TARGET}/${link}"
          ;;
      esac
    done <<< "$raw_links"

    ALL_LINKS=$(printf "%s\n%s" "$ALL_LINKS" "$new_links")

    # enqueue link penting
    local pending
    pending=$(echo "$new_links" | grep -Ei "$KW_LOGIN|$KW_ADMIN|$KW_REGISTER" 2>/dev/null)
    if [ -n "$pending" ]; then
      queue=$(printf "%s\n%s" "$queue" "$pending" | sort -u)
    fi
  done

  ALL_LINKS=$(echo "$ALL_LINKS" | grep -v '^$' | sort -u)

  local total
  total=$(echo "$ALL_LINKS" | grep -c . 2>/dev/null || echo 0)
  echo
  echo -e "  ${GREEN}Total link: $total${NC}"
  echo
}

# ============ 8. SENSITIVE FILES ============
run_sensitive() {
  section "SENSITIVE FILE SCAN"

  local found=0
  local path url code
  for path in "${SENSITIVE_PATHS[@]}"; do
    url="$TARGET/$path"
    code=$(check_status "$url")

    case "$code" in
      200)
        echo -e "    ${GREEN}[200]${NC} $url"
        found=$((found + 1))
        ;;
      301|302|307|308)
        echo -e "    ${CYAN}[$code]${NC} $url"
        found=$((found + 1))
        ;;
      401|403)
        echo -e "    ${YELLOW}[$code]${NC} $url ${GRAY}(exists)${NC}"
        found=$((found + 1))
        ;;
    esac
  done

  [ "$found" -eq 0 ] && echo -e "  ${GRAY}Tidak ada file sensitif terdeteksi.${NC}"
  echo
}

# ============ 9. FILTER LINKS ============
run_filter() {
  section "LINK PENTING"

  LOGIN=$(echo "$ALL_LINKS" | grep -Ei "$KW_LOGIN" | sort -u)
  ADMIN=$(echo "$ALL_LINKS" | grep -Ei "$KW_ADMIN" | sort -u)
  REGISTER=$(echo "$ALL_LINKS" | grep -Ei "$KW_REGISTER" | sort -u)
  CONFIG=$(echo "$ALL_LINKS" | grep -Ei "$KW_CONFIG" | sort -u)
  API=$(echo "$ALL_LINKS" | grep -Ei "$KW_API" | sort -u)
  SENSITIVE=$(echo "$ALL_LINKS" | grep -Ei "$KW_SENSITIVE" | sort -u)
  USER=$(echo "$ALL_LINKS" | grep -Ei "$KW_USER" | sort -u)

  print_cat() {
    local title="$1"
    local icon="$2"
    local color="$3"
    local items="$4"
    [ -z "$items" ] && return

    local count
    count=$(echo "$items" | grep -c .)

    echo -e "${color}${BOLD}┌──────────────────────────────────────────────────────┐${NC}"
    printf "${color}${BOLD}│${NC}  %s  %-45s ${color}${BOLD}[%d]${NC}\n" "$icon" "$title" "$count"
    echo -e "${color}${BOLD}├──────────────────────────────────────────────────────┤${NC}"

    local i=1
    while IFS= read -r u; do
      [ -z "$u" ] && continue
      printf "${color}│${NC}  ${WHITE}[%d]${NC} %s\n" "$i" "$u"
      i=$((i + 1))
    done <<< "$items"

    echo -e "${color}${BOLD}└──────────────────────────────────────────────────────┘${NC}"
    echo
  }

  print_cat "LOGIN"     "[*]" "$MAGENTA" "$LOGIN"
  print_cat "ADMIN"     "[+]" "$RED"     "$ADMIN"
  print_cat "REGISTER"  "[R]" "$CYAN"    "$REGISTER"
  print_cat "CONFIG"    "[C]" "$YELLOW"  "$CONFIG"
  print_cat "API"       "[A]" "$BLUE"    "$API"
  print_cat "SENSITIVE" "[!]" "$RED"     "$SENSITIVE"
  print_cat "USER"      "[U]" "$GREEN"   "$USER"
}

# ============ 10. PARAMETERS ============
run_params() {
  section "PARAMETER URL"

  local params
  params=$(echo "$ALL_LINKS" | grep -oE '\?[^#]*' | grep -oE '[a-zA-Z_][a-zA-Z0-9_]*=' | sed 's/=$//' | sort -u)

  if [ -z "$params" ]; then
    echo -e "  ${GRAY}Tidak ada parameter.${NC}"
  else
    echo -e "  ${WHITE}Parameter unik:${NC}"
    while IFS= read -r p; do
      [ -n "$p" ] && echo -e "    ${GREEN}*${NC} $p"
    done <<< "$params"
  fi
  echo
}

# ============ 11. FORM EXTRACT ============
run_forms() {
  section "FORM LOGIN / ADMIN"

  local shown=0
  local url html
  for url in $(echo "$LOGIN" | head -3) $(echo "$ADMIN" | head -2); do
    [ -z "$url" ] && continue

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
      case "$type" in
        hidden|submit|button|image|reset) continue ;;
      esac
      printf "${MAGENTA}│${NC}   ${GREEN}*${NC} ${WHITE}%-20s${NC} ${GRAY}[%s]${NC}" "$name" "$type"
      [ -n "$placeholder" ] && printf " ${GRAY}(%s)${NC}" "$placeholder"
      echo
    done

    echo -e "${MAGENTA}${BOLD}└─────────────────────────────────────────────────────┘${NC}"
    echo
    shown=1
  done

  [ "$shown" -eq 0 ] && echo -e "  ${GRAY}Tidak ada form login/admin.${NC}\n"
}

# ============ 12. SQLi ============
run_sqli() {
  section "SQL INJECTION TEST"
  echo -e "  ${YELLOW}Only for legal testing!${NC}"
  echo

  local candidates
  candidates=$(echo "$ALL_LINKS" | grep -E '\?.*=' | head -n "$MAX_SQLI")

  if [ -z "$candidates" ]; then
    echo -e "  ${GRAY}Tidak ada URL berparam.${NC}"
    return
  fi

  local payloads=("'" "\"" "' OR '1'='1" "1 AND 1=2")
  local hits=0
  local url payload

  for url in $candidates; do
    echo -e "    ${GRAY}Testing: $url${NC}"

    local base_html base_size
    base_html=$(fetch_html "$url")
    base_size=$(echo "$base_html" | wc -c)

    for payload in "${payloads[@]}"; do
      local enc testurl
      enc=$(printf '%s' "$payload" | sed "s/ /%20/g;s/'/%27/g;s/\"/%22/g")
      testurl=$(echo "$url" | sed -E "s/(=)[^&]*$/\1$enc/")

      local thtml tsize
      thtml=$(fetch_html "$testurl")
      tsize=$(echo "$thtml" | wc -c)

      if echo "$thtml" | grep -qiE "SQL syntax|MySQL server|mysql_fetch|ORA-[0-9]|PostgreSQL.*ERROR|SQLite.*error|Unclosed quotation"; then
        echo -e "      ${RED}[SQLi-ERR]${NC} Payload: $payload"
        echo -e "      ${GRAY}URL: $testurl${NC}"
        hits=$((hits + 1))
      fi

      local diff=$((base_size - tsize))
      [ "$diff" -lt 0 ] && diff=$((-diff))
      if [ "$base_size" -gt 100 ] && [ "$diff" -gt $((base_size / 2)) ]; then
        echo -e "      ${YELLOW}[SQLi-DIFF]${NC} ${diff} bytes diff, payload: $payload"
        hits=$((hits + 1))
      fi
    done
  done

  [ "$hits" -eq 0 ] && echo -e "  ${GRAY}Tidak ada indikasi SQLi.${NC}"
  echo
}

# ============ 13. XSS ============
run_xss() {
  section "XSS TEST (reflected)"

  local candidates
  candidates=$(echo "$ALL_LINKS" | grep -E '\?.*=' | head -n "$MAX_XSS")

  if [ -z "$candidates" ]; then
    echo -e "  ${GRAY}Tidak ada URL berparam.${NC}"
    return
  fi

  local payload='<script>alert(1)</script>'
  local enc='%3Cscript%3Ealert(1)%3C%2Fscript%3E'
  local hits=0
  local url

  for url in $candidates; do
    echo -e "    ${GRAY}Testing: $url${NC}"
    local testurl
    testurl=$(echo "$url" | sed -E "s/(=)[^&]*$/\1$enc/")

    local thtml
    thtml=$(fetch_html "$testurl")

    if echo "$thtml" | grep -qF "$payload"; then
      echo -e "      ${RED}[XSS!]${NC} Payload reflected unencoded!"
      echo -e "      ${GRAY}URL: $testurl${NC}"
      hits=$((hits + 1))
    fi
  done

  [ "$hits" -eq 0 ] && echo -e "  ${GRAY}Tidak ada indikasi XSS.${NC}"
  echo
}

# ============ 14. LFI ============
run_lfi() {
  section "LFI TEST"

  local candidates
  candidates=$(echo "$ALL_LINKS" | grep -E '\?.*=' | head -n 5)

  if [ -z "$candidates" ]; then
    echo -e "  ${GRAY}Tidak ada URL cocok.${NC}"
    return
  fi

  local payloads=("../../../../etc/passwd" "....//....//....//etc/passwd")
  local hits=0
  local url payload

  for url in $candidates; do
    for payload in "${payloads[@]}"; do
      local enc testurl
      enc=$(printf '%s' "$payload" | sed 's|/|%2F|g')
      testurl=$(echo "$url" | sed -E "s/(=)[^&]*$/\1$enc/")

      local thtml
      thtml=$(fetch_html "$testurl")

      if echo "$thtml" | grep -qE "root:x:0:0|root:.*:0:0:"; then
        echo -e "      ${RED}[LFI!]${NC} /etc/passwd readable!"
        echo -e "      ${GRAY}URL: $testurl${NC}"
        hits=$((hits + 1))
      fi
    done
  done

  [ "$hits" -eq 0 ] && echo -e "  ${GRAY}Tidak ada indikasi LFI.${NC}"
  echo
}

# ============ 15. OPEN REDIRECT ============
run_openredirect() {
  section "OPEN REDIRECT TEST"

  local candidates
  candidates=$(echo "$ALL_LINKS" | grep -Ei 'redirect|url=|next=|return=|goto=|dest=' | head -n 5)

  if [ -z "$candidates" ]; then
    echo -e "  ${GRAY}Tidak ada URL cocok.${NC}"
    return
  fi

  local payload="https://evil.example.com"
  local hits=0
  local url

  for url in $candidates; do
    local enc testurl
    enc=$(printf '%s' "$payload" | sed 's/:/%3A/g;s|/|%2F|g')
    testurl=$(echo "$url" | sed -E "s/(=)[^&]*$/\1$enc/")

    local headers
    headers=$(curl -sIL --max-time 5 -A "$UA" "$testurl" 2>/dev/null)

    if echo "$headers" | grep -qiE "^location:.*evil\.example\.com"; then
      echo -e "      ${RED}[OPEN REDIRECT]${NC} -> external!"
      echo -e "      ${GRAY}URL: $testurl${NC}"
      hits=$((hits + 1))
    fi
  done

  [ "$hits" -eq 0 ] && echo -e "  ${GRAY}Tidak ada indikasi open redirect.${NC}"
  echo
}

# ============ 16. CORS ============
run_cors() {
  section "CORS MISCONFIG"

  local headers
  headers=$(curl -sIL --max-time 5 -A "$UA" -H "Origin: https://evil.example.com" "$TARGET" 2>/dev/null)

  local acao acac
  acao=$(echo "$headers" | grep -i "^access-control-allow-origin:" | head -1)
  acac=$(echo "$headers" | grep -i "^access-control-allow-credentials:" | head -1)

  if [ -n "$acao" ]; then
    echo -e "  ${WHITE}ACAO:${NC} $acao"
    [ -n "$acac" ] && echo -e "  ${WHITE}ACAC:${NC} $acac"

    if echo "$acao" | grep -q "evil.example.com"; then
      echo -e "  ${RED}[!] Reflects arbitrary origin - HIGH RISK${NC}"
    elif echo "$acao" | grep -q "\*"; then
      if [ -n "$acac" ]; then
        echo -e "  ${RED}[!] Wildcard + credentials - HIGH RISK${NC}"
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
  section "ALLOWED HTTP METHODS"

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

# ============ 18. ROBOTS / SITEMAP ============
run_robots() {
  section "ROBOTS.TXT & SITEMAP"

  local robots
  robots=$(fetch_html "$TARGET/robots.txt")
  if echo "$robots" | grep -qi "user-agent"; then
    echo -e "  ${GREEN}[OK]${NC} robots.txt ditemukan"
    echo -e "${GRAY}-------------------------------${NC}"
    echo "$robots" | head -20
    echo -e "${GRAY}-------------------------------${NC}"
  else
    echo -e "  ${GRAY}robots.txt tidak ditemukan${NC}"
  fi
  echo

  local sitemap
  sitemap=$(fetch_html "$TARGET/sitemap.xml")
  if echo "$sitemap" | grep -qi "<urlset"; then
    local count
    count=$(echo "$sitemap" | grep -c "<loc>")
    echo -e "  ${GREEN}[OK]${NC} sitemap.xml ditemukan ($count URL)"
  else
    echo -e "  ${GRAY}sitemap.xml tidak ditemukan${NC}"
  fi
  echo
}

# ============ 19. GOOGLE DORKS ============
run_dorks() {
  section "GOOGLE DORK HINTS"

  echo -e "${GRAY}  Copy-paste ke Google:${NC}"
  echo
  echo -e "    ${WHITE}1.${NC} site:$DOMAIN ext:sql OR ext:bak OR ext:log"
  echo -e "    ${WHITE}2.${NC} site:$DOMAIN inurl:admin OR inurl:login"
  echo -e "    ${WHITE}3.${NC} site:$DOMAIN intitle:index.of"
  echo -e "    ${WHITE}4.${NC} site:$DOMAIN ext:env OR ext:config"
  echo -e "    ${WHITE}5.${NC} site:$DOMAIN inurl:api OR inurl:graphql"
  echo -e "    ${WHITE}6.${NC} site:pastebin.com \"$DOMAIN\""
  echo -e "    ${WHITE}7.${NC} site:github.com \"$DOMAIN\" password"
  echo
}

# ============ 20. FINAL SUMMARY ============
final_summary() {
  section "FINAL SUMMARY"

  local t_login t_admin t_reg t_cfg t_api t_sens t_user t_total
  t_login=$(echo "$LOGIN" | grep -c . 2>/dev/null || echo 0)
  t_admin=$(echo "$ADMIN" | grep -c . 2>/dev/null || echo 0)
  t_reg=$(echo "$REGISTER" | grep -c . 2>/dev/null || echo 0)
  t_cfg=$(echo "$CONFIG" | grep -c . 2>/dev/null || echo 0)
  t_api=$(echo "$API" | grep -c . 2>/dev/null || echo 0)
  t_sens=$(echo "$SENSITIVE" | grep -c . 2>/dev/null || echo 0)
  t_user=$(echo "$USER" | grep -c . 2>/dev/null || echo 0)
  t_total=$((t_login + t_admin + t_reg + t_cfg + t_api + t_sens + t_user))

  printf "  ${WHITE}%-22s${NC} : ${MAGENTA}%d${NC}\n" "Login"     "$t_login"
  printf "  ${WHITE}%-22s${NC} : ${RED}%d${NC}\n"     "Admin"     "$t_admin"
  printf "  ${WHITE}%-22s${NC} : ${CYAN}%d${NC}\n"    "Register"  "$t_reg"
  printf "  ${WHITE}%-22s${NC} : ${YELLOW}%d${NC}\n"  "Config"    "$t_cfg"
  printf "  ${WHITE}%-22s${NC} : ${BLUE}%d${NC}\n"    "API"       "$t_api"
  printf "  ${WHITE}%-22s${NC} : ${RED}%d${NC}\n"     "Sensitive" "$t_sens"
  printf "  ${WHITE}%-22s${NC} : ${GREEN}%d${NC}\n"   "User"      "$t_user"
  echo -e "  ${GRAY}-------------------------${NC}"
  printf "  ${WHITE}${BOLD}%-22s${NC} : ${GREEN}${BOLD}%d${NC}\n" "TOTAL LINK" "$t_total"
  echo
}

# ============ MAIN ============
main() {
  check_deps
  banner
  get_target

  echo -ne "${YELLOW}Pilih mode [1=Quick / 2=Full]: ${NC}"
  read -r mode
  echo

  case "$mode" in
    1)
      echo -e "${GREEN}Mode QUICK${NC}"
      run_cms
      run_crawl
      run_filter
      run_sensitive
      final_summary
      ;;
    2)
      echo -e "${GREEN}Mode FULL${NC}"
      run_dns
      run_portscan
      run_subdomains
      run_waf
      run_sec_headers
      run_methods
      run_cors
      run_robots
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
    *)
      echo -e "${RED}Mode tidak valid. Pilih 1 atau 2.${NC}"
      exit 1
      ;;
  esac

  echo
  echo -e "${GREEN}${BOLD}Selesai. Selamat hunting!${NC}"
  echo -e "${GRAY}Ingat: legal testing only.${NC}"
  echo
}

main
