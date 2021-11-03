.eqv VGA 	0xFF000000	# endereco da mem VGA (tela 0)
.eqv finalVGA 	0xFF012C00	# ultimo end da VGA

.data
round: .word 0x3f000000	# 0.5
maps: .word
map0: .word 
0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,4,
0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,1,
0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,1,1,0,0,0,
0,0,0,0,0,0,0,0,0,1,3,3,1,1,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,2,1,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,2,1,1,
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,1,1,1,0,0,0,0,1,0,0,0,0,0,0,
1,1,0,0,1,1,1,1,1,0,0,0,0,1,1,0,1,1,1,1,
1,1,3,3,1,1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,
1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,0,0,1,1,1,
1,1,1,1,1,1,1,1,0,0,0,1,1,1,1,0,0,1,1,1,


.text
# o endeco do mapa vem em a0
PRINT_MAP0:	
	addi a0,a0,8	# pega primeiro byte depois das info nCol x nLin
	li t1,VGA
	li t2,finalVGA
LOOP_PT_MAP:
	beq t1,t2,EXIT_PT_MAP
	lw t0,0(a0)
	sw t0,0(t1)
	addi a0,a0,4
	addi t1,t1,4
	j LOOP_PT_MAP
	
EXIT_PT_MAP: ret



# X = ft0		Y = ft1
GET_IDX:
	la t0,round
	flw ft5,0(t0)

	fsub.s ft0,ft0,ft5
	fsub.s ft1,ft1,ft5

	fcvt.w.s a0,ft0
	fcvt.w.s a1,ft1

	li t0,20
	mul t0,t0,a1		# y * w
	add a2,t0,a0		# a2 = (y * w) + x
	mv a1,a2			# a1 = idx

	li t0,4
	mul a2,a2,t0		# idx * 4

	la t0, map0
	add a2,a2,t0		# idx + end incial
	lw a0,0(a2)			# valor dentro de idx


EXIT_GID: ret