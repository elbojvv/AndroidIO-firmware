;
; AndroidIO
;   Written by E.J. van Veldhuizen, 2014, 2015, 2016
;   
;   Firmware for AndroidIO board, published in Elektor
;
; For modifying:
; - ppmacros are used with:
;   - bank_option=2: use banklabel at every label
;   - page_option=2: use the ppmacros or set page at every variable
; - you can put your own configuration in set_default_pins (see examples in that routine)
;

	#define 	FW_Version	.11

; Undefine (put ; in front of all defines) for production firmware
	;#define	include_bootloader	; include the bootloader in the HEX file
	#define	include_datalogger	; datalogger functionality
	#define	include_extendedPWM	; Extended PWM functionality
	#define	include_CPSchange	; CPS functionality
;	#define	include_3STOPBITS	; Make 3 stopbits in UART for reliable Tx with FT31xD 
;	#define	ADC_workaround		; Include the workaround for revision A and B
;	#define	debug_org200		; For debgugging: jump to 0x200
;	#define	debug_mplabsim		; Use this for special cases
;	#define	PIN40			; 40 pin code
;	#define	debugsavemem		; make empty strings to give some space for debug

	
	NOLIST
	include "p16f1938.inc"
	NOLIST

bank_option=2
page_option=2


	include "ppmacros_v14.inc"
	LIST
	#ifdef include_bootloader
	 include "bootloader.inc"
	#endif

app_number=.1
	#ifdef PIN40
app_number=app_number+.6
	#else
	 #ifdef PIN18
app_number=app_number+.2
	 #else
	  #ifdef PIN8
app_number=app_number+.0
	  #else
app_number=app_number+.4
	  #endif
	 #endif
	#endif
	#ifdef include_datalogger
app_number=app_number+.8
	#endif
	#ifdef include_extendedPWM
app_number=app_number+.16
	#endif
	#ifdef include_CPSchange
app_number=app_number+.32
	#endif
	#ifdef ADC_workaround
app_number=app_number+.64
	#endif
	#ifdef include_3STOPBITS
app_number=app_number+.128
	#endif
	#define 	FW_App	app_number


; SET TABSIZE to 16 (edit/properties/ASM file types)

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

; TIMER 0 - CPS counter
; TIMER 1 - counter for external pulses
; Timer 2 - 8 kHz interrupt

; Pinstatus 0: input (high impediance)
;   PP0=0
;   PP1:
;     bit0: 1: send reply ("1") on low-high change
;     bit1: 1: send reply ("0") on high-low change
;     bit4: 1: Latch mode
;     bit7: 1: include this channel in Datalogger 
; 
; Pinstatus 1: input (weak pull up)
;   PP0=1
;   PP1:
;     bit0: 1: send reply ("1") on low-high change
;     bit1: 1: send reply ("0") on high-low change
;     bit4: 1: Latch mode
;     bit7: 1: include this channel in Datalogger 
; 
; Pinstatus 2: output (arg4 sets value; otherwise 0)
;   PP0=2
;   PP1:
;     bit2: 1: Watchdog 2 seconds (switch off to high impediance after 2 seconds no communication)
;     bit3: 1: Watchdog 60 seconds (switch off to high impediance after 60 seconds no communication)
;     bit4: 1: Latch mode
; 
; Pinstatus 3: ADC
;   PP0=3
;   PP1:
;     bit0: 0: Vref=Vdd, 1:Vref=2.048V
;     bit1: 0: avarage of PP2 measurements, 1: sum of PP2 measurements
;     bit6: 1: send every 100 ms
;     bit7: 1: include this channel in Datalogger 
;   PP2: Number of ADC measurements in one go
; 
; Pinstatus 4: CPS
;   PP0=4
;   PP1:
;     bit0: 1: send reply ("1") on off-on change (with threshold in PP2)
;     bit1: 1: send reply ("0") on on-off change (with threshold in PP2)
;     bit<2:3>: power into CPS: 00: high, 01: medium, 10: low, 11: off (noise detect) 
;     bit7: 1: include this channel in Datalogger 
;   PP2: threshold
;   PP3: actual read timer value (use this to set PP2)
; 
; Pinstatus 5: PWM (arg4 sets value; otherwise 0)
;   PP0=5
;   PP1:
;     bit0: 0: PWM high = pin high, 1: PWM high = pin low
;     bit1: 0: PWM low = inverse bit 4, 1: PWM low = high impediance
;     bit2: 1: Watchdog 2 seconds (switch off to high impediance after 2 seconds no communication)
;     bit3: 1: Watchdog 60 seconds (switch off to high impediance after 60 seconds no communication)
;     bit<4:5>: 00: synchronous sawtooth (max = 100), 01: sawtooth (max in PP2), 10: sigma-delta (max=16384), 11: random mode (max=255) 
;     bit6: 0: on interrupt, 1 on 10 ms.
;   PP2: maximum PWM value (see bit <0:1>=01 in PP1)
; 
; Pinstatus 6: Special
; 
;  PIN C0: Timer
;   PP0=6
;   PP1:
;     bit0: 0: count, 1: count per time unit ("frequency"), see bit<0:2>
;     bit<1:3>: frequency measurement period: 
;                  000: 1 ms, 001: 10 ms,    010: 100 ms, 011: 1s,
;                  100: 10s,  101: 1 minute, 110: 10 min, 111: 1 hour 
;     bit<4:5>: prescaler: 00: 1:1, 01: 1:2, 10: 1:4, 11: 1:8
;     bit6: if bit0=0: 0: stop for reading and start afterwards, 1: read high1-low-high2 without stopping counting; if high1=high2: high:low, otherwise high2:00
;           if bit0=1: 0: restart measurement after one measurement, 1: stop after one measurement (restart by writing to C01)
;     bit7: do send measurement every period / include in datalogger
;
;  PIN C3 and C4: I2C (setting one of the pins on special, sets both; setting one of the pins to another function, disables the other) 
;   See datalogger S
; 
;
; SPECIAL SETTING REGISTER 
; 
; Register S-Z, only set and get, no read and write
; 
;  Z - Global settings 
;  Z0:
;    bit0: 0: enable change in pin function/settings, 1: prohibit change in pin function/settings
;    bit1: 0: echo input and debug info and enable Q to return to bootloader, 1: no debug info
;    bit2: 0: on boot: set all pins on 0 (high impediance input), 1: load functions from eeprom (do save to eeprom to hve effect! see Z2)
;    bit<3:4>: interrupt frequency  00: 16 kHz, 01: 8 kHz, 10: 4 kHz, 11: 32kHz
;    bit5: 0: Z2 range -0.4% .. 0.4% (.1%/32/stp), 1: Z2 range -3% .. 3% (.1%/stp)
;    bit6: PWM only: PWM on sigma-delta and high/low, disable CPS, clock, Z2 in order to get 32 kHz PWM
;    bit7: internal use
;
;  Z2: Oscillator tune (signed)
;    32 - 63 slower (32 slowest)
;    0 -     default
;    1 - 31  faster (31 fastest)
;
;  Z3:
;    .01 (S ) Set settings on default values
;    .02 (S ) Save settings to EEPROM 
;    .03 (S ) Load settings from EEPROM
;    .04 ( G) Read EEPROM
;    .05 (S ) Erase EEPROM
;    .10 ( G) Read PIC version number (HEX format)
;    .11 ( G) Read PIC version number (Text)
;    .12 ( G) Read interrupt overflow (decimal)
;    .13 ( G) Read interrupt overflow (Text)
;    .20 (S ) Reset controller (through bootloader)
;    .21 (S ) Jump to bootloader (even without jumper)
;    .30 (SG) Password (not implemented in version 1.0)
;  
;  Y - Serial number 
;  Y0,1 - App number (can be overwritten and saved)
;    bit0: Basic IO/function
;    bit<1:2>: 00: 8 pin, 01: 18 pin, 10, 28 pin, 11: 40 pin
;    bit3: Datalogger
;    bit4: Extendend PWM
;    bit5: CPS
;    bit6: ADC workaround
;    bit7: 3 stop bits (FT31xD)
;  Y2 - Version (Hexadecimal 0x<Version><Subversion> (can be overwritten and saved)
;  Y3: store a byte for custom serial number (save to eeprom to maintain after reboot) 
; 
;  X - Clock
;  X0:
;    bit0: 1: output clock every second
;  X1, X2, X3: second, minute, hour
;
;  S - data logger
;  Read command (R)
;   C3 blocknumber
;     blocknumber 0..511
;     give 64 byte (hexadecimal) of block
;
;   C4: "dlog_status" "position blocks" "current position in unwritten block" "current bit" "#measuremnets to next write to block" "ms to next measurement"
;       with dlog_ststus: bit0: logging running, bit1: error (bpm>504), bit 2: missed measurement, bit3: restarted, bit4 :looped, bit7: flag for measurement 
;
;  Settings command (S and G)  
;  S0: 
;    bit0: 0: datalogger is stopped, 1: is started (use S3 to start or stop)
;    bit1: 0: stops at end of memory, 1: loops the memory (cannot set when bit0=1) 
;    bit2: 0: do not start at boot (eg power outage), 1: continue after boot
;    bit<3:4>: number of measuremenst for statistics
;              00: 1 measurements (>= ~ 1 ms), 01: 64 measurements (>= ~ 100 ms), 10: 2048 measurements (>= ~ 1 minute), 11 4194304 measurements (>=1 ~ hour)
;    bit<5:7>: frequency measurement period: 000: 10 ms, 001: 100 ms, 010: 1 s, 011 : 15 s, 100: 1 minute, 101: 15 minute, 110: 1 hour, , 111: 1 day
;
;  S1: statistics
;    bit<0:1> 01: Store Sigma measurements, 10: Store avarage of measurements, 11 store Sigma for 1 bit input, avarage for rest 
;    bit2: 1: Store maximum value
;    bit3: 1: Store minimum value
;    bit4: 1: Store standard deviation
;    bit7: 1: blink LED on B0 while reading
;
;  S3: commands
;    00: stop
;    01: start
;    02: continue (within buffer, if possible, otherwise 03)
;    03: continue with empty buffer
;
;    Structure on flash memory
;      Header 4 bytes
;        byte 0:
;         bit<0:3>: ID of run (increments 1 after restart or power outage)
;         bit4: 
;         bit<5:7>: bit <5:7> of S0
;        byte 1: S1
;        byte 2: S2
;        byte 3: S3
;
;      After header structure with values, inorder of ports in S1, and ADCs in S2 and S3
;        shifted to pack
;        if structure does not fit into 64 byte block, structure is written in new block
;        structures are not shifted into each other (eg, if 4 bits are left in structure, they are not used by new structure)
;       



; Configuration words:    2FA4, 39FE
	__config	_CONFIG1, (_FOSC_INTOSC & _WDTE_OFF  & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_ON) & 0x3FFF
	__config	_CONFIG2, (_WRT_BOOT & _PLLEN_ON & _STVREN_OFF & _BORV_HI & _LVP_ON) & 0x3FFF

PR2_4k	EQU	.123
PR2_8k	EQU	.61
PR2_16k	EQU	.29
PR2_32k	EQU	.14


; ***********************************************************************
; VARIABLES, CONSTANTS AND MACRP DECLARATIONS
; ***********************************************************************
; Address in linear mode:
;  Linear   Normal
;  0x000 -> 0x020
;  0x010 -> 0x030
;  0x020 -> 0x040
;  0x030 -> 0x050
;  0x040 -> 0x060
;  0x050 -> 0x0A0
;  0x060 -> 0x0B0
;  0x070 -> 0x0C0
;  0x080 -> 0x0D0
;  0x090 -> 0x0E0
;  0x0A0 -> 0x120
;  0x0B0 -> 0x130
;  0x0C0 -> 0x140
;  0x0D0 -> 0x150
;  0x0E0 -> 0x160
;  0x0F0 -> 0x1A0
;  0x100 -> 0x1B0
;  0x110 -> 0x1C0
;  0x120 -> 0x1D0
;  0x130 -> 0x1E0
;  0x140 -> 0x220
;  0x150 -> 0x230
;  0x160 -> 0x240
;  0x170 -> 0x250
;  0x180 -> 0x260
;  0x190 -> 0x2A0
;  0x1A0 -> 0x2B0
;  0x1B0 -> 0x2C0
;  0x1C0 -> 0x2D0
;  0x1D0 -> 0x2E0
;  0x1E0 -> 0x320
;  0x1F0 -> 0x330
;  0x200 -> 0x340
;  0x210 -> 0x350
;  0x220 -> 0x360
;  0x230 -> 0x3A0
;  0x240 -> 0x3B0
;  0x250 -> 0x3C0
;  0x260 -> 0x3D0
;  0x270 -> 0x3E0
;  0x280 -> 0x420
;  0x290 -> 0x430
;  0x2A0 -> 0x440
;  0x2B0 -> 0x450
;  0x2C0 -> 0x460
;  0x2D0 -> 0x4A0
;  0x2E0 -> 0x4B0
;  0x2F0 -> 0x4C0
;  0x300 -> 0x4D0
;  0x310 -> 0x4E0
;  0x320 -> 0x520
;  0x330 -> 0x530
;  0x340 -> 0x540
;  0x350 -> 0x550
;  0x360 -> 0x560
;  0x370 -> 0x5A0
;  0x380 -> 0x5B0
;  0x390 -> 0x5C0
;  0x3A0 -> 0x5D0
;  0x3B0 -> 0x5E0
;  0x3C0 -> 0x620
;  0x3D0 -> 0x630
;  0x3E0 -> 0x640
;  0x3F0 does not exist
;
;  Linear mode:
;    0x000 - 0x0FF   Normal variables
;    0x100 - 0x1FF   Variables for Statistical operations datalogger
;    0x200 - 0x24F   Values for pins
;    0x250 - 0x29F   Work variables for pins
;    0x2C0 - 0x2FF   64 byte buffer for FLASH write
;    0x300 - 0x3BF   Settings for pins (mirrored in EEPROM) 
;    0x3C0 - 0x3DF   Math sub variables
;    0x3E0 - 0x3EF   Not used
;    0x3F0 - 0x3FF   Does not exist
;
;
;
	cblock 0x20	; bank 0      

	; variables for command parser
	cmdstat	; bit0: 0: text output, 1: result in txt_int, bit1: 1: binary output
	cmdbfl,cmdbfad, cmdtmp:2, cmdppos, nofargs
	cmdbf0, cmdbf1, cmdbf2, cmdbf3
	cmdbf4, cmdbf5, cmdbf6, cmdbf7:9 
	wrtargt1:2, wrtargt2, txt_int:4

	; variables for bit manipulation
	BTP 	; pin number (0..23 for A0 .. C7)
	BTF:2	; 16 bit address to set bit 
	BTB 	; bit number (0..7)
	BTC 	; pin status (0,1: input, 2: output, 3: ADC, 4: CPS, 5: PWM, 6: special) 
	BTA 	; allowed pin function (bit 0: status 0, etc)
	BTS 	; general status/reply byte. Bit 0: response of bit read. Bit 7: 4th argument
	BTAC	; ADC channel 
	BTCC	; CPS channel 
	ADCmult	; number of ADC readings
	ADCref	; Reference voltage: 0: Vdd, 1: 2.048V (copy of PP1)

	; Buffer 2 
	BUFFER2:.15, BUFFEREND2

	tunedelta
	PWMstat

	FLASH_Address:2, FLASH_Value, FLASH_Debug, FLASH_Count, sspif_cnt:2, i2c_wait

	; variables for math
	_PPMCR1_, _PPMCR2_, _PPMCR3_, _PPMCR4_
	_PPMCR5_, _PPMCR6_, _PPMCR7_, _PPMCR8_
	_PPMCR9_, _PPMCR10_, _PPMCR11_, _PPMCR12_
	_PPMCR13_

	bank0tst
	endc
	#if (bank0tst > 0x70) 
	 error "Variables out of bank 0"
	#endif

	cblock 0xA0	; bank 1
	; Buffer 1 
	BUFFER1:.79, BUFFEREND1
	bank1tst
	endc
	#if (bank1tst > 0x0F0) 
	 error "Variables out of bank 1"
	#endif

	cblock 0x120	; bank 2
	delaycnt:4
	; for clock
	CNT_stat		; bit0: ms flag, bit1: 2 sec WDT, bit2: 60 sec WDT, bit3: ADC 100ms flag, bit4: 10ms PWM flag, bit7: clock sec flag
	CNT_subms, CNT_submsmax, CNT_ms:2
	
	dbg1, dbg2:2
	tmp1,tmp2, tmp3:4
	UART_RD, UART_ST
	intcount	; timer increased on every nterrupt (for PWM)
	rcv_timer	; timer for time out on recieving characters
	CPS_channel
	DATA_EE_ADDR, DATA_EE_DATA

	TEXT_POS:2, TEXT_CHAR	; variables for text output

	; Buffer variables. BUFST: If bit set: then buffer empty    
	BUFST
	BUFRD1, BUFWRT1, BUFPOSR1, BUFPOSW1, BUFPOSWTMP1
	BUFRD2, BUFWRT2, BUFPOSR2, BUFPOSW2, BUFPOSWTMP2
	cmda1, cmda2:2, cmda3:2, cmda4:2, cmda3store
	; variables for datalogger    
	dlog_stat		; bit0: logging running, bit1: error (bpm>504), bit 2: missed measurement, bit3: restarted, bit4 :looped, bit7: flag for measurement 
	dlog_mcountdown:4	; countdown number of measurements
	dlog_mcountdownmax:4	; number of measurements
	dlog_mscountdown:4	; mseconds countdown to next measurements
	dlog_mscountmax:4	; mseconds between measurements
	dlog_pos		; position inside block (0..63)
	dlog_posbit		; bit position (for packing)
	dlog_posblock:2		; blocknumber (0..511) 
	dlog_bpm:2		; bytes needed per measurement
	dlog_lipos		; linear address op dlog_pos
	dlog_chcnt		; channel counter for loop
	dlog_exbits		; extra bits for loop (pin counter)
	dlog_tmp1, dlog_tmp2:2

	wdt_2:2, wdt_60:2

	bank2tst
	endc
	#if (bank2tst > 0x170) 
	 error "Variables out of bank 2"
	#endif

	cblock 0x1A0	; bank 3
	; Variables for PWM subroutine
	PWMres, PWMstat0, PWMstat1, PWMstat2, PWMvalue:2, PWMwork:2, PWMfunc2
	ADCcountdown, CPScountdown, PWMcountdown, txt_bits 

	stop3bitcnt,stop3bitmax	; counter to generate 2 stop bits fot FT31xd	
	bank3tst
	endc
	#if (bank3tst > 0x1B0) 	; At 1B0 the statistics starts
	 error "Variables out of bank3"
	#endif

	cblock 0x1B0	; (bank 3) bank 1, address 0x00, in linear mode
	; Values for PWM / CPS    
	Pin_ch0, Bits_ch0, Sigma_ch0:4, Sigma2_ch0:4, Max_ch0:2, Min_ch0:2, Cnt_ch0:2		; 0x1B0
	Pin_ch1, Bits_ch1, Sigma_ch1:4, Sigma2_ch1:4, Max_ch1:2, Min_ch1:2, Cnt_ch1:2		; 0x1C0
	Pin_ch2, Bits_ch2, Sigma_ch2:4, Sigma2_ch2:4, Max_ch2:2, Min_ch2:2, Cnt_ch2:2		; 0x1D0
	Pin_ch3, Bits_ch3, Sigma_ch3:4, Sigma2_ch3:4, Max_ch3:2, Min_ch3:2, Cnt_ch3:2		; 0x1E0
	endc
	cblock 0x220
	Pin_ch4, Bits_ch4, Sigma_ch4:4, Sigma2_ch4:4, Max_ch4:2, Min_ch4:2, Cnt_ch4:2		; 0x220
	Pin_ch5, Bits_ch5, Sigma_ch5:4, Sigma2_ch5:4, Max_ch5:2, Min_ch5:2, Cnt_ch5:2		; 0x230
	Pin_ch6, Bits_ch6, Sigma_ch6:4, Sigma2_ch6:4, Max_ch6:2, Min_ch6:2, Cnt_ch6:2		; 0x240
	Pin_ch7, Bits_ch7, Sigma_ch7:4, Sigma2_ch7:4, Max_ch7:2, Min_ch7:2, Cnt_ch7:2		; 0x250
	Pin_ch8, Bits_ch8, Sigma_ch8:4, Sigma2_ch8:4, Max_ch8:2, Min_ch8:2, Cnt_ch8:2		; 0x260
	endc
	cblock 0x2A0
	Pin_ch9, Bits_ch9, Sigma_ch9:4, Sigma2_ch9:4, Max_ch9:2, Min_ch9:2, Cnt_ch9:2		; 0x2A0
	Pin_ch10, Bits_ch10, Sigma_ch10:4, Sigma2_ch10:4, Max_ch10:2, Min_ch10:2, Cnt_ch10:2	; 0x2B0
	Pin_ch11, Bits_ch11, Sigma_ch11:4, Sigma2_ch11:4, Max_ch11:2, Min_ch11:2, Cnt_ch11:2	; 0x2C0
	Pin_ch12, Bits_ch12, Sigma_ch12:4, Sigma2_ch12:4, Max_ch12:2, Min_ch12:2, Cnt_ch12:2	; 0x2D0
	Pin_ch13, Bits_ch13, Sigma_ch13:4, Sigma2_ch13:4, Max_ch13:2, Min_ch13:2, Cnt_ch13:2	; 0x2E0
	endc
	cblock 0x320
	Pin_ch14, Bits_ch14, Sigma_ch14:4, Sigma2_ch14:4, Max_ch14:2, Min_ch14:2, Cnt_ch14:2	; 0x320
	Pin_ch15, Bits_ch15, Sigma_ch15:4, Sigma2_ch15:4, Max_ch15:2, Min_ch15:2, Cnt_ch15:2	; 0x330
	endc

	cblock 0x340	; (bank 6) bank 2, address 0x00, in linear mode
	; Values for PWM / CPS    
	Val_A0:2, Val_A1:2, Val_A2:2, Val_A3:2	; 0x340
	Val_A4:2, Val_A5:2, Val_A6:2, Val_A7:2
	Val_B0:2, Val_B1:2, Val_B2:2, Val_B3:2	; 0x350
	Val_B4:2, Val_B5:2, Val_B6:2, Val_B7:2
	Val_C0:2, Val_C1:2, Val_C2:2, Val_C3:2	; 0x360
	Val_C4:2, Val_C5:2, Val_C6:2, Val_C7:2
	endc
	cblock 0x3C0	; (bank 7) bank 2, address 0x50, in linear mode
	; Work variables for PWM / CPS    
	Work_A0:2, Work_A1:2, Work_A2:2, Work_A3:2	; 0x3C0
	Work_A4:2, Work_A5:2, Work_A6:2, Work_A7:2
	Work_B0:2, Work_B1:2, Work_B2:2, Work_B3:2	; 0x3D0
	Work_B4:2, Work_B5:2, Work_B6:2, Work_B7:2
	Work_C0:2, Work_C1:2, Work_C2:2, Work_C3:2	; 0x3E0
	Work_C4:2, Work_C5:2, Work_C6:2, Work_C7:2
	endc

	cblock 0x460	; (bank 4) bank 2, address 0xC0, in linear mode
	; Buffer for writing to FLASH: 64 byte at 0x2C0 (linear mode)
	; do not use, just for overview  (you can use the first 16 byte)  
	FlashBuffer:64
	endc

	cblock 0x4D0	; (bank 9) bank 3, address 0x00, in linear mode
	; Status variables of pin    
	Stat_A0:4			; 0x4D0 
	Stat_A1:4 
	Stat_A2:4 
	Stat_A3:4
	Stat_A4:4			; 0x4E0 
	Stat_A5:4 
	Stat_A6:4 
	Stat_A7:4
	endc
	cblock 0x520
	Stat_B0:4, Stat_B1:4, Stat_B2:4, Stat_B3:4	; 0x520
	Stat_B4:4, Stat_B5:4, Stat_B6:4, Stat_B7:4	; 0x530
	Stat_C0:4, Stat_C1:4, Stat_C2:4, Stat_C3:4	; 0x540
	Stat_C4:4, Stat_C5:4, Stat_C6:4, Stat_C7:4	; 0x550
	Stat_D0:4, Stat_D1:4, Stat_D2:4, Stat_D3:4	; 0x560
	endc
	cblock 0x5A0
	Stat_D4:4, Stat_D5:4, Stat_D6:4, Stat_D7:4	; 0x5A0
	Stat_E0:4, Stat_E1:4, Stat_E2:4, Stat_E3:4	; 0x5B0
	Stat_E4:4, Stat_E5:4, Stat_E6:4, Stat_E7:4	; 0x5C0
	Stat_S0,   Stat_S1,   Stat_S2,   Stat_S3	; 0x5D0
	Stat_T0,   Stat_T1,   Stat_T2,   Stat_T3	; 0x5D4
	Stat_U0,   Stat_U1,   Stat_U2,   Stat_U3	; 0x5D8
	Stat_V0,   Stat_V1,   Stat_V2,   Stat_V3	; 0x5DC
	Stat_W0,   Stat_W1,   Stat_W2,   Stat_W3	; 0x5E0
	Stat_X0,   Stat_X1,   Stat_X2,   Stat_X3	; 0x5E4
	Stat_Y0,   Stat_Y1,   Stat_Y2,   Stat_Y3	; 0x5E8
	Stat_Z0,   Stat_Z1,   Stat_Z2,   Stat_Z3	; 0x5EC
	endc

	cblock 0x620	; variables for math subs
	mvar1:4, mvar2:4, mvar3:4, mvar4:4
	mvar5:4, mvar6:4
	; Timer 1
	T1countdown:4, T1countdownmax:4
	endc

; *** MACROS ***

mcr_cnt = 0


delxms_old	macro	delay
	load_f16_l16	delaycnt, delay ; *.1429/.10+.257
	decf	delaycnt,f
	btfsc	STATUS,Z
	decf	delaycnt+1,f
	btfsc	STATUS,Z
	return
	goto	$-5	 
	endm

delxms	macro	delay
	for_f32_l32_l32 delaycnt,.0,delay
	nop
	next_f32	delaycnt
	endm

uart_init	macro	baudrate
	bankblockstart
	; set RC7 (RX), RC6 (TX) to I/O
	load_f_b_l	TRISC, 7, 1 ; Set C7 as input
	load_f_b_l	TRISC, 6, 0 ; Set C6 as output
	; Implement baudrate selection here (now: 9600 baud @ 16 MHz)
	load_f_l	SPBRGH, 0
	load_f_l	SPBRGL,  .51	; (.25 for 16 MHz)
	load_f_b_l	TXSTA, BRGH, 0
	load_f_b_l	BAUDCON, BRG16, 0
	; enable TX and RX
	; • TXEN = 1 • SYNC = 0 • SPEN = 1
	; • CREN = 1 • SYNC = 0 • SPEN = 1
	load_f_b_l	TXSTA, TXEN, 1
	load_f_b_l	RCSTA, CREN, 1
	load_f_b_l	TXSTA, SYNC, 0
	load_f_b_l	RCSTA, SPEN, 1
	bankblockend
	endm


uart_read	macro	dest_f, stat_f
	load_f_b_l	stat_f, 0, 0	; set bit on 0: nothing recieved
	if_f_b_s	PIR1, RCIF	; recieved?
	  load_f_b_l	stat_f, 0, 1	; set bit on 1: recieved
	  load_f_f	dest_f, RCREG	; copy recieved byte
	else_
  	  if_f_b_s	RCSTA, FERR	; Framing error?
	    load_f_f	dest_f, RCREG	; clears error
	  else_
  	    if_f_b_s	RCSTA, OERR	; Overrun error?
	     load_f_b_l	RCSTA, CREN, 0	; clear error
	    end_if
	  end_if
	end_if
	endm

uart_write_f	macro	value_f
	btfss	PIR1, TXIF
	goto	$-1
	load_f_f	TXREG, value_f
	endm

uart_write_l	macro	value_l
	btfss	PIR1, TXIF
	goto	$-1
	load_f_l	TXREG, value_l
	endm

; bufinit
;   initialize buffer, by setting read and writeposition to beginning of buffer
bufinit	macro	bufnr
	load_f_l	BUFPOSR#v(bufnr), BUFFER#v(bufnr)
	load_f_l	BUFPOSW#v(bufnr), BUFFER#v(bufnr)
	return
	endm

; bufread
;   reads from buffer:
;     if value in buffer then value in BUFRD and BUFST equals 0
;     if no value in buffer then BUFST equals 1 (bit buffernr)
bufread	macro	bufnr
	if_f_eq_f	BUFPOSR#v(bufnr), BUFPOSW#v(bufnr)	; if read and wite position are equal, then empty
	 bsfb	BUFST, #v(bufnr) 	; buffer empty
	else_
	 load_f_i	BUFRD#v(bufnr), BUFPOSR#v(bufnr)
	 bcfb	BUFST, #v(bufnr) 	; buffer read succesfully
	 incfb	BUFPOSR#v(bufnr),f
	 if_f_gt_l	BUFPOSR#v(bufnr), BUFFEREND#v(bufnr)	; if read pointer beyond end of buffer
	   load_f_l	BUFPOSR#v(bufnr), BUFFER#v(bufnr)	; set read pointer to begin of buffer
	 end_if
	end_if
	return
	endm

; bufreadwait
;   reads from buffer:
;     if value in buffer then value in BUFRD and BUFST equals 0
;     if no value in buffer then BUFST equals 1
bufreadwait	macro	bufnr
	repeat
	until_f_ne_f	BUFPOSR#v(bufnr), BUFPOSW#v(bufnr)	; if read and wite position are equal, then empty
	load_f_i	BUFRD#v(bufnr), BUFPOSR#v(bufnr)
	bcfb	BUFST, #v(bufnr) 	; buffer read succesfully
	incfb	BUFPOSR#v(bufnr),f
	if_f_gt_l	BUFPOSR#v(bufnr), BUFFEREND#v(bufnr)	; if read pointer beyond end of buffer
	  load_f_l	BUFPOSR#v(bufnr), BUFFER#v(bufnr)	; set read pointer to begin of buffer
	end_if
	return
	endm

; bufwrite
;   write BUFWRT to buffer. Overwites previous values if buffer is full...
bufwrite	macro	bufnr
	load_i_f	BUFPOSW#v(bufnr), BUFWRT#v(bufnr)
	incfb	BUFPOSW#v(bufnr),f
	if_f_gt_l	BUFPOSW#v(bufnr), BUFFEREND#v(bufnr)	; if write pointer beyond end of buffer
	 load_f_l	BUFPOSW#v(bufnr), BUFFER#v(bufnr)	; set write pointer to begin of buffer
	end_if
	return
	endm

; bufwritewait
;   writes BUFWRT to buffer. Wait if buffer is full...
bufwritewait	macro	bufnr
	; first test if full	
	incfb	BUFPOSW#v(bufnr),w
	load_f_w	BUFPOSWTMP#v(bufnr)
	if_f_gt_l	BUFPOSWTMP#v(bufnr), BUFFEREND#v(bufnr)	; if write pointer beyond end of buffer
	 load_f_l	BUFPOSWTMP#v(bufnr), BUFFER#v(bufnr)	; set write pointer to begin of buffer
	end_if
	while_f_eq_f	BUFPOSWTMP#v(bufnr), BUFPOSR#v(bufnr)	; if equal, then full: wait
	 nop
	end_while
	load_i_f	BUFPOSW#v(bufnr), BUFWRT#v(bufnr)
	load_f_f	BUFPOSW#v(bufnr), BUFPOSWTMP#v(bufnr)	; load new position
	return
	endm

; bufwriteskip
;   writes BUFWRT to buffer, or skips if buffer is full
bufwriteskip	macro	bufnr
	; first test if full	
	incfb	BUFPOSW#v(bufnr),w
	load_f_w	BUFPOSWTMP#v(bufnr)
	if_f_gt_l	BUFPOSWTMP#v(bufnr), BUFFEREND#v(bufnr)	; if write pointer beyond end of buffer
	 load_f_l	BUFPOSWTMP#v(bufnr), BUFFER#v(bufnr)	; set write pointer to begin of buffer
	end_if
	if_f_eq_f	BUFPOSWTMP#v(bufnr), BUFPOSR#v(bufnr)	; if equal, then full: skip
	 return
	end_while
	load_i_f	BUFPOSW#v(bufnr), BUFWRT#v(bufnr)
	load_f_f	BUFPOSW#v(bufnr), BUFPOSWTMP#v(bufnr)	; load new position
	return
	endm

; writetext
;  writes text to TX buffer
;  example: writetext text_OK
;  with:    text_OK:	dt	"OK",.13,.10,0

writetext	macro	textlabel
	load_f16_l16	TEXT_POS, textlabel
	callp	write_text
	endm

write_char:	macro	char
	load_f_l	BUFWRT1, char
	callp	bufwritewait1	
	endm

write_f	macro	f
	load_f_f	BUFWRT1, f
	callp	bufwritewait1	; write to TX buffer
	endm

safe_wait_sspif	macro	cd
; DEBUG
;	load_f_l	(Stat_C3+3), cd
	callp	safe_wait_sspif_sub
	endm

safe_wait_sspif_macro	macro	cd
; DEBUG
;	clrfb	(Stat_C3+3)
	load_f16_l16	sspif_cnt,0x0000
	repeat
	 inc_f16	sspif_cnt
	 if_f16_ge_l16	sspif_cnt,0x0A80	; appr. 10 ms
	  bcfb	PIR1, SSPIF	; clear sspif
	  bcfb	PIR2, BCLIF	; clear collision
	  callp	i2c_init
	  return
	 end_if  
	until_f_b_s	PIR1, SSPIF	; if 12c operation completed
;mcr_#v(mcr_cnt)
;mcr_cnt++
	bcfb	PIR1, SSPIF	; clear sspif
	endm

; pin_to_BT - split pin number BTP in byte and bit; add byte to BTF and set bit in BTB
;               e.g. pin number 10 = B2 -> add 1 to BTF and set 2 in BTB  

bsfBTP_f	macro	flag
	load_f16_l16	BTF, flag 	; literal for address
	callp	pin_to_BT
	callp	setbitfl
	endm

bcfBTP_f	macro	flag
	load_f16_l16	BTF, flag 	; literal for address
	callp	pin_to_BT
	callp	clrbitfl
	endm

bgfBTP_f	macro	flag
	load_f16_l16	BTF, flag 	; literal for address
	callp	pin_to_BT
	callp	getbitfl
	endm

; ld_BTP_f - writes value of f2 to (f1 + pinnumber/8)
ld_BTP_f	macro	f1, f2
	load_f16_l16	BTF, f1 	; literal for address
	callp	pin_to_BT
	load_f_f	FSR1H, (BTF+1)
	load_f_f	FSR1L, BTF
	load_f_f	INDF1, f2
	endm

; gt_BTP_f - writes value (f1 + pinnumber/8) to f2
gt_BTP_f	macro	f1, f2
	load_f16_l16	BTF, f1 	; literal for address
	callp	pin_to_BT
	load_f_f	FSR1H, (BTF+1)
	load_f_f	FSR1L, BTF
	load_f_f	f2, INDF1
	endm


; pwm_port_h - macro to set pwm bit high
pwm_port_h	macro	offset
	gotoif_f_b_s	PWMstat,2, mcr_#v(mcr_cnt+4)	; 4..7
	gotoif_f_b_s	PWMstat,1, mcr_#v(mcr_cnt+2)	; 2..3
	gotoif_f_b_s	PWMstat,0, mcr_#v(mcr_cnt+1)	; 1
	; PWMstat=.0	; PWM low,  high output, output,    pin1
	bcfb	PWMres,0+offset		; pin low
	bcfb	PWMres,1+offset		; output
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+1)
	banklabel
	; PWMstat=.1	; PWM high, high output, output,    pin1
	bsfb	PWMres,0+offset		; pin high
	bcfb	PWMres,1+offset		; output
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+2)
	banklabel
	gotoif_f_b_s	PWMstat,0, mcr_#v(mcr_cnt+3)	; 3
	; PWMstat=.2	; PWM low,  low output, output,     pin1
	bsfb	PWMres,0+offset		; pin high
	bcfb	PWMres,1+offset		; output
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+3)
	banklabel
	; PWMstat=.3	; PWM high, low output, output,     pin1
	bcfb	PWMres,0+offset		; pin low
	bcfb	PWMres,1+offset		; output
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+4)
	banklabel
	gotoif_f_b_s	PWMstat,1, mcr_#v(mcr_cnt+6)	; 6..7
	gotoif_f_b_s	PWMstat,0, mcr_#v(mcr_cnt+5)	; 5
	; PWMstat=.4	; PWM low,  high output, high imp., pin1
	bsfb	PWMres,1+offset		; high impediance
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+5)
	banklabel
	; PWMstat=.5	; PWM high, high output, high imp., pin1
	bsfb	PWMres,0+offset		; pin high
	bcfb	PWMres,1+offset		; output
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+6)
	banklabel
	gotoif_f_b_s	PWMstat,0, mcr_#v(mcr_cnt+7)	; 7
	; PWMstat=.6	; PWM low,  low output, high imp.,  pin1
	bsfb	PWMres,1+offset		; high impediance
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+7)
	banklabel
	; PWMstat=.7	; PWM high, low output, high imp.,  pin1
	bcfb	PWMres,0+offset		; pin low
	bcfb	PWMres,1+offset		; output
