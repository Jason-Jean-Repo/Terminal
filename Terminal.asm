;esta estructura permite conocer el largo de un archivo, es usada en el comando mostrar
struc STAT        
    .st_dev:        resd 1       
    .st_ino:        resd 1    
    .st_mode:       resw 1    
    .st_nlink:      resw 1    
    .st_uid:        resw 1    
    .st_gid:        resw 1    
    .st_rdev:       resd 1        
    .st_size:       resd 1    
    .st_blksize:    resd 1    
    .st_blocks:     resd 1    
    .st_atime:      resd 1    
    .st_atime_nsec: resd 1    
    .st_mtime:      resd 1    
    .st_mtime_nsec: resd 1
    .st_ctime:      resd 1    
    .st_ctime_nsec: resd 1    
    .unused4:       resd 1    
    .unused5:       resd 1    
endstruc
%define sizeof(x) x %+ _size

section .bss
	;estos buffers son usados por la estructura para el comando mostrar
	FileBuff 	resb 	10
	stat 		resb 	sizeof(STAT)
	Org_Break   resd    1
	TempBuf		resd	1
	
	linea_comando  	     resb	 100	;en este buffer se guarda toda la línea que se ingresa cuando se ejecuta un comando
	temp			 	 resb	 30		;este buffer guarda temporalmente los argumentos ingresados
	temp2     			 resb  	 30		;aquí se guardan los argumentos temporalmente
	primer_argumento	 resb	 30		;aquí se guarda el primer argumento (comando a ejecutar)
	segundo_argumento    resb    30		;aquí se guarda el segundo argumento (nombre del archivo o --ayuda)
	tercer_argumento     resb    30		;aquí se guarda el tercer argumento (nombre del segundo archivo o --forzado en el caso de borrar)
	cuarto_argumento	 resb	 30		;aquí se guarda el cuarto argumento (--forzado en renombrar)
	respuesta			 resb	 2		;para la respuesta cuando se pregunta si se desea realizar la acción
	primer_documento	 resb	 100	;usado en el comando de comparar
	segundo_documento	 resb	 100	;usado en el comando de comparar
	contador 			 resb    100	;usado para llevar la cantidad de líneas en comparar

section .data
	prompt: 		db 		"JJCLI# "	;Jason & Jean Command Line Interface
	prompt_len: 	equ 	$-prompt

	;para comparar con los argumentos que se ingresen
	aceptar: 		 db 	"s"
	mostrar: 		 db 	"mostrar"
	copiar: 		 db 	"copiar"
	borrar: 		 db 	"borrar"
	renombrar: 		 db 	"renombrar"
	comparar: 		 db 	"comparar"
	salir: 			 db 	"salir"
	ayuda: 			 db 	"--ayuda"
	forzado: 		 db 	"--forzado"
	ayuda_mostrar: 	 db 	"mostrar.ayuda"
	ayuda_borrar: 	 db 	"borrar.ayuda"
	ayuda_renombrar: db		"renombrar.ayuda"
	ayuda_copiar: 	 db 	"copiar.ayuda"
	ayuda_comparar:	 db		"comparar.ayuda"

	;mensajes de error
	pregunta_seguro: 	db 		"¿Seguro que desea realizar la acción? (Ingrese 's' para sí o cualquier otra cosa para no)", 10, "JJCLI# "
	pregunta_len: 		equ 	$-pregunta_seguro
	comando_invalido: 	db 		"Comando no válido...", 10
	error_comando_len:	equ 	$-comando_invalido
	error_archivo: 		db 		"El archivo ingresado no existe...", 10
	error_archivo_len: 	equ 	$-error_archivo

	;usado para convertir de int a ascii
	resultado: 	times 16 db 0
	
section .text
	global _start

_start:
	nop
	
