!-CONST KEY $1A00
!-CONST REORG $1A0C
10 PRINT"{clear}{red}";
20 PRINT"{cm a}{sh asterisk}{cm r}{sh asterisk}{cm r}{sh asterisk}{cm s}"
30 PRINT"{sh -}1{sh -}2{sh -}3{sh -}"
40 PRINT"{cm q}{sh asterisk}{sh +}{sh asterisk}{sh +}{sh asterisk}{cm w}"
50 PRINT"{sh -}4{sh -}5{sh -}6{sh -}"
60 PRINT"{cm q}{sh asterisk}{sh +}{sh asterisk}{sh +}{sh asterisk}{cm w}"
70 PRINT"{sh -}7{sh -}8{sh -}9{sh -}"
80 PRINT"{cm q}{sh asterisk}{sh +}{sh asterisk}{sh +}{sh asterisk}{cm w}"
90 PRINT"{sh -}*{sh -}0{sh -}#{sh -}"
100 PRINT"{cm z}{sh asterisk}{cm e}{sh asterisk}{cm e}{sh asterisk}{cm x}"
110 DIM P(12)
120 FOR Y=0 TO 3
130 FOR X=0 TO 2
140 P(Y*3+X+1)=7680+Y*44+X*2+23
150 NEXT
160 NEXT
180 SYS REORG
190 FOR Y=0 TO 3
200 FOR X=0 TO 2
210 V=PEEK(KEY + Y*3 + X)
220 IF V<>0 THEN POKE P(Y*3+X+1),PEEK(P(Y*3+X+1)) OR 128
230 IF V=0 THEN POKE P(Y*3+X+1),PEEK(P(Y*3+X+1)) AND 127
240 NEXT
250 NEXT
260 GOTO 170