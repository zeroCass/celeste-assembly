.eqv VGA 	0xFF000000	# endereco da mem VGA (tela 0)
.eqv finalVGA 	0xFF012C00	# ultimo end da VGA

.data
floatPixel: .word 0x3d800000	# valor float para 1 pixel dentro de um bloco de 16 pixels
zeroConstante: .word 0x00000000



player: .word
player.x: .word 0x00000000
player.y: .word 0x41200000
player.dx: .word 0x00000000
player.dy: .word 0x00000000
player.dash: .word 0x00000000 # valor 1: true or false, 	valor 2: lastTime
player.dashTime: .word 0x00000000	# fliped
# DIR: 0=idle	1=right		2=left		3=up	4=down	5=diagonal right	6=diagonal left
player.dir: .word 0x00000000
player.flp: .word 0x00000000
player.running: .word 0x00000000
player.falling: .word 0x00000000
player.jumping: .word 0x00000000
player.landed: .word 0x00000000


.text
# recebe x,y e width da matriz, e calcula o idx do PLAYER
# s0 = player 		w = a
IDX_2_MEM: #(%player, a2)
#.macro IDX_2_MEM(%player, %w):

	flw fa0,0(s0)			# ft0 = X
	flw fa1,4(s0)			# ft1 = Y
	
	mv a2,a2					# w (largura do mapa) (INT)
	fcvt.s.w fa2,a2				# converte INT para float
	
	li t0,16					# carrega TILE SIZE do MAPA
	fcvt.s.w ft0,t0				# converte 16 INT para FLOAT
	
	fmul.s fa0,fa0,ft0			# x x 16
	fmul.s fa1,fa1,ft0			# y x 16
	fmul.s fa2,fa2,ft0			# w x 16
	
	
	fmul.s ft0,fa1,fa2			# ft0 = Y * WIDTH
	fadd.s fa0,fa0,ft0			# fa0 = (Y * WIDTH) + X	
	

	fcvt.w.s a0,fa0				# converte FLOAT to INT
	li t0,0xFF000000
	add a0,a0,t0				# ENDERECO REAL DA VGA
	# RETORNA EM A0 VALOR DO ENDERECO DA VGA
EXIT_I2M: ret
#.end_macro


# player = s0 -> desenha o player de acordo com seu IDX (end mem VGA)
# a0 = IDX		a1 = COR
DRAW_PLAYER:#(%idx, %cor)	

	li t0,20					# width matriz
	li t1, 320					# t1 = 320 (largura da VGA)
	addi t1,t1,-16				# offset para proxLinha (320 - width do player)
	li t2,0						# i = 0;
	li t3,0						# j = 0;
	li t4,16					# tamanho do player
	
	
LOOP_DRW_I:
	beq t2,t4,EXIT_DRAW_P
	li t3,0						# j = 0

LOOP_DRW_J:
	
	#lb t5,0(a5)				# carrega o byte da sprite
	sb a1,0(a0)				# armazena o dado na VGA (a0)
	
	addi t3,t3,1				# j++
	addi a0,a0,1			# t0++ (endreco VGA)
	#addi a5,a5,1				# a5++ (endreco sprite)
	
	blt t3,t4,LOOP_DRW_J
	
	addi t2,t2,1				# i++
	add a0,a0,t1			# t0 (endereco) + offiset new line
	j LOOP_DRW_I

EXIT_DRAW_P: ret	













# Ajusta a posicao x,y (e/ou IDX) para que nao ultrapasse os limites do mapa
# garantido que o mapa sempre eh 20x15
# s0 = player
MAP_BOUNDARY: #(%player)
	flw fa0,0(s0)				# player.X
	flw fa1,4(s0)				# player.Y
	
	li t0,20					# MAP WIDTH 
	li t1,14					# MAP HEIGHT
	li t3,0						# variavel que diz se eh true or false
	li t4,1
	
	fcvt.s.w ft0,t0				# convert para float  20
	fcvt.s.w ft1,t1				# convert para float  14
	fcvt.s.w ft2,t3				# convert para float  0
	fcvt.s.w ft4,t4				# convert para float  1
		
X_0:flt.s t3,fa0,ft2			# se X < 0
	beqz t3,X_20				# se t3 == false, nao faz nada
	fmv.s fa0,ft2				# X = 0
	fsw fa0,0(s0)				# salva X
	j MAP_BDY_EXIT
	
