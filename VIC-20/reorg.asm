; This uses the poller to poll a keypad and then
; unpacks the bitfields generated. See "poller.asm".
* = $1a00

KEY2$   BYTE 0,0,0,0,0,0,0,0,0,0,0,0
REORG$
        JSR POLL$
        LDA KEY$
        LDY #$00
        TAX
ROLOOP1
        TXA
        AND #$01
        STA KEY2$,Y
        INY
        TXA
        LSR
        TAX
        TYA
        CMP #$08
        BMI ROLOOP1
        LDA KEY$+1
        LDY #$00
        TAX
ROLOOP2
        TXA
        AND #$01
        STA KEY2$+8,Y
        INY
        TXA
        LSR
        TAX
        TYA
        CMP #$04
        BMI ROLOOP2
        RTS

Incasm "poller.asm"