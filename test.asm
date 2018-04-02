	.inesprg 1   ; 16KB PRG code
	.ineschr 1   ; 8KB CHR data
	.inesmap 0   ; Mapper 0
	.inesmir 1   ; Background mirroring
 

; ____              _       ___  
;|  _ \            | |     / _ \ 
;| |_) | __ _ _ __ | | __ | | | |
;|  _ < / _` | '_ \| |/ / | | | |
;| |_) | (_| | | | |   <  | |_| |
;|____/ \__,_|_| |_|_|\_\  \___/ 
                                 
	.bank 0
	.org $C000

vblankwait:       
	BIT $2002
	BPL vblankwait
	RTS

RESET:
	SEI          ; disable IRQs
	CLD          ; disable decimal mode
	LDX #$40
	STX $4017    ; disable APU frame IRQ
	LDX #$FF
	TXS          ; Set up stack
	INX          ; now X = 0
	STX $2000    ; disable NMI
	STX $2001    ; disable rendering
	STX $4010    ; disable DMC IRQs

	JSR vblankwait

clrmem:
	LDA #$00
	STA $0000, x
	STA $0100, x
	STA $0200, x
	STA $0400, x
	STA $0500, x
	STA $0600, x
	STA $0700, x
	LDA #$FE
	STA $0300, x
	INX
	BNE clrmem
   
	JSR vblankwait

	LDA #%00100000   ; Set PPU To RED
	STA $2001

Forever:
	JMP Forever     ; Loop forever

NMI:
	RTI

; ____              _      __ 
;|  _ \            | |    /_ |
;| |_) | __ _ _ __ | | __  | |
;|  _ < / _` | '_ \| |/ /  | |
;| |_) | (_| | | | |   <   | |
;|____/ \__,_|_| |_|_|\_\  |_|

                          
	.bank 1
	.org $FFFA     ;first of the three vectors starts here
	.dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
	.dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
	.dw 0          ;external interrupt IRQ is not used in this tutorial
  
; ____              _      ___  
;|  _ \            | |    |__ \ 
;| |_) | __ _ _ __ | | __    ) |
;|  _ < / _` | '_ \| |/ /   / / 
;| |_) | (_| | | | |   <   / /_ 
;|____/ \__,_|_| |_|_|\_\ |____|
  
	.bank 2
	.org $0000
	.incbin "sprite.chr"
	.incbin "background.chr"