;       ************************************************************
;       *****             Line Cutter card program             *****
;       *****              (C) 1997 Richard Moore              *****
;       ************************************************************
;
;       ************************************************************
;       *****    Use 'MPALC /P 16C57 CUTTER.ASM to assemble'.  *****
;       *****     Port A is used for environmental I/O i.e     *****
;       *****  bit 0 = motor on/off, bit 1 = revolution pulses *****
;       *****   bit 2 = motor inch push button, bit 3 = start  *****
;       ***** Port B is used to accept a byte from a dil switch*****
;       ***** The data input from port B determines the length *****
;       ***** of line to be cut, each pulse received = 1.8mm   *****
;       *****   of line fed. The line is to be fed until line  *****
;       *****   out = desired value set on Port B switches.    *****
;       ************************************************************

INCLUDE "PICREG.EQU"    ;Declares some commonly used constants

;               *****   Define some constants   *****

DesiredLength  EQU       0x08    ;Register holds desired length
Delay_1        EQU       0x09    ;Temporary delay register
Delay_2        EQU       0x0A    ;Temporary delay register
CurrentLength  EQU       0x0B    ;Register holds current length
CurrentPulse   EQU       0x0C    ;Register holds current pulse count
CurrentCut     EQU       0x0D    ;Register holds current number of cuts

Cuts           EQU       0x0A
Motor          EQU       0x00
Pulse          EQU       0x01
Inch           EQU       0x02
Go             EQU       0x03
Solenoid       EQU       0x00

START                   ;***  INITIALISATION  ***
        MOVLW   0x00
        TRIS    Port_C
        BSF     Port_C , Solenoid ;De-energise solenoid
        MOVLW   0x0E
        TRIS    Port_A          ;Set bit 0 port A as output, rest are input
        BSF     Port_A , Motor  ;Stop the motor
        MOVLW   0xFF
        TRIS    Port_B          ;Set port B as input
        CALL    DELAY2
        MOVF    Port_B , 0x00   ;Get the switch settings from port B into W
        MOVWF   DesiredLength   ;store desired length in register 8

;               *****   POLL PORT A BIT'S 2 & 3 FOR INTERRUPT *****

DO_SOMETHING
     BSF       Port_A , Motor ;Stop motor just in case
     BTFSS     Port_A , Inch  ;Is inch button pressed ?
     CALL      INCHY_INCHY    ;If pressed then inch the motor

     BTFSS     Port_A , Go    ;Has GO button been pressed?
     GOTO      ROTATE         ;If yes then start turning the motor.

     GOTO      DO_SOMETHING   ;No interrupts - keep checking....

INCHY_INCHY    ;***Inch the motor routine***

     CALL      DELAY1         ;Wait a bit to debounce switch
     BTFSC     Port_A , Inch  ;Check that button is still down
     RETLW     0x00           ;If not then false alarm - return
     BCF       Port_A , Motor ;Switch pressed - switch the motor on
     CALL      DELAY2         ;Wait some
     BSF       Port_A , Motor ;Turn the sod off...
     RETLW     0x00           ;Go back to polling

ROTATE         ;***Start the proceedings***

          MOVLW     0x00
          MOVWF     CurrentLength  ;Set current length to zero
          MOVWF     CurrentPulse   ;Reset pulse counter
          MOVWF     CurrentCut     ;Reset cut counter
          CALL      DELAY1         ;Wait a bit to debounce switch
          BTFSC     Port_A , Go    ;Check that button is still down
          RETLW     0x00           ;If not then false alarm - return
  RESTART BCF       Port_A , Motor ;Switch pressed - switch on motor
          NOP

  WAITHI  BTFSS     Port_A , Pulse ;Test for encoder pulse high
          GOTO      WAITHI         ;Wait for high pulse
          CALL      DELAY1         ;Wait some
          BTFSS     Port_A , Pulse ;Is pulse for real or glitch
          GOTO      WAITHI         ;Pulse was glitch - try again
          
          INCF      CurrentPulse,0x01 ;Increment current pulse count
          MOVLW     0x06
          XORWF     CurrentPulse , 0x00   
          BTFSC     STATUS , Z     ;Is current pulse count = 6?
          CALL      RESET          ;Yes - do the thang...
          MOVLW     0x0A    ;Get cuts into W
          XORWF     CurrentCut , 0x00
          BTFSC     STATUS , Z     ;Is current cut = cuts?
          GOTO      DO_SOMETHING

  WAITLO  BTFSC     Port_A , Pulse ;Test for encoder pulse low
          GOTO      WAITLO         ;Wait for low pulse
          CALL      DELAY1         ;Wait some
          BTFSC     Port_A , Pulse ;Is pulse for real or glitch
          GOTO      WAITLO         ;Pulse was glitch - try again
          GOTO      WAITHI         ;Pulse has gone low - wait for high


DELAY1    ;***Short delay 768uS***
          MOVLW     0x7F
          MOVWF     Delay_1
  LOOP    DECFSZ    Delay_1 , 0x01
          GOTO      LOOP
          RETLW     0x00

DELAY2    ;***Long Delay 392mS***
          MOVLW     0xFF      
          MOVWF     Delay_1   ;Set up delay numbers
  LOOP1   MOVLW     0xFF
          MOVWF     Delay_2
          DECFSZ    Delay_1 , 0x01
          GOTO      LOOP2
          RETLW     0x00
  LOOP2   DECFSZ    Delay_2 , 0x01
          GOTO      LOOP2
          GOTO      LOOP1

RESET     ;***Pulse detected - test for desired length***

     MOVLW     0x00
     MOVWF     CurrentPulse          ;Reset current pulse count
     INCF      CurrentLength , 0x01  ;Increment current length
     MOVF      DesiredLength , 0x00
     XORWF     CurrentLength , 0x00
     BTFSC     STATUS , Z     ;Is current length = desired length?
     GOTO      STOP           ;Yes - stop motor for a bit...
TIT  RETLW     0x00           ;No - go back to counting pulses

STOP      ;***Stop the motor and wait a bit***

     INCF      CurrentCut , 0x01
     BSF       Port_A , Motor ;Stop the Motor
     CALL      DELAY2         ;Wait a bit - 1.5 Secs
     BCF       Port_C , Solenoid ;Energise Solenoid
     CALL      DELAY2
     CALL      DELAY2
     BSF       Port_C , Solenoid ;De-energise Solenoid
     CALL      DELAY2
     MOVLW     0x00
     MOVWF     CurrentLength  ;Reset current length
     BCF       Port_A , Motor ;Restart the motor
     GOTO      TIT            

END
