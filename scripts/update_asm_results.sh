#!/bin/sh
set -e

LLVM_VERSION=${LLVM_VERSION:-18}
CLANG=${CLANG:-clang-${LLVM_VERSION}}
LLVM_OBJCOPY=${LLVM_OBJCOPY:-llvm-objcopy-${LLVM_VERSION}}
LLVM_OBJDUMP=${LLVM_OBJDUMP:-llvm-objdump-${LLVM_VERSION}}
LLVM_SIZE=${LLVM_SIZE:-llvm-size-${LLVM_VERSION}}
WASM_LD=${WASM_LD:-wasm-ld-${LLVM_VERSION}}

# Aggressive size CFLAGS (applies to all targets)
SIZE_CFLAGS="-Oz -ffunction-sections -fdata-sections \
  -ffreestanding -fno-builtin -fno-builtin-memcpy -fno-builtin-memset \
  -fomit-frame-pointer -fno-stack-protector -fno-unwind-tables -fno-asynchronous-unwind-tables \
  -fno-pic -fno-pie -g0 \
  -mllvm -align-all-functions=1 -mllvm -align-all-blocks=1 \
  -fno-vectorize -fno-slp-vectorize -fno-unroll-loops"

ASM_CFLAGS="-nostdinc -I fake_libc/include -I . ${SIZE_CFLAGS}"
ASM_OPT=""  # already included in SIZE_CFLAGS

FAKE_FLAGS="-DFAKE_HASH -include fake_hash.h"
REAL_FLAGS="-DEXT_SHA256_H=\"fake_libc/include/sha256.h\""

TARGET_x86_64="--target=x86_64-linux-gnu"
TARGET_x86_32="--target=i386-pc-linux-gnu"

TARGET_rv64="--target=riscv64 -march=rv64gc -mabi=lp64"
TARGET_rv32="--target=riscv32 -march=rv32gc -mabi=ilp32"

TARGET_aarch64="--target=aarch64-linux-gnu"
TARGET_mips64="--target=mips64el -mabi=64"

TARGET_wasm32="--target=wasm32"
# wasm64 is optional; only build if toolchain supports it (it’s usually larger)
TARGET_wasm64="--target=wasm64"

# Notes on code size:
# - wasm32 is generally smaller than wasm64; we build wasm64 only if supported to confirm.
# - rv32 (ILP32) can be smaller than rv64 (LP64) for pointer-heavy code; we build both.
# - x86 32-bit can be smaller than x86_64 due to shorter encodings; we build both.
# The min-only summary (asm_min.csv) identifies the absolute smallest per function.

# Build matrix – prioritize variants likely to be smallest
TARGETS="x86_32 x86_64 rv32 rv64 aarch64 mips64 wasm32 wasm64"

FUNCTIONS='lm_ots_generate_public_key lm_ots_generate_signature lm_ots_validate_signature_compute'
SRC_lm_ots_generate_public_key="lm_ots_sign.c"
SRC_lm_ots_generate_signature="lm_ots_sign.c"
SRC_lm_ots_validate_signature_compute="lm_ots_verify.c"

rm -f asm_results.txt asm_results.csv asm_min.csv
# Write CSV header
printf "function target variant text asm bin wat inst\n" > asm_results.txt
printf "function,target,variant,text,asm,bin,wat,inst\n" > asm_results.csv

build() {
  fn=$1 tgt=$2 variant=$3 src=$4 flags=$5 target_flags=$6
  base="${fn}_${tgt}_${variant}"
  $CLANG $target_flags $ASM_CFLAGS $flags $ASM_OPT -S $src -o $base.s
  $CLANG $target_flags $ASM_CFLAGS $flags $ASM_OPT -c $src -o $base.o
  if [ "$tgt" = wasm32 ] || [ "$tgt" = wasm64 ]; then
    wasm_mode=""
    if [ "$tgt" = wasm64 ]; then
      wasm_mode="-mwasm64"
    fi
    $WASM_LD $wasm_mode --allow-undefined --no-entry --gc-sections --strip-all \
      --initial-memory=131072 --max-memory=131072 \
      --export=$fn $base.o -o $base.tmp.wasm
    $LLVM_OBJCOPY --strip-all $base.tmp.wasm $base.tmp2.wasm && mv $base.tmp2.wasm $base.tmp.wasm
    if command -v wasm-opt >/dev/null 2>&1; then
      wasm-opt -Oz --strip-dwarf --strip-debug --strip-producers --strip \
        --dce --vacuum $base.tmp.wasm -o $base.tmp2.wasm
      mv $base.tmp2.wasm $base.wasm
    else
      mv $base.tmp.wasm $base.wasm
    fi
    $LLVM_OBJDUMP -d $base.wasm > $base.wat
    t=$($LLVM_SIZE -A $base.wasm | awk '/CODE/{print $2}')
    a=$(wc -c < $base.s)
    b=$(wc -c < $base.wasm)
    w=$(wc -c < $base.wat)
    i=$($LLVM_OBJDUMP -d $base.wasm | grep -E '^[[:space:]]+[0-9a-f]+:' | wc -l)
  else
    $LLVM_OBJCOPY -O binary --only-section=.text.$fn $base.o $base.bin
    t=$($LLVM_SIZE -A $base.o | awk -v sec=.text.$fn '$1==sec {print $2}')
    a=$(wc -c < $base.s)
    b=$(wc -c < $base.bin)
    w="-"
    i=$($LLVM_OBJDUMP -d -j .text.$fn $base.o | grep -E '^[[:space:]]+[0-9a-f]+:' | wc -l)
  fi
  echo "$fn $tgt $variant $t $a $b $w $i" >> asm_results.txt
  echo "$fn,$tgt,$variant,$t,$a,$b,$w,$i" >> asm_results.csv
}

for fn in $FUNCTIONS; do
  src_var="SRC_${fn}"
  src=$(eval echo \${$src_var})
  for tgt in $TARGETS; do
    case $tgt in
      x86_32)   target="$TARGET_x86_32" ;;
      x86_64)   target="$TARGET_x86_64" ;;
      rv32)     target="$TARGET_rv32" ;;
      rv64)     target="$TARGET_rv64" ;;
      aarch64)  target="$TARGET_aarch64" ;;
      mips64)   target="$TARGET_mips64" ;;
      wasm32)   target="$TARGET_wasm32" ;;
      wasm64)   target="$TARGET_wasm64" ;;
    esac
    if [ "$tgt" = "wasm64" ]; then
      if ! printf 'int x;\n' | $CLANG $target -xc - -c -o /dev/null >/dev/null 2>&1; then
        continue
      fi
    fi
    for v in fake real; do
      case $v in
        fake) flags="$FAKE_FLAGS" ;;
        real) flags="$REAL_FLAGS" ;;
      esac
      build "$fn" "$tgt" "$v" "$src" "$flags" "$target"
    done
  done
done

awk -F, 'NR==1{next} {k=$1; if(!(k in min) || $6+0 < min[k]){min[k]=$6; row[k]=$0}} END{print "function,target,variant,text,asm,bin,wat,inst"; for(k in row) print row[k]}' asm_results.csv | sort -t, -k1,1 > asm_min.csv

rm -f *.o
