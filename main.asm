INCLUDE proyecto\ui.asm

title "Proyecto: Snake" 
	.model small
	.386		
	.stack 64 		
	.data

	.code


; Reinicia el juego a sus condiciones iniciales
restart_game proc
	restart_board
	call restart_snake
	call restart_initial_conditions
	call IMPRIME_JUEGO

	ret
restart_game endp

inicio:				

	; Se inicializan los registros ds y es, se comprueba driver del mouse y se imprime UI	
	inicializa_ds_es 	
	comprueba_mouse		
	xor ax, 0FFFFh
	jz imprime_ui

	;Si no existe el driver del mouse, se muestra un mensaje con la interrupción 21h / ah = 9
	lea dx, [no_mouse]
	mov ax, 0900h
	int 21h
	jmp fin

imprime_ui:
	clear 					
	oculta_cursor_teclado	
	apaga_cursor_parpadeo 
	call DIBUJA_UI 			
	muestra_cursor_mouse
	posiciona_cursor_mouse 10d, 0d

;Lee el mouse y avanza hasta que se haga clic en el botón izquierdo
mouse_no_clic:
	lee_mouse
	test bx, 0001h
	jnz mouse_no_clic
mouse:
	lee_mouse
conversion_mouse:
	;Leer la posición del mouse y hacer la conversión a resolución
	;80x25 (columnas x renglones) en modo texto
	mov ax,dx
	div [ocho] ;divide el valor del renglón en resolución 640x200 en donde se encuentra el mouse
						 ;para obtener el valor correspondiente en resolución 80x25
	xor ah,ah  ;Descartar el residuo de la division anterior
	mov dx,ax 

	mov ax,cx 			
	div [ocho] 			
						
	xor ah,ah 			
	mov cx,ax 

	test bx,0001h ;Para revisar si el boton izquierdo del mouse fue presionado
	jz mouse 			;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Aqui va la lógica de la posicion del mouse;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp dx, 0
	je boton_x

	cmp dx, 19
	jge botones_control

	cmp dx, 11
	jge botones_velocidad

	jmp mouse_no_clic
boton_x:
	jmp boton_x1

;Lógica para revisar si el mouse fue presionado en [X]
;[X] se encuentra en renglon 0 y entre columnas 17 y 19
boton_x1:
	cmp cx,17
	jge boton_x2
	jmp mouse_no_clic
boton_x2:
	cmp cx,19
	jbe boton_x3
	jmp mouse_no_clic
boton_x3:
	;Se cumplieron todas las condiciones
	jmp salir

botones_velocidad:
	cmp dx, 13
	jg mouse_no_clic

	; Revisamos si cae dentro de los límites del botón de bajar velocidad
	cmp cx, 12
	jl mouse_no_clic

	cmp cx, 14
	jle disminuir_velocidad

	; Revisamos si cae dentro de los límites del botón de aumentar velocidad
	cmp cx, 16
	jl mouse_no_clic

	cmp cx, 18
	jle aumentar_velocidad

	; No se cumplió ninguna condición
	jmp mouse_no_clic

aumentar_velocidad:
	inc [speed]
	jmp imprimir_velocidad

disminuir_velocidad:
	dec [speed]

imprimir_velocidad:
	call IMPRIME_SPEED
	jmp mouse_no_clic


botones_control:
	cmp dx, 22
	jge mouse_no_clic

	; Límites del botón iniciar
	cmp cx, 15
	jl mouse_no_clic

	cmp cx, 17
	jle iniciar_juego

	; No se cumplió ninguna condición	
	jmp mouse_no_clic

iniciar_juego:
	mov [gameover], 0
	mov [game_running], 1
	jmp mainloop


; LOOP DEL JUEGO
mainloop:
	; Calcular la velocidad de la snake (Velocidad = 100 - speed), donde speed es la velocidad mostrada en el menu
	mov ax, 100d
	mov bl, [speed]
	mov bh, 0
	sub ax, bx

	; Función para retrasar la siguiente ejecución del loop, necesaria para mostrar cambios en velocidad
	call delay

	; Revisamos si el usuario hizo click en el menú de control del juego
	call check_mouse
	
	; Revisar si el juego terminó, se encuentra pausado o sigue corriendo
	cmp gameover, 1
	je mainloop_end

	cmp game_running, 0
	je mainloop_pause

	jmp mainloop_run

mainloop_end:
	call restart_game
	jmp mouse_no_clic

mainloop_pause:
	call check_mouse
	cmp gameover, 1
	je mainloop_end

	cmp game_running, 1
	je mainloop_run

	jmp mainloop_pause

mainloop_run:
	remove_prev
	call shift_body
	call check_input
	call check_collision
	call check_fruit

	cmp gameover, 1
	je mainloop_end

	call IMPRIME_JUEGO
	jmp mainloop

fin:
	mov ah,08h
	int 21h 		
	cmp al,0Dh		
	jnz fin 		

salir:				
	clear 			
	mov ax,4C00h	
	int 21h	

end inicio