Terminal:
	;se limpian todos los buffers antes de ingresar cualquier comando
	call 	limpiar_buffers			
	mov 	ecx, prompt
	mov 	edx, prompt_len
	call 	DisplayText
	
	;se da la opción de ingresar algún comando
	mov 	ecx, linea_comando 
	mov 	edx, 100
	call 	ReadText
	
	;se llama para separar los argumentos ingresados en distintos buffers
	call 	Separa_argumentos
	
	;se compara el primer argumento con borrar
	mov 	ecx, [borrar]
	cmp 	[primer_argumento], ecx
	je 		Borrar 
	
	;se compara el primer argumento con mostrar
	mov 	ecx, [mostrar]
	cmp 	[primer_argumento], ecx
	je 		Mostrar
	
	;se compara el primer argumento con renombrar
	mov 	ecx, [renombrar]
	cmp 	[primer_argumento], ecx
	je 		Renombrar
	
	;se compara el primer argumento con copiar
	mov 	ecx, [copiar]
	cmp 	[primer_argumento], ecx
	je 		Copiar
	
	;se compara el primer argumento con comparar
	mov 	ecx, [comparar]
	cmp 	[primer_argumento], ecx
	je 		Comparar

	;se compara el primer argumento con salir
	mov 	ecx, [salir]
	cmp 	[primer_argumento], ecx
	je 		fin				
	
	jmp 	error_comando_invalido
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aquí llega cuando se ingresa el comando borrar
Borrar:
	;se verifica si el segundo argumento es --ayuda
	mov 	ecx, [ayuda]
	cmp		[segundo_argumento], ecx
	je		respectivo_msj_ayuda
	
	;se verifica si se ingreso el argumento --forzado
	mov		ecx, [forzado]
	cmp		[tercer_argumento], ecx
	
	;si es igual se borra de una vez
	je 		Sigue_borrar
	
	;sino se pregunta si desea realizar la acción
	jmp 	pregunta

Sigue_borrar:
	;se limpia el buffer que agarra la respuesta
	xor 	ebx,ebx
	mov 	[respuesta], ebx
	
	;se borra
	mov 	eax, 10
	mov 	ebx, segundo_argumento
	int 	80h
	
	;regresa a la terminal
	jmp 	Terminal

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aquí llega cuando se ingresa el comando mostrar
Mostrar:
	;se verifica si se ingresó el argumento --ayuda
	mov 	ecx, [ayuda]
	cmp		[segundo_argumento], ecx
	je		respectivo_msj_ayuda

;esto realiza el comando de mostrar, usa la estructura que está arriba
Sigue_mostrar:
	mov		ebx, segundo_argumento
	mov		ecx, stat
	mov		eax, 106
	int		80H

	;~ Get end of bss section
	xor		ebx, ebx
	mov		eax, 45
	int		80H
	mov		[Org_Break], eax
	mov		[TempBuf], eax
	push	eax
	
	; extend it by file size
	pop		ebx
	add		ebx, dword [stat + STAT.st_size]
	mov		eax, 45
	int		80H
	
	;se abre el archivo
	mov		ebx, segundo_argumento
	mov		ecx, 0
	xor		edx, edx
	mov		eax, 5
	int		80H
	test	eax,eax
	js		error_archivo_inexistente
    xchg    eax, esi
	
	;~ read in file to buffer
	mov     ebx, esi
	mov		ecx, [TempBuf]
	mov		edx, dword [stat + STAT.st_size]
	mov		eax, 3
	int		80H

	;~ display to terminal
	mov		ebx, 1
	mov		ecx, [TempBuf]
	mov		edx, eax
	mov		eax, 4
	int		80H
	
	;~ close file
	mov		ebx, esi 
	mov		eax, 6
	int		80H

	;~ "free" memory
	mov     ebx, [Org_Break]
    mov     eax, 45
    int     80H
	jmp 	Terminal

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aquí llega cuando se ingresa el comando renombrar
Renombrar:
	;se verifica si se ingresó el argumento --ayuda
	mov 	ecx, [ayuda]
	cmp		[segundo_argumento], ecx
	je		respectivo_msj_ayuda
	
	;se verifica si se ingresó el argumento --forzado
	mov		ecx, [forzado]
	cmp		[cuarto_argumento], ecx
	
	;si se ingresó entonces se renombra directamente
	je 		Sigue_renombrar
	
	;sino se pregunta si se desea realizar la acción
	jmp 	pregunta
	