mcr_#v(mcr_cnt)
mcr_cnt=mcr_cnt+8
	banklabel
	endm

; pwm_port_l - macro to set pwm bit low
pwm_port_l	macro	offset
	gotoif_f_b_s	PWMstat,2, mcr_#v(mcr_cnt+4)	; 4..7
	gotoif_f_b_s	PWMstat,1, mcr_#v(mcr_cnt+2)	; 2..3
	; PWMstat=.0	; PWM low,  high output, output,    pin1
	bcfb	PWMres,0+offset		; pin low
	bcfb	PWMres,1+offset		; output
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+2)
	banklabel
	; PWMstat=.2	; PWM low,  low output, output,     pin1
	bsfb	PWMres,0+offset		; pin high
	bcfb	PWMres,1+offset		; output
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+4)
	banklabel
	gotoif_f_b_s	PWMstat,1, mcr_#v(mcr_cnt+6)	; 6..7
	; PWMstat=.4	; PWM low,  high output, high imp., pin1
	bsfb	PWMres,1+offset		; high impediance
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt+6)
	banklabel
	; PWMstat=.6	; PWM low,  low output, high imp.,  pin1
	bsfb	PWMres,1+offset		; high impediance
	gotop	mcr_#v(mcr_cnt)
mcr_#v(mcr_cnt)
mcr_cnt=mcr_cnt+8
	banklabel
	endm

PWM_port	macro	port, portbit, value_adr, stat_adr, work_adr, bridge, port2, portbit2, stat_adr2
	if_f_eq_l	stat_adr, .5	; is pin PWM?
	 if_f_b_s		(stat_adr+1),6	; first: on intterrupt or on 10 ms?
	  if_f_b_c		CNT_stat,4
	   gotop		mcr_#v(mcr_cnt)
	  end_if
	 end_if
	 load_f16_f16		PWMwork, work_adr ; Now copy everything in PWM* and call subroutine
	 load_f16_f16		PWMvalue, value_adr
	 load_f_f		PWMstat0, (stat_adr)
	 load_f_f		PWMstat1, (stat_adr+1)
	 load_f_f		PWMstat2, (stat_adr+2)
	 if (bridge==1)
	  load_f_f		PWMfunc2, (stat_adr2)
	 else
	  load_f_l		PWMfunc2,.0		; no bridge
	 endif
	 callp	PWM_port_sub
	 load_f16_f16		work_adr, PWMwork	; and copy PWM* back
	 load_f16_f16		value_adr, PWMvalue
					; Now analyse PWM into pin values
	 if_f_b_s	PWMres,3	; Bridge
	  load_f_b_f_b	(port+TRISA-PORTA), portbit, PWMres, 1
	  load_f_b_f_b	(port2+TRISA-PORTA), portbit2, PWMres, 5
	  load_f_b_f_b	port, portbit, PWMres, 0
	  load_f_b_f_b	port2, portbit2, PWMres, 4
	 else_
	  load_f_b_f_b	(port+TRISA-PORTA), portbit, PWMres, 1
	  load_f_b_f_b	port, portbit, PWMres, 0
	 end_if
	end_if	; stat0=5
mcr_#v(mcr_cnt)
mcr_cnt++
	banklabel
	endm

PWM_only_port	macro	port, portbit, value_adr, stat_adr, work_adr
	if_f_eq_l	stat_adr, .5	; is pin PWM?
	 add_f16_f16_f16 work_adr, value_adr, work_adr	; increase sigma with value
	 if_f_b_s	(work_adr+1),2		; if >=1024 then high and decrease sigma with 1024
	  bsfb	port,portbit	; pin high
	  load_w_f	(work_adr+1)
	  sublw	0x40	; decrease 16384
	  load_f_w	(work_adr+1)	
	 else_		; otherwise low
	  bcfb	port,portbit	; pin low
	 end_if
	end_if	
	endm

#define	CPS_high	0xA0	; upper value
#define	CPS_switch	0x90	; Switch (middle) value
#define	CPS_low	0x70	; lower value
CPS_chan	macro	chan, port, portbit, value_adr, stat_adr, work_adr, chan_new, stat_adr_new
	if_f_eq_l	stat_adr, .4		; CPS?
	 load_f_f	(stat_adr+3), TMR0
	 ; CPS filter
	 if_f_lt_f	(stat_adr+3),(stat_adr+2) 	; touch
	  incfb	work_adr,f
	  if_f_eq_l	work_adr,CPS_switch
	   load_f_l	value_adr,.1		
	   clrfb	(value_adr+1)
	   load_f_l	(work_adr+1),b'11'	; 1: signal, 1: pressed
	   load_f_l	work_adr,CPS_high
	  end_if
	  if_f_gt_l	work_adr,CPS_high
	   load_f_l	work_adr,CPS_high
	  end_if
	 else_		; no touch
	  decfb	work_adr,f
	  if_f_eq_l	work_adr,CPS_switch
	   load_f_l	value_adr,.0		
	   clrfb	(value_adr+1)
	   load_f_l	(work_adr+1),b'10'	; 1: signal, 0: unpressed
	   load_f_l	work_adr,CPS_low
	  end_if
	  if_f_lt_l	work_adr,CPS_low
	   load_f_l	work_adr,CPS_low
	  end_if
	 end_if
	 ;load_f_f	value_adr, work_adr
	 ;load_f_f	(value_adr+1), (work_adr+1)
	 clrfb	TMR0		; reset timer 0
	end_if 	; stat_adr, .4
	if_f_eq_l	stat_adr_new, .4	; CPS?
	 ;load_f_l	CPSCON0, B'10001101' ; Set CPS on, low current, sinking, CPSCLK, Timer 0
	 load_w_f	(stat_adr_new+1)	; get current setting
	 andlw	0x0C
	 xorlw	0x0C		; invert two bits for power setting
	 iorlw	B'10000001' 		; Set CPS on, sinking, CPSCLK, Timer 0
	 load_f_w	CPSCON0 
	 load_f_l	CPSCON1, chan_new	; select CPS channel
	else_
	 load_f_l	CPSCON0, B'00000000' ; Set CPS off
	end_if
	load_f_l	CPS_channel, chan_new
	return
	endm

ADC_check	macro	portpinnr, stat_adr
	if_f_eq_l	stat_adr,.3	; ADC?
	 if_f_b_s	(stat_adr+1),6	; send every 100ms?
	  load_f_l	cmda1,.2	; read
	  load_f_l	cmda2,portpinnr
	  clrfb	(cmda2+1)
	  ;clr_f16	cmda3	; not really needed
	  load_f_l	nofargs,.2
	  callp	cmd_exec_nocmdln
	 end_if	; (stat_adr+1),6
	end_if	; stat_adr,3
	endm

CPS_check	macro	chport, chportbit, stat_adr, work_adr
	if_f_eq_l	stat_adr,.4	; CPS?
	 if_f_b_s	(work_adr+1),1	; signal?
	  bcfb	(work_adr+1),1
	  if_f_b_c	(work_adr+1),0	; no touch
	   if_f_b_s	(stat_adr+1),1	; should write?
	    write_char	'R'
	    write_char	' '
	    write_char	chport
	    write_char	chportbit
	    write_char	' '
	    write_char	'0'
	    write_char	.10
	   end_if	; sa,3
	  else_
	   if_f_b_s	(stat_adr+1),0	; should write?
	    write_char	'R'
	    write_char	' '
	    write_char	chport
	    write_char	chportbit
	    write_char	' '
	    write_char	'1'
	    write_char	.10
	   end_if
	  end_if	; wa+1,0
	 end_if	; wa+1,1
	end_if	; stat_adr,5
	endm

INP_check	macro	port, portbit, chport, chportbit, stat_adr, work_adr
	if_f_eq_l	stat_adr,.0	; input (high impediance)
	  gotop	mcr_#v(mcr_cnt)
	end_if
	if_f_eq_l	stat_adr,.1	; input (wpu)
mcr_#v(mcr_cnt)
	banklabel
	 if_f_b_c	port, portbit	; bit low?
	  if_f_b_s	(stat_adr+1),1	; should write?
	   if_f_b_s	work_adr,0	; previous bit high?
	    write_char	'R'
	    write_char	' '
	    write_char	chport
	    write_char	chportbit
	    write_char	' '
	    write_char	'0'
	    write_char	.10
	   end_if	; wa,0
	  end_if	; sa+1,1
	  bcfb	work_adr,0	; store previousbit state
	 else_		; bit high?
	  if_f_b_s	(stat_adr+1),0	; should write?
	   if_f_b_c	work_adr,0	; previous bit low?
	    write_char	'R'
	    write_char	' '
	    write_char	chport
	    write_char	chportbit
	    write_char	' '
	    write_char	'1'
	    write_char	.10
	   end_if	; wa,0
	  end_if	; sa+1,1
	  bsfb	work_adr,0	; store previousbit state
	 end_if	; port,portbit
	end_if	; stat_adr,0 or 1
mcr_cnt++
	banklabel
	endm

set_valueregister  macro   pinnumber, value
	load_f_l	cmda1, 1	    ; Write command
	load_f_l	cmda2, pinnumber    ; Pin number
        load_f16_l16    cmda3, value	    ; Value 
	load_f_l	nofargs,.3	    ; 3 parameters
        callp		cmd_exec_nocmdln    ; execute the command
	endm

set_statusregister  macro   pinnumber, statusnumber, function
	load_f_l	cmda1, 3		; Set command
	load_f_l	cmda2, pinnumber	; Pin number
    	load_f_l	(cmda2+1), statusnumber ; status regster number
        load_f_l	cmda3, function		; Function 
	load_f_l	nofargs,.3		; 3 parameters
        callp		cmd_exec_nocmdln	; execute the command
	endm

set_status_and_value  macro   pinnumber, function, value
	load_f_l	cmda1, 3		; Set command
	load_f_l	cmda2, pinnumber	; Pin number
    	load_f_l	(cmda2+1), 0		; status-0 register
        load_f_l	cmda3, function		; Function 
        load_f16_l16	cmda4, value		; Value 
	load_f_l	nofargs,.4		; 4 parameters
        callp		cmd_exec_nocmdln	; execute the command
	endm


; MACRO for PULSE LENGTH in READ
pulse_read    macro   portnumber, stat
     if_f_eq_l	BTP, portnumber    ; right port?
      if_f_b_s (stat+1),6    ; bit 6 of stat-1 set (pulse length)
       if_f_lt_l stat,.2	    ; stat-0 is 0 or 1 (digital input)
        if_f_eq_l   (stat+3), .0	; stat-3==5: write valueregister
	 load_f_l (stat+3), .1	    ; then stat-3 = 1
	 gotop getcexit	    ; done here, exit interpretor 
	end_if ; stat3=0 
       end_if ; stat0<2
      end_if ; stat-1,6
     end_if ; BTP
     endm
	
; MACRO for PULSE LENGTH in main loop
pulse_main    macro   stat, value, pinchar1, pinchar2
    if_f_lt_l stat,.2	    ; stat-0 is 0 or 1 (digital input)
     if_f_b_s (stat+1),6    ; bit 6 of stat-1 set (pulse length)
     
      if_f_eq_l	(stat+3), .5	; stat-3==5: write valueregister
       write_char 'R'
       write_char ' '
       write_char pinchar1
       write_char pinchar2
       write_char ' '
       load_f16_f16 txt_int, value
       callp	write_dec_txtint_16_lf
       load_f_l (stat+3), .0
      end_if ; stat3=5
      
     end_if ; (stat+1),6
    end_if ; stat,.2
    endm
    
; MACRO for PULSE LENGTH in Interrupt-routine
pulse_interrupt    macro   stat, value, portregister, mask
    if_f_lt_l stat,.2	    ; stat-0 is 0 or 1 (digital input)
     if_f_b_s (stat+1),6    ; bit 6 of stat-1 set (pulse length)

      if_f_eq_l	(stat+3), .4	; stat-3==4: count
       load_w_f	portregister
       andlw	mask
       if_f_b_c	STATUS, Z	; pin is high 
         load_f_l (stat+3), .5
	else_
	 if_f16_eq_l16	value, 0xFFFF
          load_f_l (stat+3), .5
	 else_
	  inc_f16 value
	 end_if ; value,0xFFFF
	end_if ; status,z
      end_if ; stat3=4
     
      if_f_eq_l	(stat+3), .3	; stat-3==3: wait for low
       load_w_f	portregister
       andlw	mask
       if_f_b_s	STATUS, Z	; pin is low 
         load_f_l (stat+3), .4
	end_if ; status,z
      end_if ; stat3=3

      if_f_eq_l	(stat+3), .2	; stat-3==2: wait for high
       load_w_f	portregister
       andlw	mask
       if_f_b_c	STATUS, Z	; pin is high 
         load_f_l (stat+3), .3
	end_if ; status,z
      end_if ; stat3=2
     
     if_f_eq_l	(stat+3), .1	; stat-3==1: initialise
       load_f16_l16 value, 0	; clear valueregister 
       load_f_l (stat+3), .2
      end_if ; stat3=1
      
     end_if ; (stat+1),6
    end_if ; stat,.2
    endm
 
subdivr_f_l_f_f	macro	v1, l2, v3, v4
	load_f_f	mvar1, v1
	load_f_l	mvar2, l2
	callp	divrffff
	load_f_f	v3, mvar3
	load_f_f	v4, mvar4
	endm

subdivr_f16_l16_f16_f16	macro	v1, l2, v3, v4
	load_f16_f16	mvar1, v1
	load_f16_l16	mvar2, l2
	callp	divrf16f16f16f16
	load_f16_f16	v3, mvar3
	load_f16_f16	v4, mvar4
	endm

subdiv_f16_f_f16	macro	v1, v2, v3
	load_f16_f16	mvar1, v1
	load_f_f	mvar2, v2
	clr_f	(mvar2+1)
	callp	divrf16f16f16f16
	load_f16_f16	v3, mvar3
	endm

