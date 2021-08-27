 TITLE FOODEV
HACK==1

; This file contains the basics needed to write a JOB device handler.
; It should be .INSERTed by the file containing the device specific code.
; It defines that startup code, a few .CALL blocks, a stack, an
; interrupt handler, etc.  For full details, see the PTDD on the
; JOB device.

; The file containing the device specific code must supply the following:

;	STOPER	an eight word table.  Entry i contains the address
;		of the code that handles op-code i.  If a particular
;		op-code is not handled, put the address BADOP in its
;		table slot.

;	CALCNT	a variable whose value is set (via ==A) to the total
;		number of .CALL names that the handler knows about.

;	CALNAM	a table CALCNT words long.  Entry i contains the sixbit
;		name of a .CALL operation.

;	CALXCT	a table CALCNT words long.  Entry i contains the address
;		of the code that handles the operation whose name is
;		given in in slot i of CALNAM.


;AC DEFS

A=1
B=2
C=3
D=4
E=5
I=7
H=14
P=15    ;DO NOT CHANGE! ;PDL POINTER
T=16    ;"

CL=PUSHJ P,
RTN=POPJ P,
GO=JRST

.XCREF A,B,C,D,E,I,H,P,T,CL,RTN,GO

BOJC==1
DSK==2		; OPEN REAL FILE ON CHANNEL 2

XXXX==.

LOC	42
	JSR	TSINT

LOC	XXXX



LOC	77
SIXBIT /FOODEV/
DEVICE:	0	; DEVICE HE DID OPEN ON
FNAME1:	0	; FIRST NAME OF OPEN FILE
FNAME2:	0	; SECOND NAME OF OPEN FILE
DIRECT:	0	; DIRECTORY OF OPEN FILE
OPMODE:	0	; MODE OF OPEN
CRUNAM:	0	; CREATOR OF THIS DEVICE
CRJNAM:	0	; JNAME OF CREATOR OF THIS DEVICE

IFN HACK,[
IKEY:	0		; INITIAL KEY
KEY:	0		; CURRENT KEY
MAGIC:	525252,,525252	; INITIAL PREVIOUS KEY
OKEY:	0		; PREVIOUS KEY
	]

DSKPTR:	0	; DISK IOT POINTER
BOJPTR:	0	; BOJ IOT POINTER

CLSINP:	-1	; NOT -1 IF CLOSE IN PROGRES
RANDOM:	0	; RANDOM INFO FROM DIRECTORY BLOCK
CRDATE:	0	; CREATION DATE FROM DIRECTORY BLOCK
RFDATE:	0	; REFERENCE DATE FROM DIRECTORY BLOCK
IOCERR:	0	; IOC ERROR FLAG, 0=>NO ERROR, -1=>ERROR

PAT:
PATCH:	BLOCK	20

LPDLL=100
PDLPTR:	-LPDLL,,PDL

PDL:	BLOCK	LPDLL
INTOP:	0	; PLACE TO GET OP-CODE AT INTERRUPT LEVEL

; JOBGET AREA AND JOBGET FOR MAIN PROGRAM LEVEL

WD1:	0
WD2:	0
WD3:	0
WD4:	0
WD5:	0
WD6:	0
WD7:	0
WD8:	0
WD9:	0
WD10:	0
WD11:	0
WD12:	0
WD13:	0
RET=2000,,0

SYSTEM:	0

SSTATU:	SETZ
	SIXBIT /SSTATU/
	2000,,0
	2000,,0
	2000,,0
	2000,,0
	2000,,0
	2000,,SYSTEM
	SETZM 

RFBLK:	SETZ			; GET MY CREATOR'S NAME
	SIXBIT /RFNAME/
	1000,,BOJC
	2000,,A
	2000,,CRUNAM
	SETZM CRJNAM

IJGET:	SETZ			; GET OPERATOR WORD ONLY
	SIXBIT/JOBCAL/
	1000,,BOJC
	SETZM INTOP

