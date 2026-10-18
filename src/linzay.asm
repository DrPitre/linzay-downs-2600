; Linzay Downs -- original NTSC Atari 2600 4K racing cartridge.
; Four horses share the two TIA players in separate vertical lanes.
        processor 6502
VSYNC   = $00
VBLANK  = $01
WSYNC   = $02
NUSIZ0  = $04
NUSIZ1  = $05
COLUP0  = $06
COLUP1  = $07
COLUPF  = $08
COLUBK  = $09
CTRLPF  = $0a
PF0     = $0d
PF1     = $0e
PF2     = $0f
RESP0   = $10
RESP1   = $11
RESBL   = $14
AUDC0   = $15
AUDF0   = $17
AUDV0   = $19
GRP0    = $1b
GRP1    = $1c
ENABL   = $1f
HMP0    = $20
HMP1    = $21
HMBL    = $24
HMOVE   = $2a
HMCLR   = $2b
INPT4   = $3c
SWCHA   = $0280
SWCHB   = $0282
INTIM   = $0284
TIM64T  = $0296

        seg.u RAM
        org $80
Phase   ds 1            ; 0 attract, 1 countdown, 2 race, 3 finish
FireWas ds 1
FireEdge ds 1
Frame   ds 1
Count   ds 1
Stamina ds 1
Place   ds 1
Pos     ds 4
Frac    ds 4
Rng     ds 1
Speaker ds 1            ; 0 Cecil Brown, 1 Leroy Pitre
Quote   ds 1
Talk    ds 1
Introduced ds 1
Sound   ds 1
TextPtr ds 2
Lane    ds 1
Pose    ds 1
Temp    ds 1
Speed   ds 1
RAMEnd

        seg CODE
        org $f000
Reset
        sei
        cld
        ldx #$ff
        txs
        lda #0
        ldx #0
Clear
        sta $00,x
        inx
        bne Clear
        lda #$5d
        sta Rng
        jsr NewRace
FrameLoop
        lda #2
        sta VSYNC
        sta WSYNC
        sta WSYNC
        sta WSYNC
        lda #0
        sta VSYNC
        lda #2
        sta VBLANK
        lda #44
        sta TIM64T
        jsr Update
WaitBlank
        lda INTIM
        bne WaitBlank
        sta WSYNC
        lda #0
        sta VBLANK
        lda #228
        sta TIM64T
        jsr Picture
WaitPicture
        lda INTIM
        bne WaitPicture
        sta WSYNC
        lda #2
        sta VBLANK
        lda #35
        sta TIM64T
WaitOverscan
        lda INTIM
        bne WaitOverscan
        sta WSYNC
        sta WSYNC             ; final overscan line: 262 scanlines/frame
        jmp FrameLoop

NewRace
        lda #0
        sta Phase
        sta Speaker
        sta Introduced
        sta Quote
        sta Frame
        sta AUDV0
        sta Sound
        ldx #3
InitHorses
        sta Frac,x
        pha
        lda #8
        sta Pos,x
        pla
        dex
        bpl InitHorses
        lda #64
        sta Stamina
        lda #1
        sta Place
        lda #150
        sta Talk
        rts

Update
        inc Frame
        lda #0
        sta FireEdge
        bit INPT4
        bmi FireReleased
        lda FireWas
        bne FireRead
        inc FireEdge
FireRead
        lda #1
        sta FireWas
        bne CheckReset
FireReleased
        sta FireWas
CheckReset
        lda SWCHB
        and #1
        bne NoReset
        jsr NewRace
NoReset
        lda Rng
        lsr
        bcc NoXor
        eor #$b4
NoXor
        sta Rng
        dec Talk
        bne NoTalk
        lda Introduced
        bne RandomSpeaker
        inc Introduced
        lda #1
        bne SetSpeaker
RandomSpeaker
        lda Rng
        and #1
SetSpeaker
        sta Speaker
        lda Rng
        and #15
        cmp #12
        bcc QuoteRange
        sbc #4
