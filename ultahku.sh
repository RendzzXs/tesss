#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GOLD='\033[38;5;220m'
NC='\033[0m' # No Color

# Slow typing function with color
type_text() {
    text="$1"
    color="${2:-$WHITE}"
    delay="${3:-0.08}"
    
    echo -ne "$color"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo -e "$NC"
}

# Clear screen
clear

echo ""
echo ""

# Border Atas
echo -e "${GOLD}[----------------------------------------------------------------------]${NC}"
echo -e "${GOLD}|                                                                      |${NC}"

# Main title
type_text "  🎉🎊✨ HAPPY BIRTHDAY RENDZZ OFFICIAL! ✨🎊🎉" "\033[38;5;214m" 0.09
sleep 0.3

type_text "  ============================================" "\033[38;5;208m" 0.06
sleep 0.3

echo -e "${GOLD}|                                                                      |${NC}"

# Info
type_text "  👤  Name     : Rendzz Official" "${CYAN}" 0.07
sleep 0.2
type_text "  🎂  Age      : 18 Years Old" "${GREEN}" 0.07
sleep 0.2
type_text "  📅  Day      : 17" "${YELLOW}" 0.07
sleep 0.2
type_text "  🗓️  Year     : 2008" "${PURPLE}" 0.07
sleep 0.2

echo -e "${GOLD}|                                                                      |${NC}"

# Wishes in Indonesian
type_text "  🌟 Selamat ulang tahun yang ke-18! 🌟" "\033[38;5;212m" 0.08
sleep 0.3
type_text "  🎯 Semoga jadi pribadi yang lebih baik," "\033[38;5;219m" 0.07
sleep 0.2
type_text "  💪 sehat selalu, dan makin sukses!" "\033[38;5;225m" 0.07
sleep 0.2
type_text "  🚀 Terus berkarya dan berprestasi!" "\033[38;5;195m" 0.07
sleep 0.2

echo -e "${GOLD}|                                                                      |${NC}"

# SPONSORS SECTION
type_text "  🤝 SPONSORED BY :" "\033[38;5;226m" 0.06
sleep 0.3

echo -e "${GOLD}|                                                                      |${NC}"

type_text "    🔷 Meta AI" "\033[38;5;39m" 0.05
sleep 0.15
type_text "    🔷 DeepSeek" "\033[38;5;51m" 0.05
sleep 0.15
type_text "    🔷 OpenAI" "\033[38;5;46m" 0.05
sleep 0.15
type_text "    🔷 Akamai Cloud" "\033[38;5;196m" 0.05
sleep 0.15
type_text "    🔷 Google Cloud" "\033[38;5;33m" 0.05
sleep 0.15
type_text "    🔷 Microsoft Azure" "\033[38;5;27m" 0.05
sleep 0.15
type_text "    🔷 Amazon Web Services" "\033[38;5;214m" 0.05
sleep 0.15
type_text "    🔷 Dan Lain-lain 🌐" "\033[38;5;205m" 0.05
sleep 0.2

echo -e "${GOLD}|                                                                      |${NC}"

# Closing
type_text "  🙌 Terima kasih untuk semua dukungannya! 🙌" "\033[38;5;155m" 0.08
sleep 0.3
type_text "  🎂 Nikmati harimu, Rendzz! 🥳" "\033[38;5;220m" 0.08
sleep 0.3

echo -e "${GOLD}|                                                                      |${NC}"
echo -e "${GOLD}[----------------------------------------------------------------------]${NC}"

echo ""
