section .data
    new_line db 0x0a
    char_buff dd 0
    infile dd 0
    outfile dd 1

section .text
    global _start
    global system_call
    global main

; extern main
extern strlen
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

main:
    push    ebp             ; Save caller state
    mov     ebp, esp
    sub     esp, 4          ; Leave space for local var on stack
    pushad                  ; Save some more caller state

    mov     ecx, [ebp+8]    ; i = argc

argv_loop:
    push    ecx
    mov     eax, [ebp+12]   ; eax = argv
    mov     ebx, [ebp+8]    ; ebx = argc
    sub     ebx, ecx        ; ebx = i
    shl     ebx, 2          ; ebx = i * 4
    add     eax, ebx        ; eax = eax + i * 4
    mov     ecx, [eax]      ; ecx = *(argv + i * 4)
    push    ecx
    call    strlen
    pop     ecx
    mov     edx, eax        ; edx = strlen(ecx)
    mov     eax, 0x4        ; system call for write()
    mov     ebx, 1          ; file descriptor for stdout
    int 0x80
    ; print new line
    mov     eax, 0x4        ; system call for write()
    mov     ebx, 1          ; file descriptor for stdout
    mov     ecx, new_line
    mov     edx, 1
    int 0x80

    pop ecx
    loop    argv_loop
    
    ohad:
    ;; read char from stdin 
    mov     eax, 0x3        ; system call for read()
    mov     ebx, [infile]     ; file descriptor for stdin
    mov     ecx, char_buff  
    mov     edx, 1         ; number of bytes to read
    int 0x80 
    
    ;; encode char
    mov     eax, [char_buff]   ; eax = *char_buff
    add     eax, 1             ; encode char

    ;; write char to stdout
    mov [char_buff], eax 
    mov ecx, char_buff
    mov eax, 0x4                 ; system call for write()
    mov ebx, [outfile]            ; file descriptor for stdout 
    mov edx, 1

    ; print new line
    mov     eax, 0x4        ; system call for write()
    mov     ebx, 1          ; file descriptor for stdout
    mov     ecx, new_line
    mov     edx, 1
    int 0x80

    popad                   ; Restore caller state (registers)
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller







encode:
