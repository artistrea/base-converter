# Como rodar

Para compilar é necessário ter gcc e nasm.

```bash
make
# encodes any binary, e.g. an jpeg
./bin -e img.jpeg out.txt
# decodes base64 to binary
./bin -d out.txt img2.jpeg
```


