;default rel
extern GetStdHandle
extern WriteConsoleA
extern ReadConsoleA
extern ExitProcess
;DJB2 hashing

section .bss
    ReadConsoleHandle resq 1
    WriteConsoleHandle resq 1
    buffer resq 10
    ast_arena   resb 64000  
 
    node_count  resq 1
    statement_count resq 1
    statement_ast resq 64000
    ;ValueStack resq 100
    ;OpStack resq 100
    VariablePool: resq 26      ; 26 slots * 8 bytes = 208 bytes total!
    mem resq 10000



section .data
    align 8
       statements  times 100 dq 0
    VarCount: dq 0              ; Tracks how many UNIQUE variables we have found so far
    ; Initialized data here
	msg db "Test walkTree",1,2,3,4,5,6,7,8,9,"hey",0
	msg_lexer  db "Lexer:  ", 10, 0
    	msg_parser db "Parser: ", 10, 0	
	msg_walktree db "WalkTree Statement"
			  times 32 db 32
			  db ":",10,0
	Dfs_msg db "DFS: ",10,0
	;Node value type and def
	NODE_TYPE   equ 0
	NODE_VALUE  equ 8
	NODE_LEFT   equ 16
	NODE_RIGHT  equ 24

	
	;;Node Types
	TYPE_INT equ 100
	FUNC_PRINT equ 10000
	PRINT_str: db 'print'
   	PRINT_len: equ $ - PRINT_str
	TYPE_NAME equ 25
	OP_Semi equ 15
	OP_ASS equ 1 ;= a=1...
	EOF equ 5
	TYPE_OP_PM equ 2 ;+- Plus Minus
	TYPE_OP_DT  equ 8 ;*/
	PTR_EMPTY  equ -1    
	PTR_LOCKED equ -2   
	PTR_PRIMITIVE equ -3
	statements_count dq 0
	statement_flag db 0
	
	
	

section .text
    global main       ; Change from _start to main for Windows GCC



main:
	call AllocSTDHandles
	mov rcx,100
	sub rsp,100
	
	;lea rdx,[rsp]
	lea rdx,[rel mem]
	call Read
	;lea rcx,[rsp]
	lea rcx,[rel mem]
	call Print

	lea rcx,[rel msg_lexer]
	call Print


	;lea rcx,[rsp]
	lea rcx,[rel mem]
	call Lex
	


	lea rcx,[rel msg_parser]
	call Print
	
	mov rdx,0
	lea rcx,[rel ast_arena]
	mov r8,0
	mov r9,1000000
	call Parser
	
	lea rcx,[rel Dfs_msg]
	call Print

	
	lea rcx,[rel ast_arena]
	add rcx,32
	call DFS

	;lea rcx,[rel msg_walktree]
	;call Print
	;lea rcx,[rel ast_arena]
	;call ArenaDump

	
	;lea rcx,[rel ast_arena]
	;add rcx,32	
	;mov rdx,0
	;call WalkTree

	lea r12,[rel statements]
	sub r12,8
	mov r13,0
	.loop:	
		
		add r12,8
		mov rdx,[r12]
	
		cmp rdx,0
		je .done
		push rdx
		;mov rcx,r13
		;call ToStr
		;mov [rel msg_walkTree]
		lea rcx,[rel msg_walktree]
		call Print
		pop rdx
		mov rcx,rdx
		mov rdx,0
		mov r8,0
		call WalkTree
		inc r13
		
		jmp .loop


		

	.done:
	add rsp,100
	
   ; mov eax, 0        ; Set return code to 0 (Success)
    ret               ; Safely exit back to the OS


ArenaDump:
	; Expects the start address of your memory arena in RCX
	push r12
	mov r12, rcx                 ; Keep the current slot pointer in R12

.Loop:
	; Check if the Node Type (NT) is 0 (End of arena)
	mov rax, qword [r12]
	cmp rax, 0
	je .Done

	; 1. Print the primary node itself
	mov rcx, r12
	call PrintNode

	; 2. Guard: Only look inside if this is an operator node (NT: 2)
	mov rax, qword [r12]
	cmp rax, 2
	jne .Next_Slot               ; If it's an integer, skip checking its children

	; 3. Safely inspect Child 1 (+16)
	mov rcx, qword [r12 + 16]
	cmp rcx, 0                   ; Make sure the pointer isn't null
	je .Skip_Child1
	call PrintNode               ; Print what Child 1 points to
