#!/usr/bin/env bash
#
# saring.sh - Cari & ambil data login/admin dari URL target
# Fitur: crawl, cek status, ekstrak form, deteksi panel admin
#

set -o pipefail

# ============ WARNA ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ============ KONFIG ============
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
TIMEOUT=10
MAX_CRAWL=10          # max halaman yang di-crawl
MAX_CHECK=30          # max URL yang dicek status

# ============ KEYWORD ============
KEYWORD_LOGIN="login|signin|sign-in|log-in|masuk|auth|session|sso|oauth"
KEYWORD_ADMIN="admin|administrator|dashboard|panel|cpanel|manage|backend|wp-admin|phpmyadmin"
KEYWORD_REGISTER="register|signup|sign-up|daftar|create-account"
KEYWORD_CONFIG="config|configuration|\.env|settings|setup|install|\.git|backup|database|\.sql|\.bak"
KEYWORD_API="api|graphql|rest|swagger|docs|openapi|/v1|/v2|/v3"
KEYWORD_SENSITIVE="upload|download|private|secret|token|key|password|passwd|\.zip|\.tar|\.gz"
KEYWORD_USER="profile|account|user|users|member|customer"

# ============ CEK DEPENDENSI ============
check_deps() {
  local missing=()
  for cmd in curl grep sed awk sort; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}✗ Tool tidak ditemukan: ${missing[*]}${NC}"
    exit 1
  fi
}

# ============ BANNER ============
banner() {
  clear
  echo -e "${CYAN}${BOLD}"
  cat << "EOF"
  ╔═══════════════════════════════════════════════╗
  ║   🔍  Saring Link + Ambil Data Admin          ║
  ║       login · admin · form · endpoint         ║
  ╚═══════════════════════════════════════════════╝
EOF
  echo -e "${NC}"
}

