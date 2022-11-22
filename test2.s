	;; RK - Evalbot (Cortex M3 de Texas Instrument)
	;; Les deux LEDs sont initialement allumées
	;; Ce programme lis l'état du bouton poussoir 1 connectée au port GPIOD broche 6
	;; Si bouton poussoir fermé ==> fait clignoter les deux LED1&2 connectée au port GPIOF broches 4&5.
   	
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

BROCHE0_1			EQU 	0x03		; bumpers 1 et 2 sur broche 0 et 1
	
; blinking frequency
DUREE   			EQU     0x002FFFFF


	  	ENTRY
		EXPORT	__main
		
		;; The IMPORT command specifies that a symbol is defined in a shared object at runtime.
		IMPORT	MOTEUR_INIT					; initialise les moteurs (configure les pwms + GPIO)
		
		IMPORT	MOTEUR_DROIT_ON				; activer le moteur droit
		IMPORT  MOTEUR_DROIT_OFF			; déactiver le moteur droit
		IMPORT  MOTEUR_DROIT_AVANT			; moteur droit tourne vers l'avant
		IMPORT  MOTEUR_DROIT_ARRIERE		; moteur droit tourne vers l'arrière
		IMPORT  MOTEUR_DROIT_INVERSE		; inverse le sens de rotation du moteur droit
		
		IMPORT	MOTEUR_GAUCHE_ON			; activer le moteur gauche
		IMPORT  MOTEUR_GAUCHE_OFF			; déactiver le moteur gauche
		IMPORT  MOTEUR_GAUCHE_AVANT			; moteur gauche tourne vers l'avant
		IMPORT  MOTEUR_GAUCHE_ARRIERE		; moteur gauche tourne vers l'arrière
		IMPORT  MOTEUR_GAUCHE_INVERSE		; inverse le sens de rotation du moteur gauche

__main	

		; ;; Enable the Port F & D peripheral clock 		(p291 datasheet de lm3s9B96.pdf)
		; ;;									
		ldr r6, = SYSCTL_PERIPH_GPIO  			;; RCGC2
        mov r0, #0x00000038  					;; Enable clock sur GPIO D et F où sont branchés les leds (0x28 == 0b111000)
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
		
		ldr r6, = GPIO_PORTF_BASE+GPIO_O_DR2R	;; Choix de l'intensité de sortie (2mA)
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

		; Configure les PWM + GPIO
		BL	MOTEUR_INIT
		
		; Activer les deux moteurs droit et gauche
		BL	MOTEUR_DROIT_ON
		BL	MOTEUR_GAUCHE_ON
		
		; Evalbot avance droit devant
		BL	MOTEUR_DROIT_AVANT	   
		BL	MOTEUR_GAUCHE_AVANT
		
		B CheckBumpers
		
TurnOnLeds
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		ldr r3, = BROCHE4_5
		str r3, [r6]
		B HalfTurn

TurnOnLed1
		ldr r6, = GPIO_PORTF_BASE + (BROCHE5<<2)
		str r2, [r6] ; Turns off Led 2
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4<<2)
		ldr r3, = BROCHE4 ; Turns on Led 1
		str r3, [r6]
		B LeftDirection

TurnOnLed2
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4<<2)
		str r2, [r6] ; Turns off Led 1
		ldr r6, = GPIO_PORTF_BASE + (BROCHE5<<2)
		ldr r3, = BROCHE5
		str r3, [r6]
		B RightDirection

TurnOffLeds
		ldr r6, = GPIO_PORTF_BASE + (BROCHE4_5<<2)
		str r2, [r6]
		B CheckBumpers
		
CheckRightBumper
		B SHORTWAIT
		CMP r10, #0x01 ; check if bumper right is pushed
		BEQ TurnOnLeds
		B TurnOnLed1
		
CheckLeftBumper
		B SHORTWAIT
		CMP r10, #0x02 ; check if bumper left is pushed
		BEQ TurnOnLeds
		B TurnOnLed2

Ajoute1
		ADD r4, #1
		B CheckBumperRight
		
Ajoute2
		ADD r4, #2
		B CompareResult

CheckBumpers
		ldr r10, [r8]
		ldr r4, =0x0
		CMP r10, #0x02 ; Check if bumper left is pushed
		BEQ Ajoute1
		;BEQ CheckRightBumper
		;BEQ TurnOnLed1
		
CheckBumperRight
		CMP r10, #0x01 ; check if bumper right is pushed
		BEQ Ajoute2
		;BEQ CheckLeftBumper
		;BEQ TurnOnLed2
CompareResult
		CMP r4, #3
		BEQ TurnOnLeds
		CMP r4, #1
		BEQ TurnOnLed1
		CMP r4, #2
		BEQ TurnOnLed2
		
		B TurnOffLeds ; if none, turn off leds

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
		BL	WAIT
		BL	WAIT   
		BL	MOTEUR_GAUCHE_AVANT
		B CheckBumpers


		;; Boucle d'attante
WAIT	ldr r1, =0x2BFFFF
wait1	subs r1, #1
        bne wait1
		
SHORTWAIT	ldr r1, =0xEAAAA  ;; = WAIT / 3
wait2	subs r1, #1
        bne wait2
		
		;; retour à la suite du lien de branchement
		BX	LR
		
		
		nop		
		END 