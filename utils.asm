.model small
.386
.stack 64
.data

conta 			db 		0 		;contador auxiliar
tick_ms			dw 		55 		;55 ms por cada tick del sistema, esta variable se usa para operación de MUL convertir ticks a segundos
mil				dw		1000 	;dato de valor decimal 1000 para operación DIV entre 1000
diez 			dw 		10  	;dato de valor decimal 10 para operación DIV entre 10
sesenta			db 		60 		;dato de valor decimal 60 para operación DIV entre 60
status 			db 		0 		;0 stop-pause, 1 activo

;Auxiliar para calculo de coordenadas del mouse
ocho			db 		8
;Cuando el driver del mouse no esta disponible
no_mouse		db 	'No se encuentra driver de mouse. Presione [enter] para salir$'

; Variable auxiliar para el macro "generate_random"
random_number db ?


;clear - Limpia pantalla 
clear macro
	mov ax, 0003h 	
	int 10h		
endm

; posiciona_cursor - Cambia la posición del cursor a la especificada con 'renglon' y 'columna' 
posiciona_cursor macro renglon, columna
	mov dh, renglon	
	mov dl, columna	
	mov bx, 0
	mov ax, 0200h 	
	int 10h 
endm 

;inicializa_ds_es - Inicializa el valor del registro DS y ES
inicializa_ds_es 	macro
	mov ax, @data
	mov ds, ax
	mov es, ax 
endm

;muestra_cursor_mouse - Establece la visibilidad del cursor del mouser
muestra_cursor_mouse	macro
	mov ax, 1		
	int 33h			
endm

;posiciona_cursor_mouse - Establece la posición inicial del cursor del mouse
posiciona_cursor_mouse	macro columna,renglon
	mov dx, renglon
	mov cx, columna
	mov ax, 4		
	int 33h			
endm

;oculta_cursor_teclado - Oculta la visibilidad del cursor del teclado con la interrupcion 10h / ah = 01h
oculta_cursor_teclado	macro
	mov ah, 01h 		
	mov cx, 2607h
	int 10h
endm

;apaga_cursor_parpadeo - Deshabilita el parpadeo del cursor cuando se imprimen caracteres con fondo de color
apaga_cursor_parpadeo	macro
	mov ax, 1003h
	xor bl, bl 			
  int 10h 			
endm

; Revisa si se hizo click con el mouse y actualiza los registros pertinentes con la información del click
lee_mouse	macro
	mov ax,0003h
	int 33h
endm

;comprueba_mouse - Revisa si el driver del mouse existe
comprueba_mouse 	macro
	mov ax, 0		
	int 33h			
				
endm

; Macro que genera un num. aleatorio entre [min, max]
generate_random macro min, max
    LOCAL done           ; Etiqueta local para finalizar
    push ax              ; Guardar registros utilizados
    push dx

    ; Obtener la semilla del reloj del sistema (INT 1Ah)
    mov ah, 00h
    int 1Ah              ; DX contendrá el número de ticks desde la medianoche

    ; Usar DX como semilla
    mov ax, dx           ; Cargar semilla en AX
    xor dx, dx           ; Limpiar DX para la división

    ; Calcular el rango (max - min + 1)
    mov bx, max
    sub bx, min
    inc bx               ; bx = (max - min + 1)

    ; Generar el número pseudoaleatorio en el rango
    div bx               ; AX / BX -> Resultado en AX (cociente), DX (resto)
    mov ax, dx           ; AX = DX = resto (número entre 0 y (max - min))
    add ax, min          ; Ajustar al rango [min, max]

    ; Guardar el resultado en random_number
    mov [random_number], al

    pop dx               ; Restaurar registros
    pop ax
done:
endm

.code


; Revisa si se oprimió una tecla y actualiza los registros pertinentes
readchar proc
	mov ah, 01H
	int 16H
	jnz keypressed
	xor dl, dl
	ret
keypressed:
	mov ah, 00H
	int 16H
	mov dl, al
	ret
readchar endp 