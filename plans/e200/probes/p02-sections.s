# Probe P02: section flags and per-section encoding mode.
# Assembled with and without -mvle; readelf -S shows which sections get
# SHF_PPC_VLE (0x10000000) and objdump shows how each section decodes.
	.text
plain_text:
	add 3,4,5
	blr

	.section .text_vle_flag,"axv"
vle_flag:
	se_add 3,4
	se_blr

	.section .text_booke,"ax"
booke_only:
	addi 3,4,1
	blr
