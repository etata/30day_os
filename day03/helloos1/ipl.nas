; hello-os
; TAB=4

		ORG		0x7c00			; 指明程序的装载地址

; 以下的记述用于标准的fat12格式的软盘

		JMP		entry
		DB		0x90
		DB		"HELLOIPL"		; 启动区的名称，可以是任意字符串，（8字节
		DW		512				; 每个扇区sector的长度512
		DB		1				; cluster 簇的大小，必须为一个扇区
		DW		1				; fat的起始位置，一般从第一个扇区开始
		DB		2				; fat的个数，必须为2
		DW		224				; 根目录的大小一般设置为224项
		DW		2880			; 该磁盘的大小，必须为2880扇区  2880*512 = 1。44m
		DB		0xf0			; 磁盘的种类（必须为0xf0
		DW		9				; FAT的长度，必须为9扇区
		DW		18				; 一个磁道track 有几个扇区，必须为18
		DW		2				;  磁头数，必须2
		DD		0				; 不使用分区，0
		DD		2880			; 重写一次磁盘大小
		DB		0,0,0x29		; 意义不明，固定
		DD		0xffffffff		; 可能是卷标号码
		DB		"HELLO-OS   "	; 磁盘名字11个字节。
		DB		"FAT12   "		; 磁盘格式化名字 8字节
		RESB	18				; 先空出18个字节

; 程序主体

entry:
		MOV		AX,0			; 初始化寄存器
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX
		MOV		ES,AX

;载入磁盘

		MOV		AX,0x0820
		MOV		ES,AX
		MOV		CH,0			; 柱面0
		MOV		DH,0			; 磁头0 
		MOV		CL,2			; 扇区2

		MOV		AH,0x02			; AH=0x02 :读盘
		MOV		AL,1			; 1个扇区
		MOV		BX,0
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 调用blos
		JC		error
		
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; SI加1
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 显示一个文字
		MOV		BX,15			; 指定字符颜色
		INT		0x10			; 调用显卡bios
		JMP		putloop
fin:
		HLT						; 让cpu停止，等待指令
		JMP		fin				; 无限循环

error:	
		MOV 	SI,msg
msg:
		DB		0x0a, 0x0a		; 换行2次
		DB		"hello, world"
		DB		0x0a			; 改行
		DB		0

		RESB	0x7dfe-$		; 填写0x00直到0x7def

		DB		0x55, 0xaa      ; 软盘的第一个分区是启动区，最后两字节必须是0x55 aa，如果没有就认识不是启动区。可能是第一个设计者随便写的吧。。。

