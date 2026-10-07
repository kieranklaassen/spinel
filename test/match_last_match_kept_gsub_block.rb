# A program test/match_last_match_positions.rb leaves alone: the match is
# made inside the block of a gsub, which sets $~ itself when it is done.
s = "2026-10-05 x"
r = s.gsub(/(\d)(\d)/) { |d| "k7 z".match(/k(\d)/); "<" + d + ">" }
p r, $~.begin(0)
