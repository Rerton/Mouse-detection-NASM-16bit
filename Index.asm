bits 16; 16 bit mode
org 0x7c00; |0x7c00|memory adresas nuo kur prasides mano kodas - memory
xor ax,ax
mov ds,ax
mov [boot_drive],dl
mov ah,0
mov al,13h
int 0x10

mov ax,0; Loads rest of hard drive data to the memory [number .raw]
mov es, ax      ; ES:BX, sector where in the ram it should be put
mov ah, 02h     ; BIOS number to map hard drive into ram
mov al, 1       ; how many sectors to read, each sektor 512 bytes
mov ch, 0       ; 
mov cl, 2       ; sectors start from 1, not 0, sector 1 is bootloader so we skip it [as it is already loaded]
mov dh, 0       ; i don't know what this one for
mov dl, [boot_drive]     ; upon very boot, bios provide hard drive, from which booted [dl]
mov bx, 0x7E00     ; ES:BX = where in the ram code will be
int 13h

xor ax,ax; sets pointers to needed values
mov ss, ax
mov sp, 0x7C00
mov ax,0xA000
mov es,ax
xor di,di

.wait:
    in   al, 64h ; checks if I/O port is free
    test al, 10b ; if not when cycles until it is

mov al, 0D4h ; tells I/O port to send mouse  inputs
out 64h, al ; out -> send data to destination | in read data from

.wait2:
    in   al, 64h ; waits again
    test al, 10b
    jnz  .wait2


mov al, 0F4h           ; Lets in output mouse data
out 60h, al


jmp DrawN
start:
    ; reads mouse data button|x|y, it sends 3 bytes in a cycle, here it is made so it would catch the cyle
    .waitMI: ; left click | right click | middle button | always on | pos/neg x change | pos/neg y change | x of | y of
        in   al, 64h ; also waits until it reaceaves mouse input
        test al, 01h
        jz   .waitMI
        test al,10000b ; 
        jz   .waitMI
        in   al,60h
        test al,1000b  ; if byte 3 is 1 | aligns packets     
        jz   .waitMI
        mov [mouse_b0],al
    .waitMX:; x
        in   al, 64h
        test al, 01h
        jz   .waitMX

    in   al, 60h
    cbw; converts byte -> word
    mov  cx, ax
    .waitMY:; y
        in   al, 64h
        test al, 01h
        jz   .waitMY

    in   al, 60h
    cbw
    mov  bx, ax

    imul bx,-320; adds mouse change to di

    add di,cx
    add di,bx
    mov bx,[PrevI]; based on if left/right/middle click is active, draws, if none, act as a cursor
    test bx,bx
    jz NoPrevI
        mov byte [es:bx],0
        mov byte [PrevI],0
    NoPrevI:
    mov al,[mouse_b0]
    and al,111b
    jz EmptyCell
        mov byte [es:di],al
        jmp NotEmpty
    EmptyCell:
        mov byte [es:di],15
        mov [PrevI],di
    NotEmpty:
    

    DrawN: ;Draws x/y/mouse state
 
    push di
    mov ax,di; 12735
    mov bx,320; ax = 39 ir dx = liek(255)
    xor dx,dx
    div bx

    push ax
    mov ax,dx;255 % 10=5
    xor dx,dx
    mov bx,10
    div bx
    imul dx,48; ax = 25
    mov cx,3
    DrawX: ; mouse X
        push cx
        imul cx,6
        mov di,cx
        lea si, [img] 
        add si,dx
        call Draw
        xor dx,dx
        mov bx,10
        div bx
        imul dx,48

        pop cx
        dec cx
        jnz DrawX
    pop ax; ax = 25
    xor dx,dx
    mov bx,10
    div bx
    imul dx,48
    mov cx,3
    DrawY: ; mouse Y
        push cx
        imul cx,6
        mov di,2560
        add di,cx
        lea si,[img]
        add si,dx
        call Draw   
        xor dx,dx
        mov bx,10
        div bx
        imul dx,48

        pop cx
        dec cx
        jnz DrawY

    xor ah,ah ; left click state
    mov al,[mouse_b0]
    and al,1
    mov bl,48
    mul bl
    lea si,[img]
    add si,ax
    mov di,5126
    call Draw

    mov al,[mouse_b0] ; right click state
    and al,2
    shr al,1
    mov bl,48
    mul bl
    lea si,[img]
    add si,ax
    mov di,5132
    call Draw

    mov al,[mouse_b0] ; middle click state
    and al,4
    shr al,2
    mov bl,48
    mul bl
    lea si,[img]
    add si,ax
    mov di,5138
    call Draw
    pop di

jmp start

Draw:
    mov bx, 0xA000 
    mov es, bx
    mov cl,8
    DrawColumn:
        mov ch,6
        DrawRow:
            mov bl,[si]
            mov byte [es:di],bl
            inc di
            inc si
            dec ch
            jnz DrawRow
        add di,314
        dec cl
        jnz DrawColumn


    ret
PrevI dw 0 ; saves prevous pos if in cursor state
mouse_b0 db 0 ; mouse state
boot_drive db 0
times 510-($-$$) db 0; fill (512 bytes - ending pos of the code) with 0's. 
dw 0xaa55; hard drive marking   
img:
incbin "N6x8/0.raw"
incbin "N6x8/1.raw"
incbin "N6x8/2.raw"
incbin "N6x8/3.raw"
incbin "N6x8/4.raw"
incbin "N6x8/5.raw"
incbin "N6x8/6.raw"
incbin "N6x8/7.raw"
incbin "N6x8/8.raw"
incbin "N6x8/9.raw"
