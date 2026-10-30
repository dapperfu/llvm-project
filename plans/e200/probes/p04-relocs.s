# Probe P04: which relocation does NXP GNU as 2.28 emit for each VLE operand
# field and specifier?  Assembled with -mvle.
	.text
f:
	e_lis 3, ext@ha
	e_add16i 3, 3, ext@l
	e_or2i 3, ext@l
	e_or2is 3, ext@h
	e_lis 4, ext@h
	e_add2i. 3, ext@l
	e_add2is 3, ext@ha
	e_and2i. 3, ext@l
	e_and2is. 3, ext@h
	e_cmp16i 3, ext@l
	e_bl ext
	se_bl ext
	e_b ext
	se_b ext
	e_bc 0, 2, ext
	se_bc 1, 2, ext
	e_add16i 3, 0, sdav@sda21
	e_li 3, sdav@sda21
	e_lwz 3, sdav@sda21(0)
	e_lwz 3, sdav@sdarel(13)
	e_add16i 3, 13, sdav@sdarel
	e_li 3, ext@l
	e_lwz 3, ext@l(3)
	e_lis 3, sdav@sdarel@ha
	.long ext
	.section .sdata,"aw"
sdav:	.long 0
