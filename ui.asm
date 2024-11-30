INCLUDE proyecto\utils.asm
INCLUDE proyecto\game.asm

.model small
.386
.stack 128
.data
  ;Valor ASCII de caracteres para el marco del programa
marcoEsqInfIzq 		equ 	200d 	;'╚'
marcoEsqInfDer 		equ 	188d	;'╝'
marcoEsqSupDer 		equ 	187d	;'╗'
marcoEsqSupIzq 		equ 	201d 	;'╔'
marcoCruceVerSup	equ		203d	;'╦'
marcoCruceHorDer	equ 	185d 	;'╣'
marcoCruceVerInf	equ		202d	;'╩'
marcoCruceHorIzq	equ 	204d 	;'╠'
marcoCruce 			equ		206d	;'╬'
marcoHor 			equ 	205d 	;'═'
marcoVer 			equ 	186d 	;'║'
;Atributos de color de BIOS
;Valores de color para carácter
cNegro 			equ		00h
cAzul 			equ		01h
cVerde 			equ 	02h
cCyan 			equ 	03h
cRojo 			equ 	04h
cMagenta 		equ		05h
cCafe 			equ 	06h
cGrisClaro		equ		07h
cGrisOscuro		equ		08h
cAzulClaro		equ		09h
cVerdeClaro		equ		0Ah
cCyanClaro		equ		0Bh
cRojoClaro		equ		0Ch
cMagentaClaro	equ		0Dh
cAmarillo 		equ		0Eh
cBlanco 		equ		0Fh
;Valores de color para fondo de carácter
bgNegro 		equ		00h
bgAzul 			equ		10h
bgVerde 		equ 	20h
bgCyan 			equ 	30h
bgRojo 			equ 	40h
bgMagenta 		equ		50h
bgCafe 			equ 	60h
bgGrisClaro		equ		70h
bgGrisOscuro	equ		80h
bgAzulClaro		equ		90h
bgVerdeClaro	equ		0A0h
bgCyanClaro		equ		0B0h
bgRojoClaro		equ		0C0h
bgMagentaClaro	equ		0D0h
bgAmarillo 		equ		0E0h
bgBlanco 		equ		0F0h

;Número de columnas para el área de controles
area_controles_ancho 		equ 	20d

;Definicion de variables
;Títulos
nameStr			db 		"SNAKE"
recordStr 		db 		"HI-SCORE"
scoreStr 		db 		"SCORE"
levelStr 		db 		"LEVEL"
speedStr 		db 		"SPEED"

;Variables que sirven de parametros para el procedimiento IMPRIME_BOTON
boton_caracter 	db 		0 		;caracter a imprimir
boton_renglon 	db 		0 		;renglon de la posicion inicial del boton
boton_columna 	db 		0 		;columna de la posicion inicial del boton
boton_color		db 		0  		;color del caracter a imprimir dentro del boton
boton_bg_color	db 		0 		;color del fondo del boton

;Variables auxiliares para posicionar cursor al imprimir en pantalla
col_aux  		db 		0
ren_aux 		db 		0

imprime_caracter_color macro caracter,color,bg_color
	mov ah, 09h				;preparar AH para interrupcion, opcion 09h
	mov al, caracter 		;AL = caracter a imprimir
	mov bh, 0				;BH = numero de pagina
	mov bl, color 			
	or bl, bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx, 1				;CX = numero de veces que se imprime el caracter
							;CX es un argumento necesario para opcion 09h de int 10h
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

imprime_cadena_color macro cadena,long_cadena,color,bg_color
	mov ah,13h				;preparar AH para interrupcion, opcion 13h
	lea bp,cadena 			;BP como apuntador a la cadena a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,long_cadena		;CX = longitud de la cadena, se tomarán este número de localidades a partir del apuntador a la cadena
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

.code

