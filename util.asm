;------------------------------------------------------------------------------
; Waits for VBlank
;------------------------------------------------------------------------------
Util.VBlankWait:       
  BIT $2002
  BPL Util.VBlankWait
  RTS

;------------------------------------------------------------------------------
; Loads game palette
;------------------------------------------------------------------------------
Util.LoadPalette:
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006
  LDX #$00
.LoadPaletteLoop:
  LDA palette, x
  STA $2007
  INX
  CPX #$20
  BNE .LoadPaletteLoop
  RTS

;------------------------------------------------------------------------------
; Reads first controller
;------------------------------------------------------------------------------
Util.ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDX #$08
.ReadController1Loop:
  LDA $4016
  LSR A            ; bit0 -> Carry
  ROL controller1  ; bit0 <- Carry
  DEX
  BNE .ReadController1Loop
  RTS

;------------------------------------------------------------------------------
; Cleans up PPU after drawing
;------------------------------------------------------------------------------
Util.PPUCleanup:
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005
  RTS

;------------------------------------------------------------------------------
; Loads Sprites
;------------------------------------------------------------------------------
Util.LoadSprites:
  LDX #$00
.LoadSpritesLoop:
  LDA sprites, x
  STA $0200, x
  INX
  CPX #(4 * 4)        ;Load 4 sprites
  BNE .LoadSpritesLoop

;------------------------------------------------------------------------------
; Loads background
;------------------------------------------------------------------------------
Util.LoadBackground
  LDA #%00000110   ; disable PPU
  STA $2001

  LDA $2002        ;Reset PPU Latch
  LDA #$20         ;Set PPU Address 2000
  STA $2006
  LDA #$00
  STA $2006
  
  ;;Load Nametable
  LDX #$04               ;4 outer loops with 256 inner loops 4*256-1024
  LDY #$00
.LoadBackgroundLoop
  LDA [backgroundptr], y
  STA $2007
  INY
  BNE .LoadBackgroundLoop ;loop 256 times
  INC backgroundptr+1
  DEX
  BNE .LoadBackgroundLoop
  ;;Load attributes
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
.LoadAttributeLoop
  LDA titledata+960, x
  STA $2007
  INX
  CPX #$40
  BNE .LoadAttributeLoop

  LDA #%00011110   ; ReEnable PPU
  STA $2001
  RTS
;------------------------------------------------------------------------------
; Loads level
;------------------------------------------------------------------------------
Util.LoadLevel:
  LDA #%00000110   ; disable PPU
  STA $2001
  LDA $2002        ;Reset PPU Latch
  LDA #$20         ;Set PPU Address 2000
  STA $2006
  LDA #$00
  STA $2006 
  LDX #$00         ;Fill top of sceen with blocks
  LDA #$48
.LoadLevelTopLoop:
  STA $2007
  INX
  CPX #$81         
  BNE .LoadLevelTopLoop
  LDY #$00         ;y=level index
  LDA #$00		   ;a=position in y column
.LoadLevelLoop:
  PHA
  JSR .LoadLevelByRow
  TYA
  SBC #$0F
  TAY
  JSR .LoadLevelByRow
  PLA
  ADC #($01-1)     ;Sub 1 because of carry flag
  CMP #$0C
  BNE .LoadLevelLoop
  LDX #$00         ;Fill bottom of sceen with blocks
  LDA #$48
.LoadLevelBottomLoop:
  STA $2007
  INX
  CPX #$1F         
  BNE .LoadLevelBottomLoop
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00
  LDA #$00              ; Only use first pallet
.LoadAttributeLoop:
  STA $2007             
  INX                   ; 
  CPX #$40              ; 64 Entries
  BNE .LoadAttributeLoop

  LDA #%00011110   ; ReEnable PPU
  STA $2001

  RTS

.LoadLevelByRow:
  LDX #$00         ;x=position in x column
.LoadLevelByRowLoop:
  LDA level1col, y
  STA leveldata, y ;Save level to ram
  CMP #$00
  BNE .LevelTileBlock
.LevelTileEmpty:
  LDA #$FF
  JMP .LevelTileDetermined
.LevelTileBlock:
  LDA #$48
.LevelTileDetermined:
  STA $2007
  STA $2007
  INX
  INY
  CPX #$0F
  BNE .LoadLevelByRowLoop
  LDA #$48     ;2 extra blocks per row
  STA $2007
  STA $2007
  RTS