X_20:	fadd.s fa3,fa0,ft4		# X + 1 (PLAYER + seu tamanho)
	fle.s t3,fa3,ft0
	bnez t3,Y_0					# se t3 == false, nao faz nada
	li t4,19					# t4 = ultima posicao valida do mapa
	fcvt.s.w ft4,t4				# convert para float
	
	fmv.s fa0,ft4				# X = 19
	fsw fa0,0(s0)				# salva X
	j MAP_BDY_EXIT
	
Y_0:	flt.s t3,fa1,ft2
	beqz t3,Y_15 		 		# se t3 == false, nao faz nada 	
	fmv.s fa1,ft2		 		# Y = 0
	fsw fa1,4(s0)				# salva Y
	
Y_15: 	fle.s t3,fa1,ft1		# Y > 15
	bnez t3,MAP_BDY_EXIT
	li t4,14					# t4 = ultima posicao valida do mapa
	fcvt.s.w ft4,t4				# convert para float
	
	fmv.s fa1,ft4				# Y = 14
	fsw fa1,4(s0)				# salva Y
	# RESETA GRAVIDADE
	flw fa2,12(s0)  			# DY
	fmv.s fa2,ft2				# DY = 0
	fsw fa2,12(s0)	 			# salva DY

	mv t0,zero
	sw t0,24(s0)				# reseta estado para IDLE
	mv t0,zero					# false
	sw t0,16(s0)				# reseta dash
	#EXIT()
	sw t0,36(s0)				# falling = false
	sw t0,40(s0)				# jumping = false
	li t0,1						# true
	sw t0,44(s0)				# landed = true

	
MAP_BDY_EXIT: ret	















# altera as coord do player (passado como arg em s0), de acordo com as teclas pressionadas
# s0 = player 	a0 = key
CONTROLLER: #(%player, %key)
	flw fa0,0(s0)				# t0 = player.X
	flw fa1,4(s0)				# t1 = player.Y
	flw fa2,8(s0) 				# a2 = player.DX
	flw fa3,12(s0) 				# a3 = player.DY

	la t1, floatPixel
	flw ft1,0(t1)				# recupera valor float de 1 pixel
	
	li t0,-1
	fcvt.s.w ft0,t0				# converte -1 para float
	fmul.s ft0,ft0,ft1			# -1* float pixel 
	
	li t2,4						# valor temp da VELOCIDADE
	fcvt.s.w ft2,t2				# converte 4 para float
	fmul.s ft0,ft0,ft2			# -negativo (aplica velocidade em Pixels para se movimentar)
	fmul.s ft1,ft1,ft2			# +positivo (aplica velocidade em Pixels para se movimentar)

	li t0, aKey
	li t1, dKey
	li t2, wKey
	li t3, eKey
	li t4, qKey
	
A:	bne a0, t0, D
	fadd.s fa0,fa0,ft0 			# X--
	li t0,2						# t0 = 2
	sw t0,24(s0)				# salva valor em player.DIR

	li t1,1						# true
	sw t1,32(s0)				# running = true
	sw t1,28(s0)				# fliped = true
	j COORD	
		
D:	bne a0, t1, W
	fadd.s fa0,fa0,ft1  		# X++
	# #define a direcao do player (RIGHT)
	li t0,1						# t0 = 1
	sw t0,24(s0)				# salva valor em player.DIR

	li t1,1						# true
	sw t1,32(s0)				# running = true
	mv t0,zero					# false
	sw t0,28(s0)				# fliped = false
	j COORD
	
W:	bne a0, t2, E
	lw t0,24(s0)
	li t1,3
	beq t0,t1,COORD

	la t0,floatPixel
	flw ft0,0(t0)				# carrega valor de 1 pixel
	li t0,-1		
	fcvt.s.w ft1,t0				# converte -1 para float
	fmul.s ft0,ft0,ft1			# pixel * -1

	li t2, 11					# speed
	fcvt.s.w ft1,t2				#converte para float

	fmul.s ft0,ft0,ft1			# VELOCITY = pixelValuee * speed
	fadd.s fa3,fa3,ft0			# DY += VELOCITY

	# #define a direcao do player (UP)
	li t0,3						# t0 = 3
	sw t0,24(s0)				# salva valor em player.DIR

	mv t0,zero					# false
	sw t0,44(s0)				# landed = true
	li t1,1						# true
	sw t1,36(s0)				# jumping = true
	j COORD



