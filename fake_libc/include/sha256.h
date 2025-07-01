typedef struct {
  unsigned long int h[8];
  unsigned long Nl, Nh;
  unsigned num;
  unsigned char data[64];
} SHA256_CTX;

void SHA256_Init(SHA256_CTX *);
void SHA256_Update(SHA256_CTX *, const void *, unsigned int);
void SHA256_Final(unsigned char *, SHA256_CTX *);

#ifndef SHA256_LEN
#define SHA256_LEN 32
#endif
