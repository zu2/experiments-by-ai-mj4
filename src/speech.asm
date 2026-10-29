; 7,169 Hz 5-bit PCM, one DAC value per byte in PCM_BUF. Header: $FF, number
; of samples. IRQ remains enabled. A sample takes 105 cycles and every eighth
; sample 107, so eight samples take 842 cycles; both paths of the BEQ below
; are part of this timing. tools/voice.py resamples to 7,168 Hz.
PCM_BUF .equ $2100
pcm_play:
 jsr unpack_voice
 ldx #PCM_BUF
 ldab #8
 stab pcm_phase
pcm_play_00:
 ldaa 0,x
 staa SOUND
 inx
 ldab #PCM_DELAY
pcm_play_01:
 decb
 bne pcm_play_01
 dec pcm_phase
 beq pcm_play_02
 bra pcm_play_03
pcm_play_02:
 ldab #8
 stab pcm_phase
pcm_play_03:
 cpx up_end
 bne pcm_play_00
 clr SOUND
 rts
PCM_DELAY .equ 11
