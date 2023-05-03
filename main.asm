; 
; Snake game made in x86_64 assembly using Raylib
; 
; 2023, Jonathan Tainer
;

bits 64

extern GetRandomValue
extern InitWindow
extern SetTargetFPS
extern WindowShouldClose
extern IsKeyDown
extern IsKeyPressed
extern BeginDrawing
extern ClearBackground
extern DrawText
extern DrawRectangle
extern EndDrawing
extern CloseWindow

global main

section .data
	win_title	db "snake!",0
	win_width	dd 1024
	win_height	dd 1024
	win_fps		dd 10
	color_red	db 255,0,0,255
	color_green	db 0,255,0,255
	color_blue	db 0,0,255,255
	color_black	db 0,0,0,255

	cols		dd 32
	rows		dd 32

	seg_width	dd 32
	seg_height	dd 32

	snake_max_len	dd 128
	snake_len	dd 8
	snake_x times 128 dd 16
	snake_y times 128 dd 16
	snake_x_vel	dd 0
	snake_y_vel	dd 0

	food_x		dd 0
	food_y		dd 0

section .text

spawn_food:
	mov edi, 0
	mov esi, 15
	call GetRandomValue
	mov [food_x], eax
	mov edi, 0
	mov esi, 15
	call GetRandomValue
	mov [food_y], eax
	ret

draw_food:
	mov edi, [food_x]
	mov esi, [food_y]
	mov edx, [seg_width]
	mov ecx, [seg_height]
	imul edi, edx
	imul esi, ecx
	mov eax, [color_red]
	mov r8, rax
	call DrawRectangle
	ret

detect_food:
	mov eax, [snake_x]
	mov ecx, [food_x]
	cmp eax, ecx
	jne detect_food_ret_false
	mov eax, [snake_y]
	mov ecx, [food_y]
	cmp eax, ecx
	jne detect_food_ret_false
	detect_food_ret_true:
	call spawn_food
	add dword [snake_len], 1
	mov eax, 1
	ret
	detect_food_ret_false:
	mov eax, 0
	ret

move_snake:

	; handle keyboard input
	test_right:
	mov edi, 262	; KEY_RIGHT
	call IsKeyPressed
	and eax, 1
	cmp eax, 1
	jne test_left
	mov dword [snake_x_vel], 1
	mov dword [snake_y_vel], 0
	test_left:
	mov edi, 263	; KEY_LEFT
	call IsKeyPressed
	and eax, 1
	cmp eax, 1
	jne test_down
	mov dword [snake_x_vel], -1
	mov dword [snake_y_vel], 0
	test_down:
	mov edi, 264	; KEY_DOWN
	call IsKeyPressed
	and eax, 1
	cmp eax, 1
	jne test_up
	mov dword [snake_x_vel], 0
	mov dword [snake_y_vel], 1
	test_up:
	mov edi, 265	; KEY_UP
	call IsKeyPressed
	and eax, 1
	cmp eax, 1
	jne test_end
	mov dword [snake_x_vel], 0
	mov dword [snake_y_vel], -1
	test_end:


	push rbp
	mov rbp, rsp
	sub rsp, 32

	mov rcx, snake_x	; pointer to x coords
	mov rdx, snake_y	; pointer to y coords
	mov eax, [snake_len]
	sub eax, 1
	imul eax, 4
	add rcx, rax		; 
	add rdx, rax		; point to end of tail and iterate back to front

	mov eax, [snake_len]
	sub eax, 1
	mov [rbp-16], rax	; index of end of tail at [rbp-16]

	move_snake_loop_begin:
	cmp dword [rbp-16], 0
	jle move_snake_loop_end
	sub dword [rbp-16], 1

	mov eax, [rcx-4]
	mov [rcx], eax
	mov eax, [rdx-4]
	mov [rdx], eax

	sub rcx, 4
	sub rdx, 4

	jmp move_snake_loop_begin
	move_snake_loop_end:
	add rsp, 32
	mov rsp, rbp
	pop rbp
	ret

draw_snake:
	push rbp
	mov rbp, rsp
	sub rsp, 32

	mov rax, snake_x	; pointer to x coords at [rbp-32]
	mov [rbp-32], rax
	mov rax, snake_y	; pointer to y coords at [rbp-24]
	mov [rbp-24], rax

	mov eax, [snake_len]
	mov [rbp-16], eax	; loop counter at [rbp-16]
	
	draw_snake_loop_begin:
	cmp dword [rbp-16], 0
	je draw_snake_loop_end
	sub dword [rbp-16], 1

	mov rax, [rbp-32]
	mov edi, [rax]
	imul edi, [seg_width]
	mov rax, [rbp-24]
	mov esi, [rax]
	imul esi, [seg_height]
	mov edx, [seg_width]
	mov ecx, [seg_height]
	mov eax, [color_green]
	mov r8, rax
	call DrawRectangle

	add dword [rbp-32], 4
	add dword [rbp-24], 4

	jmp draw_snake_loop_begin
	draw_snake_loop_end:
	add rsp, 32
	mov rsp, rbp
	pop rbp
	ret

main:
	push rbp
	mov rbp, rsp
	sub rsp, 16
	
	mov edi, [win_width]
	mov esi, [win_height]
	mov rdx, win_title
	call InitWindow

	mov edi, [win_fps]
	call SetTargetFPS

	; spawn initial food location
	call spawn_food

	loop_begin:
	; while (!WindowShouldClose())
	call WindowShouldClose
	cmp eax, 0
	jne loop_end

	call detect_food
	call move_snake

	mov eax, [snake_x_vel]
	add [snake_x], eax
	mov eax, [snake_y_vel]
	add [snake_y], eax

	; BeginDrawing()
	call BeginDrawing
	
	; ClearBackground(GREEN)
	mov edi, [color_black]
	call ClearBackground

	call draw_snake
	call draw_food

	; EndDrawing()
	call EndDrawing

	jmp loop_begin
	loop_end:
	
	; CloseWindow()
	call CloseWindow

	add rsp, 16
	mov rsp, rbp
	pop rbp
	ret

