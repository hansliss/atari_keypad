; This is just a wrapper to give "poller.asm" a
; start address. See "poller.asm" for more info.

* = $1A00

Incasm "poller.asm"