E:	bne a0,t3, Q
	# DEFINE VALOR EM DX
	#fadd.s fa2,fa2,ft1  		# DX = value
	fmv.s fa2,ft1 
	li t0,4
	fcvt.s.w ft0,t0				# converte para float
	fmul.s fa2,fa2,ft0			# escala DX value por t0

	# DEFINE VALOR EM DY
	la t0,floatPixel
	flw ft0,0(t0)				# carrega valor de 1 pixel
	li t0,-1		
	fcvt.s.w ft1,t0				# converte -1 para float
	fmul.s ft0,ft0,ft1			# pixel * -1

	li t2, 21					# speed
	fcvt.s.w ft1,t2				#converte para float

	fmul.s ft0,ft0,ft1			# VELOCITY = pixelValuee * speed
	fadd.s fa3,fa3,ft0			# DY += VELOCITY

	# #define a direcao do player (UP)
	li t0,5						# direcao para diagonal direita
	sw t0,24(s0)				# salva valor em player.DIR

	mv t0,zero					# false
	sw t0,44(s0)				# landed = true
	sw t0,28(s0)				# fliped = false
	li t1,1						# true
	sw t1,36(s0)				# jumping = true
	j COORD




Q:	bne a0,t4,CK_DASH
	# DEFINE VALOR EM DX
	fmv.s fa2,ft0 				# DX = value
	li t0,4
	fcvt.s.w ft0,t0				# converte para float
	fmul.s fa2,fa2,ft0			# escala DX value por t0

	# DEFINE VALOR EM DY
	la t0,floatPixel
	flw ft0,0(t0)				# carrega valor de 1 pixel
	li t0,-1		
	fcvt.s.w ft1,t0				# converte -1 para float
	fmul.s ft0,ft0,ft1			# pixel * -1

	li t2, 21					# speed
	fcvt.s.w ft1,t2				#converte para float

	fmul.s ft0,ft0,ft1			# VELOCITY = pixelValuee * speed
	fadd.s fa3,fa3,ft0			# DY += VELOCITY
	# #define a direcao do player (UP)

	li t0,6						# direcao para diagonal direita
	sw t0,24(s0)			# salva valor em player.DIR

	mv t0,zero					# false
	sw t0,44(s0)				# landed = true
	li t1,1						# true
	sw t1,36(s0)				# jumping = true
	sw t1,28(s0)				# fliped = true
	j COORD


# verifica teclas de dash
CK_DASH:
	lw t0,16(s0)				# carrega valor atual do dash
	bnez t0,COORD				# se dash == 1, não pode dashar novamente

	la t1, floatPixel
	flw ft1,0(t1)				# recupera valor float de 1 pixel
	
	li t0,-1
	fcvt.s.w ft0,t0				# converte -1 para float
	fmul.s ft0,ft0,ft1			# -1* float pixel 
	
	li t2,4					# valor temp da VELOCIDADE
	fcvt.s.w ft2,t2				# converte 4 para float
	fmul.s ft0,ft0,ft2			# (-) aplica velocidade em Pixels para se movimentar
	fmul.s ft1,ft1,ft2			# (+) aplica velocidade em Pixels para se movimentar

	li t0, jKey
	li t1, lKey
	li t2, iKey
	li t3, oKey
	li t4, uKey

DASH_LEFT: bne a0,t0, DASH_RIGHT
	li t0,5
	fcvt.s.w ft1,t0				# converte para float
	fmul.s ft0,ft0,ft1			# escala valor de DX
	fmv.s fa2,ft0				# DX = dash value

	li t0,2						# direcao = left
	sw t0,24(s0)				# salva valor em player.DIR

	li t1,1
	sw t1,16(s0)				# dash = true
	sw t1,28(s0)				# fliped = true
	csrr t0,3073				# tempo atual
	sw t0,20(s0)				# salva tempo atuall em dashTime
	
	j COORD

DASH_RIGHT: bne a0,t1,DASH_UP
	li t0,5
	fcvt.s.w ft0,t0				# converte para float
	fmul.s ft1,ft1,ft0			# escala valor de DX
	fmv.s fa2,ft1				# DX = dash value
	li t0,1						# direcao = right
	sw t0,24(s0)				# salva valor em player.DIR

	li t1,1
	sw t1,16(s0)				# dash = true
	csrr t0,3073				# tempo atual
	sw t0,20(s0)
	mv t0,zero
	sw t0,28(s0)				# fliped = true

	j COORD

