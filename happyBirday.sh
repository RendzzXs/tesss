#!/bin/bash

# Slow typing function
type_text() {
    text="$1"
    delay="${2:-0.08}"  # default delay 0.08 seconds
    
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep "$delay"
    done
    echo ""
}

# Clear screen
clear

echo ""
echo ""

# Slow typing messages
type_text "  🎉🎊 Happy Birthday Rendzz Official! 🎊🎉" 0.09
sleep 0.5

type_text "  ✨ Age 18 ✨" 0.08
sleep 0.5

type_text "  📅 Day 17 📅" 0.08
sleep 0.5

type_text "  🗓️ Year 2008 🗓️" 0.08
sleep 0.8

echo ""
type_text "  🥳 Selamat ulang tahun yang ke-18! 🥳" 0.08
sleep 0.4

type_text "  Semoga panjang umur, sehat selalu," 0.07
sleep 0.3

type_text "  dan sukses terus buat Rendzz! 🔥" 0.07
sleep 0.5

type_text "  Nikmati hari spesialmu! 🎂✨" 0.08

echo ""
echo ""