.Skip_Child1:

	; 4. Safely inspect Child 2 (+24)
	mov rcx, qword [r12 + 24]
	cmp rcx, 0                   ; Make sure the pointer isn't null
	je .Next_Slot
	call PrintNode               ; Print what Child 2 points to

.Next_Slot:
	; Advance exactly 32 bytes to the next physical slot in the arena
	add r12, 32
	jmp .Loop

.Done:
	pop r12
	ret

DFS:
	; 1. Safety check: Did we get passed a null pointer?
	cmp rcx, 0
	je .Exit_DFS

	push r15
	mov r15, rcx                 ; Keep current node address safe in R15

	; 2. Print this node first (Pre-order)
	mov rcx, r15
	call PrintNode

	; 3. THE STOP SIGN: What kind of node are we looking at?
	mov rax, qword [r15]         ; Fetch Node Type (NT)
	cmp rax, 100                 ; Is it an Integer (Leaf node)?
	je .Stop_Diving              ; If yes, STOP! Do not look for children.

	; 4. Save our current operator node address onto the stack.
	;    This ensures that when the left branch finishes diving, 
	;    we can come right back here to look at the right branch.
	push r15

	; 5. DIVE LEFT SIDE
	mov rcx, qword [r15 + 16]    ; Grab whatever is at +16
	call DFS                     ; Dive down it completely

	; 6. RESTORE PARENT POINTER
	pop r15                      ; Recover our clean operator pointer

	; 7. DIVE RIGHT SIDE
	mov rcx, qword [r15 + 24]    ; Grab whatever is at +24
	call DFS                     ; Dive down it completely

.Stop_Diving:
	pop r15
.Exit_DFS:
	ret


HashName:
	push r15


	pop r15
	ret
CreateName:
	push r15
	push r14
	push r13

	mov r15,rcx
	mov r14,rdx

	xor r13,r13
	mov rcx,r14
	mov r13,r15
	sub r13,r14
        mov byte[r14+r13],0
	call Print
	

		
	mov rcx,TYPE_NAME
	movzx rdx,byte [r14]
	;mov r8,r13
	mov r8,0
	mov r9,0 
	call CreateNode
		
	mov rcx,rax
	call PrintNode
	;mov r14,r15
	;inc r14
	;mov rax,r14

	pop r13
	pop r14
	pop r15

	ret
AddToStatements:
	push r15
	mov r15,rcx
	
	mov r8,[rel statement_count]
	shl r8,3
	lea rcx,[rel statements]
	
	add rcx,r8
	mov rdx,[rcx]
	cmp rdx,0
	jne .exit
	mov r8,[rel statement_flag]
	cmp r8,1
	jge .exit
	mov qword [rcx],r15
	add qword[rel statement_count],1
	mov qword[rel statement_flag],1
	


	.exit:
	
	
	pop r15
	ret


MatchTokenRange:

    ; --- STEP 1: Calculate the Parsed Token Length ---
    mov r8, r15
    sub r8, r14         ; r8 = Token Length (End Ptr - Start Ptr)

    ; --- STEP 2: Route based on Token ID Flag in RCX ---
    cmp rcx, 1
    je .check_print
    
    ; If you add more keywords later (like IF, WHILE, LET):
    ; cmp rcx, 2
    ; je .check_if
    
    jmp .no_match       ; Unknown flag passed, reject instantly

.check_print:
    ; --- STEP 3: Validate Length First (Fast-Abort Shield) ---
    cmp r8, PRINT_len   ; Does parsed length match 'print' length (5)?
    jne .no_match       ; If lengths mismatch, it physically cannot be the word!
    
    ; --- STEP 4: Setup Hardware Byte-by-Byte Comparison ---
    mov rsi, r14        ; RSI = Source pointer (your parsed buffer string)
    lea rdi, [rel PRINT_str] ; RDI = Destination pointer (the static 'print' string)
    mov rcx, PRINT_len  ; RCX = Number of bytes to compare for the loop
    
    cld                 ; Clear Direction Flag (ensure string reads forward)
    repe cmpsb          ; REPEAT WHILE EQUAL: Compare bytes at DS:RSI and ES:RDI
    jne .no_match       ; If any byte flunked, drop out!

.matched:
    mov rax, 1          ; Match success! Return 1
    ret

.no_match:
    mov rax, 0          ; Match failed! Return 0
    ret	