Sigue_renombrar:
	;se limpia el buffer de la respuesta
	xor 	ebx,ebx
	mov 	[respuesta], ebx
	
	;se renombra
	mov 	eax, 38
	mov 	ebx, segundo_argumento
	mov 	ecx, tercer_argumento
	int 	80h
	
	;regresa a la terminal
	jmp 	Terminal

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aquí llega cuando se ingresa el comando copiar
Copiar:
	;se verifica si se ingresó el argumento --ayuda
	mov 	ecx, [ayuda]
	cmp		[segundo_argumento], ecx
	je		respectivo_msj_ayuda
	
	;se copia
	mov 	eax, 9
	mov 	ebx, segundo_argumento
	mov 	ecx, tercer_argumento
	int 	80h
	
	;regresa a la terminal
	jmp 	Terminal	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;aquí llega cuando se ingresa el comando comparar
Comparar:
	;se verifica si se ingresó el argumento --ayuda
	mov 	ecx, [ayuda]
	cmp		[segundo_argumento], ecx
	je		respectivo_msj_ayuda
	
	mov		ebx, segundo_argumento
	mov		ecx, 0		
	mov		eax, 5
	int		80h
	test	eax, eax
	js		error_archivo_inexistente
	
	mov		ebx, eax
	mov		ecx, primer_documento
	mov		edx, 100
	mov		eax, 3
	int 	80h
	
	mov		ebx, tercer_argumento
	mov		ecx, 0		
	mov		eax, 5
	int		80h
	test	eax, eax
	js		error_archivo_inexistente
	
	mov		ebx, eax
	mov		ecx, segundo_documento
	mov		edx, 100
	mov		eax, 3
	int		80h
	
	mov 	byte[contador], 1
    xor 	ecx,ecx
    xor 	eax,eax
    xor 	ebx,ebx
    xor 	edx,edx

.comparar:
    mov 	dl,byte[primer_documento+ecx]
    mov 	bl,byte[segundo_documento+eax]
    cmp 	dl,0
    je 		Terminal
    cmp 	bl,0
    je 		Terminal
    cmp 	dl,bl
    jne 	.msj_linea_diferente
    cmp 	bl,10
    je 		.continuar_primer_documento
    cmp 	dl,10
    je 		.continuar_segundo_documento
    cmp 	dl,bl
    je 		.continuar

;en este ciclo se mueve el ecx al proximo enter, siendo ecx el indice del buffer con la 
;informacion del primer documento recorriendo la linea hasta el final para continuar
;al terminar brinca a la parte donde se incrementa el contador de las lineas
                        
.continuar_primer_documento:
	mov 	dl,byte[primer_documento+ecx]
    cmp 	edx,0
    je  	Terminal
    cmp 	edx,10
    je 		.continuar_segundo_documento
    inc 	ecx
    jmp 	.continuar_primer_documento

;en este ciclo pasa lo mismo que en el anterior, solo cambia en que eax indica el indice 
;del buffer con la informacion del segundo documento

.continuar_segundo_documento:
    mov 	bl,byte[segundo_documento + eax]
    cmp 	ebx,0
    je  	Terminal
    cmp 	ebx,10
    je 		.incrementar_lineas
    inc 	eax
    jmp 	.continuar_segundo_documento

;cuando se imprime en cual linea de los documentos hay diferencias,
;entonces se recorren los dos documentos hasta el enter mas cercano
;incrementando el eax y ecx que son los indices para moverse por 
;los diferentes documentos

