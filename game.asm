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
STATE_TITLE    = $00
STATE_PLAYING  = $01
STATE_END      = $02
NTSC_MODE      = $01

;FamiTone2 settings
FT_BASE_ADR   = $0300 ;page in the RAM used for FT2 variables, should be $xx00
FT_TEMP     = $00 ;3 bytes in zeropage used by the library as a scratchpad
FT_DPCM_OFF   = $c000 ;$c000..$ffc0, 64-byte steps
FT_SFX_STREAMS  = 4   ;number of sound effects played at once, 1..4
FT_NTSC_SUPPORT

;__      __        
;\ \    / /        
; \ \  / /_ _ _ __ 
;  \ \/ / _` | '__|
;   \  / (_| | |   
;    \/ \__,_|_|   
                   
  .rsset $003
playerx         .rs 1  ;x pos on screen
playery         .rs 1  ;y pos on screen
playermoved     .rs 1
gridx           .rs 1
gridy           .rs 1
prevgridx       .rs 1
prevgridy       .rs 1
controller1     .rs 1  ; player 1 buttons
backgroundptr   .rs 2  ; 16 bit
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
  JSR Util.VBlankWait

.Clrmem:
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
  BNE .Clrmem

  ;;Setup Game State
  LDA #STATE_TITLE
  STA currentstate

  ;Load Game Data
  JSR Util.VBlankWait
  JSR Util.LoadPalette
  JSR Util.LoadSprites

  LDA #LOW(titledata)
  STA backgroundptr
  LDA #HIGH(titledata)
  STA backgroundptr+1
  JSR Util.LoadBackground
  
  ;JSR Util.LoadLevel

  ;;Setup Famitone
  LDX #LOW(audio_music_data) 
  LDY #HIGH(audio_music_data)
  LDA NTSC_MODE
  JSR FamiToneInit    ;init FamiTone
  LDA #$02
  JSR FamiToneMusicPlay

  ;;Enable PPU
  LDA #%10000000   ; enable NMI, sprites
  STA $2000
  LDA #%00011110   ; enable sprites
  STA $2001

.Forever:
  JMP .Forever     ; Loop forever

NMI: 
  ;;Setup Sprite DMA Transfer
  LDA #$00
  STA $2003
  LDA #$02
  STA $4014

  ;;Only update player if in playing state (prob not best way to go)
  LDA currentstate
  CMP #STATE_PLAYING
  BNE .DrawingDone
  JSR UpdatePlayer
.DrawingDone:

  JSR Util.PPUCleanup

  JSR Util.ReadController1

GameLoop:
  LDA currentstate
  CMP #STATE_TITLE
  BEQ GameTitle

  LDA currentstate
  CMP #STATE_PLAYING
  BEQ GamePlaying

  LDA currentstate
  CMP #STATE_END
  BEQ GameEnd
GameLoopDone:
  JSR FamiToneUpdate
  RTI

GameTitle:
  LDA controller1
  AND #BUTTON_START
  BEQ .GameTitleDone
  LDA #STATE_PLAYING
  STA currentstate
  JSR Util.LoadLevel
  LDA #$00
  JSR FamiToneMusicPlay
.GameTitleDone:
  
  JMP GameLoopDone

GamePlaying:
  JSR PlayerMove
  JSR PaletteSwap
  JSR GridToScreen
  JMP GameLoopDone

GameEnd:
  JMP GameLoopDone

PaletteSwap:
  LDA controller1
  AND #BUTTON_B
  BEQ .PaletteSwapDone
  LDA #%00000001
  STA PLAYER_ADDRESS+2
  STA PLAYER_ADDRESS+10
  LDA #%01000001
  STA PLAYER_ADDRESS+6
  STA PLAYER_ADDRESS+14
.PaletteSwapDone:
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

  ;;collison checks
  LDA playermoved
  BEQ PlayerMoveDone

  ;;calculate bounds
  LDA gridx
  BMI UndoMovement ;If x negative
  CMP #$0F
  BCS UndoMovement ;If x >=15
  LDA gridy
  BMI UndoMovement ;If y negative
  CMP #$0C
  BCS UndoMovement ;If y >=12
  
  ;;calculate level index = x + (y * width)
  LDA gridx
  LDX gridy
  BEQ LevelIndexLoopDone
LevelIndexLoop:
  CLC
  ADC #$0F
  DEX
  BNE LevelIndexLoop
LevelIndexLoopDone:
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

GridToScreen:
  LDA #$08 ; origin x for grid
  LDX gridx
  BEQ .GridXLoopDone
.GridXLoop:
  CLC
  ADC #$10
  DEX
  BNE .GridXLoop
.GridXLoopDone:
  STA playerx
  LDA #$1F
  LDX gridy
  BEQ .GridYLoopDone
.GridYLoop:
  CLC
  ADC #$10
  DEX
  BNE .GridYLoop
.GridYLoopDone:
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
  .db $FF, $44, %00000000, $FF ;Player 1
  .db $FF, $44, %01000000, $FF ;Player 2
  .db $FF, $45, %00000000, $FF ;Player 3
  .db $FF, $45, %01000000, $FF ;Player 4

titledata: ; including attribute table
  .incbin "data/startscreen.nam"
windata: ; including attribute table
  .incbin "data/youwin.nam"

level1col: ;15x12
  .db $00, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $10, $00
  .db $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $01, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $01, $00, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
  .db $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $00
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