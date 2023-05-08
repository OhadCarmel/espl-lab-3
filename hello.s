section .data
    message db 'Ohad is the king', 0x0a
    message_length equ $-message

section .text
    global _start

_start:
    ; write the message to stdout
    mov eax, 0x4                    ; system call for write()
    mov ebx, 1                      ; file descriptor for stdout
    mov ecx, message                ; pointer to the message
    mov edx, message_length         ; message length
    int 0x80                        

    ; exit the program with status code 0
    mov eax, 0x1                    ; system call for exit()
xor ebx, ebx                        ; exit status code
    int 0x80                        n


