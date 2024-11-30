.model small
.386
.stack 64
.data

; Variables de la snake utilizadas por la UI y lógica del juego
head 			dw 		0000001011101100b 
tail 			dw 		0000001010101100b,0000001011001100b,1355 dup(0)
tail_conta 		dw 		2

curr_dir db 0      ; Valores posibles: 0 (derecha), 1 (izquierda), 2 (arriba), 3 (abajo)

; Variables para los estados del juego (En curso, pausado, terminado)
; Valores posibles: 0 (false), 1 (true)
game_running db 0
gameover db 0

; Variables para las coordenadas del objeto actual en pantalla
item_col 		db 		50  	;columna
item_ren 		db 		16 		;renglon

; Variables auxiliares para limpiar el tablero
board_col db 0
board_row db 0

; Variables para el juego
score 			dw 		0
hi_score	 	dw 		0
speed 			db 		0


; Itera sobre el área de juego y la reestablece a su estado inicial (para borrar la serpiente)
restart_board macro
	mov [board_row], 23
	mov [board_col], 78
	
	loop_col:
		posiciona_cursor [board_row], [board_col]
		imprime_caracter_color ' ', cBlanco, bgNegro
		dec [board_col]
		cmp [board_col], 20
		je siguiente
		jmp loop_col

	siguiente: 
		dec [board_row]
		mov [board_col], 78
		cmp [board_row], 0
		jne loop_col

endm

; Se encarga de borrar la posición anterior de la cola de la snake, para mostrar el movimiento
remove_prev macro
	lea bx, [tail]
	mov ax, [bx]
	mov dx, ax
	and ax, 11111b
	mov [ren_aux], al
	and dx, 111111100000b
	shr dx, 5
	mov [col_aux], dl
	posiciona_cursor [ren_aux], [col_aux]
	imprime_caracter_color ' ', cBlanco, bgNegro
endm


.code

; Se encarga de actualizar las posiciones de la cola de la snake para avanzar
shift_body proc
	lea bx, [tail]
	mov cx, 1
lp:
	push bx
	mov ax, [bx + 2]
	cmp word ptr [bx + 2], 0
	jne cambiar

	pop bx
	mov ax, [head]
	mov [bx], ax
	ret

cambiar:
	pop bx
	mov [bx], ax
	add bx, 2
	jmp lp

shift_body endp


; Se encarga de crear un retraso artificial para cambiar la velocidad del juego
delay proc 
	push cx
	push dx

	mov cx, ax
outer_loop:
	mov dx, 1000
inner_loop:
	nop
	dec dx
	jnz inner_loop

	dec cx
	jnz outer_loop

	pop dx
	pop cx
	ret
delay endp


; Reestablece el arreglo "tail" a sus condiciones iniciales 
restart_snake proc
	mov cx, 1356 ; 1356 = longitud del arreglo "tail"
  lea bx, tail
  mov si, 1356

	mov [head], 0000001011101100b
	mov word ptr [bx], 0000001010101100b
	mov word ptr [bx + 2], 0000001011001100b
reestablecer_cuerpo:
  mov di, si
  shl di, 1
  add di, bx

	cmp cx, 1
	je fin_reestablecer

  mov word ptr [di], 0

  dec si
  loop reestablecer_cuerpo
fin_reestablecer:
  ret
restart_snake endp


; Reestablece las variables del juego a sus condiciones iniciales 
restart_initial_conditions proc
	; Si el score de la partida es más alto que el highscore, se actualiza
	mov ax, [score]
	cmp ax, [hi_score]
	jng restart_conditions_end

	mov [hi_score], ax

restart_conditions_end:
	mov [gameover], 0
	mov [game_running], 0
	mov [score], 0
	mov [curr_dir], 0
	mov [tail_conta], 2
	ret
restart_initial_conditions endp


; Revisa si la cabeza de la snake chocó con los límites del mapa o con su propio cuerpo
check_collision proc
	mov ax, [head]
	mov dx, ax
	and dx, 111111100000b
	shr dx, 5
	
	and ax, 11111b

	; Revisar si chocó con los límites del mapa
	cmp ax, 0
	je game_over
	cmp ax, 24d
	je game_over
	cmp dx, 20d
	je game_over
	cmp dx, 79d
	je game_over

	; Revisar si chocó con su cuerpo
	lea bx, [tail]
	mov cx, [tail_conta]
	dec cx

body_loop:
	mov ax, [bx]
	cmp ax, [head]
	je game_over

	add bx, 2
	loop body_loop

	ret
game_over:
	mov [gameover], 1
	ret

check_collision endp


; Recorre todos los elementos del arreglo "tail" una posición a la derecha, para agregar un elemento cuando crece
shift_array proc
	lea bx, [tail]
	mov ax, [bx]
	add bx, 2
	mov cx, 2

shift_lp:
	push ax
	mov ax, [bx]
	mov dx, ax
	pop ax
	mov [bx], ax
	mov ax, dx
	add bx, 2

	cmp word ptr [bx], 0
	jne shift_lp

	dec cx
	cmp cx, 0
	je shift_array_end

	jmp shift_lp

shift_array_end:
	ret
shift_array endp