; Dibuja la UI inicial
DIBUJA_UI proc
		;imprimir esquina superior izquierda del marco
		posiciona_cursor 0,0
		imprime_caracter_color marcoEsqSupIzq, cAmarillo, bgNegro
		
		;imprimir esquina superior derecha del marco
		posiciona_cursor 0,79
		imprime_caracter_color marcoEsqSupDer, cAmarillo, bgNegro
		
		;imprimir esquina inferior izquierda del marco
		posiciona_cursor 24,0
		imprime_caracter_color marcoEsqInfIzq, cAmarillo, bgNegro
		
		;imprimir esquina inferior derecha del marco
		posiciona_cursor 24,79
		imprime_caracter_color marcoEsqInfDer, cAmarillo, bgNegro
		
		;imprimir marcos horizontales, superior e inferior
		mov cx, 78 		;CX = 004Eh => CH = 00h, CL = 4Eh 

	marcos_horizontales:
		mov [col_aux], cl
		;Superior
		posiciona_cursor 0, [col_aux]
		imprime_caracter_color marcoHor, cAmarillo, bgNegro
		;Inferior
		posiciona_cursor 24, [col_aux]
		imprime_caracter_color marcoHor, cAmarillo, bgNegro

		mov cl, [col_aux]
		loop marcos_horizontales

		;imprimir marcos verticales, derecho e izquierdo
		mov cx, 23 		;CX = 0017h => CH = 00h, CL = 17h 
	marcos_verticales:
		mov [ren_aux], cl
		;Izquierdo
		posiciona_cursor [ren_aux], 0
		imprime_caracter_color marcoVer, cAmarillo, bgNegro
		;Inferior
		posiciona_cursor [ren_aux], 79
		imprime_caracter_color marcoVer, cAmarillo, bgNegro
		;Interno
		posiciona_cursor [ren_aux], area_controles_ancho
		imprime_caracter_color marcoVer, cAmarillo, bgNegro
		
		mov cl, [ren_aux]
		loop marcos_verticales

		;imprimir marcos horizontales internos
		mov cx, area_controles_ancho 		;CX = 0014h => CH = 00h, CL = 14h 
  marcos_horizontales_internos:
		mov [col_aux],cl
		;Interno izquierdo (marcador player 1)
		posiciona_cursor 8,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro

		;Interno derecho (marcador player 2)
		posiciona_cursor 16,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro

		mov cl,[col_aux]
		loop marcos_horizontales_internos

		;imprime intersecciones internas	
		posiciona_cursor 0,area_controles_ancho
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 24,area_controles_ancho
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 8,0
		imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
		posiciona_cursor 8,area_controles_ancho
		imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

		posiciona_cursor 16,0
		imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
		posiciona_cursor 16,area_controles_ancho
		imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

		;imprimir [X] para cerrar programa
		posiciona_cursor 0,17
		imprime_caracter_color '[',cAmarillo,bgNegro
		posiciona_cursor 0,18
		imprime_caracter_color 'X',cRojoClaro,bgNegro
		posiciona_cursor 0,19
		imprime_caracter_color ']',cAmarillo,bgNegro

		;imprimir título
		posiciona_cursor 0, 38
		imprime_cadena_color [nameStr], 5, cAmarillo, bgNegro

		call IMPRIME_DATOS_INICIALES
		ret
	endp

;Reinicia scores y speed, e imprime
DATOS_INICIALES proc
		mov [score], 0
		mov [hi_score], 0
		mov [speed], 0
		call IMPRIME_SCORE
		call IMPRIME_HISCORE
		call IMPRIME_SPEED
		ret
endp

;Imprime la información inicial del programa
IMPRIME_DATOS_INICIALES proc
  call DATOS_INICIALES

		;imprime cadena 'HI-SCORE'
  posiciona_cursor 3,2
  imprime_cadena_color recordStr,8,cGrisClaro,bgNegro

  ;imprime cadena 'SCORE'
  posiciona_cursor 5,2
  imprime_cadena_color scoreStr,5,cGrisClaro,bgNegro

  ;imprime cadena 'SPEED'
  posiciona_cursor 12,2
  imprime_cadena_color speedStr,5,cGrisClaro,bgNegro
  
  ;imprime viborita
  call IMPRIME_PLAYER

  ;imprime ítem
  call IMPRIME_ITEM

  ;Botón Speed down
  mov [boton_caracter], 31 		;▼
  mov [boton_color], bgAmarillo
  mov [boton_renglon], 11
  mov [boton_columna], 12
  call IMPRIME_BOTON

  ;Botón Speed UP
  mov [boton_caracter],30 		;▲
  mov [boton_color],bgAmarillo
  mov [boton_renglon],11
  mov [boton_columna],16
  call IMPRIME_BOTON

  ;Botón Pause
  mov [boton_caracter],186 		;║
  mov [boton_color],bgAmarillo
  mov [boton_renglon],19
  mov [boton_columna],3
  call IMPRIME_BOTON

  ;Botón Stop
  mov [boton_caracter],254d 		;■
  mov [boton_color],bgAmarillo
  mov [boton_renglon],19
  mov [boton_columna],9
  call IMPRIME_BOTON

  ;Botón Start
  mov [boton_caracter],16d 		;►
  mov [boton_color],bgAmarillo
  mov [boton_renglon],19
  mov [boton_columna],15
  call IMPRIME_BOTON

  ret
endp

IMPRIME_SCORE proc
  mov [ren_aux], 5
  mov [col_aux], 12
  mov bx, [score]
  call IMPRIME_SCORE_BX
  ret
endp

IMPRIME_HISCORE proc
  mov [ren_aux], 3
  mov [col_aux], 12
  mov bx, [hi_score]
  call IMPRIME_SCORE_BX
  ret
