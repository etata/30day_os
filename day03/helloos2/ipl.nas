; hello-os
; TAB=4

		ORG		0x7c00			; 指明程序的装载地址
		
CYLS	EQU		10     			;常量定义cyls=10  equal  cylinders

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

readloop:
		MOV		SI,0			; 失败次数的寄存器
retry:
		MOV		AH,0x02			; AH=0x02 :读入磁盘    //读入一个扇区
		MOV		AL,1			; 1个扇区
		MOV		BX,0
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 调用blos
		JNC		next			; 没有出错转到next    // jump if not carry 
		ADD		SI,1			; si+1                 错了，就纪录错误次数，重复5次。
		CMP		SI,5			; SI和5比较           
		JAE		error			; SI >= 5 转到error    jump if above or equal //超过5次就转到error
		MOV		AH,0x00
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 重置驱动器
		JMP		retry           ；  jump if 
next:
		MOV		AX,ES			; 把内存地址后移0x200     //移动内存位置
		ADD		AX,0x0020
		MOV		ES,AX			; 没有ADD ES,0x020 ，所以需要转一下
		ADD		CL,1			; 加1                     //移动扇区
		CMP		CL,18			; cl和18比较              //重复18次
		JBE		readloop		; CL <= 18 转到readloop   jump if below or equal
		MOV		CL,1            ; 重置1扇区
		ADD		DH,1			; 转动磁头
		CMP		DH,2			; 
		JB		readloop		; DH < 2 jump if below readloop
		MOV		DH,0
		ADD		CH,1			; 移动柱面
		CMP		CH,CYLS         ; 重复10个柱面
		JB		readloop		; CH < CYLS   
		
; 10 * 2 * 18 * 512 184320 byte = 180KB 内存  每个扇区512  ，18个扇区  反正两个磁头  10个柱面
; 一个扇区有80个柱面。或者说一个圆环柱面有18个扇区。
; 一个软盘的容量   80个柱面  2个磁头 反正两面  18个扇区  每个扇区512字节 
;  80 * 2 * 18 * 512   = 1474560byte = 1440KB   
; 一般都是  柱面 磁头 扇区定位一个地址  c0-h0-s1， 下一个扇区c0-h0-s2.为什么中间是磁头.因为快，好定位。看组成计算机原理去。
; 跳到haribote.sys的内存地址

		JMP		0xc200
		
error:	
		MOV 	SI,msg	
	
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


msg:
		DB		0x0a, 0x0a		; 换行2次
		DB		"hello, world"
		DB		0x0a			; 改行
		DB		0

		RESB	0x7dfe-$		; 填写0x00直到0x7def

		DB		0x55, 0xaa      ; 软盘的第一个分区是启动区，最后两字节必须是0x55 aa，如果没有就认识不是启动区。可能是第一个设计者随便写的吧。。。

