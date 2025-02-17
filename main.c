#include <stdint.h>
#include <stdio.h>
#include <string.h>

// comment if don't want newline to be added in encoding or considered in decoding
#define NEWLINE_SPACING 76

__attribute__((cdecl))
extern uint32_t base64_encode(uint32_t n, uint32_t text);

__attribute__((cdecl))
extern uint32_t base64_decode(uint32_t text);

FILE *inptr, *outptr;

int little_endian_arch() {
  int t=1;
  return *((char*)&t) == 0x1;
}

void encode(FILE* inptr, FILE* outptr) {
  int n_read;
  char value[3];
  int is_little_endian_arch = little_endian_arch();

  memset(value, 0, 3);
#ifdef NEWLINE_SPACING
  const int newline_loop_n = NEWLINE_SPACING / 4;
  int loop_count=0;
  char *newline = "\r\n";
#endif

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
#ifdef NEWLINE_SPACING
    loop_count++;
    if (loop_count == newline_loop_n) {
      loop_count = 0;
      
      fwrite(newline, sizeof(char), 2, outptr);
    }
#endif
    
    // limpando o que pode lixo para a próxima iteração
    memset(value, 0, 3);
  }
}

void decode(FILE* inptr, FILE* outptr) {
  int n_read;
  char value[4];
  int is_little_endian_arch = little_endian_arch();

  memset(value, 0, 4);

#ifdef NEWLINE_SPACING
  const int newline_loop_n = NEWLINE_SPACING / 4;

  int loop_count=0;

  char newline[2];
#endif

  while ((n_read = fread(value, sizeof(char), 4, inptr))) {
    uint32_t text = (value[0] & 0xff) << 24 | (value[1] & 0xff) << 16 | (value[2] & 0xff) << 8 | value[3];

    // returns encoded in big endian order
    uint32_t encoded = base64_decode(text);
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
    // printf("out: %c, %c, %c, %c\n", ((char*)&encoded)[0], ((char*)&encoded)[1], ((char*)&encoded)[2], ((char*)&encoded)[3]);

    if (value[2] == '=') {
      fwrite(&encoded, sizeof(char), 1, outptr);
    } else if (value[3] == '=') {
      fwrite(&encoded, sizeof(char), 2, outptr);
    } else {
      fwrite(&encoded, sizeof(char), 3, outptr);
    }

#ifdef NEWLINE_SPACING
    loop_count++;
    if (loop_count == newline_loop_n) {
      loop_count = 0;

      fread(newline, sizeof(char), 2, inptr);
    }
#endif
    
    // limpando o que pode lixo para a próxima iteração
    memset(value, 0, 4);
  }
}

int main(int argc, char* argv[]) {
  if (argc != 4) {
    printf("You need to pass the mode, input and output file to this executable.\n");
    printf("To encode: ./bin -e test.jpeg out.txt\n");
    printf("To decode: ./bin -d test.txt out.jpeg\n");
    return 1;
  }

  int dec = 0;
  if (strcmp(argv[1], "-e") == 0) dec = 0;
  else if (strcmp(argv[1], "-d") == 0) dec = 1;
  else {
    printf("Invalid first parameter!\n");
    printf("To encode: ./bin -e test.jpeg out.txt\n");
    printf("To decode: ./bin -d test.txt out.jpeg\n");
    return 1;
  }
  
  inptr = fopen(argv[2], "rb");
  outptr = fopen(argv[3], "wb");

  if (dec) {
    decode(inptr, outptr);
  } else {
    encode(inptr, outptr);
  }
  
  return 0;
}
