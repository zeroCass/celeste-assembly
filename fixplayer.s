.eqv VGA 	0xFF000000	# endereco da mem VGA (tela 0)
.eqv finalVGA 	0xFF012C00	# ultimo end da VGA

.data
floatPixel: .word 0x3d800000	# valor float para 1 pixel dentro de um bloco de 16 pixels
zeroConstante: .word 0x00000000




player: .word
player.x: .word 0x41900000
player.y: .word 0x3f800000
player.dx: .word 0x00000000
player.dy: .word 0x00000000
player.oldx: .word 0x00000000
player.oldy: .word 0x00000000
# player.dr: 0=idle		1=right, 2=left, 	3=up, 4=down
player.dir: .word 0x00000000
player.state: .word
player.sprite: .word 0x00000000


.text
# recebe x,y e width da matriz, e calcula o idx do PLAYER e retorna valor da mem VGA
.macro IDX_2_MEM (%player, %w)
	flw fa0,4(%player)	# ft0 = X
	flw fa1,8(%player)	# ft1 = Y
	
	mv a2,%w		# w (largura do mapa) (INT)
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
	
.end_macro



# player = s0 -> desenha o player de acordo com seu IDX (end mem VGA)
.macro DRAW_PLAYER(%idx, %cor)	

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
	sb %cor,0(%idx)	# armazena o dado na VGA (a0)
	
	addi t3,t3,1	# j++
	addi %idx,%idx,1	# t0++ (endreco VGA)
	#addi a5,a5,1	# a5++ (endreco sprite)
	
	blt t3,t4,LOOP_DRW_J
	
	addi t2,t2,1	# i++
	add %idx,%idx,t1	# t0 (endereco) + offiset new line
	j LOOP_DRW_I

EXIT_DRAW_P:		
				
.end_macro



# Ajusta a posicao x,y (e/ou IDX) para que nao ultrapasse os limites do mapa
# garantido que o mapa sempre eh 20x15
.macro MAP_BOUNDARY(%player)
	flw fa0,4(%player)	# player.X
	flw fa1,8(%player)	# player.Y
	
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
	fsw fa0,4(%player)	# salva X
	j MAP_BDY_EXIT
	
X_20:	fadd.s fa3,fa0,ft4	# X + 1 (PLAYER + seu tamanho)
	fle.s t3,fa3,ft0
	bnez t3,Y_0		# se t3 == false, nao faz nada
	li t4,19		# t4 = ultima posicao valida do mapa
	fcvt.s.w ft4,t4		# convert para float
	
	fmv.s fa0,ft4		# X = 19
	fsw fa0,4(%player)	# salva X
	j MAP_BDY_EXIT
	
Y_0:	flt.s t3,fa1,ft2
	beqz t3,Y_15 	 # se t3 == false, nao faz nada 	
	fmv.s fa1,ft2		 # Y = 0
	fsw fa1,8(%player)	 # salva Y
	
Y_15: 	fle.s t3,fa1,ft1		# Y > 15
	bnez t3,MAP_BDY_EXIT
	EXIT()
	
MAP_BDY_EXIT:	
.end_macro



# altera as coord do player (passado como arg em s0), de acordo com as teclas pressionadas
.macro CONTROLLER(%player, %key)
	flw fa0,12(%player)	# t0 = player.DX
	flw fa1,16(%player)	# t1 = player.DY
	#lw t0,8(%player)	# idx
	la t1, floatPixel
	flw ft1,0(t1)	# recupera valor float de 1 pixel
	
	li t2,18				# valor temp da VELOCIDADE
	fcvt.s.w ft2,t2		# converte 4 para float
	fmul.s ft1,ft1,ft2	# aplica velocidade em Pixels para se movimentar


	li t0,-1
	fcvt.s.w ft0,t0		# converte -1 para float
	fmul.s ft0,ft0,ft1	# -1* float pixel
	
	#mv s10,%key
	li t2, aKey
	li t3, dKey
	li t4, wKey
	li t5, sKey
	
A:	bne %key, t2, D
	fadd.s fa0,fa0,ft0 		# X--
	# #define a direcao do player (LEFT)
	li t0,2		# t0 = 0
	sw t0,28(%player)	# salva valor em player.DIR

	j COORD	
		
