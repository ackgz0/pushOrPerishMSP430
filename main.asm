;-------------------------------------------------------------------------------
;
;	CENG 329 - Project Push or Perish
;
;	Team Members: Umut Eray Acikgoz, Ulas Ucrak, Nurettin Efe Alver
;
;	Project is implemented using only interrupts, without relying on any
;	other mechanisms
;
;	When one of the players presses the button consecutively 2-times,
;	it manually resets the game
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.
;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer
;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
reset:
	bic.b #01110011b, &P1SEL
	bic.b #01110011b, &P1SEL2
	bis.b #01110011b, &P1DIR ;seven segment outputs
	bic.b #00111111b, &P2SEL
	bic.b #00111111b, &P2SEL2
	bis.b #00110011b, &P2DIR ; led outputs [p2.0 & p2.1] & the rest of the seven segment outputs [p2.4 & p2.5]

	bic.b #00001100b, &P2DIR ; buttons inputs [p2.2 & p2.3]
	bis.b #00001100b, &P2REN ; enabling pull-up resistors [p2.2 & p2.3]
	bis.b #00001100b, &P2OUT ; enabling pull-up resistors [p2.2 & p2.3]

	mov.w   #TASSEL_2|MC_1|ID_3, &TACTL ; SMCLK, Up mode, /8 divider
    mov.w   #65535, &TACCR0            ; set TimerA period for 0.5s
    bis.w  #CCIE, &TACCTL0              ; enable TACCR0 interrupt

	bis.w #GIE, SR ; enable global interrupts
	bic.b #00001100b, &P2IES
	bis.b #00001100b, &P2IE

    mov.w #3, R4 ; countdown counter
    mov.b #0, r7 ; r7 next round phase flag = 0, when its 1, while seven segment s showing dash, any led wont be on
	mov.b #0, r9 ; r9 zero flag = 0, when this flag is 1, while seven segment s showing zero, player's led will be on when player presses the button
	mov.b #0, r11 ; r11 toggle flag = 0, it s gonna be 1 if one of the players presses the button
	mov.b #0, r12 ; interrupt count flag, because the timer interrupt's max interval is 0.5s, we are entering interrupt twice to do 1s interval
	mov.w #0, r13 ; dash flag, seven segment shows dash when the flag is not 0.
	mov.w #0, r8 ; manual reset flag for player 1
	mov.w #0, r10 ; manual reset flag for player 2
	;mov.b #0, r6 ; press when 0 flag

mainloop:

	jmp mainloop

;-----------------------------------------------------------------
	;TIMER INTERRUPT
;-----------------------------------------------------------------

TIMER_ISR:
	cmp.b #0, r12	; we increase the interrupt count flag in the first entrance then we decrease (line 108) it in the second entrance
	jeq CLEAR_FLAGS ; thanks to this mechanism, we increase the timer interrupt interval from 0.5s to 1s
	cmp.w #2, r8 ; did player 1 pressed the button twice in 1s?
	jeq RESET_COUNTER ; if yes reset countdown
	cmp.w #2, r10 ; did player 2 pressed the button twice in 1s?
	jeq RESET_COUNTER ; if yes reset countdown
	mov.w #0, r8 ; else reset the button flag for manual reset
	mov.w #0, r10 ; else reset the button flag for manual reset

    cmp.w #0, r4                           ; did countdown reach 0?
    jeq RESET_COUNTER                      ; if it reached, restart game

    ; decrease countdown value
    dec.w R4                            ; countdown = countdown - 1

    ; update 7-segment
    call #UPDATE_DISPLAY

    ; clear interrupt flag
    dec.b r12
    bic.w #CCIFG, &TA0CCTL0
    reti

RESET_COUNTER:
;	cmp.w #0, r13
;	jne DONT_TOGGLE
;	mov.b #1, r11
;DONT_TOGGLE:
;	cmp.b #1, r11
;	jne WAIT_PRESS
	;mov.w #3, r13
; comparisons & jumps for skipping the dash part when we reset the game manually (line 93 & 97)
	cmp.w #2, r8
	jne SKIP_MANUAL_RESET1
	mov.w #0, r13
SKIP_MANUAL_RESET1:
	cmp.w #2, r10
	jne SKIP_MANUAL_RESET2
	mov.w #0, r13
SKIP_MANUAL_RESET2:

	mov.w #0, r8 ; manual reset flag for p1 = 0
	mov.w #0, r10 ; manual reset flag for p2 = 0
	mov.b #0, r7 ; r7 next round phase flag = 0
	mov.b #0, r9 ; r9 zero flag = 0
	mov.b #0, r11 ; r11 toggle flag = 0
	mov.w #3, R4 ; reset countdown
	call #UPDATE_DISPLAY
;WAIT_PRESS:
	dec.b r12
    bic.w #CCIFG, &TA0CCTL0             ; clear interrupt flag
    reti
CLEAR_FLAGS:
	inc.b r12
	bic.w   #CCIFG, &TACCTL0          ; clear interrupt flag
    reti

; 7-segment display update subroutine
UPDATE_DISPLAY:
	bis.b #01110011b, &P1OUT
	bis.b #00110000b, &P2OUT
	cmp.b #1, r11              ; toggle flag check
    jeq buttonDASH              ; if toggle flag = 1, end the game and display dash
    cmp.w #0, r13              ; Toggle flag kontrolü
    jne DASH              ; Eðer toggle flag 1 deðilse, sayýyý göster
    cmp.w #3, R4
    jeq DISPLAY_3
    cmp.w #2, R4
    jeq DISPLAY_2
    cmp.w #1, R4
    jeq DISPLAY_1
    cmp.w #0, R4
    jeq DISPLAY_0
    ret

DISPLAY_3:
	bic.b #00000011b, &P2OUT ; turn off leds

    bic.b #01100001b, &P1OUT;3
	bic.b #00110000b, &P2OUT
    ret

DISPLAY_2:
	;cmp.b #1, r11              ; Toggle flag kontrolü
    ;jeq DASH              ; Eðer toggle flag 1 deðilse, sayýyý göster
    bic.b #00110001b, &P1OUT;2
	bic.b #00110000b, &P2OUT
    ret


DISPLAY_1:
	;cmp.b #1, r11              ; Toggle flag kontrolü
    ;jeq DASH             ; Eðer toggle flag 1 deðilse, sayýyý göster
    bic.b #01000000b, &P1OUT;1
	bic.b #00010000b, &P2OUT

    ret

DISPLAY_0:
	;cmp.b #1, r11              ; Toggle flag kontrolü
    ;jeq DASH              ; Eðer toggle flag 1 deðilse, sayýyý göster
    bic.b #01110010b, &P1OUT;0
	bic.b #00110000b, &P2OUT
	mov.b #1, r9 ; r9 zero flag = 1
	mov.w #3, r13
	ret

buttonDASH:
	mov.w #3, r13
DASH:
    mov.b #1, r7 ; r7 next round phase flag = 1
	bis.b #01110111b, &P1OUT
	bis.b #00110000b, &P2OUT
	bic.b #00000001b, &P1OUT;-
	mov.b #0, r11
	mov.b #0, R4
	dec.w r13
	ret


;-----------------------------------------------------------------
	;BUTTON INTERRUPT
;-----------------------------------------------------------------
but_ISR:
	bit.b #00000100b, &P2IFG
	jeq p21tog
	inc.w r8
	cmp.b #1, r11
	jeq exit
	mov.b #1, r11;
	cmp.b #1, r7 ; r7 phase kontrol
	jeq exit
	cmp.b #1, r9
	jeq player1wins
	jmp player1loses

player1wins:
	xor.b #00000001b, &P2OUT ; set p1.0 blue on
	bic.b #00000100b, &P2IFG
	mov.w #3, r13
	reti

player1loses:
	xor.b #00000010b, &P2OUT
	bic.b #00000100b, &P2IFG
	reti

p21tog:
	bit.b #00001000b, &P2IFG
	jeq exit
	inc.w r10
	cmp.b #1, r11
	jeq exit
	mov.b #1, r11;
	cmp.b #1, r7 ; r7 phase kontrol
	jeq exit
	cmp.b #1, r9
	jeq player2wins
	jmp player2loses

player2wins:
	xor.b #00000010b, &P2OUT ; set p1.1 yellow on
	bic.b #00001000b, &P2IFG
	mov.w #3, r13
	reti

player2loses:
	xor.b #00000001b, &P2OUT ; set p1.1 yellow on
	bic.b #00001000b, &P2IFG
	reti
exit:
	bic.b #00001100b, &P2IFG
	reti

;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack

;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
			.sect   ".int03"                ; MSP430 button Vector
            .short  but_ISR

            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET

            .sect ".int09"
    		.short TIMER_ISR
