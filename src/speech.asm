; 7,169 Hz 5-bit PCM in PCM_BUF, 8 samples in 5 bytes: 4 bytes of bits 3-0 of
; two samples (high nibble first), then bits 4 of the 8 samples (bit 7 first).
; Header: $FF, number of bytes. IRQ remains enabled. A sample takes 105 cycles
; and the first of every eight 107, so eight samples take 842 cycles; both
; paths of the BEQ below are part of this timing. tools/voice.py resamples to
; 7,168 Hz.
PCM_BUF .equ $2100
pcm_play:
 jsr unpack_voice
 ldx #PCM_BUF
 ldaa 4,x
 staa pcm_hb
 ldab #4
 stab pcm_phase
pcm_play_00:
 ldaa 0,x
 asl pcm_hb
 rora
 lsra
 lsra
 anda #$3E
 staa SOUND
 ldab #11
pcm_play_01:
 decb
 bne pcm_play_01
 ; 7 cycles.
 ldaa pcm_phase
 nop
 nop
 ldaa 0,x
 asla
 asla
 asla
 asla
 asl pcm_hb
 rora
 lsra
 lsra
 staa SOUND
 inx
 ldab #6
pcm_play_02:
 decb
 bne pcm_play_02
 dec pcm_phase
 beq pcm_play_04
 ; 20 cycles, as pcm_play_04 less 2.
 ldab #2
pcm_play_03:
 decb
 bne pcm_play_03
 nop
 bra pcm_play_05
pcm_play_04:
 inx
 ldaa 4,x
 staa pcm_hb
 ldab #4
 stab pcm_phase
 nop
pcm_play_05:
 cpx up_end
 bne pcm_play_00
 ; The last sample takes 102 cycles as before.
 ldab #2
pcm_play_06:
 decb
 bne pcm_play_06
 clr SOUND
 rts
 .bss
pcm_hb: .ds 1 ; bits 4 of the samples left in this group
