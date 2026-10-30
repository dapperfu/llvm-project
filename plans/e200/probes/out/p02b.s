	.text
plain_text:
	add 3,4,5
	se_blr
	.section .text_vle_flag,"axv"
vle_flag:
	se_add 3,4
	se_blr
	.section .text_other,"ax"
other:
	se_blr
	.data
d:	.long 1
	.section .rodata_v,"av"
	.long 2
