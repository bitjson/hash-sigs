#ifndef FAKE_STRING_H
#define FAKE_STRING_H
typedef __SIZE_TYPE__ size_t;
void *memcpy(void *dest, const void *src, size_t n);
void *memset(void *s, int c, size_t n);
#endif
