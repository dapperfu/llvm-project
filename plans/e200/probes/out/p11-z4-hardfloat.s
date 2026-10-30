	.file	"p10-abi.c"
	.section	".text","axv"
	.align 1
	.p2align 2,,3
	.globl frame_align
	.type	frame_align, @function
frame_align:
	e_stwu 1,-16(1)
	se_mflr 0
	se_stw 31,12(1)
	se_stw 0,20(1)
	se_mr 31,1
	se_lwz 7,0(1)
	se_addi 3,15
	e_andi 3,3,-16
	se_neg 3
	stwux 7,1,3
	e_addi 3,1,8
	e_bl sink
	e_addi 11,31,16
	e_lwz 0,4(11)
	se_mtlr 0
	se_li 3,0
	e_lwz 31,-4(11)
	se_mfar 1,11
	se_blr
	.size	frame_align, .-frame_align
	.align 1
	.p2align 2,,3
	.globl call_mix
	.type	call_mix, @function
call_mix:
	e_stwu 1,-48(1)
	se_mflr 0
	e_addi 9,1,24
	se_stw 0,52(1)
	e_lis 3,0x3ff8
	se_li 4,0
	e_lis 7,.LANCHOR0@ha
	e_lis 5,0x4020
	e_la 7,.LANCHOR0@l(7)
	e_li 8,3
	e_lwz 10,0(7)
	e_lwz 11,4(7)
	se_lhz 6,8(7)
	e_stw 10,24(1)
	se_lbz 7,10(7)
	e_stw 11,28(1)
	e_stb 7,34(1)
	e_sth 6,32(1)
	e_addi 10,1,32
	se_li 7,0
	e_bl dsink
	se_lwz 0,52(1)
	se_mtlr 0
	e_addi 1,1,48
	se_blr
	.size	call_mix, .-call_mix
	.align 1
	.p2align 2,,3
	.globl fadd
	.type	fadd, @function
fadd:
	efsadd 3,3,4
	se_blr
	.size	fadd, .-fadd
	.globl __adddf3
	.align 1
	.p2align 2,,3
	.globl dadd
	.type	dadd, @function
dadd:
	e_stwu 1,-8(1)
	se_mflr 0
	se_stw 0,12(1)
	e_bl __adddf3
	se_lwz 0,12(1)
	se_mtlr 0
	se_addi 1,8
	se_blr
	.size	dadd, .-dadd
	.align 1
	.p2align 2,,3
	.globl ret_struct
	.type	ret_struct, @function
ret_struct:
	e_lis 7,.LANCHOR0@ha
	e_la 7,.LANCHOR0@l(7)
	se_lwz 0,16(7)
	se_lwz 4,20(7)
	se_lwz 5,24(7)
	se_stw 0,0(3)
	se_lwz 7,28(7)
	se_stw 4,4(3)
	se_stw 5,8(3)
	se_stw 7,12(3)
	se_blr
	.size	ret_struct, .-ret_struct
	.globl __fixdfsi
	.align 1
	.p2align 2,,3
	.globl va
	.type	va, @function
va:
	e_stwu 1,-64(1)
	se_mflr 0
	se_stw 31,60(1)
	e_stw 0,68(1)
	se_mr 31,4
	se_stw 4,28(1)
	se_stw 5,32(1)
	se_stw 6,36(1)
	se_stw 7,40(1)
	se_lwz 3,32(1)
	e_addi 7,1,72
	se_lwz 4,36(1)
	se_stw 7,12(1)
	e_stw 8,44(1)
	e_addi 7,1,24
	e_stw 9,48(1)
	se_stw 7,16(1)
	e_stw 10,52(1)
	se_li 7,2
	se_stb 7,8(1)
	e_bl __fixdfsi
	e_lwz 0,68(1)
	se_mtlr 0
	se_add 3,31
	se_lwz 31,60(1)
	e_addi 1,1,64
	se_blr
	.size	va, .-va
	.align 1
	.p2align 2,,3
	.globl mul64
	.type	mul64, @function
mul64:
	mullw 7,3,6
	se_mullw 5,4
	mulhwu 3,4,6
	add 5,7,5
	se_mullw 4,6
	add 3,5,3
	se_blr
	.size	mul64, .-mul64
	.align 1
	.p2align 2,,3
	.globl big_const
	.type	big_const, @function
big_const:
	e_lis 3,0x1234
	e_or2i 3,22136
	se_blr
	.size	big_const, .-big_const
	.align 1
	.p2align 2,,3
	.globl loop_sum
	.type	loop_sum, @function
loop_sum:
	se_cmpi 4,0
	e_ble 0,.L16
	se_slwi 4, 2
	e_addi 7,3,-4
	e_addi 4,4,-4
	se_li 3,0
	se_srwi 4,2
	se_addi 4,1
	se_mtctr 4
.L15:
	e_lwzu 6,4(7)
	se_add 3,6
	e_bdnz .L15
	se_blr
.L16:
	se_li 3,0
	se_blr
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
