 ; ================================================================
; EEE 4706 Project - Clean Hardware Version
; Hardware map taken from user's known-good hardware code
; ---------------------------------------------------------------
; LCD data   : P0
; LCD ctrl   : RS=P3.5, RW=P3.6, E=P3.7
; Keypad     : P2
; UART/HC-05 : RXD=P3.0, TXD=P3.1
; Relay 1    : P3.2
; Relay 2    : P3.3
; LEDs 1..8  : P1.0..P1.7
; ---------------------------------------------------------------
; Modes:
;   1 = Relay control
;   2 = Morse + LED control
;   3 = Encryption / Decryption
;   4 = Advanced 8-LED + brightness control
; ================================================================

$NOMOD51
$INCLUDE (8051.MCU)

; ------------------------------
; PIN
; ------------------------------
PIN_D1      EQU     '1'
PIN_D2      EQU     '2'
PIN_D3      EQU     '3'
PIN_D4      EQU     '4'

; ------------------------------
; Hardware aliases
; ------------------------------
LCD_DATA    EQU     P0
RS          EQU     P3.5
RW          EQU     P3.6
E           EQU     P3.7
REL1        EQU     P3.2
REL2        EQU     P3.3

; ------------------------------
; RAM variables
; ------------------------------
pattern     EQU     30H
length      EQU     31H
m_led_mask  EQU     32H
m_led_num   EQU     33H
line2_pos   EQU     34H
enc_key     EQU     35H
tmp1        EQU     36H
tmp2        EQU     37H
rx_head     EQU     38H
rx_tail     EQU     39H
rx_count    EQU     3AH
led4_mask   EQU     3BH
led4_bright EQU     3CH
led4_pwm    EQU     3DH

            ORG     0000H
            LJMP    START

            ORG     0023H
ISR_SERIAL:
            PUSH    ACC
            PUSH    PSW
            PUSH    00H

            JNB     RI, ISR_DONE

            MOV     A, rx_count
            CJNE    A, #10H, ISR_STORE
            MOV     A, SBUF
            CLR     RI
            SJMP    ISR_DONE

ISR_STORE:
            MOV     R0, rx_head
            MOV     A, SBUF
            MOV     @R0, A
            CLR     RI
            INC     R0
            CJNE    R0, #60H, ISR_HEAD_OK
            MOV     R0, #50H
ISR_HEAD_OK:
            MOV     rx_head, R0
            INC     rx_count

ISR_DONE:
            POP     00H
            POP     PSW
            POP     ACC
            RETI

; ===============================================================
; START
; ===============================================================
START:
            MOV     SP, #5FH
            MOV     P0, #0FFH
            MOV     P1, #00H
            MOV     P2, #0FFH
            MOV     P3, #0FFH
            MOV     PSW, #00H
            LCALL   RXBUF_INIT
            LCALL   UART_INIT
            LCALL   LCD_INIT
            LJMP    SPLASH

; ===============================================================
; SPLASH / PASSWORD
; ===============================================================
SPLASH:
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG1
            LCALL   LCD_MSG
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     DPTR, #MSG2
            LCALL   LCD_MSG
            LCALL   DELAY1S
            LCALL   DELAY1S
            LJMP    PASS_START

PASS_START:
            MOV     R6, #3
PASS_PROMPT:
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_PIN
            LCALL   LCD_MSG
            MOV     A, #0C0H
            LCALL   COMNWRT

            ACALL   GET_KEY
            MOV     P2, #0FFH
            MOV     40H, A
            MOV     A, #'*'
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT

            ACALL   GET_KEY
            MOV     P2, #0FFH
            MOV     41H, A
            MOV     A, #'*'
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT

            ACALL   GET_KEY
            MOV     P2, #0FFH
            MOV     42H, A
            MOV     A, #'*'
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT

            ACALL   GET_KEY
            MOV     P2, #0FFH
            MOV     43H, A
            MOV     A, #'*'
            LCALL   DATAWRT

            LCALL   DELAY1S

            MOV     A, 40H
            CJNE    A, #PIN_D1, PASS_WRONG
            MOV     A, 41H
            CJNE    A, #PIN_D2, PASS_WRONG
            MOV     A, 42H
            CJNE    A, #PIN_D3, PASS_WRONG
            MOV     A, 43H
            CJNE    A, #PIN_D4, PASS_WRONG

