.eqv KDMMIO	0xFF200000	# endereco Keyboard KDMMIO
.eqv dKey	0x00000064	# ASCII code d key
.eqv aKey	0x00000061	# ASCII code a key
.eqv wKey	0x00000077	# ASCII code w key
.eqv sKey	0x00000073	# ASCII code s key
.eqv sKey	0x00000065	# ASCII code e key

.eqv lKey	0x0000006C	# ASCII code l key
.eqv jKey	0x0000006A	# ASCII code j key
.eqv iKey 	0x00000069	# ASCII code i key
.eqv kKey	0x0000006B	# ASCII code k key	


.data
.include "MAP0.data"
.include "player.s"
.include "maps.s"

.text
# ecall para finalizar o programa
.macro EXIT()
	li a7, 10
	ecall 
.end_macro


# recebe o ultimo time e a qtd de tempo do sleep (argumento vindo em A0 !!!)
.macro SLEEP(%lastTime, %sleepTime)
	csrr t0,3073	# t0 = currentTime
	sub t0, t0,%lastTime	# currentTime - lastTime
	#li t1,%sleepTime
	slt a0,t0,%sleepTime	# a0 == 1 se tempo passado for menor que a qtd de ms necessaria (if passedTime < sleepTime)
	bnez a0, EXIT_SLEEP	# se a0 == 1, entao o temp passado eh menor e nao deve ser alterado
	csrr %lastTime,3073	# atualiza o ultimo tempo para ser o tempo atual, pois o tempo passado eh maior que o tempo necessario (sleepTime)

EXIT_SLEEP:	
.end_macro


# ler o valor da tecla presenta na Keybord MEM, e retorna em a0 o valor  ??(se for a0,  pq nao leu nada)??
.macro	KB_INPUT()
	li t0, KDMMIO			# carrega o endere�o do keyboard	
	lw t1, 0(t0)			# pega o valor contido no end
	andi t1,t1,0x0001		# mascara o bit menos significativo
	mv a0,zero			# a0 = 0
	beq t1,zero,INPUT_END		# se nao houver mudanca, encerra
	lw a0,4(t0)			# a0 = tecla gravada 
INPUT_END:
.end_macro







#.text
MAIN:	
	la s0,player	# ''objeto'' player
	csrr s11,3073	# s11 = mainTimer
LOOP:
	li a0,33	# tempo em milissegundos
	SLEEP(s11,a0)	# se nao retornar 0, entao nao se passou o tempo
	bnez a0,LOOP	# if != 0, nao faz as coisas abaixo e pula para o loop
	
	
	la a0,MAP0
	PRINT_MAP0(a0)
	KB_INPUT()	# retorna em a0 a tecla
	CONTROLLER(s0, a0)
	UPDATE_PLAYER(s0)	# altera X e Y do player com base em DX  e DY
	MAP_BOUNDARY(s0)	# colisao com as bordas do mapa (na borda de baixo player cai e dps reseta jogo)
	
	li a2,20		# width matriz
	IDX_2_MEM(s0,a2)		# pega o IDX do player e retorna em a0
	

	li a1,0x07	# cor
	DRAW_PLAYER(a0,a1) # recebe o idx e uma cor e printa na tela
	

	
	li t0,1		# fazendo looop ser infinito
	bnez t0, LOOP
	
EXIT:	EXIT()
