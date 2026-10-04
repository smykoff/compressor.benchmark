#!/usr/bin/env bash
# Сравнение компрессоров: сжатие (время + размер) и распаковка (время).
# Дефолты инструментов: gzip -6; pigz -6 (все ядра); xz -6 (все ядра); zstd -3; lz4 -1.
set -e

EXTRACT=.extract

compress() { # compress <label> <archive> [plain|compress-program ...]
  local label=$1 f=$2; shift 2
  local t=$(date +%s%N)
  if [ "${1:-}" = plain ]; then tar -cf "$f" -C .data .
  elif [ "$#" -gt 0 ]; then tar -I "$*" -cf "$f" -C .data .
  else tar -caf "$f" -C .data .; fi
  printf 'C  %-16s %8d ms  %12d bytes\n' "$label" \
    "$(( ($(date +%s%N) - t) / 1000000 ))" \
    "$(stat -c%s "$f")"
}

extract() { # extract <label> <archive> [plain|decompress-program ...]
  local label=$1 f=$2; shift 2
  rm -rf "$EXTRACT"; mkdir "$EXTRACT"
  local t=$(date +%s%N)
  if [ "${1:-}" = plain ]; then tar -xf "$f" -C "$EXTRACT"
  elif [ "$#" -gt 0 ]; then tar -I "$*" -xf "$f" -C "$EXTRACT"
  else tar -xaf "$f" -C "$EXTRACT"; fi
  printf 'X  %-16s %8d ms  (на диск)\n' "$label" "$(( ($(date +%s%N) - t) / 1000000 ))"
  rm -rf "$EXTRACT"
}

decomp() { # decomp <label> <archive> [plain|decompress-program ...]
  local label=$1 f=$2; shift 2
  local t=$(date +%s%N)
  if [ "${1:-}" = plain ]; then tar -xOf "$f" > /dev/null
  elif [ "$#" -gt 0 ]; then tar -I "$*" -xOf "$f" > /dev/null
  else tar -xaf "$f" -O > /dev/null; fi
  printf 'D  %-16s %8d ms  (в поток)\n' "$label" "$(( ($(date +%s%N) - t) / 1000000 ))"
}

echo '== сжатие =='
compress 'baseline (tar)' archive.tar plain
compress 'gzip (default)'  archive.tar.gz
compress 'pigz'            archive.pigz.tar.gz 'pigz'
compress 'xz (default)'    archive.tar.xz
compress 'zstd (default)'  archive.tar.zst
compress 'lz4'             archive.tar.lz4    'lz4'
compress 'zstd -6'          archive.6.tar.zst  'zstd -6'
compress 'zstd -9'          archive.9.tar.zst  'zstd -9'
compress 'zstd -12'         archive.12.tar.zst 'zstd -12'

echo '== распаковка =='
extract 'baseline (tar)' archive.tar plain
extract 'gzip'  archive.tar.gz
extract 'pigz'  archive.pigz.tar.gz 'pigz'
extract 'xz'    archive.tar.xz
extract 'zstd'  archive.tar.zst
extract 'lz4'   archive.tar.lz4 'lz4'

echo '== распаковка без записи на диск (чистая скорость кодека) =='
decomp 'baseline (tar)' archive.tar plain
decomp 'gzip'  archive.tar.gz
decomp 'pigz'  archive.pigz.tar.gz 'pigz'
decomp 'xz'    archive.tar.xz
decomp 'zstd'  archive.tar.zst
decomp 'lz4'   archive.tar.lz4 'lz4'
