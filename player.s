.eqv VGA 	0xFF000000	# endereco da mem VGA (tela 0)
.eqv finalVGA 	0xFF012C00	# ultimo end da VGA

.data
floatPixel: .word 0x3d800000	# valor float para 1 pixel dentro de um bloco de 16 pixels




player: .word
player.x: .word 0x41900000
player.y: .word 0x3f800000
player.dx: .word
player.dy: .word
player.oldx: .word
player.oldy: .word
player.state: .word
player.dir: .word
player.sprite: .word 


.text
# ecall para finalizar o programa
.macro EXIT()
	li a7, 10
	ecall 
.end_macro


# dado x,y e width da matriz, calcula o idx do PLAYER e retorna o end VGA correspondente
IDX:
	flw fa0,4(s0)	# ft0 = X
	flw fa1,8(s0)	# ft1 = Y
	
	mv a2,a2		# w (largura do mapa) (INT) -- !! MOV inutil para o jal, mas para macro nao
	fcvt.s.w fa2,a2		# converte INT para float
	
	li t0,16		# carrega TILE SIZE do MAPA
	fcvt.s.w ft0,t0		# converte 16 INT para FLOAT
	
	fmul.s fa0,fa0,ft0	# x x 16
	fmul.s fa1,fa1,ft0	# y x 16
	fmul.s fa2,fa2,ft0	# w x 16
	
	
	fmul.s ft0,fa1,fa2	# ft0 = Y * WIDTH
	fadd.s fa0,fa0,ft0	# fa0 = (Y * WIDTH) + X	
	

	fcvt.w.s a0,fa0		# converte FLOAT to INT
	li t0,0xFF000000
	add a0,a0,t0		# ENDERECO REAL DA VGA
	# RETORNA EM A0 VALOR DO ENDERECO DA VGA
EXIT_IDX: ret



# player = s0 -> desenha o player de acordo com seu IDX (end mem VGA)
DRAW_PLAYER:	
	li t0,20		# width matriz
	li t1, 320		# t1 = 320 (largura da VGA)
	addi t1,t1,-16		# offset para proxLinha (320 - width do player)
	li t2,0			# i = 0;
	li t3,0			# j = 0;
	li t4,16		# tamanho do player
	
	
LOOP_DRW_I:
	beq t2,t4,EXIT_DRAW_P
	li t3,0		# j = 0

LOOP_DRW_J:
	
	#lb t5,0(a5)	# carrega o byte da sprite
	sb a1,0(a0)	# armazena o dado na VGA (a0)
	
	addi t3,t3,1	# j++
	addi a0,a0,1	# t0++ (endreco VGA)
	#addi a5,a5,1	# a5++ (endreco sprite)
	
	blt t3,t4,LOOP_DRW_J
	
	addi t2,t2,1	# i++
	add a0,a0,t1	# t0 (endereco) + offiset new line
	j LOOP_DRW_I

EXIT_DRAW_P: ret		




# Ajusta a posicao x,y (e/ou IDX) para que nao ultrapasse os limites do mapa
# garantido que o mapa sempre eh 20x15
# recebe em s0 = player
MAP_BOUNDARY:
	flw fa0,4(s0)	# player.X
	flw fa1,8(s0)	# player.Y
	
	li t0,20		# MAP WIDTH 
	li t1,15		# MAP HEIGHT
	li t3,0			# variavel que diz se eh true or false
	li t4,1
	
	fcvt.s.w ft0,t0		# convert para float
	fcvt.s.w ft1,t1		# convert para float
	fcvt.s.w ft2,t3		# convert para float
	fcvt.s.w ft4,t4		# convert para float
		
X_0:	flt.s t3,fa0,ft2	# se X < 0
	beqz t3,X_20		# se t3 == false, nao faz nada
	fmv.s fa0,ft2		# X = 0
	fsw fa0,4(s0)	# salva X
	j MAP_BDY_EXIT
	
X_20:	fadd.s fa3,fa0,ft4	# X + 1 (PLAYER + seu tamanho)
	fle.s t3,fa3,ft0
	bnez t3,Y_0		# se t3 == false, nao faz nada
	li t4,19		# t4 = ultima posicao valida do mapa
	fcvt.s.w ft4,t4		# convert para float
	
	fmv.s fa0,ft4		# X = 19
	fsw fa0,4(s0)	# salva X
	j MAP_BDY_EXIT
	
Y_0:	flt.s t3,fa1,ft2
	beqz t3,Y_15 	 # se t3 == false, nao faz nada 	
	fmv.s fa1,ft2		 # Y = 0
	fsw fa1,8(s0)	 # salva Y
	
Y_15: 	fle.s t3,fa1,ft1		# Y > 15
	bnez t3,MAP_BDY_EXIT
	EXIT()
	
MAP_BDY_EXIT: ret	




# altera as coord do player (passado como arg em s0), de acordo com a tecla pressionada (passado em a0)
CONTROLLER:
	flw fa0,4(s0)	# t0 = player.X
	flw fa1,8(s0)	# t1 = player.Y
	#lw t0,8(%player)	# idx
	la t1, floatPixel
	flw ft1,0(t1)	# recupera valor float de 1 pixel
	
	li t0,-1
	fcvt.s.w ft0,t0		# converte -1 para float
	fmul.s ft0,ft0,ft1	# -1* float pixel 
	
	#mv s10,%key
	li t2, aKey
	li t3, dKey
	li t4, wKey
	li t5, sKey
	
A:	bne a0, t2, D
	fadd.s fa0,fa0,ft0 		# X--
	j COORD	
		
D:	bne a0, t3, W
	fadd.s fa0,fa0,ft1  		# X++
	j COORD
	
W:	bne a0, t4, S
	fadd.s fa1,fa1,ft0
	j COORD

S:	bne a0,t5, COORD
	fadd.s fa1,fa1,ft1
COORD:	
	fsw fa0,4(s0)	# salva X do player
	fsw fa1,8(s0)	# salva Y do player
EXIT_CONTROL: ret
