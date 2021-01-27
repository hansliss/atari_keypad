; Keypad scanner for the Atari 2600-compatible keypad
; This implements full n-key rollover, which may or may
; not be useful depending on whether the keypad has anti-
; ghosting or not.

; If you want to use this from something, either include
; this file or load "kppoll", and then call POLL, and read
; the result as a bitfield in KEY and KEY+1.
; If you want the bits unpacked, load "reorg", call REORG$,
; and read the result from KEY2$.

; Finally, if you just want a flashy demo, load "showpad"
; and jump to START.

; bits within the two bytes
; and their correspondence to
; keypad keys
;     012   byte 0
;     345
;     670
;     123   byte 1

V1PORTA = $9111
V1DDRA = $9113
V2PORTB = $9120
V2DDRB = $9122
POTX = $9008
POTY = $9009

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
SV1DDRA
        BYTE 0
SV1PORTA
        BYTE 0
SV2DDRB
        BYTE 0
SV2PORTB
        BYTE 0
;  scratch storage
SCRATCH BYTE 0

; persistent
;  debouncing status
DEBST   BYTE 0,0
;  the two key state bytes
KEY$     BYTE 0,0
POLL$
        SEI
        ; save I/O pin direction and port state
        LDA V1DDRA
        STA SV1DDRA
        LDA V1PORTA
        STA SV1PORTA
        LDA V2DDRB
        STA SV2DDRB
        LDA V2PORTB
        STA SV2PORTB
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
        STA V1DDRA
        LDA #$00
        ; Reset the other VIA port to input
        ; so it doesn't interfere!
        STA V2DDRB
        ; Set the output to low
        STA V1PORTA
        BEQ RDONE
        ; Row 3 is different, it's connected to
        ; VIA 2 port B
RSPEC
        LDA #$80
        STA V2DDRB
        LDA #$00
        ; Reset the other VIA port to input
        ; so it doesn't interfere!
        STA V1DDRA
        ; Set the output to low
        STA V2PORTB
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
        LDA V1PORTA
        AND #$20
        BEQ C2
        LDA #$04
        ORA COLUMNS
        STA COLUMNS
C2              
        LDA POTX
        BMI C3
        LDA #$02
        ORA COLUMNS
        STA COLUMNS
C3              
        LDA POTY
        BMI C4
        LDA #$01
        ORA COLUMNS
        STA COLUMNS
C4
        ; restore I/O pin direction
        LDA SV1PORTA
        STA V1PORTA
        LDA SV1DDRA
        STA V1DDRA
        LDA SV2PORTB
        STA V2PORTB
        LDA SV2DDRB
        STA V2DDRB
        CLI

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
        LDA KEY$,Y
        AND BITMASK
        BEQ END

        ; Release event - we just clear the current bit
        ; in KEY and DEBST
        LDX INVBM
        ; key[idx] &= inversebitmask
        TXA
        AND KEY$,Y
        STA KEY$,Y
        ; debounce[idx] &= inversebitmask
        TXA
        AND DEBST,Y
        STA DEBST,Y
        JMP END
ISPRSD
        LDX BITMASK

        ; Key is pressed. Was it already pressed?
        ; if last[idx] & bitmask goto end
        LDA KEY$,Y
        AND BITMASK
        BNE END

        ; Nope, check whether it has been debounced
        ; if !(debounce[idx] & bitmask) goto deb
        LDA DEBST,Y
        AND BITMASK
        BEQ DEB

        ; Now set the bit in KEY
        ; key[idx] |= bitmask
        TXA
        ORA KEY$,Y
        STA KEY$,Y
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
        RTS