subdiv_f32_f32_f32	macro	v1, v2, v3
	load_f32_f32	mvar1, v1
	load_f32_f32	mvar2, v2
	callp	divf32f32f32
	load_f32_f32	v3, mvar3
	endm

; subsqr v1, v3 : v3=v1*v1
subsqr_f16_f32	macro	v1, v3
	load_f16_f16	mvar1, v1
	load_f16_f16	mvar2, v1
	clr_f16	(mvar1+2)
	clr_f16	(mvar2+2)
	mul_f32_f32_f32	mvar1, mvar2, v3
	endm

load_bk_li_l	macro	lit1, flag, lit2
	  load_f_l	FSR0H,lit1 | 0x20
	  ;bsf	FSR0H,5 	; linear mode
	  load_f_f	FSR0L,flag
	  load_f_l	INDF0,lit2
	endm

load_bk_li_f	macro	lit, flag1, flag2
	  load_f_l	FSR0H,lit | 0x20
	  ;bsf	FSR0H,5 	; linear mode
	  load_f_f	FSR0L,flag1
	  load_f_f	INDF0,flag2
	endm

load_w_bk_li	macro	lit, flag
	  load_f_l	FSR0H,lit | 0x20
	  ;bsf	FSR0H,5 	; linear mode
	  load_f_f	FSR0L,flag
	  load_w_f	INDF0
	endm

load_f_bk_li	macro	flag1, lit, flag2
	  load_f_l	FSR0H,lit | 0x20
	  ;bsf	FSR0H,5 	; linear mode
	  load_f_f	FSR0L,flag2
	  load_f_f	flag1, INDF0
	endm

load_bk_li_addl_f	macro	lit1, flag1, lit2, flag2
	  load_f_l	FSR0H,lit1 | 0x20
	  ;bsf	FSR0H,5 	; linear mode
	  load_w_f	flag1
	  addlw	lit2
	  load_f_w	FSR0L
	  load_f_f	INDF0,flag2
	endm

load_f_bk_li_addl	macro	flag1, lit1, flag2, lit2
	  load_f_l	FSR0H,lit1 | 0x20
	  ;bsf	FSR0H,5 	; linear mode
	  load_w_f	flag2
	  addlw	lit2
	  load_f_w	FSR0L
	  load_f_f	flag1, INDF0
	endm

load_bk_li_f16	macro	lit, flag1, flag2
	  load_f_l	FSR0H,lit | 0x20
	  ;bsf	FSR0H,5 	; linear mode
	  load_f_f	FSR0L,flag1
	  load_f_f	INDF0,flag2
	  incfb	FSR0L,f
	  load_f_f	INDF0,(flag2+1)
	endm

load_f16_bk_li	macro	flag1, lit, flag2
	  load_f_l	FSR0H,lit | 0x20
	  ;bsf	FSR0H,5 	; linear mode
	  load_f_f	FSR0L,flag2
	  load_f_f	flag1, INDF0
	  incfb	FSR0L,f
	  load_f_f	(flag1+1), INDF0
	endm



; ***********************************************************************
; START OF CODE
; ***********************************************************************

	ifdef	debug_org200
	org	0x0000		; After bootloader
	goto	0x0200
	nop
	nop
	nop
	gotopp	0x0204		; goto interrupt routines
	endif
	org	0x0200		; After bootloader
	gotopp	initialize
	nop
	nop
	gotopp	interrupt	; goto interrupt routines

; setbitfl - set bit number in BTB in register BTF:2	
setbitfl	
	banklabel
	load_f_f	FSR1H, BTF+1
	load_f_f	FSR1L, BTF
	load_w_f	BTB
	andlw	0x07
	lslf	WREG, f
	;addlw	(sbfl0 % .256)
	addwf	PCL,f
sbfl0	banklabel
	bsf	INDF1,0
	return
	bsf	INDF1,1
	return
	bsf	INDF1,2
	return
	bsf	INDF1,3
	return
	bsf	INDF1,4
	return
	bsf	INDF1,5
	return
	bsf	INDF1,6
	return
	bsf	INDF1,7
sbfl1	banklabel
	return
	if (setbitfl / .256) != (sbfl1 / .256) 
	  error "Table in SETBITFL not in same 256 byte segment. Move code block."
	endif
	
; clrbitfl - clear bit number in BTB in register BTF:2	
clrbitfl	
	banklabel
	load_f_f	FSR1H, BTF+1
	load_f_f	FSR1L, BTF
	load_w_f	BTB
	andlw	0x07
	lslf	WREG, f
	;addlw	(rbfl0 % .256)
	addwf	PCL,f
rbfl0	banklabel
	bcf	INDF1,0
	return
	bcf	INDF1,1
	return
	bcf	INDF1,2
	return
	bcf	INDF1,3
	return
	bcf	INDF1,4
	return
	bcf	INDF1,5
	return
	bcf	INDF1,6
	return
	bcf	INDF1,7
rbfl1	banklabel
	return
	if (clrbitfl / .256) != (rbfl1 / .256) 
	  error "Table in CLRBITFL not in same 256 byte segment. Move code block."
	endif

; getbitfl - get bit number in BTB in register BTF:2 and put into bit zero of BTS	
getbitfl	
	banklabel
	load_f_f	FSR1H, BTF+1
	load_f_f	FSR1L, BTF
	load_w_f	BTB
	andlw	0x07
	lslf	WREG, f
	lslf	WREG, f
	;addlw	(gbfl0 % .256)
	addwf	PCL,f
gbfl0	banklabel
	bcf	BTS,0
	btfsc	INDF1,0
	bsf	BTS,0
	return
	bcf	BTS,0
	btfsc	INDF1,1
	bsf	BTS,0
	return
	bcf	BTS,0
	btfsc	INDF1,2
	bsf	BTS,0
	return
	bcf	BTS,0
	btfsc	INDF1,3
	bsf	BTS,0
	return
	bcf	BTS,0
	btfsc	INDF1,4
	bsf	BTS,0
	return
	bcf	BTS,0
	btfsc	INDF1,5
	bsf	BTS,0
	return
	bcf	BTS,0
	btfsc	INDF1,6
	bsf	BTS,0
	return
	bcf	BTS,0
	btfsc	INDF1,7
	bsf	BTS,0
gbfl1	banklabel
	return
	if (getbitfl / .256) != (gbfl1 / .256) 
	  error "Table in GETBITFL not in same 256 byte segment. Move code block."
	endif

; get_allowedpinfunctions - give allowed function (bits in byte) of pin in BTP
get_allowedpinfunctions
	banklabel
	load_f_l	PCLATH, (gap0 / .256)
	load_w_l	(gap0 % .256)
	addwf	BTP,w
	callw
	load_f_w	BTA
	return
gap0	banklabel
	retlw	b'00001111'	; A0
	retlw	b'00001111'	; A1
	retlw	b'00001111'	; A2
	retlw	b'00001111'	; A3
	retlw	b'00010111'	; A4
	retlw	b'00011111'	; A5
	retlw	b'00100111'	; A6
	retlw	b'01100111'	; A7
	retlw	b'00111111'	; B0
	retlw	b'01111111'	; B1
	retlw	b'00011111'	; B2
	retlw	b'00011111'	; B3
	retlw	b'00011111'	; B4
	retlw	b'00011111'	; B5
	retlw	b'00100111'	; B6
	retlw	b'01100111'	; B7
	retlw	b'01000111'	; C0
	retlw	b'00100111'	; C1
	retlw	b'01100111'	; C2
	retlw	b'01000011'	; C3
	retlw	b'01000011'	; C4
	retlw	b'00000111'	; C5
	retlw	b'00000000'	; C6
	ifndef	PIN40
gap1	banklabel
	retlw	b'00000000'	; C7
	else
	retlw	b'00000000'	; C7
	retlw	b'00000111'	; D0
	retlw	b'00000111'	; D1
	retlw	b'00000111'	; D2
	retlw	b'00000111'	; D3
	retlw	b'00000111'	; D4
	retlw	b'00000111'	; D5
	retlw	b'00000111'	; D6
	retlw	b'00000111'	; D7
	retlw	b'00000111'	; E0
	retlw	b'00000111'	; E1
	retlw	b'00000111'	; E2
	retlw	b'00000001'	; E3
	retlw	b'00000111'	; E4
	retlw	b'00000111'	; E5
	retlw	b'00000111'	; E6
gap1	banklabel
	retlw	b'00000111'	; E7
	endif
	if (get_allowedpinfunctions / .256) != (gap1 / .256) 
	  error "Table in GET_ALLOWEDPINFUNCTIONS not in same 256 byte segment. Move code block."
	endif
	
; get_pintoADC - give ADC number (in BTAC) of pin in BTP; 0x80 if no ADC
get_pintoADC
	banklabel
	load_f_l	PCLATH, (gpa0 / .256)
	load_w_l	(gpa0 % .256)
	addwf	BTP,w
	callw
	load_f_w	BTAC
	return
gpa0	banklabel
	retlw	0x00	; A0
	retlw	0x01	; A1
	retlw	0x02	; A2
	retlw	0x03	; A3
	retlw	0x80	; A4
	retlw	0x04	; A5
	retlw	0x80	; A6
	retlw	0x80	; A7
	retlw	0x0C	; B0
	retlw	0x0A	; B1
	retlw	0x08	; B2
	retlw	0x09	; B3
	retlw	0x0B	; B4
	retlw	0x0D	; B5
	retlw	0x80	; B6
	retlw	0x80	; B7
	retlw	0x80	; C0
	retlw	0x80	; C1
	retlw	0x80	; C2
	retlw	0x80	; C3
	retlw	0x80	; C4
	retlw	0x80	; C5
	retlw	0x80	; C6
	ifndef	PIN40
gpa1	banklabel
	retlw	0x80	; C7
	else
	retlw	0x80	; C7
	retlw	0x80	; D0
	retlw	0x80	; D1
	retlw	0x80	; D2
	retlw	0x80	; D3
	retlw	0x80	; D4
	retlw	0x80	; D5
	retlw	0x80	; D6
	retlw	0x80	; D7
	retlw	0x05	; E0
	retlw	0x06	; E1
	retlw	0x07	; E2
	retlw	0x80	; E3
	retlw	0x80	; E4
	retlw	0x80	; E5
	retlw	0x80	; E6
gpa1	banklabel
	retlw	0x80	; E7
	endif
	if (get_pintoADC / .256) != (gpa1 / .256) 
	  error "Table in get_pintoADC not in same 256 byte segment. Move code block."
	endif

; get_ADCtopin - give pin in BTP for ADC number (in BTAC); 0x80 if not exist
get_ADCtopin
	banklabel
	load_f_l	PCLATH, (gpac0 / .256)
	load_w_f	BTAC
	andlw	0x0F
	addlw	(gpac0 % .256)
	callw
	load_f_w	BTP
	return
;  S2: Analog
;    bit 0: read A0 
;    bit 1: read A1 
;    bit 2: read A2 
;    bit 3: read A3 
;    bit 4: read A5 
;    (bit 5: read E0)
;    (bit 6: read E1)
;    (bit 7: read E2) 
; 
;  S3: Analog
;    bit 0: read B2 
;    bit 1: read B3 
;    bit 2: read B1 
;    bit 3: read B4 
;    bit 4: read B0 
;    bit 5: read B5
;    bit 6: read Core temperature
;    bit 7: read 2.048 V reference
gpac0	banklabel
	retlw	0x00	; ch0 -> A0
	retlw	0x01	; ch1 -> A1
	retlw	0x02	; ch2 -> A2
	retlw	0x03	; ch3 -> A3
	retlw	0x05	; ch4 -> A5
	#ifdef	PIN40
	retlw	0x20	; ch5 -> E0
	retlw	0x21	; ch6 -> E1
	retlw	0x22	; ch7 -> E2
	#else
	retlw	0x80	; ch5 -> -
	retlw	0x80	; ch6 -> -
	retlw	0x80	; ch7 -> -
	#endif
	retlw	0x0A	; ch8 -> B2
	retlw	0x0B	; ch9 -> B3
	retlw	0x09	; ch10 -> B1
	retlw	0x0C	; ch11 -> B4
	retlw	0x08	; ch12 -> B0
	retlw	0x0D	; ch13 -> B5
	retlw	0x80	; ch14 -> -
gpac1	banklabel
	retlw	0x80	; ch15 -> -
	if (get_ADCtopin / .256) != (gpac1 / .256) 
	  error "Table in get_ADCtopin not in same 256 byte segment. Move code block."
	endif

; CPS_jump - jump to right routine, depending CPS_channel
CPS_jump
	banklabel
	load_w_f	CPS_channel
	#ifndef	PIN40
	andlw	0x07	; 8 channels
	#else
	andlw	0x0F	; 16 channels
	#endif
	lslf	WREG, f
	;lslf	WREG, f
	addwf	PCL,f
cpsj0
	banklabel
	errorlevel 	-306	; supress page boundary warning
	pagesel	CPS_jump0	; B0 (Ch 0)
	goto	CPS_jump0
	pagesel	CPS_jump1	; B1 (Ch 1)
	goto	CPS_jump1
	pagesel	CPS_jump2	; B2 (Ch 2)
	goto	CPS_jump2
	pagesel	CPS_jump3	; B3 (Ch 3)
	goto	CPS_jump3
	pagesel	CPS_jump4	; B4 (Ch 4)
	goto	CPS_jump4
	pagesel	CPS_jump5	; B5 (Ch 5)
	goto	CPS_jump5
	pagesel	CPS_jump6	; A4 (Ch 6)
	goto	CPS_jump6
	pagesel	CPS_jump7	; A5 (Ch 7)
	goto	CPS_jump7
	ifdef	PIN40
	pagesel	CPS_jump8	; D0 (Ch 8)
	goto	CPS_jump8
	pagesel	CPS_jump9	; D1 (Ch 9)
	goto	CPS_jump9
	pagesel	CPS_jump10	; D2 (Ch 10)
	goto	CPS_jump10
	pagesel	CPS_jump11	; D3 (Ch 11)
	goto	CPS_jump11
	pagesel	CPS_jump12	; D4 (Ch 12)
	goto	CPS_jump12
	pagesel	CPS_jump13	; D5 (Ch 13)
	goto	CPS_jump13
	pagesel	CPS_jump14	; D6 (Ch 14)
	goto	CPS_jump14
	pagesel	CPS_jump15	; D7 (Ch 15)
	goto	CPS_jump15
	endif
	pagesel	$
	errorlevel 	+306


; set_default_pins - set default pin functions and settings
set_default_pins
	banklabel
	callp	clear_pinfunctions
	load_f_l	Stat_Y0, FW_App
	load_f_l	Stat_Y1, FW_Version
; *** ADD HERE YOUR OWN PINFUNCTION SETTINGS
;   B2 as digital input with weak pull-up, B20=1, 
;      and pulse length, B21=64
    set_statusregister .10, 0, .1	
    set_statusregister .10, 1, .64
	return

initialize:
	banklabel


	bcf	INTCON,7	; disable interrupt
	load_f_l	OSCCON, b'11110000' ; 32 MHz clock (be aware of ADC Errata on 32 MHz)

	; set RC as input (RC3 and RC4 as I2C, RC& as Rx)
	load_f_l	TRISC, 0xFF
	; Set Tx (RC6) as output
	load_f_b_l	TRISC, 6, 0
	load_f_b_l	PORTC, 6, 1
	uart_init	.9600 ; baudrate not implemented!
	#ifdef	include_3STOPBITS
	 clr_f	stop3bitcnt
	 load_f_l	stop3bitmax,.100
	#endif
	; Buffer for TX and RX
	callp	bufinit1	; Make buffer 1 for TX
	callp	bufinit2	; Make buffer 2 for RX
	bsfb	BUFST,7

	; Timer 2 for Interrupt at 16 kHz (or other value depending on Z0)
	load_f_l	PR2, PR2_16k	; trigger value for timer 2 (16 KHz)
	load_f_l	T2CON, 0x06	; Timer 2 on, prescaler 1:16
	
	; Timer 0 init for CPS read
	load_f_b_l	OPTION_REG, 3, 1 ; PSA off for Timer 0
	load_f_b_l	OPTION_REG, 5, 1 ; CPS on Timer 0

	
	load_f_l	CNT_submsmax, .16	; Interrupts / 10ms
	clrfb	CNT_subms
	clr_f16	CNT_ms
	clr_f16	wdt_2
	clr_f16	wdt_60
	clrfb	CNT_stat

	clrfb	dlog_stat

	clrfb	cmdbfl	; reset read buffer

	clr_f	cmdstat
	clr_f	dlog_posblock
	; Fixed Voltage Reference
	load_f16_l16	FVRCON, b'10100010' ; FVR on, 2.048V for ADC, off for DAC, T on, low range

	; Timer 2 enable 
	bsfb	INTCON,PEIE	; enable interrupt for peripherals (Timer 2)
	bsfb	PIE1,TMR2IE	; enable interrupt on Timer 2 PR value
	bcfb	PIR1, TMR2IF	; clear timer 2 bit
	bsfb	INTCON,7	; enable interrupt


	
main:
	banklabel
	
	load_f_l	DATA_EE_ADDR, .188	; Z0 in EEPROM
	callp	read_eeprom
	if_f_b_c	DATA_EE_DATA, 7		; EEPROM not empty
	 if_f_b_s	DATA_EE_DATA, 2		; flag set to load from eeprom
	  callp	load_from_eeprom
	  callp	set_all_pins_from_eeprom
	 else_
	  callp	set_default_pins
	 end_if
	else_
	 callp	set_default_pins
	end_if

; DEBUG 
	ifdef	debug_mplabsim
	callp	debugcommands	
	endif

mainloop:	
	banklabel
	nop ; for debugging

        ; ADDED FOR PULS LENGTH
	pulse_main    Stat_B2, Val_B2, 'B', '2'	; write pulse length
	
	; Watch DOG
	if_f_b_s	CNT_stat,1	; 2 s watchdog time out
	 bcfb	CNT_stat,1	; reset flag
	  for_f_l_l	tmp1, .0, .21
	  load_w_f	tmp1	; calculate RAM position for status-0 register
	  lslf	WREG,f
	  lslf	WREG,f
	  load_f_w	tmp2
	  load_f_bk_li	tmp3,.3,tmp2
	  if_f_eq_l	tmp3,.2	; output
	   gotop	mlp1
	  end_if
	  if_f_eq_l	tmp3,.5	; PWM
mlp1	banklabel
	   incfb	tmp2,f	; status-1 register	
	   load_f_bk_li	tmp3,.3,tmp2
	   if_f_b_s	tmp3,2	; watchdog 2s enabled?
	    callp	watchdog_switchoff
	   end_if
	  end_if
	 next_f	tmp1
	end_if
	if_f_b_s	CNT_stat,2	; 60 s watchdog time out
	 bcfb	CNT_stat,2	; reset flag
	  for_f_l_l	tmp1, .0, .21
	  load_w_f	tmp1	; calculate RAM position for status-0 register
	  lslf	WREG,f
	  lslf	WREG,f
	  load_f_w	tmp2
	  load_f_bk_li	tmp3,.3,tmp2
	  if_f_eq_l	tmp3,.2	; output
	   gotop	mlp2
	  end_if
	  if_f_eq_l	tmp3,.5	; PWM
mlp2	banklabel
	   incfb	tmp2,f	; status-1 register	
	   load_f_bk_li	tmp3,.3,tmp2
	   if_f_b_s	tmp3,3	; watchdog 60s enabled?
	    callp	watchdog_switchoff
	   end_if
	  end_if
	 next_f	tmp1
	end_if


	#ifdef	include_datalogger
	if_f_b_s	Stat_S0,0		; if datalogging
	 if_f_b_s	dlog_stat,7		; flag set for measurement?
	  bcfb	dlog_stat,7		; reset flag 
	  callp	datalog_measure
	 end_if

	else_			; Execute if no datalogging
	#endif	; include_datalogger

	#ifdef include_CPSchange
	 CPS_check	'B','0', Stat_B0, Work_B0
	 CPS_check	'B','1', Stat_B1, Work_B1
	 CPS_check	'B','2', Stat_B2, Work_B2
	 CPS_check	'B','3', Stat_B3, Work_B3
	 CPS_check	'B','4', Stat_B4, Work_B4
	 CPS_check	'B','5', Stat_B5, Work_B5
	 CPS_check	'A','4', Stat_B4, Work_A4
	 CPS_check	'A','5', Stat_B5, Work_A5
	 #ifdef	PIN40
	 CPS_check	'D','0', Stat_D0, Work_D0
	 CPS_check	'D','1', Stat_D1, Work_D1
	 CPS_check	'D','2', Stat_D2, Work_D2
	 CPS_check	'D','3', Stat_D3, Work_D3
	 CPS_check	'D','4', Stat_D4, Work_D4
	 CPS_check	'D','5', Stat_D5, Work_D5
	 CPS_check	'D','6', Stat_D6, Work_D6
	 CPS_check	'D','7', Stat_D7, Work_D7
	 #endif
	 #endif


	if_f_b_s	CNT_stat,3	; 100 ms ADC flag 
	 ADC_check	.0, Stat_A0
	 ADC_check	.1, Stat_A1
	 ADC_check	.2, Stat_A2
	 ADC_check	.3, Stat_A3
	 ADC_check	.5, Stat_A5
	 ADC_check	.8, Stat_B0
	 ADC_check	.9, Stat_B1
	 ADC_check	.10, Stat_B2
	 ADC_check	.11, Stat_B3
	 ADC_check	.12, Stat_B4
	 ADC_check	.13, Stat_B5
	 bcfb	CNT_stat,3
	end_if

	 ;INP_check	PORTA, .0, 'A','0', Stat_A0, Work_A0
	 ;INP_check	PORTA, .1, 'A','1', Stat_A1, Work_A1
	 ;INP_check	PORTA, .2, 'A','2', Stat_A2, Work_A2
	 ;INP_check	PORTA, .3, 'A','3', Stat_A3, Work_A3
	 ;INP_check	PORTA, .4, 'A','4', Stat_A4, Work_A4
	 ;INP_check	PORTA, .5, 'A','5', Stat_A5, Work_A5
	 INP_check	PORTA, .6, 'A','6', Stat_A6, Work_A6
	 INP_check	PORTA, .7, 'A','7', Stat_A7, Work_A7
	 ;INP_check	PORTB, .0, 'B','0', Stat_B0, Work_B0
	 ;INP_check	PORTB, .1, 'B','1', Stat_B1, Work_B1
	 ;INP_check	PORTB, .2, 'B','2', Stat_B2, Work_B2
	 ;INP_check	PORTB, .3, 'B','3', Stat_B3, Work_B3
	 INP_check	PORTB, .4, 'B','4', Stat_B4, Work_B4
	 INP_check	PORTB, .5, 'B','5', Stat_B5, Work_B5
	 ;INP_check	PORTB, .6, 'B','6', Stat_B6, Work_B6
	 ;INP_check	PORTB, .7, 'B','7', Stat_B7, Work_B7
	 INP_check	PORTC, .0, 'C','0', Stat_C0, Work_C0
	 INP_check	PORTC, .1, 'C','1', Stat_C1, Work_C1
	 INP_check	PORTC, .2, 'C','2', Stat_C2, Work_C2
	 INP_check	PORTC, .3, 'C','3', Stat_C3, Work_C3
	 ;INP_check	PORTC, .4, 'C','4', Stat_C4, Work_C4
	 ;INP_check	PORTC, .5, 'C','5', Stat_C5, Work_C5
	 #ifdef	PIN40
	 INP_check	PORTD, .0, 'D','0', Stat_D0, Work_D0
	 INP_check	PORTD, .1, 'D','1', Stat_D1, Work_D1
	 INP_check	PORTD, .2, 'D','2', Stat_D2, Work_D2
	 INP_check	PORTD, .3, 'D','3', Stat_D3, Work_D3
	 INP_check	PORTD, .4, 'D','4', Stat_D4, Work_D4
	 INP_check	PORTD, .5, 'D','5', Stat_D5, Work_D5
	 INP_check	PORTD, .6, 'D','6', Stat_D6, Work_D6
	 INP_check	PORTD, .7, 'D','7', Stat_D7, Work_D7
	 INP_check	PORTE, .0, 'E','0', Stat_E0, Work_E0
	 INP_check	PORTE, .1, 'E','1', Stat_E1, Work_E1
	 INP_check	PORTE, .2, 'E','2', Stat_E2, Work_E2
	 #endif


	 ; Clock
	 if_f_b_s	CNT_stat,7		; second flag set?
	  bcfb	CNT_stat,7			; reset second flag
	  if_f_b_s	Stat_X0,0		; show clock?
	   write_char	'R'
	   write_char	' '
	   write_char	'X'
	   write_char	' '
	   load_f_f	txt_int, Stat_X3	; hour
	   callp	write_dec_txtint_8
	   write_char	':'
	   load_f_f	txt_int, Stat_X2	; minute
	   callp	write_dec2_txtint_8
	   write_char	':'
	   load_f_f	txt_int, Stat_X1	; second
	   callp	write_dec2_txtint_8
	   write_char	.10
	  end_if ; Stat_X0,0
	 end_if ; CNT_stat,7

	 ; Timer1
	 if_f_eq_l	Stat_C0,.6		; Timer1?
	  if_f_b_s	(Stat_C0+1),7		; send Timer 1 every period?
	   if_f_b_s	Work_C0,0		; flag set for new send?
	    write_char	'R'
	    write_char	' '
	    write_char	'C'
	    write_char	'0'
	    write_char	' '
	    load_f16_f16	txt_int, Val_C0	; timer value
	    callp	write_dec_txtint_16_lf
	    bcfb	Work_C0,0		; reset flag 
	   end_if
	  end_if
	 end_if

	#ifdef	include_datalogger
	end_if ; datalogging 
	#endif	; include_datalogger

	; Get value from UART RX and put in parse buffer
	nop	; debug