.seguir_documento1:
	mov 	dl,byte[primer_documento+ecx]
    cmp 	dl,0
    je 		Terminal
    cmp 	dl,10
    je 		.seguir_documento2
    inc 	ecx
    jmp 	.seguir_documento1
        
.seguir_documento2:
    mov 	bl,byte[segundo_documento+eax]
    cmp 	bl,0
    je 		Terminal
    cmp 	bl,10
    je 		.incrementar_lineas
    inc 	eax
    jmp 	.seguir_documento2

;Fucion que incrementa los indices de los documentos
;Se retorna al ciclo principal para seguir comparando

.continuar:
	inc 	ecx
    inc 	eax
    jmp 	.comparar
                
;ciclo para incrementar el contador de las lineas
;Lleva la cuneta de la linea actual en proceso
;se incrementa cada vez que los archivos juntos salten de linea

.incrementar_lineas:
	xor 	edx,edx
    mov 	edx,dword[contador]
    inc 	edx
    mov 	dword[contador],edx
    jmp 	.continuar

;para agregar el mensaje de que son diferentes
                 
.msj_linea_diferente:
	push 	eax
    push 	ecx
    jmp 	.lineas_diferentes

;imprime en pantalla la linea donde son diferentes entre los documntos
                
.lineas_diferentes:
	mov 	eax,dword[contador]
    call 	intAscci
    pop 	ecx
    pop 	eax
    jmp 	.seguir_documento1
                
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;esta subrutina separa los argumentos que se ingresaron en distintos buffers para hacer todas las comparaciones y saber que se
;desea hacer
Separa_argumentos:
	;estos registros se van a usar como índices para ir recorriendo la línea donde se ingresaron los argumentos 
	mov 	ecx,0			
	mov 	esi,0			
	xor 	ebx,ebx
	jmp 	Comando_actual.ciclo
	
Comando_actual:
	mov 	ecx, edi	;se guarda el índice 
	xor 	ebx, ebx
	
.ciclo:
	mov 	dl, byte[linea_comando  + ecx]		;se toma el caracter (según el valor de ecx) y se mueve al buffer temp2,
	mov 	byte[temp2 + ebx], dl				;buffer donde se guarda temporalmente el comando 
	inc 	ecx
	inc 	ebx
	
	;si se encuentra con 0 significa que es el final de la linea ingresada y no hay más argumentos
	cmp 	dl, 0 							
	je 		ciclo			
	
	;si hay un espacio significa que hay más argumentos por tomar				
	cmp 	dl, " "							
	je 		Incrementar_esi							
	jmp 	.ciclo							

;aquí llega cuando aún quedan argumentos por separar
Incrementar_esi:					
	;en el esi se encuentra el número de argumento por el que se va
	inc 	esi									
	mov 	edi, ecx							


;esta subrutina se encarga de quitar del buffer donde se ponen los argumentos temporalmente el espacio que queda o el 0 (en el caso
;de que sea el último argumento).
;esto es para evitar errores a la hora de abrir los archivos
ciclo:
	mov 	eax, -1			;esto es para asegurarse que cuando se tome el largo de los argumentos el índice empiece en 0
	call 	Obtener_largo	;se agarra el largo del argumento (queda en eax)
	mov 	ecx, 0			;índice para mover lo que haya en temp2 a temp
	dec 	eax				;se quita lo último que haya en el último espacio del argumento 
								