Lex:
	;rcx the data stream	
	push r15
	push r14
	push r13
	
	mov r15,rcx
	mov r14,r15

	dec r15
	_loop_Lex:	
		inc r15
		mov rcx,r15
		call GetNextChar
		

		lea r8,[rel _loop_Lex]
		lea rbx,[rel _exit]
		cmp al,-1
		cmove r8,rbx

		lea rbx,[rel _Space]
		cmp al,32
		cmove r8,rbx
		
	
		lea rbx,[rel _Semi_Colon]
		cmp al,';'
		cmove r8,rbx
		
		lea rbx,[rel _EQ]
		cmp al,'='
		cmove r8,rbx
		
		
		lea rbx,[rel _OPEN_BRAK]
		cmp al,'('
		cmove r8,rbx

		lea rbx,[rel _CLOSE_BRAK]
		cmp al,')'
		cmove r8,rbx
		
		lea rbx,[rel _OP_PM]
	
		cmp     al, '+'
    		cmove   r8, rbx   
         
    		cmp     al, '-'
    		cmove   r8, rbx           		

		lea rbx,[rel _OP_DT]
	
		cmp     al, '*'
    		cmove   r8, rbx   
         
    		cmp     al, '/'
    		cmove   r8, rbx 
		
		mov     r9b, al
    		sub     r9b, '0'       
    		cmp     r9b, 9         
    		jbe     _Digit
		jmp r8

	_CLOSE_BRAK:
		mov r14,r15
		inc r14
		jmp _loop_Lex
	_OPEN_BRAK:	
		cmp r14,r15
		je .skip_eq
		;mov r14, rbx        
    		;mov r15, rdx        
    		mov rcx, 1          
    		call MatchTokenRange
    
    		cmp rax, 1
    		je .handle_print_statement   	
		jmp .skip_eq

		.handle_print_statement:

		mov rcx,FUNC_PRINT
		mov rdx,0
		mov r8,0
		mov r9,0
		call CreateNode


		mov rcx,rax
		call PrintNode



		.skip_eq:
		mov r14,r15
		jmp _loop_Lex
	_EQ:	
		
		cmp r14,r15
		je .skip_eq
		mov rcx,r15
		mov rdx,r14
		call CreateName
	
		
		.skip_eq:
		mov rcx,OP_ASS
		mov rdx,0
		mov r8,0
		mov r9,0
		call CreateNode

		
		.save_eq:

		mov rcx,rax
		call PrintNode	

		mov r14,r15
		inc r14		
		jmp _loop_Lex	
	_Digit:	
		mov rcx,r15
		call GetDigit
		add r15,rbx
		
		dec r15
		mov r14,r15

		mov rcx,TYPE_INT
		mov rdx,rax

		mov r8, PTR_LOCKED
		mov r9,PTR_PRIMITIVE
		
		call CreateNode
			
		mov rcx,rax
		mov r14,r15
		inc r14
		call PrintNode	
		jmp _loop_Lex
	

	_OP_DT:
		push rax
		;TYPE_OP_DT
		
		;.save:
		;ascii for * is 42 and / 47
		
		cmp r14,r15
		je .skip_op_dt
		mov rcx,r15
		mov rdx,r14
		call CreateName
		;mov r14,rax

		.skip_op_dt:
		pop rax
		mov rcx,TYPE_OP_DT
		sub al,42
		movzx rdx,al
		mov r8,0
		mov r9,0	
		call CreateNode

		

		.save_op_dt:
		mov r14,r15
		inc r14

		mov rcx,rax
		call PrintNode
		jmp _loop_Lex

	_OP_PM:
		push rax
		;TYPE_OP_PM
		
		.save:
		;ascii for + is 43 and - 45
		
		cmp r14,r15
		je .skip_op_pm
		mov rcx,r15
		mov rdx,r14
		call CreateName
		;mov r14,rax

		.skip_op_pm:
		pop rax
		mov rcx,TYPE_OP_PM
		sub al,43
		movzx rdx,al
		mov r8,0
		mov r9,0	
		call CreateNode

		

		.save_op_pm:
		mov r14,r15
		inc r14

		mov rcx,rax
		call PrintNode
		jmp _loop_Lex

	_Semi_Colon:
		cmp r14,r15
		je .skip
		mov rcx,r15
		mov rdx,r14
		call CreateName


		;mov r14,rax
		.skip:
		mov rcx,OP_Semi
		mov rdx,10
		mov r9,0
		mov r8,0 ; placeholder
		call CreateNode
		mov rcx,rax
		call PrintNode	
		
		mov r14,r15
		inc r14
		jmp _loop_Lex
	_Space:
		;figure out bug
		
		cmp r14,r15
		je .skip_space
	
		mov rcx,r15
		mov rdx,r14
		call CreateName

		
		
	
		
		.skip_space:
		mov r14,r15
		inc r14
		jmp _loop_Lex



	.done:
		mov r14, r15             
		jmp _loop_Lex

	_exit:	
		;mov rcx,r15
	      	;call Print

		mov rcx,EOF
		mov rdx,10
		mov r8,0
		mov r9,0
		call CreateNode

		mov rcx,rax
		call PrintNode
		pop r13
		pop r14
		pop r15
		ret