DASH_UP: bne a0,t2,DASH_DR
	la t0,floatPixel
	flw ft0,0(t0)				# carrega valor de 1 pixel
	li t0,-1		
	fcvt.s.w ft1,t0				# converte -1 para float
	fmul.s ft0,ft0,ft1			# pixel * -1

	li t2, 11					# speed
	fcvt.s.w ft1,t2				# converte para float
	fmul.s ft0,ft0,ft1			# speed * -0.0625
	fmv.s fa3,ft0				# DY = speed * -0.0625
	li t0,3						# direcao = up
	sw t0,24(s0)				# salva direcao player.DIR

	li t0,1	
	sw t0,16(s0)				# dash = true
	csrr t0,3073				# tempo atual
	sw t0,20(s0)

	mv t0,zero					# false
	sw t0,44(s0)				# landed = true
	li t1,1						# true
	sw t1,36(s0)				# jumping = true
	j COORD

DASH_DR: bne a0,t3,DASH_EQ
	# DX
	li t0,6
	fcvt.s.w ft0,t0				# converte para float
	fmul.s ft1,ft1,ft0			# escala valor de DX
	fmv.s fa2,ft1				# DX = dash value

	# DY
	la t0,floatPixel
	flw ft0,0(t0)				# carrega valor de 1 pixel
	li t0,-1		
	fcvt.s.w ft1,t0				# converte -1 para float
	fmul.s ft0,ft0,ft1			# pixel * -1

	# 25 eh um valor ok
	li t2, 25					# speed
	fcvt.s.w ft1,t2				# converte para float
	fmul.s ft0,ft0,ft1			# speed * -0.0625
	fmv.s fa3,ft0				# DY = speed * -0.0625

	li t0,5						# direcao = diagonal direita
	sw t0,24(s0)				# salva direcao player.DIR

	li t0,1	
	sw t0,16(s0)				# dash = true
	csrr t0,3073				# tempo atual
	sw t0,20(s0)

	mv t0,zero					# false
	sw t0,44(s0)				# landed = true
	li t1,1						# true
	sw t1,36(s0)				# jumping = true
	j COORD



DASH_EQ: bne a0,t4,COORD
	# DX
	li t0,6
	fcvt.s.w ft1,t0				# converte para float
	fmul.s ft0,ft0,ft1			# escala valor de DX
	fmv.s fa2,ft0				# DX = dash value

	# DY
	la t0,floatPixel
	flw ft0,0(t0)				# carrega valor de 1 pixel
	li t0,-1		
	fcvt.s.w ft1,t0				# converte -1 para float
	fmul.s ft0,ft0,ft1			# pixel * -1

	li t2, 25					# speed
	fcvt.s.w ft1,t2				# converte para float
	fmul.s ft0,ft0,ft1			# speed * -0.0625
	fmv.s fa3,ft0				# DY = speed * -0.0625

	li t0,6						# direcao = diagonal direita
	sw t0,24(s0)				# salva direcao player.DIR

	li t0,1	
	sw t0,16(s0)				# dash = true
	csrr t0,3073				# tempo atual
	sw t0,20(s0)

	mv t0,zero					# false
	sw t0,44(s0)				# landed = true
	li t1,1						# true
	sw t1,36(s0)				# jumping = true
	j COORD


COORD:	
	fsw fa0,0(s0)
	fsw fa1,4(s0)
	fsw fa2,8(s0)
	fsw fa3,12(s0)	
EXIT_CONTROL: ret















# Aplica gravidade e move o player com base em Dx e Dy, velocity
# player vem em s0
UPDATE_PLAYER:
	flw fa0,8(s0)				# t0 = player.DX
	flw fa1,12(s0)				# t1 = player.DY

	la t2, floatPixel
	flw fa2,0(t2)				# recupera valor float de 1 pixel
	fadd.s fa1,fa1,fa2			# aplica gravidade
	#################
	lw t6,16(s0)				# pega o valor de dash
	beqz t6,ATT_COORD			# se dash for false, entao pula
	lw t6,20(s0)				# pega lastTime do dash
	li t1,250					# duracao em ms do dash
	#SLEEP(t6,t1)				# verifica se ja se passou o tempo em ms
	csrr t5,3073				# t5 = currentTIme
	sub t5,t5,t6				# t5 = currentTime - lasTime
	slt a0,t5,t1				# 
	beqz a0,ATT_COORD			# 
	#and a0,a0,t6
	#sw a0,32(%player)			# se a0 == 1, permanece no dash
	

	# se dash == true and dir == 1 || dir == 2 
	lw t0,20(s0)				# pega o valor de dash
	beqz t0,ATT_COORD			# se dash for false, entao pula

	lw t0,24(s0)				# pega direcao atual
	li t1,1
	beq t0,t1,Z_GRVT			# se direcao == right, entao esta na condicao
	li t1,2
	bne t0,t1,ATT_COORD			# se a direcao nao for nem right nem left, sai