rdrx
	banklabel
	callp	bufread2	; if value in buffer then value in BUFRD and BUFST equals 0, else BUFST = 1
	if_f_b_c	BUFST,2	; so, there is a value
	  clr_f16	wdt_2	; clear watchdog
	  clr_f16	wdt_60
	  load_f_f	UART_RD, BUFRD2
	  if_f_b_c	Stat_Z0,1	; Echo depending on Z0:1 setting
	   load_f_f	BUFWRT1, BUFRD2
	   callp	bufwritewait1	; write to TX buffer
	  end_if
	  clrfb	rcv_timer 	; clear time out
 	  if_f_eq_l	BUFRD2,'Q' 	; Goto Bootloader!
	   if_f_b_c	Stat_Z0,1	; Only on Z0:1 setting
	    gotop	set_Z3_bootloader
	   end_if
 	  end_if
 	  if_f_lt_l	BUFRD2,.32 	; end of line
  	   gotop	lpparse
	   gotop	rdrx	; check whether there is another character in the buffer
 	  end_if
 	  if_f_eq_l	BUFRD2,'*' 	; skip RN171 commando's
  	   gotop	lpparse
	   gotop	rdrx	; check whether there is another character in the buffer
 	  end_if
 	  if_f_eq_l	BUFRD2,'#' 	; EOL for Android Bluetooth Terminal
  	   gotop	lpparse
	   gotop	rdrx	; check whether there is another character in the buffer
 	  end_if
	  if_f_ge_l	BUFRD2,'a'	; make upper case
	   if_f_le_l	BUFRD2,'z'
	    sub_f_l_f	BUFRD2,.32,BUFRD2
	   end_if
	  end_if
   	  add_f_l_f	cmdbfl, cmdbf0, cmdbfad ; set index of buffer (l explicit)
   	  load_i_f	cmdbfad, BUFRD2
   	  if_f_lt_l	cmdbfl, .15 	; buffer full?
    	    incfb	cmdbfl,f
   	  end_if
	  gotop	rdrx	; check whether there is another character in the buffer
	end_if
	; also check for time out
; DEBUG
	if_f_gt_l	rcv_timer, .240	; 3000 ms
	  clrfb	rcv_timer
	  if_f_ne_l	cmdbfl, 0	; and buffer not empty
	    gotop	lpparse
	  end_if
	end_if
	gotop	mainloop

lpparse	banklabel
	callp	cmdparse
	gotop	mainloop

; *** PARSER ***
; parses command buffer
cmdparse: 
	banklabel
	load_f_l	cmda1,.0
	if_f_eq_l	cmdbfl,.0 	; is command zero characters long? Then eg CR: skip
	 gotop	cmd_clrbf	; jump to end
	end_if
	if_f_lt_l	cmdbfl,.3 	; is command at least 3 characters long?
	 gotop	cmd_err	; error
	end_if
	if_f_ne_l	cmdbf1,' '	; if second character not a space: error
	 gotop	cmd_err	; error
	end_if
	if_f_eq_l	cmdbf0, 'W' 	; [W]rite command
	 load_f_l	cmda1,.1
 	 gotop	cmd_arg2	; goto parse second argument
	end_if 
	if_f_eq_l	cmdbf0, 'R' 	; [R]ead command
	 load_f_l	cmda1,.2
 	 gotop	cmd_arg2	; goto parse second argument
	end_if 
	if_f_eq_l	cmdbf0, 'S' 	; [S]et config
	 load_f_l	cmda1,.3
 	 gotop	cmd_arg2	; goto parse second argument
	end_if 
	if_f_eq_l	cmdbf0, 'G' 	; [G]et config
	 load_f_l	cmda1,.4
 	 gotop	cmd_arg2	; goto parse second argument
	end_if 
cmd_err: 	banklabel
	; error
	if_f_b_c	Stat_Z0,1	; Error message depending on Z0:1 setting
	 load_f16_l16	TEXT_POS,TXT_LParseError
	 callp	write_text	
	end_if
cmd_clrbf:	banklabel
	; clear command buffer by setting pointer (length) to zero
	load_f_l	cmdbfl, 0
	return

; First command parsed OK, now second part: pin A00 - Z
cmd_arg2:	
	banklabel
	; first character
	load_f_l	cmda2,0xFF
	load_f_l	cmda2+1,.0	
	; first character A, B, C
	if_f_ge_l	cmdbf2,'A'	; if first character of pin is A .. C
	ifndef	PIN40
	 if_f_le_l	cmdbf2,'C'
	else
	 if_f_le_l	cmdbf2,'E'
	endif
	  sub_f_l_f	cmdbf2,'A',cmda2
	  bankset	cmda2
	  lslf	cmda2,f
	  lslf	cmda2,f
	  lslf	cmda2,f
	  bankres	cmda2
	  ; second character
	  if_f_lt_l	cmdbfl,.4	; no second character in second argument
	   gotop	cmd_err	; error
	  end_if
	  if_f_lt_l	cmdbf3,'0'	; pin number should be between 0 and 7
	   gotop	cmd_err	; error
	  end_if
	  if_f_gt_l	cmdbf3,'7'
	   gotop	cmd_err	; error
	  end_if
	  add_f_f_f	cmda2,cmdbf3,cmda2	; calculate pin number
	  sub_f_l_f	cmda2,.48,cmda2
	  ; third character
	  if_f_lt_l	cmdbfl,.5	; no third character in second argument
	   load_f_l	nofargs,.2
	   gotop	cmd_exec	; finished parsing; execute command 
	  end_if
	  if_f_eq_l	cmdbf4,' '	; single digit followed by space: goto parse third argument
	   load_f_l	cmdppos,.4
	   gotop	cmd_arg3	; analyse third argument
	  end_if
	  if_f_lt_l	cmdbf4,'0'	; pin number should be between 0 and 3
	   gotop	cmd_err	; error
	  end_if
	  if_f_gt_l	cmdbf4,'3'
	   gotop	cmd_err	; error
	  end_if
	  sub_f_l_f	cmdbf4,.48,cmda2+1
	  load_f_l	cmdppos,.5
	  gotop	cmd_arg3	; analyse third argument
	 end_if
	end_if
	; first character X, Y, Z
	if_f_ge_l	cmdbf2,'S'	; if first character of pin is S .. Z
	 if_f_le_l	cmdbf2,'Z'
	  sub_f_l_f	cmdbf2,'S'-.40,cmda2	; S on .40 (0x28), ..., Z on .47 (0x2F)
	  ; second character
	  if_f_lt_l	cmdbfl,.4	; no second character in second argument
	   load_f_l	nofargs,.2
	   gotop	cmd_exec	; finished parsing; execute command 
	  end_if
	  if_f_eq_l	cmdbf3,' '	; no subpin number -> 0
	   load_f_l	cmda2+1,.0
	   load_f_l	cmdppos,.3
	   gotop	cmd_arg3	; analyse third argument
	  end_if
	  if_f_lt_l	cmdbf3,'0'	; pin number should be between 0 and 3
	   gotop	cmd_err	; error
	  end_if
	  if_f_gt_l	cmdbf3,'3'
	   gotop	cmd_err	; error
	  end_if
	  sub_f_l_f	cmdbf3,.48,cmda2+1
	  load_f_l	cmdppos,.4
	  gotop	cmd_arg3	; analyse third argument
	 end_if
	end_if
	gotop	cmd_err	; error , no A, B, C, X, Y, or Z

cmd_arg3: 	banklabel
	; checks argument 3 of command buffer
	load_f16_l16	cmda3,.0
	if_f_le_f	cmdbfl, cmdppos	; end of buffer?
	 load_f_l	nofargs,.2
	 gotop	cmd_exec	; finished parsing; execute command
	end_if
	add_l_f_f 	cmdbf0,cmdppos,cmdbfad ; real address in buf
	load_f_i 	cmdtmp, cmdbfad
	if_f_ne_l	cmdtmp,' '	; no space -> error
	  gotop cmd_err
	end_if
	inc_f	cmdppos
	while_f_lt_f	cmdppos, cmdbfl
	 inc_f	cmdbfad
	 load_f_i 	cmdtmp, cmdbfad
	 if_f_eq_l	cmdtmp,' '	; if space, then argument4
	  gotop	cmd_arg4
	 end_if
	 if_f_lt_l	cmdtmp,'0'	; number should be between 0 and 9
	  gotop	cmd_err	; error
	 end_if
	 if_f_gt_l	cmdtmp,'9'
	  gotop	cmd_err	; error
	 end_if
	 	
	 mul10_f16_f16 cmda3,cmda3 	; now shift arg3 x10, add next number
	 sub_f_l_f 	cmdtmp,.48,cmdtmp
	 load_f_l	cmdtmp+1,.0
	 add_f16_f16_f16 cmda3, cmdtmp, cmda3
	 inc_f	cmdppos
	end_while
	load_f_l	nofargs,.3
	gotop	cmd_exec	; finished parsing; execute command 
 
cmd_arg4: 	banklabel
	; checks argument 4 of command buffer
	load_f16_l16	cmda4,.0
	add_l_f_f 	cmdbf0,cmdppos,cmdbfad ; real address in buf
	inc_f	cmdppos
	while_f_lt_f	cmdppos, cmdbfl
	 inc_f	cmdbfad
	 load_f_i 	cmdtmp, cmdbfad
	 if_f_lt_l	cmdtmp,'0'	; number should be between 0 and 9
	  gotop	cmd_err	; error
	 end_if
	 if_f_gt_l	cmdtmp,'9'
	  gotop	cmd_err	; error
	 end_if
	 	
	 mul10_f16_f16 cmda4,cmda4 	; now shift arg3 x10, add next number
	 sub_f_l_f 	cmdtmp,.48,cmdtmp
	 load_f_l	cmdtmp+1,.0
	 add_f16_f16_f16 cmda4, cmdtmp, cmda4
	 inc_f	cmdppos
	end_while
	load_f_l	nofargs,.4
	gotop	cmd_exec	; finished parsing; execute command 
 

; *** Now execute the parsed command
cmd_exec:
	banklabel
	; clear command buffer by setting pointer (length) to zero
	load_f_l	cmdbfl, 0
cmd_exec_nocmdln:
	banklabel
	if_f_eq_l	cmda1,.1	; WRITE COMMAND
	 ; if nofparams <3 then error  
	 ; if A0..C7 (0..23):
	  ;   if status(pin)=input: nothing
	  ;   if status(pin)=output: write bit to pin
	  ;   if status(pin)=ADC: nothing
	  ;   if status(pin)=CPS: nothing
	  ;   if status(pin)=PWM -> write value to RAM location
	  ;   if status(pin)=Special -> jump to special routines
	 ; if X .. Z (41..48): nothing
	 if_f_eq_l	cmda2,.16	; C0
	  if_f_eq_l	Stat_C0,.6	; counter
	   load_f_f	TMR1L, cmda3
	   load_f_f	TMR1H, (cmda3+1)
	  end_if
	 end_if
	 if_f_le_l	cmda2,.21
	  load_f_f	BTP,cmda2
	  callp	get_pinstatus
	  if_f_eq_l	BTC,.2	; output
	   load_f_f	tmp2,cmda2	; get bit 4 from PP1 (latch mode?)
	   lslfb	tmp2,f
	   lslfb	tmp2,f
	   incfb	tmp2,f	; status-1
	   load_f_bk_li	ADCref,.3,tmp2	; use temporary ADCref for PP1
	   if_f_b_s	ADCref, .4	; latch mode
	    callp	write_latch
	   else_
	    if_f_b_s	cmda3,0
	     bsfBTP_f	LATA
	    else_
	     bcfBTP_f	LATA
	    end_if
	   end_if
	   gotop	writecexitlog
	  end_if
	  if_f_eq_l	BTC,.5	; PWM
	   load_w_f	BTP	; set variable in RAM bank 2
	   lslf	WREG,f
	   load_f_w	tmp2
	   load_bk_li_f	.2,tmp2,cmda3
	   incfb	tmp2,f
	   load_bk_li_f	.2,tmp2,cmda3+1
	   gotop	writecexitlog
	  end_if
	 end_if	
	end_if
writecexit
	banklabel
	if_f_eq_l	cmda1,.2	; READ COMMAND
	 ; if A0..C7 (0..23):
	  ;   if status(pin)=input or output -> get pin bit  -> return value
	  ;   if status(pin)=ADC -> read ADC -> return value
	  ;   if status(pin)=CPS -> read CPS counter (set by interrupt) -> return value
	  ;   if status(pin)=PWM -> read PWM setting -> return value
	  ;   if status(pin)=Special -> jump to special routines
	 ; if X .. Z (41..48): nothing
	 if_f_eq_l	cmda2,.16	; C0
	  if_f_eq_l	Stat_C0,.6	; special function timer
	   callp	read_C0
	   gotop	readcexit
	  end_if
	 end_if
	#ifdef	include_datalogger
	 if_f_eq_l	cmda2,.19	; C3
	  if_f_eq_l	Stat_C3,.6	; special function i2c
	   if_f_le_l	nofargs,.2
	    load_f16_l16	cmda3,.0
	   end_if
	   callp	read_C3
	   gotop	readcexit
	  end_if
	 end_if
	 if_f_eq_l	cmda2,.20	; C4
	  if_f_eq_l	Stat_C4,.6	; special function i2c
	   write_char	'R'		; write out
	   write_char	' '
	   write_char	'C'
	   write_char	'4'
	   write_char	' '
	   load_f_f	txt_int, dlog_stat	
	   callp	write_hex_txtint_8	; status
	   write_char	' '
	   load_f16_f16	txt_int, dlog_posblock	; load posblocks
	   callp	write_hex_txtint_16	; blockpos
	   write_char	' '
	   load_f_f	txt_int, dlog_pos	
	   callp	write_hex_txtint_8	; pos
	   write_char	' '
	   load_f_f	BUFWRT1, dlog_posbit	
	   callp	write_hex_n		; posbit
	   write_char	' '
	   load_f16_f16	txt_int, dlog_mcountdown	
	   callp	write_hex_txtint_16	; measurements countdown
	   write_char	' '
	   load_f32_f32	txt_int, dlog_mscountdown	
	   callp	write_hex_txtint_32	; ms countdown
	   write_char	.10
	   gotop	readcexit		; and jump to end
	  end_if
	 end_if
	#endif	; include_datalogger
	 if_f_lt_l	cmda2,.22	; pins
	  load_f_f	BTP,cmda2
	  callp	get_pinstatus
	  if_f_eq_l	BTC,.0	; input
	   gotop	cex1
	  end_if
	  if_f_eq_l	BTC,.1	; input
	   gotop	cex1
	  end_if
	  if_f_eq_l	BTC,.2	; (output) read input
cex1:	banklabel
	    load_f_f	tmp2,cmda2	; get bit 4 from PP1 (latch mode?)
	    lslfb	tmp2,f
	    lslfb	tmp2,f
	    incfb	tmp2,f	; status-1
	    load_f_bk_li	ADCref,.3,tmp2	; use temporary ADCref for PP1
	    if_f_b_s	ADCref, .4	; latch mode
	     gt_BTP_f	PORTA, txt_int
	     clr_f	(txt_int+1)
	    else_
	     ; ADDED FOR PULS LENGTH
	     pulse_read    .10, Stat_B2	; check whether puls length measurement
	     bgfBTP_f	PORTA
	     if_f_b_c	BTS,0
	      load_f16_l16	txt_int, .0
	     else_
	      load_f16_l16	txt_int, .1
	     end_if
	    end_if
	   if_f_b_c	cmdstat,0	; text or internal output
	    write_char	'R'
	    write_char	' '
	    callp	write_BTP
	    write_char	' '
	    callp	write_dec_txtint_8_lf
	   end_if
	  end_if
	  if_f_eq_l	BTC,.3	; ADC
	   load_f_f	BTP,cmda2	; get ADC number
	   callp	get_pintoADC
	   if_f_b_c	BTC,7	; valid ADC channel
	    if_f_b_c	cmdstat,0	; text or internal output
	     write_char	'R'
	     write_char	' '
	     callp	write_BTP
	     write_char	' '
	    end_if
	    load_f_f	tmp2,cmda2	; get multple readings from PP2
	    lslfb	tmp2,f
	    lslfb	tmp2,f
	    incfb	tmp2,f	; status-1
	    load_f_bk_li	ADCref,.3,tmp2
	    incfb	tmp2,f	; status-2
	    load_f_bk_li	ADCmult,.3,tmp2
	    callp	read_ADC	; read ADC and result in txt_int:16
	    if_f_b_c	cmdstat,0	; text or internal output
	     callp	write_dec_txtint_16_lf
	    end_if
	   end_if
	  end_if
	  if_f_eq_l	BTC,.4	; CPS
	   gotop	cex2
	  end_if
	  if_f_eq_l	BTC,.5	; PWM
cex2:	banklabel
	   if_f_b_c	cmdstat,0	; text or internal output
	    write_char	'R'
	    write_char	' '
	    callp	write_BTP
	    write_char	' '
	   end_if
	   load_w_f	BTP	; read variable in RAM bank 2
	   lslf	WREG,f
	   load_f_w	tmp2
	   load_f_bk_li	txt_int,.2,tmp2
	   incfb	tmp2,f
	   load_f_bk_li	(txt_int+1),.2,tmp2
	   if_f_b_c	cmdstat,0	; text or internal output
	    callp	write_dec_txtint_16_lf
	   end_if
	  end_if

	 end_if
	end_if
readcexit
	banklabel
	if_f_eq_l	cmda1,.3	; SET COMMAND
	 ; First check whethet pin functions are blocked (Z0:0)
	 if_f_b_s	Stat_Z0,0
	  gotoif_f_le_l	cmda2,.39,setcexit
	 end_if
	 ; FIRST SPECIAL FUNCTIONS AND SPECIAL FUNCTIONS BEFORE SET
	#ifdef	include_datalogger
	 if_f_eq_l	cmda2,.19	; C3
	  if_f_eq_l	Stat_C3,.6	; Disable i2c and digital ports C3 and C4 if no i2c anymore
	   if_f_ne_l	cmda3,.6
	    callp	i2c_stop	; digital port C3 and C4
	   end_if	
	  end_if
	 end_if
	 if_f_eq_l	cmda2,.20	; C4
	  if_f_eq_l	Stat_C4,.6	; Disable i2c and digital ports C3 and C4 if no i2c anymore
	   if_f_ne_l	cmda3,.6
	    callp	i2c_stop	; digital port C3 and C4
	   end_if	
	  end_if
	 end_if
	#endif	; include_datalogger
	 if_f_eq_l	cmda2,.45	; X
	  if_f_eq_l	(cmda2+1), .1	; X1
	   clr_f16	CNT_ms	; reset mscounter
	  end_if
	 end_if
	 if_f_eq_l	cmda2,.47	; Z
	  if_f_eq_l	(cmda2+1), .3	; Z3
	   gotop	getz3	; junmp to the Z3 in get
	  end_if
	 end_if
	  ; if A0..C7 (arg2: 0..23, arg2+1=0): set_pinfunction
	  ; if A01..C73 (arg2: 0..23, arg2+1>0): save to RAM
	  ; if S0.. Z3 (arg2: 40..47, all arg2+1): save to RAM
	 if_f_lt_l	cmda2,.22
	  if_f_eq_l	cmda2+1,.0
	   load_f_f	BTP, cmda2	; pin number
	   load_f_f	BTC, cmda3	; pin function
	   callp	set_pinfunction_a4	
	  end_if
	 end_if
	 load_w_f	cmda2	; calculate RAM position for both A01..C73 and S..Z
	 lslf	WREG,f
	 lslf	WREG,f
	 addwfb	(cmda2+1),w
	 load_f_w	tmp2
	 load_bk_li_f	.3,tmp2,cmda3
	 callp	setclog
	 ; SPECIAL FUNCTIONS AFTER SET
	 if_f_eq_l	Stat_C0,.6	; Timer 1?	
	  if_f_eq_l	cmda2,.16	; C0-C03
	   callp	start_timer1
	  end_if
	 end_if
	#ifdef	include_datalogger
	 if_f_eq_l	cmda2,.19	; C3
	  if_f_eq_l	Stat_C3,.6	
	   load_f_l	Stat_C4,.6	
	   callp	i2c_init
	  end_if
	 end_if
	 if_f_eq_l	cmda2,.20	; C4
	  if_f_ne_l	Stat_C4,.6	
	   if_f_eq_l	Stat_C3,.6	
	    load_f_l	Stat_C3,.0
	   end_if
	  end_if
	 end_if
	 if_f_eq_l	cmda2,.40	; S
	  if_f_eq_l	(cmda2+1), .3	; S3
	   callp	set_S3
	  end_if
	 end_if
	#endif	; include_datalogger
	 if_f_eq_l	cmda2,.47	; Z
	  if_f_eq_l	(cmda2+1), .0	; Z0
	   callp	set_Z0
	  end_if
	  if_f_eq_l	(cmda2+1), .2	; Z2
	   callp	set_Z2
	  end_if
	 end_if
	end_if ; SET
setcexit
	banklabel
	if_f_eq_l	cmda1,.4	; GET COMMAND
	 ; FIRST SPECIAL FUNCTIONS
	 if_f_eq_l	cmda2,.47	; Z
	  if_f_eq_l	(cmda2+1), .3	; Z3
getz3	banklabel
	   if_f_eq_l	cmda3,.01	; Z3 = 01: Set settings on default values
	    callp	set_Z3_default
	    gotop	z3cexitlog
	   end_if
	   if_f_eq_l	cmda3,.02	; Z3 = 02: Save settings to EEPROM
	    callp	set_Z3_save
	    gotop	z3cexitlog
	   end_if
	   if_f_eq_l	cmda3,.03	; Z3 = 03: Load settings form EEPROM
	    callp	set_Z3_load
	    gotop	z3cexitlog
	   end_if
	   if_f_eq_l	cmda3,.04	; Z3 = 04: Read EEPROM
	    callp	get_Z3_eeprom
	    gotop	getcexit
	   end_if
	   if_f_eq_l	cmda3,.05	; Z3 = 05: Erase EEPROM
	    callp	set_Z3_erase
	    gotop	z3cexitlog
	   end_if
	   if_f_eq_l	cmda3,.10	; Z3 = 10: Read PIC version number (HEX format)
	    callp	get_Z3_version
	    gotop	getcexit
	   end_if
	   if_f_eq_l	cmda3,.11	; Z3 = 11: Read PIC version number (text)
	    callp	get_Z3_version_text
	    gotop	getcexit
	   end_if
	   if_f_eq_l	cmda3,.12	; Z3 = 12: Read interrupt overflow (decimal)
	    callp	get_Z3_intoverflow
	    gotop	getcexit
	   end_if
	   if_f_eq_l	cmda3,.13	; Z3 = 13: Read interrupt overflow (text)
	    callp	get_Z3_intoverflow_text
	    gotop	getcexit
	   end_if
	   if_f_eq_l	cmda3,.20	; Z3 = 20: Reset controller (through bootloader)
	    callp	set_Z3_reset
	    gotop	z3cexitlog
	   end_if
	   if_f_eq_l	cmda3,.21	; Z3 = 21: Jump to bootloader (even without jumper)
	    callp	set_Z3_bootloader
	    gotop	z3cexitlog
	   end_if
	   if_f_eq_l	cmda3,.30	; Z3 = 30: Password
	    callp	get_Z3_password
	    gotop	z3cexitlog
	   end_if
	  end_if
	 end_if
	 ; in all cases: return value from RAM
	 write_char	'G'
	 write_char	' '
	 load_f_f	BTP, cmda2	; pin number
	 callp	write_BTP
	 load_w_f	(cmda2+1)
	 addlw	'0'
	 load_f_w	BUFWRT1
	 callp	bufwritewait1	; write to TX buffer
	 write_char	' '
	 load_w_f	BTP	; calculate RAM position for both A01..C73 and S..Z
	 lslf	WREG,f
	 lslf	WREG,f
	 addwfb	(cmda2+1),w
	 load_f_w	tmp2
	 load_f_bk_li	txt_int,.3,tmp2
	 ;incfb	tmp2,f
	 ;load_f_bk_li	(txt_int+1),.3,tmp2
	 callp	write_dec_txtint_8_lf
	end_if
getcexit
	banklabel
	return

; Functions for debug logging
writecexitlog
	banklabel
	if_f_b_c	Stat_Z0,1	; OK message depending on Z0:1 setting
	 load_f16_l16	TEXT_POS,TXT_LWOK
	 callp	write_text	
	end_if
	gotop	writecexit

setcexitlog
	banklabel
	callp	setclog
	gotop	setcexit

z3cexitlog
	banklabel
	if_f_b_c	Stat_Z0,1	; OK message depending on Z0:1 setting
	 load_f16_l16	TEXT_POS,TXT_LZ3OK
	 callp	write_text	
	end_if
	gotop	getcexit

setclog
	banklabel
	if_f_b_c	Stat_Z0,1	; OK message depending on Z0:1 setting
	 load_f16_l16	TEXT_POS,TXT_LSOK
	 callp	write_text	
	end_if
	return

