# atari_keypad
A 12-key keypad for the joystick port, based on the Atari 2600 keypad

The keypad uses Kailh sockets for Cherry MX-compatible keyswitches,
and is meant to be used with a 3d-printed box, including a faceplate
to keep the switches in place. This box has not been designed yet.

The keypad has anti-ghosting diodes on all keys. There are three
pull-up resistors, one for each column. The original keypad only
included the first two resistors, and as far as I know, the third
one is not needed.

The design includes a PCB-mounted DB-9 female connector. You can use
this with a straight, fully connected DB-9 male-to-female cable to
connect the keypad to a computer or console, or you can just solder
cables to the solder pads if you prefer that.

Included is also VIC-20 code for scanning the keypad. It includes
full N-key rollover and produces two bytes of bits, one bit for each
key. Debouncing is done by delaying keypress events until they have
been seen by at least two scanning cycles.

There is a second machine code function that "unpacks" the bytes into
a series of individual bytes, one for each key. This is because BASIC
turns out to be breathtakingly slow at this kind of bit-mangling.

There are two BASIC programs, one that uses just the main subroutine
and does the bit unpacking itself, and another on that uses the machine
code subroutine to unpack the bytes. The second one is a little bit
faster.
