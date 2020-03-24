; haribote-os
; TAB=4

		ORG		0xc200			; 装入内存的地址
		
		MOV 	AL,0x13 		; VGA显卡 320*200*8位彩色
		MOV 	AH,0x00
		INT 	0x10
fin:                            ; 最简单的操作系统
		HLT
		JMP		fin