; clear_pinfunctions - put all pins in impediance high mode, and settings on '0'	
clear_pinfunctions	
	banklabel
	for_f_l_l	tmp1, .4*.40, .4*.48-.1
	 load_bk_li_l	.3,tmp1,.0
	next_f	tmp1 
	for_f_l_l	tmp1, .0, .21
	  load_f_f	BTP, tmp1
	  load_f_l	BTC,.0	; function 0
	  callp	set_pinfunction
	next_f	tmp1
	ifdef	PIN40
	for_f_l_l	tmp1, .24, .39	; skip C6 and C7 (Uart)
	  load_f_f	BTP, tmp1
	  load_f_l	BTC,.0	; function 0
	  callp	set_pinfunction
	next_f	tmp1
	endif	
	return

; set_pinfunction - set function of pin in BTP with the function in BTC (and checkes whether allowed)
; set_pinfunctiona4 - same, but sets the output with variable in cmda4       
;                     e.g. BTP=.10, BTC=2: set B2 as output
set_pinfunction_a4
	banklabel
	bsfb	BTS,7	; indicate to set an outputvalue (in cmda4)
	gotop	spf_1
set_pinfunction
	banklabel
	bcfb	BTS,7	; indicate not to set an outputvalue
spf_1	banklabel
	callp	get_allowedpinfunctions
	if_f_eq_l	BTC,.0	; input high impediance (no WPU)
	  gotoif_f_b_c	BTA,0, spf_notallowed
	  callp	setandclear_pinconfig
	  bcfBTP_f	(WPUB-1)  	; no WPU (writing to WPUA is no problem)
	  bsfBTP_f	TRISA  	; input
	  bcfBTP_f	ANSELA  	; digital (writing to ANSELC is no problem)
	end_if
	if_f_eq_l	BTC,.1	; input with WPU
	  gotoif_f_b_c	BTA,1, spf_notallowed
	  callp	setandclear_pinconfig
	  bsfBTP_f	(WPUB-1)  	; WPU (writing to WPUA is no problem)
	  bsfBTP_f	TRISA  	; input
	  bcfBTP_f	ANSELA  	; digital (writing to ANSELC is no problem)
	end_if
	if_f_eq_l	BTC,.2	; output
	  gotoif_f_b_c	BTA,2, spf_notallowed
	  callp	setandclear_pinconfig
	  if_f_b_s	BTS,7	; if argument 4 
	   if_f_b_s	cmda4,0
	    bsfBTP_f	LATA  	; set output high
	   else_
	    bcfBTP_f	LATA  	; set output low
	   end_if
	  else_		; else set 0 as default
	   bcfBTP_f	LATA  	; set output low
	  end_if
	  bcfBTP_f	(WPUB-1)  	; no WPU (writing to WPUA is no problem)
	  bcfBTP_f	TRISA  	; output
	  bcfBTP_f	ANSELA  	; digital (writing to ANSELC is no problem)
	end_if
	if_f_eq_l	BTC,.3	; ADC
	  gotoif_f_b_c	BTA,3, spf_notallowed
	  callp	setandclear_pinconfig
	  bcfBTP_f	(WPUB-1)  	; no WPU (writing to WPUA is no problem)
	  bsfBTP_f	TRISA  	; input
	  bsfBTP_f	ANSELA  	; analog (writing to ANSELC is no problem)
	end_if
	if_f_eq_l	BTC,.4	; CPS
	  gotoif_f_b_c	BTA,4, spf_notallowed
	  callp	setandclear_pinconfig
	  bcfBTP_f	(WPUB-1)  	; no WPU (writing to WPUA is no problem)
	  bsfBTP_f	TRISA  	; input
	  bsfBTP_f	ANSELA  	; analog (writing to ANSELC is no problem)
	end_if
	if_f_eq_l	BTC,.5	; PWM
	  gotoif_f_b_c	BTA,5, spf_notallowed
	  callp	setandclear_pinconfig
	  if_f_b_s	BTS,7	; set cama4?
	   load_w_f	BTP	; set variable in RAM bank 2
	   lslf	WREG,f
	   load_f_w	tmp2
	   load_bk_li_f	.2,tmp2,cmda4
	   incfb	tmp2,f
	   load_bk_li_f	.2,tmp2,cmda4+1
	  else_		; else set PWM value to zero
	   lslf	WREG,f
	   load_f_w	tmp2
	   load_bk_li_l	.2,tmp2,.0
	   incfb	tmp2,f
	   load_bk_li_l	.2,tmp2,.0
	  end_if
	  callp	setandclear_pinconfig
	  bcfBTP_f	(WPUB-1)  	; no WPU (writing to WPUA is no problem)
	  bcfBTP_f	TRISA  	; output
	  bcfBTP_f	ANSELA  	; digital (writing to ANSELC is no problem)
	end_if
	if_f_eq_l	BTC,.6	; Timer
	  gotoif_f_b_c	BTA,6, spf_notallowed
	  callp	setandclear_pinconfig
	  bcfBTP_f	(WPUB-1)  	; no WPU (writing to WPUA is no problem)
	  bsfBTP_f	TRISA  	; input
	  bcfBTP_f	ANSELA  	; digital (writing to ANSELC is no problem)
	end_if
	return
spf_notallowed
	banklabel
	return

; setandclear_pinconfig - clear RAM values 1, 2, 3 and set RAM value 0 (function)
setandclear_pinconfig
	banklabel
	load_w_f	BTP
	lslf	WREG,f
	lslf	WREG,f
	load_f_w	tmp2
	load_bk_li_f	.3,tmp2,BTC
	incfb	tmp2,f
	load_bk_li_l	.3,tmp2,.0
	incfb	tmp2,f
	load_bk_li_l	.3,tmp2,.0
	incfb	tmp2,f
	load_bk_li_l	.3,tmp2,.0
	return

; get_pinstatus - get RAM value 0 (function) (into BTC) of pin BTP
get_pinstatus
	banklabel
	load_w_f	BTP
	lslf	WREG,f
	lslf	WREG,f
	load_f_w	tmp2
	load_f_bk_li	BTC,.3,tmp2
	return

; pin_to_BT - split pin number BTP in byte and bit; add byte to BTF and set bit in BTB
;               e.g. pin number 10 = B2 -> add 1 to BTF and set 2 in BTB  
pin_to_BT
	banklabel
	load_w_f	BTP
	lsrf	WREG,f
	lsrf	WREG,f
	lsrf	WREG,f
	addwf	BTF,f
	skpnc	
	incf	BTF+1,f
	load_w_f	BTP
	andlw	0x07
	load_f_w	BTB
	return	

; write_BTP - convert pin number to text (eg B3) and write to TX (buffer)
write_BTP
	banklabel
	if_f_lt_l	BTP,.40	; if A0..E7
	 load_w_f	BTP	; first the port character
	 andlw	0x38
	 lsrf	WREG,f
	 lsrf	WREG,f
	 lsrf	WREG,f
	 addlw	'A'
	 load_f_w	BUFWRT1
	 callp	bufwritewait1	; write to TX buffer
	 load_w_f	BTP	; then port number
	 andlw	0x07
	 addlw	'0'
	 load_f_w	BUFWRT1
	 callp	bufwritewait1	; write to TX buffer
	else_		; S..Z
	 load_w_f	BTP	; first the port character
	 andlw	0x3F
	 addlw	'S'-.40
	 load_f_w	BUFWRT1
	 callp	bufwritewait1	; write to TX buffer
	end_if
	return

; writes value of txt_int (8 bit) as decimal to tx buffer
write_dec_txtint_8:
	banklabel
	load_f_l	wrtargt2,.0 ; leading zero 
	subdivr_f_l_f_f	txt_int, .100, wrtargt1, txt_int
	if_f_ne_l	wrtargt1,.0
 	 load_f_l	wrtargt2,.1 ; no more in leading zero 
	end_if
	if_f_ne_l 	wrtargt2,.0 ; no more in leading
  	 add_f_l_f 	wrtargt1,.48,BUFWRT1
	 callp	bufwritewait1	; write to TX buffer	
	end_if

	subdivr_f_l_f_f 	txt_int, .10, wrtargt1, txt_int
	if_f_ne_l 	wrtargt1,.0
 	 load_f_l 	wrtargt2,.1 ; no more in leading zero 
	end_if
	if_f_ne_l 	wrtargt2,.0 ; no more in leading
  	 add_f_l_f 	wrtargt1,.48,BUFWRT1
	 callp	bufwritewait1	; write to TX buffer	
	end_if

	add_f_l_f 	txt_int,.48,BUFWRT1   ; and last digit
	callp	bufwritewait1	; write to TX buffer
	return

; writes value of txt_int (8 bit) as decimal to tx buffer, with two digits (including zero)
write_dec2_txtint_8:
	banklabel
	subdivr_f_l_f_f 	txt_int, .10, wrtargt1, txt_int
  	add_f_l_f 	wrtargt1,.48,BUFWRT1
	callp	bufwritewait1		; write to TX buffer	
	add_f_l_f 	txt_int,.48,BUFWRT1   	; and last digit
	callp	bufwritewait1		; write to TX buffer
	return

; writes value of txt_int (16 bit) as decimal to tx buffer 
write_dec_txtint_16:
	banklabel
	load_f_l	wrtargt2,.0 ; leading zero 

	subdivr_f16_l16_f16_f16	txt_int, .10000, wrtargt1, txt_int
	if_f_ne_l	wrtargt1,.0		; only first 8 bit
 	 load_f_l	wrtargt2,.1 ; no more in leading zero 
	end_if
	if_f_ne_l 	wrtargt2,.0 ; no more in leading
  	 add_f_l_f 	wrtargt1,.48,BUFWRT1	; only first 8 bit
	 callp	bufwritewait1	; write to TX buffer	
	end_if

	subdivr_f16_l16_f16_f16	txt_int, .1000, wrtargt1, txt_int
	if_f_ne_l	wrtargt1,.0		; only first 8 bit
 	 load_f_l	wrtargt2,.1 ; no more in leading zero 
	end_if
	if_f_ne_l 	wrtargt2,.0 ; no more in leading
  	 add_f_l_f 	wrtargt1,.48,BUFWRT1	; only first 8 bit
	 callp	bufwritewait1	; write to TX buffer	
	end_if

	subdivr_f16_l16_f16_f16	txt_int, .100, wrtargt1, txt_int
	if_f_ne_l	wrtargt1,.0		; only first 8 bit
 	 load_f_l	wrtargt2,.1 ; no more in leading zero 
	end_if
	if_f_ne_l 	wrtargt2,.0 ; no more in leading
  	 add_f_l_f 	wrtargt1,.48,BUFWRT1	; only first 8 bit
	 callp	bufwritewait1	; write to TX buffer	
	end_if

	subdivr_f16_l16_f16_f16	txt_int, .10, wrtargt1, txt_int
	if_f_ne_l	wrtargt1,.0		; only first 8 bit
 	 load_f_l	wrtargt2,.1 ; no more in leading zero 
	end_if
	if_f_ne_l 	wrtargt2,.0 ; no more in leading
  	 add_f_l_f 	wrtargt1,.48,BUFWRT1	; only first 8 bit
	 callp	bufwritewait1	; write to TX buffer	
	end_if

	add_f_l_f 	txt_int,.48,BUFWRT1   ; and last digit
	callp	bufwritewait1	; write to TX buffer
	;callp	write_lf	
	return

; writes value of txt_int (8 bit) as heximal to tx buffer
write_hex_txtint_8:
	banklabel
	load_f_f	BUFWRT1, txt_int
	swapfb	BUFWRT1, f
	callp	write_hex_n	; write first char
	load_f_f	BUFWRT1, txt_int
	callp	write_hex_n	; write second char
	return

; writes value of txt_int (16 bit) as heximal to tx buffer
write_hex_txtint_16:
	banklabel
	load_f_f	BUFWRT1, (txt_int+1)	; second byte
	swapfb	BUFWRT1, f
	callp	write_hex_n		; write first char
	load_f_f	BUFWRT1, (txt_int+1)
	callp	write_hex_n		; write second char
	load_f_f	BUFWRT1, txt_int	; first byte
	swapfb	BUFWRT1, f
	callp	write_hex_n		; write first char
	load_f_f	BUFWRT1, txt_int
	callp	write_hex_n		; write second char
	return

; writes value of txt_int (32 bit) as heximal to tx buffer
write_hex_txtint_32:
	banklabel
	load_f_f	BUFWRT1, (txt_int+3)	; fourth byte
	swapfb	BUFWRT1, f
	callp	write_hex_n		; write first char
	load_f_f	BUFWRT1, (txt_int+3)
	callp	write_hex_n		; write second char
	load_f_f	BUFWRT1, (txt_int+2)	; second byte
	swapfb	BUFWRT1, f
	callp	write_hex_n		; write first char
	load_f_f	BUFWRT1, (txt_int+2)
	callp	write_hex_n		; write second char
	load_f_f	BUFWRT1, (txt_int+1)	; second byte
	swapfb	BUFWRT1, f
	callp	write_hex_n		; write first char
	load_f_f	BUFWRT1, (txt_int+1)
	callp	write_hex_n		; write second char
	load_f_f	BUFWRT1, txt_int	; first byte
	swapfb	BUFWRT1, f
	callp	write_hex_n		; write first char
	load_f_f	BUFWRT1, txt_int
	callp	write_hex_n		; write second char
	return

write_hex_n:
	banklabel
	movlw	0x0F
	andwfb	BUFWRT1, f
	if_f_gt_l	BUFWRT1, .9
	 movlw	0x37
	 addwfb	BUFWRT1, f
	else_
	 movlw	0x30
	 iorwfb	BUFWRT1, f
	end_if
	callp	bufwritewait1	; write to TX buffer
	return

; writes value of txt_int (16 bit) as decimal to tx buffer + linefeed
write_dec_txtint_16_lf:
	banklabel
	callp	write_dec_txtint_16
	callp	write_lf
	return

; writes value of txt_int (8 bit) as decimal to tx buffer + linefeed
write_dec_txtint_8_lf:
	banklabel
	callp	write_dec_txtint_8
	callp	write_lf
	return

; writes value of txt_int (16 bit) as heximal to tx buffer + linefeed
write_hex_txtint_16_lf:
	banklabel
	callp	write_hex_txtint_16
	callp	write_lf
	return

; writes value of txt_int (8 bit) as heximal to tx buffer + linefeed
write_hex_txtint_8_lf:
	banklabel
	callp	write_hex_txtint_8
	callp	write_lf
	return


read_ADC:
	banklabel
	clr_f16	txt_int
	load_f_f	tmp2, ADCmult
	#ifndef	ADC_workaround
	if_f_b_c	ADCref,0	; Reference voltage?
	 load_f_l	ADCON1, b'11110000' ;Right justify, Frc, Vdd and Vss Vref
	else_
	 load_f_l	ADCON1, b'11110011' ;Right justify, Frc, 2.048V and Vss Vref
	end_if
	#else	; for ADC workaround
	if_f_b_c	ADCref,0	; Reference voltage?
	 load_f_l	ADCON1, b'10100000' ;Right justify, Fosc/32, Vdd and Vss Vref
	else_
	 load_f_l	ADCON1, b'10100011' ;Right justify, Fosc/32, 2.048V and Vss Vref
	end_if
	#endif
	load_w_f	BTAC	; set ADC channel
	lslf	WREG,w
	lslf	WREG,w
	bsf	WREG, 0	; turn ADC on
	load_f_w	ADCON0
	; wait 4.5 us
	for_f_l_l	tmp1, .0, .0
	  nop
	next_f	tmp1
	; ready to start
radc1	banklabel
	#ifndef	ADC_workaround
	bsfb	ADCON0,ADGO 	; Start conversion
	repeat
	until_f_b_c	ADCON0,ADGO 	; Is conversion done?
	#else	; Workaround three for error in A1 and A2
	bcf	INTCON,7	; disable interrupt
	bankset	ADCON0
	BSF	ADCON0, ADGO ; Start ADC conversion 
	; Provide 86 instruction cycle delay here
	callp	nopdeladc
	callp	nopdeladc
	callp	nopdeladc
	callp	nopdeladc
	callp	nopdeladc
	callp	nopdeladc
	callp	nopdeladc
	nop
	nop
	BCF	ADCON0, ADGO ; Terminate the conversion manually
	bankres	ADCON0
	bsf	INTCON,7	; enable interrupt
	#endif
	#ifndef	debug_mplabsim
	 add_f16_f16_f16	txt_int, ADRESL, txt_int
	#else		; at debug: ADC = 0x200+channel nr
	 load_f_f	(txt_int+2),BTAC
	 load_f_l	(txt_int+3),.2
	 add_f16_f16_f16	txt_int, (txt_int+2), txt_int
	#endif
	if_f_eq_l	ADCmult,.0	; enough readings
	 return
	end_if
	decfb	tmp2,f	; decrease once more: both 0 and 1 give 1 reading
	if_f_eq_l	tmp2,.0	; enough readings
	 if_f_b_c	ADCref,1	; divide measurements
	  if_f_gt_l	ADCmult,.1
	   subdiv_f16_f_f16	txt_int, ADCmult, txt_int
	  end_if
	 end_if
	 return
	end_if
	gotop	radc1

	#ifdef	ADC_workaround
nopdeladc
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	return
	#endif

; set_Z0 - process the Z0 setting when set
set_Z0
;  Z0:
	banklabel
	bcfb	Stat_Z0,7	; Reset for EEPROM flag
;    bit<3:4>: interrupt frequency  00: 16 kHz, 01: 8 kHz, 10: 4 kHz, 11: 32kHz
	if_f_b_c	Stat_Z0,4
	 if_f_b_c	Stat_Z0,3
		; 00: 16 kHz
	  load_f_l	PR2, PR2_16k	; trigger value for timer 2 (16 KHz)
	  load_f_l	CNT_submsmax, .16
	#ifdef	include_3STOPBITS
	  load_f_l	stop3bitmax, .21
	#endif
	 else_	
		; 01: 8 kHz
	  load_f_l	PR2, PR2_8k	; trigger value for timer 2 (8 KHz)
	  load_f_l	CNT_submsmax, .8
	#ifdef	include_3STOPBITS
	  load_f_l	stop3bitmax, 9
	#endif
	 end_if
	else_
	 if_f_b_c	Stat_Z0,3
		; 10: 4 kHz
	  load_f_l	PR2, PR2_4k	; trigger value for timer 2 (4 KHz)
	  load_f_l	CNT_submsmax, .4
	#ifdef	include_3STOPBITS
	  load_f_l	stop3bitmax, .5
	#endif
	 else_	
		; 11: 32 kHz
	  load_f_l	PR2, PR2_32k	; trigger value for timer 2 (32 KHz)
	  load_f_l	CNT_submsmax, .32
	#ifdef	include_3STOPBITS
	  load_f_l	stop3bitmax, .41
	#endif
	 end_if
	end_if
	; return ; Always perform Z2!

; set_Z2 - process the Z2 setting when set (OSCTUNE)
set_Z2
	banklabel
	if_f_b_s	Stat_Z0,5	; coarse range
	 load_w_f	Stat_Z2
	 andlw	0x3F	; load lower 6 bits into OSCTUNE
	 load_f_w	OSCTUNE
	end_if
	return

set_Z3_default
	banklabel
	callp	set_default_pins
	return

set_Z3_save
	banklabel
	callp	save_to_eeprom
	return

set_Z3_load
	banklabel
	callp	load_from_eeprom
	return

set_Z3_erase
	banklabel
	callp	erase_eeprom
	return

set_Z3_reset
	banklabel
	reset
	return

set_Z3_bootloader
	banklabel
	clrfb	INTCON	; disable interrupts
	load_f_l	OSCCON, b'01111000' ; 16 MHz clock
	load_f_l	SPBRGL, .25 	; (9600 baud at 16 MHz)
	clrf	BSR
  	gotop	0x0019
	return

set_Z3_password
	banklabel
	return

get_Z3_password
	banklabel
	return

; get_Z3_version - read PIC version
get_Z3_version
	banklabel
	load_f16_l16	TEXT_POS,TXT_GZ310
	callp	write_text	
	callp	get_deviceID
	callp	write_hex_txtint_16_lf
	return

; get_Z3_version_text - read PIC version text output
get_Z3_version_text
	banklabel
	writetext	DEV_device		; First: device ID
	callp	get_deviceID
	load_w_l	0xE0		; Check high 9 bits for device
	andwfb	txt_int,f
	load_f16_l16	TEXT_POS,DEV_unknown
	if_f16_eq_l16	txt_int, B'10001110100000'
	 load_f16_l16	TEXT_POS,DEV_PIC16F1938
	end_if
	if_f16_eq_l16	txt_int, B'10001111000000'
	 load_f16_l16	TEXT_POS,DEV_PIC16F1939
	end_if
	if_f16_eq_l16	txt_int, B'10001111000000'
	 load_f16_l16	TEXT_POS,DEV_PIC16LF1938
	end_if
	if_f16_eq_l16	txt_int, B'10010011000000'
	 load_f16_l16	TEXT_POS,DEV_PIC16LF1939
	end_if
	callp	write_text	

	writetext	DEV_version		; now lower 5 bits for revision
	callp	get_deviceID
	load_f16_l16	TEXT_POS,DEV_unknown
	load_w_l	0x1F
	andwfb	txt_int,f
	if_f_eq_l	txt_int,.1
	 load_f16_l16	TEXT_POS,DEV_A1
	end_if
	if_f_eq_l	txt_int,.2
	 load_f16_l16	TEXT_POS,DEV_A2
	end_if
	if_f_eq_l	txt_int,.3
	 load_f16_l16	TEXT_POS,DEV_A3
	end_if
	callp	write_text	
	write_char	.10
	return

; get_Z3_intoverflow - read interrupt overflow
get_Z3_intoverflow
	banklabel
	load_f16_l16	TEXT_POS,TXT_GZ312
	callp	write_text	
	if_f_b_s	Stat_Z3,0
	 write_char	'1'	; Interrupt overflow set
	 bcfb	Stat_Z3,0	; reset flag
	else_
	 write_char	'0'	; No interrupt overflow
	end_if
	write_char	.10
	return

; get_Z3_intoverflow_text - read interrupt overflow (text)
get_Z3_intoverflow_text
	banklabel
	if_f_b_s	Stat_Z3,0
	 writetext	DEV_int_ov	; Interrupt overflow set
	 bcfb	Stat_Z3,0	; reset flag
	else_
	 writetext	DEV_int_noov	; No interrupt overflow
	end_if
	return

; get_Z3_eeprom - read EEPROM
get_Z3_eeprom
	banklabel
	for_f_l_l	tmp2,.0,.15
	 load_w_f	tmp2
	 swapf	WREG,w
	 load_f_w	txt_int
	 callp	write_hex_txtint_8
	 write_char	' '
	 for_f_l_l	tmp1,.0,.15
	  load_w_f	tmp2
	  swapf	WREG,w
	  iorwfb	tmp1,w
	  load_f_w	DATA_EE_ADDR	; address in EEPROM
	  callp	read_eeprom
	  load_f_f	txt_int, DATA_EE_DATA ; EEPROM data
	  callp	write_hex_txtint_8
	  write_char	' '
	 next_f	tmp1
	 write_char	.10
	next_f	tmp2
	return

; ***********************************************************************
; INTERRUPT ROUTINES
; ***********************************************************************

interrupt:		; Interrupt routines start here. Context is autamaticaly saved.
	banklabel
	bcf	INTCON,7	; disabled interrupt (obsolete?)
	clrf	BSR
	bcfb	PIR1, TMR2IF	; clear timer 2 bit
	clrfb	TMR2	; reset Timer 2

	; Read UART RX
	callp	UART_int_read
	callp	UART_int_read

	; Write UART TX
	#ifdef	include_3STOPBITS
	if_f_ne_l	stop3bitcnt,0	; 2 bits stop counter
	 dec_f	stop3bitcnt
	end_if
	#endif
	if_f_b_s	TXSTA, TRMT	; UART TX is clear and value can be loaded in TXREG
	#ifdef	include_3STOPBITS
	 if_f_eq_l	stop3bitcnt,0	; timer to generate 3 stop bits
	#endif
	  callp	bufread1	; if value in buffer then value in BUFRD and BUFST equals 0, else BUFST = 1
	  if_f_b_c	BUFST,1	; so, there is a value
	   load_f_f	TXREG, BUFRD1
	   load_f_f	stop3bitcnt,stop3bitmax
	  end_if
	#ifdef	include_3STOPBITS
	 end_if
	#endif
	end_if

        ; ADDED FOR PULS LENGTH
	pulse_interrupt	Stat_B2, Val_B2, PORTB, b'00000100'
	
	; Clock
	bcfb	CNT_stat,0		; reset signal for 1 ms
	incfb	CNT_subms, f
	if_f_eq_f	CNT_subms, CNT_submsmax
	 clrfb	CNT_subms
	 bsfb	CNT_stat,0		; signal for 1 ms
	 if_f_ne_l	i2c_wait,.0		; decrease i2c_wait counter
	  dec_f	i2c_wait
	 end_if 	
	 gotoif_f_b_s	Stat_Z0,6, skip_pwmonly1	; PWM only?
	 inc_f16	CNT_ms
	 if_f16_eq_l16	CNT_ms, .1000
	  clrfb	CNT_ms
	  clrfb	(CNT_ms+1)
	  incfb	Stat_X1,f
	  bsfb	CNT_stat,7		; signal for 1 second clock write
	  if_f_eq_l	Stat_X1, .60
	   clrfb	Stat_X1
	   incfb	Stat_X2,f
	   if_f_eq_l	Stat_X2, .60
	    clrfb	Stat_X2
	    incfb	Stat_X3,f
	    if_f_eq_l	Stat_X3, .24
	     clrfb	Stat_X3
	    end_if
	   end_if
	  end_if
	 end_if
	end_if

	; ADC 100ms timer
