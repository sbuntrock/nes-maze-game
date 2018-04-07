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

PLAYER_ADDRESS = $0200
BUTTON_A       = %10000000
BUTTON_B       = %01000000
BUTTON_SELECT  = %00100000
BUTTON_START   = %00010000
BUTTON_UP      = %00001000
BUTTON_DOWN    = %00000100
BUTTON_LEFT    = %00000010
BUTTON_RIGHT   = %00000001

;__      __        
;\ \    / /        
; \ \  / /_ _ _ __ 
;  \ \/ / _` | '__|
;   \  / (_| | |   
;    \/ \__,_|_|   
                   
  .rsset $000
playerx      .rs 1
playery      .rs 1
controller1  .rs 1  ; player 1 buttons

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
  
  LDA #$20
  STA playerx
  STA playery

LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$10              ; Compare X to hex $20, decimal 32
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 32, keep going down

LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address
  LDX #$00              ; start out at 0
LoadBackgroundLoop:
  LDA background, x     ; load data from address (background + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$FF              ; Compare X to hex $80, decimal 128 - copying 128 bytes
  BNE LoadBackgroundLoop  ; Branch to LoadBackgroundLoop if compare was Not Equal to zero
                        ; if compare was equal to 128, keep going down

LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0

LoadAttributeLoop:
  LDA attribute, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$08              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttributeLoop

  LDA #%10000000   ; enable NMI, sprites
  STA $2000

  LDA #%00011110   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ; Loop forever

NMI: ;Setup Sprite DMA Transfer
  LDA #$00
  STA $2003
  LDA #$02
  STA $4014

  JSR UpdatePlayer

  JSR ReadController1

  JSR PaletteSwap
  JSR GoRight
  JSR GoLeft
  JSR GoUp
  JSR GoDown

 ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005

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
  ROL controller1  ; bit0 <- Carry
  DEX
  BNE ReadController1Loop
  RTS

UpdatePlayer:
  LDA playery
  STA PLAYER_ADDRESS
  STA PLAYER_ADDRESS+4
  CLC
  ADC #$08
  STA PLAYER_ADDRESS+8
  STA PLAYER_ADDRESS+12

  LDA playerx
  STA PLAYER_ADDRESS+3
  STA PLAYER_ADDRESS+11
  CLC
  ADC #$08
  STA PLAYER_ADDRESS+7
  STA PLAYER_ADDRESS+15
  RTS

PaletteSwap:
  LDA controller1
  AND #BUTTON_B
  BEQ PaletteSwapDone
  LDA #%00000001
  STA PLAYER_ADDRESS+2
  STA PLAYER_ADDRESS+10
  LDA #%01000001
  STA PLAYER_ADDRESS+6
  STA PLAYER_ADDRESS+14
PaletteSwapDone:
  RTS

GoRight:
  LDA controller1
  AND #BUTTON_RIGHT
  BEQ GoRightDone
  LDA playerx
  CLC
  ADC #$01 ;(A + M + Carryflag)
  STA playerx
GoRightDone:
  RTS

GoLeft:
  LDA controller1
  AND #BUTTON_LEFT
  BEQ GoLeftDone
  LDA playerx
  SEC
  SBC #$01 
  STA playerx
GoLeftDone:
  RTS

GoUp:
  LDA controller1
  AND #BUTTON_UP
  BEQ GoUpDone
  LDA playery
  SEC
  SBC #$01 
  STA playery
GoUpDone:
  RTS

GoDown:
  LDA controller1
  AND #BUTTON_DOWN
  BEQ GoDownDone
  LDA playery
  CLC
  ADC #$01 ;(A + M + Carryflag)
  STA playery
GoDownDone:
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

sprites: ;y,tile,attr,x
  .db $F9, $44, %00000000, $00 ;Player 1
  .db $F9, $44, %01000000, $00 ;Player 2
  .db $F9, $45, %00000000, $00 ;Player 3
  .db $F9, $45, %01000000, $00 ;Player 4

background:
  .incbin "game.nam"

attribute:
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000


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
  .incbin "game.chr"