#!/usr/bin/env bash
set -euo pipefail

# ==========================================
#  Anshuman's Universal ROM Uploader
#  Powered by BuzzHeavier
# ==========================================

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

clear
echo -e "${CYAN}${BOLD}"
cat <<'EOF'
    _                _                                  
   / \   _ __  ___| |__  _   _ _ __ ___   __ _ _ __     
  / _ \ | '_ \/ __| '_ \| | | | '_ ` _ \ / _` | '_ \    
 / ___ \| | | \__ \ | | | |_| | | | | | | (_| | | | |   
/_/   \_\_| |_|___/_| |_|\__,_|_| |_| |_|\__,_|_| |_|   
                                                        
        :: Anshuman's Universal ROM Uploader ::         
EOF
echo -e "${NC}"

read -r -p "$(echo -e "${YELLOW}Paste ROM path (target/device or .zip file):${NC} ")" target
target="${target//\"/}"
target="${target//\'/}"
target="${target/#\~/$HOME}"

if [[ -z "$target" ]]; then
  echo -e "${RED}[!] No path provided.${NC}" >&2
  exit 1
fi

if [[ -d "$target" ]]; then
  zip=$(find "$target" -maxdepth 2 -type f -name '*.zip' ! -name '*-ota-*.zip' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)
  [[ -z "$zip" ]] && zip=$(find "$target" -maxdepth 2 -type f -name '*.zip' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-)
elif [[ -f "$target" ]]; then
  zip="$target"
else
  echo -e "${RED}[!] Invalid file or folder: $target${NC}" >&2
  exit 1
fi

if [[ -z "${zip:-}" || ! -f "$zip" ]]; then
  echo -e "${RED}[!] No .zip file found.${NC}" >&2
  exit 1
fi

filename=$(basename "$zip")
filesize=$(du -h "$zip" | cut -f1)
sha256=$(sha256sum "$zip" | awk '{print $1}')

# Derive target and device cleanly from path
rel_path="${zip#out/target/product/}"
if [[ "$rel_path" != "$zip" ]]; then
  device=$(printf '%s\n' "$rel_path" | cut -d'/' -f1)
  build_target="out/target/product/${device}"
else
  parent_dir=$(dirname "$zip")
  device=$(basename "$parent_dir")
  build_target="$parent_dir"
fi

echo -e "\n${BOLD}File   :${NC} $filename ($filesize)"
echo -e "${CYAN}[*] Uploading to BuzzHeavier...${NC}\n"

note_b64=$(printf '%s' "SHA-256: $sha256" | base64 | tr -d '\n')
resp=$(curl -# -T "$zip" "https://w.buzzheavier.com/${filename}?note=${note_b64}")
id=$(printf '%s\n' "$resp" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

echo ""
if [[ -n "$id" ]]; then
  echo -e "${GREEN}${BOLD}[✓] Upload Complete!${NC}"
  echo -e "${BOLD}Download Link :${NC} ${CYAN}https://buzzheavier.com/${id}${NC}"
  echo -e "${BOLD}SHA-256       :${NC} $sha256"
  echo -e "${BOLD}Target        :${NC} $build_target"
  echo -e "${BOLD}Device        :${NC} $device"
else
  echo -e "${YELLOW}[!] Upload finished, raw response:${NC} $resp"
fi