endp

IMPRIME_SCORE_BX proc
  mov ax, bx 		;AX = BX
  mov cx, 5 		;CX = 5. Se realizan 5 divisiones entre 10 para obtener los 5 dígitos
;En el bloque div10, se obtiene los dígitos del número haciendo divisiones entre 10 y se almacenan en la pila
div10:
  xor dx, dx
  div [diez]
  push dx
  loop div10
  mov cx, 5
;En el bloque imprime_digito, se recuperan los dígitos anteriores calculados para imprimirse en pantalla.
imprime_digito:
  mov [conta], cl
  posiciona_cursor [ren_aux], [col_aux]
  pop dx
  or dl, 30h
  imprime_caracter_color dl, cBlanco, bgNegro
  xor ch, ch
  mov cl, [conta]
  inc [col_aux]
  loop imprime_digito
  ret
endp

IMPRIME_SPEED proc
  ;Coordenadas en donde se imprime el valor de speed
  mov [ren_aux], 12
  mov [col_aux], 9
  ;Si speed es mayor o igual a 100, se limita a 99
  cmp [speed], 100d
  jb continua
  mov [speed], 99d
continua:
  ;posiciona el cursor en la posición a imprimir
  posiciona_cursor [ren_aux],[col_aux]
  ;Se convierte el valor de 'speed' a ASCII
  xor ah,ah 		;AH = 00h
  mov al,[speed] 	;AL = [speed]
  aam 			;AH: Decenas, AL: Unidades
  push ax 		;guarda AX temporalmente
  mov dl,ah 		;Decenas en DL
  or dl,30h 		;Convierte BCD a su ASCII
  imprime_caracter_color dl,cBlanco,bgNegro
  inc [col_aux] 	;Desplaza la columna a la derecha
  posiciona_cursor [ren_aux],[col_aux]
  pop dx 			;recupera valor de la pila
  or dl,30h  	 	;Convierte BCD a su ASCII, DL están las unidades
  imprime_caracter_color dl,cBlanco,bgNegro
  ret
endp

;Imprime viborita
IMPRIME_PLAYER proc
  call IMPRIME_HEAD 
  call IMPRIME_TAIL
  ret
endp

;Imprime objeto en pantalla
IMPRIME_ITEM proc
  posiciona_cursor [item_ren], [item_col]
  imprime_caracter_color 3, cVerdeClaro, bgNegro
  ret
endp

;Imprime la cabeza de la serpiente
IMPRIME_HEAD proc
  mov ax,[head]
  mov dx,ax
  and ax,11111b
  mov [ren_aux],al
  and dx,111111100000b
  shr dx,5
  mov [col_aux],dl
  posiciona_cursor [ren_aux],[col_aux]
  imprime_caracter_color 2,cCyanClaro,bgNegro
  ret
endp

;Imprime el cuerpo/cola de la serpiente
;Cada valor del arreglo 'tail' iniciando en el primer elemento es un elemento del cuerpo/cola
;Los valores establecidos en 0 son espacios reservados para el resto de los elementos.
;Se imprimen todos los elementos iniciando en el primero, hasta que se encuentre un 0 
IMPRIME_TAIL proc
  lea bx, [tail]
loop_tail:
  push bx
  mov ax,[bx]
  mov dx,ax
  and ax,11111b
  mov [ren_aux],al
  and dx,111111100000b
  shr dx,5
  mov [col_aux],dl
  posiciona_cursor [ren_aux],[col_aux]
  imprime_caracter_color 254,cCyanClaro,bgNegro
  pop bx
  add bx,2
  cmp word ptr [bx],0
  jne loop_tail
  ret 
endp

IMPRIME_BOTON proc
  ;background de botón
  mov ax,0600h 		;AH=06h (scroll up window) AL=00h (borrar)
  mov bh,cRojo	 	;Caracteres en color amarillo
  xor bh,[boton_color]
  mov ch,[boton_renglon]
  mov cl,[boton_columna]
  mov dh,ch
  add dh,2
  mov dl,cl
  add dl,2
  int 10h
  mov [col_aux],dl
  mov [ren_aux],dh
  dec [col_aux]
  dec [ren_aux]
  posiciona_cursor [ren_aux],[col_aux]
  imprime_caracter_color [boton_caracter],cRojo,[boton_color]
  ret 			;Regreso de llamada a procedimiento
endp	 			;Indica fin de procedimiento UI para el ensamblador


; Imprime la snake y las condiciones iniciales del juego
IMPRIME_JUEGO proc
  call IMPRIME_PLAYER
	call IMPRIME_ITEM
	call IMPRIME_SCORE
	call IMPRIME_HISCORE

  ret
IMPRIME_JUEGO endp