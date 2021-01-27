!-CONST KEY1 $1A0D
!-CONST KEY2 $1A0E
!-CONST POLL $1A0F
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
170 SYS POLL
180 LK1=K1:LK2=K2:K1=PEEK(KEY1):K2=PEEK(KEY2)
190 IF LK1=K1 AND LK2=K2 THEN 170
200 FOR Y=0 TO 3
210 FOR X=0 TO 2
220 MASK=2^((Y * 3 + X) AND 7)
230 V=K1 AND MASK
240 IF ((Y AND 1) OR ((X AND 2)/2)) AND ((Y AND 2) / 2) THEN V=K2 AND MASK
250 IF V<>0 THEN POKE P(Y*3+X+1),PEEK(P(Y*3+X+1)) OR 128
260 IF V=0 THEN POKE P(Y*3+X+1),PEEK(P(Y*3+X+1)) AND 127
270 NEXT
280 NEXT
290 GOTO 170