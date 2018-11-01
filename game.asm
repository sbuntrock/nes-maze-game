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
STATE_START    = $00
STATE_PLAYING  = $01
STATE_END      = $02
NTSC_MODE      = $01

;FamiTone2 settings

FT_BASE_ADR   = $0300 ;page in the RAM used for FT2 variables, should be $xx00
FT_TEMP     = $00 ;3 bytes in zeropage used by the library as a scratchpad
FT_DPCM_OFF   = $c000 ;$c000..$ffc0, 64-byte steps
FT_SFX_STREAMS  = 4   ;number of sound effects played at once, 1..4

;FT_DPCM_ENABLE      ;undefine to exclude all DMC code
;FT_SFX_ENABLE     ;undefine to exclude all sound effects code
;FT_THREAD       ;undefine if you are calling sound effects from the same thread as the sound update call

;FT_PAL_SUPPORT      ;undefine to exclude PAL support
FT_NTSC_SUPPORT     ;undefine to exclude NTSC support

;__      __        
;\ \    / /        
; \ \  / /_ _ _ __ 
;  \ \/ / _` | '__|
;   \  / (_| | |   
;    \/ \__,_|_|   
                   
  .rsset $003
debugval        .rs 1
playerx         .rs 1
playery         .rs 1
playermoved     .rs 1
gridx           .rs 1
gridy           .rs 1
prevgridx       .rs 1
prevgridy       .rs 1
controller1     .rs 1  ; player 1 buttons
backroundptr    .rs 2  ; 16 bit
playermovedelay .rs 1
currentstate    .rs 1
leveldata       .rs 180
; ____              _       ___  
;|  _ \            | |     / _ \ 
;| |_) | __ _ _ __ | | __ | | | |
;|  _ < / _` | '_ \| |/ / | | | |
;| |_) | (_| | | | |   <  | |_| |
;|____/ \__,_|_| |_|_|\_\  \___/ 
                                 
  .bank 0
  .org $C000

  .include "util.asm"

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
  
  LDA #$00 ;00
  STA playerx
  LDA #$00 ;20
  STA playery
  LDA #$00
  STA playermovedelay
  STA gridx
  STA gridy
  STA playermoved

LoadSprites:
  LDX #$00
LoadSpritesLoop:
  LDA sprites, x
  STA $0200, x
  INX
  CPX #$10
  BNE LoadSpritesLoop

  loadlevel level1, level1col

  LDA #%10000000   ; enable NMI, sprites
  STA $2000

  LDA #%00011110   ; enable sprites
  STA $2001

  LDX #LOW(audio_music_data) ;initialize using the first song data
  LDY #HIGH(audio_music_data)
  LDA NTSC_MODE
  JSR FamiToneInit    ;init FamiTone

  LDA #$00
  JSR FamiToneMusicPlay

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

  JSR FamiToneUpdate

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

PaletteSwap:
  LDA controller1
  AND #BUTTON_B
  BEQ PaletteSwapDone
  loadlevel level2,level2col
  LDA #%00000001
  STA PLAYER_ADDRESS+2
  STA PLAYER_ADDRESS+10
  LDA #%01000001
  STA PLAYER_ADDRESS+6
  STA PLAYER_ADDRESS+14
PaletteSwapDone:
  RTS

PlayerMoveDelayed:
  DEC playermovedelay
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

PlayerMove: ;Movement code
  LDA playermovedelay
  BNE PlayerMoveDelayed

  LDA gridx ;Save previous pos
  STA prevgridx
  LDA gridy
  STA prevgridy

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
  LDA #$01
  STA playermoved
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
  LDA #$01
  STA playermoved
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
  LDA #$01
  STA playermoved
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
  LDA #$01
  STA playermoved
PlayerMoveDownDone:

  ;collison checks
  LDA playermoved
  BEQ PlayerMoveDone

  ;calculate bounds
  LDA gridx
  BMI UndoMovement ;If x negative
  CMP #$0F
  BCS UndoMovement ;If x >=15
  LDA gridy
  BMI UndoMovement ;If y negative
  CMP #$0C
  BCS UndoMovement ;If y >=12
  
  ;calculate level index = x + (y * width)
  LDA gridx
  LDX gridy
  BEQ LevelIndexLoopDone
LevelIndexLoop:
  CLC
  ADC #$0F
  DEX
  BNE LevelIndexLoop
LevelIndexLoopDone:
  STA debugval
  TAX
  LDA leveldata, x
  BEQ PlayerMoveDone

UndoMovement:
  LDA prevgridx
  STA gridx
  LDA prevgridy
  STA gridy

PlayerMoveDone:
  LDA #$00
  STA playermoved
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
  LDA #$1F
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

level1: ; including attribute table
  .incbin "data/level1.nam"
level2:
  .incbin "data/level2.nam"

level1col: ;15x12
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
level2col: ;15x12
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
  .db $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

  .include "famitone2.asm"
  .include "audio.asm"

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