QuoteRange
        cmp Quote
        bne SetQuote
        clc
        adc #1
        cmp #12
        bcc SetQuote
        lda #0
SetQuote
        sta Quote
        lda Rng
        and #63
        ora #128
        sta Talk
NoTalk
        lda Sound
        beq Quiet
        dec Sound
        bne SoundActive
Quiet
        lda #0
        sta AUDV0
SoundActive
        lda Phase
        beq WaitFire
        cmp #3
        beq WaitFire
        cmp #1
        bne Racing
        dec Count
        bne UpdateDone
        lda #2
        sta Phase
        lda #4
        sta AUDC0
        lda #8
        sta AUDF0
        lda #4
        sta AUDV0
        lda #8
        sta Sound
UpdateDone
        rts
WaitFire
        lda FireEdge
        beq UpdateDone
        jsr NewRace
        lda #1
        sta Phase
        lda #120
        sta Count
        rts
Racing
        lda #18             ; trot while the joystick is released
        sta Speed
        lda SWCHA
        and #$80            ; joystick 1 right, active low
        bne RecoverFast
        lda #38
        sta Speed
        bit INPT4
        bmi Recover
        lda Stamina
        beq MoveHorses
        lda #60
        sta Speed
        lda Frame
        and #3
        bne MoveHorses
        dec Stamina
        jmp MoveHorses
RecoverFast
        lda Frame
        and #1
        bne MoveHorses
        jmp GainStamina
Recover
        lda Frame
        and #3
        bne MoveHorses
GainStamina
        lda Stamina
        cmp #64
        bcs MoveHorses
        inc Stamina
MoveHorses
        lda Frac
        clc
        adc Speed
        sta Frac
        bcc Rivals
        inc Pos
Rivals
        ldx #3
MoveRival
        lda Frac,x
        clc
        adc RivalSpeed-1,x
        sta Frac,x
        bcc NextRival
        lda Pos,x
        cmp #120
        bcs NextRival
        inc Pos,x
NextRival
        dex
        bne MoveRival
        lda #1
        sta Place
        ldx #3
Rank
        lda Pos,x
        cmp Pos
        bcc RankNext
        inc Place
RankNext
        dex
        bne Rank
        lda Pos
        cmp #120
        bcc Hoofbeat
        lda #120
        sta Pos
        lda #3
        sta Phase
        lda #4
        sta AUDC0
        lda #5
        sta AUDF0
        lda #5
        sta AUDV0
        lda #30
        sta Sound
        rts
Hoofbeat
        lda Frame
        and #7
        beq PlayHoof
        rts
PlayHoof
        lda #8
        sta AUDC0
        lda #11
        sta AUDF0
        lda #2
        sta AUDV0
        lda #2
        sta Sound
        rts

; A is a pixel coordinate, X is the TIA object index (0,1 or 4).
Position
        sta WSYNC
        sec
Divide15
        sbc #15
        bcs Divide15
        eor #7
        asl
        asl
        asl
        asl
        sta HMP0,x
        sta RESP0,x
        rts

; Ten 3x5 characters, doubled vertically, using all 40 playfield bits.
; Left stores end at cycle 28; right stores at 42/52/62.
Text
        tax
        lda TextLo,x
        sta TextPtr
        lda TextHi,x
        sta TextPtr+1
        ldy #0
TextRow
        sta WSYNC
        lda (TextPtr),y
        sta PF0
        iny
        lda (TextPtr),y
        sta PF1
        iny
        lda (TextPtr),y
        sta PF2
        iny
        nop
        nop
        lda (TextPtr),y
        sta PF0
        iny
        lda (TextPtr),y
        sta PF1
        iny
        lda (TextPtr),y
        sta PF2
        iny
        cpy #60
        bne TextRow
        lda #0
        sta PF0
        sta PF1
        sta PF2
        rts

