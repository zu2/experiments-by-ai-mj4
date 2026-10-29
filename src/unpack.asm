; Per-word lossless delta Huffman expansion into PCM_BUF, one DAC value per sample.
; A delta after a zero delta (and the first) uses voice_tree0, others voice_tree.
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
 clr up_bits
 ldaa #16
 staa up_prev
 clr up_node+1
unpack_voice_00:
 ldaa up_flag
 ldab up_bits
 ldx #voice_tree
 ; up_node+1 is the previous leaf: the delta (0..31).
 tst up_node+1
 bne unpack_voice_01
 ldx #voice_tree0
unpack_voice_01:
 tstb
 bne unpack_voice_02
 stx up_node
 ldx up_src
 ldaa 0,x
 inx
 stx up_src
 ldab #8
 ldx up_node
unpack_voice_02:
 asla
 decb
 bcs unpack_voice_03
 ldx 0,x
 bra unpack_voice_04
unpack_voice_03:
 ldx 2,x
unpack_voice_04:
 ; Nodes are in $4000..$AFFF; leaves are 0..31. CPX does not set C on 6800.
 cpx #$4000
 bpl unpack_voice_01
 staa up_flag
 stab up_bits
 stx up_node
 ldaa up_node+1
 adda up_prev
 anda #31
 staa up_prev
 asla
 ldx up_dst
 staa 0,x
 inx
 stx up_dst
 cpx up_end
 bne unpack_voice_00
 rts
 .bss
up_src: .ds 2 ; next packed byte
up_dst: .ds 2 ; next output byte
up_end: .ds 2 ; end of the output
up_bits: .ds 1 ; bits in up_flag
up_flag: .ds 1 ; Huffman bit buffer
up_prev: .ds 1 ; previous sample
up_node: .ds 2 ; Huffman tree node