;se mueve al buffer temp el argumento actual pero sin el último caracter		
.ciclo2:									
	;se mueve caracter por caratcer del buffer temp2 al temp
	mov		dl, byte [temp2 + ecx]		
	mov     byte[temp + ecx],dl				
	inc		ecx		
	cmp		ecx, eax    ;para cuando sea igual que el largo del argumento
	jne 	.ciclo2
	
	;aquí se usara el valor del esi para saber a cual otro buffer mover ya el argumento "limpio" y usar ese para hacer lo que se
	;ingrese
	mov 	ecx, 0
	
	;si en el esi hay un 0 entonces se ingresó salir
	cmp 	esi, 0
	je 		mover_argumento_salir
	;si hay 1 es porque va por el por primer argumento
	cmp 	esi, 1 
	je		mover_primer_argumento
	;si hay 2 o 3 es porque va por el por segundo argumento
	cmp 	esi, 2
	je		mover_segundo_argumento
	cmp 	esi, 3
	je		mover_segundo_argumento
	;si hay 4 o 5 es porque va por el tercer argumento
	cmp 	esi, 4
	je		mover_tercer_argumento
	cmp 	esi, 5
	;si hay 6 es porque va por el cuarto argumento
	je		mover_tercer_argumento
	cmp 	esi, 6
	je		mover_cuarto_argumento
	ret
		
;se usa para saber cuantos caracteres tiene un argumento (queda en el eax)
Obtener_largo:
	inc 	eax
    cmp 	byte[temp2 + eax], 0
    jne 	Obtener_largo
    ret	
  
;cuando se ingresa el comando salir
mover_argumento_salir:
	mov 	dl, byte[temp + ecx]
	mov 	byte[primer_argumento + ecx], dl
	inc 	ecx
	;se compara con 0 para saber cuando se terminó se mover la palabra
	cmp 	dl, 0
	jne 	mover_argumento_salir
	;se limpia
	mov 	ecx, 0
	call 	limpiar_temp
	call 	limpiar_temp2
	ret   
  
;se mueve del buffer temp al buffer donde se guarda el primer argumento (siempre va a ser el comando a ejecutar)
mover_primer_argumento:
	mov 	dl, byte[temp + ecx]
	mov 	byte[primer_argumento + ecx], dl
	inc 	ecx
	;se compara con 0 para saber cuando se terminó se mover la palabra
	cmp 	dl, 0
	jne 	mover_primer_argumento
	inc 	esi
	;se limpia
	mov 	ecx, 0
	call 	limpiar_temp
	call 	limpiar_temp2
	jmp		Comando_actual  
  
;se mueve del buffer temp al buffer donde se guarda el segundo argumento (puede ser nommbre de archivo o --ayuda)
mover_segundo_argumento:
	mov 	dl, byte[temp + ecx]
	mov 	byte[segundo_argumento + ecx], dl
	inc 	ecx
	;se compara con 0 para saber cuando se terminó se mover la palabra
	cmp 	dl, 0
	jne 	mover_segundo_argumento
	inc 	esi
	;se limpia
	mov 	ecx, 0
	call 	limpiar_temp
	call 	limpiar_temp2
	jmp		Comando_actual

;se mueve del buffer temp al buffer donde se guarda el tercer argumento (ya sea el nombre de archivo o --forzado)
mover_tercer_argumento:
	mov 	dl, byte[temp + ecx]
	mov 	byte[tercer_argumento + ecx], dl
	inc 	ecx
	;se compara con 0 para saber cuando se terminó se mover la palabra
	cmp 	dl, 0
	jne 	mover_tercer_argumento	
	inc 	esi
	;se limpia
	mov 	ecx, 0
	call 	limpiar_temp
	call 	limpiar_temp2
	jmp		Comando_actual
	

;se mueve del buffer temp al buffer donde se guarda el cuarto argumento (--forzado en renombrar)
mover_cuarto_argumento:
	mov 	dl, byte[temp + ecx]
	mov 	byte[cuarto_argumento + ecx], dl
	inc 	ecx
	;se compara con 0 para saber cuando se terminó se mover la palabra
	cmp 	dl, 0
	jne 	mover_cuarto_argumento	
	;se limpia
	mov 	ecx, 0
	call 	limpiar_temp
	call 	limpiar_temp2
	ret
	
