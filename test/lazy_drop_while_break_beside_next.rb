# A `break` with a value in the block of a lazy drop_while, beside a `next`:
# LocalJumpError, as in CRuby and as in every other stage
# (test/lazy_stage_break_beside_next.rb). drop_while binds and reads its
# block in a branch of its own. The sidecar holds Spinel's tail format for
# an uncaught raise.
p [1, 2, 3].lazy.drop_while { |x| break 7 if x > 100; x < 2 }.first(2)
p [1, 2, 3].lazy.drop_while { |x| next true if x == 1; break 7 if x == 2; x < 2 }.to_a
