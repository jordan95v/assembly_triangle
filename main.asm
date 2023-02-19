; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XDrawPoint
extern XFillArc
extern XNextEvent

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1
%define number_triangle 3


global main

section .bss
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		    resq	1
gc:		        resq	1

section .data
array_x:        times 3 dd 0
array_y:        times 3 dd 0
event:		    times 24 dq 0
colors:         times 6 dd 0x000000, 0xFFAA00, 0xFF00FF, 0x0000FF, 0x00FF00, 0xFF0000
color_counter:  dd 0
i:              dd 0
j:              dd 0
number_of_triangle: dd 0
nb:             dd 0
fmt:            db "%d", 10, 0
section .text

global main
main:
    xor     rdi,rdi
    call    XOpenDisplay	; Création de display
    mov     qword[display_name],rax	; rax=nom du display

    ; display_name structure
    ; screen = DefaultScreen(display_name);
    mov     rax,qword[display_name]
    mov     eax,dword[rax+0xe0]
    mov     dword[screen],eax

    mov rdi,qword[display_name]
    mov esi,dword[screen]
    call XRootWindow
    mov rbx,rax

    mov rdi,qword[display_name]
    mov rsi,rbx
    mov rdx,10
    mov rcx,10
    mov r8,400	; largeur
    mov r9,400	; hauteur
    push 0xFFFFFF	; background  0xRRGGBB
    push 0x00FF00
    push 1
    call XCreateSimpleWindow
    mov qword[window],rax

    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,131077 ;131072
    call XSelectInput

    mov rdi,qword[display_name]
    mov rsi,qword[window]
    call XMapWindow

    mov rsi,qword[window]
    mov rdx,0
    mov rcx,0
    call XCreateGC
    mov qword[gc],rax

boucle: ; boucle de gestion des évènements
    mov rdi,qword[display_name]
    mov rsi,event
    call XNextEvent

    cmp dword[event], ConfigureNotify	; à l'apparition de la fenêtre
    je draw						        ; on saute au label 'dessin'

    cmp dword[event], KeyPress			; Si on appuie sur une touche
    je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
    jmp boucle

draw:
    ; inc dword[nb]
    ; mov ecx, number_triangle
    ; cmp dword[nb], ecx
    ; ja draw_triangle

    xor r14, r14
    generation_x:
        call random_number
        mov [array_x+r14*DWORD], r15
        inc r14
        cmp r14, 3
        jb generation_x
    
    xor r14, r14
    generation_y:
        call random_number
        mov [array_y+r14*DWORD], r15
        inc r14
        cmp r14, 3
        jb generation_y

draw_triangle:
    ; On définit la couleur du trait.
    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, 0x000000	; Couleur du crayon ; noir
    call XSetForeground

    ; On dessine le trait du point 1 au point 2.
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[array_x]	; coordonnée source en x
    mov r8d, dword[array_y]	; coordonnée source en y
    mov r9d, dword[array_x+1*DWORD]	; coordonnée destination en x
    push qword[array_y+1*DWORD]		; coordonnée destination en y
    call XDrawLine

    ; On dessine le trait du point 1 au point 3.
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[array_x]	; coordonnée source en x
    mov r8d, dword[array_y]	; coordonnée source en y
    mov r9d, dword[array_x+2*DWORD]	; coordonnée destination en x
    push qword[array_y+2*DWORD]		; coordonnée destination en y
    call XDrawLine

    ; On dessine le trait du point 2 au point 3.
    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[array_x+1*DWORD]	; coordonnée source en x
    mov r8d, dword[array_y+1*DWORD]	; coordonnée source en y
    mov r9d, dword[array_x+2*DWORD]	; coordonnée destination en x
    push qword[array_y+2*DWORD]		; coordonnée destination en y
    call XDrawLine

    reset_color:
        mov rdi, qword[display_name]
        mov rsi, qword[gc]
        mov ecx, [color_counter]
        mov edx, [colors+ecx*DWORD]
        call XSetForeground

        inc dword[color_counter]
        cmp dword[color_counter], 6
        je reset_color

    ; Récupération des coordonnées des points A, B, et C dans les tableaux array_x et array_y
    mov eax, dword[array_x+1*DWORD]          ;  bx
    mov ebx, dword[array_y+1*DWORD]          ;  by
    mov ecx, dword[array_x]                  ;  ax
    mov edx, dword[array_y]                  ;  ay
    mov r8d, dword[array_x+2*DWORD]          ;  Cx
    mov r9d, dword[array_y+2*DWORD]          ;  Cy

    ; Comparaison du résultat avec 0
    call get_determinant
    cmp ecx, 0
    jl direct             ; Si résultat < 0, saut vers direct
    jmp indirect