;esta subrutina redirige para mostrar el respectivo mensaje de ayuda
respectivo_msj_ayuda:
	xor 	ecx, ecx
	;se verifica cual mensaje de ayuda mostrar
	mov 	eax, [primer_argumento]
	;en el caso de borrar
	cmp 	[borrar], eax
	je 		.descripcion_borrar
	;en el caso de mostrar
	cmp 	[mostrar],eax
	je 		.descripcion_mostrar
	;en el caso de renombrar
	cmp 	[renombrar],eax
	je 		.descripcion_renombrar
	;en el caso de copiar
	cmp 	[copiar], eax
	je 		.descripcion_copiar
	;en el caso de comparar
	cmp 	[comparar], eax
	je		.descripcion_comparar
	
;imprime la ayuda de mostrar (descripcion del comando)
;se mueve al buffer que se usa para mostrar un archivo el nombre del archivo que muestra la ayuda correspondiente y luego se
;usa el comando mostrar
.descripcion_mostrar:
	mov 	dl, byte[ayuda_mostrar+ecx]
	mov 	byte[segundo_argumento+ecx],dl
	inc 	ecx
	cmp 	ecx, 13
	jne 	.descripcion_mostrar
	jmp 	Sigue_mostrar

.descripcion_renombrar:
	mov 	dl, byte[ayuda_renombrar+ecx]
	mov 	byte[segundo_argumento+ecx],dl
	inc 	ecx
	cmp 	ecx, 15
	jne 	.descripcion_renombrar
	jmp 	Sigue_mostrar

.descripcion_borrar:
	mov 	dl, byte[ayuda_borrar+ecx]
	mov 	byte[segundo_argumento+ecx],dl
	inc		ecx
	cmp 	ecx, 12
	jne 	.descripcion_borrar
	jmp 	Sigue_mostrar

.descripcion_copiar:
	mov 	dl, byte[ayuda_copiar+ecx]
	mov 	byte[segundo_argumento+ecx],dl
	inc 	ecx
	cmp 	ecx, 12
	jne 	.descripcion_copiar
	jmp 	Sigue_mostrar
	
.descripcion_comparar:
	mov 	dl, byte[ayuda_comparar+ecx]
	mov 	byte[segundo_argumento+ecx],dl
	inc 	ecx
	cmp 	ecx, 14
	jne 	.descripcion_comparar
	jmp 	Sigue_mostrar
	
;esta subrutina limpia todos los buffers que se usan, para asegurarse que cuando se ejecute un comando no ocurran errores
limpiar_buffers:
	mov 	ecx, 0
	xor		eax, eax
	call 	limpiar_linea_comando 
	call 	limpiar_temp2
	call 	limpiar_primer_argumento
	call 	limpiar_segundo_argumento
	call 	limpiar_tercer_argumento
	call 	limpiar_temp
	mov		[contador], eax
	mov 	[TempBuf], eax
	mov 	[stat], eax
	mov 	[Org_Break], eax
	mov 	[respuesta], eax
	ret

limpiar_linea_comando :
	mov 	byte[linea_comando  + ecx],0
	inc 	ecx
	cmp 	ecx, 99
	jne 	limpiar_linea_comando 
	mov 	ecx, 0
	ret

limpiar_temp2:
	mov 	byte[temp2 + ecx],0
	inc 	ecx
	cmp 	ecx, 29
	jne 	limpiar_temp2
	mov 	ecx, 0
	ret
	
limpiar_primer_argumento:
	mov 	byte[primer_argumento + ecx],0
	inc 	ecx
	cmp 	ecx, 29
	jne 	limpiar_primer_argumento
	mov 	ecx, 0
	ret

limpiar_segundo_argumento:
	mov 	byte[segundo_argumento + ecx],0
	inc 	ecx
	cmp 	ecx, 29
	jne 	limpiar_segundo_argumento
	mov 	ecx, 0
	ret
	
