AR = /usr/bin/ar
CC = /usr/bin/gcc
CFLAGS = -Wall -O3

all: hss_lib.a \
     hss_lib_thread.a \
     hss_verify.a \
     demo \
     test_hss

hss_lib.a: hss.o hss_alloc.o hss_aux.o hss_common.o \
     hss_compute.o hss_generate.o hss_keygen.o hss_param.o hss_reserve.o \
     hss_sign.o hss_sign_inc.o hss_thread_single.o \
     hss_verify.o hss_verify_inc.o hss_derive.o \
     hss_derive.o hss_zeroize.o lm_common.o \
     lm_ots_common.o lm_ots_sign.o lm_ots_verify.o lm_verify.o endian.o \
     hash.o sha256.o
	$(AR) rcs $@ $^

hss_lib_thread.a: hss.o hss_alloc.o hss_aux.o hss_common.o \
     hss_compute.o hss_generate.o hss_keygen.o hss_param.o hss_reserve.o \
     hss_sign.o hss_sign_inc.o hss_thread_pthread.o \
     hss_verify.o hss_verify_inc.o \
     hss_derive.o hss_zeroize.o lm_common.o \
     lm_ots_common.o lm_ots_sign.o lm_ots_verify.o lm_verify.o endian.o \
     hash.o sha256.o
	$(AR) rcs $@ $^

hss_verify.a: hss_verify.o hss_verify_inc.o hss_common.o hss_thread_single.o \
    hss_zeroize.o lm_common.o lm_ots_common.o lm_ots_verify.o lm_verify.o \
    endian.o hash.o sha256.o
	$(AR) rcs $@ $^

demo: demo.c hss_lib_thread.a
	$(CC) $(CFLAGS) demo.c hss_lib_thread.a -lcrypto -lpthread -o demo

test_1: test_1.c lm_ots_common.o lm_ots_sign.o lm_ots_verify.o  endian.o hash.o sha256.o hss_zeroize.o
	$(CC) $(CFLAGS) -o test_1 test_1.c lm_ots_common.o lm_ots_sign.o lm_ots_verify.o  endian.o hash.o sha256.o hss_zeroize.o -lcrypto

test_hss: test_hss.c test_hss.h test_testvector.c test_stat.c test_keygen.c test_load.c test_sign.c test_sign_inc.c test_verify.c test_verify_inc.c test_keyload.c test_reserve.c test_thread.c test_h25.c hss.h hss_lib_thread.a
	$(CC) $(CFLAGS) test_hss.c test_testvector.c test_stat.c test_keygen.c test_sign.c test_sign_inc.c test_load.c test_verify.c test_verify_inc.c test_keyload.c test_reserve.c test_thread.c test_h25.c hss_lib_thread.a -lcrypto -lpthread -o test_hss

hss.o: hss.c hss.h common_defs.h hash.h endian.h hss_internal.h hss_aux.h hss_derive.h
	$(CC) $(CFLAGS) -c hss.c -o $@

hss_alloc.o: hss_alloc.c hss.h hss_internal.h lm_common.h
	$(CC) $(CFLAGS) -c hss_alloc.c -o $@

hss_aux.o: hss_aux.c hss_aux.h hss_internal.h common_defs.h lm_common.h endian.h hash.h
	$(CC) $(CFLAGS) -c hss_aux.c -o $@

hss_common.o: hss_common.c common_defs.h hss_common.h lm_common.h
	$(CC) $(CFLAGS) -c hss_common.c -o $@

hss_compute.o: hss_compute.c hss_internal.h hash.h hss_thread.h lm_ots_common.h lm_ots.h endian.h hss_derive.h
	$(CC) $(CFLAGS) -c hss_compute.c -o $@

hss_derive.o: hss_derive.c hss_derive.h hss_internal.h hash.h endian.h
	$(CC) $(CFLAGS) -c hss_derive.c -o $@