AllocSTDHandles:
	sub rsp,20h
	mov rcx,-10
	call GetStdHandle
	mov  [ rel ReadConsoleHandle],rax
	mov rcx,-11
	call GetStdHandle
	mov  [rel WriteConsoleHandle],rax
	add rsp,20h
	ret

Parser:
	;rcx ptr
	;rdx parentNode
	push r15
	push r14
	push r13
	push r12
	push r11
	
	mov r15,rcx
	mov r14,rdx
	mov r12,r8 ;ir counter value to move on nodes etc
	mov r11,r9 ;precedence level
	xor r13, r13
	

	sub r15,32
	.MainLoop:
		add r15,32
		;32 bytes
		;mov rcx,r15
		;call PrintNode
		

		mov rax,qword[r15]
		
		
		lea r8,[rel .MainLoop]
		lea rbx,[rel .Int]
		cmp rax,TYPE_INT
		cmove r8,rbx
		

		lea rbx,[rel .NAME]
		cmp rax,TYPE_NAME
		
		cmove r8,rbx

		lea rbx,[rel .OP_ASS]
		cmp rax,OP_ASS
		cmove r8,rbx

		lea rbx,[rel .OP_PM]
		cmp rax,TYPE_OP_PM
		cmove r8,rbx

		lea rbx,[rel .OP_DT]
		cmp rax,TYPE_OP_DT
		cmove r8,rbx


		lea rbx,[rel .SEMI]
		cmp rax,OP_Semi
		cmove r8,rbx

		lea rbx,[rel .EOF]
		cmp rax,EOF
		cmove r8,rbx

		lea rbx,[rel .FUNC_PRINT]
		cmp rax,FUNC_PRINT
		cmove r8,rbx


		cmp rax,0
		je .SEMI
		jmp r8
	.FUNC_PRINT:
		
		lea rcx,[r15+32]
		mov rdx,rcx
		mov r8,r15
		mov r9,0 ;to get the correct value back
		call Parser

		
		push rax
		lea rcx,[rel msg]
		call Print

		pop rax
		push rax
		mov rcx,rax
		call DFS
		pop rax		
		sub rsp,64
		mov rcx,[rax]
		lea rdx,[rsp+32]
		call ToStr

		lea rcx,[rsp+32]
		mov byte[rsp+60],0
		call Print

		add rsp,64
		jmp .MainLoop
	;fix 
	.OP_ASS:
		;push r14
		mov rcx,r15
		call PrintNode
		mov r8,[rel statement_flag]	
		cmp r8,0
		jne .save_eq
		
		mov rcx,r15
		call AddToStatements
		
		.save_eq:
		pop r13	
		lea r13, [r15 - 32]
		mov qword [r15+NODE_LEFT],r13
		
		
		lea rcx,[r15+32]
		mov rdx,rcx
		mov r8,r15
		mov r9,[r15]
		call Parser
		
		
		mov qword[r15+NODE_RIGHT],rax
		

		;pop r14
		cmp r14,0
		jne .ret_op_om
		
		mov r15,rbx
		jmp .MainLoop

		.op_ass_ret:
			pop r11
			pop r12
			pop r13
			pop r14
			pop r15
			ret
	;fix
	.NAME:	
		mov rcx,r15
		call PrintNode
		lea r8,[rel .Normal_Name]
		
		
		;cmove r8,rbx
		lea rbx,[rel .NAME_RET]
		cmp r14,0
		cmovne r8,rbx

		
	
		lea rbx,[rel .Normal_Name]
		mov rax,[r15+32]
		cmp rax,0
		cmovne r8,rbx
		jmp r8

		cmp r14,0
		jne .NAME_RET
		
		mov rcx,r15

	.Normal_Name:
		mov rax,r15
		
		cmp qword[r15+32],OP_Semi
		je .MakeNameStatement
		push rax
		jmp .MainLoop

	.MakeNameStatement:

		mov r8,[rel statement_flag]	
		cmp r8,0
		jne .skip_name
		mov rcx,r15
		call AddToStatements
		.skip_name:	
		jmp .MainLoop
	.NAME_RET:
		mov rcx,r15
		call PrintNode
		mov rax,r15
		mov rbx,32
		pop r11
		pop r12
		pop r13
		pop r14
		pop r15
		ret

	.OP_DT:
		push r11
		mov rcx,r15
		call PrintNode
		pop r11

		mov r8,[rel statement_flag]	
		cmp r8,0
		jne .save_op_dt
		jmp .save_op_dt

		
		mov r8,[r15+32]
		cmp r8, r11; temp fix use precededence level
		jge .save_op_dt
		mov rcx,r15
		call AddToStatements
		
		
		.save_op_dt:
	
		pop r13
		mov qword [r15+NODE_LEFT],r13
		
		
		lea rcx,[r15+32]
		mov rdx,rcx
		mov r8,r15
		mov r9,[r15]
		call Parser

		
		mov qword[r15+NODE_RIGHT],rax
		

		cmp r14,0
		jne .op_dt_r14
		lea r8,[r15+64]
		mov r8,[r8]
		cmp r8, r11
		jle .push_op_dt

	
		
		mov r15,rbx
		
		jmp .MainLoop
		

		

		.op_dt_r14:
		
		lea r8,[r15+64]
		mov r8,[r8]
		cmp r8, r11
		jge .push_op_dt_r14 ; maybe correct fuck knows

			
		
		jmp .ret_op_dt

		.push_op_dt:
		
		cmp r8,OP_Semi
		je .not_dt_push
		
		push r15
		mov r15,rbx
		jmp .MainLoop



		.not_dt_push:
		push rbx
		mov rcx,r15
		call AddToStatements
		pop rbx
		mov r15,rbx
		jmp .MainLoop




		.push_op_dt_r14:
		
		cmp r8,OP_Semi
		je .not_dt_push_r14
		


		push r15
		push rbx
		
		pop rbx
		mov r15,rbx

		
		jmp .MainLoop
		
		.not_dt_push_r14:
			
			jmp .ret_op_dt


		;;Deleted
		cmp r14,0
		jne .ret_op_dt
		jmp .MainLoop
		.push_time:
		
		;check if the next char is eof or semi etc
		;cmp r14,0
		;jne .ret_op_dt


		push r15
		mov r15,rbx
		;dec qword[rel statement_count]
		mov qword[rel statement_flag],0
		jmp .MainLoop
		
		.ret_op_dt:
			
			mov rax,r15
			
			pop r11
			pop r12
			pop r13
			pop r14
			pop r15	
			ret
		.op_dt_exit:
			pop r11
			pop r12
			pop r13
			pop r14
			pop r15
			ret

	.OP_PM:	
		push r11
		;push r14
		mov rcx,r15
		call PrintNode
		pop r11

		mov r8,[rel statement_flag]	
		cmp r8,0
		jne .save_op_pm
		
		mov rcx,r15
		call AddToStatements
		
		.save_op_pm:
		;++ check
		
		;mov rax, qword [r15+NODE_LEFT]
		;cmp rax,0
		;jne .op_pm_exit

	
		pop r13
		mov qword [r15+NODE_LEFT],r13
		
		
		lea rcx,[r15+32]
		mov rdx,rcx
		mov r8,r15
		mov r9,[r15]
		
		call Parser
		
		
		mov qword[r15+NODE_RIGHT],rax
		;add r15,rbx
		;add r15,32
		
		
		;pop r14
		cmp r14,0
		jne .ret_op_om
		
		mov r15,rbx
		
		jmp .MainLoop
		
		.ret_op_om:
			
			mov rax,r15
			;mov r15,rbx
			pop r11
			pop r12
			pop r13
			pop r14
			pop r15	
			ret
		.op_pm_exit:
			pop r11
			pop r12
			pop r13
			pop r14
			pop r15
			ret
	.Int:
		push r11
		mov rcx,r15
		call PrintNode
		pop r11

		cmp r11,0
		je .normal_int

		mov rax,[r15+32]
		cmp rax,OP_Semi
		je .ret_Int

		

	.is_r14_0:
		mov rax,[r15+32]
		;mov rax,[rax]
		cmp r11,rax
			
		cmp r11,TYPE_OP_DT
		je .ret_Int
		;jl .ret_Int
		jmp .normal_int
		
		;;;To be refactored later;;....
		lea r8,[rel .normal_int]
		
		
		;cmove r8,rbx
		lea rbx,[rel .ret_Int]
		cmp r14,0
		cmovne r8,rbx

		
	
		lea rbx,[rel .normal_int]
		mov rax,[r15+32]
		;cmp rax,0
		cmp rax,OP_Semi
		cmovne r8,rbx

		lea rbx,[rel .ret_Int]
		lea rax,[r15]
		add rax,32
		mov rax,[r15+8]
		cmp r11,rax
		cmovge r8,rbx
		

		lea rbx,[rel .normal_int]
		cmp r11,0
		cmove r8,rbx

		jmp r8

	.normal_int:
		
		xor r13,r13
		mov r13,r15
		push r13

		jmp .MainLoop
	
		.ret_Int:
			
			mov rax,r15
			mov rbx,r15
			;mov rbx,32
		
			.ret_fin:
			pop r11
			pop r12
			pop r13
			pop r14
			pop r15
			ret
		
	.SEMI:
	;mov rcx,r15
	;call PrintNode
	mov qword[rel statement_flag], 0
	jmp .MainLoop	

	.EOF:
	pop r11
	pop r12
	pop r13
	pop r14
	pop r15
	ret


