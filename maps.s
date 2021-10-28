.eqv VGA 	0xFF000000	# endereco da mem VGA (tela 0)
.eqv finalVGA 	0xFF012C00	# ultimo end da VGA

.data
maps: .word
map0: .word

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