hss_generate.o: hss_generate.c hss.h hss_internal.h hss_aux.h hash.h hss_thread.h hss_reserve.h lm_ots_common.h endian.h
	$(CC) $(CFLAGS) -c hss_generate.c -o $@

hss_keygen.o: hss_keygen.c hss.h common_defs.h hss_internal.h hss_aux.h endian.h hash.h hss_thread.h lm_common.h lm_ots_common.h
	$(CC) $(CFLAGS) -c hss_keygen.c -o $@

hss_param.o: hss_param.c hss.h hss_internal.h endian.h hss_zeroize.h
	$(CC) $(CFLAGS) -c hss_param.c -o $@

hss_reserve.o: hss_reserve.c common_defs.h hss_internal.h hss_reserve.h endian.h
	$(CC) $(CFLAGS) -c hss_reserve.c -o $@
   
hss_sign.o: hss_sign.c common_defs.h hss.h hash.h endian.h hss_internal.h hss_aux.h hss_thread.h hss_reserve.h lm_ots.h lm_ots_common.h hss_derive.h
	$(CC) $(CFLAGS) -c hss_sign.c -o $@
   
hss_sign_inc.o: hss_sign_inc.c hss.h common_defs.h hss.h hash.h endian.h hss_internal.h hss_aux.h hss_reserve.h hss_derive.h lm_ots.h lm_ots_common.h hss_sign_inc.h
	$(CC) $(CFLAGS) -c hss_sign_inc.c -o $@

hss_thread_single.o: hss_thread_single.c hss_thread.h
	$(CC) $(CFLAGS) -c hss_thread_single.c -o $@

hss_thread_pthread.o: hss_thread_pthread.c hss_thread.h
	$(CC) $(CFLAGS) -c hss_thread_pthread.c -o $@

hss_verify.o: hss_verify.c hss_verify.h common_defs.h lm_verify.h lm_common.h lm_ots_verify.h hash.h endian.h hss_thread.h
	$(CC) $(CFLAGS) -c hss_verify.c -o $@

hss_verify_inc.o: hss_verify_inc.c hss_verify_inc.h common_defs.h lm_verify.h lm_common.h lm_ots_verify.h hash.h endian.h hss_thread.h
	$(CC) $(CFLAGS) -c hss_verify_inc.c -o $@

hss_zeroize.o: hss_zeroize.c hss_zeroize.h
	$(CC) $(CFLAGS) -c hss_zeroize.c -o $@

lm_common.o: lm_common.c lm_common.h hash.h common_defs.h lm_ots_common.h
	$(CC) $(CFLAGS) -c lm_common.c -o $@

lm_ots_common.o: lm_ots_common.c common_defs.h hash.h
	$(CC) $(CFLAGS) -c lm_ots_common.c -o $@

lm_ots_sign.o: lm_ots_sign.c common_defs.h lm_ots.h lm_ots_common.h hash.h endian.h hss_zeroize.h hss_derive.h
	$(CC) $(CFLAGS) -c lm_ots_sign.c -o $@

lm_ots_verify.o: lm_ots_verify.c lm_ots_verify.h lm_ots_common.h hash.h endian.h common_defs.h
	$(CC) $(CFLAGS) -c lm_ots_verify.c -o $@

lm_verify.o: lm_verify.c lm_verify.h lm_common.h lm_ots_common.h lm_ots_verify.h hash.h endian.h common_defs.h
	$(CC) $(CFLAGS) -c lm_verify.c -o $@

endian.o: endian.c endian.h
	$(CC) $(CFLAGS) -c endian.c -o $@

hash.o: hash.c hash.h sha256.h hss_zeroize.h
	$(CC) $(CFLAGS) -c hash.c -o $@

sha256.o: sha256.c sha256.h endian.h
	$(CC) $(CFLAGS) -c sha256.c -o $@

clean:
	-rm *.o *.a demo test_hss

.PHONY: asm_x86_fake asm_riscv_fake asm_wasm_fake \
        asm_x86_real asm_riscv_real asm_wasm_real \
        asm_fake asm_real update_asm_results

