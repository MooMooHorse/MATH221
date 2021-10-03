.ORIG x3000

JSR FIND_M_N
LD R0,ADDR_STR_M
PUTS
LD R0,SPACE
OUT

LEA R0,RIGHTARROW
PUTS

LD R0,SPACE
OUT

LD R0,ADDR_STR_N
PUTS
LD R0,LINEFEED
OUT
LEA R0,LEVENSHTEINDIS
PUTS

LDI R1,ADDR_LEV_ANS
JSR PRINT_DECIMAL

LD R0,LINEFEED
OUT

JSR PRETTY_PRINT


HALT 
;;;;;;;;;;;;;;MAIN;;;;;;;;;;;;


STRLEN 
	; Address of the first character is passed to R0
	; Length of the given string is recorded in R1
	; No other register value except for R7 can be changed
	; store and recovery every register except for R1 
	ST R0,STR0
	ST R2,STR2
	ST R3,STR3
	ST R4,STR4
	ST R5,STR5
	ST R6,STR6
	ST R7,STR7
	; No other register are used except for R0 and R7, this store and recover method is just to make sure

	ST R0,PT01 ; set the initial value of the first pointer to the value in R0
	AND R1,R1,#0 ; clear the length of string to 0

	;looping through the string
	LOOP1 
	LDI R7,PT01 ; load the value of current character pointed by the first pointer
	BRz ENDLOOP1
	; Increment PT01
	LD R7,PT01
	ADD R7,R7,1
	ST R7,PT01

	ADD R1,R1,#1 ;increment R1
	BRnzp LOOP1
	ENDLOOP1

	LD R0,STR0
	LD R2,STR2
	LD R3,STR3
	LD R4,STR4
	LD R5,STR5
	LD R6,STR6
	LD R7,STR7


	RET

;;;;;;;;;;;;;STRLEN;;;;;;;;;;;;;;;;;;

PRINT_DECIMAL
;A non-negative number is passed into your subroutine in R1 
;whose length is at most 5,since its range is on [0,32767]
;this subroutine puts the value without leading zero(s)
;R0 to PUTS string 
;R1 to keep track of number
;R2 temporary register
;R3 R3=-10^R7
;R4 temporary register
;R5 point to current character
;R6 unused
;R7 outer loop (enumerate digits) counter

	;store
	ST R0,STR0
	ST R1,STR1
	ST R2,STR2
	ST R3,STR3
	ST R4,STR4
	ST R5,STR5
	ST R6,STR6
	ST R7,STR7



	; clear result string

	AND R2,R2,#0
	ADD R2,R2,#12
	ADD R2,R2,#12
	ADD R2,R2,#12
	ADD R2,R2,#12

	;clear string
	LEA R5,RESULT
	CLEAR_RESULT_LOOP
		LDR R4,R5,#0
		BRz END_CLEAR_RESULT_LOOP

		STR R2,R5,#0
		ADD R5,R5,#1
		BRnzp CLEAR_RESULT_LOOP
	END_CLEAR_RESULT_LOOP

	;R7=5
	AND R7,R7,#0
	ADD R7,R7,#5

	;R5->RESULT
	LEA R5,RESULT

	ENUMERATE_DIGIT
		ADD R7,R7,#-1
		BRn END_ENUMERATE_DIGIT


		; put -10^R7 into R3
		; R2 Temp register
		LEA R2,TABLELINE1
		ADD R2,R2,R7
		LDR R3,R2,#0


		;inner loop
		NUMBER_START
			ADD R2,R1,R3
			BRn END_NUMBER_START

			;number -= 10^R7
			ADD R1,R1,R3 
			; M[R5]+=1
			LDR R2,R5,#0
			ADD R2,R2,#1
			STR R2,R5,#0

			BRnzp NUMBER_START
		END_NUMBER_START


		;inner loop
		ADD R5,R5,#1

		BRnzp ENUMERATE_DIGIT
	END_ENUMERATE_DIGIT

	;set NUL to M[R5]
	AND R2,R2,#0
	STR R2,R5,#0
	;PUTS string
	LEA R0,RESULT

	;eliminate prefix 0

	ELIMINATE_PREFIX_ZERO
		LDR R2,R0,#0 
		ADD R2,R2,#-12
		ADD R2,R2,#-12
		ADD R2,R2,#-12
		ADD R2,R2,#-12
		BRnp END_ELIMINATE_PREFIX_ZERO ;negative when it goes to NUL (the case when the number is 0)
		ADD R0,R0,#1
		BRnzp ELIMINATE_PREFIX_ZERO
	END_ELIMINATE_PREFIX_ZERO
	LD R1,STR1 ; see if the number is 0
	BRnp PRINT_SCREEN
	ADD R0,R0,#-1 ;when it's zero, you should output a zero
	PRINT_SCREEN
	PUTS

	;recover
	LD R0,STR0
	LD R1,STR1
	LD R2,STR2
	LD R3,STR3
	LD R4,STR4
	LD R5,STR5
	LD R6,STR6
	LD R7,STR7
	
