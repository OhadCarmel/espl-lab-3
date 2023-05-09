section .data
    new_line db 0x0a
    char_buff dd 0
    infile dd 0
    outfile dd 1
    infected_msg db 'Hello, Infected File', 0x0a
    infected_msg_length equ $-infected_msg

section .text
    global _start
    global system_call
    global infector
    

; extern main
extern strlen
extern main

_start:
    pop    dword ecx    ; ecx = argc
    mov    esi,esp      ; esi = argv
    ;; lea eax, [esi+4*ecx+4] ; eax = envp = (4*ecx)+esi+4
    mov     eax,ecx     ; put the number of arguments into eax
    shl     eax,2       ; compute the size of argv in bytes
    add     eax,esi     ; add the size to the address of argv 
    add     eax,4       ; skip NULL at the end of argv
    push    dword eax   ; char *envp[]
    push    dword esi   ; char* argv[]
    push    dword ecx   ; int argc

    call    main        ; int main( int argc, char *argv[], char *envp[] )

    mov     ebx,eax
    mov     eax,1
    int     0x80
    nop
  
        
system_call:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     eax, [ebp+8]    ; Copy function args to registers: leftmost...        
    mov     ebx, [ebp+12]   ; Next argument...
    mov     ecx, [ebp+16]   ; Next argument...
    mov     edx, [ebp+20]   ; Next argument...
    int     0x80            ; Transfer control to operating system
    mov     [ebp-4], eax    ; Save returned value...
    popad                   ; Restore caller state (registers)
    mov     eax, [ebp-4]    ; place returned value where caller can see it
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

    popad                   ; Restore caller state (registers)
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

code_start:
    nop
infection:
    push    ebp             ; Save caller state
    mov     ebp, esp
    pushad                  ; Save some more caller state

    ; write the message to stdout
    mov eax, 0x4                            ; system call for write()
    mov ebx, 1                           ; file descriptor for stdout
    mov ecx, infected_msg                ; pointer to the message
    mov edx, infected_msg_length         ; message length
    int 0x80                        

    popad                   ; Restore caller state (registers)
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller

infector:
    push    ebp             ; Save caller state
    mov     ebp, esp
    pushad                  ; Save some more caller state

    ;;open the file from the argument
    mov ebx, [ebp+8]        ;get the file name
    mov eax, 5              ; open syscall
    mov ecx, 02001o             ; O_WRONLY | O_APPEND
    int 0x80

    
    ;;add excutable code to the end of the file
    ; write the message to end of file
    mov ebx, eax                       ; file descriptor for fd
    mov eax, 0x4                       ; system call for write()
    mov ecx, code_start                ; pointer to the message
    mov edx, code_end                  ; message length
    sub edx, code_start
    int 0x80    

    ;;close the file
    mov     eax, 0x6           ; system call for close()
    int 0x80


    popad                   ; Restore caller state (registers)
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller
    nop
code_end:
    nop