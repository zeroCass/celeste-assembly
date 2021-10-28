.eqv KDMMIO	0xFF200000	# endere�o Keyboard KDMMIO
.eqv dKey	0x00000064	# ASCII code d key
.eqv aKey	0x00000061	# ASCII code a key
.eqv wKey	0x00000077	# ASCII code w key
.eqv sKey	0x00000073	# ASCII code s key


.data


.text
# ecall para finalizar o programa
.macro EXIT()
	li a7, 10
	ecall 
.end_macro






#.text
MAIN:	
	la s0,player	# ''objeto'' player
	csrr s11,3073	# s11 = mainTimer
LOOP:
	
			# s11 = lastTime
	li a0,33	# a1 = tempo em milissegundos (para dormir)
	jal SLEEP	# se nao retornar 0 em a1, entao nao se passou o tempo
	bnez a0,LOOP	# if != 0, nao faz as coisas abaixo e pula para o loop
	
	
	la a0,MAP0
	jal PRINT_MAP0
	jal KB_INPUT	# retorna em a0 a tecla
	jal CONTROLLER
	jal MAP_BOUNDARY	# colisao com as bordas do mapa (na borda de baixo player cai e dps reseta jogo)

	li a2,20		# width matriz
	# parametros: s0 = player, a2 = largura da matriz
	jal IDX
	# retorna end VGA em a0 a partir do idx do player 		    
	
	li a1,0x07	# cor
	jal DRAW_PLAYER # recebe o end VGA e uma cor e printa na tela
	
	
	li t0,1		# fazendo looop ser infinito
	bnez t0, LOOP
	
EXIT:	EXIT()


.data
.include "MAP0.data"
.include "maps.s"
.include "player.s"

.text
############ PROCEDIMENTOS ###############


# recebe o ultimo time e a qtd de tempo do sleep (argumento vindo em A0 !!!)
# s11 = lastTime, a0 = sleepTime  -> !!! REG SALVO A11 eh alterado !!!!
SLEEP:
	csrr t0,3073	# t0 = currentTime
	sub t0,t0,s11	# currentTime - lastTime
	#li t1,%sleepTime
	slt a0,t0,a0	# a0 == 1 se tempo passado for menor que a qtd de ms necessaria (if passedTime < sleepTime)
	bnez a0, EXIT_SLEEP	# se a0 == 1, entao o temp passado eh menor e nao deve ser alterado
	csrr s11,3073	# atualiza o ultimo tempo para ser o tempo atual, pois o tempo passado eh maior que o tempo necessario (sleepTime)
	# retorna em a0 -> zero se SLEE true

EXIT_SLEEP: ret





# ler o valor da tecla presenta na Keybord MEM, e retorna em a0 o valor  ??(se for a0,  pq nao leu nada)??
KB_INPUT:
	li t0, KDMMIO			# carrega o endereco do keyboard	
	lw t1, 0(t0)			# pega o valor contido no end
	andi t1,t1,0x0001		# mascara o bit menos significativo
	mv a0,zero			# a0 = 0
	beq t1,zero,INPUT_END		# se nao houver mudanca, encerra
	lw a0,4(t0)			# a0 = tecla gravada

INPUT_END: ret
