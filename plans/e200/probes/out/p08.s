	.text
	lwz 3, sdav@sda21(0)
	addi 3, 0, sdav@sda21
	lwz 3, sdav@sdarel(13)
	.section .sdata,"aw"
sdav: .long 0
	.section .sdata2,"a"
sd2: .long 0
	.text
	lwz 4, sd2@sda21(0)