JGET:	SETZ			; GET ALL INFO ABOUT LAST JOB I/O OP
	SIXBIT/JOBCAL/
	1000,,BOJC
	RET WD1
	SETZ [-12.,,WD2]

JRET:	SETZ			; UNHANG LAST JOB I/O OP 
	SIXBIT/JOBRET/
	1000,,BOJC
	H
	SETZ I

JIOC:	SETZ			; GIVE JOB USER AN I/O CHANNEL ERROR
	SIXBIT/SETIOC/
	1000,,BOJC
	SETZ I

JSTS:	SETZ			; RETURN FILE NAMES TO SYSTEM
	SIXBIT/JOBSTS/
	MOVEI BOJC
	MOVEI 22	;SNJOB
	[SIXBIT/DSK/]
	FNAME1
	SETZ FNAME2

START:	JFCL			; LEAVE PLACE TO PUT .VALUE FOR DEBUGGING
	.SUSET	[.SMASK,,[1_10]]	; ENABLE IOCERR INTERRUPT
	.SUSET	[.SMSK2,,[1_BOJC]]	; ENABLE CHANNEL INTERRUPT
	.CALL	SSTATU
	 .VALUE
	.OPEN	BOJC,[17,,(SIXBIT/BOJ/)]	; OPEN CHANNEL
	GO	CLOSE		; CAN'T
START1:	MOVE	P,PDLPTR	; RESET PDL
	SETOM	HNGFLG		; SET NOT HUNG

LOOP:	MOVEI	A,GOTOPR	; NO IOT IN PROGRESS
	MOVEM	A,INIOT		; MAKE INTERRUPTS GO AFTER HANG
	SETZM	INTSW		; INTERRUPTS SHOULD NEVER BE LOCKED OUT HERE
	SKIPN	HNGFLG		; SEE IF HUNG
	.HANG			; YES - WAIT UNTIL NOT
GOTOPR:	SETZM	HNGFLG
	MOVE	P,[-LPDLL-1,,PDL-1]	; RESET PDL IN CASE SOMEBODY INTERRUPTED
	MOVEI	A,LOOP		; NO IOT IN PROGRESS
	MOVEM	A,INIOT		; MAKE INTERRUPTS ABORT OPERATION
	.CALL	JGET		; GET INFO FOR CALL
	GO	CHKOPN		; FAILED - IGNORE
	LDB	A,[370200,,WD1]	; SEE IF CLOSE BITS SET
	JUMPN	A,CLOSE		; YES - GO CLOSE
	LDB	A,[000400,,WD1]	; GET OP CODE
	CAIGE	A,10		; .CALL?
	GO	@STOPER(A)	; STANDARD OPERATOR - GO PROCESS
	MOVE	A,WD2		; GET SIXBIT OF .CALL NAME
	SKIPL	B,[-CALCNT,,0]	; GET POINTER TO NAMES WE KNOW ABOUT
	GO	BADOP		; IF CALCNT=0, THEN NO .CALLS HANDLED
	CAMN	A,CALNAM(B)
	GO	@CALXCT(B)		; FOUND IT - GO EXECUTE THE RIGHT CODE
	AOBJN	B,.-2		; NO - KEEP LOOKING
BADOP:	HRLZI	H,12		; SET "MODE NOT AVAILABLE" FOR ILLEGAL OPS
	SETZM	I		; NO RETURNS
	.CALL	JRET		; MAKE HIM CONTINUE W/O SKIPPING
	JFCL			; DON'T CARE IF HE HAS QUIT
	GO	LOOP		; DON'T DIE FOR THAT

CHKOPN:	SKIPE	IFOPEN		; IS THE CHANNEL ALREADY OPEN?
	GO	LOOP		; YES - STAY IN LOOP UNTIL CLOSE
	GO	CLOSE		; NO - LET SOMEBODY ELSE HAVE IT

CLOSE:	.CLOSE	BOJC,		; CLOSE THE CHANNEL
	SKIPE	CLSCOD		; DID USER SUPPLY CLOSE ROUTINE?
	GO	@CLSCOD		; YES - EXEUCUTE IT
	.LOGOUT
	.VALUE


