#!/usr/bin/env bash
#
# caritoken.sh - Cari token/API key yang bocor di halaman publik
# For LEGAL security research only (bug bounty / pentest resmi)
#

set -o pipefail

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

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36"
TIMEOUT=8
MAX_JS=15

# ============ CEK DEP ============
check_deps() {
  local missing=()
  local cmd
  for cmd in curl grep sed awk sort head; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  [ ${#missing[@]} -gt 0 ] && {
    echo -e "${RED}Missing: ${missing[*]}${NC}"
    exit 1
  }
}

# ============ BANNER ============
banner() {
  clear
  echo -e "${RED}${BOLD}"
  cat << 'EOF'
  ╔══════════════════════════════════════════════╗
  ║   🔑 LEAKED TOKEN / API KEY SCANNER          ║
  ║   ⚠ Legal bug bounty use only ⚠              ║
  ╚══════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
  echo -e "${GRAY}Script ini CUMA cari token bocor + verifikasi read-only.${NC}"
  echo -e "${GRAY}Gak ada fungsi add subdomain / modif apa pun.${NC}"
  echo
}

# ============ INPUT ============
get_target() {
  echo -ne "${BLUE}URL target: ${NC}"
  read -r TARGET
  [ -z "$TARGET" ] && { echo -e "${RED}Kosong!${NC}"; exit 1; }
  case "$TARGET" in
    http://*|https://*) ;;
    *) TARGET="https://$TARGET" ;;
  esac
  TARGET="${TARGET%/}"
  HOST=$(echo "$TARGET" | sed -E 's|https?://([^/]+).*|\1|')
  SCHEME=$(echo "$TARGET" | sed -E 's|(https?)://.*|\1|')
  echo
  echo -e "${GRAY}Target: ${WHITE}$TARGET${NC}"
  echo
}

# ============ FETCH ============
fetch() {
  curl -sL --max-time "$TIMEOUT" -A "$UA" "$1" 2>/dev/null
}

# ============ SECTION ============
section() {
  echo
  echo -e "${MAGENTA}${BOLD}┌──────────────────────────────────────────────────────┐${NC}"
  printf "${MAGENTA}${BOLD}│${NC}  %-52s ${MAGENTA}${BOLD}│${NC}\n" "$1"
  echo -e "${MAGENTA}${BOLD}└──────────────────────────────────────────────────────┘${NC}"
  echo
}

# ============ PATTERN TOKEN ============
# Regex pattern buat deteksi token populer
# Format: "NamaToken|regex|deskripsi"
declare -a TOKEN_PATTERNS=(
  # Cloudflare
  "Cloudflare-API-Token|cloudflare.*[A-Za-z0-9_-]{40}|CF API Token"
  "Cloudflare-Global-Key|[a-f0-9]{37}|CF Global Key"
  "Cloudflare-Email|cloudflare.*email|[email protected]"
  "CF-API-Key|[A-Za-z0-9_-]{37}|CF API Key"

  # AWS
  "AWS-Access-Key|AKIA[0-9A-Z]{16}|AWS Access Key"
  "AWS-Secret|aws_secret.*[A-Za-z0-9/+=]{40}|AWS Secret"

  # Google
  "Google-API-Key|AIza[0-9A-Za-z_-]{35}|Google API Key"
  "Firebase|firebaseio\\.com|Firebase URL"

  # GitHub
  "GitHub-Token|gh[pousr]_[A-Za-z0-9]{36,}|GitHub Token"
  "GitHub-OAuth|github_pat_[A-Za-z0-9_]{82}|GitHub PAT"

  # GitLab
  "GitLab-Token|glpat-[A-Za-z0-9_-]{20}|GitLab PAT"

  # Slack
  "Slack-Token|xox[baprs]-[A-Za-z0-9-]+|Slack Token"
  "Slack-Webhook|hooks\\.slack\\.com/services/[A-Z0-9/]+|Slack Webhook"

  # Stripe
  "Stripe-Live|sk_live_[A-Za-z0-9]{24,}|Stripe Live Secret"
  "Stripe-Pub|pk_live_[A-Za-z0-9]{24,}|Stripe Public"

  # SendGrid / Mailgun
  "SendGrid|SG\\.[A-Za-z0-9_-]{22}\\.[A-Za-z0-9_-]{43}|SendGrid API"
  "Mailgun|key-[a-f0-9]{32}|Mailgun API"

  # Twilio
  "Twilio-Key|SK[a-f0-9]{32}|Twilio API"

  # JWT
  "JWT|eyJ[A-Za-z0-9_-]+\\.eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+|JWT Token"

  # Generic
  "Generic-API-Key|api[_-]?key[\"']?\\s*[:=]\\s*[\"'][A-Za-z0-9_-]{20,}[\"']|Generic API Key"
  "Generic-Secret|secret[\"']?\\s*[:=]\\s*[\"'][A-Za-z0-9_-]{20,}[\"']|Generic Secret"
  "Generic-Token|token[\"']?\\s*[:=]\\s*[\"'][A-Za-z0-9_.-]{20,}[\"']|Generic Token"
  "Private-Key|-----BEGIN (RSA|EC|OPENSSH|DSA|PGP) PRIVATE KEY-----|Private Key"
  "Bearer|Bearer\\s+[A-Za-z0-9_.-]{20,}|Bearer Token"
)