skip_pwmonly1	banklabel
	if_f_b_s	CNT_stat,0	; 1 ms
	 dec_f	 ADCcountdown	; ADC counter
	 if_f_eq_l	 ADCcountdown,.0
	  bsfb	 CNT_stat,3
	  load_f_l	ADCcountdown, .100
	 end_if
	end_if

	gotoif_f_b_s	Stat_Z0,6, skip_pwmonly2	; PWM only?

	if_f_b_s	CNT_stat,0	; ms
	 ; PWM 10ms timer
	 dec_f	 PWMcountdown
	 if_f_eq_l	 PWMcountdown,.0
	  bsfb	 CNT_stat,4	; 10 ms flag for PWM
	  load_f_l	 PWMcountdown, .10
	 end_if
	end_if
	 
	 ; CPS READOUT
	 dec_f	CPScountdown	; Only CPS at 4 kHz
	 if_f_eq_l	CPScountdown,.0
	  callp	CPS_jump	;   To speed things up (no lookup table, indirect addressing and loops) just everything in a row...
	  load_f_f	CPScountdown, CNT_submsmax	; 4 kHz by CNT_submsmax / 4
	  lsrfb	CPScountdown,f
	  lsrfb	CPScountdown,f
	 end_if
	  
	 ; PWM control
	 incfb	intcount, f
	 if_f_gt_l	intcount,.100
	  clrfb	intcount
	  incfb	rcv_timer,f ; increase the timeoutbuffer at 80 Hz
	 end_if

	 ; PWM ports
	 #ifdef	include_extendedPWM
	 PWM_port	PORTA, .6, Val_A6, Stat_A6, Work_A6, 1, PORTA, .7, Stat_A7
	 PWM_port	PORTA, .7, Val_A7, Stat_A7, Work_A7, 0,0,0,0
	 PWM_port	PORTB, .0, Val_B0, Stat_B0, Work_B0, 1, PORTB, .1, Stat_B1 
	 PWM_port	PORTB, .1, Val_B1, Stat_B1, Work_B1, 0,0,0,0
	 PWM_port	PORTB, .6, Val_B6, Stat_B6, Work_B6, 1, PORTB, .7, Stat_B7
	 PWM_port	PORTB, .7, Val_B7, Stat_B7, Work_B7, 0,0,0,0
	 PWM_port	PORTC, .1, Val_C1, Stat_C1, Work_C1, 1, PORTC, .2, Stat_C2
	 PWM_port	PORTC, .2, Val_C2, Stat_C2, Work_C2, 0,0,0,0
	 bcfb	CNT_stat,4	; reset 10ms flag
	 #endif	; include_extendedPWM

	#ifdef	include_datalogger
	if_f_b_s	dlog_stat,0	; Execute if datalogging
	 ; DATA Logging
	 if_f_b_s	CNT_stat,0	; ms
	  if_f32_eq_l32	dlog_mscountdown,.0
	   if_f_b_s	dlog_stat,7
	    bsfb	dlog_stat,2		; indicate missed measurement
	   end_if
	   bsfb	dlog_stat,7		; flag to start measurements
	   load_f32_f32	dlog_mscountdown, dlog_mscountmax
	  end_if
	  dec_f32	dlog_mscountdown
	 end_if
	end_if
	#endif	; include_datalogger

	 
;     bit0: 0: count, 1: count per time unit ("frequency"), see bit<0:2>
;     bit<1:3>: frequency measurement period: 
;                  000: 1 ms, 001: 10 ms,    010: 100 ms, 011: 1s,
;                  100: 10s,  101: 1 minute, 110: 10 min, 111: 1 hour 
;     bit<4:5>: prescaler: 00: 1:1, 01: 1:2, 10: 1:4, 11: 1:8
;     bit6: if bit0=0: 0: stop for reading and start afterwards, 1: read high1-low-high2 without stopping counting; if high1=high2: high:low, otherwise high2:00
;           if bit0=1: 0: restart measurement after one measurement, 1: stop after one measurement (restart by writing to C01)
;     bit7: do send measurement every period
	; Timer1
	if_f_eq_l	Stat_C0,.6		; Timer1?
	 if_f_b_s	(Stat_C0+1),0		; frequency mode?
	  if_f_b_s	CNT_stat,0	; ms
	   sub_f32_l32_f32	T1countdown,.1,T1countdown
	   if_f32_eq_l32	T1countdown,.0
	    bcfb	T1CON, TMR1ON	; stop timer1
	    load_f16_f16	Val_C0, TMR1L	; Set value in Val_C0
	    bsfb	Work_C0,0		; flag for new value
	    if_f_b_c	(Stat_C0+1),6		; retart timer?
	     clrfb	TMR1L
	     clrfb	TMR1H
	     bsfb	T1CON, TMR1ON	; start timer1
	    else_
	     bcfb	(Stat_C0+1),0	; put to count
	    end_if ; C01,6
	    load_f32_f32	T1countdown,T1countdownmax
	   end_if ; T1countdown=0
	  end_if ; CNT_subms=0
	 end_if ; C01,0
	end_if ; C0=6

	; Watch Dog
	if_f_b_s	CNT_stat,0	; ms
	 if_f16_lt_l16	wdt_2, .2001
	  inc_f16	wdt_2
	 end_if
	 if_f16_eq_l16	wdt_2, .2000
	  bsfb	CNT_stat,1	; flag for 2 s watchdog time out 
	 end_if
	 if_f16_lt_l16	wdt_60, .60001
	  inc_f16	wdt_60
	 end_if
	 if_f16_eq_l16	wdt_60, .60000
	  bsfb	CNT_stat,2	; flag for 60 s watchdog time out 
	 end_if
	end_if

	; OSCTUNE
	if_f_b_c	Stat_Z0,5	; fine range OSCTUNE
	 load_w_f	Stat_Z2
	 andlw	0x1F
	 addwfb	tunedelta, f	; perform sigma delta on lower 5 bits
	 if_f_ge_l	tunedelta,0x20
	  sub_f_l_f	tunedelta, 0x20, tunedelta
	  load_w_f	Stat_Z2
	  asrf	WREG,f	; signed 8 bit -> signed 6 bit /4
	  asrf	WREG,f
	  asrf	WREG,f
	  lsrf	WREG,w
	  lsrf	WREG,w
	  incf	WREG,w
	  load_f_w	OSCTUNE
	 else_
	  load_w_f	Stat_Z2
	  asrf	WREG,f	; signed 8 bit -> signed 6 bit /4
	  asrf	WREG,f
	  asrf	WREG,f
	  lsrf	WREG,w
	  lsrf	WREG,w
	  load_f_w	OSCTUNE
	 end_if	  
	end_if

skip_pwmonly3
	banklabel
	if_f_b_s	PIR1, TMR2IF	; check whether interrupt is overflown
	 bsfb	Stat_Z3,0	; zet bit
	end_if
	bcfb	PIR1, TMR2IF	; clear timer 2 bit
	bsf	INTCON,7	; enable interrupt
	retfie
skip_pwmonly2
	banklabel
	PWM_only_port	PORTA, .6, Val_A6, Stat_A6, Work_A6
	PWM_only_port	PORTA, .7, Val_A7, Stat_A7, Work_A7
	PWM_only_port	PORTB, .0, Val_B0, Stat_B0, Work_B0
	PWM_only_port	PORTB, .1, Val_B1, Stat_B1, Work_B1
	PWM_only_port	PORTB, .6, Val_B6, Stat_B6, Work_B6
	PWM_only_port	PORTB, .7, Val_B7, Stat_B7, Work_B7
	PWM_only_port	PORTC, .1, Val_C1, Stat_C1, Work_C1
	PWM_only_port	PORTC, .2, Val_C2, Stat_C2, Work_C2
	gotop	skip_pwmonly3

; ***********************************************************************
; SUBROUTINES
; ***********************************************************************

UART_int_read
	banklabel
	uart_read	BUFWRT2, UART_ST
	if_f_b_s	UART_ST,0
	 callp	bufwriteskip2
	end_if
	return


CPS_jump0	banklabel
	CPS_chan	.0, PORTB, .0, Val_B0, Stat_B0, Work_B0, .1, Stat_B1 
CPS_jump1	banklabel
	CPS_chan	.1, PORTB, .1, Val_B1, Stat_B1, Work_B1, .2, Stat_B2
CPS_jump2	banklabel
	CPS_chan	.2, PORTB, .2, Val_B2, Stat_B2, Work_B2, .3, Stat_B3
CPS_jump3	banklabel
	CPS_chan	.3, PORTB, .3, Val_B3, Stat_B3, Work_B3, .4, Stat_B4
CPS_jump4	banklabel
	CPS_chan	.4, PORTB, .4, Val_B4, Stat_B4, Work_B4, .5, Stat_B5
CPS_jump5	banklabel
	CPS_chan	.5, PORTB, .5, Val_B5, Stat_B5, Work_B5, .6, Stat_A4
CPS_jump6	banklabel
	CPS_chan	.6, PORTA, .4, Val_A4, Stat_A4, Work_A4, .7, Stat_A5
	#ifndef	PIN40
CPS_jump7	banklabel
	CPS_chan	.7, PORTA, .5, Val_A5, Stat_A5, Work_A5, .0, Stat_B0
	#else
CPS_jump7	banklabel
	CPS_chan	.7,  PORTA, .5, Val_A5, Stat_A5, Work_A5, .8,  Stat_D0
CPS_jump8	banklabel
	CPS_chan	.8,  PORTD, .0, Val_D0, Stat_D0, Work_D0, .9,  Stat_D1
CPS_jump9	banklabel
	CPS_chan	.9,  PORTD, .1, Val_D1, Stat_D1, Work_D1, .10, Stat_D2
CPS_jump10	banklabel
	CPS_chan	.10, PORTD, .2, Val_D2, Stat_D2, Work_D2, .11, Stat_D3
CPS_jump11	banklabel
	CPS_chan	.11, PORTD, .3, Val_D3, Stat_D3, Work_D3, .12, Stat_D4
CPS_jump12	banklabel
	CPS_chan	.12, PORTD, .4, Val_D4, Stat_D4, Work_D4, .13, Stat_D5
CPS_jump13	banklabel
	CPS_chan	.13, PORTD, .5, Val_D5, Stat_D5, Work_D5, .14, Stat_D6
CPS_jump14	banklabel
	CPS_chan	.14, PORTD, .6, Val_D6, Stat_D6, Work_D6, .15, Stat_D7
CPS_jump15	banklabel
	CPS_chan	.15, PORTD, .7, Val_D7, Stat_D7, Work_D7, .0,  Stat_B0
	#endif
	

bufinit1:	banklabel
	bufinit	1
bufread1:	banklabel
	bufread	1
bufreadwait1:	banklabel
	bufreadwait	1
bufwrite1:	banklabel
	bufwrite	1
bufwritewait1:	banklabel
	bufwritewait	1

bufinit2:	banklabel
	bufinit	2
bufread2:	banklabel
	bufread	2
bufreadwait2:	banklabel
	bufreadwait	2
bufwrite2:	banklabel
	bufwrite	2
bufwriteskip2:	banklabel
	bufwriteskip	2


	 #ifdef	include_extendedPWM
PWM_port_sub
	banklabel
	clr_f	PWMstat
	;if_f_eq_l	PWMstat0, .5	; is pin PWM?
	 if_f_b_c	(PWMstat1), 5
	  if_f_b_c	(PWMstat1), 4	; now mode 0: synchrounous
	   if_f_le_f	(PWMvalue), intcount
	    ;bcfb	port,portbit	; pin low
	    bcfb	PWMstat,0	; pwm low
	   else_
	    ;bsfb	port,portbit	; pin high
	    bsfb	PWMstat,0	; pwm high
	   end_if
	  else_		; mode 1: max in PP2
	   incfb	(PWMwork),f
	   if_f_gt_f	(PWMwork), (PWMstat2)
	    clrfb	(PWMwork)
	   end_if
	   if_f_le_f	(PWMvalue), (PWMwork)
	    ;bcfb	port,portbit	; pin low
	    bcfb	PWMstat,0	; pin low
	   else_
	    ;bsfb	port,portbit	; pin high
	    bsfb	PWMstat,0	; pwm high
	   end_if
	  end_if		; end mode 1
	 else_	; now mode 2 and 3
	  if_f_b_c	(PWMstat1), 4	; now mode 2: sigma-delta
	   load_w_f	(PWMvalue)	; increase sigma with value, but ignore bit 15 of (PWMvalue)
	   addwfb	(PWMwork),F
	   if_f_b_s	STATUS,C
	    movlw	.1
	    addwfb	((PWMwork)+1),F
	   end_if
	   load_w_f	((PWMvalue)+1)
	   andlw	0x7F
	   addwfb	(PWMwork+1),F
	   if_f_b_s	((PWMwork)+1),6		; if >=16384 then high and decrease sigma with 16384
	    ;bsfb	port,portbit	; pin high
	    bsfb	PWMstat,0	; pwm high
	    load_w_f	((PWMwork)+1)
	    addlw	0xC0	; decrease 16384, by adding 49152
	    load_f_w	((PWMwork)+1)	
	   else_		; otherwise low
	    ;bcfb	port,portbit	; pin low
	    bcfb	PWMstat,0	; pin low
	   end_if	
	  else_		; now mode 3: random
	   bankset	(PWMwork)
	   lslf	(PWMwork),f
	   rlf	((PWMwork)+1),f
	   bankres	(PWMwork)
	   if_f_b_c	((PWMwork)+1),7	; xor operation of Linear Feedback Shift Register (15 bit)
	    if_f_b_c	((PWMwork)+1),6
	     bsfb	(PWMwork),0	; 00: 0 xor 0 xor 1 = 1
	    else_
	     bcfb	(PWMwork),0	; 01: 0 xor 1 xor 1 = 0
	    end_if
	   else_
	    if_f_b_c	((PWMwork)+1),6
	     bcfb	(PWMwork),0	; 10: 1 xor 0 xor 1 = 0
	    else_
	     bsfb	(PWMwork),0	; 11: 1 xor 1 xor 1 = 1
	    end_if
	   end_if		; end xor op
	   load_w_f	(PWMwork)
	   bcf	WREG,7	; make 0..127
	   bankset	(PWMvalue)
	   addlw	.1	; to make >127 bit value (in stead of >=)
	   subwf	(PWMvalue),w
	   bankset	(PWMstat)
	   skpnc		; skip if val < 127 bit random value		; 
	   ;bsf	port,portbit	; pin high
	   bsf	PWMstat,0	; pwm high
	   skpc		; skip if val >= 127 bit random value
	   ;bcf	port,portbit	; pin low
	   bcf	PWMstat,0	; pin low
	   bankres	(PWMstat)
	  end_if		; end mode 3
	 end_if		; end of mode 2 and 3
	;end_if		; end stat=5
	; Now result of PWM calculation in PWMstat:0
	; depending on bits 4 and 5 high or low, or tri state
	; depending on function, single channel or bridge 
	clrfb	PWMres
	; PWMres: bit0: PORT(1), bit1: TRIS(1), bit3: Bridge, bit4: PORT(2), bit5: TRIS(2) 
	load_f_b_f_b	PWMstat,1, (PWMstat1),0	; High or low output
	load_f_b_f_b	PWMstat,2, (PWMstat1),1	; output or high impediance
	if_f_eq_l	PWMfunc2,.6		; Bridge
	 bsfb		PWMres,3
	 if_f_b_c	((PWMvalue)+1),7	; pin1 pwm
	  pwm_port_l	4 
	  pwm_port_h	0 
	 else_			; pin2 pwm
	  pwm_port_l	0 
	  pwm_port_h	4 
	 end_if
	else_			; Single channel
	 pwm_port_h	0
	end_if
	return
	#endif	; include_extendedPWM


; write_text
;   outputs text, starting from TEXT_POS, until zero-character is detected
write_text:
	banklabel
	load_f_f	FSR0H, TEXT_POS+1
	bsfb	FSR0H, 7
	load_f_f	FSR0L, TEXT_POS
	load_f_f	TEXT_CHAR, INDF0
	if_f_eq_l	TEXT_CHAR,0
	  return
	end_if
	write_f	TEXT_CHAR
	incfb	TEXT_POS, f	; increment TEXT_POS
	btfsc	STATUS,Z
	incfb	(TEXT_POS+1), f	
	gotop	write_text	
	
; Jump to Data fields
write_text_cll	banklabel
	load_f_f	PCLATH, TEXT_POS+1
	load_f_f	PCL, TEXT_POS

write_lf:
	banklabel
	;write_char	.13
	write_char	.10
	return

write_space:
	banklabel
	write_char 	.32
	return

; write_latch - writes masked value of cmda3 to port of pin in cmda2 and BTP
write_latch
	banklabel
	clr_f	ADCmult	; use ADCmult temporary as mask
	load_w_f	cmda2	; get bit 4 from PP1 (latch mode?)
	andlw	0xF8	; get the lower pin of the port
	load_f_w	tmp2
	lslfb	tmp2,f
	lslfb	tmp2,f
	incfb	tmp2,f	; status-1
	load_f_bk_li	ADCref,.3,tmp2	; use temporary ADCref for PP1
	if_f_b_s	ADCref, .4	; latch mode of pin 0
	 bsfb	ADCmult,0
	end_if
	add_f_l_f	ADCref, .4, ADCref	; status 1 of next pin
	if_f_b_s	ADCref, .4	; latch mode of pin 1
	 bsfb	ADCmult,1
	end_if
	add_f_l_f	ADCref, .4, ADCref	; status 1 of next pin
	if_f_b_s	ADCref, .4	; latch mode of pin 2
	 bsfb	ADCmult,2
	end_if
	add_f_l_f	ADCref, .4, ADCref	; status 1 of next pin
	if_f_b_s	ADCref, .4	; latch mode of pin 3
	 bsfb	ADCmult,3
	end_if
	add_f_l_f	ADCref, .4, ADCref	; status 1 of next pin
	if_f_b_s	ADCref, .4	; latch mode of pin 4
	 bsfb	ADCmult,4
	end_if
	add_f_l_f	ADCref, .4, ADCref	; status 1 of next pin
	if_f_b_s	ADCref, .4	; latch mode of pin 5
	 bsfb	ADCmult,5
	end_if
	add_f_l_f	ADCref, .4, ADCref	; status 1 of next pin
	if_f_b_s	ADCref, .4	; latch mode of pin 6
	 bsfb	ADCmult,6
	end_if
	add_f_l_f	ADCref, .4, ADCref	; status 1 of next pin
	if_f_b_s	ADCref, .4	; latch mode of pin 7
	 bsfb	ADCmult,7
	end_if
	gt_BTP_f	PORTA, txt_int	; now in txt_int value of PORTA+BTP/8
	load_w_f	cmda3	; value
	andwfb	ADCmult,w	; and Mask
	iorwfb	txt_int,f	; now txt_int the new value
	ld_BTP_f	PORTA, txt_int
	return

get_deviceID
	banklabel
	bankset	EEADRL 	; Select correct Bank
	MOVLW	0x06
	MOVWF	EEADRL 	; Store LSB of address
	MOVLW	0x0
	MOVWF	EEADRH 	; Store MSB of address
	BSF 	EECON1,CFGS 	; Select Configuration Space
	BCF 	INTCON,GIE 	; Disable interrupts
	BSF 	EECON1,RD 	; Initiate read
	NOP 	; Executed (See Figure 11-1)
	NOP 	; Ignored (See Figure 11-1)
	BSF	INTCON,GIE 	; Restore interrupts
	MOVF	EEDATL,W 	; Get LSB of word
	banksel	txt_int
	MOVWF	txt_int
	banksel	EEDATH
	MOVF	EEDATH,W 	; Get MSB of word
	banksel	(txt_int+1)
	MOVWF	(txt_int+1)
	bankres	EEADRL
	return

; Read the EEPROM at DATA_EE_ADDR and store into DATA_EE_DATA
read_eeprom
	banklabel
	load_f_f	EEADRL, DATA_EE_ADDR  	;Data Memory address to read
	bcfb	EECON1, CFGS 		;Deselect Config space
	bcfb	EECON1, EEPGD		;Point to DATA memory
	bsfb	EECON1, RD 		;EE Read
	load_f_f	DATA_EE_DATA, EEDATL	;Data Memory Value to write
	return

; Write DATA_EE_DATA to the EEPROM at DATA_EE_ADDR
write_eeprom
	banklabel
	load_f_f	EEADRL, DATA_EE_ADDR 	;Data Memory Address to write
	load_f_f	EEDATL, DATA_EE_DATA	;Data Memory Value to write
	bankset	EECON1
	bcf	EECON1, CFGS 	;Deselect Configuration space
	bcf	EECON1, EEPGD 	;Point to DATA memory
	bsf	EECON1, WREN 	;Enable writes
	bcf	INTCON, GIE 	;Disable INTs.
	movlw	0x55
	movwf	EECON2 	;Write 55h
	movlw	0xAA
	movwf	EECON2 	;Write AAh
	bsf	EECON1, WR 	;Set WR bit to begin write
	bsf	INTCON, GIE 	;Enable Interrupts
	bcf	EECON1, WREN 	;Disable writes
	BTFSC	EECON1, WR	;Wait for write to complete
	GOTO	$-2	;Done
	bankres	EECON1
	return

; load_from_eeprom - load all status bytes from eeprom and set in RAM
load_from_eeprom
	banklabel
	for_f_l_l	DATA_EE_ADDR, .0, .191
	 callp	read_eeprom
	 load_bk_li_f	.3, DATA_EE_ADDR, DATA_EE_DATA
	next_f	DATA_EE_ADDR
	return

; set_all_pins_from_eeprom - sets the pins after copying eeprom to RAM (do not skip load_from_eeprom!)
set_all_pins_from_eeprom
	banklabel
	for_f_l_l	DATA_EE_ADDR, .0, .88
	 callp	read_eeprom
	 load_f_l	cmda1,.3
	 load_f_f	cmda2, DATA_EE_ADDR
	 clr_f	(cmda2+1)
	 lsrfb	cmda2,f
	 rrfb	(cmda2+1),f
	 lsrfb	cmda2,f
	 rrfb	(cmda2+1),f
	 swapfb	(cmda2+1),f
	 lsrfb	(cmda2+1),f
	 lsrfb	(cmda2+1),f
	 load_f_f	cmda3, DATA_EE_DATA
	 clr_f	(cmda3+1)
	 load_f_l	nofargs,.3
	 callp	cmd_exec_nocmdln
	next_f	DATA_EE_ADDR
	#ifdef	include_datalogger
	if_f_b_s	Stat_S0,2	; start datalogger
	 load_f_l	cmda3,.3	; continue
	 callp	set_S3
	end_if
	#endif	; include_datalogger
	return


; save_to_eeprom - save all status bytes from RAM to eeprom
save_to_eeprom
	banklabel
	for_f_l_l	DATA_EE_ADDR, .0, .191
	 load_f_bk_li	DATA_EE_DATA, .3, DATA_EE_ADDR
	 callp	write_eeprom
	next_f	DATA_EE_ADDR
	return

; erase_eeprom - save all status bytes from RAM to eeprom
erase_eeprom
	banklabel
	for_f_l_l	DATA_EE_ADDR, .0, .191
	 load_f_l	DATA_EE_DATA, 0xFF
	 callp	write_eeprom
	next_f	DATA_EE_ADDR
	return

; start_timer1 - start timer 1 with settings in Stat_C01
start_timer1
	banklabel
	if_f_b_c	(Stat_C0+1),3
	 if_f_b_c	(Stat_C0+1),2
	  if_f_b_c	(Stat_C0+1),1
	   ; <1:3>=000
	   load_f32_l32	T1countdownmax, .1
	  else_
	   ; <1:3>=001
	   load_f32_l32	T1countdownmax, .10
	  end_if
	 else_
	  if_f_b_c	(Stat_C0+1),1
	   ; <1:3>=010
	   load_f32_l32	T1countdownmax, .100
	  else_
	   ; <1:3>=011
	   load_f32_l32	T1countdownmax, .1000
	  end_if
	 end_if
	else_
	 if_f_b_c	(Stat_C0+1),2
	  if_f_b_c	(Stat_C0+1),1
	   ; <1:3>=100
	   load_f32_l32	T1countdownmax, .10000
	  else_
	   ; <1:3>=101
	   load_f32_l32	T1countdownmax, .60000
	  end_if
	 else_
	  if_f_b_c	(Stat_C0+1),1
	   ; <1:3>=110
	   load_f32_l32	T1countdownmax, .600000
	  else_
	   ; <1:3>=111
	   load_f32_l32	T1countdownmax, .3600000
	  end_if
	 end_if
	end_if
	bcfb	T1CON, TMR1ON	; stop timer1
	clrfb	TMR1L	; clear counter
	clrfb	TMR1H
	bcfb	T1GCON, TMR1GE	; no gate control
	load_w_f	(Stat_C0+1)	; prescaler
	andlw	0x30
	iorlw	0x81	; Pin C0 as input, synchronized input and Timer1 on
	load_f_w	T1CON
	load_f32_f32	T1countdown,T1countdownmax
	bcfb	Work_C0,0	; reset flag 
	return
;del500ms:	delxms	(.105787/.2)	; @16MHz
;	return

