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
%define number_triangle 6


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
res_a: dd 0
res_b: dd 0
res_c: dd 0
count: dd 0
nb:             dd 0
triangle_determinant: dd 0
section .text

global main
main:
    xor rdi,rdi
    call XOpenDisplay	
    mov qword[display_name],rax	

    mov rax,qword[display_name]
    mov eax,dword[rax+0xe0]
    mov dword[screen],eax

    mov rdi, qword[display_name]
    mov esi, dword[screen]
    call XRootWindow
    mov rbx, rax

    mov rdi, qword[display_name]
    mov rsi, rbx
    mov rdx, 10
    mov rcx, 10
    mov r8, 400	
    mov r9, 400	
    push 0xFFFFFF	
    push 0x00FF00
    push 1
    call XCreateSimpleWindow
    mov qword[window],rax

    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, 131077 
    call XSelectInput

    mov rdi, qword[display_name]
    mov rsi, qword[window]
    call XMapWindow

    mov rsi, qword[window]
    mov rdx, 0
    mov rcx, 0
    call XCreateGC
    mov qword[gc],rax

boucle: 
    mov rdi, qword[display_name]
    mov rsi, event
    call XNextEvent

    cmp dword[event], ConfigureNotify	
    je draw						        

mov dword[count], 0
draw:
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
    mov rdi, qword[display_name]
    mov rsi, qword[gc]
    mov edx, 0x000000	
    call XSetForeground

    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[array_x]	
    mov r8d, dword[array_y]	
    mov r9d, dword[array_x+1*DWORD]	
    push qword[array_y+1*DWORD]		
    call XDrawLine

    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[array_x]	
    mov r8d, dword[array_y]	
    mov r9d, dword[array_x+2*DWORD]	
    push qword[array_y+2*DWORD]		
    call XDrawLine

    mov rdi, qword[display_name]
    mov rsi, qword[window]
    mov rdx, qword[gc]
    mov ecx, dword[array_x+1*DWORD]	
    mov r8d, dword[array_y+1*DWORD]	
    mov r9d, dword[array_x+2*DWORD]	
    push qword[array_y+2*DWORD]		
    call XDrawLine

    cmp dword[color_counter], 6
    je reset_color
    inc dword[color_counter]
    jmp set_color

    reset_color:
        mov dword[color_counter], 0

    set_color:
        mov rdi, qword[display_name]
        mov rsi, qword[gc]
        mov ecx, [color_counter]
        mov edx, [colors+ecx*DWORD]
        call XSetForeground

    mov eax, dword[array_x+1*DWORD]          
    mov ebx, dword[array_y+1*DWORD]          
    mov ecx, dword[array_x]                  
    mov edx, dword[array_y]                  
    mov r8d, dword[array_x+2*DWORD]          
    mov r9d, dword[array_y+2*DWORD]          

    call get_determinant
    mov dword[triangle_determinant], ecx

    mov dword[i], 0
    boucle_i:
        mov dword[j], 0
        boucle_j:
            mov eax, [array_x]
            mov ebx, [array_y]
            mov ecx, [array_x+1*DWORD]
            mov edx, [array_y+1*DWORD]
            mov r8d, [i]
            mov r9d, [j]
            call get_determinant
            mov dword[res_a], ecx

            mov eax, [array_x+1*DWORD]
            mov ebx, [array_y+1*DWORD]
            mov ecx, [array_x+2*DWORD]
            mov edx, [array_y+2*DWORD]
            mov r8d, dword[i]
            mov r9d, dword[j]
            call get_determinant
            mov dword[res_b], ecx

            mov eax, [array_x+2*DWORD]
            mov ebx, [array_y+2*DWORD]
            mov ecx, [array_x]
            mov edx, [array_y]
            mov r8d, dword[i]
            mov r9d, dword[j]
            call get_determinant
            mov dword[res_c], ecx

            cmp dword[triangle_determinant], 0
            jl direct
            jmp indirect

            direct:
                cmp dword[res_a], 0
                jl next
                cmp dword[res_b], 0
                jl next
                cmp dword[res_c], 0
                jl next
                jmp draw_point

            indirect:
                cmp dword[res_a], 0
                jg next
                cmp dword[res_b], 0
                jg next
                cmp dword[res_c], 0
                jg next
                jmp draw_point

            draw_point:
                mov rdi, qword[display_name]
                mov rsi, qword[window]
                mov rdx, qword[gc]
                mov ecx, dword[i]
                mov r8d, dword[j]
                call XDrawPoint

            next:
                inc dword[j]
                cmp dword[j], 400
                jbe boucle_j

    inc dword[i]
    cmp dword[i], 400
    jb boucle_i

    jmp flush

flush:
    inc dword[count]
    cmp dword[count], number_triangle
    jb draw

    mov rdi, qword[display_name]
    call XFlush

end:
    mov rdi,qword[display_name]
    mov rsi,event
    call XNextEvent

    cmp dword[event], KeyPress            
    je closeDisplay                        
    jmp end

closeDisplay:
    mov     rax, qword[display_name]
    mov     rdi, rax
    call    XCloseDisplay
    xor	    rdi, rdi
    call    exit

global random_number
random_number:
    rdrand r15
    jnc random_number  

    xor rdx, rdx        
    mov rax, r15
    mov rbx, 400        
    div rbx            
    mov r15, rdx        
    ret

global get_determinant
get_determinant:
    sub ecx, eax   
    sub edx, ebx    

    sub r8d, eax   
    sub r9d, ebx    

    imul ecx, r9d   
    imul r8d, edx   

    sub ecx, r8d 
    ret