; NOTE!! - BECAUSE OF PCLSR HACKING IN THE SYSTEM, INTERRUPTS FROM
; THE JOB USER MUST CAUSE ANY CURRENT OPERATION TO BE ABORTED.  IOT'S
; ARE HANDLED IN A SPECIAL WAY TO ALLOW THE BOJ TO RECORD INTERRUPTED
; IOTS THAT WERE HALF COMPLETED.  IF YOU WANT SOMETHING TO BE DONE
; WHEN IOTS ARE INTERRUPTED, PUT AN ADDRESS INTO THE WORD "INIOT".
; THE INTERRUPT HANDLER WILL JUMP TO THAT ADDRESS INSTEAD OF DISMISSING.
; THE LAST THING THAT SHOULD BE DONE AT THAT ADDRESS IS THE FOLLOWING:

;	.DISMISS [LOOP]

TSINT:	0
	0
	SKIPL	TSINT		; IOC INTERRUPT
	GO	INTIOE		; NO - IOERR INTERRUPT
	.CALL	IJGET		; GET COMMAND INFO
	GO	TSINT1		; NONE - DISMISS WITHOUT WAKEUP
	PUSH	P,A		; SAVE A
	LDB	A,[370200,,INTOP]	; GET CLOSE BITS
	JUMPE	A,TSINT0	; SEE IF CLOSE?
	SKIPN	INTSW		; ARE INTERRUPTS LOCKED OUT?
	GO	CLOSE		; NO - GO CLOSE RIGHT NOW
	MOVEI	A,1		; YES - MARK CLOSE WANTED WHEN UNLOCKED
	MOVEM	A,INTSW2
	POP	P,A
	.DISMIS	TSINT+1

TSINT0:	POP	P,A		; OTHERWISE - RESTORE A
	SETOM	HNGFLG		; WAKEUP MAIN PROGRAM LEVEL
TSINT1:	SKIPN	INTSW		; BOJ INTERRUPTS LOCKED OUT?
	.DISMIS	INIOT		; NO - DISMISS REGULAR WAY
	SETOM	INTSW2		; SET INTERRUPT OCCURRED SWITCH
	.DISMIS	TSINT+1		; CONTINUE INTERRUPTED CODE FOR NOW

INTIOE:	MOVEI	I,3
	.CALL	JIOC		; SIGNAL IOC ERROR TO USER
	JFCL
	MOVEI	A,300		; SLEEP AWHILE TO TRY AVOID STATUS TIMING ERROR
	.SLEEP	A,
	GO	CLOSE		; DIE


