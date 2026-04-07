section .text
global ft_strcpy

ft_strcpy:
    mov rax, rdi

boucle:
    mov bl, [rsi]
    mov [rdi], bl
    
    cmp bl, 0
    je fini
    
    inc rsi
    inc rdi
    jmp boucle

fini:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits