;
; Bootloader for Android Bluetooth / WiFi board
; Written by E.J. van Veldhuizen, 2014
; 
bank_option=0
page_option=0
	NOLIST
	include "p16f1938.inc"
	NOLIST
	include "ppmacros_v14.inc"
	LIST

;#define 	FAKEINPUT		; uncomment to have to input data for debugging (see end of file) 

; SET TABSIZE to 16 (edit/properties/ASM file types)

; Configuration words:    2FA4, 39FE
	__config	_CONFIG1, (_FOSC_INTOSC & _WDTE_OFF  & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_ON) & 0x3FFF
	__config	_CONFIG2, (_WRT_BOOT & _PLLEN_ON & _STVREN_OFF & _BORV_HI & _LVP_ON) & 0x3FFF


; ***********************************************************************
; VARIABLES, CONSTANTS AND MACRP DECLARATIONS
; ***********************************************************************
	cblock 0x20      
	  delaycnt:4			; delay conter
	  TEXT_TMP			; variables for text output
	  RXDcnt, RXDtmp
	  HEXTADR:2
	  HEXOUT, HEXOUTCNT
	  fakereadadr:2
	endc

	cblock 0x70      
	  HEXADR:2, RXD, RXDl, HEXFADR:2, RXFD:2, TEXT_POS:2, TX_OUT, ERRCNT:2
	  MISC_STATE 	; bit 0: program (0) or verify (1), 
		; bit 1: hexline for programming
		; bit 2
		; bit 3
		; bit 4: flush bit 0: flush not needed, 1 flush needed
	endc

; PIN LAYOUT
;
; RA0 - 
; RA1 - 
; RA2 - 
; RA3 - 
; RA4 - 
; RA5 - 
; RA6 - 
; RA7 - 
;
; RB0 - LED Yellow
; RB1 - LED Orange 
; RB2 - CPS Button
; RB3 - NTC / Bootloader switch
; RB4 - 
; RB5 - 
; RB6 - 
; RB7 - 
;
; RC0 - 
; RC1 - 
; RC2 - 
; RC3 - 
; RC4 - 
; RC5 - 
; RC6 - Tx
; RC7 - Rx
;
; RE3 - Vpp

; *** MACROS ***

; writetext
;  writes text to TX
;  example: writetext text_OK
;  with:    text_OK:	dt	"OK",.13,.10,0
writetext	macro	textlabel
	load_f16_l16	TEXT_POS, textlabel
	call	write_text
	endm

uart_write_l	macro	value_l
	movlw	value_l
	call	uart_write_w
	endm

uart_write_f	macro	reg
	movf	ref,w
	call	uart_write_w
	endm


loadnb_f_l	macro	flag, lit
	movlw	lit
	movwf	flag
	endm

loadnb_f_f	macro	flag1, flag2
	movf	flag2, w
	movwf	flag1
	endm

DoubleC2W	macro	char1, char2
	dw	(( ((char1 & 0x3F) << 8) | ((char1 & 0x40) << 1) | (char2 & 0x7F) ) & 0x3FFF)
	endm

QuadC2W	macro	char1, char2, char3, char4
	DoubleC2W	char1, char2
	DoubleC2W	char3, char4
	endm

OctC2W	macro	char1, char2, char3, char4, char5, char6, char7, char8
	DoubleC2W	char1, char2
	DoubleC2W	char3, char4
	DoubleC2W	char5, char6
	DoubleC2W	char7, char8
	endm

; ***********************************************************************
; START OF CODE
; ***********************************************************************

	org	0x0000
; *****************************************************************************************************************
; *** CHECK BOOTLOADER SELECTED. Set ports to read Port RB2. Delay to stabilize levels
bootloadcheck	
	banksel	OPTION_REG
	loadnb_f_l	OSCCON^80, b'11111000' ; 16 MHz clock (do not use ...11 !) (see ADC Errata on 32 MHz)
	goto	init2

intvector	; Interupt vector is at 0x004 ; so we have to deal with it
	pagesel	0x0204
	goto	0x0204
	if intvector != 0x0004 
	  error "Interrupt vector not correct! Should be on 0x0004."
	endif

init2
	loadnb_f_l	TRISB^80, b'11111111'	; PORTB all input
	bcf	OPTION_REG^80, 7	; enable all weak pull up
	banksel	ANSELB
	clrf	ANSELB^180
	banksel	WPUB
	loadnb_f_l	WPUB^200, b'00000100'
	banksel	.0

	;DELAY100ms
	clrf	delaycnt		; delay 91 ms (by result :) )
	clrf	delaycnt+1