Z_GRVT:	
	li t0,0						# DY = 0
	fcvt.s.w fa1,t0				# sem gravidade durante o dash
	j ATT_COORD	

# ENTENDER ISSO
#Z_DX:
	##sw a0,32(%player)
	#li t0,0						# DX = 0
	#fcvt.s.w fa0,t0				# sem gravidade durante o dash


ATT_COORD:
	

	la t2, floatPixel
	flw fa2,0(t2)				# recupera valor float de 1 pixel
    li t6,4						# valor de deseceleracao
    fcvt.s.w ft6,t6				# convete para float
    fmul.s fa2,fa2,ft6 			# valor de deseceleracao


UPD:lw t0,24(s0)				# recupera a direcao
	li t1,1
	beq t0,t1,UPDT_RIGHT


	li t1,2
	beq t0,t1,UPDT_LEFT

	li t1,3
	beq t0,t1,UPDT_UP


	li t1,5
	beq t0,t1,UPDT_DIAG_R		# diagonal direita

	li t1,6
	beq t0,t1,UPDT_DIAG_L
	J EXIT_UPDATE_PLY

UPDT_RIGHT:
	# CALCULA DESACELERACAO -> SE DX > 0, ENTAO DX -= 1 PX
	fsub.s fa0,fa0,fa2			# DX -= 0.0625 (DX -= 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)				# ft0 = 0
	# PREVINI DE IR PARA DIRECAO OPOSTA
	flt.s t0,fa0,ft0			# se DX > 0,t0 = 0 

	# Se DX > 0, ESTA INDO PARA DIREITA E ESTA DESACELARANDO
	beqz t0,EXIT_UPDATE_PLY		# se t0 == 0, entao esta tudo ok
	# se nao, DX tem que ser 0 para Nao ir para direcao oposta
	fmv.s fa0,ft0				# DX = 0
	j EXIT_UPDATE_PLY


UPDT_LEFT:
	# CALCULA DESACELERACAO -> SE DX < 0, ENTAO DX += 1 PX
	fadd.s fa0,fa0,fa2			# DX += 0.0625 (DX += 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)				# ft0 = 0
	flt.s t0,fa0,ft0			# se DX < 0,t0 = 0

	# Se DX < 0, ESTA INDO PARA ESQUERDA E ESTA DESACELARANDO
	bnez t0,EXIT_UPDATE_PLY		# se t0 == 1, entao esta tudo ok
	# se nao, DX tem que ser 0 para Nao ir para direcao oposta
	fmv.s fa0,ft0				# DX = 0
	j EXIT_UPDATE_PLY


UPDT_UP:
	# CALCULA DESACELERACAO -> SE DY < 0, ENTAO DY += 1 PX
	#fadd.s fa1,fa1,fa2			# DY += 0.0625 (DY += 1 px)
	j EXIT_UPDATE_PLY

UPDT_DOWN:
	# CALCULA DESACELERACAO -> SE DY > 0, ENTAO DY -= 1 PX
	fsub.s fa1,fa1,fa2			# DY -= 0.0625 (DY -= 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)				# ft0 = 0
	flt.s t0,fa1,ft0			# se DY >= 0, t0 = 0

	# Se DY >= 0, ESTA INDO PARA BAIXO E ESTA DESACELARANDO
	beqz t0,EXIT_UPDATE_PLY		# se t0 == 0, entao esta tudo ok
	# se nao, DY tem que ser 0
	fmv.s fa1,ft0				# DX = 0
	j EXIT_UPDATE_PLY 



UPDT_DIAG_R:
	# CALCULA DESACELERACAO -> SE DX > 0, ENTAO DX -= 1 PX
	#fadd.s fa2,fa2,fa2			# 1 pixel * 2 (0.0625 * 2 = 0.125)

	fsub.s fa0,fa0,fa2			# DX -= 0.0625 (DX -= 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)				# ft0 = 0
	# PREVINI DE IR PARA DIRECAO OPOSTA
	flt.s t0,fa0,ft0			# se DX > 0,t0 = 0 

	# Se DX > 0, ESTA INDO PARA DIREITA E ESTA DESACELARANDO
	beqz t0,DIAG_UP_R				# se t0 == 0, entao esta tudo ok
	fmv.s fa0,ft0				# DX = 0