WalkTree:
	push r15
	push r14
	push r13
	mov r15,rcx
	mov r14,rdx
	.Walk:
		;lea rax,[r15+16]
		;lea rbx,[r15+24]
		;cmp rbx,0
		;je .done
		mov rcx,r15
		call PrintNode

		lea r8,[rel .Walk]

		lea rbx,[rel .OP_PM]
		mov rax, qword [r15]
		cmp rax,TYPE_OP_PM
		cmove r8,rbx 

		lea rbx,[rel .OP_DT]
		mov rax,qword[r15]
		cmp rax,TYPE_OP_DT
		cmove r8,rbx
		
		lea rbx,[rel .NAME]
		cmp rax,TYPE_NAME
		cmove r8,rbx

		lea rbx,[rel .OP_ASS]
		cmp rax,OP_ASS
		cmove r8,rbx

		lea rbx,[rel .Int]
		cmp rax,TYPE_INT
		cmove r8,rbx
		
			
		jmp r8
	.OP_ASS:
		mov rcx,[r15+16]
		call PrintNode

		

		mov rcx,[r15+24]
		mov rdx,0
		call WalkTree
	
		mov r13,qword[r15+16]
		movzx r13,byte[r13+8]
		;
		shl r13,3	
		lea rbx,[rel mem]
		mov qword[rbx+r13],rax


		
		jmp .done
	.NAME:	
		mov rcx,r15
		call PrintNode

		xor r13,r13
		movzx r13,byte[r15+8]
		

		shl r13,3
		
		
		
		

		lea rbx,[rel mem]
		add rbx,r13
		mov rax,[rbx]
				
		
		;mov rax,0
		jmp .done
	.Int:
		xor rax,rax
		mov eax,dword [r15+8]
		jmp .done
	.OP_DT:	
		mov rax,0
	
		mov rcx,[r15+16]
		mov rdx,1
		call WalkTree

		push rax
		mov rcx,[r15+24]
		mov rdx,0
		call WalkTree
	
		
		
		pop r13	
		;mov rax,-1

		mov rdx,[r15+8]
		cmp rdx,5
		
		je .div_op_dt
		

		.mul_op_dt:
		imul rax, r13   
		jmp .done
		.div_op_dt:

		; --- THE HOLY DIVISION SANCTUARY ---
		mov r11, rax           ; r11 = Save our divisor (Right Child) safely out of RAX
		mov rax, r13           ; rax = Load our dividend (Left Child) into RAX where it belongs!
		
		cqo                    ; ⚡ SIGN-EXTEND RAX INTO RDX! Preps the 128-bit RDX:RAX track.
		idiv r11               ; Divide RDX:RAX by R11! 
	
		jmp .done
	.OP_PM:
		xor rax,rax
		
	
		mov rcx,[r15+16]
		mov rdx,1
		call WalkTree
		push rax
		
		
		mov rdx,[r15+8]
		mov rcx,[r15+24]
		call WalkTree
		
	
		pop r13
		mov rdx,[r15+8]
		cmp rdx,2
		je .sub	
		.add:
			cmp r14,0
			jne .flip_add
			add rax,r13
			jmp .done
			.flip_add:
				sub r13,rax
				mov rax,r13
				jmp .done

		.sub:
			cmp r14,0
			jne .flip_sub
			sub r13,rax	
			mov rax,r13	
			jmp .done	
			.flip_sub:
				add r13,rax
				mov rax,r13
				jmp .done
	.done:
	pop r13
	pop r14
	pop r15
	ret
