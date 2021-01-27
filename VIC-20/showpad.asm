; A machine code version of the keypad demo. It's snappy!

* = $1A00

SCR=$1E00

PLEN = PADEND-PAD

START
        LDY #$00
@LOOP
        LDA PAD,Y
        JSR $FFD2
        INY
        CPY #PLEN
        BNE @LOOP

READER
        JSR POLL$
        ; Initialize everything
        LDA #$00
        STA ROW
        STA COL
        STA IDX
        LDX KEY$
LOOP1
        ; SCR+Y*44+X*2+23
        LDA ROW
        ASL
        ASL
        STA RTMP
        ASL
        TAY
        ADC RTMP
        STA RTMP
        TYA
        ASL
        ASL
        ADC RTMP
        STA RTMP
        LDA COL
        ASL
        ADC RTMP
        ADC #23
        TAY
        ; If we're at exactly the ninth key
        CMP #115
        BNE FBYTE
        LDX KEY$+1
FBYTE
        TXA
        AND #$01
        BEQ KREL
        LDA SCR,Y
        ORA #$80
        STA SCR,Y
        BNE KDONE
KREL
        LDA SCR,Y
        AND #$7F
        STA SCR,Y
KDONE
        ; Shift in the next bit of the bitfield
        TXA
        LSR
        TAX

        INC COL
        LDA COL
        CMP #3
        BMI LOOP1
        LDA #0
        STA COL
        INC ROW
        LDA ROW
        CMP #4
        BMI LOOP1
        JMP READER

COL     BYTE 0
ROW     BYTE 0
IDX     BYTE 0
RTMP    BYTE 0

PAD     BYTE "{clear}{red}"
        BYTE "{cm a}{sh asterisk}{cm r}{sh asterisk}{cm r}{sh asterisk}{cm s}",$0D
        BYTE "{sh -}1{sh -}2{sh -}3{sh -}",$0D
        BYTE "{cm q}{sh asterisk}{sh +}{sh asterisk}{sh +}{sh asterisk}{cm w}",$0D
        BYTE "{sh -}4{sh -}5{sh -}6{sh -}",$0D
        BYTE "{cm q}{sh asterisk}{sh +}{sh asterisk}{sh +}{sh asterisk}{cm w}",$0D
        BYTE "{sh -}7{sh -}8{sh -}9{sh -}",$0D
        BYTE "{cm q}{sh asterisk}{sh +}{sh asterisk}{sh +}{sh asterisk}{cm w}",$0D
        BYTE "{sh -}*{sh -}0{sh -}#{sh -}",$0D
        BYTE "{cm z}{sh asterisk}{cm e}{sh asterisk}{cm e}{sh asterisk}{cm x}"
PADEND

Incasm "poller.asm"