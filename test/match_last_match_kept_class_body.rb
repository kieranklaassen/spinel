# A program test/match_last_match_positions.rb leaves alone: the match is
# made in a class body, a frame of its own in CRuby.
"ab" =~ /b/
class Probe
  HIT = "xxxk".match(/k/) ? 1 : 0
end
p $~.begin(0), Probe::HIT