read_C0
;   PP1:
;     bit6: 0: stop for reading and start afterwards, 1: read high1-low-high2 without stopping counting; if high1=high2: high:low, otherwise high2:00
	banklabel
	if_f_b_c	(Stat_C0+1),0	; counter
	 if_f_b_c	(Stat_C0+1),6	; stop-read-start
	  bcfb	T1CON, TMR1ON	; stop timer1
	  load_f16_f16	txt_int, TMR1L	; Set value in txt_int
	  bsfb	T1CON, TMR1ON	; start timer1
	 else_		;read high1, low, high2
	  load_f_f	(txt_int+2), TMR1H
	  load_f_f	txt_int, TMR1L
	  load_f_f	(txt_int+1), TMR1H
	  if_f_ne_f	(txt_int+2),(txt_int+1)	; if high2!=high1 -> low=0
	   clrfb	txt_int
	  end_if
	 end_if
	else_		; frequency
	 load_f16_f16	txt_int,Val_C0
	end_if
	clrfb	(txt_int+2)
	clrfb	(txt_int+3)
	if_f_b_c	cmdstat,0	; text or internal output
	 write_char	'R'		; write out
	 write_char	' '
	 write_char	'C'
	 write_char	'0'
	 write_char	' '
	 callp	write_dec_txtint_16_lf	; blockpos
	end_if
	return

	#ifdef	include_datalogger

; i2c_init
;
;
i2c_init
	banklabel
	bsfb	TRISC,3	; set C4 as input
	bsfb	TRISC,4	; set C4 as input
	bsfb	SSPSTAT,SMP	; Slew rate control disabled for standard speed mode
	load_f_l	SSPCON1, b'00101000'	; Enable serial port, I2C master mode, 7-bit address
	bsfb	SSPCON3,SDAHT	; Minimum of 300 ns hold time
	load_f_l	SSPADD, 0x4F	; load the baud rate value: 100 kHz at 32 MHz (0x27 for 16 MHz)
	return

; i2c_stop
;
;
i2c_stop
	banklabel
	clrfb	SSPCON1	; Disable i2c port and digital port C3 and C4
	return


safe_wait_sspif_sub
	banklabel
	load_f16_l16	sspif_cnt,0x0000
	repeat
	 inc_f16	sspif_cnt
	 if_f16_ge_l16	sspif_cnt,0x0740 ; appr. 10 ms
	  bcfb	PIR1, SSPIF	; clear sspif
	  bcfb	PIR2, BCLIF	; clear collision
	  callp	i2c_stop
	  callp	i2c_init
	  return
	 end_if  
	until_f_b_s	PIR1, SSPIF	; if 12c operation completed
	bcfb	PIR1, SSPIF	; clear sspif
	return

; write_i2c_flash
;   writes to i2C (24FC256 at i2c-address 0x50) flash address in FLASH_Address the value FLASH_Value
;
write_i2c_flash:
	banklabel
	gotoif_f_ne_l	i2c_wait,.0,write_i2c_flash
	; start bit
	bcfb	PIR1,SSPIF
	bsfb	SSPCON2,SEN	; start bit
	safe_wait_sspif .1 	; wait to complete
	; i2c address
	load_f_l	SSPBUF,0xA0	; address 0x50 (shifted) and write bit
	safe_wait_sspif .2		; wait to complete
	; flash high address
	load_f_f	SSPBUF,FLASH_Address+1	; high byte of the address
	safe_wait_sspif .3		; wait to complete
	; flash low address
	load_f_f	SSPBUF,FLASH_Address	; low byte of the address
	safe_wait_sspif .4		; wait to complete
	; flash value
	load_f_f	SSPBUF,FLASH_Value	; value to be written to flash
	safe_wait_sspif .5		; wait to complete
	; stop bit
	bsfb	SSPCON2,PEN	; stop bit
	safe_wait_sspif .6		; wait to complete
	load_f_l	i2c_wait,.6		; set i2c_wait counter to wait for next i2c operation, since 24FC256 is blocked for 5 ms 
	return

; write_buf_i2c_flash
;   writes to i2C (24FC256 at i2c-address 0x50) the 32 byte buffer form (linear address) 02C0-02FF to address starting with FLASH_Address
;
write_buf_i2c_flash:
	banklabel
	gotoif_f_ne_l	i2c_wait,.0,write_buf_i2c_flash
	; start bit
	bcfb	PIR1,SSPIF
	bsfb	SSPCON2,SEN	; start bit
	safe_wait_sspif .11		; wait to complete
	; i2c address
	load_f_l	SSPBUF,0xA0	; address 0x50 (shifted) and write bit
	safe_wait_sspif .12		; wait to complete
	; flash high address
	load_f_f	SSPBUF,FLASH_Address+1	; high byte of the address
	safe_wait_sspif .13		; wait to complete
	; flash low address
	load_f_f	SSPBUF,FLASH_Address	; low byte of the address
	safe_wait_sspif .14		; wait to complete
	; now write 64 byte
	for_f_l_l	FLASH_Count, .0,.63
	 bsfb	FLASH_Count,7		; to get into 0x80-0xFF range
	 bsfb	FLASH_Count,6
	 load_f_bk_li	SSPBUF,.2,FLASH_Count	; value to be written to flash
	 safe_wait_sspif .15	; wait to complete
	 bcfb	FLASH_Count,7		; set back to 0..64 range
	 bcfb	FLASH_Count,6
	next_f	FLASH_Count
	; stop bit
	bsfb	SSPCON2,PEN	; stop bit
	safe_wait_sspif .16		; wait to complete
	load_f_l	i2c_wait,.6		; set i2c_wait counter to wait for next i2c operation, since 24FC256 is blocked for 5 ms 
	return

; read_i2c
;   reades from i2C address 0x50 and flash address in FLASH_Address and puts the value in FLASH_Value
;
read_i2c_flash:
	banklabel
	gotoif_f_ne_l	i2c_wait,.0,read_i2c_flash
	; start bit
	bcfb	PIR1,SSPIF
	bsfb	SSPCON2,SEN	; start bit
	safe_wait_sspif .21		; wait to complete
	; i2c address
	load_f_l	SSPBUF,0xA0	; address 0x50 (shifted) and write bit
	safe_wait_sspif .22		; wait to complete
	; flash high address
	load_f_f	SSPBUF,FLASH_Address+1	; high byte of the address
	safe_wait_sspif .23		; wait to complete
	; flash low address
	load_f_f	SSPBUF,FLASH_Address	; low byte of the address
	safe_wait_sspif .24		; wait to complete
	; Again i2c address, but now read
	bsfb	SSPCON2,RSEN	; start bit
	safe_wait_sspif .25		; wait to complete
	; i2c address
	load_f_l	SSPBUF,0xA1	; address 0x50 (shifted) and read bit
	safe_wait_sspif .26		; wait to complete
	; read byte

	bsfb	SSPCON2,RCEN	; start reading
	safe_wait_sspif .27		; wait to complete
	load_f_f	FLASH_Value, SSPBUF
	; send acknowledge
	bsfb	SSPCON2,ACKDT            ; acknowledge bit state to send (not ack)
	bsfb	SSPCON2,ACKEN            ; initiate acknowledge sequence
	safe_wait_sspif .28		; wait to complete
	; stop bit
	bsfb	SSPCON2,PEN	; stop bit
	safe_wait_sspif .29		; wait to complete
	return

read_buf_i2c_flash:
	banklabel
	gotoif_f_ne_l	i2c_wait,.0,read_buf_i2c_flash
	; start bit
	bcfb	PIR1,SSPIF
	bsfb	SSPCON2,SEN	; start bit
	safe_wait_sspif .31		; wait to complete
	; i2c address
	load_f_l	SSPBUF,0xA0	; address 0x50 (shifted) and write bit
	safe_wait_sspif .32		; wait to complete
	; flash high address
	load_f_f	SSPBUF,FLASH_Address+1	; high byte of the address
	safe_wait_sspif .33		; wait to complete
	; flash low address
	load_f_f	SSPBUF,FLASH_Address	; low byte of the address
	safe_wait_sspif .34		; wait to complete
	; Again i2c address, but now read
	bsfb	SSPCON2,RSEN	; start bit
	safe_wait_sspif .35		; wait to complete
	; i2c address
	load_f_l	SSPBUF,0xA1	; address 0x50 (shifted) and read bit
	safe_wait_sspif .36		; wait to complete
	; now read 64 byte. First 63 in a loop (with acknowledge)
	for_f_l_l	FLASH_Count, .0,.30
	 ; read byte
	 bsfb	SSPCON2,RCEN	; start reading
	 safe_wait_sspif .37	; wait to complete
	 load_f_f	txt_int, SSPBUF
	 callp	write_hex_txtint_8
	 ; send acknowledge
	 bcfb	SSPCON2,ACKDT	; send acknowledge (clear ACKDT en start by setting ACKEN)
	 bsfb	SSPCON2,ACKEN
	 safe_wait_sspif .38	; wait to complete
	next_f	FLASH_Count
	; read byte 64 (without acknowledge)
	bsfb	SSPCON2,RCEN	; start reading
	safe_wait_sspif .39		; wait to complete
	load_f_f	txt_int, SSPBUF
	callp	write_hex_txtint_8
	bsfb	SSPCON2,ACKDT            ; acknowledge bit state to send (not ack)
	bsfb	SSPCON2,ACKEN            ; initiate acknowledge sequence
	; stop bit
	bsfb	SSPCON2,PEN	; stop bit
	safe_wait_sspif .40		; wait to complete
	return

; sspif_error error handler for sspif time out
sspif_error:
	banklabel
	bcfb	PIR1, SSPIF	; clear sspif
	return

; read_buf_internal
read_buf_internal
	banklabel
	for_f_l_l	FLASH_Count, .0,.31
	 bsfb	FLASH_Count,7
	 bsfb	FLASH_Count,6
	 if_f_b_s	cmda3,5	; lower or upper half of buffer
	  bsfb	FLASH_Count,5
	 end_if
	 load_f_bk_li	txt_int, .2, FLASH_Count
	 bcfb	FLASH_Count,5
	 bcfb	FLASH_Count,7
	 bcfb	FLASH_Count,6
	 callp	write_hex_txtint_8
	next_f	FLASH_Count
	return



; read_C3
read_C3
	banklabel
	write_char	'R'
	write_char	' '
	write_char	'C'
	write_char	'3'
	write_char	' '

	if_f_b_c	(cmda3+1),7		; address<0x8000
	 load_f16_f16	txt_int, cmda3		;  normal address
	else_
	 bankblockstart
	 load_f16_f16	txt_int, dlog_posblock	; now the address the buffer is meant for, and bit 15 set
	 lslfb	txt_int,f
	 rlfb	(txt_int+1), f
	 lslfb	txt_int,f
	 rlfb	(txt_int+1), f
	 lslfb	txt_int,f
	 rlfb	(txt_int+1), f
	 lslfb	txt_int,f
	 rlfb	(txt_int+1), f
	 lslfb	txt_int,f
	 rlfb	(txt_int+1), f
	 lslfb	txt_int,f
	 rlfb	(txt_int+1), f
	 bsfb	(txt_int+1),7
	 bankblockend
	 if_f_b_s	cmda3,5	; lower or upper half of buffer
	  bsfb	txt_int,5
	 end_if
	end_if
	callp	write_hex_txtint_16
	write_char	' '
	load_f16_f16   FLASH_Address, cmda3
	if_f_b_c	(FLASH_Address+1),7		; address<0x8000
	 callp	read_buf_i2c_flash	; read i2c memory
	else_
	 callp	read_buf_internal	; read internal buffer
	end_if
	write_char	.10
	return

	#endif	include_datalogger


; watchdog_switchoff - switch off pin, pinnumber in tmp1
watchdog_switchoff
	banklabel
	load_f_l	cmda1,.1	; write
	load_f_f	cmda2,tmp1
	clrfb	(cmda2+1)
	clr_f16	cmda3	; send value 0
	callp	cmd_exec_nocmdln
	return


divrffff
	banklabel
	divr_f_f_f_f	mvar1, mvar2, mvar3, mvar4
	return

divrf16f16f16f16
	banklabel
	divr_f16_f16_f16_f16	mvar1, mvar2, mvar3, mvar4
	return

divf32f32f32
	banklabel
	div_f32_f32_f32		mvar1, mvar2, mvar3
	return

	#ifdef	include_datalogger

; sqrt_mvar5_txt_int : txt_int = sqrt(mvar5)
sqrt_mvar5_txt_int
	banklabel
	if_f32_eq_l32	mvar5,.0	; if v1=0, protocol does not work: return 0
	 clr_f32	txt_int
	 return
	end_if
	bankblockstart
	clr_f16	mvar6
	if_f_b_s	(mvar5+3),7
	 bsfb	(mvar6+1),7
	end_if
	if_f_b_s	(mvar5+3),6
	 bsfb	(mvar6+1),7
	end_if
	if_f_b_s	(mvar5+3),5
	 bsfb	(mvar6+1),6
	end_if
	if_f_b_s	(mvar5+3),4
	 bsfb	(mvar6+1),6
	end_if
	if_f_b_s	(mvar5+3),3
	 bsfb	(mvar6+1),5
	end_if
	if_f_b_s	(mvar5+3),2
	 bsfb	(mvar6+1),5
	end_if
	if_f_b_s	(mvar5+3),1
	 bsfb	(mvar6+1),4
	end_if
	if_f_b_s	(mvar5+3),0
	 bsfb	(mvar6+1),4
	end_if
	if_f_b_s	(mvar5+2),7
	 bsfb	(mvar6+1),3
	end_if
	if_f_b_s	(mvar5+2),6
	 bsfb	(mvar6+1),3
	end_if
	if_f_b_s	(mvar5+2),5
	 bsfb	(mvar6+1),2
	end_if
	if_f_b_s	(mvar5+2),4
	 bsfb	(mvar6+1),2
	end_if
	if_f_b_s	(mvar5+2),3
	 bsfb	(mvar6+1),1
	end_if
	if_f_b_s	(mvar5+2),2
	 bsfb	(mvar6+1),1
	end_if
	if_f_b_s	(mvar5+2),1
	 bsfb	(mvar6+0),0
	end_if
	if_f_b_s	(mvar5+2),0
	 bsfb	(mvar6+1),0
	end_if
	if_f_b_s	(mvar5+1),7
	 bsfb	(mvar6+0),7
	end_if
	if_f_b_s	(mvar5+1),6
	 bsfb	(mvar6+0),7
	end_if
	if_f_b_s	(mvar5+1),5
	 bsfb	(mvar6+0),6
	end_if
	if_f_b_s	(mvar5+1),4
	 bsfb	(mvar6+0),6
	end_if
	if_f_b_s	(mvar5+1),3
	 bsfb	(mvar6+0),5
	end_if
	if_f_b_s	(mvar5+1),2
	 bsfb	(mvar6+0),5
	end_if
	if_f_b_s	(mvar5+1),1
	 bsfb	(mvar6+0),4
	end_if
	if_f_b_s	(mvar5+1),0
	 bsfb	(mvar6+0),4
	end_if
	if_f_b_s	(mvar5+0),7
	 bsfb	(mvar6+0),3
	end_if
	if_f_b_s	(mvar5+0),6
	 bsfb	(mvar6+0),3
	end_if
	if_f_b_s	(mvar5+0),5
	 bsfb	(mvar6+0),2
	end_if
	if_f_b_s	(mvar5+0),4
	 bsfb	(mvar6+0),2
	end_if
	if_f_b_s	(mvar5+0),3
	 bsfb	(mvar6+0),1
	end_if
	if_f_b_s	(mvar5+0),2
	 bsfb	(mvar6+0),1
	end_if
	bsfb	(mvar6),0
	load_f16_f16	txt_int, mvar6
	bankblockend
	callp	sqrt_step
	callp	sqrt_step
	callp	sqrt_step
	callp	sqrt_step
	return

sqrt_step	
	banklabel
	load_f32_f32	mvar1, mvar5
	load_f16_f16	mvar2, txt_int
	clr_f16	(mvar2+2)
	callp	divf32f32f32
	clr_f16	(txt_int+2)
	add_f32_f32_f32	mvar3,txt_int, txt_int
	lsrfb	(txt_int+2),f
	rrfb	(txt_int+1),f
	rrfb	txt_int,f
	return
	
	#endif	; include_datalogger


; ***********************************************************************
; DATA LOGGER
; ***********************************************************************
	#ifdef	include_datalogger
set_S3
	banklabel
	if_f_b_s	dlog_stat,0	; Already started
	 if_f_eq_l	cmda3,.0	; stop
	  bcfb	dlog_stat,0	; stop measurement
	  bcfb	Stat_S0,0
	 end_if
	else_		; Stopped
	 if_f_eq_l	cmda3,.0
	  return
	 end_if
	 if_f_gt_l	cmda3,.3
	  return
	 end_if
	 bcfb	dlog_stat,0	; stop measurement
	 load_f_f	cmda3store, cmda3	; store a3, gets destroyed at datalog_init
	 callp	datalog_init
	 gotoif_f16_gt_l16	dlog_bpm,.504,ss32
	load_f_f	cmda3, cmda3store
	 if_f_eq_l	cmda3,.1	; start from scratch
	  load_f_l	dlog_pos,.0
	  load_f_l	dlog_posbit,0
	  load_f16_l16	dlog_posblock,.0
	  clr_f	dlog_stat
	 end_if
	 if_f_eq_l	cmda3,.2	; resume
	  clr_f	dlog_stat
	  if_f16_eq_l16	dlog_posblock,.0	; if dlog_posblock = 0, then go for finding the place
	   gotop	ss31
	  end_if
	  bsfb	dlog_stat,3	; set restart flag
	 end_if
	 if_f_eq_l	cmda3,.3	; find place in FLASH memory
ss31	banklabel
	  clr_f	dlog_stat
	  callp	datalog_findposblock 
	  ; now get get loop bit from previous block
	  callp	datalog_calcFAddress
	  sub_f16_l16_f16	FLASH_Address, .64, FLASH_Address
	  callp	read_i2c_flash
	  if_f_b_c	FLASH_Value,5
	   bsfb	dlog_stat,4
	  end_if
	  load_f_l	dlog_pos,.0
	  load_f_l	dlog_posbit,0
	  bsfb	dlog_stat,3	; set restart flag
	 end_if
	 bsfb	dlog_stat,0	; start measurement
	 bsfb	Stat_S0,0
	end_if
	return
ss32	banklabel	; error because bpm>504
	bsfb	dlog_stat,1	; error flag
	return

clear_statistics
	banklabel
	for_f_l_l	dlog_chcnt,.0, .14
	 load_w_f	dlog_chcnt
	 swapf	WREG,f
	 incf	WREG,w
	 load_f_w	dlog_tmp1
	 for_f_l_l	dlog_tmp2,0,.13
	  inc_f	dlog_tmp1
	  load_bk_li_l	.1,dlog_tmp1,.0
	 next_f	dlog_tmp2
	next_f	dlog_chcnt
	;bankblockstart
	load_f16_l16	Min_ch0,0xFFFF
	load_f16_l16	Min_ch1,0xFFFF
	load_f16_l16	Min_ch2,0xFFFF
	load_f16_l16	Min_ch3,0xFFFF
	load_f16_l16	Min_ch4,0xFFFF
	load_f16_l16	Min_ch5,0xFFFF
	load_f16_l16	Min_ch6,0xFFFF
	load_f16_l16	Min_ch7,0xFFFF
	load_f16_l16	Min_ch8,0xFFFF
	load_f16_l16	Min_ch9,0xFFFF
	load_f16_l16	Min_ch10,0xFFFF
	load_f16_l16	Min_ch11,0xFFFF
	load_f16_l16	Min_ch12,0xFFFF
	load_f16_l16	Min_ch13,0xFFFF
	load_f16_l16	Min_ch14,0xFFFF
	;bankblockend
	return

; copy row in chcnt to row 15 of statistics
copy_into_ch15
	banklabel
	for_f_l_l	dlog_tmp2,0,.15
	 load_w_f	dlog_chcnt
	 swapf	WREG,f
	 load_f_w	dlog_tmp1
	 add_f_f_f	dlog_tmp1, dlog_tmp2, dlog_tmp1
	 load_f_bk_li	(dlog_tmp2+1),.1,dlog_tmp1
	 load_w_f	dlog_tmp2
	 addlw	.240
	 load_f_w	dlog_tmp1
	 load_bk_li_f	.1,dlog_tmp1,(dlog_tmp2+1)	 
	next_f	dlog_tmp2
	return
	
; copy row 15 to row in chcnt of statistics
copy_from_ch15
	banklabel
	for_f_l_l	dlog_tmp2,0,.15
	 load_w_f	dlog_tmp2
	 addlw	.240
	 load_f_w	dlog_tmp1
	 load_f_bk_li	(dlog_tmp2+1),.1,dlog_tmp1
	 load_w_f	dlog_chcnt
	 swapf	WREG,f
	 load_f_w	dlog_tmp1
	 add_f_f_f	dlog_tmp1, dlog_tmp2, dlog_tmp1
	 load_bk_li_f	.1,dlog_tmp1,(dlog_tmp2+1)	 
	next_f	dlog_tmp2
	return

datalog_init
	banklabel
	bsfb	Stat_Z0,1	; Disable debug info
	bcfb	dlog_stat,2	; Clear missed measurement flag
	; first set the variables for statistics
	; clear pin variables
	for_f_l_l	dlog_chcnt,.0, .14
	 load_w_f	dlog_chcnt
	 swapf	WREG,f
	 load_f_w	dlog_tmp1
	 load_bk_li_l	.1,dlog_tmp1,.255	; 255 in pin_ch means no pin assigned 
	next_f	dlog_chcnt
	clr_f	dlog_chcnt
	for_f_l_l	dlog_exbits,.0, .21
	 load_w_f	dlog_exbits
	 lslf	WREG,f
	 lslf	WREG,f
	 load_f_w	dlog_tmp1
	 load_f_bk_li	(dlog_tmp2),.3,dlog_tmp1	; status 0 register
	 inc_f	dlog_tmp1
	 load_f_bk_li	(dlog_tmp2+1),.3,dlog_tmp1	; status 1 register
	 inc_f	dlog_tmp1
	 load_f_bk_li	(dlog_bpm),.3,dlog_tmp1	; status 2 register
	 load_w_f	dlog_chcnt
	 swapf	WREG,f
	 load_f_w	dlog_tmp1	; now address of Pin_chx
	 if_f_eq_l	(dlog_tmp2),.0	; input
	  gotop	dain1
	 end_if
	 if_f_eq_l	(dlog_tmp2),.1	; input
dain1:	banklabel
	  if_f_b_s	(dlog_tmp2+1),7	; datalog bit set
	   load_bk_li_f	.1, dlog_tmp1, dlog_exbits	; Pin_chx = pin
	   inc_f	dlog_tmp1
	   if_f_b_s	(dlog_tmp2+1),4	; latch bit set
	    load_bk_li_l	.1, dlog_tmp1, .8	; Bits_chx = 8 bits
	   else_
	    load_bk_li_l	.1, dlog_tmp1, .1	; Bits_chx = 1 bits
	   end_if
	   inc_f	dlog_chcnt
	   gotop	dain2
	  end_if
	 end_if
	 if_f_eq_l	(dlog_tmp2),.3	; ADC
	  if_f_b_s	(dlog_tmp2+1),7	; datalog bit set
	   load_bk_li_f	.1, dlog_tmp1, dlog_exbits	; Pin_chx = pin
	   inc_f	dlog_tmp1
	   load_bk_li_l	.1, dlog_tmp1, .10	; Bits_chx = 10 bit
	   if_f_b_s	(dlog_tmp2+1),1	; Avarage or sum?
	    if_f_ge_l	dlog_bpm,.2
	     load_bk_li_l	.1, dlog_tmp1, .11	; Bits_chx = 11 bit
	    end_if
	    if_f_ge_l	dlog_bpm,.4
	     load_bk_li_l	.1, dlog_tmp1, .12	; Bits_chx = 12 bit
	    end_if
	    if_f_ge_l	dlog_bpm,.8
	     load_bk_li_l	.1, dlog_tmp1, .13	; Bits_chx = 13 bit
	    end_if
	    if_f_ge_l	dlog_bpm,.16
	     load_bk_li_l	.1, dlog_tmp1, .14	; Bits_chx = 14 bit
	    end_if
	    if_f_ge_l	dlog_bpm,.32
	     load_bk_li_l	.1, dlog_tmp1, .15	; Bits_chx = 15 bit
	    end_if
	    if_f_ge_l	dlog_bpm,.64
	     load_bk_li_l	.1, dlog_tmp1, .16	; Bits_chx = 16 bit
	    end_if
	   end_if
	   inc_f	dlog_chcnt
	   gotop	dain2
	  end_if
	 end_if
	 if_f_eq_l	(dlog_tmp2),.4	; CPS
	  if_f_b_s	(dlog_tmp2+1),7	; datalog bit set
	   load_bk_li_f	.1, dlog_tmp1, dlog_exbits	; Pin_chx = pin
	   inc_f	dlog_tmp1
	   load_bk_li_l	.1, dlog_tmp1, .1	; Bits_chx = 8 bit
	   inc_f	dlog_chcnt
	   gotop	dain2
	  end_if
	 end_if
	 if_f_eq_l	dlog_chcnt, .16	; C0
	  if_f_eq_l	(dlog_tmp2),.6	; Timer@C0
	   if_f_b_s	(dlog_tmp2+1),7	; datalog bit set
	    load_bk_li_f	.1, dlog_tmp1, dlog_exbits	; Pin_chx = pin
	    inc_f	dlog_tmp1
	    load_bk_li_l	.1, dlog_tmp1, .16	; Bits_chx = 16 bit
	    inc_f	dlog_chcnt
	    ;gotop	dain2
	   end_if
	  end_if
	 end_if
dain2	
	banklabel
	 if_f_eq_l	dlog_chcnt,.15	; all channels already full
	  gotop	dain3
	 end_if	 
	next_f	dlog_exbits