del1:	movlw	.1
	subwf	delaycnt,f
	movlw	.0
	subwfb	delaycnt+1,f
	skpz
	goto	del1

	ifndef	FAKEINPUT
	gotoif_f_b_s	PORTB, 2, 0x0200	; If bootloader button NOT pressed -> jump to 0x0200
	;gotoif_f_b_c	PORTB, 2, 0x0200	; *****************************************************
	endif

; *****************************************************************************************************************
; *** BOOTLOADER is selected, now initialize the ports

init3	bsf	PORTB, 0		; LED yellow on
	banksel	TRISB
	loadnb_f_l	TRISB^80, b'11111110'
	loadnb_f_l	TRISC^80, b'10111111'	; set RC as input (RC3 and RC4 as I2C, RC7 as Rx), set Tx (RC6) as output

	; UART init at 9600 baudrate
	; set RC7 (RX), RC6 (TX) to I/O
	; 9600 baud @ 16 MHz -> SPBRG = .25
	banksel	SPBRGH
	clrf	SPBRGH^180
	loadnb_f_l	SPBRGL^180, .25
	bcf	TXSTA^180, BRGH;, 0
	bcf	BAUDCON^180, BRG16;, 0
	; enable TX and RX
	; • TXEN = 1 • SYNC = 0 • SPEN = 1
	; • CREN = 1 • SYNC = 0 • SPEN = 1
	bsf	TXSTA^180, TXEN;, 1
	bsf	RCSTA^180, CREN;, 1
	bcf	TXSTA^180, SYNC;, 0
	bsf	RCSTA^180, SPEN;, 1

	banksel	.0
	ifdef	FAKEINPUT
	load_f16_l16	fakereadadr, fakedata
	endif

; *****************************************************************************************************************
; *** MAIN loop: print Menu. Read selection (W, V, R or G) and jump to right routine
mainloop	
	writetext	text_menu
	call	readRXwait		; read character
	load_f_f	TX_OUT, RXD		; echo input
	call	uart_write_TX_OUT	; write out
	call	write_lf	
	if_f_eq_l	RXD, 'W'		; "Write" selected
	 bcf	MISC_STATE,0
	 call	readhexfile
	 writetext	text_OK
	 goto	mainloop
	end_if
	if_f_eq_l	RXD, 'V'		; "Verify" selected
	 bsf	MISC_STATE,0
	 clrf	ERRCNT		; clear error conter
	 clrf	ERRCNT+1
	 call	readhexfile
	 load_f_f	HEXOUT, ERRCNT+1	; write counted errors
	 call	write_hex
	 load_f_f	HEXOUT, ERRCNT
	 call	write_hex
	 writetext	text_errors
	 goto	mainloop
	end_if
	if_f_eq_l	RXD, 'R'		; "Read" selected
	 call	readprogram
	 goto	mainloop
	end_if
	if_f_eq_l	RXD, 'G'		; "Go" selected
	 clrf	PORTB		; LED off
	 writetext	text_bye
	 goto	0x0200
	end_if
	goto	mainloop

; *****************************************************************************************************************
; *** READPROGRAM. Reads the flash memory and prints the values. 
;        If more than 4 empty (0x3FFF) values, do not print. Print the last FLASH location
readprogram
	load_f_l	HEXOUTCNT,.5
	load_f16_l16	HEXADR, 0x0200		; start at address 0x0200
rdp1:	call	readPFlash

	banksel	EEDATH		; check if data 0x3FFF
	movf	EEDATH,w
	banksel	.0
	sublw	0x3F
	skpz
	goto	rdp3
	banksel	EEDATL
	movf	EEDATL,w
	banksel	.0
	sublw	0xFF
	skpz
	goto	rdp3		; not empty, reset counter to 4
	decfsz	HEXOUTCNT,f		; already 4 times 0x3FFF?
	goto	rdp2
	incf	HEXOUTCNT,f		; increase for next round
	movlw	0xFF		; print last address 0x3FFF
	subwf	HEXADR,w
	skpz
	goto	rdp4
	movlw	0x3F
	subwf	HEXADR+1,w
	skpz
	goto	rdp4
	
