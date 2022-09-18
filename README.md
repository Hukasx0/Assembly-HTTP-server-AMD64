# Assembly HTTP server AMD64
Wrote in a few days to learn how http server works in low-level
## About
- one threaded
- single page
- no libraries
- needs NASM assembler to compile
- runs only on Linux 64 bit

# How to run
```shell
git clone https://github.com/Hukasx0/Assembly-HTTP-server-AMD64
cd Assembly-HTTP-server-AMD64/
chmod +x compile.sh && ./compile.sh && ./server
