# A `break` in the block of a lazy pipeline written inside the block of
# another, which also holds a `next`: LocalJumpError, as in CRuby. The
# inner pipeline has no loop of its own for the break to leave, so in the
# outer block's step frame it left only that frame, and the outer stage
# went on: [0, 1]. A block with a `break` anywhere in it is read without
# the frame (test/lazy_stage_break_beside_next.rb). The sidecar holds
# Spinel's tail format for an uncaught raise.
p [1, 2].lazy.map { |x| [5, 6].lazy.map { |q| break if q > 100; q }.to_a.size + x }.first(2)
p [1, 2].lazy.map { |x| next 0 if x == 1; [5, 6].lazy.map { |q| break if q == 6; q }.to_a.size }.to_a
