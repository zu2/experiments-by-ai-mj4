; Entry at $4000. voice/trees.s follows these tables.
	.setcpu	6800
	.code
start:
	jmp	boot
; greedy reads gd_transitions and kattr_x reads kattr with a one-byte
; offset, so the tables must not cross a page. Here, right after the entry at
; $4000, they do not move.
gd_transitions:
 .byte 0,8,1,9,2,0,0,0,16,1,9,2,10,0,0,0,0,1,9,2,10
; Kind attributes: A_YAOCHU, A_HONOR, A_GREEN, A_T28, A_M46 and the suit
; (0 for the empty kinds between the suits and the honors).
kattr:
 .byte 0,$11,$18,$10,$90,$90,$90,$10,$18,$11
 .byte 0,$21,$28,$20,$A0,$A0,$A0,$20,$28,$21
 .byte 0,$41,$4C,$44,$C4,$C0,$C4,$40,$4C,$41
 .byte 0,$03,$03,$03,$03,$03,$07,$03
