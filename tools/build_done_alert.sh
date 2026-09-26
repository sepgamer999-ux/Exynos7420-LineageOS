#!/bin/bash
SOUND="$HOME/los22/alarm.mp3"

if [ ! -f "$SOUND" ]; then
  echo "الملف غير موجود: $SOUND"
  exit 1
fi

trap 'echo ""; echo "تم الإيقاف."; exit 0' SIGINT

if command -v mpg123 >/dev/null 2>&1; then
  echo "يشغّل عبر mpg123 (تكرار لا نهائي)..."
  mpg123 --loop -1 "$SOUND"
elif command -v ffplay >/dev/null 2>&1; then
  echo "يشغّل عبر ffplay (تكرار لا نهائي)..."
  ffplay -nodisp -autoexit -loop 0 "$SOUND" -loglevel quiet
elif command -v cvlc >/dev/null 2>&1; then
  echo "يشغّل عبر cvlc (تكرار لا نهائي)..."
  cvlc --loop "$SOUND" --play-and-exit
else
  echo "لا يوجد مشغل mp3 مثبت. ثبّت أحدها:"
  echo "sudo dnf install mpg123"
  exit 1
fi
