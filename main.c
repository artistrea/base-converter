#include <stdint.h>
#include <stdio.h>
#include <string.h>

#define NEWLINE_SPACING 76

__attribute__((cdecl))
extern uint32_t base64_encode(uint32_t n, uint32_t text);

FILE *inptr, *outptr;

int little_endian_arch() {
  int t=1;
  return *((char*)&t) == 0x1;
}


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
  int is_little_endian_arch = little_endian_arch();

  memset(value, 0, 3);
  const int newline_loop_n = NEWLINE_SPACING / 4;
  int loop_count=0;
  char *newline = "\r\n";

  while ((n_read = fread(value, sizeof(char), 3, inptr))) {
    uint32_t text = (value[0] & 0xff) << 16 | (value[1] & 0xff) << 8 | (value[2] & 0xff);

    // returns encoded in big endian order
    uint32_t encoded = base64_encode(n_read, text);
    // // char* c = (char*)&encoded;
    // printf("nread: %d\n", n_read);
    // printf("in: %d, %d, %d\n", value[0], value[1], value[2]);
    // printf("inn: %016b\n", encoded);

    if (is_little_endian_arch) {
      encoded = ((encoded >> 24) & 0xff) |      // move byte 3 to byte 0
                ((encoded << 8) & 0xff0000) |   // move byte 1 to byte 2
                ((encoded >> 8) & 0xff00) |     // move byte 2 to byte 1
                ((encoded << 24) & 0xff000000); // byte 0 to byte 3
    }
    // printf("out: %c, %c, %c, %c\n", ((uint8_t*)&encoded)[0], ((uint8_t*)&encoded)[1], ((uint8_t*)&encoded)[2], ((uint8_t*)&encoded)[3]);

    fwrite(&encoded, sizeof(char), 4, outptr);

    loop_count++;
    if (loop_count == newline_loop_n) {
      loop_count = 0;
      
      fwrite(newline, sizeof(char), 2, outptr);
    }
    
    // limpando o que pode lixo para a próxima iteração
    memset(value, 0, 3);
  }
  // char a[3] = "ç";
  // printf("%x, %x, %x\n", a[0], a[1], a[2]);
  // printf("%d\n", base64_encode(10));
  // printf("%d\n", base64_encode(20));
  // printf("%d\n", base64_encode(1));
  
  return 0;
}