PASS_OK:
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_OK
            LCALL   LCD_MSG
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_WELCOME
            LCALL   LCD_MSG
            LCALL   DELAY1S
            LCALL   DELAY1S
            LJMP    MENU

PASS_WRONG:
            DJNZ    R6, PASS_LEFT
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_LOCK
            LCALL   LCD_MSG
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_WAIT
            LCALL   LCD_MSG
            MOV     R7, #10
PASS_WAIT_LOOP:
            LCALL   DELAY1S
            DJNZ    R7, PASS_WAIT_LOOP
            LJMP    PASS_START

PASS_LEFT:
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_WRONG
            LCALL   LCD_MSG
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_LEFT
            LCALL   LCD_MSG
            MOV     A, R6
            ADD     A, #'0'
            LCALL   DATAWRT
            LCALL   DELAY1S
            LJMP    PASS_PROMPT

; ===============================================================
; MENU
; ===============================================================
MENU:
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_MENU1
            LCALL   LCD_MSG
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_MENU2
            LCALL   LCD_MSG
            ACALL   GET_KEY
            MOV     P2, #0FFH
            CJNE    A, #'1', MENU_CHK2
            LJMP    RELAY_MODE
MENU_CHK2:  CJNE    A, #'2', MENU_CHK3
            LJMP    MORSE_MODE
MENU_CHK3:  CJNE    A, #'3', MENU_CHK4
            LJMP    ENCRYPT_MODE
MENU_CHK4:  CJNE    A, #'4', MENU
            LJMP    LEDCTRL_MODE

; ===============================================================
; MODE 1: RELAY CONTROL
; Keypad and Bluetooth both accepted
; 1=R1 ON 0=R1 OFF 3=R2 ON 2=R2 OFF 5=back
; ===============================================================
RELAY_MODE:
            LCALL   RXBUF_INIT
            CLR     REL1
            CLR     REL2
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_RELAY1
            LCALL   LCD_MSG
            LCALL   RELAY_SHOW
            MOV     DPTR, #MSG_BT_REL_READY
            LCALL   UART_SEND_STR

RELAY_LOOP:
            LCALL   KEY_CHECK
            JNZ     RELAY_HAVE_CMD
            LCALL   BT_CHECK
            JZ      RELAY_LOOP
RELAY_HAVE_CMD:
            CJNE    A, #'5', RELAY_NOT_BACK
            CLR     REL1
            CLR     REL2
            LJMP    MENU
RELAY_NOT_BACK:
            CJNE    A, #'1', RELAY_NOT_R1ON
            SETB    REL1
            LCALL   RELAY_SHOW
            LJMP    RELAY_LOOP
RELAY_NOT_R1ON:
            CJNE    A, #'0', RELAY_NOT_R1OFF
            CLR     REL1
            LCALL   RELAY_SHOW
            LJMP    RELAY_LOOP
RELAY_NOT_R1OFF:
            CJNE    A, #'3', RELAY_NOT_R2ON
            SETB    REL2
            LCALL   RELAY_SHOW
            LJMP    RELAY_LOOP
RELAY_NOT_R2ON:
            CJNE    A, #'2', RELAY_LOOP
            CLR     REL2
            LCALL   RELAY_SHOW
            LJMP    RELAY_LOOP

RELAY_SHOW:
            PUSH    ACC
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     A, #'R'
            LCALL   DATAWRT
            MOV     A, #'1'
            LCALL   DATAWRT
            MOV     A, #':'
            LCALL   DATAWRT
            MOV     A, P3
            ANL     A, #00000100B
            JZ      RELAY_R1_ZERO
            MOV     A, #'1'
            SJMP    RELAY_R1_DONE
RELAY_R1_ZERO:
            MOV     A, #'0'
RELAY_R1_DONE:
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT
            MOV     A, #'R'
            LCALL   DATAWRT
            MOV     A, #'2'
            LCALL   DATAWRT
            MOV     A, #':'
            LCALL   DATAWRT
            MOV     A, P3
            ANL     A, #00001000B
            JZ      RELAY_R2_ZERO
            MOV     A, #'1'
            SJMP    RELAY_R2_DONE
RELAY_R2_ZERO:
            MOV     A, #'0'
RELAY_R2_DONE:
            LCALL   DATAWRT
            POP     ACC
            RET

; ===============================================================
; MODE 2: MORSE + 8 LED CONTROL
; Bluetooth commands:
;   1..8  = select Morse LED
;   .     = dot
;   -     = dash
;   space = end letter and decode
;   /     = word space
;   0     = back to menu
; ===============================================================
MORSE_MODE:
            LCALL   RXBUF_INIT
            MOV     P1, #00H
            MOV     pattern, #00H
            MOV     length, #00H
            MOV     m_led_mask, #00H
            MOV     m_led_num, #00H
            MOV     line2_pos, #0C0H
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_MORSE1
            LCALL   LCD_MSG
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_MORSE2
            LCALL   LCD_MSG
            MOV     DPTR, #MSG_BT_MORSE_READY
            LCALL   UART_SEND_STR

MORSE_LOOP:
            LCALL   REC_FUNC
            CJNE    A, #'0', MORSE_CHK_DIGIT
            LJMP    MENU

MORSE_CHK_DIGIT:
            CJNE    A, #'1', MORSE_CHK2
            MOV     m_led_mask, #01H
            MOV     m_led_num,  #'1'
            LCALL   MORSE_SHOW_SEL
            LJMP    MORSE_LOOP
MORSE_CHK2: CJNE    A, #'2', MORSE_CHK3
            MOV     m_led_mask, #02H
            MOV     m_led_num,  #'2'
            LCALL   MORSE_SHOW_SEL
            LJMP    MORSE_LOOP
MORSE_CHK3: CJNE    A, #'3', MORSE_CHK4
            MOV     m_led_mask, #04H
            MOV     m_led_num,  #'3'
            LCALL   MORSE_SHOW_SEL
            LJMP    MORSE_LOOP
MORSE_CHK4: CJNE    A, #'4', MORSE_CHK5
            MOV     m_led_mask, #08H
            MOV     m_led_num,  #'4'
            LCALL   MORSE_SHOW_SEL
            LJMP    MORSE_LOOP
MORSE_CHK5: CJNE    A, #'5', MORSE_CHK6
            MOV     m_led_mask, #10H
            MOV     m_led_num,  #'5'
            LCALL   MORSE_SHOW_SEL
            LJMP    MORSE_LOOP
MORSE_CHK6: CJNE    A, #'6', MORSE_CHK7
            MOV     m_led_mask, #20H
            MOV     m_led_num,  #'6'
            LCALL   MORSE_SHOW_SEL
            LJMP    MORSE_LOOP
MORSE_CHK7: CJNE    A, #'7', MORSE_CHK8
            MOV     m_led_mask, #40H
            MOV     m_led_num,  #'7'
            LCALL   MORSE_SHOW_SEL
            LJMP    MORSE_LOOP
MORSE_CHK8: CJNE    A, #'8', MORSE_CHK_DOT
            MOV     m_led_mask, #80H
            MOV     m_led_num,  #'8'
            LCALL   MORSE_SHOW_SEL
            LJMP    MORSE_LOOP

MORSE_CHK_DOT:
            CJNE    A, #'.', MORSE_CHK_DASH
            LCALL   MORSE_DOT
            LJMP    MORSE_LOOP
MORSE_CHK_DASH:
            CJNE    A, #'-', MORSE_CHK_SPACE
            LCALL   MORSE_DASH
            LJMP    MORSE_LOOP
MORSE_CHK_SPACE:
            CJNE    A, #' ', MORSE_CHK_SLASH
            LCALL   DECODE_LETTER
            LJMP    MORSE_LOOP
MORSE_CHK_SLASH:
            CJNE    A, #'/', MORSE_NOT_SLASH
            LCALL   DECODE_LETTER
            MOV     A, #' '
            LCALL   LINE2_APPEND
            LJMP    MORSE_LOOP
MORSE_NOT_SLASH:
            LJMP    MORSE_LOOP

MORSE_DOT:
            MOV     A, m_led_mask
            JZ      MD_RET
            MOV     P1, A
            LCALL   DELAY500MS
            MOV     P1, #00H
            LCALL   MORSE_SHOW_DOT
            MOV     A, pattern
            RL      A
            ANL     A, #1FH
            MOV     pattern, A
            INC     length
MD_RET:     RET

MORSE_DASH:
            MOV     A, m_led_mask
            JZ      MH_RET
            MOV     P1, A
            LCALL   DELAY1S
            MOV     P1, #00H
            LCALL   MORSE_SHOW_DASH
            MOV     A, pattern
            RL      A
            ANL     A, #1FH
            ORL     A, #01H
            MOV     pattern, A
            INC     length
MH_RET:     RET

MORSE_SHOW_SEL:
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_SEL
            LCALL   LCD_MSG
            MOV     A, m_led_num
            LCALL   DATAWRT
            MOV     DPTR, #MSG_PAD6
            LCALL   LCD_MSG
            RET

MORSE_SHOW_DOT:
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_SYM_DOT
            LCALL   LCD_MSG
            RET

MORSE_SHOW_DASH:
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_SYM_DASH
            LCALL   LCD_MSG
            RET

DECODE_LETTER:
            MOV     A, length
            JZ      DL_EXIT
            CLR     C
            SUBB    A, #06H
            JNC     DL_CLEAR
            MOV     A, length
            MOV     DPTR, #lengthOffset
            MOVC    A, @A+DPTR
            MOV     tmp1, A
            MOV     A, pattern
            ADD     A, tmp1
            MOV     DPTR, #decodeTable
            MOVC    A, @A+DPTR
            JZ      DL_CLEAR
            LCALL   LINE2_APPEND
DL_CLEAR:
            MOV     pattern, #00H
            MOV     length,  #00H
DL_EXIT:    RET

LINE2_APPEND:
            MOV     tmp2, A
            MOV     A, line2_pos
            LCALL   COMNWRT
            MOV     A, tmp2
            LCALL   DATAWRT
            INC     line2_pos
            MOV     A, line2_pos
            CJNE    A, #0D0H, L2_RET
            MOV     line2_pos, #0C0H
L2_RET:     RET

; ===============================================================
; MODE 3: ENCRYPT / DECRYPT
; Keypad digit = Caesar key (0..9)
; Bluetooth sends encrypted text
; '/' or CR or LF ends current message
; Spaces are preserved and output is shown on LCD line 2
; Keypad 5 returns to menu, any other key restarts mode
; ===============================================================
ENCRYPT_MODE:
            LCALL   RXBUF_INIT
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_ENC1
            LCALL   LCD_MSG
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_KEYIN
            LCALL   LCD_MSG
            ACALL   GET_KEY
            MOV     P2, #0FFH
            MOV     enc_key, A
            MOV     A, enc_key
            LCALL   DATAWRT
            MOV     A, enc_key
            CLR     C
            SUBB    A, #'0'
            MOV     enc_key, A
            LCALL   DELAY1S

ENC_START_MSG:
            LCALL   RXBUF_INIT
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_ENC2
            LCALL   LCD_MSG
            MOV     line2_pos, #0C0H

ENC_LOOP:
            LCALL   REC_FUNC
            CJNE    A, #'/', ENC_CHK_CR
            SJMP    ENC_DONE
ENC_CHK_CR:
            CJNE    A, #0DH, ENC_CHK_LF
            SJMP    ENC_DONE
ENC_CHK_LF:
            CJNE    A, #0AH, ENC_CHK_SPACE
            SJMP    ENC_DONE
ENC_CHK_SPACE:
            CJNE    A, #' ', ENC_CHK_UPPER
            LCALL   LINE2_APPEND
            LJMP    ENC_LOOP

ENC_CHK_UPPER:
            MOV     tmp1, A
            CLR     C
            SUBB    A, #'A'
            JC      ENC_CHK_LOWER
            MOV     A, tmp1
            CLR     C
            SUBB    A, #('Z'+1)
            JNC     ENC_CHK_LOWER
            MOV     A, tmp1
            CLR     C
            SUBB    A, #'A'
            CLR     C
            SUBB    A, enc_key
            JNC     ENC_UPPER_OK
            ADD     A, #26
ENC_UPPER_OK:
            ADD     A, #'A'
            LCALL   LINE2_APPEND
            LJMP    ENC_LOOP

ENC_CHK_LOWER:
            MOV     A, tmp1
            CLR     C
            SUBB    A, #'a'
            JC      ENC_RAW
            MOV     A, tmp1
            CLR     C
            SUBB    A, #('z'+1)
            JNC     ENC_RAW
            MOV     A, tmp1
            CLR     C
            SUBB    A, #'a'
            CLR     C
            SUBB    A, enc_key
            JNC     ENC_LOWER_OK
            ADD     A, #26
