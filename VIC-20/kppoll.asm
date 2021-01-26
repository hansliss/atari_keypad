* = $1A00

; bits within the two bytes
; and their correspondence to
; keypad keys
;     012   byte 0
;     345
;     670
;     123   byte 1

;  idx of byte
IDX     BYTE 0
;  bitmask
BITMASK BYTE 0
;  inversebitmask
INVBM   BYTE 0
;  row
ROW     BYTE 0
;  column 
COLUMN  BYTE 0
;  columns (all column bits)
COLUMNS BYTE 0
;  saved data direction registers
V1DDRA  BYTE 0
V2DDRB  BYTE 0
;  scratch storage
SCRATCH BYTE 0

; persistent
;  the two key state bytes
KEY     BYTE 0,0
;  the previous state of keys
LAST    BYTE 0,0
;  debouncing status
DEBST   BYTE 0,0

        SEI
        ; save I/O pin direction
        LDA $9113
        STA V1DDRA
        LDA $9122
        STA V2DDRB
        ; Loop over the row number, high to low
        LDA #$03
        STA ROW
        ; set output on 1<<row, input on the others
        ; pull the output low
RLOOP
        LDY ROW
        TYA
        CMP #$03
        BEQ RSPEC
        ; Rows 0 to 2 are connected to adjacent bits
        ; on VIA 1 PORT A, from bit 2 to bit 4
        LDA #$02
RSHFT1
        ROL
        DEY
        BPL RSHFT1
        STA $9113
        LDA #$00
        ; Reset the other VIA port to input
        ; so it doesn't interfere!
        STA $9122
        ; Set the output to low
        STA $9111
        BEQ RDONE
        ; Row 3 is different, it's connected to
        ; VIA 2 port B
RSPEC
        LDA #$80
        STA $9122
        LDA #$00
        ; Reset the other VIA port to input
        ; so it doesn't interfere!
        STA $9113
        ; Set the output to low
        STA $9120
RDONE
        ; wait for a bit
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
        ; Now loop over the columns
        ; calculate idx, shift and bitmask
        ; idx = (row & 0x01 | column >> 1) & row >> 1
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
        ; We don't need to store this bitmask

        LDY IDX
        ; if !(columns & colbitmask) goto isprsd
        ; We only use COLUMNS and the colbitmask here,
        ; so there might be room for optimization.
        AND COLUMNS
        BEQ ISPRSD
        
        ; Here if the current key is *not* pressed.
        ; Check whether it was pressed the last time.
        ; if !(last[idx] & bitmask) goto end
        LDA LAST,Y
        AND BITMASK
        BEQ END

        ; Release event - we just clear the current bit
        ; in KEY, LAST and DEBST
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

        ; Key is pressed. Was it already pressed?
        ; if last[idx] & bitmask goto end
        LDA LAST,Y
        AND BITMASK
        BNE END

        ; Nope, check whether it has been debounced
        ; if !(debounce[idx] & bitmask) goto deb
        LDA DEBST,Y
        AND BITMASK
        BEQ DEB

        ; Now set the bit in KEY and LAST
        ; key[idx] |= bitmask
        TXA
        ORA KEY,Y
        STA KEY,Y
        ; last[idx] |= bitmask
        TXA
        ORA LAST,Y
        STA LAST,Y
        JMP END

        ; Debounce - just mark this as on in DEBST
        ; and we will handle it on the next run
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
