#!/bin/sh
set -e

LLVM_VERSION=${LLVM_VERSION:-18}
CLANG=${CLANG:-clang-${LLVM_VERSION}}
LLVM_OBJCOPY=${LLVM_OBJCOPY:-llvm-objcopy-${LLVM_VERSION}}
LLVM_OBJDUMP=${LLVM_OBJDUMP:-llvm-objdump-${LLVM_VERSION}}
LLVM_SIZE=${LLVM_SIZE:-llvm-size-${LLVM_VERSION}}
WASM_LD=${WASM_LD:-wasm-ld-${LLVM_VERSION}}

ASM_CFLAGS="-nostdinc -I fake_libc/include -I ."
ASM_OPT="-Oz -ffunction-sections -fdata-sections"
FAKE_FLAGS="-DFAKE_HASH -include fake_hash.h"
REAL_FLAGS="-DEXT_SHA256_H=\"fake_libc/include/sha256.h\""

TARGET_x86="--target=x86_64-linux-gnu"
TARGET_riscv="--target=riscv64 -march=rv64gc -mabi=lp64"
TARGET_wasm="--target=wasm32"
TARGET_aarch64="--target=aarch64-linux-gnu"
TARGET_mips="--target=mips64el -mabi=64"
TARGETS="x86 riscv wasm aarch64 mips"

FUNCTIONS='lm_ots_generate_public_key lm_ots_generate_signature lm_ots_validate_signature_compute'
SRC_lm_ots_generate_public_key="lm_ots_sign.c"
SRC_lm_ots_generate_signature="lm_ots_sign.c"
SRC_lm_ots_validate_signature_compute="lm_ots_verify.c"

rm -f asm_results.txt asm_results.csv
printf "function target variant text asm bin wat inst\n" > asm_results.txt
printf "function,target,variant,text,asm,bin,wat,inst\n" > asm_results.csv

build() {
  fn=$1 tgt=$2 variant=$3 src=$4 flags=$5 target_flags=$6
  base="${fn}_${tgt}_${variant}"
  $CLANG $target_flags $ASM_CFLAGS $flags $ASM_OPT -S $src -o $base.s
  $CLANG $target_flags $ASM_CFLAGS $flags $ASM_OPT -c $src -o $base.o
  if [ "$tgt" = wasm ]; then
    $WASM_LD --allow-undefined --no-entry --gc-sections --strip-all --export=$fn $base.o -o $base.tmp.wasm
    $LLVM_OBJCOPY --strip-all $base.tmp.wasm $base.tmp2.wasm && mv $base.tmp2.wasm $base.tmp.wasm
    if command -v wasm-opt >/dev/null 2>&1; then
      wasm-opt -Oz --strip-dwarf --strip-debug --strip-producers --strip $base.tmp.wasm -o $base.tmp2.wasm
      mv $base.tmp2.wasm $base.tmp.wasm
    fi
    if command -v wasm-strip >/dev/null 2>&1; then
      wasm-strip $base.tmp.wasm -o $base.wasm
      rm -f $base.tmp.wasm
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
    target_var="TARGET_${tgt}"
    target=$(eval echo \${$target_var})
    for v in fake real; do
      case $v in
        fake) flags="$FAKE_FLAGS" ;;
        real) flags="$REAL_FLAGS" ;;
      esac
      build "$fn" "$tgt" "$v" "$src" "$flags" "$target"
    done
  done
done

rm -f *.o