ENC_LOWER_OK:
            ADD     A, #'A'
            LCALL   LINE2_APPEND
            LJMP    ENC_LOOP

ENC_RAW:
            MOV     A, tmp1
            LCALL   LINE2_APPEND
            LJMP    ENC_LOOP

ENC_DONE:
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_ENC3
            LCALL   LCD_MSG
            ACALL   GET_KEY
            MOV     P2, #0FFH
            CJNE    A, #'5', ENC_RESTART
            LJMP    MENU
ENC_RESTART:
            LJMP    ENCRYPT_MODE

; ===============================================================
; MODE 4: ADVANCED 8-LED + BRIGHTNESS CONTROL
; Bluetooth / keypad commands:
;   1..8 = toggle LED1..LED8
;   9    = all LEDs ON
;   0    = all LEDs OFF
;   .    = brightness up
;   -    = brightness down
;   /    = back to menu
; Brightness is global for the current LED mask.
; ===============================================================
LEDCTRL_MODE:
            LCALL   RXBUF_INIT
            MOV     P1, #00H
            MOV     led4_mask, #00H
            MOV     led4_bright, #09H
            MOV     led4_pwm, #00H
            LCALL   LCD_CLR
            MOV     A, #80H
            LCALL   COMNWRT
            MOV     DPTR, #MSG_LED41
            LCALL   LCD_MSG
            LCALL   LED4_SHOW
            MOV     DPTR, #MSG_BT_LED4_READY
            LCALL   UART_SEND_STR

LED4_LOOP:
            LCALL   LED4_PWM_SLICE
            LCALL   KEY_CHECK
            JNZ     LED4_HAVE_CMD
            LCALL   BT_CHECK
            JZ      LED4_LOOP

LED4_HAVE_CMD:
            CJNE    A, #'/', LED4_NOT_BACK
            MOV     P1, #00H
            LJMP    MENU

LED4_NOT_BACK:
            CJNE    A, #'1', LED4_CHK2
            MOV     A, led4_mask
            XRL     A, #01H
            MOV     led4_mask, A
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK2:  CJNE    A, #'2', LED4_CHK3
            MOV     A, led4_mask
            XRL     A, #02H
            MOV     led4_mask, A
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK3:  CJNE    A, #'3', LED4_CHK4
            MOV     A, led4_mask
            XRL     A, #04H
            MOV     led4_mask, A
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK4:  CJNE    A, #'4', LED4_CHK5
            MOV     A, led4_mask
            XRL     A, #08H
            MOV     led4_mask, A
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK5:  CJNE    A, #'5', LED4_CHK6
            MOV     A, led4_mask
            XRL     A, #10H
            MOV     led4_mask, A
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK6:  CJNE    A, #'6', LED4_CHK7
            MOV     A, led4_mask
            XRL     A, #20H
            MOV     led4_mask, A
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK7:  CJNE    A, #'7', LED4_CHK8
            MOV     A, led4_mask
            XRL     A, #40H
            MOV     led4_mask, A
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK8:  CJNE    A, #'8', LED4_CHK_ALLON
            MOV     A, led4_mask
            XRL     A, #80H
            MOV     led4_mask, A
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP

LED4_CHK_ALLON:
            CJNE    A, #'9', LED4_CHK_ALLOFF
            MOV     led4_mask, #0FFH
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK_ALLOFF:
            CJNE    A, #'0', LED4_CHK_BUP
            MOV     led4_mask, #00H
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK_BUP:
            CJNE    A, #'.', LED4_CHK_BDN
            MOV     A, led4_bright
            CJNE    A, #09H, LED4_BUP_DO
            LJMP    LED4_LOOP
LED4_BUP_DO:
            INC     led4_bright
            LCALL   LED4_SHOW
            LJMP    LED4_LOOP
LED4_CHK_BDN:
            CJNE    A, #'-', LED4_IGNORE
            MOV     A, led4_bright
            JZ      LED4_BDN_EXIT
            DEC     led4_bright
            LCALL   LED4_SHOW
LED4_BDN_EXIT:
            LJMP    LED4_LOOP
LED4_IGNORE:
            LJMP    LED4_LOOP

LED4_PWM_SLICE:
            MOV     A, led4_pwm
            INC     A
            CJNE    A, #0AH, LED4_PWM_SAVE
            MOV     A, #00H
