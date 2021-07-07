	INCLUDE core_cm4_constants.s		; Load Constant Definitions
	INCLUDE stm32l476xx_constants.s      

	AREA    main, CODE, READONLY
	EXPORT	__main				; make __main visible to linker
	ENTRY	
	
		
__main 			PROC
				LDR R9, =0
				LDR R10, =0
				LDR R11, =0
			
				BL	RCC_Init
				BL	GPIO_Init
				
infinite		BL ButtonPoll
				BL Delay
				BL UpdateCoils
				B infinite
				ENDP
			;LDR R0,=GPIOE_BASE
			;LDR R1, =seq1
			;MOV R5, R1

;loop		
;			LDRB R2,[R1],#1
;			CBNZ R2,next
;			MOV  R1, R5
;			B  loop
;next		
;			LDR R3,[R0,#GPIO_ODR]
;			LDR R4,=0x0F
;			BIC R3,R3,R4, LSL #12
;			ORR R3,R3,R2,LSL #12
;			STR R3, [R0,#GPIO_ODR]
;			BL  Delay
;			B loop
;			ENDP

RCC_Init		PROC
				PUSH {R0,R1}   					;gpioe clock
				LDR R0, =RCC_BASE
				LDR R1, [R0,#RCC_AHB2ENR]
				ORR R1,R1,#RCC_AHB2ENR_GPIOEEN
				STR R1, [R0,#RCC_AHB2ENR]
											;gpioa clock
				LDR r1, [R0,#RCC_AHB2ENR]
				ORR R1,R1,#RCC_AHB2ENR_GPIOAEN
				STR R1, [R0,#RCC_AHB2ENR]
			
				POP{R1,R0}
				BX LR 
				ENDP	

GPIO_Init		PROC
				PUSH {R0,R1,R2}
									;gpioe
									
				LDR R0, =GPIOE_BASE			
				LDR R2, =0xFF
				BIC  R1,R1,R2, LSL #24
				LDR R2, =0x55
				ORR R1, R1, R2, LSL #24
				STR R1, [R0,#GPIO_MODER]
			
				LDR R1, [R0,#GPIO_OSPEEDR]
				LDR R2, =0xFF
				ORR R1, R1, R2, LSL #24
				STR R1, [R0,#GPIO_OSPEEDR]
			
				LDR R1, [R0,#GPIO_PUPDR]
				LDR R2, =0xFF
				BIC  R1,R1,R2, LSL #24
				STR R1, [R0,#GPIO_PUPDR]
				
				LDR R1, [R0,#GPIO_OTYPER]
				LDR R2, =0x0F
				BIC  R1, R1, R2, LSL #12
				STR  R1, [R0,#GPIO_OTYPER]
										;gpioa
										
				LDR R0, =GPIOA_BASE
				LDR R1, [R0,#GPIO_MODER]
				LDR R2, =0x0CC3
				BIC R1, R1, R2
				STR R1, [R0, #GPIO_MODER]
				LDR R1, [R0, #GPIO_PUPDR]
				LDR R2, =0x0CC3
				BIC R1, R1, R2
				LDR R2, =0x22
				ORR R1, R1, R2, LSL #6
				STR R1, [R0, #GPIO_PUPDR]
			
				POP  {R2,R1,R0}
				BX	LR
				ENDP
				
ButtonPoll		PROC
				PUSH {R0,R1,R2}
			
				LDR R0, =GPIOA_BASE
				LDR R1, [R0, #GPIO_IDR]
				AND R2, R1, #8
				CMP R2, #8
				BEQ up_press
				AND R2, R1, #32
				CMP R2, #32
				BEQ down_press
				AND R2, R1, #1
				CMP R2, #1
				BEQ center_press
				B done1

up_press		SUBS R8,#10
				MOVEQ R8, #10
				B done1
			
down_press  	ADD R8, #10
				B done1

center_press	EOR R9, R9, #1
				B wait_letgo
				
wait_letgo		LDR R0, =GPIOA_BASE
				LDR R1, [R0, #GPIO_IDR]
				AND R2, R1, #1
				CMP R2, #1
				BEQ wait_letgo
				BNE done1
			
done1			POP {R2, R1, R0}
				BX LR
				ENDP

UpdateCoils 	PROC
				PUSH {R0,R1,R2,R3,R4}
			
				LDR R0, =full_step
				LDR R1, =half_step
				CMP R9, #0
				BEQ run_full
				BNE run_half
			
run_full		CMP R10, #4
				MOVEQ R10, #0
				LDRB R2, [R0, R10]
				LDR R3, =GPIOE_BASE
				LDR R4, [R3, #GPIO_ODR]
				BIC R4, R4, #(0xFF<<12)
				ORR R4, R4, R2, LSL #12
				STR R4, [R3, #GPIO_ODR]
				ADD R10, #1
				B done2
			
run_half		CMP R11, #8
				MOVEQ R11, #0
				LDRB R2, [R1, R11]
				LDR R3, =GPIOE_BASE
				LDR R4, [R3, #GPIO_ODR]
				BIC R4, R4, #(0xFF<<12)
				ORR R4, R4, R2, LSL #12
				STR R4, [R3, #GPIO_ODR]
				ADD R11, #1
				B done2

done2			POP {R4, R3, R2, R1, R0}
				BX LR
				ENDP
				
Delay			PROC 
				push {r1}
				ldr r1, =2000   ;initial value for loop counter
again  			NOP  ;execute two no-operation instructions
				NOP
				subs r1, #1
				BNE again
				POP {r1}
				BX lr				
				ENDP
				
				




	ALIGN			

	AREA    myData, DATA, READWRITE
	ALIGN
full_step	DCB		2_0011, 2_0110, 2_1100, 2_1001	
half_step	DCB 	2_0001, 2_0011, 2_0010, 2_0110, 2_0100, 2_1100, 2_1000, 2_1001
;seq1	DCB		2_0101,2_0110,2_1010,2_1001,2_0000
;seq2	DCB		2_0101,2_1001,2_1010,2_0110,2_0000
;seq3	DCB		2_0001,2_0100,2_0010,2_1000,2_0000
;seq4	DCB 	2_0001,2_1000,2_0010,2_0100,2_0000
;seq5	DCB 	2_0001,2_0101,2_0100,2_0110,2_0010,2_1010,2_1000,2_1001,2_0000
	END
