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

LoadPalettes:
  LDA $2002    ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006    ; write the high byte of $3F00 address
  LDA #$00
  STA $2006    ; write the low byte of $3F00 address
  LDX #$00    
loadPaletteLoop:
  LDA palette, x      
  STA $2007               
  INX                     
  CPX #$20                
  BNE loadPaletteLoop    

  LDA #$80
  STA $0200        ; put sprite 0 in center ($80) of screen vert
  STA $0203        ; put sprite 0 in center ($80) of screen horiz
  LDA #$05
  STA $0201        ; tile number = 0
  STA $0202        ; color = 0, no flipping

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ; Loop forever

NMI:
  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer
  RTI

; ____              _      __ 
;|  _ \            | |    /_ |
;| |_) | __ _ _ __ | | __  | |
;|  _ < / _` | '_ \| |/ /  | |
;| |_) | (_| | | | |   <   | |
;|____/ \__,_|_| |_|_|\_\  |_|
                              
                            
  .bank 1
  .org $E000
palette:
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
  .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

  .org $FFFA     ;Interrupts
  .dw NMI        
  .dw RESET      
  .dw 0          ;IRQ is not used
  
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