GetDigit:
    xor     rax, rax
    xor     rbx, rbx

.loop:
    movzx   r10, byte [rcx + rbx]
    sub     r10, '0'
    cmp     r10, 9
    ja      .done

    lea     rax, [rax * 4 + rax]
    shl     rax, 1
    add     rax, r10

    inc     rbx
    jmp     .loop

.done:
    ret

PrintNode:
	push r15
	mov r15,rcx
	sub rsp,28h
	mov byte [rsp],'N'
	mov byte [rsp+1],'T'
	mov byte[rsp+2],':'
	mov byte [rsp+3],32

	

	mov rcx,qword[r15]
	lea rdx,[rsp+4]
	call ToStr
	



	lea r9,[rsp+4]
	mov byte[r9+rbx],0
	lea rcx,[rsp]
	call Print

	mov byte[rsp],32
	mov byte [rsp+1],'N'
	mov byte [rsp+2],'V'
	mov byte[rsp+3],':'
	mov byte [rsp+4],32
	mov rcx,qword[r15+8]
	lea rdx,[rsp+5]
	call ToStr

	lea r9,[rsp+5]
	mov byte[r9+rbx],10
	mov byte[r9+rbx+1],0
	lea rcx,[rsp]
	call Print

	add rsp,28h
	pop r15
	ret

