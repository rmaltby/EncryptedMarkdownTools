#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 [-i input_file] [-o output_file] [-p passphrase] [-c (use clipboard)]"
  exit 1
}

INPUT=""
OUTPUT=""
CLIPBOARD=false
PASSPHRASE=""

while getopts ":i:o:p:c" opt; do
  case $opt in
    i) INPUT="$OPTARG" ;;
    o) OUTPUT="$OPTARG" ;;
    p) PASSPHRASE="$OPTARG" ;;
    c) CLIPBOARD=true ;;
    *) usage ;;
  esac
done

if [[ -z "$PASSPHRASE" ]]; then
  echo "Passphrase required (-p)"
  usage
fi

if $CLIPBOARD; then
  if command -v xclip &>/dev/null; then
    INPUT_TEXT=$(xclip -selection clipboard -o)
  elif command -v powershell.exe &>/dev/null; then
    INPUT_TEXT=$(powershell.exe Get-Clipboard -Raw)
  else
    echo "Clipboard access not supported on this platform"
    exit 1
  fi
elif [[ -n "$INPUT" ]]; then
  INPUT_TEXT=$(<"$INPUT")
else
  echo "No input source specified"
  usage
fi

ENCRYPTED=$(echo "$INPUT_TEXT" | openssl enc -aes-256-cbc -a -salt -pass pass:"$PASSPHRASE")

if [[ -n "$OUTPUT" ]]; then
  echo "$ENCRYPTED" > "$OUTPUT"
elif $CLIPBOARD; then
  if command -v xclip &>/dev/null; then
    echo "$ENCRYPTED" | xclip -selection clipboard
  elif command -v clip &>/dev/null; then
    echo "$ENCRYPTED" | clip
  else
    echo "Clipboard write not supported"
    exit 1
  fi
else
  echo "$ENCRYPTED"
fi