Picture
        lda #0
        sta GRP0
        sta GRP1
        sta ENABL
        sta CTRLPF
        lda #$80
        sta COLUBK
        lda #$1e
        sta COLUPF
        lda #TXT_LINZAY
        jsr Text
        lda #TXT_DOWNS
        jsr Text
        lda #TXT_EUNICE
        jsr Text
        lda Speaker
        beq CecilTalk
        lda #TXT_LEROY
        jsr Text
        lda #TXT_PITRE
        jmp LastName
CecilTalk
        lda #TXT_CECIL
        jsr Text
        lda #TXT_BROWN
LastName
        jsr Text
        lda Quote
        clc
        adc #TXT_CHEER0
        jsr Text
        ; Six old men, with waving arms, multiplexed above the fence.
        sta HMCLR
        lda #6
        sta NUSIZ0
        lda #3
        sta NUSIZ1
        lda #16
        ldx #0
        jsr Position
        lda #92
        ldx #1
        jsr Position
        sta WSYNC
        sta HMOVE
        lda Frame
        and #32
        lsr
        sta Pose
        tax
        ldy #0
MenRow
        sta WSYNC
        lda Men,x
        sta GRP0
        sta GRP1
        lda MenColor,y
        sta COLUP0
        sta COLUP1
        inx
        iny
        cpy #15
        bne MenRow
        lda #0
        sta GRP0
        sta GRP1
        lda #$c4
        sta COLUBK
        lda #$2e
        sta COLUPF
        lda #$f0
        sta PF0
        lda #$ff
        sta PF1
        sta PF2
        sta WSYNC
        sta WSYNC
        lda #0
        sta PF0
        sta PF1
        sta PF2
        ; Finish post is the ball, shared by all four horse lanes.
        sta HMCLR
        lda #148
        ldx #4
        jsr Position
        sta WSYNC
        sta HMOVE
        lda #$20
        sta CTRLPF
        lda #2
        sta ENABL
        lda #$0e
        sta COLUPF
        lda #5
        sta NUSIZ0
        sta NUSIZ1
        lda #$22
        sta COLUBK
        lda #0
        sta Lane
HorseLane
        sta HMCLR
        ldx Lane
        lda Pos,x
        ldx #0
        jsr Position
        ldx Lane
        lda Pos,x
        clc
        adc #16
        ldx #1
        jsr Position
        sta WSYNC
        sta HMOVE
        lda Phase
        cmp #2
        bne Standing
        lda Frame
        lsr
        lsr
        and #3
        asl
        asl
        asl
        asl
        jmp PoseReady
Standing
        lda #0
PoseReady
        tax
        lda Lane
        asl
        asl
        asl
        asl
        tay
        lda #15
        sta Temp
HorseRow
        sta WSYNC
        lda HorseLeft,x
        sta GRP0
        lda HorseRight,x
        sta GRP1
        lda HorseColorLeft,y
        sta COLUP0
        lda HorseColorRight,y
        sta COLUP1
        inx
        iny
        dec Temp
        bne HorseRow
        lda #0
        sta GRP0
        sta GRP1
        sta WSYNC
        inc Lane
        lda Lane
        cmp #4
        bne HorseLane
        lda #0
        sta ENABL
        lda #$80
        sta COLUBK
        lda #$1e
        sta COLUPF
        lda Phase
        beq AttractFooter
        cmp #1
        beq ReadyFooter
        cmp #3
        beq FinishFooter
        lda #TXT_RUN
        bne Footer
AttractFooter
        lda #TXT_START
        bne Footer
ReadyFooter
        lda #TXT_READY
        bne Footer
FinishFooter
        lda Place
        clc
        adc #TXT_FIRST-1
Footer
        jsr Text
        lda Stamina
        lsr
        lsr
        lsr
        tax
        lda Bar,x
        sta PF1
        lda #$ae
        sta COLUPF
        sta WSYNC
        sta WSYNC
        lda #0
        sta PF1
        rts
RivalSpeed
        byte 40,35,32
Bar
        byte $00,$80,$c0,$e0,$f0,$f8,$fc,$fe,$ff
        include "assets.inc"
        echo "ROM bytes free: ",($fffa-*)
        org $fffa
        word Reset,Reset,Reset