GetNextChar:
	movzx rax, byte [rcx]
	mov rbx,-1
	cmp al,0
	cmove rax,rbx	
	ret

; Input:  RCX = Node Type
;         RDX = Value / Payload (or 0 if operator)
;         R8  = Left Child Pointer (or 0 if terminal)
;         R9  = Right Child Pointer (or 0 if terminal/unary)
;         -1 is used to say that there is no value currently but can be alloc
;         -2 is there is no value and there may not be a value or left right child for something like primitives
; Output: RAX = Memory Address of the newly created node
CreateNode:
    mov     rax, [rel node_count]
    shl     rax, 5                  
    lea     r10, [rel ast_arena]
    add     rax, r10           
    
    mov     [rax + NODE_TYPE], rcx
    mov     [rax + NODE_VALUE], rdx
    mov     [rax + NODE_LEFT], r8
    mov     [rax + NODE_RIGHT], r9
    
    inc     qword [rel node_count]  
    ret 
ToStr:
    push    r12
    push    r13
    
    mov     rax, rcx
    mov     r12, rdx
    mov     r10, 10
    xor     r13, r13

.extract:
    xor     rdx, rdx
    div     r10
    add     dl, '0'
    push    rdx
    inc     r13
    test    rax, rax
    jnz     .extract

    mov     rbx, r13
    mov     rax, r12

.write:
    pop     rdx
    mov     [r12], dl
    inc     r12
    dec     r13
    jnz     .write

    pop     r13
    pop     r12
    ret

Read:
	sub rsp,38h
	mov r8,rcx ; ie the amount to read
	;rdx the buffer
	mov rcx, [rel ReadConsoleHandle]
	;rdx has ptr to dest

	
	lea r9,  [rsp+30h]
	mov qword [rsp+20h],0
	call ReadConsoleA
	add rsp,38h
	ret

Print:
	sub rsp,38h
	;rcx has ptr to msg
	mov rdx,rcx
	mov rcx, [rel WriteConsoleHandle]
	
	call GetLenStr
	mov r8,rax
	lea r9,  [rsp+28h]
	mov qword [rsp+20h],0
	call WriteConsoleA
	add rsp,38h
	ret

GetLenStr: 
	mov rsi,rdx
	xor rax,rax
	dec rax
	dec rsi
	_loop:
		inc rsi
		inc rax
		mov dil, byte [rsi]
		
		cmp dil,0
		jne _loop 
	ret
Leave:
	xor ecx,0
	call ExitProcess
