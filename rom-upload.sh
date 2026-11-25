#!/usr/bin/env bash
#
# Anshuman - Upload Files
#

echo " "
echo "======================================"
echo "       Anshuman - File Uploader        "
echo "======================================"
echo "[1] Github Release [gh auth login]
[2] Devuploads [Key]
[3] pixeldrain [Key]
[4] Temp.sh
[5] Gofile
[6] oshi.at
[7] Sourceforge [Key]
[8] VexFiles [Key] [File Url]
[9] BuzzHeavier
"
read -p "Please enter your number: " UP
if [ "$UP" == 8 ]; then
  read -p "Please enter uploaded file link: " URL
else
  read -p "Please enter file path/name: " FP
fi

read_secret() {
  echo -n "$1"
  KEY=""
  while IFS= read -r -s -n1 c; do
    [[ $c == $'\n' || $c == $'\0' ]] && echo && break
    [[ $c == $'\177' ]] && KEY="${KEY%?}" && echo -ne "\b \b" || { KEY+="$c"; echo -n "*"; }
  done
}

if [ "$UP" == 1 ]; then
  read -p "Please enter github repo link: " GH
  FN="$(basename "$FP")" && FN="${FN%%.*}"
  echo -e "Started uploading file on github..."
  gh release create "$FN" --generate-notes --repo "$GH"
  gh release upload --clobber "$FN" "$FP" --repo "$GH"
fi

if [ "$UP" == 2 ]; then
  read_secret "Please enter devupload key: "
  echo "Started uploading file on DevUploads..."
  bash <(curl -s https://devuploads.com/upload.sh) -f "$FP" -k "$KEY"
fi

if [ "$UP" == 3 ]; then
  read_secret "Please enter Pixel Drain key: "
  echo "Started uploading file on PixelDrain..."
  curl -T "$FP" -u ":$KEY" https://pixeldrain.com/api/file/
fi

if [ "$UP" == 4 ]; then
  echo -e "Started uploading file on Temp..."
  curl -T "$FP" temp.sh
fi

if [ "$UP" == 5 ]; then
  echo -e "Started uploading file on Gofile..."
  SERVER=$(curl -X GET 'https://api.gofile.io/servers' | grep -Po '(store*)[^"]*' | tail -n 1)
  curl -X POST "https://${SERVER}.gofile.io/contents/uploadfile" -F "file=@$FP" | grep -Po '(https://gofile.io/d/)[^"]*'
fi

if [ "$UP" == 6 ]; then
  echo -e "Started uploading file on Oshi.at..."
  curl -T "$FP" https://oshi.at
fi

if [ "$UP" == 7 ]; then
  echo -e "Started uploading file on Sourceforge..."
  read -p "Please enter Username: " USER
  read -p "Please enter upload location:
Note: Path after /home/frs/project/" UPL
  scp "$FP" "$USER"@frs.sourceforge.net:/home/frs/project/"$UPL"
fi

if [ "$UP" == 8 ]; then
  read_secret "Please enter Vex files API key: "
  echo "Started uploading file on VexFiles..."
  curl -X POST https://vexfile.com/api/upload/handle \
    -H "Content-Type: application/json" \
    -d "{
      \"token\": \"$KEY\",
      \"url\": \"$URL\"
    }"
fi

if [ "$UP" == 9 ]; then
  echo -e "Started uploading file on BuzzHeavier..."
  FN="$(basename "$FP")"
  SHA256=$(sha256sum "$FP" | awk '{print $1}')
  NOTE_B64=$(printf '%s' "SHA-256: $SHA256" | base64 | tr -d '\n')
  RESP=$(curl -# -T "$FP" "https://w.buzzheavier.com/${FN}?note=${NOTE_B64}")
  ID=$(printf '%s\n' "$RESP" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')
  echo ""
  if [ -n "$ID" ]; then
    echo "Download Link: https://buzzheavier.com/${ID}"
    echo "SHA-256: $SHA256"
  else
    echo "$RESP"
  fi
fi

echo " "
echo "Powered by Anshuman"
