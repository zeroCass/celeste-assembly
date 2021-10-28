.data


.text
MAIN:	
	li a0,10
        jal subrotina(a0)


EXIT:   li a7,10
        ecall 



subrotina(%valor):
	addi %valor, %valor,1
	ret