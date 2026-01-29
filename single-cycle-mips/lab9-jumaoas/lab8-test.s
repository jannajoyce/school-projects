jal	main
nop	
printhello:	
addi	$a2, $a1,24
loop:	
lw	$t2,0($a1)
nop	
sw	$t2,12($a0)
addi	$a1, $a1,4
bne	$a1, $a2,loop
nop	
jr	$ra
nop	
main:	
addi	$t2, $zero,16384
neg	$s4, $t2
sub	$s4, $s4, $t2
sub	$s4, $s4, $t2
sub	$s4, $s4, $t2
addi	$t3, $zero,16384
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
add	$t3, $t3, $t3
addi	$t2, $zero,72
sw	$t2,0($t3)
add	$zero, $zero, $zero
addi	$t2, $zero,101
sw	$t2,4($t3)
add	$zero, $zero, $zero
addi	$t2, $zero,108
sw	$t2,8($t3)
add	$zero, $zero, $zero
sw	$t2,12($t3)
add	$zero, $zero, $zero
addi	$t2, $zero,111
sw	$t2,16($t3)
add	$zero, $zero, $zero
addi	$t2, $zero,32
sw	$t2,20($t3)
add	$zero, $zero, $zero
add	$a0, $s4, $zero
add	$a1, $t3, $zero
jal	printhello
addi	$t2, $zero,87
sw	$t2,12($s4)
add	$zero, $zero, $zero
addi	$t2, $zero,111
sw	$t2,12($s4)
add	$zero, $zero, $zero
addi	$t2, $zero,114
sw	$t2,12($s4)
add	$zero, $zero, $zero
addi	$t2,$zero,108
sw	$t2,12($s4)
add	$zero, $zero, $zero
addi	$t2, $zero,100
sw	$t2,12($s4)
add	$zero, $zero, $zero