# CALCULA DESACELARACAO EM DY
# CALCULA DESACELERACAO -> SE DY < 0, ENTAO DY += 1 PX
DIAG_UP_R:
	fadd.s fa1,fa1,fa2			# DY += 0.0625 (DY += 1 px)
	j EXIT_UPDATE_PLY




UPDT_DIAG_L:
	# CALCULA DESACELERACAO -> SE DX < 0, ENTAO DX += 1 PX

	fadd.s fa0,fa0,fa2			# DX -= 0.0625 (DX -= 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)				# ft0 = 0
	flt.s t0,fa0,ft0			# se DX < 0,t0 = 0

	# Se DX < 0, ESTA INDO PARA ESQUERDA E ESTA DESACELARANDO
	bnez t0,DIAG_UP_L		# se t0 == 1, entao esta tudo ok
	# se nao, DX tem que ser 0 para Nao ir para direcao oposta
	fmv.s fa0,ft0				# DX = 0

# CALCULA DESACELARACAO EM DY
# CALCULA DESACELERACAO -> SE DY < 0, ENTAO DY += 1 PX
DIAG_UP_L:
	fadd.s fa1,fa1,fa2			# DY += 0.0625 (DY += 1 px)
	j EXIT_UPDATE_PLY


EXIT_UPDATE_PLY:
	flw fa2,0(s0)				# X
	flw fa3,4(s0)				# Y

	addi sp,sp,-4
	sw ra,0(sp)
	jal COLLISION
	lw ra,0(sp)
	addi sp,sp,4


	fadd.s fa2,fa2,fa0			# X += DX
	fadd.s fa3,fa3,fa1			# Y += DY

	fsw fa2,0(s0)				# salva X
	fsw fa3,4(s0)				# salva Y

	fsw fa0,8(s0)				# salva novo DX
	fsw fa1,12(s0)				# salva novo DX
	ret









# fa0 = DX	fa1 = DY
# fa2 = X	fa3 = Y
COLLISION:
	li t5,15					# equivalente a 0.999
	fcvt.s.w ft5,t5				# converte para float 
	la t4,floatPixel			# valor de 1 px (0.0625)
	flw ft4,0(t4)				# ler valor
	fmul.s ft5,ft5,ft4			# 15 x 0.0625 = 0.9375


	li t4,1
	fcvt.s.w ft4,t4				# valor 1 em float

	fadd.s ft0,fa0,fa2			# newX = X += DX
	fadd.s ft1,fa1,fa3 			# newY = Y += DY
	fadd.s ft1,ft1,ft4			# newY += 1

	addi sp,sp,-12
	sw ra,0(sp)
	fsw ft4,4(sp)
	fsw ft5,8(sp)

	jal GET_IDX

	lw ra,0(sp)
	flw ft4,4(sp)
	flw ft5,8(sp)
	addi sp,sp,12

	li t0,1						# tile 1 = parede
	beq t0,a0,COLIDE_Y			# se for true, colidiu

	fadd.s ft0,fa0,fa2			# newX = X += DX
	fadd.s ft0,ft0,ft5			# newX += 0.9375
	fadd.s ft1,fa1,fa3 			# newY = Y += DY
	fadd.s ft1,ft1,ft4			# newY += 1

	addi sp,sp,-4
	sw ra,0(sp)

	jal GET_IDX

	lw ra,0(sp)
	addi sp,sp,4

	li t0,1						# tile 1 = parede
	bne t0,a0,EXIT_COLL			# se for false, nao colidiu

COLIDE_Y: fadd.s fa3,fa3,fa1
	
	la t0,round
	flw ft5,0(t0)
	fsub.s fa3,fa3,ft5			# X -= 0.5
	fcvt.w.s a0,fa3				# trunca valor
	fcvt.s.w fa3,a0				# converte valor truncado para float

	fsw fa3,4(s0)				# salva Y
	fmv.s.x fa1,zero			# DY = 0

	mv t0,zero
	sw t0,24(s0)				# reseta estado para IDLE
	mv t0,zero					# false
	sw t0,16(s0)				# reseta dash
	#EXIT()
	sw t0,36(s0)				# falling = false
	sw t0,40(s0)				# jumping = false
	li t0,1						# true
	sw t0,44(s0)				# landed = true

EXIT_COLL: ret




