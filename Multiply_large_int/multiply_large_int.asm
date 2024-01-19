.386
.model flat, stdcall
option casemap: none

includelib   msvcrt.lib
printf PROTO C :ptr sbyte, :VARARG	
scanf  PROTO C :ptr sbyte, :VARARG
strlen PROTO C :ptr sbyte, :VARARG
system PROTO C :ptr sbyte

.data
operand_1_len   dword 0              ;存储输入操作数，输出结果的字符串长度
operand_2_len   dword 0
result_len      dword 0
operand_1_str    byte   200 dup(0)	 ;存储输入操作数，输出结果的字符串形式(Byte)
operand_2_str    byte   200 dup(0)
result_str		 byte   400 dup(0)
operand_1_intArr  dword  200 dup(0)  ;存储输入操作数，输出结果的整数数组形式
operand_2_intArr  dword  200 dup(0)
result_intArr     dword  400 dup(0)
mod_num           dword  10          ;模数10，处理每次乘法得到的输出和进位
neg_flag          dword  0           ;负数标志

input_hint_1		byte	"Please input operant_1:", 0
input_hint_2		byte	"Please input operant_2:", 0
output_hint			byte	"operant_1 * operant_2 = ", 0
debug_info_1		byte	"Input operant_1 length(sign included):", 0
debug_info_2		byte	"Input operant_2 length(sign included):", 0
debug_info_3		byte	"Input operant_1 length(digital part):", 0
debug_info_4		byte	"Input operant_2 length(digital part):", 0
debug_info_5		byte	"Result length(digital part):", 0
input_struct		byte	"%s", 0				;输入，输出格式定义
output_struct_int	byte	"%d", 0dh, 0ah, 0
output_struct_str	byte	"%s", 0dh, 0ah, 0  
sys_pause			db		"pause", 0

.code
str_to_intArr proc stdcall str_input:ptr byte, intArr:ptr dword,len :ptr dword    ;将字符串转换为整数数组
	mov		esi, len
	mov		ecx, dword ptr [esi]		;ecx = len
	mov		esi, str_input
	mov		edi, intArr

	add		esi, ecx
	dec		esi							;esi指向字符串中最后一个字符（最低位）
										;[esi <- str + len - 1]
	
	mov		edx, str_input
	cmp		byte ptr [edx], '+'			;判断第一个字符是否是'+'
	je		is_explicit_positive
	cmp		byte ptr [edx], '-'			;判断第一个字符是否是'-'
	je		is_negative
	jmp		is_positive						;否则为不含'+'的正数

is_explicit_positive:
	dec		ecx							;若第一字符为'+'或'-'，ecx-=1且长度len减1
	mov		edx, len
	dec		dword ptr [edx]
	jmp		convert_loop

is_negative:
	dec		ecx
	mov		edx, len
	dec		dword ptr [edx]
	xor		neg_flag, 1					;为负数，负数标志按位取反
	jmp		convert_loop

is_positive:

convert_loop:							;循环将字符串中的字符转换为int再一一存入整数数组
	movzx	edx, byte ptr [esi]
	sub		edx, '0'
	mov		dword ptr [edi], edx
	dec		esi
	add		edi, 4
	loop	convert_loop
	ret
str_to_intArr endp

intArr_to_str proc stdcall intArr:ptr dword, str_output:ptr byte, len:ptr dword    ;将整数数组转换为字符串
	mov		esi, len
	mov		ecx, dword ptr [esi]
	mov		esi, intArr
	mov		edi, str_output
	cmp		neg_flag, 0
	je		is_positive
	mov		byte ptr [edi], '-'
	inc		edi

is_positive:
	add		edi, ecx						
	dec		edi					;esi指向字符串中最后一个字符（最低位）
								;[esi <- str + len - 1]

convert_loop:
	mov		edx, dword ptr [esi]
	add		edx, '0'
	mov		byte ptr [edi], dl
	add		esi, 4
	dec		edi
	loop	convert_loop
	ret
intArr_to_str endp

multiply proc
	mov		ecx, operand_1_len		
	mov		esi, offset result_intArr
	mov		eax, 0

multi_loop1:
	push	ecx
	mov		ecx, operand_2_len			
	mov		ebx, 0

multi_loop2:
	push	eax
	mov		eax, operand_1_intArr[4*eax]			
	mul		operand_2_intArr[4*ebx]
	add		eax, dword ptr [esi+4*ebx]		;eax存储[上一位计算的进位+当前位乘积]值
	mov		edx, 0
	div		mod_num							;eax存储商，edx存储余数
	add		dword ptr [esi+4*ebx+4], eax	;商作为下一位的进位，预先存储至结果下一位中
	mov		dword ptr [esi+4*ebx], edx		;余数作为结果当前位（范围为0~9）
	pop		eax
	inc		ebx								;内层循环步进
	loop	multi_loop2						;内层循环operand_2_len次

	inc		eax
	add		esi, 4							;外层循环步进
	pop		ecx
	loop	multi_loop1						;外层循环operand_1_len次

	mov		eax, 0
	add		eax, operand_1_len	
	add		eax, operand_2_len	
	mov		ecx, eax
	dec		ecx								;判断结果位数的最大循环为次数lenA+lenB-1（至少为1位）

result_len_count:
	mov		edx, dword ptr [esi+4*ebx-4]
	cmp		edx, 0							;判断最高位是否为0
	jnz		judge_zero
	dec		eax								;不为零: result_len(eax)--
	dec		ebx
	loop	result_len_count

judge_zero:
	mov		result_len, eax
	cmp		result_len, 1						;若答案为0，将负数标志置0
	jnz		mul_end
	mov		edx, result_intArr
	cmp		edx, 0
	jnz		mul_end
	mov		neg_flag, 0						
mul_end:
	ret
multiply endp

start:
main proc
	invoke	printf, offset input_hint_1	
	invoke	scanf, offset input_struct, offset operand_1_str    ;输入操作数1，操作数2
	invoke	printf, offset input_hint_2
	invoke  scanf, offset input_struct, offset operand_2_str
	invoke  strlen, offset operand_1_str
	mov     operand_1_len, eax
	invoke  strlen, offset operand_2_str
	mov     operand_2_len, eax
	invoke	printf, offset debug_info_1	
	invoke	printf, offset output_struct_int, operand_1_len
	invoke	printf, offset debug_info_2	
	invoke	printf, offset output_struct_int, operand_2_len

	invoke  str_to_intArr, offset operand_1_str, offset operand_1_intArr, offset operand_1_len		;将操作数1和操作数2由字符串转换为整数数组
	invoke  str_to_intArr, offset operand_2_str, offset operand_2_intArr, offset operand_2_len		
	invoke	printf, offset debug_info_3	
	invoke	printf, offset output_struct_int, operand_1_len
	invoke	printf, offset debug_info_4	
	invoke	printf, offset output_struct_int, operand_2_len

	invoke	multiply	;计算大数相乘
	invoke	printf, offset debug_info_5
	invoke	printf, offset output_struct_int, result_len

	invoke	intArr_to_str, offset result_intArr, offset result_str, offset result_len ;将结果由整数数组转换为字符串（打印）
	invoke	printf, offset output_hint
	invoke	printf, offset output_struct_str, offset result_str
	invoke	system, addr sys_pause				;暂停程序，查看输出
	ret
main endp
end start