rdp2:	load_f_f	HEXOUT, HEXADR+1 	; write out address - data
	call	write_hex
	load_f_f	HEXOUT, HEXADR
	call	write_hex
	call	write_space
	load_f_f	HEXOUT, EEDATH
	call	write_hex
	load_f_f	HEXOUT, EEDATL
	call	write_hex
	call	write_lf
	 
rdp4	movlw	.1		; increase HEXADR
	addwf	HEXADR,f
	movlw	.0
	addwfc	HEXADR+1,f
	
	movf	HEXADR+1,w		; at end (0x4000)?
	sublw	0x40
	skpz
	goto	rdp1
	return

rdp3	load_f_l	HEXOUTCNT,.5		; set back at 4 times 
	goto	rdp2

; *****************************************************************************************************************
; *** READHEXFILE. This routine programs or verifies the flash memory by reading the HEX file
readhexfile	;call	write_lf
	writetext	text_hexfile
	;bcf	MISC_STATE, 3		; flag for segment
	;bcf	MISC_STATE, 4		; flag for not flushed yet
	;bcf	MISC_STATE, 5		; flag to flush
	;bcf	MISC_STATE, 6		; flag for verify error
	movlw	b'10000111'
	andwf	MISC_STATE,f
rhf4:
rhf2:	call	readRXwait
	gotoif_f_ne_l	RXD, ':', rhf2		; wait for start character
	call	readhexbyteRXwait	; number of bytes
	load_f_f	RXDcnt, RXD
	clrc			; divide by 2: 16 bits values are written
	rrf	RXDcnt,f
	call	readhexbyteRXwait	; high byte of address
	load_f_f	HEXADR+1, RXD
	call	readhexbyteRXwait	; low byte of address
	load_f_f	HEXADR, RXD
	clrc			; divide by 2: 16 bits values are written
	rrf	HEXADR+1,f
	rrf	HEXADR,f
	call	readhexbyteRXwait	; record type: if 0x00 then data, if 0x01: end of file
	bcf	MISC_STATE, 1
	bcf	MISC_STATE, 2
	if_f_eq_l	RXD, 0x00		; record type is data
	  loadnb_f_f	HEXTADR+1, HEXADR+1	; save HEXADR for flush
	  loadnb_f_f	HEXTADR, HEXADR
	  call	checkFlushData		; check whether change in ..1F segment 
	  bsf	MISC_STATE,1
	  loadnb_f_f	HEXADR+1, HEXTADR+1	; restore HEXADR for flush
	  loadnb_f_f	HEXADR, HEXTADR
	end_if 
	if_f_eq_l	RXD, 0x04		; record type is segment
	  call	checkFlush
	  bsf	MISC_STATE,2
	end_if 
	if_f_eq_l	RXD, 0x01		; record type is end of file
	  call	checkFlush
	  call	readRXwait		; read last two hex coded and lf
	  call	readRXwait
	  goto	readRXwait
	  ;return
	end_if 
rhf1:
				; read the bytes
	call	readhexbyteRXwait	; low databyte
	load_f_f	RXDl, RXD
	call	readhexbyteRXwait	; high databyte
	gotoif_f_b_c	MISC_STATE,1,rhf3	; skip if recordtype is wrong
	gotoif_f_b_c	MISC_STATE,3,rhf3	; skip if segment is wrong
	if_f_b_c	MISC_STATE,0		; Write (not Verify)
	 call	writeRXDtoflash
	else_			; Verify (not Write)
	 call	readPFlash
	 load_w_f	EEDATH		; compare
	 subwf	RXD,w
	 skpz
	 goto	rhf5
	 load_w_f	EEDATL
	 subwf	RXDl,w
	 skpnz
	 goto	rhf3
rhf5: 	 movlw	.1		; error detected: add 1 to ERRCNT
	 addwf	ERRCNT,f
	 movlw	.0
	 addwfc	ERRCNT+1,f
	end_if

rhf3:	incf	HEXADR,f		; assume no 0xFF boundary
	decfsz	RXDcnt,f
	goto	rhf1
	if_f_b_s	MISC_STATE,2	; record type = 2
	  if_f_eq_l	RXD,0x00	; code segment
	    bsf	MISC_STATE,3
	  else_
	    bcf	MISC_STATE,3
	  end_if
	end_if 
	goto	rhf4

; *****************************************************************************************************************
; *** FLASH routines for reading, erasing, writing and flushing the FLASH memory
; readPFlash
;   This code block will read 1 word of program
;   memory at the memory address: HEXADR
;   data will be returned in the variables EEDATH, EEDATL
readPFlash
	banksel	EECON1
	call	load_eeadr	; load HEXADR into EEADR
