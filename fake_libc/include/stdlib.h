#ifndef FAKE_STDLIB_H
#define FAKE_STDLIB_H
#include <stddef.h>
/* Minimal stdlib.h for LM-OTS measurement build */
static inline void abort(void) { __builtin_trap(); }
#endif