direct:
    mov dword[i], 0

    boucle_i_direct:
        mov dword[j], 0
        boucle_j_direct:
            ; Calcul AB -> AP.
            mov eax, [array_x]
            mov ebx, [array_y]
            mov ecx, [array_x+1*DWORD]
            mov edx, [array_y+1*DWORD]
            mov r8d, [i]
            mov r9d, [j]
            call get_determinant
            cmp ecx, 0
            jl next_direct

            ; Calcul BC -> BP.
            mov eax, [array_x+1*DWORD]
            mov ebx, [array_y+1*DWORD]
            mov ecx, [array_x+2*DWORD]
            mov edx, [array_y+2*DWORD]
            mov r8d, dword[i]
            mov r9d, dword[j]
            call get_determinant
            cmp ecx, 0
            jl next_direct

            ; Calcul CA -> CP.
            mov eax, [array_x+2*DWORD]
            mov ebx, [array_y+2*DWORD]
            mov ecx, [array_x]
            mov edx, [array_y]
            mov r8d, dword[i]
            mov r9d, dword[j]
            call get_determinant
            cmp ecx, 0
            jl next_direct

            ; On dessine le point si tout les determinants sont positifs.
            mov rdi, qword[display_name]
            mov rsi, qword[window]
            mov rdx, qword[gc]
            mov ecx, dword[i]
            mov r8d, dword[j]
            call XDrawPoint

            next_direct:
                inc dword[j]
                cmp dword[j], 400
                jbe boucle_j_direct
            ;FIN BOUCLE J

    inc dword[i]
    cmp dword[i], 400
    jb boucle_i_direct
    ; FIN BOUCLE I

    jmp flush

indirect:
    mov dword[i], 0
    boucle_i_indirect:
        mov dword[j], 0
        boucle_j_indirect:
            ; Calcul AB -> AP.
            mov eax, [array_x]
            mov ebx, [array_y]
            mov ecx, [array_x+1*DWORD]
            mov edx, [array_y+1*DWORD]
            mov r8d, [i]
            mov r9d, [j]
            call get_determinant
            cmp ecx, 0
            jg next_indirect

            ; Calcul BC -> BP.
            mov eax, [array_x+1*DWORD]
            mov ebx, [array_y+1*DWORD]
            mov ecx, [array_x+2*DWORD]
            mov edx, [array_y+2*DWORD]
            mov r8d, dword[i]
            mov r9d, dword[j]
            call get_determinant
            cmp ecx, 0
            jg next_indirect

            ; Calcul CA -> CP.
            mov eax, [array_x+2*DWORD]
            mov ebx, [array_y+2*DWORD]
            mov ecx, [array_x]
            mov edx, [array_y]
            mov r8d, dword[i]
            mov r9d, dword[j]
            call get_determinant
            cmp ecx, 0
            jg next_indirect

            ; On dessine le point si tout les determinants sont positifs.
            mov rdi, qword[display_name]
            mov rsi, qword[window]
            mov rdx, qword[gc]
            mov ecx, dword[i]
            mov r8d, dword[j]
            call XDrawPoint

            next_indirect:
                inc dword[j]
                cmp dword[j], 400
                jbe boucle_j_indirect
            ;FIN BOUCLE J

    inc dword[i]
    cmp dword[i], 400
    jb boucle_i_indirect
    ; FIN BOUCLE I

    jmp flush

; Fin du dessin.
flush:
    mov rdi,qword[display_name]
    call XFlush

    ; Fait en sorte de dessiner le bon nombre de triangle.
    inc dword[number_of_triangle]
    mov ecx, number_triangle
    cmp dword[number_of_triangle], ecx
    jl draw

    ; Sinon on jump à la gestion d'évenements.
    jmp boucle
    mov rax,34
    syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit

global random_number
random_number:
    rdrand r15          ; Génération d'un nombre aléatoire.
    jnc random_number   ; Si CF=0, on recommence.

    ; Effectue un module 400 sur le nombre aléatoire.
    xor rdx, rdx        ; Initialiser RDX à zéro.
    mov rax, r15
    mov rbx, 400        ; Copier 400 dans RBX.
    div rbx             ; Diviser RAX par 400.
    mov r15, rdx        ; Copie rax dans r15, qui nous sert à stocker la valeur aléatoire.
    ret

global get_determinant
get_determinant:
    sub ecx, eax    ; bx - ax
    sub edx, ebx    ; by - ay

    sub r8d, eax    ; px - ax
    sub r9d, ebx    ; py - ay

    imul ecx, r9d   ; bx * py
    imul r8d, edx   ; px * by

    sub ecx, r8d    ; Resultat
    ret