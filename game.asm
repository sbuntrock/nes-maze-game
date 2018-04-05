; __  __                  _____                      
;|  \/  |                / ____|                     
;| \  / | __ _ _______  | |  __  __ _ _ __ ___   ___ 
;| |\/| |/ _` |_  / _ \ | | |_ |/ _` | '_ ` _ \ / _ \
;| |  | | (_| |/ /  __/ | |__| | (_| | | | | | |  __/
;|_|  |_|\__,_/___\___|  \_____|\__,_|_| |_| |_|\___|
                                                                                                       
  .inesprg 1   ; 16KB PRG code
  .ineschr 1   ; 8KB CHR data
  .inesmap 0   ; Mapper 0
  .inesmir 1   ; Background mirroring

;  _____                _   
; / ____|              | |  
;| |     ___  _ __  ___| |_ 
;| |    / _ \| '_ \/ __| __|
;| |___| (_) | | | \__ \ |_ 
; \_____\___/|_| |_|___/\__|
                            
BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_SELECT = %00100000
BUTTON_START  = %00010000
BUTTON_UP     = %00001000
BUTTON_DOWN   = %00000100
BUTTON_LEFT   = %00000010
BUTTON_RIGHT  = %00000001

;__      __        
;\ \    / /        
; \ \  / /_ _ _ __ 
;  \ \/ / _` | '__|
;   \  / (_| | |   
;    \/ \__,_|_|   
                   
  .rsset $000
guyx .rs 1
guyy .rs 1
controller1   .rs 1  ; player 1 buttons

; ____              _       ___  
;|  _ \            | |     / _ \ 
;| |_) | __ _ _ __ | | __ | | | |
;|  _ < / _` | '_ \| |/ / | | | |
;| |_) | (_| | | | |   <  | |_| |
;|____/ \__,_|_| |_|_|\_\  \___/ 
                                 
  .bank 0
  .org $C000

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
  JSR VBlankWait

Clrmem:
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
  BNE Clrmem
  JSR VBlankWait

LoadPalettes:
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006
  LDX #$00    
LoadPaletteLoop:
  LDA palette, x
  STA $2007
  INX
  CPX #$20
  BNE LoadPaletteLoop
  
  LDA $80
  STA guyx
  STA guyy

loadSprites:
  LDX #$00              ; start at 0
loadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$20              ; Compare X to hex $20, decimal 32
  BNE loadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

  LDA #%10000000   ; enable NMI, sprites
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ; Loop forever

NMI: ;Setup Sprite DMA Transfer
  LDA #$00
  STA $2003
  LDA #$02
  STA $4014

  JSR ReadController1

  LDA controller1
  AND #BUTTON_B
  BNE PaletteSwap

  RTI

VBlankWait:       
  BIT $2002
  BPL VBlankWait
  RTS

ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
ReadController1Loop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL controller1     ; bit0 <- Carry
  DEX
  BNE ReadController1Loop
  RTS

PaletteSwap:
  LDA #%00000001
  STA $0202
  STA $020A
  LDA #%01000001
  STA $0206
  STA $020E
  RTS

; ____              _      __ 
;|  _ \            | |    /_ |
;| |_) | __ _ _ __ | | __  | |
;|  _ < / _` | '_ \| |/ /  | |
;| |_) | (_| | | | |   <   | |
;|____/ \__,_|_| |_|_|\_\  |_|
                              
                            
  .bank 1
  .org $E000
palette:
  .db $0F,$20,$10,$00 , $0F,$35,$36,$37 , $0F,$39,$3A,$3B , $0F,$3D,$3E,$0F  ;background palette data
  .db $0F,$3C,$2C,$1C , $0F,$25,$15,$05 , $0F,$3A,$2A,$1A , $0F,$02,$38,$3C  ;sprite palette data

sprites:
  .db $80, $44, %00000000, $80 ;Guy 1
  .db $80, $44, %01000000, $88 ;Guy 2
  .db $88, $45, %00000000, $80 ;Guy 3
  .db $88, $45, %01000000, $88 ;Guy 4

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