	TITLE	MINPUT

	TTYI==1
	DSKO==2
	A==1
	B==2
	C==3
	P==17
	BUFSIZ==100*5

START:	.CALL	[SETZ ? SIXBIT/OPEN/ ? 5000,,0
		1000,,TTYI ? [SIXBIT/TTY/] + SETZ]
	.VALUE
	.CALL	[SETZ ? SIXBIT/OPEN/ ? 5000,,1
		1000,,DSKO ? [SIXBIT/DSK/] ? [SIXBIT/FOO/]
		SETZ + [SIXBIT/>/]]
	.VALUE
	.CALL	[SETZ ? SIXBIT/TTYSET/ ? 1000,,TTYI
		[020000000000] ? 1000,,0 + SETZ]
	.VALUE

	MOVE	P,[-10,,PDL]
	MOVE	A,[440700,,BUF]
	MOVEI	B,BUFSIZ
LOOP:	.IOT	TTYI,C
	CAIN	C,^C
	JRST	EOF
	IDPB	C,A
	SOJG	B,L6
	PUSHJ	P,FLUSH
L6:	CAIE	C,15
	JRST	LOOP
	MOVEI	C,12	; HERE IF CR
	IDPB	C,A
	SOJG	B,LOOP
	PUSHJ	P,FLUSH
	JRST	LOOP

FLUSH:	MOVE	A,[440700,,BUF]
	MOVEI	B,BUFSIZ
	.CALL	[SETZ ? SIXBIT/SIOT/ ? 1000,,DSKO ? A ? SETZ B]
	.VALUE
	MOVE	A,[440700,,BUF]
	MOVEI	B,BUFSIZ
	POPJ	P,

EOF:	MOVN	B,B
	ADDI	B,BUFSIZ
	JUMPE	B,DONE
	MOVE	A,[440700,,BUF]
	.CALL	[SETZ ? SIXBIT/SIOT/ ? 1000,,DSKO ? A ? SETZ B]
	.VALUE
DONE:	.CLOSE	TTYI,
	.CLOSE	DSKO,
	.BREAK	16,160000
BUF:	BLOCK	BUFSIZ/5
PDL:	BLOCK	10
	END START
