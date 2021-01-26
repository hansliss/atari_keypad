* = $1A00

; bit organization
;     012   byte 0
;     345
;     678
;     9ab   byte 1 from "8"

; scratch storage
;  idx of byte
;  bitmask
;  inversebitmask
;  row
;  column 
;  columns (all column bits)
IDX     BYTE 0
BITMASK BYTE 0
INVBM   BYTE 0
ROW     BYTE 0
COLUMN  BYTE 0
COLUMNS BYTE 0
V1DDRA  BYTE 0
V2DDRB  BYTE 0
SCRATCH BYTE 0

; persistent
KEY     BYTE 0,0
LAST    BYTE 0,0
DEBST   BYTE 0,0

        SEI
        ; save I/O pin direction
        LDA $9113
        STA V1DDRA
        LDA $9122
        STA V2DDRB
        ; row=0
        LDA #$03
        STA ROW
        ; set output on 1<<row, input on the others
        ; pull low 1<<row
RLOOP
        LDY ROW
        TYA
        CMP #$03
        BEQ RSPEC
        LDA #$02
RSHFT1
        ROL
        DEY
        BPL RSHFT1
        STA $9113
        LDA #$00
        STA $9122
        STA $9111
        BEQ RDONE
RSPEC
        LDA #$80
        STA $9122
        LDA #$00
        STA $9113
        STA $9120
RDONE
        ; wait
        LDY #$80
DELAY
        NOP
        DEY
        BNE DELAY
        
        ; read all columns into single byte - "columns"
        LDA #$00
        STA COLUMNS
        LDA $9111
        AND #$20
        BEQ C2
        LDA #$04
        ORA COLUMNS
        STA COLUMNS
C2              
        LDA $9008
        BMI C3
        LDA #$02
        ORA COLUMNS
        STA COLUMNS
C3              
        LDA $9009
        BMI C4
        LDA #$01
        ORA COLUMNS
        STA COLUMNS
C4
        ; column=2
        LDA #$02
        STA COLUMN

CLOOP
        ; set idx, shift and bitmask
        ; idx = (row & 0x01 | column >> 1) & row >> 1
        ; calculate idx
        ; y = row
        ; a = column
        LDA COLUMN
        LDY ROW
        LSR
        STA SCRATCH
        TYA
        AND #$01
        ORA SCRATCH
        STA SCRATCH
        TYA
        LSR
        AND SCRATCH
        STA IDX
        ; shift = (3 * row + column) % 8
        ; calculate shift
        ; y = row
        TYA
        CLC
        STA SCRATCH
        ROL
        ADC SCRATCH
        ADC COLUMN
        AND #$07
;       STA SHIFT
        TAY

        ; bitmask = 1 << shift
        ; calculate bitmask
        LDA #$00
        SEC
BMLOOP
        ROL
        DEY
        BPL BMLOOP

        STA BITMASK
        ; inversebitmask = ~bitmask
        EOR #$FF
        STA INVBM
        ; colbitmask = 1 << column
        LDY COLUMN
        LDA #$00
        SEC
CBLOOP
        ROL
        DEY
        BPL CBLOOP
;       STA COLBITMASK

        LDY IDX
        ; if !(columns & colbitmask) goto isprsd  // <<<---- need "columns" here only
        AND COLUMNS
        BEQ ISPRSD
        
        ; if !(last[idx] & bitmask) goto end
        LDA LAST,Y
        AND BITMASK
        BEQ END

        LDX INVBM
        ; key[idx] &= inversebitmask
        TXA
        AND KEY,Y
        STA KEY,Y
        ; last[idx] &= inversebitmask
        TXA
        AND LAST,Y
        STA LAST,Y
        ; debounce[idx] &= inversebitmask
        TXA
        AND DEBST,Y
        STA DEBST,Y
        JMP END
ISPRSD
        LDX BITMASK

        ; if last[idx] & bitmask goto end
        LDA LAST,Y
        AND BITMASK
        BNE END

        ; if !(debounce[idx] & bitmask) goto deb
        LDA DEBST,Y
        AND BITMASK
        BEQ DEB

        ; key[idx] |= bitmask
        TXA
        ORA KEY,Y
        STA KEY,Y
        ; last[idx] |= bitmask
        TXA
        ORA LAST,Y
        STA LAST,Y
        JMP END
DEB
        ; debounce[idx] |= bitmask
        TXA
        ORA DEBST,Y
        STA DEBST,Y
END
        ; if column >= 0 goto cloop
        DEC COLUMN
        BMI CFIN
        JMP CLOOP
CFIN
        DEC ROW
        ; if row >= 0 goto rloop
        BMI RFIN
        JMP RLOOP
RFIN
        ; restore I/O pin direction
        LDA V1DDRA
        STA $9113
        LDA V2DDRB
        STA $9122
        RTS

K2      BYTE 0,0,0,0,0,0,0,0,0,0,0,0
REORG
        LDA KEY
        LDY #$00
        TAX
ROLOOP1
        TXA
        AND #$01
        STA K2,Y
        INY
        TXA
        LSR
        TAX
        TYA
        CMP #$08
        BMI ROLOOP1
        LDA KEY+1
        LDY #$00
        TAX
ROLOOP2
        TXA
        AND #$01
        STA K2+8,Y
        INY
        TXA
        LSR
        TAX
        TYA
        CMP #$04
        BMI ROLOOP2
        RTS
