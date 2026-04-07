BITS 32

section .text
global ft_strlen

; size_t ft_strlen(const char *s)
; 32-bit cdecl: s is at [esp + 4]
; return value in eax

ft_strlen:
    mov  edx, [esp + 4]   ; edx = s  (edx is caller-saved, no need to preserve)
    xor  eax, eax          ; eax = 0  (counter, also return value)

boucle:
    cmp  byte [edx + eax], 0
    je   fini
    inc  eax
    jmp  boucle

fini:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