; Lógica para ver en qué posición se va a agregar un nuevo segmento cuando la snake crece
grow_snake proc
	mov ax, [tail]
	mov dx, ax
	and dx, 111111100000b
	shr dx, 5
	mov [col_aux], dl
	and ax, 11111b
	mov [ren_aux], al

	mov ax, [head]
	mov dx, ax
	and dx, 111111100000b
	shr dx, 5
	and ax, 11111b

	cmp dl, [col_aux]
	je check_row
	jg add_left

	inc [col_aux]
	jmp add_segment

add_left:
	dec [col_aux]
	jmp add_segment

check_row:
	cmp al, [ren_aux]
	jg add_up

	inc [ren_aux]
	jmp add_segment

add_up:
	dec [ren_aux]
	jmp add_segment

add_segment:
	call shift_array
	lea bx, [tail]
	xor ax, ax
	mov al, [ren_aux]
	xor dx, dx
	mov dl, [col_aux]
	shl dx, 5
	xor ax, dx
	mov [tail], ax

	ret
grow_snake endp


; Revisa si la serpiente comió la fruta y se encarga de generar una nueva
check_fruit proc
	mov ax, [head]
	mov dx, ax
	and dx, 111111100000b
	shr dx, 5
	and ax, 11111b

	cmp al, [item_ren]
	je cond2

	jmp fruit_end

cond2:
	cmp dl, [item_col]
	jne fruit_end

	; La serpiente se comió la fruta
	generate_random 21, 78
	mov al, [random_number]
	mov [item_col], al
	generate_random 1, 23
	mov al, [random_number]
	mov [item_ren], al

	mov ax, [score]
	add ax, 10d
	mov [score], ax
	inc [tail_conta]

	call grow_snake

fruit_end:
	ret
check_fruit endp


; Realiza el cambio de dirección de la snake, se asume que la nueva dirección se encuentra en el registro al
; Recordemos que 0 (derecha), 1 (izquierda), 2 (arriba), 3 (abajo)
change_dir proc
	cmp al, 0
	je change_right
	cmp al, 1
	je change_left
	cmp al, 2
	je change_up
	cmp al, 3
	je change_down

change_right:
	; Lógica para impedir que se mueva en la dirección opuesta
	xor ax, ax
	mov al, [curr_dir]
	cmp ax, 1
	je change_left

	; Si no se está moviendo en el sentido opuesto, se cambia de dirección
	mov [curr_dir], 0

	mov ax, [head]
	mov dx, ax
	and dx, 111111100000b
	shr dx, 5
	inc dl
	shl dx, 5
	and ax, 11111b
	xor ax, dx
	mov [head], ax

	jmp change_end

change_left:
	xor ax, ax
	mov al, [curr_dir]
	cmp ax, 0
	je change_right

	mov [curr_dir], 1

	mov ax, [head]
	mov dx, ax
	and dx, 111111100000b
	shr dx, 5
	dec dl
	shl dx, 5
	and ax, 11111b
	xor ax, dx
	mov [head], ax

	jmp change_end

change_up:
	xor ax, ax
	mov al, [curr_dir]
	cmp ax, 3
	je change_down

	mov [curr_dir], 2

	mov ax, [head]
	mov dx, ax
	and dx, 111111100000b
	and ax, 11111b
	dec al
	xor ax, dx
	mov [head], ax

	jmp change_end

change_down:
	xor ax, ax
	mov al, [curr_dir]
	cmp ax, 2
	je change_up

	mov [curr_dir], 3

	mov ax, [head]
	mov dx, ax
	and dx, 111111100000b
	and ax, 11111b
	inc al
	xor ax, dx
	mov [head], ax

	jmp change_end

change_end:
	ret
change_dir endp


; Revisa si el usuario oprimió WASD para cambiar de dirección
check_input proc
	call readchar
	cmp dl, 0
	je not_pressed

	cmp dl, 'w'
	je up
	cmp dl, 'a'
	je left
	cmp dl, 's'
	je down
	cmp dl, 'd'
	je right

	jmp not_pressed

; En estas secciones se actualiza el registro al para el procedimiento "change_dir"
up:
	mov al, 2
	jmp move_to
left:
	mov al, 1
	jmp move_to
down:
	mov al, 3
	jmp move_to
right:
	mov al, 0
	jmp move_to

not_pressed:
	mov al, [curr_dir]
	jmp move_to
	
move_to:
	call change_dir
	ret

check_input endp


; Revisa si el usuario hizo click en los botones de control para actualizar el estado del juego
check_mouse proc
	mov bx, 0
	lee_mouse
	cmp bx, 1
	jne check_mouse_end

	mov ax,dx 		
	div [ocho] 
	xor ah,ah 			
	mov dx,ax 			

	mov ax,cx 	
	div [ocho] 		
	
	xor ah,ah 			
	mov cx,ax 			

	cmp dx, 19
	jl check_mouse_end

	cmp dx, 22
	jge check_mouse_end

	; Límites del botón pausar
	cmp cx, 3
	jl check_mouse_end

	cmp cx, 5
	jle pause_game

	; Límites del botón detener
	cmp cx, 9
	jl check_mouse_end

	cmp cx, 11
	jle stop_game

	; Límites del botón iniciar
	cmp cx, 15
	jl check_mouse_end

	cmp cx, 17
	jle play_game

	jmp check_mouse_end

pause_game:
	mov [game_running], 0
	jmp check_mouse_end

stop_game:
	mov [gameover], 1
	jmp check_mouse_end

play_game:
	mov [game_running], 1
	jmp check_mouse_end

check_mouse_end:
	ret
check_mouse endp