LED4_PWM_SAVE:
            MOV     led4_pwm, A
            CJNE    A, led4_bright, LED4_PWM_NE
            SJMP    LED4_PWM_OFF
LED4_PWM_NE:
            JC      LED4_PWM_ON

LED4_PWM_OFF:
            MOV     P1, #00H
            LCALL   LED4_PWM_DELAY
            RET

LED4_PWM_ON:
            MOV     A, led4_mask
            MOV     P1, A
            LCALL   LED4_PWM_DELAY
            RET

LED4_PWM_DELAY:
            MOV     R4, #08
LED4_PD1:   MOV     R5, #80
LED4_PD2:   DJNZ    R5, LED4_PD2
            DJNZ    R4, LED4_PD1
            RET

LED4_SHOW:
            MOV     A, #0C0H
            LCALL   COMNWRT
            MOV     A, #'B'
            LCALL   DATAWRT
            MOV     A, #':'
            LCALL   DATAWRT
            MOV     A, led4_bright
            ADD     A, #'0'
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT
            MOV     A, #'M'
            LCALL   DATAWRT
            MOV     A, #':'
            LCALL   DATAWRT
            MOV     A, led4_mask
            SWAP    A
            LCALL   HEX_NIBBLE_ASC
            LCALL   DATAWRT
            MOV     A, led4_mask
            LCALL   HEX_NIBBLE_ASC
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT
            MOV     A, #'/'
            LCALL   DATAWRT
            MOV     A, #'='
            LCALL   DATAWRT
            MOV     A, #'B'
            LCALL   DATAWRT
            MOV     A, #'k'
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT
            MOV     A, #' '
            LCALL   DATAWRT
            RET

HEX_NIBBLE_ASC:
            ANL     A, #0FH
            CLR     C
            SUBB    A, #0AH
            JC      HN_DEC
            ADD     A, #'A'
            RET
HN_DEC:
            ADD     A, #('0'+10)
            RET

; ===============================================================
; LCD ROUTINES
; ===============================================================
LCD_INIT:
            LCALL   LONGDELAY
            LCALL   LONGDELAY
            MOV     A, #38H
            LCALL   COMNWRT
            MOV     A, #38H
            LCALL   COMNWRT
            MOV     A, #38H
            LCALL   COMNWRT
            MOV     A, #0FH
            LCALL   COMNWRT
            MOV     A, #01H
            LCALL   COMNWRT
            LCALL   LONGDELAY
            MOV     A, #06H
            LCALL   COMNWRT
            RET

LCD_CLR:
            MOV     A, #01H
            LCALL   COMNWRT
            LCALL   LONGDELAY
            RET

LCD_MSG:
            CLR     A
LCD_NEXT:
            MOVC    A, @A+DPTR
            JZ      LCD_DONE
            LCALL   DATAWRT
            INC     DPTR
            CLR     A
            SJMP    LCD_NEXT
LCD_DONE:   RET

COMNWRT:
            MOV     LCD_DATA, A
            CLR     RS
            CLR     RW
            SETB    E
            LCALL   DELAY
            CLR     E
            LCALL   DELAY
            RET

DATAWRT:
            MOV     LCD_DATA, A
            SETB    RS
            CLR     RW
            SETB    E
            LCALL   DELAY
            CLR     E
            LCALL   DELAY
            RET

; ===============================================================
; UART
; ===============================================================
UART_INIT:
            CLR     TR1
            SETB    ES
            MOV     TMOD, #20H
            MOV     TH1,  #0FDH
            MOV     TL1,  #0FDH
            MOV     SCON, #50H
            CLR     TI
            CLR     RI
            SETB    TR1
            SETB    EA
            RET

RXBUF_INIT:
            MOV     rx_head, #50H
            MOV     rx_tail, #50H
            MOV     rx_count, #00H
            RET

RXBUF_GET:
            MOV     A, rx_count
            JZ      RXG_EMPTY
            DEC     rx_count
            MOV     R0, rx_tail
            MOV     A, @R0
            INC     R0
            CJNE    R0, #60H, RXG_OK
            MOV     R0, #50H
RXG_OK:
            MOV     rx_tail, R0
            RET
RXG_EMPTY:
            MOV     A, #00H
            RET

; Blocking receive with measured normalization
REC_FUNC:
RF_WAIT:
            MOV     A, rx_count
            JZ      RF_WAIT
            LCALL   RXBUF_GET
            LCALL   NORMALIZE_RX
            JZ      RF_WAIT
            RET