# ============ CARI DI HTML ============
scan_content() {
  local content="$1"
  local source="$2"
  local found=0

  local entry name pattern desc match
  for entry in "${TOKEN_PATTERNS[@]}"; do
    name="${entry%%|*}"
    rest="${entry#*|}"
    pattern="${rest%%|*}"
    desc="${rest##*|}"

    # cari matches
    match=$(echo "$content" | grep -oE "$pattern" 2>/dev/null | head -3)

    if [ -n "$match" ]; then
      echo -e "  ${RED}${BOLD}[FOUND]${NC} ${WHITE}$name${NC} ${GRAY}($desc)${NC}"
      echo -e "    ${GRAY}Source: $source${NC}"
      echo "$match" | while read -r m; do
        # masking
        masked=$(echo "$m" | sed -E 's/^(.{8}).*(.{4})$/\1***MASKED***\2/')
        echo -e "    ${YELLOW}->${NC} ${masked}"
      done
      echo
      found=$((found + 1))
    fi
  done

  return $found
}

# ============ EXTRACT JS FILES ============
extract_js() {
  local html="$1"
  echo "$html" \
    | grep -oEi 'src=["'"'"'][^"'"'"']+\.js[^"'"'"']*' \
    | sed -E 's/^[sS][rR][cC]=["'"'"']//' \
    | sort -u \
    | while read -r js; do
        [ -z "$js" ] && continue
        case "$js" in
          http://*|https://*) echo "$js" ;;
          //*) echo "${SCHEME}:$js" ;;
          /*) echo "${TARGET}${js}" ;;
          *) echo "${TARGET}/${js}" ;;
        esac
      done | sort -u
}

# ============ MAIN SCAN ============
run_scan() {
  section "1. SCAN HALAMAN UTAMA"

  echo -e "${BLUE}Fetching: $TARGET${NC}"
  HTML=$(fetch "$TARGET")

  if [ -z "$HTML" ]; then
    echo -e "${RED}Gagal fetch${NC}"
    return
  fi

  echo -e "${GRAY}Ukuran: $(echo "$HTML" | wc -c) bytes${NC}"
  echo

  scan_content "$HTML" "$TARGET"
  echo

  section "2. CARI JS FILES"

  JS_LIST=$(extract_js "$HTML")
  JS_COUNT=$(echo "$JS_LIST" | grep -c . 2>/dev/null || echo 0)

  echo -e "${GRAY}Ditemukan $JS_COUNT JS files${NC}"
  echo

  if [ "$JS_COUNT" -eq 0 ]; then
    echo -e "${GRAY}Tidak ada JS file.${NC}"
    return
  fi

  section "3. SCAN JS FILES"

  local i=0
  while IFS= read -r jsurl; do
    [ -z "$jsurl" ] && continue
    i=$((i + 1))
    [ "$i" -gt "$MAX_JS" ] && break

    echo -e "${GRAY}[$i] $jsurl${NC}"

    local jscontent
    jscontent=$(fetch "$jsurl")
    local jssize
    jssize=$(echo "$jscontent" | wc -c)
    echo -e "${GRAY}    Size: $jssize bytes${NC}"

    if [ "$jssize" -gt 100 ]; then
      scan_content "$jscontent" "$jsurl"
    fi
  done <<< "$JS_LIST"

  echo
}

# ============ SCAN COMMON FILES ============
run_common() {
  section "4. SCAN FILE SENSITIF UMUM"

  local FILES=(
    "/.env"
    "/.env.local"
    "/.env.production"
    "/config.js"
    "/config.json"
    "/config.php"
    "/app.js"
    "/main.js"
    "/bundle.js"
    "/.git/config"
    "/package.json"
    "/composer.json"
    "/Dockerfile"
    "/docker-compose.yml"
    "/.aws/credentials"
    "/sitemap.xml"
    "/robots.txt"
    "/.well-known/security.txt"
  )

  local file url code content
  for file in "${FILES[@]}"; do
    url="$TARGET$file"
    code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 -A "$UA" "$url" 2>/dev/null)

    case "$code" in
      200)
        echo -e "  ${GREEN}[200]${NC} $url"
        content=$(fetch "$url")
        if [ -n "$content" ]; then
          scan_content "$content" "$url"
        fi
        ;;
      401|403)
        echo -e "  ${YELLOW}[$code]${NC} $url ${GRAY}(exists)${NC}"
        ;;
    esac
  done
  echo
}

# ============ CEK VALIDITAS CLOUDFLARE TOKEN (READ-ONLY) ============
verify_cf_token() {
  section "5. VERIFIKASI TOKEN CLOUDFLARE (READ-ONLY)"

  echo -e "${GRAY}Kalau ada token CF ditemukan, kita cek valid atau nggak.${NC}"
  echo -e "${GRAY}Endpoint: GET /client/v4/user/tokens/verify${NC}"
  echo -e "${YELLOW}Ini cuma READ - gak bisa modif apa pun.${NC}"
  echo

  echo -ne "${BLUE}Paste token CF (atau Enter buat skip): ${NC}"
  read -r CF_TOKEN

  if [ -z "$CF_TOKEN" ]; then
    echo -e "${GRAY}Skip.${NC}"
    return
  fi

  echo
  echo -e "${BLUE}Cek validitas...${NC}"

  RESP=$(curl -s --max-time 10 \
    -H "Authorization: Bearer $CF_TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/user/tokens/verify" 2>/dev/null)

  if echo "$RESP" | grep -q '"success":true'; then
    echo -e "  ${RED}[!] TOKEN VALID${NC}"
    echo -e "  ${YELLOW}JANGAN DIPAKAI! Lapor ke program bug bounty.${NC}"
    echo
    echo -e "${GRAY}Response:${NC}"
    echo "$RESP" | head -20
  elif echo "$RESP" | grep -q '"success":false'; then
    echo -e "  ${GREEN}[OK]${NC} Token INVALID (udah expired/revoked)"
    echo -e "${GRAY}$RESP${NC}" | head -5
  else
    echo -e "  ${YELLOW}[?]${NC} Response aneh"
    echo "$RESP" | head -5
  fi
  echo
}

# ============ REPORT TEMPLATE ============
show_report_template() {
  section "6. TEMPLATE LAPORAN (buat bug bounty)"

  cat << 'EOF'
  Kalau nemu token bocor, laporan ke program bug bounty:

  ┌─────────────────────────────────────────────────┐
  │ Title: Exposed Cloudflare API Token in <file>  │
  ├─────────────────────────────────────────────────┤
  │ Severity: Critical / High                      │
  │                                                 │
  │ Description:                                    │
  │ Token API Cloudflare ditemukan bocor di         │
  │ <URL/file>. Token ini bisa dipakai untuk        │
  │ <aksi>. Diverifikasi dengan GET endpoint        │
  │ /user/tokens/verify (read-only) -> VALID.       │
  │                                                 │
  │ Steps to Reproduce:                             │
  │ 1. Kunjungi <URL>                               │
  │ 2. Lihat file <file> baris <N>                  │
  │ 3. Token: <token-yang-dimasking>                │
  │ 4. Verifikasi pakai curl:                       │
  │    curl -H "Authorization: Bearer <token>" \    │
  │      https://api.cloudflare.com/client/v4/      │
  │      user/tokens/verify                         │
  │                                                 │
  │ Impact:                                         │
  │ Attacker bisa kontrol DNS, add/delete DNS       │
  │ records, lihat traffic, dll.                    │
  │                                                 │
  │ Remediation:                                    │
  │ - Revoke token segera                           │
  │ - Rotate credentials                            │
  │ - Hapus file dari public access                 │
  └─────────────────────────────────────────────────┘

EOF
}

# ============ MAIN ============
main() {
  check_deps
  banner
  get_target

  echo -e "${YELLOW}⚠ Konfirmasi:${NC}"
  echo -e "${GRAY}  Script ini buat LEGAL security testing.${NC}"
  echo -e "${GRAY}  Token yang ditemukan JANGAN DIPAKAI buat modif.${NC}"
  echo -e "${GRAY}  Langsung lapor ke program kalau ada temuan.${NC}"
  echo
  echo -ne "${YELLOW}Lanjut? (y/N): ${NC}"
  read -r confirm
  case "$confirm" in
    y|Y|yes|YES) ;;
    *) echo -e "${GRAY}Batal.${NC}"; exit 0 ;;
  esac
  echo

  run_scan
  run_common
  verify_cf_token
  show_report_template

  echo -e "${GREEN}${BOLD}Selesai.${NC}"
  echo -e "${GRAY}Kalau nemu token: laporkan, jangan dipakai.${NC}"
  echo
}

main
