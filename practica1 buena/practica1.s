.globl main

.data

frase: .asciiz "Mis hermanos, veo en vuestros ojos el mismo miedo que encogeria mi propio corazon \n"
pulsacion: .asciiz "[Pulsacion("
num:	.space 4
cierre: .asciiz ") = "
corchete: .asciiz "]"
separador: .asciiz " : "
askhour: .asciiz "\n Indique una hora por favor "
askminute: .asciiz "\n ahora indique los minutos "
asksecond: .asciiz "\n por ultimo indique los segundos "
wronghour: .asciiz "\n hora incorrecta\n"
wrongminute: .asciiz "\n minuto incorrecto\n"
wrongsecond: .asciiz "\n segundo incorrecto\n"
salto: .asciiz "\n"
horaLocal: .asciiz " Hora local --> "


.data 0xFFFF0000

tcontrol: .space 4
tdata: .space 4
pcontrol: .space 4
pdata: .space 4


.text
main:
	lw $a3, tcontrol			
	ori $a3, $a3, 0x2			#habilitamos la interrupcion del registro en el bit 1(inte)
	sw $a3, tcontrol			
	mfc0 $t0, $12				#cargamos status de coprocesador 0
	ori $t0, $t0, 0x39			
	mtc0 $t0, $12				#devolvemos status a coprocesador 0 
	la $a0, frase				
	li $a3, 1000
	mtc0 $a3, $11				#cargamos el valor de actualizacion de timer en el compare

inicializa:						
	li $a1, 50000				#valor para el delay
	jal printcharac
	jal delay
	addi $a0, $a0, 1
	j  inicializa

printcharac:
	lb $t6, 0($a0)				
	beqz $t6, main				
	lw $t3, pcontrol			
	andi $t1, $t3, 1 			
	beqz $t1, printcharac		#comprobamos que el bit 0 esta a 1 para saber que la pantalla esta preparada
	sb $t6, pdata				
	
	jr $31

delay:	
	addi $a1, $a1, -1
	bnez $a1, delay 
	
	jr $31
	
CaseIntr:

	andi $a0, $k0, 0x800 		#activamos las interrupciones de teclado (iP3 (bit 12))
	beq $a0, 0x800, KbdIntr		#si se trata de una interrupcion de teclado

	andi $a0, $k0, 0x8000		#activamos interrupciones de timer
	beq $a0, 0x8000, TimerIntr	#si se trata de una interrupcion de timer
	
	jr $31
	
KbdIntr:
	la $a2, tdata				#lee la dirección de la tecla pulsada
	lw $a3, 0($a2)				
	beq $a3, 0x12, ctrlR
	
	addi $t4, $t4, 1			#contador de pulsaciones
	
	li $v0, 4					#syscall 4 (print_str)				
	la $a0, pulsacion
	syscall
	
	li $v0, 1					#syscall 1 (print_integer)
	move $a0, $t4
	syscall
	
	li $v0, 4
	la $a0, cierre
	syscall
	
	li $v0, 11					#syscall 11 (print_char)
	move $a0, $a3
	syscall
	
	li $v0, 4
	la $a0, corchete
	syscall
	
	jr $31
	
ctrlR:
	li $v0, 4
	la $a0, askhour				#primero pregunta la hora
	syscall
	
	li $v0, 5					#syscall 5 (read_integer)
	syscall
	
	bgt $v0, 23, horaIncorrecta
	
	move $s2, $v0
	
leeminuto:
	li $v0, 4
	la $a0, askminute			
	syscall
	
	li $v0, 5					#leemos los minutos 
	syscall
	
	bgt $v0, 59, minutoIncorrecto
	
	move $s1, $v0
	
leeSegundo:		
	li $v0, 4					
	la $a0, asksecond
	syscall
	
	li $v0, 5 					#leemos los segundos
	syscall
	
	bgt $v0, 59, segundosIncorrectos
	
	move $t5, $v0
	
	
	
TimerIntr:
	mtc0 $zero, $9				#reinicializamos el registro count
	addi $t5, $t5, 1			#vamos contando los segundos
	beq $t5, 60, minutes

imprime:

	li $v0, 4
	la $a0, salto				
	syscall
	
	li $v0, 4
	la $a0, horaLocal
	syscall
	
	li $v0, 1
	bgt $s2, 9, etiq1
	li $a0, 0
	syscall
	
etiq1:							# imprime segundos
	move $a0, $s2
	syscall
	
	li $v0, 4
	la $a0, separador
	syscall
	
	li $v0, 1
	bgt $s1, 9, etiq2
	li $a0, 0
	syscall
	
etiq2:							#imprime minutos
	move $a0, $s1
	syscall
	
	li $v0, 4
	la $a0, separador
	syscall
	
	li $v0, 1
	bgt $t5, 9, etiq3
	li $a0, 0
	syscall
	
etiq3:							#imprime horas
	move $a0, $t5
	syscall
	
	li $v0, 4
	la $a0, salto
	syscall
	
	jr $31
	
minutes:						#contador minutos
	add $t5, $zero, $zero
	addi $s1, $s1, 1
	beq $s1, 60, hours
	j imprime

hours:							#contador horas
	add $s1, $zero, $zero
	addi $s2, $s2, 1
	bne $s2, 24, imprime
	add $s2, $zero, $zero
	j imprime
	
horaIncorrecta:
	li $v0, 4
	la $a0, wronghour
	syscall
	j ctrlR
	
minutoIncorrecto:
	li $v0, 4
	la $a0, wrongminute
	syscall
	j leeminuto

segundosIncorrectos:
	li $v0, 4
	la $a0, wrongsecond
	syscall
	j leeSegundo