dain3
	banklabel

	; Init C3 and C4 as I2C
	bankblockstart
	load_f_l	cmda1, .3		; SET
	load_f_l	cmda2, 0x13		; C3
	clrfb	(cmda2+1)
	load_f_l	cmda3,.6		; Special -> i2c
	clrfb	(cmda3+1)
	clrfb	cmda4		; No extra arguments
	clrfb	(cmda4+1)
	bankblockend
	callp	cmd_exec_nocmdln		; execute command

	if_f_msk_eq_l	Stat_S0,0xE0,0x00	; 000: 10 ms
	 load_f32_l32	dlog_mscountmax, .10
	end_if
	if_f_msk_eq_l	Stat_S0,0xE0,0x20	; 001: 100 ms
	 load_f32_l32	dlog_mscountmax, .100
	end_if
	if_f_msk_eq_l	Stat_S0,0xE0,0x40	; 010: 1000 ms (1 second)
	 load_f32_l32	dlog_mscountmax, .1000
	end_if
	if_f_msk_eq_l	Stat_S0,0xE0,0x60	; 011: 15000 ms (15 second)
	 load_f32_l32	dlog_mscountmax, .15000
	end_if
	if_f_msk_eq_l	Stat_S0,0xE0,0x80	; 100: 60000 ms (1 minute)
	 load_f32_l32	dlog_mscountmax, .60000
	end_if
	if_f_msk_eq_l	Stat_S0,0xE0,0xA0	; 101: 900000 ms (15 minute)
	 load_f32_l32	dlog_mscountmax, .900000
	end_if
	if_f_msk_eq_l	Stat_S0,0xE0,0xC0	; 110: 3600000 ms (1 hour)
	 load_f32_l32	dlog_mscountmax, .3600000
	end_if
	if_f_msk_eq_l	Stat_S0,0xE0,0xE0	; 111: 86400000 ms (1 day)
	 load_f32_l32	dlog_mscountmax, .86400000
	end_if

	if_f_msk_eq_l	Stat_S0,0x18,0x00	; 00: 1 measurements
	 load_f32_l32	dlog_mcountdownmax, .1
	 load_f_l	dlog_exbits, .0
	end_if
	if_f_msk_eq_l	Stat_S0,0x18,0x08	; 01: 64 measurements
	 load_f32_l32	dlog_mcountdownmax, .64
	 load_f_l	dlog_exbits, .6
	end_if
	if_f_msk_eq_l	Stat_S0,0x18,0x10	; 10: 2048 measurements
	 load_f32_l32	dlog_mcountdownmax, .2048
	 load_f_l	dlog_exbits, .16
	end_if
	if_f_msk_eq_l	Stat_S0,0x18,0x18	; 11: 4194304 measurements
	 load_f32_l32	dlog_mcountdownmax, .4194304
	 load_f_l	dlog_exbits, .22
	end_if

	div_f32_f32_f32	dlog_mscountmax, dlog_mcountdownmax, dlog_mscountmax
	if_f32_eq_l32	dlog_mscountmax, .0
	 load_f32_l32	dlog_mscountmax, .1
	end_if

	;load_f32_l32	dlog_mscountmax, (.480000/.256)
	;load_f16_l16	dlog_mcountdownmax, .256

	;else

	;load_f32_l32	dlog_mscountmax, .10
	;load_f16_l16	dlog_mcountdownmax, .256

	;endif

	load_f32_f32	dlog_mscountdown, dlog_mscountmax
	load_f32_f32	dlog_mcountdown, dlog_mcountdownmax


	; determine run number (0..15) by looking at last 4 bits of 64 byte block
	; get EEPROM address .0; get lowest 4 bits and increase

	; calculate bits per measurement
	clr_f16	dlog_bpm
	for_f_l_l	dlog_chcnt,.0, .14
	 callp	copy_into_ch15
	 if_f_ne_l	Pin_ch15,.255	; 255 in pin_ch means no pin assigned 
	  if_f_msk_eq_l	Stat_S1,.3,.3	; Store Sigma (1 bit) or avarage
	   gotoif_f_eq_l	Bits_ch15,.1,dain5
	   gotop	dain4
	  end_if
	  if_f_msk_eq_l	Stat_S1,.3,.2	; Store avarage
dain4	banklabel
	   add_f16_f_f16	dlog_bpm, Bits_ch15, dlog_bpm
	  end_if
	  if_f_msk_eq_l	Stat_S1,.3,.1	; Store Sigma
dain5	banklabel
	   add_f16_f_f16	dlog_bpm, Bits_ch15, dlog_bpm
	   add_f16_f_f16	dlog_bpm, dlog_exbits, dlog_bpm
	  end_if
	  if_f_b_s	Stat_S1,2	; Store Maximum
	   add_f16_f_f16	dlog_bpm, Bits_ch15, dlog_bpm
	  end_if
	  if_f_b_s	Stat_S1,3	; Store Minimum
	   add_f16_f_f16	dlog_bpm, Bits_ch15, dlog_bpm
	  end_if
	  if_f_b_s	Stat_S1,4	; Store Standard Deviation
	   add_f16_f_f16	dlog_bpm, Bits_ch15, dlog_bpm
	   ;add_f16_f_f16	dlog_bpm, dlog_exbits, dlog_bpm
	  end_if
	 end_if
	next_f	dlog_chcnt


	; Clear statistical variables
	callp	clear_statistics
	return

; datalog_trimbuffer shifts bits of last byte to upper bits
datalog_trimbuffer
	banklabel
	load_f_bk_li	dlog_tmp1, .2, dlog_lipos
	for_f_f_l	dlog_tmp2, dlog_posbit, .7
	 rlfb	dlog_tmp1,f
	next_f	dlog_tmp2
	load_bk_li_f	.2, dlog_lipos, dlog_tmp1
	return

; datalog_writetobuffer writes txt_bits number of bits of txt_int:4 to Flashbuffer	
datalog_writetobuffer
	banklabel
	load_w_f	dlog_pos		; calculate linear address in buffer
	iorlw	0xC0
	load_f_w	dlog_lipos
	; shift the bits to bit31 (the stupid way)
	for_f_f_l	dlog_tmp1, txt_bits, .31
	 bankset	txt_int
	 rlf	txt_int,f
	 rlf	txt_int+1,f
	 rlf	txt_int+2,f
	 rlf	txt_int+3,f
	 bankres	txt_int
	next_f	dlog_tmp1

	for_f_l_f	dlog_tmp2,.1,txt_bits	; rotate the bits into the buffer
	 load_f_bk_li	dlog_tmp1, .2, dlog_lipos
	 bankset	txt_int
	 rlf	txt_int,f
	 rlf	txt_int+1,f
	 rlf	txt_int+2,f
	 rlf	txt_int+3,f
	 bankres	txt_int
	 rlfb	dlog_tmp1,f
	 load_bk_li_f	.2, dlog_lipos, dlog_tmp1
	 inc_f	dlog_posbit
	 if_f_gt_l	dlog_posbit,.7
	  clr_f	dlog_posbit
	  inc_f	dlog_pos
	  inc_f	dlog_lipos
	 end_if
	next_f	dlog_tmp2
	return

datalog_measure
	banklabel
	; check if buffer empty -> make header
	if_f_eq_l	dlog_pos,.0		; write header?
	 if_f_eq_l	dlog_posbit,.0
	  ; make first block?
	  if_f16_eq_l16	dlog_posblock,.0
	   callp	datalog_writeinitblock
	  end_if
	  ; make header
	  callp	datalog_makerunID
	  ;load_f_f	txt_int, dlog_runnmb
	  load_f_l	txt_bits,.8
	  callp	datalog_writetobuffer
	 end_if
	end_if
	
	if_f_b_s	Stat_S1, 7	; Blink LED?
	 load_f_l	cmda1,.3	; SET
	 load_f16_l16	cmda2,.8	; B0
	 load_f_l	cmda3,.2	; output
	 load_f_l	cmda4,.1	; on
	 load_f_l	nofargs,.4
	 callp	cmd_exec_nocmdln
	end_if

	for_f_l_l	dlog_chcnt,.0,.14
	 callp	copy_into_ch15
	 if_f_ne_l	Pin_ch15,.255
	  load_f_l	cmda1,.2	; READ
	  load_f_f	cmda2,Pin_ch15
	  clr_f	(cmda2+1)
	  load_f_l	nofargs,.2
	  clr_f	(txt_int+1)
	  ;clr_f	(txt_int+2)
	  ;clr_f	(txt_int+3)
	  bsfb	cmdstat,0	; output only to txt_int
	  callp	cmd_exec_nocmdln	; now result in txt_int
	  bcfb	cmdstat,0
	  clr_f16	(txt_int+2)
	  add_f32_f32_f32	Sigma_ch15, txt_int, Sigma_ch15
	  if_f_b_s	Stat_S1,2	; Calculate Maximum
	   if_f16_gt_f16	txt_int, Max_ch15
	    load_f16_f16	Max_ch15, txt_int
	   end_if
	  end_if
	  if_f_b_s	Stat_S1,3	; Calculate Minimum
	   if_f16_lt_f16	txt_int, Min_ch15
	    load_f16_f16	Min_ch15, txt_int
	   end_if
	  end_if
	  if_f_b_s	Stat_S1,4	; Calculate Standard Deviation
	   subsqr_f16_f32	txt_int, txt_int
	   add_f32_f32_f32	Sigma2_ch15, txt_int, Sigma2_ch15
	  end_if
	  callp	copy_from_ch15
	 else_
	  gotop	dame1	; skip rest of channels
	 end_if
	next_f	dlog_chcnt	
dame1
	banklabel
	if_f_b_s	Stat_S1, 7	; Blink LED?
	 load_f_l	cmda1,.1	; SET
	 load_f16_l16	cmda2,.8	; B0
	 load_f_l	cmda3,.0	; off
	 load_f_l	nofargs,.3
	 callp	cmd_exec_nocmdln
	end_if

	; calculate mcountdown
	dec_f32	dlog_mcountdown
	if_f32_eq_l32	dlog_mcountdown, .0
	 ; Calculate statistics and store in buffer
	 for_f_l_l	dlog_chcnt,.0,.13
	  callp	copy_into_ch15
	  if_f_ne_l	Pin_ch15,.255
;  S1: statistics
;    bit<0:1> 01: Store Sigma measurements, 10: Store avarage of measurements, 11 store Sigma for 1 bit input, avarage for rest 
;    bit2: 1: Store maximum value
;    bit3: 1: Store minimum value
;    bit4: 1: Store standard deviation
	   if_f_msk_eq_l	Stat_S1,.3,.3	; Store Sigma (1 bit) or avarage
	    gotoif_f_eq_l	Bits_ch15,.1,dame3
	    gotop	dame4
	   end_if
	   if_f_msk_eq_l	Stat_S1,.3,.2	; Store avarage
dame4	banklabel
	    gotoif_f32_eq_l32	dlog_mcountdownmax, .1, dame3	; skip div if only one measurement
	    load_f_f	txt_bits, Bits_ch15
	    load_f32_f32	txt_int, Sigma_ch15
	    div_f32_f32_f32	txt_int, dlog_mcountdownmax, txt_int
	    callp	datalog_writetobuffer
	   end_if
	   if_f_msk_eq_l	Stat_S1,.3,.1	; Store Sigma
dame3	banklabel
	    load_f_f	txt_bits, Bits_ch15
	    add_f_f_f	txt_bits, dlog_exbits, txt_bits
	    load_f32_f32	txt_int, Sigma_ch15
	    callp	datalog_writetobuffer
	   end_if
	   if_f_b_s	Stat_S1,2	; Store Maximum
	    load_f_f	txt_bits, Bits_ch15
	    load_f16_f16	txt_int, Max_ch15
	    callp	datalog_writetobuffer
	   end_if
	   if_f_b_s	Stat_S1,3	; Store Minimum
	    load_f_f	txt_bits, Bits_ch15
	    load_f16_f16	txt_int, Min_ch15
	    callp	datalog_writetobuffer
	   end_if
	   if_f_b_s	Stat_S1,4	; Store Standard Deviation
	    ; SD = sqrt( (S2 -(S)2/n )/n )
	    subsqr_f16_f32	Sigma_ch15, mvar5
	    subdiv_f32_f32_f32	mvar5, dlog_mcountdownmax, mvar6
	    sub_f32_f32_f32	Sigma2_ch15, mvar6, mvar5
	    subdiv_f32_f32_f32	mvar5, dlog_mcountdownmax, mvar5
	    callp	sqrt_mvar5_txt_int 
	    load_f_f	txt_bits, Bits_ch15
	    ;add_f_f_f	txt_bits, dlog_exbits, txt_bits
	    callp	datalog_writetobuffer
	   end_if
	  
	  else_
	   gotop	dame2	; skip rest of channels
	  end_if
	 next_f	dlog_chcnt	
dame2
	banklabel
	 ; reset mcountdown
	 load_f32_f32	dlog_mcountdown, dlog_mcountdownmax
	 callp	clear_statistics
	end_if

	; check whether buffer is full (less than dlog_bpm in buffer left)
	; calculate bits if extra measurements: tmp2=pos*8+posbit+bpm <=512
	load_f_f	dlog_tmp2, dlog_pos
	clrfb	(dlog_tmp2+1)
	lslfb	dlog_tmp2, f	; multiply * 8
	rlfb	(dlog_tmp2+1), f 
	lslfb	dlog_tmp2, f
	rlfb	(dlog_tmp2+1), f
	lslfb	dlog_tmp2, f
	rlfb	(dlog_tmp2+1), f
	add_f16_f_f16	dlog_tmp2, dlog_posbit, dlog_tmp2	; add posbits 	
	add_f16_f16_f16	dlog_tmp2, dlog_bpm, dlog_tmp2		; add bpm 	
	if_f16_gt_l16	dlog_tmp2,.512
	 ; no space for extra measurements: write buffer to I2C (512 is still OK)
	 callp	datalog_trimbuffer	; shift bits of last byte to highest bit position
	 callp	datalog_calcFAddress
	 callp	write_buf_i2c_flash	; and write to i2c
	 clrfb	dlog_pos		; now adjust counters
	 clrfb	dlog_posbit
	 inc_f16	dlog_posblock
	 if_f16_ge_l16	dlog_posblock, .512	; check end of memory
	  if_f_b_s	Stat_S0,1		; continue after memory full?
	   clr_f16	dlog_posblock
	   bsfb	dlog_stat,4		; indicate looped
	  else_			; not continue after memory is full
	   bcfb	Stat_S0,0		; stop datalogging
	   bcfb	dlog_stat,0	
	   load_f16_l16	dlog_posblock,.0
	  end_if ; S0,1
	 end_if ; posblock>=512
	end_if ; tmp1>=64
	return

datalog_writeinitblock
	banklabel
	callp	datalog_makerunID
	load_f_f	(FlashBuffer+.0), txt_int
	load_f_f	(FlashBuffer+.1), Stat_S0
	load_f_f	(FlashBuffer+.2), Stat_S1
	load_f_f	(FlashBuffer+.3), dlog_exbits
	load_f16_f16	(FlashBuffer+.4), dlog_bpm
	load_f32_f32	(FlashBuffer+.6), dlog_mcountdownmax
	load_f32_f32	(FlashBuffer+.10), dlog_mscountmax

	load_f16_f16	(FlashBuffer+.64), Pin_ch0
	load_f16_f16	(FlashBuffer+.66), Pin_ch1	; plus 64 because of bank 
	load_f16_f16	(FlashBuffer+.68), Pin_ch2
	load_f16_f16	(FlashBuffer+.70), Pin_ch3
	load_f16_f16	(FlashBuffer+.72), Pin_ch4
	load_f16_f16	(FlashBuffer+.74), Pin_ch5
	load_f16_f16	(FlashBuffer+.76), Pin_ch6
	load_f16_f16	(FlashBuffer+.78), Pin_ch7
	load_f16_f16	(FlashBuffer+.80), Pin_ch8
	load_f16_f16	(FlashBuffer+.82), Pin_ch9
	load_f16_f16	(FlashBuffer+.84), Pin_ch10
	load_f16_f16	(FlashBuffer+.86), Pin_ch11
	load_f16_f16	(FlashBuffer+.88), Pin_ch12
	load_f16_f16	(FlashBuffer+.90), Pin_ch13
	load_f16_f16	(FlashBuffer+.92), Pin_ch14
	clr_f16	FLASH_Address
	callp	write_buf_i2c_flash	; and write to i2c
	; new position
	clr_f	dlog_pos
	clr_f	dlog_posbit
	load_f16_l16	dlog_posblock,.1
	return

; datalog_makerunID - calculates runID and put in txt_int
datalog_makerunID
	banklabel
	; runnumber: 
	;  bit 0..2: runnumber (0..7)
	;  bit3: flag for missed measurement (bit2 of dlog_stat)
	;  bit4: flag for pause / restart (bit3 of dlog_stat)
	;  bit5: loop flag (bit4 of dlog_stat)
	;  bit6: inverse of bit 7 in next block
	;  bit7: copy of bit 6 in previous block
	clr_f16	FLASH_Address		; first get runnumber (lowest three bits)
	callp	read_i2c_flash
	if_f16_eq_l16	dlog_posblock,.0
	 inc_f	FLASH_Value		; inc if new 0-block is written, otherwise copy of present 0 block
	end_if
	load_w_f	FLASH_Value
	andlw	b'00000111'
	load_f_w	txt_int		
	; Now run number in lowest three bits in txt_int
	; Continue with bits 3..5
	load_w_f	dlog_stat
	rlf	WREG,w
	andlw	b'00111000'
	bankset	txt_int
	iorwf	txt_int, f
	bankres	txt_int
	; Now also bit 3..5 set
 	; Calculate bits 6 and 7
	callp	datalog_calcFAddress
	sub_f16_l16_f16	FLASH_Address, .64, FLASH_Address
;	bcfb	(FLASH_Address+1),7	; not needed, 24FC256 ignores address bit 15
	callp	read_i2c_flash
	if_f_b_c	FLASH_Value,6
	 bcfb	txt_int,7
	else_
	 bsfb	txt_int,7
	end_if
	add_f16_l16_f16	FLASH_Address, .128, FLASH_Address
;	bcfb	(FLASH_Address+1),7	; not needed, 24FC256 ignores address bit 15
	callp	read_i2c_flash
	if_f_b_s	FLASH_Value,7
	 bcfb	txt_int,6
	else_
	 bsfb	txt_int,6
	end_if
	bcfb	dlog_stat,3	; reset restart flag (only one time per restart stored)
	return

datalog_findposblock
	banklabel
	clr_f16	dlog_posblock
	callp	datalog_calcFAddress
	callp	read_i2c_flash
	load_f_f	dlog_tmp1, FLASH_Value
dafi1	banklabel
	inc_f16	dlog_posblock	
	callp	datalog_calcFAddress
	callp	read_i2c_flash
	load_w_f	dlog_tmp1	; xor the relevant bits of the two RunIDs
	rlf	WREG,w
	xorwfb	FLASH_Value,w
	if_f_b_s	WREG,7	; bits differ -> dlog_posblock is the right position
	 return
	end_if
	if_f16_eq_l16	dlog_posblock,.511	; end reached
	 clr_f16	dlog_posblock		; start at 0
	 return
	end_if
	load_f_f	dlog_tmp1, FLASH_Value
	gotop	dafi1
	
	

; datalog_calcFAddress - calculate from block-number in dlog_posblock address (first address of 64 byte block) into FLASH_Address
datalog_calcFAddress
	banklabel
	load_f16_f16	FLASH_Address, dlog_posblock	; generate I2C address (64 * posblock)
	;bankblockstart
	lslfb	FLASH_Address,f
	rlfb	(FLASH_Address+1), f
	lslfb	FLASH_Address,f
	rlfb	(FLASH_Address+1), f
	lslfb	FLASH_Address,f
	rlfb	(FLASH_Address+1), f
	lslfb	FLASH_Address,f
	rlfb	(FLASH_Address+1), f
	lslfb	FLASH_Address,f
	rlfb	(FLASH_Address+1), f
	lslfb	FLASH_Address,f
	rlfb	(FLASH_Address+1), f
	;bankblockend
	return

	#endif	; include_datalogger


	ifdef	debug_mplabsim
; DEBUG 
debugcommands	
	banklabel
	load_f_l	cmdbfl,.6	; pos after last character
	load_f_l	cmdbf0+.0,'S'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'A'
	load_f_l	cmdbf0+.3,'0'
	load_f_l	cmdbf0+.4,' '
	load_f_l	cmdbf0+.5,'3'
	;callp	cmdparse

	load_f_l	cmdbfl,.9	; pos after last character
	load_f_l	cmdbf0+.0,'S'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'A'
	load_f_l	cmdbf0+.3,'0'
	load_f_l	cmdbf0+.4,'1'
	load_f_l	cmdbf0+.5,' '
	load_f_l	cmdbf0+.6,'1'
	load_f_l	cmdbf0+.7,'2'
	load_f_l	cmdbf0+.8,'8'
	;callp	cmdparse

	banklabel
	load_f_l	cmdbfl,.6	; pos after last character
	load_f_l	cmdbf0+.0,'S'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'B'
	load_f_l	cmdbf0+.3,'3'
	load_f_l	cmdbf0+.4,' '
	load_f_l	cmdbf0+.5,'3'
	callp	cmdparse

	load_f_l	cmdbfl,.9	; pos after last character
	load_f_l	cmdbf0+.0,'S'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'B'
	load_f_l	cmdbf0+.3,'3'
	load_f_l	cmdbf0+.4,'1'
	load_f_l	cmdbf0+.5,' '
	load_f_l	cmdbf0+.6,'1'
	load_f_l	cmdbf0+.7,'2'
	load_f_l	cmdbf0+.8,'8'
	callp	cmdparse

	load_f_l	cmdbfl,.8	; pos after last character
	load_f_l	cmdbf0+.0,'S'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'S'
	load_f_l	cmdbf0+.3,'0'
	load_f_l	cmdbf0+.4,' '
	load_f_l	cmdbf0+.5,'1' ; 74 / 110
	load_f_l	cmdbf0+.6,'1'
	load_f_l	cmdbf0+.7,'0'
	callp	cmdparse

	load_f_l	cmdbfl,.8	; pos after last character
	load_f_l	cmdbf0+.0,'S'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'S'
	load_f_l	cmdbf0+.3,'1'
	load_f_l	cmdbf0+.4,' '
	load_f_l	cmdbf0+.5,'2'
	load_f_l	cmdbf0+.6,'5'
	load_f_l	cmdbf0+.7,'5'
	load_f_l	cmdbf0+.8,' '
	callp	cmdparse

	load_f_l	cmdbfl,.6	; pos after last character
	load_f_l	cmdbf0+.0,'S'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'S'
	load_f_l	cmdbf0+.3,'3'
	load_f_l	cmdbf0+.4,' '
	load_f_l	cmdbf0+.5,'1'
	load_f_l	cmdbf0+.6,' '
	callp	cmdparse

	load_f_l	cmdbfl,.4	; pos after last character
	load_f_l	cmdbf0+.0,'R'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'B'
	load_f_l	cmdbf0+.3,'3'
	load_f_l	cmdbf0+.4,' '
	load_f_l	cmdbf0+.5,'3'
;	callp	cmdparse


	load_f_l	cmdbfl,.8	; pos after last character
	load_f_l	cmdbf0+.0,'S'
	load_f_l	cmdbf0+.1,' '
	load_f_l	cmdbf0+.2,'S'
	load_f_l	cmdbf0+.3,'0'
	load_f_l	cmdbf0+.4,' '
	load_f_l	cmdbf0+.5,'1'
	load_f_l	cmdbf0+.6,'6'
	load_f_l	cmdbf0+.7,'9'
;	callp	cmdparse

	return
	endif


; ***********************************************************************
; TEXT
; ***********************************************************************
	ifndef	debugsavemem
DEV_device	dt	"Device: ",0
DEV_unknown	dt	"unknown",0
DEV_PIC16F1938	dt	"PIC16F1938",0
DEV_PIC16F1939	dt	"PIC16F1939",0
DEV_PIC16LF1938	dt	"PIC16LF1938",0
DEV_PIC16LF1939	dt	"PIC16LF1939",0
DEV_version	dt	", version: ",0
DEV_A1	dt	"A1",.10,0
DEV_A2	dt	"A2",.10,0
DEV_A3	dt	"A3",.10,0
DEV_int_ov	dt	"Interrupt overflow detected!",.10,0
DEV_int_noov	dt	"No interrupt overflow detected.",.10,0
TXT_LWOK	dt	"L W_OK",.10,0
TXT_LZ3OK	dt	"L Z3_OK",.10,0
TXT_LSOK	dt	"L S_OK",.10,0
TXT_LParseError	dt	"L parse_error",.10,0
TXT_GZ310	dt	"G Z3 10 ",0
TXT_GZ312	dt	"G Z3 12 ",0
	else
DEV_device	dt	" ",0
DEV_unknown	dt	" ",0
DEV_PIC16F1938	dt	" ",0
DEV_PIC16F1939	dt	" ",0
DEV_PIC16LF1938	dt	" ",0
DEV_PIC16LF1939	dt	" ",0
DEV_version	dt	" ",0
DEV_A1	dt	" ",0
DEV_A2	dt	" ",0
DEV_A3	dt	" ",0
DEV_int_ov	dt	" ",0
DEV_int_noov	dt	" ",0
TXT_LWOK	dt	" ",0
TXT_LZ3OK	dt	" ",0
TXT_LSOK	dt	" ",0
TXT_LParseError	dt	" ",0
TXT_GZ310	dt	" ",0
TXT_GZ312	dt	" ",0
	endif




lastmemuse
	messg Last location: #v(lastmemuse)
	END
