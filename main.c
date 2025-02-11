#include <stdint.h>
#include <stdio.h>

extern uint32_t base64_encode(uint32_t n, uint32_t text);

FILE *inptr, *outptr;

int main(int argc, char* argv[]) {
  if (argc != 3) {
    printf("You need to pass a input and output file to this executable.\n");
    printf("e.g. ./bin test.txt out.txt\n");
    return 1;
  }

  inptr = fopen(argv[1], "rb");
  outptr = fopen(argv[2], "w");

  int n_read;
  char value[3];
  while ((n_read = fread(value, sizeof(char), 3, inptr))) {
    uint32_t text = value[2] << 16 | value[1] << 8 | value[0];

    uint32_t encoded = base64_encode(n_read, text);
    // char* c = (char*)&encoded;
    printf("%c, %c, %c, %c\n", ((char*)&encoded)[0], ((char*)&encoded)[1], ((char*)&encoded)[2], ((char*)&encoded)[3]);

    fwrite(&encoded, sizeof(char), 4, outptr);
  }

  // printf("%d\n", base64_encode(10));
  // printf("%d\n", base64_encode(20));
  // printf("%d\n", base64_encode(1));
  
  return 0;
}
