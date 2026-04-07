BITS 32

section .text
global ft_strcpy

; char *ft_strcpy(char *dst, const char *src)
; 32-bit cdecl: dst at [esp + 4], src at [esp + 8]
; return value in eax (= dst)
; edi and esi are callee-saved

ft_strcpy:
    push edi
    push esi
    mov  edi, [esp + 12]  ; dst  (offset: 2 pushes = 8 + ret addr = 4 → +12)
    mov  esi, [esp + 16]  ; src  (offset: +16)
    mov  eax, edi          ; save dst for return value

boucle:
    mov  dl, [esi]         ; dl is low byte of edx (caller-saved)
    mov  [edi], dl
    cmp  dl, 0
    je   fini
    inc  esi
    inc  edi
    jmp  boucle

fini:
    pop  esi
    pop  edi
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
