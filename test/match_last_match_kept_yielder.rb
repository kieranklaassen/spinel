# A program test/match_last_match_positions.rb leaves alone: the match is
# made in a block a method yields to, so it is the block's frame's and not
# the method's.
def around
  "ab" =~ /b/
  yield
  $~.begin(0)
end
p around { "xxxk".match(/k/) }