RET

;;;;;;;;;;;;;;PRINT_DECIMAL;;;;;;;;;;;;


FIND_M_N 
	; find the value of M and N 
	; then put it into address labeled ADDR_VALUE_M and ADDR_VALUE_N respectively
    
	; R0 address of start of the string
    ; R1 value of string length
    ; R7 should be stored and restored since it changed in the subroutine
	; no other registers are used in this subroutine
    ST R0,STR0
    ST R1,STR1
    ST R7,STR7_L2 ; 2nd layer

    LD R0,ADDR_STR_M
    JSR STRLEN
	ADD R1,R1,#1
    STI R1,ADDR_VALUE_M

    LD R0,ADDR_STR_N
    JSR STRLEN
	ADD R1,R1,#1
    STI R1,ADDR_VALUE_N

    LD R0,STR0
    LD R1,STR1
    LD R7,STR7_L2

RET

;;;;;;;;;;;;;;FIND_M_N;;;;;;;;;;;;

PRETTY_PRINT 
    ; last entry LD 3*((N-1)*M+M-1)=3*(N*M-1)
	; go  to the bottom right corner of the table then walk the table via its offset
	; until it reaches the top left corner of the table
	; all the operations are pushed in a stack and this subroutine prints the operation in a unique manner
	; when the operation is insertion, the first line of string outputs a hyphen
	; when the operation is deletion , the second line of string outputs a hyphen
	; other time each line of string output a character in M or N string
	; so that if you eliminate the hyphens the first line is strin M and the second line is string N
    
	; R0 pointer at the head of the string
	; R1 unused
	; R2 temporary register
    ; R3 temporary register
    ; R4 store the current position in table
    ; R5 current pointer in structure
    ; R6 stack  pointer
	; R7 used for trap and JSR

    ;store
	ST R0,STR0
	ST R1,STR1
	ST R2,STR2
	ST R3,STR3
	ST R4,STR4
	ST R5,STR5
	ST R6,STR6
	ST R7,STR7

    ;initialize stack pionter
    LD R6,STACK_POINTER ;R6 <- Base

    ; R2 <- N
    LDI R2,ADDR_VALUE_N

    ; R3 <- M
    LDI R3,ADDR_VALUE_M

    AND R4,R4,#0
    ; R4 <- M*N
    MULT_LOOP1 
    ADD R2,R2,#-1
    BRn END_MULT_LOOP1
    ADD R4,R4,R3
    BRnzp MULT_LOOP1
    END_MULT_LOOP1

    ADD R4,R4,#-1 ;R4 <- M*N -1

    ; R4 <- 3*(N*M-1)
    AND R3,R3,0
    ADD R3,R4,R3
    ADD R4,R4,R4
    ADD R4,R4,R3

    LD R3,FOURK ; R3 <- x4000
    ADD R4,R4,R3   ; R4 <- x4000 + 3* ( M*N -1 ) 

    ;now R4 points to the bottom right corner of the table

    WALK_TABLE
        AND R5,R5,0 
        ADD R5,R5,R4
        ADD R5,R5,2 ;R5 <- R4 + 2
        LDR R2,R5,#0 ; at present R2 is the operation type
        BRn END_WALK_TABLE ;no predecessor 

        ADD R6,R6,#-1 ;push
        STR R2,R6,#0

        ADD R5,R5,#-1 ;R5 <- R4 + 1
        LDR R2,R5,#0 ; R2 <- offset
        ADD R4,R4,R2 ; R4 <- R4 + offset

    BRnzp WALK_TABLE
    END_WALK_TABLE

    ADD  R4,R6,#0 ;R4 points to top of the stack
    ; R4 points to current position at stack
    LD R1,ADDR_STR_M ;R1 <- address of the start of string M
    IT_STACK_1 ;iterate the stack from top to bottom
        LDR R2,R4,#0
        BRz INS_OP
        ;deletion or substitution or match
		LDR R0,R1,#0
        OUT
        ADD R1,R1,#1
        BRnzp SKIP_IT_STACK_1

        INS_OP ;insertion
        LD R0,HYPHEN
        OUT

        SKIP_IT_STACK_1
        ADD R4,R4,#1
        BRn END_IT_STACK_1

    BRnzp IT_STACK_1
    END_IT_STACK_1

	;print linefeed
	LD R0,LINEFEED
	OUT

    ADD  R4,R6,#0
    ; R4 points to current position at stack
    LD R1,ADDR_STR_N ;R1 <- address of the start of string N
    IT_STACK_2 ;iterate the stack from top to bottom
        LDR R2,R4,#0
        ADD R2,R2,#-1 ; R2 <- operation type - 1
        BRz DEL_OP ;
        ;insertion or substitution or match
		LDR R0,R1,#0
        OUT
        ADD R1,R1,#1
        BRnzp SKIP_IT_STACK_2

        DEL_OP ;deletion
        LD R0,HYPHEN
        OUT

        SKIP_IT_STACK_2

        ADD R4,R4,#1
        BRn END_IT_STACK_2

    BRnzp IT_STACK_2
    END_IT_STACK_2

	;print linefeed
	LD R0,LINEFEED
	OUT

    ;recover
	LD R0,STR0
	LD R1,STR1
	LD R2,STR2
	LD R3,STR3
	LD R4,STR4
	LD R5,STR5
	LD R6,STR6
	LD R7,STR7
