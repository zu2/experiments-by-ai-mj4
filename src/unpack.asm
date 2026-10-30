; Per-word lossless delta Huffman expansion into PCM_BUF in the form of pcm_play.
; A delta after 0, 1 or 31 (and the first) uses voice_tree0, others voice_tree.
unpack_voice:
 ldaa 1,x
 ldab 2,x
 addb #<PCM_BUF
 adca #>PCM_BUF
 staa up_end
 stab up_end+1
 inx
 inx
 inx
 stx up_src
 ldx #PCM_BUF
 stx up_dst
 ldaa #$80
 staa up_flag
 clr up_k
 ldaa #16
 staa up_prev
 clr up_delta
unpack_voice_00:
 ldx #voice_tree0
 ldab up_delta
 incb
 andb #31
 cmpb #3
 bcs unpack_voice_07
 ldx #voice_tree
unpack_voice_07:
 ldaa up_flag
 ; up_flag holds the bits not used yet, then a 1.
unpack_voice_01:
 asla
 bne unpack_voice_02
 stx up_node
 ldx up_src
 ldaa 0,x
 inx
 stx up_src
 ldx up_node
 sec
 rola
unpack_voice_02:
 ldab 0,x
 bcc unpack_voice_03
 ldab 1,x
unpack_voice_03:
 ; A node is in the page of up_node; leaves are 0..31.
 cmpb #32
 bcs unpack_voice_04
 stab up_node+1
 ldx up_node
 bra unpack_voice_01
unpack_voice_04:
 staa up_flag
 stab up_delta
 tba
 adda up_prev
 anda #31
 staa up_prev
 tab
 aslb
 aslb
 aslb
 aslb
 rol up_hb
 ldx up_dst
 inc up_k
 ldaa up_k
 bita #1
 beq unpack_voice_05
 stab 0,x
 bra unpack_voice_00
unpack_voice_05:
 ldaa up_prev
 anda #$0F
 oraa 0,x
 staa 0,x
 inx
 ldaa up_k
 cmpa #8
 bne unpack_voice_06
 ldaa up_hb
 staa 0,x
 inx
 stx up_dst
 jsr demo_poll
 ldx up_dst
 clr up_k
unpack_voice_06:
 stx up_dst
 cpx up_end
 bne unpack_voice_00
 rts
 .bss
up_src: .ds 2 ; next packed byte
up_dst: .ds 2 ; next output byte
up_end: .ds 2 ; end of the output
up_flag: .ds 1 ; Huffman bit buffer
up_prev: .ds 1 ; previous sample
up_node: .ds 2 ; Huffman tree node
up_delta: .ds 1 ; last delta (0..31)
up_k: .ds 1 ; samples of this group written
up_hb: .ds 1 ; bits 4 of these samples
