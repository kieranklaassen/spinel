# A `break` in an argument of a call that takes a block, in the block of a lazy stage that also holds a
# `next`: LocalJumpError, as in CRuby. The break is the stage's block's
# own wherever it is written, so the block is read without the step's
# frame (test/lazy_stage_break_beside_next.rb). The sidecar holds Spinel's
# tail format for an uncaught raise.
p [1, 2, 3].lazy.map { |x| [x].each_slice((break if x > 100; 1)) { |q| }; x * 2 }.first(2)
p [1, 2, 3].lazy.map { |x| next 0 if x == 1; [x].each_slice((break if x == 2; 1)) { |q| }; x }.to_a
