.386
.model flat, stdcall
option casemap: none

includelib   msvcrt.lib
printf PROTO C :ptr sbyte, :VARARG	
scanf  PROTO C :ptr sbyte, :VARARG
strlen PROTO C :ptr sbyte, :VARARG
system PROTO C :ptr sbyte

.data
operand_1_len   dword 0              ;�洢��������������������ַ�������
operand_2_len   dword 0
result_len      dword 0
operand_1_str    byte   200 dup(0)	 ;�洢��������������������ַ�����ʽ(Byte)
operand_2_str    byte   200 dup(0)
result_str		 byte   400 dup(0)
operand_1_intArr  dword  200 dup(0)  ;�洢�����������������������������ʽ
operand_2_intArr  dword  200 dup(0)
result_intArr     dword  400 dup(0)
mod_num           dword  10          ;ģ��10������ÿ�γ˷��õ�������ͽ�λ
neg_flag          dword  0           ;������־

input_hint_1		byte	"Please input operant_1:", 0
input_hint_2		byte	"Please input operant_2:", 0
output_hint			byte	"operant_1 * operant_2 = ", 0
debug_info_1		byte	"Input operant_1 length(sign included):", 0
debug_info_2		byte	"Input operant_2 length(sign included):", 0
debug_info_3		byte	"Input operant_1 length(digital part):", 0
debug_info_4		byte	"Input operant_2 length(digital part):", 0
debug_info_5		byte	"Result length(digital part):", 0
input_struct		byte	"%s", 0				;���룬�����ʽ����
output_struct_int	byte	"%d", 0dh, 0ah, 0
output_struct_str	byte	"%s", 0dh, 0ah, 0  
sys_pause			db		"pause", 0

.code
str_to_intArr proc stdcall str_input:ptr byte, intArr:ptr dword,len :ptr dword    ;���ַ���ת��Ϊ��������
	mov		esi, len
	mov		ecx, dword ptr [esi]		;ecx = len
	mov		esi, str_input
	mov		edi, intArr

	add		esi, ecx
	dec		esi							;esiָ���ַ��������һ���ַ������λ��
										;[esi <- str + len - 1]
	
	mov		edx, str_input
	cmp		byte ptr [edx], '+'			;�жϵ�һ���ַ��Ƿ���'+'
	je		is_explicit_positive
	cmp		byte ptr [edx], '-'			;�жϵ�һ���ַ��Ƿ���'-'
	je		is_negative
	jmp		is_positive						;����Ϊ����'+'������

is_explicit_positive:
	dec		ecx							;����һ�ַ�Ϊ'+'��'-'��ecx-=1�ҳ���len��1
	mov		edx, len
	dec		dword ptr [edx]
	jmp		convert_loop

is_negative:
	dec		ecx
	mov		edx, len
	dec		dword ptr [edx]
	xor		neg_flag, 1					;Ϊ������������־��λȡ��
	jmp		convert_loop

is_positive:

convert_loop:							;ѭ�����ַ����е��ַ�ת��Ϊint��һһ������������
	movzx	edx, byte ptr [esi]
	sub		edx, '0'
	mov		dword ptr [edi], edx
	dec		esi
	add		edi, 4
	loop	convert_loop
	ret
str_to_intArr endp

intArr_to_str proc stdcall intArr:ptr dword, str_output:ptr byte, len:ptr dword    ;����������ת��Ϊ�ַ���
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
	dec		edi					;esiָ���ַ��������һ���ַ������λ��
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
	add		eax, dword ptr [esi+4*ebx]		;eax�洢[��һλ����Ľ�λ+��ǰλ�˻�]ֵ
	mov		edx, 0
	div		mod_num							;eax�洢�̣�edx�洢����
	add		dword ptr [esi+4*ebx+4], eax	;����Ϊ��һλ�Ľ�λ��Ԥ�ȴ洢�������һλ��
	mov		dword ptr [esi+4*ebx], edx		;������Ϊ�����ǰλ����ΧΪ0~9��
	pop		eax
	inc		ebx								;�ڲ�ѭ������
	loop	multi_loop2						;�ڲ�ѭ��operand_2_len��

	inc		eax
	add		esi, 4							;���ѭ������
	pop		ecx
	loop	multi_loop1						;���ѭ��operand_1_len��

	mov		eax, 0
	add		eax, operand_1_len	
	add		eax, operand_2_len	
	mov		ecx, eax
	dec		ecx								;�жϽ��λ�������ѭ��Ϊ����lenA+lenB-1������Ϊ1λ��

result_len_count:
	mov		edx, dword ptr [esi+4*ebx-4]
	cmp		edx, 0							;�ж����λ�Ƿ�Ϊ0
	jnz		judge_zero
	dec		eax								;��Ϊ��: result_len(eax)--
	dec		ebx
	loop	result_len_count

judge_zero:
	mov		result_len, eax
	cmp		result_len, 1						;����Ϊ0����������־��0
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
	invoke	scanf, offset input_struct, offset operand_1_str    ;���������1��������2
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

	invoke  str_to_intArr, offset operand_1_str, offset operand_1_intArr, offset operand_1_len		;��������1�Ͳ�����2���ַ���ת��Ϊ��������
	invoke  str_to_intArr, offset operand_2_str, offset operand_2_intArr, offset operand_2_len		
	invoke	printf, offset debug_info_3	
	invoke	printf, offset output_struct_int, operand_1_len
	invoke	printf, offset debug_info_4	
	invoke	printf, offset output_struct_int, operand_2_len

	invoke	multiply	;����������
	invoke	printf, offset debug_info_5
	invoke	printf, offset output_struct_int, result_len

	invoke	intArr_to_str, offset result_intArr, offset result_str, offset result_len ;���������������ת��Ϊ�ַ�������ӡ��
	invoke	printf, offset output_hint
	invoke	printf, offset output_struct_str, offset result_str
	invoke	system, addr sys_pause				;��ͣ���򣬲鿴���
	ret
main endp
end start