D:	bne %key, t3, W
	fadd.s fa0,fa0,ft1  		# X++
	# #define a direcao do player (RIGHT)
	li t0,1			# t0 = 0
	sw t0,28(%player)	# salva valor em player.DIR

	j COORD
	
W:	bne %key, t4, S
	fadd.s fa1,fa1,ft0
	# #define a direcao do player (UP)
	li t0,3			# t0 = 0
	sw t0,28(%player)	# salva valor em player.DIR

	j COORD

S:	bne %key,t5, NOTHING
	fadd.s fa1,fa1,ft1
	# #define a direcao do player (DOWN)
	li t0,4			# t0 = 0
	sw t0,28(%player)	# salva valor em player.DIR

	j COORD

NOTHING:
	# #define a direcao do player (IDLE)
	#mv t0,zero			# t0 = 0
	#sw t0,28(%player)	# salva valor em player.DIR
	#j EXIT_CONTROL

COORD:	
	fsw fa0,12(%player)	# update DX
	fsw fa1,16(%player)	# update DY
	
EXIT_CONTROL:
.end_macro


# Aplica gravidade e move o player com base em Dx e Dy, velocity
# player vem em s0
.macro UPDATE_PLAYER(%player)
	flw fa0,12(%player)	# t0 = player.DX
	flw fa1,16(%player)	# t1 = player.DY

	flw ft0,4(%player)
	flw ft1,8(%player)

	fadd.s ft0,ft0,fa0	# X += DX
	fadd.s ft1,ft1,fa1	# Y += DY

	fsw ft0,4(%player)	# salva X
	fsw ft1,8(%player)	# salva Y

	la t2, floatPixel
	flw fa2,0(t2)	# recupera valor float de 1 pixel
    li t6,4
    fcvt.s.w ft6,t6
    fmul.s fa2,fa2,ft6 


	lw t0,28(%player)	# recupera a direcao
	li t1,1
	beq t0,t1,UPDT_RIGHT


	li t1,2
	beq t0,t1,UPDT_LEFT

	li t1,3
	beq t0,t1,UPDT_UP

	li t1,4
	beq t0,t1,UPDT_DOWN
	J EXIT_UPDATE_PLY

UPDT_RIGHT:
	fsub.s fa0,fa0,fa2	# DX -= 0.0625 (DX -= 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)	# ft0 = 0
	flt.s t0,fa0,ft0	# t0 = 1 se DX < 0

	beqz t0,EXIT_UPDATE_PLY	# se t0 == 0, entao esta tudo ok
	# se nao, DX tem que ser 0
	fmv.s fa0,ft0	# DX = 0
	j EXIT_UPDATE_PLY


UPDT_LEFT:
	fadd.s fa0,fa0,fa2	# DX += 0.0625 (DX -= 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)	# ft0 = 0
	flt.s t0,fa0,ft0	# t0 = 0 se DX > 0

	bnez t0,EXIT_UPDATE_PLY	# se t0 == 1, entao esta tudo ok
	# se nao, DX tem que ser 0
	fmv.s fa0,ft0	# DX = 0
	j EXIT_UPDATE_PLY


UPDT_UP:
	fadd.s fa1,fa1,fa2	# DY += 0.0625 (DY -= 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)	# ft0 = 0
	flt.s t0,fa1,ft0	# t0 = 0 se DY < 0

	bnez t0,EXIT_UPDATE_PLY	# se t0 == 1, entao esta tudo ok
	# se nao, DY tem que ser 0
	fmv.s fa1,ft0	# DX = 0
	j EXIT_UPDATE_PLY

UPDT_DOWN:
	fsub.s fa1,fa1,fa2	# DY -= 0.0625 (DY -= 1 px)
	la t0,zeroConstante
	flw ft0,0(t0)	# ft0 = 0
	flt.s t0,fa1,ft0	# t0 = 1 se DY < 0

	beqz t0,EXIT_UPDATE_PLY	# se t0 == 0, entao esta tudo ok
	# se nao, DY tem que ser 0
	fmv.s fa1,ft0	# DX = 0
	
	
	
EXIT_UPDATE_PLY:
	fsw fa0,12(%player)	# salva novo DX
	fsw fa1,16(%player)	# salva novo DX
.end_macro


# checa colisao com todos os tipos de blocos e ajusta a posicao do player
# player vem em s0
#.macro COLLISION_PLAYER(%player, %idxMatriz)

#.end_macro