# ============ INPUT URL ============
get_target() {
  echo -ne "${BLUE}→ Masukkan URL target: ${NC}"
  read -r TARGET

  [ -z "$TARGET" ] && { echo -e "${RED}✗ URL kosong.${NC}"; exit 1; }

  [[ "$TARGET" =~ ^https?:// ]] || TARGET="https://$TARGET"
  TARGET="${TARGET%/}"

  if ! [[ "$TARGET" =~ ^https?://[a-zA-Z0-9.-]+ ]]; then
    echo -e "${RED}✗ URL tidak valid: $TARGET${NC}"
    exit 1
  fi

  HOST=$(echo "$TARGET" | sed -E 's|https?://([^/]+).*|\1|')
  SCHEME=$(echo "$TARGET" | sed -E 's|(https?)://.*|\1|')

  echo
  echo -e "${GRAY}┌─────────────────────────────────────────────┐${NC}"
  echo -e "${GRAY}│${NC} Target : ${WHITE}$TARGET${NC}"
  echo -e "${GRAY}│${NC} Host   : ${WHITE}$HOST${NC}"
  echo -e "${GRAY}│${NC} Scheme : ${WHITE}$SCHEME${NC}"
  echo -e "${GRAY}└─────────────────────────────────────────────┘${NC}"
  echo
}

# ============ FETCH HTML ============
fetch_html() {
  local url="$1"
  curl -sL --max-time "$TIMEOUT" -A "$UA" "$url" 2>/dev/null
}

# ============ EKSTRAK LINK ============
extract_links_from() {
  local html="$1"
  local baseurl="$2"
  local basehost="$3"

  echo "$html" \
    | grep -oEi '(href|src|action)=["'"'"'][^"'"'"' >]+' \
    | sed -E 's/^[a-zA-Z]+=["'"'"']//' \
    | sort -u \
    | while read -r link; do
        [ -z "$link" ] && continue
        case "$link" in
          \#*|javascript:*|mailto:*|tel:*|data:*) continue ;;
        esac

        if [[ "$link" =~ ^https?:// ]]; then
          [[ "$link" == *"$basehost"* ]] && echo "$link"
        elif [[ "$link" =~ ^// ]]; then
          echo "${SCHEME}:$link"
        elif [[ "$link" =~ ^/ ]]; then
          echo "$baseurl$link"
        else
          echo "$baseurl/$link"
        fi
      done | sort -u
}

# ============ CEK STATUS HTTP ============
check_status() {
  local url="$1"
  curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 -A "$UA" "$url" 2>/dev/null
}

# ============ CRAWL OTOMATIS ============
crawl_site() {
  echo -e "${BLUE}→ Crawling situs (max $MAX_CRAWL halaman)...${NC}"

  ALL_LINKS=""
  PAGES_VISITED=0
  QUEUE="$TARGET"

  while [ -n "$QUEUE" ] && [ "$PAGES_VISITED" -lt "$MAX_CRAWL" ]; do
    local current
    current=$(echo "$QUEUE" | head -n1)
    QUEUE=$(echo "$QUEUE" | tail -n +2)

    [ -z "$current" ] && continue

    PAGES_VISITED=$((PAGES_VISITED + 1))
    echo -e "${GRAY}  [$PAGES_VISITED/$MAX_CRAWL] Crawling: $current${NC}"

    local html
    html=$(fetch_html "$current")
    [ -z "$html" ] && continue

    local new_links
    new_links=$(extract_links_from "$html" "$TARGET" "$HOST")

    # tambahin link baru ke ALL_LINKS
    ALL_LINKS=$(printf "%s\n%s" "$ALL_LINKS" "$new_links")

    # tambahin ke queue kalau belum pernah dikunjungi
    local pending
    pending=$(echo "$new_links" | grep -Ei "$KEYWORD_LOGIN|$KEYWORD_ADMIN|$KEYWORD_REGISTER")
    QUEUE=$(printf "%s\n%s" "$QUEUE" "$pending")
    QUEUE=$(echo "$QUEUE" | sort -u)
  done

  ALL_LINKS=$(echo "$ALL_LINKS" | grep -v '^$' | sort -u)
  echo -e "${GRAY}  Selesai crawl. Total link: $(echo "$ALL_LINKS" | grep -c .)${NC}"
  echo
}

# ============ FILTER ============
filter_category() {
  local pattern="$1"
  local links="$2"
  echo "$links" | grep -Ei "$pattern" | sort -u
}

# ============ CEK STATUS SEMUA LINK PENTING ============
check_important_status() {
  echo -e "${BLUE}→ Cek status HTTP link penting...${NC}"

  IMPORTANT=$(printf "%s\n%s\n%s\n%s\n%s\n%s\n%s" \
    "$LOGIN" "$ADMIN" "$REGISTER" "$CONFIG" "$API" "$SENSITIVE" "$USER" \
    | grep -v '^$' | sort -u | head -n "$MAX_CHECK")

  CHECKED=""
  for url in $IMPORTANT; do
    local code
    code=$(check_status "$url")
    CHECKED="$CHECKED$code|$url\n"
  done

  echo -e "${GRAY}  Selesai cek $(echo -e "$CHECKED" | grep -c .) URL${NC}"
  echo
}

# ============ EKSTRAK FORM LOGIN ============
extract_forms() {
  local url="$1"
  local html
  html=$(fetch_html "$url")
  [ -z "$html" ] && return

  # cari form
  echo "$html" | tr '\n' ' ' | grep -oEi '<form[^>]*>' | while read -r formtag; do
    local action method
    action=$(echo "$formtag" | grep -oEi 'action=["'"'"'][^"'"'"']*' | sed -E 's/.*=["'"'"']//')
    method=$(echo "$formtag" | grep -oEi 'method=["'"'"'][^"'"'"']*' | sed -E 's/.*=["'"'"']//')
    [ -z "$method" ] && method="GET"
    [ -z "$action" ] && action="$url"

    echo "ACTION=$action|METHOD=$method"
  done

  # cari input field
  echo "$html" | tr '\n' ' ' | grep -oEi '<input[^>]*>' | while read -r inputtag; do
    local name type placeholder
    name=$(echo "$inputtag" | grep -oEi 'name=["'"'"'][^"'"'"']*' | sed -E 's/.*=["'"'"']//')
    type=$(echo "$inputtag" | grep -oEi 'type=["'"'"'][^"'"'"']*' | sed -E 's/.*=["'"'"']//')
    placeholder=$(echo "$inputtag" | grep -oEi 'placeholder=["'"'"'][^"'"'"']*' | sed -E 's/.*=["'"'"']//')

    [ -z "$name" ] && continue
    [ -z "$type" ] && type="text"

    # skip hidden & csrf (kecuali user mau liat)
    case "$type" in
      hidden|submit|button|image|reset) continue ;;
    esac

    echo "FIELD=$name|TYPE=$type|PLACEHOLDER=$placeholder"
  done
}

# ============ TAMPILKAN HASIL UTAMA ============
print_category() {
  local title="$1"
  local icon="$2"
  local color="$3"
  local items="$4"

  [ -z "$items" ] && return 1

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
  return 0
}

# ============ TAMPILKAN DETAIL FORM ============
show_form_details() {
  local url="$1"
  local label="$2"
  local color="$3"

  echo -e "${color}${BOLD}┌─ FORM LOGIN/ADMIN ──────────────────────────────────┐${NC}"
  echo -e "${color}│${NC} ${WHITE}URL:${NC} $url"
  echo -e "${color}│${NC} ${GRAY}─────────────────────────────────────────${NC}"

  local forms
  forms=$(extract_forms "$url" | grep '^ACTION=')
  local fields
  fields=$(extract_forms "$url" | grep '^FIELD=')

  if [ -z "$forms" ]; then
    echo -e "${color}│${NC} ${YELLOW}⚠ Tidak ada form ditemukan${NC}"
    echo -e "${color}${BOLD}└─────────────────────────────────────────────────────┘${NC}"
    echo
    return
  fi

  echo "$forms" | while read -r line; do
    local action method
    action=$(echo "$line" | sed -E 's/.*ACTION=([^|]+).*/\1/')
    method=$(echo "$line" | sed -E 's/.*METHOD=([^|]+).*/\1/')
    echo -e "${color}│${NC} ${WHITE}├─ Action :${NC} $action"
    echo -e "${color}│${NC} ${WHITE}├─ Method :${NC} $method"
  done

  echo -e "${color}│${NC} ${GRAY}─────────────────────────────────────────${NC}"

  if [ -n "$fields" ]; then
    echo -e "${color}│${NC} ${WHITE}└─ Field yang dibutuhkan:${NC}"
    echo "$fields" | while read -r line; do
      local name type placeholder
      name=$(echo "$line" | sed -E 's/.*FIELD=([^|]+).*/\1/')
      type=$(echo "$line" | sed -E 's/.*TYPE=([^|]+).*/\1/')
      placeholder=$(echo "$line" | sed -E 's/.*PLACEHOLDER=([^|]+).*/\1/')

      printf "${color}│${NC}     ${GREEN}•${NC} ${WHITE}%-20s${NC} ${GRAY}[%s]${NC}" "$name" "$type"
      [ -n "$placeholder" ] && printf " ${GRAY}(%s)${NC}" "$placeholder"
      echo
    done
  fi

  echo -e "${color}${BOLD}└─────────────────────────────────────────────────────┘${NC}"
  echo
}

# ============ TAMPILKAN HASIL AKHIR ============
show_results() {
  echo
  echo -e "${GREEN}${BOLD}═══════════════ HASIL FILTER ═══════════════${NC}"
  echo

  local found=0
  print_category "LOGIN PAGE"      "🔐" "$MAGENTA" "$LOGIN"     && found=1
  print_category "ADMIN PANEL"     "🛠️ " "$RED"     "$ADMIN"     && found=1
  print_category "REGISTER"        "📝" "$CYAN"    "$REGISTER"  && found=1
  print_category "CONFIG / SECRET" "⚙️ " "$YELLOW"  "$CONFIG"    && found=1
  print_category "API ENDPOINT"    "🔌" "$BLUE"    "$API"       && found=1
  print_category "SENSITIVE FILE"  "⚠️ " "$RED"     "$SENSITIVE" && found=1
  print_category "USER / PROFILE"  "👤" "$GREEN"   "$USER"      && found=1

  if [ "$found" -eq 0 ]; then
    echo -e "${YELLOW}⚠ Tidak ada link penting ditemukan.${NC}"
    echo
    return
  fi

  # detail form login
  echo
  echo -e "${GREEN}${BOLD}═══════════════ DETAIL FORM ═══════════════${NC}"
  echo

  local shown=0
  for url in $(echo "$LOGIN" | head -n 3); do
    [ -n "$url" ] && show_form_details "$url" "LOGIN" "$MAGENTA" && shown=1
  done
  for url in $(echo "$ADMIN" | head -n 2); do
    [ -n "$url" ] && show_form_details "$url" "ADMIN" "$RED" && shown=1
  done

  [ "$shown" -eq 0 ] && echo -e "${YELLOW}⚠ Tidak ada form login/admin yang bisa diekstrak.${NC}\n"
}

# ============ TAMPILKAN STATUS ============
show_status() {
  echo
  echo -e "${GREEN}${BOLD}═══════════════ STATUS HTTP ═══════════════${NC}"
  echo

  if [ -z "$CHECKED" ]; then
    echo -e "${YELLOW}⚠ Tidak ada URL yang dicek.${NC}"
    return
  fi

  printf "${GRAY}┌─────┬────────────────────────────────────────────┐${NC}\n"
  printf "${GRAY}│${NC} ${WHITE}%-3s${NC} ${GRAY}│${NC} ${WHITE}%-42s${NC} ${GRAY}│${NC}\n" "St" "URL"
  printf "${GRAY}├─────┼────────────────────────────────────────────┤${NC}\n"

  echo -e "$CHECKED" | while IFS='|' read -r code url; do
    [ -z "$url" ] && continue
    local color="$GRAY"
    case "$code" in
      200) color="$GREEN" ;;
      301|302|307|308) color="$CYAN" ;;
      401|403) color="$YELLOW" ;;
      404|410) color="$RED" ;;
      5*) color="$RED" ;;
      000) color="$GRAY" ;;
    esac
    printf "${GRAY}│${NC} ${color}%-3s${NC} ${GRAY}│${NC} %-42s ${GRAY}│${NC}\n" "$code" "$url"
  done

  printf "${GRAY}└─────┴────────────────────────────────────────────┘${NC}\n"
  echo
}

# ============ RINGKASAN ============
show_summary() {
  local t_login t_admin t_register t_config t_api t_sensitive t_user t_total
  t_login=$(echo "$LOGIN" | grep -c . 2>/dev/null || echo 0)
  t_admin=$(echo "$ADMIN" | grep -c . 2>/dev/null || echo 0)
  t_register=$(echo "$REGISTER" | grep -c . 2>/dev/null || echo 0)
  t_config=$(echo "$CONFIG" | grep -c . 2>/dev/null || echo 0)
  t_api=$(echo "$API" | grep -c . 2>/dev/null || echo 0)
  t_sensitive=$(echo "$SENSITIVE" | grep -c . 2>/dev/null || echo 0)
  t_user=$(echo "$USER" | grep -c . 2>/dev/null || echo 0)
  t_total=$((t_login + t_admin + t_register + t_config + t_api + t_sensitive + t_user))

  echo -e "${GREEN}${BOLD}═══════════════ RINGKASAN ═══════════════${NC}"
  echo
  printf "  ${WHITE}%-20s${NC} : ${MAGENTA}%d${NC}\n" "Login"     "$t_login"
  printf "  ${WHITE}%-20s${NC} : ${RED}%d${NC}\n"     "Admin"     "$t_admin"
  printf "  ${WHITE}%-20s${NC} : ${CYAN}%d${NC}\n"    "Register"  "$t_register"
  printf "  ${WHITE}%-20s${NC} : ${YELLOW}%d${NC}\n"  "Config"    "$t_config"
  printf "  ${WHITE}%-20s${NC} : ${BLUE}%d${NC}\n"    "API"       "$t_api"
  printf "  ${WHITE}%-20s${NC} : ${RED}%d${NC}\n"     "Sensitive" "$t_sensitive"
  printf "  ${WHITE}%-20s${NC} : ${GREEN}%d${NC}\n"   "User"      "$t_user"
  echo -e "  ${GRAY}─────────────────────────${NC}"
  printf "  ${WHITE}${BOLD}%-20s${NC} : ${GREEN}${BOLD}%d${NC}\n" "TOTAL" "$t_total"
  echo
}

# ============ MAIN ============
main() {
  check_deps
  banner
  get_target
  crawl_site

  LOGIN=$(filter_category "$KEYWORD_LOGIN" "$ALL_LINKS")
  ADMIN=$(filter_category "$KEYWORD_ADMIN" "$ALL_LINKS")
  REGISTER=$(filter_category "$KEYWORD_REGISTER" "$ALL_LINKS")
  CONFIG=$(filter_category "$KEYWORD_CONFIG" "$ALL_LINKS")
  API=$(filter_category "$KEYWORD_API" "$ALL_LINKS")
  SENSITIVE=$(filter_category "$KEYWORD_SENSITIVE" "$ALL_LINKS")
  USER=$(filter_category "$KEYWORD_USER" "$ALL_LINKS")

  check_important_status
  show_results
  show_status
  show_summary

  echo -e "${GREEN}${BOLD}✓ Selesai.${NC}\n"
}

main