RET
;;;;;;;;;;;;;;PRETTY_PRINT;;;;;;;;;;;;
; memory used by main

ADDR_LEV_ANS 		.FILL 		x38C0
STACK_POINTER 		.FILL 		x8000

; memory used to save constant values

SPACE      			.STRINGZ	" "
RIGHTARROW 			.STRINGZ	"->"
HYPHEN   			.FILL 		x002D
LINEFEED 			.FILL 		x000A
LEVENSHTEINDIS 		.STRINGZ	"Levenshtein distance = "
FOURK 				.FILL 		x4000
; memory used to store and restore register values

STR0 				.FILL 		x0000
STR1 				.FILL 		x0000
STR2 				.FILL 		x0000
STR3 				.FILL 		x0000
STR4 				.FILL 		x0000
STR5 				.FILL 		x0000
STR6 				.FILL 		x0000
STR7 				.FILL 		x0000
STR7_L2				.FILL		x0000


; memory used by FIND_M_N and PRETTY_PRINT

ADDR_VALUE_M 		.FILL 		x38E0
ADDR_VALUE_N 		.FILL 		x38E1
ADDR_STR_M   		.FILL 		x3800
ADDR_STR_N   		.FILL 		x3840


; memory used by PREINT_DECIMAL and STRLEN

PT01 				.FILL 		x0000
TABLELINE1 			.FILL 		#-1 
					.FILL 		#-10 
					.FILL 		#-100 
					.FILL 		#-1000 
					.FILL 		#-10000 

RESULT 				.STRINGZ 	"00000"  
; the following 5 address of memory is used to store the result of decimal to print

.END