readPFlash_ld	BCF	EECON1,CFGS 	; Do not select Configuration Space
	BSF	EECON1,EEPGD 	; Select Program Memory
	;BCF	INTCON,GIE 	; Disable interrupts
	BSF	EECON1,RD 	; Initiate read
	NOP		; Executed (Figure 11-1)
	NOP		; Ignored (Figure 11-1)
	;BSF	INTCON,GIE	; Restore interrupts
	banksel	.0
	return

;erasePFlash
erasePFlash
; This row erase routine
	;BCF	INTCON,GIE ; Disable ints so required sequences will execute properly
	BANKSEL	EECON1
	BSF	EECON1,FREE ; Specify an erase operation
PFlashHk
	call	load_eeadr	; load HEXADR into EEADR
	BSF	EECON1,EEPGD 	; Point to program memory
	BCF	EECON1,CFGS 	; Not configuration space
	BSF	EECON1,WREN 	; Enable writes
	MOVLW	55h 	; Start of required sequence to initiate erase
	MOVWF	EECON2 	; Write 55h
	MOVLW	0AAh 	;
	MOVWF	EECON2 	; Write AAh
	BSF	EECON1,WR 	; Set WR bit to begin erase
	NOP	 	; Any instructions here are ignored as processor
			; halts to begin erase sequence
	NOP	 	; Processor will stop here and wait for erase complete.
			; after erase processor continues with 3rd instruction
	BCF	EECON1,WREN 	; Disable writes
	BANKSEL	.0
	;BSF	INTCON,GIE 	; Enable interrupts
	return

; writePFlash
writePFlash
; This write routine assumes the following:
	BANKSEL	EECON1
	movf	RXDl,w	; Load first data byte into lower
	movwf	EEDATL
	movf	RXD,w	; Load second data byte into upper
	movwf	EEDATH
	BSF	EECON1,LWLO 	; Only Load Write Latches
	movf	HEXADR,w	; chech ik address is 1f
	andlw	0x1f
	xorlw	0x1f
	skpnz
	goto	wpf1
	btfsc	MISC_STATE, 5
	goto	wpf1
	bsf	MISC_STATE, 4	; Only loading latches -> set flag for flush
	loadnb_f_f	HEXFADR, HEXADR	; store address for flush
	loadnb_f_f	HEXFADR+1, HEXADR+1
	loadnb_f_f	RXFD+1, RXD+1
	loadnb_f_f	RXFD, RXD
	goto	PFlashHk
wpf1	BCF	EECON1,LWLO 	; No more loading latches - Actually start Flash program memory write
	bcf	MISC_STATE, 4
	bcf	MISC_STATE, 5
	goto	PFlashHk

; checkFlush / checkFlushData
;   checkes wheter the atches are filled and need to be flushed because the hex file is nog going through ..1F address
;   checkFlush assumes it is clear from the HEXfile (e.g eof or segment change) flush is needed
;   checkFlushData is used if address is changed in the same HEXfile segment (caused by a new ORG in the asm file)  
checkFlushData
	movf	HEXADR+1,w	; check whether HEXADR and HEXFADR are in the same ..1F segment
	subwf	HEXFADR+1,w
	skpz	
	goto	checkFlush	; upper byte already different -> flush maybe needed

	movf	HEXFADR,w
	subwf	HEXADR,w	; assuming HEXADR is only increasing
	andlw	0xE0	; check only upper three bits
	skpnz	
	return	; upper three bits of lower byte are equal -> no flush needed

checkFlush
	btfsc	MISC_STATE,0		; return if verify
	return 
	btfss	MISC_STATE,4		; flush flag set?
	return
	loadnb_f_f	HEXADR+1, HEXFADR+1		; retrieve flush address
	loadnb_f_f	HEXADR, HEXFADR
	loadnb_f_f	RXD+1, RXFD+1
	loadnb_f_f	RXD, RXFD
	bsf	MISC_STATE, 5		; indicate flush
	;goto	writeRXDtoflash
	;return

; writeRXDtoflash
;  write value RXD to address HEXADR:2
writeRXDtoflash
	if_f_lt_l	HEXADR+1,0x02	; check whether not overwriting bootloader
	  return
	end_if
	movf	HEXADR,w
	andlw	0x1F	; row 32 byte
	skpnz
	call	erasePFlash
	goto	writePFlash
	;return
	
