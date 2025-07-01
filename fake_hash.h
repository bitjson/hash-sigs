#ifndef FAKE_HASH_H
#define FAKE_HASH_H

#include <stdint.h>
#include <stddef.h>

/* minimal definitions to satisfy lm_ots_verify.c */
#define HASH_SHA256 1

typedef struct {
    unsigned long int h[8];
    unsigned long Nl, Nh;
    unsigned num;
    unsigned char data[64];
} SHA256_CTX;

union hash_context {
    SHA256_CTX sha256;
};

#define hss_hash_length(t) 32
#define hss_hash_blocksize(t) 64

#define hss_hash(result, type, message, len) \
    do { \
        (void)(type); \
        ((uint8_t *)(result))[0] = ((len) ? ((const uint8_t *)(message))[0] : 0) ^ 1; \
    } while (0)

#define hss_hash_ctx(result, type, ctx, message, len) \
    hss_hash(result, type, message, len)

#define hss_init_hash_context(h, ctx) \
    do { \
        (void)(h); \
        ((uint8_t *)(ctx))[0] = 0; \
    } while (0)

#define hss_update_hash_context(h, ctx, msg, len) \
    do { \
        (void)(h); \
        if ((len) > 0) \
            ((uint8_t *)(ctx))[0] ^= ((const uint8_t *)(msg))[0]; \
    } while (0)

#define hss_finalize_hash_context(h, ctx, buffer) \
    do { \
        (void)(h); \
        ((uint8_t *)(buffer))[0] = ((uint8_t *)(ctx))[0]; \
    } while (0)

#endif /* FAKE_HASH_H */