; Non-blocking receive with measured normalization
BT_CHECK:
BT_NEXT:
            MOV     A, rx_count
            JZ      BT_NONE
            LCALL   RXBUF_GET
            LCALL   NORMALIZE_RX
            JZ      BT_NEXT
            RET
BT_NONE:
            MOV     A, #00H
            RET

; Measured bytes from hardware/app:
; A -> 81h, 1 -> 71h, 8 -> 78h
; . -> 4Eh, - -> 4Dh, space -> 40h, / -> 4Fh, 0 -> 70h
NORMALIZE_RX:
            CJNE    A, #0DH, NRX_CHKLF
            MOV     A, #00H
            RET
NRX_CHKLF:  CJNE    A, #0AH, NRX_CHKDOT
            MOV     A, #00H
            RET
NRX_CHKDOT: CJNE    A, #04EH, NRX_CHKDASH
            MOV     A, #'.'
            RET
NRX_CHKDASH:
            CJNE    A, #04DH, NRX_CHKSP
            MOV     A, #'-'
            RET
NRX_CHKSP:  CJNE    A, #040H, NRX_CHKSL
            MOV     A, #' '
            RET
NRX_CHKSL:  CJNE    A, #04FH, NRX_SUB40
            MOV     A, #'/'
            RET
NRX_SUB40:
            CLR     C
            SUBB    A, #040H
            RET

UART_SEND:
            CLR     TI
            MOV     SBUF, A
US_WAIT:    JNB     TI, US_WAIT
            CLR     TI
            RET

UART_SEND_STR:
            CLR     A
USS_NEXT:   MOVC    A, @A+DPTR
            JZ      USS_DONE
            LCALL   UART_SEND
            INC     DPTR
            CLR     A
            SJMP    USS_NEXT
USS_DONE:   RET

; ===============================================================
; KEYPAD
; ===============================================================
GET_KEY:
GK0:        MOV     P2, #0FFH
GK1:        CLR     P2.4
            CLR     P2.5
            CLR     P2.6
            CLR     P2.7
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, GK1
GK2:        LCALL   DELAY
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, GK_DEB
            SJMP    GK2
GK_DEB:     LCALL   DELAY
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, GK_SCAN
            SJMP    GK2
GK_SCAN:
            MOV     P2, #0FFH
            CLR     P2.4
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, GK_R0
            MOV     P2, #0FFH
            CLR     P2.5
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, GK_R1
            MOV     P2, #0FFH
            CLR     P2.6
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, GK_R2
            MOV     P2, #0FFH
            CLR     P2.7
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, GK_R3
            SJMP    GK2
GK_R0:      MOV     DPTR, #KCODE0
            SJMP    GK_FIND
GK_R1:      MOV     DPTR, #KCODE1
            SJMP    GK_FIND
GK_R2:      MOV     DPTR, #KCODE2
            SJMP    GK_FIND
GK_R3:      MOV     DPTR, #KCODE3
GK_FIND:    RRC     A
            JNC     GK_MATCH
            INC     DPTR
            SJMP    GK_FIND
GK_MATCH:   CLR     A
            MOVC    A, @A+DPTR
            MOV     P2, #0FFH
            RET

KEY_CHECK:
            MOV     P2, #0FFH
            CLR     P2.4
            CLR     P2.5
            CLR     P2.6
            CLR     P2.7
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, KC_SCAN
            MOV     P2, #0FFH
            MOV     A, #00H
            RET
KC_SCAN:
            MOV     P2, #0FFH
            CLR     P2.4
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, KC_R0
            MOV     P2, #0FFH
            CLR     P2.5
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, KC_R1
            MOV     P2, #0FFH
            CLR     P2.6
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, KC_R2
            MOV     P2, #0FFH
            CLR     P2.7
            MOV     A, P2
            ANL     A, #0FH
            CJNE    A, #0FH, KC_R3
            MOV     P2, #0FFH
            MOV     A, #00H
            RET
KC_R0:      MOV     DPTR, #KCODE0
            SJMP    KC_FIND
KC_R1:      MOV     DPTR, #KCODE1
            SJMP    KC_FIND
KC_R2:      MOV     DPTR, #KCODE2
            SJMP    KC_FIND
