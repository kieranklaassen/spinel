# The same through an index into a constant's Array, which no sharing rule
# follows, for a bang method and inside a loop body.
WORDS = [+"q", +"r"]
2.times { WORDS[0].upcase! }
p WORDS