; load_eeadr
;  assumes bank 3 selected
;  and loads HEXADR (70-7F) into EEADR
load_eeadr
	movf	HEXADR,w	; Load lower 8 bits of erase address boundary
	movwf	EEADRL
	movf	HEXADR+1,w	; Load upper 6 bits of erase address boundary
	movwf	EEADRH
	return

uart_write_TX_OUT
	movf	TX_OUT, w
uart_write_w	
	btfss	PIR1, TXIF
	goto	$-1
	banksel	TXREG
	movwf	TXREG
	banksel	.0
	return

; *****************************************************************************************************************
; *** READRX routines for reading from serial input
; readRXwait - wait for RX and put in RXD
	ifndef	FAKEINPUT
readRXwait
; Read UART
rrxw2	;
	banksel	RCSTA
	btfss	RCSTA, OERR	; Overrun?
	goto	rrxw1
	bcf	RCSTA, CREN	; clear overrun
	bsf	RCSTA, CREN
	
rrxw1	;if_f_b_s	PIR1, RCIF	; recieved?
	banksel	.0
	btfss	PIR1, RCIF	; recieved?
	goto 	rrxw2

	; character recieved
	 ; if_f_b_s	RCSTA,FERR	; Framing error
	banksel	RCSTA
	btfss	RCSTA,FERR	; Framing error
	goto	rrxw3
	loadnb_f_f	RXD, RCREG	; copy recieved byte
	;banksel	.0
	goto	rrxw2

rrxw3	loadnb_f_f	RXD, RCREG	; copy recieved byte
	if_f_ge_l	RXD,.97	; lower case -> upper case
	  if_f_lt_l	RXD,.123
	    movlw	.224
	    addwf	RXD,f
	  end_if
	end_if
	banksel	.0

	;if_f_eq_l	RXD,'Q'	; to Menu if Q
	movf	RXD,w	; to Menu if Q
	sublw	'Q'
	skpz
	return
	load_f_l	STKPTR,0x00	; clear stack
	goto	mainloop
	;end_if
	;bcf	PORTB,1	; Orange LED off
	;return
	endif	

; readRXwait - wait for RX and put in RXD - DEBUG MODE
	ifdef	FAKEINPUT
readRXwait
	call	get_fake_char
	movwf	RXD
	movlw	.1
	addwf	fakereadadr,f
	movlw	.0
	addwfc	fakereadadr+1,f
	return
get_fake_char	load_f_f	PCLATH, fakereadadr+1
	load_f_f	PCL, fakereadadr
	endif

; read two hex characters and convert to byte
readhexbyteRXwait
	call	readRXwait	; first caracter
	call	hextobin
	swapf	RXD,W
	movwf	RXDtmp
	call	readRXwait	; second character
	call	hextobin
	movf	RXDtmp,W
	iorwf	RXD,f
	return

; *****************************************************************************************************************
; *** WRITE TEXT routines for writing to serial output

; write_text
;   outputs text, starting from TEXT_POS, until zero-character is detected
write_text:	;return ; *****************************************************************
	;repeat
	;until_f_b_s	BUFST, 7
	banksel	EECON1
	loadnb_f_f	EEADRH, TEXT_POS+1
	loadnb_f_f	EEADRL, TEXT_POS
	call	readPFlash_ld
	load_f_f	TX_OUT, EEDATH	; first character
	banksel	EECON1
	bcf	TX_OUT,6
	btfsc	EEDATL,7
	bsf	TX_OUT,6
	banksel	.0
	movf	TX_OUT, w
	skpnz
	return
	call	uart_write_TX_OUT	; write out
	load_f_f	TX_OUT, EEDATL	; second character
	bcf	TX_OUT,7
	banksel	.0
	movf	TX_OUT, w
	skpnz
	return
	call	uart_write_TX_OUT	; write out
	incf	TEXT_POS, f	; increment TEXT_POS
	btfsc	STATUS,Z
	incf	TEXT_POS+1, f	
	goto	write_text	
	

; hextobin
;  convert single HEX character in RXD to binary value in RXD
hextobin:	if_f_b_s	RXD, 6	; 0x3? or 0x4?
	  movlw	.9	; A..F: + 9
	  addwf	RXD,f
	end_if
	movlw	0x0F
	andwf	RXD,f
	return