ASM_CFLAGS = -nostdinc -I fake_libc/include -I .
ASM_OPT    = -Oz
FAKE_FLAGS = -DFAKE_HASH -include fake_hash.h
REAL_FLAGS = -DEXT_SHA256_H=\"fake_libc/include/sha256.h\"

TARGET_wasm = --target=wasm32

TARGET_x86   = -target x86_64-linux-gnu
TARGET_riscv = --target=riscv64 -march=rv64gc -mabi=lp64

define compile_asm
clang $(1) $(ASM_CFLAGS) $(2) $(ASM_OPT) -S lm_ots_verify.c -o $(3).s
clang $(1) $(ASM_CFLAGS) $(2) $(ASM_OPT) -c lm_ots_verify.c -o $(3).o
	llvm-objcopy-19 -O binary --only-section=.text $(3).o $(3).bin
endef

WASM_LD ?= wasm-ld-19
define compile_wasm
clang $(TARGET_wasm) $(ASM_CFLAGS) $(1) $(ASM_OPT) -S lm_ots_verify.c -o $(2).s
clang $(TARGET_wasm) $(ASM_CFLAGS) $(1) $(ASM_OPT) -c lm_ots_verify.c -o $(2).o
$(WASM_LD) --allow-undefined --no-entry \
        --export=lm_ots_validate_signature_compute $(2).o -o $(2).wasm
        llvm-objdump-19 -d $(2).wasm > $(2).wat
endef

asm_x86_fake:
	$(call compile_asm,$(TARGET_x86),$(FAKE_FLAGS),lm_ots_validate_signature_compute_x86)

asm_riscv_fake:
	$(call compile_asm,$(TARGET_riscv),$(FAKE_FLAGS),lm_ots_validate_signature_compute_riscv)

asm_x86_real:
	$(call compile_asm,$(TARGET_x86),$(REAL_FLAGS),lm_ots_validate_signature_compute_x86_real)

asm_riscv_real:
	$(call compile_asm,$(TARGET_riscv),$(REAL_FLAGS),lm_ots_validate_signature_compute_riscv_real)

asm_wasm_fake:
	$(call compile_wasm,$(FAKE_FLAGS),lm_ots_validate_signature_compute_wasm)

asm_wasm_real:
	$(call compile_wasm,$(REAL_FLAGS),lm_ots_validate_signature_compute_wasm_real)

asm_fake: asm_x86_fake asm_riscv_fake asm_wasm_fake
	
asm_real: asm_x86_real asm_riscv_real asm_wasm_real

	# Reproduce assembly outputs and collect their sizes.  This target
# runs all four build variants and writes a summary to asm_results.txt.
update_asm_results: asm_fake asm_real
	@rm -f asm_results.txt
	@printf "target variant text asm bin wat\n" > asm_results.txt
	@for f in x86 x86_real riscv riscv_real wasm wasm_real; do \
	case $$f in \
	*wasm*) \
	t=$$(llvm-size-19 -A lm_ots_validate_signature_compute_$$f.wasm | awk '/CODE/{print $$2}'); \
	a=$$(wc -c < lm_ots_validate_signature_compute_$$f.s); \
	b=$$(wc -c < lm_ots_validate_signature_compute_$$f.wasm); \
	w=$$(wc -c < lm_ots_validate_signature_compute_$$f.wat); \
	echo "$$f $$t $$a $$b $$w" >> asm_results.txt ;; \
	*) \
	t=$$(llvm-size-19 -A lm_ots_validate_signature_compute_$$f.o | awk '/\.text/{print $$2}'); \
	a=$$(wc -c < lm_ots_validate_signature_compute_$$f.s); \
	b=$$(wc -c < lm_ots_validate_signature_compute_$$f.bin); \
	echo "$$f $$t $$a $$b -" >> asm_results.txt ;; \
	esac; \
	done
	-rm -f lm_ots_validate_signature_compute_*.o
