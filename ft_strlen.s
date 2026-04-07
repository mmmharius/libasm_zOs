section .text
global ft_strlen

ft_strlen:
    xor rax, rax

boucle:
    cmp byte [rdi + rax], 0
    je fini

    inc rax
    jmp boucle

fini:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits