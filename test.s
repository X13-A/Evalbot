	;; RK - Evalbot (Cortex M3 de Texas Instrument)
	;; Les deux LEDs sont initialement allum�es
	;; Ce programme lis l'�tat du bouton poussoir 1 connect�e au port GPIOD broche 6
	;; Si bouton poussoir ferm� ==> fait clignoter les deux LED1&2 connect�e au port GPIOF broches 4&5.
   	
		AREA    |.text|, CODE, READONLY
 
; This register controls the clock gating logic in normal Run mode
SYSCTL_PERIPH_GPIO EQU		0x400FE108	; SYSCTL_RCGC2_R (p291 datasheet de lm3s9b92.pdf)

; The GPIODATA register is the data register
GPIO_PORTF_BASE		EQU		0x40025000	; GPIO Port F (APB) base: 0x4002.5000 (p416 datasheet de lm3s9B92.pdf)
GPIO_PORTD_BASE		EQU		0x40007000		; GPIO Port D (APB) base: 0x4000.7000 (p416 datasheet de lm3s9B92.pdf)
GPIO_PORTE_BASE		EQU		0x40024000		; GPIO Port E (APB) base: 0x4002.4000 (p416 datasheet de lm3s9B92.pdf)
	
; configure the corresponding pin to be an output
; all GPIO pins are inputs by default
GPIO_O_DIR   		EQU 	0x00000400  ; GPIO Direction (p417 datasheet de lm3s9B92.pdf)

; The GPIODR2R register is the 2-mA drive control register
; By default, all GPIO pins have 2-mA drive.
GPIO_O_DR2R   		EQU 	0x00000500  ; GPIO 2-mA Drive Select (p428 datasheet de lm3s9B92.pdf)

; Digital enable register
; To use the pin as a digital input or output, the corresponding GPIODEN bit must be set.
GPIO_O_DEN  		EQU 	0x0000051C  ; GPIO Digital Enable (p437 datasheet de lm3s9B92.pdf)

; Pul_up
GPIO_I_PUR   		EQU 	0x00000510  ; GPIO Pull-Up (p432 datasheet de lm3s9B92.pdf)

; Broches select
BROCHE4_5			EQU		0x30		; led1 & led2 sur broche 4 et 5

BROCHE4 			EQU 	0x10		; led1 sur broche 4

BROCHE5 			EQU 	0x20		; led2 sur broche 5

BROCHE6_7			EQU 	0xC0		; bouton poussoir 1 et 2 sur broche 6 et 7
	
BROCHE6				EQU 	0x40		; bouton poussoir 1 sur broche 6
	
BROCHE7				EQU 	0x80		; bouton poussoir 2 sur broche 7

BROCHE0_1			EQU 	0x03		; bumpers 1 et 2 sur broche 0 et 1


	  	ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; d�activer le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arri�re
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; d�activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arri�re
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche

__main	

		; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D et F o� sont branch�s les leds (0x28 == 0b111000)
		; ;;														 									      (GPIO::FEDCBA)
        str r0, [r6]
		
		; ;; "There must be a delay of 3 system clocks before any GPIO reg. access  (p413 datasheet de lm3s9B92.pdf)
		nop	   									;; tres tres important....
		nop	   
		nop	   									;; pas necessaire en simu ou en debbug step by step...
	

		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION 2 LEDs

        ldr r6, = GPIO_PORTF_BASE+GPIO_O_DIR    ;; 1 Pin du portF en sortie (broche 4 : 00010000)
        ldr r0, = BROCHE4_5 	
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE4_5		
        str r0, [r6]
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensit� de sortie (2mA)
        ldr r0, = BROCHE4_5			
        str r0, [r6]
		
		 mov r2, #0x000       					;; pour eteindre LED
     
		; allumer la led broche 4 (BROCHE4_5)
		mov r3, #BROCHE4_5		;; Allume LED1&2 portF broche 4&5 : 00110000
		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)  ;; @data Register = @base + (mask<<2) ==> LED1
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration LED 
		
			
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Switcher 

		ldr r7, = GPIO_PORTD_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE6_7		
        str r0, [r7]
		
		ldr r7, = GPIO_PORTD_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE6_7	
        str r0, [r7]     
		
		ldr r7, = GPIO_PORTD_BASE + (BROCHE6_7<<2)  ;; @data Register = @base + (mask<<2) ==> Switcher
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Switcher
		
				
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^CONFIGURATION Bumper 

		ldr r8, = GPIO_PORTE_BASE+GPIO_I_PUR	;; Pul_up 
        ldr r0, = BROCHE0_1		
        str r0, [r8]
		
		ldr r8, = GPIO_PORTE_BASE+GPIO_O_DEN	;; Enable Digital Function 
        ldr r0, = BROCHE0_1	
        str r0, [r8]     
		
		ldr r8, = GPIO_PORTE_BASE + (BROCHE0_1<<2)  ;; @data Register = @base + (mask<<2) ==> Bumper
		
		;vvvvvvvvvvvvvvvvvvvvvvvFin configuration Bumper	


ChooseProgram
		ldr r10, [r7]
		CMP r10, #0x40 ; Check if switch 1 is pushed
		BEQ Program1
		CMP r10, #0x80 ; Check if switch 2 is pushed
		BEQ Program2
		B ChooseProgram



Program2

Init
		ldr r4, =0x0
		ldr r5, =0x0
		B Main
		
Main
		CMP r10, #0x40 ; Check if switch 1 is pushed
		BEQ gPlus1
		CMP r10, #0x80 ; Check if switch 2 is pushed
		BEQ dPlus1
		B Main
		
gPlus1
		ADD r4, #1
		B Main
		
dPlus1
		ADD r5, #1
		B Main




Program1
		; Configure les PWM + GPIO
		BL	MOTEUR_INIT
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		
		; Evalbot avance droit devant
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT

		B MainProgram1
		
CheckBumpers
		ldr r10, [r8]
		CMP r10, #0x02 ; Check if left one is pushed
		BEQ waitBumperRight
		CMP r10, #0x01 ; check if right one is pushed
		BEQ waitBumperleft
		
		B TurnOffLeds ; if none, turn off leds
		
TurnOnLeds
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		ldr r3, = BROCHE4_5
		str r3, [r6]
		B HalfTurn

TurnOnLed1
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4<<2)
		;str r2, [r6] ; Turns off Led 1
		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE5<<2)
		ldr r3, = BROCHE5
		str r3, [r6]
		B LeftDirection

TurnOnLed2
		ldr r6, = GPIO_PORTF_BASE + (BROCHE5<<2)
		;str r2, [r6] ; Turns off Led 2
		
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4<<2)
		ldr r3, = BROCHE4 ; Turns on Led 1
		str r3, [r6]
		B RightDirection

TurnOffLeds
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r2, [r6]
		B CheckBumpers

RightDirection
		BL	MOTEUR_DROIT_ARRIERE
		BL	MOTEUR_GAUCHE_ARRIERE
		BL WAIT
		BL	MOTEUR_DROIT_ARRIERE   ; MOTEUR_DROIT_INVERSE
		BL	MOTEUR_GAUCHE_AVANT
		BL	WAIT
		BL	MOTEUR_DROIT_AVANT
		B CheckBumpers

		
LeftDirection
		BL	MOTEUR_DROIT_ARRIERE
		BL	MOTEUR_GAUCHE_ARRIERE
		BL WAIT
		BL	MOTEUR_GAUCHE_ARRIERE   ; MOTEUR_GAUCHE_INVERSE
		BL	MOTEUR_DROIT_AVANT
		BL	WAIT	   
		BL	MOTEUR_GAUCHE_AVANT
		B CheckBumpers


HalfTurn
		BL	MOTEUR_DROIT_ARRIERE
		BL	MOTEUR_GAUCHE_ARRIERE
		BL WAIT
		BL	MOTEUR_GAUCHE_ARRIERE   ; MOTEUR_GAUCHE_INVERSE
		BL	MOTEUR_DROIT_AVANT
		BL WAIT
		BL WAIT
		BL	MOTEUR_GAUCHE_AVANT

		B CheckBumpers


		;; Boucle d'attente
WAIT	
		ldr r1, =0x2BFFFF
wait1	
		subs r1, #1
        bne wait1
		
		;; retour � la suite du lien de branchement
		BX	LR


		;; Boucle d'attente pour bumper droit
waitBumperRight	
		ldr r1, =0xAFFFF
wait2
		ldr r10, [r8]
		CMP r10, #0x0 ; Check if left and right are pushed
		BEQ TurnOnLeds
		subs r1, #1
        bne wait2
		
		B TurnOnLed1
	
	
		;; Boucle d'attente pour bumper gauche
waitBumperleft
		ldr r1, =0xAFFFF
wait3
		ldr r10, [r8]
		CMP r10, #0x0 ; Check if left and right are pushed
		BEQ TurnOnLeds
		subs r1, #1
        bne wait3
		
		B TurnOnLed2
	
		
MainProgram1
		B CheckBumpers
		
		nop		
		END 