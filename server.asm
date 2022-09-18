;                   Assembly AMD64 Server
;                 https://github.com/Hukasx0/
;           ~ Hubert Hukasx0 Kasperek
;
;

struc sockaddr
    sin_family: resw    1   ; 2 bytes
    sin_port:   resw    1   ; 2 bytes
    sin_addr:   resd    1   ; 4 bytes
    sin_zero:   resw    4   ; 8 bytes
endstruc

section .data
introMsg db         "Starting on port 1337",0ah,0h
introMsgLen equ     $-introMsg
socket      dq      0
socketEnabled dw    0
client      dq      0
bufferLen   equ     30000
bufferReq   TIMES   bufferLen   db     0
bufferFile  TIMES   bufferLen   db     0
http200     db      "HTTP/1.1 200 OK",0ah,"Date: xyz",0ah,"Server: AssemblyAmd64",0ah,"Content-Type: text/html",0ah,0ah,0h
http200Len  equ     $-http200
index       db      "index.html",0h
indexPointer dq     0

address:
    istruc sockaddr
        at sin_family, dw 0x2       ; AF_INET
        at sin_port,   dw 0x3905    ; port 1337
        at sin_addr,   dd 0x0       ; 0.0.0.0
        at sin_zero,   dw 0h       ; '\0'
    iend
addressLen  equ  $-address

section .text
    global _start
    global _startServer
    global _acceptCons
    global _closeSocket
    global _exit

_start:
    call _startServer
    call _closeSocket
    call _exit

_startServer:
    ; ~~~~~~~~~~~~~~~~ print intro
    mov rax,1               ; sys_write
    mov rdi,1               ; STDOUT_FILENO
    mov rsi,introMsg        ; intro message
    mov rdx,introMsgLen     ; intro message length
    syscall
    ; ~~~~~~~~~~~~~~~~  create socket
    mov rax,41              ; sys_socket
    mov rdi,2               ; AF_INET
    mov rsi,1               ; SOCK_STREAM
    mov rdx,0               ; IPPROTO_IP
    syscall
    ; ~~~~~~~~~~~~~~~~ set socket opt
    mov [socket],rax        ; socket = fd
    mov rdi,rax             ; fd
    mov rax,54              ; sys_setsockopt
    mov rsi,1               ; SOL_SOCKET
    mov rdx,2               ; SO_REUSEADDR
    mov r10, socketEnabled
    mov r8, dword 32
    syscall
    ; ~~~~~~~~~~~~~~~~ bind socket
    mov rax,49              ; sys_bind
    mov rdi,[socket]        ; fd
    mov rsi,address         ; struct sockaddr
    mov rdx,[addressLen]    ; sockaddr length
    syscall
    ; ~~~~~~~~~~~~~~~~ listen
    xor rdx,rdx             ; 0
    mov rax,50              ; sys_listen
    mov rsi,15              ; backlog
    syscall
    ; ~~~~~~~~~~~~~~~~ accept incoming connections
    jmp _acceptCons

_acceptCons:
    ; ~~~~~~~~~~~~~~~~ accept connection
    mov rax,43              ; sys_accept
    mov rdi,[socket]        ; fd
    mov rsi,0               ; NULL
    mov rdx,0               ; NULL
    syscall
    ; ~~~~~~~~~~~~~~~~ read sent data
    mov [client],rax        ; client = client fd
    mov rdi,rax             ; client socket fd
    mov rax,0               ; sys_read
    mov rsi,bufferReq       ; buffer
    mov rdx,bufferLen       ; buffer length
    syscall
    ; ~~~~~~~~~~~~~~~~ print data
    mov rax,1               ; sys_write
    mov rdi,1               ; STDOUT_FILENO
    mov rsi,bufferReq       ; buffer
    mov rdx,bufferLen       ; buffer length
    syscall
    ; ~~~~~~~~~~~~~~~~ open index.html
    mov rax,2               ; sys_open
    mov rdi,index           ; index.html
    mov rsi,0               ; O_RDONLY
    syscall
    mov [indexPointer],rax
    ; ~~~~~~~~~~~~~~~~ send http 200
    mov rax,1               ; sys_write
    mov rdi,[client]        ; client socket fd
    mov rsi,http200         ; http 200 ok response
    mov rdx,http200Len      ; http 200 ok response length
    syscall
    ; ~~~~~~~~~~~~~~~~ read index.html
    mov rax,0               ; sys_read
    mov rdi,[indexPointer]  ; index.html pointer
    mov rsi,bufferFile      ; file buffer
    mov rdx,bufferLen       ; file buffer length
    syscall
    ; ~~~~~~~~~~~~~~~~ send index.html data
    mov rdx,rax             ; file buffer length
    mov rax,1               ; sys_write
    mov rdi,[client]        ; client socket fd
    mov rsi,bufferFile      ; file buffer
    syscall
    ; ~~~~~~~~~~~~~~~~ close client socket
    mov rax,3               ; sys_close
    mov rdi,[client]        ; client socket fd
    syscall
    ; ~~~~~~~~~~~~~~~~ while(true) 
    mov ax,1
    cmp ax,1
    je _acceptCons
    xor rax,rax
    ret

_closeSocket:
    mov rax,3               ; sys_close
    mov rdi,[socket]        ; fd
    syscall
    xor rax,rax
    ret

_exit:
    pop rbp
    mov rax,60
    syscall