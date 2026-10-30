	.file	"p10-abi.c"
	.section	".text","ax"
	.align 2
	.globl frame_align
	.type	frame_align, @function
frame_align:
	stwu 1,-16(1)
	mflr 0
	stw 31,12(1)
	stw 0,20(1)
	mr 31,1
	lwz 7,0(1)
	addi 3,3,15
	rlwinm 3,3,0,0,27
	neg 3,3
	stwux 7,1,3
	addi 3,1,8
	bl sink
	addi 11,31,16
	lwz 0,4(11)
	mtlr 0
	li 3,0
	lwz 31,-4(11)
	mr 1,11
	blr
	.size	frame_align, .-frame_align
	.align 2
	.globl call_mix
	.type	call_mix, @function
call_mix:
	stwu 1,-48(1)
	mflr 0
	addi 9,1,24
	stw 0,52(1)
	lis 3,0x3ff8
	li 4,0
	lis 7,.LANCHOR0@ha
	lis 5,0x4020
	la 7,.LANCHOR0@l(7)
	li 8,3
	lwz 10,0(7)
	lwz 11,4(7)
	lhz 6,8(7)
	stw 10,24(1)
	lbz 7,10(7)
	stw 11,28(1)
	stb 7,34(1)
	sth 6,32(1)
	addi 10,1,32
	li 7,0
	bl dsink
	lwz 0,52(1)
	mtlr 0
	addi 1,1,48
	blr
	.size	call_mix, .-call_mix
	.globl __addsf3
	.align 2
	.globl fadd
	.type	fadd, @function
fadd:
	stwu 1,-8(1)
	mflr 0
	stw 0,12(1)
	bl __addsf3
	lwz 0,12(1)
	mtlr 0
	addi 1,1,8
	blr
	.size	fadd, .-fadd
	.globl __adddf3
	.align 2
	.globl dadd
	.type	dadd, @function
dadd:
	stwu 1,-8(1)
	mflr 0
	stw 0,12(1)
	bl __adddf3
	lwz 0,12(1)
	mtlr 0
	addi 1,1,8
	blr
	.size	dadd, .-dadd
	.align 2
	.globl ret_struct
	.type	ret_struct, @function
ret_struct:
	lis 7,.LANCHOR0@ha
	la 7,.LANCHOR0@l(7)
	lwz 0,16(7)
	lwz 4,20(7)
	lwz 5,24(7)
	stw 0,0(3)
	lwz 7,28(7)
	stw 4,4(3)
	stw 5,8(3)
	stw 7,12(3)
	blr
	.size	ret_struct, .-ret_struct
	.globl __fixdfsi
	.align 2
	.globl va
	.type	va, @function
va:
	stwu 1,-64(1)
	mflr 0
	stw 31,60(1)
	stw 0,68(1)
	mr 31,4
	stw 4,28(1)
	stw 5,32(1)
	stw 6,36(1)
	stw 7,40(1)
	lwz 3,32(1)
	addi 7,1,72
	lwz 4,36(1)
	stw 7,12(1)
	stw 8,44(1)
	addi 7,1,24
	stw 9,48(1)
	stw 7,16(1)
	stw 10,52(1)
	li 7,2
	stb 7,8(1)
	bl __fixdfsi
	lwz 0,68(1)
	mtlr 0
	add 3,3,31
	lwz 31,60(1)
	addi 1,1,64
	blr
	.size	va, .-va
	.align 2
	.globl mul64
	.type	mul64, @function
mul64:
	mullw 0,3,6
	mullw 5,5,4
	mulhwu 3,4,6
	add 5,0,5
	mullw 4,4,6
	add 3,5,3
	blr
	.size	mul64, .-mul64
	.align 2
	.globl big_const
	.type	big_const, @function
big_const:
	lis 3,0x1234
	ori 3,3,22136
	blr
	.size	big_const, .-big_const
	.align 2
	.globl loop_sum
	.type	loop_sum, @function
loop_sum:
	cmpwi 0,4,0
	ble- 0,.L16
	slwi 7,4,2
	addi 6,3,-4
	addi 7,7,-4
	li 3,0
	srwi 7,7,2
	addi 7,7,1
	mtctr 7
.L15:
	lwzu 7,4(6)
	add 3,3,7
	bdnz .L15
	blr
.L16:
	li 3,0
	blr
	.size	loop_sum, .-loop_sum
	.globl sizes
	.section	.rodata
	.align 3
	.set	.LANCHOR0,. + 0
.LC0:
	.long	1
	.long	2
.LC1:
	.byte	1
	.byte	2
	.byte	3
	.zero	5
.LC2:
	.long	1072693248
	.long	0
	.long	2
	.zero	4
	.section	".data"
	.align 2
	.type	sizes, @object
	.size	sizes, 24
sizes:
	.long	8
	.long	8
	.long	8
	.long	8
	.long	8
	.long	8
	.ident	"GCC: (BLD = 1607) 4.9.4 20160726 (build.sh rev=gceb1328 s=F494 -i /opt/freescale ELe200 -V release_gceb1328_build_Fed_ELe200_ML3)"
	.gnu_attribute 4, 2
