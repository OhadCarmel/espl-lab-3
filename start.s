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
    call    check_inout_files_from_arg
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
    

encode_loop:
    ;; read char from stdin 
    mov     eax, 0x3           ; system call for read()
    mov     ebx, [infile]      ; file descriptor for stdin
    mov     ecx, char_buff  
    mov     edx, 1             ; number of bytes to read
    int 0x80 
    
    ;; check if eax > 0
    cmp    eax, 0
    jle    end_encode_loop
    push   dword [char_buff]
    call   encode
    mov [char_buff], eax
    add     esp, 4

    ;; write char to stdout
    mov ecx, char_buff
    mov eax, 0x4               ; system call for write()
    mov ebx, [outfile]         ; file descriptor for out file 
    mov edx, 1
    int 0x80

    ; print new line
    mov     eax, 0x4           ; system call for write()
    mov     ebx, [outfile]     ; file descriptor for out file
    mov     ecx, new_line
    mov     edx, 1
    int 0x80
    jmp    encode_loop

end_encode_loop:
    ;; Close input/output files
    cmp dword [infile], 0
    jne close_output_file
    mov     eax, 0x6           ; system call for close()
    mov     ebx, [infile]      ; file descriptor
    int 0x80

close_output_file:
    cmp dword [outfile], 1
    jne main_end
    mov     eax, 0x6           ; system call for close()
    mov     ebx, [outfile]     ; file descriptor
    int 0x80

main_end:
    popad                   ; Restore caller state (registers)
    add     esp, 4          ; Restore caller state
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller


encode:
    ;; fuck state of registers
    mov eax , [esp + 4]       ; eax = char

    ;; check if char is between 'a' and 'z'
    cmp eax, 'A'
    jl encode_return
    ;;else
    cmp eax, 'z'
    jg encode_return
    ;; encode char
    add     eax, 1             ; encode char
encode_return:
    ret
    


check_inout_files_from_arg:
    push    ebp             ; Save caller state
    mov     ebp, esp
    pushad                  ; Save some more caller state

    mov ebx, [ebp+8]
    ;; Check for output file
    cmp word [ebx], '-'+(256*'o')
    jne check_input_file
    add ebx, 2
    mov eax, 5          ; open syscall
    mov ecx, 0x241      ; O_WRONLY | O_CREAT | O_TRUNC
    mov edx, 0644o      ; File permissions -rw-r--r--
    int 0x80
    sub ebx, 2
    cmp eax, 0
    jl check_input_file
    mov [outfile], eax

check_input_file:
    ;; Check for input file
    cmp word [ebx], '-'+(256*'i')
    jne check_inout_files_from_arg_end
    add ebx, 2
    mov eax, 5          ; open syscall
    mov ecx, 0x0        ; O_RDONLY
    int 0x80
    
    cmp eax, 0
    jl check_inout_files_from_arg_end
    mov [infile], eax

check_inout_files_from_arg_end:
    popad                   ; Restore caller state (registers)
    pop     ebp             ; Restore caller state
    ret                     ; Back to caller
