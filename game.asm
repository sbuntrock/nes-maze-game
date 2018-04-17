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
MOVE_DELAY     = $08

;__      __        
;\ \    / /        
; \ \  / /_ _ _ __ 
;  \ \/ / _` | '__|
;   \  / (_| | |   
;    \/ \__,_|_|   
                   
  .rsset $000
playerx         .rs 1
playery         .rs 1
gridx           .rs 1
gridy           .rs 1
controller1     .rs 1  ; player 1 buttons
backroundptr    .rs 2  ; 16 bit
playermovedelay .rs 1
leveldata       .rs 180
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

LoadLevel:
  LDX #$00
LoadlevelLoop:
  LDA level1, x
  STA leveldata, x
  INX
  CPX #$B4
  BNE LoadlevelLoop

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
  
  LDA #$00 ;00
  STA playerx
  LDA #$00 ;20
  STA playery
  LDA #$00
  STA playermovedelay
  STA gridx
  STA gridy

LoadSprites:
  LDX #$00
LoadSpritesLoop:
  LDA sprites, x
  STA $0200, x
  INX
  CPX #$10
  BNE LoadSpritesLoop

LoadBackground:
  LDA $2002              ;Reset PPU Latch
  LDA #$20 
  STA $2006
  LDA #$00
  STA $2006              ;Set background location to $2000

  LDA #LOW(background)
  STA backroundptr+0

  LDA #HIGH(background)
  STA backroundptr+1

  LDX #$04               ;4 outer loops with 256 inner loops 4*256-1024
  LDY #$00
LoadBackgroundLoop:
  LDA [backroundptr+0], y
  STA $2007
  INY
  BNE LoadBackgroundLoop ;Loop 256 times until resets to zero
  INC backroundptr+1
  DEX
  BNE LoadBackgroundLoop

LoadAttribute:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadAttributeLoop:
  LDA background+960, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$40              ; Compare X to hex $08, decimal 8 - copying 8 bytes
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

  JSR GridToPlayer
  JSR UpdatePlayer

  JSR ReadController1
  JSR PaletteSwap
  JSR PlayerMove

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

PlayerMove: ;Movement code
  LDA playermovedelay
  BNE PlayerMoveDelayed

PlayerMoveRight:
  LDA controller1
  AND #BUTTON_RIGHT
  BEQ PlayerMoveRightDone
  LDA #MOVE_DELAY
  STA playermovedelay
  LDA gridx
  CLC
  ADC #$01 ;(A + M + Carryflag)
  STA gridx
PlayerMoveRightDone:

PlayerMoveLeft:
  LDA controller1
  AND #BUTTON_LEFT
  BEQ PlayerMoveLeftDone
  LDA #MOVE_DELAY
  STA playermovedelay
  LDA gridx
  SEC
  SBC #$01 
  STA gridx
PlayerMoveLeftDone:

PlayerMoveUp:
  LDA controller1
  AND #BUTTON_UP
  BEQ PlayerMoveUpDone
  LDA #MOVE_DELAY
  STA playermovedelay
  LDA gridy
  SEC
  SBC #$01
  STA gridy
PlayerMoveUpDone:

PlayerMoveDown:
  LDA controller1
  AND #BUTTON_DOWN
  BEQ PlayerMoveDownDone
  LDA #MOVE_DELAY
  STA playermovedelay
  LDA gridy
  CLC
  ADC #$01 ;(A + M + Carryflag)
  STA gridy
PlayerMoveDownDone:
  RTS

PlayerMoveDelayed:
  DEC playermovedelay
  RTS

GridToPlayer:
  LDA #$08 ; origin x for grid
  LDX gridx
  BEQ GridXLoopDone
GridXLoop:
  CLC
  ADC #$10
  DEX
  BNE GridXLoop
GridXLoopDone:
  STA playerx
  LDA #$20
  LDX gridy
  BEQ GridYLoopDone
GridYLoop:
  CLC
  ADC #$10
  DEX
  BNE GridYLoop
GridYLoopDone:
  STA playery
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
  .incbin "data/background.pal"
  .incbin "data/sprite.pal"

sprites: ;y,tile,attr,x
  .db $F9, $44, %00000000, $00 ;Player 1
  .db $F9, $44, %01000000, $00 ;Player 2
  .db $F9, $45, %00000000, $00 ;Player 3
  .db $F9, $45, %01000000, $00 ;Player 4

background: ; including attribute table
  .incbin "data/game.nam"

level1: ;12x15
  .db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF



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
  .incbin "data/game.chr"