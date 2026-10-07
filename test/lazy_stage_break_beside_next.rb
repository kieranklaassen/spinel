# A `break` in the block of a lazy stage raises LocalJumpError, as in CRuby:
# the stage that took the block has returned by the time the block runs. A
# block that also holds a `next` is read no other way. In the step's frame
# (test/lazy_stage_step_frame.rb) the break left only the frame, and the
# stage went on with nil for the element: [0, nil, 3]. The sidecar holds
# Spinel's tail format for an uncaught raise.
p [1, 2, 3].lazy.map { |x| break if x > 100; x * 2 }.first(2)
p [1, 2, 3].lazy.map { |x| next 0 if x == 1; break if x == 2; x }.to_a