; INTOFF - THIS ROUTINE CAN BE CALLED TO TELL THE INTERRUPT HANDLER
; NOT TO INTERRUPT UNTIL AN INTON IS DONE (INTOFF'S ARE NOT CUMMULATIVE)

INTOFF:	SKIPG	INTSW		; IF NOT LOCKED - FLUSH PENDING STUFF
	SETZM	INTSW2		; NO PENDING INTERRUPTS
	AOS	INTSW		; BUMP INTERRUPT LOCK COUNT
	RTN

; INTON - THIS ROUTINE CAN BE CALLED TO TELL THE INTERRUPT HANDLER
; THAT BOJ INTERRUPTS ARE OK AGAIN.  ANY INTERRUPT THAT HAS ARRIVED
; SINCE THE INTOFF WILL BE PRESENTED NOW (I.E. INTON WILL NOT RETURN
; TO THE CALLER UNLESS THERE IS NO PENDING INTERRUPT).

INTON:	PUSH	P,A
	SOSLE	INTSW		; DECREMENT INTERRUPT LOCK SWITCH
	GO	INTON2		; STILL POSITIVE - STILL LOCKED
	SETZM	INTSW
	SKIPLE	INTSW2		; DID A CLOSE OCCUR?
	GO	CLOSE		; YES - CLOSE RIGHT NOW
	SKIPN	INTSW2		; DID AN INTERRUPT OCCUR?
	GO	INTON2		; NO - FORGET IT
	SETOM	HNGFLG		; MAKE SURE HE DOESN'T HANG
	POP	P,A
	GO	@INIOT		; OK TO PROCESS NOW
INTON2:	POP	P,A		; OTHERWISE RETURN TO CALLER
	RTN


INTSW:	0	; 0=> BOJ INTERRUPTS OK, -1=>NO BOJ INTERRUPTS
INTSW2:	0	; -1=>BOJ INTERRUPT OCCURRED WHILE LOCKED
HNGFLG:	0
IFOPEN:	0
INIOT:	START			; INTERRUPTS CAUSE RESTART UNTIL
				;   MAIN LOOP IS ENTERED THE FIRST TIME

CLSCOD:	0
; DISPATCH TABLES, ETC. USED BY 'BASIC' DEVICE CODE
STOPER:	OPEN
	IOT
	BADOP			; STATUS DOESN'T COME ANY MORE
	RESET
	RCHST
	ACCESS
	BADOP			; DELETE
	NOOP1			; RENAME WHILE OPEN

NOOP0:	SKIPA	H,[0]		; MAKE USERS CALL DO NOTHING - NO SKIP
NOOP1:	MOVEI	H,1		; MAKE USERS CALL DO NOTHING BUT SKIP
	SETZM	I
	.CALL	JRET
	JFCL
	GO	LOOP

RESET==NOOP0

; CALNAM - TABLE OF THE NAMES OF THE .CALLS HANDLED

CALNAM:	SIXBIT/FILBLK/		; GET NAME AREA FROM DIRECTORY
	SIXBIT/FILLEN/		; GET FILE LENGTH
	SIXBIT/RFDATE/		; READ CREATION DATE/TIME
	SIXBIT/SFDATE/		; SET CREATION DATE/TIME
	SIXBIT/RDMPBT/		; READ DUMP BIT
	SIXBIT/RESRDT/		; RESET REFERENCE DATE
	SIXBIT/SDMPBT/		; SET DUMP BIT
	SIXBIT/SRDATE/		; SET REFERENCE DATE
	SIXBIT/SREAPB/
	SIXBIT/SAUTH/
	SIXBIT/RAUTH/
CALCNT==4;	.-CALNAM	; CALCNT - NUMBER OF .CALLS HANDLED

; CALXCT - NAMES OF ROUTINES TO HANDLE .CALLS

CALXCT:	FILBLK
	FILLEN
	RDFDAT
	SFDATE
	RDMPBT
	RESRDT
	SDMPBT
	SRDATE
	SREAPB
	SAUTH
	RAUTH


; NOSUCH - COME HERE TO REPORT "NO SUCH DEVICE"

NOSUCH:	HRLZI	H,1
	GO	OPFAIL

NOMODE:	HRLZI	H,12
	GO	OPFAIL

; TOOFEW - COME HERE TO INDICATE TOO FEW ARGS ON A .CALL

TOOFEW:	HRLZI	H,30
	JRST	OPFAIL

; OPFAIL - COME HERE WITH FAILURE CODE IN LEFT HALF OF H TO REPORT
; OPEN FAILURE

OPFAIL:	SETZM	I		; COME HERE TO REPORT OPEN FAILURE
	SKIPL	CLSINP		; ERROR WHILE CLOSE IN PROGRESS?
	GO	CLSDIE		; THEN JUST GO AWAY
	.CALL	JRET
	JFCL
	SKIPN	IFOPEN		; IS THIS .CALL FAILURE?
	GO	CLOSE		; NO - OPEN FAILURE - DIE
	GO	LOOP		; .CALL FAILURE - STAY IN LOOP

; COME HERE TO REPORT ACCESS BEYOND END OF FILE

PSTEOF:	MOVEI	I,2		; REPORT ACCESS BEYOND EOF
	.CALL	JIOC		; BY GENERATING IOC ERR
	JFCL
	GO	LOOP		; BUT DON'T DIE (HE MIGHT ACCESS)



; OPEN - PROCESS A REQUEST FOR AN OPEN ON THE DEVICE

OPEN:	MOVE	A,WD3		; COPY SUB-FILE NAMES
	MOVEM	A,FNAME1
	MOVE	A,WD4
	MOVEM	A,FNAME2
	MOVE	A,WD5
	MOVEM	A,DIRECT
	MOVE	A,WD6
	MOVEM	A,DEVICE
	MOVE	A,WD7		; SAVE OPEN MODE
	MOVEM	A,OPMODE
IFN HACK,[
	TRNN	A,2		; MUST BE BLOCK MODE
	GO	NOMODE		; UNIT MODE NOT AVAILABLE
	]
	HRLZ	A,OPMODE	; GET OPEN MODE
	TLZ	A,777770	; ISOLATE BASIC OPEN MODES
	TLC	A,1		; COMPLEMENT READ/WRITE MODE
	TLO	A,10		; MAKE SURE OPPOSITE DIRECTION BIT IS ON
	HRRI	A,(SIXBIT/BOJ/)
	.OPEN	BOJC,A		; OPEN BOJ IN THE CORRECT MODE
	GO	CLOSE		; ERROR IF CANT
	.CALL	RFBLK
	JFCL

	MOVE	A,FNAME1
	MOVE	B,FNAME2	; SEE IF HE ASKED FOR DIRECTORY
	CAMN	A,[SIXBIT/.FILE./]
	CAME	B,[SIXBIT/(DIR)/]
	GO	.+2	
	GO	NOSUCH

IFN HACK,[CL	MAKKEY
	MOVE	A,[SIXBIT/:FILE:/]
	MOVEM	A,FNAME2
	]

	.CALL	JSTS
	 JFCL

IFN HACK,[
	.CALL	[SETZ ? SIXBIT/OPEN/ ? 5000,,0 ? 3000,,H
		1000,,DSK ? [SIXBIT/DSK/] ? FNAME1 ? FNAME2 ? SETZ DIRECT]
	 JRST 	USENUM
	.CLOSE	DSK,
	JRST	REALOPN
USENUM:	MOVE	A,[SIXBIT/>/]
	MOVEM	A,FNAME2
	.CALL	JSTS
	 JFCL
	]

REALOPN:
	.CALL	[SETZ ? SIXBIT/OPEN/ ? 4000,,OPMODE ? 3000,,H
		1000,,DSK ? [SIXBIT/DSK/] ? FNAME1 ? FNAME2 ? SETZ DIRECT]
	GO	[HRLZ H,H
		JRST OPFAIL]

	.CALL	RFLBLK
	JFCL

IFN HACK,[CL	ACCES0]

	GO	OPNWIN


CLSDIE:	.LOGOU			; AND GO AWAY
	.VALUE


; IOT - COME HERE TO PROCESS JOB'S IOTS.

IOT:	SKIPGE	IOCERR		; I/O CHANNEL ERROR PENDING?
	GO	PSTEOF		; YES - GO REPORT IT
	MOVEI	A,FILIOT	; USE FILE IOT TABLE
	LDB	B,[000300,,OPMODE]	; GET BASIC OPEN MODE
	ADD	A,B		; SPACE TO RIGHT ENTRY IN TABLE
	GO	@(A)		; DISPATCH TO AN IOT ROUTINE


; FILIOT - DISPATCH TABLE FOR NON-DIRECTORY IOTS

FILIOT:	FAUI	; ASCII UNIT INPUT
	FAUO	; ASCII UNIT OUTPUT
	FABI	; ASCII BLOCK INPUT
	FABO	; ASCII BLOCK OUTPUT
	FIUI	; IMAGE UNIT INPUT
	FIUO	; IMAGE UNIT OUTPUT
	FIBI	; IMAGE BLOCK INPUT
	FIBO	; IMAGE BLOCK OUTPUT



; FABO - FILE ASCII BLOCK OUTPUT    SAME AS,
; FIBO - FILE IMAGE BLOCK OUTPUT

FABO:
FIBO:	JFCL
	CL	INTOFF
	SKIPE	DSKPTR
	GO	FIBO2
	SKIPE	BOJPTR
	GO	FIBO1
FIBO0:	MOVEI	B,BUFFER	; BUILD IOT POINTER
	HLL	B,WD2		; COUNT
	TLO	B,774000	; DONT OVERFLOW BUFFER
	MOVEM	B,BOJPTR
	CL	INTON
	.IOT	BOJC,BOJPTR	; READ STUFF
	CL	INTOFF
FIBO1:	HRRZ	A,BOJPTR
	SETZM	BOJPTR
	SUBI	A,BUFFER	; NUMBER OF WORDS TRANSFERRED
IFN HACK,[CL	ZAP]
	HRLZ	B,A
	ADDM	B,WD2		; UPDATE USER'S IOT POINTER
	MOVN	A,A
	MOVEI	B,BUFFER
	HRL	B,A		; NEW IOT POINTER
	MOVEM	B,DSKPTR
FIBO2:	CL	INTON
	.IOT	DSK,DSKPTR	; WRITE STUFF
	CL	INTOFF
	SETZM	DSKPTR
	SKIPL	WD2		; DOES USER WANT ANY MORE?
	GO	FIBO4		; NO - GO FINISH UP
	GO	FIBO0		; OK - GO ON
FIBO4:	CL	INTON		; TURN INTERRUPTS BACK ON
	GO	LOOP





; FABI - FILE ASCII BLOCK INPUT   SAME AS,
; FIBI - FILE IMAGE BLOCK INPUT


FABI:
FIBI:	JFCL
	CL	INTOFF
	SKIPE	BOJPTR
	GO	FIBI2
	SKIPN	DSKPTR
	GO	FIBI0
	HRRZ	B,DSKPTR
	CAIE	B,BUFFER
	GO	FIBI1
FIBI0:	MOVEI	B,BUFFER	; BUILD IOT POINTER
	HLL	B,WD2		; COUNT
	TLO	B,774000	; DON'T OVERFLOW BUFFER
	MOVEM	B,DSKPTR
	CL	INTON
	.IOT	DSK,DSKPTR	; READ STUFF
	CL	INTOFF
FIBI1:	HRRZ	A,DSKPTR
	SETZM	DSKPTR
	SUBI	A,BUFFER	; NUMBER OF WORDS TRANSFERRED
	JUMPE	A,[SETZM H	; NO SKIP NEEDED
		.CALL JRET	; UNHANG USER
		JFCL
		JRST FIBI4]
IFN HACK,[CL	DEZAP]
	MOVN	A,A
	MOVEI	B,BUFFER
	HRL	B,A		; NEW IOT POINTER
	MOVEM	B,BOJPTR
FIBI2:	CL	INTON
	.IOT	BOJC,BOJPTR	; WRITE STUFF
	CL	INTOFF
	HRRZ	A,BOJPTR
	SETZM	BOJPTR
	SUBI	A,BUFFER	; NUMBER OF WORDS TRANSFERRED
	HRLZ	A,A
	ADDM	A,WD2		; UPDATE USER'S IOT POINTER
	SKIPL	WD2		; DOES USER WANT ANY MORE?
	GO	FIBI4		; NO - GO FINISH UP
	GO	FIBI0		; OK - GO ON
FIBI4:	CL	INTON		; TURN INTERRUPTS BACK ON
	GO	LOOP

; FAUO - FILE ASCII UNIT OUTPUT
; FIUO - FILE IMAGE UNIT OUTPUT

FAUO:
FIUO:	.IOT	BOJC,B		; GET NEXT CHARACTER
	.IOT	DSK,B		; WRITE TO FILE
	GO	LOOP

; FAUI - FILE ASCII UNIT INPUT

FAUI:	.IOT	DSK,B		; READ CHARACTER FROM FILE
	SKIPGE	B,
	GO	FAUI3		; SEND EOF
	.IOT	BOJC,B		; NO - SEND CHARACTER
	GO	LOOP		; GO UPDATE COUNTS

FAUI3:	.IOT	BOJC,[-1,,3]	; SEND EOF
	SETOM	IOCERR		; IOC ERROR NEXT TIME
	GO	LOOP

; FIUI - FILE IMAGE UNIT INPUT

FIUI:	.IOT	DSK,B		; READ WORD FROM FILE
	.IOT	BOJC,B		; SEND WORD
	GO	LOOP		; MUST DETECT EOF!!!



; RCHST - HANDLE THE .RCHST UUO - RETURN NAMES AND ACCESS POINTER

RCHST:	MOVEI	I,1(P)		; GET POINTER TO ROOM ON STACK
	MOVS	H,DEVICE
	PUSH	P,H		; SEND DEVICE
	PUSH	P,FNAME1	; REAL FILE NAMES
	PUSH	P,FNAME2
	PUSH	P,DIRECT	; DIRECTORY NAME
	PUSH	P,[0]		; CURRENT ACCESS POINTER
	PUSH	P,[0]		; UNKNOWN
	PUSH	P,[0]		; UNKNOWN
	HRLI	I,-7
	SETZM	H		; NO SKIP NEEDED
	.CALL	JRET		; SEND INFO AND UNHANG USER
	JFCL
	SUB	P,[7,,7]
	GO	LOOP


; .CALL HANDLERS

; FILBLK - SEND 5 WORD NAME AREA

RFLBLK:	SETZ
	SIXBIT/FILBLK/
	1000,,DSK
	2000,,FNAME1
	2000,,FNAME2
	2000,,RANDOM
	2000,,CRDATE
	402000,,RFDATE

FILBLK:	.CALL	RFLBLK
	JFCL
	PUSH	P,FNAME1	; FILE NAMES FIRST
	PUSH	P,FNAME2
	PUSH	P,RANDOM	; THEN RANDOM INFO
	PUSH	P,CRDATE	; THEN CREATION DATE
	PUSH	P,RFDATE	; AND REFERENCE DATE
	MOVEI	A,5
CALWIN:	SKIPN	I,A		; ANY RETURNS?
	GO	CALWN1
	MOVN	B,A		; GET NEGATIVE OF COUNT
	MOVEI	I,1(P)		; GET POINTER TO TOP OF P
	SUB	I,A		; GET POINTER TO FIRST ONE
	HRL	I,B		; MAKE CPTR
CALWN1:	MOVEI	H,1		; MAKE LOSER SKIP
	.CALL	JRET
	JFCL
	HRLS	A
	SUB	P,A		; RESET P
	GO	LOOP

; FILLEN - SEND FILE'S LENGTH

FILLEN:	.CALL	[SETZ ? SIXBIT/FILLEN/ ? 1000,,DSK ? 402000,,A]
	JFCL
	PUSH	P,A		; SEND HIM THE LENGTH
	MOVEI	A,1
	GO	CALWIN

; RDMPBT - READ THE DUMP BIT

RDMPBT:	PUSH	P,[0]		; 0 => NOT BACKUP UP
	MOVEI	A,1
	GO	CALWIN

; RESRDT - RESET REFERENCE DATE TO WHAT IT WAS BEFORE OPEN.

RESRDT:	SETZM	A		; JUST SKIP - NO RETURNS
	GO	CALWIN

; RFDATE - READ CREATION DATE

RDFDAT:	.CALL	[SETZ ? SIXBIT/RFDATE/ ? 1000,,DSK ? 402000,,A]
	JFCL
	PUSH	P,A
	MOVEI	A,1
	GO	CALWIN

; RAUTH - READ THE FILE AUTHOR

RAUTH:	PUSH	P,[0]
	MOVEI	A,1
	GO	CALWIN

; SAUTH - SET THE FILE AUTHOR

SAUTH:	SETZ	A,
	GO	CALWIN

; SREAPB - SET THE REAP BIT

SREAPB:	SETZ	A,
	GO	CALWIN

; SDMPBT - SET THE DUMP BIT

SDMPBT:	SETZ	A,
	GO	CALWIN

; SFDATE - SET FILE CREATION DATE

SFDATE:	MOVE	A,WD4		; GET ARG COUNT
	CAIGE	A,2		; MUST BE AT LEAST TWO
	GO	TOOFEW		; GIVE TOO FEW ARGUMENT FAILURE
	.CALL	[SETZ ? SIXBIT/SFDATE/ ? 1000,,DSK ? SETZ WD6]
	JFCL
	SETZ	A,
	GO	CALWIN

; SRDATE - SET REFERENCE DATE

SRDATE:	SETZ	A,
	GO	CALWIN


; ACCESS - THIS ROUTINE HANDLES ACCESSING WITHIN THE FILE

ACCESS:	SETZM	IOCERR		; CLEAR I/O ERROR FLAG
	MOVE	A,WD2		; GET POSITION HE WANTS
	JUMPN	A,BADOP		; ONLY ACCESS TO ZERO WORKS
	CL	ACCES0
	GO	NOOP1

ACCES0:	.ACCESS	DSK,[0]
IFN HACK,[
	MOVE	A,[14060301406]
	MOVE	B,[-1,,A]
	.IOT	DSK,B
	MOVE	A,IKEY
	MOVEM	A,KEY
	MOVE	A,MAGIC
	MOVEM	A,OKEY
	]
	RTN

OPNWIN:	SETOM	IFOPEN		; SET NOW OPEN SWITCH
	MOVEI	H,1		; MAKE HIM SKIP
	SETZM	I		; NO - RETURNS
	.CALL	JRET
	JFCL			; WHAT?
	GO	LOOP		; GO BACK INTO THE LOOP

IFN HACK,[

MAKKEY:	PUSH	P,A
	PUSH	P,B
	PUSH	P,C
	PUSH	P,D
	MOVE	B,[440400,,FNAME2]
	MOVEI	C,9.
	SETZ	A,
MK1:	ILDB	D,B
	ADD	A,D
	SOJG	C,MK1
	ANDI	A,17
	MOVE	B,FNAME2
	XOR	B,MASK(A)
	MOVEM	B,IKEY
	MOVEM	B,KEY
	POP	P,D
	POP	P,C
	POP	P,B
	POP	P,A
	RTN

MASK:	777777,,777777
	737373,,737373
	373737,,373737
	535353,,535353
	353535,,353535
	636363,,636363
	363636,,363636
	676767,,676767
	757575,,757575
	575757,,575757
	777333,,333777
	333777,,777333
	777123,,321777
	135713,,571357
	565656,,565656
	656565,,656565

ZAP:	PUSH	P,A
	PUSH	P,B
	PUSH	P,C
	PUSH	P,D
	MOVEI	B,BUFFER
ZAP0:	JUMPLE	A,ZAP1
	MOVE	C,(B)
	MOVE	D,KEY
	ANDI	D,37
	ROT	C,2(D)
	XOR	C,KEY
	EXCH	C,(B)
	ANDI	C,37
	MOVE	D,KEY
	EXCH	D,OKEY
	ROT	D,2(C)
	XORM	D,KEY
	ADDI	B,1
	SUBI	A,1
	GO	ZAP0
ZAP1:	POP	P,D
	POP	P,C
	POP	P,B
	POP	P,A
	RTN

DEZAP:	PUSH	P,A
	PUSH	P,B
	PUSH	P,C
	PUSH	P,D
	MOVEI	B,BUFFER
DEZAP0:	JUMPLE	A,DEZAP1
	MOVE	C,(B)
	XOR	C,KEY
	MOVE	D,KEY
	ANDI	D,37
	MOVN	D,D
	ROT	C,-2(D)
	MOVEM	C,(B)
	ANDI	C,37
	MOVE	D,KEY
	EXCH	D,OKEY
	ROT	D,2(C)
	XORM	D,KEY
	ADDI	B,1
	SUBI	A,1
	GO	DEZAP0
DEZAP1:	POP	P,D
	POP	P,C
	POP	P,B
	POP	P,A
	RTN
	]


CONSTANTS
BUFFER:	BLOCK 4000
0
END START

