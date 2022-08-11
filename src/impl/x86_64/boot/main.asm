global start
extern long_mode_start
 

section .text
bits 32

start:
	mov esp, stack_top; store the top of stack into esp

	;Need to switch cpu to 64bit(long) mode
	;Need to check if cpu supports long mode

	call check_multiboot ;check if multiboot compatible
	call check_cpuid ;check for cpuid
	call check_long_mode ;use cpuid to check for long mode

	;GOING TO LONG MODE REQUIRES PAGING
	;Paging allows virtual mapping using page tables

	call setup_page_tables
	call enable_paging

	lgdt [gdt64.pointer]
	jmp gdt64.code_segment:long_mode_start

	hlt

check_multiboot:
	;Bootloeader stores multiboot in eax register
	cmp eax, 0x36d76289 ;check if magic value is stored
	jne .no_multiboot;jump if not equal
	ret; return to calling segment

.no_multiboot:
	mov al,"M" ;if no multiboot set error as 'M'
	jmp error ;jump to error handling section

check_cpuid:
	pushfd ;pushing flags to the stack
	pop eax ;popping the stack to eax register
	mov ecx, eax ;copy contents to ecx
	xor eax, 1 << 21 ;flip the bit 21
	push eax ;pushing eax to stack
	popfd ;popping stack to flags register
	pushfd ;now bring it back to stack
	pop eax ;and then to eax
	push ecx;move previous config to stack
	popfd; and move it to flags (reset flags to default)
	;Now compare eax and ecx
	cmp eax, ecx ;compare if matches
	je .no_cpuid ;cpu didnot allow us to flip the bit
	ret

.no_cpuid:
	mov al, "C" ;if no cpuid set error as 'C'
	jmp error ;jump to error handling

check_long_mode:
	mov eax, 0x80000000
	cpuid; if cpu supports long mode
	;it will store 80000001 in eax
	cmp eax, 0x80000001
	jb .no_long_mode
	;check if long mode is available
	mov eax, 0x80000001
	cpuid; this time cpu stores a val in edx reg
	test edx, 1<<29; check if bit 29(ln bit) is set
	jz .no_long_mode
	ret

.no_long_mode:
	mov al, "L"
	jmp error

setup_page_tables:
	;subroutine for paging

	mov eax, page_table_l3 ;mov the address of l3 into eax
	;cpu uses initial bits(12bits) to store flags
	or eax, 0b11 ;enable present and writeable flags
	mov [page_table_l4],eax ;put it as first entry in l4 table

	mov eax, page_table_l2 ;mov the address of l3 into eax
	;cpu uses initial bits(12bits) to store flags
	or eax, 0b11 ;enable present and writeable flags
	mov [page_table_l3],eax ;put it as first entry in l4 table

	mov ecx, 0 ; counter
.loop:

	mov eax, 0x200000 ;2MiB
	mul ecx
	or eax, 0b10000011 ;put in present and writeable flag again
	mov [page_table_l2 + ecx * 8],eax; put entry in l2 table

	inc ecx ;increment
	cmp ecx, 512 ;check if entire table is mapped
	jne .loop ;if not 512

	ret

enable_paging:
	;pass page table location to cpu
	mov eax, page_table_l4
	mov cr3, eax

	;enable PAE
	mov eax, cr4
	or eax, 1<<5 ;enable PAE flag
	mov cr4, eax

	; enable long mode
	mov ecx, 0xC0000080
	rdmsr ; read model specific register instructions
	or eax, 1 << 8; enable long mode flag
	wrmsr ;write it back

	;enable paging
	mov eax, cr0
	or eax, 1 << 31
	mov cr0, eax

	ret

error:
	; PRINT "ERR: X" Where X is the Error Code
	mov dword	[0xb8000], 0x4f524f45
	mov dword	[0xb8004], 0x4f3a4f52
	mov dword	[0xb8008], 0x4f204f20
	mov byte	[0xb800a], al ; show the ascii we stored
	hlt ; stop the cpu


section .bss
;this section contains statically allocated variables
;will be reserved when the bootloader loads our kernel

;page tables, we'll have 4 layers of page tables,
;each table would be of 4 kb

align 4096

page_table_l4:
	resb 4096

page_table_l3:
	resb 4096

page_table_l2:
	resb 4096

;esp register is used to determine the current stack frame
;(stack pointer)
stack_bottom:
	resb 4096 * 4 ;reserve 16kb of memory

stack_top:

section .rodata
;Read only data section, 
;used to define 64bit global descriptor table

gdt64:
	dq 0 ;zero entry
	;code segment 
.code_segment: equ $ - gdt64
	dq (1<<43) | (1 << 44) | (1 << 47) | (1 << 53)
	;43: Executable Flag
	;44: Descriptor Type
	;47: Present Flag
	;53: 64bit Flag
.pointer:
	dw $ - gdt64 - 1 ;$: current memory address
	dq gdt64