limpiar_tercer_argumento:
	mov 	byte[tercer_argumento + ecx],0
	inc 	ecx
	cmp 	ecx, 29
	jne 	limpiar_tercer_argumento
	mov 	ecx, 0
	ret	

limpiar_temp:
	mov 	byte[temp + ecx],0
	inc 	ecx
	cmp 	ecx, 29
	jne 	limpiar_temp
	mov 	ecx, 0
	ret			
	
;pregunta si se desea realizar la acción (en el caso de borrar y renombrar)
pregunta:
	;se pregunta
	mov 	ecx, pregunta_seguro
	mov 	edx, pregunta_len
	call 	DisplayText
	mov 	ecx, respuesta
	mov 	edx, 5
	call 	ReadText
	
	;si la respuesta fue "s" es porque sí la desea hacer, sino es porque no
	mov 	al, byte[respuesta]
	cmp		al, "s"
	;se verifica cual comando se ingresó
	je 		.verificar_comando_ingresado
	xor 	ebx,ebx
	mov 	[respuesta], ebx
	;no ejecutó el comando y regresa a la terminal
	jmp 	Terminal

;se verifica cual comando es el que se ingresó
.verificar_comando_ingresado:
	mov 	ecx, [renombrar]
	cmp 	[primer_argumento], ecx
	je 		Sigue_renombrar
	jmp 	Sigue_borrar
		
;subrutinas que imprimen mensajes de errores	
error_comando_invalido:
	mov 	ecx, comando_invalido
	mov 	edx, error_comando_len
	call 	DisplayText
	jmp 	Terminal
			
error_archivo_inexistente:
	mov 	ecx, error_archivo
	mov 	edx, error_archivo_len
	call 	DisplayText
	jmp 	Terminal	
    
;muestra un mensaje en pantalla
DisplayText:
    mov     eax, 4
    mov     ebx, 1
    int     80H 
    ret

;para inputs
ReadText:
    mov     ebx, 0
    mov     eax, 3
    int     80H
    ret

;para convertir un int a string e imprimirlo	
intAscci:
	divisiones_sucesivas:
	xor edx,edx			;Limpia la parte alta del número a dividir
	mov eax,dword[contador]		;número a trabajar
	mov ecx,10			;divisor
	xor bx,bx			;limpia el resgistro para usarlo de contador de digitos

.division:
	;la division se hara así: edx:eax/ecx
	;el resultado quedara en eax y el residuo en edx
	xor edx,edx			;limpia el residuo anterior
	div ecx				;efectua division sin signos
	push dx				;guarda en la pila el digito (dx = 16 bits)
	inc bx				;contador + 1
	test eax,eax			;fin del ciclo? (revisa si el numero ya es 0)
	jnz .division			;recursivo sino es 0 continua el ciclo

acomoda_digitos:
	mov edx,resultado		;edx apunta al buffer resultado
	mov cx,bx			;contador se copia a cx (para no perderlo)

.siguiente_digito:
	pop ax				;saca de la pila 16 bits pero solo importan 8
	or al, 30h			;lo convierte al correspondiente ascii
	mov [edx],byte al		;escribo en la direccion apuntada por edx el resultado
	inc edx				;para escribir bien la siguiente vez
	loop .siguiente_digito

.agregar_punto:
	mov [edx],byte 2Eh		;agrega un punto
	inc edx

.agregar_cambio_linea:
	mov[edx],byte 0Ah		;agrega al final un cambio de linea

imprime_numero:
	push bx	
	mov ecx,resultado
	xor edx,edx			;limpia para poner resultado
	pop dx				;cantidad de digitos
	inc dx				;para mostrar el punto
	inc dx				;para mostrar linea de agregado
	call DisplayText
	ret

;termina el programa
fin:  
    mov     eax, 1
    xor     ebx, ebx
    int     80H
	
