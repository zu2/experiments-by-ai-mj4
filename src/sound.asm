; Sound with the DAC at $EE80 (bit 1-5).

	.code
SOUND	.equ	$EE80
SOUND_ON	.equ	$30

; X = notes: pairs of (delay, waves), ending with 0. A wave is two halves of
; about 6 * delay + 20 cycles each.
play:
 ldaa 0,x
 cmpa #$FF
 jeq pcm_play
	ldaa	0,x
	beq	play_04
	staa	pl_delay
	ldaa	1,x
	staa	pl_waves
	stx	pl_p
play_01:
	ldaa	#SOUND_ON
	staa	SOUND
	ldab	pl_delay
play_02:
	decb
	bne	play_02
	clr	SOUND
	ldab	pl_delay
play_03:
	decb
	bne	play_03
	dec	pl_waves
	bne	play_01
	ldx	pl_p
	inx
	inx
	bra	play
play_04:
	clr	SOUND
	rts

snd_select:
	.byte	60,40,0

snd_discard:
	.byte	40,8,0
	.bss
pl_delay:	.ds	1 ; half-wave delay
pl_waves:	.ds	1 ; waves left
pl_p:	.ds	2 ; current note
