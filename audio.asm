;this file for FamiTone2 library generated by text2data tool

audio_music_data:
	.db 2
	.dw .instruments
	.dw .samples-3
	.dw .song0ch0,.song0ch1,.song0ch2,.song0ch3,.song0ch4,307,256
	.dw .song1ch0,.song1ch1,.song1ch2,.song1ch3,.song1ch4,307,256

.instruments:
	.db $30 ;instrument $00
	.dw .env1,.env0,.env0
	.db $00
	.db $30 ;instrument $02
	.dw .env2,.env0,.env0
	.db $00
	.db $30 ;instrument $03
	.dw .env4,.env0,.env0
	.db $00
	.db $30 ;instrument $04
	.dw .env3,.env0,.env0
	.db $00

.samples:
.env0:
	.db $c0,$00,$00
.env1:
	.db $c6,$c7,$c6,$c0,$00,$03
.env2:
	.db $c8,$c7,$c5,$c3,$c2,$c1,$02,$c0,$00,$07
.env3:
	.db $cc,$c5,$c4,$c3,$c2,$c1,$c1,$c0,$00,$07
.env4:
	.db $c5,$06,$c0,$00,$02


.song0ch0:
	.db $fb,$06
.song0ch0loop:
.ref0:
	.db $80,$33,$1b,$3d,$25,$35,$1d,$3d,$25,$33,$1b,$3d,$25,$35,$1d,$3d
	.db $24,$81
.ref1:
	.db $33,$1b,$3d,$25,$35,$1d,$3d,$25,$33,$1b,$3d,$25,$35,$1d,$3d,$24
	.db $81
	.db $ff,$11
	.dw .ref1
	.db $ff,$11
	.dw .ref1
.ref4:
	.db $33,$1b,$3d,$25,$35,$1d,$3d,$25,$28,$2a,$28,$24,$29,$25,$40,$42
	.db $40,$3c,$41,$24,$81
	.db $ff,$15
	.dw .ref4
	.db $fd
	.dw .song0ch0loop

.song0ch1:
.song0ch1loop:
.ref6:
	.db $82,$4a,$85,$55,$59,$5a,$85,$5b,$59,$54,$9d
.ref7:
	.db $4b,$4d,$51,$54,$8d,$55,$5b,$59,$55,$50,$4c,$4a,$8d
.ref8:
	.db $4a,$85,$55,$59,$5a,$85,$5b,$59,$54,$9d
	.db $ff,$0d
	.dw .ref7
.ref10:
	.db $3a,$85,$3d,$3b,$35,$3b,$32,$85,$40,$42,$40,$3c,$40,$85,$28,$2a
	.db $28,$24,$28,$85
	.db $ff,$14
	.dw .ref10
	.db $fd
	.dw .song0ch1loop

.song0ch2:
.song0ch2loop:
.ref12:
	.db $84,$1a,$85,$00,$85,$24,$85,$00,$85,$1c,$85,$00,$85,$24,$85,$00
	.db $85
.ref13:
	.db $1a,$85,$00,$85,$24,$85,$00,$85,$1c,$85,$00,$85,$24,$85,$00,$85
	.db $ff,$10
	.dw .ref13
	.db $ff,$10
	.dw .ref13
	.db $ff,$10
	.dw .ref13
	.db $ff,$10
	.dw .ref13
	.db $fd
	.dw .song0ch2loop

.song0ch3:
.song0ch3loop:
.ref18:
	.db $86,$02,$83,$02,$1d,$03,$03,$1c,$1c,$1c,$85,$02,$83,$02,$1d,$03
	.db $03,$1c,$1c,$1c,$85
.ref19:
	.db $02,$83,$02,$1d,$03,$03,$1c,$1c,$1c,$85,$02,$83,$02,$1d,$03,$03
	.db $1c,$1c,$1c,$85
	.db $ff,$14
	.dw .ref19
	.db $ff,$14
	.dw .ref19
	.db $ff,$14
	.dw .ref19
	.db $ff,$14
	.dw .ref19
	.db $fd
	.dw .song0ch3loop

.song0ch4:
.song0ch4loop:
.ref24:
	.db $bf
.ref25:
	.db $bf
.ref26:
	.db $bf
.ref27:
	.db $bf
.ref28:
	.db $bf
.ref29:
	.db $bf
	.db $fd
	.dw .song0ch4loop


.song1ch0:
	.db $fb,$06
.song1ch0loop:
.ref30:
	.db $82,$3a,$3b,$3a,$45,$3f,$49,$44,$48,$4d,$4c,$4e,$52,$85,$5c,$5c
	.db $57,$52,$4e,$53,$5d,$57,$52,$4e,$53,$3b,$44,$83
	.db $fd
	.dw .song1ch0loop

.song1ch1:
.song1ch1loop:
.ref31:
	.db $80,$22,$23,$22,$2d,$27,$31,$2c,$30,$35,$34,$36,$3a,$85,$44,$44
	.db $3f,$3a,$36,$3b,$45,$3f,$3a,$36,$3b,$23,$2c,$83
	.db $fd
	.dw .song1ch1loop

.song1ch2:
.song1ch2loop:
.ref32:
	.db $84,$22,$85,$2c,$85,$22,$85,$34,$85,$22,$85,$2d,$27,$22,$85,$2c
	.db $85,$22,$85,$23,$2c,$83
	.db $fd
	.dw .song1ch2loop

.song1ch3:
.song1ch3loop:
.ref33:
	.db $86,$02,$02,$03,$18,$85,$02,$02,$03,$19,$02,$18,$02,$85,$02,$02
	.db $03,$18,$85,$02,$02,$03,$19,$02,$18,$02,$1a,$02,$83
	.db $fd
	.dw .song1ch3loop

.song1ch4:
.song1ch4loop:
.ref34:
	.db $d1
	.db $fd
	.dw .song1ch4loop