KC_R3:      MOV     DPTR, #KCODE3
KC_FIND:    RRC     A
            JNC     KC_MATCH
            INC     DPTR
            SJMP    KC_FIND
KC_MATCH:   CLR     A
            MOVC    A, @A+DPTR
            PUSH    ACC
KC_WAITREL: MOV     P2, #0FFH
            CLR     P2.4
            CLR     P2.5
            CLR     P2.6
            CLR     P2.7
            MOV     tmp1, P2
            MOV     A, tmp1
            ANL     A, #0FH
            CJNE    A, #0FH, KC_WAITREL
            MOV     P2, #0FFH
            POP     ACC
            RET

; ===============================================================
; DELAYS
; ===============================================================
DELAY:
            MOV     R3, #50
D1:         MOV     R5, #255
D2:         DJNZ    R5, D2
            DJNZ    R3, D1
            RET

LONGDELAY:
            MOV     R3, #200
LD1:        MOV     R5, #255
LD2:        DJNZ    R5, LD2
            DJNZ    R3, LD1
            RET

DELAY1S:
            MOV     R3, #20
S1:         MOV     R2, #250
S2:         MOV     R5, #200
S3:         DJNZ    R5, S3
            DJNZ    R2, S2
            DJNZ    R3, S1
            RET

DELAY500MS:
            MOV     R3, #10
H1:         MOV     R2, #250
H2:         MOV     R5, #200
H3:         DJNZ    R5, H3
            DJNZ    R2, H2
            DJNZ    R3, H1
            RET

; ===============================================================
; TABLES / STRINGS
; ===============================================================
            ORG     1200H
lengthOffset:
            DB      0, 2, 4, 8, 16, 32

decodeTable:
            DB      0, 0
            DB      'E','T'
            DB      'I','A','N','M'
            DB      'S','U','R','W','D','K','G','O'
            DB      'H','V','F',0,'L',0,'P','J'
            DB      'B','X','C','Y','Z','Q',0,0
            DB      '5','4',0,'3',0,'2',0,'1'
            DB      '6',0,0,'7',0,'8','9','0'
            DB      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
            DB      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

            ORG     1400H
MSG1:       DB      'EEE 4706 Project',0
MSG2:       DB      'Hardware Final  ',0
MSG_PIN:    DB      'Enter PIN:      ',0
MSG_OK:     DB      'Access Granted! ',0
MSG_WELCOME:DB      'Welcome         ',0
MSG_WRONG:  DB      'Wrong PIN!      ',0
MSG_LEFT:   DB      'Tries left:     ',0
MSG_LOCK:   DB      '** LOCKED **    ',0
MSG_WAIT:   DB      'Wait 10 seconds ',0
MSG_MENU1:  DB      'Select a mode   ',0
MSG_MENU2:  DB      '1R 2M 3E 4LED  ',0
MSG_RELAY1: DB      'Relay mode      ',0
MSG_MORSE1: DB      'Morse mode      ',0
MSG_MORSE2: DB      'Send 1..8 / .-  ',0
MSG_ENC1:   DB      'Decrypt key?    ',0
MSG_ENC2:   DB      'Send txt end /  ',0
MSG_ENC3:   DB      'Done 5=back    ',0
MSG_KEYIN:  DB      'Enter key 0..9  ',0
MSG_BACK5:  DB      '5=back else rpt ',0
MSG_SEL:    DB      'SEL LED:',0
MSG_PAD6:   DB      '        ',0
MSG_SYM_DOT:DB      'SYM:.          ',0
MSG_SYM_DASH:DB     'SYM:-          ',0
MSG_BT_REL_READY:
            DB      'Relay ready',0DH,0AH,0
MSG_BT_MORSE_READY:
            DB      'Morse ready',0DH,0AH,'1..8 select LED',0DH,0AH,'. - sp / 0',0DH,0AH,0
MSG_BT_LED4_READY:
            DB      'LED ctrl ready',0DH,0AH
            DB      '1..8 toggle 9=all on',0DH,0AH
            DB      '0=all off .=B+ -=B-',0DH,0AH
            DB      '/=back',0DH,0AH,0

            ORG     1800H
KCODE0:     DB      '1','2','3','-'
KCODE1:     DB      '4','5','6','*'
KCODE2:     DB      '7','8','9','/'
KCODE3:     DB      'C','0','=','+'

            END