; write_hex		
;   writes HEXOUT as two chracter HEX value to TX_OUT
write_hex:	
wh1:	movf	HEXOUT, w
	swapf	WREG, f
	call	write_hex_n	; write first char
	movf	HEXOUT, w
	call	write_hex_n	; write second char
	return
write_hex_n:
	;movlw	0x0F
	andlw	0x0F
	movwf	TX_OUT
	if_f_ge_l	TX_OUT, .10
	 movlw	0x37
	 addwf	TX_OUT, f
	else_
	 movlw	0x30
	 iorwf	TX_OUT, f
	end_if
	call	uart_write_TX_OUT	; write out
	return

write_lf:
	;write_char	.13
	uart_write_l	.10
	return

write_space:
	uart_write_l 	.32
	return

; *****************************************************************************************************************
; *** TEXT definitions

;text_menu:	dt	.10,"Menu",.10," [W]rite",.10," [V]erify",.10," [R]ead",.10," [G]o",.10,0
;text_hexfile:	dt	"Send HEXfile ([Q] to quit)",.10,0
;text_error:	dt	" Verify errors",.10,0
;text_OK:	dt	"OK",.10,0
;text_bye:	dt	"Bye!",.10,0

text_menu	OctC2W	.10, "M", "e", "n", "u", .10, "[", "W"
	OctC2W	"]", "r", "i", "t", "e", .10, "[", "V"
	OctC2W	"]", "e", "r", "i", "f", "y", .10, "["
	OctC2W	"R", "]", "e", "a", "d", .10, "[", "G"
	QuadC2W	"]", "o", .10, 0x0
text_hexfile	OctC2W	"S", "e", "n", "d", " ", "H", "E", "X"
	OctC2W	"f", "i", "l", "e", " ", "[", "Q", "]"
	OctC2W	" ", "t", "o", " ", "q", "u", "i", "t"
	DoubleC2W	.10, 0x0
text_errors	OctC2W	" ", "v", "e", "r", "i", "f", "y", " "
	OctC2W	"e", "r", "r", "o", "r", "s", .10, 0x0
text_OK	QuadC2W	"O", "K", .10, 0x0
text_bye	QuadC2W	"B", "y", "e", "!"
	DoubleC2W	.10, 0x0


; *****************************************************************************************************************
; *** Input data for debuging (define FAKEINPUT)
	ifdef	FAKEINPUT
	org 0x0300
fakedata	dt	"W"
	dt	":020000040000FA"
	dt	":10040000052A00000000000009008B13F8302100CD"
	dt	":1004100099002000003023008D00200000308D0066"
	dt	":10042000FC3021008D002000043024008D002000CD"
	dt	":10043000BF3021008E002000003023009C002000EF"
	dt	":10044000193023009B00200023001E1120002300F0"
	dt	":100450009F11200023009E16200023001D1620005F"
	dt	":1004600023001E12200023009D1720000D108D1464"
	dt	":100470006A220D148D106A220D108D146A220D103F"
	dt	":100480008D106A227410911E4B2A741423001908CF"
	dt	":100490002000F200622A23001D19502A2000562A4B"
	dt	":1004A0002000230019082000F200622A23009D1872"
	dt	":1004B0005B2A2000622A200023001D122000230056"
	dt	":1004C0001D162000741C692A42307202031D692A1D"
	dt	":1004D0000100362A0030A0000030A1000030A20048"
	dt	":1004E0000030A30000302302031C782A031DC92A10"
	dt	":1004F00000302302031C962A00302202031C822AA9"
	dt	":10050000031DC92A00302202031C962ACE30210284"
	dt	":10051000031C8C2A031DC92ACE302102031C962AF3"
	dt	":100520009D302002031C962A031DC92AC72A0030C9"
	dt	":100530002302031C9D2A031DC92A00302302031C29"
	dt	":10054000B92A00302202031CA72A031DC92A003041"
	dt	":100550002202031CB92ACE302102031CB12A031D3A"
	dt	":10056000C92ACE302102031CB92A9D30200203186B"
	dt	":10057000C92A0130A007031CBF2A0130A107031CB0"
	dt	":10058000C32A0130A207031CC72A0130A3070000B9"
	dt	":04059000972A08009E"
	dt	":0240200000009E"
	dt	":027F040000007B"
	dt	":020000040001F9"
	dt	":02000E00A42F1D"
	dt	":02001000FF39B6"
	dt	":00000001FF"
	dt	.10, .10, .10, "G"
	endif


	END
