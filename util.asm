;------------------------------------------------------------------------------
; Macro that loads name table and attributes
; in: \1 nametable
;------------------------------------------------------------------------------

loadlevel  .macro
  LDA #%00000110   ; disable PPU
  STA $2001
LoadBackground\@:
  LDA $2002              ;Reset PPU Latch
  LDA #$20 
  STA $2006
  LDA #$00
  STA $2006              ;Set background location to $2000

  LDA #LOW(\1)
  STA backroundptr+0

  LDA #HIGH(\1)
  STA backroundptr+1

  LDX #$04               ;4 outer loops with 256 inner loops 4*256-1024
  LDY #$00
LoadBackgroundLoop\@:
  LDA [backroundptr+0], y
  STA $2007
  INY
  BNE LoadBackgroundLoop\@ ;Loop 256 times until resets to zero
  INC backroundptr+1
  DEX
  BNE LoadBackgroundLoop\@

LoadAttribute\@:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$23
  STA $2006             ; write the high byte of $23C0 address
  LDA #$C0
  STA $2006             ; write the low byte of $23C0 address
  LDX #$00              ; start out at 0
LoadAttributeLoop\@:
  LDA \1+960, x      ; load data from address (attribute + the value in x)
  STA $2007             ; write to PPU
  INX                   ; X = X + 1
  CPX #$40              ; Compare X to hex $08, decimal 8 - copying 8 bytes
  BNE LoadAttributeLoop\@

LoadLevelCol\@:
  LDX #$00
LoadlevelColLoop\@:
  LDA \2, x
  STA leveldata, x
  INX
  CPX #$B4
  BNE LoadlevelColLoop\@

  LDA #%00011110   ; ReEnable PPU
  STA $2001
  .endm